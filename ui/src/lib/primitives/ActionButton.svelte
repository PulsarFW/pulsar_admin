<!-- flex-wrap row of themed buttons, degrades better than a fixed button-group since visible buttons vary by permission -->
<script lang="ts">
	let {
		label,
		onclick,
		disabled = false,
		variant = 'default',
	}: { label: string; onclick: () => void; disabled?: boolean; variant?: 'default' | 'danger' } = $props();
</script>

<button type="button" class="action" class:danger={variant === 'danger'} {disabled} {onclick}>
	{label}
</button>

<style>
	.action {
		background: rgba(232, 232, 236, 0.05);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		font-family: inherit;
		font-size: 1.05vmin;
		font-weight: 600;
		padding: 0.9vh 1.2vw;
		cursor: pointer;
		transition: color 120ms ease, border-color 120ms ease, background 120ms ease;
	}

	.action:hover:not(:disabled) {
		border-color: rgba(139, 92, 246, 0.5);
		background: rgba(139, 92, 246, 0.14);
		color: var(--color-primary-light);
	}

	.action.danger:hover:not(:disabled) {
		border-color: rgba(229, 72, 77, 0.5);
		background: rgba(229, 72, 77, 0.14);
		color: var(--color-error);
	}

	.action:disabled {
		opacity: 0.35;
		pointer-events: none;
	}
</style>
