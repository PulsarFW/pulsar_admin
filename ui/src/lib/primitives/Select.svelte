<!-- self-contained themed listbox, native select popups render unstylable OS/Chromium chrome in a CEF NUI. used for Ban Length -->
<script lang="ts">
	import Icon from '../Icon.svelte';

	let {
		value = $bindable(),
		options,
		label,
	}: { value: number; options: { label: string; value: number }[]; label?: string } = $props();

	let open = $state(false);
	let root: HTMLDivElement = $state()!;

	const selected = $derived(options.find((o) => o.value === value));

	function pick(v: number) {
		value = v;
		open = false;
	}

	function onWindowClick(e: MouseEvent) {
		if (open && root && !root.contains(e.target as Node)) open = false;
	}
</script>

<svelte:window onclick={onWindowClick} />

<div class="wrap" bind:this={root}>
	{#if label}<span class="label">{label}</span>{/if}
	<button type="button" class="control" class:open onclick={() => (open = !open)}>
		<span>{selected?.label ?? '—'}</span>
		<Icon name="chevron-left" size="0.8vmin" />
	</button>
	{#if open}
		<div class="panel">
			{#each options as opt (opt.value)}
				<button type="button" class="option" class:active={opt.value === value} onclick={() => pick(opt.value)}>
					{opt.label}
				</button>
			{/each}
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
		max-height: 20vh;
		overflow-y: auto;
		box-shadow: 0 0.8vh 2vh rgba(0, 0, 0, 0.5);
	}

	.option {
		display: block;
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
</style>
