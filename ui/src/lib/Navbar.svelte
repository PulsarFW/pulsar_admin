<!-- vertical icon-rail nav, doubles as the compact-mode nav (same link list, laid out as a horizontal strip instead) -->
<script lang="ts">
	import Icon from './Icon.svelte';
	import { navLinks } from '../config';
	import { adminState, navigate } from './store/admin.svelte';

	const links = $derived(navLinks(adminState.permission, adminState.compact));
</script>

<nav class="rail" class:compact={adminState.compact}>
	{#each links as link (link.page)}
		<button type="button" class="link" class:active={adminState.page === link.page} onclick={() => navigate(link.page)} title={link.label}>
			<Icon name={link.icon} size={adminState.compact ? '1.3vmin' : '1.5vmin'} />
		</button>
	{/each}
</nav>

<style>
	.rail {
		flex-shrink: 0;
		width: 5.5vw;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 0.8vh;
		padding: 1.6vh 0;
		border-right: var(--border-subtle);
		overflow-y: auto;
	}

	.rail.compact {
		width: 100%;
		flex-direction: row;
		justify-content: center;
		gap: 0.5vw;
		padding: 0.8vh 0;
		border-right: none;
		border-bottom: var(--border-subtle);
		overflow-x: auto;
		overflow-y: hidden;
	}

	.link {
		width: 4.4vh;
		height: 4.4vh;
		min-width: 40px;
		min-height: 40px;
		border-radius: 50%;
		background: transparent;
		border: none;
		color: rgba(232, 232, 236, 0.55);
		display: flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		flex-shrink: 0;
		transition: color 120ms ease, background 120ms ease;
	}

	.rail.compact .link {
		width: 3.6vh;
		height: 3.6vh;
		min-width: 30px;
		min-height: 30px;
	}

	.link:hover {
		color: var(--color-primary-light);
		background: rgba(139, 92, 246, 0.1);
	}

	.link.active {
		color: var(--color-primary-light);
		background: rgba(139, 92, 246, 0.18);
	}
</style>
