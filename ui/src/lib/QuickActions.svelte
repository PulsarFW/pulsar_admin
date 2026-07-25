<!-- persistent footer bar for Noclip/Invisibility/Nametags, visible in both panel and compact mode. these are blind toggles, none report on/off state back from Lua -->
<script lang="ts">
	import Icon from './Icon.svelte';
	import { Nui } from './nui';
	import { adminState } from './store/admin.svelte';
</script>

<div class="quick-actions" class:compact={adminState.compact}>
	<button type="button" class="action" onclick={() => Nui.toggleNoclip()} title="Toggle Noclip">
		<Icon name="ghost" size={adminState.compact ? '1.2vmin' : '1.4vmin'} />
		{#if !adminState.compact}<span>Noclip</span>{/if}
	</button>
	{#if adminState.permissionLevel >= 100}
		<button type="button" class="action" onclick={() => Nui.toggleInvisible()} title="Toggle Invisibility">
			<Icon name="eye-slash" size={adminState.compact ? '1.2vmin' : '1.4vmin'} />
			{#if !adminState.compact}<span>Invisible</span>{/if}
		</button>
	{/if}
	<button type="button" class="action" onclick={() => Nui.toggleIds()} title="Toggle Nametags">
		<Icon name="id-badge" size={adminState.compact ? '1.2vmin' : '1.4vmin'} />
		{#if !adminState.compact}<span>Nametags</span>{/if}
	</button>
</div>

<style>
	.quick-actions {
		flex-shrink: 0;
		display: flex;
		gap: 0.6vw;
		padding: 1vh 1.2vw;
		border-top: var(--border-subtle);
		background: rgba(232, 232, 236, 0.02);
	}

	.quick-actions.compact {
		padding: 0.7vh 0.8vw;
		gap: 0.5vw;
	}

	.action {
		flex: 1;
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 0.5vw;
		background: rgba(232, 232, 236, 0.05);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		font-family: inherit;
		font-size: 1.05vmin;
		font-weight: 600;
		padding: 0.9vh 0.8vw;
		cursor: pointer;
		transition: color 120ms ease, border-color 120ms ease, background 120ms ease;
	}

	.quick-actions.compact .action {
		padding: 0.8vh 0.5vw;
	}

	.action:hover {
		border-color: rgba(139, 92, 246, 0.5);
		background: rgba(139, 92, 246, 0.14);
		color: var(--color-primary-light);
	}
</style>
