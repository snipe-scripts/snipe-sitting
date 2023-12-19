-----------------For support, scripts, and more----------------
--------------- https://discord.gg/AeCVP2F8h7  -------------
---------------------------------------------------------------

local ped = nil
local sitting = false


local txt = {
    '_Sit Controls_  \n',
    '[E] Sit in position  \n',
    '[X or Right Click] Cancel  \n',
    '[Scroll Wheel] Rotate  \n',
    '[Up/Down Arrows] Height  \n',
}

local function RequestAnimDictionary(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(1)
    end
end

local function StartSittingThread()
    sitting = true
    lib.showTextUI("Press [Q] to cancel")

    CreateThread(function ()
        while sitting do
            Wait(1)
            if IsControlJustReleased(0, 44) then
                sitting = false
                lib.hideTextUI()
                ClearPedTasksImmediately(PlayerPedId())
                return
            end
        end
    end)
end

local function MakePedSitDown(coords, heading, animData)
    ClearPedTasksImmediately(PlayerPedId())
    stopPlacing()
    TaskGoToCoordAnyMeans(PlayerPedId(), coords.x, coords.y, coords.z, 1.0, 0, 0, 786603, 0xbf800000)
    local PlayerCoords = GetEntityCoords(PlayerPedId())
    lib.showTextUI("Press [Right Click] to cancel")
    SetFollowPedCamViewMode(0)
    SetCamViewModeForContext(0, 2)
    while #(PlayerCoords - coords) > 10.0 do
        Wait(1)
        PlayerCoords = GetEntityCoords(PlayerPedId())
        if IsControlJustReleased(0, 177) then
            lib.hideTextUI()
            ClearPedTasksImmediately(PlayerPedId())
            return
        end
    end
    lib.hideTextUI()
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, false)
    TaskPlayAnimAdvanced(PlayerPedId(), animData.dict, animData.anim, coords.x, coords.y, coords.z, 0, 0, heading, 3.0, 3.0, -1, 2, 1.0, false, false)
    StartSittingThread()
end

local function PlacingThread(animData)
    if ped == nil then
        local playerPed = PlayerPedId()
        ped = ClonePed(playerPed, false, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityAlpha(ped, 0)
        RequestAnimDictionary(animData.dict)
        TaskPlayAnim(ped, animData.dict, animData.anim, 8.0, 8.0, -1, 1, 0, false, false, false)
        SetEntityCollision(ped, false, false)
        SetEntityAlpha(ped, 100)
        SetBlockingOfNonTemporaryEvents(ped, false)
        if Config.SetToFirstPerson then
            SetFollowPedCamViewMode(3)
            SetCamViewModeForContext(0, 4)
        end
        heading = GetEntityHeading(playerPed) + 90.0
        CreateThread(function ()
            local currentCoordsZ = 0
            while ped ~= nil do
                Wait(1)
                DisableControlAction(0, 22, true)
                startPlacing()
                if currentCoords then
                    SetEntityCoords(ped, currentCoords.x, currentCoords.y, currentCoords.z + currentCoordsZ)
                    SetEntityHeading(ped, heading)
                end
                -- Jay added this 
                if IsDisabledControlPressed(0, 27) then
                    currentCoordsZ = currentCoordsZ + 0.01
                end
                if IsDisabledControlPressed(0, 173) then
                    currentCoordsZ = currentCoordsZ - 0.01
                end
                if IsDisabledControlJustPressed(0, 14) then
                    print("adadwd")
                    heading = heading + 5
                    if heading > 360 then heading = 0.0 end
                end
        
                if IsDisabledControlJustPressed(0, 15) then
                    heading = heading - 5
                    if heading < 0 then heading = 360.0 end
                end
                if IsControlJustReleased(0, 38) then
                    if #(GetEntityCoords(PlayerPedId()) - currentCoords) < 35.0 then
                        MakePedSitDown(GetEntityCoords(ped), GetEntityHeading(ped), animData)
                    else
                        lib.notify({type = "error", description = "You are too far"})
                    end
                end
                if IsControlJustReleased(0, 177) then
                    stopPlacing()
                end
            end
        end)
    else
        DeleteObject(ped)
        ped = nil
        stopPlacing()
        return
    end
end

function GetForwardVector(rotation)
    local rot = (math.pi / 180.0) * rotation
    return vector3(-math.sin(rot.z) * math.abs(math.cos(rot.x)), math.cos(rot.z) * math.abs(math.cos(rot.x)),
        math.sin(rot.x))
end

local function RotationToDirection(rotation)
	local adjustedRotation =
	{
		x = (math.pi / 180) * rotation.x,
		y = (math.pi / 180) * rotation.y,
		z = (math.pi / 180) * rotation.z
	}
	local direction =
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		z = math.sin(adjustedRotation.x)
	}
	return direction
end

function Camera(ped)
    DoingCamera = true
    local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	local destination =
	{
		x = cameraCoord.x + direction.x * 1000.0,
		y = cameraCoord.y + direction.y * 1000.0,
		z = cameraCoord.z + direction.z * 1000.0
	}
    local sphereCast = StartShapeTestSweptSphere(
        cameraCoord.x,
        cameraCoord.y,
        cameraCoord.z,
        destination.x,
        destination.y,
        destination.z,
        0.2,
        339,
        ped,
        4
    );
    return GetShapeTestResultIncludingMaterial(sphereCast);
end

function startPlacing()
    local _, hit, endCoords, _, _, _ = Camera(ped)
    if hit then
        lib.showTextUI(table.concat(txt))
        currentCoords = endCoords
    end
end

function stopPlacing()
    if ped then
        DeleteEntity(ped)
    end
    ped = nil
    heading = 0.0
    currentCoords = nil
    lib.hideTextUI()
    DoingCamera = false
end

RegisterCommand("sit", function(source, args)
    if not Config.Anims[tonumber(args[1])] then
        lib.notify({type = "error", description = "Invalid value chosen. Usage: /sit [1-"..#Config.Anims.."]"})
        return
    end
    PlacingThread(Config.Anims[tonumber(args[1])])
end)
