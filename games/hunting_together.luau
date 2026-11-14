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
    if getgenv then
        if getgenv()._SongHubSessionExpired == true then
            return false
        end
        if type(getgenv()._SongHubAuth) == "table" and getgenv()._SongHubAuth.revoked == true then
            return false
        end
        if getgenv()._HT_ScriptRunId and getgenv()._HT_ScriptRunId ~= currentRunId then
            return false
        end
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
local BossHunt = {
    trackedDeaths = {},
    lastCheckTime = -999,
    inspectToken = 0,
    isInspecting = false,
    lastStayNotify = 0,
    lastStayZone = "",
    isServerHopping = false,
    hopStartedAt = 0,
    serverHopNextTick = 0,
    lastHopJobId = nil,
    dynamicZoneMap = {},
    uiRefs = {},
    pillarData = {
        Town   = { Tier = 0, Pillar = Vector3.new(22.3, 3.6, 71.5),       Arena = Vector3.new(0, 5, 0),       BridgeZ = 40 },
        Boss01 = { Tier = 1, Pillar = Vector3.new(18.8, 59.8, -798.8),   Arena = Vector3.new(0, 60, -906),   BridgeZ = -855 },
        Boss02 = { Tier = 2, Pillar = Vector3.new(18.8, 115.8, -1692.8), Arena = Vector3.new(0, 116, -1800), BridgeZ = -1750 },
        Boss03 = { Tier = 3, Pillar = Vector3.new(18.8, 171.8, -2586.8), Arena = Vector3.new(0, 172, -2694), BridgeZ = -2642 },
        Boss04 = { Tier = 4, Pillar = Vector3.new(18.8, 227.8, -3480.8), Arena = Vector3.new(0, 228, -3588), BridgeZ = -3535 },
        Boss05 = { Tier = 5, Pillar = Vector3.new(18.8, 283.4, -4372.8), Arena = Vector3.new(0, 284, -4540), BridgeZ = -4450 },
    },
    worldBosses = {
        { Id = "terra_colossus",               Name = "Gorilla King",         Zone = "Boss01", MinLevel = 18, MaxLevel = 38 },
        { Id = "bigboss_thornback_behemoth",   Name = "Whitefang Sabertooth", Zone = "Boss02", MinLevel = 39, MaxLevel = 62 },
        { Id = "bigboss_obsidian_pharaoh",     Name = "Obsidian Pharaoh",     Zone = "Boss03", MinLevel = 63, MaxLevel = 84 },
        { Id = "bigboss_tempest_dragon_king",  Name = "Tempest Dragon King",  Zone = "Boss04", MinLevel = 85, MaxLevel = 97 },
        { Id = "bigboss_volcano_turtle_king",  Name = "Volcano Turtle King",  Zone = "Boss05", MinLevel = 98, MaxLevel = 999 },
    },
}

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
        if LocalPlayer:GetAttribute("AutoOn") == true then
            local now = os.clock()
            if (now - (BossHunt.lastDisableAutoAt or 0)) >= 2.0 then
                BossHunt.lastDisableAutoAt = now
                local LumiMenuToggle = LocalPlayer:FindFirstChild("LumiMenuToggle")
                if LumiMenuToggle and LumiMenuToggle:IsA("BindableEvent") then
                    pcall(LumiMenuToggle.Fire, LumiMenuToggle, "autoToggle")
                end
            end
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
    if BossHunt then
        BossHunt.inspectToken = (BossHunt.inspectToken or 0) + 1
        BossHunt.isInspecting = false
    end
    isWarpingZone = false
    isReturningFromBoss = false
    isSelling = false
    isOpeningBox = false
    isLooting = false
    outOfZoneTicks = 0
end

-- Safe helper to manage target attributes & ObjectValue without crashing
local function setClientCurrentTarget(tgt)
    local ct = LocalPlayer:FindFirstChild("CurrentTarget")
    if ct and ct:IsA("ObjectValue") and ct.Value ~= tgt then
        if tgt == nil or (typeof(tgt) == "Instance" and tgt.Parent ~= nil) then
            ct.Value = tgt
        else
            ct.Value = nil
        end
    end
    local wantLocked = (tgt ~= nil)
    if LocalPlayer:GetAttribute("TargetLocked") ~= wantLocked then
        LocalPlayer:SetAttribute("TargetLocked", wantLocked)
    end
    if tgt ~= nil then
        -- Never force AutoOn = true during Hub combat: CombatClient's toggleAuto conflicts with disableGameAutoOn
        local wantBotSkills = (Config.AutoUseSkills == true)
        if LocalPlayer:GetAttribute("BotUseSkills") ~= wantBotSkills then
            LocalPlayer:SetAttribute("BotUseSkills", wantBotSkills)
        end
    elseif not Config.AutoFarm and not (Config.AutoDungeon and isInsideDungeon()) then
        if LocalPlayer:GetAttribute("AutoOn") == true then
            local now = os.clock()
            if (now - (BossHunt.lastDisableAutoAt or 0)) >= 2.0 then
                BossHunt.lastDisableAutoAt = now
                local LumiMenuToggle = LocalPlayer:FindFirstChild("LumiMenuToggle")
                if LumiMenuToggle and LumiMenuToggle:IsA("BindableEvent") then
                    pcall(LumiMenuToggle.Fire, LumiMenuToggle, "autoToggle")
                end
            end
            LocalPlayer:SetAttribute("AutoOn", false)
        end
    end
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
        local stOk, st = pcall(hum.GetState, hum)
        if stOk and st == Enum.HumanoidStateType.Dead then
            return false
        end
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
    FarmDistance = 4.5,          -- ค่าตั้งต้นระยะฟาร์ม
    AttackDelay = 0.08,
    SelectedMonster = "All",
    AutoBoss = false,            -- Automatically hunt Bosses & Mini-Bosses (ปิดไว้เป็นค่าเริ่มต้น)
    AutoWarpToBoss = false,     -- Automatically warp to World Boss Arenas (ปิดไว้เป็นค่าเริ่มต้น)
    PrioritizeBoss = false,      -- Attack Boss first when present (ปิดไว้เป็นค่าเริ่มต้น)
    BossOnly = false,           -- Farm ONLY Bosses and Mini-Bosses
    SelectedBoss = "All Bosses",-- Specific Boss, summary string, or "All Bosses"
    SelectedBosses = { "All Bosses" }, -- Multi-select Boss names for BossOnly & BossServerHop
    BossServerHop = false,      -- Auto Server Hop when target boss is missing or defeated
    BossHopDelay = 15,          -- Seconds to wait before Server Hop when selected boss is missing (15s safe default)
    BossTimedHop = false,       -- Enable periodic timed Server Hop for Boss Hunting
    BossTimedHopMinutes = 5,    -- Minutes interval for Timed Boss Server Hop
    ReturnToProgressionAfterBoss = false, -- ตีบอสเสร็จกลับไปฟาร์มตาม Auto Lv.99 ทันที
    BossCheckInterval = 75,     -- Seconds between periodic Boss Arena inspections
    KillAura = false,
    KillAuraRadius = 20,
    MaxTargetDistance = 70,     -- Keep search strictly within active field
    AutoUseSkills = true,        -- เปิดใช้งานสกิลต่อสู้อัตโนมัติเป็นค่าเริ่มต้น
    AutoUseBuffs = true,         -- เปิดใช้งานสกิลบัฟอัตโนมัติเป็นค่าเริ่มต้น
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
        return (Config.AutoFarm == true) or (Config.AutoProgression == true) or (Config.AutoDungeon == true) or (Config.BossOnly == true) or (Config.BossServerHop == true)
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
                if type(Config.SelectedBosses) ~= "table" or #Config.SelectedBosses == 0 then
                    if type(Config.SelectedBoss) == "string" and Config.SelectedBoss ~= "" then
                        local splitList = {}
                        for part in Config.SelectedBoss:gmatch("[^,]+") do
                            local trimmed = part:match("^%s*(.-)%s*$")
                            if trimmed and trimmed ~= "" then
                                table.insert(splitList, trimmed)
                            end
                        end
                        Config.SelectedBosses = (#splitList > 0) and splitList or { "All Bosses" }
                    else
                        Config.SelectedBosses = { "All Bosses" }
                    end
                end
                if Config.BossHopDelay == nil then Config.BossHopDelay = 15 end
                if Config.BossTimedHop == nil then Config.BossTimedHop = false end
                if Config.BossTimedHopMinutes == nil then Config.BossTimedHopMinutes = 5 end
                BossHunt.serverJoinAt = BossHunt.serverJoinAt or os.clock()
                BossHunt.hopUnlockAt = BossHunt.serverJoinAt + 12.0
                if not BossHunt._coldHopChecked then
                    BossHunt._coldHopChecked = true
                    local hopMarkerValid = false
                    local markerPath = "HuntingTogether_HopSession_" .. tostring(LocalPlayer.UserId) .. ".json"
                    if type(readfile) == "function" then
                        local exists = true
                        if type(isfile) == "function" then
                            local isOk, res = pcall(isfile, markerPath)
                            exists = (isOk and res == true)
                        end
                        if exists then
                            local mOk, mRaw = pcall(readfile, markerPath)
                            if mOk and type(mRaw) == "string" and #mRaw > 2 then
                                local dOk, mData = pcall(HttpService.JSONDecode, HttpService, mRaw)
                                if dOk and type(mData) == "table" and tonumber(mData.ts) and (os.time() - tonumber(mData.ts)) <= 90 and (os.time() - tonumber(mData.ts)) >= -5 then
                                    hopMarkerValid = true
                                end
                            end
                            if type(delfile) == "function" then
                                pcall(delfile, markerPath)
                            elseif type(writefile) == "function" then
                                pcall(writefile, markerPath, "{}")
                            end
                        end
                    end
                    if not hopMarkerValid then
                        -- Cold launch / manual rejoin / aborted session: never auto-resume a server hop loop
                        Config.BossServerHop = false
                        Config.BossTimedHop = false
                        Config.ServerHopAuto = false
                    end
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
BossHunt.serverJoinAt = BossHunt.serverJoinAt or os.clock()
BossHunt.hopUnlockAt = BossHunt.hopUnlockAt or (BossHunt.serverJoinAt + 12.0)
_G.HT_Config = Config
if getgenv then getgenv().HT_Config = Config end

-- ==================== AUTO EXECUTE ON TELEPORT ====================
local hasRegisteredQueue = false
local function registerQueueOnTeleport(forceQueue)
    if not Config.AutoExecuteOnTeleport and not forceQueue then return end
    if hasRegisteredQueue and not forceQueue then return end -- Guard: Only queue once per game session unless forced for retry
    local queue = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if queue then
        hasRegisteredQueue = true
        local execCode = [[
            task.wait(2.0)
            if getgenv and (getgenv()._HuntingTogetherRunning or getgenv()._UniversalLoaderLoading or getgenv()._SongHubLoading) then
                return
            end
            local reqFn = (syn and syn.request) or request or (http and http.request) or http_request
            local compiledFn = nil
            for attempt = 1, 2 do
                local cb = tostring(os.time()) .. "_" .. tostring(math.random(100, 999)) .. "_" .. tostring(attempt)
                local urls = {
                    "https://song-hub-whitelist.song-hub-cloudflare-worker.workers.dev/loader.luau?v=" .. cb,
                    "https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/loader.luau?v=" .. cb,
                    "https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/Universal_Loader.luau?v=" .. cb,
                }
                local function validLua(code)
                    if type(code) ~= "string" or #code <= 500 then return nil end
                    local head = code:sub(1, 512):gsub("^%s+", "")
                    if head == "" or head:sub(1, 1) == "<" then return nil end
                    if head:find("403" .. ": Forbidden", 1, true) or head:find("404" .. ": Not Found", 1, true) or head:find("-- Game script" .. " not found", 1, true) then return nil end
                    return loadstring(code)
                end
                for _, u in ipairs(urls) do
                    local sOk, code = pcall(function() return game:HttpGet(u) end)
                    local fn = sOk and validLua(code) or nil
                    if fn then compiledFn = fn; break end
                    if reqFn then
                        local rOk, resp = pcall(reqFn, { Url = u, Method = "GET", Headers = { ["Cache-Control"] = "no-cache" } })
                        if rOk and type(resp) == "table" then
                            fn = validLua(resp.Body)
                            if fn then compiledFn = fn; break end
                        end
                    end
                end
                if compiledFn then break end
                if attempt < 2 then task.wait(0.8) end
            end
            if compiledFn then
                return compiledFn()
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
    Boss01  = Vector3.new(0, 60, -906),
    Field04 = Vector3.new(0, 62, -1097),
    Field05 = Vector3.new(0, 90, -1353),
    Field06 = Vector3.new(0, 118, -1609),
    Boss02  = Vector3.new(0, 116, -1800),
    Field07 = Vector3.new(0, 118, -1991),
    Field08 = Vector3.new(0, 146, -2247),
    Field09 = Vector3.new(0, 174, -2503),
    Boss03  = Vector3.new(0, 172, -2694),
    Field10 = Vector3.new(0, 174, -2885),
    Field11 = Vector3.new(0, 202, -3141),
    Field12 = Vector3.new(0, 230, -3397),
    Boss04  = Vector3.new(0, 228, -3588),
    Field13 = Vector3.new(0, 230, -3779),
    Field14 = Vector3.new(0, 258, -4035),
    Field15     = Vector3.new(0, 286, -4291),
    Boss05      = Vector3.new(0, 284, -4540),
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

local function getDungeonSafeCombatPosition(targetPos, mobLook, safeDist, isRanged, isBoss, isPillar, farmH)
    local wallInstances = getDungeonWallInstances()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    local baseDist = tonumber(safeDist)
    if baseDist == nil then
        baseDist = isRanged and 12.0 or (isBoss and 5.0 or 3.5)
    end
    local effectiveDist = math.clamp(baseDist, 1.0, 65.0)

    local flatLook = mobLook and Vector3.new(mobLook.X, 0, mobLook.Z) or Vector3.new(0, 0, -1)
    flatLook = (flatLook.Magnitude > 0.05) and flatLook.Unit or Vector3.new(0, 0, -1)

    -- Accurate ground detection excluding characters and monsters
    local floorY = targetPos.Y
    local rayParamsEnv = RaycastParams.new()
    rayParamsEnv.FilterType = Enum.RaycastFilterType.Exclude
    local envIgnore = { char }
    local monstersFolder = workspace:FindFirstChild("Monsters")
    if monstersFolder then table.insert(envIgnore, monstersFolder) end
    rayParamsEnv.FilterDescendantsInstances = envIgnore
    pcall(function()
        local floorRay = workspace:Raycast(Vector3.new(targetPos.X, targetPos.Y + 15.0, targetPos.Z), Vector3.new(0, -35.0, 0), rayParamsEnv)
        if floorRay and floorRay.Instance and floorRay.Instance.Name:lower():find("ceiling") == nil then
            floorY = floorRay.Position.Y + 2.8
        end
    end)

    -- If fly / warp mode (not Walk), apply configured hover clamped under dungeon ceilings
    local isWalk = (Config.FarmMode == "Walk")
    if not isWalk then
        local hover = tonumber(farmH)
        if hover == nil then
            hover = (isBoss or isPillar) and (tonumber(Config.DungeonSafeHeight) or 3.5) or 0.8
        end
        hover = math.clamp(hover, 0.0, 15.0)
        pcall(function()
            local ceilRay = workspace:Raycast(Vector3.new(targetPos.X, floorY, targetPos.Z), Vector3.new(0, hover + 3.5, 0), rayParamsEnv)
            if ceilRay and ceilRay.Distance then
                hover = math.max(0.0, math.min(hover, ceilRay.Distance - 2.5))
            end
        end)
        floorY = floorY + hover
    end

    -- If no wall instances detected in game, position directly at requested distance behind monster
    if #wallInstances == 0 then
        local p = targetPos - (flatLook * effectiveDist)
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

        -- If a wall is right next to the monster (< 1.5 studs), discard this direction
        if wallDist >= 1.5 then
            -- Maximum safe distance the player can stand along this direction without touching the wall
            local maxAllowedDist = math.max(1.0, wallDist - 1.5)
            local standDist = math.min(effectiveDist, maxAllowedDist)

            local candPos = Vector3.new(targetPos.X + dir.X * standDist, floorY, targetPos.Z + dir.Z * standDist)
            local candRayPos = Vector3.new(candPos.X, rayY, candPos.Z)

            -- 2. Line of sight check: from candPos to targetPos
            local toTarget = rayOrigin - candRayPos
            local losHit = workspace:Raycast(candRayPos, toTarget, rayParams)

            -- Must have 100% clean line of sight (no wall between player and monster!)
            if not losHit then
                -- 3. Check clearance behind player (cast 2.0 studs behind player)
                local behindHit = workspace:Raycast(candRayPos, dir * 2.0, rayParams)
                local behindClearance = behindHit and behindHit.Distance or 2.0

                if behindClearance >= 0.8 then
                    -- Prefer unobstructed directions that closely match the user's configured effectiveDist
                    local distPenalty = math.abs(effectiveDist - standDist) * 35
                    local score = wallDist * 10 + behindClearance * 20 - distPenalty
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
    if hallwayDir then
        local hwHit = workspace:Raycast(rayOrigin, hallwayDir * (effectiveDist + 1.5), rayParams)
        local hwMax = hwHit and math.max(1.2, hwHit.Distance - 1.5) or effectiveDist
        local safeDistHw = math.min(effectiveDist, hwMax)
        local safeHallwayPos = Vector3.new(targetPos.X + hallwayDir.X * safeDistHw, floorY, targetPos.Z + hallwayDir.Z * safeDistHw)
        return safeHallwayPos
    end

    local fallback = targetPos - (flatLook * effectiveDist)
    return Vector3.new(fallback.X, floorY, fallback.Z)
end

local function getDungeonTarget()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local folder = workspace:FindFirstChild("Monsters")
    local CollectionService = game:GetService("CollectionService")

    -- Collect all potential dungeon mobs from Monsters folder and tagged Monsters
    local candidateMobs = {}
    local seen = {}
    if folder then
        for _, mob in ipairs(folder:GetChildren()) do
            if mob:IsA("Model") and not seen[mob] then
                seen[mob] = true
                table.insert(candidateMobs, mob)
            end
        end
    end
    for _, mob in ipairs(CollectionService:GetTagged("Monster")) do
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
                local isGoldSpecial = (mName:find("gold") ~= nil or mId:find("gold") ~= nil or mName:find("barrel") ~= nil or mId:find("barrel") ~= nil)
                local isGoblin = (mName:find("goblin") ~= nil or mId:find("goblin") ~= nil or mId:find("gd_") ~= nil)
                local score = 1000 - dist

                -- 1. Pillar priority: ABSOLUTE TOP PRIORITY if alive pillars exist
                if isPillar then
                    score = 1000000 - dist
                -- 2. Gold Goblin / Barrel priority in Gold Dungeon
                elseif isGoldSpecial then
                    score = 250000 - dist
                -- 3. Mini Boss (Potion Witch) priority during Step 3 or when in/near Witch Lair
                elseif isWitch and (dStep == 3 or inWitchLair or (Config.PrioritizeDungeonBoss or Config.PrioritizeBoss)) then
                    if alivePillarCount > 0 then
                        score = -1000000
                    else
                        score = 500000 - dist
                    end
                -- 4. Final Boss (Skull King) priority during Step 4 or when in Boss Arena
                elseif isBoss and (dStep >= 4 or inBossArena or (Config.PrioritizeDungeonBoss or Config.PrioritizeBoss)) then
                    if alivePillarCount > 0 then
                        score = -1000000
                    else
                        score = 500000 - dist
                    end
                -- 5. Standard goblins in Gold Dungeon
                elseif isGoblin then
                    score = 50000 - dist
                -- 6. Close aggro monsters along corridor (clears corridor cleanly without wall snag)
                elseif dist <= 35 then
                    score = 30000 - dist
                elseif dist <= 75 then
                    score = 15000 - dist
                end

                -- Line of sight wall penalty: exempt pillars, gold special, witch in step 3/lair, and boss in step 4/arena
                local exemptLos = isPillar or isGoldSpecial or (isWitch and (dStep == 3 or inWitchLair)) or (isBoss and (dStep >= 4 or inBossArena))
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
    if Config.SelectedDungeon == "gold" or workspace:FindFirstChild("GoldDungeon") then return end

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

    -- Scan monsters for active objectives:
    local mFolder = workspace:FindFirstChild("Monsters")
    local hasAlivePillars = false
    local hasAliveWitch = false
    local aliveMobsCount = 0
    local bossFound = false
    if mFolder then
        for _, m in ipairs(mFolder:GetChildren()) do
            if m:IsA("Model") and isMonsterAlive(m) then
                aliveMobsCount = aliveMobsCount + 1
                local mName = m.Name:lower()
                local mId = tostring(m:GetAttribute("MonsterId") or "")
                if mName:find("pillar") or mName:find("ritual") or mId == "dgn_ritual_pillar" then
                    hasAlivePillars = true
                elseif mName:find("witch") or mId:find("witch") or m:GetAttribute("IsMiniBoss") == true then
                    hasAliveWitch = true
                end
                if m:GetAttribute("IsBoss") == true or mName:find("boss") or mName:find("skull king") or mId:find("boss") or mId:find("skull") then
                    bossFound = true
                end
            end
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

    -- Boss Room Stagnation Recovery:
    if closestIdx >= 32 and not currentCombatTarget then
        if dStep >= 4 and not bossFound then
            -- In Step 4 with no boss yet: advance to center of arena to trigger spawn
            local h = workspace:FindFirstChild("Halloween")
            local bd = h and h:FindFirstChild("BossDoor")
            local slab = bd and bd:FindFirstChild("Slab")
            local prompt = bd and bd:FindFirstChildWhichIsA("ProximityPrompt", true)
            if slab and slab.CanCollide and prompt and prompt.Enabled then
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
            else
                currentDungeonWpIndex = 36
                local bossSpot = DungeonPathWaypoints[36]
                if bossSpot then
                    hrp.CFrame = CFrame.new(bossSpot.X, bossSpot.Y, bossSpot.Z)
                    hrp.Velocity = Vector3.zero
                end
                return
            end
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
    if BossHunt then
        BossHunt.inspectToken = (BossHunt.inspectToken or 0) + 1
        BossHunt.isInspecting = false
    end
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
    local isGoldDungeon = (Config.SelectedDungeon == "gold")
    if not isGoldDungeon then
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
        if bName:find("^Boss") then
            -- Boss05 has a 170x170 zone (wider radius), Boss01-04 are smaller arenas
            local arenaRad = (bName == "Boss05") and 115 or 90
            if (Vector3.new(pPos.X, 0, pPos.Z) - Vector3.new(bPos.X, 0, bPos.Z)).Magnitude <= arenaRad then
                return true, bName
            end
        end
    end
    if Config.CurrentZone and Config.CurrentZone:find("^Boss") then
        return true, Config.CurrentZone
    end
    return false, nil
end

local function isAnyBossAliveInArena(arenaName, selectedBoss)
    if BossHunt and BossHunt.findMatchingBoss then
        local arenaPos = arenaName and ZoneCoordinates[arenaName]
        local maxDist = arenaPos and 155 or math.huge
        local found = BossHunt.findMatchingBoss(selectedBoss or Config.SelectedBoss, arenaPos, maxDist)
        return found ~= nil, found
    end
    local arenaPos = arenaName and ZoneCoordinates[arenaName]
    local folder = workspace:FindFirstChild("Monsters")
    if not folder then return false, nil end
    for _, m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") and isMonsterAlive(m) and isBossMonster(m) then
            local mHrp = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
            if mHrp then
                if arenaPos then
                    local d = (Vector3.new(mHrp.Position.X, 0, mHrp.Position.Z) - Vector3.new(arenaPos.X, 0, arenaPos.Z)).Magnitude
                    if d <= 155 then
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
    -- Priority: When boss is defeated, return directly to Lv.99 MAX field (Field13) as requested
    if Config.ReturnToProgressionAfterBoss or Config.AutoBoss then
        return "Field13", "Lava Turtle Hill (Lv.99 MAX)"
    end
    local pLevel = getPlayerLevel()
    if pLevel >= 95 then
        return "Field13", "Lava Turtle Hill (Lv.99 MAX)"
    end
    local optField, optName = getOptimalZone(pLevel)
    return optField, optName
end

function BossHunt.disableGameAutoOn()
    if LocalPlayer:GetAttribute("AutoOn") ~= true then return end
    LocalPlayer:SetAttribute("AutoOn", false)
    local now = os.clock()
    if (now - (BossHunt.lastDisableAutoAt or 0)) < 2.0 then
        return
    end
    BossHunt.lastDisableAutoAt = now
    local LumiMenuToggle = LocalPlayer:FindFirstChild("LumiMenuToggle")
    if LumiMenuToggle and LumiMenuToggle:IsA("BindableEvent") then
        pcall(LumiMenuToggle.Fire, LumiMenuToggle, "autoToggle")
    end
    local BotAutoState = getRemote("BotAutoState")
    if BotAutoState then pcall(BotAutoState.FireServer, BotAutoState, false) end
    local BotState = getRemote("BotState")
    if BotState then pcall(BotState.FireServer, BotState, false) end
end

function BossHunt.hasPillarUnlocked(zoneName)
    if not zoneName then return false end
    local unlockedRaw = tostring(LocalPlayer:GetAttribute("WarpPillars") or "")
    for token in string.gmatch(unlockedRaw, "[^,]+") do
        if token:match("^%s*(.-)%s*$") == zoneName then
            return true
        end
    end
    return false
end

function BossHunt.getLivePillarPos(zoneName)
    local pData = BossHunt.pillarData and BossHunt.pillarData[zoneName]
    local fallback = pData and pData.Pillar
    pcall(function()
        local mapFolder = workspace:FindFirstChild("Map")
        local wpFolder = mapFolder and mapFolder:FindFirstChild("WarpPillars")
        local pillarObj = wpFolder and wpFolder:FindFirstChild("WarpPillar_" .. tostring(zoneName))
        if pillarObj then
            if pillarObj:IsA("BasePart") then
                fallback = pillarObj.Position
            elseif pillarObj:IsA("Model") then
                fallback = pillarObj:GetPivot().Position
            end
        end
    end)
    return fallback
end

function BossHunt.walkToPoint(pt, stopTol, timeoutSec)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return false end
    local tol = stopTol or 4.5
    local limit = os.clock() + (timeoutSec or 5.5)
    local targetSpeed = math.max(hum.WalkSpeed or 16, tonumber(Config and Config.WalkFarmSpeed) or 28, 30)
    while os.clock() < limit and isScriptAlive() and hrp.Parent and hum.Health > 0 do
        if isInsideDungeon() then break end
        BossHunt.disableGameAutoOn()
        if (hum.WalkSpeed or 0) < targetSpeed then
            pcall(function() hum.WalkSpeed = targetSpeed end)
        end
        local dx = pt.X - hrp.Position.X
        local dz = pt.Z - hrp.Position.Z
        if math.sqrt(dx * dx + dz * dz) <= tol then
            pcall(function() hum:Move(Vector3.zero, false) end)
            return true
        end
        pcall(function() hum:MoveTo(Vector3.new(pt.X, hrp.Position.Y, pt.Z)) end)
        task.wait(0.15)
    end
    pcall(function() hum:Move(Vector3.zero, false) end)
    local finalDx = pt.X - hrp.Position.X
    local finalDz = pt.Z - hrp.Position.Z
    return math.sqrt(finalDx * finalDx + finalDz * finalDz) <= (tol + 2.5)
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

    -- 1. Detach from current targets cleanly & stop built-in game AutoOn override
    setClientCurrentTarget(nil)
    BossHunt.disableGameAutoOn()

    -- 2. Notify player
    if WindUI and WindUI.Notify then
        WindUI:Notify({
            Title = "Auto Field Warper",
            Content = "เลเวล " .. getPlayerLevel() .. "\nกำลังเดินทางสู่ Field: " .. (fieldName or targetField),
            Duration = 2.5,
            Icon = "navigation",
        })
    end

    -- 3. Legitimate PillarWarp when travelling to Boss01-Boss05/Town from near any WarpPillar (0 CheatTag!)
    local arrivedSafely = false
    pcall(function()
        local dstData = BossHunt.pillarData and BossHunt.pillarData[targetField]
        if not dstData then return end

        local myPos = hrp.Position
        local dstPillarPos = BossHunt.getLivePillarPos(targetField) or dstData.Pillar
        local distToDstArenaXZ = (Vector3.new(myPos.X, 0, myPos.Z) - Vector3.new(dstData.Arena.X, 0, dstData.Arena.Z)).Magnitude
        local distToDstPillarXZ = (Vector3.new(myPos.X, 0, myPos.Z) - Vector3.new(dstPillarPos.X, 0, dstPillarPos.Z)).Magnitude

        -- Already in target rest area / doorway: simply walk inside the arena cleanly
        if targetField:find("^Boss") and (distToDstArenaXZ <= 185 or distToDstPillarXZ <= 95) then
            if distToDstArenaXZ > 55 then
                BossHunt.walkToPoint(Vector3.new(0, myPos.Y, dstPillarPos.Z), 6.0, 4.0)
                BossHunt.walkToPoint(Vector3.new(0, myPos.Y, dstData.Arena.Z + ((targetField == "Boss05") and 40 or 25)), 6.0, 5.5)
            end
            arrivedSafely = true
            return
        end

        if not (RemotesLazy.PillarWarp and BossHunt.hasPillarUnlocked(targetField)) then return end
        local isPremium = (LocalPlayer:GetAttribute("Premium") == true)
        local silver = tonumber(LocalPlayer:GetAttribute("Silver")) or 0
        if not isPremium and silver < (dstData.Tier * 1000) then return end

        -- Find nearest reachable WarpPillar (Town or Boss01-05)
        local curZone, curData, curPillarPos, bestPillarDist = nil, nil, nil, math.huge
        for zName, zData in pairs(BossHunt.pillarData) do
            local pPos = BossHunt.getLivePillarPos(zName) or zData.Pillar
            local dXZ = (Vector3.new(myPos.X, 0, myPos.Z) - Vector3.new(pPos.X, 0, pPos.Z)).Magnitude
            local aXZ = (Vector3.new(myPos.X, 0, myPos.Z) - Vector3.new(zData.Arena.X, 0, zData.Arena.Z)).Magnitude
            local minD = math.min(dXZ, aXZ)
            if minD <= 190 and minD < bestPillarDist then
                bestPillarDist = minD
                curZone = zName
                curData = zData
                curPillarPos = pPos
            end
        end

        if not curZone or not curData or not curPillarPos then return end

        local nowP = hrp.Position
        local curDist3D = (nowP - curPillarPos).Magnitude
        if curZone ~= targetField and curDist3D > 10 then
            if curZone ~= "Town" and nowP.Z < (curPillarPos.Z - 25) then
                BossHunt.walkToPoint(Vector3.new(0, nowP.Y, curData.BridgeZ), 6.0, 4.5)
                BossHunt.walkToPoint(Vector3.new(0, nowP.Y, curPillarPos.Z), 6.0, 4.5)
            end
            BossHunt.walkToPoint(Vector3.new(curPillarPos.X - 4, curPillarPos.Y + 2, curPillarPos.Z), 4.0, 4.5)
            task.wait(0.28)
        end

        if curZone ~= targetField and hrp and hrp.Parent and (hrp.Position - curPillarPos).Magnitude <= 12 and (os.clock() - (BossHunt.lastWarpTime or 0)) >= 2.5 then
            BossHunt.lastWarpTime = os.clock()
            BossHunt.warpLog = BossHunt.warpLog or {}
            table.insert(BossHunt.warpLog, { t = os.clock(), from = curZone, to = targetField, dist = (hrp.Position - curPillarPos).Magnitude })
            getgenv()._HT_WarpLog = BossHunt.warpLog
            local prevPos = hrp.Position
            RemotesLazy.PillarWarp:FireServer(targetField)
            local waitUntil = os.clock() + 3.2
            while os.clock() < waitUntil and hrp and hrp.Parent do
                local freshDst = BossHunt.getLivePillarPos(targetField) or dstData.Pillar
                local landedDist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(freshDst.X, 0, freshDst.Z)).Magnitude
                if landedDist <= 45 and (hrp.Position - prevPos).Magnitude > 60 then
                    dstPillarPos = freshDst
                    break
                end
                task.wait(0.1)
            end
            if hrp and hrp.Parent then
                local landedDist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(dstPillarPos.X, 0, dstPillarPos.Z)).Magnitude
                if landedDist <= 50 then
                    if dstData.BridgeZ then
                        BossHunt.walkToPoint(Vector3.new(0, hrp.Position.Y, dstPillarPos.Z), 6.0, 3.0)
                        BossHunt.walkToPoint(Vector3.new(0, hrp.Position.Y, dstData.Arena.Z + ((targetField == "Boss05") and 40 or 25)), 6.0, 5.5)
                    end
                    arrivedSafely = true
                end
            end
        end
    end)

    -- 4. Fallback: Sync zone & Smooth Step-wise Teleport (for distant Field -> Boss0X or locked pillars)
    if not arrivedSafely then
        pcall(function()
            if RemotesLazy.WarpTo then
                RemotesLazy.WarpTo:FireServer(targetField)
            end
        end)

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
    end

    Config.CurrentZone = targetField
    if not targetField:find("Boss") then
        lastNormalFarmZone = targetField
    end
    task.wait(0.35)

    -- 5. Reset target monster to "All" so auto farm engages immediately in the new field
    Config.SelectedMonster = "All"
    pcall(function()
        if monsterDropdown then
            monsterDropdown:SetValues(getMonsterList())
        end
        if BossHunt and BossHunt.refreshBossDropdown then
            BossHunt.refreshBossDropdown()
        end
    end)

    isWarpingZone = false
end

-- ==================== AUTO RETURN TO PROGRESSION & BOSS HUNT ENGINE ====================
activeBossFight = nil
isReturningFromBoss = false
isCheckingBossArena = false

BossHunt.bossZones = BossHunt.worldBosses

BossHunt.bossZoneMap = {
    ["Volcano Turtle King"]      = { Zone = "Boss05", Name = "Volcano Turtle King",      Id = "bigboss_volcano_turtle_king", Level = 99 },
    ["Tempest Dragon King"]      = { Zone = "Boss04", Name = "Tempest Dragon King",      Id = "bigboss_tempest_dragon_king", Level = 85 },
    ["Obsidian Pharaoh"]         = { Zone = "Boss03", Name = "Obsidian Pharaoh",         Id = "bigboss_obsidian_pharaoh",    Level = 63 },
    ["Whitefang Sabertooth"]     = { Zone = "Boss02", Name = "Whitefang Sabertooth",     Id = "bigboss_thornback_behemoth",  Level = 39 },
    ["Gorilla King"]             = { Zone = "Boss01", Name = "Gorilla King",             Id = "terra_colossus",              Level = 18 },
    ["Ram King"]                 = { Zone = "Field08", Name = "Ram King",                Level = 60 },
    ["Leader Fang Hyena"]        = { Zone = "Field04", Name = "Leader Fang Hyena",        Level = 30 },
    ["Leader Saber Tiger"]       = { Zone = "Field06", Name = "Leader Saber Tiger",       Level = 45 },
    ["Leader Spiked Stone Golem"]= { Zone = "Field09", Name = "Leader Spiked Stone Golem",Level = 70 },
    ["Leader Spiked Ice Golem"]  = { Zone = "Field12", Name = "Leader Spiked Ice Golem",  Level = 95 },
}

BossHunt.leaderZones = {
    { Zone = "Field12", Name = "Leader Spiked Ice Golem", Level = 95 },
    { Zone = "Field09", Name = "Leader Spiked Stone Golem", Level = 70 },
    { Zone = "Field06", Name = "Leader Saber Tiger", Level = 45 },
    { Zone = "Field04", Name = "Leader Fang Hyena", Level = 30 },
}

function BossHunt.normalizeOneChoice(val)
    if type(val) == "table" then
        val = val.Title or val.Name or val.Value or val[1]
    end
    if type(val) ~= "string" then
        return ""
    end
    val = val:match("^%s*(.-)%s*$") or ""
    if val == "" then return "" end
    val = val:gsub("%s*%(Boss%d%d.-%)$", "")
    val = val:match("^%s*(.-)%s*$") or ""
    if val == "World Bosses Only" or val == "World Bosses Only (Boss01-05)" then
        return "All Bosses"
    end
    return val
end

function BossHunt.getSelectionList(selectedBoss)
    local src = selectedBoss
    if src == nil then
        if type(Config.SelectedBosses) == "table" and #Config.SelectedBosses > 0 then
            src = Config.SelectedBosses
        else
            src = Config.SelectedBoss
        end
    end

    local rawList = {}
    if type(src) == "string" then
        for part in src:gmatch("[^,]+") do
            table.insert(rawList, part)
        end
    elseif type(src) == "table" then
        if #src > 0 then
            for _, v in ipairs(src) do
                table.insert(rawList, v)
            end
        else
            for k, v in pairs(src) do
                if v == true and type(k) == "string" then
                    table.insert(rawList, k)
                elseif type(v) == "string" then
                    table.insert(rawList, v)
                end
            end
        end
    end

    local out, seen = {}, {}
    local hasAll, hasAllPlus, hasLeaders = false, false, false
    local specifics = {}
    for _, item in ipairs(rawList) do
        local norm = BossHunt.normalizeOneChoice(item)
        if norm ~= "" and not seen[norm] then
            seen[norm] = true
            table.insert(out, norm)
            if norm == "All Bosses" then
                hasAll = true
            elseif norm == "All Bosses + Leaders" then
                hasAllPlus = true
            elseif norm == "Pack Leaders Only" then
                hasLeaders = true
            else
                table.insert(specifics, norm)
            end
        end
    end

    if #out == 0 then
        return { "All Bosses" }
    end
    if hasAllPlus and #specifics == 0 then
        return { "All Bosses + Leaders" }
    end
    if #specifics > 0 or hasLeaders then
        -- Specific names / Pack Leaders take precedence over a leftover "All Bosses" entry
        local filtered = {}
        for _, v in ipairs(out) do
            if v ~= "All Bosses" and v ~= "All Bosses + Leaders" then
                table.insert(filtered, v)
            end
        end
        if #filtered > 0 then
            return filtered
        end
    end
    if hasAll then
        return { "All Bosses" }
    end
    return out
end

function BossHunt.formatSelectionSummary(val)
    local list = BossHunt.getSelectionList(val)
    return table.concat(list, ", ")
end

function BossHunt.normalizeChoice(val)
    if val == nil then
        return BossHunt.formatSelectionSummary(nil)
    end
    if type(val) == "table" then
        return BossHunt.formatSelectionSummary(val)
    end
    local single = BossHunt.normalizeOneChoice(val)
    if single == "" then return "All Bosses" end
    return single
end

function BossHunt.toDropdownValues(selInput, availableValues)
    local list = BossHunt.getSelectionList(selInput)
    local result, seen = {}, {}
    local normToLabel = {}
    if type(availableValues) == "table" then
        for _, lbl in ipairs(availableValues) do
            local n = BossHunt.normalizeOneChoice(lbl)
            if n ~= "" and not normToLabel[n] then
                normToLabel[n] = lbl
            end
        end
    end
    for _, name in ipairs(list) do
        local mapped = normToLabel[name] or name
        if not seen[mapped] then
            seen[mapped] = true
            table.insert(result, mapped)
        end
    end
    if #result == 0 then
        table.insert(result, normToLabel["All Bosses"] or "All Bosses")
    end
    return result
end

function BossHunt.formatSeconds(secs)
    local s = math.max(0, math.floor(tonumber(secs) or 0))
    return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

function BossHunt.isWorldBoss(monster)
    if not monster or not monster.Parent then return false end
    if monster:GetAttribute("IsLeader") == true then return false end
    local mId = tostring(monster:GetAttribute("MonsterId") or ""):lower()
    for _, wb in ipairs(BossHunt.worldBosses) do
        if mId == wb.Id then
            return true
        end
    end
    if monster:GetAttribute("IsBoss") == true and monster:GetAttribute("IsMiniBoss") ~= true then
        return true
    end
    local hum = monster:FindFirstChildOfClass("Humanoid")
    local rawNames = {
        monster.Name,
        monster:GetAttribute("DisplayName"),
        monster:GetAttribute("MonsterName"),
        hum and hum.DisplayName,
    }
    for _, raw in ipairs(rawNames) do
        if type(raw) == "string" and raw ~= "" then
            local c = raw:lower()
            for _, wb in ipairs(BossHunt.worldBosses) do
                local wnl = wb.Name:lower()
                if c == wnl or c:find(wnl, 1, true) then
                    return true
                end
            end
        end
    end
    return false
end

function BossHunt.findWorldBossEntry(selectedBoss)
    local sel = BossHunt.normalizeChoice(selectedBoss or Config.SelectedBoss)
    local selLower = sel:lower()
    for _, wb in ipairs(BossHunt.worldBosses) do
        local wnl = wb.Name:lower()
        if selLower == wnl or selLower == wb.Id or selLower:find(wnl, 1, true) or (#selLower >= 5 and wnl:find(selLower, 1, true)) then
            return wb
        end
    end
    return nil
end

function BossHunt.getWorldBossEntries(selectedBoss, level)
    level = tonumber(level) or getPlayerLevel()
    local selList = BossHunt.getSelectionList(selectedBoss)
    local entries, seen = {}, {}
    local onlyWorldKnown = true

    for _, sel in ipairs(selList) do
        if sel == "Pack Leaders Only" then
            onlyWorldKnown = false
        elseif sel == "All Bosses" or sel == "All Bosses + Leaders" then
            local effLevel = math.max(level, 18)
            for i = #BossHunt.worldBosses, 1, -1 do
                local wb = BossHunt.worldBosses[i]
                if wb.MinLevel <= effLevel and not seen[wb.Id] then
                    seen[wb.Id] = true
                    table.insert(entries, wb)
                end
            end
            if #entries == 0 then
                local wb = BossHunt.worldBosses[1]
                seen[wb.Id] = true
                table.insert(entries, wb)
            end
            if sel == "All Bosses + Leaders" then
                onlyWorldKnown = false
            end
        else
            local matched = BossHunt.findWorldBossEntry(sel)
            if matched then
                if not seen[matched.Id] then
                    seen[matched.Id] = true
                    table.insert(entries, matched)
                end
            else
                onlyWorldKnown = false
            end
        end
    end

    if #entries == 0 then
        return nil, false
    end
    return entries, onlyWorldKnown
end

function BossHunt.getWorldBossStatus(entry)
    if not entry or not entry.Id then return nil, nil, false end
    local aliveAttr = workspace:GetAttribute("BossAlive_" .. entry.Id)
    local nextTs = tonumber(workspace:GetAttribute("BossNext_" .. entry.Id))
    local remaining = nil
    if nextTs and nextTs > 0 then
        remaining = math.max(0, nextTs - workspace:GetServerTimeNow())
    end
    return aliveAttr, remaining, (type(aliveAttr) == "boolean")
end

function BossHunt.isMonsterMatchingSingleName(monster, sel)
    if sel == "All Bosses + Leaders" then
        return true
    end
    if sel == "All Bosses" then
        -- In Boss Only mode, "All Bosses" strictly targets Boss Room World Bosses (Boss01-05), never field Pack Leaders!
        if Config and Config.BossOnly then
            return BossHunt.isWorldBoss(monster)
        end
        return true
    end
    if sel == "Pack Leaders Only" then
        if monster:GetAttribute("IsLeader") == true then return true end
        local n = tostring(monster.Name or ""):lower()
        return n:find("leader", 1, true) ~= nil
    end

    local matchedWb = BossHunt.findWorldBossEntry(sel)
    if matchedWb and tostring(monster:GetAttribute("MonsterId") or ""):lower() == matchedWb.Id then
        return true
    end

    local selLower = sel:lower()
    local hum = monster:FindFirstChildOfClass("Humanoid")
    local candidates = {
        monster.Name,
        monster:GetAttribute("DisplayName"),
        monster:GetAttribute("MonsterName"),
        monster:GetAttribute("Name"),
        monster:GetAttribute("MonsterId"),
        hum and hum.DisplayName,
    }
    for _, raw in ipairs(candidates) do
        if type(raw) == "string" and raw ~= "" then
            local c = raw:match("^%s*(.-)%s*$"):lower()
            if c == selLower or c:find(selLower, 1, true) or (#c >= 4 and selLower:find(c, 1, true)) then
                return true
            end
        end
    end
    return false
end

function BossHunt.isMatchingBoss(monster, selectedBoss)
    if not monster or not monster.Parent or not isBossMonster(monster) then
        return false
    end
    local selList = BossHunt.getSelectionList(selectedBoss)
    for _, sel in ipairs(selList) do
        if BossHunt.isMonsterMatchingSingleName(monster, sel) then
            return true
        end
    end
    return false
end

function BossHunt.nearestZoneName(pos)
    if not pos then return nil end
    local bestZone, bestDist = nil, math.huge
    for zName, zPos in pairs(ZoneCoordinates) do
        if zName:find("^Boss") or zName:find("^Field") then
            local d = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(zPos.X, 0, zPos.Z)).Magnitude
            if d < bestDist then
                bestDist = d
                bestZone = zName
            end
        end
    end
    return bestZone
end

function BossHunt.findMatchingBoss(selectedBoss, centerPos, maxDist)
    local folder = workspace:FindFirstChild("Monsters")
    if not folder then return nil, math.huge end
    local limit = maxDist or math.huge
    local refPos = centerPos
    if not refPos then
        local ch = LocalPlayer.Character
        local h = ch and ch:FindFirstChild("HumanoidRootPart")
        refPos = h and h.Position
    end
    local best, bestD = nil, math.huge
    for _, m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") and isMonsterAlive(m) and BossHunt.isMatchingBoss(m, selectedBoss) then
            local mPart = getMonsterCombatPart(m)
            if mPart then
                local d
                if centerPos then
                    d = (Vector3.new(mPart.Position.X, 0, mPart.Position.Z) - Vector3.new(centerPos.X, 0, centerPos.Z)).Magnitude
                elseif refPos then
                    d = (mPart.Position - refPos).Magnitude
                else
                    d = 0
                end
                if d <= limit and d < bestD then
                    bestD = d
                    best = m
                end
            end
        end
    end
    return best, bestD
end

function BossHunt.getInspectionZones(level, selectedBoss)
    level = tonumber(level) or getPlayerLevel()
    local rawSel = selectedBoss
    if rawSel == nil then
        rawSel = (Config.SelectedBosses and #Config.SelectedBosses > 0) and Config.SelectedBosses or Config.SelectedBoss
    end
    local selList = BossHunt.getSelectionList(rawSel)
    local zones, seenZones = {}, {}

    local function addZone(z, name, id)
        if not z or z == "" then return end
        local key = z .. "\0" .. tostring(name or "")
        if seenZones[key] then return end
        seenZones[key] = true
        table.insert(zones, { Zone = z, Name = name, Id = id })
    end

    for _, sel in ipairs(selList) do
        if sel == "All Bosses" or sel == "All Bosses + Leaders" then
            local effLevel = math.max(level, 18)
            for i = #BossHunt.bossZones, 1, -1 do
                local bz = BossHunt.bossZones[i]
                if bz.MinLevel <= effLevel then
                    addZone(bz.Zone, bz.Name, bz.Id)
                end
            end
            if sel == "All Bosses + Leaders" then
                for _, lz in ipairs(BossHunt.leaderZones) do
                    if lz.Level <= (level + 10) then
                        addZone(lz.Zone, lz.Name)
                    end
                end
            end
        elseif sel == "Pack Leaders Only" then
            local higher = {}
            for _, lz in ipairs(BossHunt.leaderZones) do
                if lz.Level <= (level + 10) then
                    addZone(lz.Zone, lz.Name)
                else
                    table.insert(higher, lz)
                end
            end
            for _, h in ipairs(higher) do
                addZone(h.Zone, h.Name)
            end
        else
            if BossHunt.bossZoneMap[sel] then
                local entry = BossHunt.bossZoneMap[sel]
                addZone(entry.Zone, entry.Name, entry.Id)
            else
                local matched = false
                local selLower = sel:lower()
                for name, data in pairs(BossHunt.bossZoneMap) do
                    local nl = name:lower()
                    if selLower:find(nl, 1, true) or nl:find(selLower, 1, true) then
                        addZone(data.Zone, data.Name, data.Id)
                        matched = true
                        break
                    end
                end
                if not matched and BossHunt.dynamicZoneMap[sel] then
                    addZone(BossHunt.dynamicZoneMap[sel], sel)
                end
            end
        end
    end

    if #zones > 0 then
        return zones
    end

    if level >= 98 then
        return { { Zone = "Boss05", Name = "Volcano Turtle King", Id = "bigboss_volcano_turtle_king" } }
    elseif level >= 85 then
        return { { Zone = "Boss04", Name = "Tempest Dragon King", Id = "bigboss_tempest_dragon_king" } }
    elseif level >= 63 then
        return { { Zone = "Boss03", Name = "Obsidian Pharaoh", Id = "bigboss_obsidian_pharaoh" } }
    elseif level >= 39 then
        return { { Zone = "Boss02", Name = "Whitefang Sabertooth", Id = "bigboss_thornback_behemoth" } }
    else
        return { { Zone = "Boss01", Name = "Gorilla King", Id = "terra_colossus" } }
    end
end

function BossHunt.syncBossDropdownVisual(targetVals)
    if not bossDropdown then return end
    BossHunt._updatingDropdown = true
    BossHunt._prevDropdownRaw = targetVals
    pcall(function()
        if bossDropdown.Select then
            bossDropdown:Select(targetVals)
        elseif bossDropdown.SetValue then
            bossDropdown:SetValue(targetVals)
        end
    end)
    BossHunt._updatingDropdown = false
end

function BossHunt.refreshBossDropdown(force)
    if not bossDropdown or not getBossList then return nil end
    local list = getBossList()
    local key = table.concat(list, "\0")
    if not force and BossHunt._lastListKey == key then
        return list
    end
    BossHunt._lastListKey = key
    BossHunt._updatingDropdown = true
    pcall(function()
        if bossDropdown.Refresh then
            bossDropdown:Refresh(list)
        elseif bossDropdown.SetValues then
            bossDropdown:SetValues(list)
        end
    end)
    BossHunt._updatingDropdown = false
    local activeSel = (Config.SelectedBosses and #Config.SelectedBosses > 0) and Config.SelectedBosses or Config.SelectedBoss
    BossHunt.syncBossDropdownVisual(BossHunt.toDropdownValues(activeSel, list))
    return list
end

local function getTargetBossZone(level, selectedBoss)
    local zones = BossHunt.getInspectionZones(level, selectedBoss)
    if zones and zones[1] then
        return zones[1].Zone, zones[1].Name
    end
    return "Boss01", "Gorilla King"
end

function BossHunt.triggerOrDelayBossHop(selected, silent, soonestName, soonestRem)
    if BossHunt.cancelHopRequested then
        return false
    end
    local selSummary = BossHunt.formatSelectionSummary(selected)
    local hopDelay = math.max(0, tonumber(Config.BossHopDelay) or 15)
    local remStr = soonestRem and BossHunt.formatSeconds(soonestRem) or nil
    local now = os.clock()
    local joinUnlockLeft = math.max(0, (BossHunt.hopUnlockAt or ((BossHunt.serverJoinAt or now) + 12.0)) - now)
    local editUnlockLeft = math.max(0, ((BossHunt.lastHopEditAt or 0) + 3.0) - now)
    local guardLeft = math.max(joinUnlockLeft, editUnlockLeft)

    if guardLeft > 0 then
        BossHunt.missingSince = nil
        if (now - (BossHunt.lastDelayNotify or 0)) >= 8 then
            BossHunt.lastDelayNotify = now
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "🛡️ รอความปลอดภัยก่อนย้ายเซิร์ฟ",
                    Content = string.format("รอกันย้ายเซิร์ฟรัวอีก %d วินาที (สามารถกดหยุดหรือปิด Auto Hop ได้ตลอดเวลา)", math.ceil(guardLeft)),
                    Duration = 3,
                    Icon = "shield",
                })
            end
        end
        return false
    end

    if hopDelay <= 0 then
        BossHunt.missingSince = nil
        BossHunt.lastMissingKey = ""
        if WindUI and WindUI.Notify then
            local msg = soonestName and string.format("ไม่พบบอสที่เลือก (%s) [เกิดเร็วสุด: %s อีก %s]\nกำลังย้ายเซิร์ฟเวอร์ทันที!", selSummary, soonestName, remStr or "N/A")
                or string.format("ไม่พบบอส (%s) ในเซิร์ฟนี้ — กำลังย้ายเซิร์ฟเวอร์ทันที!", selSummary)
            WindUI:Notify({
                Title = "🌐 ไม่มีบอส — ย้ายเซิร์ฟทันที",
                Content = msg,
                Duration = 3,
                Icon = "zap",
            })
        end
        BossHunt.serverHopForBoss(selSummary, silent, false)
        return true
    end

    if not BossHunt.missingSince or BossHunt.lastMissingKey ~= selSummary then
        BossHunt.missingSince = now
        BossHunt.lastMissingKey = selSummary
        BossHunt.lastDelayNotify = -999
    end

    local elapsed = now - BossHunt.missingSince
    local waitLeft = math.ceil(math.max(0, hopDelay - elapsed))
    if waitLeft > 0 then
        if (now - (BossHunt.lastDelayNotify or 0)) >= 10 then
            BossHunt.lastDelayNotify = now
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "⏱️ นับถอยหลังก่อนย้ายเซิร์ฟ",
                    Content = string.format("ยังไม่พบบอส (%s) — จะเปลี่ยนเซิร์ฟใน %d วินาที", selSummary, waitLeft),
                    Duration = 3,
                    Icon = "clock",
                })
            end
        end
        return false
    end

    BossHunt.missingSince = nil
    BossHunt.lastMissingKey = ""
    if WindUI and WindUI.Notify then
        WindUI:Notify({
            Title = "🌐 ครบเวลารอ — ย้ายเซิร์ฟทันที",
            Content = string.format("รอครบ %d วินาทีแล้วยังไม่มี (%s)\nกำลังย้ายไปหาเซิร์ฟเวอร์ใหม่!", math.floor(hopDelay), selSummary),
            Duration = 3,
            Icon = "zap",
        })
    end
    BossHunt.serverHopForBoss(selSummary, silent, false)
    return true
end

local function executeBossInspection(silent, forceStart)
    if not isScriptAlive() then return end
    if isInsideDungeon() or isEnteringDungeon or isWaitingForParty then return end
    if isWarpingZone or isSelling or isReturningFromBoss or BossHunt.isServerHopping then return end
    local activeCheckSel = (Config.SelectedBosses and #Config.SelectedBosses > 0) and Config.SelectedBosses or Config.SelectedBoss
    if not forceStart and activeBossFight and activeBossFight.model and isMonsterAlive(activeBossFight.model) and BossHunt.isMatchingBoss(activeBossFight.model, activeCheckSel) then
        return
    end
    if BossHunt.isInspecting and not forceStart then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    BossHunt.inspectToken = BossHunt.inspectToken + 1
    local myToken = BossHunt.inspectToken
    BossHunt.isInspecting = true
    BossHunt.lastCheckTime = os.clock()

    local inBoss = isPlayerInBossArena()
    if not inBoss and Config.CurrentZone and not Config.CurrentZone:find("^Boss") then
        lastNormalFarmZone = Config.CurrentZone
    end

    local selectedList = BossHunt.getSelectionList(Config.SelectedBosses and #Config.SelectedBosses > 0 and Config.SelectedBosses or Config.SelectedBoss)
    local selected = BossHunt.formatSelectionSummary(selectedList)
    Config.SelectedBoss = selected
    local pLevel = getPlayerLevel()

    -- 0. Local arena check FIRST: never leave the current arena/zone if an alive matching boss is already here!
    local localBoss = BossHunt.findMatchingBoss(selectedList, hrp.Position, 260)
    if localBoss then
        BossHunt.missingSince = nil
        local mPart = getMonsterCombatPart(localBoss)
        activeBossFight = {
            model = localBoss,
            name = localBoss.Name,
            pos = (mPart and mPart.Position) or hrp.Position,
            time = os.clock(),
        }
        currentCombatTarget = localBoss
        trackBossDeath(localBoss)
        BossHunt.isInspecting = false
        BossHunt.lastCheckTime = os.clock()
        return
    end

    -- 1. Fast global check: if a matching boss model is ALREADY spawned & loaded elsewhere, travel/engage immediately!
    local liveGlobal = BossHunt.findMatchingBoss(selectedList, nil, math.huge)
    if liveGlobal then
        BossHunt.missingSince = nil
        local mPart = getMonsterCombatPart(liveGlobal)
        local mPos = mPart and mPart.Position
        local flatDist = mPos and (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(mPos.X, 0, mPos.Z)).Magnitude or 0
        if mPos and flatDist > 160 then
            local wbMatch = BossHunt.findWorldBossEntry(liveGlobal.Name)
            local nearZone = (wbMatch and wbMatch.Zone) or BossHunt.nearestZoneName(mPos) or getTargetBossZone(pLevel, selected)
            isCheckingBossArena = true
            if not silent and WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "👑 World Boss Found",
                    Content = string.format("พบบอส %s! กำลังเดินทางไปที่ %s", liveGlobal.Name, tostring(nearZone)),
                    Duration = 3,
                    Icon = "swords",
                })
            end
            travelToZone(nearZone, liveGlobal.Name, true)
            isCheckingBossArena = false
        end
        if BossHunt.inspectToken == myToken and isMonsterAlive(liveGlobal) then
            activeBossFight = {
                model = liveGlobal,
                name = liveGlobal.Name,
                pos = (getMonsterCombatPart(liveGlobal) and getMonsterCombatPart(liveGlobal).Position) or mPos,
                time = os.clock(),
            }
            currentCombatTarget = liveGlobal
            trackBossDeath(liveGlobal)
        end
        BossHunt.isInspecting = false
        BossHunt.lastCheckTime = os.clock()
        return
    end

    -- 2. Replicated World Boss attribute pre-check (workspace BossAlive_<id> & BossNext_<id>)
    -- Avoids blindly visiting 5 empty boss arenas under StreamingEnabled & enables instant Server Hop!
    local wbEntries, isWorldTarget = BossHunt.getWorldBossEntries(selected, pLevel)
    local zones = nil

    if isWorldTarget and wbEntries and #wbEntries > 0 then
        local aliveList, deadList, unknownList = {}, {}, {}
        for _, wb in ipairs(wbEntries) do
            local aliveAttr, remSecs, known = BossHunt.getWorldBossStatus(wb)
            if not known then
                table.insert(unknownList, wb)
            elseif aliveAttr == true then
                table.insert(aliveList, wb)
            else
                table.insert(deadList, { entry = wb, rem = remSecs or math.huge })
            end
        end

        if #aliveList > 0 then
            BossHunt.missingSince = nil
            zones = {}
            for _, wb in ipairs(aliveList) do
                table.insert(zones, { Zone = wb.Zone, Name = wb.Name, Id = wb.Id })
            end
        elseif #unknownList > 0 then
            zones = BossHunt.getInspectionZones(pLevel, selectedList)
        else
            -- ALL matching World Bosses confirmed dead on this server!
            table.sort(deadList, function(a, b) return a.rem < b.rem end)
            local soonest = deadList[1] and deadList[1].entry or wbEntries[1]
            local soonestRem = deadList[1] and deadList[1].rem

            if Config.BossServerHop then
                BossHunt.isInspecting = false
                BossHunt.lastCheckTime = os.clock()
                BossHunt.triggerOrDelayBossHop(selectedList, silent, soonest and soonest.Name, soonestRem)
                return
            elseif Config.BossOnly then
                local waitEntry = (#wbEntries == 1) and wbEntries[1] or soonest
                local remVal = nil
                for _, dl in ipairs(deadList) do
                    if dl.entry.Id == waitEntry.Id then remVal = dl.rem; break end
                end
                local waitZonePos = getZonePosition(waitEntry.Zone)
                local distXZ = waitZonePos and (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(waitZonePos.X, 0, waitZonePos.Z)).Magnitude or math.huge
                local nowT = os.clock()

                if distXZ > 95 then
                    BossHunt.inspectToken = myToken
                    task.spawn(function()
                        if not isScriptAlive() or BossHunt.inspectToken ~= myToken then return end
                        isCheckingBossArena = true
                        if WindUI and WindUI.Notify then
                            WindUI:Notify({
                                Title = "👑 ไปห้องบอสรอดักเกิด",
                                Content = string.format("กำลังเดินทางไป %s (%s) — เกิดอีก %s", waitEntry.Name, waitEntry.Zone, remVal and BossHunt.formatSeconds(remVal) or "N/A"),
                                Duration = 3,
                                Icon = "clock",
                            })
                        end
                        travelToZone(waitEntry.Zone, waitEntry.Name .. " Zone", true)
                        isCheckingBossArena = false
                        BossHunt.isInspecting = false
                        BossHunt.lastCheckTime = os.clock()
                        BossHunt.lastStayZone = waitEntry.Zone
                        BossHunt.lastStayNotify = os.clock()
                    end)
                    return
                end

                if (not silent or forceStart) or (nowT - BossHunt.lastStayNotify) >= 25 or BossHunt.lastStayZone ~= waitEntry.Zone then
                    BossHunt.lastStayNotify = nowT
                    BossHunt.lastStayZone = waitEntry.Zone
                    if WindUI and WindUI.Notify then
                        WindUI:Notify({
                            Title = "⏳ รอดักเกิดในห้องบอส",
                            Content = string.format("กำลังรอ %s (%s) — เกิดอีก %s", waitEntry.Name, waitEntry.Zone, remVal and BossHunt.formatSeconds(remVal) or "N/A"),
                            Duration = 3,
                            Icon = "clock",
                        })
                    end
                end
                BossHunt.isInspecting = false
                BossHunt.lastCheckTime = os.clock()
                return
            else
                -- AutoBoss + AutoWarpToBoss (BossOnly OFF): stay out of empty Boss Rooms
                if not silent and WindUI and WindUI.Notify then
                    WindUI:Notify({
                        Title = "บอสยังไม่เกิด (Cooldown)",
                        Content = string.format("บอสที่เลือก (%s) กำลังคูลดาวน์ (เร็วสุด %s อีก %s)", selected, soonest.Name, soonestRem and BossHunt.formatSeconds(soonestRem) or "N/A"),
                        Duration = 2.5,
                        Icon = "clock",
                    })
                end
                if isPlayerInBossArena() then
                    BossHunt.inspectToken = myToken
                    task.spawn(function()
                        if not isScriptAlive() or BossHunt.inspectToken ~= myToken then return end
                        local targetField, fieldName = getReturnField()
                        travelToZone(targetField, fieldName)
                        BossHunt.isInspecting = false
                        BossHunt.lastCheckTime = os.clock()
                    end)
                    return
                end
                BossHunt.isInspecting = false
                BossHunt.lastCheckTime = os.clock()
                return
            end
        end
    end

    zones = zones or BossHunt.getInspectionZones(pLevel, selected)
    if not zones or #zones == 0 then
        BossHunt.isInspecting = false
        return
    end

    isCheckingBossArena = true

    task.spawn(function()
        local foundBoss = nil
        local aborted = false

        local function shouldAbort()
            if not isScriptAlive() or BossHunt.inspectToken ~= myToken then return true end
            if isInsideDungeon() or isEnteringDungeon or isWaitingForParty or BossHunt.isServerHopping then return true end
            if not forceStart and not (Config.BossOnly or Config.BossServerHop or Config.AutoBoss) then return true end
            return false
        end

        local okRun, runErr = pcall(function()
            for idx, targetInfo in ipairs(zones) do
                if shouldAbort() then aborted = true; break end

                local bZone = targetInfo.Zone
                local bName = targetInfo.Name or selected
                local bPos = getZonePosition(bZone)
                local curChar = LocalPlayer.Character
                local curHrp = curChar and curChar:FindFirstChild("HumanoidRootPart")
                local curHum = curChar and curChar:FindFirstChildOfClass("Humanoid")
                if not curHrp or not curHum or curHum.Health <= 0 then
                    aborted = true
                    break
                end

                local distXZ = bPos and (Vector3.new(curHrp.Position.X, 0, curHrp.Position.Z) - Vector3.new(bPos.X, 0, bPos.Z)).Magnitude or math.huge
                local alreadyNear = (distXZ <= 95)

                if not alreadyNear then
                    if (not silent or forceStart or idx == 1) and WindUI and WindUI.Notify then
                        WindUI:Notify({
                            Title = "👑 Boss Hunter",
                            Content = string.format("กำลังเดินทางไปหาบอส: %s (%s)", bName, bZone),
                            Duration = 2.5,
                            Icon = "swords",
                        })
                    end
                    travelToZone(bZone, bName .. " Zone", forceStart == true or Config.BossOnly == true or Config.BossServerHop == true)
                end

                if shouldAbort() then aborted = true; break end

                -- Poll while chunks & monsters stream in (returns the instant matching boss appears)
                local zoneRadius = bZone:find("^Boss") and 175 or 270
                local waitSecs = alreadyNear and 1.2 or ((#zones == 1) and 4.5 or 3.0)
                local deadline = os.clock() + waitSecs

                while os.clock() <= deadline do
                    if shouldAbort() then aborted = true; break end
                    foundBoss = BossHunt.findMatchingBoss(selectedList, bPos, zoneRadius)
                    if not foundBoss and #zones == 1 then
                        foundBoss = BossHunt.findMatchingBoss(selectedList, nil, math.huge)
                    end
                    if foundBoss then break end
                    task.wait(0.25)
                end

                if aborted or foundBoss then break end
            end
        end)

        if not okRun then
            warn("[BossInspect Error]:", runErr)
        end

        isCheckingBossArena = false
        BossHunt.isInspecting = false
        BossHunt.lastCheckTime = os.clock()

        if aborted or BossHunt.inspectToken ~= myToken or not isScriptAlive() then
            return
        end

        if foundBoss and isMonsterAlive(foundBoss) then
            BossHunt.missingSince = nil
            BossHunt.lastMissingKey = ""
            local mPart = getMonsterCombatPart(foundBoss)
            activeBossFight = {
                model = foundBoss,
                name = foundBoss.Name,
                pos = mPart and mPart.Position,
                time = os.clock(),
            }
            currentCombatTarget = foundBoss
            trackBossDeath(foundBoss)
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "⚔️ เจอบอสแล้ว!",
                    Content = string.format("กำลังเข้าโจมตี: %s", foundBoss.Name),
                    Duration = 3,
                    Icon = "skull",
                })
            end
            return
        end

        -- No matching boss alive across inspected zone(s)
        if Config.BossServerHop then
            BossHunt.triggerOrDelayBossHop(selectedList, silent, nil, nil)
        elseif Config.BossOnly then
            -- Stay patiently at the selected boss's zone without touching trash mobs or turning off BossOnly!
            local campZone = zones[1] and zones[1].Zone or "Boss"
            local campName = zones[1] and zones[1].Name or selected
            local nowT = os.clock()
            if (not silent or forceStart) and ((nowT - BossHunt.lastStayNotify) >= 20 or BossHunt.lastStayZone ~= campZone) then
                BossHunt.lastStayNotify = nowT
                BossHunt.lastStayZone = campZone
                if WindUI and WindUI.Notify then
                    WindUI:Notify({
                        Title = "⏳ รอดักเกิดเฉพาะบอส",
                        Content = string.format("ยังไม่พบ %s (%s) — ยืนรอดักตีเฉพาะบอสที่โซนนี้", campName, campZone),
                        Duration = 3,
                        Icon = "clock",
                    })
                end
            end
        else
            -- Normal AutoBoss + AutoWarpToBoss (BossOnly OFF): return to farm field until next check
            if not silent and WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "บอสยังไม่เกิด (Cooldown)",
                    Content = "ยังไม่พบบอสในห้อง กำลังกลับไปฟาร์มมอนสเตอร์ปกติ...",
                    Duration = 2.5,
                    Icon = "clock",
                })
            end
            task.wait(0.6)
            if BossHunt.inspectToken == myToken and not isInsideDungeon() and not Config.BossOnly then
                local targetField, fieldName = getReturnField()
                travelToZone(targetField, fieldName)
            end
        end
    end)
end

local function handlePostBossReturn(bossName, deathPos)
    if isInsideDungeon() or isReturningFromBoss then return end
    isReturningFromBoss = true
    activeBossFight = nil
    currentCombatTarget = nil

    task.spawn(function()
        local shouldBossHopNow = false
        local bName = tostring(bossName or "Boss")

        local success, err = pcall(function()
            -- 1. Notify player
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "🏆 Boss Defeated!",
                    Content = "กำจัด " .. bName .. " สำเร็จ!\nกำลังดูดเก็บไอเทมดรอป" .. ((Config.BossServerHop and "และเตรียมย้ายเซิร์ฟหาบอสต่อ...") or ((Config.BossOnly and "และยืนรอ/ล่าบอสต่อ...") or "และเตรียมกลับไปฟาร์มมอนปกติ...")),
                    Duration = 2.5,
                    Icon = "trophy",
                })
            end

            -- 2. Fast stealth loot vacuum around boss death area (ensures drops/eggs aren't lost before hop/warp)
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local dropsFolder = workspace:FindFirstChild("Drops")

            for sweep = 1, 3 do
                if dropsFolder and hrp and hrp.Parent then
                    for _, d in ipairs(dropsFolder:GetChildren()) do
                        local dp = d:IsA("BasePart") and d or (d:IsA("Model") and (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart", true)))
                        if dp and dp.Parent then
                            local dDist = (dp.Position - hrp.Position).Magnitude
                            if dDist <= (Config.LootRadius or 120) then
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
                task.wait(0.25)
            end

            if Config.AutoLoot and performAutoLoot then
                pcall(performAutoLoot)
                task.wait(0.25)
            end

            BossHunt.missingSince = nil
            BossHunt.lastMissingKey = ""
            local selectedList = BossHunt.getSelectionList(Config.SelectedBosses and #Config.SelectedBosses > 0 and Config.SelectedBosses or Config.SelectedBoss)

            if Config.BossOnly then
                -- CRITICAL: NEVER reset Config.BossOnly = false and NEVER warp back to Field13 while BossOnly is active!
                local anotherAlive = BossHunt.findMatchingBoss(selectedList, hrp and hrp.Position or deathPos, 260)
                if anotherAlive then
                    activeBossFight = {
                        model = anotherAlive,
                        name = anotherAlive.Name,
                        pos = getMonsterCombatPart(anotherAlive) and getMonsterCombatPart(anotherAlive).Position,
                        time = os.clock(),
                    }
                    currentCombatTarget = anotherAlive
                    trackBossDeath(anotherAlive)
                else
                    local wbEntries, isWorldTarget = BossHunt.getWorldBossEntries(selectedList, getPlayerLevel())
                    local hasOtherWorldAlive = false
                    if isWorldTarget and wbEntries then
                        for _, wb in ipairs(wbEntries) do
                            if workspace:GetAttribute("BossAlive_" .. wb.Id) == true then
                                hasOtherWorldAlive = true
                                break
                            end
                        end
                    end

                    if hasOtherWorldAlive then
                        BossHunt.lastCheckTime = -999
                        task.delay(0.55, function()
                            if isScriptAlive() and Config.BossOnly and not BossHunt.isServerHopping and not isInsideDungeon() then
                                executeBossInspection(false, true)
                            end
                        end)
                    elseif Config.BossServerHop then
                        if not isWorldTarget then
                            task.wait(0.5)
                        end
                        local globalAlive = BossHunt.findMatchingBoss(selectedList, nil, math.huge)
                        if not globalAlive then
                            shouldBossHopNow = true
                        end
                    end
                end
                return
            end

            -- Non-BossOnly mode: Reset combat flags if AutoReturn is on
            if Config.AutoBoss and Config.ReturnToProgressionAfterBoss and not Config.BossServerHop then
                Config.AutoFarm = true
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
                    if BossHunt and BossHunt.refreshBossDropdown then
                        BossHunt.refreshBossDropdown()
                    end
                end)
            end

            if Config.BossServerHop then
                local wbEntries, isWorldTarget = BossHunt.getWorldBossEntries(selectedList, getPlayerLevel())
                local hasOtherWorldAlive = false
                if isWorldTarget and wbEntries then
                    for _, wb in ipairs(wbEntries) do
                        if workspace:GetAttribute("BossAlive_" .. wb.Id) == true then
                            hasOtherWorldAlive = true
                            break
                        end
                    end
                end
                local anotherAlive = BossHunt.findMatchingBoss(selectedList, nil, math.huge)
                if anotherAlive or hasOtherWorldAlive then
                    BossHunt.lastCheckTime = -999
                    task.delay(0.55, function()
                        if isScriptAlive() and Config.BossServerHop and not BossHunt.isServerHopping and not isInsideDungeon() then
                            executeBossInspection(false, true)
                        end
                    end)
                    return
                end
                shouldBossHopNow = true
                return
            end

            local inBoss = isPlayerInBossArena()
            if inBoss then
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
                if Config.CurrentZone and Config.CurrentZone:find("^Boss") then
                    local targetField = getReturnField()
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

        task.wait(0.4)
        activeBossFight = nil
        isReturningFromBoss = false
        BossHunt.lastCheckTime = os.clock()

        if shouldBossHopNow and Config.BossServerHop and not isInsideDungeon() then
            local activeSel = BossHunt.getSelectionList(Config.SelectedBosses and #Config.SelectedBosses > 0 and Config.SelectedBosses or Config.SelectedBoss)
            BossHunt.triggerOrDelayBossHop(activeSel, false, nil, nil)
        end
    end)
end

trackBossDeath = function(boss)
    if not boss or not boss:IsA("Model") or BossHunt.trackedDeaths[boss] then return end
    BossHunt.trackedDeaths[boss] = true

    local hum = boss:FindFirstChildOfClass("Humanoid")
    local bName = boss.Name
    local bPart = getMonsterCombatPart(boss)
    local bPos = bPart and bPart.Position

    local function onDead()
        if not isReturningFromBoss and (activeBossFight == nil or activeBossFight.model == boss or isBossMonster(boss)) then
            local p = getMonsterCombatPart(boss)
            local pos = (p and p.Position) or bPos
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
    -- Never override Boss Only / active Boss Server Hop with Auto Lv.99 normal field warping!
    if not Config.AutoProgression and not force then return end
    if (Config.BossOnly or Config.BossServerHop) and not force then return end
    if isCheckingBossArena or BossHunt.isInspecting or BossHunt.isServerHopping then return end
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
        local aliveBoss = isAnyBossAliveInArena(bossZoneName, Config.SelectedBoss)
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

-- ==================== LOW-PLAYER & BOSS SERVER HOP SYSTEM ====================
do
    local HISTORY_FILE = "HuntingTogether_BossHopHistory.json"

    function BossHunt.loadHopHistory()
        local out = {}
        pcall(function()
            if isfile and readfile and isfile(HISTORY_FILE) then
                local raw = readfile(HISTORY_FILE)
                local dec = raw and #raw > 0 and HttpService:JSONDecode(raw)
                if type(dec) == "table" then
                    local nowEpoch = os.time()
                    for jId, ts in pairs(dec) do
                        if type(jId) == "string" and type(ts) == "number" and (nowEpoch - ts) <= 120 then
                            out[jId] = ts
                        end
                    end
                end
            end
        end)
        return out
    end

    function BossHunt.recordVisitedServer(jobId)
        if not jobId or jobId == "" then return end
        pcall(function()
            local hist = BossHunt.loadHopHistory()
            hist[tostring(jobId)] = os.time()
            -- Cap stored history to avoid unbounded file growth
            local keys = {}
            for k, v in pairs(hist) do
                table.insert(keys, { k = k, v = v })
            end
            if #keys > 30 then
                table.sort(keys, function(a, b) return a.v > b.v end)
                local trimmed = {}
                for i = 1, 25 do
                    trimmed[keys[i].k] = keys[i].v
                end
                hist = trimmed
            end
            if writefile then
                writefile(HISTORY_FILE, HttpService:JSONEncode(hist))
            end
        end)
    end

    local TeleportService = game:GetService("TeleportService")
function BossHunt.getHopSessionPath()
    return "HuntingTogether_HopSession_" .. tostring(LocalPlayer.UserId) .. ".json"
end

function BossHunt.markHopSession()
    if type(writefile) ~= "function" then return end
    local payloadOk, payload = pcall(HttpService.JSONEncode, HttpService, {
        ts = os.time(),
        job = tostring(game.JobId or ""),
    })
    if payloadOk and type(payload) == "string" then
        pcall(writefile, BossHunt.getHopSessionPath(), payload)
    end
end

function BossHunt.clearHopSession()
    local path = BossHunt.getHopSessionPath()
    if type(delfile) == "function" then
        local exists = (type(isfile) ~= "function") or (pcall(isfile, path) and isfile(path))
        if exists then
            pcall(delfile, path)
        end
    elseif type(writefile) == "function" then
        pcall(writefile, path, "{}")
    end
end

function BossHunt.stopAllHops(resetUnsafeDelay)
    Config.BossServerHop = false
    Config.BossTimedHop = false
    Config.ServerHopAuto = false
    BossHunt.cancelHopRequested = true
    BossHunt.isServerHopping = false
    BossHunt.missingSince = nil
    BossHunt.lastMissingKey = ""
    BossHunt.bossTimedHopNextTick = 0
    BossHunt.serverHopNextTick = 0
    BossHunt.hopFailCount = 0
    BossHunt.clearHopSession()
    if resetUnsafeDelay and (tonumber(Config.BossHopDelay) or 0) < 10 then
        Config.BossHopDelay = 15
        local slider = BossHunt.uiRefs and BossHunt.uiRefs.bossHopDelaySlider
        if slider then
            if slider.SetValue then pcall(slider.SetValue, slider, 15)
            elseif slider.Set then pcall(slider.Set, slider, 15) end
        end
    end
    local function setOff(t)
        if not t then return end
        if t.SetValue then pcall(t.SetValue, t, false)
        elseif t.Set then pcall(t.Set, t, false) end
    end
    if BossHunt.uiRefs then
        setOff(BossHunt.uiRefs.bossHopToggle)
        setOff(BossHunt.uiRefs.bossTimedHopToggle)
        setOff(BossHunt.uiRefs.autoServerHopToggle)
    end
    if Config.AutoSave then SaveConfig(true) end
end

    trackConn(TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
        if player ~= LocalPlayer then return end
        BossHunt.isServerHopping = false
        BossHunt.clearHopSession()
        BossHunt.hopFailCount = (BossHunt.hopFailCount or 0) + 1
        if BossHunt.lastHopJobId then
            BossHunt.lastFailedJobId = BossHunt.lastHopJobId
            BossHunt.recordVisitedServer(BossHunt.lastHopJobId)
            BossHunt.lastHopJobId = nil
        end
        if BossHunt.cancelHopRequested or BossHunt.hopFailCount >= 2 then
            BossHunt.stopAllHops(false)
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "Teleport Failed (Auto Hop Paused)",
                    Content = "ย้ายเซิร์ฟล้มเหลว (" .. tostring(teleportResult) .. ") ระบบหยุด Auto Server Hop อัตโนมัติแล้ว",
                    Duration = 4,
                    Icon = "shield-alert",
                })
            end
            return
        end
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "Teleport Failed",
                Content = "ย้ายเซิร์ฟไม่สำเร็จ (" .. tostring(teleportResult) .. ") กำลังลองหาเซิร์ฟใหม่...",
                Duration = 3,
                Icon = "alert-circle",
            })
        end
        if isScriptAlive() and not BossHunt.cancelHopRequested and (Config.BossServerHop or Config.BossTimedHop or Config.ServerHopAuto) and not isInsideDungeon() then
            task.delay(3.0, function()
                if isScriptAlive() and not BossHunt.cancelHopRequested and not BossHunt.isServerHopping and not isInsideDungeon() then
                    if Config.BossServerHop or Config.BossTimedHop then
                        local activeSel = BossHunt.getSelectionList(Config.SelectedBosses and #Config.SelectedBosses > 0 and Config.SelectedBosses or Config.SelectedBoss)
                        BossHunt.serverHopForBoss(activeSel, false, false)
                    elseif Config.ServerHopAuto then
                        BossHunt.serverHop({ silent = true, forBoss = false, manual = false })
                    end
                end
            end)
        end
    end))
end

function BossHunt.serverHop(opts)
    opts = opts or {}
    local silent = opts.silent == true
    local forBoss = opts.forBoss == true
    local manual = opts.manual == true
    local rawReason = opts.reasonBoss
    if rawReason == nil then
        rawReason = (Config.SelectedBosses and #Config.SelectedBosses > 0) and Config.SelectedBosses or Config.SelectedBoss
    end
    local reasonBoss = BossHunt.formatSelectionSummary(rawReason)

    if not manual then
        if BossHunt.cancelHopRequested then return end
        local now = os.clock()
        if forBoss and (now < (BossHunt.hopUnlockAt or 0) or (now - (BossHunt.lastHopEditAt or 0)) < 3.0) then
            return
        end
    else
        BossHunt.cancelHopRequested = false
    end

    if isInsideDungeon() or isEnteringDungeon or isWaitingForParty then
        if not silent and WindUI and WindUI.Notify then
            WindUI:Notify({ Title = "Server Hop", Content = "กำลังสร้างห้องหรืออยู่ในดันเจี้ยน ปิดการย้ายเซิร์ฟเวอร์ชั่วคราว", Duration = 2.5, Icon = "clock" })
        end
        return
    end
    if BossHunt.isServerHopping then
        if (os.clock() - (BossHunt.hopStartedAt or 0)) < 18 then
            if not silent and WindUI and WindUI.Notify then
                WindUI:Notify({ Title = "Server Hop", Content = "กำลังอยู่ระหว่างการย้ายเซิร์ฟเวอร์ กรุณารอสักครู่...", Duration = 2.5, Icon = "clock" })
            end
            return
        end
        BossHunt.isServerHopping = false
    end

    BossHunt.isServerHopping = true
    BossHunt.hopStartedAt = os.clock()
    BossHunt.inspectToken = (BossHunt.inspectToken or 0) + 1
    BossHunt.isInspecting = false
    isCheckingBossArena = false

    -- Save current config so BossOnly / SelectedBoss / BossServerHop / AutoFarm carry over seamlessly
    if Config.AutoSave then
        SaveConfig(true)
    end
    pcall(function() registerQueueOnTeleport(true) end)

    if not silent and WindUI and WindUI.Notify then
        WindUI:Notify({
            Title = forBoss and ("👑 Boss Server Hop") or "Server Hop",
            Content = forBoss and string.format("กำลังค้นหาเซิร์ฟเวอร์ใหม่เพื่อล่าบอส: %s...", reasonBoss) or "กำลังค้นหาเซิร์ฟเวอร์ที่มีผู้เล่นน้อยที่สุด...",
            Duration = 3,
            Icon = "search"
        })
    end

    task.spawn(function()
        local placeId = game.PlaceId
        local curJob = tostring(game.JobId or "")
        BossHunt.recordVisitedServer(curJob)
        local history = BossHunt.loadHopHistory()

        local freshCandidates = {}
        local fallbackCandidates = {}

        local function scanServers()
            local cursor = ""
            freshCandidates = {}
            fallbackCandidates = {}
            for page = 1, 3 do
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
                            local sId = tostring(s.id or "")
                            if sId ~= "" and sId ~= curJob and s.playing and s.maxPlayers and s.playing < s.maxPlayers and s.playing > 0 then
                                if sId ~= BossHunt.lastFailedJobId then
                                    table.insert(fallbackCandidates, s)
                                    if not history[sId] then
                                        table.insert(freshCandidates, s)
                                    end
                                end
                            end
                        end
                        cursor = data.nextPageCursor or ""
                    else
                        cursor = ""
                    end
                else
                    cursor = ""
                end
                if #freshCandidates >= 15 or cursor == "" then
                    break
                end
            end
        end

        scanServers()
        if #freshCandidates == 0 and #fallbackCandidates == 0 then
            -- Brief retry in case Roblox server list API returned transient 429 rate-limit
            task.wait(2.2)
            if not isScriptAlive() or isInsideDungeon() then
                BossHunt.isServerHopping = false
                return
            end
            scanServers()
        end

        local poolList = (#freshCandidates > 0) and freshCandidates or fallbackCandidates
        if #poolList == 0 then
            BossHunt.isServerHopping = false
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "Server Hop",
                    Content = "ไม่พบเซิร์ฟเวอร์ว่างอื่นในขณะนี้ (หรือ API ติดจำกัดชั่วคราว) จะลองใหม่อัตโนมัติ...",
                    Duration = 3.5,
                    Icon = "alert-triangle"
                })
            end
            return
        end

        -- Sort ascending: lowest players first, then lowest ping
        table.sort(poolList, function(a, b)
            if a.playing ~= b.playing then
                return a.playing < b.playing
            end
            return (a.ping or 999) < (b.ping or 999)
        end)

        -- Pick randomly among top 4 lowest-player servers to avoid colliding
        local pickPool = math.min(4, #poolList)
        local targetServer = poolList[math.random(1, pickPool)]
        BossHunt.lastHopJobId = tostring(targetServer.id)
        BossHunt.recordVisitedServer(targetServer.id)

        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = forBoss and "👑 พบเซิร์ฟเวอร์ใหม่แล้ว!" or "Server Hop Found!",
                Content = string.format("เป้าหมาย: คนเล่น %d/%d คน (Ping: %s)\nกำลังย้ายใน %s วิ (ปิด Auto Hop เพื่อยกเลิกได้)...", targetServer.playing, targetServer.maxPlayers, tostring(targetServer.ping or "N/A"), manual and "0.45" or "1.2"),
                Duration = 3.5,
                Icon = "zap"
            })
        end

        task.wait(manual and 0.45 or 1.2)
        if not isScriptAlive() or BossHunt.cancelHopRequested or (not manual and forBoss and not Config.BossServerHop and not Config.BossTimedHop) or (not manual and not forBoss and not Config.ServerHopAuto) then
            BossHunt.isServerHopping = false
            return
        end

        BossHunt.hopFailCount = 0
        BossHunt.markHopSession()
        if Config.AutoSave then SaveConfig(true) end
        pcall(function() registerQueueOnTeleport(true) end)
        pcall(function() setClientCurrentTarget(nil) end)

        local TeleportService = game:GetService("TeleportService")
        local tpOk, tpErr = pcall(function()
            TeleportService:TeleportToPlaceInstance(placeId, targetServer.id, LocalPlayer)
        end)

        if not tpOk then
            BossHunt.isServerHopping = false
            BossHunt.clearHopSession()
            BossHunt.lastFailedJobId = tostring(targetServer.id)
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

function BossHunt.serverHopForBoss(reasonBoss, silent, manual)
    local rawReason = reasonBoss
    if rawReason == nil then
        rawReason = (Config.SelectedBosses and #Config.SelectedBosses > 0) and Config.SelectedBosses or Config.SelectedBoss
    end
    BossHunt.serverHop({
        silent = (silent == true),
        forBoss = true,
        manual = (manual == true),
        reasonBoss = BossHunt.formatSelectionSummary(rawReason),
    })
end

local function serverHopLowPlayer(silent, manual)
    BossHunt.serverHop({ silent = (silent == true), forBoss = false, manual = (manual == true) })
end

local function rejoinCurrentServer()
    if WindUI and WindUI.Notify then
        WindUI:Notify({ Title = "Rejoining", Content = "กำลังรีจอยน์เซิร์ฟเวอร์เดิม...", Duration = 3, Icon = "rotate-cw" })
    end
    if Config.AutoSave then SaveConfig(true) end
    pcall(function() registerQueueOnTeleport(true) end)
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
        local now = os.clock()
        if Config.BossTimedHop then
            local intervalSecs = math.max(60, (tonumber(Config.BossTimedHopMinutes) or 5) * 60)
            if (BossHunt.bossTimedHopNextTick or 0) == 0 then
                BossHunt.bossTimedHopNextTick = now + intervalSecs
            end
            if now >= BossHunt.bossTimedHopNextTick then
                if activeBossFight and activeBossFight.model and isMonsterAlive(activeBossFight.model) then
                    -- Wait for ongoing boss fight to finish before hopping
                    BossHunt.bossTimedHopNextTick = now + 5
                else
                    BossHunt.bossTimedHopNextTick = now + intervalSecs
                    local activeSel = BossHunt.getSelectionList(Config.SelectedBosses and #Config.SelectedBosses > 0 and Config.SelectedBosses or Config.SelectedBoss)
                    local selSummary = BossHunt.formatSelectionSummary(activeSel)
                    print(string.format("[Boss Timed Hop] ⏰ Interval reached (%d mins). Hopping for: %s", tonumber(Config.BossTimedHopMinutes) or 5, selSummary))
                    if WindUI and WindUI.Notify then
                        WindUI:Notify({
                            Title = "⏰ ครบเวลาตั้งไว้ — ย้ายเซิร์ฟหาบอส",
                            Content = string.format("ครบ %d นาทีแล้ว กำลังเปลี่ยนเซิร์ฟเวอร์หา (%s)", math.floor(tonumber(Config.BossTimedHopMinutes) or 5), selSummary),
                            Duration = 3,
                            Icon = "clock",
                        })
                    end
                    BossHunt.serverHopForBoss(activeSel, false)
                end
            end
        else
            BossHunt.bossTimedHopNextTick = 0
        end

        if Config.ServerHopAuto then
            local intervalSecs = math.max(60, (tonumber(Config.ServerHopInterval) or 15) * 60)
            if BossHunt.serverHopNextTick == 0 then
                BossHunt.serverHopNextTick = now + intervalSecs
            end
            if now >= BossHunt.serverHopNextTick then
                BossHunt.serverHopNextTick = now + intervalSecs
                print(string.format("[Server Hop] ⏰ Interval reached (%d mins). Hopping to low-player server...", tonumber(Config.ServerHopInterval) or 15))
                serverHopLowPlayer(false)
            end
        else
            BossHunt.serverHopNextTick = 0
        end
    end
end)

-- ==================== SMART SKILLS & COMBAT ENGINE ====================
local SkillState = {
    skillLastCast = {},
    cachedHotbarSkills = {},
    lastGlobalSkillCast = 0,
    lastCombatLootScan = 0,
    lastHotbarUpdate = 0,
    nativeSlotTrigger = nil,
}
local evaluateAndCastBestSkill = nil

local function getNativeSlotTrigger()
    if SkillState.nativeSlotTrigger then return SkillState.nativeSlotTrigger end
    pcall(function()
        local ap = LocalPlayer.PlayerGui:FindFirstChild("LumiHotbar")
        local pad = ap and ap:FindFirstChild("ActionPad")
        local slot1 = pad and pad:FindFirstChild("Slot1")
        if slot1 and typeof(getconnections) == "function" then
            for _, conn in ipairs(getconnections(slot1.MouseButton1Click)) do
                if conn.Function and typeof(debug.getupvalues) == "function" then
                    local ups = debug.getupvalues(conn.Function)
                    if type(ups[2]) == "function" then
                        SkillState.nativeSlotTrigger = ups[2]
                        return
                    end
                end
            end
        end
    end)
    return SkillState.nativeSlotTrigger
end

local function isSlotSelected(slotNum)
    local cfg = Config.SelectedSkillSlots
    if not cfg or type(cfg) ~= "table" then return true end

    local hasAny = false
    for _ in pairs(cfg) do
        hasAny = true
        break
    end
    -- If empty, default to TRUE so all equipped hotbar skills are used
    if not hasAny then return true end

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

local function updateHotbarCache()
    local now = os.clock()
    if (now - SkillState.lastHotbarUpdate) < 0.3 then return end
    SkillState.lastHotbarUpdate = now

    local hotbarRaw = LocalPlayer:GetAttribute("HotbarJson")
    local hotbar = nil
    if hotbarRaw and hotbarRaw ~= "" then
        pcall(function() hotbar = HttpService:JSONDecode(hotbarRaw) end)
    end

    local ap = LocalPlayer.PlayerGui:FindFirstChild("LumiHotbar")
    local pad = ap and ap:FindFirstChild("ActionPad")

    local buffNames = {
        meikyo = true, vanish = true, stealth = true, haste = true,
        blessing = true, increase_agi = true, endure = true, catbrew = true,
        divineprotection = true, holyguard = true, overthrust = true,
        spiritinstinct = true, zanshin = true, ironbody = true
    }

    for slotNum = 1, 8 do
        local sId = nil
        if hotbar then
            local item = hotbar[tostring(slotNum)]
            if type(item) == "string" and item:find("^skill:") then
                sId = item:sub(7):lower()
            end
        end

        if sId then
            SkillState.cachedHotbarSkills[slotNum] = {
                slotNum = slotNum,
                id = sId,
                isBuff = buffNames[sId] == true,
                range = 200
            }
        else
            local slotBtn = pad and pad:FindFirstChild("Slot" .. slotNum)
            if slotBtn and slotBtn.Visible then
                SkillState.cachedHotbarSkills[slotNum] = {
                    slotNum = slotNum,
                    id = "slot_" .. slotNum,
                    isBuff = false,
                    range = 200,
                    isGeneric = true
                }
            else
                SkillState.cachedHotbarSkills[slotNum] = nil
            end
        end
    end
end

-- Initialize cache immediately and listen for changes
task.spawn(updateHotbarCache)
pcall(function()
    if trackConn then
        trackConn(LocalPlayer:GetAttributeChangedSignal("HotbarJson"):Connect(function()
            updateHotbarCache()
        end))
    end
end)

local function getHotbarSkillInSlot(slotNum)
    local sInfo = SkillState.cachedHotbarSkills[slotNum]
    if sInfo then return sInfo.id end
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

function SkillState.getCachedSlot(slotNum)
    SkillState.slotCache = SkillState.slotCache or {}
    local cached = SkillState.slotCache[slotNum]
    if cached and cached.slot and cached.slot.Parent then
        if not cached.cdLabel or not cached.cdLabel.Parent then
            cached.cdLabel = cached.slot:FindFirstChild("Cooldown", true)
        end
        if not cached.shade or not cached.shade.Parent then
            cached.shade = cached.slot:FindFirstChild("CooldownShade", true)
        end
        return cached
    end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local ap = pg and pg:FindFirstChild("LumiHotbar")
    local pad = ap and ap:FindFirstChild("ActionPad")
    local slot = pad and pad:FindFirstChild("Slot" .. slotNum)
    if not slot then
        SkillState.slotCache[slotNum] = nil
        return nil
    end
    cached = {
        slot = slot,
        cdLabel = slot:FindFirstChild("Cooldown", true),
        shade = slot:FindFirstChild("CooldownShade", true),
    }
    SkillState.slotCache[slotNum] = cached
    return cached
end

local function isHotbarSlotReady(slotNum, sInfo)
    local cached = SkillState.getCachedSlot(slotNum)

    -- 1. Check UI Cooldown Label if active (cached refs, zero recursive scan in hot loop)
    if cached then
        local cdLabel = cached.cdLabel
        if cdLabel and cdLabel.Visible and cdLabel.Text ~= "" and cdLabel.Text ~= "0" and cdLabel.Text ~= "0.0" then
            local cdNum = tonumber((cdLabel.Text:gsub("[^%d%.]", "")))
            if cdNum and cdNum > 0.05 then
                return false
            end
        end
        local shade = cached.shade
        if shade and shade.Visible and shade.Size.Y.Scale > 0.08 then
            return false
        end
    end

    -- 2. SP Requirement (Lenient)
    local currentSp = LocalPlayer:GetAttribute("SP") or 999
    if currentSp < 3 then
        return false
    end

    -- 3. Safety micro-gap between repeated casts of same skill
    local now = os.clock()
    local sKey = (sInfo and sInfo.id) or tostring(slotNum)
    if (now - (SkillState.skillLastCast[sKey] or 0)) < 0.15 then
        return false
    end

    return true
end

local function executeSmartSkill(slotNum, sInfo, target, castTrigger)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local now = os.clock()

    -- Face target immediately
    if target and target.Parent then
        local tHrp = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
        if tHrp then
            hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(tHrp.Position.X, hrp.Position.Y, tHrp.Position.Z))
        end
    end

    local success = false

    -- Method 1: Native game slot trigger (100% accurate, triggers native cooldown + visual effects + animations)
    local trigger = castTrigger or getNativeSlotTrigger()
    if trigger then
        local ok = pcall(function() trigger(slotNum) end)
        if ok then success = true end
    end

    -- Method 2: Remote Fire to server
    if UseSkill and sInfo and sInfo.id and not sInfo.isGeneric then
        pcall(function()
            UseSkill:FireServer(sInfo.id, sInfo.isBuff and nil or target)
        end)
        success = true
    end

    -- Method 3: Fallback Client Slot Button connections ONLY if Method 1 & 2 failed
    if not success and typeof(getconnections) == "function" then
        pcall(function()
            local cached = SkillState.getCachedSlot(slotNum)
            local slotBtn = cached and cached.slot
            if slotBtn then
                for _, conn in ipairs(getconnections(slotBtn.MouseButton1Click)) do
                    pcall(function() conn:Fire() end)
                end
            end
        end)
    end

    local sKey = (sInfo and sInfo.id) or tostring(slotNum)
    SkillState.skillLastCast[sKey] = now
    SkillState.lastGlobalSkillCast = now
    return success
end

evaluateAndCastBestSkill = function(target)
    if not Config.AutoUseSkills then return false end
    if isEnteringDungeon or isWaitingForParty then return false end
    local now = os.clock()
    if (now - SkillState.lastGlobalSkillCast) < 0.08 then return false end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    updateHotbarCache()

    local targetPos = target and (target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart) and (target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart).Position
    local distToTarget = targetPos and (hrp.Position - targetPos).Magnitude or 10

    local castTrigger = getNativeSlotTrigger()
    local anyCast = false

    -- 1. Auto Buffs Check (Slot by slot, casts if buff skill and off cooldown)
    if Config.AutoUseBuffs then
        for slotNum = 1, 8 do
            if isSlotSelected(slotNum) then
                local sInfo = SkillState.cachedHotbarSkills[slotNum]
                if sInfo and sInfo.isBuff and isHotbarSlotReady(slotNum, sInfo) then
                    if (now - (SkillState.skillLastCast[sInfo.id] or 0)) > 8 then
                        executeSmartSkill(slotNum, sInfo, nil, castTrigger)
                        anyCast = true
                        break
                    end
                end
            end
        end
    end

    -- 2. Attack Skills Check (Fires the first ready attack skill immediately)
    if target and isMonsterAlive(target) and distToTarget <= 200 then
        for slotNum = 1, 8 do
            if isSlotSelected(slotNum) then
                local sInfo = SkillState.cachedHotbarSkills[slotNum]
                if sInfo and not sInfo.isBuff and isHotbarSlotReady(slotNum, sInfo) then
                    executeSmartSkill(slotNum, sInfo, target, castTrigger)
                    anyCast = true
                    break
                end
            end
        end
    end

    return anyCast
end

local function castSmartSkill(skillId, target)
    if not skillId or skillId == "" then return false end
    local trigger = getNativeSlotTrigger()
    for slotNum, sInfo in pairs(SkillState.cachedHotbarSkills) do
        if sInfo.id == skillId:lower() then
            if isHotbarSlotReady(slotNum, sInfo) then
                return executeSmartSkill(slotNum, sInfo, target, trigger)
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
        local stOk, st = pcall(hum.GetState, hum)
        if stOk and st == Enum.HumanoidStateType.Dead then
            return false
        end
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
    local list = {
        "All Bosses",
        "All Bosses + Leaders",
        "Pack Leaders Only",
        "Gorilla King (Boss01)",
        "Whitefang Sabertooth (Boss02)",
        "Obsidian Pharaoh (Boss03)",
        "Tempest Dragon King (Boss04)",
        "Volcano Turtle King (Boss05)",
    }
    local seenNorm = {}
    for _, v in ipairs(list) do
        local norm = (BossHunt and BossHunt.normalizeOneChoice) and BossHunt.normalizeOneChoice(v) or v
        seenNorm[norm] = true
    end
    if BossHunt and BossHunt.getSelectionList then
        local savedList = BossHunt.getSelectionList(Config.SelectedBosses and #Config.SelectedBosses > 0 and Config.SelectedBosses or Config.SelectedBoss)
        for _, savedItem in ipairs(savedList) do
            if savedItem ~= "" and not seenNorm[savedItem] then
                seenNorm[savedItem] = true
                table.insert(list, savedItem)
            end
        end
    end
    local folder = workspace:FindFirstChild("Monsters")
    if folder then
        for _, m in ipairs(folder:GetChildren()) do
            if m:IsA("Model") and isBossMonster(m) then
                if BossHunt and BossHunt.nearestZoneName and BossHunt.dynamicZoneMap then
                    local mp = getMonsterCombatPart(m)
                    local nz = mp and BossHunt.nearestZoneName(mp.Position)
                    if nz then
                        BossHunt.dynamicZoneMap[m.Name] = nz
                    end
                end
                local mNorm = (BossHunt and BossHunt.normalizeOneChoice) and BossHunt.normalizeOneChoice(m.Name) or m.Name
                if not seenNorm[mNorm] then
                    seenNorm[mNorm] = true
                    table.insert(list, m.Name)
                end
            end
        end
    end
    local known = {
        "Leader Fang Hyena",
        "Leader Saber Tiger",
        "Leader Spiked Stone Golem",
        "Leader Spiked Ice Golem",
        "Ram King",
        "Pumpkin Spider",
    }
    for _, b in ipairs(known) do
        local bNorm = (BossHunt and BossHunt.normalizeOneChoice) and BossHunt.normalizeOneChoice(b) or b
        if not seenNorm[bNorm] then
            seenNorm[bNorm] = true
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
        local tHrp = getMonsterCombatPart(currentCombatTarget)
        if tHrp then
            local dist = (hrp.Position - tHrp.Position).Magnitude
            local currentIsBoss = isBossMonster(currentCombatTarget)
            local activeBossSel = (Config.SelectedBosses and #Config.SelectedBosses > 0) and Config.SelectedBosses or Config.SelectedBoss
            local currentMatchesSelected = currentIsBoss and BossHunt.isMatchingBoss(currentCombatTarget, activeBossSel)
            local stickLimit = currentIsBoss and 280 or 140

            if Config.BossOnly and (not currentIsBoss or not currentMatchesSelected) then
                currentCombatTarget = nil
            elseif (Config.AutoBoss or Config.PrioritizeBoss) and currentIsBoss and not currentMatchesSelected and BossHunt.formatSelectionSummary(activeBossSel) ~= "All Bosses" then
                currentCombatTarget = nil
            elseif dist <= stickLimit then
                -- If we're fighting a normal mob and a matching boss is nearby with PrioritizeBoss, switch to boss
                if not currentIsBoss and (Config.PrioritizeBoss or Config.BossOnly) then
                    for _, mob in ipairs(folder:GetChildren()) do
                        if mob:IsA("Model") and isMonsterAlive(mob) and BossHunt.isMatchingBoss(mob, activeBossSel) then
                            local bHrp = getMonsterCombatPart(mob)
                            if bHrp and (hrp.Position - bHrp.Position).Magnitude <= 180 then
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
            local mHrp = getMonsterCombatPart(monster)
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

                local isBoss = isBossMonster(monster)
                -- Bosses and Boss Arenas are ALWAYS in zone!
                if isBoss or inBoss then
                    inZone = true
                end

                if inZone then
                    -- 🎃 Halloween Priority Matching (Skipped when BossOnly is filtering for specific bosses)
                    if not Config.BossOnly and Config.AutoHalloween and Config.HuntHalloweenPumpkins then
                        local mName = monster.Name:lower()
                        local isPumpkin = monster:GetAttribute("HalloweenPumpkin") or mName:find("pumpkin") or mName:find("halloween")
                        if isPumpkin and distFromPlayer < bestHalloweenDist then
                            bestHalloweenDist = distFromPlayer
                            bestHalloween = monster
                        end
                    end

                    -- Boss Candidate Matching (strictly respects SelectedBosses / SelectedBoss!)
                    if isBoss and (Config.AutoBoss or Config.BossOnly or Config.PrioritizeBoss or Config.BossServerHop) then
                        local activeBossSel = (Config.SelectedBosses and #Config.SelectedBosses > 0) and Config.SelectedBosses or Config.SelectedBoss
                        if BossHunt.isMatchingBoss(monster, activeBossSel) and distFromPlayer < bestBossDist then
                            bestBossDist = distFromPlayer
                            bestBoss = monster
                        end
                    end

                    -- Normal Candidate Matching
                    if not Config.BossOnly and not isBoss then
                        local nameAllowed = false
                        if Config.SelectedMonster == "All" or not Config.SelectedMonster then
                            nameAllowed = true
                        elseif monster.Name == Config.SelectedMonster or string.find(monster.Name, Config.SelectedMonster, 1, true) then
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
    if bestHalloween and not Config.BossOnly and Config.AutoHalloween and Config.HuntHalloweenPumpkins then
        currentCombatTarget = bestHalloween
        return bestHalloween
    end

    if bestBoss and (Config.PrioritizeBoss or Config.BossOnly or Config.AutoBoss or Config.BossServerHop) then
        currentCombatTarget = bestBoss
        trackBossDeath(bestBoss)
        activeBossFight = {
            model = bestBoss,
            name = bestBoss.Name,
            pos = getMonsterCombatPart(bestBoss) and getMonsterCombatPart(bestBoss).Position,
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
    local isWalk = (Config.FarmMode == "Walk")

    local baseDist = tonumber(Config.FarmDistance)
    if baseDist == nil then
        baseDist = isRanged and 14.0 or 5.0
    end
    local baseHeight = tonumber(Config.SafeFarmHeight)
    if baseHeight == nil then
        baseHeight = 5.5
    end

    -- Measure configured distance from monster hitbox surface so large bosses (e.g. Volcano Turtle King) never trap player inside collider
    local surfDist = math.clamp(baseDist, 1.0, 35.0)
    local height = isWalk and 0.0 or math.clamp(baseHeight, 0.0, 25.0)

    -- Only apply weapon-reach clamp when the user explicitly opts into AdaptiveDistance
    if Config.AdaptiveDistance then
        if isRanged then
            local rangedMax = math.min(35.0, math.max(12.0, atkRange - 2.0))
            surfDist = math.clamp(surfDist, 1.0, rangedMax)
        else
            local meleeMax = math.min(35.0, math.max(4.0, atkRange - 0.5))
            surfDist = math.clamp(surfDist, 1.0, meleeMax)
        end
    end

    local mobRadius = 0.0
    if target then
        mobRadius = tonumber(target:GetAttribute("Radius")) or (isBossMonster(target) and 7.2 or 1.5)
    end
    local centerDist = surfDist + mobRadius

    return centerDist, height, isRanged, surfDist, mobRadius
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
    if isInsideDungeon() then
        local floorY = (targetOverridePos and targetOverridePos.Y) or startPos.Y
        targetDodgePos = Vector3.new(targetDodgePos.X, floorY, targetDodgePos.Z)
    elseif Config.FarmMode == "Walk" then
        targetDodgePos = Vector3.new(targetDodgePos.X, startPos.Y, targetDodgePos.Z)
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
            local flatMobLook = Vector3.new(mobLook.X, 0, mobLook.Z)
            flatMobLook = (flatMobLook.Magnitude > 0.05) and flatMobLook.Unit or Vector3.new(0, 0, -1)
            local toPlayer = (hrp.Position - mHrp.Position)
            local isFacingPlayer = (toPlayer.Magnitude > 0.1) and (mobLook:Dot(toPlayer.Unit) > 0.25)

            -- If mob is facing us, slip behind it at the configured distance & height!
            if isFacingPlayer then
                local animSet = mob:GetAttribute("AnimSet")
                local attackTime = 0.35
                if animSet and MonsterAnimModule and MonsterAnimModule.Sets and MonsterAnimModule.Sets[animSet] then
                    attackTime = MonsterAnimModule.Sets[animSet].AttackTime or 0.35
                end

                local safeDist, safeHeight = getSmartFarmOffset(mob)
                local targetPos = mHrp.Position - (flatMobLook * safeDist) + Vector3.new(0, safeHeight, 0)
                performDodge("Pre-Hit Flank: " .. mob.Name, -flatMobLook, safeDist, attackTime + 0.05, mob, targetPos)
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
    local function hookFolder(folder)
        if not folder then return end
        for _, mob in ipairs(folder:GetChildren()) do
            if mob:IsA("Model") then
                task.spawn(hookMonsterEvasion, mob)
            end
        end
        if trackConn then
            trackConn(folder.ChildAdded:Connect(function(mob)
                if not isScriptAlive() then return end
                if mob:IsA("Model") then
                    task.spawn(hookMonsterEvasion, mob)
                end
            end))
        end
    end

    local monstersFolder = workspace:FindFirstChild("Monsters")
    if monstersFolder then hookFolder(monstersFolder) end
    local activeMonsters = workspace:FindFirstChild("ActiveMonsters")
    if activeMonsters then hookFolder(activeMonsters) end
    if trackConn then
        trackConn(workspace.ChildAdded:Connect(function(child)
            if child.Name == "Monsters" or child.Name == "ActiveMonsters" then
                hookFolder(child)
            end
        end))
    end
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
    if silent then
        if isWarpingZone or isCheckingBossArena or BossHunt.isInspecting or isReturningFromBoss or activeBossFight then return end
        if isPlayerInBossArena() then
            local used = LocalPlayer:GetAttribute("BagSlotsUsed") or 0
            local max = LocalPlayer:GetAttribute("BagSlotsMax") or 50
            if used < max then return end
        end
    end
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
    getgenv()._SongHubRevokeCallbacks = getgenv()._SongHubRevokeCallbacks or {}
    getgenv()._SongHubRevokeCallbacks["HuntingTogether"] = function()
        if getgenv()._HT_ScriptRunId == currentRunId then
            getgenv()._HT_ScriptRunId = -1
        end
        getgenv()._HuntingTogetherRunning = false
        if type(Config) == "table" then
            for k, v in pairs(Config) do
                if type(v) == "boolean" and (k:find("Auto") or k:find("Farm") or k:find("Kill") or k:find("Boss") or k:find("Spam") or k:find("Collect") or k:find("Hop")) then
                    Config[k] = false
                end
            end
        end
        if getgenv()._HT_Connections then
            for _, conn in ipairs(getgenv()._HT_Connections) do
                pcall(function() conn:Disconnect() end)
            end
            getgenv()._HT_Connections = {}
        end
        pcall(function() Window:Destroy() end)
    end
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
            BossHunt.lastDisableAutoAt = 0
            WindUI:Notify({ Title = "Auto Farm", Content = "เริ่มการฟาร์มอัตโนมัติ", Duration = 2, Icon = "play" })
        else
            stopCombatAndTargeting()
            WindUI:Notify({ Title = "Auto Farm", Content = "หยุดการฟาร์มและปลดล็อคเป้าหมายเรียบร้อย", Duration = 2, Icon = "square" })
        end
    end,
})

FarmTab:Button({
    Title = "⛔ Emergency Stop All (หยุดการทำงานและหยุดวาร์ปทั้งหมดทันที)",
    Desc = "ปิด Auto Farm, Auto Dungeon, Auto Progression, Boss Only, Boss Server Hop และหยุดวาร์ปทั้งหมด 100%",
    Callback = function()
        Config.AutoFarm = false
        Config.AutoDungeon = false
        Config.AutoProgression = false
        Config.AutoBoss = false
        Config.AutoWarpToBoss = false
        Config.BossOnly = false
        Config.AutoOpenLootBox = false
        Config.AutoTrickTreat = false
        if BossHunt and BossHunt.stopAllHops then
            BossHunt.stopAllHops(true)
        else
            Config.BossServerHop = false
            Config.BossTimedHop = false
            Config.ServerHopAuto = false
        end
        local function resetToggleVisual(t)
            if t then
                if t.SetValue then pcall(function() t:SetValue(false) end)
                elseif t.Set then pcall(function() t:Set(false) end) end
            end
        end
        resetToggleVisual(autoFarmToggle)
        resetToggleVisual(autoDungeonToggle)
        resetToggleVisual(autoProgressionToggle)
        if BossHunt and BossHunt.uiRefs then
            resetToggleVisual(BossHunt.uiRefs.autoBossToggle)
            resetToggleVisual(BossHunt.uiRefs.autoWarpBossToggle)
            resetToggleVisual(BossHunt.uiRefs.bossOnlyToggle)
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
    Desc = "ปรับความสูงลอยตัวเหนือมอนสเตอร์ขณะฟาร์มในโหมดวาร์ป/บิน (0 - 25)",
    Value = { Min = 0, Max = 25, Default = math.clamp(tonumber(Config.SafeFarmHeight) or 5.5, 0, 25) },
    Step = 0.5,
    Callback = function(val)
        local n = tonumber(val)
        if n ~= nil then
            Config.SafeFarmHeight = math.clamp(n, 0, 25)
            if Config.AutoSave then SaveConfig(true) end
        end
    end,
})

BossHunt.uiRefs.farmDistSlider = FarmTab:Slider({
    Title = "Farm Distance (ระยะห่างจากมอนสเตอร์)",
    Desc = "ปรับระยะห่างจริงจากมอนสเตอร์และบอสทุกตัว (1 - 35 studs | ตีใกล้แนะนำ 2-6 / ตีไกลแนะนำ 12-28)",
    Value = { Min = 1, Max = 35, Default = math.clamp(tonumber(Config.FarmDistance) or 4.5, 1, 35) },
    Step = 0.5,
    Callback = function(val)
        local n = tonumber(val)
        if n == nil then return end
        local clamped = math.clamp(n, 1, 35)
        Config.FarmDistance = clamped
        if Config.AutoSave then SaveConfig(true) end
        if BossHunt and BossHunt.uiRefs and not BossHunt.uiRefs._syncingDist then
            local other = BossHunt.uiRefs.dungeonDistSlider
            if other then
                BossHunt.uiRefs._syncingDist = true
                if other.SetValue then pcall(function() other:SetValue(clamped) end)
                elseif other.Set then pcall(function() other:Set(clamped) end) end
                BossHunt.uiRefs._syncingDist = false
            end
        end
    end,
})

BossHunt.uiRefs.adaptiveDistToggle = FarmTab:Toggle({
    Title = "Auto Adapt Distance by Weapon (จำกัดระยะอัตโนมัติตามอาวุธ)",
    Desc = "ปิด (ค่าเริ่มต้น) = ใช้ระยะห่างตาม Farm Distance จริง 100% ทุกมอนและบอส | เปิด = จำกัดไม่ให้เกินระยะอาวุธ",
    Value = Config.AdaptiveDistance == true,
    Callback = function(state)
        Config.AdaptiveDistance = state
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

BossHunt.uiRefs.autoBossToggle = FarmTab:Toggle({
    Title = "Auto Hunt Bosses & Mini-Bosses",
    Desc = "ตรวจจับและโจมตีบอส / มินิบอส / หัวหน้าฝูงอัตโนมัติเมื่อเกิด",
    Value = Config.AutoBoss,
    Callback = function(state)
        Config.AutoBoss = state
        if Config.AutoSave then SaveConfig(true) end
        if state then
            BossHunt.lastCheckTime = -999
            task.spawn(function() executeBossInspection(false, true) end)
        end
    end,
})

BossHunt.uiRefs.autoWarpBossToggle = FarmTab:Toggle({
    Title = "Auto Warp to World Bosses (วาร์ปไปห้องบอสโลกอัตโนมัติ)",
    Desc = "วาร์ปไปตรวจสอบและล่าบอสใหญ่ในห้องบอส (Boss01-05 เช่น Gorilla King, Obsidian Pharaoh) เป็นระยะอัตโนมัติ",
    Value = Config.AutoWarpToBoss,
    Callback = function(state)
        Config.AutoWarpToBoss = state
        if Config.AutoSave then SaveConfig(true) end
        if state then
            BossHunt.lastCheckTime = -999
            task.spawn(function() executeBossInspection(false, true) end)
        end
    end,
})

FarmTab:Button({
    Title = "Warp to Level Boss Arena Now (วาร์ปไปห้องบอสทันที)",
    Desc = "วาร์ปไปตรวจสอบบอสตามรายชื่อบอสที่เลือก (หรือระดับเลเวล) ทันที",
    Callback = function()
        task.spawn(function() executeBossInspection(false, true) end)
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

BossHunt.uiRefs.bossOnlyToggle = FarmTab:Toggle({
    Title = "Bosses Only Mode (ล่าเฉพาะบอสในห้องบอสเท่านั้น)",
    Desc = "ไม่ตีมอนสเตอร์ขยะทั่วไป วาร์ปไปห้องบอสตามรายชื่อที่เลือกด้านล่าง (All Bosses = Boss01-05) และรอดักเกิด/ย้ายเซิร์ฟตามตั้งค่า",
    Value = Config.BossOnly,
    Callback = function(state)
        Config.BossOnly = state
        if state then
            local activeSel = (Config.SelectedBosses and #Config.SelectedBosses > 0) and Config.SelectedBosses or Config.SelectedBoss
            if currentCombatTarget and not BossHunt.isMatchingBoss(currentCombatTarget, activeSel) then
                currentCombatTarget = nil
            end
            if activeBossFight and activeBossFight.model and not BossHunt.isMatchingBoss(activeBossFight.model, activeSel) then
                activeBossFight = nil
            end
            if not Config.AutoFarm then
                Config.AutoFarm = true
                if autoFarmToggle then
                    if autoFarmToggle.SetValue then pcall(function() autoFarmToggle:SetValue(true) end)
                    elseif autoFarmToggle.Set then pcall(function() autoFarmToggle:Set(true) end) end
                end
            end
            BossHunt.missingSince = nil
            BossHunt.lastMissingKey = ""
            BossHunt.lastCheckTime = -999
            if Config.AutoSave then SaveConfig(true) end
            task.spawn(function() executeBossInspection(false, true) end)
        else
            BossHunt.inspectToken = (BossHunt.inspectToken or 0) + 1
            BossHunt.isInspecting = false
            BossHunt.missingSince = nil
            BossHunt.lastMissingKey = ""
            isCheckingBossArena = false
            if Config.AutoSave then SaveConfig(true) end
        end
    end,
})

do
    local initList = getBossList()
    local initSel = (Config.SelectedBosses and #Config.SelectedBosses > 0) and Config.SelectedBosses or Config.SelectedBoss
    local initVals = BossHunt.toDropdownValues(initSel, initList)
    BossHunt._prevDropdownRaw = initVals
    BossHunt._lastListKey = table.concat(initList, "\0")

    bossDropdown = FarmTab:Dropdown({
        Title = "Select Boss Names for Boss Only / Hop (เลือกชื่อบอสได้หลายตัว)",
        Desc = "เลือกชื่อบอสสำหรับโหมด Boss Only และ Server Hop (เลือก All Bosses หรือติ๊กเลือกเฉพาะบอสหลายตัวได้)",
        Values = initList,
        Value = initVals,
        Multi = true,
        AllowNone = true,
        Callback = function(selected)
            if BossHunt._updatingDropdown then return end

            local rawItems = {}
            if type(selected) == "table" then
                if #selected > 0 then
                    for _, v in ipairs(selected) do
                        if type(v) == "string" then
                            table.insert(rawItems, v)
                        end
                    end
                else
                    for k, v in pairs(selected) do
                        if v == true and type(k) == "string" then
                            table.insert(rawItems, k)
                        elseif type(v) == "string" then
                            table.insert(rawItems, v)
                        end
                    end
                end
            elseif type(selected) == "string" then
                table.insert(rawItems, selected)
            end

            local prevSet, nowSet = {}, {}
            for _, v in ipairs(BossHunt._prevDropdownRaw or {}) do
                prevSet[BossHunt.normalizeOneChoice(v)] = true
            end
            for _, v in ipairs(rawItems) do
                nowSet[BossHunt.normalizeOneChoice(v)] = true
            end

            local chosenList
            if nowSet["All Bosses"] and not prevSet["All Bosses"] then
                chosenList = { "All Bosses" }
            elseif nowSet["All Bosses + Leaders"] and not prevSet["All Bosses + Leaders"] then
                chosenList = { "All Bosses + Leaders" }
            else
                chosenList = BossHunt.getSelectionList(rawItems)
            end

            local summary = BossHunt.formatSelectionSummary(chosenList)
            Config.SelectedBosses = chosenList
            Config.SelectedBoss = summary

            local currentList = getBossList()
            local displayVals = BossHunt.toDropdownValues(chosenList, currentList)
            BossHunt._prevDropdownRaw = displayVals

            local diff = (#displayVals ~= #rawItems)
            if not diff then
                local dispSet = {}
                for _, v in ipairs(displayVals) do dispSet[v] = true end
                for _, v in ipairs(rawItems) do
                    if not dispSet[v] then diff = true; break end
                end
            end
            if diff then
                BossHunt.syncBossDropdownVisual(displayVals)
            end

            if currentCombatTarget and not BossHunt.isMatchingBoss(currentCombatTarget, chosenList) then
                currentCombatTarget = nil
            end
            if activeBossFight and activeBossFight.model and not BossHunt.isMatchingBoss(activeBossFight.model, chosenList) then
                activeBossFight = nil
            end
            BossHunt.missingSince = nil
            BossHunt.lastMissingKey = ""
            BossHunt.lastCheckTime = -999
            BossHunt.lastStayZone = ""
            if Config.AutoSave then SaveConfig(true) end
            if Config.BossOnly or Config.BossServerHop or Config.AutoBoss then
                task.spawn(function() executeBossInspection(false, true) end)
            elseif WindUI and WindUI.Notify then
                local z = getTargetBossZone(getPlayerLevel(), chosenList)
                WindUI:Notify({
                    Title = "เลือกบอสแล้ว",
                    Content = string.format("เป้าหมาย: %s (โซนหลัก %s)\nเปิด Boss Only เพื่อวาร์ปไปล่าทันที", summary, tostring(z)),
                    Duration = 2.5,
                    Icon = "crown",
                })
            end
        end,
    })
end

FarmTab:Button({
    Title = "Refresh Boss List",
    Callback = function()
        local updated = BossHunt.refreshBossDropdown(true) or getBossList()
        WindUI:Notify({ Title = "Updated", Content = "อัปเดตรายชื่อบอส: " .. #updated .. " ตัว", Duration = 2, Icon = "crown" })
    end,
})

FarmTab:Toggle({
    Title = "Return to Auto Lv.99 Field After Boss (ตีบอสเสร็จกลับไปฟาร์มต่อ)",
    Desc = "เมื่อบอสถูกกำจัด จะดูดเก็บของดรอป/ไข่สัตว์เลี้ยง แล้ววาร์ปกลับไปฟาร์มตามเลเวล 1-99 (ทำงานเมื่อปิด Bosses Only)",
    Value = Config.ReturnToProgressionAfterBoss,
    Callback = function(state)
        Config.ReturnToProgressionAfterBoss = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

BossHunt.uiRefs.bossHopToggle = FarmTab:Toggle({
    Title = "🌐 Auto Server Hop for Boss (ไม่เจอบอสที่เลือก ย้ายเซิฟอัตโนมัติ)",
    Desc = "วาร์ปเช็คบอสที่เลือก (1 ตัว / หลายตัว / All Bosses) หากไม่มีบอสเกิดจะย้ายเซิร์ฟตาม Delay ที่ตั้ง (กันย้ายรัว 12 วิหลังเข้าห้อง)",
    Value = Config.BossServerHop,
    Callback = function(state)
        Config.BossServerHop = state
        BossHunt.lastHopEditAt = os.clock()
        BossHunt.missingSince = nil
        BossHunt.lastMissingKey = ""
        if state then
            BossHunt.cancelHopRequested = false
            BossHunt.hopFailCount = 0
            local activeSel = (Config.SelectedBosses and #Config.SelectedBosses > 0) and Config.SelectedBosses or Config.SelectedBoss
            if currentCombatTarget and not BossHunt.isMatchingBoss(currentCombatTarget, activeSel) then
                currentCombatTarget = nil
            end
            if activeBossFight and activeBossFight.model and not BossHunt.isMatchingBoss(activeBossFight.model, activeSel) then
                activeBossFight = nil
            end
            if not Config.AutoFarm then
                Config.AutoFarm = true
                if autoFarmToggle then
                    if autoFarmToggle.SetValue then pcall(function() autoFarmToggle:SetValue(true) end)
                    elseif autoFarmToggle.Set then pcall(function() autoFarmToggle:Set(true) end) end
                end
            end
            BossHunt.lastCheckTime = -999
            if Config.AutoSave then SaveConfig(true) end
            task.spawn(function() executeBossInspection(false, true) end)
        else
            BossHunt.cancelHopRequested = true
            BossHunt.isServerHopping = false
            BossHunt.clearHopSession()
            BossHunt.inspectToken = (BossHunt.inspectToken or 0) + 1
            BossHunt.isInspecting = false
            isCheckingBossArena = false
            if Config.AutoSave then SaveConfig(true) end
        end
    end,
})

BossHunt.uiRefs.bossHopDelaySlider = FarmTab:Slider({
    Title = "⏱️ Boss Server Hop Delay (ตั้งเวลารอก่อนย้ายเซิฟ - วินาที)",
    Desc = "0 วินาที = ย้ายเมื่อไม่มีบอส (มีระบบหน่วงปลอดภัยหลังเข้าเซิร์ฟ 12 วิ) | แนะนำ >= 10 วิ กันเผลอโดน 1 วิแล้วย้ายรัว",
    Value = { Min = 0, Max = 300, Default = math.clamp(tonumber(Config.BossHopDelay) or 15, 0, 300) },
    Step = 1,
    Callback = function(val)
        local n = tonumber(val)
        if n ~= nil then
            Config.BossHopDelay = math.clamp(math.floor(n + 0.5), 0, 300)
            BossHunt.lastHopEditAt = os.clock()
            BossHunt.missingSince = nil
            BossHunt.lastMissingKey = ""
            if Config.AutoSave then SaveConfig(true) end
        end
    end,
})

FarmTab:Button({
    Title = "🛑 Stop Boss Server Hop Now (หยุดย้ายเซิร์ฟ + รีเซ็ต 15 วิ)",
    Desc = "กดปุ่มนี้เพื่อยกเลิกการย้ายเซิร์ฟเวอร์รัวทันที ปิด Auto Server Hop และรีเซ็ตค่าหน่วง 1 วิ กลับเป็น 15 วิ",
    Callback = function()
        if BossHunt and BossHunt.stopAllHops then
            BossHunt.stopAllHops(true)
        end
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "🛑 หยุดย้ายเซิร์ฟเวอร์เรียบร้อย",
                Content = "ปิด Auto Server Hop และรีเซ็ต Delay เป็นค่าปลอดภัยแล้ว!",
                Duration = 3,
                Icon = "shield-check",
            })
        end
    end,
})

BossHunt.uiRefs.bossTimedHopToggle = FarmTab:Toggle({
    Title = "⏰ Timed Auto Server Hop for Boss (ตั้งเวลาเปลี่ยนเซิฟหาบอสตามรอบ)",
    Desc = "เปลี่ยนเซิร์ฟเวอร์หาบอสที่เลือกซ้ำอัตโนมัติทุกรอบเวลาที่กำหนด (รอตีบอสที่กำลังสู้ให้จบก่อนย้าย)",
    Value = Config.BossTimedHop == true,
    Callback = function(state)
        Config.BossTimedHop = state
        if state then
            BossHunt.cancelHopRequested = false
            BossHunt.hopFailCount = 0
            local mins = math.clamp(math.floor((tonumber(Config.BossTimedHopMinutes) or 5) + 0.5), 1, 60)
            BossHunt.bossTimedHopNextTick = os.clock() + (mins * 60)
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "⏰ Timed Boss Server Hop",
                    Content = string.format("เปิดตั้งเวลาย้ายเซิร์ฟหาบอสทุกๆ %d นาทีแล้ว", mins),
                    Duration = 3,
                    Icon = "clock",
                })
            end
        else
            BossHunt.bossTimedHopNextTick = 0
            BossHunt.clearHopSession()
        end
        if Config.AutoSave then SaveConfig(true) end
    end,
})

FarmTab:Slider({
    Title = "🕰️ Timed Boss Hop Interval (รอบเวลาเปลี่ยนเซิฟหาบอส - นาที)",
    Desc = "ตั้งเวลารอบเปลี่ยนเซิร์ฟเวอร์หาบอสอัตโนมัติ (1 - 60 นาที)",
    Value = { Min = 1, Max = 60, Default = math.clamp(math.floor((tonumber(Config.BossTimedHopMinutes) or 5) + 0.5), 1, 60) },
    Step = 1,
    Callback = function(val)
        local n = tonumber(val)
        if n ~= nil then
            local mins = math.clamp(math.floor(n + 0.5), 1, 60)
            Config.BossTimedHopMinutes = mins
            if Config.BossTimedHop then
                BossHunt.bossTimedHopNextTick = os.clock() + (mins * 60)
            end
            if Config.AutoSave then SaveConfig(true) end
        end
    end,
})

FarmTab:Button({
    Title = "🚀 Hop Server to Find Selected Boss Now (ย้ายเซิฟหาบอสทันที)",
    Desc = "ย้ายไปเซิร์ฟเวอร์คนน้อยที่ยังไม่เคยเช็คทันที เพื่อหาบอสที่เลือกไว้ใน Select Boss Names",
    Callback = function()
        local activeSel = (Config.SelectedBosses and #Config.SelectedBosses > 0) and Config.SelectedBosses or Config.SelectedBoss
        BossHunt.serverHopForBoss(activeSel, false, true)
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
    if BossHunt then
        BossHunt.inspectToken = (BossHunt.inspectToken or 0) + 1
        BossHunt.isInspecting = false
    end
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
    Values = { "🎃 Skull King's Crypt (Lv.90+)", "💰 Gold Dungeon (Lv.90+ · ไม่ใช้กุญแจ)" },
    Value = (Config.SelectedDungeon == "gold") and "💰 Gold Dungeon (Lv.90+ · ไม่ใช้กุญแจ)" or "🎃 Skull King's Crypt (Lv.90+)",
    Callback = function(selected)
        if selected:find("Gold") or selected:find("💰") then
            Config.SelectedDungeon = "gold"
        else
            Config.SelectedDungeon = "halloween"
        end
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
    Value = { Min = 0, Max = 15, Default = math.clamp(tonumber(Config.DungeonSafeHeight) or 3.5, 0, 15) },
    Step = 0.5,
    Callback = function(val)
        local n = tonumber(val)
        if n ~= nil then
            Config.DungeonSafeHeight = math.clamp(n, 0, 15)
            if Config.AutoSave then SaveConfig(true) end
        end
    end,
})

BossHunt.uiRefs.dungeonDistSlider = DungeonTab:Slider({
    Title = "Dungeon Farm Distance (ระยะห่างจากมอนสเตอร์ในดันเจี้ยน)",
    Desc = "ปรับระยะห่างจากมอนสเตอร์และบอสในดันเจี้ยน (ซิงค์กับ Farm Distance | จำกัดอัตโนมัติหากติดกำแพงแคบ)",
    Value = { Min = 1, Max = 35, Default = math.clamp(tonumber(Config.FarmDistance) or 4.5, 1, 35) },
    Step = 0.5,
    Callback = function(val)
        local n = tonumber(val)
        if n == nil then return end
        local clamped = math.clamp(n, 1, 35)
        Config.FarmDistance = clamped
        if Config.AutoSave then SaveConfig(true) end
        if BossHunt and BossHunt.uiRefs and not BossHunt.uiRefs._syncingDist then
            local other = BossHunt.uiRefs.farmDistSlider
            if other then
                BossHunt.uiRefs._syncingDist = true
                if other.SetValue then pcall(function() other:SetValue(clamped) end)
                elseif other.Set then pcall(function() other:Set(clamped) end) end
                BossHunt.uiRefs._syncingDist = false
            end
        end
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
    if BossHunt then
        BossHunt.inspectToken = (BossHunt.inspectToken or 0) + 1
        BossHunt.isInspecting = false
    end
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
do
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
end

-- ==================== LOW-PLAYER SERVER HOP UI ====================
TeleportTab:Section({ Title = "🌐 Low-Player Server Hop (ระบบย้ายเซิร์ฟเวอร์คนน้อย)", Opened = true })

BossHunt.uiRefs.autoServerHopToggle = TeleportTab:Toggle({
    Title = "Auto Server Hop (ย้ายเซิร์ฟเวอร์อัตโนมัติ)",
    Desc = "สลับย้ายไปเซิร์ฟเวอร์ที่มีผู้เล่นน้อยที่สุดตามรอบเวลาที่ตั้งไว้",
    Value = Config.ServerHopAuto,
    Callback = function(state)
        Config.ServerHopAuto = state
        if state then
            BossHunt.cancelHopRequested = false
            BossHunt.hopFailCount = 0
            BossHunt.serverHopNextTick = os.clock() + ((tonumber(Config.ServerHopInterval) or 15) * 60)
        else
            BossHunt.serverHopNextTick = 0
            BossHunt.clearHopSession()
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
            BossHunt.serverHopNextTick = os.clock() + ((tonumber(val) or 15) * 60)
        end
        if Config.AutoSave then SaveConfig(true) end
    end,
})

TeleportTab:Button({
    Title = "🚀 Server Hop Now (ย้ายไปเซิร์ฟคนน้อยทันที)",
    Desc = "ค้นหาเซิร์ฟเวอร์คนน้อยที่สุดในขณะนี้และย้ายทันที ไม่ต้องรอรอบเวลา",
    Callback = function()
        serverHopLowPlayer(false, true)
    end,
})

TeleportTab:Button({
    Title = "👑 Hop Server to Hunt Boss (ย้ายเซิฟเวอร์หาบอสที่เลือก)",
    Desc = "ย้ายไปเซิร์ฟเวอร์ใหม่เพื่อล่าบอสตามชื่อที่เลือกไว้ใน Select Boss Names",
    Callback = function()
        local activeSel = (Config.SelectedBosses and #Config.SelectedBosses > 0) and Config.SelectedBosses or Config.SelectedBoss
        BossHunt.serverHopForBoss(activeSel, false, true)
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
    Desc = "Copy Discord invite link to your clipboard (https://discord.gg/Cpcg9wU5k)",
    Callback = function()
        pcall(function()
            if typeof(setclipboard) == "function" then
                setclipboard("https://discord.gg/Cpcg9wU5k")
            end
            WindUI:Notify({
                Title = "Discord Link Copied! 💬",
                Content = "https://discord.gg/Cpcg9wU5k\nJoin Song Hub Discord for support, updates & keys!",
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
            -- Ensure game's built-in AutoOn bot never hijacks Humanoid:Move / CurrentTarget during Hub combat
            BossHunt.disableGameAutoOn()

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
                if Config.AutoLoot and Config.LootPriority and dropsFolder and (nowClock - SkillState.lastCombatLootScan) >= 0.5 then
                    SkillState.lastCombatLootScan = nowClock
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
                        local bPart = getMonsterCombatPart(target)
                        if not activeBossFight or activeBossFight.model ~= target then
                            trackBossDeath(target)
                            activeBossFight = {
                                model = target,
                                name = target.Name,
                                pos = bPart and bPart.Position,
                                time = os.clock(),
                            }
                        else
                            activeBossFight.time = os.clock()
                            if bPart then
                                activeBossFight.pos = bPart.Position
                            end
                        end
                    end
                    local targetHrp = getMonsterCombatPart(target)

                    if targetHrp then
                        local targetPos = targetHrp.Position
                        local mobLook = targetHrp.CFrame.LookVector
                        local flatLook = Vector3.new(mobLook.X, 0, mobLook.Z)
                        flatLook = (flatLook.Magnitude > 0.05) and flatLook.Unit or Vector3.new(0, 0, -1)
                        local toPlayer = (hrp.Position - targetPos)
                        local mName = (target.Name or ""):lower()
                        local mId = tostring(target:GetAttribute("MonsterId") or "")
                        local isBoss = isBossMonster(target) or (mName:find("boss") ~= nil) or (mName:find("witch") ~= nil) or (mId:find("boss") ~= nil)
                        local isPillar = (mName:find("pillar") ~= nil or mName:find("ritual") ~= nil or mId == "dgn_ritual_pillar")

                        local now = os.clock()
                        local isHoldingSafe = (currentSafeHoldTarget ~= nil and now < safeHoldUntil)

                        local safeDist, safeHeight, isRanged, _, mobRadius = getSmartFarmOffset(target)
                        local walkTargetDist = safeDist

                        -- 1000% Flank Defense: if monster turns to face player, slip behind it at configured distance & height
                        -- (Skipped in dungeon to prevent corridor wall pin, skipped in Walk Mode, and skipped while holding green circle)
                        if Config.AutoDodge and Config.DodgeFlank and (Config.FarmMode ~= "Walk") and not isHoldingSafe and not inDungeon then
                            if toPlayer.Magnitude < (safeDist + 4) and (toPlayer.Magnitude > 0.1 and mobLook:Dot(toPlayer.Unit) > 0.15) then
                                local behindPos = targetPos - (flatLook * safeDist) + Vector3.new(0, safeHeight, 0)
                                performDodge("Combat Flank Behind", -flatLook, safeDist, 0.25, target, behindPos)
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
                                    farmH = tonumber(Config.DungeonSafeHeight) or 3.5
                                else
                                    farmH = math.min(safeHeight, 6.0)
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
                                playerPos = getDungeonSafeCombatPosition(targetPos, flatLook, safeDist, isRanged, isBoss, isPillar, farmH)
                                targetFloorY = playerPos.Y
                            else
                                local mFolder = workspace:FindFirstChild("Monsters")
                                local dFolder = workspace:FindFirstChild("Drops")
                                local rayParams = BossHunt.groundRayParams
                                if not rayParams then
                                    rayParams = RaycastParams.new()
                                    rayParams.FilterType = Enum.RaycastFilterType.Exclude
                                    BossHunt.groundRayParams = rayParams
                                end
                                if BossHunt.rayChar ~= char or BossHunt.rayTarget ~= target or BossHunt.rayMFolder ~= mFolder or BossHunt.rayDFolder ~= dFolder then
                                    BossHunt.rayChar = char
                                    BossHunt.rayTarget = target
                                    BossHunt.rayMFolder = mFolder
                                    BossHunt.rayDFolder = dFolder
                                    local ignoreList = BossHunt.rayIgnoreList or {}
                                    table.clear(ignoreList)
                                    ignoreList[1] = char
                                    ignoreList[2] = target
                                    if mFolder then ignoreList[#ignoreList + 1] = mFolder end
                                    if dFolder then ignoreList[#ignoreList + 1] = dFolder end
                                    BossHunt.rayIgnoreList = ignoreList
                                    rayParams.FilterDescendantsInstances = ignoreList
                                end

                                local inBossZone, bossZoneName = isPlayerInBossArena()
                                local arenaCenter = (inBossZone and bossZoneName and ZoneCoordinates[bossZoneName]) or nil

                                local function clampBossArenaXZ(pt)
                                    if not arenaCenter then return pt end
                                    if bossZoneName == "Boss05" then
                                        local dx = pt.X - arenaCenter.X
                                        local dz = pt.Z - arenaCenter.Z
                                        local r = math.sqrt(dx * dx + dz * dz)
                                        if r > 78 then
                                            local s = 78 / r
                                            return Vector3.new(arenaCenter.X + dx * s, pt.Y, arenaCenter.Z + dz * s)
                                        end
                                        return pt
                                    else
                                        return Vector3.new(
                                            math.clamp(pt.X, -64, 64),
                                            pt.Y,
                                            math.clamp(pt.Z, arenaCenter.Z - 49, arenaCenter.Z + 49)
                                        )
                                    end
                                end

                                local minCoreDist = math.max(3.0, (mobRadius or 1.5) * 0.65)
                                if Config.FarmMode == "Walk" then
                                    -- Maintain 3D-compensated distance along player's current angle, clamped inside Boss Arena bounds
                                    local flatFromMob = Vector3.new(hrp.Position.X - targetPos.X, 0, hrp.Position.Z - targetPos.Z)
                                    local awayDir = (flatFromMob.Magnitude > 0.5) and flatFromMob.Unit or -flatLook
                                    local initialXZ = clampBossArenaXZ(targetPos + (awayDir * safeDist))
                                    local groundRay = workspace:Raycast(Vector3.new(initialXZ.X, math.max(hrp.Position.Y, targetPos.Y) + 18, initialXZ.Z), Vector3.new(0, -80, 0), rayParams)
                                    if not groundRay then
                                        groundRay = workspace:Raycast(targetPos + Vector3.new(0, 18, 0), Vector3.new(0, -80, 0), rayParams)
                                    end
                                    local groundY = groundRay and (groundRay.Position.Y + 2.8) or hrp.Position.Y
                                    local dy = math.abs(targetPos.Y - groundY)
                                    local effDist = safeDist
                                    if dy > 1.0 and (safeDist * safeDist) > (dy * dy) then
                                        effDist = math.max(minCoreDist, math.sqrt((safeDist * safeDist) - (dy * dy)))
                                    end
                                    walkTargetDist = effDist
                                    local standXZ = (effDist ~= safeDist) and clampBossArenaXZ(targetPos + (awayDir * effDist)) or initialXZ
                                    if arenaCenter then
                                        local actualD = Vector3.new(standXZ.X - targetPos.X, 0, standXZ.Z - targetPos.Z).Magnitude
                                        if actualD < (effDist * 0.72) then
                                            local toCenter = Vector3.new(arenaCenter.X - targetPos.X, 0, arenaCenter.Z - targetPos.Z)
                                            if toCenter.Magnitude > 1 then
                                                standXZ = clampBossArenaXZ(targetPos + (toCenter.Unit * effDist))
                                            end
                                        end
                                    end
                                    playerPos = Vector3.new(standXZ.X, groundY, standXZ.Z)
                                    targetFloorY = groundY
                                else
                                    local initialXZ = clampBossArenaXZ(targetPos - (flatLook * safeDist))
                                    local groundRay = workspace:Raycast(Vector3.new(initialXZ.X, math.max(hrp.Position.Y, targetPos.Y) + 18, initialXZ.Z), Vector3.new(0, -80, 0), rayParams)
                                    local baseY = groundRay and math.min(targetPos.Y, groundRay.Position.Y + 2.8) or targetPos.Y
                                    local desiredY = baseY + farmH
                                    local dy = math.abs(desiredY - targetPos.Y)
                                    local effDist = safeDist
                                    if dy > 1.0 and (safeDist * safeDist) > (dy * dy) then
                                        effDist = math.max(minCoreDist, math.sqrt((safeDist * safeDist) - (dy * dy)))
                                    end
                                    walkTargetDist = effDist
                                    local standXZ = (effDist ~= safeDist) and clampBossArenaXZ(targetPos - (flatLook * effDist)) or initialXZ
                                    playerPos = Vector3.new(standXZ.X, desiredY, standXZ.Z)
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
                            local tooCloseWalk = false
                            if Config.FarmMode == "Walk" then
                                -- ==================== WALK MODE (DUNGEON & FIELD) ====================
                                local cfgWalkSpd = tonumber(Config.WalkFarmSpeed) or 28
                                hum.WalkSpeed = (cfgWalkSpd > 16) and math.max(hum.WalkSpeed, cfgWalkSpd) or math.max(hum.WalkSpeed, 26)
                                local flatDiff = Vector3.new(playerPos.X - hrp.Position.X, 0, playerPos.Z - hrp.Position.Z)
                                local flatDist = flatDiff.Magnitude
                                local curMobDist = Vector3.new(hrp.Position.X - targetPos.X, 0, hrp.Position.Z - targetPos.Z).Magnitude
                                local stopTol = inDungeon and 0.9 or 0.75
                                tooCloseWalk = (curMobDist < (walkTargetDist - 1.2))

                                if inDungeon then
                                    if curMobDist > (walkTargetDist + 0.15) or flatDist > stopTol then
                                        hum:MoveTo(playerPos)
                                    else
                                        hum:Move(Vector3.zero, false)
                                        hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
                                    end
                                else
                                    if curMobDist > (walkTargetDist + 0.15) or (flatDist > 0.25 and (curMobDist < (walkTargetDist - stopTol) or flatDist > (stopTol + 0.6))) then
                                        hum:MoveTo(playerPos)
                                    else
                                        hum:Move(Vector3.zero, false)
                                        hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
                                    end
                                end
                            else
                                -- ==================== WARP / TELEPORT MODE (DUNGEON & FIELD) ====================
                                -- Instant zero-latency warp straight to safe combat position (never clipped into wall)
                                local lookPt = targetPos + Vector3.new(0, 0.6, 0)
                                hrp.CFrame = ((lookPt - playerPos).Magnitude > 0.1) and CFrame.lookAt(playerPos, lookPt) or CFrame.new(playerPos)
                                hrp.Velocity = Vector3.zero
                                hrp.AssemblyLinearVelocity = Vector3.zero
                                hrp.AssemblyAngularVelocity = Vector3.zero
                            end

                            -- 2. Target Lock & Server Combat Activation (avoid LumiLockTarget chase hijack & 0.8s range-entry blackout)
                            local curObj = LocalPlayer:FindFirstChild("CurrentTarget")
                            local targetChanged = (currentCombatTarget ~= target) or (not curObj or curObj.Value ~= target)
                            setClientCurrentTarget(target)
                            currentCombatTarget = target
                            local inAttackReach = ((targetPos - hrp.Position).Magnitude <= (safeDist + 2.5))
                            local enteredReach = inAttackReach and (BossHunt.wasInAttackRange ~= true or BossHunt.lastSyncedTarget ~= target)
                            BossHunt.wasInAttackRange = inAttackReach
                            if targetChanged or enteredReach or (inAttackReach and (now - (BossHunt.lastTargetSync or 0)) >= 0.45) or ((now - (BossHunt.lastTargetSync or 0)) >= 0.8) then
                                BossHunt.lastTargetSync = now
                                BossHunt.lastSyncedTarget = target
                                pcall(SetTarget.FireServer, SetTarget, target, false, true)
                            end
                        else
                            -- Still ensure Target Lock if targetHrp missing
                            setClientCurrentTarget(target)
                        end


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
                    BossHunt.wasInAttackRange = false
                    BossHunt.lastSyncedTarget = nil
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
        task.wait(0.08) -- ~12.5 Hz responsive skill evaluation without starving scheduler
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
pcall(function()
    trackConn(workspace.AttributeChanged:Connect(function(attrName)
        if type(attrName) == "string" and attrName:find("^BossAlive_") and workspace:GetAttribute(attrName) == true then
            if isScriptAlive() and (Config.BossOnly or Config.BossServerHop or Config.AutoBoss) then
                local activeSel = (Config.SelectedBosses and #Config.SelectedBosses > 0) and Config.SelectedBosses or Config.SelectedBoss
                local wbEntries, isWorldTarget = BossHunt.getWorldBossEntries(activeSel, getPlayerLevel())
                local matchedSpawn = false
                if isWorldTarget and wbEntries then
                    for _, wb in ipairs(wbEntries) do
                        if attrName == ("BossAlive_" .. wb.Id) then
                            matchedSpawn = true
                            break
                        end
                    end
                elseif not isWorldTarget then
                    matchedSpawn = true
                end
                if matchedSpawn then
                    BossHunt.missingSince = nil
                    BossHunt.lastMissingKey = ""
                    BossHunt.lastCheckTime = -999
                end
            end
        end
    end))
end)

task.spawn(function()
    while isScriptAlive() do
        task.wait((Config.BossOnly or Config.BossServerHop) and 1.0 or 1.5)
        if isInsideDungeon() or isEnteringDungeon or isWaitingForParty or BossHunt.isServerHopping then continue end

        -- 1. Track last normal farm zone when in normal field
        local inBoss, bossArenaName = isPlayerInBossArena()
        if not inBoss and Config.CurrentZone and not Config.CurrentZone:find("^Boss") then
            lastNormalFarmZone = Config.CurrentZone
        end

        local activeBossSel = (Config.SelectedBosses and #Config.SelectedBosses > 0) and Config.SelectedBosses or Config.SelectedBoss

        -- Validate activeBossFight hasn't died/changed outside SelectedBoss
        if activeBossFight then
            local m = activeBossFight.model
            if not m or not m.Parent or not isMonsterAlive(m) or not BossHunt.isMatchingBoss(m, activeBossSel) then
                activeBossFight = nil
            end
        end

        -- Adopt any alive matching boss in the current arena BEFORE Periodic Inspection can warp away
        if not activeBossFight and inBoss then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local localBoss = BossHunt.findMatchingBoss(activeBossSel, hrp.Position, 260)
                if localBoss then
                    BossHunt.missingSince = nil
                    local bp = getMonsterCombatPart(localBoss)
                    activeBossFight = {
                        model = localBoss,
                        name = localBoss.Name,
                        pos = (bp and bp.Position) or hrp.Position,
                        time = os.clock(),
                    }
                    currentCombatTarget = localBoss
                    trackBossDeath(localBoss)
                end
            end
        end

        -- 2. Boss Arena Safety Watchdog (ONLY when NOT in BossOnly/BossServerHop and NOT mid-inspection)
        if Config.AutoBoss and Config.AutoWarpToBoss and not Config.BossOnly and not Config.BossServerHop and inBoss and activeBossFight ~= nil and not isCheckingBossArena and not BossHunt.isInspecting and not isReturningFromBoss and not isWarpingZone then
            local aliveBoss = isAnyBossAliveInArena(bossArenaName, activeBossSel)
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

        -- 4. Normal Progression check (disabled while BossOnly / BossServerHop or inspecting boss)
        if Config.AutoProgression and not Config.BossOnly and not Config.BossServerHop and not isCheckingBossArena and not BossHunt.isInspecting and not activeBossFight and not inBoss and not isEnteringDungeon and not isWaitingForParty then
            pcall(function()
                checkAutoProgression(false)
            end)
        end

        -- 5. Periodic / Immediate Boss Inspection & Boss Server Hop
        if (Config.BossOnly or Config.BossServerHop or Config.AutoBoss) and not isEnteringDungeon and not isWaitingForParty and not isReturningFromBoss and not isSelling and not isWarpingZone and not isCheckingBossArena and not BossHunt.isInspecting and not BossHunt.isServerHopping then
            if not activeBossFight then
                local now = os.clock()
                local interval = (Config.BossOnly or (Config.BossServerHop and not BossHunt.missingSince)) and 2.2 or ((BossHunt.missingSince and Config.BossServerHop) and 1.0 or 12)
                if (now - (BossHunt.lastCheckTime or -999)) >= interval then
                    BossHunt.lastCheckTime = now
                    pcall(function()
                        executeBossInspection(true, false)
                    end)
                end
            end
        end
    end
end)

-- Event Listener: Instant Progression on Level Up
pcall(function()
    trackConn(LocalPlayer:GetAttributeChangedSignal("Level"):Connect(function()
        if not isScriptAlive() or not canScriptMoveOrWarp() then return end
        if Config.AutoProgression and not Config.BossOnly and not Config.BossServerHop and not BossHunt.isServerHopping then
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
