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

-- ==============================================================================
-- 🛡️ STRICT SINGLETON & MULTI-EXECUTE PREVENTION
-- ==============================================================================
local now = os.clock()
if getgenv then
    -- 1. If script is already running with an active UI, block duplicate launch!
    if getgenv()._GloryBoundRunning == true and getgenv()._GB_Window and (now - (getgenv()._GB_LastStartTime or 0)) < 6 then
        print("[GloryBound Hub] 🛡️ Script is already running with active UI. Skipping duplicate launch.")
        return
    end

    getgenv()._GB_LastStartTime = now
    getgenv()._GloryBoundRunning = true
    getgenv()._GloryBoundRunId = (tonumber(getgenv()._GloryBoundRunId) or 0) + 1

    -- 2. Destroy any existing UI instances to prevent overlapping windows
    pcall(function()
        if getgenv()._GB_Window and getgenv()._GB_Window.Destroy then
            getgenv()._GB_Window:Destroy()
        end
    end)
    pcall(function()
        local roots = {
            (typeof(gethui) == "function" and gethui()) or nil,
            game:GetService("CoreGui")
        }
        for _, root in ipairs(roots) do
            if root then
                for _, child in ipairs(root:GetChildren()) do
                    if child.Name == "WindUI" or child.Name == "GloryBoundHub" or child.Name == "SongHub" or child.Name:find("WindUI") then
                        pcall(function()
                            if child:FindFirstChild("Window") then
                                child.Window:ClearAllChildren()
                            end
                            child:Destroy()
                        end)
                    end
                end
            end
        end
    end)
end

local currentScriptRunId = (getgenv and getgenv()._GloryBoundRunId) or 1
local function isAlive()
    if getgenv and getgenv()._GloryBoundRunId and getgenv()._GloryBoundRunId > currentScriptRunId then
        return false
    end
    return true
end

-- ==============================================================================
-- ⚙️ CONFIGURATION & STATE
-- ==============================================================================
local Config = {
    -- Gym & Training
    AutoTrain = false,
    SelectedBarbell = "B6", -- "B1", "B2", "B3", "B4", "B5", "B6"
    TrainSpeedRps = 2.5,
    AutoRestOnHighFatigue = false,

    -- Full Auto & Combat System
    FullAutoArena = false,

    -- Combat & Target Lock
    KillAura = false,
    AttackRadius = 300,
    TargetLock = false,
    LockMode = "Behind", -- "Behind", "Above", "Face", "Front"
    LockDistance = 3.5,
    AutoParry = false,
    AutoDodge = false,
    DodgeInterval = 1.8,
    AutoDodgeLowHp = true,
    DodgeHpThreshold = 35,
    AutoAbility = true,
    AutoBoonPick = true,
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
    AutoRebirth = true,
    AutoClaimDaily = true,

    -- Safety
    AntiAfk = true,

    -- Auto Execute & Persistence
    AutoExecuteOnTeleport = true,
    AutoSave = true
}

-- ==============================================================================
-- 💾 CONFIG PERSISTENCE & AUTO-EXECUTE ENGINE
-- ==============================================================================
local CONFIG_FILE = "GloryBound_Config.json"

local function SaveConfig(silent)
    pcall(function()
        if writefile then
            local payload = game:GetService("HttpService"):JSONEncode(Config)
            writefile(CONFIG_FILE, payload)
            if not silent and WindUI and WindUI.Notify then
                WindUI:Notify({ Title = "Saved!", Content = "บันทึกการตั้งค่าเรียบร้อยแล้ว", Duration = 2, Icon = "save" })
            end
        end
    end)
end

local function LoadConfig(silent)
    local success = false
    pcall(function()
        if isfile and isfile(CONFIG_FILE) and readfile then
            local raw = readfile(CONFIG_FILE)
            local decoded = game:GetService("HttpService"):JSONDecode(raw)
            if type(decoded) == "table" then
                for k, v in pairs(decoded) do
                    Config[k] = v
                end
                success = true
                if not silent and WindUI and WindUI.Notify then
                    WindUI:Notify({ Title = "Config Loaded", Content = "โหลดการตั้งค่าอัตโนมัติสำเร็จแล้ว!", Duration = 2, Icon = "folder-check" })
                end
            end
        end
    end)
    return success
end

-- Auto load saved config on startup
LoadConfig(true)

-- ==================== AUTO EXECUTE ON TELEPORT ====================
local hasRegisteredQueue = false
local function registerQueueOnTeleport()
    if not Config.AutoExecuteOnTeleport then return end
    if hasRegisteredQueue then return end
    local queue = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if queue then
        hasRegisteredQueue = true
        local cb = tostring(os.time()) .. "_" .. tostring(math.random(100, 999))
        local execCode = [[
            task.wait(2.0)
            if getgenv and (getgenv()._GloryBoundRunning or getgenv()._UniversalLoaderLoading) then
                return
            end
            local cb = "]] .. cb .. [["
            local sOk, code = pcall(function()
                return game:HttpGet("https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/loader.luau?v=" .. cb)
            end)
            if not sOk or not code or #code < 500 then
                sOk, code = pcall(function()
                    return game:HttpGet("https://song-hub-avp8.onrender.com/loader.luau?v=" .. cb)
                end)
            end
            if sOk and code and #code > 500 then
                local fn = loadstring(code)
                if fn then return fn() end
            end
        ]]
        pcall(queue, execCode)
    end
end

pcall(registerQueueOnTeleport)

if LocalPlayer.OnTeleport then
    LocalPlayer.OnTeleport:Connect(function(state)
        pcall(registerQueueOnTeleport)
    end)
end

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
if getgenv then getgenv()._GB_Window = Window end

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
        if Config.AutoSave then SaveConfig(true) end
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

TabGym:Toggle({
    Title = "🔄 Auto Rebirth on Max Strength (จุติทันทีเมื่อสเตตัสเต็ม)",
    Desc = "เมื่อ Strength เต็มขีดจำกัด (เช่น 50/50, 70/70) บอทจะวาร์ปไปจุติที่ Shrine of Mars อัตโนมัติแล้วกลับมายกต่อทันที",
    Value = Config.AutoRebirth,
    Callback = function(val)
        Config.AutoRebirth = val
    end
})

TabGym:Dropdown({
    Title = "🏋️ Select Barbell Station (เลือกแท่นบาร์เบล)",
    Desc = "เลือกแท่นบาร์เบลที่ต้องการใช้งานในห้องยิม",
    Values = { "B1", "B2", "B3", "B4", "B5", "B6" },
    Value = Config.SelectedBarbell,
    Callback = function(val)
        Config.SelectedBarbell = val
        if Config.AutoSave then SaveConfig(true) end
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
    Title = "⚔️ Full Auto Arena Combat Engine",
    Desc = "ระบบต่อสู้และฟาร์มอารีน่าแบบอัตโนมัติครบวงจร (100% Hands-Free AFK): ล็อคเป้าเกาะหลังมอน + ฟันคอมโบ + สแปมสกิล + แดชหลบหลีก + แพรี่สะท้อน + เลือกการ์ดอัปเกรดอัตโนมัติ",
    Image = "swords"
})

TabCombat:Toggle({
    Title = "⭐ Full Auto Arena God Mode (ฟาร์มอารีน่าอัตโนมัติ 100%)",
    Desc = "เปิดระบบออโต้ครบวงจร: ล็อคเป้าเกาะหลังมอน + ฟันคอมโบ + สแปมสกิล + แดชหลบ + แพรี่ + เลือกการ์ดอัปเกรด + วนลูปจบครบในตัว",
    Value = Config.FullAutoArena,
    Callback = function(val)
        Config.FullAutoArena = val
        if val then
            Config.TargetLock = true
            Config.KillAura = true
            Config.AutoDodge = true
            Config.AutoDodgeLowHp = true
            Config.AutoParry = true
            Config.AutoAbility = true
            Config.AutoBoonPick = true
            Config.AutoSkipCutscenes = true
            Config.AutoQueueArena = true
            WindUI:Notify({ Title = "Full Auto Arena Active! ⚔️", Content = "God Mode Auto Farm running 100% AFK!", Duration = 3, Icon = "flame" })
        else
            Config.TargetLock = false
            Config.KillAura = false
            Config.AutoDodge = false
            Config.AutoQueueArena = false
            WindUI:Notify({ Title = "Full Auto Paused", Content = "Stopped auto combat loop.", Duration = 2, Icon = "pause" })
        end
    end
})

TabCombat:Divider()

TabCombat:Toggle({
    Title = "🎯 Master Target Lock (ล็อคเกาะติดมอนสเตอร์ + โจมตี)",
    Desc = "วาร์ปเกาะติดหลังมอนสเตอร์และโจมตีอัตโนมัติ ช่วยให้โจมตีโดน 100% ไม่พลาดเป้า",
    Value = Config.TargetLock,
    Callback = function(val)
        Config.TargetLock = val
        if val then
            Config.KillAura = true
            Config.AutoAbility = true
        end
        if Config.AutoSave then SaveConfig(true) end
    end
})

TabCombat:Dropdown({
    Title = "🎯 Lock Position Mode (ตำแหน่งล็อคเกาะมอน)",
    Desc = "เลือกมุมที่ต้องการให้ตัวละครล็อคติดตัวมอนสเตอร์ (แนะนำ: เกาะหลังมอน ไม่โดนมอนฟัน)",
    Values = { "Behind (เกาะหลัง - แนะนำ)", "Above (ลอยเหนือหัว)", "Face Target (หันหน้าเข้าหา)", "Front (ประชิดหน้า)" },
    Value = "Behind (เกาะหลัง - แนะนำ)",
    Callback = function(val)
        if val:find("Behind") then
            Config.LockMode = "Behind"
        elseif val:find("Above") then
            Config.LockMode = "Above"
        elseif val:find("Face") then
            Config.LockMode = "Face"
        elseif val:find("Front") then
            Config.LockMode = "Front"
        end
    end
})

TabCombat:Slider({
    Title = "📏 Lock Distance (ระยะห่างล็อค Studs)",
    Desc = "ระยะห่างระหว่างตัวละครกับมอนสเตอร์",
    Value = { Min = 2, Max = 15, Default = Config.LockDistance },
    Callback = function(val)
        Config.LockDistance = val
    end
})

TabCombat:Divider()

TabCombat:Toggle({
    Title = "⚔️ Master Kill Aura (ออโต้โจมตีคอมโบ + ยิงธนู)",
    Desc = "โจมตีมอนสเตอร์และศัตรูทั้งหมดในระยะโดยไม่ต้องคลิกเอง (รองรับทั้งดาบและธนู)",
    Value = Config.KillAura,
    Callback = function(val)
        Config.KillAura = val
        if val then
            Config.TargetLock = true
            Config.AutoAbility = true
        end
        if Config.AutoSave then SaveConfig(true) end
    end
})

TabCombat:Slider({
    Title = "📡 Combat & Search Radius (ระยะตรวจจับ Studs)",
    Desc = "ระยะในการค้นหาและล็อคเป้าศัตรู",
    Value = { Min = 15, Max = 150, Default = Config.AttackRadius },
    Callback = function(val)
        Config.AttackRadius = val
    end
})

TabCombat:Toggle({
    Title = "💨 Auto Combat Dodge (แดชหลบหลีกการโจมตี)",
    Desc = "พุ่งแดชหลบหลีกด้านข้าง/หลังมอนสเตอร์ระหว่างต่อสู้ เพื่อหลบวงฟันของมอนสเตอร์",
    Value = Config.AutoDodge,
    Callback = function(val)
        Config.AutoDodge = val
    end
})

TabCombat:Slider({
    Title = "⏱️ Dodge Interval (ความถี่ในการแดชหลบ วินาที)",
    Desc = "ระยะเวลาระหว่างการแดชหลบแต่ละครั้ง",
    Value = { Min = 1, Max = 4, Default = Config.DodgeInterval },
    Callback = function(val)
        Config.DodgeInterval = val
    end
})

TabCombat:Toggle({
    Title = "🏃 Emergency Dodge on Low HP (แดชหนีเมื่อเลือดต่ำ)",
    Desc = "แดชพุ่งหนีออกจากวงล้อมศัตรูทันทีเมื่อเลือดต่ำกว่า 35%",
    Value = Config.AutoDodgeLowHp,
    Callback = function(val)
        Config.AutoDodgeLowHp = val
    end
})

TabCombat:Toggle({
    Title = "🛡️ Auto Perfect Parry / God Block (แพรี่สะท้อนดาเมจ)",
    Desc = "จับจังหวะศัตรูโจมตีและบล็อคแพรี่ (Parry Window) สะท้อนดาเมจและทำให้ศัตรูมึนงง (Stagger)",
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

TabCombat:Divider()

TabCombat:Toggle({
    Title = "🎴 Auto Pick Boons & Upgrades (เลือกการ์ดอัปเกรดออโต้)",
    Desc = "เลือกการ์ดอัปเกรดระหว่างผ่านรอบในอารีน่าให้อัตโนมัติ (เลือกการ์ดหายากสุด Legendary > Epic > Rare > Damage)",
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
    Desc = "จุติที่ Shrine of Mars ทันทีที่ Strength เต็มขีดจำกัด (เช่น 50/50, 70/70) แล้วกลับมายกบาร์เบลต่ออัตโนมัติ",
    Value = Config.AutoRebirth,
    Callback = function(val)
        Config.AutoRebirth = val
    end
})

TabProg:Button({
    Title = "🔄 Manual Rebirth Now (กดจุติทันที)",
    Desc = "วาร์ปไป Shrine of Mars และทำการ Rebirth ทันทีในคลิกเดียว",
    Icon = "rotate-cw",
    Callback = function()
        task.spawn(performRebirth)
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

TabSettings:Paragraph({
    Title = "⚡ Auto Execute & Teleport Queue",
    Desc = "ระบบรันสคริปต์อัตโนมัติเมื่อเปลี่ยนห้อง/วาร์ปข้ามเซิร์ฟเวอร์ และบันทึกการตั้งค่าถาวร",
    Image = "zap"
})

TabSettings:Toggle({
    Title = "⚡ Auto Execute on Teleport / Warp",
    Desc = "รัน Song Hub อัตโนมัติทันทีเมื่อเปลี่ยนเซิร์ฟเวอร์หรือวาร์ปเข้าแมตช์",
    Value = Config.AutoExecuteOnTeleport,
    Callback = function(val)
        Config.AutoExecuteOnTeleport = val
        registerQueueOnTeleport()
        if Config.AutoSave then SaveConfig(true) end
    end
})

TabSettings:Toggle({
    Title = "💾 Auto Save Settings",
    Desc = "บันทึกการตั้งค่าทั้งหมดอัตโนมัติเมื่อมีการเปลี่ยนแปลง",
    Value = Config.AutoSave,
    Callback = function(val)
        Config.AutoSave = val
        SaveConfig(true)
    end
})

TabSettings:Button({
    Title = "💾 Save Settings Now (บันทึกการตั้งค่าเดี๋ยวนี้)",
    Desc = "บันทึกการตั้งค่าปัจจุบันลงใน GloryBound_Config.json",
    Icon = "save",
    Callback = function()
        SaveConfig(false)
    end
})

TabSettings:Button({
    Title = "📂 Load Settings Now (โหลดการตั้งค่า)",
    Desc = "โหลดการตั้งค่าล่าสุดจากไฟล์เซฟ",
    Icon = "folder-check",
    Callback = function()
        LoadConfig(false)
    end
})

TabSettings:Button({
    Title = "💾 Install Auto-Execute (ติดตั้งลงโฟลเดอร์ autoexec)",
    Desc = "สร้างไฟล์ SongHub.luau ในโฟลเดอร์ autoexec ของตัวรัน (Wave/Solara/Swift/Delta/etc.)",
    Icon = "download",
    Callback = function()
        local code = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/loader.luau"))()'
        local success = false
        pcall(function()
            if writefile then
                if makefolder then pcall(makefolder, "autoexec") end
                writefile("autoexec/SongHub.luau", code)
                writefile("autoexec/SongHub.lua", code)
                writefile("autoexec/SongHub_GloryBound.luau", code)
                success = true
            end
        end)
        if setclipboard then pcall(setclipboard, code) end
        if success then
            WindUI:Notify({ 
                Title = "Auto-Execute Installed! ⚡", 
                Content = "ติดตั้งไฟล์ลง autoexec เรียบร้อย และคัดลอกโค้ดไว้ในคลิปบอร์ดแล้ว!", 
                Duration = 4, 
                Icon = "check" 
            })
        else
            WindUI:Notify({ 
                Title = "Copied to Clipboard 📋", 
                Content = "คัดลอกคำสั่งเรียบร้อยแล้ว นำไปวางในโฟลเดอร์ autoexec ของตัวรันได้เลย", 
                Duration = 4, 
                Icon = "clipboard" 
            })
        end
    end
})

TabSettings:Button({
    Title = "📋 Copy Loader Script (คัดลอกโค้ดสำหรับใส่ autoexec)",
    Desc = "คัดลอกคำสั่ง loadstring เพื่อนำไปใส่ในโฟลเดอร์ autoexec ด้วยตนเอง",
    Icon = "clipboard",
    Callback = function()
        local code = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/loader.luau"))()'
        if setclipboard then
            setclipboard(code)
            WindUI:Notify({ Title = "Copied! 📋", Content = "คัดลอกโค้ดสำหรับ autoexec เรียบร้อยแล้ว", Duration = 3, Icon = "check" })
        end
    end
})

TabSettings:Toggle({
    Title = "🛡️ Anti-AFK (กันหลุด 20 นาที)",
    Desc = "ป้องกัน Roblox ตัดการเชื่อมต่อขณะปล่อยบอทฟาร์ม",
    Value = Config.AntiAfk,
    Callback = function(val)
        Config.AntiAfk = val
        if Config.AutoSave then SaveConfig(true) end
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

    local closest, closestDist = nil, maxDist or 300
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

-- ==============================================================================
-- 🔄 AUTO REBIRTH SYSTEM & HELPERS (STRICT CONDITION GATED)
-- ==============================================================================
local isRebirthing = false
local lastRebirthTime = 0

local function checkRebirthReady()
    local ready = false
    
    -- Primary Check: ClientState (Game's official internal values)
    pcall(function()
        local cs = require(LocalPlayer.PlayerScripts.Controllers.ClientState)
        local state = cs and cs.get and cs.get()
        if state then
            local str = tonumber(state.Strength) or 0
            local cap = tonumber(state.StrengthCap) or 999999
            -- Rebirth is ONLY ready when Strength has reached or exceeded Cap!
            if str >= cap and cap > 0 then
                ready = true
            end
        end
    end)
    if ready then return true end

    -- Secondary Check: Training HUD Push Button (Only when actively working out)
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local tr = pg and pg:FindFirstChild("Training")
        if tr and tr.Enabled then
            local root = tr:FindFirstChild("Root", true)
            if root and root.Visible then
                local push = tr:FindFirstChild("Push", true)
                local lbl = push and push:FindFirstChild("Label", true)
                -- When capped, the game's TrainingController changes button text to 'Rebirth'
                if lbl and lbl.Visible and lbl.Text and lbl.Text:lower() == "rebirth" then
                    ready = true
                end
            end
        end
    end)

    return ready
end

local function performRebirth()
    if isRebirthing then return end
    if tick() - lastRebirthTime < 6 then return end -- Strict 6-second cooldown guard
    if not checkRebirthReady() then return end -- Guard: Never trigger if strength is not ready!

    isRebirthing = true
    lastRebirthTime = tick()

    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local lp = LocalPlayer
        local char = lp.Character
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
        local shrine = workspace:FindFirstChild("Lobby") and workspace.Lobby:FindFirstChild("Stations") and workspace.Lobby.Stations:FindFirstChild("RebirthShrine")
        local shrinePart = shrine and shrine:FindFirstChild("PromptPart")
        
        if not shrinePart or not root then
            isRebirthing = false
            return
        end

        WindUI:Notify({ 
            Title = "Auto Rebirth 🔄", 
            Content = "Strength Max reached! Warping to Shrine of Mars...", 
            Duration = 3, 
            Icon = "refresh-cw" 
        })

        -- 1. Disengage from barbell
        rep.Remotes.TrainStop:FireServer()
        task.wait(0.3)

        -- 2. Teleport & pin at shrine
        local currentRebirth = tonumber(lp:GetAttribute("Rebirth")) or 0
        local startTime = tick()

        while isAlive() and (tick() - startTime < 3.5) do
            root.CFrame = shrinePart.CFrame + Vector3.new(0, 1.2, 0)
            root.AssemblyLinearVelocity = Vector3.zero

            -- Open prompt if present
            if fireproximityprompt and shrinePart:FindFirstChild("OpenPrompt") and shrinePart.OpenPrompt.Enabled then
                fireproximityprompt(shrinePart.OpenPrompt)
            end

            -- Fire rebirth remote
            rep.Remotes.Rebirth:FireServer()

            -- Check if rebirth registered
            local newRebirth = tonumber(lp:GetAttribute("Rebirth")) or 0
            if newRebirth > currentRebirth then
                break
            end

            task.wait(0.2)
        end

        task.wait(0.4)

        local finalRebirth = tonumber(lp:GetAttribute("Rebirth")) or 0
        if finalRebirth > currentRebirth then
            WindUI:Notify({ 
                Title = "Rebirth Successful! 🎉", 
                Content = string.format("Ascended to Rebirth %d! Resuming workout...", finalRebirth), 
                Duration = 3, 
                Icon = "award" 
            })
        end
    end)

    isRebirthing = false
end

-- 1. GYM AUTO TRAINING LOOP
task.spawn(function()
    while isAlive() do
        task.wait(1 / math.max(1, Config.TrainSpeedRps))
        if Config.AutoTrain and not isRebirthing then
            pcall(function()
                -- Check if rebirth ready first!
                if Config.AutoRebirth and checkRebirthReady() then
                    performRebirth()
                    return
                end

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

-- 1.4. AUTO BOON & UPGRADE PICKER HELPER
local function autoPickBoon()
    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    local bc = pg and pg:FindFirstChild("BoonChoice")
    if not bc or not bc.Enabled then return end

    local cardButtons = {}
    for _, desc in ipairs(bc:GetDescendants()) do
        if desc:IsA("TextButton") and desc.Name:match("^Card%d") then
            table.insert(cardButtons, desc)
        end
    end

    if #cardButtons == 0 then
        for _, desc in ipairs(bc:GetDescendants()) do
            if (desc:IsA("TextButton") or desc:IsA("ImageButton")) and desc.Visible and desc.Name:lower():find("card") then
                table.insert(cardButtons, desc)
            end
        end
    end

    if #cardButtons > 0 then
        local chosenBtn = cardButtons[2] or cardButtons[1]
        local highestScore = -1

        for _, btn in ipairs(cardButtons) do
            local score = 10
            local slot = btn.Parent
            if slot then
                for _, lbl in ipairs(slot:GetDescendants()) do
                    if lbl:IsA("TextLabel") and lbl.Text then
                        local t = lbl.Text:lower()
                        if t:find("legendary") or t:find("mythic") then
                            score = math.max(score, 100)
                        elseif t:find("epic") then
                            score = math.max(score, 60)
                        elseif t:find("rare") or t:find("lupa") or t:find("heal") then
                            score = math.max(score, 40)
                        elseif t:find("fury") or t:find("damage") or t:find("mars") then
                            score = math.max(score, 25)
                        end
                    end
                end
            end
            if score > highestScore then
                highestScore = score
                chosenBtn = btn
            end
        end

        pcall(function()
            if firesignal then
                firesignal(chosenBtn.Activated)
                firesignal(chosenBtn.MouseButton1Click)
                firesignal(chosenBtn.MouseButton1Down)
                firesignal(chosenBtn.MouseButton1Up)
            end
        end)

        pcall(function()
            local rep = game:GetService("ReplicatedStorage")
            local boonRemote = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("BoonPick")
            if boonRemote then
                local slot = chosenBtn.Parent
                if slot then
                    for _, lbl in ipairs(slot:GetDescendants()) do
                        if lbl:IsA("TextLabel") and lbl.Text and #lbl.Text > 3 then
                            local raw = lbl.Text:lower():gsub("%s+", "_"):gsub("[^%w_]", "")
                            if raw:find("mars") or raw:find("lupa") or raw:find("mercury")
                                or raw:find("fury") or raw:find("edge") or raw:find("brand") then
                                boonRemote:FireServer(raw)
                            end
                        end
                    end
                end
            end
        end)
    end
end

-- 1.5. MASTER TARGET LOCK & SNAP CONTROLLER
task.spawn(function()
    while isAlive() do
        task.wait(0.03)
        if Config.TargetLock or Config.FullAutoArena then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
                if not root then return end

                local target, dist = getClosestEnemy(Config.AttackRadius)
                if target and target.Parent then
                    local hum = target.Parent:FindFirstChildOfClass("Humanoid")
                    if not hum or hum.Health > 0 then
                        local lockDist = Config.LockDistance or 3.5
                        local targetPos = target.Position
                        local targetLook = target.CFrame.LookVector
                        local newCFrame = nil

                        if Config.LockMode == "Behind" then
                            local behindPos = targetPos - (targetLook * lockDist)
                            newCFrame = CFrame.lookAt(behindPos, targetPos)
                        elseif Config.LockMode == "Above" then
                            local abovePos = targetPos + Vector3.new(0, math.max(4.5, lockDist), 0)
                            newCFrame = CFrame.lookAt(abovePos, targetPos)
                        elseif Config.LockMode == "Front" then
                            local frontPos = targetPos + (targetLook * lockDist)
                            newCFrame = CFrame.lookAt(frontPos, targetPos)
                        else -- "Face"
                            newCFrame = CFrame.lookAt(root.Position, Vector3.new(targetPos.X, root.Position.Y, targetPos.Z))
                        end

                        if newCFrame then
                            root.CFrame = newCFrame
                            root.AssemblyLinearVelocity = Vector3.zero
                            root.AssemblyAngularVelocity = Vector3.zero
                        end
                    end
                end
            end)
        end
    end
end)

-- 2. MASTER COMBAT KILL AURA LOOP (MELEE + BOW COMPATIBLE)
task.spawn(function()
    local combo = 1
    while isAlive() do
        task.wait(0.12)
        if Config.KillAura or Config.FullAutoArena then
            pcall(function()
                local rep = game:GetService("ReplicatedStorage")
                local char = LocalPlayer.Character
                local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
                if not root then return end

                local target, dist = getClosestEnemy(Config.AttackRadius or 300)
                if target and target.Parent then
                    local hum = target.Parent:FindFirstChildOfClass("Humanoid")
                    if not hum or hum.Health > 0 then
                        -- Aim camera at target
                        pcall(function()
                            if workspace.CurrentCamera then
                                workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, target.Position)
                            end
                        end)

                        -- Face enemy if target lock is not actively positioning
                        if not Config.TargetLock then
                            pcall(function()
                                root.CFrame = CFrame.lookAt(root.Position, Vector3.new(target.Position.X, root.Position.Y, target.Position.Z))
                            end)
                        end

                        -- Attack Method 1: RemoteEvent Attack + Release
                        rep.Remotes.Attack:FireServer(combo, target.Position, false)
                        task.wait(0.04)
                        rep.Remotes.AttackRelease:FireServer(combo, 1, target.Position)
                        combo = (combo % 3) + 1

                        -- Attack Method 2: Virtual Click (Fires Bow drawing/release & standard attacks)
                        pcall(function()
                            VirtualUser:Button1Down(Vector2.zero, workspace.CurrentCamera.CFrame)
                            task.wait(0.05)
                            VirtualUser:Button1Up(Vector2.zero, workspace.CurrentCamera.CFrame)
                        end)

                        -- Cast Ability if enabled
                        if Config.AutoAbility then
                            rep.Remotes.AbilityCast:FireServer(target.Position)
                        end
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

-- 4. ADVANCED AUTO DODGE & TACTICAL FLANK CONTROLLER
local lastCombatDodge = 0
task.spawn(function()
    while isAlive() do
        task.wait(0.1)
        if Config.AutoDodge or Config.AutoDodgeLowHp then
            pcall(function()
                local rep = game:GetService("ReplicatedStorage")
                local dashRemote = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("Dash")
                if not dashRemote then return end

                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
                if not hum or not root or hum.Health <= 0 then return end

                local now = tick()
                local hpPct = (hum.Health / math.max(1, hum.MaxHealth)) * 100

                -- A. Emergency Low HP Retreat Dash
                if Config.AutoDodgeLowHp and hpPct <= Config.DodgeHpThreshold then
                    if now - lastCombatDodge > 1.2 then
                        lastCombatDodge = now
                        local target = getClosestEnemy(30)
                        local escapeDir = target and (root.Position - target.Position).Unit or (-root.CFrame.LookVector)
                        dashRemote:FireServer(escapeDir)
                        return
                    end
                end

                -- B. Tactical Combat Dodge (Sideways / Flank to dodge forward cleave)
                if Config.AutoDodge then
                    local target, dist = getClosestEnemy(16)
                    if target and dist and dist < 14 then
                        if now - lastCombatDodge > (Config.DodgeInterval or 1.8) then
                            lastCombatDodge = now
                            local flankDir = (math.random() > 0.5 and target.CFrame.RightVector or -target.CFrame.RightVector).Unit
                            dashRemote:FireServer(flankDir)
                        end
                    end
                end
            end)
        end
    end
end)

-- 5. AUTO SKIP BOSS CUTSCENES & BOON PICKER LOOP
task.spawn(function()
    while isAlive() do
        task.wait(0.4)
        pcall(function()
            local rep = game:GetService("ReplicatedStorage")
            if Config.AutoSkipCutscenes and rep.Remotes:FindFirstChild("BossCutsceneSkip") then
                rep.Remotes.BossCutsceneSkip:FireServer(1)
            end

            if Config.AutoBoonPick or Config.FullAutoArena then
                autoPickBoon()
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
        task.wait(2)
        pcall(function()
            local rep = game:GetService("ReplicatedStorage")
            if Config.AutoClaimDaily then
                rep.Remotes.DailyAction:FireServer("Claim")
            end
            if Config.AutoRebirth and not isRebirthing and checkRebirthReady() then
                performRebirth()
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


-- Auto-install to autoexec folder if supported by executor
pcall(function()
    if writefile and readfile then
        local installed = pcall(readfile, "autoexec/SongHub.luau")
        if not installed then
            if makefolder then pcall(makefolder, "autoexec") end
            local code = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/loader.luau"))()'
            writefile("autoexec/SongHub.luau", code)
        end
    end
end)
