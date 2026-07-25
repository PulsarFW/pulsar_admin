<!-- jobs database browser, full-panel only, click a grade to assign it to yourself or an online player -->
<script lang="ts">
	import { onMount } from 'svelte';
	import { Nui } from '../nui';
	import { adminState, toast } from '../store/admin.svelte';
	import Loader from '../primitives/Loader.svelte';
	import Icon from '../Icon.svelte';
	import Combobox from '../primitives/Combobox.svelte';
	import Modal from '../primitives/Modal.svelte';
	import SearchField from '../primitives/SearchField.svelte';
	import type { JobCatalogEntry, JobGrade, PlayerListItem } from '../types';

	let jobs = $state<JobCatalogEntry[]>([]);
	let players = $state<PlayerListItem[]>([]);
	let loading = $state(false);
	let search = $state('');
	let expandedId = $state<string | null>(null);

	let assignOpen = $state(false);
	let pendingJob = $state<JobCatalogEntry | null>(null);
	let pendingWorkplaceId = $state('');
	let pendingGradeName = $state('');
	let pendingGradeId = $state('');
	let pendingTarget = $state('');

	async function fetchData() {
		loading = true;
		const [jobRes, playerRes] = await Promise.all([Nui.getJobsCatalog(), Nui.getPlayerList(false)]);
		jobs = jobRes ?? [];
		players = (playerRes as PlayerListItem[]) ?? [];
		loading = false;
	}

	onMount(fetchData);

	function toggle(id: string) {
		expandedId = expandedId === id ? null : id;
	}

	function startAssign(job: JobCatalogEntry, workplaceId: string, grade: JobGrade) {
		pendingJob = job;
		pendingWorkplaceId = workplaceId;
		pendingGradeName = grade.Name;
		pendingGradeId = grade.Id;
		pendingTarget = String(adminState.user?.Source ?? '');
		assignOpen = true;
	}

	async function onAssign() {
		if (!pendingJob || !pendingTarget) return;
		assignOpen = false;
		const targetSource = Number.parseInt(pendingTarget, 10);
		const res = await Nui.setJob(targetSource, pendingJob.Id, pendingWorkplaceId || undefined, pendingGradeId);
		if (res?.success) toast.success(`Set Job To ${pendingJob.Name} (${pendingGradeName})`);
		else toast.error(res?.message ?? 'Failed To Set Job');
	}

	const filtered = $derived.by(() => {
		const q = search.toLowerCase();
		return jobs.filter((r) => r.Name.toLowerCase().includes(q) || r.Id.toLowerCase().includes(q));
	});

	const targetOptions = $derived([
		{ value: String(adminState.user?.Source ?? ''), label: 'Myself' },
		...players
			.filter((p) => p.Character && p.Source !== adminState.user?.Source)
			.map((p) => ({ value: String(p.Source), label: `${p.Character!.First} ${p.Character!.Last}`, sublabel: `SID ${p.Character!.SID}` })),
	]);
</script>

<div class="page">
	<div class="controls">
		<SearchField bind:value={search} />
	</div>

	{#if loading && jobs.length === 0}
		<Loader text="Loading" />
	{:else}
		<div class="list">
			{#if filtered.length === 0}
				<div class="empty">No results found</div>
			{/if}
			{#each filtered as job (job.Id)}
				<div class="job">
					<button type="button" class="job-header" onclick={() => toggle(job.Id)}>
						<Icon name={expandedId === job.Id ? 'chevron-down' : 'chevron-right'} size="0.9vmin" />
						<span class="name">{job.Name}</span>
						<span class="id">{job.Id}</span>
					</button>
					{#if expandedId === job.Id}
						<div class="detail">
							{#if job.Workplaces}
								{#each job.Workplaces as wp (wp.Id)}
									<div class="workplace-name">{wp.Name}</div>
									{#each wp.Grades as grade (grade.Id)}
										<button type="button" class="grade" onclick={() => startAssign(job, wp.Id, grade)}>
											<span class="grade-name">{grade.Name}</span>
											<span class="grade-level">Level {grade.Level}</span>
										</button>
									{/each}
								{/each}
							{:else if job.Grades}
								{#each job.Grades as grade (grade.Id)}
									<button type="button" class="grade" onclick={() => startAssign(job, '', grade)}>
										<span class="grade-name">{grade.Name}</span>
										<span class="grade-level">Level {grade.Level}</span>
									</button>
								{/each}
							{/if}
						</div>
					{/if}
				</div>
			{/each}
		</div>
	{/if}
</div>

<Modal
	showing={assignOpen}
	title={`Assign ${pendingJob?.Name ?? ''} - ${pendingGradeName}`}
	acceptLabel="Assign"
	onAccept={onAssign}
	onClose={() => (assignOpen = false)}
>
	<Combobox bind:value={pendingTarget} label="Target" placeholder="Search players…" options={targetOptions} />
</Modal>

<style>
	.page {
		padding: 2vh 1.5vw;
		height: 100%;
		display: flex;
		flex-direction: column;
		position: relative;
	}

	.controls {
		margin-bottom: 1.4vh;
		flex-shrink: 0;
	}

	.list {
		flex: 1;
		min-height: 0;
		overflow-y: auto;
	}

	.job {
		border-bottom: var(--border-subtle);
	}

	.job-header {
		display: flex;
		align-items: center;
		gap: 0.7vw;
		width: 100%;
		padding: 1.1vh 1.1vw;
		background: transparent;
		border: none;
		font-family: inherit;
		text-align: left;
		color: var(--color-text-muted);
		cursor: pointer;
		transition: background 120ms ease;
	}

	.job-header:hover {
		background: rgba(139, 92, 246, 0.08);
		color: var(--color-text);
	}

	.name {
		font-size: 1.3vmin;
		color: var(--color-text);
	}

	.id {
		font-size: 1vmin;
		color: var(--color-text-muted);
	}

	.detail {
		padding: 0 1.1vw 1.4vh 3.2vw;
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
	}

	.workplace-name {
		font-size: 1vmin;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		color: var(--color-primary-light);
		margin: 0.8vh 0 0.4vh;
	}

	.grade {
		display: flex;
		justify-content: space-between;
		width: 100%;
		background: transparent;
		border: none;
		font-family: inherit;
		text-align: left;
		font-size: 1.15vmin;
		padding: 0.5vh 0.6vw;
		border-radius: var(--radius);
		cursor: pointer;
		transition: background 120ms ease;
	}

	.grade:hover {
		background: rgba(139, 92, 246, 0.12);
	}

	.grade-name {
		color: var(--color-text);
	}

	.grade-level {
		color: var(--color-text-muted);
	}

	.empty {
		text-align: center;
		padding: 3vh 0;
		color: var(--color-text-muted);
		font-size: 1.1vmin;
	}
</style>
