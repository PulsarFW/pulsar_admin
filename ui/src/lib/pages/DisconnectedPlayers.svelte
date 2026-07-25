<script lang="ts">
	import { onMount } from 'svelte';
	import { Nui } from '../nui';
	import { navigate } from '../store/admin.svelte';
	import Loader from '../primitives/Loader.svelte';
	import Row from '../primitives/Row.svelte';
	import Pagination from '../primitives/Pagination.svelte';
	import SearchField from '../primitives/SearchField.svelte';
	import { PLAYERS_PER_PAGE, POLL_INTERVAL_MS } from '../../config';
	import type { DisconnectedPlayerListItem } from '../types';

	let results = $state<DisconnectedPlayerListItem[]>([]);
	let loading = $state(false);
	let search = $state('');
	let page = $state(1);

	async function fetchPlayers() {
		loading = true;
		const res = await Nui.getPlayerList(true);
		if (res) results = res as DisconnectedPlayerListItem[];
		loading = false;
	}

	onMount(() => {
		fetchPlayers();
		const interval = setInterval(fetchPlayers, POLL_INTERVAL_MS);
		return () => clearInterval(interval);
	});

	const filtered = $derived.by(() => {
		const q = search.toLowerCase();
		return results
			.filter((r) => {
				const nameMatch = r.Name?.toLowerCase().includes(q);
				const charNameMatch = r.Character ? `${r.Character.First ?? ''} ${r.Character.Last ?? ''}`.toLowerCase().includes(q) : false;
				const accountMatch = r.AccountID === Number.parseInt(search, 10);
				const sidMatch = r.Character?.SID === Number.parseInt(search, 10);
				return nameMatch || accountMatch || charNameMatch || sidMatch;
			})
			.sort((a, b) => b.DisconnectedTime - a.DisconnectedTime);
	});

	const pages = $derived(Math.max(1, Math.ceil(filtered.length / PLAYERS_PER_PAGE)));
	const pageItems = $derived(filtered.slice((page - 1) * PLAYERS_PER_PAGE, page * PLAYERS_PER_PAGE));

	function relativeTime(unixSeconds: number): string {
		const diffMs = Date.now() - unixSeconds * 1000;
		const mins = Math.floor(diffMs / 60000);
		if (mins < 1) return 'just now';
		if (mins < 60) return `${mins}m ago`;
		const hours = Math.floor(mins / 60);
		if (hours < 24) return `${hours}h ago`;
		return `${Math.floor(hours / 24)}d ago`;
	}
</script>

<div class="page">
	<div class="controls">
		<SearchField bind:value={search} />
	</div>

	{#if loading && results.length === 0}
		<Loader text="Loading" />
	{:else}
		<div class="header-row">
			<span class="col">Account ID</span>
			<span class="col">Player</span>
			<span class="col">Character</span>
			<span class="col">Status</span>
			<span class="col">Disconnected</span>
		</div>
		<div class="list">
			{#if pageItems.length === 0}
				<div class="empty">No results found</div>
			{/if}
			{#each pageItems as p (p.Source)}
				<Row onclick={() => navigate('player', { id: String(p.Source) })}>
					<span class="cell">{p.AccountID}</span>
					<span class="cell">{p.Name}</span>
					<span class="cell">
						{#if p.Character}
							{p.Character.First} {p.Character.Last}
							<div class="sub">SID: {p.Character.SID}</div>
						{:else}
							Not Logged In
						{/if}
					</span>
					<span class="cell" class:reconnected={!!p.Reconnected} class:disconnected={!p.Reconnected}>
						{p.Reconnected ? 'Reconnected' : 'Disconnected'}
					</span>
					<span class="cell">
						{relativeTime(p.DisconnectedTime)}
						{#if p.Reconnected}
							<div class="sub reconnected">Reconnected {p.Reconnected} time(s)</div>
						{/if}
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

	.header-row {
		display: flex;
		align-items: center;
		gap: 1.5vw;
		padding: 0.8vh 1.1vw;
		border-bottom: var(--border-subtle);
		flex-shrink: 0;
	}

	.col {
		flex: 1;
		color: var(--color-text-muted);
		font-size: 0.9vmin;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.04em;
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
	}

	.cell.disconnected {
		color: var(--color-error);
	}

	.cell.reconnected {
		color: var(--color-success);
	}

	.sub {
		font-size: 0.9vmin;
		color: var(--color-text-muted);
	}

	.sub.reconnected {
		color: var(--color-success);
	}

	.empty {
		text-align: center;
		padding: 3vh 0;
		color: var(--color-text-muted);
		font-size: 1.1vmin;
	}
</style>
