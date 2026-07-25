<!-- searchable version of Select.svelte, for lists too long to scroll through blind (item/job lookups) -->
<script lang="ts">
	import Icon from '../Icon.svelte';

	let {
		value = $bindable(),
		label,
		placeholder = 'Search…',
		emptyLabel = 'Select…',
		options,
		onSelect,
	}: {
		value: string;
		label?: string;
		placeholder?: string;
		emptyLabel?: string;
		options: { value: string; label: string; sublabel?: string }[];
		onSelect?: (value: string) => void;
	} = $props();

	let query = $state('');
	let open = $state(false);
	let root: HTMLDivElement = $state()!;
	let searchInput: HTMLInputElement | undefined = $state();

	const selected = $derived(options.find((o) => o.value === value));
	const filtered = $derived.by(() => {
		const q = query.trim().toLowerCase();
		const matches = q ? options.filter((o) => o.label.toLowerCase().includes(q) || o.value.toLowerCase().includes(q)) : options;
		return matches.slice(0, 50);
	});

	function toggle() {
		open = !open;
		if (open) {
			query = '';
			queueMicrotask(() => searchInput?.focus());
		}
	}

	function pick(opt: { value: string; label: string }) {
		value = opt.value;
		open = false;
		onSelect?.(opt.value);
	}

	function onWindowClick(e: MouseEvent) {
		if (open && root && !root.contains(e.target as Node)) open = false;
	}
</script>

<svelte:window onclick={onWindowClick} />

<div class="wrap" bind:this={root}>
	{#if label}<span class="label">{label}</span>{/if}
	<button type="button" class="control" class:open onclick={toggle}>
		<span>{selected?.label ?? emptyLabel}</span>
		<Icon name="chevron-left" size="0.8vmin" />
	</button>
	{#if open}
		<div class="panel">
			<input type="text" class="search" {placeholder} bind:value={query} bind:this={searchInput} />
			<div class="options">
				{#each filtered as opt (opt.value)}
					<button type="button" class="option" class:active={opt.value === value} onclick={() => pick(opt)}>
						<span class="opt-label">{opt.label}</span>
						{#if opt.sublabel}<span class="sub">{opt.sublabel}</span>{/if}
					</button>
				{:else}
					<div class="empty">No Matches</div>
				{/each}
			</div>
		</div>
	{/if}
</div>

<style>
	.wrap {
		position: relative;
	}

	.label {
		display: block;
		font-size: 0.95vmin;
		color: var(--color-text-muted);
		margin-bottom: 0.4vh;
	}

	.control {
		width: 100%;
		display: flex;
		align-items: center;
		justify-content: space-between;
		background: rgba(232, 232, 236, 0.05);
		border: var(--border-subtle);
		border-radius: var(--radius);
		padding: 0.8vh 0.8vw;
		font-size: 1.05vmin;
		font-family: inherit;
		color: var(--color-text);
		cursor: pointer;
	}

	.control :global(svg) {
		transform: rotate(-90deg);
		transition: transform 120ms ease;
		color: rgba(232, 232, 236, 0.45);
	}

	.control.open :global(svg) {
		transform: rotate(90deg);
	}

	.panel {
		position: absolute;
		top: calc(100% + 0.4vh);
		left: 0;
		right: 0;
		z-index: 20;
		background: var(--color-bg-panel-alt);
		border: var(--border-subtle);
		border-radius: var(--radius);
		box-shadow: 0 0.8vh 2vh rgba(0, 0, 0, 0.5);
		overflow: hidden;
	}

	.search {
		width: 100%;
		background: rgba(232, 232, 236, 0.05);
		border: none;
		border-bottom: var(--border-subtle);
		color: var(--color-text);
		font-family: inherit;
		font-size: 1.05vmin;
		padding: 0.8vh 0.8vw;
	}

	.search:focus {
		outline: none;
	}

	.options {
		max-height: 18vh;
		overflow-y: auto;
	}

	.option {
		display: flex;
		align-items: baseline;
		justify-content: space-between;
		gap: 0.6vw;
		width: 100%;
		padding: 0.7vh 0.8vw;
		background: transparent;
		border: none;
		font-family: inherit;
		color: var(--color-text);
		font-size: 1.05vmin;
		text-align: left;
		cursor: pointer;
	}

	.option:hover {
		background: rgba(139, 92, 246, 0.12);
	}

	.option.active {
		color: var(--color-primary-light);
	}

	.opt-label {
		flex: 1;
		min-width: 0;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.sub {
		flex-shrink: 0;
		font-size: 0.85vmin;
		color: var(--color-text-muted);
	}

	.empty {
		padding: 1vh 0.8vw;
		font-size: 1vmin;
		color: var(--color-text-muted);
	}
</style>
