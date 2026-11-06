-- [[
--   ======================================================================
--   🏎️ [RAYCITY RB] All-in-One Speed, Auto Quest & Farm Hub
--   Author: Song Hub Official / Universal Edition
--   Target Game: Raycity RB (PlaceId: 117419079466193, UniverseId: 10772794231)
--   UI Framework: WindUI
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
                    return nil -- Silently drop suspicious telemetry
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
    -- Fallback: check workspace for model with player's name or character vehicle seat
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

    -- Auto Quests & Deliveries
    AutoDeliver = false,
    DeliverSpeed = 180,
    AutoClaimRewards = true,

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
-- 🚀 4. VEHICLE BOOST & FLIGHT LOGIC
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

    -- Speed Booster on Driving
    if Config.SpeedBoostEnabled and not Config.FlyEnabled then
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

-- ==============================================================================
-- 📜 5. AUTO QUEST & DELIVERY AUTOMATION
-- ==============================================================================
local function findActiveDestination()
    -- 1. Check workspace for Quest or Navigation markers
    local navFolder = workspace:FindFirstChild("RaycityNavigation") or workspace:FindFirstChild("QuestMarkers")
    if navFolder then
        for _, m in ipairs(navFolder:GetChildren()) do
            if m:IsA("BasePart") or (m:IsA("Model") and m.PrimaryPart) then
                return (m:IsA("BasePart") and m.Position) or m.PrimaryPart.Position, m
            end
        end
    end

    -- 2. Check for destination Beam or Attachment
    local char = LocalPlayer.Character
    if char then
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("Beam") and d.Attachment1 then
                return d.Attachment1.WorldPosition, d.Attachment1.Parent
            end
        end
    end

    -- 3. Check RBRCQuest Client state
    local questClient = LocalPlayer.PlayerScripts:FindFirstChild("RBRCQuestClient")
    if questClient and getsenv then
        local ok, env = pcall(getsenv, questClient)
        if ok and env and env.currentDestination then
            return env.currentDestination, nil
        end
    end

    return nil, nil
end

-- Auto Deliver & Quest Runner Loop
task.spawn(function()
    while true do
        task.wait(0.2)
        if Config.AutoDeliver then
            local root = getCarRoot()
            local destPos, destObj = findActiveDestination()

            if root and destPos then
                local dist = (root.Position - destPos).Magnitude
                if dist > 15 then
                    -- Fly smoothly towards destination to avoid traffic and walls
                    local dir = (destPos - root.Position).Unit
                    root.AssemblyLinearVelocity = dir * (Config.DeliverSpeed / 3.6)
                    root.CFrame = CFrame.lookAt(root.Position, root.Position + Vector3.new(dir.X, 0, dir.Z))
                else
                    -- Arrived at objective
                    root.AssemblyLinearVelocity = Vector3.zero
                    task.wait(0.5)

                    -- Auto trigger Quest finish
                    pcall(function()
                        local qRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
                        if qRemotes then
                            local qReq = qRemotes:FindFirstChild("QuestRequest")
                            local qEvent = qRemotes:FindFirstChild("QuestEventUp")
                            if qEvent then
                                qEvent:FireServer("GoalReached", destObj and destObj.Name)
                            end
                            if qReq then
                                qReq:InvokeServer("ClaimCurrentQuest")
                            end
                        end
                    end)
                end
            end
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
                    local behindPos = targetEnemy.CFrame * Vector3.new(0, 0, 8)
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
-- 💎 6. AUTO PICKUP VACUUM
-- ==============================================================================
task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.AutoPickups then
            local root = getCarRoot()
            if root then
                local pickups = workspace:FindFirstChild("Pickups") or workspace:FindFirstChild("PickupSpots")
                local pickupRemote = ReplicatedStorage:FindFirstChild("RaycityPickups") and ReplicatedStorage.RaycityPickups:FindFirstChild("Remotes") and ReplicatedStorage.RaycityPickups.Remotes:FindFirstChild("PickupEat")

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
-- 🛡️ 7. ANTI-AFK & PERFORMANCE OPTIMIZATION
-- ==============================================================================
if Config.AntiAfk then
    LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end

-- ==============================================================================
-- 🗺️ 8. PRESET CITY TELEPORT LOCATIONS
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
-- 🎨 9. WINDUI GUI CREATION
-- ==============================================================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Raycity RB | Song Hub [v1.0]",
    Icon = "car",
    Author = "by Song Hub Dev",
    Folder = "RaycityHub",
    Size = UDim2.fromOffset(560, 460),
    Transparent = true,
    Theme = "Dark",
    Acrylic = false,
    Resizable = true
})

-- TAB 1: 🏎️ Vehicle & Speed
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

-- TAB 2: 📜 Auto Quest & Deliver
local TabQuest = Window:Tab({ Title = "Auto Quests", Icon = "file-text" })

TabQuest:Paragraph({
    Title = "📦 Auto Delivery & Mission Bot",
    Desc = "Automates picking up passengers, packages, delivery objectives and claims rewards automatically.",
    Image = "package"
})

TabQuest:Toggle({
    Title = "📦 Auto Complete Deliveries & Quests",
    Desc = "Automatically flies and drives your car directly to active quest objectives and drops off items",
    Value = Config.AutoDeliver,
    Callback = function(val)
        Config.AutoDeliver = val
    end
})

TabQuest:Slider({
    Title = "💨 Delivery Travel Speed (km/h)",
    Desc = "Speed to fly towards quest markers",
    Min = 80,
    Max = 400,
    Value = Config.DeliverSpeed,
    Callback = function(val)
        Config.DeliverSpeed = val
    end
})

TabQuest:Divider()

TabQuest:Toggle({
    Title = "⚔️ Auto Road Fight / Gang Cars",
    Desc = "Locks onto mission target cars and chases them down",
    Value = Config.AutoRoadFight,
    Callback = function(val)
        Config.AutoRoadFight = val
    end
})

TabQuest:Toggle({
    Title = "🌪️ Auto Whirl Skill Spam",
    Desc = "Spams Whirlwind car spin attack to smash enemy cars instantly",
    Value = Config.AutoWhirlSkill,
    Callback = function(val)
        Config.AutoWhirlSkill = val
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
    Content = "Welcome " .. LocalPlayer.Name .. "!\nAll systems ready.",
    Duration = 4,
    Icon = "sparkles"
})

print("[Raycity Hub] ✨ Successfully loaded Raycity RB Automation Hub!")
