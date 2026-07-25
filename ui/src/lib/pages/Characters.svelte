<script lang="ts">
	import { onMount } from 'svelte';
	import { Nui } from '../nui';
	import { navigate } from '../store/admin.svelte';
	import Loader from '../primitives/Loader.svelte';
	import Row from '../primitives/Row.svelte';
	import Pagination from '../primitives/Pagination.svelte';
	import SearchField from '../primitives/SearchField.svelte';
	import type { CharacterSearchResult } from '../types';

	let search = $state('');
	let page = $state(1);
	let pages = $state(1);
	let loading = $state(false);
	let players = $state<CharacterSearchResult[]>([]);

	async function fetchResults(p = 1) {
		loading = true;
		const res = await Nui.getAllPlayersByCharacter(search, p);
		if (res) {
			players = res.players;
			pages = Math.max(1, res.pages);
		}
		loading = false;
	}

	onMount(() => fetchResults(1));

	function onSubmit() {
		page = 1;
		fetchResults(1);
	}

	function onPageChange(p: number) {
		page = p;
		fetchResults(p);
	}

	function onRowClick(p: CharacterSearchResult) {
		if (p.Online != null) navigate('player', { id: String(p.Online) });
	}
</script>

<div class="page">
	<div class="controls">
		<SearchField bind:value={search} onEnter={onSubmit} />
	</div>

	{#if loading}
		<Loader text="Loading" />
	{:else}
		<div class="list">
			{#if players.length === 0}
				<div class="empty">No results found</div>
			{/if}
			{#each players as p, i (`${p.SID}-${i}`)}
				<Row disabled={p.Online == null} onclick={p.Online != null ? () => onRowClick(p) : undefined}>
					<span class="cell">
						<span class="label">Character State ID</span>
						<span class="value">{p.SID}</span>
					</span>
					<span class="cell">
						<span class="label">Character Name</span>
						<span class="value">{p.First} {p.Last}</span>
					</span>
					<span class="cell">
						<span class="label">User</span>
						<span class="value">{p.User ?? ''}</span>
					</span>
				</Row>
			{/each}
		</div>
		<Pagination {page} {pages} onchange={onPageChange} />
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
		flex: 1;
		display: flex;
		flex-direction: column;
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
	}

	.empty {
		text-align: center;
		padding: 3vh 0;
		color: var(--color-text-muted);
		font-size: 1.1vmin;
	}
</style>
