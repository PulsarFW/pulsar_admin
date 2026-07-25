<script lang="ts">
	import { onMount } from 'svelte';
	import { Nui } from '../nui';
	import { adminState, toast } from '../store/admin.svelte';
	import { CURRENCY } from '../../config';
	import ActionButton from '../primitives/ActionButton.svelte';
	import Loader from '../primitives/Loader.svelte';
	import type { VehicleDetail } from '../types';

	let vehicle = $state<VehicleDetail | null>(null);
	let loading = $state(false);
	let err = $state(false);

	async function fetchVehicle() {
		loading = true;
		const res = await Nui.getCurrentVehicle();
		if (res) vehicle = res;
		else {
			err = true;
			toast.error('Not in a Vehicle');
		}
		loading = false;
	}

	onMount(fetchVehicle);

	async function onAction(action: 'repair' | 'repair_full' | 'repair_engine' | 'fuel' | 'alarm' | 'explode' | 'customs') {
		const res = await Nui.currentVehicleAction(action);
		if (res?.success) toast.success(res.message ?? 'Done');
		else toast.error(res?.message ?? 'Error');
	}

	function copyInfo(text: string) {
		navigator.clipboard.writeText(text).catch(() => {});
		toast.success('Copied');
	}

	function damagePct(value: number | undefined): number {
		return Math.round(((value ?? 1000) / 1000) * 100);
	}
</script>

<div class="page">
	{#if loading || (!vehicle && !err)}
		<Loader static text="Loading" />
	{:else if err || !vehicle}
		<div class="error-wrap">
			<div class="error-banner">Not In a Vehicle</div>
			<ActionButton label="Refresh" onclick={fetchVehicle} />
		</div>
	{:else}
		<div class="scroll">
			<div class="actions">
				<ActionButton label="Quick Repair" onclick={() => onAction('repair')} />
				{#if adminState.permissionLevel >= 90}
					<ActionButton label="Full Repair" onclick={() => onAction('repair_full')} />
					<ActionButton label="Engine Repair" onclick={() => onAction('repair_engine')} />
					<ActionButton label="Fuel" onclick={() => onAction('fuel')} />
					<ActionButton label="Alarm" onclick={() => onAction('alarm')} />
				{/if}
				<ActionButton label="Refresh" onclick={fetchVehicle} />
			</div>

			<div class="grid" class:compact={adminState.compact}>
				<div class="col">
					<div class="field"><span class="label">Vehicle Name</span><span class="value">{vehicle.Make ?? 'Unknown'} {vehicle.Model ?? 'Unknown'}</span></div>
					<button type="button" class="field clickable" onclick={() => copyInfo(`${vehicle?.EntityModel}`)}>
						<span class="label">Vehicle Entity Model</span><span class="value">{vehicle.EntityModel}</span>
					</button>
					<div class="field"><span class="label">Vehicle VIN</span><span class="value">{vehicle.VIN}</span></div>
					<div class="field"><span class="label">Vehicle Plate</span><span class="value">{vehicle.Plate}</span></div>
					<div class="field"><span class="label">Owned</span><span class="value">{vehicle.Owned ? `Yes - ${vehicle.Owner?.Id ?? 'Unknown'}` : 'No'}</span></div>
					<div class="field"><span class="label">Estimated Value</span><span class="value">{CURRENCY.format(vehicle.Value ?? 0)}</span></div>
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
					<div class="field"><span class="label">Current Seat</span><span class="value">{vehicle.Seat}</span></div>
				</div>
				<div class="col">
					<div class="field"><span class="label">Fuel</span><span class="value">{Math.round(vehicle.Fuel ?? 0)}%</span></div>
					<div class="field"><span class="label">Engine Damage</span><span class="value">{damagePct(vehicle.Damage?.Engine)}%</span></div>
					<div class="field"><span class="label">Body Damage</span><span class="value">{damagePct(vehicle.Damage?.Body)}%</span></div>
					{#if vehicle.DamagedParts}
						<div class="field"><span class="label">Axle</span><span class="value">{vehicle.DamagedParts.Axle ?? 100}%</span></div>
						<div class="field"><span class="label">Radiator</span><span class="value">{vehicle.DamagedParts.Radiator ?? 100}%</span></div>
						<div class="field"><span class="label">Transmission</span><span class="value">{vehicle.DamagedParts.Transmission ?? 100}%</span></div>
						<div class="field"><span class="label">Fuel Injectors</span><span class="value">{vehicle.DamagedParts.FuelInjectors ?? 100}%</span></div>
						<div class="field"><span class="label">Brakes</span><span class="value">{vehicle.DamagedParts.Brakes ?? 100}%</span></div>
						<div class="field"><span class="label">Clutch</span><span class="value">{vehicle.DamagedParts.Clutch ?? 100}%</span></div>
						<div class="field"><span class="label">Electronics</span><span class="value">{vehicle.DamagedParts.Electronics ?? 100}%</span></div>
					{/if}
				</div>
			</div>
		</div>

		{#if adminState.permissionLevel >= 90}
			<div class="bottom-actions">
				<ActionButton label="Explode" variant="danger" onclick={() => onAction('explode')} />
				<ActionButton label="Customs" onclick={() => onAction('customs')} />
			</div>
		{/if}
	{/if}
</div>

<style>
	.page {
		padding: 2vh 1.5vw;
		height: 100%;
		display: flex;
		flex-direction: column;
		position: relative;
	}

	.scroll {
		flex: 1;
		min-height: 0;
		overflow-y: auto;
	}

	.error-wrap {
		position: absolute;
		inset: 0;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 1.4vh;
	}

	.actions {
		display: flex;
		flex-wrap: wrap;
		gap: 0.6vw;
		margin-bottom: 1.6vh;
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

	.grid.compact {
		flex-direction: column;
		gap: 1.2vh;
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

	.bottom-actions {
		flex-shrink: 0;
		display: flex;
		justify-content: center;
		gap: 0.7vw;
		padding-top: 1.4vh;
	}
</style>
