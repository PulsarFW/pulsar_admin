<script lang="ts">
	import { onMount } from 'svelte';
	import { Nui } from '../nui';
	import { toast } from '../store/admin.svelte';
	import Icon from '../Icon.svelte';
	import Loader from '../primitives/Loader.svelte';
	import Row from '../primitives/Row.svelte';
	import Pagination from '../primitives/Pagination.svelte';
	import SearchField from '../primitives/SearchField.svelte';
	import Modal from '../primitives/Modal.svelte';
	import ActionButton from '../primitives/ActionButton.svelte';
	import { DOORS_PER_PAGE } from '../../config';
	import type { DoorEntry, DoorRestriction, DoorRestrictionType } from '../types';

	let doors = $state<DoorEntry[]>([]);
	let loading = $state(false);
	let search = $state('');
	let categoryFilter = $state('all');
	let page = $state(1);

	let formOpen = $state(false);
	let formMode = $state<'create' | 'edit'>('create');
	let pendingDbId = $state<number | null>(null);
	let form = $state(blankForm());
	let picking = $state(false);
	let capturingZone = $state(false);

	let removeOpen = $state(false);
	let pendingRemove = $state<DoorEntry | null>(null);

	function blankLeaf() {
		return { model: '', x: '0', y: '0', z: '0', heading: '0' };
	}

	function blankZone() {
		return { x: '', y: '', z: '', heading: '0', length: '10', width: '10', minZ: '', maxZ: '' };
	}

	function blankForm() {
		return {
			identifier: '',
			category: 'misc',
			label: '',
			type: 'standard' as 'standard' | 'garage',
			leaves: [blankLeaf()],
			locked: true,
			autoRate: '',
			autoDist: '',
			maxDist: '',
			holdOpen: false,
			canLockpick: false,
			restricted: [] as DoorRestriction[],
			zone: blankZone(),
		};
	}

	async function fetchDoors() {
		loading = true;
		const res = await Nui.getDoorsCatalog();
		doors = res ?? [];
		loading = false;
	}

	onMount(fetchDoors);

	const categories = $derived.by(() => {
		const set = new Set<string>();
		for (const d of doors) set.add(d.category);
		return ['all', ...Array.from(set).sort()];
	});

	const filtered = $derived.by(() => {
		const q = search.toLowerCase();
		return doors.filter((d) => {
			const matchesSearch = (d.label ?? '').toLowerCase().includes(q) || (d.identifier ?? '').toLowerCase().includes(q);
			const matchesCategory = categoryFilter === 'all' || d.category === categoryFilter;
			return matchesSearch && matchesCategory;
		});
	});

	const pages = $derived(Math.max(1, Math.ceil(filtered.length / DOORS_PER_PAGE)));
	const pageItems = $derived(filtered.slice((page - 1) * DOORS_PER_PAGE, page * DOORS_PER_PAGE));
	const isDouble = $derived(form.leaves.length > 1);

	function startCreate() {
		formMode = 'create';
		pendingDbId = null;
		form = blankForm();
		formOpen = true;
	}

	function startEdit(door: DoorEntry) {
		formMode = 'edit';
		pendingDbId = door.dbId ?? null;
		form = {
			identifier: door.identifier ?? '',
			category: door.category,
			label: door.label ?? '',
			type: door.type,
			leaves: door.doors.map((leaf) => ({
				model: String(leaf.model),
				x: String(leaf.coords.x),
				y: String(leaf.coords.y),
				z: String(leaf.coords.z),
				heading: String(leaf.heading ?? 0),
			})),
			locked: door.locked,
			autoRate: door.autoRate != null ? String(door.autoRate) : '',
			autoDist: door.autoDist != null ? String(door.autoDist) : '',
			maxDist: door.maxDist != null ? String(door.maxDist) : '',
			holdOpen: !!door.holdOpen,
			canLockpick: !!door.canLockpick,
			restricted: door.restricted ? door.restricted.map((r) => ({ ...r })) : [],
			zone: door.garageZone
				? {
						x: String(door.garageZone.x),
						y: String(door.garageZone.y),
						z: String(door.garageZone.z),
						heading: String(door.garageZone.heading),
						length: String(door.garageZone.length),
						width: String(door.garageZone.width),
						minZ: String(door.garageZone.minZ),
						maxZ: String(door.garageZone.maxZ),
					}
				: blankZone(),
		};
		formOpen = true;
	}

	function toggleDouble() {
		if (isDouble) form.leaves = [form.leaves[0]];
		else form.leaves = [...form.leaves, blankLeaf()];
	}

	async function pickLeaf(index: number) {
		picking = true;
		const result = await Nui.pickDoorInWorld();
		picking = false;
		if (!result) {
			toast.error('Pick Cancelled');
			return;
		}
		form.leaves[index] = {
			model: String(result.model),
			x: String(result.coords.x),
			y: String(result.coords.y),
			z: String(result.coords.z),
			heading: String(result.heading ?? 0),
		};
		toast.success('Door Object Captured');
	}

	async function captureZone() {
		capturingZone = true;
		const result = await Nui.captureZonePosition();
		capturingZone = false;
		if (!result) {
			toast.error('Capture Failed');
			return;
		}
		form.zone.x = String(result.x);
		form.zone.y = String(result.y);
		form.zone.z = String(result.z);
		form.zone.heading = String(result.heading);
		if (!form.zone.minZ) form.zone.minZ = String(result.z - 2);
		if (!form.zone.maxZ) form.zone.maxZ = String(result.z + 3);
		toast.success('Zone Position Captured');
	}

	function addRestriction(type: DoorRestrictionType) {
		if (type === 'job') form.restricted.push({ type, job: '', workplace: false, gradeLevel: 0, jobPermission: false, reqDuty: false });
		else if (type === 'character') form.restricted.push({ type, SID: 0 });
		else form.restricted.push({ type, key: 'house', value: '' });
	}

	function removeRestriction(index: number) {
		form.restricted.splice(index, 1);
	}

	function buildPayload(): Partial<DoorEntry> {
		return {
			identifier: form.identifier || undefined,
			category: form.category || 'misc',
			label: form.label || undefined,
			type: form.type,
			doors: form.leaves.map((leaf) => ({
				model: Number(leaf.model) || leaf.model,
				coords: { x: Number(leaf.x) || 0, y: Number(leaf.y) || 0, z: Number(leaf.z) || 0 },
				heading: Number(leaf.heading) || 0,
			})),
			locked: form.locked,
			autoRate: form.autoRate ? Number(form.autoRate) : undefined,
			autoDist: form.autoDist ? Number(form.autoDist) : undefined,
			maxDist: form.maxDist ? Number(form.maxDist) : undefined,
			holdOpen: form.holdOpen,
			// suppresses the proximity E-prompt for keyfob/zone-triggered doors, always tied to type='garage'
			special: form.type === 'garage',
			canLockpick: form.canLockpick,
			restricted: form.restricted,
			garageZone:
				form.type === 'garage' && form.zone.x !== ''
					? {
							x: Number(form.zone.x) || 0,
							y: Number(form.zone.y) || 0,
							z: Number(form.zone.z) || 0,
							heading: Number(form.zone.heading) || 0,
							length: Number(form.zone.length) || 10,
							width: Number(form.zone.width) || 10,
							minZ: Number(form.zone.minZ) || 0,
							maxZ: Number(form.zone.maxZ) || 0,
						}
					: undefined,
		};
	}

	async function onSubmitForm() {
		if (form.leaves.some((leaf) => !leaf.model)) {
			toast.error('Every Leaf Needs A Model (Pick In World Or Enter A Hash)');
			return;
		}

		formOpen = false;
		if (formMode === 'create') {
			const res = await Nui.createDoor(buildPayload() as DoorEntry);
			if (res?.success) toast.success('Door Created');
			else toast.error(res?.message ?? 'Failed To Create Door');
		} else if (pendingDbId != null) {
			const res = await Nui.editDoor(pendingDbId, buildPayload());
			if (res?.success) toast.success('Door Updated');
			else toast.error(res?.message ?? 'Failed To Update Door');
		}
		await fetchDoors();
	}

	async function teleportTo(door: DoorEntry) {
		if (!door.dbId) return;
		const res = await Nui.teleportToDoor(door.dbId);
		if (res?.success) toast.success('Teleported To Door');
		else toast.error(res?.message ?? 'Failed To Teleport');
	}

	function startRemove(door: DoorEntry) {
		pendingRemove = door;
		removeOpen = true;
	}

	async function onRemove() {
		if (!pendingRemove?.dbId) return;
		removeOpen = false;
		const res = await Nui.removeDoor(pendingRemove.dbId);
		if (res?.success) toast.success('Door Removed');
		else toast.error(res?.message ?? 'Failed To Remove Door');
		await fetchDoors();
	}
</script>

<div class="page">
	<div class="controls">
		<SearchField bind:value={search} placeholder="Search by label or identifier…" />
		<select class="category-select" bind:value={categoryFilter}>
			{#each categories as c (c)}
				<option value={c}>{c === 'all' ? 'All Categories' : c}</option>
			{/each}
		</select>
		<ActionButton label="Add Door" onclick={startCreate} />
	</div>

	{#if loading && doors.length === 0}
		<Loader text="Loading" />
	{:else}
		<div class="list">
			{#if pageItems.length === 0}
				<div class="empty">No results found</div>
			{/if}
			{#each pageItems as door (door.dbId)}
				<Row onclick={() => startEdit(door)}>
					<span class="cell wide">
						<span class="label">Label</span>
						<span class="value">
							{door.label ?? door.identifier ?? `Door #${door.dbId}`}
							{#if door.doors.length > 1}<span class="garage-badge">Double</span>{/if}
						</span>
					</span>
					<span class="cell">
						<span class="label">Identifier</span>
						<span class="value">{door.identifier ?? '—'}</span>
					</span>
					<span class="cell">
						<span class="label">Category</span>
						<span class="value">{door.category}</span>
					</span>
					<span class="cell">
						<span class="label">Type</span>
						<span class="value">
							{door.type}
							{#if door.type === 'garage'}<span class="garage-badge">Keyfob</span>{/if}
						</span>
					</span>
					<button type="button" class="delete-btn" onclick={(e) => { e.stopPropagation(); teleportTo(door); }} aria-label="Teleport To Door">
						<Icon name="location-crosshairs" size="1vmin" />
					</button>
					<button type="button" class="delete-btn" onclick={(e) => { e.stopPropagation(); startRemove(door); }} aria-label="Delete">
						<Icon name="trash" size="1vmin" />
					</button>
				</Row>
			{/each}
		</div>
		<Pagination {page} {pages} onchange={(p) => (page = p)} />
	{/if}
</div>

<Modal
	showing={formOpen}
	title={formMode === 'create' ? 'Add Door' : `Edit ${form.label || form.identifier || 'Door'}`}
	acceptLabel={formMode === 'create' ? 'Create' : 'Save'}
	onAccept={onSubmitForm}
	onClose={() => (formOpen = false)}
>
	<div class="form-grid">
		<label class="form-field">
			<span class="form-label">Identifier</span>
			<input type="text" bind:value={form.identifier} placeholder="e.g. bennys_office_main" />
		</label>
		<label class="form-field">
			<span class="form-label">Category</span>
			<input type="text" bind:value={form.category} placeholder="e.g. businesses" />
		</label>
		<label class="form-field">
			<span class="form-label">Label</span>
			<input type="text" bind:value={form.label} placeholder="Admin panel display name" />
		</label>
		<label class="form-field">
			<span class="form-label">Type</span>
			<select bind:value={form.type}>
				<option value="standard">Standard (Proximity Lock/Unlock)</option>
				<option value="garage">Garage (Keyfob/Zone-Triggered)</option>
			</select>
		</label>

		{#if form.type === 'garage'}
			<div class="leaf-box">
				<div class="leaf-header">
					<span class="form-label">Keyfob Zone</span>
					<ActionButton label={capturingZone ? 'Capturing…' : 'Capture Zone Position'} disabled={capturingZone} onclick={captureZone} />
				</div>
				<span class="hint">Stand where the zone should be centered, then capture - the keyfob action only fires while standing inside this zone.</span>
				<div class="coords-row">
					<label class="form-field">
						<span class="form-label">X</span>
						<input type="number" bind:value={form.zone.x} />
					</label>
					<label class="form-field">
						<span class="form-label">Y</span>
						<input type="number" bind:value={form.zone.y} />
					</label>
					<label class="form-field">
						<span class="form-label">Z</span>
						<input type="number" bind:value={form.zone.z} />
					</label>
					<label class="form-field">
						<span class="form-label">Heading</span>
						<input type="number" bind:value={form.zone.heading} />
					</label>
				</div>
				<div class="coords-row">
					<label class="form-field">
						<span class="form-label">Length</span>
						<input type="number" bind:value={form.zone.length} />
					</label>
					<label class="form-field">
						<span class="form-label">Width</span>
						<input type="number" bind:value={form.zone.width} />
					</label>
					<label class="form-field">
						<span class="form-label">Min Z</span>
						<input type="number" bind:value={form.zone.minZ} />
					</label>
					<label class="form-field">
						<span class="form-label">Max Z</span>
						<input type="number" bind:value={form.zone.maxZ} />
					</label>
				</div>
			</div>
		{/if}

		<label class="form-field checkbox">
			<input type="checkbox" checked={isDouble} onchange={toggleDouble} />
			<span class="form-label">Double Door (Two Leaves That Toggle Together)</span>
		</label>

		{#each form.leaves as leaf, i (i)}
			<div class="leaf-box">
				<div class="leaf-header">
					<span class="form-label">{isDouble ? `Leaf ${i + 1}` : 'Door Object'}</span>
					<ActionButton label={picking ? 'Aim In-Game…' : 'Pick In World'} disabled={picking} onclick={() => pickLeaf(i)} />
				</div>
				<label class="form-field">
					<span class="form-label">Model Hash</span>
					<input type="text" bind:value={leaf.model} placeholder="Filled by Pick In World, or enter manually" />
				</label>
				<div class="coords-row">
					<label class="form-field">
						<span class="form-label">X</span>
						<input type="number" bind:value={leaf.x} />
					</label>
					<label class="form-field">
						<span class="form-label">Y</span>
						<input type="number" bind:value={leaf.y} />
					</label>
					<label class="form-field">
						<span class="form-label">Z</span>
						<input type="number" bind:value={leaf.z} />
					</label>
					<label class="form-field">
						<span class="form-label">Heading</span>
						<input type="number" bind:value={leaf.heading} />
					</label>
				</div>
			</div>
		{/each}

		<div class="coords-row">
			<label class="form-field">
				<span class="form-label">Auto Rate</span>
				<input type="number" step="0.1" bind:value={form.autoRate} />
			</label>
			<label class="form-field">
				<span class="form-label">Auto Distance</span>
				<input type="number" step="0.1" bind:value={form.autoDist} />
			</label>
			<label class="form-field">
				<span class="form-label">Max Interact Distance</span>
				<input type="number" step="0.1" bind:value={form.maxDist} />
			</label>
		</div>
		<div class="checkbox-row">
			<label class="form-field checkbox">
				<input type="checkbox" bind:checked={form.locked} />
				<span class="form-label">Locked By Default</span>
			</label>
			<label class="form-field checkbox">
				<input type="checkbox" bind:checked={form.holdOpen} />
				<span class="form-label">Hold Open</span>
			</label>
			<label class="form-field checkbox">
				<input type="checkbox" bind:checked={form.canLockpick} />
				<span class="form-label">Lockpickable</span>
			</label>
		</div>

		<div class="restrictions">
			<div class="restrictions-header">
				<span class="form-label">Access Restrictions</span>
				<span class="hint">No rules means force/lockpick-only access (used by every heist door) - leave empty for that.</span>
			</div>
			{#each form.restricted as rule, i (i)}
				<div class="restriction-row">
					{#if rule.type === 'job'}
						<input type="text" class="rule-input" bind:value={rule.job} placeholder="Job (e.g. police)" />
						<input
							type="text"
							class="rule-input"
							value={rule.workplace === false ? '' : (rule.workplace ?? '')}
							oninput={(e) => (rule.workplace = (e.currentTarget as HTMLInputElement).value || false)}
							placeholder="Workplace (blank = false)"
						/>
						<input type="number" class="rule-input narrow" bind:value={rule.gradeLevel} placeholder="Grade" />
						<label class="rule-checkbox">
							<input type="checkbox" bind:checked={rule.reqDuty} />
							Duty
						</label>
					{:else if rule.type === 'character'}
						<input type="number" class="rule-input" bind:value={rule.SID} placeholder="State ID" />
					{:else}
						<input type="text" class="rule-input narrow" bind:value={rule.key} placeholder="Key (e.g. house)" />
						<input type="text" class="rule-input" bind:value={rule.value} placeholder="Value (e.g. lakevinewood2)" />
					{/if}
					<button type="button" class="delete-btn" onclick={() => removeRestriction(i)} aria-label="Remove Rule">
						<Icon name="trash" size="0.9vmin" />
					</button>
				</div>
			{/each}
			<div class="add-rule-row">
				<ActionButton label="+ Job Rule" onclick={() => addRestriction('job')} />
				<ActionButton label="+ Character Rule" onclick={() => addRestriction('character')} />
				<ActionButton label="+ Property Rule" onclick={() => addRestriction('propertyData')} />
			</div>
		</div>
	</div>
</Modal>

<Modal
	showing={removeOpen}
	title={`Remove ${pendingRemove?.label ?? pendingRemove?.identifier ?? 'Door'}`}
	acceptLabel="Remove"
	onAccept={onRemove}
	onClose={() => (removeOpen = false)}
>
	<span class="hint">This permanently deletes this door's definition, any resource still calling plsr.Doors with this identifier will no longer find it.</span>
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
		display: flex;
		gap: 0.6vw;
		margin-bottom: 1.4vh;
		flex-shrink: 0;
	}

	.controls :global(.field) {
		flex: 1;
	}

	.category-select {
		background: rgba(232, 232, 236, 0.05);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		font-family: inherit;
		font-size: 1.05vmin;
		padding: 0.6vh 1.8vw 0.6vh 0.6vw;
	}

	.category-select,
	.form-field select {
		appearance: none;
		-webkit-appearance: none;
		cursor: pointer;
		background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16' fill='none' stroke='%23a0a0ab' stroke-width='1.6' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M4 6l4 4 4-4'/%3E%3C/svg%3E");
		background-repeat: no-repeat;
		background-position: right 0.5vw center;
		background-size: 1vmin;
		transition: border-color 120ms ease;
	}

	.category-select:hover,
	.form-field select:hover {
		border-color: rgba(139, 92, 246, 0.4);
	}

	.category-select:focus,
	.form-field select:focus {
		outline: none;
		border-color: rgba(139, 92, 246, 0.6);
	}

	.category-select option,
	.form-field select option {
		background: #0e0e12;
		color: var(--color-text);
	}

	.list {
		flex: 1;
		min-height: 0;
		overflow-y: auto;
	}

	.cell {
		display: flex;
		flex-direction: column;
		flex: 1;
	}

	.cell.wide {
		flex: 2;
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
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		display: flex;
		align-items: center;
		gap: 0.4vw;
	}

	.garage-badge {
		font-size: 0.8vmin;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		color: var(--color-primary-light);
		background: rgba(139, 92, 246, 0.15);
		border-radius: var(--radius);
		padding: 0.15vh 0.4vw;
	}

	.delete-btn {
		flex-shrink: 0;
		background: transparent;
		border: none;
		color: var(--color-text-muted);
		cursor: pointer;
		padding: 0.4vh;
		display: flex;
	}

	.delete-btn:hover {
		color: var(--color-error);
	}

	.empty {
		text-align: center;
		padding: 3vh 0;
		color: var(--color-text-muted);
		font-size: 1.1vmin;
	}

	.form-grid {
		display: flex;
		flex-direction: column;
		gap: 1.2vh;
		max-height: 60vh;
		overflow-y: auto;
	}

	.form-field {
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
		flex: 1;
	}

	.form-field.checkbox {
		flex-direction: row;
		align-items: center;
		gap: 0.6vw;
	}

	.form-field.checkbox input[type='checkbox'] {
		appearance: none;
		-webkit-appearance: none;
		width: 1.6vmin;
		height: 1.6vmin;
		flex-shrink: 0;
		margin: 0;
		background: rgba(232, 232, 236, 0.05);
		border: var(--border-subtle);
		border-radius: 0.3vmin;
		cursor: pointer;
		transition: background-color 120ms ease, border-color 120ms ease;
	}

	.form-field.checkbox input[type='checkbox']:hover {
		border-color: rgba(139, 92, 246, 0.4);
	}

	.form-field.checkbox input[type='checkbox']:checked {
		background-color: rgba(139, 92, 246, 0.9);
		border-color: rgba(139, 92, 246, 0.9);
		background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16' fill='none' stroke='%23fff' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M3 8l3.5 3.5L13 5'/%3E%3C/svg%3E");
		background-repeat: no-repeat;
		background-position: center;
		background-size: 70%;
	}

	.form-label {
		font-size: 0.95vmin;
		color: var(--color-text-muted);
	}

	.leaf-box {
		display: flex;
		flex-direction: column;
		gap: 0.8vh;
		border: var(--border-subtle);
		border-radius: var(--radius);
		padding: 1vh 1vw;
	}

	.leaf-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
	}

	.coords-row,
	.checkbox-row {
		display: flex;
		gap: 0.8vw;
		flex-wrap: wrap;
	}

	input[type='text'],
	input[type='number'],
	.form-field select {
		background: rgba(232, 232, 236, 0.05);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		font-family: inherit;
		font-size: 1.05vmin;
		padding: 0.8vh 0.8vw;
	}

	.form-field select {
		padding-right: 1.8vw;
	}

	input:focus {
		outline: none;
		border-color: rgba(139, 92, 246, 0.5);
	}

	.restrictions {
		border-top: var(--border-subtle);
		padding-top: 1.2vh;
		display: flex;
		flex-direction: column;
		gap: 0.8vh;
	}

	.restrictions-header {
		display: flex;
		flex-direction: column;
		gap: 0.3vh;
	}

	.hint {
		font-size: 0.85vmin;
		color: var(--color-text-muted);
	}

	.restriction-row {
		display: flex;
		align-items: center;
		gap: 0.5vw;
	}

	.rule-input {
		flex: 1;
		min-width: 0;
	}

	.rule-input.narrow {
		flex: 0 0 5vw;
	}

	.rule-checkbox {
		display: flex;
		align-items: center;
		gap: 0.3vw;
		font-size: 0.95vmin;
		color: var(--color-text-muted);
		flex-shrink: 0;
	}

	.add-rule-row {
		display: flex;
		gap: 0.6vw;
		flex-wrap: wrap;
	}
</style>
