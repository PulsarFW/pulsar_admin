/*
	Pulsar Admin content config.
	Server owners: for colors/fonts, edit theme.css instead.
*/

export type PageId =
	| 'dashboard'
	| 'players'
	| 'disconnected-players'
	| 'characters'
	| 'vehicles'
	| 'current-vehicle'
	| 'items'
	| 'jobs'
	| 'doors'
	| 'player'
	| 'vehicle'
	| 'error';

export interface NavLink {
	page: PageId;
	icon: string;
	label: string;
}

// Dev/Management get the admin list (adds Vehicles + Current Vehicle), everyone else gets the trimmed list
// Items/Jobs drop out entirely in compact mode, same as PlayerDetail's Give Item/Set Job buttons
export function navLinks(permission: string, compact: boolean): NavLink[] {
	const staff: NavLink[] = [
		{ page: 'dashboard', icon: 'house', label: 'Dashboard' },
		{ page: 'players', icon: 'user-large', label: permission === 'Dev' || permission === 'Management' ? 'Online Players' : 'Players' },
		{ page: 'disconnected-players', icon: 'user-large-slash', label: 'Disconnected Players' },
		{ page: 'characters', icon: 'people', label: 'Find Characters' },
	];

	const admin =
		permission === 'Dev' || permission === 'Management'
			? [
					...staff,
					{ page: 'vehicles' as const, icon: 'car', label: 'Active Owned Vehicles' },
					{ page: 'current-vehicle' as const, icon: 'car-side', label: 'Current Vehicle' },
					// doors control heist/business access, kept out of the general Items/Jobs staff tier below
					{ page: 'doors' as const, icon: 'door-open', label: 'Doors Database' },
				]
			: staff;

	if (compact) return admin;
	return [
		...admin,
		{ page: 'items', icon: 'boxes-stacked', label: 'Items Database' },
		{ page: 'jobs', icon: 'briefcase', label: 'Jobs Database' },
	];
}

export interface BanLengthOption {
	name: string;
	value: number;
	permissionLevel: number;
}

// real authorization-adjacent business logic, not something to redesign lightly
export const BAN_LENGTHS: BanLengthOption[] = [
	{ name: '1 Day', value: 1, permissionLevel: 0 },
	{ name: '2 Day', value: 2, permissionLevel: 0 },
	{ name: '3 Day', value: 3, permissionLevel: 20 },
	{ name: '7 Day', value: 7, permissionLevel: 20 },
	{ name: '14 Day', value: 14, permissionLevel: 99 },
	{ name: '30 Day', value: 30, permissionLevel: 99 },
	{ name: 'Permanent', value: -1, permissionLevel: 99 },
];

export const PLAYERS_PER_PAGE = 15;
export const CHARACTERS_PER_PAGE = 10;
export const VEHICLES_PER_PAGE = 32;
export const ITEMS_PER_PAGE = 20;
export const DOORS_PER_PAGE = 20;
export const POLL_INTERVAL_MS = 60 * 1000;

export const CURRENCY = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' });
