<!-- sorts the full filtered list by .Entity before paginating, not after -->
<script lang="ts">
	import { onMount } from 'svelte';
	import { Nui } from '../nui';
	import { navigate } from '../store/admin.svelte';
	import Loader from '../primitives/Loader.svelte';
	import Row from '../primitives/Row.svelte';
	import Pagination from '../primitives/Pagination.svelte';
	import SearchField from '../primitives/SearchField.svelte';
	import { VEHICLES_PER_PAGE } from '../../config';
	import type { VehicleListItem } from '../types';

	let results = $state<VehicleListItem[]>([]);
	let loading = $state(false);
	let search = $state('');
	let page = $state(1);

	async function fetchVehicles() {
		loading = true;
		const res = await Nui.getVehicleList();
		if (res) results = res;
		loading = false;
	}

	onMount(fetchVehicles);

	const filtered = $derived.by(() => {
		const q = search.toLowerCase();
		return results
			.filter((r) => {
				return (
					`${r.Make ?? ''} ${r.Model ?? ''}`.toLowerCase().includes(q) ||
					r.Plate.toUpperCase().includes(search.toUpperCase()) ||
					r.VIN.toUpperCase() === search.toUpperCase() ||
					r.OwnerId.toString().toLowerCase().includes(q)
				);
			})
			.sort((a, b) => b.Entity - a.Entity);
	});

	const pages = $derived(Math.max(1, Math.ceil(filtered.length / VEHICLES_PER_PAGE)));
	const pageItems = $derived(filtered.slice((page - 1) * VEHICLES_PER_PAGE, page * VEHICLES_PER_PAGE));
</script>

<div class="page">
	<div class="controls">
		<SearchField bind:value={search} />
	</div>

	{#if loading && results.length === 0}
		<Loader text="Loading" />
	{:else}
		<div class="list">
			{#if pageItems.length === 0}
				<div class="empty">No results found</div>
			{/if}
			{#each pageItems as v (v.Entity)}
				<Row onclick={() => navigate('vehicle', { id: String(v.Entity) })}>
					<span class="cell">
						<span class="label">Owner</span>
						<span class="value">{v.OwnerId ?? '?'}</span>
					</span>
					<span class="cell wide">
						<span class="label">Make/Model</span>
						<span class="value">{v.Make ?? 'Unknown'} {v.Model ?? 'Unknown'}</span>
					</span>
					<span class="cell wide">
						<span class="label">VIN</span>
						<span class="value">{v.VIN}</span>
					</span>
					<span class="cell">
						<span class="label">Plate</span>
						<span class="value">{v.Plate}</span>
					</span>
				</Row>
			{/each}
		</div>
		<Pagination {page} {pages} onchange={(p) => (page = p)} />
	{/if}
</div>

<style>
	.page {
		padding: 2vh 1.5vw;
		height: 100%;
		display: flex;
		flex-direction: column;
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
</style>
