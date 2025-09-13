--==================--
--      CONFIG      --
--==================--
NoClipEnabled = false
local FreeCamVeh = 0
local NoClipCooldown = 0

local NOCLIP_SETTINGS = {
    KEYBIND = 'F1',
    COOLDOWN = 1000,
    LOOK_SENSITIVITY_X   = 5,
    LOOK_SENSITIVITY_Y   = 5,
    BASE_MOVE_MULTIPLIER = 0.85,
    FAST_MOVE_MULTIPLIER = 6,
    SLOW_MOVE_MULTIPLIER = 6,
    CONTROLS = {
        LOOK_X      = 1,           -- INPUT_LOOK_LR
        LOOK_Y      = 2,           -- INPUT_LOOK_UD
        MOVE_X      = 30,          -- INPUT_MOVE_LR
        MOVE_Y      = 31,          -- INPUT_MOVE_UD
        MOVE_Z      = {152, 153},  -- INPUT_PARACHUTE_BRAKE_LEFT / RIGHT
        MOVE_FAST   = 21,          -- INPUT_SPRINT
        MOVE_SLOW   = 19           -- INPUT_CHARACTER_WHEEL
    },
    CAMERA = {
        FOV = 50.0,
        ENABLE_EASING = true,
        EASING_DURATION = 250,
        KEEP_POSITION = false,
        KEEP_ROTATION = false
    },
    PTFX = {
        DICT = 'core',
        ASSET = 'ent_dst_elec_fire_sp',
        SCALE = 1.75,
        DURATION = 1500,
        AUDIO = {
            NAME = 'ent_amb_elec_crackle',
            REF = 0,
        },
        LOOP = {
            AMOUNT = 7,
            DELAY = 75,
        },
    }
}

local ControlsTable = {
    --french oui oui baguette
    {'Slow', NOCLIP_SETTINGS.CONTROLS.MOVE_SLOW},
    {'Fast', NOCLIP_SETTINGS.CONTROLS.MOVE_FAST},
    {'Down', NOCLIP_SETTINGS.CONTROLS.MOVE_Z[2]},
    {'Up', NOCLIP_SETTINGS.CONTROLS.MOVE_Z[1]},
    {'Left/Right', NOCLIP_SETTINGS.CONTROLS.MOVE_X},
    {'Forward/Backward', NOCLIP_SETTINGS.CONTROLS.MOVE_Y},
}

--==================--
--    UTILITIES     --
--==================--
local rad, sin, cos, min, max, floor, vector3, Wait = math.rad, math.sin, math.cos, math.min, math.max, math.floor, vector3, Citizen.Wait

local function Clamp(x, _min, _max) return min(max(x, _min), _max) end

local function ClampCameraRotation(rotX, rotY, rotZ)
    return Clamp(rotX, -90, 90), rotY % 360, rotZ % 360
end

local function EulerToMatrix(rotX, rotY, rotZ)
    local rx, ry, rz = rad(rotX), rad(rotY), rad(rotZ)
    local sx, sy, sz = sin(rx), sin(ry), sin(rz)
    local cx, cy, cz = cos(rx), cos(ry), cos(rz)
    return vector3(cy*cz, cy*sz, -sy),
           vector3(cz*sx*sy - cx*sz, cx*cz - sx*sy*sz, cy*sx),
           vector3(-cx*cz*sy + sx*sz, -cz*sx - cx*sy*sz, cx*cy)
end

function GetSmartControlNormal(control)
    if type(control) == 'table' then
        return GetDisabledControlNormal(0, control[1]) - GetDisabledControlNormal(0, control[2])
    end
    return GetDisabledControlNormal(0, control)
end

--==================--
--   SCALEFORM      --
--==================--
--- Generates a instructional scaleform
---@param ControlsTable table
---@return integer scaleform
function MakeInstructionalScaleform(ControlsTable)
    local scaleform = RequestScaleformMovie("instructional_buttons")
    while not HasScaleformMovieLoaded(scaleform) do
        Wait(10)
    end
    BeginScaleformMovieMethod(scaleform, "CLEAR_ALL")
    EndScaleformMovieMethod()

    BeginScaleformMovieMethod(scaleform, "SET_CLEAR_SPACE")
    ScaleformMovieMethodAddParamInt(200)
    EndScaleformMovieMethod()

    for btnIndex, keyData in ipairs(ControlsTable) do
        local btn = GetControlInstructionalButton(0, keyData[2], true)

        BeginScaleformMovieMethod(scaleform, "SET_DATA_SLOT")
        ScaleformMovieMethodAddParamInt(btnIndex - 1)
        ScaleformMovieMethodAddParamPlayerNameString(btn)
        BeginTextCommandScaleformString("STRING")
        AddTextComponentSubstringKeyboardDisplay(keyData[1])
        EndTextCommandScaleformString()
        EndScaleformMovieMethod()
    end

    BeginScaleformMovieMethod(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    EndScaleformMovieMethod()

    BeginScaleformMovieMethod(scaleform, "SET_BACKGROUND_COLOUR")
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(80)
    EndScaleformMovieMethod()

    return scaleform
end

--==================--
--   FREECAM CORE   --
--==================--
local function GetSpeedMultiplier()
    local fast = 1 + ((NOCLIP_SETTINGS.FAST_MOVE_MULTIPLIER - 1) * GetSmartControlNormal(NOCLIP_SETTINGS.CONTROLS.MOVE_FAST))
    local slow = 1 + ((NOCLIP_SETTINGS.SLOW_MOVE_MULTIPLIER - 1) * GetSmartControlNormal(NOCLIP_SETTINGS.CONTROLS.MOVE_SLOW))
    return NOCLIP_SETTINGS.BASE_MOVE_MULTIPLIER * fast / slow * GetFrameTime() * 60
end

function SetFreecamPosition(x, y, z)
    local pos = vector3(x, y, z)
    SetFocusPosAndVel(x, y, z, 0.0, 0.0, 0.0)
    SetCamCoord(_internal_camera, x, y, z)
        LockMinimapPosition(x, y)
    _internal_pos = pos
end

function SetFreecamRotation(x, y, z)
    local rotX, rotY, rotZ = ClampCameraRotation(x, y, z)
    local vecX, vecY, vecZ = EulerToMatrix(rotX, rotY, rotZ)
    local rot = vector3(rotX, rotY, rotZ)

    LockMinimapAngle(floor(rotZ))
    SetCamRot(_internal_camera, rotX, rotY, rotZ, 2)

    _internal_rot  = rot
    _internal_vecX = vecX
    _internal_vecY = vecY
    _internal_vecZ = vecZ
end

function SetFreecamFov(fov)
    local fov = Clamp(fov, 0.0, 90.0)
    SetCamFov(_internal_camera, fov)
    _internal_fov = fov
end

function IsFreecamActive()
    return IsCamActive(_internal_camera) == 1
end

function SetFreecamActive(active)
    if active == IsFreecamActive() then
        return
    end

    local enableEasing = NOCLIP_SETTINGS.CAMERA.ENABLE_EASING
    local easingDuration = NOCLIP_SETTINGS.CAMERA.EASING_DURATION

    if active then
        local pos = GetInitialCameraPosition()
        local rot = GetInitialCameraRotation()

        _internal_camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)

        SetFreecamFov(NOCLIP_SETTINGS.CAMERA.FOV)
        SetFreecamPosition(pos.x, pos.y, pos.z)
        SetFreecamRotation(rot.x, rot.y, rot.z)
    else
        DestroyCam(_internal_camera)
        ClearFocus()
        UnlockMinimapAngle()
        UnlockMinimapPosition()
    end

    RenderScriptCams(active, enableEasing, easingDuration, true, true)
end

function GetFreecamMatrix()
    return _internal_vecX,
            _internal_vecY,
            _internal_vecZ,
            _internal_pos
end

function StartFreecamThread()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)

    Citizen.CreateThread(function()
        local loopPos, loopRotZ
        local frameCounter = 0

        while IsFreecamActive() do
            loopPos, loopRotZ = UpdateCamera()
            if loopPos and loopRotZ then
                frameCounter = frameCounter + 1
                if frameCounter > 100 then
                    frameCounter = 0
                    SetEntityCoords(ped, loopPos.x, loopPos.y, loopPos.z, false, false, false, false)
                    SetEntityHeading(ped, loopRotZ)
                    if veh and veh > 0 and DoesEntityExist(veh) then
                        SetEntityCoords(veh, loopPos.x, loopPos.y, loopPos.z, false, false, false, false)
                        SetEntityHeading(veh, loopRotZ)
                    end
                end
            end
            Wait(0)
        end

        if loopPos and loopRotZ then
            SetEntityCoords(ped, loopPos.x, loopPos.y, loopPos.z, false, false, false, false)
            SetEntityHeading(ped, loopRotZ)
            if veh and veh > 0 and DoesEntityExist(veh) then
                SetEntityCoords(veh, loopPos.x, loopPos.y, loopPos.z, false, false, false, false)
                SetEntityHeading(veh, loopRotZ)
            end
        end
    end)

    Citizen.CreateThread(function()
        local scaleform = MakeInstructionalScaleform(ControlsTable)
        while IsFreecamActive() do
            DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
            Wait(0)
        end
        SetScaleformMovieAsNoLongerNeeded(scaleform)
    end)
end

--==================--
--   CAMERA CORE   --
--==================--
function GetInitialCameraPosition()
    if NOCLIP_SETTINGS.CAMERA.KEEP_POSITION and _internal_pos then
        return _internal_pos
    end

    return GetGameplayCamCoord()
end

function GetInitialCameraRotation()
    if NOCLIP_SETTINGS.CAMERA.KEEP_ROTATION and _internal_rot then
        return _internal_rot
    end

    local rot = GetGameplayCamRot(2)
    return vector3(rot.x, 0.0, rot.z)
end

function UpdateCamera()
    if not IsCamActive(_internal_camera) or IsPauseMenuActive() then return end
    if _internal_isFrozen then return end

    local vecX, vecY, vecZ = _internal_vecX, _internal_vecY, vector3(0,0,1)
    local pos, rot = _internal_pos, _internal_rot

    -- Input
    local speed = GetSpeedMultiplier()
    local lookX, lookY = GetSmartControlNormal(NOCLIP_SETTINGS.CONTROLS.LOOK_X), GetSmartControlNormal(NOCLIP_SETTINGS.CONTROLS.LOOK_Y)
    local moveX, moveY, moveZ = GetSmartControlNormal(NOCLIP_SETTINGS.CONTROLS.MOVE_X), GetSmartControlNormal(NOCLIP_SETTINGS.CONTROLS.MOVE_Y), GetSmartControlNormal(NOCLIP_SETTINGS.CONTROLS.MOVE_Z)

    -- Rotation
    local rotX = rot.x - lookY * NOCLIP_SETTINGS.LOOK_SENSITIVITY_X
    local rotZ = rot.z - lookX * NOCLIP_SETTINGS.LOOK_SENSITIVITY_Y
    rot = vector3(rotX, rot.y, rotZ)

    -- Position
    pos = pos + vecX * moveX * speed + vecY * -moveY * speed + vecZ * moveZ * speed

    SetFreecamPosition(pos.x, pos.y, pos.z)
    SetFreecamRotation(rot.x, rot.y, rot.z)
    return pos, rotZ
end

--==================--
--   NO FALLDAMAGE  --
--==================--
local function GetFallImpulse(H)
    return 1.6428571428571428 * H + 3.5714285714285836
end

local function DisableRagdollingWhileFall()
    CreateThread(function()
        local ped = PlayerPedId()
        local height = GetEntityHeightAboveGround(ped)
        if not height or height < 4.0 then return end

        local pid = PlayerId()
        SetEntityInvincible(ped, true)
        SetPlayerFallDistance(pid, 9000.0)

        ApplyForceToEntity(
            ped, 3,
            vector3(0, 0, -GetFallImpulse(height)),
            vector3(0, 0, 0),
            0, true, true, true, false, true
        )

        local elapsed, limit, step = 0, 1000, 25
        while not IsPedFalling(ped) and elapsed < limit do
            elapsed = elapsed + step
            Wait(step)
        end

        if not IsPedFalling(ped) then
            SetEntityInvincible(ped, false)
            SetPlayerFallDistance(pid, -1)
            return
        end

        repeat Wait(50) until not IsPedFalling(ped)
        Wait(750)

        SetEntityInvincible(ped, false)
        SetPlayerFallDistance(pid, -1)
    end)
end

--==================--
--    PARTICLE FX   --
--==================--
local function PlayPtfxSoundFivem(pedId)
    PlaySoundFromEntity(-1, NOCLIP_SETTINGS.PTFX.AUDIO.NAME, pedId, NOCLIP_SETTINGS.PTFX.AUDIO.REF, false, 0)
end

local function CreateNoClipPtfx(ped)
    CreateThread(function()
        RequestNamedPtfxAsset(NOCLIP_SETTINGS.PTFX.DICT)
        while not HasNamedPtfxAssetLoaded(NOCLIP_SETTINGS.PTFX.DICT) do Wait(5) end

        local particleTbl = {}
        for i = 0, NOCLIP_SETTINGS.PTFX.LOOP.AMOUNT do
            UseParticleFxAsset(NOCLIP_SETTINGS.PTFX.DICT)
            PlayPtfxSoundFivem(ped)
            local fx = StartParticleFxLoopedOnEntity(
                NOCLIP_SETTINGS.PTFX.ASSET, ped,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                NOCLIP_SETTINGS.PTFX.SCALE,
                false, false, false
            )
            particleTbl[#particleTbl+1] = fx
            Wait(NOCLIP_SETTINGS.PTFX.LOOP.DELAY)
        end

        Wait(NOCLIP_SETTINGS.PTFX.DURATION)
        for _, fx in ipairs(particleTbl) do
            StopParticleFxLooped(fx, true)
        end
        RemoveNamedPtfxAsset(NOCLIP_SETTINGS.PTFX.DICT)
    end)
end

--==================--
--    NOCLIP/VEH    --
--==================--
function ToggleNoClip(enabled)
    if enabled and NOCLIP_SETTINGS.COOLDOWN > 0 then 
        if NoClipCooldown > GetGameTimer() then return end
        NoClipCooldown = GetGameTimer() + NOCLIP_SETTINGS.COOLDOWN
    end

    local ped = PlayerPedId()
    NoClipEnabled = enabled

    SetEntityVisible(ped, not enabled)
    SetEntityInvincible(ped, enabled)

    if enabled then
        CreateNoClipPtfx(ped)
        FreeCamVeh = GetVehiclePedIsIn(ped, false)
        if FreeCamVeh > 0 then
            NetworkSetEntityInvisibleToNetwork(FreeCamVeh, true)
            SetEntityCollision(FreeCamVeh, false, false)
            SetEntityVisible(FreeCamVeh, false)
            FreezeEntityPosition(FreeCamVeh, true)
            SetVehicleCanBreak(FreeCamVeh, false)
            SetVehicleWheelsCanBreak(FreeCamVeh, false)
        end

        _internal_camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetFreecamFov(NOCLIP_SETTINGS.CAMERA.FOV)
        local pos, rot = GetGameplayCamCoord(), GetGameplayCamRot(2)
        SetFreecamPosition(pos.x, pos.y, pos.z)
        SetFreecamRotation(rot.x, 0, rot.z)
        RenderScriptCams(true, NOCLIP_SETTINGS.CAMERA.ENABLE_EASING, NOCLIP_SETTINGS.CAMERA.EASING_DURATION, true, true)
        StartFreecamThread()
    else
        RenderScriptCams(false, NOCLIP_SETTINGS.CAMERA.ENABLE_EASING, NOCLIP_SETTINGS.CAMERA.EASING_DURATION, true, true)
        DestroyCam(_internal_camera)
        ClearFocus()
        UnlockMinimapAngle()
        UnlockMinimapPosition()
        if FreeCamVeh > 0 then
            local coords = GetEntityCoords(ped)
            NetworkSetEntityInvisibleToNetwork(FreeCamVeh, false)
            SetEntityCoords(FreeCamVeh, coords.x, coords.y, coords.z, false, false, false, false)
            SetEntityCollision(FreeCamVeh, true, true)
            SetEntityVisible(FreeCamVeh, true)
            FreezeEntityPosition(FreeCamVeh, false)
            SetVehicleCanBreak(FreeCamVeh, true)
            SetVehicleWheelsCanBreak(FreeCamVeh, true)
            Wait(50)
            SetPedIntoVehicle(ped, FreeCamVeh, -1)
            TaskWarpPedIntoVehicle(ped, FreeCamVeh, -1)
        else
            SetEntityCoords(ped, _internal_pos.x, _internal_pos.y, _internal_pos.z, false, false, false, false)
            SetEntityHeading(ped, _internal_rot.z)
            DisableRagdollingWhileFall()
        end
        FreeCamVeh = 0
    end
end

--==================--
--    KEYBINDING    --
--==================--
RegisterCommand('noclip', function()
    ToggleNoClip(not NoClipEnabled)
end, false)
RegisterKeyMapping('noclip', 'Toggle NoClip', 'keyboard', NOCLIP_SETTINGS.KEYBIND)