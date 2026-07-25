local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

PER_PAGE = config.CharacterSearch.perPage

local fuckingCharProjection = {
    SID = 1,
    First = 1,
    Last = 1,
    DOB = 1,
    BankAccount = 1,
    Jobs = 1,
    Cash = 1,
    LastPlayed = 1,
    Phone = 1,
    Deleted = 1,
    User = 1,
}

function GetSpawnLocations()
    local p = promise.new()

    plsr.Database:Query("SELECT `id`, `data` FROM `locations` WHERE `type` = 'spawn'", nil, function(success, rows)
        if not success or #rows == 0 then
            p:resolve(false)
            return
        end
        local results = {}
        for k, row in ipairs(rows) do
            local ok, v = pcall(json.decode, row.data)
            if ok and type(v) == "table" then
                v._id = row.id
                table.insert(results, v)
            end
        end
        p:resolve(#results > 0 and results or false)
    end)

    local res = Citizen.Await(p)
    return res
end

function RegisterCallbacks()
    plsr.Callbacks:RegisterServerCallback('Admin:GetPlayerList', function(source, data, cb)
        CreateThread(function()
            local player = plsr.Fetch:Source(source)
            if player and player.Permissions:IsStaff() then
                local data = {}
                local activePlayers = plsr.Fetch:All()
    
                for k, v in pairs(activePlayers) do
                    if v ~= nil and v:GetData('AccountID') then
                        table.insert(data, {
                            Source = v:GetData('Source'),
                            Name = v:GetData('Name'),
                            AccountID = v:GetData('AccountID'),
                            Character = v:GetData('Character'),
                        })
                    end
                end
                cb(data)
            else
                cb(false)
            end
        end)
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:GetDisconnectedPlayerList', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if player and player.Permissions:IsStaff() then
            local rDs = plsr.RecentDisconnects
            cb(rDs)
        else
            cb(false)
        end
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:GetPlayer', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if player and player.Permissions:IsStaff() then
            local target = plsr.Fetch:Source(data)

            if target then
                local staffGroupName = false
                if target.Permissions:IsStaff() then
                    local highestLevel = 0
                    for k, v in ipairs(target:GetData('Groups')) do
                        if plsr.Config.Groups[tostring(v)] ~= nil and (type(plsr.Config.Groups[tostring(v)].Permission) == 'table') then
                            if plsr.Config.Groups[tostring(v)].Permission.Level > highestLevel then
                                highestLevel = plsr.Config.Groups[tostring(v)].Permission.Level
                                staffGroupName = plsr.Config.Groups[tostring(v)].Name
                            end
                        end
                    end
                end

                local pPed = GetPlayerPed(target:GetData('Source'))
                local coords = GetEntityCoords(pPed)
                local inVehicle = GetVehiclePedIsIn(pPed, false)
                if inVehicle and inVehicle > 0 then
                    local ent = plsr.State.Entity(inVehicle)

                    local isDriver = GetPedInVehicleSeat(inVehicle, -1) == pPed

                    inVehicle = {
                        Entity = inVehicle,
                        VIN = ent.VIN,
                        Plate = GetVehicleNumberPlateText(inVehicle),
                        Make = ent.Make,
                        Model = ent.Model,
                        Driver = isDriver,
                    }
                end

                local char = plsr.Fetch:CharacterSource(data)

                local jobsList = {}
                if char then
                    local salaryData = char:GetData('Salary') or {}
                    local currentDuty = plsr.Jobs.Duty:Get(data)
                    for i, j in ipairs(char:GetData('Jobs') or {}) do
                        table.insert(jobsList, {
                            Id = j.Id,
                            Name = j.Name,
                            Hidden = j.Hidden,
                            Workplace = j.Workplace,
                            Grade = j.Grade,
                            TotalMinutes = salaryData[j.Id] and salaryData[j.Id].minutes or 0,
                            OnDuty = currentDuty and currentDuty.Id == j.Id or false,
                        })
                    end
                end

                local p = promise.new()
                local sql = "SELECT `id`, `data` FROM `characters` WHERE `account` = ?"
                local params = { target:GetData('AccountID') }
                if char then
                    sql = sql .. " AND `sid` <> ?"
                    table.insert(params, char:GetData("SID"))
                end

                plsr.Database:Query(sql, params, function(success, rows)
                    if not success then
                        p:resolve({})
                        return
                    end
                    local results = {}
                    for k, row in ipairs(rows) do
                        local ok, v = pcall(json.decode, row.data)
                        if ok and type(v) == "table" then
                            v._id = row.id
                            table.insert(results, v)
                        end
                    end
                    p:resolve(results)
                end)

                local chars = Citizen.Await(p)

                local tData = {
                    Source = target:GetData('Source'),
                    Name = target:GetData('Name'),
                    GameName = target:GetData('GameName'),
                    AccountID = target:GetData('AccountID'),
                    Identifier = target:GetData('Identifier'),
                    Discord = target:GetData("Discord"),
                    Mention = target:GetData("Mention"),
                    Avatar = target:GetData("Avatar"),
                    Level = target.Permissions:GetLevel(),
                    Groups = target:GetData('Groups'),
                    StaffGroup = staffGroupName,
                    Character = char and {
                        First = char:GetData('First'),
                        Last = char:GetData('Last'),
                        SID = char:GetData('SID'),
                        DOB = char:GetData('DOB'),
                        Phone = char:GetData('Phone'),
                        Jobs = jobsList,
                        Coords = {
                            x = coords.x,
                            y = coords.y,
                            z = coords.z
                        }
                    } or false,
                    Characters = chars,
                    Vehicle = inVehicle,
                }

                cb(tData)
            else
                local rDs = plsr.RecentDisconnects
                for k, v in ipairs(rDs) do
                    if v.Source == data then
                        local tData = v

                        if tData.IsStaff then
                            local highestLevel = 0
                            for k, v in ipairs(tData.Groups) do
                                if plsr.Config.Groups[tostring(v)] ~= nil and (type(plsr.Config.Groups[tostring(v)].Permission) == 'table') then
                                    if plsr.Config.Groups[tostring(v)].Permission.Level > highestLevel then
                                        highestLevel = plsr.Config.Groups[tostring(v)].Permission.Level
                                        tData.StaffGroup = plsr.Config.Groups[tostring(v)].Name
                                    end
                                end
                            end
                        end

                        tData.Disconnected = true
                        tData.Reconnected = false

                        for k, v in pairs(plsr.Fetch:All()) do
                            if v:GetData('AccountID') == tData.AccountID then
                                tData.Reconnected = k
                            end
                        end

                        cb(tData)
                        return
                    end
                end

                cb(false)
            end
        else
            cb(false)
        end
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:GetAllPlayersByCharacter', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if player and player.Permissions:IsStaff() then
            local whereClause = ""
            local whereParams = {}

            if #data.term > 0 then
                whereClause = " WHERE (`sid` = ? OR CONCAT(JSON_UNQUOTE(JSON_EXTRACT(`data`, '$.First')), ' ', JSON_UNQUOTE(JSON_EXTRACT(`data`, '$.Last'))) LIKE ?)"
                whereParams = { tonumber(data.term), "%" .. data.term .. "%" }
            end

            local countParams = { table.unpack(whereParams) }
            plsr.Database:Scalar("SELECT COUNT(*) FROM `characters`" .. whereClause, countParams, function(countSuccess, total)
                if not countSuccess then
                    cb(false)
                    return
                end

                local pageParams = { table.unpack(whereParams) }
                table.insert(pageParams, PER_PAGE)
                table.insert(pageParams, (data.page - 1) * PER_PAGE)

                plsr.Database:Query(
                    "SELECT `id`, `data` FROM `characters`" .. whereClause .. " ORDER BY `sid` DESC LIMIT ? OFFSET ?",
                    pageParams,
                    function(success, rows)
                        if not success then
                            cb(false)
                            return
                        end

                        local resultData = {}
                        for k, row in ipairs(rows) do
                            local ok, v = pcall(json.decode, row.data)
                            if ok and type(v) == "table" then
                                v._id = row.id

                                local isOnline = plsr.Fetch:PlayerData("AccountID", v.User)
                                if isOnline then
                                    v.Online = isOnline:GetData("Source")
                                end

                                table.insert(resultData, v)
                            end
                        end

                        cb({
                            players = resultData,
                            pages = total,
                        })
                    end
                )
            end)
        else
            cb(false)
        end
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:BanPlayer', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if player and data.targetSource and type(data.length) == "number" and type(data.reason) == "string" and data.length >= -1 and data.length <= config.Ban.maxDays then
            if player.Permissions:IsAdmin() or (player.Permissions:IsStaff() and data.length > 0 and data.length <= config.Ban.staffMaxDays) then
                cb(plsr.Punishment.Ban:Source(data.targetSource, data.length, data.reason, source))
            else
                cb(false)
            end
        else
            cb(false)
        end
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:KickPlayer', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if player and data.targetSource and type(data.reason) == "string" and player.Permissions:IsStaff() then
            cb(plsr.Punishment:Kick(data.targetSource, data.reason, source))
        else
            cb(false)
        end
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:GetItemsCatalog', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if not (player and player.Permissions:IsStaff()) then
            cb(nil)
            return
        end
        local list = {}
        for name, item in pairs(plsr.Inventory.Items:GetCatalog()) do
            table.insert(list, { name = name, label = item.label or name, type = item.type, isThrowable = item.isThrowable or nil })
        end
        cb(list)
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:GiveItem', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if not (player and player.Permissions:IsStaff() and data.targetSource and type(data.item) == "string" and tonumber(data.count)) then
            cb({ success = false, message = "Invalid Request" })
            return
        end

        local itemData = plsr.Inventory.Items:GetData(data.item)
        if not itemData then
            cb({ success = false, message = "Item Not Found" })
            return
        end

        local targetChar = plsr.Fetch:CharacterSource(data.targetSource)
        if not targetChar then
            cb({ success = false, message = "Target Not Logged In" })
            return
        end

        local sid = targetChar:GetData("SID")
        local count = math.max(1, math.floor(tonumber(data.count)))

        if itemData.type == 2 then -- weapon
            if itemData.isThrowable then -- grenades etc, stacks like a normal item
                plsr.Inventory:AddItem(sid, data.item, count, { ammo = 1, clip = 0 }, 1)
            else -- real firearm: always a single instance, carries its own ammo/scratched state
                local ammo = tonumber(data.ammo) or 0
                plsr.Inventory:AddItem(sid, data.item, 1, { ammo = ammo, clip = 0, Scratched = data.scratched or nil }, 1)
            end
        else
            plsr.Inventory:AddItem(sid, data.item, count, {}, 1)
        end

        plsr.Logger:Warn("Admin", string.format("%s Gave x%s %s To State ID %s", player:GetData("Name"), count, data.item, sid))

        cb({ success = true })
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:GetJobsCatalog', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if not (player and player.Permissions:IsStaff()) then
            cb(nil)
            return
        end
        local list = {}
        for id, job in pairs(plsr.Jobs:GetAll()) do
            if not job.Hidden then
                table.insert(list, {
                    Id = id,
                    Name = job.Name,
                    Grades = job.Grades,
                    Workplaces = job.Workplaces,
                })
            end
        end
        cb(list)
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:SetJob', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if not (player and data.targetSource and type(data.jobId) == "string" and player.Permissions:IsStaff()) then
            cb({ success = false, message = "Invalid Request" })
            return
        end

        local target = plsr.Fetch:Source(data.targetSource)
        local isSelf = data.targetSource == source
        if not target or (not isSelf and player.Permissions:GetLevel() <= target.Permissions:GetLevel()) then
            cb({ success = false, message = "Insufficient Permissions" })
            return
        end

        local targetChar = plsr.Fetch:CharacterSource(data.targetSource)
        if not targetChar then
            cb({ success = false, message = "Target Not Logged In" })
            return
        end

        local sid = targetChar:GetData("SID")
        local success = plsr.Jobs:GiveJob(sid, data.jobId, data.workplaceId, data.gradeId, false)

        if success then
            plsr.Logger:Warn("Admin", string.format("%s Set State ID %s's Job To %s", player:GetData("Name"), sid, data.jobId))
        end

        cb({ success = success, message = not success and "Failed To Set Job" or nil })
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:RemoveJob', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if not (player and data.targetSource and type(data.jobId) == "string" and player.Permissions:IsStaff()) then
            cb({ success = false, message = "Invalid Request" })
            return
        end

        local target = plsr.Fetch:Source(data.targetSource)
        local isSelf = data.targetSource == source
        if not target or (not isSelf and player.Permissions:GetLevel() <= target.Permissions:GetLevel()) then
            cb({ success = false, message = "Insufficient Permissions" })
            return
        end

        local targetChar = plsr.Fetch:CharacterSource(data.targetSource)
        if not targetChar then
            cb({ success = false, message = "Target Not Logged In" })
            return
        end

        local sid = targetChar:GetData("SID")
        local success = plsr.Jobs:RemoveJob(sid, data.jobId)

        if success then
            plsr.Logger:Warn("Admin", string.format("%s Removed State ID %s's Job %s", player:GetData("Name"), sid, data.jobId))
        end

        cb({ success = success, message = not success and "Failed To Remove Job" or nil })
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:GetDoorsCatalog', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if not (player and player.Permissions:IsStaff()) then
            cb(nil)
            return
        end
        cb(plsr.Doors:GetAllDoors())
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:CreateDoor', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if not (player and player.Permissions:IsStaff() and data and type(data.doors) == "table" and data.doors[1]) then
            cb({ success = false, message = "Invalid Request" })
            return
        end

        local newId = plsr.Doors:CreateDoor(data)
        if newId then
            plsr.Logger:Warn("Admin", string.format("%s Created Door #%s (%s)", player:GetData("Name"), newId, data.identifier or data.label or "unnamed"))
        end

        cb({ success = newId and true or false, message = not newId and "Failed To Create Door" or nil })
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:EditDoor', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if not (player and player.Permissions:IsStaff() and data and data.dbId and data.door) then
            cb({ success = false, message = "Invalid Request" })
            return
        end

        local success = plsr.Doors:EditDoor(data.dbId, data.door)
        if success then
            plsr.Logger:Warn("Admin", string.format("%s Edited Door #%s", player:GetData("Name"), data.dbId))
        end

        cb({ success = success, message = not success and "Failed To Edit Door" or nil })
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:RemoveDoor', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if not (player and player.Permissions:IsStaff() and data and data.dbId) then
            cb({ success = false, message = "Invalid Request" })
            return
        end

        local success = plsr.Doors:RemoveDoor(data.dbId)
        if success then
            plsr.Logger:Warn("Admin", string.format("%s Removed Door #%s", player:GetData("Name"), data.dbId))
        end

        cb({ success = success, message = not success and "Failed To Remove Door" or nil })
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:TeleportToDoor', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if not (player and player.Permissions:IsStaff() and data and data.dbId) then
            cb({ success = false, message = "Invalid Request" })
            return
        end

        local door = plsr.Doors:GetDoor(data.dbId)
        local leaf = door and door.doors and door.doors[1]
        if not leaf then
            cb({ success = false, message = "Door Not Found" })
            return
        end

        local ped = GetPlayerPed(source)
        SetEntityCoords(ped, leaf.coords.x, leaf.coords.y, leaf.coords.z + 1.0)

        cb({ success = true, message = "Teleported To Door" })
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:ActionPlayer', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if player and data.action and data.targetSource and player.Permissions:IsStaff() then
            local target = plsr.Fetch:Source(data.targetSource)
            if target then
                local canFuckWith = player.Permissions:GetLevel() > target.Permissions:GetLevel()
                local notMe = player:GetData('Source') ~= target:GetData('Source')
                local wasSuccessful = false

                local targetChar = plsr.Fetch:CharacterSource(data.targetSource)
                if targetChar then
                    local playerPed = GetPlayerPed(player:GetData('Source'))
                    local targetPed = GetPlayerPed(target:GetData('Source'))
                    if data.action == 'bring' and canFuckWith and notMe then
                        local playerCoords = GetEntityCoords(playerPed)
                        plsr.Pwnzor.Players:TempPosIgnore(target:GetData("Source"))
                        SetEntityCoords(targetPed, playerCoords.x, playerCoords.y, playerCoords.z + 1.0)

                        cb({
                            success = true,
                            message = 'Brought Successfully'
                        })

                        wasSuccessful = true
                    elseif data.action == 'goto' then
                        local targetCoords = GetEntityCoords(targetPed)
                        SetEntityCoords(playerPed, targetCoords.x, targetCoords.y, targetCoords.z + 1.0)

                        cb({
                            success = true,
                            message = 'Teleported To Successfully'
                        })

                        wasSuccessful = true
                    elseif data.action == 'heal' then
                        if (notMe or player.Permissions:IsAdmin()) then
                            plsr.Callbacks:ClientCallback(targetChar:GetData("Source"), "Damage:Heal", true)
                            
                            cb({
                                success = true,
                                message = 'Healed Successfully'
                            })

                            wasSuccessful = true
                        else
                            cb({
                                success = false,
                                message = 'Can\'t Heal Yourself'
                            })
                        end
                    elseif data.action == 'attach' and (canFuckWith or player.Permissions:GetLevel() == 100) and notMe then
                        TriggerClientEvent('Admin:Client:Attach', source, target:GetData('Source'), GetEntityCoords(targetPed), {
                            First = targetChar:GetData("First"),
                            Last = targetChar:GetData("Last"),
                            SID = targetChar:GetData("SID"),
                            Account = target:GetData("AccountID"),
                        })

                        cb({
                            success = true,
                            message = 'Attached Successfully'
                        })

                        wasSuccessful = true
                    elseif data.action == 'marker' and (canFuckWith or player.Permissions:GetLevel() == 100) then
                        local targetCoords = GetEntityCoords(targetPed)
                        TriggerClientEvent('Admin:Client:Marker', source, targetCoords.x, targetCoords.y)
					else
						cb({
                            success = false,
                            message = 'An error has occured due to similar permissions.'
                        })
					end

                    if wasSuccessful then
                        plsr.Logger:Warn(
                            "Admin",
                            string.format(
                                "%s [%s] Used Staff Action %s On %s [%s] - Character %s %s (%s)", 
                                player:GetData("Name"),
                                player:GetData("AccountID"),
                                string.upper(data.action),
                                target:GetData("Name"),
                                target:GetData("AccountID"),
                                targetChar:GetData('First'),
                                targetChar:GetData('Last'),
                                targetChar:GetData('SID')
                            ),
                            {
                                console = true,
                                file = false,
                                database = true,
                                discord = {
                                    embed = true,
                                    type = "error",
                                    webhook = GetConvar("discord_admin_webhook", ''),
                                },
                            }
                        )
                    end
                    return
                end
            end
        end

        cb(false)
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:GetVehicleList', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if player and player.Permissions:IsStaff() then
            local tData = {}
            local allVehicles = plsr.Vehicles.Owned.GetAllActive()
            for k, v in pairs(allVehicles) do
                local entityId = v:GetData("EntityId")
                local ent = plsr.State.Entity(entityId)
                if ent then
                    table.insert(tData, {
                        Entity = entityId,
                        VIN = ent.VIN,
                        Plate = GetVehicleNumberPlateText(entityId),
                        Make = ent.Make,
                        Model = ent.Model,
                        OwnerId = ent.Owner?.Id
                    })
                end
            end
            cb(tData)
        else
            cb(false)
        end
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:GetVehicle', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if player and player.Permissions:IsStaff() and data and DoesEntityExist(data) then
            local ent = plsr.State.Entity(data)

            local vehicleCoords = GetEntityCoords(data)
            local vehicleHeading = GetEntityHeading(data)

            local vData = {
                Make = ent.Make,
                Model = ent.Model,
                VIN = ent.VIN,
                Owned = ent.Owned,
                Owner = ent.Owner,
                Plate = ent.Plate,
                Value = ent.Value,
                Entity = data,
                EntityModel = GetEntityModel(data),
                Coords = {
                    x = vehicleCoords.x,
                    y = vehicleCoords.y,
                    z = vehicleCoords.z,
                },
                Heading = vehicleHeading,
                Fuel = ent.Fuel,
                Damage = ent.Damage,
                DamagedParts = ent.DamagedParts,
            }

            cb(vData)
        else
            cb(false)
        end
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:VehicleAction', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if player and data.action and player.Permissions:IsAdmin() and data.target and DoesEntityExist(data.target) then
            local veh = plsr.State.Entity(data.target)
            local netOwner = NetworkGetEntityOwner(data.target)

            if data.action == "fuel" then
                veh.Fuel = 100
            elseif data.action == "delete" then
                plsr.Vehicles:Delete(data.target, function() end)
            elseif data.action == "locks" then
                veh.Locked = not veh.Locked

                SetVehicleDoorsLocked(data.target, veh.Locked and 2 or 1)

                cb({
                    success = true,
                    message = veh.Locked and "Vehicle Locked" or "Vehicle Unlocked",
                })

                return
            elseif data.action == "sitinside" then
                local pPed = GetPlayerPed(source)
                local currentVehicle = GetVehiclePedIsIn(pPed, false)
                if currentVehicle == data.target then
                    cb({
                        success = false,
                        message = "Already In Vehicle!",
                    })

                    return
                end

                for i = -1, (data.numSeats - 2) do
                    if GetPedInVehicleSeat(data.target, i) <= 0 then
                        local vehCoords = GetEntityCoords(data.target)

                        SetEntityCoords(pPed, vehCoords.x, vehCoords.y, vehCoords.z - 25.0, true, false, false, false)
                        Wait(300)
                        SetPedIntoVehicle(pPed, data.target, i)

                        break
                    end
                end
            else
                if netOwner > 0 then
                    if data.action == "explode" then
                        TriggerClientEvent("NetSync:Client:Execute", netOwner, "NetworkExplodeVehicle", NetworkGetNetworkIdFromEntity(data.target), 1, 0)
                    elseif data.action == "repair" then
                        TriggerClientEvent("Vehicles:Client:Repair:Normal", netOwner, NetworkGetNetworkIdFromEntity(data.target))
                    elseif data.action == "repair_full" then
                        TriggerClientEvent("Vehicles:Client:Repair:Full", netOwner, NetworkGetNetworkIdFromEntity(data.target))
                    elseif data.action == "repair_engine" then
                        TriggerClientEvent("Vehicles:Client:Repair:Engine", netOwner, NetworkGetNetworkIdFromEntity(data.target))
                    elseif data.action == "stall" then
                        TriggerClientEvent("Admin:Client:Stall", netOwner, NetworkGetNetworkIdFromEntity(data.target))
                    else
                        cb({
                            success = false,
                            message = "Unknown Action"
                        })

                        return
                    end
                else
                    cb({
                        success = false,
                        message = "Cannot Execute RPC Action on This Vehicle At This Time!"
                    })

                    return
                end
            end

            plsr.Logger:Warn(
                "Admin",
                string.format(
                    "%s [%s] Used Vehicle Action %s on %s",
                    player:GetData("Name"),
                    player:GetData("AccountID"),
                    string.upper(data.action),
                    veh.VIN or "Unknown"
                ),
                {
                    console = true,
                    file = false,
                    database = true,
                    discord = {
                        embed = true,
                        type = "error",
                        webhook = GetConvar("discord_admin_webhook", ''),
                    },
                }
            )
            cb({
                success = true,
                message = "Success"
            })
        else
            cb(false)
        end
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:CurrentVehicleAction', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if player and data.action and player.Permissions:IsAdmin() and player.Permissions:GetLevel() >= config.VehicleAction.minPermissionLevel then
            plsr.Logger:Warn(
                "Admin",
                string.format(
                    "%s [%s] Used Vehicle Action %s",
                    player:GetData("Name"),
                    player:GetData("AccountID"),
                    string.upper(data.action)
                ),
                {
                    console = (player.Permissions:GetLevel() < 100),
                    file = false,
                    database = true,
                    discord = (player.Permissions:GetLevel() < 100) and {
                        embed = true,
                        type = "error",
                        webhook = GetConvar("discord_admin_webhook", ''),
                    } or false,
                }
            )
            cb(true)
        else
            cb(false)
        end
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:NoClip', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if player and player.Permissions:IsStaff() then
            plsr.Logger:Warn(
                "Admin",
                string.format(
                    "%s [%s] Used NoClip (State: %s)",
                    player:GetData("Name"),
                    player:GetData("AccountID"),
                    data?.active and 'On' or 'Off'
                ),
                {
                    console = true,
                    file = false,
                    database = true,
                    discord = {
                        embed = true,
                        type = "error",
                        webhook = GetConvar("discord_admin_webhook", ''),
                    },
                }
            )
            cb(true)
        else
            cb(false)
        end
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:UpdatePhonePerms', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if player.Permissions:IsAdmin() then
            local char = plsr.Fetch:CharacterSource(data.target)
            if char ~= nil then
                local cPerms = char:GetData("PhonePermissions")
                cPerms[data.app][data.perm] = data.state
                char:SetData("PhonePermissions", cPerms)
                cb(true)
            else
                cb(false)
            end
        else
            cb(false)
        end
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:ToggleInvisible', function(source, data, cb)
        local player = plsr.Fetch:Source(source)
        if player and player.Permissions:IsAdmin() then
            plsr.Logger:Warn(
                "Admin",
                string.format(
                    "%s [%s] Used Invisibility",
                    player:GetData("Name"),
                    player:GetData("AccountID")
                ),
                {
                    console = true,
                    file = false,
                    database = true,
                    discord = {
                        embed = true,
                        type = "error",
                        webhook = GetConvar("discord_admin_webhook", ''),
                    },
                }
            )

            TriggerClientEvent('Admin:Client:Invisible', source)
            cb(true)
        else
            cb(false)
        end
    end)

    plsr.Callbacks:RegisterServerCallback('Admin:OpenInventory', function(source, data, cb)        
        local player = plsr.Fetch:Source(source)
        if player and player.Permissions:IsAdmin() then
            plsr.Logger:Warn(
                "Admin",
                string.format(
                    "%s [%s] Viewed inventory of State ID %s",
                    player:GetData("Name"),
                    player:GetData("AccountID"),
                    data.player
                ),
                {
                    console = (player.Permissions:GetLevel() < 100),
                    file = false,
                    database = true,
                    discord = (player.Permissions:GetLevel() < 100) and {
                        embed = true,
                        type = "error",
                        webhook = GetConvar("discord_admin_webhook", ''),
                    } or false,
                }
            )
    
            plsr.Inventory:OpenSecondary(source, 1, data.player)
            cb(true)
        else
            cb(false)
        end
    end)
    
    plsr.Callbacks:RegisterServerCallback('Admin:OpenStash', function(source, data, cb)        
        local player = plsr.Fetch:Source(source)
        if player and player.Permissions:IsAdmin() then
            plsr.Logger:Warn(
                "Admin",
                string.format(
                    "%s [%s] Viewed stash %s",
                    player:GetData("Name"),
                    player:GetData("AccountID"),
                    data.stashId
                ),
                {
                    console = (player.Permissions:GetLevel() < 100),
                    file = false,
                    database = true,
                    discord = (player.Permissions:GetLevel() < 100) and {
                        embed = true,
                        type = "error",
                        webhook = GetConvar("discord_admin_webhook", ''),
                    } or false,
                }
            )
    
            plsr.Inventory:OpenSecondary(source, 13, string.format("stash:%s", data.stashId))
            cb(true)
        else
            cb(false)
        end
    end)
    
    plsr.Callbacks:RegisterServerCallback('Admin:OpenTrunk', function(source, data, cb)        
        local player = plsr.Fetch:Source(source)
        if player and player.Permissions:IsAdmin() then
            plsr.Logger:Warn(
                "Admin",
                string.format(
                    "%s [%s] Viewed trunk of vehicle %s",
                    player:GetData("Name"),
                    player:GetData("AccountID"),
                    data.vin
                ),
                {
                    console = (player.Permissions:GetLevel() < 100),
                    file = false,
                    database = true,
                    discord = (player.Permissions:GetLevel() < 100) and {
                        embed = true,
                        type = "error",
                        webhook = GetConvar("discord_admin_webhook", ''),
                    } or false,
                }
            )
    
            plsr.Inventory:OpenSecondary(source, 4, data.vin)
            cb(true)
        else
            cb(false)
        end
    end)

    -- Callbacks:RegisterServerCallback("Admin:Target:OpenPlyInv", function(source, target, cb)        
    --     local targetChar = plsr.Fetch:CharacterSource(target)

    --     if targetChar then
    --         cb({
    --             invType = 1,
    --             owner = targetChar:GetData("SID"),
    --         })
    --     else
    --         cb(false)
    --     end
    -- end)

end