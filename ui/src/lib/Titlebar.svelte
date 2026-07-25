<!-- dropped the dead "Toggle Reveal Players" button (no Lua handler) and the Prev/Next page chevrons (no browser history here) -->
<script lang="ts">
	import Icon from './Icon.svelte';
	import { Nui } from './nui';
	import { adminState, navigate, setOpacity, toggleCompact } from './store/admin.svelte';
	import logo from '../assets/pulsarlogo.png';

	function viewSelf() {
		if (adminState.user) navigate('player', { id: String(adminState.user.Source) });
	}
</script>

<div class="titlebar" class:compact={adminState.compact} onmouseenter={() => setOpacity(true)} onmouseleave={() => setOpacity(false)} role="presentation">
	<div class="branding">
		<img class="logo" class:compact={adminState.compact} src={logo} alt="" />
		<span class="name">Pulsar</span>
		{#if !adminState.compact}
			<span class="sub">Admin System</span>
		{/if}
	</div>

	<div class="right" onmouseenter={() => setOpacity(false)} onmouseleave={() => setOpacity(true)} role="presentation">
		{#if !adminState.compact}
			<div class="account">
				<div class="account-text">
					<small>{adminState.permissionName || 'Staff'}</small>
					<span>{adminState.user?.Name ?? ''}</span>
				</div>
				{#if adminState.user?.Avatar}
					<img class="avatar" src={adminState.user.Avatar} alt="" />
				{:else}
					<div class="avatar placeholder"></div>
				{/if}
			</div>

			<div class="divider"></div>

			{#if adminState.permissionLevel >= 100}
				<button type="button" class="icon-btn" title="Toggle Invisibility" onclick={() => Nui.toggleInvisible()}>
					<Icon name="eye-slash" size="1.6vmin" />
				</button>
			{/if}
			<button type="button" class="icon-btn" title="View Self Player Data" onclick={viewSelf}>
				<Icon name="user-large" size="1.6vmin" />
			</button>
			<button type="button" class="icon-btn" title="Detach From Player" onclick={() => Nui.stopAllAttach()}>
				<Icon name="link-slash" size="1.6vmin" />
			</button>
			<div class="divider"></div>
		{/if}
		<button type="button" class="icon-btn" title={adminState.compact ? 'Switch to Panel' : 'Switch to Compact'} onclick={toggleCompact}>
			<Icon name={adminState.compact ? 'expand' : 'compress'} size={adminState.compact ? '1.3vmin' : '1.6vmin'} />
		</button>
		<button type="button" class="icon-btn" title="Close" onclick={() => Nui.close()}>
			<Icon name="xmark" size={adminState.compact ? '1.3vmin' : '1.6vmin'} />
		</button>
	</div>
</div>

<style>
	.titlebar {
		flex-shrink: 0;
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 1.4vh 1.2vw;
		border-bottom: var(--border-subtle);
	}

	.titlebar.compact {
		padding: 0.9vh 0.9vw;
	}

	.branding {
		display: flex;
		align-items: center;
		gap: 0.7vw;
	}

	.logo {
		height: 4.6vh;
		width: auto;
		object-fit: contain;
	}

	.logo.compact {
		height: 3vh;
	}

	.branding .name {
		font-family: var(--font-heading);
		font-size: 2.2vmin;
		font-weight: 700;
		color: var(--color-text);
	}

	.branding .sub {
		font-size: 1.3vmin;
		color: var(--color-text-muted);
	}

	.right {
		display: flex;
		align-items: center;
		gap: 0.7vw;
	}

	.account {
		display: flex;
		align-items: center;
		gap: 0.7vw;
	}

	.account-text {
		text-align: right;
	}

	.account-text small {
		display: block;
		color: var(--color-text-muted);
		font-size: 1.05vmin;
	}

	.account-text span {
		font-size: 1.3vmin;
		font-weight: 600;
		color: var(--color-text);
	}

	.avatar {
		width: 3vh;
		height: 3vh;
		border-radius: 50%;
		object-fit: cover;
	}

	.avatar.placeholder {
		background: rgba(139, 92, 246, 0.25);
	}

	.divider {
		width: 1px;
		height: 3vh;
		background: rgba(232, 232, 236, 0.12);
	}

	.icon-btn {
		background: transparent;
		border: none;
		color: rgba(232, 232, 236, 0.55);
		cursor: pointer;
		padding: 1vh 0.9vw;
		display: flex;
		border-radius: var(--radius);
		transition: color 120ms ease, background 120ms ease;
	}

	.icon-btn:hover {
		color: var(--color-primary-light);
		background: rgba(139, 92, 246, 0.12);
	}
</style>
