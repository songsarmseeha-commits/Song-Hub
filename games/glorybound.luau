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
    -- 1. Strict Singleton: If script is already running with an active window, NEVER stack duplicate windows
    if getgenv()._GloryBoundRunning and getgenv()._GB_Window and not getgenv()._GB_ForceReload then
        print("[GloryBound Hub] 🛡️ GloryBound Hub is already running with active UI. Skipping duplicate launch.")
        return
    end

    getgenv()._GB_ForceReload = nil
    getgenv()._GB_LastStartTime = now
    getgenv()._GloryBoundRunning = true
    getgenv()._GloryBoundRunId = (tonumber(getgenv()._GloryBoundRunId) or 0) + 1
end

-- 2. Destroy any existing UI instances (including CoreGui.RobloxGui.WindUI) to prevent overlapping windows
local function cleanAllWindUI()
    pcall(function()
        if getgenv and getgenv()._GB_Window and getgenv()._GB_Window.Destroy then
            pcall(function() getgenv()._GB_Window:Destroy() end)
            getgenv()._GB_Window = nil
        end
    end)
    pcall(function()
        local searchRoots = {}
        if typeof(gethui) == "function" then
            local h = gethui()
            if h then table.insert(searchRoots, h) end
        end
        local cg = game:GetService("CoreGui")
        table.insert(searchRoots, cg)
        if cg:FindFirstChild("RobloxGui") then
            table.insert(searchRoots, cg.RobloxGui)
        end
        if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
            table.insert(searchRoots, LocalPlayer.PlayerGui)
        end

        for _, root in ipairs(searchRoots) do
            for _, child in ipairs(root:GetChildren()) do
                local cName = child.Name
                if cName:find("WindUI") or cName:find("GloryBound") or cName:find("SongHub") then
                    pcall(function()
                        if child:FindFirstChild("Window") then
                            for _, w in ipairs(child.Window:GetChildren()) do
                                pcall(function() w:Destroy() end)
                            end
                        end
                        child:Destroy()
                    end)
                end
            end
        end
    end)
end

cleanAllWindUI()

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
    MasterFullAuto = false,
    FullAutoArena = false,

    -- Combat & Target Lock
    KillAura = false,
    AttackRadius = 350,
    TargetLock = false,
    LockMode = "Behind", -- "Behind (เกาะหลัง 100% ไม่โดนตี)", "Above (ลอยเหนือหัว)", "Orbit (วนรอบตัว)", "WalkTo (เดินอ้อมหลัง)", "Face", "Front"
    LockDistance = 4.5,
    UntouchableGodMode = true, -- ระบบหลบหลีก 100% ไร้เทียมทาน (ไม่โดนโจมตี)
    AutoParry = true,
    AutoDodge = true,
    DodgeInterval = 0.3,
    AutoDodgeLowHp = true,
    DodgeHpThreshold = 45,
    AutoAbility = true,
    AutoBoonPick = true,
    AutoSkipCutscenes = true,
    AutoReviveTeammates = true,
    AutoRetryVote = true,

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
    AutoUpgradeSkills = true,
    AutoOpenChests = true,
    AutoBuyChests = false,
    AutoBuyChestTier = "Common",
    KeepMinCash = 1000,

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
            task.wait(1.5)
            if getgenv and (getgenv()._GloryBoundRunning or getgenv()._SongHubLoading or getgenv()._UniversalLoaderLoading) then
                return
            end
            getgenv()._SongHubLoading = true
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
    Title = "⭐ Master Full Auto AFK (ฟาร์มครบวงจร 100%)",
    Desc = "เปิดใช้งานโหมดบอทเล่นเองทุกอย่าง: ยกน้ำหนักยิม + จุติ + ล็อคเป้าตีมอน + สแปมสกิล + แพรี่ + เลือกการ์ด + อัปสกิล + เปิดกล่อง + รับรางวัลรายวัน",
    Image = "flame"
})

TabGym:Toggle({
    Title = "⭐ Master Full Auto AFK (เปิดบอทเล่นเองทุกอย่าง 100%)",
    Desc = "เปิดใช้งานระบบออโต้ครบวงจรทุกระบบ AFK ได้ตลอด 24 ชั่วโมงโดยไม่ต้องกดอะไรเลย",
    Value = Config.MasterFullAuto,
    Callback = function(val)
        Config.MasterFullAuto = val
        Config.AutoTrain = val
        Config.AutoRebirth = val
        Config.FullAutoArena = val
        Config.TargetLock = val
        Config.KillAura = val
        Config.AutoAbility = val
        Config.AutoParry = val
        Config.AutoDodge = val
        Config.AutoDodgeLowHp = val
        Config.AutoBoonPick = val
        Config.AutoSkipCutscenes = val
        Config.AutoReviveTeammates = val
        Config.AutoRetryVote = val
        Config.AutoUpgradeSkills = val
        Config.AutoClaimDaily = val
        Config.AutoOpenChests = val
        if Config.AutoSave then SaveConfig(true) end
        if val then
            WindUI:Notify({ Title = "Master Full Auto Active! ⭐", Content = "All-in-One God Mode AFK is now running!", Duration = 3, Icon = "flame" })
        else
            WindUI:Notify({ Title = "Master Full Auto Off", Content = "Disabled all automated loops.", Duration = 2, Icon = "pause" })
        end
    end
})

TabGym:Divider()

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
    Desc = "เปิดระบบออโต้ครบวงจร: ล็อคเป้าเกาะหลังมอน + ฟันคอมโบ + สแปมสกิล + แดชหลบ 100% + แพรี่สะท้อน + เลือกการ์ด + วนลูปจบครบในตัว",
    Value = Config.FullAutoArena,
    Callback = function(val)
        Config.FullAutoArena = val
        if val then
            Config.TargetLock = true
            Config.KillAura = true
            Config.UntouchableGodMode = true
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

TabCombat:Toggle({
    Title = "🛡️ 100% Untouchable Evasion (ระบบหลบหลีก 100% ไร้เทียมทาน)",
    Desc = "ไม่โดนการโจมตี 100%! สลิปหลบหลังมอนทันทีที่มอนหันหน้าเข้าหา หรือง้างดาบ พร้อมแดช I-Frame และแพรี่สะท้อนดาเมจ",
    Value = Config.UntouchableGodMode,
    Callback = function(val)
        Config.UntouchableGodMode = val
        if val then
            Config.AutoDodge = true
            Config.AutoParry = true
            WindUI:Notify({ Title = "Untouchable Evasion ON! 🛡️", Content = "100% Attack Avoidance Active!", Duration = 2, Icon = "shield-check" })
        end
    end
})

TabCombat:Divider()

TabCombat:Toggle({
    Title = "🎯 Master Target Lock (ล็อคเกาะติดมอนสเตอร์ + โจมตี)",
    Desc = "เกาะติดมอนสเตอร์และโจมตีอัตโนมัติ ช่วยให้โจมตีโดน 100% ไม่พลาดเป้า",
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
    Title = "🎯 Combat Movement & Lock Mode (ระบบหลบหลีก / ตำแหน่งสู้)",
    Desc = "เลือกมุมต่อสู้: แนะนำ 'Behind (เกาะหลัง)' หรือ 'Above (ลอยเหนือหัว)' มอนสเตอร์จะตีไม่ถึง 100%",
    Values = {
        "Behind (เกาะหลังมอนสเตอร์ - หลบได้ 100% แนะนำ)",
        "Above (ลอยเหนือหัวมอนสเตอร์ - มอนตีไม่ถึง 100%)",
        "Orbit (เดินวนรอบตัวมอนสเตอร์ Kiting - หลบวงฟัน)",
        "WalkTo (เดินอ้อมไปตีข้างหลัง)",
        "Face Target (หันหน้าเข้าหา)",
        "Front (ประชิดหน้า)"
    },
    Value = "Behind (เกาะหลังมอนสเตอร์ - หลบได้ 100% แนะนำ)",
    Callback = function(val)
        if val:find("Behind") then
            Config.LockMode = "Behind"
        elseif val:find("Above") then
            Config.LockMode = "Above"
        elseif val:find("Orbit") then
            Config.LockMode = "Orbit"
        elseif val:find("WalkTo") then
            Config.LockMode = "WalkTo"
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
    Value = { Min = 15, Max = 500, Default = Config.AttackRadius },
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

TabCombat:Toggle({
    Title = "❤️ Auto Revive Teammates (ชุบชีวิตเพื่อน + รับชุบอัตโนมัติ)",
    Desc = "กดรับข้อเสนอชุบชีวิตทันที และช่วยชุบเพื่อนร่วมทีมที่ล้มในอารีน่า",
    Value = Config.AutoReviveTeammates,
    Callback = function(val)
        Config.AutoReviveTeammates = val
    end
})

TabCombat:Toggle({
    Title = "🔄 Auto Retry Match (โหวตเล่นซ้ำทันทีเมื่อจบแมตช์)",
    Desc = "โหวต Yes เริ่มรอบใหม่ทันทีเมื่อจบแมตช์ เพื่อฟาร์มต่อเนื่องไม่ต้องกลับล็อบบี้",
    Value = Config.AutoRetryVote,
    Callback = function(val)
        Config.AutoRetryVote = val
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
    Desc = "ส่งคำสั่ง QueueJoin เข้า Arena ทันที",
    Icon = "play",
    Callback = function()
        pcall(function()
            local rep = game:GetService("ReplicatedStorage")
            rep.Remotes.QueueJoin:FireServer()
            WindUI:Notify({ Title = "Joined Queue", Content = "Queueing for Arena...", Duration = 3 })
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

TabProg:Paragraph({
    Title = "💎 Progression, Economy & Auto Upgrades",
    Desc = "ระบบอัปเกรดตัวละครอัตโนมัติ: อัปสกิล, เปิดกล่องสมบัติ, รับรางวัลรายวัน และ Rebirth",
    Image = "award"
})

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

TabProg:Divider()

TabProg:Toggle({
    Title = "🧠 Auto Upgrade Skills (อัปเกรดสกิลอัตโนมัติ)",
    Desc = "เมื่อมีแต้ม Skill Points คงเหลือ บอทจะเลือกอัปเกรดสกิลที่ปลดล็อคให้อัตโนมัติ",
    Value = Config.AutoUpgradeSkills,
    Callback = function(val)
        Config.AutoUpgradeSkills = val
    end
})

TabProg:Button({
    Title = "🧠 Upgrade All Skills Now (อัปสกิลทั้งหมดตอนนี้)",
    Desc = "อัปเกรดสกิลทั้งหมดที่ซื้อได้ทันทีตามจำนวนแต้มที่มี",
    Icon = "zap",
    Callback = function()
        task.spawn(autoUpgradeSkills)
        WindUI:Notify({ Title = "Skills", Content = "Checking and upgrading available skills...", Duration = 2 })
    end
})

TabProg:Divider()

TabProg:Toggle({
    Title = "📦 Auto Open Owned Chests (เปิดกล่องในตัวอัตโนมัติ)",
    Desc = "เปิดกล่องสมบัติทั้งหมดที่มีอยู่ในกระเป๋าให้อัตโนมัติ",
    Value = Config.AutoOpenChests,
    Callback = function(val)
        Config.AutoOpenChests = val
    end
})

TabProg:Toggle({
    Title = "🛒 Auto Buy & Open Chests (ซื้อกล่องสมบัติอัตโนมัติ)",
    Desc = "ซื้อและเปิดกล่องสมบัติเมื่อมีเงินมากกว่าจำนวนเงินขั้นต่ำที่สำรองไว้",
    Value = Config.AutoBuyChests,
    Callback = function(val)
        Config.AutoBuyChests = val
    end
})

TabProg:Dropdown({
    Title = "🎁 Select Chest Tier to Buy (เลือกระดับกล่องที่จะซื้อ)",
    Desc = "ระดับกล่องที่ต้องการให้ซื้ออัตโนมัติ",
    Values = { "Common (400 Cash)", "Rare (1200 Cash)", "Epic (3200 Cash)" },
    Value = "Common (400 Cash)",
    Callback = function(val)
        if val:find("Rare") then
            Config.AutoBuyChestTier = "Rare"
        elseif val:find("Epic") then
            Config.AutoBuyChestTier = "Epic"
        else
            Config.AutoBuyChestTier = "Common"
        end
    end
})

TabProg:Slider({
    Title = "💰 Keep Minimum Cash (เงินขั้นต่ำที่ต้องสำรอง)",
    Desc = "ระบบจะไม่ซื้อกล่องถ้าเงินต่ำกว่าค่านี้ เพื่อไม่ให้เงินหมดตัว",
    Value = { Min = 0, Max = 10000, Default = Config.KeepMinCash },
    Callback = function(val)
        Config.KeepMinCash = val
    end
})

TabProg:Divider()

TabProg:Toggle({
    Title = "🎁 Auto Claim Daily & Spin Wheel",
    Desc = "กดรับรางวัลล็อกอินประจำวัน หมุนวงล้อสุ่ม และเคลมเควสประจำวันให้อัตโนมัติ",
    Value = Config.AutoClaimDaily,
    Callback = function(val)
        Config.AutoClaimDaily = val
    end
})

TabProg:Button({
    Title = "🎁 Claim Daily Rewards & Spin Wheel Now",
    Desc = "กดเคลมของรางวัลรายวันและหมุนวงล้อทันที",
    Icon = "gift",
    Callback = function()
        task.spawn(autoClaimDaily)
        WindUI:Notify({ Title = "Daily Rewards", Content = "Claimed daily rewards and spun wheel!", Duration = 2 })
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
    local char = LocalPlayer.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
    if not root then return nil, nil end

    local closest, closestDist = nil, maxDist or 300

    local function checkCandidate(model)
        if not model or not model:IsA("Model") or model == char then return end
        if Players:GetPlayerFromCharacter(model) then return end

        local hum = model:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then return end

        local eRoot = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model:FindFirstChildWhichIsA("BasePart")
        if eRoot then
            local d = (eRoot.Position - root.Position).Magnitude
            if d < closestDist then
                closestDist = d
                closest = eRoot
            end
        end
    end

    -- 1. ActiveEnemies folder
    local activeEnemies = workspace:FindFirstChild("ActiveEnemies")
    if activeEnemies then
        for _, e in ipairs(activeEnemies:GetChildren()) do
            checkCandidate(e)
        end
    end

    -- 2. Workspace Arena
    if not closest then
        local arena = workspace:FindFirstChild("Arena")
        if arena then
            for _, desc in ipairs(arena:GetDescendants()) do
                if desc:IsA("Model") and desc:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(desc) then
                    checkCandidate(desc)
                end
            end
        end
    end

    -- 3. Fallback scan of workspace models with Humanoid (excluding Lobby & Sanctum)
    if not closest then
        for _, c in ipairs(workspace:GetChildren()) do
            if c:IsA("Model") and c ~= char and not Players:GetPlayerFromCharacter(c) and c:FindFirstChildOfClass("Humanoid") then
                local n = c.Name:lower()
                if not n:find("lobby") and not n:find("sanctum") and not n:find("npc") and not n:find("shrine") and not n:find("barbell") then
                    checkCandidate(c)
                end
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
    local str = nil
    local cap = nil

    -- 1. Primary Check: ClientState (Game's official internal source of truth)
    pcall(function()
        local cs = require(LocalPlayer.PlayerScripts.Controllers.ClientState)
        local state = cs and cs.get and cs.get()
        if state then
            if state.Strength ~= nil then str = tonumber(state.Strength) end
            if state.StrengthCap ~= nil then cap = tonumber(state.StrengthCap) end
        end
    end)

    -- 2. Fallback: Defs.Rebirth capFor(currentRebirth)
    if not cap or cap <= 0 then
        pcall(function()
            local rebDef = require(ReplicatedStorage.Shared.Defs.Rebirth)
            local currentRebirth = tonumber(LocalPlayer:GetAttribute("Rebirth")) or 0
            if rebDef and rebDef.capFor then
                cap = tonumber(rebDef.capFor(currentRebirth))
            end
        end)
    end

    -- 3. Fallback: LobbyHUD Strength Text (e.g. "2 / 330")
    if (not str or not cap) then
        pcall(function()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local chip = pg and pg:FindFirstChild("LobbyHUD", true) and pg.LobbyHUD:FindFirstChild("Chips", true)
            local sRow = chip and chip:FindFirstChild("Strength", true)
            local lbl = sRow and sRow:FindFirstChild("Text", true)
            if lbl and lbl.Text and lbl.Text:find("/") then
                local sStr, sCap = lbl.Text:match("(%d+[%d%,]*)%s*/%s*(%d+[%d%,]*)")
                if sStr and sCap then
                    sStr = sStr:gsub(",", "")
                    sCap = sCap:gsub(",", "")
                    str = str or tonumber(sStr)
                    cap = cap or tonumber(sCap)
                end
            end
        end)
    end

    -- STRICT GUARD: If strength is less than cap, NEVER trigger rebirth!
    if str and cap and cap > 0 then
        return str >= cap
    end

    return false
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
        if (Config.AutoTrain or Config.MasterFullAuto) and not isRebirthing then
            pcall(function()
                local lp = LocalPlayer
                local zone = tostring(lp:GetAttribute("Zone") or "")
                local inArena = lp:GetAttribute("InArena")
                if inArena or (zone ~= "" and zone ~= "Lobby") then return end

                -- Check if rebirth ready first!
                if (Config.AutoRebirth or Config.MasterFullAuto) and checkRebirthReady() then
                    performRebirth()
                    return
                end

                local rep = game:GetService("ReplicatedStorage")
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
local lastBoonPickTime = 0
local function autoPickBoon()
    local now = tick()
    if now - lastBoonPickTime < 1.0 then return end

    pcall(function()
        local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        local boonChoice = pg and pg:FindFirstChild("BoonChoice")
        local isBoonOpen = false

        pcall(function()
            local bc = require(LocalPlayer.PlayerScripts.Controllers.BoonController)
            if bc and bc.isOpen and bc.isOpen() then
                isBoonOpen = true
            end
        end)
        if boonChoice and boonChoice.Enabled then isBoonOpen = true end
        if not isBoonOpen then return end

        lastBoonPickTime = now
        local vim = game:GetService("VirtualInputManager")
        local rep = game:GetService("ReplicatedStorage")
        local boonRemote = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("BoonPick")

        -- Card scoring: Legendary (100) > Epic (80) > Rare (60) > Common (40)
        local cardScores = { [1] = 40, [2] = 40, [3] = 40 }
        local cardIds = {}
        local highestScore = -1
        local bestCardIndex = 1

        if boonChoice then
            local screenW = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X) or 1920
            for _, lbl in ipairs(boonChoice:GetDescendants()) do
                if lbl:IsA("TextLabel") and lbl.Text and #lbl.Text > 1 then
                    local t = lbl.Text:lower()
                    local x = lbl.AbsolutePosition.X
                    local cardIdx = 1
                    if x > screenW * 0.60 then
                        cardIdx = 3
                    elseif x > screenW * 0.38 then
                        cardIdx = 2
                    else
                        cardIdx = 1
                    end

                    if t:find("legendary") or t:find("mythic") then
                        cardScores[cardIdx] = math.max(cardScores[cardIdx], 100)
                    elseif t:find("epic") or t:find("twin fates") or t:find("bloodthirst") or t:find("hercules") or t:find("nemesis") then
                        cardScores[cardIdx] = math.max(cardScores[cardIdx], 80)
                    elseif t:find("rare") or t:find("lupa") or t:find("apollo") or t:find("vulcan") or t:find("minerva") then
                        cardScores[cardIdx] = math.max(cardScores[cardIdx], 60)
                    elseif t:find("fury") or t:find("damage") or t:find("mars") or t:find("mercury") or t:find("diana") then
                        cardScores[cardIdx] = math.max(cardScores[cardIdx], 45)
                    end

                    local raw = t:gsub("%s+", ""):gsub("[^%w]", "")
                    if raw == "furyofmars" or raw == "lupashunger" or raw == "mercuryssandals" or raw == "dianaseye"
                        or raw == "apolloslight" or raw == "vulcansbrand" or raw == "minervasaegis" or raw == "junosgrace"
                        or raw == "twinfates" or raw == "crowdsfavor" or raw == "bloodthirst" or raw == "medicus"
                        or raw == "windstep" or raw == "keenedge" or raw == "testudo" or raw == "herculesclub"
                        or raw == "saturnshourglass" or raw == "nemesisverdict" then
                        cardIds[cardIdx] = raw
                    end
                end
            end
        end

        for idx = 1, 3 do
            if cardScores[idx] > highestScore then
                highestScore = cardScores[idx]
                bestCardIndex = idx
            end
        end

        -- 1. Native key press simulation (1, 2, or 3)
        local key = (bestCardIndex == 1 and Enum.KeyCode.One) or (bestCardIndex == 2 and Enum.KeyCode.Two) or Enum.KeyCode.Three
        pcall(function()
            vim:SendKeyEvent(true, key, false, game)
            task.wait(0.05)
            vim:SendKeyEvent(false, key, false, game)
        end)

        -- 2. Direct server remote confirmation
        local chosenBoonId = cardIds[bestCardIndex]
        if boonRemote and chosenBoonId then
            pcall(function() boonRemote:FireServer(chosenBoonId) end)
        end
    end)
end

-- 1.5. AUTO SKILL UPGRADE HELPER
local function autoUpgradeSkills()
    pcall(function()
        local cs = require(LocalPlayer.PlayerScripts.Controllers.ClientState)
        local state = cs and cs.get and cs.get()
        local sp = state and tonumber(state.SkillPoints) or 0
        if sp <= 0 then return end

        local rep = game:GetService("ReplicatedStorage")
        local skillsDef = require(rep.Shared.Defs.Skills)
        local remote = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("SkillUpgrade")
        if not remote or not skillsDef or not skillsDef.IDS or not skillsDef.canBuy then return end

        local playerSkills = state.Skills or {}
        local playerLevel = state.Level or 1

        local priorityList = {
            "SharpEdge", "Relentless", "DeepWounds", "GiantSlayer", "WrathOfMars", "Sunder", "Executioner",
            "IronSkin", "Vigor", "Unyielding", "ShieldWall", "Hardened", "PhantomStep", "LightStep",
            "LongStride", "Blessed", "InnerFire", "GoldenTouch", "MidasTouch", "SwiftSandals"
        }

        for _, id in ipairs(priorityList) do
            local ok, can = pcall(skillsDef.canBuy, playerSkills, id, playerLevel, sp)
            if ok and can == true then
                remote:FireServer(id)
                task.wait(0.15)
                state = cs.get and cs.get()
                sp = state and tonumber(state.SkillPoints) or 0
                if sp <= 0 then return end
            end
        end

        for _, id in ipairs(skillsDef.IDS) do
            local ok, can = pcall(skillsDef.canBuy, playerSkills, id, playerLevel, sp)
            if ok and can == true then
                remote:FireServer(id)
                task.wait(0.15)
                state = cs.get and cs.get()
                sp = state and tonumber(state.SkillPoints) or 0
                if sp <= 0 then return end
            end
        end
    end)
end

-- 1.6. AUTO CLAIM DAILY & SPIN WHEEL HELPER
local function autoClaimDaily()
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local remote = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("DailyAction")
        if not remote then return end

        remote:FireServer("claim")
        remote:FireServer("spin")
        for i = 1, 5 do
            remote:FireServer("qclaim", i)
        end
    end)
end

-- 1.7. AUTO CHEST BUYER & OPENER HELPER
local function autoOpenChests()
    pcall(function()
        local cs = require(LocalPlayer.PlayerScripts.Controllers.ClientState)
        local state = cs.get and cs.get()
        local rep = game:GetService("ReplicatedStorage")
        if not rep:FindFirstChild("Remotes") then return end

        -- 1. Open any owned chests in inventory
        if state and state.OwnedChests and #state.OwnedChests > 0 and rep.Remotes:FindFirstChild("ChestOpen") then
            for _, chest in ipairs(state.OwnedChests) do
                local chestId = type(chest) == "table" and (chest.id or chest.Id or chest.uid) or chest
                rep.Remotes.ChestOpen:FireServer(chestId)
                task.wait(0.15)
            end
        end

        -- 2. Auto Buy Chest if cash > KeepMinCash
        if Config.AutoBuyChests and rep.Remotes:FindFirstChild("ChestBuy") then
            local tier = Config.AutoBuyChestTier or "Common"
            local minCash = Config.KeepMinCash or 1000
            local price = (tier == "Epic" and 3200) or (tier == "Rare" and 1200) or 400
            if state and state.Cash and (state.Cash - price) >= minCash then
                rep.Remotes.ChestBuy:FireServer(tier)
            end
        end
    end)
end

-- 1.8. AUTO RETRY VOTE HELPER
local function autoRetryVote()
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local remote = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("RetryVote")
        if remote and LocalPlayer:GetAttribute("TrialRetryVoted") ~= true then
            remote:FireServer("yes")
        end

        -- Click Skip & Retry buttons on BattleReport GUI
        local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        local br = pg and pg:FindFirstChild("BattleReport")
        if br and br.Enabled then
            for _, btn in ipairs(br:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                    local txt = (btn:IsA("TextButton") and btn.Text or btn.Name):lower()
                    if txt:find("skip") or txt:find("retry") or txt:find("again") or txt:find("continue") then
                        pcall(function()
                            if firesignal then
                                firesignal(btn.Activated)
                                firesignal(btn.MouseButton1Click)
                            end
                        end)
                        pcall(function()
                            local center = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
                            VirtualUser:Button1Down(center)
                            task.wait(0.04)
                            VirtualUser:Button1Up(center)
                        end)
                    end
                end
            end
        end

        -- Auto queue if returned to Lobby
        if (Config.AutoQueueArena or Config.FullAutoArena or Config.MasterFullAuto) and rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("QueueJoin") then
            local inArena = LocalPlayer:GetAttribute("InArena")
            local zone = tostring(LocalPlayer:GetAttribute("Zone") or "")
            if not inArena or zone == "Lobby" then
                rep.Remotes.QueueJoin:FireServer()
            end
        end
    end)
end

-- 1.9. AUTO REVIVE TEAMMATES & SELF HELPER
local function autoRevive()
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        if not rep:FindFirstChild("Remotes") then return end

        -- Accept any incoming revive offer
        if rep.Remotes:FindFirstChild("ReviveOfferAnswer") then
            rep.Remotes.ReviveOfferAnswer:FireServer(true)
        end

        -- Proximity prompt revive for fallen teammates
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local prompt = p.Character:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and prompt.ActionText and prompt.ActionText:lower():find("revive") then
                    if fireproximityprompt then
                        fireproximityprompt(prompt)
                    end
                end
            end
        end
    end)
end

-- 1.10. MASTER 100% UNTOUCHABLE COMBAT MOVEMENT CONTROLLER
local lastPathStuckCheck = 0
local lastPlayerPos = nil

task.spawn(function()
    while isAlive() do
        task.wait(0.02)
        if Config.TargetLock or Config.FullAutoArena or Config.KillAura or Config.UntouchableGodMode then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
                if not hum or not root or hum.Health <= 0 then return end

                local target, dist = getClosestEnemy(Config.AttackRadius or 350)
                if target and target.Parent then
                    local eHum = target.Parent:FindFirstChildOfClass("Humanoid")
                    if not eHum or eHum.Health > 0 then
                        -- Auto Equip Weapon from Backpack if unequipped
                        local currentTool = char:FindFirstChildWhichIsA("Tool")
                        if not currentTool then
                            local bp = LocalPlayer:FindFirstChild("Backpack")
                            local tool = bp and bp:FindFirstChildWhichIsA("Tool")
                            if tool then
                                hum:EquipTool(tool)
                                currentTool = tool
                            end
                        end

                        local toolName = currentTool and currentTool.Name:lower() or ""
                        local isRanged = toolName:find("bow") or toolName:find("arrow") or toolName:find("staff")
                        local desiredDist = isRanged and 26 or (Config.LockDistance or 4.5)
                        local targetPos = target.Position
                        local targetLook = target.CFrame.LookVector

                        if Config.LockMode == "Behind" then
                            -- 100% UNTOUCHABLE BEHIND: Always pinned to enemy blindspot rear arc
                            local behindPos = targetPos - (targetLook * desiredDist) + Vector3.new(0, 0.4, 0)
                            root.CFrame = CFrame.lookAt(behindPos, targetPos)
                            root.AssemblyLinearVelocity = Vector3.zero
                            root.AssemblyAngularVelocity = Vector3.zero

                        elseif Config.LockMode == "Above" then
                            -- 100% UNTOUCHABLE HEIGHT: Ground melee hitboxes cannot reach Y + 6.0
                            local abovePos = targetPos + Vector3.new(0, 6.0, 0)
                            root.CFrame = CFrame.lookAt(abovePos, targetPos)
                            root.AssemblyLinearVelocity = Vector3.zero
                            root.AssemblyAngularVelocity = Vector3.zero

                        elseif Config.LockMode == "Orbit" then
                            -- CIRCLE-STRAFE KITING: Continuously orbits at high speed around target
                            local angle = tick() * 3.5
                            local orbitOffset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * desiredDist
                            local orbitPos = targetPos + orbitOffset + Vector3.new(0, 0.6, 0)
                            root.CFrame = CFrame.lookAt(orbitPos, targetPos)
                            root.AssemblyLinearVelocity = Vector3.zero

                        elseif Config.LockMode == "WalkTo" then
                            -- Natural Walking but navigates directly to the BEHIND of the enemy!
                            local safeBehindPos = targetPos - (targetLook * desiredDist)
                            local toBehind = (safeBehindPos - root.Position)
                            root.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetPos.X, root.Position.Y, targetPos.Z))

                            if toBehind.Magnitude > 2.5 then
                                hum:MoveTo(safeBehindPos)
                                hum:Move(toBehind.Unit, false)

                                local now = tick()
                                if dist > 65 or (lastPlayerPos and (root.Position - lastPlayerPos).Magnitude < 1 and (now - lastPathStuckCheck) > 2.0) then
                                    lastPathStuckCheck = now
                                    local glidePos = safeBehindPos + Vector3.new(0, 0.8, 0)
                                    root.CFrame = CFrame.lookAt(glidePos, targetPos)
                                    root.AssemblyLinearVelocity = Vector3.zero
                                end
                                lastPlayerPos = root.Position
                            else
                                -- At the rear: Small micro-strafe behind enemy
                                local strafeOffset = target.CFrame.RightVector * (math.sin(tick() * 4) * 2.2)
                                root.CFrame = CFrame.lookAt(safeBehindPos + strafeOffset, targetPos)
                                hum:Move(Vector3.zero, false)
                            end
                        elseif Config.LockMode == "Front" then
                            local frontPos = targetPos + (targetLook * desiredDist)
                            root.CFrame = CFrame.lookAt(frontPos, targetPos)
                            root.AssemblyLinearVelocity = Vector3.zero
                        else -- "Face"
                            root.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetPos.X, root.Position.Y, targetPos.Z))
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
        task.wait(0.11)
        if Config.KillAura or Config.FullAutoArena or Config.TargetLock then
            pcall(function()
                local rep = game:GetService("ReplicatedStorage")
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
                if not hum or not root or hum.Health <= 0 then return end

                local target, dist = getClosestEnemy(Config.AttackRadius or 350)
                if target and target.Parent then
                    local eHum = target.Parent:FindFirstChildOfClass("Humanoid")
                    if not eHum or eHum.Health > 0 then
                        local currentTool = char:FindFirstChildWhichIsA("Tool")
                        local toolName = currentTool and currentTool.Name:lower() or ""
                        local isRanged = toolName:find("bow") or toolName:find("arrow") or toolName:find("staff")
                        local maxStrikeDist = isRanged and 45 or 8.5

                        -- Only strike if within effective weapon reach!
                        if dist <= maxStrikeDist then
                            -- Aim camera at target
                            pcall(function()
                                if workspace.CurrentCamera then
                                    workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, target.Position)
                                end
                            end)

                            -- Attack Method 1: RemoteEvent Attack + Release
                            rep.Remotes.Attack:FireServer(combo, target.Position, false)
                            task.wait(0.04)
                            rep.Remotes.AttackRelease:FireServer(combo, 1, target.Position)
                            combo = (combo % 3) + 1

                            -- Attack Method 2: Virtual Click (Fires Bow drawing/release & standard attacks)
                            pcall(function()
                                local cam = workspace.CurrentCamera
                                local center = cam and Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2) or Vector2.zero
                                VirtualUser:Button1Down(center, cam and cam.CFrame or CFrame.identity)
                                task.wait(0.06)
                                VirtualUser:Button1Up(center, cam and cam.CFrame or CFrame.identity)
                            end)

                            -- Cast Ability if enabled
                            if Config.AutoAbility then
                                rep.Remotes.AbilityCast:FireServer(target.Position)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ==============================================================================
-- 🛡️ 100% UNTOUCHABLE AUTO DODGE & GOD PARRY ENGINE (ACTIVE 50Hz EVASION)
-- ==============================================================================
local lastCombatDodge = 0
local lastParryTime = 0

local function performUntouchableEvasion(threatModel, escapeCFrame)
    local now = tick()
    if now - lastCombatDodge < 0.22 then return end
    lastCombatDodge = now

    local char = LocalPlayer.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
    if not root then return end

    -- 1. Physical Relocation (100% out of attack hitbox!)
    if escapeCFrame then
        root.CFrame = escapeCFrame
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    -- 2. Trigger native client dash + remote dash
    local rep = game:GetService("ReplicatedStorage")
    local tRoot = threatModel and (threatModel:FindFirstChild("HumanoidRootPart") or threatModel.PrimaryPart)
    local dodgeDir = tRoot and (root.Position - tRoot.Position).Unit or -root.CFrame.LookVector

    pcall(function()
        local cc = require(LocalPlayer.PlayerScripts.Controllers.CombatController)
        if cc and cc.dash then
            cc.dash(dodgeDir)
        end
    end)

    if rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("Dash") then
        rep.Remotes.Dash:FireServer(dodgeDir)
    end

    -- 3. Trigger God Parry / Block Window
    if rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("Block") and (now - lastParryTime > 0.35) then
        lastParryTime = now
        rep.Remotes.Block:FireServer(true, 0)
        task.delay(0.2, function()
            pcall(function() rep.Remotes.Block:FireServer(false, 0.2) end)
        end)
    end
end

task.spawn(function()
    while isAlive() do
        task.wait(0.02) -- 50Hz instantaneous response!
        if Config.AutoDodge or Config.UntouchableGodMode or Config.AutoParry or Config.FullAutoArena then
            pcall(function()
                local rep = game:GetService("ReplicatedStorage")
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
                if not hum or not root or hum.Health <= 0 then return end

                local now = tick()
                local myPos = root.Position
                local hpPct = (hum.Health / math.max(1, hum.MaxHealth)) * 100

                -- A. Emergency Low HP Retreat Vault (HP <= 45%)
                if (Config.AutoDodgeLowHp or Config.UntouchableGodMode or Config.FullAutoArena) and hpPct <= (Config.DodgeHpThreshold or 45) then
                    if now - lastCombatDodge > 0.8 then
                        local target = getClosestEnemy(35)
                        local escapeDir = target and (myPos - target.Position).Unit or -root.CFrame.LookVector
                        local safeEscapePos = myPos + (escapeDir * 16) + Vector3.new(0, 3.5, 0)
                        performUntouchableEvasion(target and target.Parent, CFrame.lookAt(safeEscapePos, myPos))
                        return
                    end
                end

                -- B. Scan ALL active enemies in Arena (Multi-target Threat Detection)
                local ae = workspace:FindFirstChild("ActiveEnemies")
                local threats = {}

                local function evaluateThreat(e)
                    if not e or not e:IsA("Model") or e == char then return end
                    local eHum = e:FindFirstChildOfClass("Humanoid")
                    if eHum and eHum.Health <= 0 then return end

                    local eRoot = e:FindFirstChild("HumanoidRootPart") or e.PrimaryPart or e:FindFirstChildWhichIsA("BasePart")
                    if not eRoot then return end

                    local toMe = (myPos - eRoot.Position)
                    local dist = toMe.Magnitude
                    if dist > 22 then return end

                    local eLook = eRoot.CFrame.LookVector
                    local isFacingMe = (dist > 0.1) and (eLook:Dot(toMe.Unit) > 0.15)
                    local windup = tonumber(e:GetAttribute("WindupEnd")) or 0
                    local isWindingUp = (windup > 0 and (windup > now or (now - windup) < 0.35))
                    local aiState = tostring(e:GetAttribute("AIState") or ""):lower()
                    local atkKind = tostring(e:GetAttribute("AttackKind") or "")
                    local isAttacking = (aiState:find("attack") ~= nil) or (atkKind ~= "")

                    -- Threat trigger: Winding up, Attacking, or Facing player within strike range (< 9.5 studs)
                    if isWindingUp or isAttacking or (isFacingMe and dist <= 9.5) or (dist <= 6.0) then
                        table.insert(threats, { model = e, root = eRoot, dist = dist, look = eLook, isWindingUp = isWindingUp })
                    end
                end

                if ae then
                    for _, e in ipairs(ae:GetChildren()) do evaluateThreat(e) end
                end

                if #threats == 0 then
                    local target, dist = getClosestEnemy(15)
                    if target and target.Parent then
                        evaluateThreat(target.Parent)
                    end
                end

                -- C. Execute 100% Slip-Behind Evasion on any detected threat
                if #threats > 0 then
                    local threat = threats[1]
                    local tRoot = threat.root
                    local tLook = threat.look
                    local tPos = tRoot.Position
                    local desiredBehind = 5.0

                    if Config.LockMode == "Above" then
                        local abovePos = tPos + Vector3.new(0, 6.0, 0)
                        performUntouchableEvasion(threat.model, CFrame.lookAt(abovePos, tPos))
                    else
                        local safeBehindPos = tPos - (tLook * desiredBehind) + Vector3.new(0, 0.8, 0)
                        performUntouchableEvasion(threat.model, CFrame.lookAt(safeBehindPos, tPos))
                    end
                end
            end)
        end
    end
end)

-- 5. AUTO SKIP BOSS CUTSCENES, BOON PICKER, REVIVE & RETRY VOTE LOOP
task.spawn(function()
    while isAlive() do
        task.wait(0.35)
        pcall(function()
            local rep = game:GetService("ReplicatedStorage")
            if (Config.AutoSkipCutscenes or Config.MasterFullAuto) and rep.Remotes:FindFirstChild("BossCutsceneSkip") then
                rep.Remotes.BossCutsceneSkip:FireServer(1)
            end

            if Config.AutoBoonPick or Config.FullAutoArena or Config.MasterFullAuto then
                autoPickBoon()
            end

            if Config.AutoRetryVote or Config.FullAutoArena or Config.MasterFullAuto then
                autoRetryVote()
            end

            if Config.AutoReviveTeammates or Config.FullAutoArena or Config.MasterFullAuto then
                autoRevive()
            end
        end)
    end
end)

-- 6. ARENA AUTO QUEUE LOOP
task.spawn(function()
    while isAlive() do
        task.wait(2)
        if Config.AutoQueueArena or Config.MasterFullAuto then
            pcall(function()
                local zone = tostring(LocalPlayer:GetAttribute("Zone") or "")
                local inArena = LocalPlayer:GetAttribute("InArena")
                if zone == "Lobby" and not inArena then
                    local rep = game:GetService("ReplicatedStorage")
                    if rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("QueueJoin") then
                        rep.Remotes.QueueJoin:FireServer()
                    end
                end
            end)
        end
    end
end)

-- 7. AUTO PROGRESSION & REBIRTH ENGINE (STRICT CONDITION GATED)
task.spawn(function()
    while isAlive() do
        task.wait(2)
        pcall(function()
            if Config.AutoClaimDaily or Config.MasterFullAuto then
                autoClaimDaily()
            end

            if Config.AutoUpgradeSkills or Config.MasterFullAuto then
                autoUpgradeSkills()
            end

            if Config.AutoOpenChests or Config.AutoBuyChests or Config.MasterFullAuto then
                autoOpenChests()
            end

            if (Config.AutoRebirth or Config.MasterFullAuto) and not isRebirthing and checkRebirthReady() then
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
