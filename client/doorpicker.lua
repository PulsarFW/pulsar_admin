local MAX_PICK_DISTANCE = 25.0

local function getCameraRay()
	local camCoords = GetGameplayCamCoord()
	local camRot = GetGameplayCamRot(2)
	local rotZ = math.rad(camRot.z)
	local rotX = math.rad(camRot.x)
	local direction = vector3(-math.sin(rotZ) * math.abs(math.cos(rotX)), math.cos(rotZ) * math.abs(math.cos(rotX)), math.sin(rotX))
	return camCoords, direction
end

local function findObjectOnAimLine(camCoords, direction, maxDist, maxPerp)
	local best, bestDist = 0, maxDist + 1
	local handle, obj = FindFirstObject()
	local success = true

	repeat
		if DoesEntityExist(obj) then
			local objCoords = GetEntityCoords(obj)
			local toObj = objCoords - camCoords
			local t = toObj.x * direction.x + toObj.y * direction.y + toObj.z * direction.z

			if t > 0.0 and t < maxDist then
				local closestOnLine = camCoords + direction * t
				local perpDist = #(objCoords - closestOnLine)

				if perpDist < maxPerp and t < bestDist then
					best = obj
					bestDist = t
				end
			end
		end
		success, obj = FindNextObject(handle)
	until not success
	EndFindObject(handle)

	return best
end

local pickerGeneration = 0

AddEventHandler("Admin:Client:Menu:Closed", function()
	pickerGeneration = pickerGeneration + 1
end)

RegisterNUICallback('PickDoorInWorld', function(data, cb)
	pickerGeneration = pickerGeneration + 1
	local myGeneration = pickerGeneration

	-- PICKER_START/_END hide the panel via CSS, not APP_HIDE, so the form state survives
	SendNUIMessage({ type = "PICKER_START" })
	SetNuiFocus(false, false)

	local outlinedEntity = 0
	local result = false
	local cancelled = false

	plsr.Action:Show("door_picker", "Left Click To Pick The Door Object, Backspace To Cancel")

	while not result and not cancelled and pickerGeneration == myGeneration do
		Wait(0)
		DisablePlayerFiring(PlayerId(), true)

		local camCoords, direction = getCameraRay()
		local rayEntity = plsr.ShapeTest.Ray:EntityHit(camCoords, camCoords + direction * MAX_PICK_DISTANCE, 1 | 16)
		local validRayEntity = rayEntity and rayEntity ~= 0 and DoesEntityExist(rayEntity) and GetEntityType(rayEntity) == 3
		local entity = validRayEntity and rayEntity or findObjectOnAimLine(camCoords, direction, MAX_PICK_DISTANCE, 1.0)
		local validEntity = entity ~= 0 and DoesEntityExist(entity) and GetEntityType(entity) == 3

		if entity ~= outlinedEntity then
			if outlinedEntity ~= 0 and DoesEntityExist(outlinedEntity) then
				SetEntityDrawOutline(outlinedEntity, false)
			end
			outlinedEntity = validEntity and entity or 0
		end

		if validEntity then
			SetEntityDrawOutlineColor(147, 51, 234, 175)
			SetEntityDrawOutlineShader(1)
			SetEntityDrawOutline(entity, true)
			local coords = GetEntityCoords(entity)
			DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 147, 51, 234, 100, false, false, 0, true, false, false, false)

			if IsDisabledControlJustPressed(0, 24) then
				result = {
					model = GetEntityModel(entity),
					coords = { x = coords.x, y = coords.y, z = coords.z },
					heading = GetEntityHeading(entity),
				}
			end
		end

		-- control 194 = INPUT_FRONTEND_CANCEL, Backspace by default
		if IsControlJustPressed(0, 194) then
			cancelled = true
		end
	end

	if outlinedEntity ~= 0 and DoesEntityExist(outlinedEntity) then
		SetEntityDrawOutline(outlinedEntity, false)
	end

	-- superseded by a newer pick or the panel closed out from under us, that owner handles its own focus/cb lifecycle
	if pickerGeneration ~= myGeneration then
		return
	end

	plsr.Action:Hide("door_picker")
	SetNuiFocus(true, true)
	SendNUIMessage({ type = "PICKER_END" })
	cb(result)
end)

-- grabs the admins current position/heading for a garage doors polyzone
RegisterNUICallback('CaptureZonePosition', function(data, cb)
	local ped = PlayerPedId()
	local coords = GetEntityCoords(ped)
	cb({
		x = coords.x,
		y = coords.y,
		z = coords.z,
		heading = GetEntityHeading(ped),
	})
end)
