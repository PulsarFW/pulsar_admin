<!-- items database browser, full-panel only, click an item to give it to yourself or an online player -->
<script lang="ts">
	import { onMount } from 'svelte';
	import { Nui } from '../nui';
	import { adminState, toast } from '../store/admin.svelte';
	import Icon from '../Icon.svelte';
	import Loader from '../primitives/Loader.svelte';
	import Row from '../primitives/Row.svelte';
	import Pagination from '../primitives/Pagination.svelte';
	import SearchField from '../primitives/SearchField.svelte';
	import Combobox from '../primitives/Combobox.svelte';
	import Modal from '../primitives/Modal.svelte';
	import { ITEMS_PER_PAGE } from '../../config';
	import type { ItemCatalogEntry, PlayerListItem } from '../types';

	let items = $state<ItemCatalogEntry[]>([]);
	let players = $state<PlayerListItem[]>([]);
	let loading = $state(false);
	let search = $state('');
	let page = $state(1);
	let failedImages = $state<Record<string, boolean>>({});

	let giveOpen = $state(false);
	let pendingItem = $state<ItemCatalogEntry | null>(null);
	let pendingCount = $state(1);
	let pendingAmmo = $state(0);
	let pendingScratched = $state(false);
	let pendingTarget = $state('');

	async function fetchData() {
		loading = true;
		const [itemRes, playerRes] = await Promise.all([Nui.getItemsCatalog(), Nui.getPlayerList(false)]);
		items = itemRes ?? [];
		players = (playerRes as PlayerListItem[]) ?? [];
		loading = false;
	}

	onMount(fetchData);

	function imgSrc(item: ItemCatalogEntry): string {
		return `nui://pulsar_inventory/ui/images/items/${item.name}.webp`;
	}

	function typeLabel(item: ItemCatalogEntry): string {
		if (item.type !== 2) return 'Item';
		return item.isThrowable ? 'Weapon (Throwable)' : 'Weapon';
	}

	function startGive(item: ItemCatalogEntry) {
		pendingItem = item;
		pendingCount = 1;
		pendingAmmo = 0;
		pendingScratched = false;
		pendingTarget = String(adminState.user?.Source ?? '');
		giveOpen = true;
	}

	async function onGive() {
		if (!pendingItem || !pendingTarget) return;
		giveOpen = false;
		const targetSource = Number.parseInt(pendingTarget, 10);
		const res = isWeapon
			? await Nui.giveItem(targetSource, pendingItem.name, 1, pendingAmmo, pendingScratched)
			: await Nui.giveItem(targetSource, pendingItem.name, pendingCount);
		if (res?.success) toast.success(`Gave ${pendingItem.label}`);
		else toast.error(res?.message ?? 'Failed To Give Item');
	}

	const isWeapon = $derived(pendingItem?.type === 2 && !pendingItem.isThrowable);

	const filtered = $derived.by(() => {
		const q = search.toLowerCase();
		return items.filter((r) => r.label.toLowerCase().includes(q) || r.name.toLowerCase().includes(q));
	});

	const targetOptions = $derived([
		{ value: String(adminState.user?.Source ?? ''), label: 'Myself' },
		...players
			.filter((p) => p.Character && p.Source !== adminState.user?.Source)
			.map((p) => ({ value: String(p.Source), label: `${p.Character!.First} ${p.Character!.Last}`, sublabel: `SID ${p.Character!.SID}` })),
	]);

	const pages = $derived(Math.max(1, Math.ceil(filtered.length / ITEMS_PER_PAGE)));
	const pageItems = $derived(filtered.slice((page - 1) * ITEMS_PER_PAGE, page * ITEMS_PER_PAGE));
</script>

<div class="page">
	<div class="controls">
		<SearchField bind:value={search} />
	</div>

	{#if loading && items.length === 0}
		<Loader text="Loading" />
	{:else}
		<div class="list">
			{#if pageItems.length === 0}
				<div class="empty">No results found</div>
			{/if}
			{#each pageItems as item (item.name)}
				<Row onclick={() => startGive(item)}>
					<span class="icon-box">
						{#if !failedImages[item.name]}
							<img src={imgSrc(item)} alt="" onerror={() => (failedImages = { ...failedImages, [item.name]: true })} />
						{:else}
							<Icon name="boxes-stacked" size="1.4vmin" />
						{/if}
					</span>
					<span class="cell wide">
						<span class="label">Label</span>
						<span class="value">{item.label}</span>
					</span>
					<span class="cell wide">
						<span class="label">Name</span>
						<span class="value">{item.name}</span>
					</span>
					<span class="cell">
						<span class="label">Type</span>
						<span class="value">{typeLabel(item)}</span>
					</span>
				</Row>
			{/each}
		</div>
		<Pagination {page} {pages} onchange={(p) => (page = p)} />
	{/if}
</div>

<Modal
	showing={giveOpen}
	title={`Give ${pendingItem?.label ?? ''}`}
	acceptLabel="Give"
	onAccept={onGive}
	onClose={() => (giveOpen = false)}
>
	<Combobox bind:value={pendingTarget} label="Target" placeholder="Search players…" options={targetOptions} />
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
			<input type="number" min="1" bind:value={pendingCount} />
		</label>
	{/if}
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

	.icon-box {
		flex-shrink: 0;
		width: 3.4vh;
		height: 3.4vh;
		border-radius: var(--radius);
		background: rgba(232, 232, 236, 0.05);
		border: var(--border-subtle);
		display: flex;
		align-items: center;
		justify-content: center;
		color: var(--color-text-muted);
		overflow: hidden;
	}

	.icon-box img {
		width: 100%;
		height: 100%;
		object-fit: contain;
		padding: 0.4vh;
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
	}

	.empty {
		text-align: center;
		padding: 3vh 0;
		color: var(--color-text-muted);
		font-size: 1.1vmin;
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
</style>
