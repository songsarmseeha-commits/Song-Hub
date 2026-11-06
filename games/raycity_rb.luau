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
-- 🚗 2. CAR & VEHICLE CONTROLLER
-- ==============================================================================
local function getMyCar()
    local car = workspace:FindFirstChild("MyCar")
    if car and car:FindFirstChild("Root") then
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
    local car = getMyCar()
    if car then
        return car:FindFirstChild("Root") or car.PrimaryPart
    end
    return nil
end

-- ==============================================================================
-- ⚙️ 3. CONFIGURATION & STATE
-- ==============================================================================
local Config = {
    -- Autonomous Quest Farming
    AutoFarmQuests = false,
    QuestDriveMode = "Realistic Road Drive", -- "Realistic Road Drive" | "Express Glide" | "Hybrid Cruise"
    QuestDriveSpeed = 220, -- km/h
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
-- 💬 5. AUTO DIALOGUE SKiPPER & QUEST ACCEPTER
-- ==============================================================================
task.spawn(function()
    while true do
        task.wait(0.2)
        if Config.AutoFarmQuests or Config.AutoSkipDialogue then
            pcall(function()
                local qUi = nil
                pcall(function() qUi = require(ReplicatedStorage.RBRCQuest.QuestUI) end)
                local qGui = LocalPlayer.PlayerGui:FindFirstChild("RaycityQuestUi")

                if qGui then
                    -- 1. Advance NPC Dialogue
                    local npcDialog = qGui:FindFirstChild("NpcDialog", true)
                    if npcDialog and npcDialog.Visible then
                        if qUi and qUi._dialogEnter then
                            qUi._dialogEnter()
                        end
                        local nextBtn = npcDialog:FindFirstChild("Next", true)
                        if nextBtn and nextBtn.Visible then
                            for _, c in ipairs(getconnections(nextBtn.Activated)) do c:Fire() end
                        end
                    end

                    -- 2. Auto Accept Quest Offer
                    local offerFrame = qGui:FindFirstChild("Offer", true) or qGui:FindFirstChild("QuestOffer", true)
                    if offerFrame and offerFrame.Visible then
                        if qUi and qUi._offerAnswer then
                            qUi._offerAnswer(true)
                        end
                        local acceptBtn = offerFrame:FindFirstChild("Accept", true) or offerFrame:FindFirstChild("Ok", true)
                        if acceptBtn and acceptBtn.Visible then
                            for _, c in ipairs(getconnections(acceptBtn.Activated)) do c:Fire() end
                        end
                    end

                    -- 3. Auto Close / Claim Result Dialog
                    local resultDialog = qGui:FindFirstChild("Result", true) or qGui:FindFirstChild("QuestResult", true)
                    if resultDialog and resultDialog.Visible then
                        if qUi and qUi.hideResult then
                            qUi.hideResult()
                        end
                        local closeBtn = resultDialog:FindFirstChild("Close", true) or resultDialog:FindFirstChild("Confirm", true)
                        if closeBtn and closeBtn.Visible then
                            for _, c in ipairs(getconnections(closeBtn.Activated)) do c:Fire() end
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
local function getActiveQuestDestination()
    -- Priority 1: Check workspace.RBRCQuestMarkers
    local qMarkers = workspace:FindFirstChild("RBRCQuestMarkers")
    if qMarkers then
        for _, m in ipairs(qMarkers:GetChildren()) do
            local p = m:IsA("BasePart") and m or m:FindFirstChildWhichIsA("BasePart") or (m:IsA("Model") and m.PrimaryPart)
            if p then
                return p.Position, m
            end
        end
    end

    -- Priority 2: Check workspace.RBRCQuestGuide
    local qGuide = workspace:FindFirstChild("RBRCQuestGuide")
    if qGuide then
        for _, m in ipairs(qGuide:GetChildren()) do
            local p = m:IsA("BasePart") and m or m:FindFirstChildWhichIsA("BasePart")
            if p then
                return p.Position, m
            end
        end
    end

    -- Priority 3: Check Navigation Guide Destination
    local ok, nav = pcall(function() return require(ReplicatedStorage.RaycityUi.Navigation) end)
    if ok and nav and nav.getGuide then
        local g = nav.getGuide()
        if g and g.destRoblox then
            return g.destRoblox, nil
        end
    end

    -- Priority 4: Check Player Beams & Navigation
    local char = LocalPlayer.Character
    if char then
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("Beam") and d.Attachment1 then
                return d.Attachment1.WorldPosition, d.Attachment1.Parent
            end
        end
    end

    -- Priority 5: Check RaycityNavigation markers in workspace
    local navFolder = workspace:FindFirstChild("RaycityNavigation") or workspace:FindFirstChild("QuestMarkers")
    if navFolder then
        for _, m in ipairs(navFolder:GetChildren()) do
            local p = m:IsA("BasePart") and m or (m:IsA("Model") and m.PrimaryPart)
            if p then
                return p.Position, m
            end
        end
    end

    return nil, nil
end

-- ==============================================================================
-- 🚗 7. MASTER AUTONOMOUS QUEST FARMING ENGINE (ขับเองอัตโนมัติ)
-- ==============================================================================
local questFarmState = "SEARCHING" -- "SEARCHING" | "DRIVING" | "DELIVERING"
local lastStuckPos = nil
local stuckCounter = 0

task.spawn(function()
    while true do
        task.wait(0.2)
        if Config.AutoFarmQuests then
            local root = getCarRoot()
            if root then
                local destPos, destObj = getActiveQuestDestination()

                -- Anti-Stuck Detection
                if lastStuckPos and (root.Position - lastStuckPos).Magnitude < 2 then
                    stuckCounter = stuckCounter + 1
                    if stuckCounter >= 10 then -- Stuck for 2+ seconds
                        -- Execute auto un-stuck hop
                        root.AssemblyLinearVelocity = Vector3.new(0, 45, 0)
                        task.wait(0.3)
                        stuckCounter = 0
                    end
                else
                    lastStuckPos = root.Position
                    stuckCounter = 0
                end

                if destPos then
                    -- ==========================================================
                    -- A. QUEST IN PROGRESS: DRIVE AUTONOMOUSLY TO DESTINATION
                    -- ==========================================================
                    questFarmState = "DRIVING"
                    local dist = (root.Position - destPos).Magnitude

                    if dist > 18 then
                        if Config.QuestDriveMode == "Realistic Road Drive" then
                            -- 1. Drive along actual Seoul roads using boosted AutoDrive
                            pcall(function()
                                local RaycityUi = ReplicatedStorage:FindFirstChild("RaycityUi")
                                if RaycityUi and RaycityUi:FindFirstChild("AutoDrive") then
                                    local ad = require(RaycityUi.AutoDrive)
                                    if ad then
                                        ad.C.maxSpeed = Config.QuestDriveSpeed / 3.6
                                        ad.C.cap1 = 80
                                        ad.C.cap2 = 60
                                        ad.C.cap3 = 50
                                        ad.C.arriveSlowM = 5
                                        ad.C.arriveSlowerM = 2
                                        if not ad.isActive() then
                                            ad.start(destPos)
                                        end
                                    end
                                end
                            end)

                            -- Also steer and assist forward velocity
                            local dir = (destPos - root.Position).Unit
                            local flatDir = Vector3.new(dir.X, 0, dir.Z).Unit
                            local currentKmh = root.AssemblyLinearVelocity.Magnitude * 3.6
                            if currentKmh < Config.QuestDriveSpeed then
                                root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(flatDir * (Config.QuestDriveSpeed / 3.6), 0.2)
                            end

                        elseif Config.QuestDriveMode == "Express Glide" then
                            -- 2. Smooth 3D Flight straight to destination (Bypasses all obstacles)
                            local dir = (destPos - root.Position).Unit
                            root.AssemblyLinearVelocity = dir * (Config.QuestDriveSpeed / 3.6)
                            root.CFrame = CFrame.lookAt(root.Position, root.Position + Vector3.new(dir.X, 0, dir.Z))

                        elseif Config.QuestDriveMode == "Hybrid Cruise" then
                            -- 3. High-Speed Ground Cruise with obstacle hopping
                            local dir = (destPos - root.Position).Unit
                            local flatDir = Vector3.new(dir.X, 0, dir.Z).Unit
                            root.AssemblyLinearVelocity = flatDir * (Config.QuestDriveSpeed / 3.6) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
                            root.CFrame = CFrame.lookAt(root.Position, root.Position + flatDir * 5)
                        end
                    else
                        -- ==========================================================
                        -- B. ARRIVED AT OBJECTIVE: COMPLETE & CLAIM
                        -- ==========================================================
                        questFarmState = "DELIVERING"
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.CFrame = CFrame.new(destPos + Vector3.new(0, 1.5, 0))

                        -- Stop native AutoDrive
                        pcall(function()
                            local RaycityUi = ReplicatedStorage:FindFirstChild("RaycityUi")
                            if RaycityUi and RaycityUi:FindFirstChild("AutoDrive") then
                                require(RaycityUi.AutoDrive).stop()
                            end
                        end)

                        task.wait(0.3)

                        -- Submit delivery via server remotes
                        pcall(function()
                            local qRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
                            if qRemotes then
                                if qRemotes:FindFirstChild("QuestEventUp") then
                                    qRemotes.QuestEventUp:FireServer("GoalReached", destObj and destObj.Name)
                                end
                                if qRemotes:FindFirstChild("QuestRequest") then
                                    qRemotes.QuestRequest:InvokeServer("ClaimCurrentQuest")
                                end
                            end
                        end)

                        task.wait(0.6)
                    end
                else
                    -- ==========================================================
                    -- C. NO ACTIVE QUEST: AUTO DRIVE / WARP TO NEAREST NPC
                    -- ==========================================================
                    if Config.LoopNextQuest then
                        questFarmState = "SEARCHING"
                        local nearestNpc, nearestDist = nil, 99999
                        local npcsFolder = workspace:FindFirstChild("RBRCNpcs")

                        if npcsFolder then
                            for _, npc in ipairs(npcsFolder:GetChildren()) do
                                local nPart = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart")
                                if nPart then
                                    local d = (root.Position - nPart.Position).Magnitude
                                    if d < nearestDist then
                                        nearestDist = d
                                        nearestNpc = nPart
                                    end
                                end
                            end
                        end

                        if nearestNpc then
                            if nearestDist > 14 then
                                -- Drive smoothly towards quest NPC
                                local dir = (nearestNpc.Position - root.Position).Unit
                                local flatDir = Vector3.new(dir.X, 0, dir.Z).Unit
                                if Config.QuestDriveMode == "Express Glide" then
                                    root.AssemblyLinearVelocity = dir * (Config.QuestDriveSpeed / 3.6)
                                else
                                    root.AssemblyLinearVelocity = flatDir * (Config.QuestDriveSpeed / 3.6)
                                end
                                root.CFrame = CFrame.lookAt(root.Position, root.Position + flatDir * 5)
                            else
                                -- Arrived at NPC: stop and interact to take quest!
                                root.AssemblyLinearVelocity = Vector3.zero
                                pcall(function()
                                    local interactRemote = ReplicatedStorage:FindFirstChild("RaycityInteract") 
                                        and ReplicatedStorage.RaycityInteract:FindFirstChild("Remotes") 
                                        and ReplicatedStorage.RaycityInteract.Remotes:FindFirstChild("InteractRequest")
                                    if interactRemote then
                                        interactRemote:InvokeServer("Talk", nearestNpc.Parent.Name)
                                    end
                                end)
                                task.wait(0.5)
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
                root.CFrame = CFrame.lookAt(currentPos + Vector3.new(0, 2, 0), currentPos + flatLook * 10)
                root.AssemblyAngularVelocity = Vector3.zero
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

local function teleportCar(targetPos)
    local root = getCarRoot()
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
    end
end

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
    Title = "🛣️ Driving Mode (รูปแบบการขับของบอท)",
    Desc = "เลือกสไตล์การขับไปส่งของ",
    Values = { "Realistic Road Drive", "Express Glide", "Hybrid Cruise" },
    Value = Config.QuestDriveMode,
    Callback = function(val)
        Config.QuestDriveMode = val
    end
})

TabQuest:Slider({
    Title = "⚡ Auto Driving Speed (ความเร็วขับส่งของ km/h)",
    Desc = "ปรับความเร็วที่บอทใช้ขับไปส่งของและรับเควส",
    Min = 100,
    Max = 500,
    Value = Config.QuestDriveSpeed,
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
    Min = 80,
    Max = 600,
    Value = Config.TargetSpeedKmh,
    Callback = function(val)
        Config.TargetSpeedKmh = val
    end
})

TabSpeed:Slider({
    Title = "🚀 Acceleration Multiplier",
    Desc = "Rate of acceleration towards top speed",
    Min = 1,
    Max = 10,
    Value = Config.AccelerationMultiplier,
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
    Min = 50,
    Max = 500,
    Value = Config.FlySpeed,
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
    Min = 50,
    Max = 500,
    Value = Config.PickupRadius,
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
