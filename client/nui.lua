local config = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()

_hasMenu = false

RegisterNetEvent('Admin:Client:Menu:RecievePermissionData', function(userData, permission, permissionName, permissionLevel)
    if not _hasMenu then
        _hasMenu = true

        SendNUIMessage({
            type = "SET_USERDATA",
            data = {
                user = userData,
                permission = permission,
                permissionName = permissionName,
                permissionLevel = permissionLevel,
            }
        })
    end
end)

function OpenMenu()
    if not _menuOpen and _hasMenu then
        _menuOpen = true
        SendNUIMessage({ type = "APP_SHOW" })
		SetNuiFocus(true, true)
    end
end

function CloseMenu()
    if _menuOpen then
        SendNUIMessage({ type = "APP_HIDE" })
		SetNuiFocus(false, false)

        TriggerEvent("Admin:Client:Menu:Closed")
        _menuOpen = false
    end
end

RegisterNetEvent('Admin:Client:Menu:Open', function()
    OpenMenu()
end)

RegisterNetEvent('UI:Client:Reset', function(apps)
    CloseMenu()
end)

RegisterNUICallback('Close', function(data, cb)
	cb('OK')
	CloseMenu()
end)

RegisterNUICallback('GetPlayerList', function(data, cb)
    if data and data.disconnected then
        plsr.Callbacks:ServerCallback('Admin:GetDisconnectedPlayerList', data, cb)
    else
        plsr.Callbacks:ServerCallback('Admin:GetPlayerList', data, cb)
    end
end)

RegisterNUICallback('GetPlayer', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:GetPlayer', data, cb)
end)

RegisterNUICallback('GetCurrentVehicle', function(data, cb)
    local insideVehicle = GetVehiclePedIsIn(PlayerPedId(), true)
    if insideVehicle and insideVehicle > 0 and DoesEntityExist(insideVehicle) then
        local vehState = plsr.State.Entity(insideVehicle)
        local vehicleCoords = GetEntityCoords(insideVehicle)
        local vehicleHeading = GetEntityHeading(insideVehicle)
        local currentSeat = 'Not In Vehicle'
        for i = -1, 14 do
            if GetPedInVehicleSeat(insideVehicle, i) == PlayerPedId() then
                currentSeat = i
                break
            end
        end

        cb({
            Make = vehState.Make,
            Model = vehState.Model,
            VIN = vehState.VIN,
            Owned = vehState.Owned,
            Owner = vehState.Owner,
            Plate = vehState.Plate,
            Value = vehState.Value,
            EntityModel = GetEntityModel(insideVehicle),
            Coords = {
                x = vehicleCoords.x,
                y = vehicleCoords.y,
                z = vehicleCoords.z,
            },
            Heading = vehicleHeading,
            Seat = currentSeat,
            Fuel = vehState.Fuel,
            Damage = vehState.Damage,
            DamagedParts = vehState.DamagedParts,
        })
    else
        cb(false)
    end
end)

RegisterNUICallback('ActionPlayer', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:ActionPlayer', data, cb)
end)

RegisterNUICallback('KickPlayer', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:KickPlayer', data, cb)
end)

RegisterNUICallback('BanPlayer', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:BanPlayer', data, cb)
end)

RegisterNUICallback('GetItemsCatalog', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:GetItemsCatalog', data, cb)
end)

RegisterNUICallback('GiveItem', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:GiveItem', data, cb)
end)

RegisterNUICallback('GetJobsCatalog', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:GetJobsCatalog', data, cb)
end)

RegisterNUICallback('SetJob', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:SetJob', data, cb)
end)

RegisterNUICallback('RemoveJob', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:RemoveJob', data, cb)
end)

RegisterNUICallback('GetDoorsCatalog', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:GetDoorsCatalog', data, cb)
end)

RegisterNUICallback('CreateDoor', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:CreateDoor', data, cb)
end)

RegisterNUICallback('EditDoor', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:EditDoor', data, cb)
end)

RegisterNUICallback('RemoveDoor', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:RemoveDoor', data, cb)
end)

RegisterNUICallback('TeleportToDoor', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:TeleportToDoor', data, cb)
end)

RegisterNUICallback('GetVehicleList', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:GetVehicleList', data, cb)
end)

RegisterNUICallback('GetVehicle', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:GetVehicle', data, cb)
end)

RegisterNUICallback('ActionVehicle', function(data, cb)
    if data and data.model then
        data.numSeats = GetVehicleModelNumberOfSeats(data.model)
    end
    plsr.Callbacks:ServerCallback('Admin:VehicleAction', data, cb)
end)

RegisterNUICallback('GetAllPlayersByCharacter', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:GetAllPlayersByCharacter', data, cb)
end)

RegisterNUICallback('CurrentVehicleAction', function(data, cb)
    local insideVehicle = GetVehiclePedIsIn(PlayerPedId(), true)
    if insideVehicle and insideVehicle > 0 and DoesEntityExist(insideVehicle) then
        plsr.Callbacks:ServerCallback('Admin:CurrentVehicleAction', data, function(canDo)
            if canDo then
                if data.action == 'repair' then
                    if plsr.Vehicles.Repair:Normal(insideVehicle) then
                        return cb({
                            success = true,
                            message = 'Vehicle Repaired',
                        })
                    end
                elseif data.action == 'repair_full' then
                    if plsr.Vehicles.Repair:Full(insideVehicle) then
                        return cb({
                            success = true,
                            message = 'Vehicle Repaired Fully',
                        })
                    end
                elseif data.action == 'repair_engine' then
                    if plsr.Vehicles.Repair:Engine(insideVehicle) then
                        return cb({
                            success = true,
                            message = 'Engine Repaired',
                        })
                    end
                elseif data.action == 'explode' then
                    plsr.NetSync:NetworkExplodeVehicle(insideVehicle, 1, 0)
                    return cb({
                        success = true,
                        message = 'Vehicle Exploded',
                    })
                elseif data.action == 'alarm' then
                    if IsVehicleAlarmSet(insideVehicle) then
                        SetVehicleAlarm(insideVehicle, false)
                    else
                        SetVehicleAlarm(insideVehicle, true)
                        SetVehicleAlarmTimeLeft(insideVehicle, config.VehicleAction.alarmDurationMs)
                    end

                    return cb({
                        success = true,
                        message = 'Vehicle Alarm Activated',
                    })
                elseif data.action == 'fuel' then
                    plsr.State.Entity(insideVehicle).Fuel = 100

                    return cb({
                        success = true,
                        message = 'Vehicle Refueled',
                    })
                -- elseif data.action == 'delete' then
                elseif data.action == 'customs' then
                    TriggerEvent('VehicleCustoms:Client:Admin', true, 0.0)

                    Citizen.SetTimeout(1000, function()
                        CloseMenu()
                    end)

                    return cb({
                        success = true,
                        message = 'Opened',
                    })
                end

                cb(false)
            else
                cb(false);
            end
        end)
    else
        cb({
            success = false,
            message = 'No Longer In Vehicle Control',
        })
    end
end)

RegisterNUICallback('StopAllAttach', function(data, cb)
	cb('OK')
	TriggerEvent("Admin:Client:AdminStopAttach")
end)

RegisterNUICallback('GetPlayerHistory', function(data, cb)
	cb({
        current = GlobalState.PlayerCount or 0,
        max = GlobalState.MaxPlayers or 1,
        queue = GlobalState.QueueCount or 0,
        history = GlobalState.AdminPlayerHistory
    })
end)

RegisterNUICallback('ToggleInvisible', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:ToggleInvisible', data, cb)
end)

RegisterNUICallback('ToggleIDs', function(data, cb)
    cb('OK')

    if plsr.State.flags.isStaff then
        ToggleAdminPlayerIDs()
    end
end)

-- Additive — Noclip previously had no NUI path at all, only the /noclip chat
-- command. Same underlying toggle (Admin:Client:NoClip -> ADMIN.NoClip:Toggle,
-- server-permission-checked via Admin:NoClip), just reachable from the panel now.
RegisterNUICallback('ToggleNoclip', function(data, cb)
    cb('OK')
    TriggerEvent('Admin:Client:NoClip')
end)

function CopyClipboard(txt)
    SendNUIMessage({
        type = "COPY",
        data = {
            data = txt,
        }
    })
end

RegisterNUICallback('openinventory', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:OpenInventory', data, cb)
end)

RegisterNUICallback('openstash', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:OpenStash', data, cb)
end)

RegisterNUICallback('opentrunk', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:OpenTrunk', data, cb)
end)

RegisterNUICallback('clearinventory', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:ClearInventory', data, cb)
end)

RegisterNUICallback('clearinventory2', function(data, cb)
    plsr.Callbacks:ServerCallback('Admin:ClearInventory2', data, cb)
end)

-- RegisterNUICallback("OpenPlyInv", function(data, cb)
--     if not data.targetSource then return cb(false) end

--     local id = data.targetSource
--     plsr.Callbacks:ServerCallback("Admin:Target:OpenPlyInv", id, function(s)
--         Inventory.Dumbfuck:Open(s)
        
--         while not plsr.State.flags.inventoryOpen do
--             Wait(1)
--         end

--         CreateThread(function()
--             while plsr.State.flags.inventoryOpen do
--                 Wait(2)
--             end
--         end)
--     end)
-- end)