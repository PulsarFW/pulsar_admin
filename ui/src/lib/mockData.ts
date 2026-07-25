// dev-mode fallback data, returned by nui.ts's request/response wrappers when previewing in a plain browser
// or if a real fetch ever fails, one payload per request type

import type {
	CharacterSearchResult,
	DisconnectedPlayerListItem,
	DoorEntry,
	ItemCatalogEntry,
	JobCatalogEntry,
	PlayerDetail,
	PlayerHistory,
	PlayerListItem,
	VehicleDetail,
	VehicleListItem,
} from './types';

export const MOCK_PLAYERS: PlayerListItem[] = [
	{ AccountID: 25, Source: 10, Name: 'Dr Nick', Character: { First: 'Walter', Last: 'Western', SID: 420 } },
	{ AccountID: 16, Source: 8, Name: 'Panda', Character: { First: 'Willy', Last: 'Western', SID: 180 } },
	{ AccountID: 3, Source: 14, Name: 'Viper' },
	{ AccountID: 12, Source: 5, Name: 'Echo' },
	{ AccountID: 8, Source: 17, Name: 'Nova', Character: { First: 'Anna', Last: 'Jordan', SID: 204 } },
	{ AccountID: 6, Source: 2, Name: 'Shadow', Character: { First: 'Tyler', Last: 'Davis', SID: 98 } },
];

export const MOCK_DISCONNECTED: DisconnectedPlayerListItem[] = [
	{
		AccountID: 25,
		Source: 10,
		Name: 'Dr Nick',
		Character: { First: 'Walter', Last: 'Western', SID: 420 },
		DisconnectedTime: Math.floor(Date.now() / 1000) - 3600,
		Reason: 'Exiting',
	},
	{
		AccountID: 16,
		Source: 8,
		Name: 'Panda',
		Character: { First: 'Willy', Last: 'Western', SID: 180 },
		DisconnectedTime: Math.floor(Date.now() / 1000) - 7200,
		Reconnected: 2,
		Reason: 'Timed Out',
	},
];

export const MOCK_PLAYER_DETAIL: PlayerDetail = {
	AccountID: 25,
	Source: 10,
	Name: 'Dr Nick',
	Level: 20,
	Identifier: '789723918798237',
	StaffGroup: 'Staff',
	Character: {
		First: 'Walter',
		Last: 'Western',
		SID: 420,
		DOB: 662687999000,
		Phone: '555-0100',
		Coords: { x: 1000.123, y: 200.5, z: 30.9 },
		Jobs: [
			{
				Id: 'police',
				Name: 'Police',
				Workplace: { Id: 'lspd', Name: 'Los Santos Police Department' },
				Grade: { Id: 'officer', Name: 'Officer', Level: 25 },
				TotalMinutes: 742,
				OnDuty: true,
			},
			{
				Id: 'unemployed',
				Name: 'Unemployed',
				Grade: { Id: 'civilian', Name: 'Civilian', Level: 1 },
				TotalMinutes: 0,
				OnDuty: false,
			},
		],
	},
	Disconnected: false,
};

export const MOCK_VEHICLES: VehicleListItem[] = [
	{ OwnerId: 'police', Entity: 101, Plate: 'TWAT', Make: 'Vapid', Model: 'Interceptor', VIN: 'RWAAAAAAAAAAAAAAAAAAAAAA' },
	{ OwnerId: 25, Entity: 102, Plate: 'MYCAR', Make: 'Bravado', Model: 'Buffalo', VIN: 'RWBBBBBBBBBBBBBBBBBBBBBB' },
];

export const MOCK_VEHICLE_DETAIL: VehicleDetail = {
	Make: 'Bravado',
	Model: 'Buffalo',
	VIN: 'RWBBBBBBBBBBBBBBBBBBBBBB',
	Owned: true,
	Owner: { Id: 25, Type: 1 },
	Plate: 'MYCAR',
	Value: 42000,
	Entity: 102,
	EntityModel: 111111,
	Coords: { x: 1000.12, y: 200.5, z: 30.9 },
	Heading: 187.4,
	Fuel: 76,
	Damage: { Engine: 900, Body: 950 },
	DamagedParts: { Axle: 100, Radiator: 95, Transmission: 100, FuelInjectors: 100, Brakes: 100, Clutch: 100, Electronics: 100 },
	Seat: -1,
};

export const MOCK_CHARACTERS: { players: CharacterSearchResult[]; pages: number } = {
	players: [
		{ First: 'Walter', Last: 'Western', SID: 420, User: 'Dr Nick', Online: 10 },
		{ First: 'Willy', Last: 'Western', SID: 180, User: 'Panda' },
	],
	pages: 1,
};

export const MOCK_ITEMS: ItemCatalogEntry[] = [
	{ name: 'water', label: 'Water Bottle', type: 1 },
	{ name: 'sandwich_blt', label: 'BLT Sandwich', type: 1 },
	{ name: 'bandage', label: 'Bandage', type: 1 },
	{ name: 'WEAPON_PISTOL', label: 'Pistol', type: 2 },
	{ name: 'WEAPON_COMBATPISTOL', label: 'Combat Pistol', type: 2 },
	{ name: 'repairkit', label: 'Repair Kit', type: 1 },
	{ name: 'phone', label: 'Phone', type: 1 },
	{ name: 'lockpick', label: 'Lockpick', type: 1 },
];

export const MOCK_JOBS: JobCatalogEntry[] = [
	{
		Id: 'police',
		Name: 'Los Santos Police Department',
		Workplaces: [
			{
				Id: 'lspd',
				Name: 'LSPD',
				Grades: [
					{ Id: 'cadet', Name: 'Cadet', Level: 1 },
					{ Id: 'officer', Name: 'Officer', Level: 25 },
					{ Id: 'sergeant', Name: 'Sergeant', Level: 50 },
					{ Id: 'chief', Name: 'Chief', Level: 90 },
				],
			},
		],
	},
	{
		Id: 'unemployed',
		Name: 'Unemployed',
		Grades: [{ Id: 'civilian', Name: 'Civilian', Level: 1 }],
	},
];

export const MOCK_DOORS: DoorEntry[] = [
	{
		dbId: 1,
		identifier: 'bennys_office_main',
		type: 'standard',
		category: 'businesses',
		label: 'bennys office main',
		doors: [{ model: -147325430, coords: { x: -207.9, y: -1310.6, z: 30.9 }, heading: 0 }],
		locked: true,
		restricted: [{ type: 'job', job: 'bennys', workplace: false, gradeLevel: 0, jobPermission: false, reqDuty: false }],
	},
	{
		dbId: 2,
		identifier: 'mrpd_garage_enter',
		type: 'garage',
		category: 'police',
		label: 'mrpd garage enter',
		doors: [{ model: -1234567, coords: { x: 452.3, y: -1000.78, z: 26.74 } }],
		locked: true,
		special: true,
		restricted: [{ type: 'job', job: 'police', workplace: false, gradeLevel: 0, jobPermission: false, reqDuty: true }],
	},
	{
		dbId: 3,
		identifier: 'lombank_hidden_entrance',
		type: 'standard',
		category: 'robberies',
		label: 'lombank hidden entrance',
		doors: [{ model: -9988776, coords: { x: 149.9, y: -1042.2, z: 29.4 } }],
		locked: true,
		restricted: [],
	},
];

export const MOCK_PLAYER_HISTORY: PlayerHistory = {
	current: 34,
	max: 64,
	queue: 2,
	history: Array.from({ length: 8 }, (_, i) => ({
		time: Math.floor(Date.now() / 1000) - (8 - i) * 1800,
		count: 20 + Math.round(Math.sin(i) * 10) + i,
	})),
};
