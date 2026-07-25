<!-- Entity Model/Coordinates/Heading rows copy via the Clipboard API + toast -->
<script lang="ts">
	import { Nui } from '../nui';
	import { adminState, toast } from '../store/admin.svelte';
	import { CURRENCY } from '../../config';
	import ActionButton from '../primitives/ActionButton.svelte';
	import Loader from '../primitives/Loader.svelte';
	import type { VehicleDetail } from '../types';

	let { id }: { id: string } = $props();

	let vehicle = $state<VehicleDetail | null>(null);
	let loading = $state(false);
	let err = $state(false);

	async function fetchVehicle(forced = false) {
		if (vehicle && !forced) return;
		loading = true;
		const res = await Nui.getVehicle(Number.parseInt(id, 10));
		if (res) vehicle = res;
		else {
			err = true;
			toast.error('Unable to Load');
		}
		loading = false;
	}

	$effect(() => {
		void id;
		fetchVehicle();
	});

	async function onAction(action: 'repair' | 'repair_full' | 'repair_engine' | 'fuel' | 'sitinside' | 'locks' | 'stall' | 'explode' | 'delete') {
		if (!vehicle) return;
		const res = await Nui.actionVehicle(vehicle.EntityModel, vehicle.Entity, action);
		if (res?.success) toast.success(res.message ?? 'Done');
		else toast.error(res?.message ?? 'Error');
	}

	function copyInfo(text: string) {
		navigator.clipboard.writeText(text).catch(() => {});
		toast.success('Copied');
	}
</script>

<div class="page">
	{#if loading || (!vehicle && !err)}
		<Loader static text="Loading" />
	{:else if err || !vehicle}
		<div class="error-banner">Invalid Vehicle</div>
	{:else}
		<div class="actions">
			<ActionButton label="Quick Repair" onclick={() => onAction('repair')} />
			{#if adminState.permissionLevel >= 90}
				<ActionButton label="Full Repair" onclick={() => onAction('repair_full')} />
				<ActionButton label="Engine Repair" onclick={() => onAction('repair_engine')} />
				<ActionButton label="Fuel" onclick={() => onAction('fuel')} />
			{/if}
			{#if adminState.permissionLevel >= 75}
				<ActionButton label="Sit Inside" onclick={() => onAction('sitinside')} />
			{/if}
			{#if adminState.permissionLevel >= 90}
				<ActionButton label="Toggle Locks" onclick={() => onAction('locks')} />
			{/if}
			<ActionButton label="Refresh" onclick={() => fetchVehicle(true)} />
		</div>

		<div class="grid">
			<div class="col">
				<div class="field"><span class="label">Owned</span><span class="value">{vehicle.Owned ? `Yes - ${vehicle.Owner?.Id}` : 'No'}</span></div>
				<div class="field"><span class="label">Vehicle Name</span><span class="value">{vehicle.Make ?? 'Unknown'} {vehicle.Model ?? 'Unknown'}</span></div>
				<div class="field"><span class="label">Vehicle VIN</span><span class="value">{vehicle.VIN}</span></div>
				<div class="field"><span class="label">Vehicle Plate</span><span class="value">{vehicle.Plate}</span></div>
				<div class="field"><span class="label">Estimated Value</span><span class="value">{CURRENCY.format(vehicle.Value ?? 0)}</span></div>
				<button type="button" class="field clickable" onclick={() => copyInfo(`${vehicle?.EntityModel}`)}>
					<span class="label">Vehicle Entity Model</span><span class="value">{vehicle.EntityModel}</span>
				</button>
				<button
					type="button"
					class="field clickable"
					onclick={() => copyInfo(`vector3(${(vehicle?.Coords?.x ?? 0).toFixed(2)}, ${(vehicle?.Coords?.y ?? 0).toFixed(2)}, ${(vehicle?.Coords?.z ?? 0).toFixed(2)})`)}
				>
					<span class="label">Coordinates</span>
					<span class="value">vector3({(vehicle.Coords?.x ?? 0).toFixed(2)}, {(vehicle.Coords?.y ?? 0).toFixed(2)}, {(vehicle.Coords?.z ?? 0).toFixed(2)})</span>
				</button>
				<button type="button" class="field clickable" onclick={() => copyInfo(`${(vehicle?.Heading ?? 0).toFixed(2)}`)}>
					<span class="label">Heading</span><span class="value">{(vehicle.Heading ?? 0).toFixed(2)}</span>
				</button>
			</div>
			<div class="col">
				<div class="field"><span class="label">Fuel</span><span class="value">{Math.round(vehicle.Fuel ?? 0)}</span></div>
				<div class="field"><span class="label">Engine Damage</span><span class="value">{Math.round(vehicle.Damage?.Engine ?? 1000)}</span></div>
				<div class="field"><span class="label">Body Damage</span><span class="value">{Math.round(vehicle.Damage?.Body ?? 1000)}</span></div>
				{#if vehicle.DamagedParts}
					<div class="field"><span class="label">Axle</span><span class="value">{vehicle.DamagedParts.Axle}</span></div>
					<div class="field"><span class="label">Radiator</span><span class="value">{vehicle.DamagedParts.Radiator}</span></div>
					<div class="field"><span class="label">Transmission</span><span class="value">{vehicle.DamagedParts.Transmission}</span></div>
					<div class="field"><span class="label">Fuel Injectors</span><span class="value">{vehicle.DamagedParts.FuelInjectors}</span></div>
					<div class="field"><span class="label">Brakes</span><span class="value">{vehicle.DamagedParts.Brakes}</span></div>
					<div class="field"><span class="label">Clutch</span><span class="value">{vehicle.DamagedParts.Clutch}</span></div>
					<div class="field"><span class="label">Electronics</span><span class="value">{vehicle.DamagedParts.Electronics}</span></div>
				{/if}
			</div>
		</div>

		{#if adminState.permissionLevel >= 75}
			<div class="actions bottom">
				{#if adminState.permissionLevel >= 90}
					<ActionButton label="Stall" variant="danger" onclick={() => onAction('stall')} />
					<ActionButton label="Explode" variant="danger" onclick={() => onAction('explode')} />
				{/if}
				<ActionButton label="Delete" variant="danger" onclick={() => onAction('delete')} />
			</div>
		{/if}
	{/if}
</div>

<style>
	.page {
		padding: 2vh 1.5vw;
		height: 100%;
		position: relative;
	}

	.actions {
		display: flex;
		flex-wrap: wrap;
		gap: 0.6vw;
		margin-bottom: 1.6vh;
	}

	.actions.bottom {
		margin-top: 2vh;
		margin-bottom: 0;
	}

	.error-banner {
		color: var(--color-error);
		border: 1px solid var(--color-error-dark);
		border-radius: var(--radius);
		padding: 1.4vh 1.2vw;
	}

	.grid {
		display: flex;
		gap: 3vw;
	}

	.col {
		flex: 1;
		display: flex;
		flex-direction: column;
		gap: 1.2vh;
	}

	.field {
		display: flex;
		flex-direction: column;
		background: transparent;
		border: none;
		text-align: left;
		font-family: inherit;
		padding: 0;
	}

	.field.clickable {
		cursor: pointer;
	}

	.field.clickable:hover .value {
		color: var(--color-primary-light);
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
		transition: color 120ms ease;
	}
</style>
