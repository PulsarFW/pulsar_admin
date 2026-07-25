import type {
	AdminUser,
	ActionResult,
	CharacterSearchResult,
	CurrentVehicleAction,
	DisconnectedPlayerListItem,
	DoorEntry,
	DoorLeaf,
	ItemCatalogEntry,
	JobCatalogEntry,
	PlayerAction,
	PlayerDetail,
	PlayerHistory,
	PlayerListItem,
	VehicleAction,
	VehicleDetail,
	VehicleListItem,
} from './types';
import {
	MOCK_CHARACTERS,
	MOCK_DISCONNECTED,
	MOCK_DOORS,
	MOCK_ITEMS,
	MOCK_JOBS,
	MOCK_PLAYERS,
	MOCK_PLAYER_DETAIL,
	MOCK_PLAYER_HISTORY,
	MOCK_VEHICLES,
	MOCK_VEHICLE_DETAIL,
} from './mockData';

const RESOURCE_NAME = 'pulsar_admin';

async function send(event: string, data: unknown = {}): Promise<void> {
	if (import.meta.env.DEV) {
		window.dispatchEvent(new CustomEvent('nui:send', { detail: { event, data } }));
		return;
	}
	try {
		await fetch(`https://${RESOURCE_NAME}/${event}`, {
			method: 'post',
			headers: { 'Content-Type': 'application/json; charset=UTF-8' },
			body: JSON.stringify(data),
		});
	} catch {
		// Expected to fail outside the actual NUI browser
	}
}

async function sendJson<T>(event: string, data: unknown, devValue: T): Promise<T> {
	if (import.meta.env.DEV) {
		window.dispatchEvent(new CustomEvent('nui:send', { detail: { event, data } }));
		return devValue;
	}
	try {
		const res = await fetch(`https://${RESOURCE_NAME}/${event}`, {
			method: 'post',
			headers: { 'Content-Type': 'application/json; charset=UTF-8' },
			body: JSON.stringify(data),
		});
		return (await res.json()) as T;
	} catch {
		return devValue;
	}
}

export const Nui = {
	close: () => send('Close'),
	stopAllAttach: () => send('StopAllAttach'),
	toggleInvisible: () => send('ToggleInvisible'),
	toggleIds: () => send('ToggleIDs'),
	// additive callback, same server-checked path as the /noclip chat command, just reachable from the panel now
	toggleNoclip: () => send('ToggleNoclip'),

	getPlayerList: (disconnected: boolean) =>
		sendJson<(PlayerListItem | DisconnectedPlayerListItem)[] | null>(
			'GetPlayerList',
			{ disconnected },
			disconnected ? MOCK_DISCONNECTED : MOCK_PLAYERS,
		),
	getPlayer: (source: number) => sendJson<PlayerDetail | null>('GetPlayer', source, MOCK_PLAYER_DETAIL),
	getCurrentVehicle: () => sendJson<VehicleDetail | false>('GetCurrentVehicle', {}, MOCK_VEHICLE_DETAIL),
	getVehicleList: () => sendJson<VehicleListItem[] | null>('GetVehicleList', {}, MOCK_VEHICLES),
	getVehicle: (entity: number) => sendJson<VehicleDetail | null>('GetVehicle', entity, MOCK_VEHICLE_DETAIL),
	getAllPlayersByCharacter: (term: string, page: number) =>
		sendJson<{ players: CharacterSearchResult[]; pages: number } | null>('GetAllPlayersByCharacter', { term, page }, MOCK_CHARACTERS),
	getPlayerHistory: () => sendJson<PlayerHistory | null>('GetPlayerHistory', {}, MOCK_PLAYER_HISTORY),

	actionPlayer: (targetSource: number, action: PlayerAction) =>
		sendJson<ActionResult | null>('ActionPlayer', { targetSource, action }, { success: true, message: `${action} ok` }),
	kickPlayer: (targetSource: number, reason: string) =>
		sendJson<ActionResult | null>('KickPlayer', { targetSource, reason }, { success: true }),
	banPlayer: (targetSource: number, reason: string, length: number) =>
		sendJson<ActionResult | null>('BanPlayer', { targetSource, reason, length }, { success: true }),
	getItemsCatalog: () => sendJson<ItemCatalogEntry[] | null>('GetItemsCatalog', {}, MOCK_ITEMS),
	giveItem: (targetSource: number, item: string, count: number, ammo?: number, scratched?: boolean) =>
		sendJson<ActionResult | null>('GiveItem', { targetSource, item, count, ammo, scratched }, { success: true }),
	getJobsCatalog: () => sendJson<JobCatalogEntry[] | null>('GetJobsCatalog', {}, MOCK_JOBS),
	setJob: (targetSource: number, jobId: string, workplaceId: string | undefined, gradeId: string) =>
		sendJson<ActionResult | null>('SetJob', { targetSource, jobId, workplaceId, gradeId }, { success: true }),
	removeJob: (targetSource: number, jobId: string) => sendJson<ActionResult | null>('RemoveJob', { targetSource, jobId }, { success: true }),
	actionVehicle: (model: number, target: number, action: VehicleAction) =>
		sendJson<ActionResult | null>('ActionVehicle', { model, target, action }, { success: true, message: `${action} ok` }),
	currentVehicleAction: (action: CurrentVehicleAction) =>
		sendJson<ActionResult | null>('CurrentVehicleAction', { action }, { success: true, message: `${action} ok` }),
	getDoorsCatalog: () => sendJson<DoorEntry[] | null>('GetDoorsCatalog', {}, MOCK_DOORS),
	createDoor: (door: DoorEntry) => sendJson<ActionResult | null>('CreateDoor', door, { success: true }),
	editDoor: (dbId: number, door: Partial<DoorEntry>) => sendJson<ActionResult | null>('EditDoor', { dbId, door }, { success: true }),
	removeDoor: (dbId: number) => sendJson<ActionResult | null>('RemoveDoor', { dbId }, { success: true }),
	teleportToDoor: (dbId: number) => sendJson<ActionResult | null>('TeleportToDoor', { dbId }, { success: true }),
	// client-local raycast picker, no server round-trip - returns false if the admin cancels
	pickDoorInWorld: () =>
		sendJson<DoorLeaf | false>('PickDoorInWorld', {}, { model: -147325430, coords: { x: 0, y: 0, z: 0 }, heading: 0 }),
	// client-local, just grabs the admin's current ped position/heading - no raycast involved
	captureZonePosition: () =>
		sendJson<{ x: number; y: number; z: number; heading: number } | false>('CaptureZonePosition', {}, { x: 0, y: 0, z: 0, heading: 0 }),

	// registered Lua-side but never actually called by this UI, no button wires to them, kept for contract completeness
	openInventory: (player: number) => send('openinventory', { player }),
	openStash: (stashId: string | number) => send('openstash', { stashId }),
	openTrunk: (vin: string) => send('opentrunk', { vin }),
};

export interface UserDataMessage {
	user: AdminUser;
	permission: string;
	permissionName: string;
	permissionLevel: number;
}
