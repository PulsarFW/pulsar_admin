<script lang="ts">
	import { onMount } from 'svelte';
	import { Nui } from '../nui';
	import { navigate } from '../store/admin.svelte';
	import Loader from '../primitives/Loader.svelte';
	import Row from '../primitives/Row.svelte';
	import Pagination from '../primitives/Pagination.svelte';
	import SearchField from '../primitives/SearchField.svelte';
	import Icon from '../Icon.svelte';
	import { PLAYERS_PER_PAGE, POLL_INTERVAL_MS } from '../../config';
	import type { PlayerListItem } from '../types';

	let results = $state<PlayerListItem[]>([]);
	let loading = $state(false);
	let search = $state('');
	let includeLoggedOut = $state(true);
	let page = $state(1);
	let sortBy = $state<'AccountID' | 'Name' | 'Character' | 'Source' | null>(null);
	let sortDir = $state<'asc' | 'desc'>('asc');

	async function fetchPlayers() {
		loading = true;
		const res = await Nui.getPlayerList(false);
		if (res) results = res;
		loading = false;
	}

	onMount(() => {
		fetchPlayers();
		const interval = setInterval(fetchPlayers, POLL_INTERVAL_MS);
		return () => clearInterval(interval);
	});

	function sortValue(p: PlayerListItem): string | number {
		switch (sortBy) {
			case 'AccountID':
				return p.AccountID ?? 0;
			case 'Name':
				return (p.Name ?? '').toLowerCase();
			case 'Character':
				return `${p.Character?.First ?? ''} ${p.Character?.Last ?? ''}`.toLowerCase();
			case 'Source':
				return p.Source ?? 0;
			default:
				return '';
		}
	}

	const filtered = $derived.by(() => {
		const q = search.toLowerCase();
		let list = results.filter((r) => {
			const nameMatches = r.Name?.toLowerCase().includes(q);
			const accountIdMatches = r.AccountID === Number.parseInt(search, 10);
			const characterNameMatches = r.Character && `${r.Character.First ?? ''} ${r.Character.Last ?? ''}`.toLowerCase().includes(q);
			const characterSidMatches = r.Character && r.Character.SID === Number.parseInt(search, 10);
			return (nameMatches || accountIdMatches || characterNameMatches || characterSidMatches) && (r.Character || !includeLoggedOut);
		});
		if (sortBy) {
			list = [...list].sort((a, b) => {
				const va = sortValue(a);
				const vb = sortValue(b);
				if (va < vb) return sortDir === 'asc' ? -1 : 1;
				if (va > vb) return sortDir === 'asc' ? 1 : -1;
				return 0;
			});
		}
		return list;
	});

	const pages = $derived(Math.max(1, Math.ceil(filtered.length / PLAYERS_PER_PAGE)));
	const pageItems = $derived(filtered.slice((page - 1) * PLAYERS_PER_PAGE, page * PLAYERS_PER_PAGE));

	function toggleSort(column: typeof sortBy) {
		if (sortBy === column) sortDir = sortDir === 'asc' ? 'desc' : 'asc';
		else {
			sortBy = column;
			sortDir = 'asc';
		}
	}

	function sortIcon(column: typeof sortBy) {
		if (sortBy !== column) return 'sort';
		return sortDir === 'asc' ? 'sort-up' : 'sort-down';
	}
</script>

<div class="page">
	<div class="controls">
		<div class="filter">
			<button type="button" class:active={!includeLoggedOut} onclick={() => (includeLoggedOut = false)}>Show All</button>
			<button type="button" class:active={includeLoggedOut} onclick={() => (includeLoggedOut = true)}>Logged In</button>
		</div>
		<div class="search"><SearchField bind:value={search} /></div>
	</div>

	{#if loading && results.length === 0}
		<Loader text="Loading" />
	{:else}
		<div class="header-row">
			<button type="button" class="col" onclick={() => toggleSort('AccountID')}>Account ID <Icon name={sortIcon('AccountID')} size="0.8vmin" /></button>
			<button type="button" class="col" onclick={() => toggleSort('Name')}>Player <Icon name={sortIcon('Name')} size="0.8vmin" /></button>
			<button type="button" class="col" onclick={() => toggleSort('Character')}>Character <Icon name={sortIcon('Character')} size="0.8vmin" /></button>
			<button type="button" class="col" onclick={() => toggleSort('Source')}>Source <Icon name={sortIcon('Source')} size="0.8vmin" /></button>
		</div>
		<div class="list">
			{#if pageItems.length === 0}
				<div class="empty">No results found</div>
			{/if}
			{#each pageItems as p (p.AccountID)}
				<Row onclick={() => navigate('player', { id: String(p.Source) })}>
					<span class="cell">{p.AccountID}</span>
					<span class="cell">{p.Name}</span>
					<span class="cell">{p.Character ? `${p.Character.First} ${p.Character.Last}` : 'Not Logged In'}</span>
					<span class="cell">{p.Source}</span>
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
		display: flex;
		gap: 0.8vw;
		margin-bottom: 1.4vh;
		flex-shrink: 0;
	}

	.filter {
		display: flex;
		border: var(--border-subtle);
		border-radius: var(--radius);
		overflow: hidden;
		flex-shrink: 0;
	}

	.filter button {
		background: transparent;
		border: none;
		color: var(--color-text-muted);
		font-size: 1vmin;
		padding: 0.9vh 1vw;
		cursor: pointer;
		font-family: inherit;
	}

	.filter button.active {
		background: rgba(139, 92, 246, 0.18);
		color: var(--color-primary-light);
	}

	.search {
		flex: 1;
	}

	.header-row {
		display: flex;
		align-items: center;
		gap: 1.5vw;
		padding: 0.8vh 1.1vw;
		border-bottom: var(--border-subtle);
		flex-shrink: 0;
	}

	.col {
		background: transparent;
		border: none;
		color: var(--color-text-muted);
		font-size: 0.9vmin;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		display: inline-flex;
		align-items: center;
		gap: 0.3vw;
		cursor: pointer;
		font-family: inherit;
		flex: 1;
	}

	.col:hover {
		color: var(--color-text);
	}

	.list {
		flex: 1;
		min-height: 0;
		overflow-y: auto;
	}

	.cell {
		flex: 1;
		font-size: 1.25vmin;
		color: var(--color-text);
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
