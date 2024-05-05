local Action = {
    name = "",
    duration = 0,
    label = "",
    useWhileDead = false,
    canCancel = true,
	disarm = true,
    controlDisables = {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = false,
    },
    animation = {
        animDict = nil,
        anim = nil,
        flags = 0,
        task = nil,
    },
    prop = {
        model = nil,
        bone = nil,
        coords = { x = 0.0, y = 0.0, z = 0.0 },
        rotation = { x = 0.0, y = 0.0, z = 0.0 },
    },
    propTwo = {
        model = nil,
        bone = nil,
        coords = { x = 0.0, y = 0.0, z = 0.0 },
        rotation = { x = 0.0, y = 0.0, z = 0.0 },
    },
}

local isDoingAction = false
local disableMouse = false
local wasCancelled = false
local isAnim = false
local isProp = false
local isPropTwo = false
local prop_net = nil
local propTwo_net = nil
local runProgThread = false
local finishedDuration = false

RegisterNetEvent('progressbar:client:ToggleBusyness')
AddEventHandler('progressbar:client:ToggleBusyness', function(bool)
    isDoingAction = bool
end)

function Progress(action, finish)
	Process(action, nil, nil, finish)
end

function ProgressWithStartEvent(action, start, finish)
	Process(action, start, nil, finish)
end

function ProgressWithTickEvent(action, tick, finish)
	Process(action, nil, tick, finish)
end

function ProgressWithStartAndTick(action, start, tick, finish)
	Process(action, start, tick, finish)
end

function Process(action, start, tick, finish)
	ActionStart()
    Action = action
    local ped = PlayerPedId()
    if not IsEntityDead(ped) or Action.useWhileDead then
        if not isDoingAction then
            isDoingAction = true
            wasCancelled = false
            isAnim = false
            isProp = false
            finishedDuration = false

            SendNUIMessage({
                action = "progress",
                duration = Action.duration,
                label = Action.label
            })
            DisableControlAction(0, 0x156F7119, true)
            DisableControlAction(0, 0xF84FA74F, true)
            CreateThread(function ()
                if start ~= nil then
                    start()
                end
                while isDoingAction do
                    Wait(1)
                    if tick ~= nil then
                        tick()
                    end
                    
                    if IsDisabledControlJustPressed( 0, 0xF84FA74F) or IsDisabledControlJustPressed(0, 0x156F7119) and Action.canCancel then
                        TriggerEvent("progressbar:client:cancel")
                    end

                    if IsEntityDead(ped) and not Action.useWhileDead then
                        TriggerEvent("progressbar:client:cancel")
                    end
                end
                if finish ~= nil then
                    finish(wasCancelled)
                end
            end)
            CreateThread(function()
                Wait(Action.duration)
                finishedDuration = true
            end)
        else
            TriggerEvent("QBCore:Notify", "You are already doing something!", "error")
        end
    else
        TriggerEvent("QBCore:Notify", "Cant do that action!", "error")
    end
end

function ActionStart()
    runProgThread = true
    LocalPlayer.state:set("inv_busy", true, true) -- Busy
    CreateThread(function()
        while runProgThread do
            if isDoingAction then
                if not isAnim then
                    if Action.animation ~= nil then
                        if Action.animation.task ~= nil then
                            TaskStartScenarioInPlace(PlayerPedId(), Action.animation.task, 0, true)
                        elseif Action.animation.animDict ~= nil and Action.animation.anim ~= nil then
                            if Action.animation.flags == nil then
                                Action.animation.flags = 1
                            end

                            local player = PlayerPedId()
                            if (DoesEntityExist(player) and not IsEntityDead(player)) then
                                loadAnimDict( Action.animation.animDict)
                                TaskPlayAnim(player, Action.animation.animDict, Action.animation.anim, 3.0, 3.0, -1, Action.animation.flags, 0, 0, 0, 0 )     
                            end
                        else
                            --TaskStartScenarioInPlace(PlayerPedId(), 'PROP_HUMAN_BUM_BIN', 0, true)
                        end
                    end

                    isAnim = true
                end
                if not isProp and Action.prop ~= nil and Action.prop.model ~= nil then
                    local ped = PlayerPedId()
                    RequestModel(Action.prop.model)

                    while not HasModelLoaded(GetHashKey(Action.prop.model)) do
                        Wait(0)
                    end

                    local pCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, 0.0)
                    local modelSpawn = CreateObject(GetHashKey(Action.prop.model), pCoords.x, pCoords.y, pCoords.z, true, true, true)

                    local netid = ObjToNet(modelSpawn)
                    SetNetworkIdExistsOnAllMachines(netid, true)
                    NetworkSetNetworkIdDynamic(netid, true)
                    SetNetworkIdCanMigrate(netid, false)
                    if Action.prop.bone == nil then
                        Action.prop.bone = 60309
                    end

                    if Action.prop.coords == nil then
                        Action.prop.coords = { x = 0.0, y = 0.0, z = 0.0 }
                    end

                    if Action.prop.rotation == nil then
                        Action.prop.rotation = { x = 0.0, y = 0.0, z = 0.0 }
                    end

                    AttachEntityToEntity(modelSpawn, ped, GetPedBoneIndex(ped, Action.prop.bone), Action.prop.coords.x, Action.prop.coords.y, Action.prop.coords.z, Action.prop.rotation.x, Action.prop.rotation.y, Action.prop.rotation.z, 1, 1, 0, 1, 0, 1)
                    prop_net = netid

                    isProp = true
                    
                    if not isPropTwo and Action.propTwo ~= nil and Action.propTwo.model ~= nil then
                        RequestModel(Action.propTwo.model)

                        while not HasModelLoaded(GetHashKey(Action.propTwo.model)) do
                            Wait(0)
                        end

                        local pCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, 0.0)
                        local modelSpawn = CreateObject(GetHashKey(Action.propTwo.model), pCoords.x, pCoords.y, pCoords.z, true, true, true)

                        local netid = ObjToNet(modelSpawn)
                        SetNetworkIdExistsOnAllMachines(netid, true)
                        NetworkSetNetworkIdDynamic(netid, true)
                        SetNetworkIdCanMigrate(netid, false)
                        if Action.propTwo.bone == nil then
                            Action.propTwo.bone = 60309
                        end

                        if Action.propTwo.coords == nil then
                            Action.propTwo.coords = { x = 0.0, y = 0.0, z = 0.0 }
                        end

                        if Action.propTwo.rotation == nil then
                            Action.propTwo.rotation = { x = 0.0, y = 0.0, z = 0.0 }
                        end

                        AttachEntityToEntity(modelSpawn, ped, GetPedBoneIndex(ped, Action.propTwo.bone), Action.propTwo.coords.x, Action.propTwo.coords.y, Action.propTwo.coords.z, Action.propTwo.rotation.x, Action.propTwo.rotation.y, Action.propTwo.rotation.z, 1, 1, 0, 1, 0, 1)
                        propTwo_net = netid

                        isPropTwo = true
                    end
                end

                DisableActions(ped)
            end
            Wait(0)
        end
    end)
end

function Cancel()
    isDoingAction = false
    wasCancelled = true
    LocalPlayer.state:set("inv_busy", false, true) -- Not Busy
    ActionCleanup()

    SendNUIMessage({
        action = "cancel"
    })
end

function Finish()
    isDoingAction = false
    ActionCleanup()
    LocalPlayer.state:set("inv_busy", false, true) -- Not Busy
end

function ActionCleanup()
    local ped = PlayerPedId()

    if Action.animation ~= nil then
        if Action.animation.task ~= nil or (Action.animation.animDict ~= nil and Action.animation.anim ~= nil) then
            ClearPedTasks(ped)
            ClearPedSecondaryTask(ped)
            StopAnimTask(ped, Action.animDict, Action.anim, 1.0)
        else
            ClearPedTasks(ped)
        end
    end

    if prop_net then
        DetachEntity(NetToObj(prop_net), 1, 1)
        DetachEntity(NetToObj(prop_net))
    end
    if propTwo_net then
        DetachEntity(NetToObj(propTwo_net), 1, 1)
        DetachEntity(NetToObj(propTwo_net))
    end
    prop_net = nil
    propTwo_net = nil
    runProgThread = false
end

function loadAnimDict(dict)
	while (not HasAnimDictLoaded(dict)) do
		RequestAnimDict(dict)
		Wait(5)
	end
end

function DisableActions(ped)
    if Action.controlDisables.disableMouse then
        DisableControlAction(0, 0xA987235F, true) -- LookLeftRight (mouse lr)
        DisableControlAction(0, 0xD2047988, true) -- LookUpDown (mouse ud)
        DisableControlAction(0, 0x39CCABD5, true) -- VehicleMouseControlOverride
    end

    if Action.controlDisables.disableMovement then
        DisableControlAction(0, 0x4D8FB4C1, true) -- disable left/right (a/d)
        DisableControlAction(0, 0xFDA83190, true) -- disable forward/back (w/s)
        DisableControlAction(0, 0xDB096B85, true) -- diable duck (ctrl)
        DisableControlAction(0, 0x8FFC75D6, true) -- disable sprint (shift)
    end

    if Action.controlDisables.disableCarMovement then
        DisableControlAction(0, 0x126796EB, true) -- horse turn LR (a/d)
        DisableControlAction(0, 0x3BBDEFEF, true) -- horse turn UD (w/s)
        DisableControlAction(0, 0x5AA007D7, true) -- horse sprint (shift)
        DisableControlAction(0, 0xCBDB82A8, true) -- disable exit vehicle (f)
    end

    if Action.controlDisables.disableCombat then
        DisablePlayerFiring(PlayerId(), true) -- Disable weapon firing (lmb)
        DisableControlAction(0, 0x07CE1E61, true) -- disable attack (lmb)
        DisableControlAction(0, 0xF84FA74F, true) -- disable aim (rmb)
        DisableControlAction(0, 0x73846677, true) -- may not be needed (detonate)
        DisableControlAction(0, 0x0AF99998, true) -- may not be needed (grenade)
        DisableControlAction(0, 0xB2F377E8, true) -- disable melee (f)
        DisableControlAction(0, 0xB5EEEFB7, true) -- disable block (r)
        DisableControlAction(0, 0x0283C582, true) -- may not be needed (attack2)
    end
end

RegisterNetEvent("progressbar:client:progress")
AddEventHandler("progressbar:client:progress", function(action, finish)
	Process(action, nil, nil, finish)
end)

RegisterNetEvent("progressbar:client:ProgressWithStartEvent")
AddEventHandler("progressbar:client:ProgressWithStartEvent", function(action, start, finish)
	Process(action, start, nil, finish)
end)

RegisterNetEvent("progressbar:client:ProgressWithTickEvent")
AddEventHandler("progressbar:client:ProgressWithTickEvent", function(action, tick, finish)
	Process(action, nil, tick, finish)
end)

RegisterNetEvent("progressbar:client:ProgressWithStartAndTick")
AddEventHandler("progressbar:client:ProgressWithStartAndTick", function(action, start, tick, finish)
	Process(action, start, tick, finish)
end)

RegisterNetEvent("progressbar:client:cancel")
AddEventHandler("progressbar:client:cancel", function()
	Cancel()
end)

RegisterNUICallback('FinishAction', function(data, cb)
    if not finishedDuration then return end
	Finish()
end)

-- Example Usage using the qbrcore export:

-- local IfaksDict = "SCRIPT_RE@GOLD_PANNER@GOLD_SUCCESS"
-- local IfaksAnim = "panning_idle_no_water"
-- RegisterCommand("progresstest", function()
--     Citizen.InvokeNative(0xF6BEE7E80EC5CA40, 1)
--     Citizen.InvokeNative(0xF02A9C330BBFC5C7, 2)
    
--     local ped = PlayerPedId()
--     exports['qbr-core']:Progressbar("use_bandage", "Look at me mah, Im doing stuff!", 10000, false, true, {
--         disableMovement = true,
--         disableCarMovement = true,
-- 		disableMouse = true,
-- 		disableCombat = true,
--     }, {
-- 		animDict = IfaksDict,
-- 		anim = IfaksAnim,
-- 		flags = 1,
--     }, {}, {}, function() -- Done
--         print("Done")
--     end, function() -- Cancel
--         print("Cancel")
--     end)
-- end)
