<!-- root panel, reads permission off the store and lets Navbar.svelte's own check decide which links show, plain page-id switch (see store/admin.svelte.ts's navigate()/goBack()).
	compact mode: a small top-right corner widget instead of the big centered panel, toggled from Titlebar.svelte -->
<script lang="ts">
	import { adminState } from './store/admin.svelte';
	import Titlebar from './Titlebar.svelte';
	import Navbar from './Navbar.svelte';
	import QuickActions from './QuickActions.svelte';
	import Toast from './Toast.svelte';

	import Dashboard from './pages/Dashboard.svelte';
	import Players from './pages/Players.svelte';
	import DisconnectedPlayers from './pages/DisconnectedPlayers.svelte';
	import Characters from './pages/Characters.svelte';
	import Vehicles from './pages/Vehicles.svelte';
	import Items from './pages/Items.svelte';
	import Jobs from './pages/Jobs.svelte';
	import Doors from './pages/Doors.svelte';
	import PlayerDetail from './pages/PlayerDetail.svelte';
	import VehicleDetail from './pages/VehicleDetail.svelte';
	import CurrentVehicleDetail from './pages/CurrentVehicleDetail.svelte';
	import ErrorPage from './pages/ErrorPage.svelte';
</script>

{#if !adminState.hidden}
	<div
		class="panel"
		class:compact={adminState.compact}
		class:picker-hidden={adminState.pickerActive}
		style:opacity={adminState.opacity ? '0.6' : '1'}
	>
		<Titlebar />
		<div class="body" class:compact={adminState.compact}>
			<Navbar />
			<div class="content">
				{#if adminState.page === 'dashboard'}
					<Dashboard />
				{:else if adminState.page === 'players'}
					<Players />
				{:else if adminState.page === 'disconnected-players'}
					<DisconnectedPlayers />
				{:else if adminState.page === 'characters'}
					<Characters />
				{:else if adminState.page === 'vehicles'}
					<Vehicles />
				{:else if adminState.page === 'current-vehicle'}
					<CurrentVehicleDetail />
				{:else if adminState.page === 'items'}
					<Items />
				{:else if adminState.page === 'jobs'}
					<Jobs />
				{:else if adminState.page === 'doors'}
					<Doors />
				{:else if adminState.page === 'player'}
					<PlayerDetail id={adminState.pageParams.id} />
				{:else if adminState.page === 'vehicle'}
					<VehicleDetail id={adminState.pageParams.id} />
				{:else}
					<ErrorPage />
				{/if}
			</div>
		</div>
		<QuickActions />
		<Toast />
	</div>
{/if}

<style>
	.panel {
		position: absolute;
		top: 7vh;
		left: 9vw;
		right: 9vw;
		bottom: 7vh;
		display: flex;
		flex-direction: column;
		background: rgba(6, 6, 8, 1);
		border: var(--border-primary);
		border-radius: var(--radius);
		overflow: hidden;
		pointer-events: auto;
		transition: opacity 200ms ease, top 220ms ease, left 220ms ease, right 220ms ease, bottom 220ms ease, width 220ms ease, height 220ms ease;
	}

	/* hides the panel while the door picker runs, without unmounting it like {#if} would */
	.panel.picker-hidden {
		visibility: hidden;
		pointer-events: none;
	}

	/* compact mode: a small corner-anchored widget instead of the big centered panel */
	.panel.compact {
		top: 3vh;
		right: 3vh;
		left: auto;
		bottom: auto;
		width: 34vw;
		max-width: 500px;
		min-width: 320px;
		height: 80vh;
		max-height: 780px;
	}

	.body {
		flex: 1;
		min-height: 0;
		display: flex;
	}

	.body.compact {
		flex-direction: column;
	}

	.content {
		flex: 1;
		min-width: 0;
		overflow-y: auto;
	}
</style>
