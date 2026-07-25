// Mirrors the exact shapes server/callbacks.lua's Admin:* callbacks return,
// as consumed via client/nui.lua's RegisterNUICallback handlers

export interface AdminUser {
	Source: number;
	Name: string;
	AccountID: number;
	Identifier: string;
	Groups?: number[];
	Discord?: string;
	Mention?: string;
	Avatar?: string;
}

export interface PlayerListItem {
	AccountID: number;
	Source: number;
	Name: string;
	Character?: { First: string; Last: string; SID: number };
}

export interface DisconnectedPlayerListItem extends PlayerListItem {
	DisconnectedTime: number;
	Reconnected?: number;
	Reason?: string;
}

export interface Coords {
	x: number;
	y: number;
	z: number;
}

export interface PlayerJobEntry {
	Id: string;
	Name: string;
	Hidden?: boolean;
	Workplace?: { Id: string; Name: string };
	Grade: { Id: string; Name: string; Level: number };
	/** cumulative minutes worked on this job, across every duty session ever clocked, from the Salary ledger */
	TotalMinutes: number;
	OnDuty: boolean;
}

export interface PlayerDetail {
	AccountID: number;
	Source: number;
	Name: string;
	Level: number;
	Identifier: string;
	StaffGroup?: string;
	Character?: { First: string; Last: string; SID: number; DOB: number; Phone?: string | number; Coords?: Coords; Jobs?: PlayerJobEntry[] };
	Disconnected?: boolean;
	DisconnectedTime?: number;
	Reconnected?: number;
	Reason?: string;
}

export interface CharacterSearchResult {
	First: string;
	Last: string;
	SID: number;
	User?: string;
	/** Present (a live Source number) only if this character is currently online */
	Online?: number;
}

export interface VehicleListItem {
	OwnerId: number | string;
	Entity: number;
	Plate: string;
	Make?: string;
	Model?: string;
	VIN: string;
}

export interface VehicleDamage {
	Engine?: number;
	Body?: number;
}

export interface VehicleDamagedParts {
	Axle?: number;
	Radiator?: number;
	Transmission?: number;
	FuelInjectors?: number;
	Brakes?: number;
	Clutch?: number;
	Electronics?: number;
}

export interface VehicleDetail {
	Make?: string;
	Model?: string;
	VIN: string;
	Owned?: boolean;
	Owner?: { Id: number | string; Type: number };
	Plate: string;
	Value?: number;
	Entity: number;
	EntityModel: number;
	Coords?: Coords;
	Heading?: number;
	Fuel?: number;
	Damage?: VehicleDamage;
	DamagedParts?: VehicleDamagedParts;
	/** Only present on GetCurrentVehicle's response */
	Seat?: number;
}

export interface PlayerHistoryBucket {
	count: number;
	time: number;
}

export interface PlayerHistory {
	current: number;
	max: number;
	queue: number;
	history: PlayerHistoryBucket[];
}

export interface ActionResult {
	success?: boolean;
	message?: string;
}

export interface ItemCatalogEntry {
	name: string;
	label: string;
	type: number;
	/** type 2 (weapon) only - throwables (grenades etc) stack like a normal item, real firearms are always a single instance */
	isThrowable?: boolean;
}

export interface JobGrade {
	Id: string;
	Name: string;
	Level: number;
}

export interface JobWorkplace {
	Id: string;
	Name: string;
	Grades: JobGrade[];
}

export interface JobCatalogEntry {
	Id: string;
	Name: string;
	/** Present when the job has no sub-workplaces - grades apply directly */
	Grades?: JobGrade[];
	/** Present when the job is split into workplaces (e.g. multiple gang/company branches), each with its own grades */
	Workplaces?: JobWorkplace[];
}

export type DoorRestrictionType = 'job' | 'character' | 'propertyData';

export interface DoorRestriction {
	type: DoorRestrictionType;
	job?: string;
	workplace?: string | false;
	gradeLevel?: number;
	jobPermission?: boolean | string;
	reqDuty?: boolean;
	SID?: number;
	key?: string;
	value?: string;
}

export interface DoorLeaf {
	model: number | string;
	coords: { x: number; y: number; z: number };
	heading?: number;
}

export interface DoorGarageZone {
	x: number;
	y: number;
	z: number;
	heading: number;
	length: number;
	width: number;
	minZ: number;
	maxZ: number;
}

export interface DoorEntry {
	/** numeric DB id, the door's real identity - always present once created */
	dbId?: number;
	/** stable string alias other resources call plsr.Doors:* with, optional */
	identifier?: string;
	type: 'standard' | 'garage';
	category: string;
	label?: string;
	/** one leaf = a normal door, two = a double door that toggles both leaves together */
	doors: DoorLeaf[];
	locked: boolean;
	autoRate?: number;
	autoDist?: number;
	holdOpen?: boolean;
	special?: boolean;
	maxDist?: number;
	canLockpick?: boolean;
	restricted?: DoorRestriction[];
	/** only meaningful when type is 'garage' - the polyzone that lets the keyfob action detect the player is nearby */
	garageZone?: DoorGarageZone;
}

export type PlayerAction = 'goto' | 'bring' | 'heal' | 'attach' | 'marker';
export type VehicleAction = 'fuel' | 'delete' | 'locks' | 'sitinside' | 'explode' | 'repair' | 'repair_full' | 'repair_engine' | 'stall';
export type CurrentVehicleAction = 'repair' | 'repair_full' | 'repair_engine' | 'explode' | 'alarm' | 'fuel' | 'customs';
