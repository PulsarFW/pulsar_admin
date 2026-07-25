<!-- shared search input with a clear button, used by every list page -->
<script lang="ts">
	let {
		value = $bindable(),
		placeholder = 'Search',
		onEnter,
	}: { value: string; placeholder?: string; onEnter?: () => void } = $props();

	import Icon from '../Icon.svelte';

	function onKeydown(e: KeyboardEvent) {
		if (e.key === 'Enter') onEnter?.();
	}
</script>

<div class="field">
	<input type="text" bind:value {placeholder} onkeydown={onKeydown} />
	{#if value !== ''}
		<button type="button" class="clear" onclick={() => (value = '')} aria-label="Clear">
			<Icon name="xmark" size="0.85vmin" />
		</button>
	{/if}
</div>

<style>
	.field {
		display: flex;
		align-items: center;
		background: rgba(232, 232, 236, 0.05);
		border: var(--border-subtle);
		border-radius: var(--radius);
		padding: 0.2vh 0.6vw;
	}

	input {
		flex: 1;
		background: transparent;
		border: none;
		color: var(--color-text);
		font-size: 1.1vmin;
		padding: 0.8vh 0.4vw;
	}

	input:focus {
		outline: none;
	}

	.clear {
		background: transparent;
		border: none;
		color: var(--color-text-muted);
		cursor: pointer;
		display: flex;
		padding: 0.4vh;
	}

	.clear:hover {
		color: var(--color-text);
	}
</style>
