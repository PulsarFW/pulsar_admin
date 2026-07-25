return {
	Ban = {
		maxDays = 90, -- absolute cap on any ban length (admins)
		staffMaxDays = 7, -- cap on ban length staff (non-admin) can issue
	},

	Dashboard = {
		maxSamples = 12, -- historical player-count data points retained for the graph
	},

	CharacterSearch = {
		perPage = 10, -- admin panel character search page size
	},

	VehicleAction = {
		minPermissionLevel = 90, -- GetLevel() threshold required to use current-vehicle admin actions
	},
}
