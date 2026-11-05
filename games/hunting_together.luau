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

-- Core Remotes
local SetTarget = getRemote("SetTarget", 3)
local AttackAnim = getRemote("AttackAnim", 3)
local AttackAnimU = getRemote("AttackAnimU")
local UseSkill = getRemote("UseSkill", 3)
local LearnSkill = getRemote("LearnSkill", 3)
local SetAutoSkill = getRemote("SetAutoSkill")
local AllocateStat = getRemote("AllocateStat", 3)
local UseItem = getRemote("UseItem", 3)
local PickupDrop = getRemote("PickupDrop", 3)
local DungeonAction = getRemote("DungeonAction", 1)
local DungeonPrompt = getRemote("DungeonPrompt", 1)
local PartyAction = getRemote("PartyAction", 1)
local PartyInvite = getRemote("PartyInvite", 1)

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

local function safeDestroyExistingUI()
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
end
pcall(safeDestroyExistingUI)

-- Forward declarations for scope stability across functions
local currentCombatTarget = nil
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
local isLooting = false
local isOpeningBox = false
local isKnockingHouse = false
local isPullingGacha = false
local isReturningFromBoss = false
local activeBossFight = nil
local lastBoxScanTime = 0
local isEnteringDungeon = false
local isOpeningDungeonChest = false
local isWaitingForParty = false
local forceStartDungeonFlag = false
local lastDungeonEnterAttempt = 0
local lastDungeonKeyBuyTime = 0
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
    isEnteringDungeon = false
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

local function getMonsterCombatPart(monster)
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

local OpenLootBox = getRemote("OpenLootBox")
local WarpTo = getRemote("WarpTo", 1)
local DailyClaim = getRemote("DailyClaim", 1)
local RespawnChoice = getRemote("RespawnChoice")
local EquipItem = getRemote("EquipItem")
local EquipWeapon = getRemote("EquipWeapon")
local CardAction = getRemote("CardAction")
local QuestAction = getRemote("QuestAction")
local AchieveAction = getRemote("AchieveAction")
local RefineWeapon = getRemote("RefineWeapon")
local PetAction = getRemote("PetAction")
local ShopSell = getRemote("ShopSell")
local ShopSellMany = getRemote("ShopSellMany")
local ShopSellJunk = getRemote("ShopSellJunk")
local BagSell = getRemote("BagSell")
local Dash = getRemote("Dash")
local BossFx = getRemote("BossFx")
local MonsterProjectile = getRemote("MonsterProjectile")
local CombatFx = getRemote("CombatFx")
local GachaPull = getRemote("GachaPull")
local EventNpcAction = getRemote("EventNpcAction")
local TrickTreatFx = getRemote("TrickTreatFx")

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
local SCRIPT_FILE = "hunting_together_script.lua"

local Config = {
    -- Window & Controls
    ToggleKey = "RightControl",
    AutoSave = true,
    AutoExecuteOnTeleport = true,

    -- Auto Farm & Boss Hunter
    AutoFarm = false,
    FarmMode = "Fly",            -- "Fly" (โหมดบินลอยตัว) or "Walk" (โหมดเดินปกติบนพื้น)
    WalkFarmSpeed = 26,          -- ความเร็วในการเดินฟาร์มเมื่ออยู่ในโหมดเดินปกติ (Walk Mode)
    SafeFarm = true,
    SafeFarmExploit = true,      -- ช่องโหว่มุมอับสายตา & ระยะปลอดภัยสมบูรณ์แบบ
    SafeFarmHeight = 5.5,        -- ความสูงลอยเหนือหัวมอนสเตอร์ (พ้นระยะกวาดแนวนอน)
    AdaptiveDistance = true,     -- ปรับระยะห่างตามอาวุธ (Archer/Mage 14 studs, Melee 5.8 studs)
    FarmDistance = 14.0,         -- ค่าตั้งต้นระยะฟาร์ม
    AttackDelay = 0.15,
    SelectedMonster = "All",
    AutoBoss = true,            -- Automatically hunt Bosses & Mini-Bosses
    AutoWarpToBoss = false,     -- Automatically warp to World Boss Arenas (ปิดไว้เป็นค่าเริ่มต้นเพื่อป้องกันการวาปไปกลับเอง)
    PrioritizeBoss = true,      -- Attack Boss first when present
    BossOnly = false,           -- Farm ONLY Bosses and Mini-Bosses
    SelectedBoss = "All Bosses",-- Specific Boss or "All Bosses"
    ReturnToProgressionAfterBoss = true, -- ตีบอสเสร็จกลับไปฟาร์มตาม Auto Lv.99 ทันที
    BossCheckInterval = 75,     -- Seconds between periodic Boss Arena inspections
    KillAura = false,
    KillAuraRadius = 20,
    MaxTargetDistance = 70,     -- Keep search strictly within active field
    AutoUseSkills = true,
    AutoUseBuffs = true,
    SelectedSkillSlots = { "ช่อง 1 (Slot 1)", "ช่อง 2 (Slot 2)", "ช่อง 3 (Slot 3)", "ช่อง 4 (Slot 4)", "ช่อง 5 (Slot 5)", "ช่อง 6 (Slot 6)", "ช่อง 7 (Slot 7)" },
    
    -- Auto Equip & Gear
    AutoEquipBest = true,
    AutoEquipBestWeapon = true,
    AutoEquipCards = true,
    AutoRefine = false,
    
    -- Auto Sell System (เลือกระดับได้)
    AutoSell = true,
    AutoSellOnFull = true,
    AutoSellPeriodic = false,
    AutoSellInterval = 120,
    AutoSellQuickVisit = true,  -- Mandatory for non-premium players so server accepts BagSell
    SellTier1 = true,
    SellTier2 = true,
    SellTier3 = true,
    SellTier4 = false,
    SellTier5 = false,
    MaxSellTier = "Up to Tier 3",
    MaxSellRarity = "Up to Rare",
    SellWeapons = true,
    SellArmors = true,
    SellAccessories = true,
    SellJunkDrops = true,
    ProtectRefined = true,
    ProtectBestGear = true,
    
    -- Auto Loot
    AutoLoot = true,
    LootPriority = true,
    LootTeleport = false,       -- Remote vacuum prevents warping/jittering
    LootRadius = 100,
    AutoOpenLootBox = false,    -- ปิดไว้เป็นค่าเริ่มต้นเพื่อป้องกันการแวบไปเปิดกล่องเอง
    
    -- Level Progression (1 - 99)
    AutoProgression = false,
    CurrentZone = "",
    
    -- Auto Stats & Skills
    AutoUpgradeSkills = true,
    AutoAllocateStats = true,
    StatPreset = "Auto (Detect by Job)",
    
    -- Rewards & Quests
    AutoClaimQuests = true,
    AutoClaimDaily = true,
    AutoClaimAchieve = true,
    AutoPet = true,
    
    -- Survival & Potions
    AutoHpPotion = true,
    HpThreshold = 55,
    AutoSpPotion = true,
    SpThreshold = 30,
    AutoRespawn = true,
    
    -- Auto Dodge & Evasion (หลบหลีกอัตโนมัติ 1000% Pre-Hit System)
    AutoDodge = true,
    DodgeBossTelegraph = true,
    DodgeGreenCircle = true,      -- เข้าไปหลบในวงกลมสีเขียว (Safe Zone) ทันทีที่มีวงเขียวขึ้นมา
    DodgeProjectiles = true,
    DodgeMonsterAttack = true,    -- หลบการง้างตีของมอนสเตอร์ล่วงหน้า 1000% (AnimAttack Telegraph)
    DodgeMonsterSkill = true,     -- หลบการร่ายสกิลของมอนสเตอร์ล่วงหน้า (AnimSkill Telegraph)
    DodgeOnHurt = true,
    DodgeFlank = true,
    DodgeDistance = 18,
    DodgeCooldown = 0.25,
    DodgeDuration = 0.45,
    DodgeNotify = false,
    
    -- 🎃 Halloween Event Automation (กิจกรรมฮาโลวีน)
    AutoHalloween = true,
    AutoTrickTreat = false,       -- ปิดไว้เพื่อไม่ให้แวบไปเคาะบ้านแม่มดเอง
    TrickTreatThreshold = 100,
    TrickTreatAutoVisit = false,
    AutoHalloweenGacha = false,
    GachaPullType = "10x Pull (100 Heads)",
    HuntHalloweenPumpkins = true,
    AutoHalloweenBoxes = false,   -- ปิดไว้เพื่อไม่ให้ดูดวาร์ปไปหากล่องฮาโลวีน
    AutoClaimEventRewards = true,
    
    -- 🏰 Dungeon Automation (Skull King's Crypt & Dungeons)
    AutoDungeon = false,          -- ปิดไว้เป็นค่าเริ่มต้น ไม่ให้แวบเข้าดันเจี้ยนเอง
    SelectedDungeon = "halloween",             -- "halloween" (Skull King's Crypt)
    DungeonDifficulty = "easy",               -- "easy" or "normal"
    DungeonForceSolo = true,                  -- ออกจากปาร์ตี้อื่นอัตโนมัติเพื่อให้สามารถเข้าคนเดียวได้ทันที
    
    -- 👥 Dungeon Party & Matchmaking
    DungeonPartyMode = "Solo",                -- "Solo" (ลงคนเดียว) or "Party" (สร้างปาร์ตี้ลงด้วยกัน)
    PartyTargetMembers = 2,                   -- จำนวนคนในตี้ที่ต้องการก่อนเริ่มลงดันเจี้ยน (2 - 4 คน)
    PartyWaitTimeout = 30,                    -- เวลารอคนตอบรับเข้าตี้ (วินาที) ก่อนเริ่มสร้างห้อง
    PartyInviteTarget = "All Server",         -- "All Server", "Friends Only", "Nearby Gate"
    PartyAutoInvite = true,                   -- ส่งคำเชิญชวนเข้าตี้หมู่อัตโนมัติเมื่อเริ่ม
    AutoAcceptParty = true,                   -- ตอบรับคำเชิญเข้าปาร์ตี้อัตโนมัติ (สำหรับตัวเด็ก / Alt account)
    PartyAcceptFilter = "Anyone",             -- "Anyone", "Friends Only", "Whitelist"
    PartyWhitelistUsers = "",                 -- รายชื่อไอดีหลัก เช่น "MainAcc1, MainAcc2"
    
    AutoBuyDungeonKey = false,
    MaxDungeonKeysToBuy = 10,
    AutoReadyDungeon = true,
    AutoReviveTeammates = true,
    PrioritizeDungeonPillars = true,
    AutoKickSkulls = true,
    PrioritizeDungeonBoss = true,
    AutoClaimExitChest = true,
    AutoSecretChests = true,
    AutoLeaveOnClear = true,
    AutoRepeatDungeon = false,
    ReturnToFarmAfterDungeon = false,          -- ปิดไว้เพื่อไม่ให้แอบเปิด Auto Farm เอง
    DungeonSafeHeight = 5.2,                  -- ความสูงลอยตัวเหนือกราวด์แอตแทกของบอส
    DungeonAttackDelay = 0.12,                -- ความเร็วโจมตีในดันเจี้ยน

    -- 🎥 Streamer Mode (โหมดสตรีมเมอร์ & ปกปิดชื่อ)
    StreamerMode = false,
    StreamerFakeName = "Protected Player",
    HideOverheadName = true,
    SpoofUIAndLeaderboard = true,
    HideOthersNames = false,

    -- Misc & Performance
    InfiniteStamina = true,
    AntiAFK = true,
    FastMode = false,
}

local function canScriptMoveOrWarp()
    if not isScriptAlive() then return false end
    if isEnteringDungeon or isWaitingForParty then return true end
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
    local h = workspace:FindFirstChild("Halloween")
    local walls = {}
    if h then
        local w = h:FindFirstChild("Wall")
        if w then table.insert(walls, w) end
        local b = h:FindFirstChild("Blockers")
        if b then table.insert(walls, b) end
        local c = h:FindFirstChild("Cave")
        if c then table.insert(walls, c) end
        local barriers = h:FindFirstChild("Barriers")
        if barriers then table.insert(walls, barriers) end
    end
    return walls
end

local function hasDungeonLineOfSight(pos1, pos2)
    local wallInstances = getDungeonWallInstances()
    if #wallInstances == 0 then return true end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = wallInstances

    local p1 = Vector3.new(pos1.X, 62.0, pos1.Z)
    local p2 = Vector3.new(pos2.X, 62.0, pos2.Z)
    local dir = p2 - p1
    if dir.Magnitude < 1.0 then return true end

    local hit = workspace:Raycast(p1, dir, rayParams)
    return (hit == nil)
end

local function getDungeonSafeCombatPosition(targetPos, mobLook, safeDist, isRanged)
    local wallInstances = getDungeonWallInstances()

    -- Strict melee distance in dungeon: 3.8 - 4.2 studs (guaranteed weapon reach, 0% misses!)
    local effectiveDist = isRanged and math.clamp(safeDist, 8.0, 14.0) or 4.0

    -- All Halloween dungeon ground floors are at Y = 60.0. Player standing on floor has HRP at Y = 62.8
    local floorY = 62.8
    local floorRay = workspace:Raycast(Vector3.new(targetPos.X, 75.0, targetPos.Z), Vector3.new(0, -35.0, 0))
    if floorRay and floorRay.Instance and floorRay.Instance.Name:lower():find("ceiling") == nil then
        floorY = floorRay.Position.Y + 2.8
    end

    if #wallInstances == 0 then
        local p = targetPos - (mobLook * effectiveDist)
        return Vector3.new(p.X, floorY, p.Z)
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = wallInstances

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local toPlayer = hrp and (hrp.Position - targetPos) or -mobLook
    local flatToPlayer = Vector3.new(toPlayer.X, 0, toPlayer.Z)
    local primaryDir = flatToPlayer.Magnitude > 0.5 and flatToPlayer.Unit or -mobLook

    -- Test multiple candidate directions to ensure player is placed in open corridor space:
    local candidateDirs = {
        primaryDir,
        -primaryDir,
        Vector3.new(-primaryDir.Z, 0, primaryDir.X),
        Vector3.new(primaryDir.Z, 0, -primaryDir.X),
        -mobLook,
    }

    local bestPos = nil
    local bestClearance = -1

    for _, dir in ipairs(candidateDirs) do
        local checkDist = effectiveDist + 3.0
        local rayOrigin = Vector3.new(targetPos.X, 62.0, targetPos.Z)
        local hit = workspace:Raycast(rayOrigin, dir * checkDist, rayParams)
        local clearance = hit and hit.Distance or checkDist

        if clearance >= (effectiveDist + 2.5) then
            local candidatePos = targetPos + (dir * effectiveDist)
            return Vector3.new(candidatePos.X, floorY, candidatePos.Z)
        elseif clearance > bestClearance then
            bestClearance = clearance
            local clampedDist = math.max(2.8, math.min(effectiveDist, clearance - 1.8))
            bestPos = targetPos + (dir * clampedDist)
        end
    end

    if bestPos then
        return Vector3.new(bestPos.X, floorY, bestPos.Z)
    end

    local fallback = targetPos - (mobLook * 3.8)
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
            if tPart and (hrp.Position - tPart.Position).Magnitude <= 35 then
                return currentCombatTarget
            end
        end
    end

    local bestTarget = nil
    local bestScore = -math.huge

    local dStep = tonumber(workspace:GetAttribute("DungeonStep")) or 1
    local inPlazaOrBeyond = (hrp.Position.X < -3880)

    for _, mob in ipairs(candidateMobs) do
        if isMonsterAlive(mob) and mob:GetAttribute("SealShield") ~= true then
            local mPart = getMonsterCombatPart(mob)
            if mPart then
                local dist = (hrp.Position - mPart.Position).Magnitude
                local mName = mob.Name:lower()
                local mId = tostring(mob:GetAttribute("MonsterId") or "")
                local isPillar = (mName:find("pillar") ~= nil or mName:find("ritual") ~= nil or mName:find("seal") ~= nil or mId == "dgn_ritual_pillar")
                local isBoss = (mob:GetAttribute("IsBoss") == true or mob:GetAttribute("IsMiniBoss") == true or mName:find("boss") or mName:find("crypt") or mName:find("witch") or mId:find("boss") or mId:find("witch"))
                local score = 1000 - dist

                -- 1. Pillar priority: ABSOLUTE TOP PRIORITY if alive pillars exist
                if isPillar then
                    score = 1000000 - dist
                -- 2. Boss & Mini-Boss priority (only when unshielded and no pillars alive)
                elseif isBoss and (Config.PrioritizeDungeonBoss or Config.PrioritizeBoss) and (dist <= 65 or inPlazaOrBeyond) then
                    if alivePillarCount > 0 then
                        score = -1000000 -- NEVER target boss while pillars exist!
                    else
                        score = 50000 - dist
                    end
                -- 3. Close aggro monsters along corridor (clears corridor cleanly without wall snag)
                elseif dist <= 35 then
                    score = 30000 - dist
                elseif dist <= 75 then
                    score = 15000 - dist
                end

                -- Line of sight wall penalty: if monster is behind a wall and not a pillar, deprioritize so we don't try to aggro through walls
                if not isPillar and not hasDungeonLineOfSight(hrp.Position, mPart.Position) then
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
            cachedExitChestPrompt = desc
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

    -- 1. Auto Secret Chests nearby
    if Config.AutoSecretChests and (os.clock() - lastSecretChestClaimTime > 2.0) then
        local h = workspace:FindFirstChild("Halloween")
        if h then
            for _, c in ipairs(h:GetChildren()) do
                if c.Name == "SecretChest" then
                    local prompt = c:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.Enabled then
                        local cPos = c:GetPivot().Position
                        if (pPos - cPos).Magnitude <= 32 then
                            lastSecretChestClaimTime = os.clock()
                            hrp.CFrame = CFrame.new(cPos.X, 60.5, cPos.Z)
                            task.wait(0.12)
                            if fireproximityprompt then
                                fireproximityprompt(prompt)
                            else
                                pcall(function()
                                    prompt:InputHoldBegin()
                                    task.wait(prompt.HoldDuration or 0.2)
                                    prompt:InputHoldEnd()
                                end)
                            end
                            task.wait(0.2)
                            return
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

    -- Monotonic forward waypoint advancement: never clamp backward (eliminates oscillation trap!)
    currentDungeonWpIndex = currentDungeonWpIndex or 2
    if closestIdx > currentDungeonWpIndex then
        currentDungeonWpIndex = closestIdx
    end

    -- Gate progression on active objectives:
    local mFolder = workspace:FindFirstChild("Monsters")
    local hasAlivePillars = false
    local hasAliveWitch = false
    if mFolder then
        for _, m in ipairs(mFolder:GetChildren()) do
            if m:IsA("Model") and isMonsterAlive(m) then
                local mName = m.Name:lower()
                local mId = tostring(m:GetAttribute("MonsterId") or "")
                if mName:find("pillar") or mName:find("ritual") or mId == "dgn_ritual_pillar" then
                    hasAlivePillars = true
                elseif mName:find("witch") or mId:find("witch") then
                    hasAliveWitch = true
                end
            end
        end
    end

    -- Gate progression on active objectives:
    -- Plaza Ritual Pillars gate: only applies while in/before Section 2 (WP <= 18)
    if hasAlivePillars and currentDungeonWpIndex <= 18 and currentDungeonWpIndex > 14 then
        currentDungeonWpIndex = 14
    -- Witch Lair gate: only applies while in/before Section 3 (WP <= 24)
    elseif hasAliveWitch and currentDungeonWpIndex > 21 then
        currentDungeonWpIndex = 21
    end

    local targetWp = DungeonPathWaypoints[currentDungeonWpIndex]
    if not targetWp then return end

    local flatTarget = Vector3.new(targetWp.X, 0, targetWp.Z)
    local flatPlayer = Vector3.new(pPos.X, 0, pPos.Z)
    local dist = (flatTarget - flatPlayer).Magnitude

    if dist <= 14 then
        local nextIdx = math.min(#DungeonPathWaypoints, currentDungeonWpIndex + 1)
        local canAdvance = true
        if hasAlivePillars and currentDungeonWpIndex <= 18 and nextIdx > 14 then
            canAdvance = false
        elseif hasAliveWitch and nextIdx > 21 then
            canAdvance = false
        end
        if canAdvance then
            currentDungeonWpIndex = nextIdx
            targetWp = DungeonPathWaypoints[currentDungeonWpIndex]
            flatTarget = Vector3.new(targetWp.X, 0, targetWp.Z)
            dist = (flatTarget - flatPlayer).Magnitude
        end
    end

    if dist < 1.5 then return end

    local dir = (flatTarget - flatPlayer).Unit
    local stepDist = math.min(dist, 4.2)

    local wallInstances = getDungeonWallInstances()
    if #wallInstances > 0 then
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Include
        rayParams.FilterDescendantsInstances = wallInstances
        local stepCheck = workspace:Raycast(pPos + Vector3.new(0, 1.5, 0), dir * (stepDist + 1.2), rayParams)
        if stepCheck then
            stepDist = math.max(0, stepCheck.Distance - 1.5)
        end
    end
    if stepDist <= 0.2 then return end

    local nextPos = pPos + (dir * stepDist)
    local targetFloorY = (targetWp.Y > 65) and targetWp.Y or 60.5
    local floorRay = workspace:Raycast(Vector3.new(nextPos.X, 85, nextPos.Z), Vector3.new(0, -50, 0))
    if floorRay and floorRay.Instance and floorRay.Instance.Name:lower():find("ceiling") == nil then
        targetFloorY = floorRay.Position.Y + 2.8
    end
    nextPos = Vector3.new(nextPos.X, targetFloorY, nextPos.Z)
    hrp.CFrame = CFrame.lookAt(nextPos, nextPos + dir)
    hrp.Velocity = Vector3.zero
    hrp.AssemblyLinearVelocity = Vector3.zero
end

local function executeClaimExitChest()
    if not canScriptMoveOrWarp() or not Config.AutoClaimExitChest then return end
    if isOpeningDungeonChest then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    currentDungeonWpIndex = 1

    local targetPrompt = nil
    if cachedExitChestPrompt and cachedExitChestPrompt.Parent and cachedExitChestPrompt.Enabled then
        targetPrompt = cachedExitChestPrompt
    else
        local h = workspace:FindFirstChild("Halloween")
        if h then
            for _, obj in ipairs(h:GetChildren()) do
                if obj.Name:lower():find("chest") then
                    local p = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if p and p.Enabled then
                        targetPrompt = p
                        cachedExitChestPrompt = p
                        break
                    end
                end
            end
        end
        if not targetPrompt then
            local mapFolder = workspace:FindFirstChild("Map") or workspace
            for _, obj in ipairs(mapFolder:GetChildren()) do
                if obj:IsA("Model") or obj:IsA("Folder") then
                    for _, p in ipairs(obj:GetChildren()) do
                        if p:IsA("ProximityPrompt") and p.Name == "ChestPrompt" and p.Enabled then
                            local ownerId = p:GetAttribute("OwnerUserId")
                            if ownerId == nil or ownerId == LocalPlayer.UserId then
                                targetPrompt = p
                                cachedExitChestPrompt = p
                                break
                            end
                        end
                    end
                end
                if targetPrompt then break end
            end
        end
    end

    local chestPos = Vector3.new(-4038, 60, -260)
    if targetPrompt and targetPrompt.Parent and targetPrompt.Parent:IsA("BasePart") then
        chestPos = targetPrompt.Parent.Position + Vector3.new(0, 3, 0)
    end

    isOpeningDungeonChest = true
    if WindUI and WindUI.Notify then
        WindUI:Notify({
            Title = "Dungeon Cleared! 🏆",
            Content = "กำลังเปิดหีบรับรางวัล Tier VI...",
            Duration = 3,
            Icon = "gift"
        })
    end

    -- Approach chest safely
    hrp.CFrame = CFrame.new(chestPos)
    task.wait(0.3)

    if targetPrompt then
        for _ = 1, 3 do
            if fireproximityprompt then
                fireproximityprompt(targetPrompt)
            else
                pcall(function()
                    targetPrompt:InputHoldBegin()
                    task.wait(0.1)
                    targetPrompt:InputHoldEnd()
                end)
            end
            task.wait(0.2)
        end
    end

    dungeonChestsClaimed = dungeonChestsClaimed + 1
    task.wait(3.0)

    -- Leave dungeon if configured
    if Config.AutoLeaveOnClear then
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "Dungeon",
                Content = "รับของรางวัลเสร็จสิ้น กำลังกลับสู่เมือง...",
                Duration = 2.5,
                Icon = "log-out"
            })
        end
        pcall(registerQueueOnTeleport)
        pcall(function()
            if DungeonAction then
                DungeonAction:FireServer("leave")
            end
        end)
    end

    task.wait(2.0)
    isOpeningDungeonChest = false
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

    -- 2. Keys & Free Runs Check
    local keys = getDungeonKeys()
    local silver = getPlayerSilver()

    if keys <= 0 and Config.AutoBuyDungeonKey then
        if silver >= 500000 then
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "Auto Buy Key",
                    Content = "กำลังซื้อกุญแจดันเจี้ยน (500,000 Silver)...",
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
        else
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "Out of Silver & Keys",
                    Content = "Silver ไม่พอซื้อกุญแจ (ต้องการ 500k)",
                    Duration = 3,
                    Icon = "alert-triangle"
                })
            end
            return
        end
    end

    isEnteringDungeon = true
    currentCombatTarget = nil
    stopCombatAndTargeting()

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
    task.wait(0.5)

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
    else
        local waitElapsed = 0
        while waitElapsed < 6 and not isInsideDungeon() do
            task.wait(0.5)
            waitElapsed = waitElapsed + 0.5
        end
        isEnteringDungeon = false
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
    if not isManual and not canScriptMoveOrWarp() and not isCheckingBossArena then return end
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
        if WarpTo then
            WarpTo:FireServer(targetField)
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
local activeBossFight = nil
local isReturningFromBoss = false
local trackedBossDeaths = {}
local isCheckingBossArena = false
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
    if isInsideDungeon() then return end
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

            -- 2. Fast loot vacuum around boss death area (catches rare drops, chests, boss pet eggs)
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local dropsFolder = workspace:FindFirstChild("Drops")

            for sweep = 1, 3 do
                if dropsFolder and hrp and hrp.Parent then
                    for _, d in ipairs(dropsFolder:GetChildren()) do
                        if d:IsA("BasePart") then
                            local dDist = (d.Position - hrp.Position).Magnitude
                            if dDist <= 85 then
                                pcall(function()
                                    PickupDrop:FireServer(true)
                                    PickupDrop:FireServer(d)
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
                task.wait(0.3)
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

local function trackBossDeath(boss)
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

local outOfZoneTicks = 0
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
    if Config.AutoEquipBest and EquipItem then
        pcall(function()
            EquipItem:FireServer("@best")
        end)
    end

    -- 2. Native auto card equip
    if Config.AutoEquipCards and CardAction then
        pcall(function()
            CardAction:FireServer("auto")
        end)
    end

    -- 3. Custom Best Weapon Selector
    if Config.AutoEquipBestWeapon and EquipWeapon then
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
                EquipWeapon:FireServer(bestWepKey)
            end
        end)
    end
end

-- ==================== HELPER FUNCTIONS ====================
local function getMonsterList()
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

-- ==================== SMART SKILLS & COMBAT ENGINE ====================
local skillLastCast = {}

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

local SkillCooldownDefaults = {
    twinfang = 0.55,
    venomknife = 7.0,
    shadowburst = 6.0,
    cross_slash = 5.0,
    sonicblow = 8.0,
    soulstrike = 3.0,
    firebolt = 3.0,
    coldbolt = 3.0,
    lightningbolt = 3.0,
    magnum_break = 6.0,
    bash = 2.0,
    arrowshower = 6.0,
    double_strafe = 2.0,
    vanish = 20.0,
    stealth = 15.0,
    iaigiri = 0.55,
    obororanbu = 2.5,
    issen = 3.0,
    meikyo = 8.0,
    shukuchi = 4.0,
}

local function castSmartSkill(skillId, target)
    if not skillId or skillId == "" then return false end
    local now = os.clock()
    local cd = SkillCooldownDefaults[skillId] or 3.0

    if SkillDataModule and SkillDataModule.Skills and SkillDataModule.Skills[skillId] then
        local sdef = SkillDataModule.Skills[skillId]
        if type(sdef.Cooldown) == "number" then
            cd = sdef.Cooldown
        elseif sdef.Cooldown == "aspd" then
            cd = 0.55
        end
    end

    if (now - (skillLastCast[skillId] or 0)) < cd then
        return false
    end

    local currentSp = LocalPlayer:GetAttribute("SP") or 999
    if currentSp < 4 then return false end

    -- Safe, non-blocking remote skill execution
    if UseSkill then
        pcall(function()
            UseSkill:FireServer(skillId, target)
            skillLastCast[skillId] = now
        end)
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
    local hotbarRaw = LocalPlayer:GetAttribute("HotbarJson")
    if hotbarRaw and hotbarRaw ~= "" then
        pcall(function()
            local hotbar = HttpService:JSONDecode(hotbarRaw)
            for slotNum = 1, 7 do
                if isSlotSelected(slotNum) then
                    local slotVal = hotbar[tostring(slotNum)]
                    if type(slotVal) == "string" and slotVal:find("^skill:") then
                        local sname = slotVal:sub(7)
                        castSmartSkill(sname, targetMob)
                    end
                end
            end
        end)
    end
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

local function getMonsterCombatPart(monster)
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

local function getBossList()
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

-- ==================== ADVANCED AUTO LOOT & VACUUM ====================
local isLooting = false

local function performAutoLoot()
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
    local maxLootDist = Config.LootRadius or 100
    local now = workspace:GetServerTimeNow()
    local validDrops = {}

    for _, drop in ipairs(allDrops) do
        if drop and drop.Parent and drop:IsA("BasePart") then
            local owner = drop:GetAttribute("OwnerUserId")
            local freeAt = drop:GetAttribute("FreeAt")
            local canPickup = true
            if owner and owner ~= 0 and owner ~= LocalPlayer.UserId then
                if freeAt and now < freeAt then
                    canPickup = false
                end
            end

            if canPickup then
                local dropDist = (drop.Position - hrp.Position).Magnitude
                if dropDist <= maxLootDist then
                    table.insert(validDrops, { part = drop, dist = dropDist })
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

    -- If all drops are already within melee pickup reach (<= 6 studs)
    local anyFar = false
    for _, dInfo in ipairs(validDrops) do
        if dInfo.dist > 6 then
            anyFar = true
            break
        end
    end

    if not anyFar then
        pcall(function()
            if PickupDrop then
                PickupDrop:FireServer(true)
                for _, dInfo in ipairs(validDrops) do
                    PickupDrop:FireServer(dInfo.part)
                end
            end
        end)
        isLooting = false
        return
    end

    -- Remote pickup for all valid drops without moving the character
    pcall(function()
        if PickupDrop then
            PickupDrop:FireServer(true)
            for _, dInfo in ipairs(validDrops) do
                PickupDrop:FireServer(dInfo.part)
            end
        end
    end)

    -- Only micro-teleport if the user explicitly enabled LootTeleport in settings (disabled in Dungeon to prevent rapid teleport bans)
    if Config.LootTeleport and not isInsideDungeon() then
        local originalCF = hrp.CFrame
        local pickedCount = 0

        for _, dInfo in ipairs(validDrops) do
            local drop = dInfo.part
            if drop and drop.Parent then
                local currDist = (drop.Position - hrp.Position).Magnitude
                if currDist > 6 and currDist <= 60 then
                    hrp.CFrame = CFrame.new(drop.Position + Vector3.new(0, 1.4, 0))
                    hrp.Velocity = Vector3.zero
                    task.wait(0.08)

                    pcall(function()
                        if firetouchinterest then
                            firetouchinterest(hrp, drop, 0)
                            task.wait()
                            firetouchinterest(hrp, drop, 1)
                        end
                    end)

                    pickedCount = pickedCount + 1
                    if pickedCount >= 3 then break end
                end
            end
        end

        if hrp and hrp.Parent and pickedCount > 0 then
            hrp.CFrame = originalCF
            hrp.Velocity = Vector3.zero
        end
    else
        -- LootTeleport is disabled: touch nearby drops without moving
        pcall(function()
            if firetouchinterest then
                for _, dInfo in ipairs(validDrops) do
                    if dInfo.dist <= 10 and dInfo.part and dInfo.part.Parent then
                        firetouchinterest(hrp, dInfo.part, 0)
                        task.wait()
                        firetouchinterest(hrp, dInfo.part, 1)
                    end
                end
            end
        end)
    end

    isLooting = false
end

local isOpeningBox = false
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
    local maxAllowed = math.min(Config.LootRadius or 60, 60)
    if dist > maxAllowed then return false end

    local canTeleportBox = canScriptMoveOrWarp() and (Config.LootTeleport == true) and not isInsideDungeon()
    if not canTeleportBox and dist > 14 then
        return false
    end

    local prevCF = hrp.CFrame

    if canTeleportBox then
        -- Approach safely if within reach
        if dist > 20 then
            local midPos = hrp.Position:Lerp(boxPos + Vector3.new(0, 1.5, 0), 0.5)
            hrp.CFrame = CFrame.new(midPos)
            task.wait(0.04)
        end

        hrp.CFrame = CFrame.new(boxPos + Vector3.new(0, 1.5, 0))
        hrp.Velocity = Vector3.zero
        task.wait(0.12)
    end

    -- 6. Multi-attempt Opening Actions (repeat up to 3 times or until opened)
    for attempt = 1, 3 do
        if not boxPart.Parent or boxPart:GetAttribute("OpenTitle") ~= nil then
            break
        end

        pcall(function()
            if OpenLootBox then
                OpenLootBox:FireServer(boxPart)
                if boxModel then
                    OpenLootBox:FireServer(boxModel)
                end
            end
        end)

        pcall(function()
            if PickupDrop then
                PickupDrop:FireServer(true)
                PickupDrop:FireServer(boxPart)
            end
        end)

        pcall(function()
            local prompt = boxPart:FindFirstChildOfClass("ProximityPrompt") or (boxModel and boxModel:FindFirstChildWhichIsA("ProximityPrompt", true))
            if prompt and fireproximityprompt then
                fireproximityprompt(prompt)
            end
        end)

        pcall(function()
            if firetouchinterest then
                firetouchinterest(hrp, boxPart, 0)
                task.wait()
                firetouchinterest(hrp, boxPart, 1)
            end
        end)

        task.wait(0.08)
    end

    -- Return smoothly to combat position if farming
    if canTeleportBox and hrp and hrp.Parent and canScriptMoveOrWarp() then
        hrp.CFrame = prevCF
        hrp.Velocity = Vector3.zero
    end

    return true
end

local function checkAllLootBoxes(customRadius)
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
local isKnockingHouse = false
local isPullingGacha = false

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
    if isPullingGacha or not GachaPull then return false end
    local _, heads = getHalloweenInventory()
    local count = pullCount or ((Config.GachaPullType == "1x Pull (10 Heads)") and 1 or 10)
    local cost = (count == 1) and 10 or 100
    if heads < cost then return false end

    isPullingGacha = true
    local result = nil
    pcall(function()
        result = GachaPull:InvokeServer(count)
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

    if Config.AdaptiveDistance then
        if isRanged then
            -- Ranged: Stay 13.5 - 16.0 studs back (Leader slam has 11 studs radius, so 16.0 studs is safe)
            dist = (isBoss or isLeader) and 16.0 or math.clamp(atkRange * 0.45, 13.5, 16.0)
            height = math.clamp(Config.SafeFarmHeight or 5.2, 4.2, 8.0)
        else
            -- Melee: Stay 4.2 - 6.0 studs back and float up (perfect weapon reach, 0% misses)
            dist = isBoss and 6.0 or (isLeader and 5.5 or math.clamp(Config.FarmDistance or 4.5, 3.8, 5.2))
            height = isBoss and 3.8 or math.clamp(Config.SafeFarmHeight or 1.2, 0.5, 2.2)
        end
    else
        dist = isBoss and 6.0 or math.clamp(Config.FarmDistance or 5.5, 3.0, 25.0)
        height = isBoss and 3.8 or math.clamp(Config.SafeFarmHeight or 5.2, 2.0, 10.0)
    end

    return dist, height, isRanged
end

local function performDodge(reason, evadeDir, customDist, customDuration, sourceMob, targetOverridePos)
    if not isScriptAlive() or not canScriptMoveOrWarp() or not Config.AutoDodge then return false end
    if Config.FarmMode == "Walk" then return false end

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
        if Dash then
            Dash:FireServer()
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
local monstersFolder = workspace:FindFirstChild("Monsters")
if monstersFolder then
    for _, mob in ipairs(monstersFolder:GetChildren()) do
        if mob:IsA("Model") then
            task.spawn(hookMonsterEvasion, mob)
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
    if BossFx then
        trackConn(BossFx.OnClientEvent:Connect(function(action, bossModel, skillName, zones, duration)
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
    if MonsterProjectile then
        trackConn(MonsterProjectile.OnClientEvent:Connect(function(mob, targetChar, speed)
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
trackConn(LocalPlayer.CharacterAdded:Connect(setupDodgeHealthMonitor))


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

    local maxRarityNum = 2
    if Config.MaxSellRarity == "Common Only" then
        maxRarityNum = 0
    elseif Config.MaxSellRarity == "Up to Uncommon" then
        maxRarityNum = 1
    elseif Config.MaxSellRarity == "Up to Rare" then
        maxRarityNum = 2
    elseif Config.MaxSellRarity == "All Rarities" then
        maxRarityNum = 999
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
                    local rarityAllowed = (rarity <= maxRarityNum)

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
            if BagSell then
                BagSell:FireServer(batch)
            end
        end)
        task.wait(0.2)
    end

    -- Also fire ShopSellJunk to ensure any remaining monster junk drops are sold
    pcall(function()
        if ShopSellJunk then
            ShopSellJunk:FireServer()
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
local WindUI = nil
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
    Title = "Farm Movement Mode (โหมดการเคลื่อนที่)",
    Desc = "สลับระหว่าง โหมดบินลอยตัว (Fly) หรือ โหมดเดินปกติบนพื้น (Walk)",
    Values = { "Fly (โหมดบินลอยตัว)", "Walk (โหมดเดินปกติบนพื้น)" },
    Value = (Config.FarmMode == "Walk" and "Walk (โหมดเดินปกติบนพื้น)") or "Fly (โหมดบินลอยตัว)",
    Callback = function(val)
        if val:find("Walk") then
            Config.FarmMode = "Walk"
            WindUI:Notify({ Title = "Farm Mode", Content = "เปิดใช้งาน: โหมดเดินปกติบนพื้น (Walk Mode)", Duration = 2.5, Icon = "footprints" })
        else
            Config.FarmMode = "Fly"
            WindUI:Notify({ Title = "Farm Mode", Content = "เปิดใช้งาน: โหมดบินลอยตัว (Fly Mode)", Duration = 2.5, Icon = "feather" })
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

FarmTab:Toggle({
    Title = "Safe Farm (Blindspot & Out-Range)",
    Desc = "เปิดใช้งานช่องโหว่ระยะมุมอับสายตา & ระยะปลอดภัยสมบูรณ์แบบ มอนสเตอร์ปกติไม่สามารถตีโดนได้ 100%",
    Value = Config.SafeFarm,
    Callback = function(state)
        Config.SafeFarm = state
        if Config.AutoSave then SaveConfig(true) end
        if not state then
            currentSafeHoldTarget = nil
            safeHoldUntil = 0
        end
    end,
})

FarmTab:Toggle({
    Title = "Adaptive Weapon Distance",
    Desc = "ปรับระยะห่างตามอาวุธของผู้เล่นอัตโนมัติ (Archer/Mage ยืน 14 studs มอนสเตอร์ตีไม่ถึง, Melee ยืน 5.8 studs ลอยเหนือมุมกวาด)",
    Value = Config.AdaptiveDistance,
    Callback = function(state)
        Config.AdaptiveDistance = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

FarmTab:Slider({
    Title = "Safe Farm Height (ความสูงลอยตัว)",
    Value = { Min = 3, Max = 10, Default = Config.SafeFarmHeight },
    Callback = function(val)
        Config.SafeFarmHeight = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

FarmTab:Slider({
    Title = "Manual Farm Distance (ระยะห่าง)",
    Value = { Min = 3, Max = 25, Default = Config.FarmDistance },
    Callback = function(val)
        Config.FarmDistance = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

FarmTab:Slider({
    Title = "Attack Delay",
    Value = { Min = 0.05, Max = 0.5, Default = Config.AttackDelay },
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

FarmTab:Section({ Title = "🐺 Mob Gathering & Cluster Farm (ฟาร์มลากมอนรวมฝูง)", Opened = true })

FarmTab:Toggle({
    Title = "Enable Mob Gathering (เปิดระบบรวมฝูงมอน)",
    Desc = "ดึง Aggro มอนสเตอร์รอบตัวให้วิ่งเข้ามารวมกันเป็นกลุ่มก้อน แล้วระเบิดสกิลหมู่ทำลายล้างพร้อมกัน",
    Value = Config.MobGathering,
    Callback = function(state)
        Config.MobGathering = state
        if Config.AutoSave then SaveConfig(true) end
        if state then
            WindUI:Notify({ Title = "Mob Gathering", Content = "เปิดระบบลากมอนสเตอร์รวมฝูงแล้ว!", Duration = 2, Icon = "users" })
        else
            WindUI:Notify({ Title = "Mob Gathering", Content = "ปิดระบบลากมอนสเตอร์รวมฝูง", Duration = 2, Icon = "square" })
        end
    end,
})

FarmTab:Slider({
    Title = "Gather Pull Radius (รัศมีดึงมอนรวมกลุ่ม)",
    Desc = "ระยะในการกวาดมอนสเตอร์รอบตัวเข้ามา (30 - 80 studs)",
    Value = { Min = 30, Max = 80, Default = Config.GatherRadius or 55 },
    Callback = function(val)
        Config.GatherRadius = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

FarmTab:Slider({
    Title = "Target Group Size (จำนวนมอนสเตอร์รวมฝูง)",
    Desc = "จำนวนมอนสเตอร์สูงสุดที่จะดึงมารวมฝูง (2 - 8 ตัว)",
    Value = { Min = 2, Max = 8, Default = Config.MaxGatherCount or 6 },
    Callback = function(val)
        Config.MaxGatherCount = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

FarmTab:Toggle({
    Title = "Full AoE Multi-Target Burst (ระเบิดสกิลหมู่)",
    Desc = "สาดสกิล AoE (Big Kaboom, Tar Flask, Neko Flask, Thunderstorm ฯลฯ) ใส่ทุกตัวในฝูงพร้อมกัน",
    Value = Config.AoEMultiBurst,
    Callback = function(state)
        Config.AoEMultiBurst = state
        if Config.AutoSave then SaveConfig(true) end
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
            if Config.AutoSave then SaveConfig(true) end
            WindUI:Notify({ Title = "Auto Dungeon", Content = "เปิดระบบลงดันเจี้ยนอัตโนมัติ (หยุด Auto Lv.99 แล้ว)", Duration = 2.5, Icon = "play" })
        else
            isEnteringDungeon = false
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
    Desc = "ซื้อกุญแจดันเจี้ยนผ่านเซิร์ฟเวอร์ทันที",
    Callback = function()
        pcall(function()
            if DungeonAction then
                DungeonAction:FireServer("selectBuyKey")
                WindUI:Notify({ Title = "Dungeon Key", Content = "ส่งคำสั่งซื้อกุญแจเรียบร้อย!", Duration = 2, Icon = "check" })
            end
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
    Value = { Min = 0.05, Max = 0.35, Default = Config.DungeonAttackDelay },
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

AutoSellTab:Dropdown({
    Title = "Max Rarity to Sell (ความหายากสูงสุด)",
    Values = {
        "Common Only",
        "Up to Uncommon",
        "Up to Rare",
        "All Rarities",
    },
    Value = Config.MaxSellRarity,
    Callback = function(val)
        Config.MaxSellRarity = val
        if Config.AutoSave then SaveConfig(true) end
    end,
})

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
LootTab:Section({ Title = "Drop Magnet & Vacuum", Opened = true })

LootTab:Toggle({
    Title = "Enable Auto Loot Drops",
    Desc = "เปิดระบบดูดเก็บไอเทมที่ดรอปบนพื้นทั้งหมดแบบอัตโนมัติ",
    Value = Config.AutoLoot,
    Callback = function(state)
        Config.AutoLoot = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

LootTab:Toggle({
    Title = "Loot Priority (Instant Sweep)",
    Desc = "เมื่อมอนตายและมีของตก จะแวะเก็บของให้หมดทันทีก่อนไปตีตัวต่อไป",
    Value = Config.LootPriority,
    Callback = function(state)
        Config.LootPriority = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

LootTab:Toggle({
    Title = "Teleport Directly to Drops",
    Desc = "วาร์ปแตะตัวไอเทมดรอปโดยตรงเพื่อทะลุระยะเช็คของเซิร์ฟเวอร์",
    Value = Config.LootTeleport,
    Callback = function(state)
        Config.LootTeleport = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

LootTab:Toggle({
    Title = "Auto Open LootBox / Chests",
    Desc = "เปิดกล่องสมบัติและหีบที่ดรอปอัตโนมัติ",
    Value = Config.AutoOpenLootBox,
    Callback = function(state)
        Config.AutoOpenLootBox = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

LootTab:Button({
    Title = "Manual Vacuum Drops Now",
    Callback = function()
        performAutoLoot()
        WindUI:Notify({ Title = "Looting", Content = "ดูดเก็บของบนพื้นเรียบร้อย", Duration = 2, Icon = "sparkles" })
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
    Title = "Auto Claim Daily Login",
    Desc = "รับของขวัญเช็คอินรายวันอัตโนมัติ",
    Value = Config.AutoClaimDaily,
    Callback = function(state)
        Config.AutoClaimDaily = state
        if Config.AutoSave then SaveConfig(true) end
    end,
})

RewardsTab:Toggle({
    Title = "Auto Claim Achievements",
    Desc = "รับรางวัลเหรียญและความสำเร็จที่ปลดล็อคอัตโนมัติ",
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
    Title = "Claim All Pending Rewards Now",
    Callback = function()
        pcall(function() DailyClaim:FireServer() end)
        pcall(function()
            local hs = HttpService
            local qJson = hs:JSONDecode(LocalPlayer:GetAttribute("QuestsJson") or "{}")
            if qJson and qJson.Active then
                for qid, _ in pairs(qJson.Active) do
                    QuestAction:FireServer("claim", qid)
                end
            end
        end)
        WindUI:Notify({ Title = "Rewards", Content = "กดส่งคำสั่งรับรางวัลทั้งหมดแล้ว", Duration = 2, Icon = "gift" })
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
            if EventNpcAction then
                EventNpcAction:FireServer("claimAll")
                EventNpcAction:FireServer("claimPet")
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
            WarpTo:FireServer(selectedWarp)
            WindUI:Notify({ Title = "Teleport", Content = "วาร์ปไป: " .. selectedWarp, Duration = 2, Icon = "send" })
        end)
    end,
})

TeleportTab:Button({
    Title = "Quick Return to Town",
    Callback = function()
        pcall(function() WarpTo:FireServer("Town") end)
    end,
})

-- ==================== TAB 10: CONFIG & HOTKEY ====================
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
            DailyClaim:FireServer()
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
            if Config.AutoReadyDungeon or Config.DungeonPartyMode == "Party" or Config.AutoAcceptParty then
                task.wait(0.15)
                pcall(function()
                    local dId = (type(data) == "table" and data.Id) or Config.SelectedDungeon or "halloween"
                    if DungeonAction then
                        DungeonAction:FireServer("ready", dId, true)
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
                if state == "cleared" then
                    if Config.AutoClaimExitChest then
                        executeClaimExitChest()
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
        if canScriptMoveOrWarp() and (Config.AutoOpenLootBox or Config.AutoHalloweenBoxes) then
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
        local attackDelay = (inDungeon and Config.DungeonAttackDelay) or Config.AttackDelay or 0.15
        task.wait(attackDelay)

        local shouldCombat = false
        if canScriptMoveOrWarp() then
            if inDungeon then
                shouldCombat = (Config.AutoDungeon == true) and (Config.AutoFarm == true)
            else
                shouldCombat = (Config.AutoFarm == true)
            end
        end

        if shouldCombat then
            if inDungeon and isDungeonDowned() then
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
                if Config.AutoRespawn and RespawnChoice then
                    pcall(function() RespawnChoice:FireServer("town") end)
                    pcall(function() RespawnChoice:FireServer("Town") end)
                end
                task.wait(2)
            elseif hrp and hum and hum.Health > 0 then
                -- Remote instant pickup for nearby drops during combat
                local dropsFolder = workspace:FindFirstChild("Drops")
                if Config.AutoLoot and Config.LootPriority and dropsFolder then
                    for _, d in ipairs(dropsFolder:GetChildren()) do
                        if d:IsA("BasePart") then
                            local dDist = (d.Position - hrp.Position).Magnitude
                            if dDist <= 8 then
                                pcall(function()
                                    PickupDrop:FireServer(true)
                                    PickupDrop:FireServer(d)
                                end)
                                if firetouchinterest then
                                    pcall(function()
                                        firetouchinterest(hrp, d, 0)
                                        firetouchinterest(hrp, d, 1)
                                    end)
                                end
                            elseif dDist <= 35 then
                                pcall(function()
                                    PickupDrop:FireServer(d)
                                end)
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
                            elseif Config.SafeFarm then
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
                                playerPos = getDungeonSafeCombatPosition(targetPos, mobLook, safeDist, isRanged)
                                targetFloorY = playerPos.Y
                            else
                                if Config.FarmMode == "Walk" then
                                    -- Accurate ground detection via Raycast
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

                            -- Anticheat-safe movement (never teleport > 4.5 studs in dungeon to prevent rapid teleport tags)
                            local distToTarget = (playerPos - hrp.Position).Magnitude
                            if inDungeon and distToTarget > 4.5 then
                                -- If target is obscured behind a wall, follow waypoints cleanly instead of walking into wall
                                if not isPillar and not hasDungeonLineOfSight(hrp.Position, targetPos) then
                                    advanceDungeonPath()
                                    continue
                                end
                                local dir = (playerPos - hrp.Position).Unit
                                local stepDist = math.min(distToTarget, 4.2)
                                local wallInstances = getDungeonWallInstances()
                                if #wallInstances > 0 then
                                    local rayParams = RaycastParams.new()
                                    rayParams.FilterType = Enum.RaycastFilterType.Include
                                    rayParams.FilterDescendantsInstances = wallInstances
                                    local stepCheck = workspace:Raycast(hrp.Position + Vector3.new(0, 1.5, 0), dir * (stepDist + 1.2), rayParams)
                                    if stepCheck then
                                        local safeStep = math.max(0, stepCheck.Distance - 1.8)
                                        if safeStep >= 0.8 then
                                            stepDist = safeStep
                                        else
                                            advanceDungeonPath()
                                            continue
                                        end
                                    end
                                end
                                local nextPos = hrp.Position + (dir * stepDist)
                                nextPos = Vector3.new(nextPos.X, targetFloorY, nextPos.Z)
                                hrp.CFrame = CFrame.lookAt(nextPos, targetPos + Vector3.new(0, 0.6, 0))
                                hrp.Velocity = Vector3.zero
                                hrp.AssemblyLinearVelocity = Vector3.zero
                                continue
                            elseif inDungeon then
                                hrp.CFrame = CFrame.lookAt(playerPos, targetPos + Vector3.new(0, 0.6, 0))
                                hrp.Velocity = Vector3.zero
                                hrp.AssemblyLinearVelocity = Vector3.zero
                                hrp.AssemblyAngularVelocity = Vector3.zero
                            elseif Config.FarmMode == "Walk" then
                                -- ==================== WALK MODE MOVEMENT ====================
                                hum.WalkSpeed = Config.WalkFarmSpeed or 26
                                local flatDiff = Vector3.new(playerPos.X - hrp.Position.X, 0, playerPos.Z - hrp.Position.Z)
                                local flatDist = flatDiff.Magnitude

                                if flatDist > (safeDist + 1.2) then
                                    hum:MoveTo(playerPos)
                                elseif flatDist > 1.8 then
                                    hum:MoveTo(playerPos)
                                    hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
                                else
                                    hum:Move(Vector3.zero, false)
                                    hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
                                end
                            else
                                -- ==================== FLY MODE MOVEMENT ====================
                                if distToTarget > 65 then
                                    local steps = math.max(1, math.ceil(distToTarget / 45))
                                    for i = 1, steps do
                                        if not char or not hrp.Parent then break end
                                        local alpha = i / steps
                                        local intermediate = hrp.Position:Lerp(playerPos, alpha)
                                        hrp.CFrame = CFrame.lookAt(intermediate, targetPos + Vector3.new(0, 0.6, 0))
                                        hrp.Velocity = Vector3.zero
                                        task.wait(0.02)
                                    end
                                elseif distToTarget > 30 then
                                    local mid = hrp.Position:Lerp(playerPos, 0.5)
                                    hrp.CFrame = CFrame.lookAt(mid, targetPos + Vector3.new(0, 0.6, 0))
                                    hrp.Velocity = Vector3.zero
                                    task.wait(0.02)
                                end

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


                        -- 3. Smart Skills Trigger (Auto casts selected slots 1-7 in order)
                        if Config.AutoUseSkills then
                            pcall(function()
                                local hotbarRaw = LocalPlayer:GetAttribute("HotbarJson")
                                if hotbarRaw and type(hotbarRaw) == "string" and hotbarRaw ~= "" then
                                    local hotbar = HttpService:JSONDecode(hotbarRaw)
                                    for slotNum = 1, 7 do
                                        if isSlotSelected(slotNum) then
                                            local slotVal = hotbar[tostring(slotNum)]
                                            if type(slotVal) == "string" and slotVal:find("^skill:") then
                                                local sname = slotVal:sub(7)
                                                castSmartSkill(sname, target)
                                            end
                                        end
                                    end
                                end
                            end)
                        end

                        -- 4. Multi-Target Mob Gathering & Kill Aura AoE
                        if Config.MobGathering then
                            local cluster, clusterCenter = getMobCluster(Config.GatherRadius or 55, Config.MaxGatherCount or 6)
                            if #cluster > 1 then
                                -- Aggro Taunt: Tag all monsters in cluster so they swarm towards player
                                for _, mob in ipairs(cluster) do
                                    if mob ~= target and isMonsterAlive(mob) then
                                        pcall(function()
                                            SetTarget:FireServer(mob, false, true)
                                        end)
                                        if Config.AoEMultiBurst then
                                            castAllAoESkills(mob)
                                        end
                                    end
                                end
                            end
                        elseif Config.KillAura then
                            local nearby = getNearbyMonsters(Config.KillAuraRadius or 20)
                            for _, mob in ipairs(nearby) do
                                if mob ~= target and isMonsterAlive(mob) then
                                    castAllAoESkills(mob)
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

-- 5. Auto Buffs Loop (Equipped Hotbar Buffs)
task.spawn(function()
    while isScriptAlive() do
        task.wait(2)
        if Config.AutoUseBuffs and Config.AutoFarm then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                pcall(function()
                    local hotbarRaw = LocalPlayer:GetAttribute("HotbarJson")
                    if hotbarRaw and hotbarRaw ~= "" then
                        local hotbar = HttpService:JSONDecode(hotbarRaw)
                        local buffNames = { meikyo = true, vanish = true, stealth = true, haste = true, blessing = true, increase_agi = true }
                        for slotNum = 1, 7 do
                            if isSlotSelected(slotNum) then
                                local slotVal = hotbar[tostring(slotNum)]
                                if type(slotVal) == "string" and slotVal:find("^skill:") then
                                    local sname = slotVal:sub(7)
                                    if buffNames[sname:lower()] then
                                        castSmartSkill(sname, nil)
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end
end)

-- 6. Auto Equip Best Gear & Cards Loop
task.spawn(function()
    while isScriptAlive() do
        task.wait(3.5)
        if Config.AutoEquipBest or Config.AutoEquipBestWeapon or Config.AutoEquipCards then
            executeAutoEquipBest()
        end
        -- Auto Refine Weapon
        if Config.AutoRefine and RefineWeapon then
            pcall(function()
                RefineWeapon:FireServer()
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
        if (Config.AutoWarpToBoss or Config.BossOnly) and Config.AutoBoss then
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
        -- Auto Daily
        if Config.AutoClaimDaily and DailyClaim then
            pcall(function() DailyClaim:FireServer() end)
        end
        -- Auto Quests
        if Config.AutoClaimQuests and QuestAction then
            pcall(function()
                local hs = HttpService
                local qJson = hs:JSONDecode(LocalPlayer:GetAttribute("QuestsJson") or "{}")
                if qJson and qJson.Active then
                    for qid, _ in pairs(qJson.Active) do
                        QuestAction:FireServer("claim", qid)
                    end
                end
            end)
        end
        -- Auto Achievements
        if Config.AutoClaimAchieve and AchieveAction then
            pcall(function()
                if (LocalPlayer:GetAttribute("AchieveReady") or 0) > 0 then
                    AchieveAction:FireServer("claim")
                end
            end)
        end
        -- Auto Pet
        if Config.AutoPet and PetAction then
            pcall(function()
                PetAction:FireServer("summon")
                PetAction:FireServer("feed")
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
            task.wait(1.5)
            pcall(function()
                if RespawnChoice then
                    RespawnChoice:FireServer("town")
                    RespawnChoice:FireServer("Town")
                end
            end)
            task.wait(3)
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
    if Config.AutoSell then
        local used = LocalPlayer:GetAttribute("BagSlotsUsed") or 0
        local max = LocalPlayer:GetAttribute("BagSlotsMax") or 50
        if max > 0 and (used >= max - 3 or (used / max) >= 0.80 or Config.AutoSellPeriodic) then
            executeAutoSell(true)
        end
    end

    while isScriptAlive() do
        task.wait(Config.AutoSellInterval or 20)
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
            if Config.AutoClaimEventRewards and EventNpcAction then
                pcall(function()
                    EventNpcAction:FireServer("claimAll")
                    EventNpcAction:FireServer("claimPet")
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
            if Config.AutoHalloweenGacha and GachaPull then
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
