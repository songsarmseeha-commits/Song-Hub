-- [[
--   ======================================================================
--   ⚔️ [GLORYBOUND] All-in-One Auto Gym, Combat & Arena Farming Hub
--   Author: Song Hub Official / Universal Edition
--   Target Game: [TRIALS] GloryBound (PlaceId: 137629355240872, UniverseId: 10768652372)
--   UI Framework: WindUI
--   Features:
--     - 🏋️ Auto Gym Barbell Trainer (Smart Walk/Warp + Rep Spammer)
--     - ⚔️ Master Combat Kill Aura (Auto Attack Enemies in Arena & Trials)
--     - 🛡️ God Block / Auto Perfect Parry (Reflect & Stagger Enemies)
--     - 💥 Auto Cast Equipped Abilities on Cooldown
--     - 🏃 Auto Dash Away on Low Health (<30%)
--     - 🌟 Auto Pick Roguelike Boons & Upgrades
--     - ⏩ Instant Boss Cutscene Skipper
--     - 🏟️ Auto Queue Arena PVE (Continuous Battle Loops)
--     - ⚡ Custom WalkSpeed & JumpPower Booster
--     - 👻 No-Clip & Barrier Penetration
--     - 📍 Instant Lobby Teleports (Gym, Arena Gate, Shrine, Vault, Rift)
--     - 🔄 Auto Rebirth & Daily Reward Collector
--     - 🛡️ Anti-AFK 24/7 Protection
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

-- Multi-Execute Management
getgenv().__GloryBoundHubRunId = (tonumber(getgenv().__GloryBoundHubRunId) or 0) + 1
local currentScriptRunId = getgenv().__GloryBoundHubRunId

local function isAlive()
    local activeRun = tonumber(getgenv().__GloryBoundHubRunId)
    if activeRun and currentScriptRunId and activeRun > currentScriptRunId then
        return false
    end
    return true
end

-- Clean up previous Hub ScreenGuis (NEVER touch PlayerGui)
pcall(function()
    local roots = {
        (typeof(gethui) == "function" and gethui()) or nil,
        game:GetService("CoreGui")
    }
    for _, root in ipairs(roots) do
        if root then
            for _, child in ipairs(root:GetChildren()) do
                if child.Name == "WindUI" or child.Name == "GloryBoundHub" or child.Name == "SongHub" then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end)

-- ==============================================================================
-- ⚙️ CONFIGURATION & STATE
-- ==============================================================================
local Config = {
    -- Gym & Training
    AutoTrain = false,
    SelectedBarbell = "B6", -- "B1", "B2", "B3", "B4", "B5", "B6"
    TrainSpeedRps = 2.5,
    AutoRestOnHighFatigue = false,

    -- Combat & Arena
    KillAura = false,
    AttackRadius = 35,
    AutoParry = false,
    AutoAbility = false,
    AutoDodgeLowHp = false,
    DodgeHpThreshold = 30,
    AutoBoonPick = false,
    AutoSkipCutscenes = true,

    -- Matchmaking & Trials
    AutoQueueArena = false,

    -- Movement & Physics
    SpeedMultiplierEnabled = false,
    WalkSpeed = 28,
    JumpBooster = false,
    JumpHeight = 75,
    NoClip = false,

    -- Progression & Automation
    AutoRebirth = false,
    AutoClaimDaily = true,

    -- Safety
    AntiAfk = true
}

local LOBBY_WAYPOINTS = {
    ["🏋️ Gym (Barbells)"] = Vector3.new(-69, 3.2, 18.2),
    ["🏟️ Arena Gate"] = Vector3.new(-24, 3, 2.9),
    ["🏛️ Shrine of Mars (Rebirth)"] = Vector3.new(-104.6, 0.8, 0.8),
    ["📦 Vault Guard (Chests)"] = Vector3.new(34.5, 3.8, -21),
    ["🌀 The Rift"] = Vector3.new(38, 1.4, -32.9),
    ["⚔️ Sparring Pit"] = Vector3.new(-16, 3, -40),
    ["📜 Hall of Fame"] = Vector3.new(-10, 3, -15)
}

local BARBELL_COORDS = {
    ["B1"] = Vector3.new(-109, 3.2, 18.2),
    ["B2"] = Vector3.new(-99, 3.2, 18.2),
    ["B3"] = Vector3.new(-89, 3.2, 18.2),
    ["B4"] = Vector3.new(-79, 3.2, 18.2),
    ["B5"] = Vector3.new(-69, 3.2, 18.2),
    ["B6"] = Vector3.new(-59, 3.2, 18.2)
}

-- Forward declarations
local teleportPlayer = function(pos) end

-- ==============================================================================
-- 🎨 WINDUI FRAMEWORK LOADER
-- ==============================================================================
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
    warn("[GloryBound Hub] ❌ Failed to download WindUI framework. Check connection.")
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

-- Create Hub Window
local Window = WindUI:CreateWindow({
    Title = "GloryBound | Song Hub [v1.0]",
    Icon = "swords",
    Author = "by Song Hub Dev",
    Folder = "GloryBoundHub",
    Size = UDim2.fromOffset(580, 480),
    Transparent = true,
    Theme = "Dark",
    Acrylic = false,
    Resizable = true
})

-- ==============================================================================
-- 🏋️ TAB 1: GYM & TRAINING
-- ==============================================================================
local TabGym = Window:Tab({ Title = "Gym & Strength", Icon = "dumbbell" })

TabGym:Paragraph({
    Title = "🏋️ Auto Barbell & Strength Training",
    Desc = "บอทจะวาร์ปไปที่บาร์เบล, กดเริ่มยกน้ำหนัก, และสแปม Rep ให้อัตโนมัติ เพิ่มค่า Strength และเลเวลแบบ AFK ตลอด 24 ชม.",
    Image = "dumbbell"
})

TabGym:Toggle({
    Title = "🏋️ Master Auto Train (เปิดบอทยกบาร์เบล)",
    Desc = "เปิดใช้งานระบบยกน้ำหนักฟาร์มสเตตัส Strength อัตโนมัติ",
    Value = Config.AutoTrain,
    Callback = function(val)
        Config.AutoTrain = val
        if val then
            WindUI:Notify({ Title = "Auto Train Started! 🏋️", Content = "Training on barbell: " .. Config.SelectedBarbell, Duration = 3, Icon = "play" })
        else
            pcall(function()
                local rep = game:GetService("ReplicatedStorage")
                rep.Remotes.TrainStop:FireServer()
            end)
            WindUI:Notify({ Title = "Auto Train Paused", Content = "Stopped barbell workout.", Duration = 2, Icon = "pause" })
        end
    end
})

TabGym:Dropdown({
    Title = "🏋️ Select Barbell Station (เลือกแท่นบาร์เบล)",
    Desc = "เลือกแท่นบาร์เบลที่ต้องการใช้งานในห้องยิม",
    Values = { "B1", "B2", "B3", "B4", "B5", "B6" },
    Value = Config.SelectedBarbell,
    Callback = function(val)
        Config.SelectedBarbell = val
    end
})

TabGym:Slider({
    Title = "⚡ Rep Speed (ความเร็วยกน้ำหนัก ต่อวินาที)",
    Desc = "ปรับความถี่ในการส่ง Rep ยกน้ำหนัก (แนะนำ 2.0 - 2.8 reps/sec)",
    Value = { Min = 1, Max = 3, Default = Config.TrainSpeedRps },
    Callback = function(val)
        Config.TrainSpeedRps = val
    end
})

TabGym:Button({
    Title = "🛑 Force Stop Workout (หยุดยกทันที)",
    Desc = "ส่งคำสั่ง TrainStop ปลดตัวละครออกจากบาร์เบล",
    Icon = "square",
    Callback = function()
        pcall(function()
            local rep = game:GetService("ReplicatedStorage")
            rep.Remotes.TrainStop:FireServer()
        end)
        WindUI:Notify({ Title = "Stopped", Content = "Sent TrainStop remote signal.", Duration = 2 })
    end
})

-- ==============================================================================
-- ⚔️ TAB 2: COMBAT & KILL AURA
-- ==============================================================================
local TabCombat = Window:Tab({ Title = "Combat & Aura", Icon = "swords" })

TabCombat:Paragraph({
    Title = "⚔️ Arena Combat Engine",
    Desc = "โจมตีศัตรูในระยะรอบตัวอัตโนมัติ (Kill Aura), สแปมสกิล, และระบบบล็อกสะท้อนการโจมตี (Perfect Parry) ดาเมจสวนกลับ 100%",
    Image = "shield"
})

TabCombat:Toggle({
    Title = "⚔️ Master Kill Aura (ออโต้ฟัน/ยิงศัตรูรอบตัว)",
    Desc = "โจมตีมอนสเตอร์และศัตรูทั้งหมดในระยะโดยไม่ต้องคลิกเอง",
    Value = Config.KillAura,
    Callback = function(val)
        Config.KillAura = val
    end
})

TabCombat:Slider({
    Title = "📡 Kill Aura Radius (ระยะการโจมตี Studs)",
    Desc = "ระยะในการตรวจจับและฟาดฟันศัตรู",
    Value = { Min = 15, Max = 60, Default = Config.AttackRadius },
    Callback = function(val)
        Config.AttackRadius = val
    end
})

TabCombat:Toggle({
    Title = "🛡️ Auto Perfect Parry / God Block (แพรี่สะท้อนดาเมจ)",
    Desc = "จับจังหวะศัตรูโจมตีและบล็อกแพรี่ (Parry Window) สะท้อนดาเมจและทำให้ศัตรูมึนงง (Stagger)",
    Value = Config.AutoParry,
    Callback = function(val)
        Config.AutoParry = val
    end
})

TabCombat:Toggle({
    Title = "💥 Auto Cast Equipped Ability (สแปมสกิลออโต้)",
    Desc = "ปล่อยสกิลประจำตัวทันทีเมื่อคูลดาวน์เสร็จไปยังศัตรูที่ใกล้ที่สุด",
    Value = Config.AutoAbility,
    Callback = function(val)
        Config.AutoAbility = val
    end
})

TabCombat:Toggle({
    Title = "🏃 Emergency Dash Away on Low HP (< 30%)",
    Desc = "แดชพุ่งหนีออกจากวงล้อมศัตรูทันทีเมื่อเลือดต่ำกว่า 30%",
    Value = Config.AutoDodgeLowHp,
    Callback = function(val)
        Config.AutoDodgeLowHp = val
    end
})

TabCombat:Divider()

TabCombat:Toggle({
    Title = "🌟 Auto Pick Roguelike Boons (เลือกการ์ดบัฟออโต้)",
    Desc = "เลือกการ์ดอัปเกรดความสามารถระหว่างผ่านรอบในอารีน่าให้อัตโนมัติ",
    Value = Config.AutoBoonPick,
    Callback = function(val)
        Config.AutoBoonPick = val
    end
})

TabCombat:Toggle({
    Title = "⏩ Instant Skip Boss Cutscenes (ข้ามคัตซีนบอสทันที)",
    Desc = "ตัดฉากเปิดตัวบอสและเข้าสู่การต่อสู้ทันที",
    Value = Config.AutoSkipCutscenes,
    Callback = function(val)
        Config.AutoSkipCutscenes = val
    end
})

-- ==============================================================================
-- 🏟️ TAB 3: ARENA MATCHMAKING
-- ==============================================================================
local TabArena = Window:Tab({ Title = "Arena Queue", Icon = "flame" })

TabArena:Paragraph({
    Title = "🏟️ Arena & Trials Queue Automation",
    Desc = "วนลูปเข้าประลองในอารีน่า Great Gate PVE ต่อเนื่อง ฟาร์ม Glory และเหรียญรางวัล",
    Image = "trophy"
})

TabArena:Toggle({
    Title = "🏟️ Auto Queue Arena PVE (เข้าอารีน่าวนลูป)",
    Desc = "เมื่ออยู่ในล็อบบี้ จะกดเข้าคิว Great Gate เข้าสู้ในอารีน่าให้อัตโนมัติ",
    Value = Config.AutoQueueArena,
    Callback = function(val)
        Config.AutoQueueArena = val
    end
})

TabArena:Button({
    Title = "⚔️ Enter Arena Now (เข้าอารีน่าทันที)",
    Desc = "ส่งคำสั่ง QueueJoin เข้า ArenaPVE ทันที",
    Icon = "play",
    Callback = function()
        pcall(function()
            local rep = game:GetService("ReplicatedStorage")
            rep.Remotes.QueueJoin:FireServer("ArenaPVE")
            WindUI:Notify({ Title = "Joined Queue", Content = "Queueing for ArenaPVE...", Duration = 3 })
        end)
    end
})

TabArena:Button({
    Title = "🚪 Leave Match / Return to Lobby (ออกห้องกลับล็อบบี้)",
    Desc = "ออกจากแมตช์ปัจจุบันเพื่อกลับมาที่ล็อบบี้",
    Icon = "log-out",
    Callback = function()
        pcall(function()
            local rep = game:GetService("ReplicatedStorage")
            rep.Remotes.LeaveMatch:FireServer()
            WindUI:Notify({ Title = "Left Match", Content = "Returning to lobby...", Duration = 3 })
        end)
    end
})

-- ==============================================================================
-- ⚡ TAB 4: MOVEMENT & PHYSICS
-- ==============================================================================
local TabMove = Window:Tab({ Title = "Movement", Icon = "zap" })

TabMove:Toggle({
    Title = "⚡ Speed Booster / Multiplier",
    Desc = "ปรับความเร็วในการเดินและวิ่งของตัวละคร",
    Value = Config.SpeedMultiplierEnabled,
    Callback = function(val)
        Config.SpeedMultiplierEnabled = val
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = val and Config.WalkSpeed or 16
            end
        end)
    end
})

TabMove:Slider({
    Title = "🏃 Custom WalkSpeed",
    Desc = "ระดับความเร็วในการเคลื่อนที่",
    Value = { Min = 16, Max = 120, Default = Config.WalkSpeed },
    Callback = function(val)
        Config.WalkSpeed = val
        if Config.SpeedMultiplierEnabled then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = val end
            end)
        end
    end
})

TabMove:Toggle({
    Title = "🚀 High Jump Booster",
    Desc = "กระโดดได้สูงขึ้นเพื่อหลบการโจมตีหรือข้ามกำแพง",
    Value = Config.JumpBooster,
    Callback = function(val)
        Config.JumpBooster = val
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.JumpHeight = val and Config.JumpHeight or 7.2
            end
        end)
    end
})

TabMove:Slider({
    Title = "🦘 Custom Jump Height",
    Desc = "ความสูงในการกระโดด",
    Value = { Min = 20, Max = 150, Default = Config.JumpHeight },
    Callback = function(val)
        Config.JumpHeight = val
        if Config.JumpBooster then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.JumpHeight = val end
            end)
        end
    end
})

TabMove:Toggle({
    Title = "👻 No-Clip (ทะลุกำแพงและสิ่งกีดขวาง)",
    Desc = "เดินทะลุสิ่งกีดขวาง ประตู และบาเรียร์ในแผนที่",
    Value = Config.NoClip,
    Callback = function(val)
        Config.NoClip = val
    end
})

-- ==============================================================================
-- 📍 TAB 5: LOBBY WARPS
-- ==============================================================================
local TabWarp = Window:Tab({ Title = "Lobby Warps", Icon = "map-pin" })

TabWarp:Paragraph({
    Title = "📍 Instant Lobby Shortcuts",
    Desc = "วาร์ปไปยังจุดสำคัญต่างๆ ในล็อบบี้ทันที ไม่ต้องเดินเอง",
    Image = "map"
})

for name, pos in pairs(LOBBY_WAYPOINTS) do
    TabWarp:Button({
        Title = name,
        Desc = "Teleport character to " .. name,
        Icon = "navigation",
        Callback = function()
            teleportPlayer(pos)
            WindUI:Notify({ Title = "Teleported!", Content = "Warped to " .. name, Duration = 2, Icon = "check-circle" })
        end
    })
end

-- ==============================================================================
-- 💎 TAB 6: PROGRESSION & UTILITY
-- ==============================================================================
local TabProg = Window:Tab({ Title = "Progression", Icon = "award" })

TabProg:Toggle({
    Title = "🔄 Auto Rebirth (จุติตัวละครอัตโนมัติ)",
    Desc = "กด Rebirth ทันทีที่เลเวลถึงเกณฑ์เพื่อรับ Skill Points และบูสต์โบนัส",
    Value = Config.AutoRebirth,
    Callback = function(val)
        Config.AutoRebirth = val
    end
})

TabProg:Button({
    Title = "🔄 Manual Rebirth Now",
    Desc = "ส่งคำสั่ง Rebirth ไปที่ Shrine of Mars ทันที",
    Icon = "rotate-cw",
    Callback = function()
        pcall(function()
            local rep = game:GetService("ReplicatedStorage")
            rep.Remotes.Rebirth:FireServer()
            WindUI:Notify({ Title = "Rebirth", Content = "Fired Rebirth signal.", Duration = 2 })
        end)
    end
})

TabProg:Toggle({
    Title = "🎁 Auto Claim Daily Rewards",
    Desc = "กดรับรางวัลล็อกอินรายวันให้อัตโนมัติ",
    Value = Config.AutoClaimDaily,
    Callback = function(val)
        Config.AutoClaimDaily = val
    end
})

-- ==============================================================================
-- 🛡️ TAB 7: SETTINGS
-- ==============================================================================
local TabSettings = Window:Tab({ Title = "Settings", Icon = "settings" })

TabSettings:Toggle({
    Title = "🛡️ Anti-AFK (กันหลุด 20 นาที)",
    Desc = "ป้องกัน Roblox ตัดการเชื่อมต่อขณะปล่อยบอทฟาร์ม",
    Value = Config.AntiAfk,
    Callback = function(val)
        Config.AntiAfk = val
    end
})

TabSettings:Keybind({
    Title = "🎛️ Toggle Hub Menu Hotkey",
    Desc = "กดปุ่มเพื่อย่อหรือเปิดหน้าต่างเมนูนี้",
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
-- 🛠️ HELPER FUNCTIONS
-- ==============================================================================
teleportPlayer = function(targetPos)
    pcall(function()
        local char = LocalPlayer.Character
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
        if root and targetPos then
            if typeof(targetPos) == "Vector3" then
                root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
            elseif typeof(targetPos) == "CFrame" then
                root.CFrame = targetPos + Vector3.new(0, 3, 0)
            end
        end
    end)
end

local function getClosestEnemy(maxDist)
    local activeEnemies = workspace:FindFirstChild("ActiveEnemies")
    if not activeEnemies then return nil end
    local char = LocalPlayer.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
    if not root then return nil end

    local closest, closestDist = nil, maxDist or 9999
    for _, e in ipairs(activeEnemies:GetChildren()) do
        local hum = e:FindFirstChildOfClass("Humanoid")
        local eRoot = e:FindFirstChild("HumanoidRootPart") or e.PrimaryPart
        if eRoot and (not hum or hum.Health > 0) then
            local d = (eRoot.Position - root.Position).Magnitude
            if d < closestDist then
                closestDist = d
                closest = eRoot
            end
        end
    end
    return closest, closestDist
end

-- ==============================================================================
-- 🚀 BACKGROUND THREADS & ENGINES
-- ==============================================================================

-- 1. GYM AUTO TRAINING LOOP
task.spawn(function()
    while isAlive() do
        task.wait(1 / math.max(1, Config.TrainSpeedRps))
        if Config.AutoTrain then
            pcall(function()
                local rep = game:GetService("ReplicatedStorage")
                local lp = LocalPlayer
                local char = lp.Character
                local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
                if not root then return end

                local trainingAttr = tostring(lp:GetAttribute("Training") or "")
                local targetBarbellName = Config.SelectedBarbell

                if trainingAttr == "" then
                    -- Walk / Warp to selected barbell and trigger prompt
                    local barbells = workspace:FindFirstChild("Lobby") and workspace.Lobby:FindFirstChild("Gym") and workspace.Lobby.Gym:FindFirstChild("Barbells")
                    local targetModel = barbells and barbells:FindFirstChild(targetBarbellName)
                    local prompt = targetModel and targetModel:FindFirstChildWhichIsA("ProximityPrompt", true)

                    if targetModel and prompt then
                        local bPos = BARBELL_COORDS[targetBarbellName] or prompt.Parent.Position
                        local d = (root.Position - bPos).Magnitude
                        if d > 12 then
                            root.CFrame = CFrame.new(bPos + Vector3.new(0, 1.5, 0))
                            task.wait(0.2)
                        end
                        if fireproximityprompt then
                            fireproximityprompt(prompt)
                        end
                    end
                else
                    -- Already training: Spam TrainRep
                    rep.Remotes.TrainRep:FireServer()
                end
            end)
        end
    end
end)

-- 2. MASTER COMBAT KILL AURA LOOP
task.spawn(function()
    local combo = 1
    while isAlive() do
        task.wait(0.12)
        if Config.KillAura then
            pcall(function()
                local rep = game:GetService("ReplicatedStorage")
                local char = LocalPlayer.Character
                local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
                if not root then return end

                local target, dist = getClosestEnemy(Config.AttackRadius)
                if target then
                    -- Attack target
                    rep.Remotes.Attack:FireServer(combo, target.Position, false)
                    task.wait(0.04)
                    rep.Remotes.AttackRelease:FireServer(combo, 1, target.Position)
                    combo = (combo % 3) + 1

                    -- Cast Ability if enabled
                    if Config.AutoAbility then
                        rep.Remotes.AbilityCast:FireServer(target.Position)
                    end
                end
            end)
        end
    end
end)

-- 3. GOD BLOCK / AUTO PARRY LOOP
task.spawn(function()
    while isAlive() do
        task.wait(0.08)
        if Config.AutoParry then
            pcall(function()
                local rep = game:GetService("ReplicatedStorage")
                local char = LocalPlayer.Character
                local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
                if not root then return end

                local target, dist = getClosestEnemy(16)
                if target and dist < 14 then
                    -- Tap block in parry window
                    rep.Remotes.Block:FireServer(true, 0)
                    task.wait(0.18)
                    rep.Remotes.Block:FireServer(false, 0.18)
                end
            end)
        end
    end
end)

-- 4. EMERGENCY DODGE ON LOW HP
task.spawn(function()
    while isAlive() do
        task.wait(0.5)
        if Config.AutoDodgeLowHp then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
                if hum and root and hum.MaxHealth > 0 then
                    local hpPct = (hum.Health / hum.MaxHealth) * 100
                    if hpPct <= Config.DodgeHpThreshold then
                        local rep = game:GetService("ReplicatedStorage")
                        local target = getClosestEnemy(25)
                        local escapeDir = target and (root.Position - target.Position).Unit or (-root.CFrame.LookVector)
                        rep.Remotes.Dash:FireServer(escapeDir)
                        task.wait(1.5)
                    end
                end
            end)
        end
    end
end)

-- 5. AUTO SKIP BOSS CUTSCENES & BOON PICKER
task.spawn(function()
    while isAlive() do
        task.wait(0.6)
        pcall(function()
            local rep = game:GetService("ReplicatedStorage")
            if Config.AutoSkipCutscenes then
                rep.Remotes.BossCutsceneSkip:FireServer(1)
            end

            -- Auto Boon Pick
            if Config.AutoBoonPick then
                local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
                local panels = pg and pg:FindFirstChild("Panels")
                if panels then
                    for _, d in ipairs(panels:GetDescendants()) do
                        if d:IsA("GuiButton") and d.Visible and d.Name:lower():find("boon") then
                            if firesignal then
                                firesignal(d.Activated)
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- 6. ARENA AUTO QUEUE LOOP
task.spawn(function()
    while isAlive() do
        task.wait(2)
        if Config.AutoQueueArena then
            pcall(function()
                local zone = tostring(LocalPlayer:GetAttribute("Zone") or "")
                local inArena = LocalPlayer:GetAttribute("InArena")
                if zone == "Lobby" and not inArena then
                    local rep = game:GetService("ReplicatedStorage")
                    rep.Remotes.QueueJoin:FireServer("ArenaPVE")
                end
            end)
        end
    end
end)

-- 7. AUTO REBIRTH & DAILY REWARDS
task.spawn(function()
    while isAlive() do
        task.wait(5)
        pcall(function()
            local rep = game:GetService("ReplicatedStorage")
            if Config.AutoClaimDaily then
                rep.Remotes.DailyAction:FireServer("Claim")
            end
            if Config.AutoRebirth then
                local lvl = tonumber(LocalPlayer:GetAttribute("Level")) or 0
                if lvl >= 50 then
                    rep.Remotes.Rebirth:FireServer()
                end
            end
        end)
    end
end)

-- 8. MOVEMENT & NOCLIP ENGINE
RunService.Stepped:Connect(function()
    if Config.NoClip then
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end)

-- 9. ANTI-AFK ENGINE
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

-- Final Welcome Notification
local playerName = (LocalPlayer and LocalPlayer.Name) or "Gladiator"
pcall(function()
    WindUI:Notify({
        Title = "GloryBound Hub Loaded! ⚔️",
        Content = "Welcome " .. playerName .. "!\nGladiator Automation Hub ready.",
        Duration = 4,
        Icon = "sparkles"
    })
end)

print("[GloryBound Hub] ✨ Successfully loaded [TRIALS] GloryBound Automation Hub!")
