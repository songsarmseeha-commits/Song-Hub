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

if not game:IsLoaded() then
    pcall(function() game.Loaded:Wait() end)
    local t0 = tick()
    while not game:IsLoaded() and (tick() - t0) < 15 do
        task.wait(0.2)
    end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    local t0 = tick()
    while not Players.LocalPlayer and (tick() - t0) < 15 do
        task.wait(0.2)
    end
    LocalPlayer = Players.LocalPlayer
end
local Camera = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")

-- Execution Run Management & Multi-Execute Clean Up
getgenv().__RaycityHubRunId = (tonumber(getgenv().__RaycityHubRunId) or 0) + 1
local currentScriptRunId = getgenv().__RaycityHubRunId

local function isAlive()
    local activeRun = tonumber(getgenv().__RaycityHubRunId)
    if activeRun and currentScriptRunId and activeRun > currentScriptRunId then
        return false
    end
    return true
end

-- Clean up only previous WindUI ScreenGuis cleanly (NEVER touch PlayerGui or game UI)
pcall(function()
    local roots = {
        (typeof(gethui) == "function" and gethui()) or nil,
        game:GetService("CoreGui")
    }
    for _, root in ipairs(roots) do
        if root then
            for _, child in ipairs(root:GetChildren()) do
                if child.Name == "WindUI" or child.Name == "RaycityHub" or child.Name == "WindUI-RaycityHub" or child.Name == "SongHub" then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end)

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
-- ⚙️ 3. CONFIGURATION & STATE
-- ==============================================================================
local Config = {
    -- Autonomous Quest Farming
    AutoFarmQuests = true,
    AutoStoryProgression = true,
    AutoCleanInventory = true,
    QuestDriveMode = "Realistic Road Drive", -- "Realistic Road Drive" | "Instant Warp" | "Hyper Sonic Glide" | "Hybrid Cruise"
    QuestDriveSpeed = 260, -- km/h
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


-- Forward declarations for UI callbacks
local updateFlyState = function() end
local teleportCar = function(targetCF) end

-- ==============================================================================
-- 🎨 12. WINDUI GUI CREATION
-- ==============================================================================
-- Multi-tier WindUI framework loader
local WindUI = nil
pcall(function()
    if isfile and readfile and isfile("WindUI_cache.lua") then
        local cached = readfile("WindUI_cache.lua")
        if cached and #cached > 10000 then
            WindUI = loadstring(cached)()
        end
    end
end)
if not WindUI then
    pcall(function()
        local raw = game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua")
        if raw and #raw > 10000 then
            pcall(function() if writefile then writefile("WindUI_cache.lua", raw) end end)
            WindUI = loadstring(raw)()
        end
    end)
end
if not WindUI then
    pcall(function()
        local raw = game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua")
        if raw and #raw > 10000 then
            pcall(function() if writefile then writefile("WindUI_cache.lua", raw) end end)
            WindUI = loadstring(raw)()
        end
    end)
end

if not WindUI then
    warn("[Raycity Hub] ❌ Failed to load WindUI framework! Please check your network connection.")
    return
end

-- Safe notification wrapper
local rawNotify = WindUI.Notify
WindUI.Notify = function(self, ...)
    local args = {...}
    pcall(function()
        if type(self) == "table" and self.CreateWindow then
            rawNotify(self, unpack(args))
        else
            rawNotify(self)
        end
    end)
end

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

TabQuest:Toggle({
    Title = "🏆 Auto Story Progression Lv.1 - Max (ฟาร์มเควสหลัก 1 ถึงเวลตัน)",
    Desc = "ทำเควสเนื้อเรื่องต่อเนื่องตั้งแต่ Lv.1 ถึงเลเวลตัน หากเลเวลไม่พอจะฟาร์มส่งของข้างทางจนเลเวลอัปแล้วกลับมารับเควสต่อออโต้",
    Value = Config.AutoStoryProgression,
    Callback = function(val)
        Config.AutoStoryProgression = val
    end
})

TabQuest:Toggle({
    Title = "🧹 Auto Clean Inventory (ขายขยะเคลียร์ช่องกระเป๋าออโต้)",
    Desc = "ขายไอเทมขยะที่ไม่ได้ผูกมัดอัตโนมัติ เพื่อให้มีช่องว่างในกระเป๋าอย่างน้อย 18 ช่องสำหรับรับรางวัลเควส ป้องกันติดบั๊กกระเป๋าเต็ม",
    Value = Config.AutoCleanInventory,
    Callback = function(val)
        Config.AutoCleanInventory = val
    end
})

TabQuest:Dropdown({
    Title = "⚡ Speed & Travel Mode (รูปแบบการเดินทางทำเควส)",
    Desc = "เลือกรูปแบบการเดินทาง: Realistic Road Drive (ขับตามลูกศรบนถนน 100% ไม่บิน ไม่ทะลุตึก - แนะนำ), Hyper Sonic Glide, Instant Warp",
    Values = { "Realistic Road Drive", "Instant Warp", "Hyper Sonic Glide", "Hybrid Cruise" },
    Value = Config.QuestDriveMode,
    Callback = function(val)
        Config.QuestDriveMode = val
    end
})

TabQuest:Slider({
    Title = "⚡ Auto Driving Speed (ความเร็วขับส่งของ km/h)",
    Desc = "ปรับความเร็วที่บอทใช้ขับตามถนนไปส่งของ (แนะนำ 200 - 320 km/h)",
    Value = { Min = 100, Max = 500, Default = Config.QuestDriveSpeed },
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


-- ==============================================================================
-- 🛡️ 1. ANTI-CHEAT BYPASS & SAFETY SHIELD
-- ==============================================================================
pcall(function()
    local acFolder = ReplicatedStorage:FindFirstChild("RaycityAntiCheat")
    local remotes = acFolder and acFolder:FindFirstChild("Remotes")
    if remotes and typeof(hookmetamethod) == "function" then
        local blocked = {}
        for _, name in ipairs({ "AcPush", "AcMove", "AcThrill" }) do
            local r = remotes:FindFirstChild(name)
            if r then blocked[r] = true end
        end
        if next(blocked) ~= nil then
            local oldNamecall
            local hookFn = function(self, ...)
                local method = getnamecallmethod()
                if (method == "FireServer" or method == "fireServer") and blocked[self] then
                    return nil
                end
                return oldNamecall(self, ...)
            end
            oldNamecall = hookmetamethod(game, "__namecall", typeof(newcclosure) == "function" and newcclosure(hookFn) or hookFn)
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
    if car and (car:FindFirstChild("Root") or car.PrimaryPart or car:FindFirstChild("Body") or car:FindFirstChildWhichIsA("BasePart")) then
        return car
    end
    local lpChar = LocalPlayer and LocalPlayer.Character
    if lpChar then
        for _, d in ipairs(workspace:GetDescendants()) do
            if (d:IsA("VehicleSeat") or d:IsA("Seat")) and d.Occupant and d.Occupant.Parent == lpChar then
                return d.Parent
            end
        end
    end
    return nil
end

local function getCarRoot()
    local rcd = getRCDrive()
    if rcd and rcd.car then
        local r = rcd.car:FindFirstChild("Root") or rcd.car.PrimaryPart or rcd.car:FindFirstChild("Body") or rcd.car:FindFirstChildWhichIsA("BasePart")
        if r then return r end
    end
    local car = getMyCar()
    if car then
        return car:FindFirstChild("Root") or car.PrimaryPart or car:FindFirstChild("Body") or car:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end

teleportCar = function(targetCF)
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
    if dist < 0.3 then return end

    local speedMps = (speedKmh or 260) / 3.6
    local moveDir
    local nextPos = currentPos

    if isAir then
        moveDir = dir.Unit
        root.AssemblyLinearVelocity = moveDir * speedMps
        root.AssemblyAngularVelocity = Vector3.zero
        nextPos = currentPos + moveDir * math.min(dist, speedMps * 0.05)
    else
        -- 🚗 Ground road driving mode: Wheels firmly on the tarmac!
        local flatDir = Vector3.new(dir.X, 0, dir.Z)
        moveDir = flatDir.Magnitude > 0.1 and flatDir.Unit or Vector3.new(0, 0, -1)

        -- Raycast downward from above car to find exact asphalt elevation
        local roadY = targetPos.Y
        pcall(function()
            local rayParams = RaycastParams.new()
            local rayFilter = (Enum and Enum.RaycastFilterType and (Enum.RaycastFilterType.Exclude or Enum.RaycastFilterType.Blacklist))
            if rayFilter then
                rayParams.FilterType = rayFilter
            end
            local myCar = workspace:FindFirstChild("MyCar")
            local lpChar = LocalPlayer and LocalPlayer.Character
            local ignoreList = {}
            if myCar then table.insert(ignoreList, myCar) end
            if lpChar then table.insert(ignoreList, lpChar) end
            rayParams.FilterDescendantsInstances = ignoreList

            local groundRay = workspace:Raycast(currentPos + Vector3.new(0, 6, 0), Vector3.new(0, -40, 0), rayParams)
            if groundRay and groundRay.Position then
                roadY = groundRay.Position.Y + 1.2
            end
        end)

        -- Advance forward along road at current speed
        local stepDist = math.min(dist, math.max(0.4, speedMps * 0.045))
        local steppedXZ = currentPos + moveDir * stepDist
        local smoothY = math.abs(currentPos.Y - roadY) > 0.2 and roadY or currentPos.Y
        nextPos = Vector3.new(steppedXZ.X, smoothY, steppedXZ.Z)

        -- Downward velocity ensures all wheels make solid contact with the road
        root.AssemblyLinearVelocity = moveDir * speedMps + Vector3.new(0, -6, 0)
        root.AssemblyAngularVelocity = Vector3.zero
    end

    if moveDir and moveDir.Magnitude > 0.01 then
        local nextLook = nextPos + moveDir * 10
        pcall(function()
            root.CFrame = CFrame.lookAt(nextPos, nextLook)
        end)
    end

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
-- 👻 4. GHOST TRAFFIC (NOCLIP THROUGH CIVILIAN CARS)
-- ==============================================================================
task.spawn(function()
    while isAlive() do
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
local function fireGuiClick(btn)
    if not btn then return end
    pcall(function()
        if firesignal then
            pcall(firesignal, btn.Activated)
            pcall(firesignal, btn.MouseButton1Click)
            pcall(firesignal, btn.MouseButton1Up)
        end
        if getconnections then
            for _, c in ipairs(getconnections(btn.Activated)) do pcall(function() c:Fire() end) end
            for _, c in ipairs(getconnections(btn.MouseButton1Click)) do pcall(function() c:Fire() end) end
            for _, c in ipairs(getconnections(btn.MouseButton1Up)) do pcall(function() c:Fire() end) end
        end
        local vim = game:GetService("VirtualInputManager")
        if vim and btn:IsA("GuiObject") then
            local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
            pcall(function()
                vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                task.wait(0.02)
                vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
            end)
        end
    end)
end

local function pressReturnKey()
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        -- 1. MobileTap in RBRCNpcTalkPrompt (Talk to NPC prompt)
        local ntp = pg and pg:FindFirstChild("RBRCNpcTalkPrompt")
        if ntp and ntp.Enabled then
            local tap = ntp:FindFirstChild("MobileTap", true)
            if tap then fireGuiClick(tap) end
            local btn = ntp:FindFirstChildWhichIsA("GuiButton", true)
            if btn and btn.Visible then fireGuiClick(btn) end
        end

        -- 2. Enter button in RBRCGameGuide (Guide Mission prompt)
        local gg = pg and pg:FindFirstChild("RBRCGameGuide")
        if gg and gg.Enabled then
            local enterBtn = gg:FindFirstChild("Enter", true)
            if enterBtn and enterBtn.Visible then fireGuiClick(enterBtn) end
        end

        -- 3. RaycityQuestUi: NpcDialog Next & Result buttons
        local qGui = pg and pg:FindFirstChild("RaycityQuestUi")
        if qGui and qGui.Enabled then
            local npcDlg = qGui:FindFirstChild("NpcDialog")
            if npcDlg and npcDlg.Visible then
                local nextBtn = npcDlg:FindFirstChild("Next")
                if nextBtn then fireGuiClick(nextBtn) end
            end
            local resDlg = qGui:FindFirstChild("Result")
            if resDlg and resDlg.Visible then
                local closeBtn = resDlg:FindFirstChild("Close") or resDlg:FindFirstChildWhichIsA("GuiButton", true)
                if closeBtn then fireGuiClick(closeBtn) end
            end
            for _, d in ipairs(qGui:GetDescendants()) do
                if d:IsA("GuiButton") and (d.Visible or (d.Parent and d.Parent:IsA("GuiObject") and d.Parent.Visible)) then
                    local name = d.Name:lower()
                    local text = (d:FindFirstChildWhichIsA("TextLabel") and d:FindFirstChildWhichIsA("TextLabel").Text or (d:IsA("TextButton") and d.Text or "")):lower()
                    if name == "next" or name:find("ต่อไป") or text:find("ต่อไป") or text:find("enter") or name:find("enter") or text:find("ยืนยัน") then
                        fireGuiClick(d)
                    elseif name == "yes" or name == "accept" or name:find("ตกลง") or text:find("รับ") or text:find("ตกลง") or text:find("accept") then
                        fireGuiClick(d)
                    elseif name == "close" or name == "confirm" or name == "ok" or text:find("ปิด") or text:find("รางวัล") or text:find("confirm") or text:find("claim") or text:find("complete") then
                        fireGuiClick(d)
                    end
                end
            end
        end
    end)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        local vu = game:GetService("VirtualUser")
        local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")

        -- 1. Advance NPC Dialog (Next / ยืนยัน)
        local qUi = pg and pg:FindFirstChild("RaycityQuestUi")
        if qUi and qUi.Enabled then
            local nextBtn = qUi:FindFirstChild("Next", true)
            if nextBtn and nextBtn:IsA("GuiButton") and nextBtn.Visible then
                fireGuiClick(nextBtn)
                local center = nextBtn.AbsolutePosition + (nextBtn.AbsoluteSize / 2)
                pcall(function()
                    vu:CaptureController()
                    vu:ClickButton1(center)
                    vim:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 1)
                    task.wait(0.04)
                    vim:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 1)
                end)
            end

            -- 2. Accept Quest Offer if visible (Yes / ยอมรับ)
            local yesBtn = qUi:FindFirstChild("Yes", true)
            if yesBtn and yesBtn:IsA("GuiButton") and yesBtn.Visible then
                fireGuiClick(yesBtn)
                pcall(function()
                    local qUiMod = require(ReplicatedStorage.RBRCQuest.QuestUI)
                    if qUiMod and qUiMod._offerAnswer then
                        qUiMod._offerAnswer(true)
                    end
                end)
            end

            -- 3. Close Result Dialog if visible
            local resClose = qUi:FindFirstChild("Result", true)
            if resClose then
                local closeBtn = resClose:FindFirstChild("Close", true) or resClose:FindFirstChildWhichIsA("GuiButton")
                if closeBtn and closeBtn.Visible then
                    fireGuiClick(closeBtn)
                end
            end
        end

        -- 4. Tap RBRCNpcTalkPrompt if active
        local ntp = pg and pg:FindFirstChild("RBRCNpcTalkPrompt")
        if ntp and ntp.Enabled then
            local tap = ntp:FindFirstChild("MobileTap", true)
            if tap and tap:IsA("GuiButton") and tap.Visible then
                fireGuiClick(tap)
            end
            pcall(function()
                local rep = game:GetService("ReplicatedStorage")
                local ntpMod = rep:FindFirstChild("RBRCNpc") and rep.RBRCNpc:FindFirstChild("NpcTalkPrompt")
                if ntpMod then
                    local ntpReq = require(ntpMod)
                    local u = debug.getupvalues(ntpReq.show)
                    if u and type(u[3]) == "function" then
                        u[3]()
                    end
                end
            end)
        end

        -- 5. Native Return Key
        if vim then
            vim:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            task.wait(0.03)
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
        if qUi then
            if qUi._dialogEnter then pcall(qUi._dialogEnter) end
            if qUi._offerAnswer then
                pcall(function() qUi._offerAnswer(1) end)
                pcall(function() qUi._offerAnswer(true) end)
            end
        end
    end)
end

-- ==============================================================================
-- 💬 5.0. CONTINUOUS BACKGROUND AUTO DIALOGUE SKIP & QUEST ACCEPT ENGINE
-- ==============================================================================
task.spawn(function()
    while isAlive() do
        task.wait(0.12)
        if Config.AutoSkipDialogue or Config.AutoAcceptQuest or Config.AutoFarmQuests then
            pcall(function()
                local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
                if not pg then return end

                local qUi = pg:FindFirstChild("RaycityQuestUi")
                local ntp = pg:FindFirstChild("RBRCNpcTalkPrompt")
                local gg = pg:FindFirstChild("RBRCGameGuide")

                -- 1. Auto Talk to NPC when RBRCNpcTalkPrompt is shown ([Enter] Press Enter to chat with...)
                if ntp and ntp.Enabled then
                    pcall(function()
                        local ntpReq = require(ReplicatedStorage.RBRCNpc.NpcTalkPrompt)
                        local uvs = debug.getupvalues(ntpReq.show)
                        if uvs and type(uvs[3]) == "function" then
                            uvs[3]()
                        end
                    end)
                    local tap = ntp:FindFirstChild("MobileTap", true)
                    if tap and getconnections then
                        for _, c in ipairs(getconnections(tap.Activated)) do pcall(function() c:Fire() end) end
                    end
                    pcall(function()
                        local escGate = require(ReplicatedStorage.RaycityUi.RaycityEscGate)
                        if escGate and escGate.virtualEnter then escGate.virtualEnter() end
                    end)
                end

                -- 2. Auto Accept Quest Offer when RaycityQuestUi.MissionOffer is visible (Yes / ยอมรับ)
                if qUi and qUi.Enabled then
                    local offer = qUi:FindFirstChild("MissionOffer")
                    if offer and offer.Visible then
                        pcall(function()
                            local qUiMod = require(ReplicatedStorage.RBRCQuest.QuestUI)
                            if qUiMod and qUiMod._offerAnswer then
                                qUiMod._offerAnswer(true)
                            end
                        end)
                        local yesBtn = offer:FindFirstChild("Yes", true)
                        if yesBtn and getconnections then
                            for _, c in ipairs(getconnections(yesBtn.Activated)) do pcall(function() c:Fire() end) end
                            for _, c in ipairs(getconnections(yesBtn.MouseButton1Click)) do pcall(function() c:Fire() end) end
                        end
                    end

                    -- 3. Auto Advance NPC Dialog (Next / ยืนยัน)
                    local npcDlg = qUi:FindFirstChild("NpcDialog")
                    if npcDlg and npcDlg.Visible then
                        pcall(function()
                            local qUiMod = require(ReplicatedStorage.RBRCQuest.QuestUI)
                            if qUiMod and qUiMod._dialogEnter then
                                qUiMod._dialogEnter()
                            end
                        end)
                        local nextBtn = npcDlg:FindFirstChild("Next", true)
                        if nextBtn and getconnections then
                            for _, c in ipairs(getconnections(nextBtn.Activated)) do pcall(function() c:Fire() end) end
                            for _, c in ipairs(getconnections(nextBtn.MouseButton1Click)) do pcall(function() c:Fire() end) end
                        end
                    end

                    -- 4. Auto Close Result Dialog
                    local resDlg = qUi:FindFirstChild("Result")
                    if resDlg and resDlg.Visible then
                        pcall(function()
                            local qUiMod = require(ReplicatedStorage.RBRCQuest.QuestUI)
                            if qUiMod then
                                if qUiMod.hideResult then qUiMod.hideResult() end
                                if qUiMod.closeDrops then qUiMod.closeDrops() end
                            end
                        end)
                        local closeBtn = resDlg:FindFirstChild("Close", true) or resDlg:FindFirstChildWhichIsA("GuiButton", true)
                        if closeBtn and getconnections then
                            for _, c in ipairs(getconnections(closeBtn.Activated)) do pcall(function() c:Fire() end) end
                            for _, c in ipairs(getconnections(closeBtn.MouseButton1Click)) do pcall(function() c:Fire() end) end
                        end
                    end
                end

                -- 5. Auto Dismiss GameGuide prompt if visible
                if gg and gg.Enabled then
                    local enterBtn = gg:FindFirstChild("Enter", true)
                    if enterBtn and getconnections then
                        for _, c in ipairs(getconnections(enterBtn.Activated)) do pcall(function() c:Fire() end) end
                        for _, c in ipairs(getconnections(enterBtn.MouseButton1Click)) do pcall(function() c:Fire() end) end
                    end
                end
            end)
        end
    end
end)

-- ==============================================================================
-- 📦 5.1. STATE & INVENTORY MANAGER FOR QUEST PROGRESSION
-- ==============================================================================
local function getSkillQuestState()
    local qq = nil
    pcall(function()
        if shared.RBRCQqState and shared.RBRCQqState.get then
            qq = shared.RBRCQqState.get()
        elseif getrenv and getrenv().shared and getrenv().shared.RBRCQqState and getrenv().shared.RBRCQqState.get then
            qq = getrenv().shared.RBRCQqState.get()
        end
    end)
    if qq and qq.active and qq.available then return qq end

    -- Extract directly from RBRCSkillQuestClient connections
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local sqPush = rep:FindFirstChild("RBRCQuest") and rep.RBRCQuest:FindFirstChild("Remotes") and rep.RBRCQuest.Remotes:FindFirstChild("SkillQuestPush")
        if sqPush and getconnections then
            local conns = getconnections(sqPush.OnClientEvent)
            for _, c in ipairs(conns) do
                local fn = c.Function
                if fn then
                    local u = debug.getupvalues(fn)
                    if u and type(u[1]) == "table" and u[1].active and u[1].available then
                        qq = u[1]
                        return
                    end
                end
            end
        end
    end)
    return qq
end

local function ensureInventorySpace(minFree)
    if not Config.AutoCleanInventory then return end
    minFree = minFree or 18
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local pcMod = rep:FindFirstChild("RaycityProfile") and rep.RaycityProfile:FindFirstChild("ProfileClient")
        local scMod = rep:FindFirstChild("RaycityShop") and rep.RaycityShop:FindFirstChild("ShopClient")
        if not pcMod or not scMod then return end
        local pc = require(pcMod)
        local sc = require(scMod)
        local data = pc.get and pc.get()
        if not data or not data.inventory then return end
        local count = 0
        for _ in pairs(data.inventory) do count = count + 1 end
        local free = (data.invSize or 30) - count
        if free < minFree then
            for cell, item in pairs(data.inventory) do
                if not item.bound then
                    local res = sc.request("sell", {
                        cell = tonumber(cell),
                        count = item.count or 1,
                        uid = item.uid
                    })
                    if res and res.ok then
                        free = free + 1
                        if free >= minFree then break end
                    end
                end
            end
        end
    end)
end

-- ==============================================================================
-- 🏁 6. ACTIVE QUEST DESTINATION DETECTOR & NPC RESOLVER
-- ==============================================================================
local function getNpcWorldPos(target)
    if not target then return nil end
    if typeof(target) == "Vector3" then return target end
    if typeof(target) == "CFrame" then return target.Position end
    if typeof(target) == "Instance" then
        if target:IsA("BasePart") then return target.Position end
        if target:IsA("Model") then
            local p = target.PrimaryPart or target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Root") or target:FindFirstChildWhichIsA("BasePart")
            if p then return p.Position end
            return target:GetPivot().Position
        end
    end

    local strTarget = tostring(target):lower()
    local cleanName = strTarget:gsub("<[^>]->", ""):gsub("[%[%]]", ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
    local numId = tonumber(cleanName:match("(%d+)$"))

    -- 1. Static known key coordinates
    if cleanName:find("welcome") or cleanName:find("newbie") or numId == 9900 or numId == 939900 then
        return Vector3.new(-531.45, 42.89, -5564.04)
    end
    if cleanName:find("aoi") or cleanName:find("อาโออิ") or numId == 2000 or numId == 932000 then
        return Vector3.new(-470.82, 43.23, -5585.53)
    end
    if cleanName:find("barry") or numId == 70 or numId == 940070 then
        return Vector3.new(-241.0, 45.4, -5788.4)
    end
    if cleanName:find("sarah") or numId == 68 or numId == 940068 then
        return Vector3.new(2085.6, 78.5, -5052.3)
    end
    if cleanName:find("ken") or numId == 69 or numId == 940069 then
        return Vector3.new(2125.1, 78.5, -5067.9)
    end

    -- 2. Workspace RBRCNpcs model (Full dynamic ID matching)
    local npcsFolder = workspace:FindFirstChild("RBRCNpcs")
    if npcsFolder then
        if numId then
            for _, n in ipairs(npcsFolder:GetChildren()) do
                local nName = n.Name
                local nId = nName:match("(%d+)$") or tostring(n:GetAttribute("NpcId") or ""):match("(%d+)$") or tostring(n:GetAttribute("MissionId") or ""):match("(%d+)$")
                if nId == tostring(numId) or nName:find(tostring(numId)) then
                    local p = n.PrimaryPart or n:FindFirstChild("HumanoidRootPart") or n:FindFirstChild("Root") or n:FindFirstChildWhichIsA("BasePart")
                    if p then return p.Position end
                    return n:GetPivot().Position
                end
            end
        end
        for _, n in ipairs(npcsFolder:GetChildren()) do
            local name = n.Name:lower()
            local thaiName = tostring(n:GetAttribute("NameThai") or ""):lower()
            local nativeName = tostring(n:GetAttribute("NameNative") or ""):lower()
            if name:find(cleanName, 1, true) or thaiName:find(cleanName, 1, true) or nativeName:find(cleanName, 1, true) then
                local p = n.PrimaryPart or n:FindFirstChild("HumanoidRootPart") or n:FindFirstChild("Root") or n:FindFirstChildWhichIsA("BasePart")
                if p then return p.Position end
                return n:GetPivot().Position
            end
        end
    end

    -- 3. QuestDataSkill.npcs table
    local skillPos = nil
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local qSkill = require(rep.RBRCQuest.QuestDataSkill)
        if qSkill and qSkill.npcs then
            if numId and qSkill.npcs[numId] and qSkill.npcs[numId].roblox then
                local r = qSkill.npcs[numId].roblox
                skillPos = Vector3.new(r[1], r[2], r[3])
                return
            end
            for id, nData in pairs(qSkill.npcs) do
                if nData.name and nData.name:lower():find(cleanName, 1, true) and nData.roblox then
                    local r = nData.roblox
                    skillPos = Vector3.new(r[1], r[2], r[3])
                    return
                end
            end
        end
    end)
    if skillPos then return skillPos end

    -- 4. QuestData.npc
    local qDataPos = nil
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local qData = require(rep.RBRCQuest.QuestData)
        if qData and qData.npc and numId then
            local d = qData.npc(numId)
            if d and d.position then qDataPos = d.position end
        end
    end)
    if qDataPos then return qDataPos end

    return nil
end

local function findQuestTargetNpc(targetName)
    if not targetName or targetName == "" then return nil end
    local cleanName = targetName:gsub("<[^>]->", ""):gsub("[%[%]]", ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
    local npcsFolder = workspace:FindFirstChild("RBRCNpcs")
    if not npcsFolder then return nil end

    -- Direct numerical ID check
    local directNum = cleanName:match("(%d+)")
    if directNum and npcsFolder:FindFirstChild("Npc_" .. directNum) then
        return npcsFolder:FindFirstChild("Npc_" .. directNum)
    end

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
            for _, npc in ipairs(npcsFolder:GetChildren()) do
                local num = npc.Name:match("(%d+)$")
                if num == targetId then
                    return npc
                end
            end
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
                for word in cleanName:gmatch("%S+") do
                    if #word >= 3 and t:find(word, 1, true) then
                        return npc
                    end
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
                    if type(uvs) == "table" then
                        for _, uv in pairs(uvs) do
                            if type(uv) == "table" and (uv.state == "running" or uv.state == "boarding") and type(uv.objectives) == "table" then
                                missionType = uv.state
                                for _, obj in ipairs(uv.objectives) do
                                    if obj.active and not obj.done and typeof(obj.target) == "Vector3" then
                                        targetPos = obj.target
                                        missionObj = obj
                                        break
                                    end
                                end
                                if targetPos then break end
                            end
                        end
                    end
                    if targetPos then break end
                end
            end
        end
    end)
    return targetPos, missionObj, missionType
end

local function getActiveQuestDestination()
    local okNav, nav = pcall(function() return require(ReplicatedStorage.RaycityUi.Navigation) end)
    local navPoints = nil
    if okNav and nav and nav.getGuideLine then
        local okGl, gl = pcall(nav.getGuideLine)
        if okGl and gl and gl.points and #gl.points > 0 then
            navPoints = gl.points
        end
    end

    -- Priority 0: Live Active Taxi/Driving/Delivery Mission Checkpoints (Running right now)
    local mTarget, mObj, mState = getActiveMissionTarget()
    if mTarget then
        if not navPoints and okNav and nav and nav.pointTo then
            pcall(nav.pointTo, mTarget)
            local okGl2, gl2 = pcall(nav.getGuideLine)
            if okGl2 and gl2 and gl2.points and #gl2.points > 0 then
                navPoints = gl2.points
            end
        end
        return mTarget, nil, navPoints, "checkpoint", mState
    end

    -- Priority 1: Check Skill Quest / Newbie Quest system
    local qqState = getSkillQuestState()

    if qqState and qqState.active and #qqState.active > 0 then
        local activeQ = qqState.active[1]
        local unfinishedObj = nil
        if activeQ.ojt then
            for _, obj in ipairs(activeQ.ojt) do
                if not obj.done then
                    unfinishedObj = obj
                    break
                end
            end
        end

        -- A. Need to return to NPC to report in / claim reward:
        if not unfinishedObj or unfinishedObj.returnTo or unfinishedObj.kind == "npc" or activeQ.completedExceptNpcId or activeQ.completedExceptAnyNpc or activeQ.status == "reward" or activeQ.completed then
            local targetId = activeQ.completedExceptNpcId or activeQ.rewardNpc or (unfinishedObj and unfinishedObj.target) or activeQ.npcId or 2000
            local pos = getNpcWorldPos(targetId)
            if pos then
                if not navPoints and okNav and nav and nav.pointTo then
                    pcall(nav.pointTo, pos)
                    local okGl, gl = pcall(nav.getGuideLine)
                    if okGl and gl and gl.points and #gl.points > 0 then navPoints = gl.points end
                end
                return pos, nil, navPoints, "skill_return_npc", activeQ
            end
        -- B. Need to do a mission NPC (e.g. Sarah 68, Barry 70, Ken 69):
        elseif unfinishedObj and (unfinishedObj.kind == "missionNpc" or unfinishedObj.kind == "mission") then
            local targetId = unfinishedObj.target
            local pos = getNpcWorldPos(targetId) or getNpcWorldPos("mission:" .. tostring(targetId))
            if pos then
                if not navPoints and okNav and nav and nav.pointTo then
                    pcall(nav.pointTo, pos)
                    local okGl, gl = pcall(nav.getGuideLine)
                    if okGl and gl and gl.points and #gl.points > 0 then navPoints = gl.points end
                end
                return pos, nil, navPoints, "skill_mission_npc", { quest = activeQ, targetId = targetId }
            end
        end
    end

    -- Priority 2: Check Favorite Quest UI (RBRCQuestFavorite widget on right side) with HTML tag stripping
    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    local favGui = pg and pg:FindFirstChild("RBRCQuestFavorite")
    if favGui and favGui.Enabled then
        for _, d in ipairs(favGui:GetDescendants()) do
            if d:IsA("TextLabel") and d.Visible and d.Text ~= "" and d.Text ~= "Favorite Quest" then
                local rawText = d.Text:gsub("<[^>]->", "") -- Strip HTML/font tags
                for _, line in ipairs(string.split(rawText, "\n")) do
                    local cleanLine = line:gsub("^%s+", ""):gsub("%s+$", "")
                    if cleanLine ~= "" then
                        local extracted = cleanLine:match("[Gg]o back to%s*(.+)")
                            or cleanLine:match("[Gg]o to%s*(.+)")
                            or cleanLine:match("[Tt]alk to%s*(.+)")
                            or cleanLine:match("กลับไปหา%s*(.+)")
                            or cleanLine:match("ไปหา%s*(.+)")
                            or cleanLine:match("ไปพบ%s*(.+)")
                            or cleanLine:match("คุยกับ%s*(.+)")
                        if extracted then
                            local cleanTarget = extracted:gsub("[%[%]]", ""):gsub("^%s+", ""):gsub("%s+$", "")
                            local pos = getNpcWorldPos(cleanTarget)
                            if pos then
                                if not navPoints and okNav and nav and nav.pointTo then
                                    pcall(nav.pointTo, pos)
                                    local okGl, gl = pcall(nav.getGuideLine)
                                    if okGl and gl and gl.points and #gl.points > 0 then navPoints = gl.points end
                                end
                                return pos, nil, navPoints, "favorite_npc_target", cleanTarget
                            end
                        end
                    end
                end
            end
        end
    end

    -- Priority 3: Live Active Taxi/Driving Mission checkpoints from RBRCQuestClient
    local mTarget, mObj, mState = getActiveMissionTarget()
    if mTarget then
        if not navPoints and okNav and nav and nav.pointTo then
            pcall(nav.pointTo, mTarget)
            local okGl2, gl2 = pcall(nav.getGuideLine)
            if okGl2 and gl2 and gl2.points and #gl2.points > 0 then
                navPoints = gl2.points
            end
        end
        return mTarget, nil, navPoints, "checkpoint", mState
    end

    -- Priority 4: Navigation GuideLine (Ground Truth from RaycityUi.Navigation)
    if okNav and nav then
        if nav.getGuideLine then
            local okGl, gl = pcall(nav.getGuideLine)
            if okGl and gl and gl.target and typeof(gl.target) == "Vector3" then
                return gl.target, nil, gl.points or navPoints, "guideline", nil
            end
        end
        if nav.getGuide then
            local okG, g = pcall(nav.getGuide)
            if okG and g and g.destRoblox and typeof(g.destRoblox) == "Vector3" then
                return g.destRoblox, nil, navPoints, "guide", nil
            end
        end
    end

    -- Priority 5: Road Guide Quads from workspace.RaycityNavigation
    local rNav = workspace:FindFirstChild("RaycityNavigation")
    if rNav then
        local guideBucket = rNav:FindFirstChild("GuideBucket")
        if guideBucket then
            local quads = {}
            for _, c in ipairs(guideBucket:GetChildren()) do
                if c:IsA("BasePart") then
                    table.insert(quads, c.Position)
                end
            end
            if #quads > 0 then
                if not navPoints then navPoints = quads end
                local carRoot = getCarRoot()
                if carRoot then
                    local maxD = 0
                    local targetQuad = quads[#quads]
                    for _, pt in ipairs(quads) do
                        local d = (pt - carRoot.Position).Magnitude
                        if d > maxD then
                            maxD = d
                            targetQuad = pt
                        end
                    end
                    if maxD > 20 then
                        return targetQuad, guideBucket, navPoints, "guidebucket", nil
                    end
                end
            end
        end
    end

    -- Priority 6: Parse candidate texts from other HUD elements
    local candidateTexts = {}
    if pg then
        for _, gName in ipairs({ "RaycityQuestUi", "RBRCGameGuide", "RaycityHud" }) do
            local g = pg:FindFirstChild(gName)
            if g and g.Enabled then
                for _, d in ipairs(g:GetDescendants()) do
                    if d:IsA("TextLabel") and d.Visible and d.Text ~= "" then
                        local t = d.Text:gsub("<[^>]->", "")
                        if t:lower():find("go back") or t:lower():find("talk to") or t:lower():find("meet") or t:lower():find("deliver")
                            or t:find("กลับไปหา") or t:find("ไปพบ") or t:find("คุยกับ") or t:find("ส่ง") or t:find("ภารกิจ") then
                            table.insert(candidateTexts, t)
                        end
                    end
                end
            end
        end
    end

    local targetNpcModel = nil
    for _, txt in ipairs(candidateTexts) do
        for _, rawLine in ipairs(string.split(txt, "\n")) do
            local line = rawLine:gsub("^%s+", ""):gsub("%s+$", "")
            if line ~= "" then
                local extracted = line:match("[Gg]o back to%s*(.+)")
                    or line:match("[Gg]o to%s*(.+)")
                    or line:match("[Tt]alk to%s*(.+)")
                    or line:match("กลับไปหา%s*(.+)")
                    or line:match("ไปพบ%s*(.+)")
                    or line:match("คุยกับ%s*(.+)")
                if extracted then
                    local clean = extracted:gsub("[%[%]]", ""):gsub("^%s+", ""):gsub("%s+$", "")
                    local pos = getNpcWorldPos(clean)
                    if pos then
                        return pos, nil, navPoints, "npc_pos", clean
                    end
                    local npc = findQuestTargetNpc(clean)
                    if npc then
                        targetNpcModel = npc
                        break
                    end
                end
            end
        end
        if targetNpcModel then break end
    end

    if targetNpcModel then
        local p = targetNpcModel.PrimaryPart or targetNpcModel:FindFirstChild("HumanoidRootPart") or targetNpcModel:FindFirstChild("Root") or targetNpcModel:FindFirstChildWhichIsA("BasePart")
        if p then
            return p.Position, targetNpcModel, navPoints, "npc", nil
        end
    end

    -- Priority 7: Existing workspace quest markers
    local qMarkers = workspace:FindFirstChild("RBRCQuestMarkers") or workspace:FindFirstChild("RBRCQuestGuide")
    if qMarkers then
        for _, m in ipairs(qMarkers:GetChildren()) do
            local p = m:IsA("BasePart") and m or m:FindFirstChildWhichIsA("BasePart") or (m:IsA("Model") and m.PrimaryPart)
            if p then
                return p.Position, p, navPoints, "marker", nil
            end
        end
    end

    return nil, nil, nil, nil, nil
end


-- ==============================================================================
-- 🚗 7. MASTER AUTONOMOUS QUEST FARMING ENGINE (ระบบขับเองอัตโนมัติ 100% ลื่นไหล ไม่ติดค้าง)
-- ==============================================================================
local questFarmState = "SEARCHING" -- "SEARCHING" | "DRIVING" | "DELIVERING" | "CLAIMING" | "TALKING"
local npcVisitCooldown = {} -- [npcName] = os.clock()

-- Autonomous Driving State & Anti-Stuck Tracking
local currentAutoTarget = nil
local lastWarpTime = 0
local isWarping = false
local lastProgressPos = nil
local lastProgressTime = os.clock()

local function getAutoDrive()
    local ok, ad = pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local rUi = rep:FindFirstChild("RaycityUi")
        return rUi and rUi:FindFirstChild("AutoDrive") and require(rUi.AutoDrive)
    end)
    return ok and ad or nil
end

local function stopAutoDrive()
    pcall(function()
        local ad = getAutoDrive()
        if ad and ad.stop then
            ad.stop()
        end
    end)
    currentAutoTarget = nil
end

local function executeMoveStep(targetPos, destType, speedKmh)
    local root = getCarRoot()
    local rcd = getRCDrive()
    if not root or not targetPos then return end
    local dist = (root.Position - targetPos).Magnitude
    local mode = Config.QuestDriveMode or "Realistic Road Drive"

    -- ⚡ Mode 1: Instant Warp (Single-shot teleport with cooldown, NEVER spams spawnCar)
    if mode == "Instant Warp" then
        if not isWarping and (os.clock() - lastWarpTime) >= 1.2 and dist > 6 then
            isWarping = true
            stopAutoDrive()
            pcall(function()
                local dir = dist > 0.1 and (targetPos - root.Position).Unit or root.CFrame.LookVector
                local targetCF
                if destType == "checkpoint" then
                    targetCF = CFrame.new(targetPos + dir * 15, targetPos + dir * 30)
                else
                    targetCF = CFrame.new(targetPos + Vector3.new(0, 1.5, 0))
                end

                if rcd and type(rcd.teleport) == "function" then
                    rcd.teleport(targetCF)
                elseif root then
                    root.CFrame = targetCF
                end

                if destType == "checkpoint" then
                    root.AssemblyLinearVelocity = dir * 65
                    if rcd and type(rcd.phys) == "table" then
                        rcd.phys.v = dir * 65
                        rcd.phys.throttle = 1
                        rcd.phys.brake = 0
                    end
                else
                    root.AssemblyLinearVelocity = Vector3.zero
                end
            end)
            lastWarpTime = os.clock()
            task.wait(1.0)
            isWarping = false
        end
        return
    end

    -- ⚡ Mode 2: Hybrid Cruise (Instant warp for long distances > 80m, then road cruise)
    if mode == "Hybrid Cruise" and dist > 80 then
        if not isWarping and (os.clock() - lastWarpTime) >= 2.0 then
            isWarping = true
            stopAutoDrive()
            local dir = (targetPos - root.Position).Unit
            local nearWarpPos = targetPos - dir * 25
            pcall(function()
                local targetCF = CFrame.new(nearWarpPos + Vector3.new(0, 1.5, 0), targetPos)
                if rcd and type(rcd.teleport) == "function" then
                    rcd.teleport(targetCF)
                elseif root then
                    root.CFrame = targetCF
                end
            end)
            lastWarpTime = os.clock()
            task.wait(1.2)
            isWarping = false
            return
        end
    end

    -- 🏎️ Modes 3 & 4: Native AutoDrive Engine (Realistic Road Drive & Hyper Sonic Glide)
    local ad = getAutoDrive()
    if not ad then
        -- Fallback if AutoDrive is not loaded
        pcall(driveCarStep, targetPos, speedKmh or 160, false)
        return
    end

    -- Speed & Driving Tuning
    local desiredSpeed = speedKmh or Config.QuestDriveSpeed or 220
    if mode == "Realistic Road Drive" then
        desiredSpeed = math.min(180, desiredSpeed)
    elseif mode == "Hyper Sonic Glide" then
        desiredSpeed = math.max(260, desiredSpeed)
    end
    local maxSpeedMps = desiredSpeed / 3.6

    pcall(function()
        if ad.C then
            ad.C.maxSpeed = maxSpeedMps
            if mode == "Hyper Sonic Glide" then
                ad.C.cap1 = math.max(300, desiredSpeed * 1.15)
                ad.C.cap2 = math.max(250, desiredSpeed * 0.95)
                ad.C.cap3 = math.max(200, desiredSpeed * 0.8)
                ad.C.nearDestM = (destType == "checkpoint") and 5 or 8
            else
                ad.C.cap1 = math.min(200, desiredSpeed * 1.0)
                ad.C.cap2 = math.min(160, desiredSpeed * 0.85)
                ad.C.cap3 = math.min(120, desiredSpeed * 0.7)
                ad.C.nearDestM = (destType == "checkpoint") and 6 or 10
            end
        end
    end)

    -- Plan / update AutoDrive route when target changes (> 8 studs) or stopped
    local needsNewRoute = false
    if not currentAutoTarget or (currentAutoTarget - targetPos).Magnitude > 8 then
        needsNewRoute = true
    elseif not ad.isActive or not ad.isActive() then
        needsNewRoute = true
    end

    if needsNewRoute then
        currentAutoTarget = targetPos
        pcall(function()
            ad.requestAutoMove(targetPos, "SongHubQuest")
            ad.start()
        end)
    end

    -- Hyper Sonic Glide: Apply Nitro boost and extra torque in physics
    if mode == "Hyper Sonic Glide" and rcd and type(rcd.phys) == "table" then
        pcall(function()
            rcd.phys.boosting = true
            rcd.phys.torqueBonus = 8000
            rcd.phys.throttle = 1
            if rcd.phys.brake then rcd.phys.brake = 0 end
        end)
    end
end

task.spawn(function()
    while isAlive() do
        task.wait(0.06)
        if Config.AutoFarmQuests then
            pcall(function()
                local root = getCarRoot()
            local rcd = getRCDrive()
            if root then
                local destPos, destObj, points, destType, mState = getActiveQuestDestination()

                -- Wait while passenger is boarding taxi
                if mState == "boarding" then
                    task.wait(0.5)
                    return
                end

                -- Universal Non-Destructive Anti-Stuck Detection
                if destPos and not isWarping then
                    local movedDelta = lastProgressPos and (root.Position - lastProgressPos).Magnitude or 10
                    if movedDelta > 2.0 then
                        lastProgressPos = root.Position
                        lastProgressTime = os.clock()
                    else
                        if (os.clock() - lastProgressTime) > 3.5 then
                            -- Car stuck in place for 3.5s: replan route and apply gentle nudge
                            local ad = getAutoDrive()
                            if ad then
                                pcall(function()
                                    ad.stop()
                                    task.wait(0.05)
                                    ad.requestAutoMove(destPos, "SongHubUnstuck")
                                    ad.start()
                                end)
                            end
                            if rcd and type(rcd.phys) == "table" then
                                rcd.phys.v = root.CFrame.LookVector * 15 + Vector3.new(0, 3, 0)
                                rcd.phys.throttle = 1
                                rcd.phys.brake = 0
                            end
                            lastProgressTime = os.clock()
                        end
                    end
                else
                    lastProgressPos = root.Position
                    lastProgressTime = os.clock()
                end

                if destPos then
                    if destType == "checkpoint" then
                        -- ==========================================================
                        -- A1. CHECKPOINT / FINISH GATE: DRIVE THROUGH AT FULL SPEED!
                        -- ==========================================================
                        questFarmState = "RACING"
                        local carPos = root.Position
                        local fwd = (destPos - carPos)
                        local gateDist = fwd.Magnitude
                        local dir = fwd.Magnitude > 0.1 and fwd.Unit or root.CFrame.LookVector

                        -- 1. Aim 35 studs PAST the checkpoint so AutoDrive powers all the way through the gate
                        local throughPos = destPos + dir * 35

                        -- 2. Trigger Touch on all gate trigger parts within 25 studs
                        pcall(function()
                            if firetouchinterest then
                                local parts = workspace:GetPartBoundsInRadius(destPos, 25)
                                for _, p in ipairs(parts) do
                                    if p:IsA("BasePart") and p ~= root and not p:IsDescendantOf(workspace.MyCar) then
                                        firetouchinterest(root, p, 0)
                                        task.wait(0.01)
                                        firetouchinterest(root, p, 1)
                                    end
                                end
                            end
                        end)

                        -- 3. Trigger remote events for checkpoint / finish passing
                        pcall(function()
                            local qRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
                            if qRemotes and qRemotes:FindFirstChild("QuestEventUp") then
                                qRemotes.QuestEventUp:FireServer("GoalReached", (destObj and destObj.Name) or "Checkpoint")
                                qRemotes.QuestEventUp:FireServer("FinishLine", "Finish")
                            end
                            local qDeliver = require(ReplicatedStorage.RBRCQuest.QuestDeliver)
                            if qDeliver then
                                if qDeliver.finish then qDeliver.finish() end
                                if qDeliver.trunk then qDeliver.trunk(true) end
                            end
                        end)

                        -- 4. Drive through the gate at full speed!
                        executeMoveStep(throughPos, "checkpoint", math.max(220, Config.QuestDriveSpeed))

                        -- 5. Close to gate (<= 20 studs): punch through with high forward velocity
                        if gateDist <= 20 then
                            if rcd and type(rcd.phys) == "table" then
                                rcd.phys.throttle = 1
                                rcd.phys.brake = 0
                                rcd.phys.v = dir * 65
                            end
                            root.AssemblyLinearVelocity = dir * 65
                        end

                    else
                        -- ==========================================================
                        -- A2. NPC / DELIVERY DESTINATION: DRIVE TOWARDS OBJECTIVE
                        -- ==========================================================
                        questFarmState = "DRIVING"
                        local dist = (root.Position - destPos).Magnitude
                        local arrivalThreshold = 13

                        if dist > arrivalThreshold then
                            -- Drive smoothly along road lanes towards destination
                            executeMoveStep(destPos, destType, Config.QuestDriveSpeed)
                        else
                            -- Arrived at NPC / destination: Stop car and interact
                            stopAutoDrive()

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

                            if destType == "skill_return_npc" or destType == "favorite_npc_target" then
                                -- Arrived at NPC to complete quest and claim reward
                                questFarmState = "CLAIMING"
                                local activeQ = (typeof(mState) == "table") and mState or nil
                                local targetNpcId = activeQ and (activeQ.completedExceptNpcId or activeQ.rewardNpc or activeQ.npcId) or 2000
                                local qId = activeQ and activeQ.questId or 990203

                                ensureInventorySpace(18)

                                local sqRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
                                local sReq = sqRemotes and sqRemotes:FindFirstChild("SkillQuestRequest")
                                if sReq then
                                    pcall(function()
                                        sReq:InvokeServer({ op = "talk", npcId = targetNpcId, carPos = root.Position })
                                    end)
                                    task.wait(0.08)
                                    pcall(function()
                                        sReq:InvokeServer({ op = "reward", questId = qId, npcId = targetNpcId, carPos = root.Position, choice = 0 })
                                    end)
                                end

                                pcall(function()
                                    local renv = getrenv and getrenv() or { shared = shared }
                                    local qt = renv.shared and renv.shared.RaycityQuestTalk
                                    if qt and qt.open and activeQ then
                                        qt.open(activeQ)
                                    end
                                end)

                                pressReturnKey()
                                task.wait(0.25)

                            elseif destType == "skill_mission_npc" then
                                questFarmState = "TALKING"
                                local targetId = (typeof(mState) == "table" and mState.targetId) or 70
                                local sqRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
                                local sReq = sqRemotes and sqRemotes:FindFirstChild("SkillQuestRequest")
                                local qReq = sqRemotes and sqRemotes:FindFirstChild("QuestRequest")
                                if sReq then
                                    pcall(function()
                                        sReq:InvokeServer({ op = "talk", npcId = "mission:" .. tostring(targetId), carPos = root.Position })
                                        sReq:InvokeServer({ op = "talk", npcId = targetId, carPos = root.Position })
                                    end)
                                end
                                if qReq then
                                    pcall(function()
                                        qReq:InvokeServer({ op = "talk", npcId = "mission:" .. tostring(targetId), carPos = root.Position })
                                        qReq:InvokeServer({ op = "talk", npcId = targetId, carPos = root.Position })
                                    end)
                                end
                                pressReturnKey()
                                task.wait(0.25)

                            else
                                questFarmState = "DELIVERING"
                                if destObj and destObj:IsA("BasePart") and firetouchinterest then
                                    pcall(function()
                                        firetouchinterest(root, destObj, 0)
                                        task.wait(0.02)
                                        firetouchinterest(root, destObj, 1)
                                    end)
                                end
                                pcall(function()
                                    local rep = game:GetService("ReplicatedStorage")
                                    local qDeliver = require(rep.RBRCQuest.QuestDeliver)
                                    if qDeliver then
                                        if qDeliver.finish then qDeliver.finish() end
                                        if qDeliver.trunk then qDeliver.trunk(true) end
                                    end
                                end)
                                pcall(function()
                                    local qRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
                                    if qRemotes and qRemotes:FindFirstChild("QuestEventUp") then
                                        qRemotes.QuestEventUp:FireServer("GoalReached", destObj and destObj.Name or "Goal")
                                    end
                                end)
                                pressReturnKey()
                                task.wait(0.25)
                            end
                        end
                    end
                else
                    -- ==========================================================
                    -- C. NO ACTIVE QUEST IN PROGRESS: FIND AVAILABLE QUEST GIVER NPC
                    -- ==========================================================
                    if Config.LoopNextQuest or Config.AutoStoryProgression then
                        questFarmState = "SEARCHING"

                        -- 0. Check Skill/Story Quests available to auto-accept:
                        local qq = getSkillQuestState()
                        if qq and qq.available and #qq.available > 0 and (Config.AutoAcceptQuest or Config.AutoStoryProgression) then
                            local bestQ = nil
                            local pLevel = qq.level or 1
                            -- Sort: Main story/newbie quests (990201 - 990999) first, then Skill quests
                            for _, q in ipairs(qq.available) do
                                local reqL = q.reqMinLevel or 1
                                if pLevel >= reqL then
                                    if q.questId >= 990201 and q.questId <= 990999 then
                                        if not bestQ or bestQ.questId > q.questId then
                                            bestQ = q
                                        end
                                    elseif not bestQ and (q.questCategory == 1 or q.questId >= 100000) then
                                        bestQ = q
                                    end
                                end
                            end

                            if bestQ then
                                local nPos = getNpcWorldPos(bestQ.npcId)
                                if nPos then
                                    local distToNpc = (root.Position - nPos).Magnitude
                                    if distToNpc > 13 then
                                        executeMoveStep(nPos, "npc", Config.QuestDriveSpeed)
                                        return
                                    else
                                        stopAutoDrive()
                                        if rcd and rcd.phys then
                                            rcd.phys.v = Vector3.zero
                                            rcd.phys.throttle = 0
                                            rcd.phys.brake = 1
                                            rcd.phys.airMode = false
                                            rcd.phys.anyContact = true
                                        end
                                        root.AssemblyLinearVelocity = Vector3.zero
                                        root.AssemblyAngularVelocity = Vector3.zero
                                        local sqRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
                                        local sReq = sqRemotes and sqRemotes:FindFirstChild("SkillQuestRequest")
                                        if sReq then
                                            pcall(function()
                                                sReq:InvokeServer({ op = "talk", npcId = bestQ.npcId, carPos = root.Position })
                                            end)
                                            task.wait(0.08)
                                            pcall(function()
                                                sReq:InvokeServer({ op = "accept", questId = bestQ.questId, npcId = bestQ.npcId, carPos = root.Position })
                                            end)
                                        end
                                        pressReturnKey()
                                        task.wait(0.3)
                                        return
                                    end
                                end
                            end
                        end
                        local targetNpc, targetDist = nil, 99999
                        local npcsFolder = workspace:FindFirstChild("RBRCNpcs")

                        -- 1. Check for NPCs near active RaycityNpcJobIcons
                        local jobIcons = workspace:FindFirstChild("RaycityNpcJobIcons")
                        if jobIcons and npcsFolder then
                            for _, icon in ipairs(jobIcons:GetChildren()) do
                                local iconPart = icon:IsA("BasePart") and icon or icon:FindFirstChildWhichIsA("BasePart") or (icon:IsA("Model") and icon.PrimaryPart)
                                if iconPart then
                                    for _, npc in ipairs(npcsFolder:GetChildren()) do
                                        local nPart = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart")
                                        if nPart and (npcVisitCooldown[npc.Name] == nil or (os.clock() - npcVisitCooldown[npc.Name]) > 25) then
                                            if (nPart.Position - iconPart.Position).Magnitude <= 20 then
                                                local d = (root.Position - nPart.Position).Magnitude
                                                if d < targetDist then
                                                    targetDist = d
                                                    targetNpc = nPart
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        -- 2. Fallback: Find nearest NPC that is NOT on recent visit cooldown
                        if not targetNpc and npcsFolder then
                            for _, npc in ipairs(npcsFolder:GetChildren()) do
                                local nPart = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart")
                                if nPart and (npcVisitCooldown[npc.Name] == nil or (os.clock() - npcVisitCooldown[npc.Name]) > 25) then
                                    local d = (root.Position - nPart.Position).Magnitude
                                    if d < targetDist then
                                        targetDist = d
                                        targetNpc = nPart
                                    end
                                end
                            end
                        end

                        -- 3. If all NPCs on cooldown, pick the nearest NPC overall
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
                            local nPos = targetNpc.Position
                            -- Route along road to NPC using Navigation
                            local npcPoints = nil
                            local okNav, nav = pcall(function() return require(ReplicatedStorage.RaycityUi.Navigation) end)
                            if okNav and nav and nav.pointTo then
                                pcall(nav.pointTo, nPos)
                                local okGl, gl = pcall(nav.getGuideLine)
                                if okGl and gl and gl.points and #gl.points > 0 then
                                    npcPoints = gl.points
                                end
                            end

                            local targetWp = nPos
                            if npcPoints and #npcPoints > 0 then
                                local cIdx = 1
                                local cMin = math.huge
                                local cPos = root.Position
                                for i = 1, #npcPoints do
                                    local d = (npcPoints[i] - cPos).Magnitude
                                    if d < cMin then
                                        cMin = d
                                        cIdx = i
                                    end
                                end
                                targetWp = npcPoints[#npcPoints]
                                for i = cIdx, #npcPoints do
                                    if (npcPoints[i] - cPos).Magnitude >= 25 then
                                        targetWp = npcPoints[i]
                                        break
                                    end
                                end
                            end

                            if targetDist > 13 then
                                executeMoveStep(nPos, "npc", math.min(180, Config.QuestDriveSpeed))
                            else
                                -- Arrived at NPC: Stop car and interact
                                stopAutoDrive()
                                if rcd and rcd.phys then
                                    rcd.phys.v = Vector3.zero
                                    rcd.phys.throttle = 0
                                    rcd.phys.brake = 1
                                    rcd.phys.airMode = false
                                    rcd.phys.anyContact = true
                                end
                                root.AssemblyLinearVelocity = Vector3.zero
                                root.AssemblyAngularVelocity = Vector3.zero

                                local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
                                local hasPrompt = (pg and pg:FindFirstChild("RBRCNpcTalkPrompt") and pg.RBRCNpcTalkPrompt.Enabled)
                                    or (pg and pg:FindFirstChild("RaycityQuestUi") and pg.RaycityQuestUi.Enabled)
                                if not hasPrompt and targetNpc.Parent then
                                    npcVisitCooldown[targetNpc.Parent.Name] = os.clock()
                                end

                                pressReturnKey()
                                task.wait(0.25)
                            end
                        end
                    end
                end
            end
            end)
        end
    end
end)


-- ==============================================================================
-- 🚀 8. VEHICLE SPEED & FLIGHT CONTROLLER
-- ==============================================================================
local flyBodyGyro = nil
local flyBodyVelocity = nil

updateFlyState = function()
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
    while isAlive() do
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
    while isAlive() do
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
    while isAlive() do
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
    while isAlive() do
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
pcall(function()
    if LocalPlayer and LocalPlayer.Idled then
        LocalPlayer.Idled:Connect(function()
            if Config.AntiAfk then
                pcall(function()
                    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    task.wait(1)
                    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                end)
            end
        end)
    end
end)

local playerName = (LocalPlayer and LocalPlayer.Name) or "Driver"
pcall(function()
    WindUI:Notify({
        Title = "Raycity RB Hub Loaded! 🏎️",
        Content = "Welcome " .. playerName .. "!\nAutonomous Quest Driver ready.",
        Duration = 4,
        Icon = "sparkles"
    })
end)

print("[Raycity Hub] ✨ Successfully loaded Raycity RB Automation Hub with Autonomous Driving Engine!")