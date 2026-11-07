-- [[
--   ======================================================================
--   🏎️ [RAYCITY RB] All-in-One Autonomous Speed, Auto Quest & Farm Hub
--   Author: Song Hub Official / Universal Edition
--   Target Game: Raycity RB (PlaceId: 117419079466193, UniverseId: 10772794231)
--   UI Framework: WindUI
--   Features:
--     - 🚗 Autonomous Quest Farming (Auto Drive on Road / Express Glide to Delivery)
--     - 💬 Auto Dialogue Skipper & Quest Offer Accepter
--     - 🎁 Auto Claim Quest EXP, Cash & Rain/Jewels
--     - 🔄 Auto Loop to Next NPC / Endless 24/7 Farm
--     - 👻 Ghost Traffic (No-Collision with NPC/Civilian Cars)
--     - ⚡ Super Speed Engine (80 - 600+ km/h with Acceleration Multiplier)
--     - 🛸 Car Flight / Hover Mode (Full 3D Air Cruising)
--     - 🔄 Anti-Flip Protection (Auto-Upright)
--     - 🔥 Infinite SP / Nitro Booster
--     - 🏎️ Super AutoDrive Tuning (Remove In-Game Speed Caps)
--     - ⚔️ Auto Road Fight & Whirl Skill Spam
--     - 🧲 Auto Item Vacuum (Pickups, Jewels & Booster Boxes)
--     - 📍 City Teleports (Districts, Garages, Shops & NPCs)
--     - 🛡️ Anti-Cheat Telemetry Shield & Anti-AFK
--   ======================================================================
-- ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Global Execution Guard
if _G.RaycityHubLoaded then
    warn("[Raycity Hub] Script is already running!")
    return
end
_G.RaycityHubLoaded = true

-- ==============================================================================
-- 🛡️ 1. ANTI-CHEAT BYPASS & SAFETY SHIELD
-- ==============================================================================
pcall(function()
    local acFolder = ReplicatedStorage:FindFirstChild("RaycityAntiCheat")
    if acFolder and acFolder:FindFirstChild("Remotes") then
        local remotes = acFolder.Remotes
        local acPush = remotes:FindFirstChild("AcPush")
        local acMove = remotes:FindFirstChild("AcMove")
        local acThrill = remotes:FindFirstChild("AcThrill")

        if hookmetamethod then
            local oldNamecall = nil
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if (method == "FireServer" or method == "fireServer") and (self == acPush or self == acMove or self == acThrill) then
                    return nil -- Silently drop telemetry
                end
                return oldNamecall(self, ...)
            end)
            print("[Raycity Hub] 🛡️ Anti-Cheat Telemetry Shield Activated!")
        end
    end
end)

-- ==============================================================================
-- 🚗 2. CAR & VEHICLE CONTROLLER (RCDRIVE INTEGRATED PHYSICS ENGINE)
-- ==============================================================================
local _cachedRCDrive = nil
local function getRCDrive()
    if _cachedRCDrive and _cachedRCDrive.phys then
        return _cachedRCDrive
    end
    local rcd = nil
    pcall(function()
        if getrenv then
            local renv = getrenv()
            if renv and renv.shared and renv.shared.RCDrive then
                rcd = renv.shared.RCDrive
            end
        end
    end)
    if not rcd and getsenv then
        pcall(function()
            local rClient = LocalPlayer.PlayerScripts:FindFirstChild("RCDriveClient")
            local env = rClient and getsenv(rClient)
            if env and env.shared and env.shared.RCDrive then
                rcd = env.shared.RCDrive
            end
        end)
    end
    if not rcd then
        pcall(function()
            if rawget(shared, "RCDrive") then
                rcd = rawget(shared, "RCDrive")
            end
        end)
    end
    if not rcd then
        pcall(function()
            if rawget(_G, "RCDrive") then
                rcd = rawget(_G, "RCDrive")
            end
        end)
    end
    if rcd then
        _cachedRCDrive = rcd
    end
    return rcd
end

local function getMyCar()
    local rcd = getRCDrive()
    if rcd and rcd.car and rcd.car.Parent then
        return rcd.car
    end
    local car = workspace:FindFirstChild("MyCar")
    if car and (car:FindFirstChild("Root") or car.PrimaryPart) then
        return car
    end
    local char = LocalPlayer.Character
    if char then
        for _, d in ipairs(workspace:GetDescendants()) do
            if (d:IsA("VehicleSeat") or d:IsA("Seat")) and d.Occupant and d.Occupant.Parent == char then
                return d.Parent
            end
        end
    end
    return nil
end

local function getCarRoot()
    local rcd = getRCDrive()
    if rcd and rcd.car then
        local r = rcd.car:FindFirstChild("Root") or rcd.car.PrimaryPart
        if r then return r end
    end
    local car = getMyCar()
    if car then
        return car:FindFirstChild("Root") or car.PrimaryPart
    end
    return nil
end

local function teleportCar(targetCF)
    if typeof(targetCF) == "Vector3" then
        targetCF = CFrame.new(targetCF + Vector3.new(0, 1.5, 0))
    end
    if not targetCF then return end

    local nativePos = targetCF.Position / 2
    local rot = targetCF - targetCF.Position

    -- 1. Sync through game's native RCDrive system (Prevents physics snap-back)
    local rcd = getRCDrive()
    if rcd then
        if type(rcd.teleport) == "function" then
            pcall(function()
                rcd.teleport(targetCF)
            end)
        end
        if type(rcd.phys) == "table" then
            pcall(function()
                rcd.phys.cf = CFrame.new(nativePos) * rot
                rcd.phys.v = Vector3.zero
                if rcd.phys.brake ~= nil then rcd.phys.brake = 0 end
                if rcd.phys.throttle ~= nil then rcd.phys.throttle = 0 end
            end)
        end
    end

    -- 2. Fallback / Roblox engine sync
    local root = getCarRoot()
    if root then
        root.CFrame = targetCF
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    local car = getMyCar()
    if car and car.PrimaryPart then
        pcall(function()
            car:PivotTo(targetCF)
        end)
    end
end

local function teleportCarWithVelocity(targetCF, vel)
    if typeof(targetCF) == "Vector3" then
        targetCF = CFrame.new(targetCF + Vector3.new(0, 1.5, 0))
    end
    if not targetCF then return end
    vel = vel or Vector3.zero

    local nativePos = targetCF.Position / 2
    local rot = targetCF - targetCF.Position

    local rcd = getRCDrive()
    if rcd then
        if type(rcd.teleport) == "function" then
            pcall(function()
                rcd.teleport(targetCF)
            end)
        end
        if type(rcd.phys) == "table" then
            pcall(function()
                rcd.phys.cf = CFrame.new(nativePos) * rot
                if vel.Magnitude > 0.1 then
                    rcd.phys.v = vel / 2
                    rcd.phys.throttle = 1
                    rcd.phys.boosting = true
                else
                    rcd.phys.v = Vector3.zero
                end
            end)
        end
    end

    local root = getCarRoot()
    if root then
        root.CFrame = targetCF
        root.AssemblyLinearVelocity = vel
        root.AssemblyAngularVelocity = Vector3.zero
    end
    local car = getMyCar()
    if car and car.PrimaryPart then
        pcall(function()
            car:PivotTo(targetCF)
        end)
    end
end

local function driveCarStep(targetPos, speedKmh, isAir)
    local root = getCarRoot()
    local rcd = getRCDrive()
    if not root then return end

    local currentPos = root.Position
    local dir = targetPos - currentPos
    local dist = dir.Magnitude
    if dist < 0.5 then return end

    local speedMps = (speedKmh or 300) / 3.6
    local moveDir
    local nextPos = currentPos

    if isAir then
        moveDir = dir.Unit
        root.AssemblyLinearVelocity = moveDir * speedMps
        root.AssemblyAngularVelocity = Vector3.zero
    else
        -- 🚗 Ground road driving mode: Wheels firmly on the tarmac!
        local flatDir = Vector3.new(dir.X, 0, dir.Z)
        moveDir = flatDir.Magnitude > 0.1 and flatDir.Unit or Vector3.new(0, 0, -1)

        -- Raycast to find exact road elevation
        local groundRay = workspace:Raycast(currentPos + Vector3.new(0, 5, 0), Vector3.new(0, -35, 0))
        local roadY = groundRay and (groundRay.Position.Y + 1.2) or targetPos.Y

        -- Snap Y smoothly to road surface
        local smoothY = math.abs(currentPos.Y - roadY) > 0.2 and roadY or currentPos.Y
        nextPos = Vector3.new(currentPos.X, smoothY, currentPos.Z)

        -- Downward velocity ensures all wheels make solid contact with the road
        root.AssemblyLinearVelocity = moveDir * speedMps + Vector3.new(0, -6, 0)
        root.AssemblyAngularVelocity = Vector3.zero
    end

    local nextLook = nextPos + moveDir * 10
    root.CFrame = CFrame.lookAt(nextPos, nextLook)

    -- 2. Sync native RCDrive system
    if rcd and type(rcd.phys) == "table" then
        pcall(function()
            rcd.phys.throttle = 1
            rcd.phys.brake = 0
            rcd.phys.boosting = true
            rcd.phys.handbrake = false
            if isAir then
                rcd.phys.airMode = true
            else
                rcd.phys.airMode = false
                rcd.phys.anyContact = true
            end
            local stepVel = moveDir * speedMps
            rcd.phys.v = stepVel / 2
            local nativePos = nextPos / 2
            rcd.phys.cf = CFrame.lookAt(nativePos, (nextPos + moveDir * 10) / 2)
        end)
    end
end

-- ==============================================================================
-- ⚙️ 3. CONFIGURATION & STATE
-- ==============================================================================
local Config = {
    -- Autonomous Quest Farming
    AutoFarmQuests = false,
    QuestDriveMode = "Instant Warp", -- "Instant Warp" | "Hyper Sonic Glide" | "Realistic Road Drive" | "Hybrid Cruise"
    QuestDriveSpeed = 500, -- km/h
    AutoSkipDialogue = true,
    AutoAcceptQuest = true,
    AutoClaimRewards = true,
    LoopNextQuest = true,
    GhostTraffic = true,

    -- Speed & Driving
    SpeedBoostEnabled = false,
    TargetSpeedKmh = 250,
    AccelerationMultiplier = 2.0,
    InfiniteBoost = false,
    AntiFlip = true,
    InstantBrakeKey = Enum.KeyCode.X,

    -- Car Flight
    FlyEnabled = false,
    FlySpeed = 150,

    -- Auto Drive Tuning
    SuperAutoDrive = false,
    AutoDriveMaxSpeed = 200,

    -- Auto Road Fight
    AutoRoadFight = false,
    AutoWhirlSkill = false,

    -- Auto Pickups
    AutoPickups = false,
    PickupRadius = 150,

    -- Safety & Utility
    AntiAfk = true,
    FastMode = false
}

-- ==============================================================================
-- 👻 4. GHOST TRAFFIC (NOCLIP THROUGH CIVILIAN CARS)
-- ==============================================================================
task.spawn(function()
    while true do
        task.wait(1.5)
        if Config.GhostTraffic then
            pcall(function()
                local traffic = workspace:FindFirstChild("RBRCTrafficCars")
                if traffic then
                    for _, car in ipairs(traffic:GetChildren()) do
                        for _, p in ipairs(car:GetDescendants()) do
                            if p:IsA("BasePart") and p.CanCollide then
                                p.CanCollide = false
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ==============================================================================
-- 💬 5. AUTO DIALOGUE SKIPPER & QUEST ACCEPTER
-- ==============================================================================
local function pressReturnKey()
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local qGui = pg and pg:FindFirstChild("RaycityQuestUi")
        if qGui and qGui.Enabled then
            local npcDialog = qGui:FindFirstChild("NpcDialog", true)
            if npcDialog and npcDialog.Visible then
                local nextBtn = npcDialog:FindFirstChild("Next", true) or npcDialog:FindFirstChild("ต่อไป", true)
                if nextBtn then
                    if getconnections then
                        for _, c in ipairs(getconnections(nextBtn.Activated)) do pcall(function() c:Fire() end) end
                        for _, c in ipairs(getconnections(nextBtn.MouseButton1Click)) do pcall(function() c:Fire() end) end
                    end
                    if firesignal then
                        pcall(function() firesignal(nextBtn.Activated) end)
                        pcall(function() firesignal(nextBtn.MouseButton1Click) end)
                    end
                end
            end
            local missionOffer = qGui:FindFirstChild("MissionOffer", true)
            if missionOffer and missionOffer.Visible then
                local yesBtn = missionOffer:FindFirstChild("Yes", true)
                if yesBtn then
                    if getconnections then
                        for _, c in ipairs(getconnections(yesBtn.Activated)) do pcall(function() c:Fire() end) end
                        for _, c in ipairs(getconnections(yesBtn.MouseButton1Click)) do pcall(function() c:Fire() end) end
                    end
                end
            end
        end
    end)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        if vim then
            vim:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            task.wait(0.02)
            vim:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        end
    end)
    pcall(function()
        local RaycityUi = ReplicatedStorage:FindFirstChild("RaycityUi")
        local RaycityEscGate = RaycityUi and RaycityUi:FindFirstChild("RaycityEscGate")
        if RaycityEscGate then
            require(RaycityEscGate).virtualEnter()
        end
    end)
    pcall(function()
        local qUi = require(ReplicatedStorage.RBRCQuest.QuestUI)
        if qUi and qUi._dialogEnter then
            qUi._dialogEnter()
        end
    end)
end

local function fireGuiClick(btn)
    if not btn then return end
    pcall(function()
        if firesignal then
            firesignal(btn.Activated)
            firesignal(btn.MouseButton1Click)
            firesignal(btn.MouseButton1Up)
        end
        if getconnections then
            for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
            for _, c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
            for _, c in ipairs(getconnections(btn.MouseButton1Up)) do c:Fire() end
        end
        local vim = game:GetService("VirtualInputManager")
        if vim and btn:IsA("GuiObject") and btn.Visible then
            local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            task.wait(0.02)
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(0.08)
        if Config.AutoFarmQuests or Config.AutoSkipDialogue or Config.AutoAcceptQuest then
            pcall(function()
                local qUi = nil
                pcall(function() qUi = require(ReplicatedStorage.RBRCQuest.QuestUI) end)
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                local qGui = pg and pg:FindFirstChild("RaycityQuestUi")

                if qGui and qGui.Enabled then
                    -- 1. Advance NPC Dialogue (NpcDialog)
                    local npcDialog = qGui:FindFirstChild("NpcDialog", true)
                    if npcDialog and npcDialog.Visible then
                        local nextBtn = npcDialog:FindFirstChild("Next", true) or npcDialog:FindFirstChild("ต่อไป", true)
                        if nextBtn then
                            fireGuiClick(nextBtn)
                        end
                        if qUi and qUi._dialogEnter then
                            pcall(qUi._dialogEnter)
                        end
                        pressReturnKey()
                    end

                    -- 2. Auto Accept Quest Offer (MissionOffer)
                    local missionOffer = qGui:FindFirstChild("MissionOffer", true)
                    if missionOffer and missionOffer.Visible then
                        local yesBtn = missionOffer:FindFirstChild("Yes", true)
                        if yesBtn then
                            fireGuiClick(yesBtn)
                        end
                        if qUi and qUi._offerAnswer then
                            pcall(function() qUi._offerAnswer(1) end)
                            pcall(function() qUi._offerAnswer(true) end)
                        end
                        pressReturnKey()
                    end

                    -- Fallback for generic offer frames
                    local otherOffer = qGui:FindFirstChild("Offer", true) or qGui:FindFirstChild("QuestOffer", true)
                    if otherOffer and otherOffer.Visible and otherOffer ~= missionOffer then
                        local acceptBtn = otherOffer:FindFirstChild("Accept", true) or otherOffer:FindFirstChild("Ok", true) or otherOffer:FindFirstChild("Yes", true)
                        if acceptBtn then
                            fireGuiClick(acceptBtn)
                        end
                        if qUi and qUi._offerAnswer then
                            pcall(function() qUi._offerAnswer(1) end)
                        end
                        pressReturnKey()
                    end

                    -- 3. Auto Close / Claim Result Dialog (MissionResult, Result, QuestResult, Drops)
                    local resultDialog = qGui:FindFirstChild("MissionResult", true) or qGui:FindFirstChild("Result", true) or qGui:FindFirstChild("QuestResult", true) or qGui:FindFirstChild("Drops", true)
                    if resultDialog and resultDialog.Visible then
                        if qUi then
                            if qUi.hideResult then pcall(qUi.hideResult) end
                            if qUi.closeDrops then pcall(qUi.closeDrops) end
                            if qUi._dialogEnter then pcall(qUi._dialogEnter) end
                        end
                        local closeBtn = resultDialog:FindFirstChild("Close", true) or resultDialog:FindFirstChild("Confirm", true) or resultDialog:FindFirstChild("Ok", true)
                        if closeBtn then
                            fireGuiClick(closeBtn)
                        end
                        pressReturnKey()
                    end
                end

                -- Auto respond if RBRCNpcTalkPrompt is visible
                local ntp = pg and pg:FindFirstChild("RBRCNpcTalkPrompt")
                if ntp and ntp.Enabled and Config.AutoFarmQuests then
                    pressReturnKey()
                end

                -- Auto confirm AutoDrive popup or generic confirm windows if present
                for _, g in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
                    if g:IsA("ScreenGui") and (g.Name:lower():find("confirm") or g.Name:lower():find("autodrive")) then
                        local yes = g:FindFirstChild("Yes", true) or g:FindFirstChild("Confirm", true) or g:FindFirstChild("Ok", true)
                        if yes and yes:IsA("GuiButton") and yes.Visible then
                            fireGuiClick(yes)
                        end
                    end
                end
            end)
        end
    end
end)

-- ==============================================================================
-- 🏁 6. ACTIVE QUEST DESTINATION DETECTOR
-- ==============================================================================
local function findQuestTargetNpc(targetName)
    if not targetName or targetName == "" then return nil end
    local cleanName = targetName:gsub("^%s+", ""):gsub("%s+$", ""):lower()
    local npcsFolder = workspace:FindFirstChild("RBRCNpcs")
    if not npcsFolder then return nil end

    local rep = game:GetService("ReplicatedStorage")
    local npcNames = nil
    pcall(function() npcNames = require(rep.RBRCQuest.NpcNames) end)

    -- 1. Check exact or partial NPC model name
    for _, npc in ipairs(npcsFolder:GetChildren()) do
        if npc.Name:lower():find(cleanName, 1, true) then
            return npc
        end
    end

    -- 2. Resolve via NpcNames module
    if npcNames then
        local targetId = nil
        for id, name in pairs(npcNames.questNpc or {}) do
            if tostring(name):lower() == cleanName then
                targetId = tostring(id):match("(%d+)$")
                break
            end
        end
        if not targetId then
            for id, name in pairs(npcNames.mission or {}) do
                if tostring(name):lower() == cleanName then
                    local num = tostring(id):match(":(%d+)$") or tostring(id):match("(%d+)$")
                    if num and npcsFolder:FindFirstChild("Npc_" .. num) then
                        targetId = num
                        break
                    elseif not targetId then
                        targetId = num
                    end
                end
            end
        end
        if not targetId then
            local bestLen = 0
            for id, name in pairs(npcNames.questNpc or {}) do
                local n = tostring(name):lower()
                if cleanName:find(n, 1, true) or n:find(cleanName, 1, true) then
                    if #n > bestLen then
                        bestLen = #n
                        targetId = tostring(id):match("(%d+)$")
                    end
                end
            end
            for id, name in pairs(npcNames.mission or {}) do
                local n = tostring(name):lower()
                if cleanName:find(n, 1, true) or n:find(cleanName, 1, true) then
                    if #n > bestLen then
                        bestLen = #n
                        targetId = tostring(id):match(":(%d+)$") or tostring(id):match("(%d+)$")
                    end
                end
            end
        end

        if targetId then
            -- Pass 1: exact number match (e.g. Npc_1 for targetId "1")
            for _, npc in ipairs(npcsFolder:GetChildren()) do
                local num = npc.Name:match("(%d+)$")
                if num == targetId then
                    return npc
                end
            end
            -- Pass 2: suffix / substring match (e.g. Npc_939900 for targetId "9900")
            for _, npc in ipairs(npcsFolder:GetChildren()) do
                local num = npc.Name:match("(%d+)$")
                if num and (num:sub(-#targetId) == targetId or targetId:sub(-#num) == num) then
                    return npc
                end
            end
        end
    end

    -- 3. Check text labels in NPC models
    for _, npc in ipairs(npcsFolder:GetChildren()) do
        for _, d in ipairs(npc:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text ~= "" then
                local t = d.Text:lower()
                if t:find(cleanName, 1, true) or cleanName:find(t, 1, true) then
                    return npc
                end
            end
        end
    end

    return nil
end

local function getActiveMissionTarget()
    local targetPos, missionObj, missionType = nil, nil, nil
    pcall(function()
        local rs = game:GetService("RunService")
        local conns = getconnections and getconnections(rs.Heartbeat)
        if conns then
            for _, c in ipairs(conns) do
                local fn = c.Function
                if fn and tostring(debug.getinfo(fn).short_src):find("RBRCQuestClient") then
                    local uvs = debug.getupvalues(fn)
                    local mState = uvs and uvs[2]
                    if type(mState) == "table" and (mState.state == "running" or mState.state == "boarding") and type(mState.objectives) == "table" then
                        missionType = mState.state
                        for _, obj in ipairs(mState.objectives) do
                            if obj.active and not obj.done and typeof(obj.target) == "Vector3" then
                                targetPos = obj.target
                                missionObj = obj
                                break
                            end
                        end
                    end
                    break
                end
            end
        end
    end)
    return targetPos, missionObj, missionType
end

local function getActiveQuestDestination()
    -- Priority 1: Live Active Taxi/Driving Mission checkpoints from RBRCQuestClient
    local mTarget, mObj, mState = getActiveMissionTarget()
    if mTarget then
        return mTarget, nil, nil, "checkpoint", mState
    end

    -- Priority 2: Navigation GuideLine (Ground Truth from RaycityUi.Navigation)
    local okNav, nav = pcall(function() return require(ReplicatedStorage.RaycityUi.Navigation) end)
    if okNav and nav then
        if nav.getGuideLine then
            local okGl, gl = pcall(nav.getGuideLine)
            if okGl and gl and gl.target then
                return gl.target, nil, gl.points, "guideline", nil
            end
        end
        if nav.getGuide then
            local okG, g = pcall(nav.getGuide)
            if okG and g and g.destRoblox then
                return g.destRoblox, nil, nil, "guide", nil
            end
        end
    end

    -- Priority 3: Parse active quest from Favorite UI (RBRCQuestFavorite)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local fav = pg and pg:FindFirstChild("RBRCQuestFavorite")
    local questTexts = {}
    if fav and fav.Enabled then
        for _, d in ipairs(fav:GetDescendants()) do
            if d:IsA("TextLabel") and d.Visible and d.Text ~= "" then
                table.insert(questTexts, d.Text)
            end
        end
    end

    local subQuestNpc = nil
    local returnNpc = nil
    for _, txt in ipairs(questTexts) do
        -- Check for incomplete subquest like "ภารกิจ - มาดามอันตราย  0/1"
        local taskName, curr, maxVal = txt:match("([^\n\r%d%/]+)%s*(%d+)%s*/%s*(%d+)")
        if taskName and curr and maxVal then
            local cNum = tonumber(curr) or 0
            local mNum = tonumber(maxVal) or 1
            if cNum < mNum then
                local cleanTask = taskName:gsub("ภารกิจ", ""):gsub("%-", ""):gsub("^%s+", ""):gsub("%s+$", "")
                local npc = findQuestTargetNpc(cleanTask)
                if npc then
                    subQuestNpc = npc
                end
            end
        end

        local retName = txt:match("กลับไปหา%s*([^\n\r]+)")
            or txt:match("ไปพบ%s*([^\n\r]+)")
            or txt:match("คุยกับ%s*([^\n\r]+)")
        if retName then
            local cleanRet = retName:gsub("%d+/%d+", ""):gsub("[%[%]]", ""):gsub("^%s+", ""):gsub("%s+$", "")
            local npc = findQuestTargetNpc(cleanRet)
            if npc then
                returnNpc = npc
            end
        end
    end

    local targetNpcModel = subQuestNpc or returnNpc
    if targetNpcModel then
        local p = targetNpcModel.PrimaryPart or targetNpcModel:FindFirstChild("Root") or targetNpcModel:FindFirstChildWhichIsA("BasePart")
        if p then
            return p.Position, targetNpcModel, nil, "npc", nil
        end
    end

    -- Priority 4: Existing workspace quest markers
    local qMarkers = workspace:FindFirstChild("RBRCQuestMarkers") or workspace:FindFirstChild("RBRCQuestGuide")
    if qMarkers then
        for _, m in ipairs(qMarkers:GetChildren()) do
            local p = m:IsA("BasePart") and m or m:FindFirstChildWhichIsA("BasePart") or (m:IsA("Model") and m.PrimaryPart)
            if p then
                return p.Position, p, nil, "marker", nil
            end
        end
    end

    return nil, nil, nil, nil, nil
end

-- ==============================================================================
-- 🚗 7. MASTER AUTONOMOUS QUEST FARMING ENGINE (ขับเองอัตโนมัติ)
-- ==============================================================================
local questFarmState = "SEARCHING" -- "SEARCHING" | "DRIVING" | "DELIVERING"
local lastStuckPos = nil
local stuckCounter = 0

task.spawn(function()
    while true do
        task.wait(0.06)
        if Config.AutoFarmQuests then
            local root = getCarRoot()
            local rcd = getRCDrive()
            if root then
                local destPos, destObj, points, destType, mState = getActiveQuestDestination()

                -- Wait while passenger is boarding taxi
                if mState == "boarding" then
                    task.wait(0.5)
                    continue
                end

                -- Anti-Stuck Detection (only when driving towards destination)
                if destPos and destType ~= "npc" then
                    if lastStuckPos and (root.Position - lastStuckPos).Magnitude < 1.5 then
                        stuckCounter = stuckCounter + 1
                        if stuckCounter >= 12 then -- Stuck for ~0.7 second
                            local forward = root.CFrame.LookVector
                            teleportCar(root.CFrame + Vector3.new(0, 3, 0) + forward * 8)
                            stuckCounter = 0
                        end
                    else
                        lastStuckPos = root.Position
                        stuckCounter = 0
                    end
                else
                    stuckCounter = 0
                    lastStuckPos = root.Position
                end

                if destPos then
                    -- ==========================================================
                    -- A. QUEST IN PROGRESS: REACH DESTINATION AT LIGHTNING SPEED
                    -- ==========================================================
                    questFarmState = "DRIVING"
                    local dist = (root.Position - destPos).Magnitude

                    if destType == "checkpoint" then
                        -- Checkpoint Gate: Must pass through at speed (> 100 km/h) on road to trigger
                        if dist > 20 then
                            if Config.QuestDriveMode == "Instant Warp" then
                                local forward = (destPos - root.Position).Unit
                                teleportCarWithVelocity(CFrame.lookAt(destPos - forward * 8, destPos), forward * 60)
                            elseif Config.QuestDriveMode == "Hyper Sonic Glide" and dist > 150 then
                                -- Glide in air while far away (> 150 studs)
                                driveCarStep(destPos + Vector3.new(0, 4, 0), Config.QuestDriveSpeed, true)
                            else
                                -- Before reaching checkpoint (<= 150 studs): Drive normally on the road!
                                driveCarStep(destPos, math.max(120, Config.QuestDriveSpeed), false)
                            end
                        else
                            -- Pass smoothly through the gate on road level
                            driveCarStep(destPos, math.max(120, Config.QuestDriveSpeed), false)
                            task.wait(0.03)
                        end
                    else
                        -- Standard NPC or Delivery Destination
                        if Config.QuestDriveMode == "Instant Warp" then
                            if points and #points > 0 and dist > 25 then
                                local step = math.max(1, math.floor(#points / 15))
                                for i = 1, #points, step do
                                    local pt = points[i]
                                    local lookNext = points[i + step] or destPos
                                    local dir = (lookNext - pt)
                                    local vel = dir.Magnitude > 0.1 and (dir.Unit * 60) or Vector3.new(0, 0, -60)
                                    local targetCF = CFrame.lookAt(pt + Vector3.new(0, 1.5, 0), lookNext + Vector3.new(0, 1.5, 0))
                                    teleportCarWithVelocity(targetCF, vel)
                                    task.wait(0.015)
                                end
                            end
                            driveCarStep(destPos, 0, false)
                            dist = 0
                        end

                        if dist > 14 then
                            if Config.QuestDriveMode == "Hyper Sonic Glide" and dist > 150 then
                                -- Glide in air for speed while far away (> 150 studs)
                                driveCarStep(destPos + Vector3.new(0, 8, 0), Config.QuestDriveSpeed, true)
                            elseif Config.QuestDriveMode == "Realistic Road Drive" then
                                local nextWp = nil
                                if points and #points > 0 then
                                    for i = 1, #points do
                                        local pDist = (points[i] - root.Position).Magnitude
                                        if pDist > 10 and (points[i] - root.Position):Dot(destPos - root.Position) > -5 then
                                            nextWp = points[i]
                                            break
                                        end
                                    end
                                end
                                driveCarStep(nextWp or destPos, Config.QuestDriveSpeed, false)
                            else
                                -- Before reaching destination (<= 150 studs): Drive normally on the road without flying!
                                driveCarStep(destPos, math.min(130, Config.QuestDriveSpeed), false)
                            end
                        else
                            -- ==========================================================
                            -- B. ARRIVED AT OBJECTIVE ON THE ROAD: COMPLETE & CLAIM
                            -- ==========================================================
                            questFarmState = "DELIVERING"
                            driveCarStep(destPos, 0, false)

                            -- Solid brake on the road so interaction triggers 100%
                            if rcd and rcd.phys then
                                rcd.phys.v = Vector3.zero
                                rcd.phys.throttle = 0
                                rcd.phys.brake = 1
                                rcd.phys.airMode = false
                                rcd.phys.anyContact = true
                            end
                            root.AssemblyLinearVelocity = Vector3.zero
                            root.AssemblyAngularVelocity = Vector3.zero

                            -- Stop native AutoDrive if running
                            pcall(function()
                                local RaycityUi = ReplicatedStorage:FindFirstChild("RaycityUi")
                                if RaycityUi and RaycityUi:FindFirstChild("AutoDrive") then
                                    require(RaycityUi.AutoDrive).stop()
                                end
                            end)

                            -- Trigger Touch on destination marker
                            if destObj and destObj:IsA("BasePart") and firetouchinterest then
                                pcall(function()
                                    firetouchinterest(root, destObj, 0)
                                    task.wait(0.02)
                                    firetouchinterest(root, destObj, 1)
                                end)
                            end

                            -- Trigger Trunk / Delivery completion
                            pcall(function()
                                local rep = game:GetService("ReplicatedStorage")
                                local qDeliver = require(rep.RBRCQuest.QuestDeliver)
                                if qDeliver then
                                    if qDeliver.finish then qDeliver.finish() end
                                    if qDeliver.trunk then qDeliver.trunk(true) end
                                end
                            end)

                            -- Submit delivery via server remotes
                            pcall(function()
                                local qRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
                                if qRemotes then
                                    if qRemotes:FindFirstChild("QuestEventUp") then
                                        qRemotes.QuestEventUp:FireServer("GoalReached", destObj and destObj.Name or "Goal")
                                    end
                                    if qRemotes:FindFirstChild("QuestRequest") then
                                        qRemotes.QuestRequest:InvokeServer("ClaimCurrentQuest")
                                        qRemotes.QuestRequest:InvokeServer("CompleteQuest")
                                        qRemotes.QuestRequest:InvokeServer("FinishQuest")
                                    end
                                end
                            end)

                            -- Auto dismiss / claim rewards screen
                            pcall(function()
                                local qUi = require(ReplicatedStorage.RBRCQuest.QuestUI)
                                if qUi then
                                    if qUi.hideResult then qUi.hideResult() end
                                    if qUi.closeDrops then qUi.closeDrops() end
                                    if qUi._dialogEnter then qUi._dialogEnter() end
                                end
                            end)

                            -- Send Enter key & virtual Enter to confirm delivery or start NPC conversation
                            pressReturnKey()

                            task.wait(0.25)
                        end
                    end
                else
                    -- ==========================================================
                    -- C. NO ACTIVE QUEST IN PROGRESS: FIND QUEST GIVER NPC
                    -- ==========================================================
                    if Config.LoopNextQuest then
                        questFarmState = "SEARCHING"
                        local targetNpc, targetDist = nil, 99999
                        local npcsFolder = workspace:FindFirstChild("RBRCNpcs")

                        -- 1. First priority: Welcome Newbie (Npc_939900)
                        local newbie = npcsFolder and npcsFolder:FindFirstChild("Npc_939900")
                        if newbie then
                            local nPart = newbie.PrimaryPart or newbie:FindFirstChild("Root") or newbie:FindFirstChildWhichIsA("BasePart")
                            if nPart then
                                targetNpc = nPart
                                targetDist = (root.Position - nPart.Position).Magnitude
                            end
                        end

                        -- 2. Fallback: Nearest NPC in RBRCNpcs
                        if not targetNpc and npcsFolder then
                            for _, npc in ipairs(npcsFolder:GetChildren()) do
                                local nPart = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart")
                                if nPart then
                                    local d = (root.Position - nPart.Position).Magnitude
                                    if d < targetDist then
                                        targetDist = d
                                        targetNpc = nPart
                                    end
                                end
                            end
                        end

                        if targetNpc then
                            if Config.QuestDriveMode == "Instant Warp" then
                                teleportCar(CFrame.lookAt(targetNpc.Position + Vector3.new(0, 1.5, 4), targetNpc.Position))
                                targetDist = 4
                            end

                            if targetDist > 14 then
                                if Config.QuestDriveMode == "Hyper Sonic Glide" and targetDist > 75 then
                                    driveCarStep(targetNpc.Position + Vector3.new(0, 8, 0), Config.QuestDriveSpeed, true)
                                else
                                    -- Within 75 studs: Drive on road at ground level
                                    driveCarStep(targetNpc.Position, math.min(120, Config.QuestDriveSpeed), false)
                                end
                            else
                                -- Arrived at NPC: Stop car and interact to accept quest!
                                teleportCar(CFrame.lookAt(targetNpc.Position + Vector3.new(0, 1.5, 4), targetNpc.Position))
                                if rcd and rcd.phys then
                                    rcd.phys.v = Vector3.zero
                                end
                                root.AssemblyLinearVelocity = Vector3.zero

                                pressReturnKey()
                                task.wait(0.25)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ==============================================================================
-- 🚀 8. VEHICLE SPEED & FLIGHT CONTROLLER
-- ==============================================================================
local flyBodyGyro = nil
local flyBodyVelocity = nil

local function updateFlyState()
    local root = getCarRoot()
    if not root then return end

    if Config.FlyEnabled then
        if not flyBodyGyro then
            flyBodyGyro = Instance.new("BodyGyro")
            flyBodyGyro.P = 9e4
            flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            flyBodyGyro.CFrame = root.CFrame
            flyBodyGyro.Parent = root
        end
        if not flyBodyVelocity then
            flyBodyVelocity = Instance.new("BodyVelocity")
            flyBodyVelocity.Velocity = Vector3.zero
            flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            flyBodyVelocity.Parent = root
        end

        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDir = moveDir + Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDir = moveDir - Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDir = moveDir - Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDir = moveDir + Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end

        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit
            flyBodyVelocity.Velocity = moveDir * (Config.FlySpeed / 3.6)
            flyBodyGyro.CFrame = CFrame.lookAt(root.Position, root.Position + moveDir)
        else
            flyBodyVelocity.Velocity = Vector3.zero
            flyBodyGyro.CFrame = root.CFrame
        end
    else
        if flyBodyGyro then
            flyBodyGyro:Destroy()
            flyBodyGyro = nil
        end
        if flyBodyVelocity then
            flyBodyVelocity:Destroy()
            flyBodyVelocity = nil
        end
    end
end

-- Ground Speed Multiplier & Anti-Flip Loop
RunService.Heartbeat:Connect(function(dt)
    local root = getCarRoot()
    if not root then return end

    -- Flight handling
    if Config.FlyEnabled then
        updateFlyState()
        pcall(function()
            local rcd = getRCDrive()
            if rcd and rcd.phys then
                rcd.phys.airMode = true
                rcd.phys.brake = 0
                if flyBodyVelocity then
                    rcd.phys.v = flyBodyVelocity.Velocity
                    rcd.phys.p = root.Position
                    rcd.phys.cf = root.CFrame
                end
            end
        end)
        return
    end

    -- Speed Booster on Manual Driving
    if Config.SpeedBoostEnabled and not Config.FlyEnabled and not Config.AutoFarmQuests then
        local currentVel = root.AssemblyLinearVelocity
        local forward = root.CFrame.LookVector
        local currentKmh = currentVel.Magnitude * 3.6

        if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
            if currentKmh < Config.TargetSpeedKmh then
                local targetVel = forward * (Config.TargetSpeedKmh / 3.6)
                root.AssemblyLinearVelocity = currentVel:Lerp(targetVel, math.clamp(dt * Config.AccelerationMultiplier * 3, 0, 1))
                pcall(function()
                    local rcd = getRCDrive()
                    if rcd and rcd.phys then
                        rcd.phys.throttle = 1
                        rcd.phys.brake = 0
                        rcd.phys.boosting = true
                        rcd.phys.v = root.AssemblyLinearVelocity
                    end
                end)
            end
        end
    end

    -- Anti-Flip Protection (Auto-Upright)
    if Config.AntiFlip and not Config.FlyEnabled then
        local up = root.CFrame.UpVector
        if up.Y < 0.5 then -- Car is tilted > 60 degrees or upside down
            local currentPos = root.Position
            local look = root.CFrame.LookVector
            local flatLook = Vector3.new(look.X, 0, look.Z).Unit
            if flatLook.Magnitude > 0.1 then
                local uprightCF = CFrame.lookAt(currentPos + Vector3.new(0, 2, 0), currentPos + flatLook * 10)
                teleportCar(uprightCF)
            end
        end
    end
end)

-- Instant Brake Key Handler
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Config.InstantBrakeKey then
        local root = getCarRoot()
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
        pcall(function()
            local rcd = getRCDrive()
            if rcd and rcd.phys then
                rcd.phys.v = Vector3.zero
                rcd.phys.throttle = 0
                rcd.phys.brake = 1
            end
        end)
    end
end)

-- Infinite Booster / SP Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.InfiniteBoost then
            pcall(function()
                local car = getMyCar()
                if car then
                    car:SetAttribute("CurrentSP", 1000)
                    car:SetAttribute("MaxSP", 1000)
                    car:SetAttribute("BoosterActive", true)
                end
                local rcd = getRCDrive()
                if rcd and rcd.phys then
                    rcd.phys.boosting = true
                end
            end)
        end
    end
end)

-- Super AutoDrive Engine Hook
task.spawn(function()
    while true do
        task.wait(1)
        if Config.SuperAutoDrive then
            pcall(function()
                local RaycityUi = ReplicatedStorage:FindFirstChild("RaycityUi")
                if RaycityUi and RaycityUi:FindFirstChild("AutoDrive") then
                    local ad = require(RaycityUi.AutoDrive)
                    if ad and ad.C then
                        ad.C.maxSpeed = Config.AutoDriveMaxSpeed / 3.6
                        ad.C.cap1 = 80
                        ad.C.cap2 = 60
                        ad.C.cap3 = 45
                        ad.C.arriveSlowM = 5
                        ad.C.arriveSlowerM = 2
                    end
                end
            end)
        end
    end
end)

-- Auto Road Fight & Whirl Skill Loop
task.spawn(function()
    while true do
        task.wait(0.3)
        if Config.AutoRoadFight then
            local missionCars = workspace:FindFirstChild("RBRCMissionCars")
            local root = getCarRoot()

            if missionCars and root then
                local targetEnemy = nil
                local closestDist = 99999

                for _, car in ipairs(missionCars:GetChildren()) do
                    local enemyRoot = car:FindFirstChild("Root") or car.PrimaryPart
                    if enemyRoot then
                        local d = (root.Position - enemyRoot.Position).Magnitude
                        if d < closestDist then
                            closestDist = d
                            targetEnemy = enemyRoot
                        end
                    end
                end

                if targetEnemy then
                    -- Position car slightly behind target and ram/attack
                    root.CFrame = CFrame.lookAt(root.Position, targetEnemy.Position)
                    root.AssemblyLinearVelocity = (targetEnemy.Position - root.Position).Unit * 120

                    -- Spam Whirl skill if enabled
                    if Config.AutoWhirlSkill then
                        pcall(function()
                            local remotes = ReplicatedStorage.RBRCQuest.Remotes
                            if remotes:FindFirstChild("WhirlCast") then
                                remotes.WhirlCast:FireServer()
                            end
                            if remotes:FindFirstChild("WhirlHit") then
                                remotes.WhirlHit:FireServer(targetEnemy.Parent)
                            end
                        end)
                    end
                end
            end
        end
    end
end)

-- ==============================================================================
-- 💎 9. AUTO PICKUP VACUUM
-- ==============================================================================
task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.AutoPickups then
            local root = getCarRoot()
            if root then
                local pickups = workspace:FindFirstChild("Pickups") or workspace:FindFirstChild("PickupSpots")
                local pickupRemote = ReplicatedStorage:FindFirstChild("RaycityPickups") 
                    and ReplicatedStorage.RaycityPickups:FindFirstChild("Remotes") 
                    and ReplicatedStorage.RaycityPickups.Remotes:FindFirstChild("PickupEat")

                if pickups and pickupRemote then
                    for _, p in ipairs(pickups:GetChildren()) do
                        local part = p:IsA("BasePart") and p or p:FindFirstChildWhichIsA("BasePart")
                        if part and (root.Position - part.Position).Magnitude <= Config.PickupRadius then
                            pcall(function()
                                pickupRemote:FireServer(p.Name)
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- ==============================================================================
-- 🛡️ 10. ANTI-AFK PROTECTION
-- ==============================================================================
if Config.AntiAfk then
    LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end

-- ==============================================================================
-- 🗺️ 11. PRESET CITY TELEPORT LOCATIONS
-- ==============================================================================
local CITY_WAYPOINTS = {
    ["🏙️ City Center / Start"] = Vector3.new(-482, 44, -5589),
    ["🏢 Gangnam District"] = Vector3.new(1250, 45, -3420),
    ["🌆 Cheongdam Avenue"] = Vector3.new(-1800, 48, -2100),
    ["🔧 Tuning Shop & Garage"] = Vector3.new(200, 42, -4900),
    ["🏪 Car Market & Dealership"] = Vector3.new(-920, 44, -6150),
    ["🏁 Highway Strip"] = Vector3.new(0, 45, -1200)
}


-- ==============================================================================
-- 🎨 12. WINDUI GUI CREATION
-- ==============================================================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Raycity RB | Song Hub [v1.5 - Auto Farm Edition]",
    Icon = "car",
    Author = "by Song Hub Dev",
    Folder = "RaycityHub",
    Size = UDim2.fromOffset(580, 480),
    Transparent = true,
    Theme = "Dark",
    Acrylic = false,
    Resizable = true
})

-- TAB 1: 📜 Auto Farm Quest (ขับเองออโต้)
local TabQuest = Window:Tab({ Title = "Auto Quest Farm", Icon = "file-text" })

TabQuest:Paragraph({
    Title = "🚗 Autonomous Quest Farming Engine (ขับส่งของเองอัตโนมัติ)",
    Desc = "ระบบจะควบคุมรถให้ขับไปรับเควส, คุยกับ NPC, รับของ, ขับไปส่งที่เป้าหมาย, และวนลูปรับเควสใหม่ให้ตลอด 24 ชั่วโมงแบบ 100% AFK!",
    Image = "package"
})

TabQuest:Toggle({
    Title = "🚗 Master Auto Farm Quests (เปิดบอทขับฟาร์มเควสเอง)",
    Desc = "เปิดใช้งานบอทขับรถทำเควสและส่งของอัตโนมัติ ไม่ต้องกดบังคับเอง",
    Value = Config.AutoFarmQuests,
    Callback = function(val)
        Config.AutoFarmQuests = val
        if val then
            WindUI:Notify({ Title = "Auto Farm Started! 🚗", Content = "Autonomous driving engine active.\nMode: " .. Config.QuestDriveMode, Duration = 3, Icon = "play" })
        else
            -- Stop any active AutoDrive
            pcall(function()
                local RaycityUi = ReplicatedStorage:FindFirstChild("RaycityUi")
                if RaycityUi and RaycityUi:FindFirstChild("AutoDrive") then
                    require(RaycityUi.AutoDrive).stop()
                end
            end)
            WindUI:Notify({ Title = "Auto Farm Paused", Content = "Autonomous driver stopped.", Duration = 2, Icon = "pause" })
        end
    end
})

TabQuest:Dropdown({
    Title = "⚡ Speed & Travel Mode (รูปแบบการเดินทางทำเควส)",
    Desc = "เลือกรูปแบบการเดินทางไปส่งของ: Instant Warp (วาร์ปทันที 0 วิ - ไวสุดในเกม), Hyper Sonic Glide (เหาะทะยานความเร็วสูง 500-800 km/h), Realistic Road Drive (ขับตามถนน)",
    Values = { "Instant Warp", "Hyper Sonic Glide", "Realistic Road Drive", "Hybrid Cruise" },
    Value = Config.QuestDriveMode,
    Callback = function(val)
        Config.QuestDriveMode = val
    end
})

TabQuest:Slider({
    Title = "⚡ Auto Driving Speed (ความเร็วขับส่งของ km/h)",
    Desc = "ปรับความเร็วที่บอทใช้เหาะและขับไปส่งของ",
    Value = { Min = 100, Max = 800, Default = Config.QuestDriveSpeed },
    Callback = function(val)
        Config.QuestDriveSpeed = val
    end
})

TabQuest:Divider()

TabQuest:Toggle({
    Title = "👻 Ghost Traffic (ทะลุรถ NPC ไม่ชน)",
    Desc = "ปิดการชนของรถชาวเมือง ทำให้ขับฉลุยไม่ติดแหง็กหรือโดนชนปาดหน้า",
    Value = Config.GhostTraffic,
    Callback = function(val)
        Config.GhostTraffic = val
    end
})

TabQuest:Toggle({
    Title = "⏩ Auto Skip NPC Dialogue (ข้ามบทสนทนาออโต้)",
    Desc = "กดผ่านบทสนทนาเควสและข้ามเนื้อเรื่องให้อัตโนมัติทันที",
    Value = Config.AutoSkipDialogue,
    Callback = function(val)
        Config.AutoSkipDialogue = val
    end
})

TabQuest:Toggle({
    Title = "🎁 Auto Claim Rewards (กดรับรางวัลออโต้)",
    Desc = "กดรับ EXP, เงิน Cash, และปิดหน้าต่างผลตอบแทนอัตโนมัติ",
    Value = Config.AutoClaimRewards,
    Callback = function(val)
        Config.AutoClaimRewards = val
    end
})

TabQuest:Toggle({
    Title = "🔄 Loop Next Quest (วนลูปเควสต่อไปไม่หยุด)",
    Desc = "เมื่อส่งของเสร็จแล้ว บอทจะขับไปหา NPC เพื่อรับเควสใหม่ทันที",
    Value = Config.LoopNextQuest,
    Callback = function(val)
        Config.LoopNextQuest = val
    end
})

TabQuest:Divider()

TabQuest:Toggle({
    Title = "⚔️ Auto Road Fight / Gang Cars",
    Desc = "ล็อคเป้ารถภารกิจ / รถบอสแก๊งและขับไล่ชนอัตโนมัติ",
    Value = Config.AutoRoadFight,
    Callback = function(val)
        Config.AutoRoadFight = val
    end
})

TabQuest:Toggle({
    Title = "🌪️ Auto Whirl Skill Spam",
    Desc = "สแปมสกิลหมุนฟาดรถ (Whirlwind) ชนและทำลายรถศัตรูอย่างรวดเร็ว",
    Value = Config.AutoWhirlSkill,
    Callback = function(val)
        Config.AutoWhirlSkill = val
    end
})

-- TAB 2: 🏎️ Vehicle & Speed
local TabSpeed = Window:Tab({ Title = "Speed & Drive", Icon = "zap" })

TabSpeed:Paragraph({
    Title = "🚗 Raycity Super Physics Engine",
    Desc = "Enhance your car top speed, turbo acceleration, and unlock seamless flying mode across the whole city map.",
    Image = "gauge"
})

TabSpeed:Toggle({
    Title = "⚡ Speed Booster / Multiplier",
    Desc = "Override maximum vehicle speed when holding forward (W / Up)",
    Value = Config.SpeedBoostEnabled,
    Callback = function(val)
        Config.SpeedBoostEnabled = val
    end
})

TabSpeed:Slider({
    Title = "🏁 Target Speed (km/h)",
    Desc = "Adjust maximum cruising speed threshold",
    Value = { Min = 80, Max = 600, Default = Config.TargetSpeedKmh },
    Callback = function(val)
        Config.TargetSpeedKmh = val
    end
})

TabSpeed:Slider({
    Title = "🚀 Acceleration Multiplier",
    Desc = "Rate of acceleration towards top speed",
    Value = { Min = 1, Max = 10, Default = Config.AccelerationMultiplier },
    Callback = function(val)
        Config.AccelerationMultiplier = val
    end
})

TabSpeed:Divider()

TabSpeed:Toggle({
    Title = "🛸 Car Flight / Hover Mode",
    Desc = "Fly straight over buildings and traffic (W/A/S/D to fly, Space = Up, LeftCtrl = Down)",
    Value = Config.FlyEnabled,
    Callback = function(val)
        Config.FlyEnabled = val
        updateFlyState()
    end
})

TabSpeed:Slider({
    Title = "💨 Flight Speed (km/h)",
    Desc = "Movement speed while in flight mode",
    Value = { Min = 50, Max = 500, Default = Config.FlySpeed },
    Callback = function(val)
        Config.FlySpeed = val
    end
})

TabSpeed:Divider()

TabSpeed:Toggle({
    Title = "🔄 Anti-Flip (Auto-Upright)",
    Desc = "Instantly flips the car back upright if it tilts or lands upside down",
    Value = Config.AntiFlip,
    Callback = function(val)
        Config.AntiFlip = val
    end
})

TabSpeed:Toggle({
    Title = "🔥 Infinite Nitro / SP",
    Desc = "Keep SP filled at maximum for endless booster",
    Value = Config.InfiniteBoost,
    Callback = function(val)
        Config.InfiniteBoost = val
    end
})

TabSpeed:Toggle({
    Title = "🏎️ Super AutoDrive Tuning",
    Desc = "Remove native game AutoDrive speed limits (cruise at 200+ km/h without slowing down in turns)",
    Value = Config.SuperAutoDrive,
    Callback = function(val)
        Config.SuperAutoDrive = val
    end
})

-- TAB 3: 💎 Pickups & Item Vacuum
local TabPickup = Window:Tab({ Title = "Item Vacuum", Icon = "sparkles" })

TabPickup:Toggle({
    Title = "🧲 Auto Collect Pickups & Jewels",
    Desc = "Pulls and consumes nearby item boxes, jewels, and booster capsules",
    Value = Config.AutoPickups,
    Callback = function(val)
        Config.AutoPickups = val
    end
})

TabPickup:Slider({
    Title = "📡 Vacuum Radius (Studs)",
    Desc = "Detection range for surrounding item pickups",
    Value = { Min = 50, Max = 500, Default = Config.PickupRadius },
    Callback = function(val)
        Config.PickupRadius = val
    end
})

-- TAB 4: 🗺️ City Teleports
local TabTeleport = Window:Tab({ Title = "City Warps", Icon = "map-pin" })

TabTeleport:Paragraph({
    Title = "📍 Instant City Navigation",
    Desc = "Warp your vehicle instantly across key Seoul districts, garages, and shops.",
    Image = "map"
})

for name, pos in pairs(CITY_WAYPOINTS) do
    TabTeleport:Button({
        Title = name,
        Desc = "Teleport car to " .. name,
        Icon = "navigation",
        Callback = function()
            teleportCar(pos)
            WindUI:Notify({ Title = "Warped!", Content = "Teleported to " .. name, Duration = 3, Icon = "check-circle" })
        end
    })
end

-- TAB 5: 🛡️ Safety & Settings
local TabSettings = Window:Tab({ Title = "Settings", Icon = "settings" })

TabSettings:Toggle({
    Title = "🛡️ Anti-AFK (20-Min Kick Prevention)",
    Desc = "Prevents Roblox disconnection while auto-farming or idling",
    Value = Config.AntiAfk,
    Callback = function(val)
        Config.AntiAfk = val
    end
})

TabSettings:Keybind({
    Title = "⌨️ Instant Brake Key",
    Desc = "Emergency brake that halts all momentum immediately",
    Value = Config.InstantBrakeKey,
    Callback = function(key)
        Config.InstantBrakeKey = key
    end
})

TabSettings:Keybind({
    Title = "🎛️ Toggle Hub Menu Hotkey",
    Desc = "Press to hide or open this menu window",
    Value = Enum.KeyCode.RightControl,
    Callback = function()
        Window:Toggle()
    end
})

TabSettings:Button({
    Title = "💬 Join Discord Community",
    Desc = "Copy Discord invite link (https://discord.gg/cecytf4MHE)",
    Icon = "message-circle",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/cecytf4MHE")
            WindUI:Notify({ Title = "Copied!", Content = "Discord link copied to clipboard!", Duration = 3, Icon = "clipboard" })
        end
    end
})

WindUI:Notify({
    Title = "Raycity RB Hub Loaded! 🏎️",
    Content = "Welcome " .. LocalPlayer.Name .. "!\nAutonomous Quest Driver ready.",
    Duration = 4,
    Icon = "sparkles"
})

print("[Raycity Hub] ✨ Successfully loaded Raycity RB Automation Hub with Autonomous Driving Engine!")
