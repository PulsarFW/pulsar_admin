<!-- Ban modal's reason-field clear button checks pendingBanReason, not pendingKick -->
<script lang="ts">
	import { Nui } from '../nui';
	import { adminState, navigate, goBack, toast } from '../store/admin.svelte';
	import { BAN_LENGTHS } from '../../config';
	import ActionButton from '../primitives/ActionButton.svelte';
	import Combobox from '../primitives/Combobox.svelte';
	import Loader from '../primitives/Loader.svelte';
	import Modal from '../primitives/Modal.svelte';
	import Select from '../primitives/Select.svelte';
	import type { ItemCatalogEntry, JobCatalogEntry, PlayerDetail, PlayerJobEntry } from '../types';

	let { id }: { id: string } = $props();

	let player = $state<PlayerDetail | null>(null);
	let loading = $state(false);
	let err = $state(false);

	let kickOpen = $state(false);
	let pendingKick = $state('');
	let banOpen = $state(false);
	let pendingBanReason = $state('');
	let pendingBanLength = $state(1);

	// item/job catalogs are fetched once per panel session (lazily, on first modal open) and reused -
	// there's no reason to re-fetch either list per player
	let itemCatalog = $state<ItemCatalogEntry[]>([]);
	let jobCatalog = $state<JobCatalogEntry[]>([]);
	let catalogsLoading = $state(false);

	let giveItemOpen = $state(false);
	let pendingItem = $state('');
	let pendingItemCount = $state(1);
	let pendingAmmo = $state(0);
	let pendingScratched = $state(false);

	let setJobOpen = $state(false);
	let pendingJobId = $state('');
	let pendingWorkplaceId = $state('');
	let pendingGradeId = $state('');

	let removeJobOpen = $state(false);
	let pendingRemoveJob = $state<PlayerJobEntry | null>(null);

	const itemOptions = $derived(itemCatalog.map((i) => ({ value: i.name, label: i.label, sublabel: i.name })));
	const pendingItemData = $derived(itemCatalog.find((i) => i.name === pendingItem));
	// a real firearm (type 2, non-throwable) is always a single instance with its own ammo/scratched state -
	// grenades etc (type 2, isThrowable) stack like a normal item instead, same distinction /giveweapon makes
	const isWeapon = $derived(pendingItemData?.type === 2 && !pendingItemData.isThrowable);
	const jobOptions = $derived(jobCatalog.map((j) => ({ value: j.Id, label: j.Name })));
	const pendingJob = $derived(jobCatalog.find((j) => j.Id === pendingJobId));
	const workplaceOptions = $derived((pendingJob?.Workplaces ?? []).map((w) => ({ value: w.Id, label: w.Name })));
	const gradeOptions = $derived(
		(pendingJob?.Workplaces ? pendingJob.Workplaces.find((w) => w.Id === pendingWorkplaceId)?.Grades : (pendingJob?.Grades ?? []))?.map((g) => ({
			label: g.Name,
			value: g.Id,
		})) ?? [],
	);

	async function ensureCatalogs() {
		if (itemCatalog.length > 0 && jobCatalog.length > 0) return;
		catalogsLoading = true;
		const [items, jobs] = await Promise.all([Nui.getItemsCatalog(), Nui.getJobsCatalog()]);
		itemCatalog = items ?? [];
		jobCatalog = jobs ?? [];
		catalogsLoading = false;
	}

	async function startGiveItem() {
		pendingItem = '';
		pendingItemCount = 1;
		pendingAmmo = 0;
		pendingScratched = false;
		giveItemOpen = true;
		await ensureCatalogs();
	}

	async function onGiveItem() {
		if (!player || !pendingItem) return;
		giveItemOpen = false;
		loading = true;
		const res = isWeapon
			? await Nui.giveItem(player.Source, pendingItem, 1, pendingAmmo, pendingScratched)
			: await Nui.giveItem(player.Source, pendingItem, pendingItemCount);
		if (res?.success) toast.success(`Gave ${pendingItem}`);
		else toast.error(res?.message ?? 'Failed To Give Item');
		loading = false;
	}

	async function startSetJob() {
		pendingJobId = '';
		pendingWorkplaceId = '';
		pendingGradeId = '';
		setJobOpen = true;
		await ensureCatalogs();
	}

	async function onSetJob() {
		if (!player || !pendingJobId || !pendingGradeId) return;
		setJobOpen = false;
		loading = true;
		const res = await Nui.setJob(player.Source, pendingJobId, pendingWorkplaceId || undefined, pendingGradeId);
		if (res?.success) toast.success(`Set Job To ${pendingJob?.Name ?? pendingJobId}`);
		else toast.error(res?.message ?? 'Failed To Set Job');
		await fetchPlayer(true);
		loading = false;
	}

	function startRemoveJob(job: PlayerJobEntry) {
		pendingRemoveJob = job;
		removeJobOpen = true;
	}

	async function onRemoveJob() {
		if (!player || !pendingRemoveJob) return;
		removeJobOpen = false;
		loading = true;
		const res = await Nui.removeJob(player.Source, pendingRemoveJob.Id);
		if (res?.success) toast.success(`Removed ${pendingRemoveJob.Name}`);
		else toast.error(res?.message ?? 'Failed To Remove Job');
		await fetchPlayer(true);
		loading = false;
	}

	function formatDuration(minutes: number): string {
		if (minutes < 60) return `${minutes}m`;
		const hours = Math.floor(minutes / 60);
		const mins = minutes % 60;
		return mins > 0 ? `${hours}h ${mins}m` : `${hours}h`;
	}

	// 5h/20h breakpoints for the time-badge color tier, rough sense of new/regular/veteran on the job
	function timeTier(minutes: number): 'none' | 'low' | 'mid' | 'high' {
		if (minutes <= 0) return 'none';
		if (minutes < 300) return 'low';
		if (minutes < 1200) return 'mid';
		return 'high';
	}

	async function fetchPlayer(forced = false) {
		if (player && String(player.Source) === id && !forced) return;
		loading = true;
		const res = await Nui.getPlayer(Number.parseInt(id, 10));
		if (res) player = res;
		else {
			err = true;
			toast.error('Unable to Load');
		}
		loading = false;
	}

	$effect(() => {
		void id;
		fetchPlayer();
	});

	async function onAction(action: 'goto' | 'bring' | 'heal' | 'attach' | 'marker') {
		if (!player) return;
		const res = await Nui.actionPlayer(player.Source, action);
		if (res?.success) toast.success(res.message ?? 'Done');
		else toast.error(res?.message ?? 'Error');
	}

	function startKick() {
		pendingKick = '';
		kickOpen = true;
	}

	async function onKick() {
		if (!player) return;
		kickOpen = false;
		loading = true;
		const res = await Nui.kickPlayer(player.Source, pendingKick);
		if (res?.success) {
			toast.success(`Kicked ${player.Name ?? 'Player'}`);
			goBack();
		} else {
			toast.error(res?.message ?? 'Failed to Kick Player');
		}
		loading = false;
	}

	function startBan() {
		pendingBanLength = 1;
		pendingBanReason = '';
		banOpen = true;
	}

	async function onBan() {
		if (!player) return;
		banOpen = false;
		loading = true;
		const res = await Nui.banPlayer(player.Source, pendingBanReason, pendingBanLength);
		if (res?.success) toast.success(`Banned ${player.Name ?? 'Player'}`);
		else toast.error(res?.message ?? 'Failed to Ban Player');
		loading = false;
	}

	function copyCoords() {
		if (!player?.Character?.Coords) return;
		const { x, y, z } = player.Character.Coords;
		navigator.clipboard.writeText(`vector3(${x.toFixed(3)}, ${y.toFixed(3)}, ${z.toFixed(3)})`).catch(() => {});
		toast.success('Copied Coordinates');
	}

	function onDisconnectedClick() {
		if (player?.Reconnected) navigate('player', { id: String(player.Reconnected) });
	}

	function relativeTime(unixSeconds: number): string {
		const diffMs = Date.now() - unixSeconds * 1000;
		const mins = Math.floor(diffMs / 60000);
		if (mins < 1) return 'just now';
		if (mins < 60) return `${mins}m ago`;
		const hours = Math.floor(mins / 60);
		if (hours < 24) return `${hours}h ago`;
		return `${Math.floor(hours / 24)}d ago`;
	}

	const isSelf = $derived(adminState.user?.Source === player?.Source);
	const banLengthOptions = $derived(BAN_LENGTHS.filter((l) => adminState.permissionLevel >= l.permissionLevel).map((l) => ({ label: l.name, value: l.value })));
</script>

<div class="page">
	{#if loading || (!player && !err)}
		<Loader static text="Loading" />
	{:else if err || !player}
		<div class="error-banner">Invalid Player</div>
	{:else}
		<div class="actions">
			<ActionButton label="Goto" disabled={!player.Character || isSelf || !!player.Disconnected} onclick={() => onAction('goto')} />
			<ActionButton label="Bring" disabled={!player.Character || isSelf || adminState.permissionLevel < player.Level || !!player.Disconnected} onclick={() => onAction('bring')} />
			<ActionButton label="Heal" disabled={!player.Character || !!player.Disconnected || (isSelf && adminState.permissionLevel < 75)} onclick={() => onAction('heal')} />
			<ActionButton label="Spectate" disabled={!player.Character || isSelf || adminState.permissionLevel < player.Level || !!player.Disconnected} onclick={() => onAction('attach')} />
			<ActionButton label="Kick" disabled={isSelf || adminState.permissionLevel < player.Level} onclick={startKick} />
			<ActionButton label="Ban" variant="danger" disabled={isSelf || adminState.permissionLevel < player.Level || adminState.permissionLevel < 75} onclick={startBan} />
			<ActionButton label="Refresh" onclick={() => fetchPlayer(true)} />
			<ActionButton label="GPS Marker" disabled={isSelf} onclick={() => onAction('marker')} />
			{#if !adminState.compact}
				<ActionButton label="Give Item" disabled={!player.Character || !!player.Disconnected} onclick={startGiveItem} />
				<ActionButton label="Set Job" disabled={!player.Character || isSelf || adminState.permissionLevel <= player.Level || !!player.Disconnected} onclick={startSetJob} />
			{/if}
		</div>

		{#if player.Disconnected}
			<button type="button" class="disconnect-banner" onclick={onDisconnectedClick} disabled={!player.Reconnected}>
				<strong>Player Has Disconnected</strong>
				<span>
					Disconnected {relativeTime(player.DisconnectedTime ?? 0)}{player.Reconnected ? ', they have since reconnected to the server.' : '.'}
					{#if player.Reason}Reason: {player.Reason}{/if}
				</span>
			</button>
		{/if}

		<div class="grid">
			<div class="col">
				<div class="field"><span class="label">Player Name</span><span class="value">{player.Name} {isSelf ? '(You)' : ''}</span></div>
				<div class="field"><span class="label">Player Account</span><span class="value">{player.AccountID}</span></div>
				{#if player.StaffGroup}
					<div class="field"><span class="label">Staff Group</span><span class="value">{player.StaffGroup}</span></div>
				{/if}
				<div class="field"><span class="label">Player Source</span><span class="value">{player.Source}</span></div>
				<div class="field"><span class="label">Player Identifier</span><span class="value">{player.Identifier}</span></div>
			</div>
			<div class="col">
				{#if player.Character}
					<div class="field"><span class="label">Character Name</span><span class="value">{player.Character.First} {player.Character.Last}</span></div>
					<div class="field"><span class="label">Character State ID</span><span class="value">{player.Character.SID}</span></div>
					<div class="field"><span class="label">DOB</span><span class="value">{new Date(player.Character.DOB).toLocaleDateString(undefined, { year: 'numeric', month: 'long', day: 'numeric' })}</span></div>
					<div class="field"><span class="label">Character Phone #</span><span class="value">{player.Character.Phone}</span></div>
					{#if adminState.permissionLevel >= 90}
						<button type="button" class="field clickable" onclick={copyCoords}>
							<span class="label">Coordinates</span>
							<span class="value">vector3({(player.Character.Coords?.x ?? 0).toFixed(3)}, {(player.Character.Coords?.y ?? 0).toFixed(3)}, {(player.Character.Coords?.z ?? 0).toFixed(3)})</span>
						</button>
					{/if}
				{:else}
					<div class="field"><span class="label">Character</span><span class="value">Not Logged In</span></div>
				{/if}
			</div>
		</div>

		{#if player.Character?.Jobs && player.Character.Jobs.length > 0}
			<div class="jobs-section">
				<div class="section-title">Jobs</div>
				<div class="jobs-list">
					{#each player.Character.Jobs as job (job.Id)}
						<div class="job-row">
							<div class="job-info">
								<span class="job-name">
									{job.Name}{job.Workplace ? ` - ${job.Workplace.Name}` : ''}
									{#if job.OnDuty}<span class="duty-badge">On Duty</span>{/if}
								</span>
								<span class="job-meta">
									{job.Grade.Name} (Level {job.Grade.Level})
									<span class="time-badge tier-{timeTier(job.TotalMinutes)}">{formatDuration(job.TotalMinutes)} on duty overall</span>
								</span>
							</div>
							{#if !adminState.compact}
								<ActionButton
									label="Remove"
									variant="danger"
									disabled={!isSelf && adminState.permissionLevel <= player.Level}
									onclick={() => startRemoveJob(job)}
								/>
							{/if}
						</div>
					{/each}
				</div>
			</div>
		{/if}
	{/if}
</div>

{#if player}
	<Modal showing={kickOpen} title={`Kick ${player.Name}`} acceptLabel="Kick" onAccept={onKick} onClose={() => (kickOpen = false)}>
		<label class="form-field">
			<span class="form-label">Kick Reason</span>
			<textarea bind:value={pendingKick} rows="3"></textarea>
			<span class="hint">Please give a reason to kick the player.</span>
		</label>
	</Modal>

	<Modal showing={banOpen} title={`Ban ${player.Name}`} acceptLabel="Ban" onAccept={onBan} onClose={() => (banOpen = false)}>
		<Select bind:value={pendingBanLength} options={banLengthOptions} label="Ban Length" />
		<label class="form-field">
			<span class="form-label">Ban Reason</span>
			<textarea bind:value={pendingBanReason} rows="3"></textarea>
			<span class="hint">Please give a reason to ban the player.</span>
		</label>
	</Modal>

	<Modal showing={giveItemOpen} title={`Give Item To ${player.Name}`} acceptLabel="Give" onAccept={onGiveItem} onClose={() => (giveItemOpen = false)}>
		{#if catalogsLoading}
			<Loader static text="Loading Items" />
		{:else}
			<Combobox bind:value={pendingItem} label="Item" placeholder="Search items…" options={itemOptions} />
			{#if isWeapon}
				<label class="form-field">
					<span class="form-label">Ammo</span>
					<input type="number" min="0" bind:value={pendingAmmo} />
				</label>
				<label class="form-field checkbox">
					<input type="checkbox" bind:checked={pendingScratched} />
					<span class="form-label">Scratched Serial Number</span>
				</label>
			{:else}
				<label class="form-field">
					<span class="form-label">Count</span>
					<input type="number" min="1" bind:value={pendingItemCount} />
				</label>
			{/if}
		{/if}
	</Modal>

	<Modal showing={setJobOpen} title={`Set Job For ${player.Name}`} acceptLabel="Set Job" onAccept={onSetJob} onClose={() => (setJobOpen = false)}>
		{#if catalogsLoading}
			<Loader static text="Loading Jobs" />
		{:else}
			<Combobox
				bind:value={pendingJobId}
				label="Job"
				placeholder="Search jobs…"
				options={jobOptions}
				onSelect={() => {
					pendingWorkplaceId = '';
					pendingGradeId = '';
				}}
			/>
			{#if workplaceOptions.length > 0}
				<Combobox
					bind:value={pendingWorkplaceId}
					label="Workplace"
					placeholder="Search workplaces…"
					options={workplaceOptions}
					onSelect={() => (pendingGradeId = '')}
				/>
			{/if}
			{#if pendingJobId && (workplaceOptions.length === 0 || pendingWorkplaceId)}
				<Combobox bind:value={pendingGradeId} label="Grade" placeholder="Search grades…" options={gradeOptions} />
			{/if}
		{/if}
	</Modal>

	<Modal
		showing={removeJobOpen}
		title={`Remove ${pendingRemoveJob?.Name ?? 'Job'} From ${player.Name}`}
		acceptLabel="Remove"
		onAccept={onRemoveJob}
		onClose={() => (removeJobOpen = false)}
	>
		<span class="hint">This removes their employment at {pendingRemoveJob?.Workplace?.Name ?? pendingRemoveJob?.Name}, clocking them off duty if active.</span>
	</Modal>
{/if}

<style>
	.page {
		padding: 2vh 1.5vw;
		height: 100%;
		position: relative;
	}

	.actions {
		display: flex;
		flex-wrap: wrap;
		gap: 0.6vw;
		margin-bottom: 1.6vh;
	}

	.error-banner {
		color: var(--color-error);
		border: 1px solid var(--color-error-dark);
		border-radius: var(--radius);
		padding: 1.4vh 1.2vw;
	}

	.disconnect-banner {
		display: flex;
		flex-direction: column;
		align-items: flex-start;
		gap: 0.3vh;
		width: 100%;
		text-align: left;
		background: rgba(240, 168, 72, 0.08);
		border: 1px solid rgba(240, 168, 72, 0.3);
		border-radius: var(--radius);
		color: var(--color-warning);
		padding: 1.2vh 1.2vw;
		margin-bottom: 1.6vh;
		font-family: inherit;
		cursor: pointer;
	}

	.disconnect-banner:disabled {
		cursor: default;
		pointer-events: none;
	}

	.disconnect-banner span {
		font-size: 1vmin;
		color: var(--color-text-muted);
	}

	.grid {
		display: flex;
		gap: 3vw;
	}

	.col {
		flex: 1;
		display: flex;
		flex-direction: column;
		gap: 1.2vh;
	}

	.field {
		display: flex;
		flex-direction: column;
		background: transparent;
		border: none;
		text-align: left;
		font-family: inherit;
		padding: 0;
	}

	.field.clickable {
		cursor: pointer;
	}

	.field.clickable:hover .value {
		color: var(--color-primary-light);
	}

	.label {
		font-size: 0.85vmin;
		color: var(--color-text-muted);
		text-transform: uppercase;
		letter-spacing: 0.04em;
	}

	.value {
		font-size: 1.3vmin;
		color: var(--color-text);
		margin-top: 0.2vh;
		transition: color 120ms ease;
	}

	.jobs-section {
		margin-top: 2vh;
	}

	.section-title {
		font-size: 0.85vmin;
		color: var(--color-text-muted);
		text-transform: uppercase;
		letter-spacing: 0.04em;
		margin-bottom: 0.8vh;
	}

	.jobs-list {
		display: flex;
		flex-direction: column;
		gap: 0.6vh;
	}

	.job-row {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1vw;
		background: rgba(232, 232, 236, 0.04);
		border: var(--border-subtle);
		border-radius: var(--radius);
		padding: 1vh 1vw;
	}

	.job-info {
		display: flex;
		flex-direction: column;
		gap: 0.2vh;
		min-width: 0;
	}

	.job-name {
		font-size: 1.35vmin;
		font-weight: 600;
		color: var(--color-text);
		display: flex;
		align-items: center;
		gap: 0.5vw;
	}

	.duty-badge {
		font-size: 0.85vmin;
		font-weight: 600;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		color: var(--color-primary-light);
		background: rgba(139, 92, 246, 0.15);
		border-radius: var(--radius);
		padding: 0.2vh 0.5vw;
	}

	.job-meta {
		font-size: 1.05vmin;
		color: var(--color-text-muted);
		display: flex;
		align-items: center;
		gap: 0.6vw;
		flex-wrap: wrap;
	}

	.time-badge {
		font-size: 0.9vmin;
		font-weight: 700;
		letter-spacing: 0.03em;
		border-radius: var(--radius);
		padding: 0.25vh 0.55vw;
		border: 1px solid transparent;
	}

	.time-badge.tier-none {
		color: var(--color-text-muted);
		background: rgba(232, 232, 236, 0.06);
		border-color: rgba(232, 232, 236, 0.12);
	}

	.time-badge.tier-low {
		color: var(--color-info);
		background: rgba(91, 163, 224, 0.14);
		border-color: rgba(91, 163, 224, 0.32);
	}

	.time-badge.tier-mid {
		color: var(--color-success);
		background: rgba(107, 207, 107, 0.14);
		border-color: rgba(107, 207, 107, 0.32);
	}

	.time-badge.tier-high {
		color: var(--color-primary-light);
		background: rgba(139, 92, 246, 0.16);
		border-color: rgba(139, 92, 246, 0.36);
	}

	.form-field {
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
	}

	.form-field.checkbox {
		flex-direction: row;
		align-items: center;
		gap: 0.6vw;
	}

	.form-label {
		font-size: 0.95vmin;
		color: var(--color-text-muted);
	}

	textarea {
		background: rgba(232, 232, 236, 0.05);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		font-family: inherit;
		font-size: 1.05vmin;
		padding: 0.8vh 0.8vw;
		resize: vertical;
	}

	textarea:focus {
		outline: none;
		border-color: rgba(139, 92, 246, 0.5);
	}

	input[type='number'] {
		background: rgba(232, 232, 236, 0.05);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		font-family: inherit;
		font-size: 1.05vmin;
		padding: 0.8vh 0.8vw;
	}

	input[type='number']:focus {
		outline: none;
		border-color: rgba(139, 92, 246, 0.5);
	}

	.hint {
		font-size: 0.85vmin;
		color: var(--color-text-muted);
	}
</style>
