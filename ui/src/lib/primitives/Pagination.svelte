<!-- compact prev/page/next control -->
<script lang="ts">
	import Icon from '../Icon.svelte';

	let { page, pages, onchange }: { page: number; pages: number; onchange: (page: number) => void } = $props();
</script>

{#if pages > 1}
	<div class="pagination">
		<button type="button" class="chevron" disabled={page <= 1} onclick={() => onchange(page - 1)} aria-label="Previous page">
			<Icon name="chevron-left" size="0.85vmin" />
		</button>
		<span class="label">{page} / {pages}</span>
		<button type="button" class="chevron" disabled={page >= pages} onclick={() => onchange(page + 1)} aria-label="Next page">
			<Icon name="chevron-right" size="0.85vmin" />
		</button>
	</div>
{/if}

<style>
	.pagination {
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 0.8vw;
		padding: 1vh 0;
	}

	.chevron {
		background: rgba(232, 232, 236, 0.05);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		cursor: pointer;
		padding: 0.6vh 0.8vw;
		display: flex;
	}

	.chevron:hover:not(:disabled) {
		border-color: rgba(139, 92, 246, 0.5);
		color: var(--color-primary-light);
	}

	.chevron:disabled {
		opacity: 0.3;
		pointer-events: none;
	}

	.label {
		font-size: 1vmin;
		color: var(--color-text-muted);
		min-width: 4vw;
		text-align: center;
	}
</style>
