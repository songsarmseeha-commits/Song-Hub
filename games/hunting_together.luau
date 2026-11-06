-- [[ 
--   ======================================================================
--   🎃 [HALLOWEEN] Hunting Together - Complete All-in-One Auto Automation Hub
--   Author: Universal Community Edition (Supports All Players & Classes)
--   UI Framework: WindUI
--   Features:
--     - 🛡️ Auto Equip Best Weapon, Armor, Accessories (@best) & Best Cards
--     - ⚡ Smart Auto Use Skills (Active Combos + Buffs + Auto Skill Learner)
--     - 📜 Auto Quests & Auto Claim All Rewards (Daily, Achievements, Quests)
--     - 🔨 Auto Refine Weapon (Blacksmith Upgrade)
--     - 💰 Smart Auto Sell Items & Gear with Selectable Tiers / Rarities
--     - 🐾 Auto Pet Action & Maintenance
--     - 🧲 Advanced Auto Loot & Drop Vacuum (Teleport Proximity + Touch Bypass)
--     - 🎁 Auto Open LootBox & Chests
--     - 📈 Auto Level 1 to 99 Progression (Auto Warps to optimal Fields)
--     - ⚔️ Auto Farm Nearest + Multi-Target Kill Aura
--     - 🎯 Auto Allocate Stats (Preset Builds: Thief, Swordsman, Mage, etc.)
--     - 🧪 Auto Potion HP/SP + Auto Respawn & Return to Farm
--     - 🛡️ 100% Absolute Auto Dodge System (Full-Duration Hazard Stay-Out, Real-Time Behind Lock & Altitude Evasion)
--     - 🎃 Auto Halloween Event (Trick-or-Treat Knock, Crystal Gacha, Pumpkin Hunter & Box Vacuum)
--     - 🎥 Streamer Mode (Real-Time Name Masking, Overhead Hider & UI Spoofer)
--     - 🏃 Infinite Stamina & Speed Booster
--     - 💾 Save Config, Auto Load & Auto Execute across Teleports
--     - ⌨️ Fold / Minimize Window Hotkey (Default: RightControl)
--     - 🛡️ Anti-AFK (20-Min Kick Prevention) & Fast Mode (FPS Boost)
--   ======================================================================
-- ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 5)

-- Safe remote getter that never blocks indefinitely
local function getRemote(name, timeout)
    if not Remotes then
        Remotes = ReplicatedStorage:FindFirstChild("Remotes")
    end
    if not Remotes then return nil end
    local r = Remotes:FindFirstChild(name)
    if not r and (timeout or 0) > 0 then
        pcall(function()
            r = Remotes:WaitForChild(name, timeout)
        end)
    end
    return r
end

-- Lazy Remote cache table to conserve top-level local registers
local RemotesLazy = setmetatable({}, {
    __index = function(self, key)
        local r = getRemote(key)
        if r then
            rawset(self, key, r)
        end
        return r
    end
})

-- Core Remotes
local SetTarget = getRemote("SetTarget")
local AttackAnim = getRemote("AttackAnim")
local AttackAnimU = getRemote("AttackAnimU")
local UseSkill = getRemote("UseSkill")
local LearnSkill = getRemote("LearnSkill")
local SetAutoSkill = getRemote("SetAutoSkill")
local AllocateStat = getRemote("AllocateStat")
local UseItem = getRemote("UseItem")
local PickupDrop = getRemote("PickupDrop")
local DungeonAction = getRemote("DungeonAction")
local DungeonPrompt = getRemote("DungeonPrompt")
local PartyAction = getRemote("PartyAction")
local PartyInvite = getRemote("PartyInvite")

-- Graceful thread termination & instance cleanup
local currentRunId = (getgenv and getgenv()._HT_ScriptRunId or 0) + 1
if getgenv then
    local now = os.clock()
    -- 1. If script is already running healthy with its window active, skip duplicate execution!
    if getgenv()._HuntingTogetherRunning == true and getgenv()._HT_CurrentWindow and (now - (getgenv()._HT_LastStartTime or 0)) < 8 then
        print("[Hunting Together] 🛡️ Script is already running with active UI. Skipping duplicate startup.")
        return
    end
    -- 2. If another thread launched less than 5 seconds ago, block this thread to prevent UI flicker / open-close loop!
    if getgenv()._HT_LastStartTime and (now - getgenv()._HT_LastStartTime) < 5 then
        print("[Hunting Together] ⚠️ Duplicate startup blocked (launched " .. string.format("%.1f", now - getgenv()._HT_LastStartTime) .. "s ago).")
        return
    end
    getgenv()._HT_LastStartTime = now

    getgenv()._HT_ScriptRunId = currentRunId
    getgenv()._HuntingTogetherRunning = false
    if getgenv()._HT_Connections then
        for _, conn in ipairs(getgenv()._HT_Connections) do
            pcall(function() conn:Disconnect() end)
        end
    end
    getgenv()._HT_Connections = {}
    task.wait(0.05)
    getgenv()._HuntingTogetherRunning = true
end

local function trackConn(conn)
    if getgenv and getgenv()._HT_Connections and conn then
        table.insert(getgenv()._HT_Connections, conn)
    end
    return conn
end

local function isScriptAlive()
    if getgenv and getgenv()._HT_ScriptRunId and getgenv()._HT_ScriptRunId ~= currentRunId then
        return false
    end
    return true
end

pcall(function()
    if getgenv then
        if getgenv()._HT_CurrentWindow then
            pcall(function() getgenv()._HT_CurrentWindow:Destroy() end)
            getgenv()._HT_CurrentWindow = nil
        end
        if getgenv()._HT_WindUI then
            pcall(function()
                if getgenv()._HT_WindUI.ScreenGui then getgenv()._HT_WindUI.ScreenGui:Destroy() end
                if getgenv()._HT_WindUI.NotificationGui then getgenv()._HT_WindUI.NotificationGui:Destroy() end
                if getgenv()._HT_WindUI.DropdownGui then getgenv()._HT_WindUI.DropdownGui:Destroy() end
                if getgenv()._HT_WindUI.TooltipGui then getgenv()._HT_WindUI.TooltipGui:Destroy() end
            end)
            getgenv()._HT_WindUI = nil
        end
    end

    local containers = {}
    pcall(function() if gethui then table.insert(containers, gethui()) end end)
    pcall(function()
        local cg = game:GetService("CoreGui")
        table.insert(containers, cg)
        local rg = cg:FindFirstChild("RobloxGui")
        if rg then table.insert(containers, rg) end
    end)
    pcall(function()
        if LocalPlayer then
            local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            if pg then table.insert(containers, pg) end
        end
    end)
    pcall(function() table.insert(containers, game:GetService("StarterGui")) end)

    for _, c in ipairs(containers) do
        if c then
            pcall(function()
                for _, child in ipairs(c:GetChildren()) do
                    pcall(function()
                        if child:IsA("ScreenGui") then
                            local n = child.Name:lower()
                            if n:find("windui") or n:find("huntingtogether") or n:find("hunting") then
                                child:Destroy()
                            end
                        end
                    end)
                end
            end)
        end
    end
end)

-- Forward declarations for scope stability across functions
local WindUI = nil
local Config = nil
local performAutoLoot = nil
local currentCombatTarget = nil
local currentDungeonPillar = nil
local activeBossFight = nil
local isReturningFromBoss = false
local isCheckingBossArena = false
local outOfZoneTicks = 0
local isLooting = false
local isOpeningBox = false
local isKnockingHouse = false
local isPullingGacha = false
local getMonsterCombatPart = nil
local getMonsterList = nil
local getBossList = nil
local trackBossDeath = nil
local currentSafeHoldTarget = nil
local safeHoldUntil = 0
local safeHoldReason = ""
local isDodgingUntil = 0
local monsterDropdown = nil
local bossDropdown = nil
local autoFarmToggle = nil
local autoProgressionToggle = nil
local autoDungeonToggle = nil
local skillsDropdown = nil
local isWarpingZone = false
local isSelling = false
local lastBoxScanTime = 0
local isEnteringDungeon = false
local isOpeningDungeonChest = false
local isWaitingForParty = false
local forceStartDungeonFlag = false
local lastDungeonEnterAttempt = 0
local lastDungeonReviveTime = 0
local lastSealNotifyTime = 0
local dungeonChestsClaimed = 0

local function isInsideDungeon()
    local placeRole = workspace:GetAttribute("PlaceRole")
    if placeRole == "Dungeon" then return true end
    local pId = game.PlaceId
    if pId == 100618538481971 or pId == 91627865222791 then return true end
    return false
end

-- Centralized helper to completely stop combat, drop targets, reset velocity, and disengage native bot
local function stopCombatAndTargeting()
    currentCombatTarget = nil
    pcall(function()
        local ct = LocalPlayer:FindFirstChild("CurrentTarget")
        if ct and ct:IsA("ObjectValue") then
            ct.Value = nil
        end
        local lTarget = LocalPlayer:FindFirstChild("LumiLockTarget")
        if lTarget and lTarget:IsA("BindableEvent") then
            lTarget:Fire(nil)
        end
        if SetTarget then
            SetTarget:FireServer(nil)
        end
        local BotAutoState = getRemote("BotAutoState")
        if BotAutoState then
            BotAutoState:FireServer(false)
        end
        local SetAutoSkillRemote = getRemote("SetAutoSkill")
        if SetAutoSkillRemote then
            SetAutoSkillRemote:FireServer(false)
        end
        local LumiMenuToggle = LocalPlayer:FindFirstChild("LumiMenuToggle")
        if LocalPlayer:GetAttribute("AutoOn") == true and LumiMenuToggle and LumiMenuToggle:IsA("BindableEvent") then
            LumiMenuToggle:Fire("autoToggle")
        end
        LocalPlayer:SetAttribute("AutoOn", false)
        LocalPlayer:SetAttribute("TargetLocked", false)
    end)

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum:Move(Vector3.zero, false) end)
    end
    if hrp then
        hrp.Velocity = Vector3.zero
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
    currentSafeHoldTarget = nil
    safeHoldUntil = 0
    isDodgingUntil = 0
    activeBossFight = nil
    isOpeningDungeonChest = false
    currentDungeonPillar = nil
    isCheckingBossArena = false
    isWarpingZone = false
    isReturningFromBoss = false
    isSelling = false
    isOpeningBox = false
    isLooting = false
    outOfZoneTicks = 0
end

-- Safe helper to manage target attributes & ObjectValue without crashing
local function setClientCurrentTarget(tgt)
    pcall(function()
        local ct = LocalPlayer:FindFirstChild("CurrentTarget")
        if ct and ct:IsA("ObjectValue") then
            ct.Value = tgt
        end
        LocalPlayer:SetAttribute("TargetLocked", tgt ~= nil)
        if tgt ~= nil then
            LocalPlayer:SetAttribute("AutoOn", true)
            LocalPlayer:SetAttribute("BotUseSkills", false)
        else
            if not Config.AutoFarm and not (Config.AutoDungeon and isInsideDungeon()) then
                LocalPlayer:SetAttribute("AutoOn", false)
                local LumiMenuToggle = LocalPlayer:FindFirstChild("LumiMenuToggle")
                if LumiMenuToggle and LumiMenuToggle:IsA("BindableEvent") and LocalPlayer:GetAttribute("AutoOn") == true then
                    LumiMenuToggle:Fire("autoToggle")
                end
            end
        end
    end)
end

local travelToZone = nil
local getPlayerLevel = nil
local isMonsterAlive = nil
local isBossMonster = nil

isMonsterAlive = function(monster)
    if not monster or not monster.Parent then return false end
    if monster:GetAttribute("IsDummy") == true then return false end
    if monster:GetAttribute("Dead") == true or monster:GetAttribute("IsDead") == true or monster:GetAttribute("Dying") == true or monster:GetAttribute("dead") == true or monster:GetAttribute("isDead") == true then
        return false
    end
    -- If monster has an invulnerable seal barrier (e.g. Skull King during Seal Phase), drop target immediately
    if monster:GetAttribute("SealShield") == true then
        return false
    end
    local hpAttr = monster:GetAttribute("HP") or monster:GetAttribute("Hp") or monster:GetAttribute("Health") or monster:GetAttribute("health") or monster:GetAttribute("hp")
    if hpAttr ~= nil and tonumber(hpAttr) and tonumber(hpAttr) <= 0 then
        return false
    end
    local hum = monster:FindFirstChildOfClass("Humanoid")
    if hum then
        if hum.Health <= 0 then return false end
        local isDeadState = false
        pcall(function()
            if hum:GetState() == Enum.HumanoidStateType.Dead then
                isDeadState = true
            end
        end)
        if isDeadState then return false end
    end
    local mHrp = monster:FindFirstChild("HumanoidRootPart")
        or monster.PrimaryPart
        or monster:FindFirstChild("Base")
        or monster:FindFirstChild("Shaft")
        or monster:FindFirstChildOfClass("BasePart")
    return mHrp ~= nil
end

getMonsterCombatPart = function(monster)
    if not monster then return nil end
    return monster:FindFirstChild("HumanoidRootPart")
        or monster.PrimaryPart
        or monster:FindFirstChild("Base")
        or monster:FindFirstChild("Shaft")
        or monster:FindFirstChildOfClass("BasePart")
end

isBossMonster = function(monster)
    if not monster or not monster.Parent then return false end
    if monster:GetAttribute("IsBoss") == true then return true end
    if monster:GetAttribute("IsMiniBoss") == true then return true end
    if monster:GetAttribute("IsLeader") == true then return true end
    local name = monster.Name:lower()
    if name:find("boss") or name:find("king") or name:find("leader") or name:find("colossus") or name:find("pharaoh") or name:find("behemoth") or name:find("spider") or name:find("dragon") then
        return true
    end
    return false
end

getPlayerLevel = function()
    local lv = nil
    pcall(function()
        lv = LocalPlayer:GetAttribute("Level") or LocalPlayer:GetAttribute("Lv")
        if not lv then
            local ls = LocalPlayer:FindFirstChild("leaderstats")
            if ls then
                local lvVal = ls:FindFirstChild("Level") or ls:FindFirstChild("Lv")
                if lvVal and lvVal.Value then
                    lv = lvVal.Value
                end
            end
        end
        if not lv and LocalPlayer.Character then
            local head = LocalPlayer.Character:FindFirstChild("Head")
            if head then
                local tag = head:FindFirstChild("LevelTag") or head:FindFirstChild("NameTag")
                if tag then
                    local txt = tag:FindFirstChildOfClass("TextLabel")
                    if txt and txt.Text:find("Lv%.%s*(%d+)") then
                        lv = tonumber(txt.Text:match("Lv%.%s*(%d+)"))
                    end
                end
            end
        end
    end)
    return tonumber(lv) or 1
end

-- Remotes moved to RemotesLazy to conserve top-level registers

-- Shared Modules
local Shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 3)
local SkillDataModule = nil
local GearUtilModule = nil
local ItemDataModule = nil
local MonsterAnimModule = nil
if Shared then
    pcall(function() SkillDataModule = require(Shared:WaitForChild("SkillData", 2)) end)
    pcall(function() GearUtilModule = require(Shared:WaitForChild("GearUtil", 2)) end)
    pcall(function() ItemDataModule = require(Shared:WaitForChild("ItemData", 2)) end)
    pcall(function() MonsterAnimModule = require(Shared:WaitForChild("MonsterAnim", 2)) end)
end

-- ==================== CONFIGURATION SYSTEM ====================
local CONFIG_FILE = "HuntingTogether_Config_" .. tostring(LocalPlayer.UserId) .. ".json"

Config = {
    -- Window & Controls
    ToggleKey = "RightControl",
    AutoSave = true,
    AutoExecuteOnTeleport = true,

    -- Auto Farm & Boss Hunter (ปิดทั้งหมดเป็นค่าเริ่มต้น)
    AutoFarm = false,
    FarmMode = "Warp",            -- "Fly" (โหมดบินลอยตัว) or "Walk" (โหมดเดินปกติบนพื้น)
    WalkFarmSpeed = 26,          -- ความเร็วในการเดินฟาร์มเมื่ออยู่ในโหมดเดินปกติ (Walk Mode)
    SafeFarm = false,
    SafeFarmExploit = false,      -- ช่องโหว่มุมอับสายตา & ระยะปลอดภัย
    SafeFarmHeight = 5.5,        -- ความสูงลอยเหนือหัวมอนสเตอร์
    AdaptiveDistance = false,     -- ปรับระยะห่างตามอาวุธ
    FarmDistance = 14.0,         -- ค่าตั้งต้นระยะฟาร์ม
    AttackDelay = 0.08,
    SelectedMonster = "All",
    AutoBoss = false,            -- Automatically hunt Bosses & Mini-Bosses (ปิดไว้เป็นค่าเริ่มต้น)
    AutoWarpToBoss = false,     -- Automatically warp to World Boss Arenas (ปิดไว้เป็นค่าเริ่มต้น)
    PrioritizeBoss = false,      -- Attack Boss first when present (ปิดไว้เป็นค่าเริ่มต้น)
    BossOnly = false,           -- Farm ONLY Bosses and Mini-Bosses
    SelectedBoss = "All Bosses",-- Specific Boss or "All Bosses"
    ReturnToProgressionAfterBoss = false, -- ตีบอสเสร็จกลับไปฟาร์มตาม Auto Lv.99 ทันที
    BossCheckInterval = 75,     -- Seconds between periodic Boss Arena inspections
    KillAura = false,
    KillAuraRadius = 20,
    MaxTargetDistance = 70,     -- Keep search strictly within active field
    AutoUseSkills = false,       -- ปิดไว้เป็นค่าเริ่มต้น
    AutoUseBuffs = false,        -- ปิดไว้เป็นค่าเริ่มต้น
    SelectedSkillSlots = { "ช่อง 1 (Slot 1)", "ช่อง 2 (Slot 2)", "ช่อง 3 (Slot 3)", "ช่อง 4 (Slot 4)", "ช่อง 5 (Slot 5)", "ช่อง 6 (Slot 6)", "ช่อง 7 (Slot 7)" },
    ServerHopAuto = false,
    ServerHopInterval = 15, -- minutes
    
    -- Auto Equip & Gear (ปิดทั้งหมดเป็นค่าเริ่มต้น)
    AutoEquipBest = false,
    AutoEquipBestWeapon = false,
    AutoEquipCards = false,
    AutoRefine = false,
    
    -- Auto Sell System (ปิดทั้งหมดเป็นค่าเริ่มต้น)
    AutoSell = false,
    AutoSellOnFull = false,
    AutoSellPeriodic = false,
    AutoSellInterval = 120,
    AutoSellQuickVisit = false,
    SellTier1 = false,
    SellTier2 = false,
    SellTier3 = false,
    SellTier4 = false,
    SellTier5 = false,
    MaxSellTier = "Up to Tier 3",
    MaxSellRarity = "Up to Rare",
    SellRarities = {
        "Common (ธรรมดา / ขาว)",
        "Uncommon (ไม่ธรรมดา / เขียว)",
        "Rare (หายาก / ฟ้า)",
    },
    SellWeapons = false,
    SellArmors = false,
    SellAccessories = false,
    SellJunkDrops = false,
    ProtectRefined = true,
    ProtectBestGear = true,
    
    -- Auto Loot (ปิดทั้งหมดเป็นค่าเริ่มต้น)
    AutoLoot = false,
    LootPriority = false,
    StealthMagnetLoot = false,
    LootTeleport = false,
    LootRadius = 120,
    AutoOpenLootBox = false,
    
    -- Level Progression (1 - 99)
    AutoProgression = false,
    CurrentZone = "",
    
    -- Auto Stats & Skills (ปิดทั้งหมดเป็นค่าเริ่มต้น)
    AutoUpgradeSkills = false,
    AutoAllocateStats = false,
    StatPreset = "Auto (Detect by Job)",
    
    -- Rewards & Quests (ปิดทั้งหมดเป็นค่าเริ่มต้น)
    AutoClaimQuests = false,
    AutoClaimDaily = false,
    AutoClaimAchieve = false,
    AutoPet = false,
    
    -- Survival & Potions (ปิดทั้งหมดเป็นค่าเริ่มต้น)
    AutoHpPotion = false,
    HpThreshold = 55,
    AutoSpPotion = false,
    SpThreshold = 30,
    AutoRespawn = false,
    
    -- Auto Dodge & Evasion (ปิดทั้งหมดเป็นค่าเริ่มต้น)
    AutoDodge = false,
    DodgeBossTelegraph = false,
    DodgeGreenCircle = false,
    DodgeProjectiles = false,
    DodgeMonsterAttack = false,
    DodgeMonsterSkill = false,
    DodgeOnHurt = false,
    DodgeFlank = false,
    DodgeDistance = 18,
    DodgeCooldown = 0.25,
    DodgeDuration = 0.45,
    DodgeNotify = false,
    
    -- 🎃 Halloween Event Automation (ปิดทั้งหมดเป็นค่าเริ่มต้น)
    AutoHalloween = false,
    AutoTrickTreat = false,
    TrickTreatThreshold = 100,
    TrickTreatAutoVisit = false,
    AutoHalloweenGacha = false,
    GachaPullType = "10x Pull (100 Heads)",
    HuntHalloweenPumpkins = false,
    AutoHalloweenBoxes = false,
    AutoClaimEventRewards = false,
    
    -- 🏰 Dungeon Automation (ปิดทั้งหมดเป็นค่าเริ่มต้น)
    AutoDungeon = false,
    SelectedDungeon = "halloween",
    DungeonDifficulty = "easy",
    DungeonForceSolo = false,
    
    -- 👥 Dungeon Party & Matchmaking (ปิดทั้งหมดเป็นค่าเริ่มต้น)
    DungeonPartyMode = "Solo",
    PartyTargetMembers = 2,
    PartyWaitTimeout = 30,
    PartyInviteTarget = "All Server",
    PartyAutoInvite = false,
    AutoAcceptParty = false,
    PartyAcceptFilter = "Anyone",
    PartyWhitelistUsers = "",
    
    AutoBuyDungeonKey = false,
    MaxDungeonKeysToBuy = 10,
    AutoReadyDungeon = false,
    AutoReviveTeammates = false,
    PrioritizeDungeonPillars = false,
    AutoKickSkulls = false,
    PrioritizeDungeonBoss = false,
    AutoClaimExitChest = false,
    AutoSecretChests = false,
    AutoLeaveOnClear = false,
    AutoRepeatDungeon = false,
    AutoConfirmReplay = true,
    AutoBuyDungeonKey = true,
    ReturnToFarmAfterDungeon = false,
    DungeonSafeHeight = 5.2,
    DungeonAttackDelay = 0.08,

    -- 🎥 Streamer Mode (โหมดสตรีมเมอร์ & ปกปิดชื่อ)
    StreamerMode = false,
    StreamerFakeName = "Protected Player",
    HideOverheadName = false,
    SpoofUIAndLeaderboard = false,
    HideOthersNames = false,

    -- 🎨 UI Dungeon Theme & Animated Background
    UITheme = "🎃 Skull King's Crypt (สุสานราชาโครงกระดูก)",
    UIBackgroundAnimation = true,
    UIAnimationStyle = "Auto (ตามธีมดันเจี้ยน)",
    UIAnimationSpeed = 10,
    UIGlassTransparency = 28,

    -- Misc & Performance (ปิดทั้งหมดเป็นค่าเริ่มต้น)
    InfiniteStamina = false,
    AntiAFK = false,
    FastMode = false,
}

local function canScriptMoveOrWarp()
    if not isScriptAlive() then return false end
    -- Dungeon entry, room creation, and party waiting take absolute priority: block all background tasks from moving or warping
    if isEnteringDungeon or isWaitingForParty then return false end
    if isInsideDungeon() then
        return Config.AutoDungeon == true
    else
        return (Config.AutoFarm == true) or (Config.AutoProgression == true) or (Config.AutoDungeon == true)
    end
end

local function SaveConfig(silent)
    pcall(function()
        if writefile then
            local json = HttpService:JSONEncode(Config)
            writefile(CONFIG_FILE, json)
            if not silent and WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "Config Saved",
                    Content = "บันทึกการตั้งค่าสำเร็จ!",
                    Duration = 2,
                    Icon = "save",
                })
            end
        end
    end)
end

local function LoadConfig(silent)
    local success = false
    pcall(function()
        local fileToRead = nil
        if isfile and isfile(CONFIG_FILE) then
            fileToRead = CONFIG_FILE
        elseif isfile and isfile("HuntingTogether_Config.json") then
            fileToRead = "HuntingTogether_Config.json"
        end

        if fileToRead and readfile then
            local raw = readfile(fileToRead)
            local decoded = HttpService:JSONDecode(raw)
            if type(decoded) == "table" then
                for k, v in pairs(decoded) do
                    Config[k] = v
                end
                -- Force disable character teleport looting even if old config had it enabled
                Config.LootTeleport = false
                if Config.StealthMagnetLoot == nil then
                    Config.StealthMagnetLoot = true
                end
                if Config.SellRarities == nil then
                    if Config.MaxSellRarity == "Common Only" then
                        Config.SellRarities = { "Common (ธรรมดา / ขาว)" }
                    elseif Config.MaxSellRarity == "Up to Uncommon" then
                        Config.SellRarities = { "Common (ธรรมดา / ขาว)", "Uncommon (ไม่ธรรมดา / เขียว)" }
                    elseif Config.MaxSellRarity == "Up to Rare" then
                        Config.SellRarities = { "Common (ธรรมดา / ขาว)", "Uncommon (ไม่ธรรมดา / เขียว)", "Rare (หายาก / ฟ้า)" }
                    elseif Config.MaxSellRarity == "All Rarities" then
                        Config.SellRarities = {
                            "Common (ธรรมดา / ขาว)",
                            "Uncommon (ไม่ธรรมดา / เขียว)",
                            "Rare (หายาก / ฟ้า)",
                            "Epic (มหากาพย์ / ม่วง)",
                            "Legendary (ตำนาน / ทอง)",
                            "Mythic (เทพเจ้า / แดง)",
                        }
                    else
                        Config.SellRarities = { "Common (ธรรมดา / ขาว)", "Uncommon (ไม่ธรรมดา / เขียว)", "Rare (หายาก / ฟ้า)" }
                    end
                end
                success = true
                if not silent and WindUI and WindUI.Notify then
                    WindUI:Notify({
                        Title = "Config Loaded",
                        Content = "โหลดการตั้งค่าอัตโนมัติสำเร็จแล้ว!",
                        Duration = 2,
                        Icon = "folder-check",
                    })
                end
            end
        end
    end)
    return success
end

LoadConfig(true)
_G.HT_Config = Config
if getgenv then getgenv().HT_Config = Config end

-- ==================== AUTO EXECUTE ON TELEPORT ====================
local hasRegisteredQueue = false
local function registerQueueOnTeleport()
    if not Config.AutoExecuteOnTeleport then return end
    if hasRegisteredQueue then return end -- Guard: Only queue once per game session to prevent multiple executions
    local queue = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if queue then
        hasRegisteredQueue = true
        local execCode = [[
            task.wait(2.0)
            if getgenv and (getgenv()._HuntingTogetherRunning or getgenv()._UniversalLoaderLoading) then
                return
            end
            local cb = tostring(os.time()) .. "_" .. tostring(math.random(100, 999))
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
            if isfile and isfile("hunting_together_script.lua") and readfile then
                loadstring(readfile("hunting_together_script.lua"))()
            end
        ]]
        pcall(queue, execCode)
    end
end

pcall(registerQueueOnTeleport)

if LocalPlayer.OnTeleport then
    trackConn(LocalPlayer.OnTeleport:Connect(function(state)
        pcall(registerQueueOnTeleport)
    end))
end

-- ==================== LEVEL BRACKET ZONES & COORDINATES ====================
local LevelZones = {
    { Min = 1,  Max = 8,  Field = "Field01", Name = "Rabbit Field (Lv.1-8)" },
    { Min = 9,  Max = 16, Field = "Field02", Name = "Boar Forest (Lv.9-16)" },
    { Min = 17, Max = 25, Field = "Field03", Name = "Bear Forest (Lv.17-25)" },
    { Min = 26, Max = 33, Field = "Field04", Name = "Hyena Den (Lv.26-33)" },
    { Min = 34, Max = 41, Field = "Field05", Name = "Rhino Thicket (Lv.34-41)" },
    { Min = 42, Max = 50, Field = "Field06", Name = "Tiger Thicket (Lv.42-50)" },
    { Min = 51, Max = 58, Field = "Field07", Name = "Scorpion Dunes (Lv.51-58)" },
    { Min = 59, Max = 66, Field = "Field08", Name = "Ram Cliffs (Lv.59-66)" },
    { Min = 67, Max = 75, Field = "Field09", Name = "Stone Golem Valley (Lv.67-75)" },
    { Min = 76, Max = 83, Field = "Field10", Name = "Polar Bear Plain (Lv.76-83)" },
    { Min = 84, Max = 91, Field = "Field11", Name = "Snow Wolf Forest (Lv.84-91)" },
    { Min = 92, Max = 98, Field = "Field12", Name = "Ice Golem Peak (Lv.92-98)" },
    { Min = 99, Max = 999, Field = "Field13", Name = "Lava Turtle Hill (Lv.99 MAX)" },
}

local ZoneCoordinates = {
    Field01 = Vector3.new(0, 5, -203),
    Field02 = Vector3.new(0, 33, -459),
    Field03 = Vector3.new(0, 61, -715),
    Boss01  = Vector3.new(0, 61, -906),
    Field04 = Vector3.new(0, 62, -1097),
    Field05 = Vector3.new(0, 90, -1353),
    Field06 = Vector3.new(0, 118, -1609),
    Boss02  = Vector3.new(0, 118, -1800),
    Field07 = Vector3.new(0, 118, -1991),
    Field08 = Vector3.new(0, 146, -2247),
    Field09 = Vector3.new(0, 174, -2503),
    Boss03  = Vector3.new(0, 174, -2694),
    Field10 = Vector3.new(0, 174, -2885),
    Field11 = Vector3.new(0, 202, -3141),
    Field12 = Vector3.new(0, 230, -3397),
    Boss04  = Vector3.new(0, 230, -3588),
    Field13 = Vector3.new(0, 230, -3779),
    Field14 = Vector3.new(0, 258, -4035),
    Field15     = Vector3.new(0, 286, -4291),
    Boss05      = Vector3.new(0, 286, -4482),
    Town        = Vector3.new(0, 5, 0),
    Village     = Vector3.new(0, 5, 0),
    DungeonGate = Vector3.new(4.8, 5.0, 112.5),
}

local lastNormalFarmZone = "Field01"
local bossReturnTimeout = 0

-- ==================== DUNGEON AUTOMATION HELPER FUNCTIONS ====================
isInsideDungeon = function()
    local placeRole = workspace:GetAttribute("PlaceRole")
    if placeRole == "Dungeon" then return true end
    local pId = game.PlaceId
    if pId == 100618538481971 or pId == 91627865222791 then return true end
    return false
end

local function getDungeonState()
    return tostring(workspace:GetAttribute("DungeonState") or "none")
end

local function getDungeonKeys()
    local itemsJsonRaw = LocalPlayer:GetAttribute("ItemsJson") or "{}"
    local count = 0
    pcall(function()
        local items = HttpService:JSONDecode(itemsJsonRaw)
        count = tonumber(items.dungeon_key) or 0
    end)
    return count
end

local function getPlayerSilver()
    return tonumber(LocalPlayer:GetAttribute("Silver")) or 0
end

local function isDungeonDowned()
    return LocalPlayer:GetAttribute("DungeonDowned") == true
end

local currentDungeonWpIndex = 2
local lastSecretChestClaimTime = 0

local DungeonPathWaypoints = {
    -- Section 1: Entrance Corridor -> Plaza
    Vector3.new(-3838, 60.5, 288),  -- 1. Entrance / Start
    Vector3.new(-3842, 60.5, 250),  -- 2. Entrance Corridor 1
    Vector3.new(-3842, 60.5, 214),  -- 3. Pack 1
    Vector3.new(-3842, 60.5, 180),  -- 4. Entrance Corridor 2
    Vector3.new(-3842, 60.5, 150),  -- 5. Pack 2
    Vector3.new(-3842, 60.5, 118),  -- 6. Ambush 1
    Vector3.new(-3842, 60.5, 86),   -- 7. Pack 3
    Vector3.new(-3842, 60.5, 52),   -- 8. Entrance Corridor 3
    Vector3.new(-3842, 60.5, 18),   -- 9. Pack 4
    Vector3.new(-3842, 60.5, -20),  -- 10. Corner T-Junction Open Doorway
    Vector3.new(-3870, 60.5, -20),  -- 11. Plaza Approach 1
    Vector3.new(-3890, 60.5, -20),  -- 12. Turn towards Plaza (Pack)
    Vector3.new(-3940, 60.5, -20),  -- 13. Plaza Approach 2
    Vector3.new(-3994, 60.5, -20),  -- 14. Plaza Center (Ritual Pillars Zone)

    -- Section 2: Plaza -> Witch Lair
    Vector3.new(-4040, 60.5, -20),  -- 15. Witch Corridor 1
    Vector3.new(-4078, 60.5, -20),  -- 16. Witch Corridor 2
    Vector3.new(-4098, 60.5, -20),  -- 17. Witch Ambush
    Vector3.new(-4118, 60.5, -20),  -- 18. Witch Corridor 3
    Vector3.new(-4158, 60.5, -20),  -- 19. Witch Corridor 4
    Vector3.new(-4195, 60.5, -20),  -- 20. Witch Approach
    Vector3.new(-4226, 60.5, -20),  -- 21. Witch Lair Center (Boss Spot / Witch)

    -- Section 3: Witch Lair -> South Doorway -> South Corridor
    Vector3.new(-4226, 60.5, -42),  -- 22. Witch Room South Exit Approach
    Vector3.new(-4226, 60.5, -66),  -- 23. Witch Doorway (SealWitch Gateway)
    Vector3.new(-4226, 60.5, -90),  -- 24. South Corridor Entry
    Vector3.new(-4226, 60.5, -112), -- 25. South Corridor Pack 1
    Vector3.new(-4226, 60.5, -148), -- 26. South Corridor Ambush
    Vector3.new(-4226, 60.5, -184), -- 27. South Corridor Pack 2
    Vector3.new(-4226, 60.5, -220), -- 28. South Corridor 3
    Vector3.new(-4226, 60.5, -260), -- 29. Corner T-Junction (Turn East towards Boss Arena)

    -- Section 4: East Corridor -> Skull King Boss Arena
    Vector3.new(-4195, 60.5, -260), -- 30. East Corridor 1
    Vector3.new(-4168, 60.5, -260), -- 31. East Turn Pack
    Vector3.new(-4138, 60.5, -260), -- 32. East Ambush
    Vector3.new(-4090, 62.0, -260), -- 33. Arena Ramp 1
    Vector3.new(-4050, 65.0, -260), -- 34. Arena Ramp 2
    Vector3.new(-4010, 68.0, -260), -- 35. Boss Arena Gate
    Vector3.new(-3966, 71.0, -260), -- 36. Skull King Boss Spot
    Vector3.new(-4038, 71.0, -260), -- 37. Exit Chest Spot
}

local function getNearestDungeonWaypoint(pos)
    local bestWp = nil
    local bestDist = math.huge
    local bestIdx = 1
    for i, wp in ipairs(DungeonPathWaypoints) do
        local d = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(wp.X, 0, wp.Z)).Magnitude
        if d < bestDist then
            bestDist = d
            bestWp = wp
            bestIdx = i
        end
    end
    return bestWp, bestDist, bestIdx
end

local function getDungeonWallInstances()
    local walls = {}
    local h = workspace:FindFirstChild("Halloween")
    if h then
        for _, name in ipairs({ "Wall", "Blockers", "Cave", "Barriers", "Throne", "Decor" }) do
            local item = h:FindFirstChild(name)
            if item then table.insert(walls, item) end
        end
        local bDoor = h:FindFirstChild("BossDoor")
        if bDoor then
            local slab = bDoor:FindFirstChild("Slab")
            if slab and slab.CanCollide then
                table.insert(walls, bDoor)
            end
        end
    end
    -- Also include all objects tagged DungeonLosWall by the native game engine
    local CollectionService = game:GetService("CollectionService")
    for _, item in ipairs(CollectionService:GetTagged("DungeonLosWall")) do
        table.insert(walls, item)
    end
    -- Also look for any map folder with barriers or obstacles
    local map = workspace:FindFirstChild("Map")
    if map then
        local b = map:FindFirstChild("Barriers") or map:FindFirstChild("BlockFields")
        if b then table.insert(walls, b) end
    end
    return walls
end

local function hasDungeonLineOfSight(pos1, pos2)
    local wallInstances = getDungeonWallInstances()
    if #wallInstances == 0 then return true end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = wallInstances

    -- Use character eye/chest height at actual positions (never hardcoded)
    local y1 = (pos1.Y or 60) + 1.8
    local y2 = (pos2.Y or 60) + 1.8
    local p1 = Vector3.new(pos1.X, y1, pos1.Z)
    local p2 = Vector3.new(pos2.X, y2, pos2.Z)
    local dir = p2 - p1
    if dir.Magnitude < 1.0 then return true end

    local hit = workspace:Raycast(p1, dir, rayParams)
    return (hit == nil)
end

local function getDungeonSafeCombatPosition(targetPos, mobLook, safeDist, isRanged, isBoss, isPillar)
    local wallInstances = getDungeonWallInstances()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    -- Optimal melee combat distance in dungeon: 3.4 - 3.6 studs (or 4.8 - 5.2 for large bosses)
    local effectiveDist = isRanged and math.clamp(safeDist, 8.0, 13.0) or (isBoss and 5.0 or 3.5)

    -- Accurate ground detection excluding characters and monsters
    local floorY = targetPos.Y
    pcall(function()
        local rayParamsFloor = RaycastParams.new()
        rayParamsFloor.FilterType = Enum.RaycastFilterType.Exclude
        local ignore = { char }
        local monstersFolder = workspace:FindFirstChild("Monsters")
        if monstersFolder then table.insert(ignore, monstersFolder) end
        rayParamsFloor.FilterDescendantsInstances = ignore
        local floorRay = workspace:Raycast(Vector3.new(targetPos.X, targetPos.Y + 15.0, targetPos.Z), Vector3.new(0, -35.0, 0), rayParamsFloor)
        if floorRay and floorRay.Instance and floorRay.Instance.Name:lower():find("ceiling") == nil then
            floorY = floorRay.Position.Y + 2.8
        end
    end)

    -- If fly / warp mode (not Walk), keep slight hover
    local isWalk = (Config.FarmMode == "Walk")
    if not isWalk then
        local hover = (isBoss or isPillar) and 2.5 or 0.8
        floorY = floorY + hover
    end

    -- If no wall instances detected in game, default safely in front of monster
    if #wallInstances == 0 then
        local p = targetPos - (mobLook * effectiveDist)
        return Vector3.new(p.X, floorY, p.Z)
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = wallInstances

    -- Raycast center height at monster/player chest level
    local rayY = floorY + 1.8
    local rayOrigin = Vector3.new(targetPos.X, rayY, targetPos.Z)

    -- Direction towards the open hallway (nearest waypoint)
    local nearestWp = getNearestDungeonWaypoint(targetPos)
    local hallwayDir = nil
    if nearestWp then
        local flatHw = Vector3.new(nearestWp.X - targetPos.X, 0, nearestWp.Z - targetPos.Z)
        if flatHw.Magnitude > 0.5 then
            hallwayDir = flatHw.Unit
        end
    end

    -- Current direction from monster to player
    local toPlayer = hrp and (hrp.Position - targetPos) or -mobLook
    local flatToPlayer = Vector3.new(toPlayer.X, 0, toPlayer.Z)
    local currentDir = flatToPlayer.Magnitude > 0.5 and flatToPlayer.Unit or -mobLook

    -- Sample 12 radial directions around the monster (every 30 degrees)
    -- We want to find the direction that is completely unobstructed, has clear LOS, and has maximum clearance behind
    local bestPos = nil
    local bestScore = -math.huge

    for angleDeg = 0, 330, 30 do
        local rad = math.rad(angleDeg)
        local cosA, sinA = math.cos(rad), math.sin(rad)
        local dir = Vector3.new(cosA, 0, sinA)

        -- 1. Raycast from monster towards candidate direction up to effectiveDist + 3.5 studs
        local checkDist = effectiveDist + 3.5
        local hitWall = workspace:Raycast(rayOrigin, dir * checkDist, rayParams)
        local wallDist = hitWall and hitWall.Distance or checkDist

        -- If a wall is right next to the monster (< 2.2 studs), discard this direction
        if wallDist >= 2.2 then
            -- Maximum safe distance the player can stand along this direction without touching the wall
            -- Giving at least 1.8 studs buffer from the wall surface
            local maxAllowedDist = math.max(2.4, wallDist - 1.8)
            local standDist = math.min(effectiveDist, maxAllowedDist)

            local candPos = Vector3.new(targetPos.X + dir.X * standDist, floorY, targetPos.Z + dir.Z * standDist)
            local candRayPos = Vector3.new(candPos.X, rayY, candPos.Z)

            -- 2. Line of sight check: from candPos to targetPos
            local toTarget = rayOrigin - candRayPos
            local losHit = workspace:Raycast(candRayPos, toTarget, rayParams)

            -- Must have 100% clean line of sight (no wall between player and monster!)
            if not losHit then
                -- 3. Check clearance behind player (cast 2.5 studs behind player)
                local behindHit = workspace:Raycast(candRayPos, dir * 2.5, rayParams)
                local behindClearance = behindHit and behindHit.Distance or 2.5

                if behindClearance >= 1.0 then
                    -- Scoring:
                    -- + Clearance behind player (open room = huge bonus)
                    -- + Alignment with open hallway / waypoint (hallwayDir)
                    -- + Alignment with player's current direction (currentDir) to prevent spinning
                    local score = wallDist * 10 + behindClearance * 20
                    if hallwayDir then
                        score = score + (dir:Dot(hallwayDir) * 25)
                    end
                    if currentDir then
                        score = score + (dir:Dot(currentDir) * 15)
                    end

                    if score > bestScore then
                        bestScore = score
                        bestPos = candPos
                    end
                end
            end
        end
    end

    if bestPos then
        return bestPos
    end

    -- Ultimate Fail-safe: Stand between monster and the nearest dungeon hallway waypoint!
    -- Since waypoints are always in the open center of corridors, (hallwayDir * 3.4) is GUARANTEED to be inside the room!
    if hallwayDir then
        local safeHallwayPos = Vector3.new(targetPos.X + hallwayDir.X * 3.4, floorY, targetPos.Z + hallwayDir.Z * 3.4)
        return safeHallwayPos
    end

    local fallback = targetPos - (mobLook * 3.4)
    return Vector3.new(fallback.X, floorY, fallback.Z)
end

local function getDungeonTarget()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local folder = workspace:FindFirstChild("Monsters")
    local CollectionService = game:GetService("CollectionService")

    -- Collect all potential dungeon mobs from Monsters, Halloween, Dungeon, and Workspace
    local candidateMobs = {}
    local seen = {}
    local searchRoots = {
        workspace:FindFirstChild("Monsters"),
        workspace:FindFirstChild("Halloween"),
        workspace:FindFirstChild("Dungeon"),
        workspace
    }
    for _, root in ipairs(searchRoots) do
        if root then
            for _, mob in ipairs(root:GetChildren()) do
                if mob:IsA("Model") and not seen[mob] then
                    seen[mob] = true
                    table.insert(candidateMobs, mob)
                end
            end
        end
    end
    for _, mob in ipairs(CollectionService:GetTagged("Monster")) do
        if mob:IsA("Model") and not seen[mob] then
            seen[mob] = true
            table.insert(candidateMobs, mob)
        end
    end
    for _, mob in ipairs(CollectionService:GetTagged("Boss")) do
        if mob:IsA("Model") and not seen[mob] then
            seen[mob] = true
            table.insert(candidateMobs, mob)
        end
    end

    -- Check if there are any active ritual pillars spawned in the dungeon right now
    local alivePillarCount = 0
    for _, mob in ipairs(candidateMobs) do
        if isMonsterAlive(mob) then
            local mName = mob.Name:lower()
            local mId = tostring(mob:GetAttribute("MonsterId") or "")
            if mName:find("pillar") ~= nil or mName:find("ritual") ~= nil or mName:find("seal") ~= nil or mId == "dgn_ritual_pillar" then
                alivePillarCount = alivePillarCount + 1
            end
        end
    end

    local dObjective = tostring(workspace:GetAttribute("DungeonObjective") or ""):lower()
    local isBossSealPhase = (alivePillarCount > 0) or (dObjective:find("break the seal") ~= nil or dObjective:find("seal pillar") ~= nil or dObjective:find("destroy the ritual") ~= nil)

    -- If current target has a seal barrier or is dead, drop it immediately
    if currentCombatTarget and (currentCombatTarget:GetAttribute("SealShield") == true or not isMonsterAlive(currentCombatTarget)) then
        currentCombatTarget = nil
        isBossSealPhase = true
    end

    -- Check if current target is already a pillar
    local currentIsPillar = false
    if currentCombatTarget then
        local cName = (currentCombatTarget.Name or ""):lower()
        local cId = tostring(currentCombatTarget:GetAttribute("MonsterId") or "")
        currentIsPillar = (cName:find("pillar") ~= nil or cName:find("ritual") ~= nil or cName:find("seal") ~= nil or cId == "dgn_ritual_pillar")
    end

    -- If any ritual pillars exist, drop any non-pillar target immediately (NEVER attack shielded boss!)
    if alivePillarCount > 0 and not currentIsPillar then
        currentCombatTarget = nil
    end

    -- Show notification when seal pillars are active
    if alivePillarCount > 0 and (os.clock() - (lastSealNotifyTime or 0)) >= 3.5 then
        lastSealNotifyTime = os.clock()
        pcall(function()
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "BREAK THE SEAL PILLARS!",
                    Content = string.format("เงื่อนไขบอส 50%%: กำลังทำลายเสาผนึก (เหลือ %d เสา)...", alivePillarCount),
                    Duration = 3.0,
                    Icon = "shield-alert"
                })
            end
        end)
    end

    -- 1. STICKINESS: If current target is alive, unshielded, and within reach, stay locked on it until dead
    -- (If alive pillars exist, stickiness only applies if current target is a pillar)
    if currentCombatTarget and isMonsterAlive(currentCombatTarget) and currentCombatTarget:GetAttribute("SealShield") ~= true then
        if (alivePillarCount == 0) or currentIsPillar then
            local tPart = getMonsterCombatPart(currentCombatTarget)
            if tPart and (hrp.Position - tPart.Position).Magnitude <= 55 then
                return currentCombatTarget
            end
        end
    end

    local bestTarget = nil
    local bestScore = -math.huge

    local dStep = tonumber(workspace:GetAttribute("DungeonStep") or (workspace:FindFirstChild("Dungeon") and workspace.Dungeon:GetAttribute("DungeonStep")))
    local dObj = tostring(workspace:GetAttribute("DungeonObjective") or (workspace:FindFirstChild("Dungeon") and workspace.Dungeon:GetAttribute("DungeonObjective")) or ""):lower()

    if not dStep or dStep <= 0 then
        -- Primary fallback: Active objective banner on screen (WaveRow)
        pcall(function()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local lumiDungeon = pg and pg:FindFirstChild("LumiDungeon")
            local waveRow = lumiDungeon and lumiDungeon:FindFirstChild("WaveRow")
            local banner = waveRow and waveRow:FindFirstChildWhichIsA("TextLabel")
            if banner and banner.Visible and banner.Text ~= "" then
                local txt = banner.Text:lower()
                if txt:find("skull king") or txt:find("defeat the boss") then
                    dStep = 4
                    dObj = "defeat the skull king"
                elseif txt:find("potion witch") or txt:find("mini boss") or txt:find("witch") then
                    dStep = 3
                    dObj = "defeat the potion witch"
                elseif txt:find("pillar") or txt:find("ritual") or txt:find("seal") then
                    dStep = 2
                    dObj = "destroy the ritual pillars"
                elseif txt:find("clear") or txt:find("monster") then
                    dStep = 1
                    dObj = "clear all monsters"
                end
            end
        end)
    end

    if not dStep or dStep <= 0 then
        if dObj:find("skull king") or dObj:find("defeat the boss") or dObj:find("boss") then
            dStep = 4
        elseif dObj:find("mini boss") or dObj:find("witch") then
            dStep = 3
        elseif dObj:find("ritual pillar") or dObj:find("destroy the pillar") or dObj:find("break the seal") then
            dStep = 2
        else
            dStep = 1
        end
    end

    local inBossArena = (hrp.Position.X >= -4100 and hrp.Position.Z <= -240)
    local inWitchLair = (hrp.Position.X <= -4150 and hrp.Position.Z >= -60 and hrp.Position.Z <= 40)
    local inPlazaOrBeyond = (hrp.Position.X < -3880)

    for _, mob in ipairs(candidateMobs) do
        if isMonsterAlive(mob) and mob:GetAttribute("SealShield") ~= true then
            local mPart = getMonsterCombatPart(mob)
            if mPart then
                local dist = (hrp.Position - mPart.Position).Magnitude
                local mName = mob.Name:lower()
                local mId = tostring(mob:GetAttribute("MonsterId") or "")
                local isPillar = (mName:find("pillar") ~= nil or mName:find("ritual") ~= nil or mName:find("seal") ~= nil or mId == "dgn_ritual_pillar")
                local isWitch = (mName:find("witch") ~= nil or mId:find("witch") ~= nil or mob:GetAttribute("IsMiniBoss") == true)
                local isBoss = (mob:GetAttribute("IsBoss") == true or mName:find("boss") or mName:find("skull king") or mName:find("crypt") or mId:find("boss") or mId:find("skull"))
                local score = 1000 - dist

                -- 1. Pillar priority: ABSOLUTE TOP PRIORITY if alive pillars exist
                if isPillar then
                    score = 1000000 - dist
                -- 2. Mini Boss (Potion Witch) priority during Step 3 or when in/near Witch Lair
                elseif isWitch and (dStep == 3 or inWitchLair or (Config.PrioritizeDungeonBoss or Config.PrioritizeBoss)) then
                    if alivePillarCount > 0 then
                        score = -1000000
                    else
                        score = 500000 - dist
                    end
                -- 3. Final Boss (Skull King) priority during Step 4 or when in Boss Arena
                elseif isBoss and (dStep >= 4 or inBossArena or (Config.PrioritizeDungeonBoss or Config.PrioritizeBoss)) then
                    if alivePillarCount > 0 then
                        score = -1000000
                    else
                        score = 500000 - dist
                    end
                -- 4. Close aggro monsters along corridor (clears corridor cleanly without wall snag)
                elseif dist <= 35 then
                    score = 30000 - dist
                elseif dist <= 75 then
                    score = 15000 - dist
                end

                -- Line of sight wall penalty: exempt pillars, witch in step 3/lair, and boss in step 4/arena
                local exemptLos = isPillar or (isWitch and (dStep == 3 or inWitchLair)) or (isBoss and (dStep >= 4 or inBossArena))
                if not exemptLos and not hasDungeonLineOfSight(hrp.Position, mPart.Position) then
                    score = score - 60000
                end

                if score > bestScore then
                    bestScore = score
                    bestTarget = mob
                end
            end
        end
    end

    currentCombatTarget = bestTarget
    if bestTarget then
        pcall(function()
            local lTarget = LocalPlayer:FindFirstChild("LumiLockTarget")
            if lTarget and lTarget:IsA("BindableEvent") then
                lTarget:Fire(bestTarget)
            end
        end)
    end
    return bestTarget
end

local cachedExitChestPrompt = nil
local activeRevivePrompts = {}

local function checkLightBraziers()
    if not Config.AutoDungeon then return end
    local h = workspace:FindFirstChild("Halloween")
    local b = h and h:FindFirstChild("Braziers")
    if not b then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, ch in ipairs(b:GetChildren()) do
        if ch.Name == "Pad" and ch:IsA("BasePart") then
            pcall(function()
                if firetouchinterest then
                    firetouchinterest(hrp, ch, 0)
                    task.wait(0.01)
                    firetouchinterest(hrp, ch, 1)
                end
            end)
        end
    end
end

kickedDudSkulls = {}

local function kickDudSkull(skullPart)
    if not canScriptMoveOrWarp() or not Config.AutoDungeon or not Config.AutoKickSkulls or not skullPart or not skullPart.Parent then return false end
    local now = os.clock()
    if kickedDudSkulls[skullPart] and (now - kickedDudSkulls[skullPart] < 2.5) then return false end

    local prompt = skullPart:FindFirstChildWhichIsA("ProximityPrompt")
    if not prompt then
        for _, desc in ipairs(skullPart:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                prompt = desc
                break
            end
        end
    end
    if not prompt or not prompt.Enabled then return false end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 or isDungeonDowned() or not canScriptMoveOrWarp() then return false end

    local skullPos = skullPart:IsA("BasePart") and skullPart.Position or (prompt.Parent and prompt.Parent:IsA("BasePart") and prompt.Parent.Position)
    if not skullPos then return false end

    kickedDudSkulls[skullPart] = now

    local origCFrame = hrp.CFrame
    local targetY = math.max(skullPos.Y + 2.0, 62.8)
    local floorRay = workspace:Raycast(Vector3.new(skullPos.X, 75.0, skullPos.Z), Vector3.new(0, -35.0, 0))
    if floorRay and floorRay.Instance and floorRay.Instance.Name:lower():find("ceiling") == nil then
        targetY = floorRay.Position.Y + 2.8
    end
    local kickPos = Vector3.new(skullPos.X, targetY, skullPos.Z)

    if not canScriptMoveOrWarp() then return false end
    hrp.CFrame = CFrame.new(kickPos)
    hrp.Velocity = Vector3.zero
    hrp.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.04)

    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
            fireproximityprompt(prompt, 0)
        end
    end)
    pcall(function()
        prompt:InputHoldBegin()
        task.wait(math.min(prompt.HoldDuration or 0, 0.1))
        prompt:InputHoldEnd()
    end)

    if firetouchinterest and skullPart:IsA("BasePart") then
        pcall(function()
            firetouchinterest(hrp, skullPart, 0)
            task.wait(0.02)
            firetouchinterest(hrp, skullPart, 1)
        end)
    end

    task.wait(0.05)
    if hrp and hrp.Parent and hum.Health > 0 and not isDungeonDowned() and canScriptMoveOrWarp() then
        hrp.CFrame = origCFrame
        hrp.Velocity = Vector3.zero
        hrp.AssemblyLinearVelocity = Vector3.zero
    end

    if WindUI and WindUI.Notify then
        WindUI:Notify({
            Title = "Skull King Crypt",
            Content = "เตะ Demon Skull ใส่บอสสำเร็จ! (-1~2% HP)",
            Duration = 2,
            Icon = "skull"
        })
    end
    return true
end

local function checkKickDudSkulls()
    if not canScriptMoveOrWarp() or not Config.AutoDungeon or not Config.AutoKickSkulls or not isInsideDungeon() then return end
    local now = os.clock()

    for s, t in pairs(kickedDudSkulls) do
        if (now - t > 10) or not s.Parent then
            kickedDudSkulls[s] = nil
        end
    end

    for _, child in ipairs(workspace:GetChildren()) do
        if not canScriptMoveOrWarp() then break end
        if child.Name == "DudPumpkin" or (child:IsA("BasePart") and child.Name:lower():find("dud")) then
            local kicked = kickDudSkull(child)
            if kicked then
                task.wait(0.08)
            end
        end
    end
end

trackConn(workspace.DescendantAdded:Connect(function(desc)
    if not isScriptAlive() then return end
    if desc:IsA("ProximityPrompt") then
        if desc.Name == "ChestPrompt" then
            local owner = desc:GetAttribute("OwnerUserId")
            if owner == nil or owner == LocalPlayer.UserId then
                cachedExitChestPrompt = desc
            end
        elseif desc.Name == "RevivePrompt" then
            table.insert(activeRevivePrompts, desc)
        elseif desc.ActionText == "Kick" or desc.ObjectText == "Demon Skull" or (desc.Parent and desc.Parent.Name == "DudPumpkin") then
            if canScriptMoveOrWarp() and Config.AutoDungeon and Config.AutoKickSkulls and isInsideDungeon() then
                task.spawn(function()
                    task.wait(0.05)
                    local pPart = desc.Parent
                    if pPart and pPart:IsA("BasePart") then
                        kickDudSkull(pPart)
                    end
                end)
            end
        end
    end
end))

trackConn(workspace.ChildAdded:Connect(function(child)
    if not isScriptAlive() or not canScriptMoveOrWarp() then return end
    if child.Name == "DudPumpkin" and Config.AutoDungeon and Config.AutoKickSkulls and isInsideDungeon() then
        task.spawn(function()
            task.wait(0.05)
            kickDudSkull(child)
        end)
    end
end))

local function executeReviveTeammates()
    if not canScriptMoveOrWarp() or not Config.AutoDungeon or not Config.AutoReviveTeammates or isDungeonDowned() then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local now = os.clock()
    if now - lastDungeonReviveTime < 1.5 then return end

    -- Fast check: scan player characters or cached prompts instead of whole workspace
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local pChar = player.Character
            if pChar then
                for _, prompt in ipairs(pChar:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and prompt.Name == "RevivePrompt" and prompt.Enabled then
                        local reviveFor = prompt:GetAttribute("ReviveFor")
                        if reviveFor and reviveFor ~= LocalPlayer.UserId then
                            local pPart = prompt.Parent
                            if pPart and pPart:IsA("BasePart") then
                                lastDungeonReviveTime = now
                                local targetPos = pPart.Position + Vector3.new(0, 2.5, 0)
                                local dist = (hrp.Position - targetPos).Magnitude
                                if dist > 8 then
                                    hrp.CFrame = CFrame.new(targetPos)
                                end
                                task.wait(0.1)
                                if fireproximityprompt then
                                    fireproximityprompt(prompt)
                                else
                                    pcall(function()
                                        prompt:InputHoldBegin()
                                        task.wait(prompt.HoldDuration or 0.2)
                                        prompt:InputHoldEnd()
                                    end)
                                end
                                if WindUI and WindUI.Notify then
                                    WindUI:Notify({
                                        Title = "Auto Dungeon",
                                        Content = "กำลังชุบชีวิตเพื่อนร่วมทีม...",
                                        Duration = 2,
                                        Icon = "heart"
                                    })
                                end
                                return
                            end
                        end
                    end
                end
            end
        end
    end
end

local function advanceDungeonPath()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not canScriptMoveOrWarp() or not Config.AutoDungeon or not hrp or not hum or hum.Health <= 0 or isDungeonDowned() then return end

    local pPos = hrp.Position

    -- Respawn at entrance check: if at entrance, start from waypoint 2
    if (pPos - DungeonPathWaypoints[1]).Magnitude <= 18 then
        currentDungeonWpIndex = 2
    end

    -- Respawn / Void recovery: if player spawned off-map or falling into void, reset to entrance safely
    if pPos.X > -3500 or pPos.Y < 40 then
        local entranceWp = DungeonPathWaypoints[1] or Vector3.new(-3838, 60.5, 288)
        currentDungeonWpIndex = 2
        hrp.CFrame = CFrame.new(entranceWp.X, 60.5, entranceWp.Z)
        hrp.Velocity = Vector3.zero
        hrp.AssemblyLinearVelocity = Vector3.zero
        return
    end

    -- Wall Unstuck Watchdog: If player is separated from the safe corridor path by a wall, pop back onto centerline!
    local nearestWp, wpDist, wpIdx = getNearestDungeonWaypoint(pPos)
    if nearestWp and wpDist > 7 then
        local wallInstances = getDungeonWallInstances()
        if #wallInstances > 0 then
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Include
            rayParams.FilterDescendantsInstances = wallInstances

            local toWp = nearestWp - pPos
            local hitToWp = workspace:Raycast(pPos + Vector3.new(0, 1.5, 0), toWp, rayParams)
            if hitToWp and hitToWp.Distance < toWp.Magnitude - 1.5 then
                local floorY = (nearestWp.Y > 65 and nearestWp.Y or 60.5)
                local fRay = workspace:Raycast(Vector3.new(nearestWp.X, 85, nearestWp.Z), Vector3.new(0, -50, 0))
                if fRay and fRay.Instance and fRay.Instance.Name:lower():find("ceiling") == nil then
                    floorY = fRay.Position.Y + 2.8
                end
                hrp.CFrame = CFrame.new(nearestWp.X, floorY, nearestWp.Z)
                hrp.Velocity = Vector3.zero
                hrp.AssemblyLinearVelocity = Vector3.zero
                currentDungeonWpIndex = math.max(currentDungeonWpIndex or 2, wpIdx)
                return
            end
        end
    end

    -- 1. Auto Secret Chests nearby (Stealth remote claim without warping character)
    if Config.AutoSecretChests and (os.clock() - lastSecretChestClaimTime > 2.0) then
        local h = workspace:FindFirstChild("Halloween")
        if h then
            for _, c in ipairs(h:GetChildren()) do
                if c.Name == "SecretChest" then
                    local prompt = c:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.Enabled then
                        local cPos = c:GetPivot().Position
                        local cDist = (pPos - cPos).Magnitude
                        if cDist <= 45 then
                            lastSecretChestClaimTime = os.clock()
                            pcall(function()
                                prompt.RequiresLineOfSight = false
                                prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance or 10, cDist + 20)
                            end)
                            if fireproximityprompt then
                                pcall(function() fireproximityprompt(prompt) end)
                            else
                                pcall(function()
                                    prompt:InputHoldBegin()
                                    task.wait(math.min(prompt.HoldDuration or 0.1, 0.15))
                                    prompt:InputHoldEnd()
                                end)
                            end
                            local cPart = c:IsA("BasePart") and c or c:FindFirstChildWhichIsA("BasePart", true)
                            if cPart and firetouchinterest then
                                pcall(function()
                                    firetouchinterest(hrp, cPart, 0)
                                    firetouchinterest(hrp, cPart, 1)
                                end)
                            end
                        end
                    end
                end
            end
        end
    end

    -- 2. Step forward along waypoint path
    -- Determine physically closest waypoint
    local closestIdx = 1
    local closestDist = math.huge
    for i, wp in ipairs(DungeonPathWaypoints) do
        local d = (Vector3.new(pPos.X, 0, pPos.Z) - Vector3.new(wp.X, 0, wp.Z)).Magnitude
        if d < closestDist then
            closestDist = d
            closestIdx = i
        end
    end

    local dStep = tonumber(workspace:GetAttribute("DungeonStep") or (workspace:FindFirstChild("Dungeon") and workspace.Dungeon:GetAttribute("DungeonStep")))
    local dObj = tostring(workspace:GetAttribute("DungeonObjective") or (workspace:FindFirstChild("Dungeon") and workspace.Dungeon:GetAttribute("DungeonObjective")) or ""):lower()

    if not dStep or dStep <= 0 then
        -- Primary fallback: Active objective banner on screen (WaveRow)
        pcall(function()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local lumiDungeon = pg and pg:FindFirstChild("LumiDungeon")
            local waveRow = lumiDungeon and lumiDungeon:FindFirstChild("WaveRow")
            local banner = waveRow and waveRow:FindFirstChildWhichIsA("TextLabel")
            if banner and banner.Visible and banner.Text ~= "" then
                local txt = banner.Text:lower()
                if txt:find("skull king") or txt:find("defeat the boss") then
                    dStep = 4
                    dObj = "defeat the skull king"
                elseif txt:find("potion witch") or txt:find("mini boss") or txt:find("witch") then
                    dStep = 3
                    dObj = "defeat the potion witch"
                elseif txt:find("pillar") or txt:find("ritual") or txt:find("seal") then
                    dStep = 2
                    dObj = "destroy the ritual pillars"
                elseif txt:find("clear") or txt:find("monster") then
                    dStep = 1
                    dObj = "clear all monsters"
                end
            end
        end)
    end

    if not dStep or dStep <= 0 then
        if dObj:find("skull king") or dObj:find("defeat the boss") or dObj:find("boss") then
            dStep = 4
        elseif dObj:find("mini boss") or dObj:find("witch") then
            dStep = 3
        elseif dObj:find("ritual pillar") or dObj:find("destroy the pillar") or dObj:find("break the seal") then
            dStep = 2
        else
            dStep = 1
        end
    end

    local maxAllowedWp = 37
    if dStep == 1 then
        maxAllowedWp = 12
    elseif dStep == 2 then
        maxAllowedWp = 14
    elseif dStep == 3 then
        maxAllowedWp = 21
    end

    -- Scan monsters for active objectives (Multi-Folder & CollectionService):
    local hasAlivePillars = false
    local hasAliveWitch = false
    local aliveMobsCount = 0
    local bossFound = false
    local scanRoots = {
        workspace:FindFirstChild("Monsters"),
        workspace:FindFirstChild("Halloween"),
        workspace:FindFirstChild("Dungeon"),
        workspace
    }
    for _, root in ipairs(scanRoots) do
        if root then
            for _, m in ipairs(root:GetChildren()) do
                if m:IsA("Model") then
                    local mName = m.Name:lower()
                    local mId = tostring(m:GetAttribute("MonsterId") or ""):lower()
                    local isPillar = (mName:find("pillar") or mName:find("ritual") or mId == "dgn_ritual_pillar")
                    local isWitch = (mName:find("witch") or mId:find("witch") or m:GetAttribute("IsMiniBoss") == true)
                    local isBoss = (m:GetAttribute("IsBoss") == true or mName:find("boss") or mName:find("skull king") or mId:find("boss") or mId:find("skull"))

                    if isBoss then
                        bossFound = true
                    end
                    if isMonsterAlive(m) then
                        aliveMobsCount = aliveMobsCount + 1
                        if isPillar then hasAlivePillars = true end
                        if isWitch then hasAliveWitch = true end
                    end
                end
            end
        end
    end
    if not bossFound then
        for _, b in ipairs(game:GetService("CollectionService"):GetTagged("Boss")) do
            bossFound = true
            break
        end
    end

    -- ==================== STEP-BASED BOUNDARY ENFORCEMENT & AUTO-RECOVERY ====================
    if dStep == 1 then
        if closestIdx > 12 then
            currentDungeonWpIndex = 3
            local sweepWp = DungeonPathWaypoints[3]
            hrp.CFrame = CFrame.new(sweepWp.X, 62.5, sweepWp.Z)
            hrp.Velocity = Vector3.zero
            return
        elseif currentDungeonWpIndex > 12 then
            currentDungeonWpIndex = 12
        end
    elseif dStep == 2 and hasAlivePillars then
        if closestIdx > 14 then
            currentDungeonWpIndex = 14
            local plazaWp = DungeonPathWaypoints[14]
            hrp.CFrame = CFrame.new(plazaWp.X, 62.5, plazaWp.Z)
            hrp.Velocity = Vector3.zero
            return
        elseif currentDungeonWpIndex > 14 then
            currentDungeonWpIndex = 14
        end
    elseif dStep == 3 and hasAliveWitch then
        if closestIdx > 21 then
            currentDungeonWpIndex = 21
            local witchWp = DungeonPathWaypoints[21]
            hrp.CFrame = CFrame.new(witchWp.X, 62.8, witchWp.Z)
            hrp.Velocity = Vector3.zero
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "Mini Boss Required! 🧙‍♀️",
                    Content = "พบ Potion Witch ยังไม่ถูกกำจัด! กำลังวาร์ปกลับห้องแม่มดทันที...",
                    Duration = 2.5,
                    Icon = "skull"
                })
            end
            return
        elseif currentDungeonWpIndex > 21 then
            currentDungeonWpIndex = 21
        end
    end

    -- ==================== STEP 4: BOSS DOOR AUTO-OPEN & ARENA ADVANCEMENT ====================
    if dStep >= 4 then
        local h = workspace:FindFirstChild("Halloween")
        local bd = h and h:FindFirstChild("BossDoor")
        local slab = bd and bd:FindFirstChild("Slab")
        local prompt = bd and bd:FindFirstChildWhichIsA("ProximityPrompt", true)
        if (slab and slab.CanCollide) or (prompt and prompt.Enabled) then
            local doorPos = slab and slab.Position or (bd:GetPivot().Position)
            local dToDoor = (hrp.Position - doorPos).Magnitude
            if dToDoor <= 45 or currentDungeonWpIndex >= 31 then
                local standPos = doorPos + Vector3.new(-4.5, 0, 0)
                hrp.CFrame = CFrame.new(standPos, doorPos)
                hrp.Velocity = Vector3.zero
                hrp.AssemblyLinearVelocity = Vector3.zero
                if prompt and prompt.Enabled then
                    prompt.RequiresLineOfSight = false
                    prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance or 14, 30)
                    local holdDur = tonumber(prompt.HoldDuration) or 1
                    if fireproximityprompt then
                        pcall(function() fireproximityprompt(prompt, holdDur + 0.1) end)
                        pcall(function() fireproximityprompt(prompt) end)
                    end
                    pcall(function()
                        prompt:InputHoldBegin()
                        task.wait(holdDur + 0.15)
                        prompt:InputHoldEnd()
                    end)
                end
                task.wait(0.3)
                return
            end
        end
    end

    -- Boss Room Active Engagement & Anti-Stagnation Engine:
    if closestIdx >= 32 and not currentCombatTarget then
        if dStep >= 4 then
            local h = workspace:FindFirstChild("Halloween")
            local bd = h and h:FindFirstChild("BossDoor")
            local slab = bd and bd:FindFirstChild("Slab")
            local prompt = bd and bd:FindFirstChildWhichIsA("ProximityPrompt", true)

            -- If player is outside boss gate (X < -4010), open the door
            if slab and slab.CanCollide and prompt and prompt.Enabled and hrp.Position.X < -4010 then
                local doorPos = slab.Position
                local standPos = doorPos + Vector3.new(-4.5, 0, 0)
                hrp.CFrame = CFrame.new(standPos, doorPos)
                hrp.Velocity = Vector3.zero
                if fireproximityprompt then pcall(function() fireproximityprompt(prompt, 1.1) end) end
                pcall(function()
                    prompt:InputHoldBegin()
                    task.wait(1.15)
                    prompt:InputHoldEnd()
                end)
                task.wait(0.3)
                return
            end

            -- Inside Boss Arena (X >= -4010): ACTIVE BRAZIER & DUD SKULL ENGAGEMENT
            -- 1. Auto kick dud skulls to chip boss and break invulnerability
            if Config.AutoKickSkulls then
                pcall(checkKickDudSkulls)
            end

            -- 2. Step onto active/unlit braziers in the arena
            pcall(function()
                local b = (h and h:FindFirstChild("Braziers")) or workspace:FindFirstChild("Braziers")
                if b then
                    for _, bz in ipairs(b:GetChildren()) do
                        local pad = bz:FindFirstChild("Pad") or (bz:IsA("BasePart") and bz) or bz:FindFirstChildWhichIsA("BasePart")
                        if pad then
                            local bPrompt = bz:FindFirstChildWhichIsA("ProximityPrompt", true)
                            local bLight = bz:FindFirstChildWhichIsA("PointLight", true) or bz:FindFirstChildWhichIsA("SurfaceLight", true)
                            local isLit = (bLight and bLight.Enabled == true) or bz:GetAttribute("Lit") == true
                            if not isLit or (bPrompt and bPrompt.Enabled) then
                                local padPos = pad.Position + Vector3.new(0, 2.8, 0)
                                hrp.CFrame = CFrame.new(padPos)
                                hrp.Velocity = Vector3.zero
                                if firetouchinterest then
                                    firetouchinterest(hrp, pad, 0)
                                    task.wait(0.02)
                                    firetouchinterest(hrp, pad, 1)
                                end
                                if bPrompt and bPrompt.Enabled and fireproximityprompt then
                                    fireproximityprompt(bPrompt)
                                end
                                task.wait(0.12)
                            end
                        end
                    end
                end
            end)

            currentDungeonWpIndex = 36
        elseif not bossFound and hasAliveWitch and (dStep < 4 or dObj:find("witch") or dObj:find("mini boss")) then
            currentDungeonWpIndex = 21
            local witchWp = DungeonPathWaypoints[21]
            hrp.CFrame = CFrame.new(witchWp.X, 62.8, witchWp.Z)
            hrp.Velocity = Vector3.zero
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "Mini Boss Required! 🧙‍♀️",
                    Content = "บอสใหญ่ยังไม่เกิดเพราะยังไม่ได้ฆ่า Potion Witch! กำลังวาร์ปไปห้องแม่มด...",
                    Duration = 3,
                    Icon = "skull"
                })
            end
            return
        end
    end

    -- Sync waypoint index with physical position (clamped by maxAllowedWp)
    currentDungeonWpIndex = math.clamp(currentDungeonWpIndex or 2, 1, maxAllowedWp)
    if closestIdx > currentDungeonWpIndex then
        currentDungeonWpIndex = math.min(closestIdx, maxAllowedWp)
    elseif (currentDungeonWpIndex - closestIdx) >= 2 then
        currentDungeonWpIndex = math.min(closestIdx + 1, maxAllowedWp)
    end

    -- If still in Step 1 and player reached locked Plaza gate with no mobs streamed in, sweep back
    if dStep == 1 and currentDungeonWpIndex >= 12 and aliveMobsCount == 0 then
        currentDungeonWpIndex = 3
        local sweepWp = DungeonPathWaypoints[3]
        hrp.CFrame = CFrame.new(sweepWp.X, 62.5, sweepWp.Z)
        hrp.Velocity = Vector3.zero
        return
    end

    -- Boss Room Activity: During Skull King phase, if no active combat target, kick dud skulls and step on braziers
    if dStep >= 4 and closestIdx >= 35 and not currentCombatTarget then
        if Config.AutoKickSkulls then
            pcall(checkKickDudSkulls)
        end
        pcall(function()
            local h = workspace:FindFirstChild("Halloween")
            local b = h and h:FindFirstChild("Braziers")
            if b then
                for _, pad in ipairs(b:GetChildren()) do
                    if pad.Name == "Pad" and pad:IsA("BasePart") then
                        if firetouchinterest then
                            firetouchinterest(hrp, pad, 0)
                            task.wait(0.01)
                            firetouchinterest(hrp, pad, 1)
                        end
                    end
                end
            end
        end)
    end

    local targetWp = DungeonPathWaypoints[currentDungeonWpIndex]
    if not targetWp then return end

    local flatTarget = Vector3.new(targetWp.X, 0, targetWp.Z)
    local flatPlayer = Vector3.new(pPos.X, 0, pPos.Z)
    local dist = (flatTarget - flatPlayer).Magnitude

    if dist <= 14 then
        local nextIdx = math.min(maxAllowedWp, currentDungeonWpIndex + 1)
        local canAdvance = true
        if dStep == 1 and nextIdx > 12 then
            canAdvance = false
        elseif (dStep == 2 or hasAlivePillars) and nextIdx > 14 then
            canAdvance = false
        elseif (dStep == 3 or hasAliveWitch) and nextIdx > 21 then
            canAdvance = false
        end
        if canAdvance then
            currentDungeonWpIndex = nextIdx
            targetWp = DungeonPathWaypoints[currentDungeonWpIndex]
            flatTarget = Vector3.new(targetWp.X, 0, targetWp.Z)
            dist = (flatTarget - flatPlayer).Magnitude
        end
    end

    if dist < 1.2 then return end

    if Config.FarmMode == "Walk" then
        hum.WalkSpeed = Config.WalkFarmSpeed or 28
        hum:MoveTo(targetWp)
        if dist <= 8 then
            local nextIdx = math.min(maxAllowedWp, currentDungeonWpIndex + 1)
            local canAdvance = true
            if dStep == 1 and nextIdx > 12 then canAdvance = false
            elseif (dStep == 2 or hasAlivePillars) and nextIdx > 14 then canAdvance = false
            elseif (dStep == 3 or hasAliveWitch) and nextIdx > 21 then canAdvance = false end
            if canAdvance then
                currentDungeonWpIndex = nextIdx
            end
        end
    else
        local dir = (flatTarget - flatPlayer).Unit
        local stepDist = math.min(dist, 14.0)
        local nextPos = pPos + (dir * stepDist)
        local targetFloorY = (targetWp.Y > 65) and targetWp.Y or 62.8
        nextPos = Vector3.new(nextPos.X, targetFloorY, nextPos.Z)
        hrp.CFrame = CFrame.lookAt(nextPos, nextPos + dir)
        hrp.Velocity = Vector3.zero
        hrp.AssemblyLinearVelocity = Vector3.zero
        if dist <= 10 then
            local nextIdx = math.min(maxAllowedWp, currentDungeonWpIndex + 1)
            local canAdvance = true
            if dStep == 1 and nextIdx > 12 then canAdvance = false
            elseif (dStep == 2 or hasAlivePillars) and nextIdx > 14 then canAdvance = false
            elseif (dStep == 3 or hasAliveWitch) and nextIdx > 21 then canAdvance = false end
            if canAdvance then
                currentDungeonWpIndex = nextIdx
            end
        end
    end
end

local function clickGuiButton(btn)
    if not btn then return false end
    local fired = false
    pcall(function()
        if getconnections then
            local actConns = getconnections(btn.Activated)
            if actConns and #actConns > 0 then
                for _, conn in ipairs(actConns) do
                    pcall(function() conn:Fire() end)
                    fired = true
                end
            end
            local clickConns = getconnections(btn.MouseButton1Click)
            if clickConns and #clickConns > 0 then
                for _, conn in ipairs(clickConns) do
                    pcall(function() conn:Fire() end)
                    fired = true
                end
            end
            local downConns = getconnections(btn.MouseButton1Down)
            if downConns and #downConns > 0 then
                for _, conn in ipairs(downConns) do
                    pcall(function() conn:Fire() end)
                    fired = true
                end
            end
            local upConns = getconnections(btn.MouseButton1Up)
            if upConns and #upConns > 0 then
                for _, conn in ipairs(upConns) do
                    pcall(function() conn:Fire() end)
                    fired = true
                end
            end
        end
    end)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        if vim and btn.AbsolutePosition and btn.AbsoluteSize then
            local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            task.wait(0.04)
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
            fired = true
        end
    end)
    return fired
end

local function handleAutoReplayUi(pg)
    if not pg or not Config.AutoRepeatDungeon then return end

    -- 1. Check LumiDungeonClear: ClearDim.ClearPanel.ReplayDungeon
    local clearGui = pg:FindFirstChild("LumiDungeonClear")
    if clearGui and clearGui.Enabled then
        local replayBtn = clearGui:FindFirstChild("ReplayDungeon", true)
        if replayBtn and replayBtn.Visible then
            clickGuiButton(replayBtn)
            pcall(function()
                if DungeonAction then
                    DungeonAction:FireServer("replayStart")
                end
            end)
        end
    end

    -- 2. Check LumiDungeonReplay: ReplayPop
    local replayGui = pg:FindFirstChild("LumiDungeonReplay")
    if replayGui and replayGui.Enabled then
        if Config.AutoBuyDungeonKey then
            local buyKeyBtn = replayGui:FindFirstChild("ReplayBuyKey", true)
            if buyKeyBtn and buyKeyBtn.Visible then
                clickGuiButton(buyKeyBtn)
                pcall(function()
                    if DungeonAction then
                        DungeonAction:FireServer("replayBuyKey")
                    end
                end)
            end
        end
        if Config.AutoConfirmReplay ~= false then
            local acceptBtn = replayGui:FindFirstChild("ReplayAccept", true)
            if acceptBtn and acceptBtn.Visible then
                clickGuiButton(acceptBtn)
                pcall(function()
                    if DungeonAction then
                        DungeonAction:FireServer("replayVote", true)
                    end
                end)
            end
        end
    end

    -- 3. Check LumiDungeonWindows: ReadyCheck & Modals
    local winGui = pg:FindFirstChild("LumiDungeonWindows")
    if winGui then
        local readyCheck = winGui:FindFirstChild("ReadyCheck")
        if readyCheck and readyCheck.Visible then
            for _, b in ipairs(readyCheck:GetDescendants()) do
                if b:IsA("GuiButton") and b.Visible then
                    clickGuiButton(b)
                end
            end
            pcall(function()
                local dId = workspace:GetAttribute("DungeonId") or Config.SelectedDungeon or "halloween"
                if DungeonAction then
                    DungeonAction:FireServer("ready", dId, true)
                end
            end)
        end

        local resultWin = winGui:FindFirstChild("DungeonResult")
        if resultWin and resultWin.Visible then
            local closeBtn = resultWin:FindFirstChild("Close", true)
            if closeBtn then clickGuiButton(closeBtn) end
        end

        local leaveConfirm = winGui:FindFirstChild("LeaveConfirm")
        if leaveConfirm and leaveConfirm.Visible then
            local stayBtn = leaveConfirm:FindFirstChild("BtnBlue", true)
            if stayBtn then clickGuiButton(stayBtn) end
        end
    end
end

local function executeAutoReplayDungeon()
    local startTime = os.clock()
    local maxWait = 25
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end

    if WindUI and WindUI.Notify then
        WindUI:Notify({
            Title = "Auto Replay 🔁",
            Content = "กำลังตรวจสอบหน้าต่างจบดันเจี้ยนและกดยืนยัน Replay...",
            Duration = 3,
            Icon = "rotate-cw"
        })
    end

    local lastRemoteAttempt = 0
    while (os.clock() - startTime) < maxWait and isScriptAlive() and isInsideDungeon() do
        local now = os.clock()
        handleAutoReplayUi(pg)

        -- Direct Remote Sync backup every 1.5s
        if (now - lastRemoteAttempt) >= 1.5 then
            lastRemoteAttempt = now
            pcall(function()
                if DungeonAction then
                    DungeonAction:FireServer("replayStart")
                    DungeonAction:FireServer("replayVote", true)
                    local dId = workspace:GetAttribute("DungeonId") or Config.SelectedDungeon or "halloween"
                    DungeonAction:FireServer("ready", dId, true)
                end
            end)
        end

        local dState = getDungeonState()
        local dStep = tonumber(workspace:GetAttribute("DungeonStep") or (workspace:FindFirstChild("Dungeon") and workspace.Dungeon:GetAttribute("DungeonStep"))) or 0
        if dState == "running" and dStep == 1 then
            break
        end

        task.wait(0.4)
    end
end

local function executeClaimExitChest()
    if not canScriptMoveOrWarp() then return end
    if not Config.AutoClaimExitChest and not Config.AutoLeaveOnClear and not Config.AutoRepeatDungeon then return end
    if isOpeningDungeonChest then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    isOpeningDungeonChest = true
    currentDungeonWpIndex = 1

    -- Stop all combat immediately so character doesn't swing or get distracted
    stopCombatAndTargeting()

    -- Helper function to sweep drops until workspace.Drops is confirmed empty
    local function sweepCurrentDrops(timeoutSec, statusTitle, statusContent)
        local startTime = os.clock()
        local maxWait = timeoutSec or 6
        local dropsFolder = workspace:FindFirstChild("Drops")
        if statusContent and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = statusTitle or "Auto Loot 🎒",
                Content = statusContent,
                Duration = 2.5,
                Icon = "sparkles"
            })
        end

        local emptyStreak = 0
        while (os.clock() - startTime) < maxWait and isScriptAlive() do
            local currentChar = LocalPlayer.Character
            local currentHrp = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
            if not currentHrp then break end

            if not dropsFolder or not dropsFolder.Parent then break end
            local drops = dropsFolder:GetChildren()
            local myDrops = {}
            local now = workspace:GetServerTimeNow()

            for _, d in ipairs(drops) do
                local dp = d:IsA("BasePart") and d or (d:IsA("Model") and (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart", true)))
                if dp and dp.Parent then
                    local owner = d:GetAttribute("OwnerUserId") or dp:GetAttribute("OwnerUserId")
                    local freeAt = d:GetAttribute("FreeAt") or dp:GetAttribute("FreeAt")
                    if not owner or owner == 0 or owner == LocalPlayer.UserId or (freeAt and now >= freeAt) then
                        table.insert(myDrops, { obj = d, part = dp })
                    end
                end
            end

            if #myDrops == 0 then
                emptyStreak = emptyStreak + 1
                if emptyStreak >= 2 then
                    break -- Confirmed empty for 2 consecutive checks
                end
                task.wait(0.3)
            else
                emptyStreak = 0
                -- 1. Call forward-declared performAutoLoot if available
                pcall(function()
                    if performAutoLoot then
                        performAutoLoot()
                    end
                end)

                -- 2. Direct vacuum + remote pickup + touch trigger for each drop
                for _, item in ipairs(myDrops) do
                    pcall(function()
                        local p = item.part
                        if p and p.Parent then
                            p.CanCollide = false
                            if Config.StealthMagnetLoot ~= false and currentHrp then
                                p.CFrame = currentHrp.CFrame
                            end
                            if RemotesLazy and RemotesLazy.PickupDrop then
                                RemotesLazy.PickupDrop:FireServer(p)
                                RemotesLazy.PickupDrop:FireServer(item.obj)
                            end
                            if firetouchinterest and currentHrp and currentHrp.Parent then
                                firetouchinterest(currentHrp, p, 0)
                                firetouchinterest(currentHrp, p, 1)
                            end
                            local prompt = p:FindFirstChildWhichIsA("ProximityPrompt", true) or item.obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt and prompt.Enabled then
                                if fireproximityprompt then
                                    fireproximityprompt(prompt)
                                else
                                    prompt:InputHoldBegin()
                                    task.wait(0.05)
                                    prompt:InputHoldEnd()
                                end
                            end
                        end
                    end)
                end
                task.wait(0.25)
            end
        end
    end

    -- ==================== STAGE 1: Boss Drops Vacuum & Sweep ====================
    -- Give boss drops 0.6s to spawn into workspace.Drops upon death, then collect everything!
    task.wait(0.6)
    sweepCurrentDrops(6, "Boss Defeated! 🎁", "กำลังตรวจสอบและเก็บของดรอปจากบอสทั้งหมด...")

    -- ==================== STAGE 2: Claim Personal Exit Chest ====================
    if Config.AutoClaimExitChest then
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "Exit Chest 🏆",
                Content = "กำลังค้นหาหีบรับรางวัล Tier VI ส่วนตัว...",
                Duration = 2.5,
                Icon = "gift"
            })
        end

        local targetPrompt = nil
        local searchStart = os.clock()

        -- Scan workspace for the player's personal ChestPrompt (retry up to 8s)
        while (os.clock() - searchStart) < 8 and isScriptAlive() do
            if cachedExitChestPrompt and cachedExitChestPrompt.Parent and cachedExitChestPrompt.Enabled then
                local owner = cachedExitChestPrompt:GetAttribute("OwnerUserId")
                if owner == nil or owner == LocalPlayer.UserId then
                    targetPrompt = cachedExitChestPrompt
                    break
                end
            end

            for _, desc in ipairs(workspace:GetDescendants()) do
                if desc:IsA("ProximityPrompt") then
                    local pName = desc.Name
                    local pObj = tostring(desc.ObjectText or "")
                    local isChest = (pName == "ChestPrompt") or 
                        (pName:lower():find("chest") and not pName:lower():find("secret") and not pObj:lower():find("secret"))
                    if isChest then
                        local owner = desc:GetAttribute("OwnerUserId")
                        if (owner == nil or owner == LocalPlayer.UserId) and desc.Enabled then
                            targetPrompt = desc
                            cachedExitChestPrompt = desc
                            break
                        end
                    end
                end
            end
            if targetPrompt then break end
            task.wait(0.4)
        end

        if targetPrompt and targetPrompt.Parent then
            local chestPart = targetPrompt.Parent:IsA("BasePart") and targetPrompt.Parent or targetPrompt:FindFirstAncestorWhichIsA("BasePart")
            if chestPart then
                local standPos = chestPart.Position + Vector3.new(0, 2.5, 2.8)
                hrp.CFrame = CFrame.new(standPos, chestPart.Position)
                task.wait(0.25)

                local holdDur = tonumber(targetPrompt.HoldDuration) or 0.5
                for attempt = 1, 5 do
                    if not targetPrompt.Parent or not targetPrompt.Enabled then
                        break
                    end
                    hrp.CFrame = CFrame.new(standPos, chestPart.Position)
                    if fireproximityprompt then
                        pcall(function() fireproximityprompt(targetPrompt, holdDur + 0.1) end)
                        pcall(function() fireproximityprompt(targetPrompt) end)
                    end
                    pcall(function()
                        targetPrompt:InputHoldBegin()
                        task.wait(holdDur + 0.15)
                        targetPrompt:InputHoldEnd()
                    end)
                    task.wait(0.3)
                    if not targetPrompt.Parent or not targetPrompt.Enabled then
                        break
                    end
                end
            end
            dungeonChestsClaimed = dungeonChestsClaimed + 1
        end
    end

    -- ==================== STAGE 3: Final Post-Chest Loot Verification ====================
    -- Wait 1.0s to allow chest reward drops to replicate into workspace.Drops, then sweep until 100% empty!
    task.wait(1.0)
    sweepCurrentDrops(8, "Loot Verification 🎁", "กำลังตรวจสอบไอเทมดรอปทั้งหมดให้หมดก่อนออกจากดัน...")

    -- ==================== STAGE 4: Safe Dungeon Exit or Replay ====================
    if Config.AutoRepeatDungeon then
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "Auto Replay 🔁",
                Content = "เคลียร์ดันเจี้ยนและรับของครบแล้ว กำลังกด Replay เพื่อเริ่มรอบใหม่...",
                Duration = 3,
                Icon = "rotate-cw"
            })
        end
        executeAutoReplayDungeon()
    elseif Config.AutoLeaveOnClear then
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "Dungeon Complete! 🏆",
                Content = "เก็บของรางวัลครบทั้งหมดแล้ว กำลังกลับสู่เมือง...",
                Duration = 3,
                Icon = "log-out"
            })
        end
        task.wait(1.2)
        pcall(registerQueueOnTeleport)
        pcall(function()
            if DungeonAction then
                DungeonAction:FireServer("leave")
            end
        end)
        task.wait(2.5)
    end

    isOpeningDungeonChest = false
    cachedExitChestPrompt = nil
end

-- ==================== 👥 PARTY & CO-OP MANAGEMENT SYSTEM ====================
local function getPartyMembers()
    local members = { LocalPlayer }
    local seen = { [LocalPlayer] = true }

    -- 1. Check PartyId / Party / PartyLeader attributes
    pcall(function()
        local myPartyId = LocalPlayer:GetAttribute("PartyId") or LocalPlayer:GetAttribute("Party")
        local myLeader = LocalPlayer:GetAttribute("PartyLeader")
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and not seen[p] then
                local pPartyId = p:GetAttribute("PartyId") or p:GetAttribute("Party")
                local pLeader = p:GetAttribute("PartyLeader")
                if myPartyId and pPartyId and myPartyId == pPartyId then
                    table.insert(members, p)
                    seen[p] = true
                elseif pLeader and (pLeader == LocalPlayer.Name or tostring(pLeader) == tostring(LocalPlayer.UserId)) then
                    table.insert(members, p)
                    seen[p] = true
                elseif myLeader and pLeader and myLeader == pLeader then
                    table.insert(members, p)
                    seen[p] = true
                end
            end
        end
    end)

    -- 2. Check PartyJson attribute on LocalPlayer
    pcall(function()
        local pJson = LocalPlayer:GetAttribute("PartyJson") or LocalPlayer:GetAttribute("PartyData")
        if pJson and type(pJson) == "string" and #pJson > 2 then
            local decoded = HttpService:JSONDecode(pJson)
            local list = type(decoded) == "table" and (decoded.Members or decoded.members or decoded.Players or decoded)
            if type(list) == "table" then
                for _, item in pairs(list) do
                    local n = type(item) == "table" and (item.Name or item.name or item.UserId or item.userId) or item
                    for _, p in ipairs(Players:GetPlayers()) do
                        if (p.Name == tostring(n) or tostring(p.UserId) == tostring(n)) and not seen[p] then
                            table.insert(members, p)
                            seen[p] = true
                        end
                    end
                end
            end
        end
    end)

    -- 3. Check PlayerGui party UI if present
    pcall(function()
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            for _, gui in ipairs(pGui:GetChildren()) do
                if gui:IsA("ScreenGui") and (gui.Name:lower():find("party") or gui.Name:lower():find("team")) then
                    for _, d in ipairs(gui:GetDescendants()) do
                        if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Visible then
                            for _, p in ipairs(Players:GetPlayers()) do
                                if p ~= LocalPlayer and not seen[p] and d.Text:find(p.Name) then
                                    table.insert(members, p)
                                    seen[p] = true
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    return members
end

local function createParty()
    if not PartyAction then
        PartyAction = Remotes and Remotes:FindFirstChild("PartyAction")
    end
    if not PartyAction then return false end
    pcall(function() PartyAction:FireServer("create") end)
    pcall(function() PartyAction:FireServer("createParty") end)
    pcall(function() PartyAction:FireServer("make") end)
    return true
end

local function leaveParty()
    if not PartyAction then
        PartyAction = Remotes and Remotes:FindFirstChild("PartyAction")
    end
    if not PartyAction then return false end
    pcall(function() PartyAction:FireServer("leave") end)
    return true
end

local function invitePlayerToParty(targetPlayer)
    if not targetPlayer or targetPlayer == LocalPlayer then return false end
    if not PartyAction then
        PartyAction = Remotes and Remotes:FindFirstChild("PartyAction")
    end
    if not PartyAction then return false end

    pcall(function() PartyAction:FireServer("invite", targetPlayer) end)
    pcall(function() PartyAction:FireServer("invite", targetPlayer.Name) end)
    pcall(function() PartyAction:FireServer("invite", targetPlayer.UserId) end)
    pcall(function() PartyAction:FireServer("invitePlayer", targetPlayer) end)
    return true
end

local function massInviteParty(filterType)
    createParty()
    task.wait(0.2)

    local invitedCount = 0
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local shouldInvite = false
            local f = (filterType or Config.PartyInviteTarget or "All Server"):lower()
            if f:find("all") then
                shouldInvite = true
            elseif f:find("friend") then
                pcall(function()
                    if LocalPlayer:IsFriendsWith(p.UserId) then
                        shouldInvite = true
                    end
                end)
            elseif f:find("near") or f:find("gate") then
                local pHrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                if hrp and pHrp and (hrp.Position - pHrp.Position).Magnitude <= 120 then
                    shouldInvite = true
                end
            else
                shouldInvite = true
            end

            if shouldInvite then
                invitePlayerToParty(p)
                invitedCount = invitedCount + 1
                task.wait(0.06)
            end
        end
    end

    if WindUI and WindUI.Notify then
        WindUI:Notify({
            Title = "Party Invite Sent",
            Content = string.format("ส่งคำเชิญเข้าปาร์ตี้ให้ผู้เล่น %d คน (%s)", invitedCount, filterType or "All"),
            Duration = 3,
            Icon = "user-plus"
        })
    end
    return invitedCount
end

local function waitForPartyMembers(targetCount, timeoutSeconds)
    isWaitingForParty = true
    forceStartDungeonFlag = false
    local startTime = os.clock()
    local timeout = timeoutSeconds or Config.PartyWaitTimeout or 30
    local target = targetCount or Config.PartyTargetMembers or 2

    while (os.clock() - startTime) < timeout do
        if not isScriptAlive() or forceStartDungeonFlag then break end
        if isInsideDungeon() then break end

        local currentMembers = getPartyMembers()
        local count = #currentMembers
        local remaining = math.max(0, math.ceil(timeout - (os.clock() - startTime)))

        if count >= target then
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "👥 Party Ready!",
                    Content = string.format("สมาชิกในปาร์ตี้ครบแล้ว (%d/%d คน)! กำลังเริ่มสร้างห้องดันเจี้ยน...", count, target),
                    Duration = 2.5,
                    Icon = "users"
                })
            end
            isWaitingForParty = false
            return true
        end

        if remaining % 5 == 0 or remaining <= 3 then
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "⏳ Waiting for Party",
                    Content = string.format("สมาชิกร่วมตี้: %d/%d คน (เหลือเวลาอีก %d วินาที)\nกดปุ่ม Force Start หากต้องการเริ่มทันที", count, target, remaining),
                    Duration = 2,
                    Icon = "clock"
                })
            end
        end

        task.wait(1.0)
    end

    isWaitingForParty = false
    local finalMembers = getPartyMembers()
    if WindUI and WindUI.Notify then
        WindUI:Notify({
            Title = "🚀 Party Starting",
            Content = string.format("เริ่มดันเจี้ยนด้วยสมาชิกปัจจุบัน (%d คน)...", #finalMembers),
            Duration = 2.5,
            Icon = "play"
        })
    end
    return #finalMembers > 1
end

local function findDungeonGatePrompt()
    local gatePos = Vector3.new(4.8, 5.0, 112.5)
    local bestPrompt = nil
    local bestDist = math.huge

    -- 1. Check workspace.Map.Village
    pcall(function()
        local village = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Village")
        if village then
            for _, d in ipairs(village:GetDescendants()) do
                if d:IsA("ProximityPrompt") then
                    local pPos = d.Parent and (d.Parent:IsA("BasePart") and d.Parent.Position or d.Parent:GetPivot().Position)
                    if pPos then
                        local dist = (pPos - gatePos).Magnitude
                        if dist < bestDist and dist <= 25 then
                            bestDist = dist
                            bestPrompt = d
                        end
                    end
                end
            end
        end
    end)

    -- 2. Fallback: Search all ProximityPrompts near gatePos
    if not bestPrompt then
        pcall(function()
            for _, p in ipairs(workspace:GetDescendants()) do
                if p:IsA("ProximityPrompt") then
                    local pParent = p.Parent
                    local pPos = pParent and (pParent:IsA("BasePart") and pParent.Position or pParent:GetPivot().Position)
                    if pPos then
                        local dist = (pPos - gatePos).Magnitude
                        if dist <= 20 and dist < bestDist then
                            bestDist = dist
                            bestPrompt = p
                        end
                    end
                end
            end
        end)
    end

    return bestPrompt
end

-- ==================== 🏰 ROBUST DUNGEON ROOM CREATION & ENTRY ====================
local function buyDungeonKey(silent)
    local silver = getPlayerSilver()
    if silver < 500000 then
        if not silent and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "Silver ไม่เพียงพอ ⚠️",
                Content = string.format("ต้องใช้ 500,000 Silver ในการซื้อกุญแจ (มีอยู่: %s)", tostring(silver)),
                Duration = 3,
                Icon = "alert-triangle"
            })
        end
        return false, "Not enough silver"
    end

    local inDungeon = isInsideDungeon()
    if inDungeon then
        local bKeys = getDungeonKeys()
        pcall(function()
            if DungeonAction then
                DungeonAction:FireServer("replayBuyKey")
            end
        end)
        task.wait(1.0)
        local aKeys = getDungeonKeys()
        if aKeys > bKeys then
            if not silent and WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "ซื้อกุญแจสำเร็จ! 🗝️",
                    Content = string.format("ซื้อกุญแจรีเพลย์สำเร็จ! กุญแจปัจจุบัน: %d ดอก", aKeys),
                    Duration = 3,
                    Icon = "key"
                })
            end
            return true
        end
        return false
    end

    local char = LocalPlayer.Character or workspace:FindFirstChild(LocalPlayer.Name)
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
    if not hrp then return false, "No HRP" end

    local gatePos = Vector3.new(4.8, 5.0, 112.5)
    local origPos = hrp.Position
    local distToGate = (hrp.Position - gatePos).Magnitude
    local needsWarpBack = false

    -- 1. Warp / Travel to Gate if not near (server requires player within 60 studs)
    if distToGate > 30 then
        needsWarpBack = true
        if not silent and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "ซื้อกุญแจดันเจี้ยน 🗝️",
                Content = "กำลังไปที่ประตูทางเข้าดันเจี้ยนเพื่อทำรายการซื้อ...",
                Duration = 2,
                Icon = "navigation"
            })
        end
        hrp.CFrame = CFrame.new(gatePos)
        hrp.Velocity = Vector3.zero
        task.wait(0.4)
    end

    -- 2. Trigger DungeonGate Prompt to ensure server gate session is open
    local prompt = findDungeonGatePrompt()
    if prompt and fireproximityprompt then
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(0.6)
    end

    local beforeKeys = getDungeonKeys()
    local beforeSilver = getPlayerSilver()

    -- 3. Fire buy action on server
    pcall(function()
        if DungeonAction then
            DungeonAction:FireServer("selectBuyKey")
        end
    end)
    task.wait(1.0)

    local afterKeys = getDungeonKeys()
    local afterSilver = getPlayerSilver()

    -- 4. Fallback click simulation if not yet registered
    if afterKeys <= beforeKeys and afterSilver == beforeSilver then
        local gui = LocalPlayer.PlayerGui:FindFirstChild("HuntDungeonSelect")
        local buyBtn = gui and gui:FindFirstChild("BuyKey", true)
        if buyBtn and getconnections then
            for _, conn in ipairs(getconnections(buyBtn.MouseButton1Click)) do
                pcall(function() conn:Fire() end)
            end
        end
        pcall(function()
            if DungeonAction then
                DungeonAction:FireServer("selectBuyKey")
            end
        end)
        task.wait(1.0)
        afterKeys = getDungeonKeys()
        afterSilver = getPlayerSilver()
    end

    local success = (afterKeys > beforeKeys) or ((beforeSilver - afterSilver) >= 500000)

    if success then
        if not silent and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "ซื้อกุญแจสำเร็จ! 🗝️",
                Content = string.format("ซื้อกุญแจดันเจี้ยนเรียบร้อย! กุญแจปัจจุบัน: %d ดอก (เหลือ Silver: %s)", afterKeys, string.format("%.1fM", afterSilver / 1000000)),
                Duration = 3,
                Icon = "key"
            })
        end
    else
        if not silent and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "ซื้อกุญแจไม่สำเร็จ ⚠️",
                Content = "เซิร์ฟเวอร์ยังไม่ตอบรับการซื้อ กรุณาลองใหม่อีกครั้ง",
                Duration = 3,
                Icon = "alert-circle"
            })
        end
    end

    -- 5. Return to original spot if manual buy
    if needsWarpBack and not Config.AutoDungeon then
        hrp.CFrame = CFrame.new(origPos)
        hrp.Velocity = Vector3.zero
    end

    return success
end

local function executeDungeonEnterRoutine(isManual)
    if isEnteringDungeon or isInsideDungeon() then return end
    if not isManual and not canScriptMoveOrWarp() then return end

    -- 🛑 Immediately stop AutoProgression (Auto Lv.99) when entering dungeon!
    Config.AutoProgression = false
    isCheckingBossArena = false
    activeBossFight = nil
    isWarpingZone = false
    pcall(function()
        if autoProgressionToggle then
            if autoProgressionToggle.SetValue then
                autoProgressionToggle:SetValue(false)
            elseif autoProgressionToggle.Set then
                autoProgressionToggle:Set(false)
            end
        end
    end)

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    local now = os.clock()
    if not isManual and (now - lastDungeonEnterAttempt) < 8 then return end
    lastDungeonEnterAttempt = now

    -- 1. Level check
    local playerLevel = getPlayerLevel()
    if playerLevel < 90 then
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "Dungeon Locked",
                Content = "ดันเจี้ยนต้องการเลเวล 90+ (เลเวลปัจจุบัน: " .. playerLevel .. ")",
                Duration = 3,
                Icon = "alert-circle"
            })
        end
        return
    end

    -- 🛑 PRIORITY 1: Disengage combat & suspend all conflicting routines for dungeon room creation
    stopCombatAndTargeting()
    isEnteringDungeon = true
    currentCombatTarget = nil
    setClientCurrentTarget(nil)

    -- 3. Travel to GateKeeper in Village
    local gatePos = Vector3.new(4.8, 5.0, 112.5)
    local distToGate = (hrp.Position - gatePos).Magnitude

    if distToGate > 35 then
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "Auto Dungeon",
                Content = "กำลังเดินทางไปประตูทางเข้าดันเจี้ยน (Dungeon Gate)...",
                Duration = 2.5,
                Icon = "navigation"
            })
        end
        travelToZone("Town", "Adventurer Guild / Village", true)
        task.wait(0.6)

        -- Step to GateKeeper precisely
        local startP = hrp.Position
        local steps = math.max(1, math.ceil((gatePos - startP).Magnitude / 30))
        for i = 1, steps do
            if not char or not hrp.Parent then break end
            local alpha = i / steps
            hrp.CFrame = CFrame.new(startP:Lerp(gatePos, alpha))
            hrp.Velocity = Vector3.zero
            task.wait(0.04)
        end
        hrp.CFrame = CFrame.new(gatePos)
        hrp.Velocity = Vector3.zero
        task.wait(0.5)
    else
        hrp.CFrame = CFrame.new(gatePos)
        hrp.Velocity = Vector3.zero
        task.wait(0.2)
    end

    -- 4. Party Management & Member Wait
    if Config.DungeonPartyMode == "Party" then
        createParty()
        task.wait(0.3)
        if Config.PartyAutoInvite then
            massInviteParty(Config.PartyInviteTarget)
        end
        -- Wait for party members to join before creating the dungeon room
        waitForPartyMembers(Config.PartyTargetMembers or 2, Config.PartyWaitTimeout or 25)
    elseif Config.DungeonPartyMode == "Solo" and Config.DungeonForceSolo ~= false then
        leaveParty()
        task.wait(0.2)
    end

    -- 5. Trigger GateKeeper ProximityPrompt
    local prompt = findDungeonGatePrompt()
    if prompt then
        pcall(function()
            prompt.RequiresLineOfSight = false
            prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance or 10, 30)
        end)
        if fireproximityprompt then
            pcall(function() fireproximityprompt(prompt) end)
        end
        pcall(function()
            local holdDur = math.max(0.2, (prompt.HoldDuration or 0) + 0.15)
            prompt:InputHoldBegin()
            task.wait(holdDur)
            prompt:InputHoldEnd()
        end)
    end
    task.wait(0.6)

    -- 5.1 Keys & Free Runs Check (Right at the Gate where server allows buy)
    local keys = getDungeonKeys()
    local silver = getPlayerSilver()
    if keys <= 0 and Config.AutoBuyDungeonKey then
        if silver >= 500000 then
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "Auto Buy Key 🗝️",
                    Content = "กำลังซื้อกุญแจดันเจี้ยนที่ประตู (500,000 Silver)...",
                    Duration = 2.5,
                    Icon = "key"
                })
            end
            pcall(function()
                if DungeonAction then
                    DungeonAction:FireServer("selectBuyKey")
                end
            end)
            task.wait(1.0)
            keys = getDungeonKeys()
            if keys <= 0 then
                -- Fallback via UI button click
                local gui = LocalPlayer.PlayerGui:FindFirstChild("HuntDungeonSelect")
                local buyBtn = gui and gui:FindFirstChild("BuyKey", true)
                if buyBtn and getconnections then
                    for _, conn in ipairs(getconnections(buyBtn.MouseButton1Click)) do
                        pcall(function() conn:Fire() end)
                    end
                end
                task.wait(1.0)
                keys = getDungeonKeys()
            end
        else
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "Out of Silver & Keys ⚠️",
                    Content = "Silver ไม่พอซื้อกุญแจ (ต้องการ 500,000 Silver)",
                    Duration = 3,
                    Icon = "alert-triangle"
                })
            end
            isEnteringDungeon = false
            isWaitingForParty = false
            return
        end
    end

    -- 6. Send selectEnter & ready with multi-attempt retry
    local dId = Config.SelectedDungeon or "halloween"
    local rawDiff = tostring(Config.DungeonDifficulty or "easy"):lower()
    local diff = (rawDiff:find("normal") or rawDiff:find("hard")) and "normal" or "easy"
    pcall(registerQueueOnTeleport)

    local entered = false
    for attempt = 1, 4 do
        if isInsideDungeon() then
            entered = true
            break
        end

        pcall(function()
            if DungeonAction then
                DungeonAction:FireServer("selectEnter", dId, diff)
            end
        end)
        task.wait(0.5)

        pcall(function()
            if DungeonAction then
                DungeonAction:FireServer("ready", dId, true)
            end
        end)
        task.wait(2.0)
        if isInsideDungeon() then
            entered = true
            break
        end
    end

    if entered or isInsideDungeon() then
        task.wait(1.5)
        isEnteringDungeon = false
        isWaitingForParty = false
    else
        local waitElapsed = 0
        while waitElapsed < 6 and not isInsideDungeon() do
            task.wait(0.5)
            waitElapsed = waitElapsed + 0.5
        end
        isEnteringDungeon = false
        isWaitingForParty = false
    end
end

getPlayerLevel = function()
    local lv = nil
    pcall(function()
        lv = LocalPlayer:GetAttribute("Level") or LocalPlayer:GetAttribute("Lv")
        if not lv then
            local ls = LocalPlayer:FindFirstChild("leaderstats")
            if ls then
                local lvVal = ls:FindFirstChild("Level") or ls:FindFirstChild("Lv")
                if lvVal and lvVal.Value then
                    lv = lvVal.Value
                end
            end
        end
        if not lv and LocalPlayer.Character then
            lv = LocalPlayer.Character:GetAttribute("Level") or LocalPlayer.Character:GetAttribute("Lv")
        end
        if not lv then
            local data = LocalPlayer:FindFirstChild("Data")
            if data then
                local lvVal = data:FindFirstChild("Level") or data:FindFirstChild("Lv")
                if lvVal and lvVal.Value then
                    lv = lvVal.Value
                end
            end
        end
    end)
    return tonumber(lv) or 1
end

local function getOptimalZone(level)
    level = tonumber(level) or getPlayerLevel()
    for _, zone in ipairs(LevelZones) do
        if level >= zone.Min and level <= zone.Max then
            return zone.Field, zone.Name
        end
    end
    return "Field01", "Rabbit Field (Lv.1-8)"
end

local function getZonePosition(zoneName)
    local zPart = workspace:FindFirstChild("Zones") and workspace.Zones:FindFirstChild(zoneName)
    if zPart and zPart:IsA("BasePart") then
        return zPart.Position + Vector3.new(0, 4, 0)
    end
    return ZoneCoordinates[zoneName] or Vector3.new(0, 10, -203)
end

local function isPlayerInZone(zoneName)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local zonePos = getZonePosition(zoneName)
    local dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(zonePos.X, 0, zonePos.Z)).Magnitude
    return dist <= 240
end

local function isPlayerInBossArena()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, nil end
    local pPos = hrp.Position
    for bName, bPos in pairs(ZoneCoordinates) do
        if bName:find("Boss") then
            -- Boss arena boundary is strictly 70 studs (prevents false triggering on adjacent fields)
            if (Vector3.new(pPos.X, 0, pPos.Z) - Vector3.new(bPos.X, 0, bPos.Z)).Magnitude <= 70 then
                return true, bName
            end
        end
    end
    if Config.CurrentZone and Config.CurrentZone:find("Boss") then
        return true, Config.CurrentZone
    end
    return false, nil
end

local function isAnyBossAliveInArena(arenaName)
    local arenaPos = arenaName and ZoneCoordinates[arenaName]
    local folder = workspace:FindFirstChild("Monsters")
    if not folder then return false, nil end
    for _, m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") and isMonsterAlive(m) and isBossMonster(m) then
            local mHrp = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
            if mHrp then
                if arenaPos then
                    local d = (Vector3.new(mHrp.Position.X, 0, mHrp.Position.Z) - Vector3.new(arenaPos.X, 0, arenaPos.Z)).Magnitude
                    if d <= 260 then
                        return true, m
                    end
                else
                    return true, m
                end
            end
        end
    end
    return false, nil
end

local function getReturnField()
    local pLevel = getPlayerLevel()
    local optField, optName = getOptimalZone(pLevel)
    if Config.AutoProgression then
        return optField, optName
    end
    if lastNormalFarmZone and lastNormalFarmZone ~= "" and not lastNormalFarmZone:find("Boss") then
        for _, z in ipairs(LevelZones) do
            if z.Field == lastNormalFarmZone then
                return z.Field, z.Name
            end
        end
        return lastNormalFarmZone, lastNormalFarmZone
    end
    return optField, optName
end

travelToZone = function(targetField, fieldName, isManual)
    if isInsideDungeon() or isWarpingZone then return end
    if not isManual and (isEnteringDungeon or isWaitingForParty or not canScriptMoveOrWarp()) and not isCheckingBossArena then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    isWarpingZone = true
    currentCombatTarget = nil
    local targetPos = getZonePosition(targetField)

    -- 1. Detach from current targets cleanly
    setClientCurrentTarget(nil)

    -- 2. Notify player
    if WindUI and WindUI.Notify then
        WindUI:Notify({
            Title = "Auto Field Warper",
            Content = "เลเวล " .. getPlayerLevel() .. "\nกำลังเดินทางสู่ Field: " .. (fieldName or targetField),
            Duration = 2.5,
            Icon = "navigation",
        })
    end

    -- 3. Sync zone warp with server remote
    pcall(function()
        if RemotesLazy.WarpTo then
            RemotesLazy.WarpTo:FireServer(targetField)
        end
    end)

    -- 4. Smooth Step-wise Teleport (prevents rubberband, void fall, or anticheat kick)
    pcall(function()
        local startPos = hrp.Position
        local totalDist = (targetPos - startPos).Magnitude
        if totalDist > 70 then
            local steps = math.max(1, math.ceil(totalDist / 55))
            for i = 1, steps do
                if not char or not hrp.Parent then break end
                local alpha = i / steps
                local intermediate = startPos:Lerp(targetPos, alpha)
                hrp.CFrame = CFrame.new(intermediate + Vector3.new(0, 4, 0))
                hrp.Velocity = Vector3.zero
                hrp.AssemblyLinearVelocity = Vector3.zero
                task.wait(0.06)
            end
        end

        if hrp and hrp.Parent then
            hrp.CFrame = CFrame.new(targetPos)
            hrp.Velocity = Vector3.zero
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)

    Config.CurrentZone = targetField
    if not targetField:find("Boss") then
        lastNormalFarmZone = targetField
    end
    task.wait(0.4)

    -- 5. Reset target monster to "All" so auto farm engages immediately in the new field
    Config.SelectedMonster = "All"
    pcall(function()
        if monsterDropdown then
            monsterDropdown:SetValues(getMonsterList())
        end
        if bossDropdown then
            bossDropdown:SetValues(getBossList())
        end
    end)

    isWarpingZone = false
end

-- ==================== AUTO RETURN TO PROGRESSION AFTER BOSS ====================
activeBossFight = nil
isReturningFromBoss = false
local trackedBossDeaths = {}
isCheckingBossArena = false
local lastBossWarpCheckTime = 0

local BossZones = {
    { Name = "Gorilla King", Zone = "Boss01", MinLevel = 18, MaxLevel = 38 },
    { Name = "Whitefang Sabertooth", Zone = "Boss02", MinLevel = 39, MaxLevel = 62 },
    { Name = "Obsidian Pharaoh", Zone = "Boss03", MinLevel = 63, MaxLevel = 84 },
    { Name = "Tempest Dragon King", Zone = "Boss04", MinLevel = 85, MaxLevel = 97 },
    { Name = "Volcano Turtle King", Zone = "Boss05", MinLevel = 98, MaxLevel = 999 },
}

local function getTargetBossZone(level, selectedBoss)
    if selectedBoss and selectedBoss ~= "All Bosses" and selectedBoss ~= "Pack Leaders Only" then
        for _, b in ipairs(BossZones) do
            if b.Name == selectedBoss or selectedBoss:find(b.Name) then
                return b.Zone, b.Name
            end
        end
    end
    for _, b in ipairs(BossZones) do
        if level >= b.MinLevel and level <= b.MaxLevel then
            return b.Zone, b.Name
        end
    end
    return "Boss03", "Obsidian Pharaoh"
end

local function executeBossInspection(silent)
    if isInsideDungeon() or isEnteringDungeon or isWaitingForParty then return end
    if isWarpingZone or isSelling or isReturningFromBoss or activeBossFight then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    local inBoss, currentBossArena = isPlayerInBossArena()
    if not inBoss and Config.CurrentZone and not Config.CurrentZone:find("Boss") then
        lastNormalFarmZone = Config.CurrentZone
    end

    local pLevel = getPlayerLevel()
    local bZone, bName = getTargetBossZone(pLevel, Config.SelectedBoss)
    if not bZone then return end

    local bPos = ZoneCoordinates[bZone]
    if bPos and (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(bPos.X, 0, bPos.Z)).Magnitude <= 120 then
        -- Already at boss arena
        return
    end

    isCheckingBossArena = true

    if not silent and WindUI and WindUI.Notify then
        WindUI:Notify({
            Title = "👑 World Boss Hunter",
            Content = string.format("กำลังวาร์ปไปตรวจสอบบอส: %s (%s)", bName, bZone),
            Duration = 3,
            Icon = "swords",
        })
    end

    travelToZone(bZone, bName .. " Arena")

    task.spawn(function()
        -- Wait 3.5 seconds for chunks to stream in and check for alive boss
        task.wait(3.5)
        local folder = workspace:FindFirstChild("Monsters")
        local foundBoss = nil

        if folder and hrp and hrp.Parent then
            for _, m in ipairs(folder:GetChildren()) do
                if m:IsA("Model") and isMonsterAlive(m) and isBossMonster(m) then
                    local mHrp = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
                    if mHrp and (mHrp.Position - hrp.Position).Magnitude <= 240 then
                        foundBoss = m
                        break
                    end
                end
            end
        end

        if foundBoss then
            activeBossFight = {
                model = foundBoss,
                name = foundBoss.Name,
                pos = (foundBoss:FindFirstChild("HumanoidRootPart") or foundBoss.PrimaryPart) and (foundBoss:FindFirstChild("HumanoidRootPart") or foundBoss.PrimaryPart).Position,
                time = os.clock(),
            }
            trackBossDeath(foundBoss)
            isCheckingBossArena = false
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "⚔️ เจอบอสแล้ว!",
                    Content = string.format("กำลังเปิดฉากต่อสู้กับ: %s", foundBoss.Name),
                    Duration = 3,
                    Icon = "skull",
                })
            end
        else
            -- No boss alive in the arena
            if not silent and WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "บอสยังไม่เกิด (Cooldown)",
                    Content = "ยังไม่พบบอสในห้อง กำลังกลับไปฟาร์มมอนสเตอร์ปกติ...",
                    Duration = 2.5,
                    Icon = "clock",
                })
            end
            task.wait(0.8)
            isCheckingBossArena = false
            local targetField, fieldName = getReturnField()
            travelToZone(targetField, fieldName)
        end
    end)
end

local function handlePostBossReturn(bossName, deathPos)
    if isInsideDungeon() or isReturningFromBoss then return end
    isReturningFromBoss = true
    activeBossFight = nil
    currentCombatTarget = nil

    task.spawn(function()
        local success, err = pcall(function()
            local bName = tostring(bossName or "Boss")

            -- 1. Notify player
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "🏆 Boss Defeated!",
                    Content = "กำจัด " .. bName .. " สำเร็จ!\nกำลังดูดเก็บไอเทมดรอปและเตรียมกลับไปฟาร์มมอนปกติ...",
                    Duration = 2.5,
                    Icon = "trophy",
                })
            end

            -- 2. Fast stealth loot vacuum around boss death area (no character warp)
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local dropsFolder = workspace:FindFirstChild("Drops")

            for sweep = 1, 3 do
                if dropsFolder and hrp and hrp.Parent then
                    for _, d in ipairs(dropsFolder:GetChildren()) do
                        if d:IsA("BasePart") then
                            local dDist = (d.Position - hrp.Position).Magnitude
                            if dDist <= (Config.LootRadius or 120) then
                                if Config.StealthMagnetLoot ~= false then
                                    pcall(function()
                                        d.CanCollide = false
                                        d.CFrame = hrp.CFrame
                                    end)
                                end
                                pcall(function()
                                    if RemotesLazy.PickupDrop then
                                        RemotesLazy.PickupDrop:FireServer(true)
                                        RemotesLazy.PickupDrop:FireServer(d)
                                    end
                                end)
                                if firetouchinterest then
                                    pcall(function()
                                        firetouchinterest(hrp, d, 0)
                                        firetouchinterest(hrp, d, 1)
                                    end)
                                end
                            end
                        end
                    end
                end
                task.wait(0.25)
            end

            -- 3. Reset combat flags so normal monsters are immediately targetable
            if Config.AutoBoss and Config.ReturnToProgressionAfterBoss then
                Config.AutoFarm = true
                Config.BossOnly = false
                Config.SelectedMonster = "All"
                pcall(function()
                    if autoFarmToggle and autoFarmToggle.SetValue then
                        autoFarmToggle:SetValue(true)
                    elseif autoFarmToggle and autoFarmToggle.Set then
                        autoFarmToggle:Set(true)
                    end
                    if monsterDropdown then
                        monsterDropdown:SetValues(getMonsterList())
                    end
                    if bossDropdown then
                        bossDropdown:SetValues(getBossList())
                    end
                end)
            end

            -- 4. Check whether player is inside a Boss Arena or in a normal field
            local inBoss, bossArenaName = isPlayerInBossArena()
            if inBoss then
                -- Player is in a World Boss Arena (Boss01-05), warp back to normal field!
                local targetField, fieldName = getReturnField()
                travelToZone(targetField, fieldName)

                if WindUI and WindUI.Notify then
                    WindUI:Notify({
                        Title = "⚔️ กลับมาฟาร์มมอนสเตอร์ปกติ",
                        Content = "กลับมาฟาร์มมอนสเตอร์ที่: " .. tostring(fieldName or targetField) .. " เรียบร้อย!",
                        Duration = 3,
                        Icon = "swords",
                    })
                end
            else
                -- Player was already in a normal field (e.g. killed a Field Boss/Mini-Boss/Pack Leader)
                -- DO NOT warp away! Keep fighting in place!
                if Config.CurrentZone and Config.CurrentZone:find("Boss") then
                    local targetField, fieldName = getReturnField()
                    Config.CurrentZone = targetField
                end
                if WindUI and WindUI.Notify then
                    WindUI:Notify({
                        Title = "⚔️ ลุยต่อทันที",
                        Content = "กำจัดบอสในแมพเสร็จแล้ว สลับกลับไปตีมอนสเตอร์ปกติในพื้นที่ทันที!",
                        Duration = 2.5,
                        Icon = "swords",
                    })
                end
            end
        end)

        if not success then
            warn("[Boss Return Error]:", err)
        end

        task.wait(0.5)
        activeBossFight = nil
        isReturningFromBoss = false
    end)
end

trackBossDeath = function(boss)
    if not boss or not boss:IsA("Model") or trackedBossDeaths[boss] then return end
    trackedBossDeaths[boss] = true

    local hum = boss:FindFirstChildOfClass("Humanoid")
    local bName = boss.Name
    local bHrp = boss:FindFirstChild("HumanoidRootPart") or boss.PrimaryPart
    local bPos = bHrp and bHrp.Position

    local function onDead()
        if not isReturningFromBoss and (activeBossFight == nil or activeBossFight.model == boss or isBossMonster(boss)) then
            local pos = (boss:FindFirstChild("HumanoidRootPart") or boss.PrimaryPart) and (boss:FindFirstChild("HumanoidRootPart") or boss.PrimaryPart).Position or bPos
            activeBossFight = nil
            handlePostBossReturn(bName, pos)
        end
    end

    if hum then
        hum.Died:Connect(onDead)
        hum.HealthChanged:Connect(function(health)
            if health <= 0 then
                onDead()
            end
        end)
    end

    boss.AncestryChanged:Connect(function(_, parent)
        if not parent then
            onDead()
        end
    end)

    pcall(function()
        local attrNames = {"Dead", "IsDead", "Dying", "HP", "Hp", "Health"}
        for _, a in ipairs(attrNames) do
            boss:GetAttributeChangedSignal(a):Connect(function()
                if not isMonsterAlive(boss) then
                    onDead()
                end
            end)
        end
    end)
end

outOfZoneTicks = 0
local function checkAutoProgression(force)
    -- Only proceed if AutoProgression is enabled or forced
    if not Config.AutoProgression and not force then return end
    if isInsideDungeon() or isEnteringDungeon or isWaitingForParty then return end
    if isWarpingZone or isSelling or isReturningFromBoss then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    local playerLevel = getPlayerLevel()
    local targetField, fieldName = getOptimalZone(playerLevel)

    -- If player is in a Boss Arena and no boss is alive, return immediately to normal field
    local inBossZone, bossZoneName = isPlayerInBossArena()

    if inBossZone then
        if isCheckingBossArena or Config.BossOnly then
            return
        end
        local aliveBoss = isAnyBossAliveInArena(bossZoneName)
        if not aliveBoss then
            outOfZoneTicks = 0
            handlePostBossReturn("World Boss Area", nil)
            return
        end
    end

    if force then
        outOfZoneTicks = 0
        travelToZone(targetField, fieldName)
    elseif Config.AutoProgression then
        if not isPlayerInZone(targetField) then
            outOfZoneTicks = outOfZoneTicks + 1
            if outOfZoneTicks >= 3 then
                outOfZoneTicks = 0
                travelToZone(targetField, fieldName)
            end
        else
            outOfZoneTicks = 0
        end
    end
end

-- ==================== AUTO EQUIP BEST GEAR SYSTEM ====================
local function executeAutoEquipBest()
    -- 1. Native best armor and accessories
    if Config.AutoEquipBest and RemotesLazy.EquipItem then
        pcall(function()
            RemotesLazy.EquipItem:FireServer("@best")
        end)
    end

    -- 2. Native auto card equip
    if Config.AutoEquipCards and RemotesLazy.CardAction then
        pcall(function()
            RemotesLazy.CardAction:FireServer("auto")
        end)
    end

    -- 3. Custom Best Weapon Selector
    if Config.AutoEquipBestWeapon and RemotesLazy.EquipWeapon then
        pcall(function()
            local playerLevel = LocalPlayer:GetAttribute("Level") or 1
            local gearRaw = LocalPlayer:GetAttribute("GearJson") or "{}"
            local gearTable = HttpService:JSONDecode(gearRaw)
            local gu = GearUtilModule or require(ReplicatedStorage.Shared.GearUtil)

            local bestWepKey = nil
            local highestTier = -1
            local highestDmg = -1

            for key, gdata in pairs(gearTable) do
                local tier = gdata.T or 1
                local reqLevel = (gu and gu.TierReqLevel and gu.TierReqLevel[tier]) or 1

                if playerLevel >= reqLevel then
                    local res = gu and gu.Resolve and gu.Resolve(gdata.Id)
                    if res and res.Kind == "weapon" then
                        local dmg = gdata.M or 0
                        if tier > highestTier or (tier == highestTier and dmg > highestDmg) then
                            highestTier = tier
                            highestDmg = dmg
                            bestWepKey = key
                        end
                    end
                end
            end

            if bestWepKey then
                RemotesLazy.EquipWeapon:FireServer(bestWepKey)
            end
        end)
    end
end

-- ==================== HELPER FUNCTIONS ====================
getMonsterList = function()
    local list = {"All"}
    local seen = {}
    local folder = workspace:FindFirstChild("Monsters")
    if folder then
        for _, m in ipairs(folder:GetChildren()) do
            if m:IsA("Model") and not seen[m.Name] then
                seen[m.Name] = true
                table.insert(list, m.Name)
            end
        end
    end
    return list
end

-- ==================== LOW-PLAYER SERVER HOP SYSTEM ====================
local isServerHopping = false
local serverHopNextTick = 0

local function serverHopLowPlayer(silent)
    if isInsideDungeon() or isEnteringDungeon or isWaitingForParty then
        if not silent and WindUI and WindUI.Notify then
            WindUI:Notify({ Title = "Server Hop", Content = "กำลังสร้างห้องหรืออยู่ในดันเจี้ยน ปิดการย้ายเซิร์ฟเวอร์ชั่วคราว", Duration = 2.5, Icon = "clock" })
        end
        return
    end
    if isServerHopping then
        if not silent and WindUI and WindUI.Notify then
            WindUI:Notify({ Title = "Server Hop", Content = "กำลังอยู่ระหว่างการย้ายเซิร์ฟเวอร์ กรุณารอสักครู่...", Duration = 2.5, Icon = "clock" })
        end
        return
    end
    isServerHopping = true

    if not silent and WindUI and WindUI.Notify then
        WindUI:Notify({
            Title = "Server Hop",
            Content = "กำลังค้นหาเซิร์ฟเวอร์ที่มีผู้เล่นน้อยที่สุด...",
            Duration = 3,
            Icon = "search"
        })
    end

    task.spawn(function()
        local placeId = game.PlaceId
        local curJob = game.JobId
        local cursor = ""
        local candidates = {}

        -- Fetch up to 2 pages of servers sorted by lowest players first
        for page = 1, 2 do
            local url = string.format(
                "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s",
                placeId,
                (cursor ~= "" and ("&cursor=" .. cursor) or "")
            )
            local ok, body = pcall(function() return game:HttpGet(url) end)
            if ok and body and type(body) == "string" and #body > 20 then
                local data = nil
                pcall(function() data = HttpService:JSONDecode(body) end)
                if data and data.data then
                    for _, s in ipairs(data.data) do
                        if s.id and s.id ~= curJob and s.playing and s.maxPlayers and s.playing < s.maxPlayers and s.playing > 0 then
                            table.insert(candidates, s)
                        end
                    end
                    cursor = data.nextPageCursor or ""
                end
            end
            if #candidates >= 15 or cursor == "" then
                break
            end
        end

        if #candidates == 0 then
            isServerHopping = false
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "Server Hop",
                    Content = "ไม่พบเซิร์ฟเวอร์ว่างอื่นในขณะนี้ กรุณาลองใหม่อีกครั้ง",
                    Duration = 3.5,
                    Icon = "alert-triangle"
                })
            end
            return
        end

        -- Sort ascending: lowest players first, then lowest ping
        table.sort(candidates, function(a, b)
            if a.playing ~= b.playing then
                return a.playing < b.playing
            end
            return (a.ping or 999) < (b.ping or 999)
        end)

        -- Pick among the top 3 lowest to avoid colliding on the exact same server
        local pickPool = math.min(3, #candidates)
        local targetServer = candidates[math.random(1, pickPool)]

        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "Server Hop Found!",
                Content = string.format("พบเซิร์ฟเวอร์: คนเล่น %d/%d คน (Ping: %s)\nกำลังเทเลพอร์ต...", targetServer.playing, targetServer.maxPlayers, tostring(targetServer.ping or "N/A")),
                Duration = 4,
                Icon = "zap"
            })
        end

        -- Prepare autoexecute across teleport
        pcall(function()
            local queueScript = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/Universal_Loader.luau?v=" .. tostring(os.time())))()'
            if syn and syn.queue_on_teleport then
                syn.queue_on_teleport(queueScript)
            elseif queue_on_teleport then
                queue_on_teleport(queueScript)
            end
        end)

        task.wait(0.6)

        local TeleportService = game:GetService("TeleportService")
        local tpOk, tpErr = pcall(function()
            TeleportService:TeleportToPlaceInstance(placeId, targetServer.id, LocalPlayer)
        end)

        if not tpOk then
            isServerHopping = false
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "Teleport Error",
                    Content = "เกิดข้อผิดพลาดในการย้ายเซิร์ฟเวอร์: " .. tostring(tpErr),
                    Duration = 4,
                    Icon = "alert-circle"
                })
            end
        end
    end)
end

local function rejoinCurrentServer()
    if WindUI and WindUI.Notify then
        WindUI:Notify({ Title = "Rejoining", Content = "กำลังรีจอยน์เซิร์ฟเวอร์เดิม...", Duration = 3, Icon = "rotate-cw" })
    end
    pcall(function()
        local queueScript = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/Universal_Loader.luau?v=" .. tostring(os.time())))()'
        if syn and syn.queue_on_teleport then
            syn.queue_on_teleport(queueScript)
        elseif queue_on_teleport then
            queue_on_teleport(queueScript)
        end
    end)
    task.wait(0.5)
    local TeleportService = game:GetService("TeleportService")
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end

-- Server Hop Background Timer Loop
task.spawn(function()
    while isScriptAlive() do
        task.wait(5)
        if isInsideDungeon() or isEnteringDungeon or isWaitingForParty then
            continue
        end
        if Config.ServerHopAuto then
            local now = os.clock()
            local intervalSecs = math.max(60, (tonumber(Config.ServerHopInterval) or 15) * 60)
            if serverHopNextTick == 0 then
                serverHopNextTick = now + intervalSecs
            end
            if now >= serverHopNextTick then
                serverHopNextTick = now + intervalSecs
                print(string.format("[Server Hop] ⏰ Interval reached (%d mins). Hopping to low-player server...", tonumber(Config.ServerHopInterval) or 15))
                serverHopLowPlayer(false)
            end
        else
            serverHopNextTick = 0
        end
    end
end)

-- ==================== SMART SKILLS & COMBAT ENGINE ====================
local skillLastCast = {}
local cachedHotbarSkills = {}
local lastGlobalSkillCast = 0
local lastCombatLootScan = 0
local evaluateAndCastBestSkill = nil

local function isSlotSelected(slotNum)
    local cfg = Config.SelectedSkillSlots
    if not cfg then return true end
    if type(cfg) ~= "table" then return true end

    local hasAny = false
    for _ in pairs(cfg) do
        hasAny = true
        break
    end
    if not hasAny then return false end

    local slotStr = tostring(slotNum)
    for k, v in pairs(cfg) do
        if v == true then
            if tostring(k):find(slotStr) then return true end
        elseif type(v) == "string" then
            if v:find(slotStr) then return true end
        elseif type(v) == "number" then
            if v == slotNum then return true end
        end
    end
    return false
end

local function getHotbarSkillInSlot(slotNum)
    local hotbarRaw = LocalPlayer:GetAttribute("HotbarJson")
    if not hotbarRaw or hotbarRaw == "" then return nil end
    local ok, hotbar = pcall(function() return HttpService:JSONDecode(hotbarRaw) end)
    if not ok or not hotbar then return nil end
    local item = hotbar[tostring(slotNum)]
    if type(item) == "string" and item:find("^skill:") then
        return item:sub(7)
    end
    return nil
end

-- Suppress the game's native bot from automatically firing unwanted skills
pcall(function()
    LocalPlayer:SetAttribute("BotUseSkills", false)
    LocalPlayer:SetAttribute("AutoSkill", false)
    if trackConn then
        trackConn(LocalPlayer:GetAttributeChangedSignal("BotUseSkills"):Connect(function()
            if LocalPlayer:GetAttribute("BotUseSkills") == true then
                LocalPlayer:SetAttribute("BotUseSkills", false)
            end
        end))
        trackConn(LocalPlayer:GetAttributeChangedSignal("AutoSkill"):Connect(function()
            if LocalPlayer:GetAttribute("AutoSkill") == true then
                LocalPlayer:SetAttribute("AutoSkill", false)
            end
        end))
    end
end)

local function updateHotbarCache()
    table.clear(cachedHotbarSkills)
    local hotbarRaw = LocalPlayer:GetAttribute("HotbarJson")
    if not hotbarRaw or hotbarRaw == "" then return end
    pcall(function()
        local decoded = HttpService:JSONDecode(hotbarRaw)
        if type(decoded) == "table" then
            for i = 1, 8 do
                local val = decoded[tostring(i)]
                if type(val) == "string" and val:find("^skill:") then
                    local sId = val:sub(7):lower()
                    local sData = SkillDataModule and SkillDataModule.Skills and SkillDataModule.Skills[sId]
                    local isBuff = (sData and (sData.Kind == "buff" or sData.Type == "buff" or sData.Buff ~= nil))
                    if not isBuff then
                        local buffNames = { meikyo = true, vanish = true, stealth = true, haste = true, blessing = true, increase_agi = true, endure = true }
                        if buffNames[sId] then isBuff = true end
                    end
                    local kind = sData and sData.Kind or (isBuff and "buff" or "active")
                    local range = sData and (sData.Range or sData.Radius or sData.Length) or 200
                    cachedHotbarSkills[i] = {
                        slotNum = i,
                        id = sId,
                        isBuff = isBuff,
                        kind = kind,
                        range = range,
                    }
                end
            end
        end
    end)
end

pcall(function()
    updateHotbarCache()
    if trackConn then
        trackConn(LocalPlayer:GetAttributeChangedSignal("HotbarJson"):Connect(updateHotbarCache))
    end
end)

local function isBuffActive(buffId)
    local raw = LocalPlayer:GetAttribute("BuffsJson")
    if not raw or raw == "" then return false end
    return raw:lower():find(buffId:lower()) ~= nil
end

local function isHotbarSlotReady(slotNum, sInfo)
    local ap = LocalPlayer.PlayerGui:FindFirstChild("LumiHotbar")
    local pad = ap and ap:FindFirstChild("ActionPad")
    local slot = pad and pad:FindFirstChild("Slot" .. slotNum)
    if not slot then return false end

    -- 1. Real UI cooldown inspection (text & shade frame)
    local cdLabel = slot:FindFirstChild("Cooldown")
    if cdLabel and cdLabel.Visible and cdLabel.Text ~= "" then
        return false
    end
    local shade = slot:FindFirstChild("CooldownShade")
    if shade and shade.Visible then
        return false
    end

    -- 2. Real SP Requirement
    local currentSp = LocalPlayer:GetAttribute("SP") or 999
    local itemCount = slot:FindFirstChild("ItemCount")
    if itemCount and itemCount.Text ~= "" then
        local spCost = tonumber(itemCount.Text:match("%d+"))
        if spCost and currentSp < spCost then
            return false
        end
    elseif currentSp < 4 then
        return false
    end

    -- 3. Safety micro-gap between repeated casts of same skill
    local now = os.clock()
    if (now - (skillLastCast[sInfo.id] or 0)) < 0.08 then
        return false
    end

    return true
end

local function executeSmartSkill(slotNum, sInfo, target)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local now = os.clock()

    -- Aim towards target immediately for line/cone/targeted attacks
    if target and target.Parent then
        local tHrp = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
        if tHrp then
            hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(tHrp.Position.X, hrp.Position.Y, tHrp.Position.Z))
        end
    end

    -- 1. Remote Fire to server
    if UseSkill then
        pcall(function()
            UseSkill:FireServer(sInfo.id, sInfo.isBuff and nil or target)
        end)
    end

    -- 2. Trigger Client Slot Button (plays native animations and sounds)
    pcall(function()
        local ap = LocalPlayer.PlayerGui:FindFirstChild("LumiHotbar")
        local pad = ap and ap:FindFirstChild("ActionPad")
        local slotBtn = pad and pad:FindFirstChild("Slot" .. slotNum)
        if slotBtn and getconnections then
            for _, conn in ipairs(getconnections(slotBtn.MouseButton1Down)) do
                pcall(function() conn:Fire() end)
            end
        end
    end)

    skillLastCast[sInfo.id] = now
    lastGlobalSkillCast = now
    return true
end

evaluateAndCastBestSkill = function(target)
    if not Config.AutoUseSkills then return false end
    if isEnteringDungeon or isWaitingForParty then return false end
    local now = os.clock()
    if (now - lastGlobalSkillCast) < 0.06 then return false end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local targetPos = target and (target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart) and (target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart).Position
    local distToTarget = targetPos and (hrp.Position - targetPos).Magnitude or math.huge

    local bestBuff = nil
    local bestBurst = nil
    local bestCounter = nil
    local bestSpam = nil
    local bestOther = nil

    for slotNum = 1, 7 do
        if isSlotSelected(slotNum) then
            local sInfo = cachedHotbarSkills[slotNum]
            if sInfo and isHotbarSlotReady(slotNum, sInfo) then
                if sInfo.isBuff then
                    -- Priority 1: Self Buffs (cast if missing)
                    if not isBuffActive(sInfo.id) and not bestBuff then
                        bestBuff = sInfo
                    end
                elseif target and isMonsterAlive(target) and distToTarget <= (sInfo.range or 200) then
                    -- Priority 2: AoE / Burst
                    if sInfo.kind == "aoe_self" or sInfo.kind == "aoe_target" or sInfo.id == "obororanbu" or sInfo.id == "magnum_break" or sInfo.id == "arrowshower" or sInfo.id == "bigkaboom" or sInfo.id == "thunderstorm" or sInfo.id == "cartstrike" then
                        if not bestBurst then bestBurst = sInfo end
                    -- Priority 3: Counter / Defensive
                    elseif sInfo.kind == "counter" or sInfo.id == "issen" then
                        if not bestCounter then bestCounter = sInfo end
                    -- Priority 4: Primary Spammer / Direct Hits (IAIGIRI etc.)
                    elseif sInfo.kind == "line" or sInfo.id == "iaigiri" or sInfo.id == "bash" or sInfo.id == "double_strafe" or sInfo.id:find("bolt") or sInfo.id == "twinfang" or sInfo.id == "venomknife" then
                        if not bestSpam then bestSpam = sInfo end
                    else
                        if not bestOther then bestOther = sInfo end
                    end
                end
            end
        end
    end

    local chosen = bestBuff or bestBurst or bestCounter or bestSpam or bestOther
    if chosen then
        return executeSmartSkill(chosen.slotNum, chosen, chosen.isBuff and nil or target)
    end
    return false
end

local function castSmartSkill(skillId, target)
    if not skillId or skillId == "" then return false end
    for slotNum, sInfo in pairs(cachedHotbarSkills) do
        if sInfo.id == skillId:lower() then
            if isHotbarSlotReady(slotNum, sInfo) then
                return executeSmartSkill(slotNum, sInfo, target)
            end
            return false
        end
    end
    if UseSkill then
        pcall(function() UseSkill:FireServer(skillId, target) end)
        return true
    end
    return false
end

local function getMobCluster(radius, maxCount)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return {}, nil end

    local folder = workspace:FindFirstChild("Monsters")
    if not folder then return {}, nil end

    local r = radius or Config.GatherRadius or 55
    local limit = maxCount or Config.MaxGatherCount or 6
    local candidates = {}

    for _, mob in ipairs(folder:GetChildren()) do
        if mob:IsA("Model") and isMonsterAlive(mob) then
            local mHrp = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
            if mHrp then
                local dist = (hrp.Position - mHrp.Position).Magnitude
                if dist <= r then
                    local allowed = true
                    if Config.SelectedMonster and Config.SelectedMonster ~= "All" then
                        if mob.Name ~= Config.SelectedMonster and not mob.Name:find(Config.SelectedMonster) then
                            allowed = false
                        end
                    end
                    if allowed then
                        table.insert(candidates, { mob = mob, pos = mHrp.Position, dist = dist })
                    end
                end
            end
        end
    end

    if #candidates == 0 then return {}, nil end

    table.sort(candidates, function(a, b) return a.dist < b.dist end)

    local selected = {}
    local centerSum = Vector3.zero
    local count = math.min(#candidates, limit)
    for i = 1, count do
        table.insert(selected, candidates[i].mob)
        centerSum = centerSum + candidates[i].pos
    end

    local avgPos = centerSum / count
    return selected, avgPos
end

local function castAllAoESkills(targetMob)
    if not Config.AutoUseSkills and not Config.AoEMultiBurst then return end
    evaluateAndCastBestSkill(targetMob)
end

isMonsterAlive = function(monster)
    if not monster or not monster.Parent then return false end
    if monster:GetAttribute("IsDummy") == true then return false end
    if monster:GetAttribute("Dead") == true or monster:GetAttribute("IsDead") == true or monster:GetAttribute("Dying") == true or monster:GetAttribute("dead") == true or monster:GetAttribute("isDead") == true then
        return false
    end
    -- If monster has an invulnerable seal barrier (e.g. Skull King during Seal Phase), drop target immediately
    if monster:GetAttribute("SealShield") == true then
        return false
    end
    local hpAttr = monster:GetAttribute("HP") or monster:GetAttribute("Hp") or monster:GetAttribute("Health") or monster:GetAttribute("health") or monster:GetAttribute("hp")
    if hpAttr ~= nil and tonumber(hpAttr) and tonumber(hpAttr) <= 0 then
        return false
    end
    local hum = monster:FindFirstChildOfClass("Humanoid")
    if hum then
        if hum.Health <= 0 then return false end
        local isDeadState = false
        pcall(function()
            if hum:GetState() == Enum.HumanoidStateType.Dead then
                isDeadState = true
            end
        end)
        if isDeadState then return false end
    end
    local mHrp = monster:FindFirstChild("HumanoidRootPart")
        or monster.PrimaryPart
        or monster:FindFirstChild("Base")
        or monster:FindFirstChild("Shaft")
        or monster:FindFirstChildOfClass("BasePart")
    return mHrp ~= nil
end

getMonsterCombatPart = function(monster)
    if not monster then return nil end
    return monster:FindFirstChild("HumanoidRootPart")
        or monster.PrimaryPart
        or monster:FindFirstChild("Base")
        or monster:FindFirstChild("Shaft")
        or monster:FindFirstChildOfClass("BasePart")
end

isBossMonster = function(monster)
    if not monster or not monster.Parent then return false end
    if monster:GetAttribute("IsBoss") == true then return true end
    if monster:GetAttribute("IsMiniBoss") == true then return true end
    if monster:GetAttribute("IsLeader") == true then return true end
    local name = monster.Name:lower()
    if name:find("boss") or name:find("king") or name:find("leader") or name:find("colossus") or name:find("pharaoh") or name:find("behemoth") or name:find("spider") or name:find("dragon") then
        return true
    end
    return false
end

getBossList = function()
    local list = {"All Bosses", "Pack Leaders Only"}
    local seen = {["All Bosses"] = true, ["Pack Leaders Only"] = true}
    local folder = workspace:FindFirstChild("Monsters")
    if folder then
        for _, m in ipairs(folder:GetChildren()) do
            if m:IsA("Model") and isBossMonster(m) and not seen[m.Name] then
                seen[m.Name] = true
                table.insert(list, m.Name)
            end
        end
    end
    local known = {
        "Gorilla King",
        "Whitefang Sabertooth",
        "Obsidian Pharaoh",
        "Tempest Dragon King",
        "Volcano Turtle King",
        "Pumpkin Spider",
        "Ram King",
        "Leader Fang Hyena",
        "Leader Saber Tiger",
        "Leader Spiked Stone Golem",
        "Leader Spiked Ice Golem",
    }
    for _, b in ipairs(known) do
        if not seen[b] then
            seen[b] = true
            table.insert(list, b)
        end
    end
    return list
end

-- currentCombatTarget unified at line 88

local function getTargetMonster()
    local char = LocalPlayer.Character
    if not char then 
        currentCombatTarget = nil
        return nil 
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then 
        currentCombatTarget = nil
        return nil 
    end

    local folder = workspace:FindFirstChild("Monsters")
    if not folder then 
        currentCombatTarget = nil
        return nil 
    end

    if isInsideDungeon() then
        return getDungeonTarget()
    end

    -- Check if player is currently in a boss arena
    local inBoss, bossArenaName = isPlayerInBossArena()

    -- Determine active field center
    local currentZonePos = nil
    if Config.CurrentZone and Config.CurrentZone ~= "" and (not inBoss or not Config.CurrentZone:find("Boss")) then
        currentZonePos = getZonePosition(Config.CurrentZone)
    else
        -- Dynamically detect the closest field to player
        local closestDist = math.huge
        for zName, zPos in pairs(ZoneCoordinates) do
            if not inBoss or not zName:find("Boss") then
                local d = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(zPos.X, 0, zPos.Z)).Magnitude
                if d < closestDist then
                    closestDist = d
                    currentZonePos = zPos
                end
            end
        end
    end

    -- 1. STICKINESS CHECK: Stick to current target until it dies to prevent target ping-pong / warping
    if currentCombatTarget and isMonsterAlive(currentCombatTarget) then
        local tHrp = currentCombatTarget:FindFirstChild("HumanoidRootPart") or currentCombatTarget.PrimaryPart
        if tHrp then
            local dist = (hrp.Position - tHrp.Position).Magnitude
            local currentIsBoss = isBossMonster(currentCombatTarget)

            if Config.BossOnly and not currentIsBoss then
                currentCombatTarget = nil
            elseif dist <= 140 then
                -- If we're fighting a normal mob and a boss is nearby with PrioritizeBoss, switch to boss
                if not currentIsBoss and (Config.PrioritizeBoss or Config.BossOnly) then
                    for _, mob in ipairs(folder:GetChildren()) do
                        if mob:IsA("Model") and isMonsterAlive(mob) and isBossMonster(mob) then
                            local bHrp = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
                            if bHrp and (hrp.Position - bHrp.Position).Magnitude <= 120 then
                                currentCombatTarget = mob
                                return mob
                            end
                        end
                    end
                end
                -- Stick to current target!
                return currentCombatTarget
            else
                currentCombatTarget = nil
            end
        else
            currentCombatTarget = nil
        end
    else
        currentCombatTarget = nil
    end

    -- 2. SEARCH NEW CANDIDATE: Find closest candidate within active zone
    local bestHalloween = nil
    local bestHalloweenDist = math.huge

    local bestBoss = nil
    local bestBossDist = math.huge

    local bestNormal = nil
    local bestNormalDist = math.huge
    local fallbackNormal = nil
    local fallbackNormalDist = math.huge

    for _, monster in ipairs(folder:GetChildren()) do
        if monster:IsA("Model") and isMonsterAlive(monster) then
            local mHrp = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart
            if mHrp then
                local distFromPlayer = (hrp.Position - mHrp.Position).Magnitude
                local inZone = true

                -- Ensure candidate belongs to active zone (within 270 studs of field zone center)
                if currentZonePos then
                    local distFromZoneCenter = (Vector3.new(mHrp.Position.X, 0, mHrp.Position.Z) - Vector3.new(currentZonePos.X, 0, currentZonePos.Z)).Magnitude
                    if distFromZoneCenter > 270 then
                        inZone = false
                    end
                end

                if inZone then
                    -- 🎃 Halloween Priority Matching (Pumpkins, Pumpkin Spider, Event Bosses)
                    if Config.AutoHalloween and Config.HuntHalloweenPumpkins then
                        local mName = monster.Name:lower()
                        local isPumpkin = monster:GetAttribute("HalloweenPumpkin") or mName:find("pumpkin") or mName:find("halloween")
                        if isPumpkin and distFromPlayer < bestHalloweenDist then
                            bestHalloweenDist = distFromPlayer
                            bestHalloween = monster
                        end
                    end

                    local isBoss = isBossMonster(monster)

                    -- Boss Candidate Matching
                    if isBoss and (Config.AutoBoss or Config.BossOnly or Config.PrioritizeBoss) then
                        local bossAllowed = false
                        if Config.SelectedBoss == "All Bosses" or not Config.SelectedBoss then
                            bossAllowed = true
                        elseif monster.Name == Config.SelectedBoss or string.find(monster.Name, Config.SelectedBoss) then
                            bossAllowed = true
                        elseif Config.SelectedBoss == "Pack Leaders Only" and monster:GetAttribute("IsLeader") then
                            bossAllowed = true
                        end

                        if bossAllowed and distFromPlayer < bestBossDist then
                            bestBossDist = distFromPlayer
                            bestBoss = monster
                        end
                    end

                    -- Normal Candidate Matching
                    if not Config.BossOnly and not isBoss then
                        local nameAllowed = false
                        if Config.SelectedMonster == "All" or not Config.SelectedMonster then
                            nameAllowed = true
                        elseif monster.Name == Config.SelectedMonster or string.find(monster.Name, Config.SelectedMonster) then
                            nameAllowed = true
                        end

                        if nameAllowed and distFromPlayer < bestNormalDist then
                            bestNormalDist = distFromPlayer
                            bestNormal = monster
                        end

                        -- Fallback to any normal monster in this field if name filter matches none
                        if distFromPlayer < fallbackNormalDist then
                            fallbackNormalDist = distFromPlayer
                            fallbackNormal = monster
                        end
                    end
                end
            end
        end
    end

    -- Return priority:
    if bestHalloween and Config.AutoHalloween and Config.HuntHalloweenPumpkins then
        currentCombatTarget = bestHalloween
        return bestHalloween
    end

    if bestBoss and (Config.PrioritizeBoss or Config.BossOnly or Config.AutoBoss) then
        currentCombatTarget = bestBoss
        trackBossDeath(bestBoss)
        activeBossFight = {
            model = bestBoss,
            name = bestBoss.Name,
            pos = (bestBoss:FindFirstChild("HumanoidRootPart") or bestBoss.PrimaryPart) and (bestBoss:FindFirstChild("HumanoidRootPart") or bestBoss.PrimaryPart).Position,
            time = os.clock(),
        }
        return bestBoss
    end

    if Config.BossOnly then
        currentCombatTarget = nil
        return nil
    end

    local finalTarget = bestNormal or fallbackNormal
    currentCombatTarget = finalTarget
    return finalTarget
end

local function getNearbyMonsters(radius)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end
    
    local results = {}
    local folder = workspace:FindFirstChild("Monsters")
    if not folder then return results end

    for _, monster in ipairs(folder:GetChildren()) do
        if monster:IsA("Model") and isMonsterAlive(monster) then
            local mHrp = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart
            if mHrp then
                local dist = (hrp.Position - mHrp.Position).Magnitude
                if dist <= radius then
                    table.insert(results, monster)
                end
            end
        end
    end
    return results
end

-- ==================== ADVANCED AUTO LOOT & STEALTH MAGNET VACUUM ====================
isLooting = false

performAutoLoot = function()
    if isLooting or isWarpingZone or isSelling or isEnteringDungeon or isWaitingForParty then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    local dropsFolder = workspace:FindFirstChild("Drops")
    if not dropsFolder then return end

    local allDrops = dropsFolder:GetChildren()
    if #allDrops == 0 then return end

    isLooting = true
    local maxLootDist = tonumber(Config.LootRadius) or 120
    local now = workspace:GetServerTimeNow()
    local validDrops = {}

    for _, drop in ipairs(allDrops) do
        local dropPart = drop:IsA("BasePart") and drop or (drop:IsA("Model") and (drop.PrimaryPart or drop:FindFirstChildWhichIsA("BasePart", true)))
        if dropPart and dropPart.Parent then
            local owner = drop:GetAttribute("OwnerUserId") or dropPart:GetAttribute("OwnerUserId")
            local freeAt = drop:GetAttribute("FreeAt") or dropPart:GetAttribute("FreeAt")
            local canPickup = true
            if owner and owner ~= 0 and owner ~= LocalPlayer.UserId then
                if freeAt and now < freeAt then
                    canPickup = false
                end
            end

            if canPickup then
                local dropDist = (dropPart.Position - hrp.Position).Magnitude
                if dropDist <= maxLootDist then
                    table.insert(validDrops, { obj = drop, part = dropPart, dist = dropDist })
                end
            end
        end
    end

    if #validDrops == 0 then
        isLooting = false
        return
    end

    -- Sort closest drops first
    table.sort(validDrops, function(a, b) return a.dist < b.dist end)

    -- 1. Smooth Stealth Magnet Pull: glide item drops directly into the character WITHOUT moving/warping the character
    if Config.StealthMagnetLoot ~= false then
        pcall(function()
            local targetPos = hrp.Position
            for _, dInfo in ipairs(validDrops) do
                local dp = dInfo.part
                if dp and dp.Parent then
                    dp.CanCollide = false
                    pcall(function() dp.Massless = true end)
                    if dInfo.dist > 4 then
                        -- Smoothly pull item toward character so it looks like a natural RPG magnet
                        local midPos = dp.Position:Lerp(targetPos, 0.65)
                        dp.CFrame = CFrame.new(midPos)
                    end
                end
            end
        end)
        task.wait(0.02)
        pcall(function()
            local targetCF = hrp.CFrame
            for _, dInfo in ipairs(validDrops) do
                local dp = dInfo.part
                if dp and dp.Parent then
                    dp.CanCollide = false
                    dp.CFrame = targetCF
                end
            end
        end)
    end

    -- 2. Remote Pickup Packet for all valid drops (Zero character movement)
    pcall(function()
        if RemotesLazy.PickupDrop then
            RemotesLazy.PickupDrop:FireServer(true)
            for _, dInfo in ipairs(validDrops) do
                if dInfo.part and dInfo.part.Parent then
                    RemotesLazy.PickupDrop:FireServer(dInfo.part)
                end
                if dInfo.obj and dInfo.obj ~= dInfo.part and dInfo.obj.Parent then
                    RemotesLazy.PickupDrop:FireServer(dInfo.obj)
                end
            end
        end
    end)

    -- 3. TouchInterest & ProximityPrompt trigger across all valid drops within LootRadius (Zero character movement)
    pcall(function()
        for _, dInfo in ipairs(validDrops) do
            local dp = dInfo.part
            if dp and dp.Parent then
                if firetouchinterest then
                    firetouchinterest(hrp, dp, 0)
                    firetouchinterest(hrp, dp, 1)
                end
                local prompt = dp:FindFirstChildOfClass("ProximityPrompt") or (dInfo.obj and dInfo.obj:FindFirstChildWhichIsA("ProximityPrompt", true))
                if prompt and prompt.Enabled then
                    pcall(function()
                        prompt.RequiresLineOfSight = false
                        prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance or 10, dInfo.dist + 20)
                    end)
                    if fireproximityprompt then
                        fireproximityprompt(prompt)
                    end
                end
            end
        end
    end)

    isLooting = false
end

isOpeningBox = false
local boxRecentAttempts = setmetatable({}, {__mode = "k"})

local function openLootBoxTarget(boxObj)
    if not boxObj or not boxObj.Parent then return false end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return false end

    -- 1. Identify Model and interactive BasePart (LootBox_relic_box)
    local boxModel = boxObj:IsA("Model") and boxObj or boxObj:FindFirstAncestorOfClass("Model")
    local boxPart = boxObj:IsA("BasePart") and boxObj or (boxModel and (boxModel:FindFirstChild("LootBox_relic_box") or boxModel.PrimaryPart or boxModel:FindFirstChildWhichIsA("BasePart")))
    if not boxPart then return false end

    -- 2. Skip already opened boxes
    if boxPart:GetAttribute("OpenTitle") ~= nil or boxPart:GetAttribute("Opened") == true then
        return false
    end
    if boxModel and (boxModel:GetAttribute("OpenTitle") ~= nil or boxModel:GetAttribute("Opened") == true) then
        return false
    end

    -- 3. Avoid spamming the exact same box in rapid succession, but allow retry after 1.2s
    local lastTry = boxRecentAttempts[boxPart] or 0
    if os.clock() - lastTry < 1.2 then
        return false
    end
    boxRecentAttempts[boxPart] = os.clock()

    -- 4. Ownership and FreeAt timer verification
    local owner = boxPart:GetAttribute("OwnerUserId") or (boxModel and boxModel:GetAttribute("OwnerUserId"))
    local freeAt = boxPart:GetAttribute("FreeAt") or (boxModel and boxModel:GetAttribute("FreeAt"))
    local now = workspace:GetServerTimeNow()
    if owner and owner ~= 0 and owner ~= LocalPlayer.UserId then
        if freeAt and now < freeAt then
            return false -- Wait until FreeAt timestamp unlocks it
        end
    end

    local boxPos = boxPart.Position
    local dist = (boxPos - hrp.Position).Magnitude
    local maxAllowed = tonumber(Config.LootRadius) or 120
    if dist > maxAllowed then return false end

    -- 5. Stealth Remote & Magnet Opening (Zero character teleport / no hrp.CFrame changes!)
    for attempt = 1, 3 do
        if not boxPart.Parent or boxPart:GetAttribute("OpenTitle") ~= nil or boxPart:GetAttribute("Opened") == true then
            break
        end

        pcall(function()
            if RemotesLazy.OpenLootBox then
                RemotesLazy.OpenLootBox:FireServer(boxPart)
                if boxModel then
                    RemotesLazy.OpenLootBox:FireServer(boxModel)
                end
            end
        end)

        pcall(function()
            if RemotesLazy.PickupDrop then
                RemotesLazy.PickupDrop:FireServer(true)
                RemotesLazy.PickupDrop:FireServer(boxPart)
            end
        end)

        pcall(function()
            local prompt = boxPart:FindFirstChildOfClass("ProximityPrompt") or (boxModel and boxModel:FindFirstChildWhichIsA("ProximityPrompt", true))
            if prompt then
                pcall(function()
                    prompt.RequiresLineOfSight = false
                    prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance or 12, dist + 25)
                end)
                if fireproximityprompt then
                    fireproximityprompt(prompt)
                else
                    prompt:InputHoldBegin()
                    task.wait(0.05)
                    prompt:InputHoldEnd()
                end
            end
        end)

        pcall(function()
            if firetouchinterest then
                firetouchinterest(hrp, boxPart, 0)
                task.wait()
                firetouchinterest(hrp, boxPart, 1)
            end
        end)

        task.wait(0.06)
    end

    return true
end

local function checkAllLootBoxes(customRadius)
    if isInsideDungeon() or isEnteringDungeon or isWaitingForParty then return end
    if not canScriptMoveOrWarp() then return end
    if isOpeningBox or isWarpingZone or isSelling then return end
    if not Config.AutoOpenLootBox and not Config.AutoHalloweenBoxes then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local maxDist = customRadius or (Config.AutoHalloweenBoxes and 250) or (Config.LootRadius or 120)
    local candidates = {}
    local seen = {}

    -- 1. Scan CollectionService tagged "LootBox" (LootBox_relic_box)
    pcall(function()
        for _, box in ipairs(CollectionService:GetTagged("LootBox")) do
            if box and box.Parent and not seen[box] then
                seen[box] = true
                local bPos = box:IsA("BasePart") and box.Position or box:GetPivot().Position
                local d = (bPos - hrp.Position).Magnitude
                if d <= maxDist then
                    table.insert(candidates, { obj = box, dist = d })
                end
            end
        end
    end)

    -- 2. Scan workspace children for Halloween Hard Worker Box & regular boxes
    pcall(function()
        for _, obj in ipairs(workspace:GetChildren()) do
            local name = obj.Name:lower()
            if name:find("relic_box") or name:find("lootbox") or name:find("chest") or name:find("hard_work") or name:find("hardwork") or obj:GetAttribute("IsLootBox") then
                if not seen[obj] then
                    seen[obj] = true
                    local bPos = obj:IsA("BasePart") and obj.Position or obj:GetPivot().Position
                    local d = (bPos - hrp.Position).Magnitude
                    if d <= maxDist then
                        table.insert(candidates, { obj = obj, dist = d })
                    end
                end
            end
        end
    end)

    -- 3. Scan workspace.Drops for any boxes dropped into Drops folder
    pcall(function()
        local dropsFolder = workspace:FindFirstChild("Drops")
        if dropsFolder then
            for _, obj in ipairs(dropsFolder:GetChildren()) do
                local name = obj.Name:lower()
                if name:find("box") or name:find("relic") then
                    if not seen[obj] then
                        seen[obj] = true
                        local d = (obj.Position - hrp.Position).Magnitude
                        if d <= maxDist then
                            table.insert(candidates, { obj = obj, dist = d })
                        end
                    end
                end
            end
        end
    end)

    if #candidates == 0 then return end

    -- Sort candidates by distance (closest first)
    table.sort(candidates, function(a, b) return a.dist < b.dist end)

    isOpeningBox = true
    for _, item in ipairs(candidates) do
        if item.obj and item.obj.Parent then
            openLootBoxTarget(item.obj)
            task.wait(0.06)
        end
    end
    isOpeningBox = false
end

local function checkLootBoxes()
    checkAllLootBoxes()
end


-- ==================== 🎃 HALLOWEEN EVENT SYSTEM ENGINE ====================
isKnockingHouse = false
isPullingGacha = false

local function getHalloweenInventory()
    local candy = 0
    local heads = 0
    pcall(function()
        local raw = LocalPlayer:GetAttribute("ItemsJson") or "{}"
        local items = HttpService:JSONDecode(raw)
        candy = tonumber(items["halloween_candy"]) or 0
        heads = tonumber(items["pumpkin_head"]) or 0
    end)
    return candy, heads
end

local function getClosestWitchHouse()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, math.huge end

    local map = workspace:FindFirstChild("Map")
    local folder = map and map:FindFirstChild("Halloween_TrickTreat")
    if not folder then return nil, math.huge end

    local closest = nil
    local closestDist = math.huge
    for _, house in ipairs(folder:GetChildren()) do
        local spot = house:FindFirstChild("KnockSpot", true)
        local pos = spot and spot.Position or house:GetPivot().Position
        local d = (hrp.Position - pos).Magnitude
        if d < closestDist then
            closestDist = d
            closest = house
        end
    end
    return closest, closestDist
end

local function performTrickTreat(forceVisit)
    if isKnockingHouse or isWarpingZone or isSelling or isEnteringDungeon or isWaitingForParty then return false end
    local candy, _ = getHalloweenInventory()
    if candy < 100 then return false end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local house, dist = getClosestWitchHouse()
    if not house then return false end

    local prompt = house:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not prompt then return false end

    local spot = (prompt.Parent:IsA("BasePart") and prompt.Parent) or house:FindFirstChild("KnockSpot", true)
    local spotPos = spot and spot.Position or house:GetPivot().Position

    -- If too far and forceVisit/TrickTreatAutoVisit is not enabled, do not warp
    if dist > 35 and not forceVisit and not Config.TrickTreatAutoVisit then
        return false
    end

    isKnockingHouse = true
    local savedCFrame = hrp.CFrame
    local success = false

    pcall(function()
        -- Approach knock spot smoothly
        if dist > 12 then
            hrp.CFrame = CFrame.lookAt(spotPos + Vector3.new(0, 1.5, 3), spotPos)
            task.wait(0.18)
        end

        if fireproximityprompt then
            fireproximityprompt(prompt)
            success = true
        end

        task.wait(0.35)

        -- If visited from far away, return to previous combat spot
        if dist > 30 and savedCFrame and hrp and hrp.Parent then
            hrp.CFrame = savedCFrame
            hrp.Velocity = Vector3.zero
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end)

    isKnockingHouse = false
    return success
end

local function performHalloweenGacha(pullCount)
    if isPullingGacha or not RemotesLazy.GachaPull then return false end
    local _, heads = getHalloweenInventory()
    local count = pullCount or ((Config.GachaPullType == "1x Pull (10 Heads)") and 1 or 10)
    local cost = (count == 1) and 10 or 100
    if heads < cost then return false end

    isPullingGacha = true
    local result = nil
    pcall(function()
        result = RemotesLazy.GachaPull:InvokeServer(count)
    end)
    isPullingGacha = false
    return result ~= nil
end

local function performHalloweenBoxVacuum()
    checkAllLootBoxes()
end


-- ==================== 🛡️ AUTO DODGE & EVASION ENGINE ====================
local lastDodgeTime = 0
isDodgingUntil = 0
local activeBossHazards = {}
currentSafeHoldTarget = nil
safeHoldUntil = 0
safeHoldReason = ""

-- Geometry helpers for Boss Skills & Telegraphs
local function isInsideCone(pos, cone)
    if not cone or not cone.Center or not cone.Dir then return false end
    local flatPos = Vector3.new(pos.X, 0, pos.Z)
    local flatCenter = Vector3.new(cone.Center.X, 0, cone.Center.Z)
    local diff = flatPos - flatCenter
    local dist = diff.Magnitude
    local reach = (cone.Radius or 20) + 3.0
    if dist > reach then return false end
    if dist < 1.2 then return true end

    local flatDir = Vector3.new(cone.Dir.X, 0, cone.Dir.Z)
    if flatDir.Magnitude < 0.05 then return false end
    flatDir = flatDir.Unit

    local toPlayer = diff.Unit
    local dot = toPlayer:Dot(flatDir)
    local halfAngle = cone.Half or 0.8
    return dot >= math.cos(halfAngle + 0.12)
end

local function isInsideCircle(pos, circle)
    if not circle or not circle.Center then return false end
    local flatPos = Vector3.new(pos.X, 0, pos.Z)
    local flatCenter = Vector3.new(circle.Center.X, 0, circle.Center.Z)
    local dist = (flatPos - flatCenter).Magnitude
    local rad = (circle.Radius or circle.Reach or 15) + 3.0
    return dist <= rad
end

local function isInsideBox(pos, box)
    if not box or not box.CFrame then return false end
    local rel = box.CFrame:PointToObjectSpace(pos)
    local hw = (box.Width or 10) / 2 + 3.0
    local hl = (box.Length or 10) / 2 + 3.0
    return math.abs(rel.X) <= hw and math.abs(rel.Z) <= hl
end

local function isInsideSafeCircle(pos, safeZone)
    if not safeZone or not safeZone.Center then return false end
    local flatPos = Vector3.new(pos.X, 0, pos.Z)
    local flatCenter = Vector3.new(safeZone.Center.X, 0, safeZone.Center.Z)
    local dist = (flatPos - flatCenter).Magnitude
    local rad = math.max(2.0, (safeZone.Radius or 8) - 1.5)
    return dist <= rad
end

-- Comprehensive Position Hazard Evaluator
local function evaluatePositionHazard(pos)
    local now = os.clock()
    for hazardKey, hazard in pairs(activeBossHazards) do
        if now > hazard.expireTime then
            activeBossHazards[hazardKey] = nil
        else
            local zones = hazard.zones
            -- 1. Check for Safe Zones (Green Circles)
            local safeZones = {}
            local hasSafeZone = false
            for _, z in ipairs(zones) do
                if z.Safe then
                    hasSafeZone = true
                    table.insert(safeZones, z)
                end
            end

            if hasSafeZone then
                local inSafe = false
                for _, sz in ipairs(safeZones) do
                    if isInsideSafeCircle(pos, sz) then
                        inSafe = true
                        break
                    end
                end
                if not inSafe then
                    return true, "Outside Green Circle", hazard, safeZones, nil
                end
            else
                -- 2. Check for Red Danger Ground
                for _, z in ipairs(zones) do
                    if not z.Safe then
                        if z.Kind == "cone" then
                            if isInsideCone(pos, z) then
                                return true, "Cone AoE: " .. tostring(hazard.skill), hazard, nil, z
                            end
                        elseif z.Kind == "circle" or (z.Center and z.Radius) then
                            if isInsideCircle(pos, z) then
                                return true, "Circle AoE: " .. tostring(hazard.skill), hazard, nil, z
                            end
                        elseif z.CFrame and (z.Width or z.Length) and not z.Room then
                            if isInsideBox(pos, z) then
                                return true, "Line/Box AoE: " .. tostring(hazard.skill), hazard, nil, z
                            end
                        elseif z.Room then
                            return true, "Room AoE: " .. tostring(hazard.skill), hazard, nil, z
                        end
                    end
                end
            end
        end
    end
    return false, nil, nil, nil, nil
end

local function calculateZoneEscape(pos, zone)
    local flatPos = Vector3.new(pos.X, 0, pos.Z)
    if zone.Kind == "cone" and zone.Center and zone.Dir then
        local flatDir = Vector3.new(zone.Dir.X, 0, zone.Dir.Z).Unit
        local perp = Vector3.new(-flatDir.Z, 0, flatDir.X).Unit
        local toPos = (flatPos - Vector3.new(zone.Center.X, 0, zone.Center.Z))
        local side = toPos:Dot(perp) >= 0 and 1 or -1
        local escapeDir = perp * side
        local escapeDist = math.max(16, (zone.Radius or 20) * 0.7)
        return escapeDir, escapeDist
    elseif zone.CFrame and (zone.Width or zone.Length) and not zone.Room then
        local rel = zone.CFrame:PointToObjectSpace(pos)
        local side = rel.X >= 0 and 1 or -1
        local escapeDir = (zone.CFrame.RightVector * side)
        escapeDir = Vector3.new(escapeDir.X, 0, escapeDir.Z).Unit
        local escapeDist = math.max(12, (zone.Width or 10) / 2 + 7 - math.abs(rel.X))
        return escapeDir, escapeDist
    elseif zone.Center then
        local flatCenter = Vector3.new(zone.Center.X, 0, zone.Center.Z)
        local diff = flatPos - flatCenter
        local escapeDir = diff.Magnitude > 0.1 and diff.Unit or Vector3.new(0, 0, 1)
        local escapeDist = math.max(16, (zone.Radius or 14) + 7 - diff.Magnitude)
        return escapeDir, escapeDist
    end
    return Vector3.new(0, 0, 1), 18
end

local function findNearestSafePosition(pos, preferredCandidate)
    if preferredCandidate and not evaluatePositionHazard(preferredCandidate) then
        return preferredCandidate
    end
    -- Search in 12 directions radially outwards
    local angles = {0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330}
    local radii = {16, 24, 32}
    for _, r in ipairs(radii) do
        for _, deg in ipairs(angles) do
            local rad = math.rad(deg)
            local offset = Vector3.new(math.cos(rad) * r, 0, math.sin(rad) * r)
            local cand = pos + offset + Vector3.new(0, 1.2, 0)
            if not evaluatePositionHazard(cand) then
                return cand
            end
        end
    end
    return pos + Vector3.new(0, 5, 0)
end

-- Backward compatibility aliases
local function isPositionInDangerZone(pos, zone)
    if not zone or zone.Safe then return false end
    if zone.Kind == "cone" then return isInsideCone(pos, zone) end
    if zone.Kind == "circle" or (zone.Center and zone.Radius) then return isInsideCircle(pos, zone) end
    if zone.CFrame and (zone.Width or zone.Length) and not zone.Room then return isInsideBox(pos, zone) end
    if zone.Room then return true end
    return false
end

local function getDangerEscapeVector(pos, zone)
    local dir = calculateZoneEscape(pos, zone)
    return dir
end

-- ==================== 🎯 SMART COMBAT OFFSET & BLINDSPOT CALCULATOR ====================
-- Exploits game mechanics so monsters CANNOT hit the player:
-- 1. Class Range: Ranged classes (Archer/Mage/Cleric) have 24-36.6 studs range vs Monster Melee 9 studs.
--    Standing at 13.5 - 15.5 studs guarantees normal monsters cannot initiate or land attacks (0 damage!).
-- 2. Vertical Overhead Blindspot: Ground monsters swing horizontally at ground plane (height ~3 studs).
--    Hovering at 5.5 - 7.0 studs overhead completely bypasses ground melee sweep hitboxes.
-- 3. Rear Facing Lock: Continuously positions behind monster LookVector, exploiting turning speed latency.
local function getSmartFarmOffset(target)
    local job = LocalPlayer:GetAttribute("Job") or ""
    local isRanged = (job == "Archer" or job == "Mage" or job == "Cleric" or LocalPlayer:GetAttribute("AttackType") == "ranged")
    local atkRange = tonumber(LocalPlayer:GetAttribute("AttackRange")) or (isRanged and 32 or 7)

    local isLeader = target and (target:GetAttribute("IsLeader") == true or target.Name:find("Leader"))
    local isBoss = target and (target:GetAttribute("IsBoss") == true or target:GetAttribute("IsMiniBoss") == true or target.Name:lower():find("boss") or target.Name:lower():find("witch"))
    local dist
    local height

    -- Walk Mode: Keep feet firmly on ground level (height = 0)
    if Config.FarmMode == "Walk" then
        height = 0.0
        if Config.AdaptiveDistance then
            if isRanged then
                dist = (isBoss or isLeader) and 15.0 or math.clamp(atkRange * 0.45, 12.0, 15.0)
            else
                dist = isBoss and 5.0 or (isLeader and 4.8 or math.clamp(Config.FarmDistance or 4.0, 3.2, 4.8))
            end
        else
            dist = isBoss and 5.0 or math.clamp(Config.FarmDistance or 4.5, 2.5, 20.0)
        end
        return dist, height, isRanged
    end

    local baseDist = tonumber(Config.FarmDistance) or 5.5
    local baseHeight = tonumber(Config.SafeFarmHeight) or 5.2
    if isBoss then
        if isRanged then
            dist = math.clamp(math.max(baseDist, 14.0), 12.0, 25.0)
            height = (Config.FarmMode == "Walk") and 0.0 or math.clamp(math.max(baseHeight, 6.0), 5.5, 10.0)
        else
            -- Melee classes (Samurai, Swordsman, Thief) MUST be within weapon reach (atkRange ~7 studs)!
            dist = math.clamp(Config.FarmDistance or 5.0, 3.5, math.min(atkRange - 1.2, 5.5))
            height = (Config.FarmMode == "Walk") and 0.0 or math.clamp(baseHeight, 1.5, 4.5)
        end
    else
        dist = math.clamp(baseDist, 3.0, 25.0)
        height = (Config.FarmMode == "Walk") and 0.0 or math.clamp(baseHeight, 0.5, 15.0)
    end

    return dist, height, isRanged
end

local function performDodge(reason, evadeDir, customDist, customDuration, sourceMob, targetOverridePos)
    if not isScriptAlive() or not canScriptMoveOrWarp() or not Config.AutoDodge then return false end
    if Config.FarmMode == "Walk" then
        -- Allow dodging lethal boss telegraphs, green circles, and pre-cast skills in Walk Mode to save player's life!
        if not (reason and (reason:find("Safe Green Circle") or reason:find("Boss Telegraph") or reason:find("Pre-Cast") or reason:find("Pre-Hit") or reason:find("Manual Test"))) then
            return false
        end
    end

    local inDungeon = isInsideDungeon()
    local isCombatActive = inDungeon and (Config.AutoDungeon and Config.AutoFarm) or Config.AutoFarm
    if not isCombatActive and not (reason and reason:find("Manual Test")) then
        return false
    end

    local now = os.clock()

    -- In Dungeon: Suppress erratic non-boss dodges to prevent corridor wall pin & rapid teleport tags!
    if isInsideDungeon() then
        local isAllowed = false
        if reason and (reason:find("Safe Green Circle") or reason:find("Boss Telegraph") or reason:find("Manual Test")) then
            isAllowed = true
        end
        if not isAllowed then
            return false
        end
    end

    -- Do NOT let low priority dodges interrupt safe green circle holding!
    if currentSafeHoldTarget and safeHoldReason == "green" and now < safeHoldUntil then
        if reason and (reason:find("Flank") or reason:find("Pre-Hit")) then
            return false
        end
    end

    local cd = Config.DodgeCooldown or 0.25
    if (now - lastDodgeTime) < cd and not targetOverridePos then return false end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return false end

    lastDodgeTime = now
    local dodgeDist = customDist or Config.DodgeDistance or 18
    local inBossArena = (hrp.Position.Z < -200 or hrp.Position.X < -4100)
    if isInsideDungeon() and not inBossArena then
        dodgeDist = math.min(dodgeDist, 6)
    end
    local evadeVec = evadeDir and Vector3.new(evadeDir.X, 0, evadeDir.Z)
    if not evadeVec or evadeVec.Magnitude < 0.1 then
        evadeVec = -hrp.CFrame.LookVector
    end
    evadeVec = evadeVec.Unit

    -- 1. Ensure stamina is filled so dash remote succeeds 100%
    pcall(function()
        LocalPlayer:SetAttribute("LumiStamina", 100)
        LocalPlayer:SetAttribute("LumiStaminaEmpty", false)
    end)

    -- 2. Call game-native Dash Remote (triggers server dash, i-frames, sound & animations)
    pcall(function()
        if RemotesLazy.Dash then
            RemotesLazy.Dash:FireServer()
        end
    end)

    -- 3. Lock evasion state to prevent combat loop from snapping player back early
    local holdDur = customDuration or Config.DodgeDuration or 0.45
    isDodgingUntil = math.max(isDodgingUntil, now + holdDur)

    -- 4. Calculate target dodge position
    local startPos = hrp.Position
    local targetDodgePos = targetOverridePos
    if not targetDodgePos then
        local upOffset = (Config.FarmMode == "Walk") and 0.0 or 1.2
        targetDodgePos = startPos + (evadeVec * dodgeDist) + Vector3.new(0, upOffset, 0)
    end
    if isInsideDungeon() or Config.FarmMode == "Walk" then
        local floorY = (targetOverridePos and targetOverridePos.Y) or startPos.Y
        targetDodgePos = Vector3.new(targetDodgePos.X, floorY, targetDodgePos.Z)
    end

    task.spawn(function()
        local steps = 4
        for i = 1, steps do
            if not char or not hrp.Parent then break end
            local alpha = i / steps
            local nextPos = startPos:Lerp(targetDodgePos, alpha)
            local facePos = nextPos + evadeVec
            if sourceMob then
                local sHrp = sourceMob:FindFirstChild("HumanoidRootPart") or sourceMob.PrimaryPart
                if sHrp then facePos = sHrp.Position end
            end
            if isInsideDungeon() or Config.FarmMode == "Walk" then
                nextPos = Vector3.new(nextPos.X, startPos.Y, nextPos.Z)
            end
            hrp.CFrame = CFrame.lookAt(nextPos, facePos)
            hrp.Velocity = Vector3.zero
            hrp.AssemblyLinearVelocity = Vector3.zero
            task.wait(0.015)
        end
        if hrp and hrp.Parent then
            local floorY = (targetOverridePos and targetOverridePos.Y) or startPos.Y
            local finalPos = (isInsideDungeon() or Config.FarmMode == "Walk") and Vector3.new(targetDodgePos.X, floorY, targetDodgePos.Z) or targetDodgePos
            hrp.CFrame = CFrame.new(finalPos)
            hrp.Velocity = Vector3.zero
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end)

    -- 5. Notification feedback if enabled
    if Config.DodgeNotify and WindUI and WindUI.Notify then
        WindUI:Notify({
            Title = "⚡ Auto Dodge 1000%",
            Content = "หลบการโจมตีสำเร็จ! (" .. (reason or "Hazard") .. ")",
            Duration = 1.5,
            Icon = "shield-alert",
        })
    end
    return true
end

-- Active Safe Hold Enforcer & Anti-Gravity Drift Lock
trackConn(RunService.Heartbeat:Connect(function()
    if not isScriptAlive() or not canScriptMoveOrWarp() then
        currentSafeHoldTarget = nil
        return
    end
    local now = os.clock()
    if Config.AutoDodge and currentSafeHoldTarget and now < safeHoldUntil then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hrp and hum and hum.Health > 0 then
            local flatHrp = Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
            local flatTarget = Vector3.new(currentSafeHoldTarget.X, 0, currentSafeHoldTarget.Z)
            if (flatHrp - flatTarget).Magnitude > 2.5 then
                hrp.CFrame = CFrame.new(currentSafeHoldTarget)
                hrp.Velocity = Vector3.zero
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end
    elseif currentSafeHoldTarget and now >= safeHoldUntil then
        currentSafeHoldTarget = nil
        safeHoldReason = ""
    end

    -- Zero out downward velocity during Safe Farm so player never sinks into monster hitbox (Only in Fly Mode)
    if Config.AutoFarm and Config.SafeFarm and (Config.FarmMode ~= "Walk") and not (currentSafeHoldTarget and now < safeHoldUntil) then
        local curTgt = LocalPlayer:FindFirstChild("CurrentTarget") and LocalPlayer.CurrentTarget.Value
        if curTgt and curTgt.Parent and (curTgt:GetAttribute("HP") or 0) > 0 then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end
end))

-- ==================== 1000% PRE-HIT TELEGRAPH DETECTION (ANIMATTACK & ANIMSKILL) ====================
local trackedMonsterConns = {}

local function hookMonsterEvasion(mob)
    if not mob or not mob:IsA("Model") or trackedMonsterConns[mob] then return end
    local conns = {}
    trackedMonsterConns[mob] = conns

    -- 1. Hook normal attack windup (AnimAttack) - Server sets this attribute at the exact moment the mob swings!
    local attackConn = mob:GetAttributeChangedSignal("AnimAttack"):Connect(function()
        if not Config.AutoDodge or not Config.DodgeMonsterAttack then return end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end

        local mHrp = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
        if not mHrp then return end

        local dist = (mHrp.Position - hrp.Position).Magnitude
        local threat = mob:GetAttribute("ThreatUserId")
        local isTargetingMe = (threat == LocalPlayer.UserId)

        -- Check if mob is targeting local player or in dangerous melee reach
        if isTargetingMe or dist <= 14 then
            local mobLook = mHrp.CFrame.LookVector
            local toPlayer = (hrp.Position - mHrp.Position)
            local isFacingPlayer = (toPlayer.Magnitude > 0.1) and (mobLook:Dot(toPlayer.Unit) > 0.25)

            -- If mob is facing us, slip behind it immediately while staying within safe exploit reach!
            if isFacingPlayer then
                local animSet = mob:GetAttribute("AnimSet")
                local attackTime = 0.35
                if animSet and MonsterAnimModule and MonsterAnimModule.Sets and MonsterAnimModule.Sets[animSet] then
                    attackTime = MonsterAnimModule.Sets[animSet].AttackTime or 0.35
                end

                local safeDist, safeHeight = getSmartFarmOffset(mob)
                local targetPos = mHrp.Position - (mobLook * safeDist) + Vector3.new(0, safeHeight, 0)
                performDodge("Pre-Hit Flank: " .. mob.Name, -mobLook, safeDist, attackTime + 0.05, mob, targetPos)
            end
        end
    end)

    table.insert(conns, attackConn)

    -- 2. Hook monster skill cast (AnimSkill) - Pre-warns special boss/mob attacks
    local skillConn = mob:GetAttributeChangedSignal("AnimSkill"):Connect(function()
        if not Config.AutoDodge or not Config.DodgeMonsterSkill then return end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end

        local mHrp = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
        if not mHrp then return end

        local dist = (mHrp.Position - hrp.Position).Magnitude
        local threat = mob:GetAttribute("ThreatUserId")
        if threat == LocalPlayer.UserId or dist <= 18 then
            local skillDur = tonumber(mob:GetAttribute("AnimSkillTime")) or 1.2
            local skillName = mob:GetAttribute("AnimSkillName") or "MonsterSkill"
            local toPlayer = (hrp.Position - mHrp.Position)
            local escapeVec = (toPlayer.Magnitude > 0.5) and toPlayer.Unit or -mHrp.CFrame.LookVector

            -- Vault backwards and high out of skill radius
            local safeDist = math.max(18, (mob:GetAttribute("Radius") or 5) + 12)
            local targetPos = hrp.Position + (escapeVec * safeDist) + Vector3.new(0, 3.2, 0)
            performDodge("Pre-Skill: " .. tostring(skillName), escapeVec, safeDist, skillDur + 0.15, mob, targetPos)
        end
    end)
    table.insert(conns, skillConn)

    -- Disconnect on monster despawn / removal
    local ancConn
    ancConn = mob.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if ancConn then ancConn:Disconnect() end
            for _, c in ipairs(conns) do
                pcall(function() c:Disconnect() end)
            end
            trackedMonsterConns[mob] = nil
        end
    end)
    table.insert(conns, ancConn)
end

-- Hook all existing monsters and auto-listen for new spawns
for _, mob in ipairs(CollectionService:GetTagged("Monster")) do
    task.spawn(hookMonsterEvasion, mob)
end
do
    local monstersFolder = workspace:FindFirstChild("Monsters")
if monstersFolder then
    for _, mob in ipairs(monstersFolder:GetChildren()) do
        if mob:IsA("Model") then
            task.spawn(hookMonsterEvasion, mob)
    end
end
    end
    trackConn(monstersFolder.ChildAdded:Connect(function(mob)
        if not isScriptAlive() then return end
        if mob:IsA("Model") then
            task.spawn(hookMonsterEvasion, mob)
        end
    end))
end
trackConn(CollectionService:GetInstanceAddedSignal("Monster"):Connect(hookMonsterEvasion))

-- Boss AoE Telegraph Danger Detection (BossFx)
pcall(function()
    if RemotesLazy.BossFx then
        trackConn(RemotesLazy.BossFx.OnClientEvent:Connect(function(action, bossModel, skillName, zones, duration)
            if not isScriptAlive() or not canScriptMoveOrWarp() or not Config.AutoDodge then return end
            local inDungeon = isInsideDungeon()
            local hazardKey = tostring(bossModel) .. "|" .. tostring(skillName)

            if action == "warn" and type(zones) == "table" then
                if inDungeon and (tostring(skillName):lower():find("inferno") or tostring(skillName):lower():find("brazier") or tostring(skillName):lower():find("judgment")) then
                    task.spawn(checkLightBraziers)
                elseif inDungeon and tostring(skillName):lower():find("skull bomb") then
                    task.delay(0.8, function()
                        if Config.AutoKickSkulls then
                            checkKickDudSkulls()
                        end
                    end)
                end

                local dur = tonumber(duration) or 2.0
                local hazard = {
                    boss = bossModel,
                    skill = skillName,
                    zones = zones,
                    duration = dur,
                    startTime = os.clock(),
                    expireTime = os.clock() + dur,
                }
                activeBossHazards[hazardKey] = hazard

                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local pPos = hrp.Position

                -- 1. Check if this boss skill spawns Safe Zones (🟢 GREEN CIRCLES)
                local safeZones = {}
                for _, z in ipairs(zones) do
                    if z.Safe and z.Center then
                        table.insert(safeZones, z)
                    end
                end

                if #safeZones > 0 then
                    -- 🟢 GREEN SAFE CIRCLE DETECTED!
                    if Config.DodgeGreenCircle or inDungeon then
                        local bestZone = nil
                        local bestDist = math.huge
                        for _, sz in ipairs(safeZones) do
                            local d = (Vector3.new(pPos.X, 0, pPos.Z) - Vector3.new(sz.Center.X, 0, sz.Center.Z)).Magnitude
                            if d < bestDist then
                                bestDist = d
                                bestZone = sz
                            end
                        end

                        if bestZone then
                            local targetPos = bestZone.Center + Vector3.new(0, 1.2, 0)
                            local holdDur = dur + 0.35
                            currentSafeHoldTarget = targetPos
                            safeHoldUntil = os.clock() + holdDur
                            safeHoldReason = "green"
                            isDodgingUntil = math.max(isDodgingUntil, safeHoldUntil)

                            performDodge("🟢 Safe Green Circle (" .. tostring(skillName or "Boss Skill") .. ")", (targetPos - pPos).Unit, bestDist, holdDur, nil, targetPos)

                            if WindUI and WindUI.Notify then
                                WindUI:Notify({
                                    Title = "🟢 Auto Dodge: Safe Zone",
                                    Content = "วิ่งหลบเข้าวงกลมสีเขียวของ " .. tostring(bossModel) .. " ทันที!",
                                    Duration = 2.5,
                                    Icon = "shield-check",
                                    Duration = 2.5,
                                })
                            end
                        end
                    end
                elseif Config.DodgeBossTelegraph or inDungeon then
                    -- 🔴 RED GROUND DANGER ZONES (Cone, Circle, Line/Box, Room)
                    local inDanger, reason, _, _, triggerZone = evaluatePositionHazard(pPos)
                    if inDanger and triggerZone then
                        local escapeDir, escapeDist = calculateZoneEscape(pPos, triggerZone)
                        local candidatePos = pPos + (escapeDir * escapeDist) + Vector3.new(0, 1.2, 0)
                        candidatePos = findNearestSafePosition(pPos, candidatePos)

                        local holdDur = dur + 0.35
                        currentSafeHoldTarget = candidatePos
                        safeHoldUntil = os.clock() + holdDur
                        safeHoldReason = "red"
                        isDodgingUntil = math.max(isDodgingUntil, safeHoldUntil)

                        performDodge("🔴 Boss Telegraph: " .. tostring(skillName or "AoE"), escapeDir, escapeDist, holdDur, nil, candidatePos)
                    end
                end
            elseif action == "hit" or action == "cancel" then
                activeBossHazards[hazardKey] = nil
                local anyActive = false
                local now = os.clock()
                for k, h in pairs(activeBossHazards) do
                    if now <= h.expireTime then
                        anyActive = true
                        break
                    else
                        activeBossHazards[k] = nil
                    end
                end
                if not anyActive then
                    currentSafeHoldTarget = nil
                    safeHoldReason = ""
                    safeHoldUntil = 0
                    isDodgingUntil = math.min(isDodgingUntil, os.clock() + 0.1)
                end
            end
        end))
    end
end)

-- Monster Projectile Detection (MonsterProjectile)
pcall(function()
    if RemotesLazy.MonsterProjectile then
        trackConn(RemotesLazy.MonsterProjectile.OnClientEvent:Connect(function(mob, targetChar, speed)
            if not isScriptAlive() or not canScriptMoveOrWarp() or not Config.AutoDodge or not Config.DodgeProjectiles then return end
            if targetChar == LocalPlayer.Character then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local mHrp = mob and (mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart)
                if hrp and mHrp then
                    local toPlayer = (hrp.Position - mHrp.Position)
                    local sideDir = Vector3.new(-toPlayer.Z, 0, toPlayer.X)
                    if math.random() > 0.5 then
                        sideDir = -sideDir
                    end
                    local flightTime = tonumber(speed) or 0.45
                    performDodge("Monster Projectile", sideDir.Unit, 16, flightTime + 0.15)
                end
            end
        end))
    end
end)

-- Health & Damage Spike Monitor (Emergency Reactive Dodge)
local lastKnownHealth = nil
local function setupDodgeHealthMonitor(char)
    local hum = char and char:WaitForChild("Humanoid", 5)
    if not hum then return end
    lastKnownHealth = hum.Health

    hum.HealthChanged:Connect(function(newHp)
        if not Config.AutoDodge or not Config.DodgeOnHurt then return end
        if lastKnownHealth and newHp < lastKnownHealth then
            local dmgTaken = lastKnownHealth - newHp
            if dmgTaken >= (hum.MaxHealth * 0.05) or (newHp < (hum.MaxHealth * 0.4) and dmgTaken >= (hum.MaxHealth * 0.02)) then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local escape = -hrp.CFrame.LookVector
                    performDodge("Damage Reaction", escape, 18, 0.45)
                end
            end
        end
        lastKnownHealth = newHp
    end)
end

if LocalPlayer.Character then
    task.spawn(setupDodgeHealthMonitor, LocalPlayer.Character)
end
trackConn(LocalPlayer.CharacterAdded:Connect(function(newChar)
    setupDodgeHealthMonitor(newChar)
    if isEnteringDungeon or isWaitingForParty then
        isEnteringDungeon = false
        isWaitingForParty = false
    end
end))


-- ==================== SMART AUTO SELL HELPER FUNCTIONS ====================
local function getSellableItems()
    local lp = LocalPlayer
    local hs = HttpService
    local gearRaw = lp:GetAttribute("GearJson") or "{}"
    local itemsRaw = lp:GetAttribute("ItemsJson") or "{}"
    local locksRaw = lp:GetAttribute("LocksJson") or "[]"
    local equipRaw = lp:GetAttribute("EquipJson") or "{}"
    local refineRaw = lp:GetAttribute("RefineJson") or "{}"
    local weaponId = lp:GetAttribute("WeaponId")
    
    local gearTable = {}
    local itemsTable = {}
    local locksTable = {}
    local equipTable = {}
    local refineTable = {}

    pcall(function() gearTable = hs:JSONDecode(gearRaw) or {} end)
    pcall(function() itemsTable = hs:JSONDecode(itemsRaw) or {} end)
    pcall(function() locksTable = hs:JSONDecode(locksRaw) or {} end)
    pcall(function() equipTable = hs:JSONDecode(equipRaw) or {} end)
    pcall(function() refineTable = hs:JSONDecode(refineRaw) or {} end)
    
    local lockedMap = {}
    if type(locksTable) == "table" then
        for k, id in pairs(locksTable) do
            lockedMap[tostring(id)] = true
            lockedMap[tostring(k)] = true
        end
    end
    
    local equippedMap = {}
    if weaponId and weaponId ~= "" then
        equippedMap[weaponId] = true
    end
    if type(equipTable) == "table" then
        for _, id in pairs(equipTable) do
            if id and id ~= "" then
                equippedMap[id] = true
            end
        end
    end

    local itemData = ItemDataModule
    if not itemData then
        pcall(function() itemData = require(ReplicatedStorage.Shared.ItemData) end)
    end
    local gearUtil = GearUtilModule
    if not gearUtil then
        pcall(function() gearUtil = require(ReplicatedStorage.Shared.GearUtil) end)
    end

    -- Protection list: Valuable materials, potions, stones, boxes, keys, eggs
    local protectedItems = {
        ["red_potion"] = true,
        ["red_potion_m"] = true,
        ["white_potion"] = true,
        ["blue_potion"] = true,
        ["refine_stone"] = true,
        ["protection_stone"] = true,
        ["drop_potion"] = true,
        ["exp_potion"] = true,
        ["awakening_potion"] = true,
        ["concentration_potion"] = true,
        ["berserk_potion"] = true,
        ["lock_charm"] = true,
        ["halloween_candy"] = true,
        ["pumpkin_head"] = true,
        ["colossus_core"] = true,
        ["card_box"] = true,
        ["relic_box"] = true,
        ["egg"] = true,
    }

    local maxTierNum = 3
    if Config.MaxSellTier == "Tier 1 Only" then
        maxTierNum = 1
    elseif Config.MaxSellTier == "Up to Tier 2" then
        maxTierNum = 2
    elseif Config.MaxSellTier == "Up to Tier 3" then
        maxTierNum = 3
    elseif Config.MaxSellTier == "Up to Tier 4" then
        maxTierNum = 4
    elseif Config.MaxSellTier == "Up to Tier 5" then
        maxTierNum = 5
    elseif Config.MaxSellTier == "Custom Toggles Below" then
        maxTierNum = 999
    end

    local function isRarityAllowed(r)
        local cfg = Config.SellRarities
        if not cfg then
            local maxR = 2
            if Config.MaxSellRarity == "Common Only" then maxR = 0
            elseif Config.MaxSellRarity == "Up to Uncommon" then maxR = 1
            elseif Config.MaxSellRarity == "Up to Rare" then maxR = 2
            elseif Config.MaxSellRarity == "All Rarities" then maxR = 999 end
            local rN = tonumber(r) or 0
            return rN <= maxR
        end

        if type(cfg) ~= "table" then return false end

        local rNum = tonumber(r)
        local rStr = tostring(r):lower()

        for k, v in pairs(cfg) do
            local opt = ""
            if v == true then
                opt = tostring(k):lower()
            elseif type(v) == "string" then
                opt = v:lower()
            end

            if opt ~= "" then
                if (rNum == 0 or rStr:find("common")) and opt:find("common") and not opt:find("uncommon") then
                    return true
                elseif (rNum == 1 or rStr:find("uncommon")) and opt:find("uncommon") then
                    return true
                elseif (rNum == 2 or rStr:find("rare")) and opt:find("rare") then
                    return true
                elseif (rNum == 3 or rStr:find("epic")) and opt:find("epic") then
                    return true
                elseif (rNum == 4 or rStr:find("legendary") or rStr:find("legend")) and (opt:find("legendary") or opt:find("legend")) then
                    return true
                elseif (rNum and rNum >= 5 or rStr:find("mythic") or rStr:find("god") or rStr:find("red")) and (opt:find("mythic") or opt:find("red")) then
                    return true
                end
            end
        end
        return false
    end

    local sellIds = {}
    local sellList = {}
    local totalEstimatedSilver = 0

    -- 1. Scan Gear in GearJson
    if type(gearTable) == "table" then
        for refKey, gdata in pairs(gearTable) do
            if not equippedMap[refKey] and not lockedMap[refKey] then
                local resolved = gearUtil and gearUtil.Resolve and gearUtil.Resolve(refKey, gearTable)
                local tier = (resolved and resolved.Tier) or gdata.T or 1
                local rarity = (resolved and resolved.Rarity) or gdata.R or 0
                local refLevel = (refineTable and refineTable[refKey]) or gdata.Ref or 0

                -- Never sell refined gear if protection is on
                if not (Config.ProtectRefined and refLevel > 0) then
                    -- Tier filter
                    local tierAllowed = false
                    if Config.MaxSellTier == "Custom Toggles Below" then
                        if tier == 1 and Config.SellTier1 then tierAllowed = true end
                        if tier == 2 and Config.SellTier2 then tierAllowed = true end
                        if tier == 3 and Config.SellTier3 then tierAllowed = true end
                        if tier == 4 and Config.SellTier4 then tierAllowed = true end
                        if tier == 5 and Config.SellTier5 then tierAllowed = true end
                    else
                        if tier <= maxTierNum then
                            tierAllowed = true
                        end
                    end

                    -- Rarity filter
                    local rarityAllowed = isRarityAllowed(rarity)

                    if tierAllowed and rarityAllowed then
                        local kind = (resolved and resolved.Kind) or ""
                        local baseId = gdata.Id or (resolved and resolved.BaseId) or ""
                        local itemDef = (itemData and itemData[baseId]) or resolved

                        local categoryAllowed = false
                        if kind == "weapon" then
                            if Config.SellWeapons then categoryAllowed = true end
                        elseif kind == "armor" or kind == "body" then
                            if Config.SellArmors then categoryAllowed = true end
                        else
                            -- Accessories, Helmets, Cloaks, Boots, Rings, Sub-weapons, Flasks
                            if Config.SellAccessories or Config.SellArmors then categoryAllowed = true end
                        end

                        if categoryAllowed then
                            local sellBonus = lp:GetAttribute("SellBonusPct") or 0
                            local basePrice = (resolved and resolved.Sell) or (itemDef and itemDef.Sell) or 25
                            local price = math.floor(basePrice * (100 + sellBonus) / 100)

                            table.insert(sellIds, refKey)
                            table.insert(sellList, {
                                Id = refKey,
                                Count = 1,
                                Name = (resolved and resolved.Name) or (itemDef and itemDef.Name) or baseId,
                                Price = price,
                                IsGear = true,
                                Tier = tier,
                                Rarity = rarity,
                            })
                            totalEstimatedSilver = totalEstimatedSilver + price
                        end
                    end
                end
            end
        end
    end

    -- 2. Scan Monster Drops in ItemsJson
    if Config.SellJunkDrops and type(itemsTable) == "table" then
        local sellBonus = lp:GetAttribute("SellBonusPct") or 0
        for itemId, count in pairs(itemsTable) do
            if type(count) == "number" and count > 0 and not lockedMap[itemId] and not protectedItems[itemId] then
                -- Check if it's not a card or potion
                if not itemId:find("^card_") and not itemId:find("potion") and not itemId:find("scroll") and not itemId:find("stone") then
                    local def = itemData and itemData[itemId]
                    if def and type(def) == "table" and (def.Kind == "etc" or def.Kind == "drop" or (def.Sell and def.Sell > 0)) then
                        local unitPrice = math.floor((def.Sell or 1) * (100 + sellBonus) / 100)
                        local linePrice = unitPrice * count
                        table.insert(sellIds, itemId)
                        table.insert(sellList, {
                            Id = itemId,
                            Count = count,
                            Name = def.Name or itemId,
                            Price = linePrice,
                            IsGear = false,
                        })
                        totalEstimatedSilver = totalEstimatedSilver + linePrice
                    end
                end
            end
        end
    end

    return sellList, sellIds, totalEstimatedSilver
end

local function executeAutoSell(silent)
    if not canScriptMoveOrWarp() or not Config.AutoSell or isInsideDungeon() or isEnteringDungeon or isWaitingForParty then return end
    if isSelling then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    isSelling = true

    local sellList, sellIds, estSilver = getSellableItems()
    if #sellIds == 0 then
        if not silent and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "Auto Sell",
                Content = "ไม่มีไอเทมตรงตามระดับที่เลือกให้ขาย",
                Duration = 2,
                Icon = "check-circle",
            })
        end
        isSelling = false
        return
    end

    -- Disengage combat target during selling to prevent rubberband
    setClientCurrentTarget(nil)

    local merchantModel = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("NPCs") and workspace.Map.NPCs:FindFirstChild("merchant")
    local mPivot = merchantModel and merchantModel:GetPivot()
    local merchantPos = mPivot and mPivot.Position or Vector3.new(-50.4, 4.7, 30.5)

    local isPremium = LocalPlayer:GetAttribute("Premium") == true
    local currentDist = (hrp.Position - merchantPos).Magnitude
    local needMerchantVisit = (not isPremium and currentDist > 14) or (Config.AutoSellQuickVisit and currentDist > 14)

    local savedCFrame = hrp.CFrame

    -- Step to merchant in town if needed (Mandatory for non-premium so server accepts BagSell)
    if needMerchantVisit then
        local p0 = hrp.Position
        local p1 = merchantPos + Vector3.new(0, 1.5, 3)
        if currentDist > 80 then
            hrp.CFrame = CFrame.new(p0:Lerp(p1, 0.4))
            task.wait(0.04)
            hrp.CFrame = CFrame.new(p0:Lerp(p1, 0.75))
            task.wait(0.04)
        end
        hrp.CFrame = CFrame.new(p1)
        hrp.Velocity = Vector3.zero
        hrp.AssemblyLinearVelocity = Vector3.zero
        
        -- Essential: wait 0.75s for server position replication and StreamingEnabled model loading
        task.wait(0.75)
    end

    -- Batch BagSell into chunks of 35 string IDs (server standard)
    local batches = {}
    local currentBatch = {}
    for _, id in ipairs(sellIds) do
        table.insert(currentBatch, id)
        if #currentBatch >= 35 then
            table.insert(batches, currentBatch)
            currentBatch = {}
        end
    end
    if #currentBatch > 0 then
        table.insert(batches, currentBatch)
    end

    for _, batch in ipairs(batches) do
        pcall(function()
            if RemotesLazy.BagSell then
                RemotesLazy.BagSell:FireServer(batch)
            end
        end)
        task.wait(0.2)
    end

    -- Also fire ShopSellJunk to ensure any remaining monster junk drops are sold
    pcall(function()
        if RemotesLazy.ShopSellJunk then
            RemotesLazy.ShopSellJunk:FireServer()
        end
    end)

    task.wait(0.4)

    -- Smooth return to previous farming location
    if needMerchantVisit and savedCFrame and hrp and hrp.Parent then
        local returnDist = (savedCFrame.Position - hrp.Position).Magnitude
        local r0 = hrp.Position
        local r1 = savedCFrame.Position
        if returnDist > 80 then
            hrp.CFrame = CFrame.new(r0:Lerp(r1, 0.4))
            task.wait(0.04)
            hrp.CFrame = CFrame.new(r0:Lerp(r1, 0.75))
            task.wait(0.04)
        end
        hrp.CFrame = savedCFrame
        hrp.Velocity = Vector3.zero
        hrp.AssemblyLinearVelocity = Vector3.zero
    end

    isSelling = false

    if not silent and WindUI and WindUI.Notify then
        WindUI:Notify({
            Title = "💰 Auto Sell สำเร็จ!",
            Content = string.format("ขายไอเทมเรียบร้อย %d ชิ้น (ได้ประมาณ ~%s Silver)", #sellIds, tostring(estSilver)),
            Duration = 3,
            Icon = "coins",
        })
    end
end

-- ==================== 🎥 STREAMER MODE ENGINE (NAME HIDER & SPOOFER) ====================
local originalTexts = {}
local hookedTextObjects = {}
local originalOverheadStates = {}

local function escapeGsubReplacement(str)
    return (tostring(str):gsub("%%", "%%%%"))
end

local function maskTextElement(label)
    if not label or not label.Parent then return end
    if not (label:IsA("TextLabel") or label:IsA("TextBox") or label:IsA("TextButton")) then return end
    if not Config.StreamerMode or not Config.SpoofUIAndLeaderboard then return end

    local currentText = label.Text
    if not currentText or currentText == "" then return end

    local realName = LocalPlayer.Name
    local realDisplayName = LocalPlayer.DisplayName
    local fakeName = Config.StreamerFakeName or "Protected Player"
    local safeFake = escapeGsubReplacement(fakeName)

    local modified = false
    local newText = currentText

    -- Check for real Username
    if realName and realName ~= "" and newText:find(realName, 1, true) then
        newText = newText:gsub(realName, safeFake)
        modified = true
    end

    -- Check for real DisplayName
    if realDisplayName and realDisplayName ~= "" and newText:find(realDisplayName, 1, true) then
        newText = newText:gsub(realDisplayName, safeFake)
        modified = true
    end

    -- Check for other players names if HideOthersNames is enabled
    if Config.HideOthersNames then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                if p.Name and p.Name ~= "" and newText:find(p.Name, 1, true) then
                    newText = newText:gsub(p.Name, "Player")
                    modified = true
                end
                if p.DisplayName and p.DisplayName ~= "" and newText:find(p.DisplayName, 1, true) then
                    newText = newText:gsub(p.DisplayName, "Player")
                    modified = true
                end
            end
        end
    end

    if modified then
        if originalTexts[label] == nil then
            originalTexts[label] = currentText
        end
        label.Text = newText
    end

    if not hookedTextObjects[label] then
        hookedTextObjects[label] = true
        label:GetPropertyChangedSignal("Text"):Connect(function()
            if Config.StreamerMode and Config.SpoofUIAndLeaderboard then
                local txt = label.Text
                local rName = LocalPlayer.Name
                local rDisp = LocalPlayer.DisplayName
                if (rName and txt:find(rName, 1, true)) or (rDisp and txt:find(rDisp, 1, true)) then
                    maskTextElement(label)
                end
            end
        end)
    end
end

local function updateOverheadNametags()
    -- 1. Local Player's Overhead Nametag
    local char = LocalPlayer.Character
    if char then
        local head = char:FindFirstChild("Head") or char.PrimaryPart
        if head then
            for _, child in ipairs(head:GetChildren()) do
                if child:IsA("BillboardGui") then
                    if originalOverheadStates[child] == nil then
                        originalOverheadStates[child] = child.Enabled
                    end
                    if Config.StreamerMode and Config.HideOverheadName then
                        child.Enabled = false
                    else
                        child.Enabled = (originalOverheadStates[child] ~= false)
                    end
                end
            end
        end

        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("BillboardGui") then
                if originalOverheadStates[child] == nil then
                    originalOverheadStates[child] = child.Enabled
                end
                if Config.StreamerMode and Config.HideOverheadName then
                    child.Enabled = false
                else
                    child.Enabled = (originalOverheadStates[child] ~= false)
                end
            end
        end
    end

    -- 2. Other Players' Overheads if enabled
    if Config.StreamerMode and Config.HideOthersNames then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local oHead = p.Character:FindFirstChild("Head") or p.Character.PrimaryPart
                if oHead then
                    for _, child in ipairs(oHead:GetChildren()) do
                        if child:IsA("BillboardGui") then
                            child.Enabled = false
                        end
                    end
                end
            end
        end
    end
end

local streamerHookConnected = false
local function applyStreamerMode()
    if not Config.StreamerMode then return end

    -- Overhead nametags
    pcall(updateOverheadNametags)

    -- PlayerGui elements (Hook once to avoid heavy recurring tree sweeps)
    if Config.SpoofUIAndLeaderboard and not streamerHookConnected then
        streamerHookConnected = true
        pcall(function()
            local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            if pg then
                for _, desc in ipairs(pg:GetDescendants()) do
                    maskTextElement(desc)
                end
                pg.DescendantAdded:Connect(function(desc)
                    if Config.StreamerMode and Config.SpoofUIAndLeaderboard then
                        pcall(function() maskTextElement(desc) end)
                    end
                end)
            end
        end)
    end
end

local function restoreOriginalNames()
    -- Restore cached original texts
    for label, orig in pairs(originalTexts) do
        if label and label.Parent then
            pcall(function() label.Text = orig end)
        end
    end
    originalTexts = {}

    -- Restore overhead billboard visibility
    local char = LocalPlayer.Character
    if char then
        local head = char:FindFirstChild("Head") or char.PrimaryPart
        if head then
            for _, child in ipairs(head:GetChildren()) do
                if child:IsA("BillboardGui") then
                    child.Enabled = (originalOverheadStates[child] ~= false)
                end
            end
        end
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("BillboardGui") then
                child.Enabled = (originalOverheadStates[child] ~= false)
            end
        end
    end

    -- Restore other players' overhead billboard visibility
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local oHead = p.Character:FindFirstChild("Head") or p.Character.PrimaryPart
            if oHead then
                for _, child in ipairs(oHead:GetChildren()) do
                    if child:IsA("BillboardGui") then
                        child.Enabled = true
                    end
                end
            end
        end
    end
end

-- Listener for dynamically created UI elements (chats, popups, inventories, level-ups)
pcall(function()
    local pg = LocalPlayer:WaitForChild("PlayerGui", 5)
    if pg then
        pg.DescendantAdded:Connect(function(desc)
            if Config.StreamerMode and Config.SpoofUIAndLeaderboard then
                task.wait(0.05)
                pcall(function() maskTextElement(desc) end)
            end
        end)
    end
end)

-- Character respawn / warp handler for overhead nametags
trackConn(LocalPlayer.CharacterAdded:Connect(function(newChar)
    if not isScriptAlive() then return end
    if Config.StreamerMode then
        task.wait(0.5)
        pcall(updateOverheadNametags)
    end
end))

-- ==================== LOAD WINDUI ====================
WindUI = nil
if isfile and isfile("WindUI_cache.lua") and readfile then
    local ok, res = pcall(function() return loadstring(readfile("WindUI_cache.lua"))() end)
    if ok and res and type(res) == "table" and res.CreateWindow then 
        WindUI = res 
    end
end
if not WindUI then
    local content = game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua")
    WindUI = loadstring(content)()
    if writefile and content then
        pcall(function() writefile("WindUI_cache.lua", content) end)
    end
end

-- Purge any residual window objects in cached WindUI
pcall(function()
    if WindUI and WindUI.ScreenGui and WindUI.ScreenGui:FindFirstChild("Window") then
        for _, w in ipairs(WindUI.ScreenGui.Window:GetChildren()) do
            pcall(function() w:Destroy() end)
        end
    end
end)

local initialKey = Enum.KeyCode[Config.ToggleKey] or Enum.KeyCode.RightControl

local Window = WindUI:CreateWindow({
    Title = "Hunting Together | All-in-One Auto Hub [v3.5 - Latest]",
    Icon = "swords",
    Folder = "HuntingTogether_UltimateHub",
    Size = UDim2.fromOffset(600, 490),
    Theme = "Dark",
    ToggleKey = initialKey,
    OpenButton = {
        Title = "Hunting Hub",
        Icon = "swords",
        CornerRadius = UDim.new(0, 16),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
    },
})

if getgenv then
    getgenv()._HT_CurrentWindow = Window
    getgenv()._HT_WindUI = WindUI
end

pcall(function()
    Window:OnDestroy(function()
        if getgenv and getgenv()._HT_CurrentWindow == Window then
            getgenv()._HT_CurrentWindow = nil
        end
    end)
end)

-- Hotkey Event Listener for Window Folding / Toggle
local currentKeyCode = initialKey
trackConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not isScriptAlive() then return end
    if not gameProcessed and input.KeyCode == currentKeyCode then
        Window:Toggle()
    end
end))

-- ==================== CONSOLIDATED CLEAN TABS (6 UNIFIED TABS) ====================
CombatTab = Window:Tab({ Title = "Combat & Farm", Icon = "swords" })
DungeonTab = Window:Tab({ Title = "Dungeon Hub", Icon = "skull" })
InventoryTab = Window:Tab({ Title = "Inventory & Loot", Icon = "shopping-bag" })
ProgressionTab = Window:Tab({ Title = "Progression & Travel", Icon = "trending-up" })
CharacterTab = Window:Tab({ Title = "Character & Survival", Icon = "heart" })
EventTab = Window:Tab({ Title = "Event & Streamer", Icon = "sparkles" })
SettingsTab = Window:Tab({ Title = "Settings & Boost", Icon = "settings" })

-- Logical Aliases (Smoothly merges 15 cluttered tabs into 6 clean, professional tabs)
FarmTab = CombatTab
SkillsTab = CombatTab
DodgeTab = CombatTab

GearTab = InventoryTab
LootTab = InventoryTab
AutoSellTab = InventoryTab

AutoProgTab = ProgressionTab
TeleportTab = ProgressionTab

SurvivalTab = CharacterTab
StatsTab = CharacterTab
RewardsTab = CharacterTab

HalloweenTab = EventTab
StreamerTab = EventTab

ConfigTab = SettingsTab
MiscTab = SettingsTab

-- ==================== 🎨 DUNGEON THEMES & ANIMATED BACKGROUND ENGINE ====================
;(function()
    local THEME_PRESETS = {
        ["🎃 Skull King's Crypt (สุสานราชาโครงกระดูก)"] = {
            Id = "Dungeon_SkullKing",
            Effect = "Embers",
            Accent = "#1F1135",
            Background = "#0C0716",
            Dialog = "#150C26",
            Outline = "#FF7A18",
            Text = "#FFF7ED",
            Placeholder = "#B794F4",
            Button = "#391E5A",
            Icon = "#FB923C",
            Toggle = "#F97316",
            Slider = "#F97316",
            SliderIcon = "#FDBA74",
            Checkbox = "#F97316",
            Primary = "#F97316",
            ElementBackground = "#211238",
            PanelBackground = "#170C29",
            LabelBackground = "#090410",
            Grad1 = Color3.fromHex("#0D0618"),
            Grad2 = Color3.fromHex("#23103A"),
            Grad3 = Color3.fromHex("#2A1119"),
            Orb1 = Color3.fromHex("#FF6B1A"),
            Orb2 = Color3.fromHex("#9333EA"),
            Orb3 = Color3.fromHex("#E11D48"),
            Particle1 = Color3.fromHex("#FF8A00"),
            Particle2 = Color3.fromHex("#C084FC"),
            RuneColor = Color3.fromHex("#FB923C"),
        },
        ["🩸 Blood Moon Abyss (ห้วงเหวจันทร์สีเลือด)"] = {
            Id = "Dungeon_BloodMoon",
            Effect = "BloodMist",
            Accent = "#2A0912",
            Background = "#110408",
            Dialog = "#1C060C",
            Outline = "#FF1E42",
            Text = "#FFF1F2",
            Placeholder = "#FDA4AF",
            Button = "#4C0D1D",
            Icon = "#FB7185",
            Toggle = "#E11D48",
            Slider = "#F43F5E",
            SliderIcon = "#FDA4AF",
            Checkbox = "#E11D48",
            Primary = "#E11D48",
            ElementBackground = "#2D0A14",
            PanelBackground = "#1F060D",
            LabelBackground = "#0C0205",
            Grad1 = Color3.fromHex("#110307"),
            Grad2 = Color3.fromHex("#300813"),
            Grad3 = Color3.fromHex("#1F050B"),
            Orb1 = Color3.fromHex("#FF1E42"),
            Orb2 = Color3.fromHex("#9F1239"),
            Orb3 = Color3.fromHex("#FB7185"),
            Particle1 = Color3.fromHex("#FF2A55"),
            Particle2 = Color3.fromHex("#FCA5A5"),
            RuneColor = Color3.fromHex("#F43F5E"),
        },
        ["❄️ Soulfrost Catacombs (สุสานน้ำแข็งวิญญาณ)"] = {
            Id = "Dungeon_Soulfrost",
            Effect = "Snowfall",
            Accent = "#0C223B",
            Background = "#06101E",
            Dialog = "#0A192F",
            Outline = "#38BDF8",
            Text = "#F0F9FF",
            Placeholder = "#7DD3FC",
            Button = "#15365C",
            Icon = "#38BDF8",
            Toggle = "#0EA5E9",
            Slider = "#38BDF8",
            SliderIcon = "#BAE6FD",
            Checkbox = "#0EA5E9",
            Primary = "#0EA5E9",
            ElementBackground = "#0F2744",
            PanelBackground = "#0A1B30",
            LabelBackground = "#040B14",
            Grad1 = Color3.fromHex("#050E1A"),
            Grad2 = Color3.fromHex("#0D2847"),
            Grad3 = Color3.fromHex("#091E36"),
            Orb1 = Color3.fromHex("#00E5FF"),
            Orb2 = Color3.fromHex("#0284C7"),
            Orb3 = Color3.fromHex("#7DD3FC"),
            Particle1 = Color3.fromHex("#E0F2FE"),
            Particle2 = Color3.fromHex("#38BDF8"),
            RuneColor = Color3.fromHex("#38BDF8"),
        },
        ["🔮 Shadow Monarch's Sanctum (วิหารจักรพรรดิเงา)"] = {
            Id = "Dungeon_ShadowMonarch",
            Effect = "ShadowAura",
            Accent = "#180E36",
            Background = "#080514",
            Dialog = "#110926",
            Outline = "#A855F7",
            Text = "#FAF5FF",
            Placeholder = "#C084FC",
            Button = "#2E1663",
            Icon = "#C084FC",
            Toggle = "#9333EA",
            Slider = "#A855F7",
            SliderIcon = "#E9D5FF",
            Checkbox = "#9333EA",
            Primary = "#9333EA",
            ElementBackground = "#1C103D",
            PanelBackground = "#120A29",
            LabelBackground = "#06030F",
            Grad1 = Color3.fromHex("#070412"),
            Grad2 = Color3.fromHex("#1E0F42"),
            Grad3 = Color3.fromHex("#11183D"),
            Orb1 = Color3.fromHex("#A855F7"),
            Orb2 = Color3.fromHex("#4F46E5"),
            Orb3 = Color3.fromHex("#C084FC"),
            Particle1 = Color3.fromHex("#A855F7"),
            Particle2 = Color3.fromHex("#60A5FA"),
            RuneColor = Color3.fromHex("#C084FC"),
        },
        ["🐉 Tempest Dragon Shrine (วิหารมังกรวายุคลั่ง)"] = {
            Id = "Dungeon_TempestDragon",
            Effect = "WindStream",
            Accent = "#0B2922",
            Background = "#051310",
            Dialog = "#081F1A",
            Outline = "#10B981",
            Text = "#ECFDF5",
            Placeholder = "#6EE7B7",
            Button = "#13473B",
            Icon = "#34D399",
            Toggle = "#10B981",
            Slider = "#34D399",
            SliderIcon = "#A7F3D0",
            Checkbox = "#10B981",
            Primary = "#10B981",
            ElementBackground = "#0E3028",
            PanelBackground = "#09211B",
            LabelBackground = "#030D0A",
            Grad1 = Color3.fromHex("#04100D"),
            Grad2 = Color3.fromHex("#0D332A"),
            Grad3 = Color3.fromHex("#08222B"),
            Orb1 = Color3.fromHex("#10B981"),
            Orb2 = Color3.fromHex("#0D9488"),
            Orb3 = Color3.fromHex("#6EE7B7"),
            Particle1 = Color3.fromHex("#34D399"),
            Particle2 = Color3.fromHex("#99F6E4"),
            RuneColor = Color3.fromHex("#34D399"),
        },
        ["🌋 Infernal Magma Core (แกนกลางลาวานรก)"] = {
            Id = "Dungeon_MagmaCore",
            Effect = "MagmaSparks",
            Accent = "#2B1309",
            Background = "#120804",
            Dialog = "#1F0D06",
            Outline = "#F97316",
            Text = "#FFFBEB",
            Placeholder = "#FDBA74",
            Button = "#4D200E",
            Icon = "#FB923C",
            Toggle = "#EA580C",
            Slider = "#F97316",
            SliderIcon = "#FDE047",
            Checkbox = "#EA580C",
            Primary = "#EA580C",
            ElementBackground = "#30150A",
            PanelBackground = "#210E07",
            LabelBackground = "#0D0502",
            Grad1 = Color3.fromHex("#120703"),
            Grad2 = Color3.fromHex("#331408"),
            Grad3 = Color3.fromHex("#290B08"),
            Orb1 = Color3.fromHex("#F97316"),
            Orb2 = Color3.fromHex("#DC2626"),
            Orb3 = Color3.fromHex("#FACC15"),
            Particle1 = Color3.fromHex("#FB923C"),
            Particle2 = Color3.fromHex("#FDE047"),
            RuneColor = Color3.fromHex("#F97316"),
        },
        ["🏛️ Pharaoh's Golden Vault (มหาพีระมิดฟาโรห์ทองคำ)"] = {
            Id = "Dungeon_GoldenVault",
            Effect = "GoldenStarlight",
            Accent = "#291F09",
            Background = "#120D04",
            Dialog = "#1C1506",
            Outline = "#F59E0B",
            Text = "#FEFCE8",
            Placeholder = "#FDE047",
            Button = "#47350F",
            Icon = "#FBBF24",
            Toggle = "#D97706",
            Slider = "#F59E0B",
            SliderIcon = "#FEF08A",
            Checkbox = "#D97706",
            Primary = "#F59E0B",
            ElementBackground = "#2E230A",
            PanelBackground = "#1F1707",
            LabelBackground = "#0A0802",
            Grad1 = Color3.fromHex("#120D03"),
            Grad2 = Color3.fromHex("#2E2208"),
            Grad3 = Color3.fromHex("#1F1408"),
            Orb1 = Color3.fromHex("#F59E0B"),
            Orb2 = Color3.fromHex("#CA8A04"),
            Orb3 = Color3.fromHex("#FDE047"),
            Particle1 = Color3.fromHex("#FDE047"),
            Particle2 = Color3.fromHex("#F59E0B"),
            RuneColor = Color3.fromHex("#FBBF24"),
        },
        ["🌸 Cursed Sakura Shrine (ศาลเจ้าซากุระต้องสาป)"] = {
            Id = "Dungeon_CursedSakura",
            Effect = "SakuraPetals",
            Accent = "#2B0F24",
            Background = "#120610",
            Dialog = "#1F0A1A",
            Outline = "#EC4899",
            Text = "#FDF2F8",
            Placeholder = "#F9A8D4",
            Button = "#4D1940",
            Icon = "#F472B6",
            Toggle = "#DB2777",
            Slider = "#EC4899",
            SliderIcon = "#FBCFE8",
            Checkbox = "#DB2777",
            Primary = "#EC4899",
            ElementBackground = "#301129",
            PanelBackground = "#210B1C",
            LabelBackground = "#0A0308",
            Grad1 = Color3.fromHex("#12050F"),
            Grad2 = Color3.fromHex("#2E0E27"),
            Grad3 = Color3.fromHex("#1F0924"),
            Orb1 = Color3.fromHex("#EC4899"),
            Orb2 = Color3.fromHex("#9333EA"),
            Orb3 = Color3.fromHex("#F9A8D4"),
            Particle1 = Color3.fromHex("#F9A8D4"),
            Particle2 = Color3.fromHex("#F43F5E"),
            RuneColor = Color3.fromHex("#F472B6"),
        },
        ["🌑 Classic Dark (สีดำคลาสสิก)"] = {
            Id = "Dark",
            Effect = "GoldenStarlight",
            Grad1 = Color3.fromHex("#0E0E10"),
            Grad2 = Color3.fromHex("#18181C"),
            Grad3 = Color3.fromHex("#121216"),
            Orb1 = Color3.fromHex("#3B82F6"),
            Orb2 = Color3.fromHex("#6366F1"),
            Orb3 = Color3.fromHex("#60A5FA"),
            Particle1 = Color3.fromHex("#93C5FD"),
            Particle2 = Color3.fromHex("#A5B4FC"),
            RuneColor = Color3.fromHex("#60A5FA"),
        },
    }

    local THEME_NAMES = {
        "🎃 Skull King's Crypt (สุสานราชาโครงกระดูก)",
        "🩸 Blood Moon Abyss (ห้วงเหวจันทร์สีเลือด)",
        "❄️ Soulfrost Catacombs (สุสานน้ำแข็งวิญญาณ)",
        "🔮 Shadow Monarch's Sanctum (วิหารจักรพรรดิเงา)",
        "🐉 Tempest Dragon Shrine (วิหารมังกรวายุคลั่ง)",
        "🌋 Infernal Magma Core (แกนกลางลาวานรก)",
        "🏛️ Pharaoh's Golden Vault (มหาพีระมิดฟาโรห์ทองคำ)",
        "🌸 Cursed Sakura Shrine (ศาลเจ้าซากุระต้องสาป)",
        "🌑 Classic Dark (สีดำคลาสสิก)",
    }

    local STYLE_MAP = {
        ["Auto (ตามธีมดันเจี้ยน)"] = "Auto",
        ["🔥 Soul Embers & Runes (ไฟวิญญาณ & รูนเวท)"] = "Embers",
        ["🩸 Blood Moon Mist (ละอองจันทร์สีเลือด)"] = "BloodMist",
        ["❄️ Soulfrost Blizzard (พายุหิมะน้ำแข็ง)"] = "Snowfall",
        ["🔮 Shadow Monarch Aura (ออร่าจักรพรรดิเงา)"] = "ShadowAura",
        ["🐉 Tempest Wind Stream (สายลมมังกรวายุ)"] = "WindStream",
        ["🌋 Molten Magma Sparks (สะเก็ดลาวานรก)"] = "MagmaSparks",
        ["✨ Celestial Starlight (ละอองดาวทองคำ)"] = "GoldenStarlight",
        ["🌸 Cursed Sakura Petals (กลีบซากุระต้องสาป)"] = "SakuraPetals",
    }

    local STYLE_NAMES = {
        "Auto (ตามธีมดันเจี้ยน)",
        "🔥 Soul Embers & Runes (ไฟวิญญาณ & รูนเวท)",
        "🩸 Blood Moon Mist (ละอองจันทร์สีเลือด)",
        "❄️ Soulfrost Blizzard (พายุหิมะน้ำแข็ง)",
        "🔮 Shadow Monarch Aura (ออร่าจักรพรรดิเงา)",
        "🐉 Tempest Wind Stream (สายลมมังกรวายุ)",
        "🌋 Molten Magma Sparks (สะเก็ดลาวานรก)",
        "✨ Celestial Starlight (ละอองดาวทองคำ)",
        "🌸 Cursed Sakura Petals (กลีบซากุระต้องสาป)",
    }

    -- Register all custom themes in WindUI
    for _, preset in pairs(THEME_PRESETS) do
        if preset.Id ~= "Dark" then
            pcall(function()
                WindUI:AddTheme({
                    Name = preset.Id,
                    Accent = Color3.fromHex(preset.Accent),
                    Background = Color3.fromHex(preset.Background),
                    Dialog = Color3.fromHex(preset.Dialog),
                    Outline = Color3.fromHex(preset.Outline),
                    Text = Color3.fromHex(preset.Text),
                    Placeholder = Color3.fromHex(preset.Placeholder),
                    Button = Color3.fromHex(preset.Button),
                    Icon = Color3.fromHex(preset.Icon),
                    Toggle = Color3.fromHex(preset.Toggle),
                    Slider = Color3.fromHex(preset.Slider),
                    SliderIcon = Color3.fromHex(preset.SliderIcon),
                    Checkbox = Color3.fromHex(preset.Checkbox),
                    Primary = Color3.fromHex(preset.Primary),
                    ElementBackground = Color3.fromHex(preset.ElementBackground),
                    ElementBackgroundTransparency = (tonumber(Config.UIGlassTransparency) or 28) / 100,
                    PanelBackground = Color3.fromHex(preset.PanelBackground),
                    PanelBackgroundTransparency = 0.86,
                    LabelBackground = Color3.fromHex(preset.LabelBackground),
                    LabelBackgroundTransparency = 0.75,
                })
            end)
        end
    end

    -- Build Procedural Animated Background Canvas inside Window.UIElements.Main
    local mainWinFrame = Window and Window.UIElements and Window.UIElements.Main
    local animCanvas = nil
    local bgGrad = nil
    local borderStroke = nil
    local borderGrad = nil
    local orbs = {}
    local outerRing, innerRing, runeDiamond = nil, nil, nil
    local outerStroke, innerStroke, diamondStroke = nil, nil, nil
    local particles = {}
    local activePreset = THEME_PRESETS[Config.UITheme] or THEME_PRESETS["🎃 Skull King's Crypt (สุสานราชาโครงกระดูก)"]

    if mainWinFrame then
        pcall(function()
            local old = mainWinFrame:FindFirstChild("DungeonAnimCanvas")
            if old then old:Destroy() end

            animCanvas = Instance.new("Frame")
            animCanvas.Name = "DungeonAnimCanvas"
            animCanvas.Size = UDim2.fromScale(1, 1)
            animCanvas.Position = UDim2.fromScale(0, 0)
            animCanvas.BackgroundColor3 = Color3.new(1, 1, 1)
            animCanvas.BackgroundTransparency = 0.08
            animCanvas.BorderSizePixel = 0
            animCanvas.ClipsDescendants = true
            animCanvas.ZIndex = 5
            animCanvas.Visible = (Config.UIBackgroundAnimation ~= false)
            animCanvas.Parent = mainWinFrame

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 12)
            corner.Parent = animCanvas

            bgGrad = Instance.new("UIGradient")
            bgGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, activePreset.Grad1),
                ColorSequenceKeypoint.new(0.52, activePreset.Grad2),
                ColorSequenceKeypoint.new(1, activePreset.Grad3),
            })
            bgGrad.Rotation = 35
            bgGrad.Parent = animCanvas

            -- Glowing Animated Window Border Stroke
            borderStroke = Instance.new("UIStroke")
            borderStroke.Thickness = 1.6
            borderStroke.Transparency = 0.35
            borderStroke.Color = Color3.new(1, 1, 1)
            borderStroke.Parent = animCanvas

            borderGrad = Instance.new("UIGradient")
            borderGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, activePreset.Orb1),
                ColorSequenceKeypoint.new(0.5, activePreset.Orb2),
                ColorSequenceKeypoint.new(1, activePreset.Orb3),
            })
            borderGrad.Rotation = 0
            borderGrad.Parent = borderStroke

            -- 3 Soft Breathing Ambient Glow Orbs
            local orbConfigs = {
                { Pos = UDim2.fromScale(0.18, 0.22), Size = UDim2.fromOffset(270, 270), Col = activePreset.Orb1 },
                { Pos = UDim2.fromScale(0.82, 0.78), Size = UDim2.fromOffset(300, 300), Col = activePreset.Orb2 },
                { Pos = UDim2.fromScale(0.62, 0.28), Size = UDim2.fromOffset(230, 230), Col = activePreset.Orb3 },
            }
            for idx, oc in ipairs(orbConfigs) do
                local orb = Instance.new("Frame")
                orb.Name = "AuraOrb_" .. idx
                orb.AnchorPoint = Vector2.new(0.5, 0.5)
                orb.Position = oc.Pos
                orb.Size = oc.Size
                orb.BackgroundColor3 = oc.Col
                orb.BackgroundTransparency = 0.87
                orb.BorderSizePixel = 0
                orb.ZIndex = 6
                orb.Parent = animCanvas

                local oCorner = Instance.new("UICorner")
                oCorner.CornerRadius = UDim.new(1, 0)
                oCorner.Parent = orb

                local oGrad = Instance.new("UIGradient")
                oGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.15),
                    NumberSequenceKeypoint.new(0.65, 0.55),
                    NumberSequenceKeypoint.new(1, 1),
                })
                oGrad.Parent = orb

                table.insert(orbs, {
                    Frame = orb,
                    BaseX = oc.Pos.X.Scale,
                    BaseY = oc.Pos.Y.Scale,
                    Phase = idx * 2.1,
                })
            end

            -- Arcane Dungeon Magic Seal (Counter-Rotating Rings + Rune Diamond behind content)
            local sealCenter = UDim2.new(0.66, 0, 0.54, 0)

            outerRing = Instance.new("Frame")
            outerRing.Name = "ArcaneOuterRing"
            outerRing.AnchorPoint = Vector2.new(0.5, 0.5)
            outerRing.Position = sealCenter
            outerRing.Size = UDim2.fromOffset(250, 250)
            outerRing.BackgroundTransparency = 1
            outerRing.ZIndex = 6
            outerRing.Parent = animCanvas
            local orCorner = Instance.new("UICorner")
            orCorner.CornerRadius = UDim.new(1, 0)
            orCorner.Parent = outerRing
            outerStroke = Instance.new("UIStroke")
            outerStroke.Thickness = 1.5
            outerStroke.Transparency = 0.76
            outerStroke.Color = activePreset.RuneColor
            outerStroke.Parent = outerRing
            local orGrad = Instance.new("UIGradient")
            orGrad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.1),
                NumberSequenceKeypoint.new(0.5, 0.85),
                NumberSequenceKeypoint.new(1, 0.1),
            })
            orGrad.Parent = outerStroke

            innerRing = Instance.new("Frame")
            innerRing.Name = "ArcaneInnerRing"
            innerRing.AnchorPoint = Vector2.new(0.5, 0.5)
            innerRing.Position = sealCenter
            innerRing.Size = UDim2.fromOffset(175, 175)
            innerRing.BackgroundTransparency = 1
            innerRing.ZIndex = 6
            innerRing.Parent = animCanvas
            local irCorner = Instance.new("UICorner")
            irCorner.CornerRadius = UDim.new(1, 0)
            irCorner.Parent = innerRing
            innerStroke = Instance.new("UIStroke")
            innerStroke.Thickness = 1.2
            innerStroke.Transparency = 0.78
            innerStroke.Color = activePreset.Orb1
            innerStroke.Parent = innerRing
            local irGrad = Instance.new("UIGradient")
            irGrad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.75),
                NumberSequenceKeypoint.new(0.5, 0.1),
                NumberSequenceKeypoint.new(1, 0.75),
            })
            irGrad.Parent = innerStroke

            runeDiamond = Instance.new("Frame")
            runeDiamond.Name = "ArcaneRuneDiamond"
            runeDiamond.AnchorPoint = Vector2.new(0.5, 0.5)
            runeDiamond.Position = sealCenter
            runeDiamond.Size = UDim2.fromOffset(122, 122)
            runeDiamond.Rotation = 45
            runeDiamond.BackgroundTransparency = 1
            runeDiamond.ZIndex = 6
            runeDiamond.Parent = animCanvas
            local rdCorner = Instance.new("UICorner")
            rdCorner.CornerRadius = UDim.new(0, 14)
            rdCorner.Parent = runeDiamond
            diamondStroke = Instance.new("UIStroke")
            diamondStroke.Thickness = 1.2
            diamondStroke.Transparency = 0.80
            diamondStroke.Color = activePreset.Particle2
            diamondStroke.Parent = runeDiamond

            -- 28 Pooled Procedural Theme Particles
            for i = 1, 28 do
                local p = Instance.new("Frame")
                p.Name = "ThemeParticle_" .. i
                p.AnchorPoint = Vector2.new(0.5, 0.5)
                local sz = math.random(4, 9)
                p.Size = UDim2.fromOffset(sz, sz)
                p.Position = UDim2.fromScale(math.random() * 0.96 + 0.02, math.random())
                p.BackgroundColor3 = (i % 2 == 0) and activePreset.Particle1 or activePreset.Particle2
                p.BackgroundTransparency = 0.35 + (math.random() * 0.35)
                p.BorderSizePixel = 0
                p.ZIndex = 7
                p.Parent = animCanvas

                local pCorner = Instance.new("UICorner")
                pCorner.CornerRadius = UDim.new(1, 0)
                pCorner.Parent = p

                local pStroke = Instance.new("UIStroke")
                pStroke.Thickness = 1.2
                pStroke.Transparency = 0.55
                pStroke.Color = (i % 2 == 0) and activePreset.Orb1 or activePreset.Orb2
                pStroke.Parent = p

                table.insert(particles, {
                    Frame = p,
                    Corner = pCorner,
                    Stroke = pStroke,
                    X = math.random() * 0.96 + 0.02,
                    Y = math.random(),
                    Speed = 0.045 + math.random() * 0.085,
                    SwayAmp = 0.015 + math.random() * 0.035,
                    SwayFreq = 1.2 + math.random() * 2.2,
                    Phase = math.random() * 6.28,
                    BaseSize = sz,
                })
            end
        end)
    end

    local function applyGlassTransparency()
        if not mainWinFrame then return end
        local glassAlpha = math.clamp((tonumber(Config.UIGlassTransparency) or 28) / 100, 0, 0.75)
        if Config.UIBackgroundAnimation == false then
            glassAlpha = 0
        end
        pcall(function()
            local bgImg = mainWinFrame:FindFirstChild("Background")
            if bgImg and bgImg:IsA("ImageLabel") then
                bgImg.ImageTransparency = (Config.UIBackgroundAnimation ~= false) and 0.18 or 0
            end
            for _, d in ipairs(mainWinFrame:GetDescendants()) do
                if d.Name == "GlassBackground" and d:IsA("ImageLabel") then
                    d.ImageTransparency = glassAlpha
                end
            end
        end)
    end

    local function getActiveEffectStyle()
        local chosen = Config.UIAnimationStyle or "Auto (ตามธีมดันเจี้ยน)"
        local mapped = STYLE_MAP[chosen] or "Auto"
        if mapped == "Auto" then
            return (activePreset and activePreset.Effect) or "Embers"
        end
        return mapped
    end

    local function updateParticleLook()
        local eff = getActiveEffectStyle()
        for i, pt in ipairs(particles) do
            pcall(function()
                pt.Frame.BackgroundColor3 = (i % 2 == 0) and activePreset.Particle1 or activePreset.Particle2
                pt.Stroke.Color = (i % 2 == 0) and activePreset.Orb1 or activePreset.Orb2
                if eff == "WindStream" then
                    pt.Frame.Size = UDim2.fromOffset(pt.BaseSize * 3.2, math.max(2, math.floor(pt.BaseSize * 0.45)))
                    pt.Frame.Rotation = -16
                    pt.Corner.CornerRadius = UDim.new(1, 0)
                elseif eff == "SakuraPetals" then
                    pt.Frame.Size = UDim2.fromOffset(pt.BaseSize * 1.4, pt.BaseSize * 0.85)
                    pt.Corner.CornerRadius = UDim.new(0.45, 0)
                else
                    pt.Frame.Size = UDim2.fromOffset(pt.BaseSize, pt.BaseSize)
                    pt.Frame.Rotation = 0
                    pt.Corner.CornerRadius = UDim.new(1, 0)
                end
            end)
        end
    end

    local function applyDungeonTheme(themeLabel, notifyUser)
        local preset = THEME_PRESETS[themeLabel] or THEME_PRESETS["🎃 Skull King's Crypt (สุสานราชาโครงกระดูก)"]
        activePreset = preset
        Config.UITheme = themeLabel

        pcall(function()
            if WindUI and WindUI.Themes and WindUI.Themes[preset.Id] then
                WindUI.Themes[preset.Id].ElementBackgroundTransparency = (Config.UIBackgroundAnimation ~= false) and ((tonumber(Config.UIGlassTransparency) or 28) / 100) or 0
            end
            WindUI:SetTheme(preset.Id)
        end)

        pcall(function()
            if bgGrad then
                bgGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, preset.Grad1),
                    ColorSequenceKeypoint.new(0.52, preset.Grad2),
                    ColorSequenceKeypoint.new(1, preset.Grad3),
                })
            end
            if borderGrad then
                borderGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, preset.Orb1),
                    ColorSequenceKeypoint.new(0.5, preset.Orb2),
                    ColorSequenceKeypoint.new(1, preset.Orb3),
                })
            end
            if orbs[1] then orbs[1].Frame.BackgroundColor3 = preset.Orb1 end
            if orbs[2] then orbs[2].Frame.BackgroundColor3 = preset.Orb2 end
            if orbs[3] then orbs[3].Frame.BackgroundColor3 = preset.Orb3 end
            if outerStroke then outerStroke.Color = preset.RuneColor end
            if innerStroke then innerStroke.Color = preset.Orb1 end
            if diamondStroke then diamondStroke.Color = preset.Particle2 end
            updateParticleLook()
            applyGlassTransparency()
        end)

        if notifyUser and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "🎨 Dungeon Theme Applied",
                Content = "เปลี่ยนธีม UI เป็น: " .. tostring(themeLabel),
                Duration = 2.5,
                Icon = "palette",
            })
        end
    end

    -- Real-time 60 FPS RenderStepped Animation Loop (Auto-pauses when window is minimized/closed)
    local animClock = 0
    trackConn(RunService.RenderStepped:Connect(function(dt)
        if not isScriptAlive() then return end
        if not animCanvas or not Config.UIBackgroundAnimation then return end
        if Window.Closed or not mainWinFrame or not mainWinFrame.Visible then return end

        local speedMult = math.clamp((tonumber(Config.UIAnimationSpeed) or 10) / 10, 0.1, 3.5)
        local step = math.min(dt, 0.05) * speedMult
        animClock = animClock + step

        -- 1. Smoothly oscillate & rotate background & border gradients
        if bgGrad then
            bgGrad.Rotation = 35 + math.sin(animClock * 0.45) * 28
        end
        if borderGrad then
            borderGrad.Rotation = (animClock * 42) % 360
        end

        -- 2. Breathe & drift ambient aura orbs
        for idx, ob in ipairs(orbs) do
            local ox = ob.BaseX + math.sin(animClock * 0.55 + ob.Phase) * 0.08
            local oy = ob.BaseY + math.cos(animClock * 0.42 + ob.Phase) * 0.08
            ob.Frame.Position = UDim2.fromScale(ox, oy)
            ob.Frame.BackgroundTransparency = 0.86 + math.sin(animClock * 1.3 + ob.Phase) * 0.045
        end

        -- 3. Counter-rotate Arcane Dungeon Magic Seal rings
        if outerRing then
            outerRing.Rotation = (animClock * 14) % 360
        end
        if innerRing then
            innerRing.Rotation = (-animClock * 22) % 360
        end
        if runeDiamond then
            runeDiamond.Rotation = (45 + animClock * 9) % 360
            local pulse = 122 + math.sin(animClock * 1.8) * 8
            runeDiamond.Size = UDim2.fromOffset(pulse, pulse)
        end

        -- 4. Animate pooled particles according to active style
        local eff = getActiveEffectStyle()
        for i, pt in ipairs(particles) do
            if eff == "Snowfall" then
                pt.Y = pt.Y + step * pt.Speed * 0.85
                pt.X = pt.X + step * 0.025
                if pt.Y > 1.06 then pt.Y = -0.06; pt.X = math.random() * 0.96 + 0.02 end
                if pt.X > 1.04 then pt.X = -0.04 end
                local px = pt.X + math.sin(animClock * pt.SwayFreq + pt.Phase) * pt.SwayAmp
                pt.Frame.Position = UDim2.fromScale(px, pt.Y)
                pt.Frame.BackgroundTransparency = 0.35 + math.sin(animClock * 2.2 + pt.Phase) * 0.22
            elseif eff == "WindStream" then
                pt.X = pt.X + step * pt.Speed * 2.6
                pt.Y = pt.Y - step * pt.Speed * 0.55
                if pt.X > 1.08 or pt.Y < -0.06 then
                    pt.X = -0.08
                    pt.Y = math.random() * 0.95 + 0.05
                end
                local py = pt.Y + math.sin(animClock * pt.SwayFreq + pt.Phase) * (pt.SwayAmp * 0.5)
                pt.Frame.Position = UDim2.fromScale(pt.X, py)
                pt.Frame.BackgroundTransparency = 0.42 + math.sin(animClock * 3.0 + pt.Phase) * 0.25
            elseif eff == "SakuraPetals" then
                pt.Y = pt.Y + step * pt.Speed * 0.75
                pt.X = pt.X - step * pt.Speed * 0.45
                if pt.Y > 1.06 or pt.X < -0.06 then
                    pt.Y = -0.06
                    pt.X = math.random() * 1.1
                end
                local px = pt.X + math.sin(animClock * pt.SwayFreq + pt.Phase) * pt.SwayAmp
                pt.Frame.Position = UDim2.fromScale(px, pt.Y)
                pt.Frame.Rotation = (animClock * 65 + pt.Phase * 40) % 360
                pt.Frame.BackgroundTransparency = 0.32 + math.sin(animClock * 2.0 + pt.Phase) * 0.20
            elseif eff == "GoldenStarlight" then
                pt.Y = pt.Y - step * pt.Speed * 0.35
                if pt.Y < -0.05 then pt.Y = 1.05; pt.X = math.random() * 0.96 + 0.02 end
                local px = pt.X + math.sin(animClock * 0.8 + pt.Phase) * (pt.SwayAmp * 0.5)
                pt.Frame.Position = UDim2.fromScale(px, pt.Y)
                local twinkle = math.sin(animClock * 3.5 + pt.Phase)
                local s = math.max(3, pt.BaseSize + twinkle * 2.5)
                pt.Frame.Size = UDim2.fromOffset(s, s)
                pt.Frame.BackgroundTransparency = 0.45 - twinkle * 0.30
            else
                -- Embers, BloodMist, ShadowAura, MagmaSparks (rising dungeon energy motes)
                local boost = (eff == "MagmaSparks" and 1.45) or (eff == "ShadowAura" and 1.15) or 1.0
                pt.Y = pt.Y - step * pt.Speed * boost
                if pt.Y < -0.06 then
                    pt.Y = 1.06
                    pt.X = math.random() * 0.96 + 0.02
                end
                local px = pt.X + math.sin(animClock * pt.SwayFreq + pt.Phase) * pt.SwayAmp
                pt.Frame.Position = UDim2.fromScale(px, pt.Y)
                pt.Frame.BackgroundTransparency = 0.35 + math.sin(animClock * 2.6 + pt.Phase) * 0.25
            end
        end
    end))

    Window._DungeonThemeEngine = {
        ThemeNames = THEME_NAMES,
        StyleNames = STYLE_NAMES,
        ApplyTheme = applyDungeonTheme,
        ApplyGlass = applyGlassTransparency,
        UpdateParticles = updateParticleLook,
        SetAnimEnabled = function(enabled)
            Config.UIBackgroundAnimation = enabled
            if animCanvas then
                animCanvas.Visible = enabled
            end
            applyGlassTransparency()
        end,
    }

    -- Apply initial saved theme after UI elements are created
    task.defer(function()
        task.wait(0.25)
        applyDungeonTheme(Config.UITheme or "🎃 Skull King's Crypt (สุสานราชาโครงกระดูก)", false)
    end)
end)()

-- ==================== TAB 1: COMBAT & AUTO FARM ====================
FarmTab:Section({ Title = "Combat & Targeting", Opened = true })

autoFarmToggle = FarmTab:Toggle({
    Title = "Auto Farm Nearest Monster",
    Desc = "วาร์ปติดตามและโจมตีมอนสเตอร์อัตโนมัติ",
    Value = Config.AutoFarm,
    Callback = function(state)
        Config.AutoFarm = state
        if Config.AutoSave then SaveConfig(true) end
        if state then
            WindUI:Notify({ Title = "Auto Farm", Content = "เริ่มการฟาร์มอัตโนมัติ", Duration = 2, Icon = "play" })
        else
            stopCombatAndTargeting()
            WindUI:Notify({ Title = "Auto Farm", Content = "หยุดการฟาร์มและปลดล็อคเป้าหมายเรียบร้อย", Duration = 2, Icon = "square" })
        end
    end,
})

FarmTab:Button({
    Title = "⛔ Emergency Stop All (หยุดการทำงานและหยุดวาร์ปทั้งหมดทันที)",
    Desc = "ปิด Auto Farm, Auto Dungeon, Auto Progression และหยุดการเคลื่อนที่ทั้งหมดทันที 100%",
    Callback = function()
        Config.AutoFarm = false
        Config.AutoDungeon = false
        Config.AutoProgression = false
        Config.AutoBoss = false
        Config.AutoWarpToBoss = false
        Config.AutoOpenLootBox = false
        Config.AutoTrickTreat = false
        if autoFarmToggle and autoFarmToggle.SetValue then
            autoFarmToggle:SetValue(false)
        elseif autoFarmToggle and autoFarmToggle.Set then
            autoFarmToggle:Set(false)
        end
        stopCombatAndTargeting()
        if Config.AutoSave then SaveConfig(true) end
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "Emergency Stop",
                Content = "หยุดระบบอัตโนมัติทั้งหมดและหยุดวาร์ปเรียบร้อย!",
                Duration = 2.5,
                Icon = "octagon"
            })
        end
    end,
})

FarmTab:Dropdown({
    Title = "Movement Mode (รูปแบบการเข้าหามอนสเตอร์)",
    Desc = "เลือกรูปแบบการเคลื่อนที่: วาร์ปทันที (⚡ Warp - ตีเร็วที่สุด) หรือ เดินบนพื้นปกติ (🚶 Walk)",
    Values = { "⚡ Warp (วาร์ปไปหามอนสเตอร์ทันที - ตีเร็วสุด)", "🚶 Walk (เดินไปหามอนสเตอร์บนพื้น)" },
    Value = (Config.FarmMode == "Walk" and "🚶 Walk (เดินไปหามอนสเตอร์บนพื้น)") or "⚡ Warp (วาร์ปไปหามอนสเตอร์ทันที - ตีเร็วสุด)",
    Callback = function(val)
        if val:find("Walk") then
            Config.FarmMode = "Walk"
            WindUI:Notify({ Title = "Movement Mode", Content = "เปิดใช้งาน: โหมดเดินปกติบนพื้น (Walk Mode)", Duration = 2.5, Icon = "footprints" })
        else
            Config.FarmMode = "Warp"
            WindUI:Notify({ Title = "Movement Mode", Content = "เปิดใช้งาน: โหมดวาร์ปทันที (Warp Mode - ตีเร็วที่สุด)", Duration = 2.5, Icon = "zap" })
        end
        if Config.AutoSave then SaveConfig(true) end
    end,
})

FarmTab:Slider({
    Title = "Walk Mode Speed (ความเร็วเดินฟาร์ม)",
    Desc = "ปรับความเร็วเดินของตัวละครขณะฟาร์มในโหมดเดินปกติ (Walk Speed)",
    Value = { Min = 16, Max = 80, Default = Config.WalkFarmSpeed or 26 },
    Callback = function(val)
        Config.WalkFarmSpeed = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

FarmTab:Slider({
    Title = "Farm Height (ความสูงลอยตัวขณะบิน)",
    Desc = "ปรับความสูงลอยตัวเหนือมอนสเตอร์ขณะฟาร์มในโหมดบิน (Fly Mode)",
    Value = { Min = 1, Max = 15, Default = Config.SafeFarmHeight or 5 },
    Step = 0.5,
    Callback = function(val)
        Config.SafeFarmHeight = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

FarmTab:Slider({
    Title = "Farm Distance (ระยะห่าง)",
    Desc = "ปรับระยะห่างจากมอนสเตอร์ขณะทำการโจมตี",
    Value = { Min = 3, Max = 25, Default = Config.FarmDistance or 5 },
    Step = 0.5,
    Callback = function(val)
        Config.FarmDistance = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

FarmTab:Slider({
    Title = "Attack Delay (ความเร็วในการโจมตี / ASPD Turbo)",
    Desc = "ปรับความเร็วดีเลย์การโจมตี (ค่ายิ่งต่ำยิ่งตีรัวเร็วตามค่า ASPD)",
    Value = { Min = 0.03, Max = 0.4, Default = Config.AttackDelay or 0.08 },
    Step = 0.01,
    Callback = function(val)
        Config.AttackDelay = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

monsterDropdown = FarmTab:Dropdown({
    Title = "Select Target Monster",
    Values = getMonsterList(),
    Value = Config.SelectedMonster,
    Callback = function(selected)
        Config.SelectedMonster = selected
        if Config.AutoSave then SaveConfig(true) end
    end,
})

FarmTab:Button({
    Title = "Refresh Monster List",
    Callback = function()
        local updated = getMonsterList()
        monsterDropdown:SetValues(updated)
        WindUI:Notify({ Title = "Updated", Content = "อัปเดตมอนสเตอร์: " .. #updated .. " ชนิด", Duration = 2, Icon = "refresh-cw" })
    end,
})

FarmTab:Section({ Title = "👑 Auto Boss & Mini-Boss Hunter", Opened = true })

FarmTab:Toggle({
    Title = "Auto Hunt Bosses & Mini-Bosses",
    Desc = "ตรวจจับและโจมตีบอส / มินิบอส / หัวหน้าฝูงอัตโนมัติเมื่อเกิด",
    Value = Config.AutoBoss,
    Callback = function(state)
        Config.AutoBoss = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

FarmTab:Toggle({
    Title = "Auto Warp to World Bosses (วาร์ปไปห้องบอสโลกอัตโนมัติ)",
    Desc = "วาร์ปไปตรวจสอบและล่าบอสใหญ่ในห้องบอส (Boss01-05 เช่น Gorilla King, Obsidian Pharaoh) เป็นระยะอัตโนมัติ",
    Value = Config.AutoWarpToBoss,
    Callback = function(state)
        Config.AutoWarpToBoss = state
        if Config.AutoSave then SaveConfig(true) end
        if state then
            task.spawn(function() executeBossInspection(false) end)
        end
    end,
})

FarmTab:Button({
    Title = "Warp to Level Boss Arena Now (วาร์ปไปห้องบอสทันที)",
    Desc = "วาร์ปไปตรวจสอบบอสใหญ่ตามระดับเลเวลปัจจุบันทันที",
    Callback = function()
        executeBossInspection(false)
    end,
})

FarmTab:Toggle({
    Title = "Prioritize Bosses (เล็งบอสก่อนมอนทั่วไป)",
    Desc = "หากมีบอสในระยะจะเปลี่ยนเป้าหมายไปตีบอสเป็นอันดับแรกทันที",
    Value = Config.PrioritizeBoss,
    Callback = function(state)
        Config.PrioritizeBoss = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

FarmTab:Toggle({
    Title = "Bosses Only Mode (ล่าเฉพาะบอสเท่านั้น)",
    Desc = "ไม่ตีมอนสเตอร์ขยะทั่วไป ล่าและยืนรอดักตีเฉพาะบอส/มินิบอส",
    Value = Config.BossOnly,
    Callback = function(state)
        Config.BossOnly = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

FarmTab:Toggle({
    Title = "Return to Auto Lv.99 Field After Boss (ตีบอสเสร็จกลับไปฟาร์มต่อ)",
    Desc = "เมื่อบอสถูกกำจัด จะดูดเก็บของดรอป/ไข่สัตว์เลี้ยง แล้ววาร์ปกลับไปฟาร์มตามเลเวล 1-99 ทันทีอัตโนมัติ",
    Value = Config.ReturnToProgressionAfterBoss,
    Callback = function(state)
        Config.ReturnToProgressionAfterBoss = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

bossDropdown = FarmTab:Dropdown({
    Title = "Select Specific Boss Filter",
    Values = getBossList(),
    Value = Config.SelectedBoss,
    Callback = function(selected)
        Config.SelectedBoss = selected
        if Config.AutoSave then SaveConfig(true) end
    end,
})

FarmTab:Button({
    Title = "Refresh Boss List",
    Callback = function()
        local updated = getBossList()
        bossDropdown:SetValues(updated)
        WindUI:Notify({ Title = "Updated", Content = "อัปเดตรายชื่อบอส: " .. #updated .. " ตัว", Duration = 2, Icon = "crown" })
    end,
})

-- ==================== TAB 2: AUTO SKILLS ====================
SkillsTab:Section({ Title = "Combat Skills Automation", Opened = true })

SkillsTab:Toggle({
    Title = "Smart Auto Use Active Skills",
    Desc = "ยิงสกิลโจมตีตามอาชีพที่มีทั้งหมดอัตโนมัติ (Twinfang, Venomknife, Cross Slash ฯลฯ)",
    Value = Config.AutoUseSkills,
    Callback = function(state)
        Config.AutoUseSkills = state
        if Config.AutoSave then SaveConfig(true) end
        if not state then
            pcall(function()
                local SetAutoSkillRemote = getRemote("SetAutoSkill")
                if SetAutoSkillRemote then
                    SetAutoSkillRemote:FireServer(false)
                end
            end)
        end
    end,
})

local skillSlotLabels = {
    "ช่อง 1 (Slot 1)",
    "ช่อง 2 (Slot 2)",
    "ช่อง 3 (Slot 3)",
    "ช่อง 4 (Slot 4)",
    "ช่อง 5 (Slot 5)",
    "ช่อง 6 (Slot 6)",
    "ช่อง 7 (Slot 7)"
}

skillsDropdown = SkillsTab:Dropdown({
    Title = "Select Skill Slots to Auto Cast (เลือกช่องสกิล 1-7)",
    Desc = "เลือกช่อง 1-7 ที่ต้องการให้บอทกดใช้อัตโนมัติ (ไม่ต้องเลือกชื่อสกิล)",
    Values = skillSlotLabels,
    Value = Config.SelectedSkillSlots or skillSlotLabels,
    Multi = true,
    AllowNone = true,
    Callback = function(val)
        Config.SelectedSkillSlots = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

SkillsTab:Button({
    Title = "✅ Select All Slots (เลือกทุกช่อง 1-7)",
    Desc = "เปิดใช้งานช่องสกิล 1 ถึง 7 ทั้งหมดทันที",
    Callback = function()
        local allSlots = {
            "ช่อง 1 (Slot 1)",
            "ช่อง 2 (Slot 2)",
            "ช่อง 3 (Slot 3)",
            "ช่อง 4 (Slot 4)",
            "ช่อง 5 (Slot 5)",
            "ช่อง 6 (Slot 6)",
            "ช่อง 7 (Slot 7)"
        }
        Config.SelectedSkillSlots = allSlots
        if skillsDropdown and skillsDropdown.SetValue then
            pcall(function() skillsDropdown:SetValue(allSlots) end)
        end
        if Config.AutoSave then SaveConfig(true) end
        WindUI:Notify({
            Title = "Skill Slots",
            Content = "เลือกช่องสกิล 1-7 ทั้งหมดแล้ว",
            Duration = 2,
            Icon = "check"
        })
    end,
})

SkillsTab:Button({
    Title = "❌ Clear All Slots (ล้างการเลือกทั้งหมด)",
    Desc = "ยกเลิกทุกช่อง (หยุดกดสกิลอัตโนมัติ)",
    Callback = function()
        Config.SelectedSkillSlots = {}
        if skillsDropdown and skillsDropdown.SetValue then
            pcall(function() skillsDropdown:SetValue({}) end)
        end
        if Config.AutoSave then SaveConfig(true) end
        WindUI:Notify({
            Title = "Skill Slots",
            Content = "ยกเลิกช่องสกิลทั้งหมดแล้ว",
            Duration = 2,
            Icon = "x"
        })
    end,
})

SkillsTab:Button({
    Title = "📋 View Hotbar Slots (ดูสกิลในช่อง 1-7 ปัจจุบัน)",
    Desc = "แสดงรายชื่อสกิลที่ติดตั้งอยู่ในแต่ละช่อง 1-7",
    Callback = function()
        local hotbarRaw = LocalPlayer:GetAttribute("HotbarJson")
        local msg = ""
        if hotbarRaw and hotbarRaw ~= "" then
            local ok, hotbar = pcall(function() return HttpService:JSONDecode(hotbarRaw) end)
            if ok and hotbar then
                local parts = {}
                for s = 1, 7 do
                    local item = hotbar[tostring(s)]
                    if item and item:find("^skill:") then
                        table.insert(parts, string.format("ช่อง %d: %s", s, item:sub(7)))
                    else
                        table.insert(parts, string.format("ช่อง %d: [ว่าง]", s))
                    end
                end
                msg = table.concat(parts, " | ")
            end
        end
        if msg == "" then msg = "ไม่พบข้อมูล Hotbar ในขณะนี้" end
        WindUI:Notify({
            Title = "Hotbar Slots 1-7",
            Content = msg,
            Duration = 4,
            Icon = "list"
        })
    end,
})

SkillsTab:Toggle({
    Title = "Auto Cast Buff Skills",
    Desc = "กดบัฟตามคลาสอัตโนมัติ (Stealth, ASPD Buff, Speed Buff)",
    Value = Config.AutoUseBuffs,
    Callback = function(state)
        Config.AutoUseBuffs = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

SkillsTab:Section({ Title = "Skill Learning & Progression", Opened = true })

SkillsTab:Toggle({
    Title = "Auto Learn & Upgrade Skills",
    Desc = "อัปเกรดสกิลของคลาสปัจจุบันอัตโนมัติทันทีที่มีแต้ม Skill Point",
    Value = Config.AutoUpgradeSkills,
    Callback = function(state)
        Config.AutoUpgradeSkills = state
        if Config.AutoSave then SaveConfig(true) end
        if SetAutoSkill then
            pcall(function() SetAutoSkill:FireServer(state) end)
        end
    end,
})

-- ==================== TAB: DUNGEON HUB (SKULL KING'S CRYPT) ====================
DungeonTab:Section({ Title = "🏰 Auto Dungeon Master (ดันเจี้ยนอัตโนมัติ)", Opened = true })

autoDungeonToggle = DungeonTab:Toggle({
    Title = "Enable Auto Dungeon (เปิดระบบลงดันเจี้ยนอัตโนมัติ)",
    Desc = "ตรวจจับดันเจี้ยน, วาร์ปเข้าประตู, กดยืนยันพร้อม, ตีมอนสเตอร์, ตีเสาพิธีกรรม, ล่าบอส และเปิดหีบรับของ Tier VI ครบวงจร",
    Value = Config.AutoDungeon,
    Callback = function(state)
        Config.AutoDungeon = state
        if state then
            -- 🛑 IMMEDIATELY STOP AUTO LV.99 (AutoProgression)
            Config.AutoProgression = false
            isCheckingBossArena = false
            activeBossFight = nil
            isWarpingZone = false
            pcall(function()
                if autoProgressionToggle then
                    if autoProgressionToggle.SetValue then
                        autoProgressionToggle:SetValue(false)
                    elseif autoProgressionToggle.Set then
                        autoProgressionToggle:Set(false)
                    end
                end
            end)
            stopCombatAndTargeting()
            currentCombatTarget = nil
            setClientCurrentTarget(nil)
            if Config.AutoSave then SaveConfig(true) end
            WindUI:Notify({ Title = "Auto Dungeon", Content = "เปิดระบบลงดันเจี้ยนอัตโนมัติ (จัดลำดับความสำคัญสูงสุด)", Duration = 2.5, Icon = "play" })
        else
            isEnteringDungeon = false
            isWaitingForParty = false
            isOpeningDungeonChest = false
            currentDungeonPillar = nil
            stopCombatAndTargeting()
            if Config.AutoSave then SaveConfig(true) end
            WindUI:Notify({ Title = "Auto Dungeon", Content = "ปิดระบบลงดันเจี้ยนและหยุดการทำงานเรียบร้อย", Duration = 2, Icon = "square" })
        end
    end,
})

DungeonTab:Button({
    Title = "⛔ Emergency Stop Dungeon (หยุดดันเจี้ยนและหยุดวาร์ปทันที)",
    Desc = "ปิด Auto Dungeon, ปลดล็อคเป้าหมาย และหยุดการเคลื่อนที่ทั้งหมดในทันที",
    Callback = function()
        Config.AutoDungeon = false
        Config.AutoKickSkulls = false
        Config.AutoSecretChests = false
        Config.PrioritizeDungeonPillars = false
        isEnteringDungeon = false
        isOpeningDungeonChest = false
        currentDungeonPillar = nil
        currentSafeHoldTarget = nil
        safeHoldUntil = 0
        stopCombatAndTargeting()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Velocity = Vector3.zero
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
        if Config.AutoSave then SaveConfig(true) end
        if WindUI and WindUI.Notify then
            WindUI:Notify({ Title = "Dungeon Stopped", Content = "หยุดระบบดันเจี้ยนและการวาร์ปทั้งหมดแล้ว!", Duration = 2, Icon = "square" })
        end
    end,
})

DungeonTab:Dropdown({
    Title = "Select Dungeon (เลือกดันเจี้ยน)",
    Values = { "Skull King's Crypt (Lv.90+)" },
    Value = "Skull King's Crypt (Lv.90+)",
    Callback = function(selected)
        Config.SelectedDungeon = "halloween"
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Dropdown({
    Title = "Difficulty (ระดับความยาก)",
    Values = { "Easy (ง่าย - เลเวล 90+ มอนสเตอร์เบากว่า)", "Normal (ยาก - มอนสเตอร์เลือดเยอะ ดรอปเต็มที่)" },
    Value = (Config.DungeonDifficulty == "normal") and "Normal (ยาก - มอนสเตอร์เลือดเยอะ ดรอปเต็มที่)" or "Easy (ง่าย - เลเวล 90+ มอนสเตอร์เบากว่า)",
    Callback = function(selected)
        if selected:find("Normal") or selected:find("ยาก") then
            Config.DungeonDifficulty = "normal"
        else
            Config.DungeonDifficulty = "easy"
        end
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Toggle({
    Title = "Solo / Leave Foreign Party (ลงคนเดียว / ออกจากตี้อื่น)",
    Desc = "ออกจากปาร์ตี้ของคนอื่นที่ไม่ใช่หัวหน้าอัตโนมัติ เพื่อให้สามารถเริ่มดันเจี้ยนคนเดียวได้ทันที",
    Value = Config.DungeonForceSolo ~= false,
    Callback = function(state)
        Config.DungeonForceSolo = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Toggle({
    Title = "Auto Repeat Runs (ลงซ้ำอัตโนมัติต่อเนื่อง)",
    Desc = "ลงดันเจี้ยนซ้ำวนไปเรื่อยๆ จนกว่ารอบฟรีและกุญแจจะหมด",
    Value = Config.AutoRepeatDungeon,
    Callback = function(state)
        Config.AutoRepeatDungeon = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Toggle({
    Title = "Return to Farm After Runs (สลับไปฟาร์มเมื่อรอบหมด)",
    Desc = "เมื่อรอบดันเจี้ยนหมด จะสลับกลับไปฟาร์ม Auto Farm / Auto Lv.99 ให้ทันที ไม่ยืนนิ่ง",
    Value = Config.ReturnToFarmAfterDungeon,
    Callback = function(state)
        Config.ReturnToFarmAfterDungeon = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Section({ Title = "👥 Party & Co-op Matchmaking (ระบบปาร์ตี้ & สร้างห้องชวนเพื่อน)", Opened = true })

DungeonTab:Dropdown({
    Title = "Dungeon Mode (รูปแบบการลงดันเจี้ยน)",
    Desc = "เลือกรูปแบบการลงดันเจี้ยน: Solo (ลงคนเดียว) หรือ Party (สร้างปาร์ตี้ลงด้วยกัน)",
    Values = { "Solo (ลงคนเดียว)", "Party (สร้างปาร์ตี้ลงด้วยกัน)" },
    Value = (Config.DungeonPartyMode == "Party") and "Party (สร้างปาร์ตี้ลงด้วยกัน)" or "Solo (ลงคนเดียว)",
    Callback = function(val)
        if val:find("Party") then
            Config.DungeonPartyMode = "Party"
            Config.DungeonForceSolo = false
            WindUI:Notify({ Title = "Dungeon Mode", Content = "เปิดโหมดสร้างปาร์ตี้ (Party Mode)", Duration = 2, Icon = "users" })
        else
            Config.DungeonPartyMode = "Solo"
            WindUI:Notify({ Title = "Dungeon Mode", Content = "เปิดโหมดลงคนเดียว (Solo Mode)", Duration = 2, Icon = "user" })
        end
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Slider({
    Title = "Target Party Members (จำนวนคนในตี้ที่ต้องการ)",
    Desc = "สคริปต์จะรอจนกว่าสมาชิกในปาร์ตี้จะครบตามจำนวนนี้ก่อนจึงจะเริ่มสร้างห้องดันเจี้ยน (2 - 4 คน)",
    Value = { Min = 2, Max = 4, Default = Config.PartyTargetMembers or 2 },
    Callback = function(val)
        Config.PartyTargetMembers = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Slider({
    Title = "Party Wait Timeout (เวลารอคนเข้าตี้ - วินาที)",
    Desc = "เวลารอให้ผู้เล่นที่เราชวนตอบรับเข้าปาร์ตี้ หากหมดเวลาจะเริ่มลงด้วยสมาชิกที่มีอยู่ทันที",
    Value = { Min = 10, Max = 90, Default = Config.PartyWaitTimeout or 30 },
    Callback = function(val)
        Config.PartyWaitTimeout = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Dropdown({
    Title = "Mass Invite Target (เป้าหมายคำเชิญแบบหมู่)",
    Desc = "เลือกกลุ่มผู้เล่นที่จะส่งคำเชิญเข้าปาร์ตี้แบบหมู่",
    Values = { "All Server (ชวนทุกคนในเซิร์ฟเวอร์)", "Friends Only (ชวนเฉพาะเพื่อน)", "Nearby Gate (ชวนคนใกล้ประตูทางเข้า)" },
    Value = (Config.PartyInviteTarget == "Friends Only" and "Friends Only (ชวนเฉพาะเพื่อน)") or (Config.PartyInviteTarget == "Nearby Gate" and "Nearby Gate (ชวนคนใกล้ประตูทางเข้า)") or "All Server (ชวนทุกคนในเซิร์ฟเวอร์)",
    Callback = function(val)
        if val:find("Friend") then
            Config.PartyInviteTarget = "Friends Only"
        elseif val:find("Near") then
            Config.PartyInviteTarget = "Nearby Gate"
        else
            Config.PartyInviteTarget = "All Server"
        end
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Toggle({
    Title = "Auto Invite on Enter (ชวนคนเข้าตี้หมู่อัตโนมัติเมื่อเริ่ม)",
    Desc = "เมื่อเริ่มเข้าคิวสร้างห้อง จะทำการส่งคำเชิญปาร์ตี้ให้ผู้เล่นตามเป้าหมายที่เลือกทันที",
    Value = Config.PartyAutoInvite ~= false,
    Callback = function(state)
        Config.PartyAutoInvite = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Toggle({
    Title = "Auto Accept Party Invites (ตอบรับคำเชิญปาร์ตี้อัตโนมัติ / โหมด Alt)",
    Desc = "สำหรับตัวเด็ก (Alt Account): เมื่อมีคำเชิญเข้าปาร์ตี้เข้ามา ระบบจะตอบรับเข้าปาร์ตี้ให้อัตโนมัติทันที 100%",
    Value = Config.AutoAcceptParty ~= false,
    Callback = function(state)
        Config.AutoAcceptParty = state
        if Config.AutoSave then SaveConfig(true) end
        if state then
            WindUI:Notify({ Title = "Party Alt Mode", Content = "เปิดระบบตอบรับคำเชิญปาร์ตี้อัตโนมัติแล้ว!", Duration = 2.5, Icon = "user-check" })
        end
    end,
})

DungeonTab:Dropdown({
    Title = "Party Accept Filter (เงื่อนไขการรับคำเชิญ)",
    Desc = "เลือกประเภทคำเชิญที่จะตอบรับอัตโนมัติ",
    Values = { "Anyone (รับทุกคน)", "Friends Only (เฉพาะเพื่อน)", "Whitelist (เฉพาะชื่อที่ระบุ)" },
    Value = (Config.PartyAcceptFilter == "Friends Only" and "Friends Only (เฉพาะเพื่อน)") or (Config.PartyAcceptFilter == "Whitelist" and "Whitelist (เฉพาะชื่อที่ระบุ)") or "Anyone (รับทุกคน)",
    Callback = function(val)
        if val:find("Friend") then
            Config.PartyAcceptFilter = "Friends Only"
        elseif val:find("White") then
            Config.PartyAcceptFilter = "Whitelist"
        else
            Config.PartyAcceptFilter = "Anyone"
        end
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Input({
    Title = "Party Whitelist Leaders (ชื่อไอดีหลักที่จะรับตี้)",
    Desc = "พิมพ์ชื่อ Username หรือ UserId ของไอดีหลักที่จะให้รับตี้อัตโนมัติ (คั่นด้วยเครื่องหมายจุลภาค ,)",
    Value = Config.PartyWhitelistUsers or "",
    Placeholder = "เช่น MainPlayer1, 12345678",
    Callback = function(val)
        Config.PartyWhitelistUsers = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Button({
    Title = "👑 Create Party & Mass Invite Now (สร้างปาร์ตี้ & ส่งคำเชิญหมู่ทันที)",
    Desc = "สร้างปาร์ตี้ใหม่และส่งคำเชิญแบบหมู่ให้ผู้เล่นในเซิร์ฟเวอร์ทันที",
    Callback = function()
        task.spawn(function()
            massInviteParty(Config.PartyInviteTarget)
        end)
    end,
})

DungeonTab:Button({
    Title = "▶️ Force Start / Enter Now (เริ่มสร้างห้องลงดันเจี้ยนทันที)",
    Desc = "ข้ามเวลารอสมาชิกในปาร์ตี้ และเริ่มสร้างห้องลงดันเจี้ยนทันที 100%",
    Callback = function()
        forceStartDungeonFlag = true
        task.spawn(function()
            executeDungeonEnterRoutine(true)
        end)
    end,
})

DungeonTab:Button({
    Title = "📋 Check Party Members (ตรวจดูสมาชิกในตี้ปัจจุบัน)",
    Desc = "แสดงจำนวนและรายชื่อสมาชิกในปาร์ตี้ปัจจุบัน",
    Callback = function()
        local members = getPartyMembers()
        local names = {}
        for _, p in ipairs(members) do
            table.insert(names, p.Name)
        end
        WindUI:Notify({
            Title = "Party Status (" .. #members .. " คน)",
            Content = "สมาชิกในปาร์ตี้:\n" .. table.concat(names, ", "),
            Duration = 4,
            Icon = "users"
        })
    end,
})

DungeonTab:Button({
    Title = "🚪 Leave Current Party (ออกจากปาร์ตี้ปัจจุบัน)",
    Desc = "ออกจากปาร์ตี้ปัจจุบันเพื่อไปลงคนเดียวหรือสร้างปาร์ตี้ใหม่",
    Callback = function()
        leaveParty()
        WindUI:Notify({ Title = "Party", Content = "ออกจากปาร์ตี้เรียบร้อย!", Duration = 2, Icon = "log-out" })
    end,
})

DungeonTab:Section({ Title = "🔑 Key Management & Entry (การเข้า & กุญแจ)", Opened = true })

DungeonTab:Toggle({
    Title = "Auto Buy Dungeon Key (ซื้อกุญแจอัตโนมัติ 500k Silver)",
    Desc = "เมื่อรอบฟรีรายวันหมด ระบบจะซื้อกุญแจให้อัตโนมัติหากมี Silver เพียงพอ (ราคา 500,000 Silver ต่อดอก)",
    Value = Config.AutoBuyDungeonKey,
    Callback = function(state)
        Config.AutoBuyDungeonKey = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Toggle({
    Title = "Instant Auto Ready (กดยืนยันพร้อมทันที 100%)",
    Desc = "เมื่อหน้าต่าง Ready Check ขึ้นมา จะกดยืนยัน Ready ให้ทันทีโดยไม่ต้องรอกดเอง",
    Value = Config.AutoReadyDungeon,
    Callback = function(state)
        Config.AutoReadyDungeon = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Button({
    Title = "Enter Dungeon Now (เข้าดันเจี้ยนทันที 1 รอบ)",
    Desc = "เดินไปที่ประตูและส่งคำขอเข้า Skull King's Crypt ทันที",
    Callback = function()
        task.spawn(function()
            executeDungeonEnterRoutine(true)
        end)
    end,
})

DungeonTab:Button({
    Title = "Buy 1x Dungeon Key Now (ซื้อกุญแจ 1 ดอก - 500k Silver)",
    Desc = "ซื้อกุญแจดันเจี้ยนผ่านเซิร์ฟเวอร์ทันที (หากอยู่นอกเมืองจะเดินไปทำรายการที่ประตูให้)",
    Callback = function()
        task.spawn(function()
            buyDungeonKey(false)
        end)
    end,
})

DungeonTab:Button({
    Title = "Leave Dungeon (ออกจากดันเจี้ยนกลับเมือง)",
    Desc = "วาร์ปออกจากดันเจี้ยนกลับสู่ Adventurer Guild",
    Callback = function()
        pcall(function()
            if DungeonAction then
                DungeonAction:FireServer("leave")
                WindUI:Notify({ Title = "Leave Dungeon", Content = "กำลังกลับสู่เมือง...", Duration = 2, Icon = "log-out" })
            end
        end)
    end,
})

DungeonTab:Section({ Title = "⚔️ Dungeon Combat & Mechanics (การต่อสู้ในดันเจี้ยน)", Opened = true })

DungeonTab:Toggle({
    Title = "Prioritize Ritual Pillars (เน้นทำลายเสาพิธีกรรมปลดผนึกบอส)",
    Desc = "เมื่อบอสเข้าสู่สเตทผนึกอมตะ (Seal) ระบบจะสลับไปตีเสาพิธีกรรมทันทีเพื่อทำลายเกราะ",
    Value = Config.PrioritizeDungeonPillars,
    Callback = function(state)
        Config.PrioritizeDungeonPillars = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Toggle({
    Title = "Auto Kick Demon Skulls (เตะหัวกะโหลกใส่บอสอัตโนมัติ)",
    Desc = "เตะหัวกะโหลก Demon Skull (Dud) ที่ตกในห้องบอสใส่ Skull King ทันที (ลดเลือดบอส 1-2% ต่อนัด)",
    Value = Config.AutoKickSkulls,
    Callback = function(state)
        Config.AutoKickSkulls = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Toggle({
    Title = "Prioritize Crypt Boss & Mini-Boss (เน้นตีบอสและมินิบอสก่อน)",
    Desc = "ล็อคเป้า Skull King Boss และ Potion Witch ทันทีที่ปรากฏตัว",
    Value = Config.PrioritizeDungeonBoss,
    Callback = function(state)
        Config.PrioritizeDungeonBoss = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Toggle({
    Title = "Auto Revive Teammates (ชุบชีวิตเพื่อนร่วมทีมอัตโนมัติ)",
    Desc = "ตรวจจับเพื่อนในปาร์ตี้ที่ล้มลง (RevivePrompt) แล้ววาร์ปไปช่วยชุบทันที",
    Value = Config.AutoReviveTeammates,
    Callback = function(state)
        Config.AutoReviveTeammates = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Dropdown({
    Title = "Dungeon Movement Mode (การเคลื่อนที่ในดันเจี้ยน)",
    Desc = "เลือกรูปแบบการเข้าหามอนสเตอร์ในดันเจี้ยน: วาร์ปทันที (⚡ Warp - ตีเร็วที่สุด) หรือ เดินบนพื้นปกติ (🚶 Walk)",
    Values = { "⚡ Warp (วาร์ปไปหามอนสเตอร์ทันที - ตีเร็วสุด)", "🚶 Walk (เดินไปหามอนสเตอร์บนพื้น)" },
    Value = (Config.FarmMode == "Walk" and "🚶 Walk (เดินไปหามอนสเตอร์บนพื้น)") or "⚡ Warp (วาร์ปไปหามอนสเตอร์ทันที - ตีเร็วสุด)",
    Callback = function(val)
        if val:find("Walk") then
            Config.FarmMode = "Walk"
            WindUI:Notify({ Title = "Dungeon Movement", Content = "เปิดใช้งาน: โหมดเดินปกติบนพื้น (Walk Mode)", Duration = 2.5, Icon = "footprints" })
        else
            Config.FarmMode = "Warp"
            WindUI:Notify({ Title = "Dungeon Movement", Content = "เปิดใช้งาน: โหมดวาร์ปทันที (Warp Mode - ตีเร็วที่สุด)", Duration = 2.5, Icon = "zap" })
        end
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Slider({
    Title = "Dungeon Safe Height (ความสูงลอยตัวหลบกราวด์แอตแทก)",
    Value = { Min = 3.5, Max = 10, Default = Config.DungeonSafeHeight },
    Callback = function(val)
        Config.DungeonSafeHeight = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Slider({
    Title = "Dungeon Attack Delay (ความเร็วโจมตี)",
    Desc = "ความเร็วในการโจมตีมอนสเตอร์ (ค่า 0.05 หรือน้อยกว่าจะโจมตีเร็วสุดตาม ASPD จริง)",
    Value = { Min = 0.02, Max = 0.35, Default = Config.DungeonAttackDelay or 0.05 },
    Step = 0.01,
    Callback = function(val)
        Config.DungeonAttackDelay = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Section({ Title = "🎁 Rewards & Loot (ของรางวัล & หีบสมบัติ)", Opened = true })

DungeonTab:Toggle({
    Title = "Auto Claim Exit Chest (เปิดหีบรับรางวัล Tier VI อัตโนมัติ)",
    Desc = "เมื่อเคลียร์ดันเจี้ยนสำเร็จ จะวาร์ปไปเปิด ChestPrompt ของตัวเองเพื่อรับไอเทมระดับสูง",
    Value = Config.AutoClaimExitChest,
    Callback = function(state)
        Config.AutoClaimExitChest = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Toggle({
    Title = "Auto Secret Runes & Footprints (ค้นหารูน & หีบลับ)",
    Desc = "เปิดใช้งานรูนโบราณ (DungeonRune) ในเขาวงกตเพื่อเปิดทางสู่หีบสมบัติลับ",
    Value = Config.AutoSecretChests,
    Callback = function(state)
        Config.AutoSecretChests = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Toggle({
    Title = "Auto Leave On Clear (ออกจากดันเจี้ยนหลังรับของ)",
    Desc = "หลังจากเปิดหีบรับรางวัลเรียบร้อยแล้ว จะออกจากดันเจี้ยนอัตโนมัติเพื่อเริ่มรอบใหม่ทันที",
    Value = Config.AutoLeaveOnClear,
    Callback = function(state)
        Config.AutoLeaveOnClear = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Toggle({
    Title = "Auto Replay Dungeon (กด Replay ลงซ้ำอัตโนมัติ)",
    Desc = "เมื่อเคลียร์ดันเจี้ยนและรับของเสร็จ จะกด Replay เพื่อเริ่มรอบใหม่อัตโนมัติ",
    Value = Config.AutoRepeatDungeon,
    Callback = function(state)
        Config.AutoRepeatDungeon = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Toggle({
    Title = "Auto Confirm Replay & Ready (ยืนยันเข้าดันเจี้ยนอัตโนมัติ)",
    Desc = "กดยืนยันปุ่ม Accept และ Ready ทุกขั้นตอนเพื่อเข้าสู่ดันเจี้ยนรอบต่อไปทันที",
    Value = Config.AutoConfirmReplay,
    Callback = function(state)
        Config.AutoConfirmReplay = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Toggle({
    Title = "Auto Buy Dungeon Key (ซื้อกุญแจอัตโนมัติเมื่อหมด)",
    Desc = "กดซื้อกุญแจดันเจี้ยนอัตโนมัติ (500k Silver) ในหน้า Replay เมื่อรอบฟรีหมด",
    Value = Config.AutoBuyDungeonKey,
    Callback = function(state)
        Config.AutoBuyDungeonKey = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DungeonTab:Button({
    Title = "Teleport to Exit Chest Now (วาร์ปไปเปิดหีบทันที)",
    Desc = "วาร์ปไปที่หีบสมบัติของผู้เล่นและกดเปิดทันที",
    Callback = function()
        task.spawn(function()
            executeClaimExitChest()
        end)
    end,
})

-- ==================== TAB 3: AUTO EQUIP & GEAR ====================
GearTab:Section({ Title = "Equipment Automation", Opened = true })

GearTab:Toggle({
    Title = "Auto Equip Best Armor & Accessories",
    Desc = "ใส่เกราะ หมวก รองเท้า และเครื่องประดับที่ดีที่สุดในกระเป๋าอัตโนมัติ (@best)",
    Value = Config.AutoEquipBest,
    Callback = function(state)
        Config.AutoEquipBest = state
        if Config.AutoSave then SaveConfig(true) end
        if state then executeAutoEquipBest() end
    end,
})

GearTab:Toggle({
    Title = "Auto Equip Best Weapon",
    Desc = "ค้นหาและสวมใส่อาวุธที่มีดาเมจและ Tier สูงสุดตามเลเวลผู้เล่นอัตโนมัติ",
    Value = Config.AutoEquipBestWeapon,
    Callback = function(state)
        Config.AutoEquipBestWeapon = state
        if Config.AutoSave then SaveConfig(true) end
        if state then executeAutoEquipBest() end
    end,
})

GearTab:Toggle({
    Title = "Auto Equip Best Cards",
    Desc = "ใส่การ์ดมอนสเตอร์ที่ดีที่สุดลงช่องสวมใส่อัตโนมัติ",
    Value = Config.AutoEquipCards,
    Callback = function(state)
        Config.AutoEquipCards = state
        if Config.AutoSave then SaveConfig(true) end
        if state then executeAutoEquipBest() end
    end,
})

GearTab:Button({
    Title = "Equip All Best Gear Now",
    Desc = "กดสวมใส่อุปกรณ์และการ์ดที่ดีที่สุดทั้งหมดทันที",
    Callback = function()
        executeAutoEquipBest()
        WindUI:Notify({ Title = "Auto Equip", Content = "สวมใส่อุปกรณ์และการ์ดที่ดีที่สุดเรียบร้อย!", Duration = 2, Icon = "shield-check" })
    end,
})

GearTab:Section({ Title = "Blacksmith & Refine", Opened = true })

GearTab:Toggle({
    Title = "Auto Refine Weapon (+ Upgrade)",
    Desc = "ใช้หินตีบวกอัปเกรดอาวุธที่กำลังใส่อยู่อัตโนมัติเมื่อมีหิน Refine Stone",
    Value = Config.AutoRefine,
    Callback = function(state)
        Config.AutoRefine = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

-- ==================== TAB: AUTO SELL (เลือกระดับได้) ====================
AutoSellTab:Section({ Title = "Auto Sell Master Controls", Opened = true })

AutoSellTab:Toggle({
    Title = "Enable Auto Sell",
    Desc = "เปิดระบบขายของและอุปกรณ์อัตโนมัติตามระดับ Tier / Rarity ที่กำหนด",
    Value = Config.AutoSell,
    Callback = function(state)
        Config.AutoSell = state
        if Config.AutoSave then SaveConfig(true) end
        if state then
            WindUI:Notify({ Title = "Auto Sell", Content = "เปิดระบบขายของอัตโนมัติแล้ว กำลังตรวจสอบไอเทม...", Duration = 2, Icon = "shopping-bag" })
            task.spawn(function()
                executeAutoSell(false)
            end)
        else
            isSelling = false
            WindUI:Notify({ Title = "Auto Sell", Content = "ปิดระบบขายของอัตโนมัติแล้ว", Duration = 2, Icon = "square" })
        end
    end,
})

AutoSellTab:Toggle({
    Title = "Auto Sell on Bag Full (> 88%)",
    Desc = "เมื่อกระเป๋าใกล้เต็ม (เหลือไม่เกิน 3 ช่อง) จะขายของที่ตรงตามเกณฑ์ทันที ไม่ต้องรอนาน",
    Value = Config.AutoSellOnFull,
    Callback = function(state)
        Config.AutoSellOnFull = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

AutoSellTab:Toggle({
    Title = "Periodic Auto Sell (Timer)",
    Desc = "ตั้งเวลาขายของอัตโนมัติเป็นระยะตามรอบเวลาที่ตั้งไว้",
    Value = Config.AutoSellPeriodic,
    Callback = function(state)
        Config.AutoSellPeriodic = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

AutoSellTab:Slider({
    Title = "Auto Sell Interval (Seconds)",
    Value = { Min = 10, Max = 180, Default = Config.AutoSellInterval },
    Callback = function(val)
        Config.AutoSellInterval = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

AutoSellTab:Toggle({
    Title = "Smart Merchant Quick Visit",
    Desc = "หากอยู่นอกระยะพ่อค้า ระบบจะแวะแตะพ่อค้าเสี้ยววินาทีแล้ววาร์ปกลับจุดฟาร์มเดิมอัตโนมัติ เพื่อรับประกันว่าเซิร์ฟเวอร์คิดเงินให้ 100%",
    Value = Config.AutoSellQuickVisit,
    Callback = function(state)
        Config.AutoSellQuickVisit = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

AutoSellTab:Section({ Title = "Selectable Gear Tiers (เลือกระดับ Tier อุปกรณ์)", Opened = true })

AutoSellTab:Dropdown({
    Title = "Max Gear Tier to Sell (เกณฑ์ Tier สูงสุด)",
    Values = {
        "Tier 1 Only",
        "Up to Tier 2",
        "Up to Tier 3",
        "Up to Tier 4",
        "Up to Tier 5",
        "Custom Toggles Below",
    },
    Value = Config.MaxSellTier,
    Callback = function(val)
        Config.MaxSellTier = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

AutoSellTab:Toggle({
    Title = "Sell Tier 1 (Lv.1 - 8 Gear)",
    Desc = "ขายอาวุธและชุดเกราะ Tier 1 สีเทา/ขาว ทั้งหมด",
    Value = Config.SellTier1,
    Callback = function(state)
        Config.SellTier1 = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

AutoSellTab:Toggle({
    Title = "Sell Tier 2 (Lv.9 - 25 Gear)",
    Desc = "ขายอาวุธและชุดเกราะ Tier 2 สีเขียว ทั้งหมด",
    Value = Config.SellTier2,
    Callback = function(state)
        Config.SellTier2 = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

AutoSellTab:Toggle({
    Title = "Sell Tier 3 (Lv.26 - 50 Gear)",
    Desc = "ขายอาวุธและชุดเกราะ Tier 3 สีฟ้า ทั้งหมด",
    Value = Config.SellTier3,
    Callback = function(state)
        Config.SellTier3 = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

AutoSellTab:Toggle({
    Title = "Sell Tier 4 (Lv.51 - 75 Gear)",
    Desc = "ขายอาวุธและชุดเกราะ Tier 4 สีม่วง ทั้งหมด (โปรดระวัง)",
    Value = Config.SellTier4,
    Callback = function(state)
        Config.SellTier4 = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

AutoSellTab:Toggle({
    Title = "Sell Tier 5 (Lv.76 - 99 Gear)",
    Desc = "ขายอาวุธและชุดเกราะ Tier 5 สีส้ม ทั้งหมด (โปรดระวัง)",
    Value = Config.SellTier5,
    Callback = function(state)
        Config.SellTier5 = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

AutoSellTab:Section({ Title = "Selectable Gear Rarity (เลือกระดับความหายาก)", Opened = true })

do
    local allSellRarityOptions = {
        "Common (ธรรมดา / ขาว)",
        "Uncommon (ไม่ธรรมดา / เขียว)",
        "Rare (หายาก / ฟ้า)",
        "Epic (มหากาพย์ / ม่วง)",
        "Legendary (ตำนาน / ทอง)",
        "Mythic (เทพเจ้า / แดง)",
    }

    local sellRarityDropdown = nil
    sellRarityDropdown = AutoSellTab:Dropdown({
        Title = "Select Gear Rarities to Sell (เลือกระดับความหายากที่ต้องการขาย)",
        Desc = "เลือก Rarity ที่ต้องการให้ขายอัตโนมัติ (สามารถเลือกได้หลายระดับพร้อมกัน)",
        Values = allSellRarityOptions,
        Value = Config.SellRarities or { "Common (ธรรมดา / ขาว)", "Uncommon (ไม่ธรรมดา / เขียว)", "Rare (หายาก / ฟ้า)" },
        Multi = true,
        AllowNone = true,
        Callback = function(val)
            Config.SellRarities = val
            if Config.AutoSave then SaveConfig(true) end
        end,
    })

    AutoSellTab:Button({
        Title = "✅ Select All Rarities (เลือกทุกระดับ)",
        Desc = "เลือกขายทุกระดับความหายาก (Common ถึง Mythic)",
        Callback = function()
            Config.SellRarities = allSellRarityOptions
            if sellRarityDropdown and sellRarityDropdown.SetValue then
                pcall(function() sellRarityDropdown:SetValue(allSellRarityOptions) end)
            end
            if Config.AutoSave then SaveConfig(true) end
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "Auto Sell Rarity",
                    Content = "เลือกขายทุกระดับความหายากแล้ว (Common - Mythic)",
                    Duration = 2,
                    Icon = "check-check"
                })
            end
        end,
    })

    AutoSellTab:Button({
        Title = "⚪ Select Common & Uncommon Only (เฉพาะขาว/เขียว)",
        Desc = "เลือกเฉพาะของธรรมดาและไม่ธรรมดา (ปลอดภัย ไม่ขายของหายาก)",
        Callback = function()
            local safeRarities = { "Common (ธรรมดา / ขาว)", "Uncommon (ไม่ธรรมดา / เขียว)" }
            Config.SellRarities = safeRarities
            if sellRarityDropdown and sellRarityDropdown.SetValue then
                pcall(function() sellRarityDropdown:SetValue(safeRarities) end)
            end
            if Config.AutoSave then SaveConfig(true) end
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "Auto Sell Rarity",
                    Content = "เลือกขายเฉพาะ Common และ Uncommon เรียบร้อย",
                    Duration = 2,
                    Icon = "shield-check"
                })
            end
        end,
    })

    AutoSellTab:Button({
        Title = "❌ Clear All Rarities (ยกเลิกทั้งหมด)",
        Desc = "ยกเลิกการเลือก Rarity ทั้งหมด (ไม่ขายอุปกรณ์ใดๆ)",
        Callback = function()
            Config.SellRarities = {}
            if sellRarityDropdown and sellRarityDropdown.SetValue then
                pcall(function() sellRarityDropdown:SetValue({}) end)
            end
            if Config.AutoSave then SaveConfig(true) end
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "Auto Sell Rarity",
                    Content = "ยกเลิก Rarity ทั้งหมดแล้ว",
                    Duration = 2,
                    Icon = "x-circle"
                })
            end
        end,
    })
end

AutoSellTab:Section({ Title = "Item Categories (เลือกประเภทที่ต้องการขาย)", Opened = true })

AutoSellTab:Toggle({
    Title = "Sell Weapons (อาวุธ)",
    Desc = "ขายอาวุธ (ดาบ, มีด, ธนู, คทา, ขวาน ฯลฯ)",
    Value = Config.SellWeapons,
    Callback = function(state)
        Config.SellWeapons = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

AutoSellTab:Toggle({
    Title = "Sell Armors (ชุดเกราะ)",
    Desc = "ขายชุดเกราะป้องกันตัว",
    Value = Config.SellArmors,
    Callback = function(state)
        Config.SellArmors = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

AutoSellTab:Toggle({
    Title = "Sell Accessories (เครื่องประดับ)",
    Desc = "ขายหมวก, รองเท้า, ผ้าคลุม, หน้ากาก และแหวน",
    Value = Config.SellAccessories,
    Callback = function(state)
        Config.SellAccessories = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

AutoSellTab:Toggle({
    Title = "Sell Monster Junk Drops (ขยะมอนสเตอร์)",
    Desc = "ขายชิ้นส่วนมอนสเตอร์ประเภท Etc ทั้งหมด (ไม่รวมยา, หินตีบวก, กล่องสุ่ม)",
    Value = Config.SellJunkDrops,
    Callback = function(state)
        Config.SellJunkDrops = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

AutoSellTab:Section({ Title = "Safety & Protection (ระบบความปลอดภัย)", Opened = true })

AutoSellTab:Toggle({
    Title = "Protect Refined Gear (+ Upgraded)",
    Desc = "ห้ามขายอุปกรณ์ที่ผ่านการตีบวกเด็ดขาด (Refine > 0)",
    Value = Config.ProtectRefined,
    Callback = function(state)
        Config.ProtectRefined = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

AutoSellTab:Toggle({
    Title = "Protect Best Gear for Level",
    Desc = "ห้ามขายอุปกรณ์ที่มีสเตตัสสูงสุดตามเลเวลตัวละคร",
    Value = Config.ProtectBestGear,
    Callback = function(state)
        Config.ProtectBestGear = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

AutoSellTab:Section({ Title = "Manual Actions & Status", Opened = true })

AutoSellTab:Button({
    Title = "Sell Selected Items Now (กดขายทันที)",
    Desc = "ทำการขายไอเทมตามระดับและเกณฑ์ที่เลือกไว้ทั้งหมดทันที",
    Callback = function()
        executeAutoSell(false)
    end,
})

AutoSellTab:Button({
    Title = "Inspect Sellable Items (ตรวจเช็คไอเทม)",
    Desc = "ตรวจสอบจำนวนไอเทมที่จะถูกขายและประมาณการ Silver ที่จะได้รับ",
    Callback = function()
        local sellList, sellIds, estSilver = getSellableItems()
        WindUI:Notify({
            Title = "Sellable Status",
            Content = string.format("พบไอเทมตรงเกณฑ์: %d ชิ้น\nประเมินได้รับ: ~%s Silver", #sellIds, tostring(estSilver)),
            Duration = 3,
            Icon = "info",
        })
    end,
})

-- ==================== TAB 4: ADVANCED AUTO LOOT ====================
LootTab:Section({ Title = "🧲 Stealth Drop Magnet & Vacuum (ดูดของแบบเนียนๆ ไม่วาร์ป)", Opened = true })

LootTab:Toggle({
    Title = "Enable Auto Loot Drops (เปิดระบบเก็บของอัตโนมัติ)",
    Desc = "เก็บไอเทมที่ดรอปบนพื้นทั้งหมดแบบอัตโนมัติโดยไม่ต้องวาร์ปตัวละครไปเก็บ",
    Value = Config.AutoLoot,
    Callback = function(state)
        Config.AutoLoot = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

LootTab:Toggle({
    Title = "Stealth Magnet Pull (ดูดไอเทมลอยเข้าตัวแบบเนียนๆ)",
    Desc = "ดึงไอเทมที่ตกบนพื้นให้ลอยดูดเข้าหาตัวละครเองแบบเนียนๆ ตัวละครยืนตีมอนต่อได้โดยไม่กระตุกหรือวาร์ป",
    Value = Config.StealthMagnetLoot ~= false,
    Callback = function(state)
        Config.StealthMagnetLoot = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

LootTab:Toggle({
    Title = "Loot Priority (เก็บของทันทีที่มอนตาย)",
    Desc = "ดึงและเก็บไอเทมดรอปเข้าตัวทันทีระหว่างต่อสู้แบบเรียลไทม์",
    Value = Config.LootPriority,
    Callback = function(state)
        Config.LootPriority = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

LootTab:Slider({
    Title = "Loot Vacuum Radius (รัศมีดูดเก็บของอัตโนมัติ)",
    Desc = "ระยะรัศมีในการดึงและดูดเก็บไอเทมรอบตัวละคร (ไม่ต้องวาร์ป)",
    Value = {
        Min = 20,
        Max = 200,
        Default = tonumber(Config.LootRadius) or 120,
    },
    Step = 5,
    Callback = function(val)
        Config.LootRadius = tonumber(val) or 120
        if Config.AutoSave then SaveConfig(true) end
    end,
})

LootTab:Toggle({
    Title = "Auto Open LootBox / Chests (เปิดกล่องสมบัติระยะไกล)",
    Desc = "เปิดกล่องสมบัติและหีบที่ดรอปอัตโนมัติจากระยะไกลโดยไม่ต้องวาร์ปตัวละครไปหากล่อง",
    Value = Config.AutoOpenLootBox,
    Callback = function(state)
        Config.AutoOpenLootBox = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

LootTab:Button({
    Title = "Manual Vacuum Drops Now (กดดูดของรอบตัวทันที)",
    Callback = function()
        performAutoLoot()
        WindUI:Notify({ Title = "Stealth Looting 🧲", Content = "ดูดเก็บไอเทมรอบตัวแบบเนียนๆ เรียบร้อย!", Duration = 2, Icon = "sparkles" })
    end,
})

-- ==================== TAB 5: AUTO LEVEL 99 ====================
AutoProgTab:Section({ Title = "Auto Level Progression to Max", Opened = true })

autoProgressionToggle = AutoProgTab:Toggle({
    Title = "Auto Map Progression (Auto Level to 99)",
    Desc = "เช็คเลเวลตัวละครและวาร์ปเปลี่ยน Field อัตโนมัติ เพื่อฟาร์มจุดที่ดีที่สุดจนถึง Lv.99",
    Value = Config.AutoProgression,
    Callback = function(state)
        Config.AutoProgression = state
        if state then
            -- If user turns ON Auto Lv.99, turn OFF Auto Dungeon so they don't clash!
            if Config.AutoDungeon then
                Config.AutoDungeon = false
                pcall(function()
                    if autoDungeonToggle then
                        if autoDungeonToggle.SetValue then
                            autoDungeonToggle:SetValue(false)
                        elseif autoDungeonToggle.Set then
                            autoDungeonToggle:Set(false)
                        end
                    end
                end)
            end
            Config.AutoFarm = true
            if Config.AutoSave then SaveConfig(true) end
            WindUI:Notify({ Title = "Auto Level 99", Content = "เปิดโหมดไต่เลเวล 99 อัตโนมัติแล้ว! (ปิด Auto Dungeon แล้ว)", Duration = 3, Icon = "zap" })
            task.spawn(function()
                checkAutoProgression(true)
            end)
        else
            isCheckingBossArena = false
            activeBossFight = nil
            isWarpingZone = false
            stopCombatAndTargeting()
            if Config.AutoSave then SaveConfig(true) end
            WindUI:Notify({ Title = "Auto Level 99", Content = "ปิดโหมดไต่เลเวล 99 และหยุดการวาร์ปแล้ว", Duration = 2, Icon = "square" })
        end
    end,
})

AutoProgTab:Toggle({
    Title = "Auto Return to Field After Boss (กลับมาฟาร์มหลังตีบอสเสร็จ)",
    Desc = "เมื่อไปตีบอสจนตาย จะเก็บของดรอป/ไข่สัตว์เลี้ยง แล้ววาร์ปกลับมาฟาร์มที่แมพเลเวล 1-99 ทันที",
    Value = Config.ReturnToProgressionAfterBoss,
    Callback = function(state)
        Config.ReturnToProgressionAfterBoss = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

AutoProgTab:Button({
    Title = "Check Optimal Zone",
    Callback = function()
        local lv = LocalPlayer:GetAttribute("Level") or 1
        local field, name = getOptimalZone(lv)
        WindUI:Notify({
            Title = "Level Status",
            Content = "เลเวลปัจจุบัน: " .. lv .. "\nแมพที่แนะนำ: " .. name,
            Duration = 3,
            Icon = "info",
        })
    end,
})

-- ==================== TAB 6: AUTO REWARDS & QUESTS ====================
local function executeAutoClaimRewards()
    -- 1. Server Remote Claims: Online Rewards (1..6), Monthly Check-in, 8-Day Check-in
    pcall(function()
        local rewardAction = RemotesLazy.RewardAction or getRemote("RewardAction")
        if rewardAction then
            for i = 1, 6 do
                rewardAction:FireServer("online", i)
            end
            rewardAction:FireServer("month", nil)
            rewardAction:FireServer("c8", nil)
        end
    end)

    -- 2. Daily Calendar Claim
    pcall(function()
        local dailyClaim = RemotesLazy.DailyClaim or getRemote("DailyClaim")
        if dailyClaim then
            dailyClaim:FireServer()
        end
    end)

    -- 3. Battle Pass Missions & Rewards
    pcall(function()
        local bpAction = RemotesLazy.BattlePassAction or getRemote("BattlePassAction")
        if bpAction then
            bpAction:FireServer("claimAll")
            bpAction:FireServer("missionAll")
        end
    end)

    -- 4. Fast GUI Claim Button Clicker for any visible Claim button on screen (Rewards & Check-in)
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return end
        for _, g in ipairs(pg:GetChildren()) do
            if g:IsA("ScreenGui") and g.Enabled then
                for _, d in ipairs(g:GetDescendants()) do
                    if d:IsA("GuiButton") and d.Visible then
                        local t = (d:IsA("TextButton") and d.Text) or (d:FindFirstChildWhichIsA("TextLabel", true) and d:FindFirstChildWhichIsA("TextLabel", true).Text) or ""
                        local lowerT = t:gsub("%s+", " "):lower():match("^%s*(.-)%s*$")
                        if lowerT == "claim" or lowerT == "รับรางวัล" or lowerT == "claim all" or d.Name == "Status" or d.Name == "ClaimBtn" or d.Name == "ClaimButton" then
                            clickGuiButton(d)
                        end
                    end
                end
            end
        end
    end)
end

local function executeAutoClaimAchievements()
    -- 1. Scan all 87 Achievements against AchieveJson attributes
    pcall(function()
        local Shared = ReplicatedStorage:FindFirstChild("Shared")
        if not Shared then return end
        local AchData = require(Shared:WaitForChild("AchievementData", 2))
        if not AchData or not AchData.List then return end

        local achieveRaw = LocalPlayer:GetAttribute("AchieveJson") or "{}"
        local HttpService = game:GetService("HttpService")
        local data = HttpService:JSONDecode(achieveRaw)
        local got = data.Got or {}
        local C = data.C or {}
        local pLevel = tonumber(LocalPlayer:GetAttribute("Level")) or 1

        local actionRemote = RemotesLazy.AchieveAction or getRemote("AchieveAction")
        if not actionRemote then return end

        for _, def in ipairs(AchData.List) do
            if not got[def.Id] then
                local curVal = (def.Type == "level") and pLevel or (tonumber(C[def.Type]) or 0)
                local req = def.Count or 1
                if curVal >= req then
                    actionRemote:FireServer("claim", def.Id, false)
                end
            end
        end
    end)

    -- 2. Fast GUI Claim Button Clicker for Adventure Book (Achievements & Titles)
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return end
        for _, g in ipairs(pg:GetChildren()) do
            if g:IsA("ScreenGui") and g.Enabled then
                for _, d in ipairs(g:GetDescendants()) do
                    if d:IsA("GuiButton") and d.Visible then
                        local t = (d:IsA("TextButton") and d.Text) or (d:FindFirstChildWhichIsA("TextLabel", true) and d:FindFirstChildWhichIsA("TextLabel", true).Text) or ""
                        local lowerT = t:gsub("%s+", " "):lower():match("^%s*(.-)%s*$")
                        if lowerT == "claim" or lowerT == "รับรางวัล" or lowerT == "claim all" or d.Name == "ClaimBtn" or d.Name == "ClaimButton" then
                            clickGuiButton(d)
                        end
                    end
                end
            end
        end
    end)
end

RewardsTab:Section({ Title = "Quests & Daily Rewards", Opened = true })

RewardsTab:Toggle({
    Title = "Auto Claim Quests (EXP & Silver)",
    Desc = "ส่งและรับรางวัลเควสท์ล่ามอนสเตอร์ที่สำเร็จแล้วอัตโนมัติ",
    Value = Config.AutoClaimQuests,
    Callback = function(state)
        Config.AutoClaimQuests = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

RewardsTab:Toggle({
    Title = "Auto Claim Online & Daily Rewards (รับรางวัลออนไลน์ & เช็คอินรายวัน)",
    Desc = "รับรางวัลออนไลน์ประจำวัน (Online Rewards 5m-3h) และของขวัญเช็คอินรายวัน (Monthly Check-in / Daily) อัตโนมัติ",
    Value = Config.AutoClaimDaily,
    Callback = function(state)
        Config.AutoClaimDaily = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

RewardsTab:Toggle({
    Title = "Auto Claim Adventure Book (รับรางวัลสมุดการผจญภัย & Achievements)",
    Desc = "ตรวจสอบและกดรับรางวัลความสำเร็จใน Adventure Book (Achievements & Titles) ที่สำเร็จแล้วทั้งหมดอัตโนมัติ",
    Value = Config.AutoClaimAchieve,
    Callback = function(state)
        Config.AutoClaimAchieve = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

RewardsTab:Toggle({
    Title = "Auto Pet Summon & Care",
    Desc = "เรียกสัตว์เลี้ยงและดูแลอัตโนมัติเพื่อรับสเตตัสเสริม",
    Value = Config.AutoPet,
    Callback = function(state)
        Config.AutoPet = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

RewardsTab:Button({
    Title = "Claim All Pending Rewards Now (กดรับรางวัลทั้งหมดทันที)",
    Callback = function()
        executeAutoClaimRewards()
        executeAutoClaimAchievements()
        pcall(function()
            local hs = HttpService
            local qJson = hs:JSONDecode(LocalPlayer:GetAttribute("QuestsJson") or "{}")
            if qJson and qJson.Active then
                for qid, _ in pairs(qJson.Active) do
                    if RemotesLazy.QuestAction then
                        RemotesLazy.QuestAction:FireServer("claim", qid)
                    end
                end
            end
        end)
        WindUI:Notify({
            Title = "Rewards & Adventure Book 🎁",
            Content = "ส่งคำสั่งรับรางวัลออนไลน์, เช็คอินรายวัน, เควสท์ และสมุดความสำเร็จเรียบร้อย!",
            Duration = 3,
            Icon = "gift"
        })
    end,
})

-- ==================== TAB 7: AUTO STATS ====================
StatsTab:Section({ Title = "Auto Stat Allocation", Opened = true })

StatsTab:Toggle({
    Title = "Auto Allocate Stat Points",
    Desc = "อัปสเตตัสอัตโนมัติตามสายที่เลือก",
    Value = Config.AutoAllocateStats,
    Callback = function(state)
        Config.AutoAllocateStats = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

StatsTab:Dropdown({
    Title = "Stat Build Preset",
    Values = {
        "Auto (Detect by Job)",
        "Thief (AGI > STR)",
        "Swordsman (STR > VIT)",
        "Archer (DEX > AGI)",
        "Mage (INT > DEX)",
        "Cleric (INT > VIT)",
        "Merchant (STR > DEX)",
        "Pure STR", "Pure AGI", "Pure DEX", "Pure INT",
        "Balanced (All Stats)",
    },
    Value = Config.StatPreset,
    Callback = function(val)
        Config.StatPreset = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

-- ==================== TAB 8: SURVIVAL & POTIONS ====================
SurvivalTab:Section({ Title = "Auto Potions & Heal", Opened = true })

SurvivalTab:Toggle({
    Title = "Auto Use HP Potion",
    Desc = "ดื่มยาฟื้นพลังชีวิตอัตโนมัติเมื่อเลือดต่ำกว่าเกณฑ์",
    Value = Config.AutoHpPotion,
    Callback = function(state)
        Config.AutoHpPotion = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

SurvivalTab:Slider({
    Title = "HP Potion Threshold (%)",
    Value = { Min = 20, Max = 90, Default = Config.HpThreshold },
    Callback = function(val)
        Config.HpThreshold = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

SurvivalTab:Toggle({
    Title = "Auto Use SP Potion",
    Desc = "ดื่มยาฟื้นมานาอัตโนมัติเมื่อมานาต่ำกว่าเกณฑ์",
    Value = Config.AutoSpPotion,
    Callback = function(state)
        Config.AutoSpPotion = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

SurvivalTab:Slider({
    Title = "SP Potion Threshold (%)",
    Value = { Min = 10, Max = 80, Default = Config.SpThreshold },
    Callback = function(val)
        Config.SpThreshold = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

SurvivalTab:Section({ Title = "Death Recovery", Opened = true })

SurvivalTab:Toggle({
    Title = "Auto Respawn & Resume Farm",
    Desc = "เมื่อตาย จะกดเกิดและวาร์ปกลับไปฟาร์มต่อทันที",
    Value = Config.AutoRespawn,
    Callback = function(state)
        Config.AutoRespawn = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

-- ==================== TAB: AUTO DODGE ====================
DodgeTab:Section({ Title = "🛡️ Real Auto Dodge System", Opened = true })

DodgeTab:Toggle({
    Title = "Enable Auto Dodge (หลบหลีกอัตโนมัติ)",
    Desc = "เปิดระบบหลบหลีกอัจฉริยะ ยิง Dash Remote + พุ่งหลบการโจมตีอันตรายจริง",
    Value = Config.AutoDodge,
    Callback = function(state)
        Config.AutoDodge = state
        if Config.AutoSave then SaveConfig(true) end
        if state then
            WindUI:Notify({ Title = "Auto Dodge", Content = "เปิดระบบหลบหลีกอัตโนมัติแล้ว", Duration = 2, Icon = "shield-check" })
        else
            currentSafeHoldTarget = nil
            safeHoldUntil = 0
            isDodgingUntil = 0
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Velocity = Vector3.zero
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
            WindUI:Notify({ Title = "Auto Dodge", Content = "ปิดระบบหลบหลีกอัตโนมัติ", Duration = 2, Icon = "shield-off" })
        end
    end,
})

DodgeTab:Toggle({
    Title = "Pre-Hit Attack Dodge (หลบการง้างตี 1000%)",
    Desc = "ดักจับ AnimAttack ทันทีที่มอนสเตอร์เริ่มง้างฟัน แดชวนเข้าหลังและลอยหลบเหนือ Hitbox",
    Value = Config.DodgeMonsterAttack,
    Callback = function(state)
        Config.DodgeMonsterAttack = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DodgeTab:Toggle({
    Title = "Pre-Cast Skill Dodge (หลบสกิลมอนสเตอร์ 1000%)",
    Desc = "ดักจับ AnimSkill เมื่อมอนสเตอร์เริ่มร่ายสกิลพิเศษ แดชฉีกออกจากรัศมีสกิลทันที",
    Value = Config.DodgeMonsterSkill,
    Callback = function(state)
        Config.DodgeMonsterSkill = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DodgeTab:Toggle({
    Title = "Auto Dodge into Green Circle (หลบเข้าวงเขียวบอส)",
    Desc = "ตรวจจับวงกลมสีเขียว (Safe Zone / วงรอดชีวิต) ของบอสทุกตัว แล้วพุ่งเข้าไปหลบในวงเขียวทันทีและอยู่จนกว่าสกิลจะจบ",
    Value = Config.DodgeGreenCircle,
    Callback = function(state)
        Config.DodgeGreenCircle = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DodgeTab:Toggle({
    Title = "Dodge Boss AoE Telegraphs (หลบวงแดงบอส)",
    Desc = "ตรวจจับวงสกิลแดงของบอสและมินิบอสล่วงหน้า แล้วแดชพุ่งหลบออกจากขอบรัศมีทันที",
    Value = Config.DodgeBossTelegraph,
    Callback = function(state)
        Config.DodgeBossTelegraph = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DodgeTab:Toggle({
    Title = "Dodge Monster Projectiles (หลบกระสุน/เวท)",
    Desc = "เมื่อมอนสเตอร์ยิงบอลพลังหรือกระสุนเล็งใส่ตัวละคร จะแดชสไลด์หลบแนววิถีกระสุนฉับพลัน",
    Value = Config.DodgeProjectiles,
    Callback = function(state)
        Config.DodgeProjectiles = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DodgeTab:Toggle({
    Title = "Dodge on Damage Taken (แดชฉุกเฉินเมื่อโดนตี)",
    Desc = "เมื่อเลือดลดกะทันหันหรือติดดาเมจ จะแดชถอยหลังตัดคอมโบศัตรูทันที",
    Value = Config.DodgeOnHurt,
    Callback = function(state)
        Config.DodgeOnHurt = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DodgeTab:Toggle({
    Title = "Combat Flank Evasion (หลบเข้าหลังมอน 360°)",
    Desc = "เมื่อมอนสเตอร์หันหน้ามาเตรียมโจมตี จะแดชวนเข้าด้านหลังมอนสเตอร์ทันที",
    Value = Config.DodgeFlank,
    Callback = function(state)
        Config.DodgeFlank = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})


DodgeTab:Section({ Title = "⚙️ Dodge Tuning & Distance", Opened = true })

DodgeTab:Slider({
    Title = "Dodge Distance (ระยะทางพุ่งหลบ)",
    Value = { Min = 8, Max = 35, Default = Config.DodgeDistance },
    Callback = function(val)
        Config.DodgeDistance = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DodgeTab:Slider({
    Title = "Dodge Cooldown (คูลดาวน์การหลบ)",
    Value = { Min = 0.25, Max = 1.5, Default = Config.DodgeCooldown },
    Callback = function(val)
        Config.DodgeCooldown = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DodgeTab:Toggle({
    Title = "Show Dodge Notifications (แจ้งเตือนเมื่อหลบ)",
    Desc = "แสดงป็อปอัปแจ้งเตือนทุกครั้งที่หลบการโจมตีสำเร็จ",
    Value = Config.DodgeNotify,
    Callback = function(state)
        Config.DodgeNotify = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

DodgeTab:Button({
    Title = "Test Dash / Dodge Now (ทดสอบกดแดชหลบ)",
    Desc = "สั่งการ Dash Remote และทดสอบระบบหลบหลีกทันที",
    Callback = function()
        performDodge("Manual Test", nil, Config.DodgeDistance)
        WindUI:Notify({ Title = "Auto Dodge", Content = "ทดสอบการแดชหลบสำเร็จ!", Duration = 2, Icon = "zap" })
    end,
})


-- ==================== TAB: HALLOWEEN EVENT ====================
HalloweenTab:Section({ Title = "🎃 Halloween Event Hub", Opened = true })

HalloweenTab:Toggle({
    Title = "Enable Auto Halloween Event (เปิดระบบฮาโลวีน)",
    Desc = "เปิดระบบทำงานฮาโลวีนอัตโนมัติครบวงจร (Trick-or-Treat, ล่าฟักทอง, เปิดกล่อง, กาชา)",
    Value = Config.AutoHalloween,
    Callback = function(state)
        Config.AutoHalloween = state
        if Config.AutoSave then SaveConfig(true) end
        if state then
            WindUI:Notify({ Title = "Halloween Event", Content = "เปิดโหมดกิจกรรมฮาโลวีนแล้ว!", Duration = 2, Icon = "sparkles" })
        else
            WindUI:Notify({ Title = "Halloween Event", Content = "ปิดโหมดกิจกรรมฮาโลวีน", Duration = 2, Icon = "square" })
        end
    end,
})

HalloweenTab:Button({
    Title = "Check Event Inventory (เช็คไอเทมกิจกรรม)",
    Desc = "ตรวจสอบจำนวน Halloween Candy และ Pumpkin Head ในกระเป๋า",
    Callback = function()
        local candy, heads = getHalloweenInventory()
        WindUI:Notify({
            Title = "🎃 Halloween Bag",
            Content = string.format("🍬 Halloween Candy: %d ชิ้น\n🎃 Pumpkin Head: %d ชิ้น", candy, heads),
            Duration = 3,
            Icon = "gift",
        })
    end,
})

HalloweenTab:Section({ Title = "🏠 Auto Trick-or-Treat (เคาะบ้านแม่มดแลกของ)", Opened = true })

HalloweenTab:Toggle({
    Title = "Auto Knock Witch Houses (เคาะบ้านแม่มดอัตโนมัติ)",
    Desc = "เมื่อมี Candy >= 100 จะเคาะประตูบ้านแม่มดเพื่อรับรางวัล TREAT (ทอง, อุปกรณ์แรร์, ไอเทม)",
    Value = Config.AutoTrickTreat,
    Callback = function(state)
        Config.AutoTrickTreat = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

HalloweenTab:Toggle({
    Title = "Smart Quick-Visit Witch House (แวะเคาะบ้านแล้วกลับ)",
    Desc = "หากอยู่ใน Field ที่มีบ้านแม่มด จะแวะแตะประตูเคาะรับของทันทีแล้ววาร์ปกลับจุดฟาร์มเดิม",
    Value = Config.TrickTreatAutoVisit,
    Callback = function(state)
        Config.TrickTreatAutoVisit = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

HalloweenTab:Button({
    Title = "Knock Nearest Witch House Now (เคาะบ้านทันที 1 ครั้ง)",
    Desc = "ใช้ 100 Candy เคาะประตูบ้านแม่มดที่ใกล้ที่สุดทันที",
    Callback = function()
        if performTrickTreat(true) then
            WindUI:Notify({ Title = "Trick-or-Treat", Content = "เคาะบ้านแม่มดสำเร็จ!", Duration = 2, Icon = "check-circle" })
        else
            local candy, _ = getHalloweenInventory()
            WindUI:Notify({ Title = "Trick-or-Treat", Content = "ลูกอมไม่พอ (มี " .. candy .. "/100) หรือไม่พบบ้านแม่มด", Duration = 2.5, Icon = "alert-circle" })
        end
    end,
})

HalloweenTab:Button({
    Title = "Continuous Knock (แลกลูกอมที่มีทั้งหมดจนหมด)",
    Desc = "วนลูปเคาะบ้านแม่มดแลกของรางวัลจนกว่าลูกอมจะเหลือน้อยกว่า 100",
    Callback = function()
        task.spawn(function()
            local done = 0
            while isScriptAlive() do
                local candy, _ = getHalloweenInventory()
                if candy < 100 then break end
                if not performTrickTreat(true) then break end
                done = done + 1
                task.wait(1.5)
            end
            WindUI:Notify({ Title = "Trick-or-Treat", Content = string.format("แลกรางวัลสำเร็จทั้งหมด %d รอบ!", done), Duration = 3, Icon = "gift" })
        end)
    end,
})

HalloweenTab:Section({ Title = "🔮 Halloween Crystal Gacha (สุ่มสกินอาวุธ)", Opened = true })

HalloweenTab:Toggle({
    Title = "Auto Pull Halloween Gacha (สุ่มกาชาอัตโนมัติ)",
    Desc = "ใช้ Pumpkin Head สุ่มตู้ Halloween Crystal Gacha อัตโนมัติเมื่อมีแต้มครบ",
    Value = Config.AutoHalloweenGacha,
    Callback = function(state)
        Config.AutoHalloweenGacha = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

HalloweenTab:Dropdown({
    Title = "Gacha Pull Type (รูปแบบการสุ่ม)",
    Values = { "10x Pull (100 Heads)", "1x Pull (10 Heads)" },
    Value = Config.GachaPullType,
    Callback = function(val)
        Config.GachaPullType = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

HalloweenTab:Button({
    Title = "Pull 1x Gacha Now (สุ่ม 1 ครั้ง - 10 Heads)",
    Callback = function()
        local _, heads = getHalloweenInventory()
        if heads < 10 then
            WindUI:Notify({ Title = "Halloween Gacha", Content = "Pumpkin Head ไม่พอ (มี " .. heads .. "/10)", Duration = 2, Icon = "alert-circle" })
            return
        end
        if performHalloweenGacha(1) then
            WindUI:Notify({ Title = "Halloween Gacha", Content = "สุ่มกาชา 1x สำเร็จ!", Duration = 2, Icon = "sparkles" })
        end
    end,
})

HalloweenTab:Button({
    Title = "Pull 10x Gacha Now (สุ่ม 10 ครั้ง - 100 Heads)",
    Callback = function()
        local _, heads = getHalloweenInventory()
        if heads < 100 then
            WindUI:Notify({ Title = "Halloween Gacha", Content = "Pumpkin Head ไม่พอ (มี " .. heads .. "/100)", Duration = 2, Icon = "alert-circle" })
            return
        end
        if performHalloweenGacha(10) then
            WindUI:Notify({ Title = "Halloween Gacha", Content = "สุ่มกาชา 10x สำเร็จ!", Duration = 2, Icon = "sparkles" })
        end
    end,
})

HalloweenTab:Section({ Title = "🕷️ Halloween Monsters & Boxes", Opened = true })

HalloweenTab:Toggle({
    Title = "Prioritize Halloween Pumpkins & Bosses",
    Desc = "เล็งโจมตีมินิบอสฟักทอง (Halloween Pumpkin) และบอสแมงมุมฟักทอง (Pumpkin Spider) ก่อนมอนสเตอร์อื่น",
    Value = Config.HuntHalloweenPumpkins,
    Callback = function(state)
        Config.HuntHalloweenPumpkins = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

HalloweenTab:Toggle({
    Title = "Auto Open Halloween Boxes (relic_box)",
    Desc = "ดูดและเปิดกล่องคนขยันฮาโลวีน (Halloween Hard Worker Box) ทั่วทั้งแมพ เพื่อรับแคนดี้และบัฟ",
    Value = Config.AutoHalloweenBoxes,
    Callback = function(state)
        Config.AutoHalloweenBoxes = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

HalloweenTab:Toggle({
    Title = "Auto Claim Event NPC Rewards & Pet",
    Desc = "ส่งคำสั่งรับรางวัล Event Level Race และสัตว์เลี้ยงฟรีจาก RonB Games อัตโนมัติ",
    Value = Config.AutoClaimEventRewards,
    Callback = function(state)
        Config.AutoClaimEventRewards = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

HalloweenTab:Button({
    Title = "Claim Event Rewards & Pet Now",
    Callback = function()
        pcall(function()
            if RemotesLazy.EventNpcAction then
                RemotesLazy.EventNpcAction:FireServer("claimAll")
                RemotesLazy.EventNpcAction:FireServer("claimPet")
            end
        end)
        WindUI:Notify({ Title = "Event Rewards", Content = "ส่งคำสั่งรับรางวัลกิจกรรมและสัตว์เลี้ยงเรียบร้อย!", Duration = 2.5, Icon = "gift" })
    end,
})

-- ==================== TAB: STREAMER MODE ====================
StreamerTab:Section({ Title = "🎥 Streamer Mode & Privacy Protection", Opened = true })

StreamerTab:Toggle({
    Title = "Enable Streamer Mode (เปิดโหมดสตรีมเมอร์)",
    Desc = "ปกปิดและเปลี่ยนชื่อจริงทั้งหมดบนหน้าจอแบบเรียลไทม์ ป้องกันการโดนแบนหรือสตรีมสไนป์",
    Value = Config.StreamerMode,
    Callback = function(state)
        Config.StreamerMode = state
        if Config.AutoSave then SaveConfig(true) end
        if state then
            applyStreamerMode()
            WindUI:Notify({
                Title = "Streamer Mode",
                Content = "เปิดโหมดสตรีมเมอร์แล้ว (แสดงเป็น: " .. tostring(Config.StreamerFakeName) .. ")",
                Duration = 2.5,
                Icon = "eye-off",
            })
        else
            restoreOriginalNames()
            WindUI:Notify({
                Title = "Streamer Mode",
                Content = "ปิดโหมดสตรีมเมอร์แล้ว คืนค่าชื่อเดิมเรียบร้อย",
                Duration = 2,
                Icon = "eye",
            })
        end
    end,
})

StreamerTab:Input({
    Title = "Custom Fake Name (กำหนดชื่อจำลอง)",
    Desc = "พิมพ์ชื่อที่ต้องการให้แสดงแทนชื่อจริง (เช่น Protected Player, Streamer)",
    Value = Config.StreamerFakeName,
    Placeholder = "พิมพ์ชื่อจำลองที่นี่...",
    Callback = function(val)
        if val and val ~= "" then
            Config.StreamerFakeName = val
            if Config.AutoSave then SaveConfig(true) end
            if Config.StreamerMode then
                applyStreamerMode()
            end
        end
    end,
})

StreamerTab:Dropdown({
    Title = "Quick Fake Name Presets (เลือกชื่อสำเร็จรูป)",
    Values = {
        "Protected Player",
        "Streamer_Live",
        "Anonymous_Hunter",
        "Ghost_Warrior",
        "Player_404",
        "Hidden_Novice",
    },
    Value = Config.StreamerFakeName,
    Callback = function(val)
        Config.StreamerFakeName = val
        if Config.AutoSave then SaveConfig(true) end
        if Config.StreamerMode then
            applyStreamerMode()
            WindUI:Notify({ Title = "Fake Name Updated", Content = "เปลี่ยนชื่อเป็น: " .. val, Duration = 2, Icon = "user-check" })
        end
    end,
})

StreamerTab:Section({ Title = "🛡️ Masking Targets (จุดที่ต้องการซ่อน)", Opened = true })

StreamerTab:Toggle({
    Title = "Hide Overhead Nametag (ซ่อนชื่อบนหัวตัวละคร)",
    Desc = "ปิดป้ายชื่อ ฉายา และเลเวลเหนือหัวตัวละครของคุณบนหน้าจอ",
    Value = Config.HideOverheadName,
    Callback = function(state)
        Config.HideOverheadName = state
        if Config.AutoSave then SaveConfig(true) end
        if Config.StreamerMode then applyStreamerMode() end
    end,
})

StreamerTab:Toggle({
    Title = "Spoof UI & Leaderboard (เปลี่ยนชื่อในเมนู/หลอดเลือด/กระดาน)",
    Desc = "สแกนและเปลี่ยนชื่อใน PlayerGui, หลอดเลือด HP/SP, สเตตัส, กระเป๋า และกระดานผู้เล่น",
    Value = Config.SpoofUIAndLeaderboard,
    Callback = function(state)
        Config.SpoofUIAndLeaderboard = state
        if Config.AutoSave then SaveConfig(true) end
        if Config.StreamerMode then
            if state then
                applyStreamerMode()
            else
                restoreOriginalNames()
            end
        end
    end,
})

StreamerTab:Toggle({
    Title = "Hide Others Names (ซ่อนชื่อผู้เล่นคนอื่นด้วย)",
    Desc = "เปลี่ยนชื่อผู้เล่นคนอื่นรอบตัวเป็น 'Player' เพื่อความเป็นส่วนตัวสูงสุด",
    Value = Config.HideOthersNames,
    Callback = function(state)
        Config.HideOthersNames = state
        if Config.AutoSave then SaveConfig(true) end
        if Config.StreamerMode then applyStreamerMode() end
    end,
})

StreamerTab:Button({
    Title = "Apply / Refresh Name Masking (รีเฟรชการซ่อนชื่อทันที)",
    Desc = "บังคับสแกนและอัปเดตการซ่อนชื่อในทุกองค์ประกอบบนหน้าจอทันที",
    Callback = function()
        applyStreamerMode()
        WindUI:Notify({ Title = "Streamer Mode", Content = "อัปเดตการซ่อนชื่อบนหน้าจอเรียบร้อย!", Duration = 2, Icon = "refresh-cw" })
    end,
})

-- ==================== TAB 9: TELEPORT ====================
TeleportTab:Section({ Title = "Fast Travel Map", Opened = true })

local mapWarpList = {
    "Town",
    "Field01", "Field02", "Field03", "Field04", "Field05",
    "Field06", "Field07", "Field08", "Field09", "Field10",
    "Field11", "Field12", "Field13", "Field14", "Field15",
}

local selectedWarp = "Town"
TeleportTab:Dropdown({
    Title = "Select Destination",
    Values = mapWarpList,
    Value = "Town",
    Callback = function(val) selectedWarp = val end,
})

TeleportTab:Button({
    Title = "Warp to Selected Area",
    Callback = function()
        pcall(function()
            RemotesLazy.WarpTo:FireServer(selectedWarp)
            WindUI:Notify({ Title = "Teleport", Content = "วาร์ปไป: " .. selectedWarp, Duration = 2, Icon = "send" })
        end)
    end,
})

TeleportTab:Button({
    Title = "Quick Return to Town",
    Callback = function()
        pcall(function() RemotesLazy.WarpTo:FireServer("Town") end)
    end,
})

-- ==================== LOW-PLAYER SERVER HOP UI ====================
TeleportTab:Section({ Title = "🌐 Low-Player Server Hop (ระบบย้ายเซิร์ฟเวอร์คนน้อย)", Opened = true })

TeleportTab:Toggle({
    Title = "Auto Server Hop (ย้ายเซิร์ฟเวอร์อัตโนมัติ)",
    Desc = "สลับย้ายไปเซิร์ฟเวอร์ที่มีผู้เล่นน้อยที่สุดตามรอบเวลาที่ตั้งไว้",
    Value = Config.ServerHopAuto,
    Callback = function(state)
        Config.ServerHopAuto = state
        if state then
            serverHopNextTick = os.clock() + ((tonumber(Config.ServerHopInterval) or 15) * 60)
        else
            serverHopNextTick = 0
        end
        if Config.AutoSave then SaveConfig(true) end
    end,
})

TeleportTab:Slider({
    Title = "Server Hop Interval (รอบเวลาในการย้ายเซิร์ฟ)",
    Desc = "ตั้งเวลาว่าจะให้บอทย้ายเซิร์ฟเวอร์คนน้อยทุกๆ กี่นาที (เช่น 10, 15, 30 นาที)",
    Value = {
        Min = 1,
        Max = 120,
        Default = tonumber(Config.ServerHopInterval) or 15,
    },
    Step = 1,
    Suffix = " นาที (mins)",
    Callback = function(val)
        Config.ServerHopInterval = tonumber(val) or 15
        if Config.ServerHopAuto then
            serverHopNextTick = os.clock() + ((tonumber(val) or 15) * 60)
        end
        if Config.AutoSave then SaveConfig(true) end
    end,
})

TeleportTab:Button({
    Title = "🚀 Server Hop Now (ย้ายไปเซิร์ฟคนน้อยทันที)",
    Desc = "ค้นหาเซิร์ฟเวอร์คนน้อยที่สุดในขณะนี้และย้ายทันที ไม่ต้องรอรอบเวลา",
    Callback = function()
        serverHopLowPlayer(false)
    end,
})

TeleportTab:Button({
    Title = "📊 Current Server Info (ข้อมูลเซิร์ฟปัจจุบัน)",
    Desc = "ดูจำนวนผู้เล่นและ JobId ของเซิร์ฟเวอร์ที่อยู่ตอนนี้",
    Callback = function()
        local playersCount = #game:GetService("Players"):GetPlayers()
        local maxPlayers = 13
        pcall(function() maxPlayers = game:GetService("Players").MaxPlayers end)
        WindUI:Notify({
            Title = "Server Info",
            Content = string.format("ผู้เล่นในห้องนี้: %d/%d คน\nJobId: %s", playersCount, maxPlayers, string.sub(tostring(game.JobId), 1, 16) .. "..."),
            Duration = 4,
            Icon = "info"
        })
    end,
})

TeleportTab:Button({
    Title = "🔄 Rejoin Current Server (รีจอยน์ห้องเดิม)",
    Desc = "เชื่อมต่อกลับเข้ามาที่เซิร์ฟเวอร์เดิมทันที",
    Callback = function()
        rejoinCurrentServer()
    end,
})

-- ==================== TAB 10: CONFIG & HOTKEY ====================
ConfigTab:Section({ Title = "🎨 UI Theme & Background FX (ตั้งค่าธีมและพื้นหลังเคลื่อนไหว)", Opened = true })

ConfigTab:Dropdown({
    Title = "Select Dungeon Theme (เลือกธีมสีดันเจี้ยน)",
    Desc = "เปลี่ยนโทนสีหน้าต่าง UI และบรรยากาศพื้นหลังตามธีมดันเจี้ยนและบอส",
    Values = Window._DungeonThemeEngine.ThemeNames,
    Value = Config.UITheme or "🎃 Skull King's Crypt (สุสานราชาโครงกระดูก)",
    Callback = function(selected)
        Config.UITheme = selected
        Window._DungeonThemeEngine.ApplyTheme(selected, true)
        if Config.AutoSave then SaveConfig(true) end
    end,
})

ConfigTab:Toggle({
    Title = "Animated Background Effect (เปิดเอฟเฟกต์เคลื่อนไหวพื้นหลัง)",
    Desc = "แสดงวงเวทรูนดันเจี้ยน, ออร่าเรืองแสง และละอองพลังงานเคลื่อนไหวด้านหลังเมนูแบบเรียลไทม์",
    Value = Config.UIBackgroundAnimation ~= false,
    Callback = function(state)
        Window._DungeonThemeEngine.SetAnimEnabled(state)
        if Config.AutoSave then SaveConfig(true) end
    end,
})

ConfigTab:Dropdown({
    Title = "Background Particle Style (รูปแบบเอฟเฟกต์ละอองพื้นหลัง)",
    Desc = "เลือกรูปแบบอนิเมชั่นพื้นหลัง (ไฟวิญญาณ, จันทร์สีเลือด, พายุหิมะ, จักรพรรดิเงา, สายลมมังกร, ซากุระ)",
    Values = Window._DungeonThemeEngine.StyleNames,
    Value = Config.UIAnimationStyle or "Auto (ตามธีมดันเจี้ยน)",
    Callback = function(selected)
        Config.UIAnimationStyle = selected
        Window._DungeonThemeEngine.UpdateParticles()
        if Config.AutoSave then SaveConfig(true) end
    end,
})

ConfigTab:Slider({
    Title = "Animation Speed (ความเร็วอนิเมชั่นพื้นหลัง)",
    Desc = "ปรับความเร็วการหมุนของวงเวทรูนและการลอยของละอองพลังงาน",
    Value = {
        Min = 2,
        Max = 30,
        Default = tonumber(Config.UIAnimationSpeed) or 10,
    },
    Step = 1,
    Callback = function(val)
        Config.UIAnimationSpeed = tonumber(val) or 10
        if Config.AutoSave then SaveConfig(true) end
    end,
})

ConfigTab:Slider({
    Title = "Glass Card Transparency (ความโปร่งแสงการ์ดเมนู)",
    Desc = "ปรับความใสของกรอบปุ่มเพื่อให้มองเห็นเอฟเฟกต์วงเวทและละอองพื้นหลังทะลุขึ้นมาได้ชัดเจน",
    Value = {
        Min = 0,
        Max = 65,
        Default = tonumber(Config.UIGlassTransparency) or 28,
    },
    Step = 1,
    Suffix = "%",
    Callback = function(val)
        Config.UIGlassTransparency = tonumber(val) or 28
        Window._DungeonThemeEngine.ApplyGlass()
        if Config.AutoSave then SaveConfig(true) end
    end,
})

ConfigTab:Section({ Title = "Profile & Config Management", Opened = true })

ConfigTab:Button({
    Title = "Save Config Now",
    Desc = "บันทึกการตั้งค่าทั้งหมดลงในไฟล์ " .. CONFIG_FILE,
    Callback = function()
        SaveConfig(false)
    end,
})

ConfigTab:Button({
    Title = "Load Saved Config",
    Desc = "โหลดการตั้งค่าจากไฟล์ " .. CONFIG_FILE,
    Callback = function()
        if LoadConfig(false) then
            WindUI:Notify({ Title = "Loaded", Content = "โหลดการตั้งค่าสำเร็จแล้ว", Duration = 2, Icon = "check" })
        else
            WindUI:Notify({ Title = "Not Found", Content = "ไม่พบไฟล์การตั้งค่าที่บันทึกไว้", Duration = 2, Icon = "alert-circle" })
        end
    end,
})

ConfigTab:Toggle({
    Title = "Auto Save on Change",
    Value = Config.AutoSave,
    Callback = function(state)
        Config.AutoSave = state
        SaveConfig(true)
    end,
})

ConfigTab:Toggle({
    Title = "Auto Execute on Teleport / Warp",
    Value = Config.AutoExecuteOnTeleport,
    Callback = function(state)
        Config.AutoExecuteOnTeleport = state
        registerQueueOnTeleport()
        SaveConfig(true)
    end,
})

ConfigTab:Section({ Title = "Hotkey & Window Controls", Opened = true })

ConfigTab:Dropdown({
    Title = "Fold Window Hotkey",
    Values = {
        "RightControl", "LeftControl", "RightShift", "LeftShift",
        "Insert", "End", "Home", "F4", "F8", "Tab", "Q", "E", "X",
    },
    Value = Config.ToggleKey,
    Callback = function(keyName)
        if Enum.KeyCode[keyName] then
            currentKeyCode = Enum.KeyCode[keyName]
            Config.ToggleKey = keyName
            Window:SetToggleKey(currentKeyCode)
            SaveConfig(true)
            WindUI:Notify({
                Title = "Hotkey Changed",
                Content = "เปลี่ยนปุ่มลัดพับเมนูเป็น: " .. keyName,
                Duration = 2,
                Icon = "keyboard",
            })
        end
    end,
})

ConfigTab:Button({
    Title = "Fold / Minimize Window Now",
    Callback = function()
        Window:Toggle()
    end,
})

ConfigTab:Section({ Title = "🌐 Song Hub Community & Support", Opened = true })

ConfigTab:Button({
    Title = "💬 Join Discord Community",
    Desc = "Copy Discord invite link to your clipboard (https://discord.gg/cecytf4MHE)",
    Callback = function()
        pcall(function()
            if typeof(setclipboard) == "function" then
                setclipboard("https://discord.gg/cecytf4MHE")
            end
            WindUI:Notify({
                Title = "Discord Link Copied! 💬",
                Content = "https://discord.gg/cecytf4MHE\nJoin Song Hub Discord for support, updates & keys!",
                Duration = 4,
                Icon = "clipboard-check"
            })
        end)
    end,
})

-- ==================== TAB 11: MISC & BOOST ====================
MiscTab:Section({ Title = "Movement & Stamina Boost", Opened = true })

MiscTab:Toggle({
    Title = "Infinite Stamina & Auto Sprint",
    Desc = "ล็อคสตามิน่า 100% วิ่งไวไม่มีหมด",
    Value = Config.InfiniteStamina,
    Callback = function(state)
        Config.InfiniteStamina = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

MiscTab:Slider({
    Title = "WalkSpeed",
    Value = { Min = 16, Max = 100, Default = 20 },
    Callback = function(val)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = val end
    end,
})

MiscTab:Slider({
    Title = "JumpPower",
    Value = { Min = 50, Max = 200, Default = 50 },
    Callback = function(val)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = val end
    end,
})

MiscTab:Section({ Title = "Anti-AFK & Optimization", Opened = true })

MiscTab:Toggle({
    Title = "Anti-AFK (Prevent 20-Min Kick)",
    Value = Config.AntiAFK,
    Callback = function(state)
        Config.AntiAFK = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

MiscTab:Toggle({
    Title = "Fast Mode (Boost FPS / Low CPU)",
    Value = Config.FastMode,
    Callback = function(state)
        Config.FastMode = state
        if Config.AutoSave then SaveConfig(true) end
        pcall(function()
            LocalPlayer:SetAttribute("OptFastMode", state)
            LocalPlayer:SetAttribute("OptHideOthersDamage", state)
        end)
    end,
})

MiscTab:Button({
    Title = "Claim Daily Gift",
    Callback = function()
        pcall(function()
            RemotesLazy.DailyClaim:FireServer()
            WindUI:Notify({ Title = "Daily Gift", Content = "กดรับรางวัลรายวันแล้ว", Duration = 2, Icon = "gift" })
        end)
    end,
})

MiscTab:Button({
    Title = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end,
})

-- ==================== CORE BACKGROUND LOOPS ====================

-- 1. Anti-AFK
trackConn(LocalPlayer.Idled:Connect(function()
    if not isScriptAlive() then return end
    if Config.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end
end))

-- ==================== REAL-TIME DUNGEON PROMPT LISTENER ====================
if DungeonPrompt then
    trackConn(DungeonPrompt.OnClientEvent:Connect(function(event, data)
        if not isScriptAlive() then return end
        if event == "dungeonselect" then
            task.wait(0.15)
            pcall(function()
                if Config.DungeonPartyMode == "Solo" and Config.DungeonForceSolo ~= false then
                    leaveParty()
                    task.wait(0.1)
                end

                local dId = (type(data) == "table" and data.Id) or Config.SelectedDungeon or "halloween"
                local rawDiff = tostring(Config.DungeonDifficulty or "easy"):lower()
                local diff = "easy"
                if rawDiff:find("normal") or rawDiff:find("hard") then
                    diff = "normal"
                end

                if DungeonAction then
                    DungeonAction:FireServer("selectEnter", dId, diff)
                end
            end)
        elseif event == "readystate" or event == "ready" then
            if Config.AutoReadyDungeon or Config.DungeonPartyMode == "Party" or Config.AutoAcceptParty or Config.AutoRepeatDungeon then
                task.wait(0.15)
                pcall(function()
                    local dId = (type(data) == "table" and data.Id) or Config.SelectedDungeon or "halloween"
                    if DungeonAction then
                        DungeonAction:FireServer("ready", dId, true)
                    end
                end)
            end
        elseif event == "replay" or event == "replayStart" or event == "replayVote" then
            if Config.AutoRepeatDungeon and Config.AutoConfirmReplay ~= false then
                task.wait(0.15)
                pcall(function()
                    if DungeonAction then
                        DungeonAction:FireServer("replayVote", true)
                    end
                end)
            end
        end
    end))
end

-- ==================== AUTO ACCEPT PARTY INVITES (ALT ACCOUNT SYSTEM) ====================
if PartyInvite then
    trackConn(PartyInvite.OnClientEvent:Connect(function(fromUserId, fromName, duration, inviteType)
        if not isScriptAlive() then return end
        if not Config.AutoAcceptParty then return end

        local leaderId = tonumber(fromUserId)
        local leaderName = tostring(fromName or "")
        local action = (inviteType == "request") and "reqaccept" or "accept"

        -- Check whitelist filter if specified
        if Config.PartyAcceptFilter == "Whitelist" and Config.PartyWhitelistUsers and Config.PartyWhitelistUsers ~= "" then
            local allowed = false
            for user in string.gmatch(Config.PartyWhitelistUsers:lower(), "[%w_]+") do
                if leaderName:lower() == user or tostring(leaderId) == user then
                    allowed = true
                    break
                end
            end
            if not allowed then
                return
            end
        elseif Config.PartyAcceptFilter == "Friends Only" and leaderId then
            local isFriend = false
            pcall(function()
                isFriend = LocalPlayer:IsFriendsWith(leaderId)
            end)
            if not isFriend then
                return
            end
        end

        task.wait(0.2)
        pcall(function()
            if PartyAction then
                PartyAction:FireServer(action, leaderId)
            end
            local fromPlr = leaderId and Players:GetPlayerByUserId(leaderId)
            if fromPlr and PartyAction then
                PartyAction:FireServer(action, fromPlr)
            end
        end)

        -- Dismiss native game invite UI if open
        pcall(function()
            local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            local lumiParty = pg and pg:FindFirstChild("LumiParty")
            if lumiParty then
                for _, desc in ipairs(lumiParty:GetDescendants()) do
                    if desc:IsA("TextButton") and desc.Text == "Join" then
                        desc.Parent.Visible = false
                    end
                end
            end
        end)

        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "👥 Party Joined (Auto Accept)",
                Content = string.format("ตอบรับคำเชิญเข้าปาร์ตี้ของ %s เรียบร้อย!", leaderName ~= "" and leaderName or tostring(leaderId)),
                Duration = 2.5,
                Icon = "user-check"
            })
        end
    end))
end

-- ==================== DEDICATED AUTO DUNGEON LOOP ====================
task.spawn(function()
    while isScriptAlive() do
        task.wait(0.5)
        if Config.AutoDungeon and canScriptMoveOrWarp() then
            if isInsideDungeon() then
                local state = getDungeonState()
                local hasExitChest = (cachedExitChestPrompt and cachedExitChestPrompt.Parent and cachedExitChestPrompt.Enabled)
                if state == "cleared" or hasExitChest then
                    if Config.AutoClaimExitChest or Config.AutoLeaveOnClear or Config.AutoRepeatDungeon then
                        executeClaimExitChest()
                    end
                    if Config.AutoRepeatDungeon then
                        handleAutoReplayUi(LocalPlayer:FindFirstChild("PlayerGui"))
                    end
                    task.wait(1.5)
                elseif state == "running" or state == "countdown" or state == "starting" then
                    -- Revive teammates if anyone is down
                    if Config.AutoReviveTeammates then
                        executeReviveTeammates()
                    end

                    -- Auto kick demon skulls in boss room
                    if Config.AutoKickSkulls then
                        checkKickDudSkulls()
                    end

                    -- Auto advance path if no monster is actively targeted
                    if state == "running" and not currentCombatTarget then
                        advanceDungeonPath()
                    end

                    -- Secret Runes discovery in maze
                    if Config.AutoSecretChests then
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            for _, rune in ipairs(CollectionService:GetTagged("DungeonRune")) do
                                if rune:IsA("Model") then
                                    local rPos = rune:GetPivot().Position
                                    if (hrp.Position - rPos).Magnitude <= 22 then
                                        -- Proximity triggers rune lighting automatically
                                    end
                                end
                            end
                        end
                    end
                end
            else
                -- In Town / Village: initiate enter routine if not currently doing other tasks
                if not isWarpingZone and not isSelling and not isEnteringDungeon and not isWaitingForParty then
                    executeDungeonEnterRoutine()
                end
            end
        end
    end
end)

-- 2. Infinite Stamina Loop
task.spawn(function()
    while isScriptAlive() do
        task.wait(0.2)
        if Config.InfiniteStamina then
            pcall(function()
                LocalPlayer:SetAttribute("LumiStamina", 100)
                LocalPlayer:SetAttribute("LumiStaminaEmpty", false)
            end)
        end
    end
end)

-- 3. Dedicated High-Frequency Auto Loot & Drop Vacuum Loop
task.spawn(function()
    while isScriptAlive() do
        task.wait(0.2)
        if Config.AutoLoot then
            local dropsFolder = workspace:FindFirstChild("Drops")
            if dropsFolder and #dropsFolder:GetChildren() > 0 then
                performAutoLoot()
            end
        end
        if canScriptMoveOrWarp() and not isEnteringDungeon and not isWaitingForParty and (Config.AutoOpenLootBox or Config.AutoHalloweenBoxes) then
            local nowClock = os.clock()
            if (nowClock - lastBoxScanTime) >= 1.5 then
                lastBoxScanTime = nowClock
                checkAllLootBoxes()
            end
        end
    end
end)


-- 4. Main Auto Farm & Smart Combat Loop (With Multi-Target Kill Aura & Dungeon Combat)
task.spawn(function()
    while isScriptAlive() do
        local inDungeon = isInsideDungeon()
        -- Dynamic ASPD-scaled attack delay: high ASPD character attacks at maximum speed
        local aspd = tonumber(LocalPlayer:GetAttribute("ASPD")) or 120
        local aspdDelay = math.clamp(0.035 + (200 - aspd) * 0.0012, 0.035, 0.16)
        local attackDelay = (inDungeon and Config.DungeonAttackDelay) or math.min(aspdDelay, tonumber(Config.AttackDelay) or 0.10)
        task.wait(attackDelay)

        local shouldCombat = false
        if canScriptMoveOrWarp() then
            if inDungeon then
                shouldCombat = (Config.AutoDungeon == true) or (Config.AutoFarm == true)
            else
                shouldCombat = (Config.AutoFarm == true)
            end
        end

        if shouldCombat then
            if inDungeon and (isDungeonDowned() or isOpeningDungeonChest or getDungeonState() == "cleared") then
                task.wait(0.5)
                continue
            end
            if not inDungeon and (isWarpingZone or isSelling or isEnteringDungeon or isWaitingForParty) then
                task.wait(0.2)
                continue
            end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            -- Respawn recovery check
            if hum and hum.Health <= 0 then
                if Config.AutoRespawn then
                    pcall(function()
                        if RemotesLazy.RespawnChoice then
                            RemotesLazy.RespawnChoice:FireServer("town")
                            RemotesLazy.RespawnChoice:FireServer("Town")
                            RemotesLazy.RespawnChoice:FireServer(1)
                        end
                        local deadGui = LocalPlayer.PlayerGui:FindFirstChild("LumiRespawn")
                        if deadGui then
                            for _, d in ipairs(deadGui:GetDescendants()) do
                                if (d:IsA("TextButton") or d:IsA("ImageButton")) and (d.Name:lower():find("town") or (d:FindFirstChildWhichIsA("TextLabel") and d:FindFirstChildWhichIsA("TextLabel").Text:lower():find("town"))) then
                                    if getconnections then
                                        for _, conn in ipairs(getconnections(d.MouseButton1Click)) do pcall(function() conn:Fire() end) end
                                        for _, conn in ipairs(getconnections(d.Activated)) do pcall(function() conn:Fire() end) end
                                    end
                                    break
                                end
                            end
                        end
                    end)
                end
                task.wait(2)
            elseif hrp and hum and hum.Health > 0 then
                -- Stealth magnet & remote instant pickup for nearby drops during combat (throttled to keep attack 100% fluid)
                local nowClock = os.clock()
                local dropsFolder = workspace:FindFirstChild("Drops")
                if Config.AutoLoot and Config.LootPriority and dropsFolder and (nowClock - lastCombatLootScan) >= 0.5 then
                    lastCombatLootScan = nowClock
                    local maxCombatLootDist = tonumber(Config.LootRadius) or 120
                    local nowServer = workspace:GetServerTimeNow()
                    for _, d in ipairs(dropsFolder:GetChildren()) do
                        local dp = d:IsA("BasePart") and d or (d:IsA("Model") and (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart", true)))
                        if dp and dp.Parent then
                            local owner = d:GetAttribute("OwnerUserId") or dp:GetAttribute("OwnerUserId")
                            local freeAt = d:GetAttribute("FreeAt") or dp:GetAttribute("FreeAt")
                            local canTake = true
                            if owner and owner ~= 0 and owner ~= LocalPlayer.UserId then
                                if freeAt and nowServer < freeAt then
                                    canTake = false
                                end
                            end
                            if canTake then
                                local dDist = (dp.Position - hrp.Position).Magnitude
                                if dDist <= maxCombatLootDist then
                                    if Config.StealthMagnetLoot ~= false then
                                        pcall(function()
                                            dp.CanCollide = false
                                            dp.CFrame = hrp.CFrame
                                        end)
                                    end
                                    pcall(function()
                                        if RemotesLazy.PickupDrop then
                                            RemotesLazy.PickupDrop:FireServer(true)
                                            RemotesLazy.PickupDrop:FireServer(dp)
                                        end
                                    end)
                                    if firetouchinterest then
                                        pcall(function()
                                            firetouchinterest(hrp, dp, 0)
                                            firetouchinterest(hrp, dp, 1)
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end

                local target = getTargetMonster()
                if target and isMonsterAlive(target) then
                    if isBossMonster(target) then
                        trackBossDeath(target)
                        activeBossFight = {
                            model = target,
                            name = target.Name,
                            pos = getMonsterCombatPart(target) and getMonsterCombatPart(target).Position,
                            time = os.clock(),
                        }
                    end
                    local targetHrp = getMonsterCombatPart(target)

                    if targetHrp then
                        local targetPos = targetHrp.Position
                        local mobLook = targetHrp.CFrame.LookVector
                        local toPlayer = (hrp.Position - targetPos)
                        local mName = (target.Name or ""):lower()
                        local mId = tostring(target:GetAttribute("MonsterId") or "")
                        local isBoss = isBossMonster(target) or (mName:find("boss") ~= nil) or (mName:find("witch") ~= nil) or (mId:find("boss") ~= nil)
                        local isPillar = (mName:find("pillar") ~= nil or mName:find("ritual") ~= nil or mId == "dgn_ritual_pillar")

                        local now = os.clock()
                        local isHoldingSafe = (currentSafeHoldTarget ~= nil and now < safeHoldUntil)

                        local safeDist, safeHeight, isRanged = getSmartFarmOffset(target)

                        -- 1000% Flank Defense: if monster turns to face player, slip behind it while keeping weapon reach
                        -- (Skipped in dungeon to prevent corridor wall pin, skipped in Walk Mode, and skipped while holding green circle)
                        if Config.AutoDodge and Config.DodgeFlank and (Config.FarmMode ~= "Walk") and not isHoldingSafe and not inDungeon then
                            if toPlayer.Magnitude < (safeDist + 4) and (toPlayer.Magnitude > 0.1 and mobLook:Dot(toPlayer.Unit) > 0.15) then
                                local behindPos = targetPos - (mobLook * safeDist) + Vector3.new(0, safeHeight, 0)
                                performDodge("Combat Flank Behind", -mobLook, safeDist, 0.25, target, behindPos)
                            end
                        end

                        -- 1. Precision Positioning & Active Hazard Lock
                        if isHoldingSafe then
                            -- Keep player firmly inside the green circle or safe retreat point
                            hrp.CFrame = CFrame.lookAt(currentSafeHoldTarget, targetPos + Vector3.new(0, 0.6, 0))
                            hrp.Velocity = Vector3.zero
                            hrp.AssemblyLinearVelocity = Vector3.zero
                        elseif now >= isDodgingUntil then
                            local farmH = 0.2
                            if inDungeon then
                                if isPillar or isBoss then
                                    farmH = Config.DungeonSafeHeight or 3.5
                                else
                                    farmH = 0.2
                                end
                            else
                                farmH = (Config.FarmMode == "Walk") and 0.0 or safeHeight
                            end

                            if inDungeon and (mName:find("skull") or mName:find("king")) then
                                task.spawn(checkLightBraziers)
                                if Config.AutoKickSkulls then
                                    task.spawn(checkKickDudSkulls)
                                end
                            end
                            local targetFloorY = 62.8
                            if inDungeon then
                                playerPos = getDungeonSafeCombatPosition(targetPos, mobLook, safeDist, isRanged, isBoss, isPillar)
                                targetFloorY = playerPos.Y
                            else
                                if Config.FarmMode == "Walk" then
                                    local rayParams = RaycastParams.new()
                                    rayParams.FilterType = Enum.RaycastFilterType.Exclude
                                    rayParams.FilterDescendantsInstances = {char, target}
                                    local groundRay = workspace:Raycast(targetPos + Vector3.new(0, 10, 0), Vector3.new(0, -50, 0), rayParams)
                                    local groundY = groundRay and (groundRay.Position.Y + 2.8) or targetPos.Y
                                    playerPos = targetPos - (mobLook * safeDist)
                                    playerPos = Vector3.new(playerPos.X, groundY, playerPos.Z)
                                    targetFloorY = groundY
                                else
                                    playerPos = targetPos - (mobLook * safeDist) + Vector3.new(0, farmH, 0)
                                    targetFloorY = playerPos.Y
                                end
                            end

                            -- Danger Check: Never step into active danger zones!
                            local isDanger, dReason = evaluatePositionHazard(playerPos)
                            if isDanger then
                                local cleanCandidate = findNearestSafePosition(playerPos, nil)
                                if cleanCandidate then
                                    playerPos = cleanCandidate
                                end
                            end

                            local distToTarget = (playerPos - hrp.Position).Magnitude
                            if Config.FarmMode == "Walk" then
                                -- ==================== WALK MODE (DUNGEON & FIELD) ====================
                                hum.WalkSpeed = Config.WalkFarmSpeed or 28
                                local flatDiff = Vector3.new(playerPos.X - hrp.Position.X, 0, playerPos.Z - hrp.Position.Z)
                                local flatDist = flatDiff.Magnitude
                                local minStandDist = isRanged and 12.0 or 3.5

                                if flatDist > (minStandDist + 1.2) then
                                    hum:MoveTo(playerPos)
                                elseif flatDist > 1.8 then
                                    hum:MoveTo(playerPos)
                                    hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
                                else
                                    hum:Move(Vector3.zero, false)
                                    hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
                                end
                            else
                                -- ==================== WARP / TELEPORT MODE (DUNGEON & FIELD) ====================
                                -- Instant zero-latency warp straight to safe combat position (never clipped into wall)
                                hrp.CFrame = CFrame.lookAt(playerPos, targetPos + Vector3.new(0, 0.6, 0))
                                hrp.Velocity = Vector3.zero
                                hrp.AssemblyLinearVelocity = Vector3.zero
                                hrp.AssemblyAngularVelocity = Vector3.zero
                            end
                        end

                        -- 2. Target Lock & Server Combat Activation (Safe setter)
                        setClientCurrentTarget(target)
                        pcall(function()
                            SetTarget:FireServer(target, false, true)
                            local lTarget = LocalPlayer:FindFirstChild("LumiLockTarget")
                            if lTarget and lTarget:IsA("BindableEvent") then
                                lTarget:Fire(target)
                            end
                            if AttackAnim then
                                AttackAnim:FireServer()
                            end
                            if AttackAnimU then
                                AttackAnimU:FireServer()
                            end
                        end)


                        -- 3. Smart Skills Trigger (Weaves optimal ready skill smoothly with attack)
                        if Config.AutoUseSkills then
                            evaluateAndCastBestSkill(target)
                        end

                        -- 4. Kill Aura AoE (if enabled)
                        if Config.KillAura then
                            local nearby = getNearbyMonsters(Config.KillAuraRadius or 20)
                            for _, mob in ipairs(nearby) do
                                if mob ~= target and isMonsterAlive(mob) then
                                    evaluateAndCastBestSkill(mob)
                                end
                            end
                        end
                    end
                else
                    setClientCurrentTarget(nil)
                    currentCombatTarget = nil
                    if inDungeon and Config.AutoDungeon then
                        advanceDungeonPath()
                    end

                    -- Boss Defeat Detector: Trigger immediate return to normal monster farm
                    if activeBossFight and not isReturningFromBoss and not inDungeon then
                        local bModel = activeBossFight.model
                        local isDead = false
                        if not bModel or not bModel.Parent then
                            isDead = true
                        else
                            local bHum = bModel:FindFirstChildOfClass("Humanoid")
                            if bHum and bHum.Health <= 0 then
                                isDead = true
                            elseif not isMonsterAlive(bModel) then
                                isDead = true
                            end
                        end

                        if isDead then
                            local bName = activeBossFight.name
                            local bPos = activeBossFight.pos
                            activeBossFight = nil
                            handlePostBossReturn(bName, bPos)
                        end
                    end
                end

                -- Boss Defeat Watcher (in case target switched to a mob before activeBossFight cleared)
                if activeBossFight and not isReturningFromBoss and not inDungeon then
                    local bModel = activeBossFight.model
                    local isDead = false
                    if not bModel or not bModel.Parent then
                        isDead = true
                    elseif not isMonsterAlive(bModel) then
                        isDead = true
                    end
                    if isDead then
                        local bName = activeBossFight.name
                        local bPos = activeBossFight.pos
                        activeBossFight = nil
                        handlePostBossReturn(bName, bPos)
                    end
                end
            end
        else
            if currentCombatTarget ~= nil or currentSafeHoldTarget ~= nil or LocalPlayer:GetAttribute("AutoOn") == true then
                stopCombatAndTargeting()
            end
        end
    end
end)

-- 5. Dedicated High-Speed Smart Skill & Buff Engine Loop (Runs independently of basic attack)
task.spawn(function()
    while isScriptAlive() do
        task.wait(0.035) -- ~28 FPS responsive skill evaluation
        if Config.AutoUseSkills and canScriptMoveOrWarp() and not isEnteringDungeon and not isWaitingForParty then
            local inDungeon = isInsideDungeon()
            local activeCombat = inDungeon and (Config.AutoDungeon or Config.AutoFarm) or Config.AutoFarm
            if activeCombat then
                local target = currentCombatTarget
                if not target or not isMonsterAlive(target) then
                    local ct = LocalPlayer:FindFirstChild("CurrentTarget")
                    if ct and ct.Value and isMonsterAlive(ct.Value) then
                        target = ct.Value
                    end
                end
                evaluateAndCastBestSkill(target)
            end
        end
    end
end)

-- 6. Auto Equip Best Gear & Cards Loop
task.spawn(function()
    while isScriptAlive() do
        task.wait(3.5)
        if isEnteringDungeon or isWaitingForParty then continue end
        if Config.AutoEquipBest or Config.AutoEquipBestWeapon or Config.AutoEquipCards then
            executeAutoEquipBest()
        end
        -- Auto Refine Weapon
        if Config.AutoRefine and RemotesLazy.RefineWeapon then
            pcall(function()
                RemotesLazy.RefineWeapon:FireServer()
            end)
        end
    end
end)

-- 7. Auto Map Progression & Auto World Boss Hunter Loop
task.spawn(function()
    while isScriptAlive() do
        task.wait(2.5)
        if isInsideDungeon() or isEnteringDungeon or isWaitingForParty then continue end

        -- 1. Track last normal farm zone when in normal field
        local inBoss, bossArenaName = isPlayerInBossArena()
        if not inBoss and Config.CurrentZone and not Config.CurrentZone:find("Boss") then
            lastNormalFarmZone = Config.CurrentZone
        end

        -- 2. Boss Arena Safety Watchdog: Return only if bot actively initiated world boss hunting and boss is dead
        if Config.AutoBoss and Config.AutoWarpToBoss and inBoss and (activeBossFight ~= nil or isCheckingBossArena) and not isReturningFromBoss and not isWarpingZone then
            local aliveBoss, bMob = isAnyBossAliveInArena(bossArenaName)
            if not aliveBoss then
                handlePostBossReturn("World Boss Area", nil)
            end
        end

        -- 3. Flag recovery watchdog (clears stuck flags)
        if isReturningFromBoss then
            bossReturnTimeout = bossReturnTimeout + 1
            if bossReturnTimeout >= 6 then
                bossReturnTimeout = 0
                isReturningFromBoss = false
                isWarpingZone = false
            end
        else
            bossReturnTimeout = 0
        end

        -- 4. Normal Progression check (only when not actively inspecting boss and not in boss arena)
        if Config.AutoProgression and not isCheckingBossArena and not activeBossFight and not inBoss and not isEnteringDungeon and not isWaitingForParty then
            pcall(function()
                checkAutoProgression(false)
            end)
        end

        -- 5. Periodic World Boss Arena Inspection (Warp to Boss Room)
        if (Config.AutoWarpToBoss or Config.BossOnly) and Config.AutoBoss and not isEnteringDungeon and not isWaitingForParty then
            local now = os.clock()
            local interval = Config.BossOnly and 12 or (Config.BossCheckInterval or 75)
            if (now - lastBossWarpCheckTime) >= interval then
                lastBossWarpCheckTime = now
                pcall(function()
                    executeBossInspection(true)
                end)
            end
        end
    end
end)

-- Event Listener: Instant Progression on Level Up
pcall(function()
    trackConn(LocalPlayer:GetAttributeChangedSignal("Level"):Connect(function()
        if not isScriptAlive() or not canScriptMoveOrWarp() then return end
        if Config.AutoProgression then
            task.wait(0.5)
            pcall(function()
                checkAutoProgression(false)
            end)
        end
    end))
end)

-- 8. Auto Skill Upgrade Loop
task.spawn(function()
    while isScriptAlive() do
        task.wait(4)
        if Config.AutoUpgradeSkills then
            pcall(function()
                local job = LocalPlayer:GetAttribute("Job") or "Thief"
                local jobSkills = SkillDataModule and SkillDataModule.ByJob and SkillDataModule.ByJob[job]
                if jobSkills then
                    for _, skillId in ipairs(jobSkills) do
                        pcall(function() LearnSkill:FireServer(skillId) end)
                    end
                end
            end)
        end
    end
end)

-- 9. Auto Stat Allocation Loop
task.spawn(function()
    while isScriptAlive() do
        task.wait(3)
        if Config.AutoAllocateStats then
            pcall(function()
                local preset = Config.StatPreset
                local statsToUpgrade = {}
                
                if preset == "Auto (Detect by Job)" then
                    local currentJob = LocalPlayer:GetAttribute("Job") or "Novice"
                    if currentJob == "Thief" or currentJob == "Assassin" or currentJob == "Rogue" then
                        statsToUpgrade = {"AGI", "STR", "DEX"}
                    elseif currentJob == "Swordsman" or currentJob == "Knight" or currentJob == "Crusader" then
                        statsToUpgrade = {"STR", "VIT", "AGI"}
                    elseif currentJob == "Archer" or currentJob == "Hunter" or currentJob == "Bard" or currentJob == "Dancer" then
                        statsToUpgrade = {"DEX", "AGI", "LUK"}
                    elseif currentJob == "Mage" or currentJob == "Wizard" or currentJob == "Sage" then
                        statsToUpgrade = {"INT", "DEX", "VIT"}
                    elseif currentJob == "Acolyte" or currentJob == "Cleric" or currentJob == "Priest" or currentJob == "Monk" then
                        statsToUpgrade = {"INT", "VIT", "LUK"}
                    elseif currentJob == "Merchant" or currentJob == "Blacksmith" or currentJob == "Alchemist" then
                        statsToUpgrade = {"STR", "DEX", "LUK"}
                    else
                        statsToUpgrade = {"AGI", "STR", "DEX"}
                    end
                elseif preset == "Thief (AGI > STR)" then
                    statsToUpgrade = {"AGI", "STR", "DEX"}
                elseif preset == "Swordsman (STR > VIT)" then
                    statsToUpgrade = {"STR", "VIT", "AGI"}
                elseif preset == "Archer (DEX > AGI)" then
                    statsToUpgrade = {"DEX", "AGI", "LUK"}
                elseif preset == "Mage (INT > DEX)" then
                    statsToUpgrade = {"INT", "DEX", "VIT"}
                elseif preset == "Cleric (INT > VIT)" then
                    statsToUpgrade = {"INT", "VIT", "LUK"}
                elseif preset == "Merchant (STR > DEX)" then
                    statsToUpgrade = {"STR", "DEX", "LUK"}
                elseif preset == "Pure STR" then
                    statsToUpgrade = {"STR"}
                elseif preset == "Pure AGI" then
                    statsToUpgrade = {"AGI"}
                elseif preset == "Pure DEX" then
                    statsToUpgrade = {"DEX"}
                elseif preset == "Pure INT" then
                    statsToUpgrade = {"INT"}
                else
                    statsToUpgrade = {"STR", "AGI", "VIT", "INT", "DEX", "LUK"}
                end
                
                for _, stat in ipairs(statsToUpgrade) do
                    pcall(function() AllocateStat:FireServer(stat, 1) end)
                end
            end)
        end
    end
end)

-- 10. Auto Rewards, Quests & Pets Loop
task.spawn(function()
    while isScriptAlive() do
        task.wait(8)
        -- Auto Daily & Online Rewards
        if Config.AutoClaimDaily then
            executeAutoClaimRewards()
        end
        -- Auto Quests
        if Config.AutoClaimQuests and RemotesLazy.QuestAction then
            pcall(function()
                local hs = HttpService
                local qJson = hs:JSONDecode(LocalPlayer:GetAttribute("QuestsJson") or "{}")
                if qJson and qJson.Active then
                    for qid, _ in pairs(qJson.Active) do
                        RemotesLazy.QuestAction:FireServer("claim", qid)
                    end
                end
            end)
        end
        -- Auto Achievements & Adventure Book
        if Config.AutoClaimAchieve then
            executeAutoClaimAchievements()
        end
        -- Auto Pet
        if Config.AutoPet and RemotesLazy.PetAction then
            pcall(function()
                RemotesLazy.PetAction:FireServer("summon")
                RemotesLazy.PetAction:FireServer("feed")
            end)
        end
    end
end)

-- 11. Auto Potion & Survivability Loop
task.spawn(function()
    while isScriptAlive() do
        task.wait(0.5)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if hum and hum.Health > 0 then
            -- HP Potion Check
            if Config.AutoHpPotion then
                local hpPct = (hum.Health / hum.MaxHealth) * 100
                if hpPct <= Config.HpThreshold then
                    pcall(function()
                        UseItem:FireServer("red_potion")
                        UseItem:FireServer("red_potion_m")
                        UseItem:FireServer("white_potion")
                    end)
                end
            end

            -- SP Potion Check
            if Config.AutoSpPotion then
                local sp = LocalPlayer:GetAttribute("SP") or 100
                local maxSp = LocalPlayer:GetAttribute("MaxSP") or 100
                if (sp / maxSp) * 100 <= Config.SpThreshold then
                    pcall(function()
                        UseItem:FireServer("blue_potion")
                    end)
                end
            end
        elseif hum and hum.Health <= 0 and Config.AutoRespawn then
            task.wait(1.0)
            pcall(function()
                if RemotesLazy.RespawnChoice then
                    RemotesLazy.RespawnChoice:FireServer("town")
                    RemotesLazy.RespawnChoice:FireServer("Town")
                    RemotesLazy.RespawnChoice:FireServer(1)
                end
                local deadGui = LocalPlayer.PlayerGui:FindFirstChild("LumiRespawn")
                if deadGui then
                    for _, d in ipairs(deadGui:GetDescendants()) do
                        if (d:IsA("TextButton") or d:IsA("ImageButton")) and (d.Name:lower():find("town") or (d:FindFirstChildWhichIsA("TextLabel") and d:FindFirstChildWhichIsA("TextLabel").Text:lower():find("town"))) then
                            if getconnections then
                                for _, conn in ipairs(getconnections(d.MouseButton1Click)) do pcall(function() conn:Fire() end) end
                                for _, conn in ipairs(getconnections(d.Activated)) do pcall(function() conn:Fire() end) end
                            end
                            break
                        end
                    end
                end
            end)
            task.wait(2.5)
            if Config.AutoProgression then
                pcall(function() checkAutoProgression(true) end)
            end
        end
    end
end)

-- 12. Auto Sell Loop & Bag Capacity Monitor
trackConn(LocalPlayer:GetAttributeChangedSignal("BagSlotsUsed"):Connect(function()
    if not isScriptAlive() or not canScriptMoveOrWarp() then return end
    if Config.AutoSell and Config.AutoSellOnFull then
        local used = LocalPlayer:GetAttribute("BagSlotsUsed") or 0
        local max = LocalPlayer:GetAttribute("BagSlotsMax") or 50
        if max > 0 and (used >= max - 3 or (used / max) >= 0.80) then
            task.spawn(function() executeAutoSell(true) end)
        end
    end
end))

task.spawn(function()
    -- Check immediately on script startup
    task.wait(2.0)
    if Config.AutoSell and not isEnteringDungeon and not isWaitingForParty and not isInsideDungeon() then
        local used = LocalPlayer:GetAttribute("BagSlotsUsed") or 0
        local max = LocalPlayer:GetAttribute("BagSlotsMax") or 50
        if max > 0 and (used >= max - 3 or (used / max) >= 0.80 or Config.AutoSellPeriodic) then
            executeAutoSell(true)
        end
    end

    while isScriptAlive() do
        task.wait(Config.AutoSellInterval or 20)
        if isInsideDungeon() or isEnteringDungeon or isWaitingForParty then continue end
        if Config.AutoSell then
            local used = LocalPlayer:GetAttribute("BagSlotsUsed") or 0
            local max = LocalPlayer:GetAttribute("BagSlotsMax") or 50
            if Config.AutoSellPeriodic then
                executeAutoSell(true)
            elseif Config.AutoSellOnFull then
                if max > 0 and (used >= max - 3 or (used / max) >= 0.80) then
                    executeAutoSell(true)
                end
            end
        end
    end
end)

-- 13. Auto Halloween Event Automation Loop (Trick-or-Treat, Gacha, Boxes & Rewards)
task.spawn(function()
    while isScriptAlive() do
        task.wait(2.5)
        if isInsideDungeon() or isEnteringDungeon or isWaitingForParty then continue end
        if Config.AutoHalloween then
            -- 1. Auto Claim Event NPC Rewards & Free RonB Pet
            if Config.AutoClaimEventRewards and RemotesLazy.EventNpcAction then
                pcall(function()
                    RemotesLazy.EventNpcAction:FireServer("claimAll")
                    RemotesLazy.EventNpcAction:FireServer("claimPet")
                end)
            end

            -- 2. Auto Vacuum & Open Halloween Event Boxes (relic_box)
            if Config.AutoHalloweenBoxes then
                pcall(function()
                    performHalloweenBoxVacuum()
                end)
            end

            -- 3. Auto Trick-or-Treat Knock at Witch Houses
            if Config.AutoTrickTreat then
                local candy, _ = getHalloweenInventory()
                if candy >= (Config.TrickTreatThreshold or 100) then
                    performTrickTreat(Config.TrickTreatAutoVisit)
                end
            end

            -- 4. Auto Halloween Crystal Gacha Pull (1x or 10x)
            if Config.AutoHalloweenGacha and RemotesLazy.GachaPull then
                local _, heads = getHalloweenInventory()
                local needed = (Config.GachaPullType == "1x Pull (10 Heads)") and 10 or 100
                if heads >= needed then
                    performHalloweenGacha()
                end
            end
        end
    end
end)

-- 14. Dedicated Streamer Mode Monitor & Sweep Loop
task.spawn(function()
    while isScriptAlive() do
        task.wait(2.5)
        if Config.StreamerMode then
            pcall(updateOverheadNametags)
        end
    end
end)

-- Auto-apply Streamer Mode on startup if enabled in saved config
if Config.StreamerMode then
    task.spawn(function()
        task.wait(1.5)
        pcall(applyStreamerMode)
    end)
end

-- Automatically select Combat & Farm tab so the window is never blank on startup!
pcall(function()
    CombatTab:Select()
end)

WindUI:Notify({
    Title = "Hunting Together [v3.5]",
    Content = "อัปเดตเวอร์ชันล่าสุด [v3.5] สำเร็จ!\n- เลือกสกิลที่จะใช้\n- Alt Account รับตี้ออโต้\n- ปิด Auto Lv.99 เมื่อเปิดดันเจี้ยน",
    Duration = 4,
    Icon = "check-circle",
})
