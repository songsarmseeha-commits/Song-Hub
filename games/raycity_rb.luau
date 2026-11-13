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

-- Strict Game Validation: Prevent running in any other game
local isRaycity = (game.PlaceId == 117419079466193 or game.GameId == 10772794231 or game:GetService("ReplicatedStorage"):FindFirstChild("RCDrive") or workspace:FindFirstChild("MyCar"))
if not isRaycity then
    warn("[Song Hub] ❌ This script is exclusively for Raycity RB (PlaceId: 117419079466193)! Exiting.")
    return
end

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
    local coreGui = game:GetService("CoreGui")
    local roots = {
        (typeof(gethui) == "function" and gethui()) or nil,
        coreGui,
        coreGui:FindFirstChild("RobloxGui"),
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
    ["🎲 Derix (เต๋า & กล่องเงิน 1.5M)"] = Vector3.new(-1225.35, 40.34, -5316),
    ["🌟 Jin Ok (ฟาร์มเวลตามรูป)"] = Vector3.new(3962, 50.83, 7952),
    ["⚡ Hyon Jun (ฟาร์มเวลไว)"] = Vector3.new(1558, 36.75, 8768),
    ["🔥 Tony (Car EXP 8.2k)"] = Vector3.new(-6810, 27.85, -5412),
    ["🏢 Gangnam District"] = Vector3.new(1250, 45, -3420),
    ["🌆 Cheongdam Avenue"] = Vector3.new(-1800, 48, -2100),
    ["🔧 Tuning Shop & Garage"] = Vector3.new(200, 42, -4900),
    ["🏪 Car Market & Dealership"] = Vector3.new(-920, 44, -6150),
    ["🏁 Highway Strip"] = Vector3.new(0, 45, -1200)
}



-- ==============================================================================
-- ⚡ ROAD FIGHT LEVEL FARM TARGETS ("วิ่งแต่อันแรกยาวๆ")
-- ==============================================================================
local LEVEL_FARM_TARGETS = {
    ["🌟 Jin Ok (จินอุก) - EXP เทพ (จุดตามรูปโพสต์)"] = {
        bossId = 8,
        npcId = 1779,
        questId = "R1779",
        name = "Jin Ok",
        reqLv = 30,
        coords = Vector3.new(3962, 50.83, 7952),
        ux = 3533,
        cx = 2840,
        desc = "จุดที่คนในคอมมูนิตี้แนะนำมากที่สุด! ระยะสั้นมาก รับรอบ 1 วิ่งยาวๆ ได้ EXP สูงลิบ"
    },
    ["🎲 Derix (เดอร์ริก) - EXP + ลุ้นกล่อง 1.5M"] = {
        bossId = 2,
        npcId = 1676,
        questId = "R1676",
        name = "Derix",
        reqLv = 4,
        coords = Vector3.new(-1225.35, 40.34, -5316),
        ux = 1800,
        cx = 5000,
        desc = "Car EXP 5,000 ต่อรอบ + ได้เต๋า และมีโอกาสดรอปกล่องเงิน Power Jet Box 3 (1.5M Rain)"
    },
    ["⚡ Hyon Jun (ฮยอนจุน) - ฟาร์มเวลไว"] = {
        bossId = 10,
        npcId = 1787,
        questId = "R1787",
        name = "Hyon Jun",
        reqLv = 32,
        coords = Vector3.new(1558, 36.75, 8768),
        ux = 3533,
        cx = 2425,
        desc = "จุดฟาร์มเลเวลย่านกังนัมใต้ จุดเช็คพอยต์ใกล้ รับรอบ 1 สแปมทำเควสต่อเนื่อง"
    },
    ["🔥 Tony (โทนี่) - Car EXP สูงสุด (8.2k EXP)"] = {
        bossId = 25,
        npcId = 1847,
        questId = "R1847",
        name = "Tony",
        reqLv = 45,
        coords = Vector3.new(-6810, 27.85, -5412),
        ux = 4315,
        cx = 8239,
        desc = "Car EXP สูงที่สุดในบอสปกติ (8,239 EXP) สำหรับผู้เล่นเลเวล 45+"
    },
    ["🏎️ Bryan (ไบรอัน) - Level 29+ Farm"] = {
        bossId = 6,
        npcId = 1767,
        questId = "R1767",
        name = "Bryan",
        reqLv = 29,
        coords = Vector3.new(7315.5, 43.44, 8120),
        ux = 2100,
        cx = 2464,
        desc = "บอสสายฮีโร่ ให้ EXP ดี เหมาะสำหรับเลเวล 29-35"
    },
    ["🚁 Mr. Copter - Level 15+ Farm"] = {
        bossId = 1,
        npcId = 2050,
        questId = "R2050",
        name = "Mr. Copter",
        reqLv = 15,
        coords = Vector3.new(-2058.2, 37.4, -4993),
        ux = 1500,
        cx = 1000,
        desc = "บอสช่วงเริ่มต้น เลเวล 15 ฟาร์มผ่านง่าย"
    },
    ["⭐ James (เจมส์) - Level 42+ Farm"] = {
        bossId = 21,
        npcId = 1831,
        questId = "R1831",
        name = "James",
        reqLv = 42,
        coords = Vector3.new(-12168, 51.11, -5516),
        ux = 4315,
        cx = 5214,
        desc = "บอสย่านทิศตะวันตก เลเวล 42+ ให้ EXP สูง"
    },
    ["👑 Kang Tae San (คังแทซาน) - EXP สูงสุดในเกม"] = {
        bossId = 26,
        npcId = 1851,
        questId = "R1851",
        name = "Kang Tae San",
        reqLv = 48,
        coords = Vector3.new(-10458, 29.05, -5060),
        ux = 4315,
        cx = 8632,
        desc = "ราชาบอส Road King คังแทซาน Car EXP สูงสุด 8,632"
    }
}

-- ==============================================================================
-- ⚙️ 3. CONFIGURATION & STATE
-- ==============================================================================
local Config = {
    -- ⚡ Master 1-to-Max Auto Leveler ("ปั๊มเลเวล 1 ถึงตัน")
    AutoLevel1ToMax = false,
    AutoLevelMode = "🌟 Smart Story + Boss Rush (ทำเควสเนื้อเรื่อง + วาร์ปฟาร์มบอส)", -- "🌟 Smart Story + Boss Rush (ทำเควสเนื้อเรื่อง + วาร์ปฟาร์มบอส)" | "⚡ Jin Ok Hyper Rush (ตามรูปโพสต์ - วิ่งแต่อันแรกยาวๆ)"
    MaxLevelTarget = 50,

    -- ⚡ Road Fight Level Farm ("วิ่งแต่อันแรกยาวๆ")
    AutoFarmLevel = false,
    LevelFarmTarget = "🌟 Jin Ok (จินอุก) - EXP เทพ (จุดตามรูปโพสต์)",
    LevelFarmOnlyRound1 = true,

    -- 🎲 Derix 1.5M Dice Farm (Road Fight Boss)
    AutoFarmDerix = false,
    DerixRound = "Round 1 (R1676)", -- "Round 1 (R1676)" | "Round 2 (R1678)" | "Round 3 (R1679)" | "Round 4 (R1680)" | "Auto All Rounds"
    AutoRollDice = false,
    AutoOpen15MBox = false,
    AutoOpenAllCashBoxes = false,

    -- Autonomous Quest Farming
    AutoFarmQuests = false,
    AutoStoryProgression = false,
    AutoCleanInventory = false,
    AutoPhotoMission = false,
    AutoSellJunk = false,
    AutoTrashJunk = false,
    StrictMoneyOnly = false,
    ProtectTicketsAndKeys = true,
    MinKeepSellValue = 5000,
    QuestDriveMode = "Instant Warp", -- "Instant Warp" | "Realistic Road Drive" | "Hyper Sonic Glide" | "Hybrid Cruise"
    QuestDriveSpeed = 260, -- km/h
    AutoSkipDialogue = false,
    AutoAcceptQuest = false,
    AutoClaimRewards = false,
    LoopNextQuest = false,
    GhostTraffic = false,

    -- Speed & Driving
    SpeedBoostEnabled = false,
    TargetSpeedKmh = 250,
    AccelerationMultiplier = 2.0,
    InfiniteBoost = false,
    AntiFlip = false,
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
    AntiAfk = false,
    FastMode = false
}


local DERIX_COORDS = Vector3.new(-1225.35, 40.34, -5316.0)
local DerixStats = {
    wins = 0,
    diceRolled = 0,
    boxesOpened15M = 0,
    rainEarned = 0,
    lastChallengeTime = 0,
    activeFightRound = nil,
    clearedGates = {}
}
local LevelFarmStats = {
    runsCompleted = 0,
    totalUserExp = 0,
    totalCarExp = 0,
    lastChallengeTime = 0,
    activeFightRound = nil,
    clearedGates = {}
}

-- Forward declarations for UI callbacks
local updateFlyState = function() end
local teleportCar = function(targetCF) end
local handleDiceRollAndRewards = function() end
local autoOpenCashBoxes = function() end
local challengeDerix = function(preferredRound) end
local challengeBoss = function(bossId, questId, npcId, preferredRound)
    local car = workspace:FindFirstChild("MyCar")
    local root = car and (car:FindFirstChild("Root") or car.PrimaryPart)
    if not root then return false end

    local now = os.clock()
    if (now - LevelFarmStats.lastChallengeTime) < 1.5 then return false end
    LevelFarmStats.lastChallengeTime = now

    local targetQuestId = questId or "R1779"
    local targetNpcId = npcId or 1779

    LevelFarmStats.activeFightRound = targetQuestId

    -- 1. Native UI prompt button click if open
    pcall(function()
        local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        local rfGui = pGui and pGui:FindFirstChild("RBRCRoadFightUi")
        if rfGui then
            local dlg = rfGui:FindFirstChild("RoadFightDlg")
            if dlg and dlg.Visible then
                local btn = dlg:FindFirstChild("btChallenge", true)
                if btn and firesignal then
                    firesignal(btn.Activated)
                end
            end
        end
    end)

    -- 2. Native RBRCRoadFightClient handler
    pcall(function()
        local renv = getrenv and getrenv() or { shared = shared }
        local rfc = renv.shared and renv.shared.RBRCRoadFightClient
        if rfc and rfc.talk then
            rfc.talk(targetNpcId)
        end
    end)

    -- 3. Network Remote Function: RoadFightRequest & QuestRequest
    pcall(function()
        local qRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
        local rfReq = qRemotes and qRemotes:FindFirstChild("RoadFightRequest")
        if rfReq then
            rfReq:InvokeServer({
                op = "accept",
                questId = targetQuestId,
                carPos = root.Position
            })
        end
    end)
    pcall(function()
        local qRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
        local qReq = qRemotes and qRemotes:FindFirstChild("QuestRequest")
        if qReq then
            qReq:InvokeServer({
                op = "accept",
                questId = targetQuestId,
                carPos = root.Position,
                carLook = root.CFrame.LookVector
            })
        end
    end)

    return true
end

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

-- ==============================================================================
-- 🖱️ UI CLICKABILITY & MODAL ENHANCER (FIX UNCLICKABLE UI BUG)
-- Ensures WindUI is always topmost (DisplayOrder 999999) and mouse cursor is
-- permanently freed from vehicle camera LockCenter so all buttons/dropdowns work.
-- ==============================================================================
pcall(function()
    local roots = {
        (typeof(gethui) == "function" and gethui()) or nil,
        game:GetService("CoreGui"),
        LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    }

    local function elevateGui(sg)
        if sg:IsA("ScreenGui") then
            local name = sg.Name
            if name:find("WindUI") or name:find("RaycityHub") or name:find("SongHub") then
                sg.DisplayOrder = 999999
                sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

                if not sg:FindFirstChild("_MouseUnlockerModal") then
                    local modalBtn = Instance.new("TextButton")
                    modalBtn.Name = "_MouseUnlockerModal"
                    modalBtn.Size = UDim2.new(0, 0, 0, 0)
                    modalBtn.Position = UDim2.new(0, 0, 0, 0)
                    modalBtn.BackgroundTransparency = 1
                    modalBtn.Text = ""
                    modalBtn.Modal = true
                    modalBtn.Active = false
                    modalBtn.Selectable = false
                    modalBtn.Parent = sg
                end
            end
        end
    end

    for _, root in ipairs(roots) do
        if root then
            for _, desc in ipairs(root:GetDescendants()) do
                elevateGui(desc)
            end
            root.DescendantAdded:Connect(function(desc)
                task.wait(0.02)
                elevateGui(desc)
            end)
        end
    end

    UserInputService.MouseIconEnabled = true
    if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end)

-- Forward declarations for UI callbacks & early quest/level helpers
local stopAutoDrive
local getPlayerLevel
local getNpcWorldPos
local _cachedLiveMission = nil
local _lastLiveMissionCheck = 0
local _cachedProfileLevel = nil
local _cachedProfileDone = {}
local _lastBoardedTryTime = 0
local _boardingStartTime = 0
local _lastActiveQuestId = nil

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
        if val then
            Config.AutoFarmLevel = false
            Config.AutoFarmDerix = false
            Config.AutoAcceptQuest = true
            Config.AutoClaimRewards = true
            Config.AutoSkipDialogue = true
            Config.LoopNextQuest = true
            WindUI:Notify({
                Title = "Auto Story Progression Active! 🏆",
                Content = "เริ่มวิ่งเควสตามเลเวลอัตโนมัติ (โหมด: " .. tostring(Config.QuestDriveMode) .. ")",
                Duration = 3,
                Icon = "trophy"
            })
        else
            stopAutoDrive()
            WindUI:Notify({ Title = "Story Progression Paused", Content = "หยุดทำเควสตามเลเวลชั่วคราว", Duration = 2, Icon = "pause" })
        end
    end
})

local SmartInvBridge = {}

TabQuest:Toggle({
    Title = "📸 Auto Photo Mission (ถ่ายรูปเควสกด Insert ออโต้)",
    Desc = "ตรวจจับหน้าจอถ่ายรูป PhotoCam (กด Insert) จอดให้ตรงจุดแล้วรอจังหวะแถบสีเขียวกดถ่ายให้อัตโนมัติ (ทำงานให้เองตอนรัน Auto Farm/Story ด้วย)",
    Value = Config.AutoPhotoMission,
    Callback = function(val)
        Config.AutoPhotoMission = val
    end
})

TabQuest:Divider()

TabQuest:Paragraph({
    Title = "💰 Smart Auto Sell & Trash (ขายของ + เก็บเฉพาะของทำเงิน)",
    Desc = "แยกอัตโนมัติ: เก็บกล่องเงิน/ลูกเต๋า/ลอตเตอรี่/เพชร/ไข่มุก/รูน/สว่าน/กล่องตีบวก และของราคาสูง พร้อมขายหรือทิ้งขยะที่ไม่ทำเงิน",
    Image = "coins"
})

TabQuest:Toggle({
    Title = "🧹 Auto Clean Inventory (เคลียร์กระเป๋าก่อนรับ-ส่งเควส)",
    Desc = "เคลียร์ช่องกระเป๋าอัตโนมัติให้ว่างพอสำหรับรับรางวัลเควส โดยไม่ยุ่งกับกล่องเงิน/เพชร/ของทำเงิน",
    Value = Config.AutoCleanInventory,
    Callback = function(val)
        Config.AutoCleanInventory = val
    end
})

TabQuest:Toggle({
    Title = "💰 Auto Sell Non-Money Loot (ขายของไม่ทำเงินเป็น Rain ออโต้)",
    Desc = "ขายอะไหล่ทั่วไป/ของดรอปที่ไม่ทำเงินและราคาต่ำกว่าเกณฑ์เข้า Shop ทันทีจากทุกที่ (ไม่ต้องเปิดร้านค้า)",
    Value = Config.AutoSellJunk,
    Callback = function(val)
        Config.AutoSellJunk = val
    end
})

TabQuest:Toggle({
    Title = "🗑️ Auto Trash Unsellable Junk (ทิ้งขยะขายไม่ได้ sell=0 ออโต้)",
    Desc = "โยนทิ้งของที่ขายร้านไม่ได้ (ราคา 0 / ผูกมัด / อะไหล่ Rookie ขยะ) ออกจากกระเป๋าให้อัตโนมัติ",
    Value = Config.AutoTrashJunk,
    Callback = function(val)
        Config.AutoTrashJunk = val
    end
})

TabQuest:Toggle({
    Title = "💎 Strict Money-Only Filter (โหมดเก็บเฉพาะของทำเงิน 100%)",
    Desc = "เปิด = ทิ้ง/ขายเรียบแม้แต่ตั๋ว EXP และกุญแจรถ เหลือแค่กล่องเงิน ลูกเต๋า ลอตเตอรี่ เพชร สว่าน ตีบวก และของราคาสูงเท่านั้น",
    Value = Config.StrictMoneyOnly,
    Callback = function(val)
        Config.StrictMoneyOnly = val
    end
})

TabQuest:Toggle({
    Title = "🛡️ Protect EXP/Rain Tickets & Car Keys (กันทิ้งตั๋วคูณ/กุญแจรถ)",
    Desc = "คุ้มครองตั๋วบัฟ EXP/Rain และกุญแจรถไม่ให้ถูกทิ้งอัตโนมัติ (ไม่มีผลเมื่อเปิด Strict Mode)",
    Value = Config.ProtectTicketsAndKeys,
    Callback = function(val)
        Config.ProtectTicketsAndKeys = val
    end
})

TabQuest:Slider({
    Title = "💵 Keep High-Value Sell >= (เก็บของขายได้ตั้งแต่ Rain)",
    Desc = "ของที่ราคาขายร้านต่อชิ้นถึงค่านี้จะถูกเก็บไว้ (ตั้งเป็น 0 = ขายทุกชิ้นที่ไม่ใช่กล่องเงิน/แรร์)",
    Value = { Min = 0, Max = 50000, Default = Config.MinKeepSellValue },
    Callback = function(val)
        Config.MinKeepSellValue = math.max(0, math.floor((tonumber(val) or 0) + 0.5))
    end
})

TabQuest:Button({
    Title = "🧹 Clean & Sell Inventory Now (ขาย + ทิ้งขยะทันที Keep เฉพาะของทำเงิน)",
    Desc = "สแกนกระเป๋าเดี๋ยวนี้: ขายของไม่ทำเงินรับ Rain ทันที + ทิ้งขยะราคา 0 พร้อมแจ้งสรุปผล",
    Callback = function()
        if SmartInvBridge.run then
            local stats = SmartInvBridge.run(true, 999, true, true)
            WindUI:Notify({
                Title = "Inventory Cleaned! 💰",
                Content = string.format(
                    "ขายแล้ว %d ชิ้น (+%s Rain)\nทิ้งขยะ %d ชิ้น | เก็บของทำเงิน %d ชิ้น\nช่องว่างตอนนี้: %d ช่อง",
                    stats.soldCount or 0,
                    tostring(stats.earnedRain or 0),
                    stats.trashedCount or 0,
                    stats.keptCount or 0,
                    stats.freeSlots or 0
                ),
                Duration = 4,
                Icon = "check-circle"
            })
        end
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


-- ==============================================================================
-- TAB 1.5: 🎲 Derix Dice & 1.5M Cash Farm (บอทฟาร์มเต๋า Derix)
-- ==============================================================================
local TabDerix = Window:Tab({ Title = "Derix 1.5M Farm", Icon = "dices" })

TabDerix:Paragraph({
    Title = "🎲 Derix Road Fight & Dice Farm (ฟาร์มเต๋า & กล่องเงิน 1.5M)",
    Desc = "ระบบจะพารถวิ่งไปหา NPC Derix (จอห์น เดอร์ริก), ท้าแข่งประลอง Road Fight, ขับผ่านเช็คพอยต์ด้วยความเร็วสูง, ทอยเต๋ารับรางวัลอัตโนมัติ และตรวจเปิดกล่องเงิน Power Jet Box 3 (1.5M Rain) เข้าตัวทันทีแบบ 24/7!",
    Image = "dices"
})

TabDerix:Toggle({
    Title = "🎲 Master Auto Farm Derix (เปิดบอทฟาร์มเต๋า Derix วนลูป)",
    Desc = "เปิดใช้งานบอทวิ่งฟาร์ม Derix Road Fight อย่างต่อเนื่อง วนลูปตลอด 24 ชั่วโมง",
    Value = Config.AutoFarmDerix,
    Callback = function(val)
        Config.AutoFarmDerix = val
        if val then
            Config.AutoRollDice = true
            Config.AutoOpen15MBox = true
            Config.AutoOpenAllCashBoxes = true
            WindUI:Notify({ Title = "Derix Farm Started! 🎲", Content = "กำลังมุ่งหน้าไปหา Derix เพื่อเริ่มฟาร์มเต๋า & กล่อง 1.5M...", Duration = 3, Icon = "play" })
        else
            stopAutoDrive()
            WindUI:Notify({ Title = "Derix Farm Stopped", Content = "หยุดการฟาร์ม Derix ชั่วคราว", Duration = 2, Icon = "pause" })
        end
    end
})

TabDerix:Dropdown({
    Title = "⚡ Derix Drive Mode (โหมดการขับฟาร์มเต๋า)",
    Desc = "เลือก Instant Warp (วาร์ปผ่านเช็คพอยต์ไวสุด จบใน 2 วิ) หรือ Realistic Road Drive (ขับตามถนน)",
    Values = {
        "Instant Warp",
        "Realistic Road Drive",
        "Hyper Sonic Glide",
        "Hybrid Cruise"
    },
    Value = Config.QuestDriveMode,
    Callback = function(val)
        Config.QuestDriveMode = val
        WindUI:Notify({ Title = "Mode Updated", Content = "เปลี่ยนโหมดเป็น: " .. val, Duration = 2, Icon = "zap" })
    end
})

TabDerix:Dropdown({
    Title = "🎯 Derix Round Selection (เลือกรอบที่จะประลอง)",
    Values = {
        "Auto All Rounds (รอบ 1 - 4 วนลูป)",
        "Round 1 (R1676 - ไวสุด 3.1 km)",
        "Round 2 (R1678 - 4.3 km)",
        "Round 3 (R1679 - 2.3 km สั้นสุด!)",
        "Round 4 (R1680 - 3.9 km)"
    },
    Value = Config.DerixRound,
    Callback = function(val)
        Config.DerixRound = val
    end
})

TabDerix:Toggle({
    Title = "🎲 Auto Roll Dice (ทอยเต๋าออโต้เมื่อชนะ)",
    Desc = "กดทอยลูกเต๋าให้อัตโนมัติทันทีที่จบการแข่งขันเพื่อรับของรางวัล ไม่ต้องกดมือ",
    Value = Config.AutoRollDice,
    Callback = function(val)
        Config.AutoRollDice = val
    end
})

TabDerix:Toggle({
    Title = "💰 Auto Open 1.5M Box (เปิดกล่องเงิน 1.5M อัตโนมัติ)",
    Desc = "ตรวจหากล่อง Power Jet Box 3 (1.5M Rain) ในกระเป๋า และกดใช้งานทันที (+1,500,000 Rain/กล่อง)",
    Value = Config.AutoOpen15MBox,
    Callback = function(val)
        Config.AutoOpen15MBox = val
    end
})

TabDerix:Toggle({
    Title = "💵 Auto Open All Cash Boxes (เปิดกล่อง 500k & 700k ด้วย)",
    Desc = "เปิดกล่องเงิน Power Jet Box 1 (500k) และ Power Jet Box 2 (700k) ให้อัตโนมัติ",
    Value = Config.AutoOpenAllCashBoxes,
    Callback = function(val)
        Config.AutoOpenAllCashBoxes = val
    end
})

TabDerix:Button({
    Title = "🚀 Teleport Directly to Derix (วาร์ปไปหน้า Derix)",
    Desc = "พารถวาร์ปไปจอดหน้า NPC Derix ที่จุดพิกัด Gangnam ทันที",
    Callback = function()
        teleportCar(DERIX_COORDS)
        WindUI:Notify({ Title = "Teleported", Content = "มาถึงหน้า NPC Derix เรียบร้อยแล้ว!", Duration = 2, Icon = "map-pin" })
    end
})

TabDerix:Button({
    Title = "📦 Open All Cash Boxes Now (เปิดกล่องเงินทั้งหมดในกระเป๋า)",
    Desc = "กดสแกนและเปิดกล่องเงิน 1.5M, 700k, 500k ที่มีในกระเป๋าตอนนี้ทั้งหมดทันที",
    Callback = function()
        autoOpenCashBoxes()
        WindUI:Notify({ Title = "Boxes Processed", Content = "ตรวจสอบและกดเปิดกล่องเงินในกระเป๋าเรียบร้อย!", Duration = 2, Icon = "check-circle" })
    end
})

-- TAB 1.6: ⚡ Level Farm (วิ่งแต่อันแรกยาวๆ ตามรูป)
local TabLevel = Window:Tab({ Title = "Level Farm (เวลไว)", Icon = "zap" })

TabLevel:Paragraph({
    Title = "⚡ Master Auto Level 1 to Max (ปั๊มเลเวล 1 ถึงตันอัตโนมัติ)",
    Desc = "ระบบฟาร์มเลเวลรถและคนขับอัตโนมัติตั้งแต่เลเวล 1 จนถึงเลเวลตัน (Max Level)! ตามเทคนิคคอมมูนิตี้ไทย [ถ้าเอาเวล วิ่งอันนี้วิ่งแต่อันแรกยาวๆได้เลย] วาร์ปบอสจินอุก (Jin Ok) จบใน 2 วินาที รับ EXP สูงลิบ พร้อมทอยเต๋าและเปิดกล่องเงินให้อัตโนมัติ",
    Image = "flame"
})

TabLevel:Toggle({
    Title = "⚡ Master Auto Level 1 to Max (เปิดบอทปั๊มเลเวล 1 ถึงตัน)",
    Desc = "เปิดบอททำงานอัตโนมัติ 100% ตั้งแต่เลเวล 1 จนถึงเป้าหมายที่กำหนด (บอทจะหยุดเองเมื่อเลเวลตัน)",
    Value = Config.AutoLevel1ToMax,
    Callback = function(val)
        Config.AutoLevel1ToMax = val
        if val then
            Config.AutoFarmLevel = false
            Config.AutoFarmDerix = false
            Config.AutoFarmQuests = false
            Config.AutoAcceptQuest = true
            Config.AutoClaimRewards = true
            Config.AutoSkipDialogue = true
            Config.LoopNextQuest = true
            Config.AutoRollDice = true
            Config.AutoOpen15MBox = true
            Config.AutoOpenAllCashBoxes = true
            Config.QuestDriveMode = "Instant Warp"
            WindUI:Notify({
                Title = "1-to-Max Auto Leveler Started! ⚡",
                Content = "เริ่มปั๊มเลเวล 1 ถึงตันอัตโนมัติ! (เป้าหมาย Lv." .. tostring(Config.MaxLevelTarget) .. ")\nโหมด: " .. Config.AutoLevelMode,
                Duration = 4,
                Icon = "zap"
            })
        else
            stopAutoDrive()
            WindUI:Notify({ Title = "Auto Leveler Stopped", Content = "หยุดการปั๊มเลเวลชั่วคราว", Duration = 2, Icon = "pause" })
        end
    end
})

TabLevel:Dropdown({
    Title = "🎮 Auto Level Mode (โหมดการปั๊มเลเวล)",
    Desc = "เลือกรูปแบบการปั๊มเลเวล:",
    Values = {
        "⚡ Jin Ok Hyper Rush (ตามรูปโพสต์ - วิ่งแต่อันแรกยาวๆ)",
        "🌟 Smart Story + Boss Rush (ทำเควสเนื้อเรื่อง + วาร์ปฟาร์มบอส)"
    },
    Value = Config.AutoLevelMode,
    Callback = function(val)
        Config.AutoLevelMode = val
        WindUI:Notify({ Title = "Mode Selected", Content = "เลือก: " .. val, Duration = 2, Icon = "flame" })
    end
})

TabLevel:Slider({
    Title = "🎯 Target Max Level (เลเวลเป้าหมาย)",
    Desc = "กำหนดเลเวลที่ต้องการ เมื่อถึงเลเวลนี้บอทจะหยุดทำงานอัตโนมัติ",
    Value = { Min = 10, Max = 60, Default = Config.MaxLevelTarget },
    Callback = function(val)
        Config.MaxLevelTarget = val
    end
})

TabLevel:Divider()

TabLevel:Paragraph({
    Title = "🎯 Individual Boss Farm (ฟาร์มบอสแยกตัว)",
    Desc = "เลือกบอสที่ต้องการฟาร์มเจาะจงเฉพาะตัว เช่น Derix เพื่อกล่องเงิน 1.5M หรือบอสอื่นๆ ตามต้องการ",
    Image = "crosshair"
})

TabLevel:Toggle({
    Title = "⚡ Master Auto Level Farm (เปิดบอทฟาร์มเลเวล)",
    Desc = "เปิดใช้งานบอทวิ่งฟาร์มบอสที่เลือกเพื่อปั๊มเลเวล Car EXP & Driver EXP วนลูป 24 ชม.",
    Value = Config.AutoFarmLevel,
    Callback = function(val)
        Config.AutoFarmLevel = val
        if val then
            Config.AutoRollDice = true
            Config.AutoOpen15MBox = true
            Config.AutoOpenAllCashBoxes = true
            WindUI:Notify({ Title = "Level Farm Started! ⚡", Content = "เริ่มฟาร์มเลเวล: " .. Config.LevelFarmTarget .. "\n(โหมดวิ่งแต่อันแรกยาวๆ)", Duration = 3, Icon = "play" })
        else
            stopAutoDrive()
            WindUI:Notify({ Title = "Level Farm Stopped", Content = "หยุดการฟาร์มเลเวลชั่วคราว", Duration = 2, Icon = "pause" })
        end
    end
})

TabLevel:Dropdown({
    Title = "🎯 Target Boss (เลือกบอสที่จะฟาร์มเวล)",
    Desc = "เลือกจุด NPC บอส Road Fight ที่ต้องการให้บอทไปวิ่งฟาร์มเลเวล",
    Values = {
        "🌟 Jin Ok (จินอุก) - EXP เทพ (จุดตามรูปโพสต์)",
        "🎲 Derix (เดอร์ริก) - EXP + ลุ้นกล่อง 1.5M",
        "⚡ Hyon Jun (ฮยอนจุน) - ฟาร์มเวลไว",
        "🔥 Tony (โทนี่) - Car EXP สูงสุด (8.2k EXP)",
        "🏎️ Bryan (ไบรอัน) - Level 29+ Farm",
        "🚁 Mr. Copter - Level 15+ Farm",
        "⭐ James (เจมส์) - Level 42+ Farm",
        "👑 Kang Tae San (คังแทซาน) - EXP สูงสุดในเกม"
    },
    Value = Config.LevelFarmTarget,
    Callback = function(val)
        Config.LevelFarmTarget = val
        local info = LEVEL_FARM_TARGETS[val]
        if info then
            WindUI:Notify({ Title = "Target Selected", Content = info.name .. " (" .. tostring(info.cx) .. " Car EXP / " .. tostring(info.ux) .. " User EXP)", Duration = 3, Icon = "target" })
        end
    end
})

TabLevel:Dropdown({
    Title = "⚡ Farm Drive Mode (โหมดการขับฟาร์มเวล)",
    Desc = "เลือก Instant Warp (วาร์ปผ่านเช็คพอยต์ไวสุด จบใน 2 วิ) หรือ Realistic Road Drive (ขับตามถนน)",
    Values = {
        "Instant Warp",
        "Realistic Road Drive",
        "Hyper Sonic Glide",
        "Hybrid Cruise"
    },
    Value = Config.QuestDriveMode,
    Callback = function(val)
        Config.QuestDriveMode = val
        WindUI:Notify({ Title = "Mode Updated", Content = "เปลี่ยนโหมดเป็น: " .. val, Duration = 2, Icon = "zap" })
    end
})

TabLevel:Toggle({
    Title = "🔄 Lock Round 1 Only (วิ่งแต่อันแรกยาวๆ)",
    Desc = "ล็อคให้รับเฉพาะภารกิจรอบที่ 1 เพื่อรอบที่ไวที่สุดและ EXP/นาที สูงที่สุด",
    Value = Config.LevelFarmOnlyRound1,
    Callback = function(val)
        Config.LevelFarmOnlyRound1 = val
    end
})

TabLevel:Toggle({
    Title = "🎲 Auto Roll Dice (ทอยเต๋ารับรางวัลอัตโนมัติ)",
    Desc = "เมื่อมีเต๋าเด้งขึ้นมา ให้กดทอยเต๋าแบบสุ่มอัตโนมัติทันที",
    Value = Config.AutoRollDice,
    Callback = function(val)
        Config.AutoRollDice = val
    end
})

TabLevel:Toggle({
    Title = "📦 Auto Open Cash Boxes (เปิดกล่องเงินอัตโนมัติ)",
    Desc = "เปิดกล่องเงิน Power Jet Box 3 (1.5M), Box 2 (700k), Box 1 (500k) ทันทีเมื่อได้รับ",
    Value = Config.AutoOpen15MBox,
    Callback = function(val)
        Config.AutoOpen15MBox = val
    end
})

TabLevel:Button({
    Title = "🚀 Teleport to Selected Boss (วาร์ปไปหน้าบอสทันที)",
    Desc = "พารถวาร์ปไปจอดหน้า NPC บอสที่เลือกใน Dropdown ทันที",
    Callback = function()
        local t = LEVEL_FARM_TARGETS[Config.LevelFarmTarget] or LEVEL_FARM_TARGETS["🌟 Jin Ok (จินอุก) - EXP เทพ (จุดตามรูปโพสต์)"]
        if t and t.coords then
            teleportCar(t.coords)
            WindUI:Notify({ Title = "Teleported", Content = "มาถึงหน้า " .. t.name .. " เรียบร้อยแล้ว!", Duration = 2, Icon = "map-pin" })
        end
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
    Desc = "Copy Discord invite link (https://discord.gg/Cpcg9wU5k)",
    Icon = "message-circle",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/Cpcg9wU5k")
            WindUI:Notify({ Title = "Copied!", Content = "Discord link copied to clipboard!", Duration = 3, Icon = "clipboard" })
        end
    end
})


local function getGameShared()
    if getrenv then
        local ok, renv = pcall(getrenv)
        if ok and type(renv) == "table" and type(renv.shared) == "table" then
            return renv.shared
        end
    end
    return shared
end

-- Keep game-VM RemoteCars CarStateUp & QuestTelemetry streaming even while Roblox is unfocused
local _lastFocusWake = 0
local function ensureBackgroundCarSync()
    pcall(function()
        local gs = getGameShared()
        if gs then
            if type(gs.RaycityRemoteCars) == "table" then
                gs.RaycityRemoteCars.PAUSE_WHEN_UNFOCUSED = false
            end
            gs.RBRCQuestFastUp = true
        end
        local rep = game:GetService("ReplicatedStorage")
        local rcMod = rep:FindFirstChild("RaycityMultiplayer") and rep.RaycityMultiplayer:FindFirstChild("RemoteCars")
        if rcMod then
            local ok, mod = pcall(require, rcMod)
            if ok and type(mod) == "table" then
                mod.PAUSE_WHEN_UNFOCUSED = false
            end
        end
        local now = os.clock()
        if getconnections and (now - _lastFocusWake) >= 5.0 then
            _lastFocusWake = now
            local uis = game:GetService("UserInputService")
            for _, conn in ipairs(getconnections(uis.WindowFocused)) do
                if conn and conn.Function then
                    pcall(conn.Function)
                end
            end
        end
    end)
end

-- ==============================================================================
-- 🛡️ 1. ANTI-CHEAT BYPASS & MULTIPLAYER SYNC PRESERVATION
-- ==============================================================================
ensureBackgroundCarSync()

-- Continuous background sync guard ensuring CarStateUp never stalls when unfocused
task.spawn(function()
    while isAlive() do
        ensureBackgroundCarSync()
        task.wait(1.5)
    end
end)


-- ==============================================================================
-- 🚗 2. CAR & VEHICLE CONTROLLER (RCDRIVE INTEGRATED PHYSICS ENGINE)
-- ==============================================================================

local _cachedRCDrive = nil
local function getRCDrive()
    local curCar = workspace:FindFirstChild("MyCar")
    if _cachedRCDrive and _cachedRCDrive.phys then
        local cachedCar = _cachedRCDrive.car
        if cachedCar and cachedCar.Parent and (not curCar or cachedCar == curCar) then
            return _cachedRCDrive
        end
        _cachedRCDrive = nil
    end
    local rcd = nil
    pcall(function()
        local gs = getGameShared()
        if gs and gs.RCDrive then
            rcd = gs.RCDrive
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

local function teleportCarWithVelocity(targetCF, vel, allowRespawn)
    if typeof(targetCF) == "Vector3" then
        targetCF = CFrame.new(targetCF + Vector3.new(0, 1.5, 0))
    end
    if not targetCF then return end
    vel = vel or Vector3.zero

    local nativePos = targetCF.Position / 2
    local rot = targetCF - targetCF.Position

    local rcd = getRCDrive()
    if allowRespawn and rcd and type(rcd.teleport) == "function" then
        pcall(function()
            rcd.teleport(targetCF)
        end)
        -- rcd.teleport destroys and recreates MyCar + shared.RCDrive, so refresh references!
        rcd = getRCDrive()
    end

    if rcd and type(rcd.phys) == "table" then
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

    local root = getCarRoot()
    if root then
        if not allowRespawn and root.Anchored then
            root.Anchored = false
        end
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
            pcall(firesignal, btn.MouseButton1Down)
            pcall(firesignal, btn.MouseButton1Click)
            pcall(firesignal, btn.MouseButton1Up)
        end
        if getconnections then
            for _, c in ipairs(getconnections(btn.Activated)) do pcall(function() c:Fire() end) end
            for _, c in ipairs(getconnections(btn.MouseButton1Down)) do pcall(function() c:Fire() end) end
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

-- ==============================================================================
-- 💬 4.9. AUTONOMOUS DIRECT NPC INTERACTION & QUEST ACCEPT ENGINE
-- ==============================================================================
local _lastNpcInteractTime = 0
local _npcArrivalTimes = {} -- [npcName] = os.clock()
local npcVisitCooldown = {} -- [npcKey] = os.clock()

local function clearCarHoldLocks()
    pcall(function()
        local root = getCarRoot()
        if root and root.Anchored then
            root.Anchored = false
        end
        local car = getMyCar()
        if car then
            car:SetAttribute("RCInputLock", nil)
            car:SetAttribute("RBRCQuestRCLock", nil)
            car:SetAttribute("RBRCQuestInputLock", nil)
            car:SetAttribute("AutoThrottle", nil)
            car:SetAttribute("AutoSteer", nil)
        end
        local ts = shared.RaycityTownServices or (getrenv and getrenv().shared and getrenv().shared.RaycityTownServices)
        if ts and type(ts.holdRef) == "function" then
            pcall(ts.holdRef, "rbrcQuestTalk", false)
            pcall(ts.holdRef, "rbrcQuestBoard", false)
            pcall(ts.holdRef, "rbrcQuestDeliver", false)
        end
    end)
end

local function performTrustSyncRoll(anchorPos, faceDir, allowRespawn)
    local root = getCarRoot()
    local rcd = getRCDrive()
    if not root then return end
    anchorPos = anchorPos or root.Position
    faceDir = (faceDir and faceDir.Magnitude > 0.05) and faceDir.Unit or root.CFrame.LookVector
    local flatDir = Vector3.new(faceDir.X, 0, faceDir.Z)
    flatDir = flatDir.Magnitude > 0.05 and flatDir.Unit or Vector3.new(0, 0, -1)

    clearCarHoldLocks()
    local qt = nil
    pcall(function()
        qt = ReplicatedStorage.RBRCQuest.Remotes.QuestTelemetry
    end)

    -- Roll forward 8 studs over 5 ticks so server clears stale/untrusted state
    local startPos = anchorPos - flatDir * 8
    for step = 1, 5 do
        local alpha = step / 5
        local curPos = startPos:Lerp(anchorPos, alpha)
        local cf = CFrame.lookAt(curPos + Vector3.new(0, 1.0, 0), curPos + Vector3.new(0, 1.0, 0) + flatDir * 10)
        local vel = flatDir * 22
        if step == 1 and allowRespawn and rcd and type(rcd.teleport) == "function" then
            pcall(rcd.teleport, cf)
            local waitStart = os.clock()
            while (os.clock() - waitStart) < 1.0 do
                local newRoot = getCarRoot()
                if newRoot and not newRoot.Anchored then break end
                task.wait(0.05)
            end
        end
        -- Always refresh rcd / root / car in case rcd.teleport replaced MyCar
        rcd = getRCDrive()
        root = getCarRoot()
        local car = getMyCar()
        if not root then return end
        if root.Anchored then root.Anchored = false end
        if rcd and type(rcd.phys) == "table" then
            pcall(function()
                rcd.phys.cf = CFrame.new(cf.Position / 2) * (cf - cf.Position)
                rcd.phys.v = vel / 2
                rcd.phys.w = Vector3.zero
                rcd.phys.throttle = 1
                rcd.phys.brake = 0
                rcd.phys.airMode = false
                rcd.phys.anyContact = true
            end)
        end
        root.CFrame = cf
        root.AssemblyLinearVelocity = vel
        root.AssemblyAngularVelocity = Vector3.zero
        if car and car.PrimaryPart then
            pcall(function() car:PivotTo(cf) end)
        end
        if qt then
            pcall(function()
                qt:FireServer({ pos = cf.Position, speed = 11, stopped = false, gear = 1 })
            end)
        end
        task.wait(0.05)
    end

    -- Come to a complete stop for >= 0.14s (waitStopped threshold in RBRCQuestClient is 0.1s at v <= 1.5)
    rcd = getRCDrive()
    root = getCarRoot()
    local car = getMyCar()
    if not root then return end
    if root.Anchored then root.Anchored = false end
    local stopCF = CFrame.lookAt(anchorPos + Vector3.new(0, 1.0, 0), anchorPos + Vector3.new(0, 1.0, 0) + flatDir * 10)
    if rcd and type(rcd.phys) == "table" then
        pcall(function()
            rcd.phys.cf = CFrame.new(stopCF.Position / 2) * (stopCF - stopCF.Position)
            rcd.phys.v = Vector3.zero
            rcd.phys.w = Vector3.zero
            rcd.phys.throttle = 0
            rcd.phys.brake = 1
            rcd.phys.handbrake = 1
        end)
    end
    root.CFrame = stopCF
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    if car and car.PrimaryPart then
        pcall(function() car:PivotTo(stopCF) end)
    end
    task.wait(0.15)
    if qt then
        pcall(function()
            qt:FireServer({ pos = stopCF.Position, speed = 0, stopped = true, gear = 1 })
        end)
    end
    task.wait(0.05)
end

local function isColonNpcId(str)
    if type(str) ~= "string" then return false end
    return str:find("^mission:") ~= nil
        or str:find("^mission24:") ~= nil
        or str:find("^thtalk:") ~= nil
        or str:find("^th:") ~= nil
        or str:find("^roadfight:") ~= nil
end

local function getQuestRewardExp(qDef, rdMod)
    if type(qDef) ~= "table" then return 0 end
    local expVal = tonumber(qDef.rewards and qDef.rewards.baseUserExp) or 0
    if expVal <= 0 and rdMod and type(rdMod.baseRewards) == "function" then
        local okR, r1 = pcall(rdMod.baseRewards, qDef)
        if okR then
            if type(r1) == "table" then
                expVal = tonumber(r1.userExp) or tonumber(r1.exp) or 0
            else
                expVal = tonumber(r1) or 0
            end
        end
    end
    return expVal
end

local function interactWithNearbyNpc(optionalTarget)
    local now = os.clock()
    if (now - _lastNpcInteractTime) < 0.2 then return false end
    _lastNpcInteractTime = now

    local root = getCarRoot()
    if not root then return false end

    local npcsFolder = workspace:FindFirstChild("RBRCNpcs")
    local qRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
    local qReq = qRemotes and qRemotes:FindFirstChild("QuestRequest")
    local sReq = qRemotes and qRemotes:FindFirstChild("SkillQuestRequest")
    if not qReq and not sReq then return false end

    local targetNpc = nil
    local directNpcId = nil
    if typeof(optionalTarget) == "Instance" then
        targetNpc = optionalTarget
    elseif typeof(optionalTarget) == "string" and isColonNpcId(optionalTarget) then
        directNpcId = optionalTarget
        if npcsFolder then
            for _, n in ipairs(npcsFolder:GetChildren()) do
                if n:GetAttribute("RBRCNpcId") == optionalTarget or n.Name == optionalTarget then
                    targetNpc = n
                    break
                end
            end
        end
    elseif (typeof(optionalTarget) == "number" or typeof(optionalTarget) == "string") and npcsFolder then
        local optStr = tostring(optionalTarget)
        local numStr = optStr:match("(%d+)$")
        for _, n in ipairs(npcsFolder:GetChildren()) do
            local rId = tostring(n:GetAttribute("RBRCNpcId") or "")
            local nId = n.Name:match("(%d+)$") or tostring(n:GetAttribute("NpcId") or ""):match("(%d+)$") or tostring(n:GetAttribute("MissionId") or ""):match("(%d+)$")
            if n.Name == optStr or rId == optStr or (numStr and nId == numStr) then
                targetNpc = n
                break
            end
        end
    end

    if not targetNpc and not directNpcId and npcsFolder then
        local closestNpc, closestDist = nil, math.huge
        local curLv = getPlayerLevel()
        for _, npc in ipairs(npcsFolder:GetChildren()) do
            local npcLv = tonumber(npc:GetAttribute("Level")) or 1
            local rId = tostring(npc:GetAttribute("RBRCNpcId") or "")
            local isLevelOk = (npcLv <= curLv) or not isColonNpcId(rId)
            if isLevelOk then
                local pos = npc:GetPivot().Position
                local dist = (pos - root.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestNpc = npc
                end
            end
        end
        if closestDist <= 38 then
            targetNpc = closestNpc
        end
    end

    if not targetNpc and not directNpcId then return false end

    local rbrcNpcId = directNpcId or (targetNpc and targetNpc:GetAttribute("RBRCNpcId"))
    local mId = targetNpc and targetNpc:GetAttribute("MissionId")
    local nId = targetNpc and targetNpc:GetAttribute("NpcId")
    if not rbrcNpcId then
        if mId then
            rbrcNpcId = "mission24:" .. tostring(mId)
        elseif nId then
            rbrcNpcId = "thtalk:" .. tostring(nId)
        end
    end

    -- 1. Reset any hung tryTalk locks in client environment
    pcall(function()
        local gs = getGameShared()
        local rq = gs and gs.RBRCQuest
        if rq and rq.talk then
            local ups = debug.getupvalues(rq.talk)
            if ups and ups[1] and type(ups[1]) == "function" then
                debug.setupvalue(ups[1], 1, false)
                debug.setupvalue(ups[1], 3, false)
                debug.setupvalue(ups[1], 4, false)
            end
        end
    end)

    -- 2. Programmatic Talk & Accept directly through QuestRequest with Anti-Stale / serverFar Retry
    ensureBackgroundCarSync()
    local npcPos = (targetNpc and targetNpc:GetPivot().Position) or getNpcWorldPos(rbrcNpcId or optionalTarget) or root.Position
    local talkRes = nil
    if qReq and rbrcNpcId then
        for attempt = 1, 6 do
            ensureBackgroundCarSync()
            root = getCarRoot()
            if not root then break end
            pcall(function()
                talkRes = qReq:InvokeServer({ op = "talk", npcId = rbrcNpcId, carPos = root.Position })
            end)
            if talkRes and talkRes.ok then
                break
            elseif talkRes and (talkRes.reason == "tooFar" or talkRes.reason == "serverFar" or talkRes.reason == "quarantine") then
                local toNpc = (npcPos - root.Position)
                local flat = Vector3.new(toNpc.X, 0, toNpc.Z)
                local dir = flat.Magnitude > 0.5 and flat.Unit or root.CFrame.LookVector
                local parkPos = npcPos - dir * 5.0
                -- Sync phys.cf + CarStateUp smoothly without calling rcd.teleport (avoids RaycityBusyGate / groundHold anchor lock)
                performTrustSyncRoll(parkPos, dir, false)
                task.wait(0.55)
            else
                break
            end
        end
    end
    if (not talkRes or not talkRes.ok) and qReq and mId and rbrcNpcId ~= ("mission24:" .. tostring(mId)) then
        root = getCarRoot()
        if root then
            pcall(function()
                talkRes = qReq:InvokeServer({ op = "talk", npcId = "mission24:" .. tostring(mId), carPos = root.Position })
            end)
        end
    end

    if talkRes and talkRes.ok and talkRes.offers and #talkRes.offers > 0 then
        local curLv = getPlayerLevel()
        local qd, rd = nil, nil
        pcall(function() qd = require(ReplicatedStorage.RBRCQuest.QuestData) end)
        pcall(function() rd = require(ReplicatedStorage.RBRCQuest.RewardData) end)

        -- Filter & sort offers: strictly qLv <= curLv, undone first, EXP first, highest unlocked level first
        local rankedOffers = {}
        for _, offer in ipairs(talkRes.offers) do
            local qId = offer.questId
            local qDef = qd and qd.get and qd.get(qId)
            local qLv = tonumber(qDef and qDef.level) or tonumber(offer.level) or 1
            if qLv <= curLv then
                local doneCount = _cachedProfileDone and _cachedProfileDone[qId]
                local isUndone = not doneCount or doneCount == 0
                local expVal = getQuestRewardExp(qDef, rd)
                table.insert(rankedOffers, {
                    offer = offer,
                    qLv = qLv,
                    isUndone = isUndone,
                    hasExp = expVal > 0,
                })
            end
        end
        table.sort(rankedOffers, function(a, b)
            if a.isUndone ~= b.isUndone then return a.isUndone end
            if a.hasExp ~= b.hasExp then return a.hasExp end
            return a.qLv > b.qLv
        end)

        for _, item in ipairs(rankedOffers) do
            local offer = item.offer
            local accRes = nil
            for accAttempt = 1, 2 do
                ensureBackgroundCarSync()
                root = getCarRoot()
                if not root then break end
                pcall(function()
                    accRes = qReq:InvokeServer({
                        op = "accept",
                        questId = offer.questId,
                        carPos = root.Position,
                        carLook = root.CFrame.LookVector
                    })
                end)
                if accRes and accRes.ok then
                    break
                elseif accAttempt == 1 and accRes and (accRes.reason == "tooFar" or accRes.reason == "serverFar" or accRes.reason == "quarantine") then
                    local toNpc = (npcPos - root.Position)
                    local flat = Vector3.new(toNpc.X, 0, toNpc.Z)
                    local dir = flat.Magnitude > 0.5 and flat.Unit or root.CFrame.LookVector
                    performTrustSyncRoll(npcPos - dir * 3.5, dir, false)
                    task.wait(0.35)
                else
                    break
                end
            end
            if accRes and accRes.ok then
                if accRes.needsBoarding then
                    local bStart = os.clock()
                    while (os.clock() - bStart) < 6.5 do
                        task.wait(0.28)
                        local st = nil
                        pcall(function()
                            local gs = getGameShared()
                            local rq = gs and gs.RBRCQuest
                            if rq and rq.state then st = rq.state() end
                        end)
                        if st and st.state == "running" then
                            break
                        end
                        local bRes = nil
                        pcall(function()
                            bRes = qReq:InvokeServer({ op = "boarded", questId = offer.questId })
                        end)
                        if bRes and bRes.ok then
                            break
                        end
                    end
                end
                _lastLiveMissionCheck = 0
                _cachedLiveMission = nil
                clearCarHoldLocks()
                pcall(function()
                    require(ReplicatedStorage.RBRCQuest.QuestUI)._offerAnswer(true)
                end)
                pcall(function()
                    require(ReplicatedStorage.RBRCNpc.NpcTalkPrompt).hide()
                end)
                return true
            end
        end
    end

    -- 3. Only try UI accept fallback if talk was NOT explicitly rejected for cooldown / noQuest / tooFar / level
    local hardReject = talkRes and not talkRes.ok and (talkRes.reason == "cooldown" or talkRes.reason == "noQuest" or talkRes.reason == "tooFar" or talkRes.reason == "serverFar" or talkRes.reason == "level")
    if not hardReject and not (talkRes and talkRes.ok and (not talkRes.offers or #talkRes.offers == 0)) then
        pcall(function()
            local qui = require(ReplicatedStorage.RBRCQuest.QuestUI)
            if qui and qui._offerAnswer then
                qui._offerAnswer(true)
            end
            local ntpReq = require(ReplicatedStorage.RBRCNpc.NpcTalkPrompt)
            local u = debug.getupvalues(ntpReq.show)
            if u and type(u[3]) == "function" then
                u[3]()
            end
        end)
    end

    -- Store uniform future EXPIRY timestamp (os.clock() + cdDuration) for both rbrcNpcId and NPC name
    local waitSec = math.clamp(tonumber(talkRes and talkRes.wait) or 28, 12, 48)
    if talkRes and (talkRes.reason == "noQuest" or talkRes.reason == "level" or (talkRes.ok and (not talkRes.offers or #talkRes.offers == 0))) then
        waitSec = 120
    elseif talkRes and (talkRes.reason == "tooFar" or talkRes.reason == "serverFar" or talkRes.reason == "quarantine") then
        waitSec = 25
    end
    local expiry = os.clock() + waitSec
    if rbrcNpcId and tostring(rbrcNpcId) ~= "" then
        npcVisitCooldown[tostring(rbrcNpcId)] = expiry
    end
    if targetNpc and targetNpc.Name and targetNpc.Name ~= "" then
        npcVisitCooldown[targetNpc.Name] = expiry
    end
    clearCarHoldLocks()
    pcall(function()
        require(ReplicatedStorage.RBRCNpc.NpcTalkPrompt).hide()
    end)

    return false
end

local function pressReturnKey()

    -- 1. NATIVE EXECUTOR PHYSICAL KEYBOARD INJECTION (Guaranteed 100% OS Keystrokes)
    pcall(function()
        if keytap then
            keytap(0x0D) -- VK_RETURN (Enter)
        end
        if keypress and keyrelease then
            keypress(0x0D)
            task.wait(0.03)
            keyrelease(0x0D)
        end
    end)

    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        -- 1. MobileTap in RBRCNpcTalkPrompt (Talk to NPC prompt)
        local ntp = pg and pg:FindFirstChild("RBRCNpcTalkPrompt")
        if ntp and ntp.Enabled then
            local tap = ntp:FindFirstChild("MobileTap", true)
            if tap then fireGuiClick(tap) end
            local btn = ntp:FindFirstChildWhichIsA("GuiButton", true)
            if btn and btn.Visible then fireGuiClick(btn) end
            pcall(function()
                local rep = game:GetService("ReplicatedStorage")
                local escGate = require(rep.RaycityUi.RaycityEscGate)
                if escGate and escGate.onFieldEnter then
                    local cs = getconnections and getconnections(escGate.onFieldEnter)
                    if cs then
                        for _, c in ipairs(cs) do pcall(function() c:Fire() end) end
                    end
                end
            end)
            pcall(function()
                local rs = game:GetService("RunService")
                local conns = getconnections and getconnections(rs.Heartbeat)
                if conns then
                    for _, c in ipairs(conns) do
                        local fn = c.Function
                        if fn and tostring(debug.getinfo(fn).short_src or debug.getinfo(fn).source):find("RBRCQuestClient") then
                            local uvs = debug.getupvalues(fn)
                            if uvs and type(uvs[34]) == "function" then
                                uvs[34]()
                            end
                            break
                        end
                    end
                end
            end)
        end

        -- 2. Enter button in RBRCGameGuide (Guide Mission prompt)
        local gg = pg and pg:FindFirstChild("RBRCGameGuide")
        if gg and gg.Enabled then
            local enterBtn = gg:FindFirstChild("Enter", true)
            if enterBtn and enterBtn.Visible then fireGuiClick(enterBtn) end
        end

        -- 3. RaycityQuestUi: NpcDialog Next, Offer Yes & Result buttons
        local qGui = pg and pg:FindFirstChild("RaycityQuestUi")
        if qGui and qGui.Enabled then
            local npcDlg = qGui:FindFirstChild("NpcDialog")
            if npcDlg and npcDlg.Visible then
                local nextBtn = npcDlg:FindFirstChild("Next") or npcDlg:FindFirstChildWhichIsA("GuiButton", true)
                if nextBtn then fireGuiClick(nextBtn) end
                pcall(function()
                    local qUiMod = require(ReplicatedStorage.RBRCQuest.QuestUI)
                    if qUiMod and qUiMod._dialogEnter then qUiMod._dialogEnter() end
                end)
            end
            local resDlg = qGui:FindFirstChild("MissionResult") or qGui:FindFirstChild("Result")
            if resDlg and resDlg.Visible then
                local closeBtn = resDlg:FindFirstChild("Close") or resDlg:FindFirstChild("Ok") or resDlg:FindFirstChildWhichIsA("GuiButton", true)
                if closeBtn then fireGuiClick(closeBtn) end
                pcall(function()
                    local qUiMod = require(ReplicatedStorage.RBRCQuest.QuestUI)
                    if qUiMod then
                        if qUiMod.hideResult then qUiMod.hideResult() end
                        if qUiMod.closeDrops then qUiMod.closeDrops() end
                    end
                end)
            end
            local offerDlg = qGui:FindFirstChild("MissionOffer")
            if offerDlg and offerDlg.Visible then
                local yesBtn = offerDlg:FindFirstChild("Yes", true) or offerDlg:FindFirstChildWhichIsA("GuiButton", true)
                if yesBtn then fireGuiClick(yesBtn) end
                pcall(function()
                    local qUiMod = require(ReplicatedStorage.RBRCQuest.QuestUI)
                    if qUiMod and qUiMod._offerAnswer then qUiMod._offerAnswer(true) end
                end)
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
        local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        local qUi = pg and pg:FindFirstChild("RaycityQuestUi")
        if qUi and qUi.Enabled then
            local nextBtn = qUi:FindFirstChild("Next", true)
            if nextBtn and nextBtn:IsA("GuiButton") and nextBtn.Visible then
                fireGuiClick(nextBtn)
            end
            local yesBtn = qUi:FindFirstChild("Yes", true)
            if yesBtn and yesBtn:IsA("GuiButton") and yesBtn.Visible then
                fireGuiClick(yesBtn)
                pcall(function()
                    local qUiMod = require(ReplicatedStorage.RBRCQuest.QuestUI)
                    if qUiMod and qUiMod._offerAnswer then qUiMod._offerAnswer(true) end
                end)
            end
            local resClose = qUi:FindFirstChild("MissionResult", true) or qUi:FindFirstChild("Result", true)
            if resClose then
                local closeBtn = resClose:FindFirstChild("Close", true) or resClose:FindFirstChild("Ok", true) or resClose:FindFirstChildWhichIsA("GuiButton")
                if closeBtn and closeBtn.Visible then fireGuiClick(closeBtn) end
            end
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
            if qUi.hideResult then pcall(qUi.hideResult) end
            if qUi.closeDrops then pcall(qUi.closeDrops) end
        end
    end)
end

-- ==============================================================================
-- 💰 4.9. CONTINUOUS BACKGROUND 1.5M CASH BOX OPENER & DICE ROLLER
-- Photo Mission (PhotoDest / Press Insert Minigame) Auto Solver
SmartInvBridge.photoState = SmartInvBridge.photoState or { cam = nil, openedAt = 0, lastShotAt = 0, shotCount = 0 }
SmartInvBridge.lastBgCleanAt = 0

function SmartInvBridge.solvePhotoCamIfOpen()
    local Players = game:GetService("Players")
    local Rep = game:GetService("ReplicatedStorage")
    local lp = Players.LocalPlayer
    local pg = lp and lp:FindFirstChildOfClass("PlayerGui")
    local extraGui = pg and pg:FindFirstChild("RaycityMissionExtra")
    local photoCam = extraGui and extraGui:FindFirstChild("PhotoCam")
    local st = SmartInvBridge.photoState

    if not photoCam or not photoCam.Visible then
        st.cam = nil
        st.openedAt = 0
        return false
    end

    if st.cam ~= photoCam then
        st.cam = photoCam
        st.openedAt = os.clock()
        st.lastShotAt = 0
    end

    local stamp = photoCam:FindFirstChild("Stamp")
    if stamp and stamp.Visible then
        return true
    end

    -- Respect MissionExtraRules.photoMinShotMs (150ms) before attempting Insert
    if (os.clock() - st.openedAt) < 0.21 then
        return false
    end

    -- Avoid spamming multiple shots while waiting for server stamp confirmation
    if st.lastShotAt > 0 and (os.clock() - st.lastShotAt) < 0.65 then
        return false
    end

    local hitWindow = photoCam:FindFirstChild("HitWindow")
    local arrow = photoCam:FindFirstChild("Arrow")
    if not hitWindow or not arrow then
        return false
    end

    local okRules, rules = pcall(function()
        local mod = Rep:FindFirstChild("RaycityMissionExtra") and Rep.RaycityMissionExtra:FindFirstChild("MissionExtraRules")
        return mod and require(mod) or nil
    end)
    if not okRules then rules = nil end

    local RunService = game:GetService("RunService")
    local VIM = game:GetService("VirtualInputManager")

    local waitStart = os.clock()
    local aligned = false
    while isAlive() and photoCam.Parent and photoCam.Visible and not (stamp and stamp.Visible) do
        local lo = hitWindow.Position.X.Offset
        local hi = lo + hitWindow.Size.X.Offset - 0.5
        local ux = arrow.Position.X.Offset + 3.5
        local markerX = ux + 4.5
        local center = (lo + hi) * 0.5
        local halfSpan = math.max(1, (hi - lo) * 0.5)

        local inWindow = false
        if rules and rules.photoHit then
            local okH, resH = pcall(rules.photoHit, ux, lo, hi)
            inWindow = (okH and resH == true)
        else
            inWindow = (markerX >= lo and markerX <= hi)
        end

        local elapsed = os.clock() - waitStart
        if inWindow and (math.abs(markerX - center) <= math.max(5, halfSpan * 0.68) or elapsed >= 0.70) then
            aligned = true
            break
        end
        if elapsed >= 1.60 then
            break
        end
        RunService.Heartbeat:Wait()
    end

    if not aligned or not photoCam.Parent or not photoCam.Visible or (stamp and stamp.Visible) then
        return (stamp and stamp.Visible) == true
    end

    st.lastShotAt = os.clock()
    st.shotCount = (st.shotCount or 0) + 1

    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode.Insert, false, game)
    end)
    task.delay(0.035, function()
        pcall(function()
            VIM:SendKeyEvent(false, Enum.KeyCode.Insert, false, game)
        end)
    end)

    -- Short check: if VirtualInputManager didn't stamp (some executors block VIM), fire fallback click/keypress
    task.wait(0.14)
    if photoCam.Parent and photoCam.Visible and not (stamp and stamp.Visible) then
        local shootBtn = photoCam:FindFirstChild("PhotoShoot")
        if shootBtn and firesignal then
            pcall(firesignal, shootBtn.MouseButton1Click)
            pcall(firesignal, shootBtn.Activated)
        end
        if keypress then
            pcall(keypress, 0x2D)
            task.delay(0.035, function()
                if keyrelease then pcall(keyrelease, 0x2D) end
            end)
        elseif keytap then
            pcall(keytap, 0x2D)
        end
    end

    return true
end

task.spawn(function()
    while isAlive() do
        task.wait(0.06)
        if Config.AutoPhotoMission or Config.AutoFarmQuests or Config.AutoStoryProgression or Config.AutoLevel1ToMax then
            pcall(SmartInvBridge.solvePhotoCamIfOpen)
        end
    end
end)

task.spawn(function()
    while isAlive() do
        task.wait(1.5)
        if Config.AutoOpen15MBox or Config.AutoOpenAllCashBoxes or Config.AutoFarmDerix then
            pcall(autoOpenCashBoxes)
        end
        if Config.AutoRollDice or Config.AutoFarmDerix then
            pcall(handleDiceRollAndRewards)
        end
        if (Config.AutoSellJunk or Config.AutoTrashJunk) and SmartInvBridge.run then
            local now = os.clock()
            if (now - (SmartInvBridge.lastBgCleanAt or 0)) >= 2.5 then
                SmartInvBridge.lastBgCleanAt = now
                pcall(function()
                    SmartInvBridge.run(false, 999, Config.AutoSellJunk, Config.AutoTrashJunk)
                end)
            end
        end
    end
end)

-- 💬 5.0. CONTINUOUS BACKGROUND AUTO DIALOGUE SKIP & QUEST ACCEPT ENGINE
-- ==============================================================================
task.spawn(function()
    while isAlive() do
        task.wait(0.12)
        if Config.AutoSkipDialogue or Config.AutoStoryProgression or Config.AutoLevel1ToMax or (Config.AutoFarmQuests and Config.AutoAcceptQuest) then
            pcall(function()
                local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
                if not pg then return end

                local qUi = pg:FindFirstChild("RaycityQuestUi")
                local ntp = pg:FindFirstChild("RBRCNpcTalkPrompt")
                local gg = pg:FindFirstChild("RBRCGameGuide")

                -- 1. Auto Talk to NPC when RBRCNpcTalkPrompt is shown (skip random triggers while Story/1-to-Max chooses exact level-matched NPCs)
                if ntp and ntp.Enabled and not Config.AutoStoryProgression and not Config.AutoLevel1ToMax then
                    pcall(interactWithNearbyNpc)
                    pcall(function()
                        if keytap then
                            keytap(0x0D) -- VK_RETURN
                        elseif keypress and keyrelease then
                            keypress(0x0D)
                            task.wait(0.03)
                            keyrelease(0x0D)
                        end
                    end)
                    pcall(function()
                        local ntpReq = require(ReplicatedStorage.RBRCNpc.NpcTalkPrompt)
                        local uvs = debug.getupvalues(ntpReq.show)
                        if uvs and type(uvs[3]) == "function" then
                            uvs[3]()
                        end
                    end)
                    pcall(function()
                        local rep = game:GetService("ReplicatedStorage")
                        local escGate = require(rep.RaycityUi.RaycityEscGate)
                        if escGate and escGate.onFieldEnter then
                            local cs = getconnections and getconnections(escGate.onFieldEnter)
                            if cs then
                                for _, c in ipairs(cs) do pcall(function() c:Fire() end) end
                            end
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
                            if keytap then keytap(0x0D) end
                            local qUiMod = require(ReplicatedStorage.RBRCQuest.QuestUI)
                            if qUiMod and qUiMod._offerAnswer then
                                qUiMod._offerAnswer(true)
                            end
                        end)
                        local yesBtn = offer:FindFirstChild("Yes", true)
                        if yesBtn then fireGuiClick(yesBtn) end
                    end

                    -- 3. Auto Advance NPC Dialog (Next / ยืนยัน)
                    local npcDlg = qUi:FindFirstChild("NpcDialog")
                    if npcDlg and npcDlg.Visible then
                        pcall(function()
                            if keytap then keytap(0x0D) end
                            local qUiMod = require(ReplicatedStorage.RBRCQuest.QuestUI)
                            if qUiMod and qUiMod._dialogEnter then
                                qUiMod._dialogEnter()
                            end
                        end)
                        local nextBtn = npcDlg:FindFirstChild("Next", true)
                        if nextBtn then fireGuiClick(nextBtn) end
                    end

                    -- 4. Auto Close Result Dialog / Claim Rewards
                    local resDlg = qUi:FindFirstChild("MissionResult") or qUi:FindFirstChild("Result")
                    if resDlg and resDlg.Visible then
                        pcall(function()
                            if keytap then keytap(0x0D) end
                            local qUiMod = require(ReplicatedStorage.RBRCQuest.QuestUI)
                            if qUiMod then
                                if qUiMod.hideResult then qUiMod.hideResult() end
                                if qUiMod.closeDrops then qUiMod.closeDrops() end
                            end
                        end)
                        pcall(function()
                            local escGate = require(ReplicatedStorage.RaycityUi.RaycityEscGate)
                            if escGate and escGate.virtualEnter then escGate.virtualEnter() end
                        end)
                        local closeBtn = resDlg:FindFirstChild("Close", true) or resDlg:FindFirstChild("Ok", true) or resDlg:FindFirstChildWhichIsA("GuiButton", true)
                        if closeBtn then fireGuiClick(closeBtn) end
                    end
                end

                -- 5. Auto Dismiss GameGuide prompt if visible
                if gg and gg.Enabled then
                    local enterBtn = gg:FindFirstChild("Enter", true)
                    if enterBtn then fireGuiClick(enterBtn) end
                end
            end)
        end
    end
end)

-- ==============================================================================
-- 📦 5.1. STATE & INVENTORY MANAGER FOR QUEST PROGRESSION
-- ==============================================================================
local function getRoadFightNextGate(questId, carPos, clearedGateSet)
    clearedGateSet = clearedGateSet or {}
    local rfd = nil
    pcall(function() rfd = require(ReplicatedStorage.RBRCQuest.RoadFightData) end)
    if not rfd or not rfd.questRows then return nil, false, nil end

    local qData = rfd.questRows[questId] or rfd.questRows[tostring(questId)]
    if not qData then
        for _, row in pairs(rfd.questRows) do
            if type(row) == "table" and (row.id == questId or row.mid == questId or tostring(row.mid) == tostring(questId)) then
                qData = row
                break
            end
        end
    end
    if not qData or type(qData.obj) ~= "table" then return nil, false, nil end

    for idx, gate in ipairs(qData.obj) do
        if not clearedGateSet[idx] then
            local coords = gate[11]
            if type(coords) == "table" and #coords >= 6 then
                local gx = (coords[1] + coords[4]) / 2
                local gy = (coords[2] + coords[5]) / 2
                local gz = (coords[3] + coords[6]) / 2
                local gatePos = Vector3.new(gx, gy, gz)
                local isFinish = (idx == #qData.obj)
                return gatePos, isFinish, idx
            end
        end
    end
    return nil, false, nil
end

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


-- ==============================================================================
-- 🎲 5.3. DERIX ROAD FIGHT & 1.5M CASH BOX ENGINE
-- ==============================================================================
autoOpenCashBoxes = function()
    if not (Config.AutoOpen15MBox or Config.AutoOpenAllCashBoxes or Config.AutoFarmDerix) then return end
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local pcMod = rep:FindFirstChild("RaycityProfile") and rep.RaycityProfile:FindFirstChild("ProfileClient")
        local iuReq = rep:FindFirstChild("RaycityItemUse") and rep.RaycityItemUse:FindFirstChild("Remotes") and rep.RaycityItemUse.Remotes:FindFirstChild("ItemUseRequest")
        if not pcMod or not iuReq then return end

        local pc = require(pcMod)
        local data = pc.get and pc.get()
        if not data or not data.inventory then
            data = pc.request and pc.request("get")
            data = data and (data.profile or data)
        end
        if not data or not data.inventory then return end

        for cell, item in pairs(data.inventory) do
            local itemId = tonumber(item.id) or 0
            -- Item 19309 = Power Jet Box 3 (1,500,000 Rain / 1.5M)
            -- Item 18270 = Power Jet Box 2 (700,000 Rain)
            -- Item 15182 = Power Jet Box 1 (500,000 Rain)
            local is15M = (itemId == 19309)
            local isCashBox = (itemId == 18270 or itemId == 15182)
            local isDice = (itemId == 15559 or itemId == 16812 or itemId == 16813 or itemId == 16814 or itemId == 14653 or itemId == 14654)

            if (is15M and Config.AutoOpen15MBox) or (isCashBox and Config.AutoOpenAllCashBoxes) or (isDice and Config.AutoRollDice) then
                pcall(function()
                    local res = iuReq:InvokeServer("use", { cell = tonumber(cell), id = itemId })
                    if res and res.ok then
                        if is15M then
                            DerixStats.boxesOpened15M = DerixStats.boxesOpened15M + 1
                            DerixStats.rainEarned = DerixStats.rainEarned + 1500000
                            pcall(function()
                                WindUI:Notify({
                                    Title = "🎉 ได้รับเงิน 1,500,000 Rain!",
                                    Content = "เปิดกล่องเงิน Power Jet Box 3 สำเร็จ! (+1.5M)",
                                    Duration = 4,
                                    Icon = "sparkles"
                                })
                            end)
                        elseif isCashBox then
                            DerixStats.rainEarned = DerixStats.rainEarned + (itemId == 18270 and 700000 or 500000)
                        end
                    end
                end)
                task.wait(0.15)
            end
        end
    end)
end

handleDiceRollAndRewards = function()
    if not (Config.AutoRollDice or Config.AutoFarmDerix) then return end
    pcall(function()
        local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        if not pGui then return end

        for _, gui in ipairs(pGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                for _, obj in ipairs(gui:GetDescendants()) do
                    if obj:IsA("GuiButton") and obj.Visible then
                        local btnText = (obj:IsA("TextButton") and obj.Text or ""):lower()
                        local btnName = obj.Name:lower()
                        if btnName:find("dice") or btnName:find("roll") or btnName:find("throw")
                            or btnText:find("เต๋า") or btnText:find("dice") or btnText:find("ทอย")
                            or btnText:find("สุ่ม") or btnText:find("roll") or btnText:find("throw") then
                            if firesignal then firesignal(obj.Activated) end
                            DerixStats.diceRolled = DerixStats.diceRolled + 1
                        end
                    end
                end
            end
        end

        local merMod = ReplicatedStorage:FindFirstChild("RaycityMissionExtra") and ReplicatedStorage.RaycityMissionExtra:FindFirstChild("MissionExtraRules")
        if merMod then
            local ok, mer = pcall(require, merMod)
            if ok and mer and type(mer.roll2d6) == "function" then
                pcall(mer.roll2d6)
            end
        end
    end)
end

challengeDerix = function(preferredRound)
    local root = getCarRoot()
    if not root then return false end

    local now = os.clock()
    if (now - DerixStats.lastChallengeTime) < 1.5 then return false end
    DerixStats.lastChallengeTime = now

    local questId = "R1676"
    if preferredRound == "Round 1 (R1676)" then
        questId = "R1676"
    elseif preferredRound == "Round 2 (R1678)" then
        questId = "R1678"
    elseif preferredRound == "Round 3 (R1679)" then
        questId = "R1679"
    elseif preferredRound == "Round 4 (R1680)" then
        questId = "R1680"
    else
        local rfc = nil
        pcall(function()
            local renv = getrenv and getrenv() or { shared = shared }
            rfc = renv.shared and renv.shared.RBRCRoadFightClient
        end)
        local st = rfc and rfc.state and rfc.state()
        local rfd = nil
        pcall(function() rfd = require(ReplicatedStorage.RBRCQuest.RoadFightData) end)

        if rfd and st and rfd.fights and rfd.fights[2] then
            local fight = rfd.fights[2]
            for _, m in ipairs(fight.missions) do
                local ok, can = pcall(rfd.canAccept, st, fight, m)
                if ok and can and m.questId then
                    questId = m.questId
                    break
                end
            end
        end
    end

    DerixStats.activeFightRound = questId

    -- 1. Native UI prompt button click if open
    pcall(function()
        local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        local rfGui = pGui and pGui:FindFirstChild("RBRCRoadFightUi")
        if rfGui then
            local dlg = rfGui:FindFirstChild("RoadFightDlg")
            if dlg and dlg.Visible then
                local btn = dlg:FindFirstChild("btChallenge", true)
                if btn and firesignal then
                    firesignal(btn.Activated)
                end
            end
        end
    end)

    -- 2. Native RBRCRoadFightClient handler
    pcall(function()
        local renv = getrenv and getrenv() or { shared = shared }
        local rfc = renv.shared and renv.shared.RBRCRoadFightClient
        if rfc and rfc.talk then
            rfc.talk(1676)
        end
    end)

    -- 3. Network Remote Function: RoadFightRequest & QuestRequest
    pcall(function()
        local qRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
        local rfReq = qRemotes and qRemotes:FindFirstChild("RoadFightRequest")
        if rfReq then
            rfReq:InvokeServer({
                op = "accept",
                questId = questId,
                carPos = root.Position
            })
        end
    end)
    pcall(function()
        local qRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
        local qReq = qRemotes and qRemotes:FindFirstChild("QuestRequest")
        if qReq then
            qReq:InvokeServer({
                op = "accept",
                questId = questId,
                carPos = root.Position,
                carLook = root.CFrame.LookVector
            })
        end
    end)

    return true
end

-- Smart Auto Sell & Auto Trash ("Keep ONLY Money-Making Items")
local MONEY_BOX_IDS = {
    [15182] = true, -- Power Jet Box (500k)
    [18270] = true, -- Power Jet Box (700k)
    [19309] = true, -- Power Jet Box (1.5M)
}

local MONEY_KEEP_KEYWORDS = {
    "cash", "rain", "money", "coin", "gold", "silver",
    "box", "chest", "pouch", "lottery", "dice", "bingo",
    "jewel", "gem", "pearl", "diamond", "ruby", "emerald", "sapphire", "opal", "crystal", "rune",
    "drill", "enchant", "toolbox", "tool box", "upgrade", "jet box",
    "เพชร", "ไข่มุก", "พลอย", "ทอง", "เงิน", "กล่อง", "ลูกเต๋า", "สว่าน", "รูน", "ตีบวก",
}

local function matchesAnyKeyword(str, list)
    if not str or str == "" then return false end
    local low = string.lower(tostring(str))
    for _, kw in ipairs(list) do
        if string.find(low, kw, 1, true) then
            return true
        end
    end
    return false
end

local function loadInventoryModules()
    local rep = game:GetService("ReplicatedStorage")
    local rsShop = rep:FindFirstChild("RaycityShop")
    local rsProf = rep:FindFirstChild("RaycityProfile")
    local rsUse = rep:FindFirstChild("RaycityItemUse")

    local function safeReq(inst)
        if not inst then return nil end
        local ok, mod = pcall(require, inst)
        return ok and mod or nil
    end

    return {
        pc = safeReq(rsProf and rsProf:FindFirstChild("ProfileClient")),
        sc = safeReq(rsShop and rsShop:FindFirstChild("ShopClient")),
        shopItems = safeReq(rsShop and rsShop:FindFirstChild("ShopItems")),
        shopItemsExtra = safeReq(rsShop and rsShop:FindFirstChild("ShopItemsExtra")),
        sellPriceMod = safeReq(rsShop and rsShop:FindFirstChild("ItemSellPrice")),
        itemUseData = safeReq(rsUse and rsUse:FindFirstChild("ItemUseData")),
    }
end

local function lookupShopItemDef(id, mods)
    local numId = tonumber(id)
    local strId = tostring(id)
    local def = nil
    if mods.shopItems then
        def = (numId and mods.shopItems[numId]) or mods.shopItems[strId]
        if not def and type(mods.shopItems.get) == "function" then
            local okG, dG = pcall(mods.shopItems.get, numId or id)
            if okG then def = dG end
        end
    end
    if not def and mods.shopItemsExtra then
        def = (numId and mods.shopItemsExtra[numId]) or mods.shopItemsExtra[strId]
    end
    if not def and mods.sellPriceMod and type(mods.sellPriceMod.defOf) == "function" then
        local okD, dD = pcall(mods.sellPriceMod.defOf, numId or id)
        if okD then def = dD end
    end
    return def
end

local function computeItemSellPrice(item, def, sellPriceMod)
    if not item or not def then return 0 end
    if item.bound == true or item.expires ~= nil then return 0 end
    if def.bonding and def.bonding ~= 0 then return 0 end
    if def.type and def.type >= 5 and def.type <= 8 then return 0 end

    local p = nil
    if sellPriceMod and sellPriceMod.ofDef then
        local ok, res = pcall(sellPriceMod.ofDef, def, item.id)
        if ok then p = tonumber(res) end
    end
    return tonumber(p or def.sell) or 0
end

local function classifyInventoryItem(item, def, unitSell, itemUseData)
    if not item or not item.id or not item.uid then
        return "KEEP", "Missing Metadata"
    end
    if item.equipped then
        return "KEEP", "Equipped"
    end
    if not def then
        return "KEEP", "Unknown Item"
    end

    local id = tonumber(item.id)
    local itType = tonumber(def.type) or -1
    local kind = tostring(def.kind or "")
    local name = tostring(def.name or "")

    -- 1. Cash boxes, dice, lottery bags, drills, gems/pearls/runes, enchants, bingo kits
    if id and MONEY_BOX_IDS[id] then
        return "KEEP", "Cash Box"
    end
    if itemUseData and id then
        if (itemUseData.BOX and itemUseData.BOX[id])
            or (itemUseData.LOTTERY and itemUseData.LOTTERY[id])
            or (itemUseData.DICE and itemUseData.DICE[id])
        then
            return "KEEP", "Box/Lottery/Dice"
        end
        if itemUseData.ITEMS and itemUseData.ITEMS[id] and matchesAnyKeyword(name, { "jet box", "cash", "rain", "gold", "box", "เงิน", "กล่อง" }) then
            return "KEEP", "Cash Use Item"
        end
    end

    if kind == "Enchant" or kind == "Bingo" or kind == "Jewel" or kind == "Gem" or kind == "Drill" or kind == "Rune" then
        return "KEEP", "Money Kind (" .. kind .. ")"
    end

    if itType == 1 or itType == 11 or itType == 15 or itType == 16 or itType == 22 or itType == 23 or itType == 26 or itType == 31 or itType == 34 or itType == 36 then
        return "KEEP", "Money/Rare Type (" .. tostring(itType) .. ")"
    end

    if itType == 2 and matchesAnyKeyword(name, MONEY_KEEP_KEYWORDS) then
        return "KEEP", "Valuable Material"
    end

    -- 2. High-value sellable loot (>= MinKeepSellValue, disabled if threshold == 0)
    local threshold = tonumber(Config.MinKeepSellValue) or 5000
    local stackSell = unitSell * (tonumber(item.count) or 1)
    if threshold > 0 and (unitSell >= threshold or (itType ~= 20 and stackSell >= threshold)) then
        return "KEEP", "High Value (" .. tostring(unitSell) .. " Rain)"
    end

    -- 3. Protect EXP/Rain Tickets (type 10) & Car Keys (type 28) unless StrictMoneyOnly is enabled
    if (not Config.StrictMoneyOnly) and Config.ProtectTicketsAndKeys then
        if itType == 10 then
            return "KEEP", "Protected Ticket/Charm"
        end
        if itType == 28 then
            return "KEEP", "Protected Car Key"
        end
    end

    -- Never drop special/mission bound system types (5..8) accidentally
    if itType >= 5 and itType <= 8 then
        return "KEEP", "Special/Mission Type"
    end

    -- 4. Dispose remaining non-money items: sell if price > 0, else drop/trash
    if unitSell > 0 then
        return "SELL", "Non-Money Sellable (" .. tostring(unitSell) .. " Rain)"
    end
    return "TRASH", "Unsellable Junk (0 Rain)"
end

SmartInvBridge.classify = classifyInventoryItem
SmartInvBridge.computeSellPrice = computeItemSellPrice
SmartInvBridge.loadModules = loadInventoryModules
pcall(function()
    if type(getgenv) == "function" then
        getgenv().__RaycityHubState = {
            Config = Config,
            SmartInv = SmartInvBridge,
        }
    end
end)

function SmartInvBridge.run(forceAll, minFree, allowSell, allowTrash, dryRun)
    local stats = {
        soldCount = 0,
        earnedRain = 0,
        trashedCount = 0,
        keptCount = 0,
        freeSlots = 0,
        invSize = 30,
        preview = dryRun and {} or nil,
    }

    local mods = loadInventoryModules()
    if not mods.pc then return stats end

    local data = mods.pc.get and mods.pc.get()
    if not data or not data.inventory then
        data = mods.pc.request and mods.pc.request("get")
        data = data and (data.profile or data)
    end
    if not data or not data.inventory then return stats end

    local invSize = tonumber(data.invSize) or 30
    stats.invSize = invSize

    local sellList, trashList = {}, {}
    local itemCount = 0
    for cell, item in pairs(data.inventory) do
        itemCount = itemCount + 1
        local def = lookupShopItemDef(item.id, mods)
        local unitSell = computeItemSellPrice(item, def, mods.sellPriceMod)
        local action, reason = classifyInventoryItem(item, def, unitSell, mods.itemUseData)
        local cellNum = tonumber(cell)

        local entry = {
            cell = cellNum,
            id = item.id,
            uid = item.uid,
            count = item.count or 1,
            name = (def and def.name) or ("ID:" .. tostring(item.id)),
            itemType = def and def.type or nil,
            unitSell = unitSell,
            action = action,
            reason = reason,
        }

        if stats.preview then
            table.insert(stats.preview, entry)
        end

        if action == "SELL" then
            table.insert(sellList, entry)
        elseif action == "TRASH" then
            table.insert(trashList, entry)
        else
            stats.keptCount = stats.keptCount + 1
        end
    end

    local free = invSize - itemCount
    stats.freeSlots = free

    if dryRun then
        return stats
    end

    minFree = tonumber(minFree) or 10
    local needMoreSpace = forceAll or (free < minFree)
    if not needMoreSpace then
        return stats
    end

    -- 1. Always try selling non-money sellable loot FIRST to earn Rain cleanly
    if allowSell and mods.sc and mods.sc.request then
        table.sort(sellList, function(a, b) return a.unitSell < b.unitSell end)
        for _, entry in ipairs(sellList) do
            if not forceAll and free >= minFree then break end
            if entry.cell and entry.uid then
                local okS, res = pcall(mods.sc.request, "sell", {
                    cell = entry.cell,
                    count = entry.count,
                    uid = entry.uid,
                })
                if okS and res and res.ok then
                    stats.soldCount = stats.soldCount + 1
                    stats.earnedRain = stats.earnedRain + (tonumber(res.paid) or tonumber(res.total) or (entry.unitSell * entry.count))
                    free = free + 1
                    task.wait(0.06)
                end
            end
        end
    end

    -- 2. Drop unsellable junk (sell=0) only if enabled or forced (uses ShopClient.request("drop", ...))
    if allowTrash and mods.sc and mods.sc.request then
        for _, entry in ipairs(trashList) do
            if not forceAll and free >= minFree then break end
            if entry.cell and entry.uid then
                local okD, res = pcall(mods.sc.request, "drop", {
                    cell = entry.cell,
                    uid = entry.uid,
                })
                if okD and res and res.ok then
                    stats.trashedCount = stats.trashedCount + 1
                    free = free + 1
                    task.wait(0.06)
                end
            end
        end
    end

    stats.freeSlots = free
    return stats
end

local function ensureInventorySpace(minFree)
    if not Config.AutoCleanInventory and not Config.AutoSellJunk and not Config.AutoTrashJunk then
        return
    end
    minFree = minFree or 10
    pcall(function()
        local allowSell = Config.AutoCleanInventory or Config.AutoSellJunk
        local allowTrash = Config.AutoTrashJunk or Config.AutoCleanInventory
        -- Sell all non-money junk first; if AutoCleanInventory still needs slots under minFree, drop sell=0 junk too
        local stats = SmartInvBridge.run(Config.AutoSellJunk, minFree, allowSell, Config.AutoTrashJunk, false)
        if Config.AutoCleanInventory and stats.freeSlots < minFree and allowTrash and not Config.AutoTrashJunk then
            SmartInvBridge.run(false, minFree, false, true, false)
        end
    end)
end

-- ==============================================================================
-- 🏁 6. ACTIVE QUEST DESTINATION DETECTOR & NPC RESOLVER
-- ==============================================================================
getNpcWorldPos = function(target)
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
    if cleanName:find("derix") or cleanName:find("เดอร์ริก") or cleanName:find("เดริก") or numId == 1676 or numId == 931676 then
        return DERIX_COORDS
    end
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

    -- 2. Workspace RBRCNpcs model (Exact key match first to avoid "1" matching "10030")
    local rawStr = tostring(target)
    local hasPrefix = rawStr:find(":", 1, true) ~= nil
    local npcsFolder = workspace:FindFirstChild("RBRCNpcs")
    if npcsFolder then
        for _, n in ipairs(npcsFolder:GetChildren()) do
            if n.Name:lower() == cleanName then
                local p = n.PrimaryPart or n:FindFirstChild("HumanoidRootPart") or n:FindFirstChild("Root") or n:FindFirstChildWhichIsA("BasePart")
                if p then return p.Position end
                return n:GetPivot().Position
            end
        end
        if numId and not hasPrefix then
            for _, n in ipairs(npcsFolder:GetChildren()) do
                local nName = n.Name
                local nId = nName:match("(%d+)$") or tostring(n:GetAttribute("NpcId") or ""):match("(%d+)$") or tostring(n:GetAttribute("MissionId") or ""):match("(%d+)$")
                if nId == tostring(numId) then
                    local p = n.PrimaryPart or n:FindFirstChild("HumanoidRootPart") or n:FindFirstChild("Root") or n:FindFirstChildWhichIsA("BasePart")
                    if p then return p.Position end
                    return n:GetPivot().Position
                end
            end
        end
        if #cleanName >= 3 then
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
    end

    -- 3. QuestDataSkill.npcs table
    local skillPos = nil
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local qSkill = require(rep.RBRCQuest.QuestDataSkill)
        if qSkill and qSkill.npcs then
            if numId and not hasPrefix and qSkill.npcs[numId] and qSkill.npcs[numId].roblox then
                local r = qSkill.npcs[numId].roblox
                skillPos = Vector3.new(r[1], r[2], r[3])
                return
            end
            for id, nData in pairs(qSkill.npcs) do
                if nData.name and #cleanName >= 3 and nData.name:lower():find(cleanName, 1, true) and nData.roblox then
                    local r = nData.roblox
                    skillPos = Vector3.new(r[1], r[2], r[3])
                    return
                end
            end
        end
    end)
    if skillPos then return skillPos end

    -- 4. QuestData.npc (requires full string id like "mission:1" or "thtalk:10030")
    local qDataPos = nil
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local qData = require(rep.RBRCQuest.QuestData)
        if qData and qData.npc then
            local d = qData.npc(rawStr) or qData.npc(cleanName)
            if not d and numId then
                local sId = tostring(numId)
                for _, pref in ipairs({ "mission:", "mission24:", "thtalk:", "roadfight:", "th:" }) do
                    d = qData.npc(pref .. sId)
                    if d and d.position then break end
                end
                if not d then
                    d = qData.npc(numId)
                end
            end
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

local function getLiveMissionState(forceRefresh)
    local now = os.clock()
    if not forceRefresh and (now - _lastLiveMissionCheck) < 0.2 and _cachedLiveMission ~= nil then
        return _cachedLiveMission
    end
    _lastLiveMissionCheck = now
    pcall(function()
        local qr = ReplicatedStorage:FindFirstChild("RBRCQuest")
        local remotes = qr and qr:FindFirstChild("Remotes")
        local qReq = remotes and remotes:FindFirstChild("QuestRequest")
        if qReq then
            local st = qReq:InvokeServer({ op = "state" })
            if st and st.profile then
                if st.profile.level then
                    _cachedProfileLevel = tonumber(st.profile.level)
                end
                if type(st.profile.done) == "table" then
                    _cachedProfileDone = st.profile.done
                end
            end
            if st and st.mission and (st.mission.state == "running" or st.mission.state == "boarding") then
                _cachedLiveMission = st.mission
                return
            end
        end
        _cachedLiveMission = false
    end)
    return _cachedLiveMission
end

local function resolveMissionObjectiveFromState(stMission)
    if not stMission or (stMission.state ~= "running" and stMission.state ~= "boarding") then
        return nil, nil, nil, false
    end

    if stMission.questId then
        _lastActiveQuestId = stMission.questId
    end

    if stMission.state == "boarding" then
        if _boardingStartTime == 0 then
            _boardingStartTime = os.clock()
        elseif (os.clock() - _boardingStartTime) > 0.6 and (os.clock() - _lastBoardedTryTime) > 0.35 then
            _lastBoardedTryTime = os.clock()
            pcall(function()
                local qReq = ReplicatedStorage.RBRCQuest.Remotes.QuestRequest
                if qReq and stMission.questId then
                    local res = qReq:InvokeServer({ op = "boarded", questId = stMission.questId })
                    if res and res.ok then
                        _lastLiveMissionCheck = 0
                        _cachedLiveMission = nil
                    end
                end
            end)
            clearCarHoldLocks()
        end
        return nil, nil, "boarding", false
    end

    _boardingStartTime = 0
    clearCarHoldLocks()

    -- Load static quest definition from QuestData so we have exact .dest.center / .dest.target / .dest.stop / .dest.poly
    local qDef = stMission.q
    if not qDef and stMission.questId then
        pcall(function()
            local qd = require(ReplicatedStorage.RBRCQuest.QuestData)
            if qd and qd.get then
                qDef = qd.get(stMission.questId)
            end
        end)
    end

    local curStep = tonumber(stMission.step) or 0
    local stObjs = stMission.objectives or {}

    if qDef and type(qDef.objectives) == "table" and #qDef.objectives > 0 then
        local minPendingStep = nil
        if curStep == 0 then
            for _, v in ipairs(qDef.objectives) do
                local idx = v.idx
                local liveObj = stObjs[idx] or stObjs[tostring(idx)]
                local isDone = liveObj and (liveObj.done == true or liveObj.mine == true)
                local vStep = tonumber(v.step) or 0
                if not isDone and not v.passive and vStep > 0 then
                    if not minPendingStep or vStep < minPendingStep then
                        minPendingStep = vStep
                    end
                end
            end
        end

        local activeCandidates = {}
        for _, v in ipairs(qDef.objectives) do
            local idx = v.idx
            local liveObj = stObjs[idx] or stObjs[tostring(idx)]
            local isDone = liveObj and (liveObj.done == true or liveObj.mine == true)
            if not isDone and not v.passive then
                local vStep = tonumber(v.step) or 0
                local stepMatches = (vStep == 0)
                    or (curStep > 0 and vStep == curStep)
                    or (curStep == 0 and (not minPendingStep or vStep == minPendingStep))
                if stepMatches then
                    local targetVec = nil
                    local isStop = false
                    local minSpeedKmh = 0
                    local poly = nil
                    local liveObj = stMission.objectives and (stMission.objectives[idx] or stMission.objectives[tostring(idx)])

                    if v.cls == "Return" then
                        isStop = true
                        local rPoly = stMission.retPoly and (stMission.retPoly[idx] or stMission.retPoly[tostring(idx)])
                        if type(rPoly) == "table" and #rPoly > 0 then
                            poly = rPoly
                            local sum = Vector3.zero
                            for _, pt in ipairs(rPoly) do sum = sum + pt end
                            targetVec = sum / #rPoly
                        elseif qDef.npcId then
                            targetVec = getNpcWorldPos(qDef.npcId)
                        end
                    elseif type(v.dest) == "table" then
                        targetVec = v.dest.center or v.dest.target or (liveObj and liveObj.target)
                        isStop = (v.dest.stop == true) or (v.cls == "PhotoDest") or (v.dest.pillar == "photo")
                        minSpeedKmh = tonumber(v.dest.minSpeedKmh) or 0
                        poly = v.dest.poly or (liveObj and liveObj.poly)
                    elseif liveObj and typeof(liveObj.target) == "Vector3" then
                        targetVec = liveObj.target
                        isStop = (v.cls == "PhotoDest") or (liveObj.stop == true)
                        poly = liveObj.poly
                    end

                    if not targetVec and liveObj then
                        if typeof(liveObj.target) == "Vector3" then
                            targetVec = liveObj.target
                        elseif type(liveObj.target) == "table" and liveObj.target.x then
                            targetVec = Vector3.new(liveObj.target.x, liveObj.target.y, liveObj.target.z)
                        end
                    end

                    if typeof(targetVec) == "Vector3" then
                        table.insert(activeCandidates, {
                            idx = idx,
                            target = targetVec,
                            stop = isStop,
                            minSpeedKmh = minSpeedKmh,
                            poly = poly,
                            cls = v.cls,
                            questId = stMission.questId,
                            step = vStep
                        })
                    end
                end
            end
        end

        if #activeCandidates > 0 then
            -- Pick closest active objective in current step (or first in sequence)
            local chosen = activeCandidates[1]
            local root = getCarRoot()
            if root and #activeCandidates > 1 then
                local bestD = math.huge
                for _, cand in ipairs(activeCandidates) do
                    local d = (cand.target - root.Position).Magnitude
                    if d < bestD then
                        bestD = d
                        chosen = cand
                    end
                end
            end
            return chosen.target, chosen, "running", chosen.stop
        end
    end

    -- Fallback: check if stObjs directly contains Vector3 targets
    local targetObjs = {}
    for idx, obj in pairs(stObjs) do
        if type(obj) == "table" then
            local v = nil
            if typeof(obj.target) == "Vector3" then
                v = obj.target
            elseif type(obj.target) == "table" and obj.target.x and obj.target.y and obj.target.z then
                v = Vector3.new(obj.target.x, obj.target.y, obj.target.z)
            end
            if v then
                table.insert(targetObjs, { idx = tonumber(idx) or 1, obj = obj, target = v })
            end
        end
    end
    table.sort(targetObjs, function(a, b) return a.idx < b.idx end)
    for tIdx, item in ipairs(targetObjs) do
        local obj = item.obj
        if (obj.active or not obj.done) then
            local isFin = (tIdx == #targetObjs)
            return item.target, obj, "running", isFin
        end
    end

    return nil, nil, stMission.state, false
end

local function getActiveMissionTarget()
    -- 0. Check Active Road Fight Checkpoints (Level Farm & Derix Farm)
    local activeRId = (Config.AutoFarmLevel and LevelFarmStats.activeFightRound) or (Config.AutoFarmDerix and DerixStats.activeFightRound)
    if activeRId then
        local root = getCarRoot()
        local clearedSet = Config.AutoFarmLevel and LevelFarmStats.clearedGates or DerixStats.clearedGates
        local gPos, isFin, gIdx = getRoadFightNextGate(activeRId, root and root.Position, clearedSet)
        if gPos then
            return gPos, nil, "roadfight", isFin
        end
    end

    -- 1. Check shared.RBRCQuest.state() first (instant, zero-latency client state with .q and .retPoly)
    local clientMission = nil
    pcall(function()
        local gs = getGameShared()
        local rq = gs and gs.RBRCQuest
        if rq and type(rq.state) == "function" then
            clientMission = rq.state()
        end
    end)
    if clientMission and (clientMission.state == "running" or clientMission.state == "boarding") then
        local tPos, mObj, mType, isFin = resolveMissionObjectiveFromState(clientMission)
        if tPos or mType == "boarding" then
            return tPos, mObj, mType, isFin
        end
    end

    -- 2. Direct Server-Verified Quest State from QuestRequest (Guaranteed Live)
    local liveM = getLiveMissionState()
    if liveM and (liveM.state == "running" or liveM.state == "boarding") then
        local tPos, mObj, mType, isFin = resolveMissionObjectiveFromState(liveM)
        if tPos or mType == "boarding" then
            return tPos, mObj, mType, isFin
        end
    end

    return nil, nil, nil, false
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

    -- Priority 0: Live Active Taxi/Driving/Delivery Mission Checkpoints (Running or Boarding right now)
    local mTarget, mObj, mState, isFinish = getActiveMissionTarget()
    if mState == "boarding" then
        return nil, nil, nil, "boarding", "boarding"
    end
    if mTarget then
        if not navPoints and okNav and nav and nav.pointTo then
            pcall(nav.pointTo, mTarget)
            local okGl2, gl2 = pcall(nav.getGuideLine)
            if okGl2 and gl2 and gl2.points and #gl2.points > 0 then
                navPoints = gl2.points
            end
        end
        local dType = isFinish and "mission_finish" or "checkpoint"
        return mTarget, mObj, navPoints, dType, mState
    end

    local isStoryOrMax = Config.AutoStoryProgression or Config.AutoLevel1ToMax

    -- Priority 1: Check Skill Quest / Newbie Quest system
    local qqState = getSkillQuestState()

    if qqState and qqState.active and #qqState.active > 0 then
        local activeQ = qqState.active[1]
        local qIdKey = "sq:" .. tostring(activeQ.questId or "")
        local sqOnCd = (npcVisitCooldown[qIdKey] or 0) > os.clock()
        local unfinishedObj = nil
        if activeQ.ojt then
            for _, obj in ipairs(activeQ.ojt) do
                if not obj.done then
                    unfinishedObj = obj
                    break
                end
            end
        end

        local readyToTurnIn = (not unfinishedObj and (#(activeQ.ojt or {}) == 0 or activeQ.completed or activeQ.status == "reward"))
            or (unfinishedObj and (unfinishedObj.returnTo or unfinishedObj.kind == "npc"))
            or activeQ.completedExceptNpcId or activeQ.completedExceptAnyNpc or activeQ.status == "reward" or activeQ.completed

        -- A. Need to return to NPC to report in / claim reward:
        if not sqOnCd and readyToTurnIn then
            local targetId = activeQ.completedExceptNpcId or activeQ.rewardNpc or (unfinishedObj and unfinishedObj.target) or activeQ.npcId or 2000
            local pos = getNpcWorldPos(targetId)
            if pos then
                if not isStoryOrMax and not navPoints and okNav and nav and nav.pointTo then
                    pcall(nav.pointTo, pos)
                    local okGl, gl = pcall(nav.getGuideLine)
                    if okGl and gl and gl.points and #gl.points > 0 then navPoints = gl.points end
                end
                return pos, nil, navPoints, "skill_return_npc", activeQ
            end
        -- B. Need to do a mission NPC (only if unlocked for current player level!):
        elseif not sqOnCd and unfinishedObj and (unfinishedObj.kind == "missionNpc" or unfinishedObj.kind == "mission") then
            local targetId = unfinishedObj.target
            local curLv = getPlayerLevel()
            local npcLevelOk = true
            pcall(function()
                local qd = require(ReplicatedStorage.RBRCQuest.QuestData)
                if qd and qd.questsForNpc and qd.get then
                    local bestLv = nil
                    for _, pref in ipairs({ "mission:", "mission24:", "thtalk:", "th:" }) do
                        local key = type(targetId) == "string" and targetId or (pref .. tostring(targetId))
                        local list = qd.questsForNpc(key)
                        if type(list) == "table" and #list > 0 then
                            for _, qid in ipairs(list) do
                                local def = qd.get(qid)
                                if def and def.playable ~= false then
                                    local ql = tonumber(def.level) or 1
                                    if not bestLv or ql < bestLv then bestLv = ql end
                                end
                            end
                            break
                        end
                    end
                    if bestLv and bestLv > curLv then
                        npcLevelOk = false
                    end
                end
            end)
            if npcLevelOk then
                local pos = getNpcWorldPos(targetId) or getNpcWorldPos("mission:" .. tostring(targetId))
                if pos then
                    if not isStoryOrMax and not navPoints and okNav and nav and nav.pointTo then
                        pcall(nav.pointTo, pos)
                        local okGl, gl = pcall(nav.getGuideLine)
                        if okGl and gl and gl.points and #gl.points > 0 then navPoints = gl.points end
                    end
                    return pos, nil, navPoints, "skill_mission_npc", { quest = activeQ, targetId = targetId }
                end
            end
        end
    end

    if isStoryOrMax then
        return nil, nil, nil, nil, nil
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

    -- Priority 3: Navigation GuideLine (Ground Truth from RaycityUi.Navigation)
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

    -- Priority 4: Road Guide Quads from workspace.RaycityNavigation
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

    -- Priority 5: Parse candidate texts from other HUD elements
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

    -- Priority 6: Existing workspace quest markers
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

-- Autonomous Driving State & Anti-Stuck Tracking
local currentAutoTarget = nil
local lastWarpTime = 0
local isWarping = false
local lastProgressPos = nil
local lastProgressTime = os.clock()

getPlayerLevel = function()
    local lvl = nil
    pcall(function()
        local at = LocalPlayer:GetAttribute("RaycityPlayerLv") or LocalPlayer:GetAttribute("Level") or LocalPlayer:GetAttribute("userLevel")
        if at then lvl = tonumber(at) end
    end)
    if not lvl then
        pcall(function()
            local qq = getSkillQuestState()
            if qq and qq.level then lvl = tonumber(qq.level) end
        end)
    end
    if not lvl then
        pcall(function()
            local rep = game:GetService("ReplicatedStorage")
            local pcMod = rep:FindFirstChild("RaycityProfile") and rep.RaycityProfile:FindFirstChild("ProfileClient")
            if pcMod then
                local pc = require(pcMod)
                local data = pc.get and pc.get()
                if data and data.level then lvl = tonumber(data.level) end
            end
        end)
    end
    if not lvl and _cachedProfileLevel then
        lvl = _cachedProfileLevel
    end
    return lvl or 1
end

local function getCarLevel()
    local cLvl = nil
    pcall(function()
        local at = LocalPlayer:GetAttribute("RaycityCarLv") or LocalPlayer:GetAttribute("carLevel")
        if at then cLvl = tonumber(at) end
    end)
    if not cLvl then
        pcall(function()
            local rep = game:GetService("ReplicatedStorage")
            local pcMod = rep:FindFirstChild("RaycityProfile") and rep.RaycityProfile:FindFirstChild("ProfileClient")
            if pcMod then
                local pc = require(pcMod)
                local data = pc.get and pc.get()
                if data and data.car and data.car.level then
                    cLvl = tonumber(data.car.level)
                elseif data and data.carLevel then
                    cLvl = tonumber(data.carLevel)
                end
            end
        end)
    end
    return cLvl or 1
end

local function getAutoDrive()
    local ok, ad = pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local rUi = rep:FindFirstChild("RaycityUi")
        return rUi and rUi:FindFirstChild("AutoDrive") and require(rUi.AutoDrive)
    end)
    return ok and ad or nil
end

stopAutoDrive = function()
    pcall(function()
        local ad = getAutoDrive()
        if ad and ad.stop then
            ad.stop()
        end
    end)
    currentAutoTarget = nil
end

-- Anti-Quarantine Smooth Instant Glide (no mid-flight rcd.teleport destruction!)
local function steppedAntiQuarantineWarp(targetPos, faceDir, endSpeedMps, stopAtEnd, allowFinalRespawn)
    local root = getCarRoot()
    if not root or not targetPos then return end
    ensureBackgroundCarSync()
    clearCarHoldLocks()

    local startPos = root.Position
    local totalVec = targetPos - startPos
    local totalDist = totalVec.Magnitude
    local flatDir = (faceDir and Vector3.new(faceDir.X, 0, faceDir.Z).Magnitude > 0.05) and Vector3.new(faceDir.X, 0, faceDir.Z).Unit
        or (Vector3.new(totalVec.X, 0, totalVec.Z).Magnitude > 0.05 and Vector3.new(totalVec.X, 0, totalVec.Z).Unit or Vector3.new(0, 0, -1))

    local qt = nil
    pcall(function()
        qt = ReplicatedStorage.RBRCQuest.Remotes.QuestTelemetry
    end)

    local glideSpeedSps = 450
    local duration = totalDist > 10 and math.clamp(totalDist / glideSpeedSps, 0.08, 12.0) or 0.06
    local endPos = targetPos + Vector3.new(0, 1.5, 0)
    local travelSpeed = math.max(18, math.min(60, endSpeedMps or 45))

    local t0 = os.clock()
    local lastTelem = 0
    while true do
        if not isAlive() then break end
        local anyActive = Config.AutoFarmQuests or Config.AutoStoryProgression or Config.AutoLevel1ToMax or Config.AutoFarmLevel or Config.AutoFarmDerix
        if not anyActive then break end

        local elapsed = os.clock() - t0
        local alpha = math.clamp(elapsed / duration, 0, 1)
        local pos = startPos:Lerp(endPos, alpha)
        local isFinalTick = (alpha >= 1)
        local curVel = (stopAtEnd and isFinalTick) and Vector3.zero or (flatDir * (isFinalTick and (endSpeedMps or 0) or travelSpeed))
        local cf = CFrame.lookAt(pos, pos + flatDir * 10)
        local rot = cf - cf.Position

        local rcd = getRCDrive()
        root = getCarRoot()
        local car = getMyCar()
        if not root then break end
        if root.Anchored then root.Anchored = false end

        if rcd and type(rcd.phys) == "table" then
            pcall(function()
                rcd.phys.cf = CFrame.new(pos / 2) * rot
                rcd.phys.v = curVel / 2
                rcd.phys.w = Vector3.zero
                rcd.phys.throttle = (stopAtEnd and isFinalTick) and 0 or 1
                rcd.phys.brake = (stopAtEnd and isFinalTick) and 1 or 0
                rcd.phys.handbrake = (stopAtEnd and isFinalTick) and 1 or 0
                rcd.phys.airMode = false
                rcd.phys.anyContact = true
            end)
        end
        root.CFrame = cf
        root.AssemblyLinearVelocity = curVel
        root.AssemblyAngularVelocity = Vector3.zero
        if car and car.PrimaryPart then
            pcall(function() car:PivotTo(cf) end)
        end

        local now = os.clock()
        if qt and (isFinalTick or (now - lastTelem) >= 0.2) then
            lastTelem = now
            pcall(function()
                qt:FireServer({
                    pos = pos,
                    speed = curVel.Magnitude,
                    stopped = (stopAtEnd and isFinalTick),
                    gear = (stopAtEnd and isFinalTick) and 0 or 3
                })
            end)
        end

        if isFinalTick then break end
        RunService.Heartbeat:Wait()
    end

    if allowFinalRespawn then
        local rcd = getRCDrive()
        local finalCF = CFrame.lookAt(endPos + Vector3.new(0, 0.5, 0), endPos + Vector3.new(0, 0.5, 0) + flatDir * 10)
        if rcd and type(rcd.teleport) == "function" then
            pcall(rcd.teleport, finalCF)
            local w0 = os.clock()
            while (os.clock() - w0) < 1.2 do
                local nr = getCarRoot()
                if nr and not nr.Anchored then break end
                task.wait(0.05)
            end
        end
    end
end

local function isMissionStepCleared(initQuestId, initStep, objIdx)
    local st = nil
    pcall(function()
        local gs = getGameShared()
        local rq = gs and gs.RBRCQuest
        if rq and type(rq.state) == "function" then
            st = rq.state()
        end
    end)
    if not st or (st.state ~= "running" and st.state ~= "boarding") then
        local liveM = getLiveMissionState(true)
        if not liveM or (liveM.state ~= "running" and liveM.state ~= "boarding") then
            return true
        end
        st = liveM
    end
    if initQuestId and st.questId ~= initQuestId then
        return true
    end
    if initStep ~= nil and tonumber(st.step) ~= tonumber(initStep) then
        return true
    end
    if objIdx ~= nil and type(st.objectives) == "table" then
        local liveObj = st.objectives[objIdx] or st.objectives[tostring(objIdx)]
        if liveObj and (liveObj.done == true or liveObj.mine == true) then
            return true
        end
    end
    return false
end

local function waitUntilObjectiveCleared(targetPos, flatDir, isStop, passSpeedMps, initQuestId, initStep, objIdx)
    local qt = nil
    pcall(function()
        qt = ReplicatedStorage.RBRCQuest.Remotes.QuestTelemetry
    end)

    local wStart = os.clock()
    local lastTelem = 0
    local lastServerPoll = 0
    local dirSign = 1

    while (os.clock() - wStart) < 12.0 do
        if not isAlive() then break end
        local anyActive = Config.AutoFarmQuests or Config.AutoStoryProgression or Config.AutoLevel1ToMax
        if not anyActive then break end

        local now = os.clock()
        local checkServer = (now - lastServerPoll) >= 0.45
        if checkServer then
            lastServerPoll = now
            local liveM = getLiveMissionState(true)
            if not liveM or (liveM.state ~= "running" and liveM.state ~= "boarding") then
                _lastLiveMissionCheck = 0
                _cachedLiveMission = nil
                return true
            end
            if initQuestId and liveM.questId ~= initQuestId then
                _lastLiveMissionCheck = 0
                return true
            end
            if initStep ~= nil and tonumber(liveM.step) ~= tonumber(initStep) then
                _lastLiveMissionCheck = 0
                return true
            end
            if objIdx ~= nil and type(liveM.objectives) == "table" then
                local o = liveM.objectives[objIdx] or liveM.objectives[tostring(objIdx)]
                if o and (o.done == true or o.mine == true) then
                    _lastLiveMissionCheck = 0
                    return true
                end
            end
        end

        if isMissionStepCleared(initQuestId, initStep, objIdx) then
            _lastLiveMissionCheck = 0
            return true
        end

        local rcd = getRCDrive()
        local root = getCarRoot()
        local car = getMyCar()
        if not root then break end
        if root.Anchored then root.Anchored = false end

        local holdPos = targetPos + Vector3.new(0, 0.8, 0)
        local holdVel = Vector3.zero
        if not isStop then
            -- Gently oscillate +/- 3 studs across checkpoint center at pass speed so minSpeed & poly both register cleanly
            local phase = ((now - wStart) * 2.5) % 2
            local off = (phase <= 1) and (-3 + phase * 6) or (3 - (phase - 1) * 6)
            dirSign = (phase <= 1) and 1 or -1
            holdPos = targetPos + flatDir * off + Vector3.new(0, 0.8, 0)
            holdVel = flatDir * (dirSign * math.max(16, passSpeedMps or 25))
        end

        local cf = CFrame.lookAt(holdPos, holdPos + flatDir * 10)
        local rot = cf - cf.Position
        if rcd and type(rcd.phys) == "table" then
            pcall(function()
                rcd.phys.cf = CFrame.new(holdPos / 2) * rot
                rcd.phys.v = holdVel / 2
                rcd.phys.w = Vector3.zero
                rcd.phys.throttle = isStop and 0 or 1
                rcd.phys.brake = isStop and 1 or 0
                rcd.phys.handbrake = isStop and 1 or 0
                rcd.phys.airMode = false
                rcd.phys.anyContact = true
            end)
        end
        root.CFrame = cf
        root.AssemblyLinearVelocity = holdVel
        root.AssemblyAngularVelocity = Vector3.zero
        if car and car.PrimaryPart then
            pcall(function() car:PivotTo(cf) end)
        end

        if qt and (now - lastTelem) >= 0.2 then
            lastTelem = now
            pcall(function()
                qt:FireServer({
                    pos = holdPos,
                    speed = isStop and 0 or holdVel.Magnitude,
                    stopped = isStop,
                    gear = isStop and 0 or 3
                })
            end)
        end

        task.wait(0.08)
    end

    return false
end

local function executeMoveStep(targetPos, destType, speedKmh, metaObj)
    local root = getCarRoot()
    local rcd = getRCDrive()
    if not root or not targetPos then return end
    clearCarHoldLocks()

    local dist = (root.Position - targetPos).Magnitude
    local mode = Config.QuestDriveMode or "Instant Warp"
    if Config.AutoLevel1ToMax and mode ~= "Instant Warp" then
        mode = "Instant Warp"
    end

    -- ⚡ Mode 1: Instant Warp (Smooth Anti-Cheat Glide + Server-Verified Step Wait)
    if mode == "Instant Warp" then
        if not isWarping and (os.clock() - lastWarpTime) >= 0.05 then
            isWarping = true
            stopAutoDrive()
            pcall(function()
                local rawFlat = Vector3.new(targetPos.X - root.Position.X, 0, targetPos.Z - root.Position.Z)
                local dir = rawFlat.Magnitude > 0.1 and rawFlat.Unit or root.CFrame.LookVector
                dir = Vector3.new(dir.X, 0, dir.Z).Magnitude > 0.05 and Vector3.new(dir.X, 0, dir.Z).Unit or Vector3.new(0, 0, -1)

                if destType == "checkpoint" or destType == "mission_finish" then
                    local liveBefore = getLiveMissionState(true)
                    local initQuestId = (liveBefore and liveBefore.questId) or (type(metaObj) == "table" and metaObj.questId) or nil
                    local initStep = liveBefore and liveBefore.step or (type(metaObj) == "table" and metaObj.step) or nil
                    local objIdx = (type(metaObj) == "table" and metaObj.idx) or nil

                    if destType == "checkpoint" then
                        local minSpdKmh = (type(metaObj) == "table" and tonumber(metaObj.minSpeedKmh)) or 0
                        local passSpeedMps = math.max(25, (minSpdKmh + 25) / 3.6)

                        steppedAntiQuarantineWarp(targetPos, dir, passSpeedMps, false, false)

                        pcall(function()
                            if firetouchinterest then
                                local curRoot = getCarRoot()
                                local parts = curRoot and workspace:GetPartBoundsInRadius(targetPos, 30) or {}
                                for _, p in ipairs(parts) do
                                    if p:IsA("BasePart") and p ~= curRoot and (not workspace:FindFirstChild("MyCar") or not p:IsDescendantOf(workspace.MyCar)) then
                                        firetouchinterest(curRoot, p, 0)
                                        task.wait(0.01)
                                        firetouchinterest(curRoot, p, 1)
                                    end
                                end
                            end
                        end)

                        waitUntilObjectiveCleared(targetPos, dir, false, passSpeedMps, initQuestId, initStep, objIdx)
                    else
                        -- Final Finish Line / Drop-off / Stop Objective (NO rcd.teleport mid-mission!)
                        steppedAntiQuarantineWarp(targetPos, dir, 0, true, false)

                        pcall(function()
                            local npMod = ReplicatedStorage:FindFirstChild("RBRCNpc") and ReplicatedStorage.RBRCNpc:FindFirstChild("NpcPassenger")
                            if npMod then
                                local np = require(npMod)
                                if np.exitRun then np.exitRun() end
                                if np.deliverRun then np.deliverRun() end
                            end
                            local qDeliver = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("QuestDeliver")
                            if qDeliver then
                                local qd = require(qDeliver)
                                if qd.finish then qd.finish() end
                                if qd.trunk then qd.trunk(true) end
                            end
                        end)

                        pcall(function()
                            if firetouchinterest then
                                local curRoot = getCarRoot()
                                local parts = curRoot and workspace:GetPartBoundsInRadius(targetPos, 25) or {}
                                for _, p in ipairs(parts) do
                                    if p:IsA("BasePart") and p ~= curRoot and (not workspace:FindFirstChild("MyCar") or not p:IsDescendantOf(workspace.MyCar)) then
                                        firetouchinterest(curRoot, p, 0)
                                        task.wait(0.01)
                                        firetouchinterest(curRoot, p, 1)
                                    end
                                end
                            end
                        end)

                        waitUntilObjectiveCleared(targetPos, dir, true, 0, initQuestId, initStep, objIdx)
                    end
                else
                    -- NPC or generic pre-mission destination: smooth physics+pivot glide synced via CarStateUp (no destructive rcd.teleport)
                    local roadTarget = targetPos - dir * 5.0
                    steppedAntiQuarantineWarp(roadTarget, dir, 18, true, false)
                    performTrustSyncRoll(roadTarget, dir, false)
                end
            end)
            lastWarpTime = os.clock()
            task.wait(0.05)
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
                steppedAntiQuarantineWarp(nearWarpPos, dir, 20)
            end)
            lastWarpTime = os.clock()
            task.wait(0.4)
            isWarping = false
            return
        end
    end

    -- 🏎️ Modes 3 & 4: Native AutoDrive Engine (Realistic Road Drive & Hyper Sonic Glide)
    local ad = getAutoDrive()
    if not ad then
        pcall(driveCarStep, targetPos, speedKmh or 160, false)
        return
    end

    local desiredSpeed = speedKmh or Config.QuestDriveSpeed or 220
    if mode == "Realistic Road Drive" then
        desiredSpeed = math.min(180, desiredSpeed)
    elseif mode == "Hyper Sonic Glide" then
        desiredSpeed = math.max(260, desiredSpeed)
    end
    local maxSpeedMps = desiredSpeed / 3.6

    pcall(function()
        ad.canCruise = function() return true end
        if ad.C then
            ad.C.maxSpeed = maxSpeedMps
            if mode == "Hyper Sonic Glide" then
                ad.C.cap1 = math.max(300, desiredSpeed * 1.15)
                ad.C.cap2 = math.max(250, desiredSpeed * 0.95)
                ad.C.cap3 = math.max(200, desiredSpeed * 0.8)
                ad.C.nearDestM = (destType == "checkpoint") and 5 or ((destType == "mission_finish") and 4 or 8)
            else
                ad.C.cap1 = math.min(200, desiredSpeed * 1.0)
                ad.C.cap2 = math.min(160, desiredSpeed * 0.85)
                ad.C.cap3 = math.min(120, desiredSpeed * 0.7)
                ad.C.nearDestM = (destType == "checkpoint") and 6 or ((destType == "mission_finish") and 4 or 10)
            end
        end
    end)

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

    if mode == "Hyper Sonic Glide" and rcd and type(rcd.phys) == "table" then
        pcall(function()
            rcd.phys.boosting = true
            rcd.phys.torqueBonus = 8000
            rcd.phys.throttle = 1
            if rcd.phys.brake then rcd.phys.brake = 0 end
        end)
    end
end


-- ==============================================================================
-- 🎯 LEVEL-MATCHED NPC & QUEST FINDER (เลือก NPC ที่ตรงกับเลเวลผู้เล่นจริงๆ 100%)
-- ==============================================================================
local _lastQuestSearchLv = nil
local _lastDoneRefreshTime = 0

local function findBestLevelMatchedNpc(playerLv)
    if (os.clock() - _lastDoneRefreshTime) > 4.0 then
        _lastDoneRefreshTime = os.clock()
        getLiveMissionState(true)
    end

    local curLv = tonumber(playerLv) or getPlayerLevel() or 1
    if _lastQuestSearchLv ~= curLv then
        _lastQuestSearchLv = curLv
        -- Level changed: clear cooldowns so newly unlocked level-matched quests become eligible right away
        table.clear(npcVisitCooldown)
    end

    local root = getCarRoot()
    local carPos = root and root.Position or Vector3.zero
    local npcsFolder = workspace:FindFirstChild("RBRCNpcs")
    local now = os.clock()

    -- Map active job icons in workspace for bonus priority
    local iconPositions = {}
    local jobIcons = workspace:FindFirstChild("RaycityNpcJobIcons")
    if jobIcons then
        for _, icon in ipairs(jobIcons:GetChildren()) do
            local p = icon:IsA("BasePart") and icon or icon:FindFirstChildWhichIsA("BasePart") or (icon:IsA("Model") and icon.PrimaryPart)
            if p then table.insert(iconPositions, p.Position) end
        end
    end

    local qd, rd = nil, nil
    pcall(function() qd = require(ReplicatedStorage.RBRCQuest.QuestData) end)
    pcall(function() rd = require(ReplicatedStorage.RBRCQuest.RewardData) end)

    local streamedById = {}
    if npcsFolder then
        for _, npc in ipairs(npcsFolder:GetChildren()) do
            local rId = tostring(npc:GetAttribute("RBRCNpcId") or "")
            if rId ~= "" then
                streamedById[rId] = npc
            end
        end
    end

    -- Collect ALL story/taxi/delivery NPCs across the entire map (QuestData.npcRows) + streamed RBRCNpcs
    local npcEntries = {}
    if qd and type(qd.npcRows) == "table" then
        for _, row in ipairs(qd.npcRows) do
            local rId = tostring((type(row) == "table" and (row[1] or row.npcId or row.id)) or "")
            local isQuestNpc = rId:find("^mission:") or rId:find("^mission24:") or rId:find("^thtalk:") or rId:find("^th:")
            if isQuestNpc then
                local pos = nil
                if type(row) == "table" and typeof(row.position) == "Vector3" then
                    pos = row.position
                elseif type(qd.npc) == "function" then
                    local okN, nInfo = pcall(qd.npc, rId)
                    if okN and type(nInfo) == "table" and typeof(nInfo.position) == "Vector3" then
                        pos = nInfo.position
                    end
                end
                if not pos and type(row) == "table" and tonumber(row[7]) and tonumber(row[8]) and tonumber(row[9]) then
                    pos = Vector3.new(tonumber(row[7]), tonumber(row[8]), tonumber(row[9]))
                end
                if typeof(pos) == "Vector3" then
                    npcEntries[rId] = { rbrcId = rId, pos = pos, npc = streamedById[rId] }
                end
            end
        end
    end
    for rId, npc in pairs(streamedById) do
        local isQuestNpc = rId:find("^mission:") or rId:find("^mission24:") or rId:find("^thtalk:") or rId:find("^th:")
        if isQuestNpc and not npcEntries[rId] then
            local nPart = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart")
            if nPart then
                npcEntries[rId] = { rbrcId = rId, pos = nPart.Position, npc = npc }
            end
        end
    end

    local candidates = {}
    local doneSet = _cachedProfileDone or {}

    for rbrcId, entry in pairs(npcEntries) do
        local streamedNpc = entry.npc
        local nPos = entry.pos
        if streamedNpc and streamedNpc.Parent then
            local nPart = streamedNpc:FindFirstChild("HumanoidRootPart") or streamedNpc.PrimaryPart or streamedNpc:FindFirstChildWhichIsA("BasePart")
            if nPart then nPos = nPart.Position end
        end

        local cdExpiry = npcVisitCooldown[rbrcId] or (streamedNpc and npcVisitCooldown[streamedNpc.Name])
        local onCooldown = cdExpiry ~= nil and cdExpiry > now

        local bestLv = nil
        local bestQuestId = nil
        local bestIsUndone = false
        local bestHasExp = false

        -- IMPORTANT: QuestData.questsForNpc requires exact STRING id (e.g. "mission:1", "thtalk:10030")
        if qd and type(qd.questsForNpc) == "function" and type(qd.get) == "function" then
            local okQ, qList = pcall(qd.questsForNpc, rbrcId)
            if okQ and type(qList) == "table" then
                for _, qId in ipairs(qList) do
                    local okDef, qDef = pcall(qd.get, qId)
                    if okDef and type(qDef) == "table" and qDef.playable ~= false then
                        local qLv = tonumber(qDef.level) or 1
                        if qLv <= curLv then
                            local doneCount = doneSet[qId]
                            local isUndone = not doneCount or doneCount == 0
                            local expVal = getQuestRewardExp(qDef, rd)
                            local hasExp = expVal > 0

                            local better = false
                            if not bestQuestId then
                                better = true
                            elseif isUndone ~= bestIsUndone then
                                better = isUndone
                            elseif hasExp ~= bestHasExp then
                                better = hasExp
                            elseif qLv ~= bestLv then
                                better = qLv > bestLv
                            end

                            if better then
                                bestLv = qLv
                                bestQuestId = qId
                                bestIsUndone = isUndone
                                bestHasExp = hasExp
                            end
                        end
                    end
                end
            end
        end

        if not bestQuestId and streamedNpc then
            local attrLv = tonumber(streamedNpc:GetAttribute("Level"))
            if attrLv and attrLv <= curLv then
                bestLv = attrLv
            end
        end

        -- Only include NPCs with at least one valid unlocked quest (level <= curLv)
        if bestLv and bestLv <= curLv and nPos then
            local hasJobIcon = false
            for _, iPos in ipairs(iconPositions) do
                if (iPos - nPos).Magnitude <= 22 then
                    hasJobIcon = true
                    break
                end
            end
            table.insert(candidates, {
                npc = streamedNpc,
                pos = nPos,
                reqLv = bestLv,
                questId = bestQuestId,
                rbrcId = rbrcId,
                isUndone = bestIsUndone,
                hasExp = bestHasExp,
                hasIcon = hasJobIcon,
                onCooldown = onCooldown,
                dist = (nPos - carPos).Magnitude
            })
        end
    end

    if #candidates == 0 then return nil end

    -- Sort candidates:
    -- 1. Not on cooldown first
    -- 2. Uncompleted quest before already completed repeatable quest
    -- 3. EXP-granting quest first
    -- 4. Highest unlocked level <= curLv (matches actual driver level!)
    -- 5. Active job icon
    -- 6. Closest distance
    table.sort(candidates, function(a, b)
        if a.onCooldown ~= b.onCooldown then
            return not a.onCooldown
        end
        if a.isUndone ~= b.isUndone then
            return a.isUndone
        end
        if a.hasExp ~= b.hasExp then
            return a.hasExp
        end
        if a.reqLv ~= b.reqLv then
            return a.reqLv > b.reqLv
        end
        if a.hasIcon ~= b.hasIcon then
            return a.hasIcon
        end
        return a.dist < b.dist
    end)

    return candidates[1]
end


-- ==============================================================================
-- ⚡ DEDICATED ROAD FIGHT RUNNER (LEVEL & DERIX 1.5M FARM ENGINE)
-- ==============================================================================
local isRoadFightRunning = false

local function getBestUnlockedBossForLevel(playerLv)
    local curLv = tonumber(playerLv) or getPlayerLevel() or 1
    local bestBoss = nil
    for _, t in pairs(LEVEL_FARM_TARGETS) do
        local rLv = tonumber(t.reqLv) or 1
        if curLv >= rLv then
            if not bestBoss or (tonumber(t.ux) or 0) > (tonumber(bestBoss.ux) or 0) then
                bestBoss = t
            end
        end
    end
    return bestBoss
end

local function runDedicatedRoadFight()
    if isRoadFightRunning then return false end
    isRoadFightRunning = true

    local root = getCarRoot()
    local rcd = getRCDrive()
    if not root then
        isRoadFightRunning = false
        return false
    end

    local curPlayerLv = getPlayerLevel()
    local targetBoss = nil
    local targetQuestId = "R1779"
    local targetNpcId = 1779
    local targetCoords = Vector3.new(3962, 50.83, 7952)

    if Config.AutoLevel1ToMax or Config.AutoFarmLevel then
        local chosen = LEVEL_FARM_TARGETS[Config.LevelFarmTarget] or LEVEL_FARM_TARGETS["🌟 Jin Ok (จินอุก) - EXP เทพ (จุดตามรูปโพสต์)"]
        if Config.AutoLevel1ToMax then
            chosen = LEVEL_FARM_TARGETS["🌟 Jin Ok (จินอุก) - EXP เทพ (จุดตามรูปโพสต์)"]
        end
        -- Check if player meets required level for the chosen boss; if not, pick best unlocked boss for their level!
        if chosen and curPlayerLv < (tonumber(chosen.reqLv) or 30) then
            chosen = getBestUnlockedBossForLevel(curPlayerLv)
        end
        if not chosen then
            -- Player is below Lv.4 (no boss unlocked yet): return false so caller runs Level-Matched NPC Quests!
            isRoadFightRunning = false
            return false
        end
        targetBoss = chosen
        targetQuestId = chosen.questId or "R1779"
        targetNpcId = chosen.npcId or 1779
        targetCoords = chosen.coords or Vector3.new(3962, 50.83, 7952)
    elseif Config.AutoFarmDerix then
        if curPlayerLv < 4 then
            isRoadFightRunning = false
            return false
        end
        targetQuestId = "R1676"
        if Config.DerixRound == "Round 2 (R1678)" then
            targetQuestId = "R1678"
        elseif Config.DerixRound == "Round 3 (R1679)" then
            targetQuestId = "R1679"
        elseif Config.DerixRound == "Round 4 (R1680)" then
            targetQuestId = "R1680"
        end
        targetNpcId = 1676
        targetCoords = DERIX_COORDS
    end

    questFarmState = Config.AutoLevel1ToMax and "LEVEL_1_TO_MAX" or (Config.AutoFarmLevel and "LEVEL_FARM" or "DERIX_FARM")

    -- 1. APPROACH & SYNCHRONIZE AT BOSS NPC (BYPASS ANTI-CHEAT QUARANTINE / UNTRUSTED CHECK)
    stopAutoDrive()
    local distToBoss = (root.Position - targetCoords).Magnitude
    local dirToBoss = distToBoss > 0.5 and (targetCoords - root.Position).Unit or root.CFrame.LookVector
    if distToBoss > 320 then
        steppedAntiQuarantineWarp(targetCoords - dirToBoss * 10, dirToBoss, 20)
    end
    performTrustSyncRoll(targetCoords, dirToBoss)

    -- 2. INITIATE CHALLENGE & ACCEPT ROAD FIGHT
    local qRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
    local rfReq = qRemotes and qRemotes:FindFirstChild("RoadFightRequest")
    local qReq = qRemotes and qRemotes:FindFirstChild("QuestRequest")

    local acceptedOk = false
    if rfReq then
        pcall(function()
            local res = rfReq:InvokeServer({
                op = "accept",
                questId = targetQuestId,
                carPos = root.Position
            })
            if res and res.ok then acceptedOk = true end
        end)
    end
    if not acceptedOk and qReq then
        pcall(function()
            local res = qReq:InvokeServer({
                op = "accept",
                questId = targetQuestId,
                carPos = root.Position,
                carLook = root.CFrame.LookVector
            })
            if res and res.ok then acceptedOk = true end
        end)
    end

    pcall(function()
        local renv = getrenv and getrenv() or { shared = shared }
        local rfc = renv.shared and renv.shared.RBRCRoadFightClient
        if rfc and rfc.talk then rfc.talk(targetNpcId) end
    end)
    pcall(function()
        local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        local rfGui = pGui and pGui:FindFirstChild("RBRCRoadFightUi")
        if rfGui then
            local dlg = rfGui:FindFirstChild("RoadFightDlg")
            if dlg and dlg.Visible then
                local btn = dlg:FindFirstChild("btChallenge", true)
                if btn and firesignal then firesignal(btn.Activated) end
            end
        end
    end)
    pressReturnKey()
    task.wait(0.3)

    -- 3. LOAD ROAD FIGHT GATES
    local rfd = nil
    pcall(function() rfd = require(ReplicatedStorage.RBRCQuest.RoadFightData) end)
    local qData = rfd and rfd.questRows and (rfd.questRows[targetQuestId] or rfd.questRows[tostring(targetQuestId)])
    if not qData and rfd and rfd.questRows then
        for _, row in pairs(rfd.questRows) do
            if type(row) == "table" and (row.id == targetQuestId or row.mid == targetQuestId or tostring(row.mid) == tostring(targetQuestId)) then
                qData = row
                break
            end
        end
    end

    local numericId = tonumber(string.match(tostring(targetQuestId), "%d+"))
    if not qData and rfd and rfd.questRows then
        for _, row in pairs(rfd.questRows) do
            if type(row) == "table" then
                if row.questId == targetQuestId or row.id == targetQuestId or (numericId and (row.missionId == numericId or row.mid == numericId or tostring(row.missionId) == tostring(numericId))) then
                    qData = row
                    break
                end
            end
        end
    end

    local gates = {}
    if qData and type(qData.obj) == "table" and #qData.obj > 0 then
        for idx, gate in ipairs(qData.obj) do
            local coords = gate[11]
            if type(coords) == "table" and #coords >= 6 then
                local gx = (coords[1] + coords[4]) / 2
                local gy = (coords[2] + coords[5]) / 2
                local gz = (coords[3] + coords[6]) / 2
                table.insert(gates, {
                    idx = idx,
                    pos = Vector3.new(gx, gy, gz),
                    coords = coords,
                    isFinish = false
                })
            end
        end
    end
    if #gates > 0 then
        gates[#gates].isFinish = true
    end

    -- 4. EXECUTE RACE (INSTANT WARP VS ROAD DRIVE)
    local mode = Config.QuestDriveMode or "Instant Warp"
    if Config.AutoLevel1ToMax then mode = "Instant Warp" end

    if #gates > 0 then
        if mode == "Instant Warp" then
            for i, g in ipairs(gates) do
                if not isAlive() or not (Config.AutoLevel1ToMax or Config.AutoFarmLevel or Config.AutoFarmDerix) then break end
                local gatePos = g.pos
                local nextGate = gates[i + 1]
                local dir = nextGate and (nextGate.pos - gatePos).Unit or root.CFrame.LookVector
                if dir.Magnitude < 0.1 then dir = root.CFrame.LookVector end

                if not g.isFinish then
                    executeMoveStep(gatePos, "checkpoint", 240, { minSpeedKmh = 60 })
                    task.wait(0.08)
                else
                    executeMoveStep(gatePos, "mission_finish", 0, { stop = true })
                    pcall(function()
                        local qRemotes2 = ReplicatedStorage.RBRCQuest.Remotes
                        if qRemotes2 and qRemotes2:FindFirstChild("QuestEventUp") then
                            qRemotes2.QuestEventUp:FireServer("GoalReached", "Goal")
                        end
                    end)
                    pcall(function()
                        local qDeliver = require(ReplicatedStorage.RBRCQuest.QuestDeliver)
                        if qDeliver and qDeliver.finish then qDeliver.finish() end
                    end)
                    task.wait(0.2)
                end
            end
        else
            for i, g in ipairs(gates) do
                if not isAlive() or not (Config.AutoLevel1ToMax or Config.AutoFarmLevel or Config.AutoFarmDerix) then break end
                local gatePos = g.pos
                local gateReached = false
                local gateTimeout = os.clock() + 25

                while isAlive() and (Config.AutoLevel1ToMax or Config.AutoFarmLevel or Config.AutoFarmDerix) and not gateReached and os.clock() < gateTimeout do
                    task.wait(0.05)
                    local curRoot = getCarRoot()
                    if not curRoot then break end
                    local d = (curRoot.Position - gatePos).Magnitude

                    if g.isFinish then
                        if d <= 18 then
                            gateReached = true
                            stopAutoDrive()
                            performTrustSyncRoll(gatePos, curRoot.CFrame.LookVector)
                            pcall(function()
                                local qRemotes2 = ReplicatedStorage.RBRCQuest.Remotes
                                if qRemotes2 and qRemotes2:FindFirstChild("QuestEventUp") then
                                    qRemotes2.QuestEventUp:FireServer("GoalReached", "Goal")
                                end
                            end)
                        else
                            executeMoveStep(gatePos, "mission_finish", Config.QuestDriveSpeed)
                        end
                    else
                        if d <= 22 then
                            gateReached = true
                            pcall(function()
                                local qt = ReplicatedStorage.RBRCQuest.Remotes.QuestTelemetry
                                if qt then qt:FireServer({ pos = gatePos, speed = 80, stopped = false, gear = 3 }) end
                            end)
                        else
                            executeMoveStep(gatePos, "checkpoint", Config.QuestDriveSpeed)
                        end
                    end
                end
            end
        end
    end

    -- 5. REWARDS, DICE ROLL & 1.5M CASH BOX OPENING
    pressReturnKey()
    task.wait(0.2)
    handleDiceRollAndRewards()
    autoOpenCashBoxes()

    if Config.AutoLevel1ToMax or Config.AutoFarmLevel then
        LevelFarmStats.runsCompleted = LevelFarmStats.runsCompleted + 1
        local ux = targetBoss and targetBoss.ux or 3533
        local cx = targetBoss and targetBoss.cx or 2840
        LevelFarmStats.totalUserExp = LevelFarmStats.totalUserExp + ux
        LevelFarmStats.totalCarExp = LevelFarmStats.totalCarExp + cx
        local curPLevel = getPlayerLevel()
        pcall(function()
            local statusStr = string.format("จบรอบที่ %d | +%d EXP (รถ +%d)", LevelFarmStats.runsCompleted, ux, cx)
            if curPLevel then
                statusStr = statusStr .. string.format(" | Lv.%d", curPLevel)
            end
            WindUI:Notify({
                Title = Config.AutoLevel1ToMax and "⚡ 1-to-Max Rush สำเร็จ!" or "🎉 จบรอบ Road Fight เลเวล!",
                Content = statusStr,
                Duration = 3,
                Icon = "award"
            })
        end)
    elseif Config.AutoFarmDerix then
        DerixStats.wins = DerixStats.wins + 1
        pcall(function()
            WindUI:Notify({
                Title = "🎲 ชนะ Derix สำเร็จ! (รอบ " .. DerixStats.wins .. ")",
                Content = "ทอยเต๋าและเปิดกล่องเงิน 1.5M Rain เรียบร้อย!",
                Duration = 3,
                Icon = "trophy"
            })
        end)
    end

    task.wait(0.35)
    isRoadFightRunning = false
    return true
end


-- ==============================================================================
-- 🚀 UNIFIED LEVEL-MATCHED QUEST & INSTANT WARP RUNNER
-- ==============================================================================
local function runAutonomousQuestStep()
    local root = getCarRoot()
    local rcd = getRCDrive()
    if not root then return end

    local playerLv = getPlayerLevel()
    local mode = (Config.AutoLevel1ToMax and "Instant Warp") or Config.QuestDriveMode or "Instant Warp"
    local destPos, destObj, points, destType, mState = getActiveQuestDestination()

    -- 0. Wait while passenger is boarding taxi (and auto-release lock once ready)
    if mState == "boarding" or destType == "boarding" then
        questFarmState = "BOARDING"
        task.wait(0.25)
        return
    end

    -- Universal Non-Destructive Anti-Stuck Detection (for road driving modes)
    if destPos and mode ~= "Instant Warp" and not isWarping then
        local movedDelta = lastProgressPos and (root.Position - lastProgressPos).Magnitude or 10
        if movedDelta > 2.0 then
            lastProgressPos = root.Position
            lastProgressTime = os.clock()
        else
            if (os.clock() - lastProgressTime) > 3.5 then
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
            -- A1. PASS-THROUGH CHECKPOINT (stop == false)
            -- ==========================================================
            questFarmState = "RACING"
            if mode == "Instant Warp" then
                executeMoveStep(destPos, "checkpoint", Config.QuestDriveSpeed, destObj)
            else
                local carPos = root.Position
                local fwd = (destPos - carPos)
                local gateDist = fwd.Magnitude
                local dir = gateDist > 0.1 and fwd.Unit or root.CFrame.LookVector
                local throughPos = destPos + dir * 35

                pcall(function()
                    local qRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
                    local qt = qRemotes and qRemotes:FindFirstChild("QuestTelemetry")
                    if qt then qt:FireServer({ pos = destPos, speed = 60, stopped = false, gear = 3 }) end
                end)

                executeMoveStep(throughPos, "checkpoint", math.max(220, Config.QuestDriveSpeed), destObj)
                if gateDist <= 20 then
                    if rcd and type(rcd.phys) == "table" then
                        rcd.phys.throttle = 1
                        rcd.phys.brake = 0
                        rcd.phys.v = dir * 65
                    end
                    root.AssemblyLinearVelocity = dir * 65
                end
            end

        elseif destType == "mission_finish" then
            -- ==========================================================
            -- A2. FINAL FINISH LINE / TAXI DROP-OFF ZONE (stop == true)
            -- ==========================================================
            questFarmState = "FINISHING"
            local dist = (destPos - root.Position).Magnitude

            if mode == "Instant Warp" or dist <= 18 then
                executeMoveStep(destPos, "mission_finish", 0, destObj)

                -- Trigger Passenger Exit & Deliver completion
                pcall(function()
                    local npMod = ReplicatedStorage:FindFirstChild("RBRCNpc") and ReplicatedStorage.RBRCNpc:FindFirstChild("NpcPassenger")
                    if npMod then
                        local np = require(npMod)
                        if np.exitRun then np.exitRun() end
                        if np.deliverRun then np.deliverRun() end
                    end
                    local qDeliver = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("QuestDeliver")
                    if qDeliver then
                        local qd = require(qDeliver)
                        if qd.finish then qd.finish() end
                        if qd.trunk then qd.trunk(true) end
                    end
                end)

                pcall(function()
                    local qRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
                    local qt = qRemotes and qRemotes:FindFirstChild("QuestTelemetry")
                    if qt then
                        qt:FireServer({ pos = destPos, speed = 0, stopped = true, gear = 1 })
                    end
                end)

                pressReturnKey()
                clearCarHoldLocks()
                pcall(function()
                    local nav = require(ReplicatedStorage.RaycityUi.Navigation)
                    if nav and nav.clear then nav.clear() end
                end)
                if Config.AutoFarmDerix or Config.AutoRollDice then
                    handleDiceRollAndRewards()
                    autoOpenCashBoxes()
                end
                task.wait(0.25)
            else
                executeMoveStep(destPos, "mission_finish", math.min(180, Config.QuestDriveSpeed), destObj)
            end

        else
            -- ==========================================================
            -- A3. NPC / SKILL QUEST / DELIVERY DESTINATION
            -- ==========================================================
            questFarmState = "DRIVING"
            local dist = (root.Position - destPos).Magnitude
            local arrivalThreshold = 24

            if mode == "Instant Warp" and dist > 14 then
                executeMoveStep(destPos, "npc", Config.QuestDriveSpeed)
                root = getCarRoot()
                if not root then return end
                dist = (root.Position - destPos).Magnitude
            end

            if dist > arrivalThreshold and mode ~= "Instant Warp" then
                executeMoveStep(destPos, destType, Config.QuestDriveSpeed)
            else
                stopAutoDrive()
                local dir = (destPos - root.Position).Magnitude > 0.1 and (destPos - root.Position).Unit or root.CFrame.LookVector
                if dist > 12 then
                    performTrustSyncRoll(destPos - dir * 5.5, dir, false)
                    root = getCarRoot()
                    if not root then return end
                end

                if destType == "skill_return_npc" or destType == "favorite_npc_target" then
                    questFarmState = "CLAIMING"
                    local activeQ = (typeof(mState) == "table") and mState or nil
                    local targetNpcId = activeQ and (activeQ.completedExceptNpcId or activeQ.rewardNpc or activeQ.npcId) or 2000
                    local qId = activeQ and activeQ.questId or 990204

                    if Config.AutoCleanInventory then
                        ensureInventorySpace(18)
                    end

                    local sqRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
                    local sReq = sqRemotes and sqRemotes:FindFirstChild("SkillQuestRequest")
                    local rRes = nil
                    if sReq then
                        pcall(function()
                            sReq:InvokeServer({ op = "talk", npcId = targetNpcId, carPos = root.Position })
                        end)
                        task.wait(0.08)
                        pcall(function()
                            rRes = sReq:InvokeServer({ op = "reward", questId = qId, npcId = targetNpcId, carPos = root.Position, choice = 0 })
                        end)
                    end

                    if rRes and rRes.ok then
                        npcVisitCooldown["sq:" .. tostring(qId)] = nil
                        pcall(function()
                            local gs = getGameShared()
                            local qt = gs and gs.RaycityQuestTalk
                            if qt and qt.open and activeQ then
                                qt.open(activeQ)
                            end
                        end)
                        pressReturnKey()
                    else
                        -- Inventory full or rejected: put on long cooldown so we immediately move to normal quests!
                        npcVisitCooldown["sq:" .. tostring(qId)] = os.clock() + 300
                    end
                    task.wait(0.2)

                elseif destType == "skill_mission_npc" then
                    questFarmState = "TALKING"
                    local targetId = (typeof(mState) == "table" and mState.targetId) or 70
                    local sqQId = (typeof(mState) == "table" and mState.quest and mState.quest.questId) or ""
                    local npcsFolder = workspace:FindFirstChild("RBRCNpcs")
                    local npcObj = findQuestTargetNpc(tostring(targetId)) or (npcsFolder and (npcsFolder:FindFirstChild("Npc_9400" .. tostring(targetId)) or npcsFolder:FindFirstChild("Npc_" .. tostring(targetId))))
                    local okAccept = pcall(interactWithNearbyNpc, npcObj or targetId)
                    if not okAccept and sqQId ~= "" then
                        npcVisitCooldown["sq:" .. tostring(sqQId)] = os.clock() + 20
                    end
                    task.wait(0.2)

                else
                    questFarmState = "DELIVERING"
                    if destObj and typeof(destObj) == "Instance" and destObj:IsA("BasePart") and firetouchinterest then
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
                            qRemotes.QuestEventUp:FireServer("GoalReached", "Goal")
                        end
                    end)
                    pressReturnKey()
                    task.wait(0.25)
                end
            end
        end
    else
        -- ==========================================================
        -- C. NO ACTIVE QUEST IN PROGRESS: FIND LEVEL-MATCHED QUEST NPC
        -- ==========================================================
        if Config.LoopNextQuest or Config.AutoStoryProgression or Config.AutoLevel1ToMax or Config.AutoFarmQuests then
            questFarmState = "SEARCHING"

            -- 1. Check Skill/Newbie Story Quests ONLY when NOT in StoryProgression / 1-to-Max mode (so shop quests 100023+ never hijack quest progression)
            local qq = (not Config.AutoStoryProgression and not Config.AutoLevel1ToMax) and getSkillQuestState() or nil
            if qq and qq.available and #qq.available > 0 and Config.AutoAcceptQuest then
                local bestQ = nil
                local pLevel = getPlayerLevel()
                local nowClk = os.clock()
                for _, q in ipairs(qq.available) do
                    local sqKey = "sq:" .. tostring(q.questId or "")
                    local onSqCd = (npcVisitCooldown[sqKey] or 0) > nowClk
                    local reqL = tonumber(q.reqMinLevel) or 1
                    if not onSqCd and pLevel >= reqL then
                        local nPos = getNpcWorldPos(q.npcId)
                        if nPos then
                            if q.questId >= 990201 and q.questId <= 990999 then
                                if not bestQ or bestQ.questId > q.questId then
                                    bestQ = q
                                end
                            elseif not bestQ and (q.questCategory == 1 or q.questId >= 100000) then
                                bestQ = q
                            end
                        end
                    end
                end

                if bestQ then
                    local nPos = getNpcWorldPos(bestQ.npcId)
                    if nPos then
                        local distToNpc = (root.Position - nPos).Magnitude
                        if mode == "Instant Warp" and distToNpc > 14 then
                            executeMoveStep(nPos, "npc", Config.QuestDriveSpeed)
                            distToNpc = (root.Position - nPos).Magnitude
                        end

                        if distToNpc > 24 and mode ~= "Instant Warp" then
                            executeMoveStep(nPos, "npc", Config.QuestDriveSpeed)
                            return
                        else
                            stopAutoDrive()
                            ensureInventorySpace(10)
                            npcVisitCooldown["sq:" .. tostring(bestQ.questId or "")] = os.clock() + 30
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
                            task.wait(0.25)
                            return
                        end
                    end
                end
            end

            -- 2. Find Best Level-Matched Mission NPC (reqLv <= playerLv, works even when NPC is unstreamed!)
            local bestMatch = findBestLevelMatchedNpc(playerLv)
            if bestMatch and bestMatch.pos and bestMatch.rbrcId then
                local nPos = bestMatch.pos
                local distToNpc = (root.Position - nPos).Magnitude
                local cdKey = bestMatch.rbrcId

                if mode == "Instant Warp" then
                    if distToNpc > 14 then
                        executeMoveStep(nPos, "npc", Config.QuestDriveSpeed)
                        root = getCarRoot()
                    end
                    stopAutoDrive()
                    -- Re-resolve streamed instance now that we arrived near NPC, fallback to exact rbrcId string
                    local interactTarget = bestMatch.npc
                    if (not interactTarget or not interactTarget.Parent) then
                        local folder = workspace:FindFirstChild("RBRCNpcs")
                        if folder then
                            for _, n in ipairs(folder:GetChildren()) do
                                if n:GetAttribute("RBRCNpcId") == bestMatch.rbrcId or n.Name == bestMatch.rbrcId then
                                    interactTarget = n
                                    break
                                end
                            end
                        end
                    end
                    local accepted = interactWithNearbyNpc(interactTarget or bestMatch.rbrcId)
                    if not accepted then
                        if not npcVisitCooldown[cdKey] or npcVisitCooldown[cdKey] <= os.clock() then
                            npcVisitCooldown[cdKey] = os.clock() + 25
                        end
                    else
                        _npcArrivalTimes[cdKey] = nil
                    end
                    task.wait(0.15)
                else
                    if distToNpc > 15 then
                        executeMoveStep(nPos, "npc", math.min(180, Config.QuestDriveSpeed))
                    else
                        stopAutoDrive()
                        local interactTarget = bestMatch.npc or bestMatch.rbrcId
                        local accepted = interactWithNearbyNpc(interactTarget)
                        if not accepted then
                            _npcArrivalTimes[cdKey] = _npcArrivalTimes[cdKey] or os.clock()
                            if (os.clock() - _npcArrivalTimes[cdKey]) > 4.0 then
                                if not npcVisitCooldown[cdKey] or npcVisitCooldown[cdKey] <= os.clock() then
                                    npcVisitCooldown[cdKey] = os.clock() + 25
                                end
                                _npcArrivalTimes[cdKey] = nil
                                pcall(function()
                                    require(ReplicatedStorage.RBRCNpc.NpcTalkPrompt).hide()
                                end)
                            end
                        else
                            _npcArrivalTimes[cdKey] = nil
                        end
                        task.wait(0.2)
                    end
                end
            end
        end
    end
end

task.spawn(function()
    while isAlive() do
        task.wait(0.06)
        if Config.AutoLevel1ToMax then
            -- ⚡ 1-to-Max Auto Leveler Engine (Level-Matched NPC Quests + Instant Warp + Boss Rush)
            local curLvl = getPlayerLevel()
            if curLvl and curLvl >= (Config.MaxLevelTarget or 50) then
                Config.AutoLevel1ToMax = false
                stopAutoDrive()
                pcall(function()
                    WindUI:Notify({
                        Title = "👑 LEVEL CAP REACHED!",
                        Content = string.format("ยินดีด้วยครับ! เลเวลถึงเป้าหมาย %d แล้ว (เลเวลปัจจุบัน: %d)", Config.MaxLevelTarget or 50, curLvl),
                        Duration = 8,
                        Icon = "crown"
                    })
                end)
                task.wait(1.5)
            else
                if Config.AutoLevelMode == "🌟 Smart Story + Boss Rush (ทำเควสเนื้อเรื่อง + วาร์ปฟาร์มบอส)" then
                    -- Always run Level-Matched NPC Quests with Instant Warp (works from Lv.1 to Lv.50!)
                    pcall(runAutonomousQuestStep)
                    task.wait(0.08)
                else
                    -- Boss Rush mode: if player has active quest or is below Boss level, run Level-Matched Quests first!
                    local destPos, _, _, destType, mState = getActiveQuestDestination()
                    if destPos or mState == "boarding" or (curLvl and curLvl < 4) then
                        pcall(runAutonomousQuestStep)
                        task.wait(0.08)
                    else
                        local ranBoss = runDedicatedRoadFight()
                        if not ranBoss then
                            pcall(runAutonomousQuestStep)
                        end
                        task.wait(0.12)
                    end
                end
            end
        elseif Config.AutoFarmLevel or Config.AutoFarmDerix then
            local ranBoss = runDedicatedRoadFight()
            if not ranBoss then
                pcall(runAutonomousQuestStep)
            end
            task.wait(0.12)
        elseif Config.AutoFarmQuests or Config.AutoStoryProgression then
            pcall(runAutonomousQuestStep)
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
    if Config.SpeedBoostEnabled and not Config.FlyEnabled and not Config.AutoFarmQuests and not Config.AutoStoryProgression and not Config.AutoLevel1ToMax then
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