-- ==============================================================================
-- 🚀 SONG HUB [v1.0] - ERA DOS GRIMÓRIOS 📖 (BLACK CLOVER UNIVERSE)
-- Game: Era dos Grimórios [BETA]
-- UniverseId: 10770749098 | PlaceId: 120299741604934
-- Features:
--     - ⚔️ Full Auto Farm (Bandits, Scouts, Brutes, Raiders, Chiefs, Mobs)
--     - 🛡️ Safe Hover / Float Farm Mode (Untouchable from Melee)
--     - 💥 Auto M1 Punch / Weapon Combat Combo
--     - 🔮 Auto Cast Grimoire Magic Skills (Z, X, C, V, E)
--     - 🌾 Auto Harvest / Collect ProximityPrompts (Wheat, Chests, Crates)
--     - 📜 Auto Accept & Repeat Quests
--     - 🧠 Auto Allocate Skill Points (Strength, Magic, Health, Mana, Agility)
--     - 🎁 Auto Claim Daily Rewards & Promo Codes (+100s of free Spins & Potions)
--     - ⚡ Player Movement: SpeedBoost, JumpBoost, InfJump, NoClip
--     - 📍 Waypoint Teleports (Grimoire Tower, Hayvale, Clover Kingdom, Altars)
--     - 🛡️ Anti-AFK 24/7 Protection
-- ==============================================================================

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
local VirtualInputManager = game:GetService("VirtualInputManager")
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
    if getgenv()._GrimorioRunning and getgenv()._Grimorio_Window and not getgenv()._Grimorio_ForceReload then
        print("[Era dos Grimórios Hub] 🛡️ Script is already running with active UI. Skipping duplicate launch.")
        return
    end

    getgenv()._Grimorio_ForceReload = nil
    getgenv()._Grimorio_LastStartTime = now
    getgenv()._GrimorioRunning = true
    getgenv()._GrimorioRunId = (tonumber(getgenv()._GrimorioRunId) or 0) + 1
end

-- Destroy existing UI instances
local function cleanAllWindUI()
    pcall(function()
        if getgenv and getgenv()._Grimorio_Window and getgenv()._Grimorio_Window.Destroy then
            pcall(function() getgenv()._Grimorio_Window:Destroy() end)
            getgenv()._Grimorio_Window = nil
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
                if cName:find("WindUI") or cName:find("Grimorio") or cName:find("SongHub") then
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

local currentScriptRunId = (getgenv and getgenv()._GrimorioRunId) or 1
local function isAlive()
    if getgenv and getgenv()._GrimorioRunId and getgenv()._GrimorioRunId > currentScriptRunId then
        return false
    end
    return true
end

-- ==============================================================================
-- ⚙️ CONFIGURATION & STATE
-- ==============================================================================
local Config = {
    -- Auto Farm
    MasterAutoFarm = false,
    TargetMob = "Bandit", -- "All Mobs", "Bandit", "Bandit Scout", "Bandit Brute", "Bandit Raider", "Bandit Chief", "Boar", "Rogue Mage", "Grimoire Thief"
    FarmMode = "Above", -- "Above", "Behind", "Under"
    FarmDistance = 5,
    AutoAttack = true,
    AttackSpeed = 0.15,
    AutoEquipWeapon = true,
    TargetWeaponSlot = "Water Grimoire", -- "Knuckles", "Water Grimoire", "First Weapon"

    -- Auto Skills
    AutoCastSkills = true,
    CastSkillZ = true,
    CastSkillX = true,
    CastSkillC = true,
    CastSkillV = false,
    CastSkillE = false,
    SkillDelay = 0.6,

    -- Defense
    AutoManaCover = true,
    AutoBlockLowHp = true,
    LowHpThreshold = 30,

    -- World & Quests
    AutoRepeatQuest = true,
    AutoCollectNearby = true,
    CollectRange = 35,
    FastProximityPrompt = true,

    -- Progression & Stats
    AutoAllocateStats = true,
    TargetStat = "Strength", -- "Strength", "Magic", "Health", "Mana", "Agility"

    -- Rewards & Codes
    AutoDailyRewards = true,
    AutoMissions = true,

    -- Movement & Physics
    SpeedMultiplierEnabled = false,
    WalkSpeed = 28,
    JumpBooster = false,
    JumpHeight = 70,
    InfiniteJump = false,
    NoClip = false,

    -- Safety
    AntiAfk = true,
    AutoExecuteOnTeleport = true,
    AutoSave = true
}

-- Config Persistence
local CONFIG_FILE = "EraDosGrimorios_Config.json"

local function SaveConfig(silent)
    pcall(function()
        if writefile then
            local payload = HttpService:JSONEncode(Config)
            writefile(CONFIG_FILE, payload)
            if not silent and WindUI and WindUI.Notify then
                WindUI:Notify({ Title = "Saved!", Content = "บันทึกการตั้งค่าเรียบร้อยแล้ว", Duration = 2, Icon = "save" })
            end
        end
    end)
end

local function LoadConfig(silent)
    pcall(function()
        if isfile and isfile(CONFIG_FILE) and readfile then
            local raw = readfile(CONFIG_FILE)
            local decoded = HttpService:JSONDecode(raw)
            if type(decoded) == "table" then
                for k, v in pairs(decoded) do
                    Config[k] = v
                end
                if not silent and WindUI and WindUI.Notify then
                    WindUI:Notify({ Title = "Config Loaded", Content = "โหลดการตั้งค่าอัตโนมัติสำเร็จแล้ว!", Duration = 2, Icon = "folder-check" })
                end
            end
        end
    end)
end

pcall(function() LoadConfig(true) end)

-- Waypoint Coordinates
local TeleportLocations = {
    ["📖 Great Library (Grimoire Tower)"] = Vector3.new(245.5, 30.5, 488.2),
    ["🌾 Hayvale Village (Bandits Farm)"] = Vector3.new(585.2, 18.4, 612.8),
    ["🏰 Clover Kingdom Main Gate"] = Vector3.new(125.4, 25.1, 150.3),
    ["⛩️ Altar Area"] = Vector3.new(412.0, 45.2, 310.5),
    ["⛺ Bandit Outpost"] = Vector3.new(720.5, 22.1, 745.0),
    ["🌲 Old Woodcutter Forest"] = Vector3.new(450.2, 19.5, 820.4)
}

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
    warn("[Era dos Grimórios Hub] ❌ Failed to download WindUI framework. Check connection.")
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
    Title = "Era dos Grimórios | Song Hub [v1.0]",
    Icon = "book-open",
    Author = "by Song Hub Dev",
    Folder = "GrimorioHub",
    Size = UDim2.fromOffset(590, 490),
    Transparent = true,
    Theme = "Dark",
    Acrylic = false,
    Resizable = true
})

if getgenv then
    getgenv()._Grimorio_Window = Window
end

-- ==============================================================================
-- ⚔️ TAB 1: AUTO FARM & COMBAT
-- ==============================================================================
local TabFarm = Window:Tab({ Title = "Auto Farm", Icon = "swords" })

TabFarm:Paragraph({
    Title = "⚔️ Era dos Grimórios - Full Auto Combat",
    Desc = "ระบบฟาร์มมอนสเตอร์อัตโนมัติครบวงจร: ลอยเหนือหัวมอนสเตอร์หลบการโจมตี 100%, สแปมหมัด/อาวุธ และสแปมเวทมนตร์ตำรา (Z, X, C, V)",
    Image = "swords"
})

TabFarm:Toggle({
    Title = "⭐ Master Auto Farm (เปิดฟาร์มออโต้ 100%)",
    Desc = "ค้นหาศัตรู, วาร์ปไปตำแหน่งปลอดภัย, สแปมโจมตี M1 และสแปมสกิลเวทย์ให้อัตโนมัติ",
    Value = Config.MasterAutoFarm,
    Callback = function(val)
        Config.MasterAutoFarm = val
        if Config.AutoSave then SaveConfig(true) end
        if val then
            WindUI:Notify({ Title = "Auto Farm Active! ⭐", Content = "Auto Farming is now running safely!", Duration = 3, Icon = "flame" })
        else
            WindUI:Notify({ Title = "Auto Farm Off", Content = "Stopped auto farm loop.", Duration = 2, Icon = "pause" })
        end
    end
})

TabFarm:Dropdown({
    Title = "🎯 Target Mob (เลือกมอนสเตอร์ที่จะฟาร์ม)",
    Desc = "เลือกประเภทศัตรูที่ต้องการให้บอทเข้าไปฟาร์ม",
    Values = {
        "All Mobs (ทั้งหมด)",
        "Bandit (โจรเริ่มต้น Lv 1)",
        "Bandit Scout (สเกาต์)",
        "Bandit Brute (ตัวใหญ่)",
        "Bandit Raider (ไรเดอร์)",
        "Bandit Chief (หัวหน้าโจร)",
        "Boar (หมูป่า)",
        "Rogue Mage (จอมเวทย์นอกคอก)",
        "Grimoire Thief (ขโมยตำราเวทย์)"
    },
    Value = "Bandit (โจรเริ่มต้น Lv 1)",
    Callback = function(val)
        if val:find("All") then
            Config.TargetMob = "All Mobs"
        elseif val:find("Scout") then
            Config.TargetMob = "Bandit Scout"
        elseif val:find("Brute") then
            Config.TargetMob = "Bandit Brute"
        elseif val:find("Raider") then
            Config.TargetMob = "Bandit Raider"
        elseif val:find("Chief") then
            Config.TargetMob = "Bandit Chief"
        elseif val:find("Boar") then
            Config.TargetMob = "Boar"
        elseif val:find("Rogue Mage") then
            Config.TargetMob = "Rogue Mage"
        elseif val:find("Thief") then
            Config.TargetMob = "Grimoire Thief"
        else
            Config.TargetMob = "Bandit"
        end
    end
})

TabFarm:Dropdown({
    Title = "🛡️ Farm Position Mode (ตำแหน่งการยืนฟาร์ม)",
    Desc = "Above = ลอยเหนือหัวมอนสเตอร์ (ปลอดภัยจากการโจมตีกายภาพ 100%), Behind = เกาะข้างหลัง",
    Values = { "Above (ลอยเหนือหัว - ปลอดภัย 100%)", "Behind (เกาะหลัง)", "Under (อยู่ใต้ดิน)" },
    Value = "Above (ลอยเหนือหัว - ปลอดภัย 100%)",
    Callback = function(val)
        if val:find("Behind") then
            Config.FarmMode = "Behind"
        elseif val:find("Under") then
            Config.FarmMode = "Under"
        else
            Config.FarmMode = "Above"
        end
    end
})

TabFarm:Slider({
    Title = "📏 Farm Distance (ระยะห่างจากมอนสเตอร์)",
    Desc = "ระยะความสูงหรือระยะห่างระหว่างตัวละครกับมอนสเตอร์ (แนะนำ 4 - 6 studs)",
    Value = { Min = 2, Max = 15, Default = Config.FarmDistance },
    Callback = function(val)
        Config.FarmDistance = val
    end
})

TabFarm:Divider()

TabFarm:Toggle({
    Title = "🥊 Auto M1 Attack (สแปมโจมตีปกติ)",
    Desc = "คลิกซ้ายและรัวหมัด/อาวุธต่อเนื่อง",
    Value = Config.AutoAttack,
    Callback = function(val)
        Config.AutoAttack = val
    end
})

TabFarm:Toggle({
    Title = "🗡️ Auto Equip Weapon / Grimoire (ถืออาวุธอัตโนมัติ)",
    Desc = "หยิบตำราเวทย์หรืออาวุธขึ้นมาถืออัตโนมัติหากยังไม่ได้ถือ",
    Value = Config.AutoEquipWeapon,
    Callback = function(val)
        Config.AutoEquipWeapon = val
    end
})

TabFarm:Divider()

TabFarm:Toggle({
    Title = "🔮 Auto Cast Magic Skills (สแปมสกิลเวทย์อัตโนมัติ)",
    Desc = "กดร่ายสกิลตำราเวทย์และอาวุธอัตโนมัติเมื่อคูลดาวน์พร้อม",
    Value = Config.AutoCastSkills,
    Callback = function(val)
        Config.AutoCastSkills = val
    end
})

TabFarm:Toggle({
    Title = "💥 Use Skill [Z] (สกิล 1)",
    Desc = "ร่ายสกิล Z อัตโนมัติ",
    Value = Config.CastSkillZ,
    Callback = function(val) Config.CastSkillZ = val end
})

TabFarm:Toggle({
    Title = "💥 Use Skill [X] (สกิล 2)",
    Desc = "ร่ายสกิล X อัตโนมัติ",
    Value = Config.CastSkillX,
    Callback = function(val) Config.CastSkillX = val end
})

TabFarm:Toggle({
    Title = "💥 Use Skill [C] (สกิล 3)",
    Desc = "ร่ายสกิล C อัตโนมัติ",
    Value = Config.CastSkillC,
    Callback = function(val) Config.CastSkillC = val end
})

TabFarm:Toggle({
    Title = "💥 Use Skill [V] (สกิล 4)",
    Desc = "ร่ายสกิล V อัตโนมัติ",
    Value = Config.CastSkillV,
    Callback = function(val) Config.CastSkillV = val end
})

-- ==============================================================================
-- 📜 TAB 2: QUESTS & WORLD GATHERING
-- ==============================================================================
local TabQuest = Window:Tab({ Title = "Quests & Farm", Icon = "scroll" })

TabQuest:Paragraph({
    Title = "📜 Quests & World Gathering",
    Desc = "ระบบรับ-ส่งเควสอัตโนมัติ และระบบเก็บเกี่ยวผลผลิต/หีบสมบัติในโลกแบบ AFK",
    Image = "scroll"
})

TabQuest:Toggle({
    Title = "🔄 Auto Repeat Quest (รับและส่งเควสซ้ำอัตโนมัติ)",
    Desc = "ส่งคำขอทำเควสซ้ำอัตโนมัติ ไม่ต้องเดินไปคุยกับ NPC ด้วยตัวเอง",
    Value = Config.AutoRepeatQuest,
    Callback = function(val)
        Config.AutoRepeatQuest = val
    end
})

TabQuest:Button({
    Title = "🔄 Repeat Quest Now (กดรับเควสซ้ำทันที)",
    Desc = "ยิงคำขอทำเควสปัจจุบันซ้ำทันทีใน 1 คลิก",
    Icon = "rotate-cw",
    Callback = function()
        pcall(function()
            local rep = game:GetService("ReplicatedStorage")
            if rep:FindFirstChild("Rep_Core") and rep.Rep_Core.Events:FindFirstChild("RepeatQuest") then
                rep.Rep_Core.Events.RepeatQuest:FireServer()
                WindUI:Notify({ Title = "Quest", Content = "Fired RepeatQuest successfully!", Duration = 2 })
            end
        end)
    end
})

TabQuest:Divider()

TabQuest:Toggle({
    Title = "🌾 Auto Harvest & Collect ProximityPrompts",
    Desc = "เก็บเกี่ยวข้าวสาลี (Wild Wheat), หีบสมบัติ (Map Chests), และกล่องเสบียงเควสรอบตัวอัตโนมัติ",
    Value = Config.AutoCollectNearby,
    Callback = function(val)
        Config.AutoCollectNearby = val
    end
})

TabQuest:Toggle({
    Title = "⚡ Fast Proximity Prompt (กดโต้ตอบทันทีไม่ต้องรอ)",
    Desc = "ปรับเวลาการกดค้างของทุก ProximityPrompt เป็น 0 วิ เพื่อเก็บของได้เร็วที่สุด",
    Value = Config.FastProximityPrompt,
    Callback = function(val)
        Config.FastProximityPrompt = val
    end
})

TabQuest:Button({
    Title = "📦 Interact All Nearby Prompts Now (กดเก็บของทั้งหมดรอบตัว)",
    Desc = "สั่ง Trigger ทุก ProximityPrompt ในระยะ 35 studs ทันที",
    Icon = "package",
    Callback = function()
        pcall(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local count = 0
            for _, p in ipairs(workspace:GetDescendants()) do
                if p:IsA("ProximityPrompt") and p.Enabled then
                    local part = p.Parent
                    if part and part:IsA("BasePart") then
                        if (part.Position - root.Position).Magnitude <= 40 then
                            if fireproximityprompt then
                                fireproximityprompt(p)
                                count = count + 1
                            end
                        end
                    end
                end
            end
            WindUI:Notify({ Title = "Collect", Content = "Triggered " .. tostring(count) .. " nearby prompts!", Duration = 2 })
        end)
    end
})

-- ==============================================================================
-- 💎 TAB 3: CHARACTER & AUTO STATS
-- ==============================================================================
local TabStats = Window:Tab({ Title = "Stats", Icon = "sparkles" })

TabStats:Paragraph({
    Title = "💎 Character Stat Points Allocator",
    Desc = "ระบบอัปค่าสเตตัสอัตโนมัติ: เมื่อมีแต้มคงเหลือ บอทจะเพิ่มแต้มให้สเตตัสที่เลือกทันที",
    Image = "sparkles"
})

TabStats:Toggle({
    Title = "🧠 Auto Allocate Skill Points (อัปสเตตัสอัตโนมัติ)",
    Desc = "เมื่อมีแต้ม Points เหลือจากการเลเวลอัป จะกดอัปสเตตัสเป้าหมายให้อัตโนมัติ",
    Value = Config.AutoAllocateStats,
    Callback = function(val)
        Config.AutoAllocateStats = val
    end
})

TabStats:Dropdown({
    Title = "🎯 Target Stat to Allocate (เลือกสเตตัสที่จะอัป)",
    Desc = "เลือกสเตตัสที่ต้องการเพิ่มแต้ม",
    Values = {
        "Strength (ดาเมจหมัด/อาวุธกายภาพ)",
        "Magic (ดาเมจเวทย์ตำรากริมมัวร์)",
        "Health (เลือด Max HP)",
        "Mana (มานา Max MP & รีเจนเร็วขึ้น)",
        "Agility (ความเร็วโจมตี & Dash)"
    },
    Value = "Strength (ดาเมจหมัด/อาวุธกายภาพ)",
    Callback = function(val)
        if val:find("Magic") then
            Config.TargetStat = "Magic"
        elseif val:find("Health") then
            Config.TargetStat = "Health"
        elseif val:find("Mana") then
            Config.TargetStat = "Mana"
        elseif val:find("Agility") then
            Config.TargetStat = "Agility"
        else
            Config.TargetStat = "Strength"
        end
    end
})

TabStats:Button({
    Title = "⚡ Allocate All Remaining Points Now (อัปแต้มทั้งหมดทันที)",
    Desc = "ใช้แต้มที่เหลือทั้งหมดอัปสเตตัสที่เลือกไว้ทันที",
    Icon = "zap",
    Callback = function()
        pcall(function()
            local statKey = Config.TargetStat or "Strength"
            local map = {
                Strength = "LinhaSTRENGTH",
                Magic = "LinhaMAGIC",
                Health = "LinhaHEALTH",
                Mana = "LinhaMANA",
                Agility = "LinhaAGILITY"
            }
            local rowName = map[statKey] or "LinhaSTRENGTH"
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local statsWin = pg and pg:FindFirstChild("Main") and pg.Main:FindFirstChild("Interface") and pg.Main.Interface.Center.Janelas:FindFirstChild("Stats")
            if statsWin then
                local grade = statsWin.Frame.Raiz.Atributos.Grade
                local row = grade:FindFirstChild(rowName)
                local btn = row and row:FindFirstChild("Mais")
                if btn and firesignal then
                    for _ = 1, 15 do
                        firesignal(btn.Activated)
                        task.wait(0.04)
                    end
                    WindUI:Notify({ Title = "Stats", Content = "Allocated points into " .. statKey .. "!", Duration = 2 })
                end
            end
        end)
    end
})

-- ==============================================================================
-- 🎁 TAB 4: REWARDS & CODES
-- ==============================================================================
local TabRewards = Window:Tab({ Title = "Rewards & Codes", Icon = "gift" })

TabRewards:Paragraph({
    Title = "🎁 Daily Rewards & Promo Codes",
    Desc = "ระบบรับรางวัลรายวันและปุ่มแลกโค้ดทั้งหมดของเกม รับฟรีทั้ง Grimoire Spins, Race Spins, Lineage Spins, หีบสมบัติ และยาบัฟเพียบ!",
    Image = "gift"
})

TabRewards:Toggle({
    Title = "🎁 Auto Claim Daily Rewards (รับรางวัลรายวันออโต้)",
    Desc = "กดรับ Daily Streak และเควสรายวันอัตโนมัติ",
    Value = Config.AutoDailyRewards,
    Callback = function(val)
        Config.AutoDailyRewards = val
    end
})

TabRewards:Button({
    Title = "🎁 Claim Daily Rewards Now (รับรางวัลรายวันทันที)",
    Desc = "กดเคลม Daily Rewards ทันทีใน 1 คลิก",
    Icon = "gift",
    Callback = function()
        pcall(function()
            local rep = game:GetService("ReplicatedStorage")
            if rep:FindFirstChild("Rep_Core") and rep.Rep_Core.Events:FindFirstChild("DailyRewards") then
                rep.Rep_Core.Events.DailyRewards:FireServer()
                WindUI:Notify({ Title = "Rewards", Content = "Daily Rewards claimed!", Duration = 2 })
            end
        end)
    end
})

TabRewards:Divider()

local ALL_PROMO_CODES = {
    { code = "RELEASE", reward = "+5 Grimoire Spins" },
    { code = "NEWERA", reward = "+15 Grimoire Fragment Chest" },
    { code = "FUNZYISBACK", reward = "+50 Grimoire Fragment Chest, +60 Grimoire Spins" },
    { code = "FirstShutDown", reward = "+30 Race Spins, +100 Mana Potions" },
    { code = "FPSFIX", reward = "+50 Health Potions, +30 Mana Potions, +5 Grimoire Spins" },
    { code = "DungeonFix", reward = "+10 Race Spins" },
    { code = "ProgressionFix", reward = "+20 Lineage Spins, 2x Exp 1h" },
    { code = "StoryMode", reward = "+10 Race Spins, +10 Grimoire Spins, +10 Lineage Spins" }
}

TabRewards:Button({
    Title = "🎟️ Redeem All Active Promo Codes (แลกทุกโค้ดใน 1 คลิก!)",
    Desc = "แลกโค้ดทั้งหมดของเซิร์ฟเวอร์ รับฟรี 100+ Spins, 150+ Potions และกล่องสมบัติ (ต้องเข้ากลุ่ม Roblox ของเกมก่อน)",
    Icon = "ticket",
    Callback = function()
        task.spawn(function()
            local rep = game:GetService("ReplicatedStorage")
            local codesRemote = rep:FindFirstChild("Rep_Core") and rep.Rep_Core.Events:FindFirstChild("Codes")
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local codesFrame = pg and pg:FindFirstChild("Main") and pg.Main.Interface.Center.Janelas.Info.Frame.Janela.Codes
            local caixa = codesFrame and codesFrame.TextBox:FindFirstChild("Caixa")
            local redeemBtn = codesFrame and codesFrame:FindFirstChild("Redeem")

            for _, item in ipairs(ALL_PROMO_CODES) do
                pcall(function()
                    if caixa and redeemBtn and firesignal then
                        caixa.Text = item.code
                        firesignal(redeemBtn.Activated)
                    elseif codesRemote then
                        codesRemote:FireServer("Redeem", item.code)
                        codesRemote:FireServer(item.code)
                    end
                end)
                task.wait(0.25)
            end

            WindUI:Notify({
                Title = "Codes Redeemed! 🎟️",
                Content = "Attempted all 8 promo codes! Check your spins & bag.",
                Duration = 4,
                Icon = "sparkles"
            })
        end)
    end
})

-- ==============================================================================
-- 🏃 TAB 5: MOVEMENT & TELEPORTS
-- ==============================================================================
local TabMove = Window:Tab({ Title = "Movement", Icon = "zap" })

TabMove:Paragraph({
    Title = "🏃 Speed, Jump & Teleportation",
    Desc = "ปรับความเร็วการเคลื่อนที่, กระโดดสูง, กระโดดกลางอากาศ และวาร์ปไปยังสถานที่สำคัญ",
    Image = "zap"
})

TabMove:Toggle({
    Title = "⚡ Speed Multiplier (เร่งความเร็วเดิน)",
    Desc = "เปิดใช้งานความเร็วเดินที่กำหนด",
    Value = Config.SpeedMultiplierEnabled,
    Callback = function(val)
        Config.SpeedMultiplierEnabled = val
        if not val then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end)
        end
    end
})

TabMove:Slider({
    Title = "🏃 WalkSpeed (ความเร็วเดิน)",
    Desc = "ปรับค่า WalkSpeed ของตัวละคร (ค่าเริ่มต้น = 16, แนะนำ 28 - 45)",
    Value = { Min = 16, Max = 150, Default = Config.WalkSpeed },
    Callback = function(val)
        Config.WalkSpeed = val
    end
})

TabMove:Toggle({
    Title = "🦘 Jump Booster (เพิ่มแรงกระโดด)",
    Desc = "เปิดใช้งานแรงกระโดดสูง",
    Value = Config.JumpBooster,
    Callback = function(val)
        Config.JumpBooster = val
        if not val then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.JumpHeight = 7.2 end
            end)
        end
    end
})

TabMove:Slider({
    Title = "🦘 JumpHeight (ความสูงกระโดด)",
    Desc = "ปรับค่า JumpHeight ของตัวละคร (ค่าเริ่มต้น = 7.2, แนะนำ 50 - 90)",
    Value = { Min = 7, Max = 150, Default = Config.JumpHeight },
    Callback = function(val)
        Config.JumpHeight = val
    end
})

TabMove:Toggle({
    Title = "☁️ Infinite Jump (กระโดดกลางอากาศไม่จำกัด)",
    Desc = "สามารถกระโดดลอยบนอากาศได้เรื่อยๆ โดยไม่มีลิมิต",
    Value = Config.InfiniteJump,
    Callback = function(val)
        Config.InfiniteJump = val
    end
})

TabMove:Toggle({
    Title = "👻 NoClip (เดินทะลุกำแพง)",
    Desc = "ปิด Hitbox ของตัวละครเพื่อเดินทะลุสิ่งกีดขวางและภูมิประเทศ",
    Value = Config.NoClip,
    Callback = function(val)
        Config.NoClip = val
    end
})

TabMove:Divider()

local locKeys = {}
for k, _ in pairs(TeleportLocations) do
    table.insert(locKeys, k)
end
table.sort(locKeys)

local selectedLocation = locKeys[1] or "📖 Great Library (Grimoire Tower)"

TabMove:Dropdown({
    Title = "📍 Select Waypoint (เลือกสถานที่วาร์ป)",
    Desc = "เลือกจุดหมายที่ต้องการวาร์ปไป",
    Values = locKeys,
    Value = selectedLocation,
    Callback = function(val)
        selectedLocation = val
    end
})

TabMove:Button({
    Title = "🚀 Teleport to Waypoint (วาร์ปทันที)",
    Desc = "เทเลพอร์ตตัวละครไปยังจุดที่เลือก",
    Icon = "map-pin",
    Callback = function()
        pcall(function()
            local targetPos = TeleportLocations[selectedLocation]
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if targetPos and root then
                root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
                WindUI:Notify({ Title = "Teleported!", Content = "Arrived at " .. selectedLocation, Duration = 2 })
            end
        end)
    end
})

-- ==============================================================================
-- 🛡️ TAB 6: SETTINGS
-- ==============================================================================
local TabSettings = Window:Tab({ Title = "Settings", Icon = "settings" })

TabSettings:Paragraph({
    Title = "⚙️ Script Settings & Auto Save",
    Desc = "การตั้งค่าระบบอัตโนมัติ บันทึกการตั้งค่าถาวร และระบบ Anti-AFK",
    Image = "settings"
})

TabSettings:Toggle({
    Title = "🛡️ Anti-AFK (ป้องกันหลุด 24 ชม.)",
    Desc = "ขยับเมาส์อัตโนมัติเมื่อตัวละครไม่ได้ขยับ เพื่อป้องกัน Roblox ตัดการเชื่อมต่อหลัง 20 นาที",
    Value = Config.AntiAfk,
    Callback = function(val)
        Config.AntiAfk = val
    end
})

TabSettings:Toggle({
    Title = "💾 Auto Save Settings (บันทึกการตั้งค่าถาวร)",
    Desc = "บันทึกการตั้งค่าลงเครื่องอัตโนมัติเมื่อมีการเปลี่ยนแปลง",
    Value = Config.AutoSave,
    Callback = function(val)
        Config.AutoSave = val
    end
})

TabSettings:Button({
    Title = "💾 Save Config Now (บันทึกเดี๋ยวนี้)",
    Desc = "บันทึกการตั้งค่าปัจจุบันลงในไฟล์ Config",
    Icon = "save",
    Callback = function()
        SaveConfig(false)
    end
})

TabSettings:Button({
    Title = "🔄 Re-Load Config (โหลดการตั้งค่าใหม่)",
    Desc = "โหลดการตั้งค่าจากไฟล์ที่บันทึกไว้",
    Icon = "folder-check",
    Callback = function()
        LoadConfig(false)
    end
})

-- ==============================================================================
-- 🚀 CORE AUTOMATION LOGIC & BACKGROUND ENGINES
-- ==============================================================================

-- Helper: Get Closest Target Mob
local function getTargetMob()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil, math.huge end

    local npcs = workspace:FindFirstChild("Npcs")
    if not npcs then return nil, math.huge end

    local targetName = Config.TargetMob or "Bandit"
    local closest, closestDist = nil, math.huge

    for _, mob in ipairs(npcs:GetChildren()) do
        if mob:IsA("Model") and mob:FindFirstChildOfClass("Humanoid") then
            local hum = mob:FindFirstChildOfClass("Humanoid")
            local mRoot = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
            if hum and hum.Health > 0 and mRoot then
                local isMatch = false
                if targetName == "All Mobs" then
                    isMatch = true
                elseif mob.Name:lower():find(targetName:lower()) then
                    isMatch = true
                end

                if isMatch then
                    local dist = (mRoot.Position - root.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = mob
                    end
                end
            end
        end
    end

    return closest, closestDist
end

-- 1. AUTO FARM COMBAT ENGINE
task.spawn(function()
    while isAlive() do
        task.wait(0.1)
        pcall(function()
            if not Config.MasterAutoFarm then return end

            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not root or not hum or hum.Health <= 0 then return end

            local mob, dist = getTargetMob()
            if not mob or not mob.Parent then return end

            local mRoot = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
            local mHum = mob:FindFirstChildOfClass("Humanoid")
            if not mRoot or not mHum or mHum.Health <= 0 then return end

            -- 1. Position character safely relative to mob
            local farmDist = Config.FarmDistance or 5
            local targetCFrame = nil
            if Config.FarmMode == "Above" then
                -- Stand directly above mob head (immune to ground melee attacks)
                targetCFrame = mRoot.CFrame * CFrame.new(0, farmDist, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            elseif Config.FarmMode == "Under" then
                -- Under the ground
                targetCFrame = mRoot.CFrame * CFrame.new(0, -farmDist, 0) * CFrame.Angles(math.rad(90), 0, 0)
            else
                -- Behind mob
                targetCFrame = mRoot.CFrame * CFrame.new(0, 0, farmDist)
            end

            -- Move to target
            root.CFrame = targetCFrame
            root.Velocity = Vector3.zero
            root.RotVelocity = Vector3.zero

            -- 2. Auto Equip Weapon / Grimoire if needed
            if Config.AutoEquipWeapon then
                local hasTool = char:FindFirstChildOfClass("Tool")
                if not hasTool then
                    local bp = LocalPlayer:FindFirstChild("Backpack")
                    if bp then
                        local tool = bp:FindFirstChild("Water Grimoire") or bp:FindFirstChild("Knuckles") or bp:FindFirstChildOfClass("Tool")
                        if tool then
                            hum:EquipTool(tool)
                        end
                    end
                end
            end

            -- 3. Auto M1 Attack
            if Config.AutoAttack then
                VirtualInputManager:SendMouseButtonEvent(500, 500, 0, true, game, 1)
                task.wait(0.04)
                VirtualInputManager:SendMouseButtonEvent(500, 500, 0, false, game, 1)

                -- Also trigger server attack remote if available
                local rep = game:GetService("ReplicatedStorage")
                if rep:FindFirstChild("Rep_Core") and rep.Rep_Core.Remotes.Combat:FindFirstChild("Attack") then
                    rep.Rep_Core.Remotes.Combat.Attack:FireServer()
                end
            end

            -- 4. Auto Cast Skills (Z, X, C, V)
            if Config.AutoCastSkills then
                local keysToCast = {}
                if Config.CastSkillZ then table.insert(keysToCast, Enum.KeyCode.Z) end
                if Config.CastSkillX then table.insert(keysToCast, Enum.KeyCode.X) end
                if Config.CastSkillC then table.insert(keysToCast, Enum.KeyCode.C) end
                if Config.CastSkillV then table.insert(keysToCast, Enum.KeyCode.V) end

                for _, k in ipairs(keysToCast) do
                    VirtualInputManager:SendKeyEvent(true, k, false, game)
                    task.wait(0.03)
                    VirtualInputManager:SendKeyEvent(false, k, false, game)
                    task.wait(0.05)
                end
            end
        end)
    end
end)

-- 2. FAST PROXIMITY PROMPTS & AUTO HARVEST ENGINE
task.spawn(function()
    while isAlive() do
        task.wait(0.35)
        pcall(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")

            -- Fast ProximityPrompt optimization
            if Config.FastProximityPrompt then
                for _, p in ipairs(workspace:GetDescendants()) do
                    if p:IsA("ProximityPrompt") then
                        p.HoldDuration = 0
                        p.MaxActivationDistance = 35
                        p.RequiresLineOfSight = false
                    end
                end
            end

            -- Auto collect / harvest nearby items
            if Config.AutoCollectNearby and root then
                local range = Config.CollectRange or 35
                for _, p in ipairs(workspace:GetDescendants()) do
                    if p:IsA("ProximityPrompt") and p.Enabled then
                        local part = p.Parent
                        if part and part:IsA("BasePart") then
                            if (part.Position - root.Position).Magnitude <= range then
                                if fireproximityprompt then
                                    fireproximityprompt(p)
                                    task.wait(0.05)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- 3. AUTO STATS ALLOCATOR ENGINE
task.spawn(function()
    while isAlive() do
        task.wait(1.5)
        pcall(function()
            if not Config.AutoAllocateStats then return end

            local pts = tonumber(LocalPlayer:GetAttribute("Points")) or 0
            if pts <= 0 then return end

            local statKey = Config.TargetStat or "Strength"
            local map = {
                Strength = "LinhaSTRENGTH",
                Magic = "LinhaMAGIC",
                Health = "LinhaHEALTH",
                Mana = "LinhaMANA",
                Agility = "LinhaAGILITY"
            }
            local rowName = map[statKey] or "LinhaSTRENGTH"
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local statsWin = pg and pg:FindFirstChild("Main") and pg.Main:FindFirstChild("Interface") and pg.Main.Interface.Center.Janelas:FindFirstChild("Stats")
            if statsWin then
                local grade = statsWin.Frame.Raiz.Atributos.Grade
                local row = grade:FindFirstChild(rowName)
                local btn = row and row:FindFirstChild("Mais")
                if btn and firesignal then
                    for _ = 1, math.min(pts, 10) do
                        firesignal(btn.Activated)
                        task.wait(0.04)
                    end
                end
            end
        end)
    end
end)

-- 4. AUTO REPEAT QUEST & DAILY REWARDS ENGINE
task.spawn(function()
    while isAlive() do
        task.wait(3.0)
        pcall(function()
            local rep = game:GetService("ReplicatedStorage")
            if not rep:FindFirstChild("Rep_Core") then return end

            -- Auto Repeat Quest
            if Config.AutoRepeatQuest and rep.Rep_Core.Events:FindFirstChild("RepeatQuest") then
                rep.Rep_Core.Events.RepeatQuest:FireServer()
            end

            -- Auto Daily Rewards
            if Config.AutoDailyRewards and rep.Rep_Core.Events:FindFirstChild("DailyRewards") then
                rep.Rep_Core.Events.DailyRewards:FireServer()
            end
        end)
    end
end)

-- 5. MOVEMENT ENHANCEMENTS & NOCLIP ENGINE
RunService.Stepped:Connect(function()
    if not isAlive() then return end
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        -- Speed
        if Config.SpeedMultiplierEnabled then
            hum.WalkSpeed = Config.WalkSpeed or 28
        end

        -- Jump
        if Config.JumpBooster then
            hum.JumpHeight = Config.JumpHeight or 70
        end

        -- NoClip
        if Config.NoClip or Config.MasterAutoFarm then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end)

-- Infinite Jump Listener
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump and isAlive() then
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end)

-- 6. ANTI-AFK ENGINE
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

-- Welcome Notification
local playerName = (LocalPlayer and (LocalPlayer.DisplayName or LocalPlayer.Name)) or "Wizard"
pcall(function()
    WindUI:Notify({
        Title = "Song Hub | Era dos Grimórios 📖",
        Content = "Welcome " .. playerName .. "!\nGrimoire Automation Engine ready.",
        Duration = 4,
        Icon = "book-open"
    })
end)

print("[Era dos Grimórios Hub] ✨ Successfully loaded [BETA] Era dos Grimórios Automation Hub!")
