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


-- Forward declarations for UI callbacks
local updateFlyState = function() end
local teleportCar = function(targetCF) end
local handleDiceRollAndRewards = function() end
local autoOpenCashBoxes = function() end
local challengeBoss = function(bossId, questId, npcId, preferredRound)
    local root = getCarRoot()
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

challengeDerix = function(preferredRound) end

local DERIX_COORDS = Vector3.new(-1225.35, 40.34, -5316.0)
local DerixStats = {
    wins = 0,
    diceRolled = 0,
    boxesOpened15M = 0,
    rainEarned = 0,
    lastChallengeTime = 0,
    activeFightRound = nil
}

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
    Title = "⚡ Auto Level Farm (วิ่งแต่อันแรกยาวๆ)",
    Desc = "ฟังก์ชั่นฟาร์มเลเวลรถและคนขับที่ดีที่สุดในเกม! บอทจะพารถไปหา NPC บอส Road Fight ที่ให้ EXP สูงสุด และรับภารกิจ [รอบที่ 1 / Standard] วนซ้ำแบบไม่รู้จบ ตามเทคนิคของคอมมูนิตี้ไทย [วิ่งแต่อันแรกยาวๆได้เลย]",
    Image = "flame"
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


-- ==============================================================================
-- 🛡️ 1. ANTI-CHEAT BYPASS & MULTIPLAYER SYNC PRESERVATION
-- ==============================================================================
pcall(function()
    -- Ensure vehicle network replication continues 24/7 even when window is unfocused or backgrounded
    local rep = game:GetService("ReplicatedStorage")
    local rcMod = require(rep.RaycityMultiplayer.RemoteCars)
    if rcMod then
        rcMod.PAUSE_WHEN_UNFOCUSED = false
    end
end)

-- Continuous background sync guard ensuring PAUSE_WHEN_UNFOCUSED remains false
task.spawn(function()
    while isAlive() do
        pcall(function()
            local rep = game:GetService("ReplicatedStorage")
            local rcMod = require(rep.RaycityMultiplayer.RemoteCars)
            if rcMod and rcMod.PAUSE_WHEN_UNFOCUSED ~= false then
                rcMod.PAUSE_WHEN_UNFOCUSED = false
            end
        end)
        task.wait(2.5)
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
local function interactWithNearbyNpc(optionalTarget)
    local now = os.clock()
    if (now - _lastNpcInteractTime) < 0.2 then return false end
    _lastNpcInteractTime = now

    local root = getCarRoot()
    if not root then return false end

    local npcsFolder = workspace:FindFirstChild("RBRCNpcs")
    if not npcsFolder then return false end

    local qRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
    local qReq = qRemotes and qRemotes:FindFirstChild("QuestRequest")
    local sReq = qRemotes and qRemotes:FindFirstChild("SkillQuestRequest")
    if not qReq and not sReq then return false end

    local targetNpc = nil
    if typeof(optionalTarget) == "Instance" then
        targetNpc = optionalTarget
    elseif typeof(optionalTarget) == "number" or typeof(optionalTarget) == "string" then
        local numStr = tostring(optionalTarget):match("(%d+)")
        if numStr and npcsFolder then
            for _, n in ipairs(npcsFolder:GetChildren()) do
                local nId = n.Name:match("(%d+)$") or tostring(n:GetAttribute("NpcId") or ""):match("(%d+)$") or tostring(n:GetAttribute("MissionId") or ""):match("(%d+)$")
                if nId == numStr or n.Name:find(numStr) then
                    targetNpc = n
                    break
                end
            end
        end
    end

    if not targetNpc then
        local closestNpc, closestDist = nil, math.huge
        for _, npc in ipairs(npcsFolder:GetChildren()) do
            local pos = npc:GetPivot().Position
            local dist = (pos - root.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closestNpc = npc
            end
        end
        if closestDist <= 38 then
            targetNpc = closestNpc
        end
    end

    if not targetNpc then return false end

    local rbrcNpcId = targetNpc:GetAttribute("RBRCNpcId")
    local mId = targetNpc:GetAttribute("MissionId")
    local nId = targetNpc:GetAttribute("NpcId")
    if not rbrcNpcId then
        if mId then
            rbrcNpcId = "mission24:" .. tostring(mId)
        elseif nId then
            rbrcNpcId = "thtalk:" .. tostring(nId)
        end
    end

    -- 1. Reset any hung tryTalk locks in client environment
    pcall(function()
        local renv = getrenv and getrenv() or { shared = shared }
        local rq = renv.shared and renv.shared.RBRCQuest
        if rq and rq.talk then
            local ups = debug.getupvalues(rq.talk)
            if ups and ups[1] and type(ups[1]) == "function" then
                debug.setupvalue(ups[1], 1, false) -- u309
                debug.setupvalue(ups[1], 3, false) -- u307
                debug.setupvalue(ups[1], 4, false) -- u360
            end
        end
    end)

    -- 2. Try native client talk handler and dismiss any open dialogue / offer prompts
    pcall(function()
        local renv = getrenv and getrenv() or { shared = shared }
        local rq = renv.shared and renv.shared.RBRCQuest
        if rq and rq.talk and rbrcNpcId then
            rq.talk(rbrcNpcId)
        end

        -- If native UI already has an offer dialog open, confirm and accept immediately
        local qui = require(ReplicatedStorage.RBRCQuest.QuestUI)
        if qui and qui._offerAnswer then
            qui._offerAnswer(true)
        end

        local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        local rcUi = pGui and pGui:FindFirstChild("RaycityQuestUi")
        if rcUi then
            local offer = rcUi:FindFirstChild("MissionOffer", true)
            local yesBtn = offer and offer:FindFirstChild("Yes", true)
            if yesBtn and yesBtn.Visible and firesignal then
                local conns = getconnections and getconnections(yesBtn.Activated)
                if conns and #conns > 0 then firesignal(yesBtn.Activated) end
            end
            local dlg = rcUi:FindFirstChild("NpcDialog", true)
            local nextBtn = dlg and dlg:FindFirstChild("Next", true)
            if nextBtn and nextBtn.Visible and firesignal then
                local conns = getconnections and getconnections(nextBtn.Activated)
                if conns and #conns > 0 then firesignal(nextBtn.Activated) end
            end
        end

        local ntpReq = require(ReplicatedStorage.RBRCNpc.NpcTalkPrompt)
        local u = debug.getupvalues(ntpReq.show)
        if u and type(u[3]) == "function" then
            u[3]()
        end
    end)

    -- 3. Programmatic Talk & Accept directly through QuestRequest (Guaranteed Network Remote)
    local talkRes = nil
    if qReq and rbrcNpcId then
        pcall(function()
            talkRes = qReq:InvokeServer({ op = "talk", npcId = rbrcNpcId, carPos = root.Position })
        end)
    end
    if (not talkRes or not talkRes.ok) and qReq and mId then
        pcall(function()
            talkRes = qReq:InvokeServer({ op = "talk", npcId = "mission24:" .. tostring(mId), carPos = root.Position })
        end)
    end

    if talkRes and talkRes.ok and talkRes.offers and #talkRes.offers > 0 then
        for _, offer in ipairs(talkRes.offers) do
            local accRes = nil
            pcall(function()
                accRes = qReq:InvokeServer({
                    op = "accept",
                    questId = offer.questId,
                    carPos = root.Position,
                    carLook = root.CFrame.LookVector
                })
            end)
            if accRes and accRes.ok then
                if accRes.needsBoarding then
                    -- Server enforces passenger boarding delay (approx 1.5 - 2.5s). Retry until { ok = true }
                    local bStart = os.clock()
                    local isBoarded = false
                    while (os.clock() - bStart) < 3.8 do
                        task.wait(0.4)
                        local bRes = nil
                        pcall(function()
                            bRes = qReq:InvokeServer({ op = "boarded", questId = offer.questId })
                        end)
                        if bRes and bRes.ok then
                            isBoarded = true
                            break
                        end
                    end
                end
                -- Close dialogue and dismiss prompt cleanly
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

    -- If NPC has no active offers or rejects, set temporary cooldown so we do not get stuck
    if talkRes and (not talkRes.ok or not talkRes.offers or #talkRes.offers == 0) then
        npcVisitCooldown[targetNpc.Name] = os.clock()
        pcall(function()
            require(ReplicatedStorage.RBRCNpc.NpcTalkPrompt).hide()
        end)
    end

    return false
end

-- ==============================================================================
-- 💬 4.9. AUTONOMOUS DIRECT NPC INTERACTION & QUEST ACCEPT ENGINE
-- ==============================================================================
local _lastNpcInteractTime = 0
local _npcArrivalTimes = {} -- [npcName] = os.clock()
local function interactWithNearbyNpc(optionalTarget)
    local now = os.clock()
    if (now - _lastNpcInteractTime) < 0.2 then return false end
    _lastNpcInteractTime = now

    local root = getCarRoot()
    if not root then return false end

    local npcsFolder = workspace:FindFirstChild("RBRCNpcs")
    if not npcsFolder then return false end

    local qRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
    local qReq = qRemotes and qRemotes:FindFirstChild("QuestRequest")
    local sReq = qRemotes and qRemotes:FindFirstChild("SkillQuestRequest")
    if not qReq and not sReq then return false end

    local targetNpc = nil
    if typeof(optionalTarget) == "Instance" then
        targetNpc = optionalTarget
    elseif typeof(optionalTarget) == "number" or typeof(optionalTarget) == "string" then
        local numStr = tostring(optionalTarget):match("(%d+)")
        if numStr and npcsFolder then
            for _, n in ipairs(npcsFolder:GetChildren()) do
                local nId = n.Name:match("(%d+)$") or tostring(n:GetAttribute("NpcId") or ""):match("(%d+)$") or tostring(n:GetAttribute("MissionId") or ""):match("(%d+)$")
                if nId == numStr or n.Name:find(numStr) then
                    targetNpc = n
                    break
                end
            end
        end
    end

    if not targetNpc then
        local closestNpc, closestDist = nil, math.huge
        for _, npc in ipairs(npcsFolder:GetChildren()) do
            local pos = npc:GetPivot().Position
            local dist = (pos - root.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closestNpc = npc
            end
        end
        if closestDist <= 38 then
            targetNpc = closestNpc
        end
    end

    if not targetNpc then return false end

    local rbrcNpcId = targetNpc:GetAttribute("RBRCNpcId")
    local mId = targetNpc:GetAttribute("MissionId")
    local nId = targetNpc:GetAttribute("NpcId")
    if not rbrcNpcId then
        if mId then
            rbrcNpcId = "mission24:" .. tostring(mId)
        elseif nId then
            rbrcNpcId = "thtalk:" .. tostring(nId)
        end
    end

    -- 1. Reset any hung tryTalk locks in client environment
    pcall(function()
        local renv = getrenv and getrenv() or { shared = shared }
        local rq = renv.shared and renv.shared.RBRCQuest
        if rq and rq.talk then
            local ups = debug.getupvalues(rq.talk)
            if ups and ups[1] and type(ups[1]) == "function" then
                debug.setupvalue(ups[1], 1, false) -- u309
                debug.setupvalue(ups[1], 3, false) -- u307
                debug.setupvalue(ups[1], 4, false) -- u360
            end
        end
    end)

    -- 2. Try native client talk handler and dismiss any open dialogue / offer prompts
    pcall(function()
        local renv = getrenv and getrenv() or { shared = shared }
        local rq = renv.shared and renv.shared.RBRCQuest
        if rq and rq.talk and rbrcNpcId then
            rq.talk(rbrcNpcId)
        end

        -- If native UI already has an offer dialog open, confirm and accept immediately
        local qui = require(ReplicatedStorage.RBRCQuest.QuestUI)
        if qui and qui._offerAnswer then
            qui._offerAnswer(true)
        end

        local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        local rcUi = pGui and pGui:FindFirstChild("RaycityQuestUi")
        if rcUi then
            local offer = rcUi:FindFirstChild("MissionOffer", true)
            local yesBtn = offer and offer:FindFirstChild("Yes", true)
            if yesBtn and yesBtn.Visible and firesignal then
                local conns = getconnections and getconnections(yesBtn.Activated)
                if conns and #conns > 0 then firesignal(yesBtn.Activated) end
            end
            local dlg = rcUi:FindFirstChild("NpcDialog", true)
            local nextBtn = dlg and dlg:FindFirstChild("Next", true)
            if nextBtn and nextBtn.Visible and firesignal then
                local conns = getconnections and getconnections(nextBtn.Activated)
                if conns and #conns > 0 then firesignal(nextBtn.Activated) end
            end
        end

        local ntpReq = require(ReplicatedStorage.RBRCNpc.NpcTalkPrompt)
        local u = debug.getupvalues(ntpReq.show)
        if u and type(u[3]) == "function" then
            u[3]()
        end
    end)

    -- 3. Programmatic Talk & Accept directly through QuestRequest (Guaranteed Network Remote)
    local talkRes = nil
    if qReq and rbrcNpcId then
        pcall(function()
            talkRes = qReq:InvokeServer({ op = "talk", npcId = rbrcNpcId, carPos = root.Position })
        end)
    end
    if (not talkRes or not talkRes.ok) and qReq and mId then
        pcall(function()
            talkRes = qReq:InvokeServer({ op = "talk", npcId = "mission24:" .. tostring(mId), carPos = root.Position })
        end)
    end

    if talkRes and talkRes.ok and talkRes.offers and #talkRes.offers > 0 then
        for _, offer in ipairs(talkRes.offers) do
            local accRes = nil
            pcall(function()
                accRes = qReq:InvokeServer({
                    op = "accept",
                    questId = offer.questId,
                    carPos = root.Position,
                    carLook = root.CFrame.LookVector
                })
            end)
            if accRes and accRes.ok then
                if accRes.needsBoarding then
                    -- Server enforces passenger boarding delay (approx 1.5 - 2.5s). Retry until { ok = true }
                    local bStart = os.clock()
                    local isBoarded = false
                    while (os.clock() - bStart) < 3.8 do
                        task.wait(0.4)
                        local bRes = nil
                        pcall(function()
                            bRes = qReq:InvokeServer({ op = "boarded", questId = offer.questId })
                        end)
                        if bRes and bRes.ok then
                            isBoarded = true
                            break
                        end
                    end
                end
                -- Close dialogue and dismiss prompt cleanly
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

    -- If NPC has no active offers or rejects, set temporary cooldown so we do not get stuck
    if talkRes and (not talkRes.ok or not talkRes.offers or #talkRes.offers == 0) then
        npcVisitCooldown[targetNpc.Name] = os.clock()
        pcall(function()
            require(ReplicatedStorage.RBRCNpc.NpcTalkPrompt).hide()
        end)
    end

    return false
end

local function pressReturnKey()
    -- 0. Autonomous Programmatic NPC Interaction (Direct Remote - 100% Guaranteed)
    pcall(interactWithNearbyNpc)

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
task.spawn(function()
    while isAlive() do
        task.wait(1.5)
        if Config.AutoOpen15MBox or Config.AutoOpenAllCashBoxes or Config.AutoFarmDerix then
            pcall(autoOpenCashBoxes)
        end
        if Config.AutoRollDice or Config.AutoFarmDerix then
            pcall(handleDiceRollAndRewards)
        end
    end
end)

-- 💬 5.0. CONTINUOUS BACKGROUND AUTO DIALOGUE SKIP & QUEST ACCEPT ENGINE
-- ==============================================================================
task.spawn(function()
    while isAlive() do
        task.wait(0.12)
        if Config.AutoSkipDialogue or (Config.AutoFarmQuests and Config.AutoAcceptQuest) then
            pcall(function()
                local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
                if not pg then return end

                local qUi = pg:FindFirstChild("RaycityQuestUi")
                local ntp = pg:FindFirstChild("RBRCNpcTalkPrompt")
                local gg = pg:FindFirstChild("RBRCGameGuide")

                -- 1. Auto Talk to NPC when RBRCNpcTalkPrompt is shown ([Enter] Press Enter to chat with...)
                if ntp and ntp.Enabled then
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

local function ensureInventorySpace(minFree)
    if not Config.AutoCleanInventory then return end
    minFree = minFree or 10
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local pcMod = rep:FindFirstChild("RaycityProfile") and rep.RaycityProfile:FindFirstChild("ProfileClient")
        local scMod = rep:FindFirstChild("RaycityShop") and rep.RaycityShop:FindFirstChild("ShopClient")
        local iuReq = rep:FindFirstChild("RaycityItemUse") and rep.RaycityItemUse:FindFirstChild("Remotes") and rep.RaycityItemUse.Remotes:FindFirstChild("ItemUseRequest")
        if not pcMod then return end

        local pc = require(pcMod)
        local data = pc.get and pc.get()
        if not data or not data.inventory then
            data = pc.request and pc.request("get")
            data = data and (data.profile or data)
        end
        if not data or not data.inventory then return end

        local count = 0
        for _ in pairs(data.inventory) do count = count + 1 end
        local free = (data.invSize or 30) - count

        -- 1. Use / consume usable car keys, part boxes, charms, or tickets to free inventory slots permanently
        if free < minFree and iuReq then
            for cell, item in pairs(data.inventory) do
                pcall(function()
                    local uRes = iuReq:InvokeServer("use", { cell = tonumber(cell), id = item.id })
                    if uRes and uRes.ok then
                        free = free + 1
                    end
                end)
                if free >= minFree then break end
            end
        end

        -- 2. Sell unbound loot items via ShopClient if still under threshold
        if free < minFree and scMod then
            local sc = require(scMod)
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

local _cachedLiveMission = nil
local _lastLiveMissionCheck = 0

local function getLiveMissionState()
    local now = os.clock()
    if (now - _lastLiveMissionCheck) < 0.25 and _cachedLiveMission ~= nil then
        return _cachedLiveMission
    end
    _lastLiveMissionCheck = now
    pcall(function()
        local qr = ReplicatedStorage:FindFirstChild("RBRCQuest")
        local remotes = qr and qr:FindFirstChild("Remotes")
        local qReq = remotes and remotes:FindFirstChild("QuestRequest")
        if qReq then
            local st = qReq:InvokeServer({ op = "state" })
            if st and st.mission and (st.mission.state == "running" or st.mission.state == "boarding") then
                _cachedLiveMission = st.mission
                return
            end
        end
        _cachedLiveMission = false
    end)
    return _cachedLiveMission
end

local function getActiveMissionTarget()
    local targetPos, missionObj, missionType, isFinishLine = nil, nil, nil, false

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

    -- 1. Direct Server-Verified Quest State from QuestRequest (Guaranteed Live)
    local liveM = getLiveMissionState()
    if liveM and type(liveM.objectives) == "table" and (liveM.state == "running" or liveM.state == "boarding") then
        missionType = liveM.state
        if liveM.state == "boarding" then
            -- Waiting for passenger to finish boarding animation: keep car stationary at NPC until boarded!
            return nil, nil, "boarding", false
        end
        local targetObjs = {}
        for idx, obj in ipairs(liveM.objectives) do
            local v = nil
            if typeof(obj.target) == "Vector3" then
                v = obj.target
            elseif type(obj.target) == "table" and obj.target.x and obj.target.y and obj.target.z then
                v = Vector3.new(obj.target.x, obj.target.y, obj.target.z)
            end
            if v then
                table.insert(targetObjs, { idx = idx, obj = obj, target = v })
            end
        end
        for tIdx, item in ipairs(targetObjs) do
            local obj = item.obj
            if (obj.active or not obj.done) then
                targetPos = item.target
                missionObj = obj
                isFinishLine = (tIdx == #targetObjs)
                return targetPos, missionObj, missionType, isFinishLine
            end
        end
    end

    -- 2. Upvalue inspection fallback

    -- 1. Direct Server-Verified Quest State from QuestRequest (Guaranteed Live)
    local liveM = getLiveMissionState()
    if liveM and type(liveM.objectives) == "table" and (liveM.state == "running" or liveM.state == "boarding") then
        missionType = liveM.state
        local targetObjs = {}
        for idx, obj in ipairs(liveM.objectives) do
            local v = nil
            if typeof(obj.target) == "Vector3" then
                v = obj.target
            elseif type(obj.target) == "table" and obj.target.x and obj.target.y and obj.target.z then
                v = Vector3.new(obj.target.x, obj.target.y, obj.target.z)
            end
            if v then
                table.insert(targetObjs, { idx = idx, obj = obj, target = v })
            end
        end
        for tIdx, item in ipairs(targetObjs) do
            local obj = item.obj
            if (obj.active or not obj.done) then
                targetPos = item.target
                missionObj = obj
                isFinishLine = (tIdx == #targetObjs)
                return targetPos, missionObj, missionType, isFinishLine
            end
        end
    end

    -- 2. Upvalue inspection fallback
    pcall(function()
        local rs = game:GetService("RunService")
        local conns = getconnections and getconnections(rs.Heartbeat)
        if conns then
            for _, c in ipairs(conns) do
                local fn = c.Function
                if fn and tostring(debug.getinfo(fn).short_src or debug.getinfo(fn).source):find("RBRCQuestClient") then
                    local uvs = debug.getupvalues(fn)
                    if type(uvs) == "table" then
                        -- Check uvs[9].state() first
                        if uvs[9] and type(uvs[9].state) == "function" then
                            local okSt, st = pcall(uvs[9].state)
                            if okSt and type(st) == "table" and (st.state == "running" or st.state == "boarding") and type(st.objectives) == "table" then
                                missionType = st.state
                                local targetObjs = {}
                                for idx, obj in ipairs(st.objectives) do
                                    if typeof(obj.target) == "Vector3" then
                                        table.insert(targetObjs, { idx = idx, obj = obj })
                                    end
                                end
                                for tIdx, item in ipairs(targetObjs) do
                                    local obj = item.obj
                                    if (obj.active or not obj.done) and typeof(obj.target) == "Vector3" then
                                        targetPos = obj.target
                                        missionObj = obj
                                        isFinishLine = (tIdx == #targetObjs)
                                        break
                                    end
                                end
                            end
                        end

                        if not targetPos then
                            for _, uv in pairs(uvs) do
                                if type(uv) == "table" and (uv.state == "running" or uv.state == "boarding") and type(uv.objectives) == "table" then
                                    missionType = uv.state
                                    local targetObjs = {}
                                    for idx, obj in ipairs(uv.objectives) do
                                        if typeof(obj.target) == "Vector3" then
                                            table.insert(targetObjs, { idx = idx, obj = obj })
                                        end
                                    end
                                    for tIdx, item in ipairs(targetObjs) do
                                        local obj = item.obj
                                        if (obj.active or not obj.done) and typeof(obj.target) == "Vector3" then
                                            targetPos = obj.target
                                            missionObj = obj
                                            isFinishLine = (tIdx == #targetObjs)
                                            break
                                        end
                                    end
                                    if targetPos then break end
                                end
                            end
                        end
                    end
                    if targetPos then break end
                end
            end
        end
    end)
    return targetPos, missionObj, missionType, isFinishLine
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
    local mTarget, mObj, mState, isFinish = getActiveMissionTarget()
    if mTarget then
        if not navPoints and okNav and nav and nav.pointTo then
            pcall(nav.pointTo, mTarget)
            local okGl2, gl2 = pcall(nav.getGuideLine)
            if okGl2 and gl2 and gl2.points and #gl2.points > 0 then
                navPoints = gl2.points
            end
        end
        local dType = isFinish and "mission_finish" or "checkpoint"
        return mTarget, nil, navPoints, dType, mState
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
    local mTarget, mObj, mState, isFinish = getActiveMissionTarget()
    if mTarget then
        if not navPoints and okNav and nav and nav.pointTo then
            pcall(nav.pointTo, mTarget)
            local okGl2, gl2 = pcall(nav.getGuideLine)
            if okGl2 and gl2 and gl2.points and #gl2.points > 0 then
                navPoints = gl2.points
            end
        end
        local dType = isFinish and "mission_finish" or "checkpoint"
        return mTarget, nil, navPoints, dType, mState
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
                    -- Warp directly into front entrance of checkpoint gate so gate plane is crossed
                    targetCF = CFrame.new(targetPos - dir * 6, targetPos + dir * 15)
                else
                    targetCF = CFrame.new(targetPos + Vector3.new(0, 1.2, 0), targetPos + dir * 5)
                end

                if rcd and type(rcd.teleport) == "function" then
                    rcd.teleport(targetCF)
                elseif root then
                    root.CFrame = targetCF
                end

                if destType == "checkpoint" then
                    root.AssemblyLinearVelocity = dir * 75
                    if rcd and type(rcd.phys) == "table" then
                        rcd.phys.v = dir * 75
                        rcd.phys.throttle = 1
                        rcd.phys.brake = 0
                    end
                    pcall(function()
                        local qt = ReplicatedStorage.RBRCQuest.Remotes.QuestTelemetry
                        qt:FireServer({pos = targetPos, speed = 60, stopped = false, gear = 3})
                    end)
                else
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    if rcd and type(rcd.phys) == "table" then
                        rcd.phys.v = Vector3.zero
                        rcd.phys.throttle = 0
                        rcd.phys.brake = 1
                    end
                    pcall(function()
                        local qt = ReplicatedStorage.RBRCQuest.Remotes.QuestTelemetry
                        qt:FireServer({pos = targetPos, speed = 0, stopped = true, gear = 1})
                    end)
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


-- ==============================================================================
-- ⚡ DEDICATED ROAD FIGHT RUNNER (LEVEL & DERIX 1.5M FARM ENGINE)
-- ==============================================================================
local isRoadFightRunning = false

local function runDedicatedRoadFight()
    if isRoadFightRunning then return end
    isRoadFightRunning = true

    local root = getCarRoot()
    local rcd = getRCDrive()
    if not root then
        isRoadFightRunning = false
        return
    end

    local targetBoss = nil
    local targetQuestId = "R1779"
    local targetNpcId = 1779
    local targetCoords = Vector3.new(3962, 50.83, 7952)

    if Config.AutoFarmLevel then
        local t = LEVEL_FARM_TARGETS[Config.LevelFarmTarget] or LEVEL_FARM_TARGETS["🌟 Jin Ok (จินอุก) - EXP เทพ (จุดตามรูปโพสต์)"]
        targetBoss = t
        targetQuestId = t.questId or "R1779"
        targetNpcId = t.npcId or 1779
        targetCoords = t.coords or Vector3.new(3962, 50.83, 7952)
    elseif Config.AutoFarmDerix then
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

    questFarmState = Config.AutoFarmLevel and "LEVEL_FARM" or "DERIX_FARM"

    -- 1. APPROACH & SYNCHRONIZE AT BOSS NPC (BYPASS ANTI-CHEAT QUARANTINE / UNTRUSTED CHECK)
    local distToBoss = (root.Position - targetCoords).Magnitude
    if distToBoss > 25 then
        local approachCF = CFrame.new(targetCoords + Vector3.new(0, 1.2, 12), targetCoords)
        teleportCarWithVelocity(approachCF, approachCF.LookVector * 15)
        pcall(function()
            local qt = ReplicatedStorage.RBRCQuest.Remotes.QuestTelemetry
            if qt then qt:FireServer({ pos = root.Position, speed = 25, stopped = false, gear = 2 }) end
        end)
        task.wait(0.25)
    end

    -- Complete stop at boss NPC
    stopAutoDrive()
    teleportCarWithVelocity(CFrame.new(targetCoords + Vector3.new(0, 1.2, 0), targetCoords + root.CFrame.LookVector), Vector3.zero)
    if rcd and type(rcd.phys) == "table" then
        rcd.phys.v = Vector3.zero
        rcd.phys.throttle = 0
        rcd.phys.brake = 1
        rcd.phys.handbrake = 1
    end
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    pcall(function()
        local qt = ReplicatedStorage.RBRCQuest.Remotes.QuestTelemetry
        if qt then qt:FireServer({ pos = root.Position, speed = 0, stopped = true, gear = 1 }) end
    end)
    task.wait(0.25)

    -- 2. INITIATE CHALLENGE & ACCEPT ROAD FIGHT
    local qRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
    local rfReq = qRemotes and qRemotes:FindFirstChild("RoadFightRequest")
    local qReq = qRemotes and qRemotes:FindFirstChild("QuestRequest")

    if rfReq then
        pcall(function()
            rfReq:InvokeServer({
                op = "accept",
                questId = targetQuestId,
                carPos = root.Position
            })
        end)
    end
    if qReq then
        pcall(function()
            qReq:InvokeServer({
                op = "accept",
                questId = targetQuestId,
                carPos = root.Position,
                carLook = root.CFrame.LookVector
            })
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
    task.wait(0.35)

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
                    isFinish = (idx == #qData.obj)
                })
            end
        end
    end

    -- 4. EXECUTE RACE (INSTANT WARP VS ROAD DRIVE)
    local mode = Config.QuestDriveMode or "Instant Warp"

    if #gates > 0 then
        if mode == "Instant Warp" then
            -- ⚡ INSTANT WARP: Sequentially teleport through each gate with physics & telemetry
            for i, g in ipairs(gates) do
                if not isAlive() or not (Config.AutoFarmLevel or Config.AutoFarmDerix) then break end

                local gatePos = g.pos
                local nextGate = gates[i + 1]
                local dir = nextGate and (nextGate.pos - gatePos).Unit or root.CFrame.LookVector
                if dir.Magnitude < 0.1 then dir = root.CFrame.LookVector end

                if not g.isFinish then
                    -- Intermediate Gate: Warp directly into gate with forward velocity
                    local gateCF = CFrame.new(gatePos - dir * 4, gatePos + dir * 15)
                    teleportCarWithVelocity(gateCF, dir * 85)

                    pcall(function()
                        local qt = ReplicatedStorage.RBRCQuest.Remotes.QuestTelemetry
                        if qt then qt:FireServer({ pos = gatePos, speed = 85, stopped = false, gear = 4 }) end
                    end)

                    pcall(function()
                        if firetouchinterest then
                            local parts = workspace:GetPartBoundsInRadius(gatePos, 35)
                            for _, p in ipairs(parts) do
                                if p:IsA("BasePart") and p ~= root and not p:IsDescendantOf(workspace.MyCar) then
                                    firetouchinterest(root, p, 0)
                                    task.wait(0.01)
                                    firetouchinterest(root, p, 1)
                                end
                            end
                        end
                    end)

                    task.wait(0.12)
                else
                    -- Finish Line Gate: Stop completely and fire completion
                    local finishCF = CFrame.new(gatePos + Vector3.new(0, 1.2, 0), gatePos + dir * 5)
                    teleportCarWithVelocity(finishCF, Vector3.zero)

                    local rcd2 = getRCDrive()
                    if rcd2 and type(rcd2.phys) == "table" then
                        rcd2.phys.v = Vector3.zero
                        rcd2.phys.throttle = 0
                        rcd2.phys.brake = 1
                        rcd2.phys.handbrake = 1
                    end
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero

                    task.wait(0.15) -- Essential stationary verification time

                    pcall(function()
                        local qt = ReplicatedStorage.RBRCQuest.Remotes.QuestTelemetry
                        if qt then qt:FireServer({ pos = gatePos, speed = 0, stopped = true, gear = 1 }) end
                    end)

                    pcall(function()
                        if firetouchinterest then
                            local parts = workspace:GetPartBoundsInRadius(gatePos, 25)
                            for _, p in ipairs(parts) do
                                if p:IsA("BasePart") and p ~= root and not p:IsDescendantOf(workspace.MyCar) then
                                    firetouchinterest(root, p, 0)
                                    task.wait(0.01)
                                    firetouchinterest(root, p, 1)
                                end
                            end
                        end
                    end)

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

                    task.wait(0.25)
                end
            end
        else
            -- Realistic Road Drive / Hyper Sonic Glide
            for i, g in ipairs(gates) do
                if not isAlive() or not (Config.AutoFarmLevel or Config.AutoFarmDerix) then break end
                local gatePos = g.pos
                local gateReached = false
                local gateTimeout = os.clock() + 25

                while isAlive() and (Config.AutoFarmLevel or Config.AutoFarmDerix) and not gateReached and os.clock() < gateTimeout do
                    task.wait(0.05)
                    local curRoot = getCarRoot()
                    if not curRoot then break end
                    local d = (curRoot.Position - gatePos).Magnitude

                    if g.isFinish then
                        if d <= 18 then
                            gateReached = true
                            stopAutoDrive()
                            local rcd3 = getRCDrive()
                            if rcd3 and rcd3.phys then
                                rcd3.phys.v = Vector3.zero
                                rcd3.phys.brake = 1
                            end
                            curRoot.AssemblyLinearVelocity = Vector3.zero
                            task.wait(0.15)
                            pcall(function()
                                local qt = ReplicatedStorage.RBRCQuest.Remotes.QuestTelemetry
                                if qt then qt:FireServer({ pos = gatePos, speed = 0, stopped = true, gear = 1 }) end
                            end)
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

    if Config.AutoFarmLevel then
        LevelFarmStats.runsCompleted = LevelFarmStats.runsCompleted + 1
        local ux = targetBoss and targetBoss.ux or 3533
        local cx = targetBoss and targetBoss.cx or 2840
        LevelFarmStats.totalUserExp = LevelFarmStats.totalUserExp + ux
        LevelFarmStats.totalCarExp = LevelFarmStats.totalCarExp + cx
        pcall(function()
            WindUI:Notify({
                Title = "🎉 จบรอบ Road Fight เลเวล!",
                Content = string.format("จบรอบที่ %d | +%d EXP (รถ +%d)", LevelFarmStats.runsCompleted, ux, cx),
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

    task.wait(0.4)
    isRoadFightRunning = false
end

task.spawn(function()
    while isAlive() do
        task.wait(0.06)
        if Config.AutoFarmLevel or Config.AutoFarmDerix then
            runDedicatedRoadFight()
            task.wait(0.15)
        elseif Config.AutoFarmQuests then
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

                        -- 3. Trigger remote events for checkpoint passing
                        pcall(function()
                            local qRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
                            local qt = qRemotes and qRemotes:FindFirstChild("QuestTelemetry")
                            if qt then
                                qt:FireServer({ pos = destPos, speed = 60, stopped = false, gear = 3 })
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

                    elseif destType == "mission_finish" then
                        -- ==========================================================
                        -- A2. FINAL FINISH LINE / TAXI DROP-OFF ZONE:
                        -- DRIVE IN, STOP COMPLETELY, COMPLETE MISSION & ADVANCE!
                        -- ==========================================================
                        questFarmState = "FINISHING"
                        local carPos = root.Position
                        local dist = (destPos - carPos).Magnitude
                        local arrivalThreshold = 18

                        if dist > arrivalThreshold then
                            -- Drive directly towards finish line (do NOT overshoot!)
                            executeMoveStep(destPos, "mission_finish", math.min(180, Config.QuestDriveSpeed))
                        else
                            -- Arrived in the finish / drop-off zone: STOP COMPLETELY!
                            stopAutoDrive()

                            if rcd and rcd.phys then
                                rcd.phys.v = Vector3.zero
                                rcd.phys.throttle = 0
                                rcd.phys.brake = 1
                                rcd.phys.airMode = false
                                rcd.phys.anyContact = true
                                rcd.phys.handbrake = 1
                            end
                            root.AssemblyLinearVelocity = Vector3.zero
                            root.AssemblyAngularVelocity = Vector3.zero
                            task.wait(0.12) -- Essential for game engine stationary verification (time >= 0.1s)

                            -- 1. Trigger touch on all finish parts in radius 20
                            pcall(function()
                                if firetouchinterest then
                                    local parts = workspace:GetPartBoundsInRadius(destPos, 20)
                                    for _, p in ipairs(parts) do
                                        if p:IsA("BasePart") and p ~= root and not p:IsDescendantOf(workspace.MyCar) then
                                            firetouchinterest(root, p, 0)
                                            task.wait(0.01)
                                            firetouchinterest(root, p, 1)
                                        end
                                    end
                                end
                            end)

                            -- 2. Trigger Passenger Exit & Deliver completion
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

                            -- 3. Trigger Server Telemetry for FinishLine validation & passenger delivery
                            pcall(function()
                                local qRemotes = ReplicatedStorage:FindFirstChild("RBRCQuest") and ReplicatedStorage.RBRCQuest:FindFirstChild("Remotes")
                                local qt = qRemotes and qRemotes:FindFirstChild("QuestTelemetry")
                                if qt then
                                    qt:FireServer({ pos = root.Position, speed = 0, stopped = true, gear = 1 })
                                end
                            end)

                            -- 4. Advance completion dialogues, close result popups, and claim rewards
                            pressReturnKey()
                            if Config.AutoFarmDerix or Config.AutoRollDice then
                                handleDiceRollAndRewards()
                                autoOpenCashBoxes()
                                DerixStats.wins = DerixStats.wins + 1
                            end
                            task.wait(0.35)
                        end

                    else
                        -- ==========================================================
                        -- A3. NPC / DELIVERY DESTINATION: DRIVE TOWARDS OBJECTIVE
                        -- ==========================================================
                        questFarmState = "DRIVING"
                        local dist = (root.Position - destPos).Magnitude
                        local arrivalThreshold = 28

                        local promptOpen = false
                        pcall(function()
                            local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
                            local pr = pGui and pGui:FindFirstChild("RBRCNpcTalkPrompt")
                            if pr and pr.Enabled then promptOpen = true end
                        end)

                        if dist > arrivalThreshold and not promptOpen then
                            -- Drive smoothly along road lanes towards destination
                            executeMoveStep(destPos, destType, Config.QuestDriveSpeed)
                        else
                            -- Arrived in proximity: glide directly into NPC interaction ring
                            if dist > 8 and not promptOpen then
                                pcall(driveCarStep, destPos, 40, false)
                            end

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
                                local qId = activeQ and activeQ.questId or 990204

                                ensureInventorySpace(10)

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
                                local npcsFolder = workspace:FindFirstChild("RBRCNpcs")
                                local npcObj = findQuestTargetNpc(tostring(targetId)) or (npcsFolder and (npcsFolder:FindFirstChild("Npc_9400" .. tostring(targetId)) or npcsFolder:FindFirstChild("Npc_" .. tostring(targetId))))
                                local rbrcId = npcObj and npcObj:GetAttribute("RBRCNpcId") or ("mission24:" .. tostring(targetId))

                                if sReq then
                                    pcall(function()
                                        sReq:InvokeServer({ op = "talk", npcId = rbrcId, carPos = root.Position })
                                        sReq:InvokeServer({ op = "talk", npcId = "mission:" .. tostring(targetId), carPos = root.Position })
                                        sReq:InvokeServer({ op = "talk", npcId = targetId, carPos = root.Position })
                                    end)
                                end
                                if qReq then
                                    pcall(function()
                                        qReq:InvokeServer({ op = "talk", npcId = rbrcId, carPos = root.Position })
                                        qReq:InvokeServer({ op = "talk", npcId = "mission:" .. tostring(targetId), carPos = root.Position })
                                        qReq:InvokeServer({ op = "talk", npcId = targetId, carPos = root.Position })
                                    end)
                                end
                                pcall(interactWithNearbyNpc, npcObj or targetId)
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
                                    local promptOpen = false
                                    pcall(function()
                                        local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
                                        local pr = pGui and pGui:FindFirstChild("RBRCNpcTalkPrompt")
                                        if pr and pr.Enabled then promptOpen = true end
                                    end)

                                    if distToNpc > 28 and not promptOpen then
                                        executeMoveStep(nPos, "npc", Config.QuestDriveSpeed)
                                        return
                                    else
                                        if distToNpc > 8 and not promptOpen then
                                            pcall(driveCarStep, nPos, 40, false)
                                        end
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

                                        ensureInventorySpace(10)

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

                                local parentName = targetNpc.Parent and targetNpc.Parent.Name
                                if parentName then
                                    _npcArrivalTimes[parentName] = _npcArrivalTimes[parentName] or os.clock()
                                    -- If car has stayed at this NPC for > 4.5s without quest starting, set cooldown and hide prompt
                                    if (os.clock() - _npcArrivalTimes[parentName]) > 4.5 then
                                        npcVisitCooldown[parentName] = os.clock()
                                        _npcArrivalTimes[parentName] = nil
                                        pcall(function()
                                            require(ReplicatedStorage.RBRCNpc.NpcTalkPrompt).hide()
                                        end)
                                    end
                                end

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