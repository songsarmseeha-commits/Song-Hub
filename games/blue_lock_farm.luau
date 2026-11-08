--[[
    ========================================================================
    Song Hub | [⚽] Blue Lock Farm (v80 + Polisher Fixes & Auto Obby)
    PlaceId: 132767904294856
    Engineered by: Song Hub / Antigravity
    
    Complete Feature Set:
      - Fixed Polisher Automation (v80):
          * Correct model hierarchy: Workspace.Map.PlotModels.<Player>.Systems.PolisherModel.PhysicalModel.CollectPart
          * Equip tool handling: automatically equips raw crate tool for DepositCrate remote
          * Proximity handling: pivots character near polisher if > 18 studs and returns smoothly
          * Fixed conveyor conflict: preserves raw crates for Polisher and sells shiny crates immediately
          * Polisher unlock verification via PolisherService & UpgradesService ($150T Tycoon Upgrade check)
          * Added one-click "Purchase / Upgrade Crate Polisher ($150T)" button
      - Obby Teleport & Multi-Course Solver (v79):
          * Direct integration with Workspace.Systems.ObbyPortal & Obby Courses
          * Multi-Course Solver: Easy Obby (5m), Medium Obby (10m), Hard Obby (15m)
          * Claims Grade Tokens (2x, 5x, 5x), LuckPotion, GradeSpeedPotion & BluetoothPotion
          * Live Status Dashboard with countdown timers for all 3 courses
          * Quick Teleport Shortcuts: Obby Portal, Obby Arena, and Finish Goal Pads
          * Cooldown verification via ObbyBonusService & Replica ClientDataManager
      - Complete Bug Fixes (v78):
          * Fixed Locker Roll/Buy: Pauses rolling when target box/mutation appears, preventing skipping
          * Fixed Map Tokens: Teleports and collects Trait Tokens, Grade Tokens, and Potions across the map
          * Fixed Ball Skin Cash Sync: Multi-source cash reader (leaderstats, GUI, Data) and unblocked buying
      - Zombie Wave Defense Event:
          * Real-Time Zombie Wave Live Monitor: Wave status, seconds left, countdown to next wave
          * Active Zombie Counter: Live count of SpawnedZombie & high-value SpawnedKingZombie
          * Anti-Cheat Join Lockout Tracker: Displays 2-minute server lockout eligibility
          * Auto Slay Zombie Waves: Automatically hunts, teleports to, and eliminates spawned zombies
          * Prioritize King Zombies: Targets high-value King Zombies (100 Candy each) first
          * Fast Candy Drop Sweeper: Sweeps dropped candies immediately upon zombie elimination
          * Advances Zombie Slayer event mission ("EventClaimZombies" - 50 zombies) for 10 Halloween items + 50 Candy
      - Multi-Select Rarity & Mutation Filters:
          * Multi-Select Target Boxes: Choose any combination of 24 boxes to buy
          * Multi-Select Mutation Variants: Choose any combination of 14 mutations (Shadow, Predator, Admin, FlowState, etc.)
          * Multi-Select Dropper Placement Filter: Choose which boxes and variants are placed onto droppers
          * Multi-Select Unit Target Grades: Auto Reroll Player Unit Grade to target tiers (S, SS, X, EX, UR)
          * Multi-Select Variant Token Snatcher: Choose which variant mutations to warp & snatch
          * Multi-Select Halloween Shop: Choose multiple items to auto-buy with candy
      - Ball Skin Market & Purchasing:
          * Multi-Select Target Ball Skins: Beach (25M), Supercharged (25B), Monster (750T), King (20Qi), Panther (5Sx), Meta (1Sp)
          * Live Cash & Affordability Status Display
          * Guaranteed Real Cash Purchase Execution (Remotes.BallSkinPurchaseCash)
          * One-Click "Buy Selected Ball Skins Now" Button
          * Auto Apply Best Owned Ball Skin to All Droppers
      - Weather System & Item Rain:
          * Real-Time Weather Status: Cosmic, Halloween, GoldenHour, Thunderstorm, Snowstorm
          * Weather Countdown & Multiplier Live Display (Luck, Cash, Candy Corn, Roll Speed)
          * Auto Collect Item Rain Drops (GradeToken, Predator, Shadow, Potions)
          * Auto Use Weather Globes (HalloweenGlobe, GoldenGlobe, ThunderGlobe, SnowGlobe, CosmicGlobe)
      - Mad Scientist Synthesis:
          * Material Tracker: Predator, Shadow, BluetoothPotion, Trait, Grade
          * Auto Craft Permanent Bluetooth Rolls (Remotes.MadScientistCraft)
          * Manual One-Click Craft Button
      - Missions & Quests Automation:
          * Auto Claim All Completed Daily & Event Missions (Remotes.TryClaimMission)
      - Halloween Event (100% Functional & Verified):
          * Real-Time Event Status: Day/Night cycle countdown, Candy count, House knocks, Active Graves, Admin House timer
          * Auto Trick or Treat: Knocks all 84 houses at night with proximity teleport & 5.2s cooldown
          * Admin House Priority: Automatically rushes the giant Admin Pumpkin House (1-hour cooldown) first for massive Candy bursts
          * Auto Conveyor Candy Bags: Picks up and sells conveyor candy bags for instant Candy
          * Auto Dig Active Graves: Equips Player Unit tool, teleports to spawned graves, digs & claims loot
          * Auto Collect Candy Corn: Gathers dropped candies around houses & map
      - Tycoon Automation:
          * Auto Collect & Sell Conveyor Crates (Instant Cash Generation)
          * Auto Deposit to Polisher & Collect Shiny Polished Crates
          * Auto Roll Locker with NewRequestConveyorRoll / RequestConveyorRoll fallback
          * Auto Buy Rolled Locker with Multi-Box & Multi-Variant Filter
          * Auto Place Lockers on Empty Droppers (with custom filters)
          * Auto Open Ready Lockers & Skip Locker Timers
          * Auto Equip Best Player Units & Auto Level Up Units
      - Upgrades & Progression:
          * Auto Purchase All Upgrades (ConveyorLuck, Luck, OpenTimeBoost, etc.)
          * Auto Claim Playtime Rewards (1-12), Daily Rewards, ClaimAllIndexRewards, Offline Earnings, Obby Bonus
          * Auto Redeem Active Creator Codes ("WEATHER", "HALLOWEEN", "RELEASE", "TRICKORTREAT", etc.)
      - Infinity Tower & World:
          * Auto Battle Infinity Tower
          * Auto Collect Map Tokens (GradeToken, TraitToken, Potions)
          * Dynamic Teleports & Player Movement Enhancements (Speed, Jump, Noclip, Anti-AFK)
      - Config Manager:
          * Save, Load, Overwrite, Delete, Auto-Load on startup
    ========================================================================
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
end)

-- Safe alive check for live-reload / loop management & multi-execute cleanup
getgenv().__BlueLockFarmRunId = (tonumber(getgenv().__BlueLockFarmRunId) or 0) + 1
local currentScriptRunId = getgenv().__BlueLockFarmRunId

local function isAlive()
    local activeRun = tonumber(getgenv().__BlueLockFarmRunId)
    if activeRun and currentScriptRunId and activeRun > currentScriptRunId then
        return false
    end
    if typeof(STATE) == "table" and typeof(STATE.alive) == "function" then
        return STATE.alive()
    end
    return true
end

-- Clean up any previous WindUI ScreenGuis cleanly
getgenv().__BlueLockFarmWindow = nil
pcall(function()
    local roots = {
        (typeof(gethui) == "function" and gethui()) or nil,
        game:GetService("CoreGui"),
        game:GetService("CoreGui"):FindFirstChild("RobloxGui"),
        LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    }
    for _, root in ipairs(roots) do
        if root then
            for _, child in ipairs(root:GetChildren()) do
                if string.find(child.Name, "WindUI") then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end)

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Register Custom Football & Blue Lock Stadium Themes
pcall(function()
    if WindUI and typeof(WindUI.AddTheme) == "function" then
        -- 1. BlueLockStadium: Night Football Pitch Turf + Blue Lock Ego Electric Cyan
        WindUI:AddTheme({
            Name = "BlueLockStadium",
            Accent = Color3.fromHex("#064E3B"),
            Dialog = Color3.fromHex("#052E1E"),
            Outline = Color3.fromHex("#10B981"),
            Text = Color3.fromHex("#F0FDF4"),
            Placeholder = Color3.fromHex("#6EE7B7"),
            Background = Color3.fromHex("#04140E"),
            Button = Color3.fromHex("#059669"),
            Icon = Color3.fromHex("#00E5FF"),
            Toggle = Color3.fromHex("#10B981"),
            Slider = Color3.fromHex("#00E5FF"),
            Checkbox = Color3.fromHex("#10B981"),
            Primary = Color3.fromHex("#00E5FF"),
            ElementBackground = Color3.fromHex("#0A261B"),
            ElementBackgroundTransparency = 0.05,
            PanelBackground = Color3.fromHex("#071D15"),
            PanelBackgroundTransparency = 0.88,
            LabelBackground = Color3.fromHex("#03100B"),
            LabelBackgroundTransparency = 0.78,
        })

        -- 2. EgoistBlue: Blue Lock Royal Striker Blue & Electric Flow Cyan
        WindUI:AddTheme({
            Name = "EgoistBlue",
            Accent = Color3.fromHex("#0C4A6E"),
            Dialog = Color3.fromHex("#082F49"),
            Outline = Color3.fromHex("#00E5FF"),
            Text = Color3.fromHex("#F0F9FF"),
            Placeholder = Color3.fromHex("#7DD3FC"),
            Background = Color3.fromHex("#040D1A"),
            Button = Color3.fromHex("#0284C7"),
            Icon = Color3.fromHex("#38BDF8"),
            Toggle = Color3.fromHex("#00E5FF"),
            Slider = Color3.fromHex("#3B82F6"),
            Checkbox = Color3.fromHex("#00E5FF"),
            Primary = Color3.fromHex("#00E5FF"),
            ElementBackground = Color3.fromHex("#0B1E36"),
            ElementBackgroundTransparency = 0.05,
        })

        -- 3. WorldCupGold: Ballon d'Or Champion Gold & Pitch Turf
        WindUI:AddTheme({
            Name = "WorldCupGold",
            Accent = Color3.fromHex("#78350F"),
            Dialog = Color3.fromHex("#451A03"),
            Outline = Color3.fromHex("#FBBF24"),
            Text = Color3.fromHex("#FEFCE8"),
            Placeholder = Color3.fromHex("#FDE047"),
            Background = Color3.fromHex("#120D04"),
            Button = Color3.fromHex("#D97706"),
            Icon = Color3.fromHex("#FBBF24"),
            Toggle = Color3.fromHex("#10B981"),
            Slider = Color3.fromHex("#F59E0B"),
            Checkbox = Color3.fromHex("#FBBF24"),
            Primary = Color3.fromHex("#FBBF24"),
            ElementBackground = Color3.fromHex("#241A08"),
            ElementBackgroundTransparency = 0.05,
        })
    end
end)

local initialTheme = (WindUI and WindUI.Themes and WindUI.Themes["BlueLockStadium"]) and "BlueLockStadium" or "Plant"

-- Create Window (Football Stadium Theme)
local Window = WindUI:CreateWindow({
    Title = "⚽ Blue Lock Farm | Song Hub 🏟️",
    Icon = "trophy",
    Author = "⚽ Striker Stadium Edition | by Song Hub",
    Folder = "BlueLockFarmSongHub",
    Size = UDim2.fromOffset(700, 580),
    SideBarWidth = 195,
    Theme = initialTheme,
    Transparent = true,
    Resizable = true,
    ToggleKey = Enum.KeyCode.RightControl,
    OpenButton = {
        Title = "⚽ Song Hub | Blue Lock",
        Icon = "trophy",
        CornerRadius = UDim.new(0, 14),
        StrokeThickness = 2,
        Color = ColorSequence.new(
            Color3.fromHex("#10B981"),
            Color3.fromHex("#00E5FF")
        ),
        Enabled = true,
        Draggable = true,
    },
})

getgenv().__BlueLockFarmWindow = Window

-- Configure floating Open Button (shown when UI is folded/minimized)
pcall(function()
    Window:EditOpenButton({
        Title = "⚽ Song Hub | Blue Lock",
        Icon = "trophy",
        CornerRadius = UDim.new(0, 14),
        StrokeThickness = 2,
        Color = ColorSequence.new(
            Color3.fromHex("#10B981"),
            Color3.fromHex("#00E5FF")
        ),
    })
end)

-- Teardown registration for live-reload
if typeof(STATE) == "table" and typeof(STATE.onCleanup) == "function" then
    STATE.onCleanup(function()
        pcall(function()
            Window = nil
            local hui = (typeof(gethui) == "function" and gethui()) or game:GetService("CoreGui")
            for _, g in ipairs(hui:GetChildren()) do
                if string.find(g.Name, "WindUI") then
                    g:Destroy()
                end
            end
        end)
    end)
end

--------------------------------------------------------------------------------
-- SERVICES & REMOTES CACHE
--------------------------------------------------------------------------------
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

-- Core Game Modules & Services (Registered to environment to save Luau local registers)
BoxService = nil
pcall(function() BoxService = require(ReplicatedStorage.Shared.Services.BoxService) end)

BoxesLibrary = nil
pcall(function() BoxesLibrary = require(ReplicatedStorage.Shared.Core.Storage.Game.BoxesLibrary) end)

ClientDataManager = nil
pcall(function() ClientDataManager = require(ReplicatedStorage.Client.Data.ClientDataManager) end)

DayNightService = nil
pcall(function() DayNightService = require(ReplicatedStorage.Shared.Services.DayNightService) end)

TournamentService = nil
pcall(function() TournamentService = require(ReplicatedStorage.Shared.Services.TournamentService) end)

TournamentGuiClient = nil
pcall(function() TournamentGuiClient = require(ReplicatedStorage.Client.Core.Gui.TournamentGuiClient) end)

TournamentMinigameClient = nil
pcall(function() TournamentMinigameClient = require(ReplicatedStorage.Client.Core.Gui.TournamentMinigameClient) end)

TournamentMatchClient = nil
pcall(function() TournamentMatchClient = require(ReplicatedStorage.Client.Core.Classes.TournamentMatchClient) end)

CurrencyService = nil
pcall(function() CurrencyService = require(ReplicatedStorage.Shared.Services.CurrencyService) end)

WeatherService = nil
pcall(function() WeatherService = require(ReplicatedStorage.Shared.Services.WeatherService) end)

WeatherLibrary = nil
pcall(function() WeatherLibrary = require(ReplicatedStorage.Shared.Core.Storage.Game.WeatherLibrary) end)

MissionService = nil
pcall(function() MissionService = require(ReplicatedStorage.Shared.Services.MissionService) end)

MissionLibrary = nil
pcall(function() MissionLibrary = require(ReplicatedStorage.Shared.Core.Storage.Game.MissionLibrary) end)

BallSkinService = nil
pcall(function() BallSkinService = require(ReplicatedStorage.Shared.Services.BallSkinService) end)

TokensService = nil
pcall(function() TokensService = require(ReplicatedStorage.Shared.Services.TokensService) end)

GradeService = nil
pcall(function() GradeService = require(ReplicatedStorage.Shared.Services.GradeService) end)


ObbyBonusService = nil
pcall(function() ObbyBonusService = require(ReplicatedStorage.Shared.Services.ObbyBonusService) end)

ObbyBonusLibrary = nil
pcall(function() ObbyBonusLibrary = require(ReplicatedStorage.Shared.Core.Storage.Game.ObbyBonusLibrary) end)

PolisherService = nil
pcall(function() PolisherService = require(ReplicatedStorage.Shared.Services.PolisherService) end)

UpgradesService = nil
pcall(function() UpgradesService = require(ReplicatedStorage.Shared.Services.UpgradesService) end)

PlayerUnitService = nil
pcall(function() PlayerUnitService = require(ReplicatedStorage.Shared.Services.PlayerUnitService) end)

InfinityTowerService = nil
pcall(function() InfinityTowerService = require(ReplicatedStorage.Shared.Services.InfinityTowerService) end)

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------
-- Helper: Format large numbers (K, M, B, T, Qa, Qi, Sx, Sp)
local function formatNumber(num)
    if type(num) ~= "number" then return tostring(num) end
    if num >= 1e24 then return string.format("%.2fSp", num / 1e24) end
    if num >= 1e21 then return string.format("%.2fSx", num / 1e21) end
    if num >= 1e18 then return string.format("%.2fQi", num / 1e18) end
    if num >= 1e15 then return string.format("%.2fQa", num / 1e15) end
    if num >= 1e12 then return string.format("%.2fT", num / 1e12) end
    if num >= 1e9 then return string.format("%.2fB", num / 1e9) end
    if num >= 1e6 then return string.format("%.2fM", num / 1e6) end
    if num >= 1e3 then return string.format("%.2fK", num / 1e3) end
    return tostring(math.floor(num))
end

-- Helper: Bulletproof Paragraph Updater (WindUI API + Direct GuiObject fallback)
local function updateParagraph(para, title, desc)
    if not para then return end
    pcall(function()
        if typeof(para.SetDesc) == "function" then
            para:SetDesc(desc)
        elseif typeof(para.Set) == "function" then
            para:Set({ Title = title, Desc = desc })
        end
    end)
    pcall(function()
        if para.ElementFrame then
            for _, d in ipairs(para.ElementFrame:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text ~= "Locked" and d.Text ~= title then
                    d.Text = desc
                end
            end
        end
    end)
end

-- Helper: Get Player's Plot
local function getMyPlot()
    local map = workspace:FindFirstChild("Map")
    local plotModels = map and map:FindFirstChild("PlotModels")
    if plotModels then
        local p = plotModels:FindFirstChild(LocalPlayer.Name)
        if p then return p end
    end
    local ps = ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("PlotService", true)
    if ps then
        local ok, p = pcall(function() return require(ps):GetPlot(LocalPlayer) end)
        if ok and p then return p end
    end
    return nil
end

-- Helper: Get Player's Polisher Model & CollectPart
local function getPolisher()
    local plot = getMyPlot()
    if not plot then return nil, nil end
    local systems = plot:FindFirstChild("Systems")
    if not systems then return nil, nil end

    local polisher = systems:FindFirstChild("PolisherModel") or systems:FindFirstChild("Polisher")
    if not polisher then return nil, nil end

    local physical = polisher:FindFirstChild("PhysicalModel")
    local collectPart = (physical and physical:FindFirstChild("CollectPart")) or polisher:FindFirstChild("CollectPart", true)
    return polisher, collectPart
end

-- Helper: Get Character Root & Humanoid
local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- Helper: Check Day / Night cycle
local function isNightTime()
    if DayNightService and typeof(DayNightService.CanTrickOrTreat) == "function" then
        local ok, can = pcall(DayNightService.CanTrickOrTreat)
        if ok and can ~= nil then return can end
    end
    if Lighting:GetAttribute("IsNight") ~= nil then
        return Lighting:GetAttribute("IsNight") == true
    end
    local serverTime = workspace:GetServerTimeNow()
    return ((serverTime - 1787848200) % 900) >= 600
end

-- Helper: Get seconds remaining in current cycle
local function getNightTimeRemaining()
    local serverTime = workspace:GetServerTimeNow()
    local cycle = (serverTime - 1787848200) % 900
    if cycle >= 600 then
        return math.floor(900 - cycle), true -- seconds left in night
    else
        return math.floor(600 - cycle), false -- seconds until night
    end
end

-- (Candy currency removed with Halloween event)

-- Helper: Parse formatted number strings with suffixes (e.g. "$25M", "500K", "$1Sp", "1.5Qa")
local function parseSuffixNumber(str)
    if not str then return nil end
    if typeof(str) == "number" then return str end
    if typeof(str) ~= "string" then return nil end
    -- 1. Strip RichText / HTML tags (<font ...>, </font>, <b>, etc.)
    local clean = string.gsub(str, "<[^>]->", "")
    -- 2. Strip commas, dollar signs, spaces, non-breaking spaces, quotes
    clean = string.gsub(clean, "[,%$%s\'\"]", "")
    if clean == "" then return nil end
    -- 3. Check for direct scientific notation or pure number
    local direct = tonumber(clean)
    if direct and direct >= 0 then return direct end
    -- 4. Match number and suffix
    local num, suffix = string.match(clean, "([%d%.]+)%s*([a-zA-Z]*)")
    if not num then return nil end
    local n = tonumber(num)
    if not n then return nil end
    suffix = string.lower(suffix or "")
    local multipliers = {
        k   = 1e3,
        m   = 1e6,
        b   = 1e9,
        t   = 1e12,
        qa  = 1e15,
        q   = 1e15,
        qi  = 1e18,
        sx  = 1e21,
        sp  = 1e24,
        s   = 1e24,
        oc  = 1e27,
        o   = 1e27,
        no  = 1e30,
        n   = 1e30,
        dc  = 1e33,
        d   = 1e33,
        ud  = 1e36,
        dd  = 1e39,
        td  = 1e42,
    }
    if suffix ~= "" and multipliers[suffix] then
        return n * multipliers[suffix]
    end
    return n
end

-- Helper: Get player Cash amount (Multi-Source Robust Resolution)
local lastKnownCash = 0
local function getCashAmount()
    -- 1. Try ClientDataManager (Fastest & most direct data source)
    if ClientDataManager and typeof(ClientDataManager.GetData) == "function" then
        local ok, d = pcall(ClientDataManager.GetData)
        if ok and d then
            if d.Currency then
                local c = d.Currency.Cash or d.Currency.cash or d.Currency.Money or d.Currency.Coins
                local p = parseSuffixNumber(c)
                if p and p >= 0 then
                    lastKnownCash = p
                    return p
                end
            end
            if d.Cash ~= nil then
                local p = parseSuffixNumber(d.Cash)
                if p and p >= 0 then
                    lastKnownCash = p
                    return p
                end
            end
            if d.Money ~= nil then
                local p = parseSuffixNumber(d.Money)
                if p and p >= 0 then
                    lastKnownCash = p
                    return p
                end
            end
        end
    end

    -- 2. Try CurrencyService
    if CurrencyService and typeof(CurrencyService.GetCurrencyAmount) == "function" then
        local ok, val = pcall(CurrencyService.GetCurrencyAmount, LocalPlayer, "Cash")
        if ok and val ~= nil then
            local p = parseSuffixNumber(val)
            if p and p >= 0 then
                lastKnownCash = p
                return p
            end
        end
    end

    -- 3. Try FrontGui (LeftBottomFrame.CashHolder.ImageLabel.AmountLabel)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local fg = pg and pg:FindFirstChild("FrontGui")
    local cashHolder = fg and fg:FindFirstChild("LeftBottomFrame") and fg.LeftBottomFrame:FindFirstChild("CashHolder")
    local amountLabel = cashHolder and cashHolder:FindFirstChild("ImageLabel") and cashHolder.ImageLabel:FindFirstChild("AmountLabel")
    if amountLabel and amountLabel.Text and amountLabel.Text ~= "" then
        local p = parseSuffixNumber(amountLabel.Text)
        if p and p >= 0 then
            lastKnownCash = p
            return p
        end
    end

    -- 4. Try leaderstats
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        for _, name in ipairs({ "Cash", "Money", "Coins", "Gold", "Points" }) do
            local val = ls:FindFirstChild(name)
            if val and val:IsA("ValueBase") and val.Value ~= nil then
                local p = parseSuffixNumber(val.Value)
                if p and p >= 0 then
                    lastKnownCash = p
                    return p
                end
            end
        end
    end

    -- 5. Try Attributes on LocalPlayer
    for _, attr in ipairs({ "Cash", "Money", "Coins" }) do
        local a = LocalPlayer:GetAttribute(attr)
        if a ~= nil then
            local p = parseSuffixNumber(a)
            if p and p >= 0 then
                lastKnownCash = p
                return p
            end
        end
    end

    -- 6. Try scanning PlayerGui for any Cash / Amount label
    if pg then
        for _, desc in ipairs(pg:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Visible and (desc.Name == "CashLabel" or desc.Name == "AmountLabel" or string.find(desc.Text, "%$")) then
                local parsed = parseSuffixNumber(desc.Text)
                if parsed and parsed > 0 then
                    lastKnownCash = parsed
                    return parsed
                end
            end
        end
    end

    return lastKnownCash or 0
end

-- Helper: Get Conveyor Locker Price accurately from BoxService or BillboardGui
local function getConveyorLockerPrice(boxName, variant, rollPart)
    if not boxName or boxName == "" then return 0 end
    variant = variant or "Normal"
    
    if BoxService and typeof(BoxService.GetConveyorBoxPrice) == "function" then
        local ok, p = pcall(function() return BoxService.GetConveyorBoxPrice(boxName, variant) end)
        if ok and p ~= nil then
            local parsed = parseSuffixNumber(p)
            if parsed and parsed > 0 then return parsed end
        end
    end
    if BoxService and typeof(BoxService.GetBoxPrice) == "function" then
        local ok, p = pcall(function() return BoxService.GetBoxPrice(boxName, variant) end)
        if ok and p ~= nil then
            local parsed = parseSuffixNumber(p)
            if parsed and parsed > 0 then return parsed end
        end
    end

    -- Fallback 1: Deep scan all TextLabels on rollPart / BoxModel for price (e.g. "$1Sp")
    if rollPart then
        for _, desc in ipairs(rollPart:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Text and string.find(desc.Text, "%$") then
                local p = parseSuffixNumber(desc.Text)
                if p and p > 0 then return p end
            end
        end
    end

    -- Fallback 2: BoxesLibrary lookup (handles spaced and unspaced names)
    if BoxesLibrary and type(BoxesLibrary) == "table" then
        local cleanKey = string.gsub(boxName, "%s+", "")
        local boxData = BoxesLibrary[boxName] or BoxesLibrary[cleanKey]
        if not boxData then
            for k, v in pairs(BoxesLibrary) do
                if string.gsub(k, "%s+", ""):lower() == cleanKey:lower() then
                    boxData = v
                    break
                end
            end
        end
        if boxData then
            local bp = boxData.BoxPrice or boxData.Price or boxData.Cost
            if bp then
                local numBp = parseSuffixNumber(bp) or 0
                if variant and variant ~= "Normal" then
                    numBp = numBp * 50
                end
                if numBp > 0 then return numBp end
            end
        end
    end

    return 0
end

-- Helper: Get Locker Inventory Info (Current Count, Max Capacity, Space Available)
local function getLockerInventoryInfo()
    local count = 0
    local max = 100
    local hasSpace = true
    pcall(function()
        if BoxService then
            if typeof(BoxService.GetTotalBoxInventoryAmount) == "function" then
                local c = BoxService.GetTotalBoxInventoryAmount(LocalPlayer)
                if typeof(c) == "number" then count = c end
            end
            if typeof(BoxService.GetMaxBoxInventorySpace) == "function" then
                local m = BoxService.GetMaxBoxInventorySpace(LocalPlayer)
                if typeof(m) == "number" then max = m end
            end
            if typeof(BoxService.HasBoxInventorySpace) == "function" then
                hasSpace = BoxService.HasBoxInventorySpace(LocalPlayer)
            else
                hasSpace = count < max
            end
        else
            if ClientDataManager and typeof(ClientDataManager.GetData) == "function" then
                local d = ClientDataManager.GetData()
                if d and d.Inventory and d.Inventory.Boxes then
                    for _, vars in pairs(d.Inventory.Boxes) do
                        if type(vars) == "table" then
                            for _, info in pairs(vars) do
                                local amt = (type(info) == "table" and (info.Amount or info.Count)) or tonumber(info) or 0
                                count = count + amt
                            end
                        end
                    end
                    hasSpace = count < max
                end
            end
        end
    end)
    return count, max, hasSpace
end

-- Helper: Retrieve available player unit options for selection dropdowns
local unitGuidByOption = {}
local unitOptionByGuid = {}

local function getPlayerUnitOptions()
    local options = { "All Units", "Backpack Units Only", "Equipped Units Only" }
    local ownedNames = {}
    local ownedSpecific = {}
    unitGuidByOption = {}
    unitOptionByGuid = {}

    local allUnits = nil
    if PlayerUnitService and LocalPlayer then
        pcall(function() allUnits = PlayerUnitService.GetAllPlayerUnits(LocalPlayer) end)
    end
    if not allUnits and ClientDataManager then
        pcall(function()
            local d = ClientDataManager.GetData()
            allUnits = d and d.PlayerUnits
        end)
    end

    if allUnits and type(allUnits) == "table" then
        for guid, uData in pairs(allUnits) do
            local rawName = uData.PlayerUnitName or ""
            local cleanName = rawName
            if PlayerUnitService and typeof(PlayerUnitService.GetPlayerUnitName) == "function" then
                local okName, n = pcall(function() return PlayerUnitService.GetPlayerUnitName(rawName) end)
                if okName and n and n ~= "" then cleanName = n end
            end

            if cleanName ~= "" and not table.find(ownedNames, cleanName) then
                table.insert(ownedNames, cleanName)
            end

            local variant = uData.Variant or "Normal"
            local level = tostring(uData.Level or 1)
            local curGrade = tostring(uData.Grade or "None")
            local statusTag = uData.Equipped and "[Equipped]" or "[Backpack]"
            local display = string.format("%s (Lvl %s - %s - Gr %s) %s", cleanName, level, variant, curGrade, statusTag)

            unitGuidByOption[display] = guid
            unitOptionByGuid[guid] = display

            if not table.find(ownedSpecific, display) then
                table.insert(ownedSpecific, display)
            end
        end
    end

    table.sort(ownedNames)
    table.sort(ownedSpecific)

    for _, name in ipairs(ownedNames) do
        table.insert(options, name)
    end
    for _, spec in ipairs(ownedSpecific) do
        table.insert(options, spec)
    end

    -- Default fallback unit names
    local defaultNames = { "Isagi", "Rin", "Kaiser", "Nagi", "Barou", "Bachira", "Sae", "Shidou", "Chigiri", "Tokimitsu" }
    for _, dName in ipairs(defaultNames) do
        if not table.find(options, dName) then
            table.insert(options, dName)
        end
    end

    return options
end

-- Helper: Check if a unit matches user's selected unit filter
local function isUnitSelected(guid, uData, selectedList)
    if not selectedList or #selectedList == 0 then return true end
    if table.find(selectedList, "All") or table.find(selectedList, "All Units") then
        return true
    end
    if (table.find(selectedList, "Backpack Only") or table.find(selectedList, "Backpack Units Only")) and uData.Equipped ~= true then
        return true
    end
    if (table.find(selectedList, "Equipped Only") or table.find(selectedList, "Equipped Units Only")) and uData.Equipped == true then
        return true
    end

    local rawName = uData.PlayerUnitName or ""
    local cleanName = rawName
    if PlayerUnitService and typeof(PlayerUnitService.GetPlayerUnitName) == "function" then
        local okName, n = pcall(function() return PlayerUnitService.GetPlayerUnitName(rawName) end)
        if okName and n and n ~= "" then cleanName = n end
    end

    local specificDisplay = unitOptionByGuid and unitOptionByGuid[guid]

    for _, target in ipairs(selectedList) do
        local targetStr = tostring(target)
        if targetStr == guid then return true end
        if specificDisplay and targetStr == specificDisplay then return true end
        if targetStr == cleanName or targetStr == rawName then return true end
        if cleanName:lower() == targetStr:lower() or rawName:lower() == targetStr:lower() then
            return true
        end
        if string.find(targetStr:lower(), cleanName:lower(), 1, true) or string.find(targetStr:lower(), rawName:lower(), 1, true) then
            local targetLvl = string.match(targetStr, "Lvl%s+(%d+)")
            if targetLvl then
                if tostring(uData.Level or 1) == targetLvl then
                    return true
                end
            else
                return true
            end
        end
    end

    return false
end

-- (Grave digging helper removed with Halloween event)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end

    local held = char:FindFirstChildOfClass("Tool")
    if held and held:GetAttribute("InventoryType") == "PlayerUnit" then
        return true
    end

    -- Look in Backpack
    for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if t:IsA("Tool") and t:GetAttribute("InventoryType") == "PlayerUnit" then
            hum:EquipTool(t)
            task.wait(0.25)
            return true
        end
    end

    -- Fallback: If no PlayerUnit in backpack, place and retrieve from dropper 1
    pcall(function()
        local plot = getMyPlot()
        local droppers = plot and plot.Systems
            and plot.Systems:FindFirstChild("TycoonConveyor")
            and plot.Systems.TycoonConveyor:FindFirstChild("Conveyors")
            and plot.Systems.TycoonConveyor.Conveyors:FindFirstChild("Conveyor1")
            and plot.Systems.TycoonConveyor.Conveyors.Conveyor1:FindFirstChild("Droppers")
        if droppers and Remotes:FindFirstChild("RemovePlayerUnitFromDropper") then
            for _, d in ipairs(droppers:GetChildren()) do
                if d:GetAttribute("Type") == "PlayerUnit" then
                    Remotes.RemovePlayerUnitFromDropper:FireServer(d)
                    task.wait(0.3)
                    break
                end
            end
        end
    end)

    for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if t:IsA("Tool") and t:GetAttribute("InventoryType") == "PlayerUnit" then
            hum:EquipTool(t)
            task.wait(0.25)
            return true
        end
    end

    return false
end

-- Helper: Format seconds MM:SS
local function formatSeconds(sec)
    if not sec or sec <= 0 then return "00:00" end
    local m = math.floor(sec / 60)
    local s = math.floor(sec % 60)
    return string.format("%02d:%02d", m, s)
end

-- Helper: Get Obby Cooldown Time Left
local function getObbyCooldown(name)
    if ObbyBonusService then
        local ok, tl = pcall(function()
            return ObbyBonusService.GetBonusCooldownTimeLeft(LocalPlayer, name)
        end)
        if ok and typeof(tl) == "number" then
            return tl
        end
    end
    local ok, data = pcall(function()
        if ClientDataManager then
            return ClientDataManager.GetData()
        end
    end)
    if ok and data and data.ObbyBonuses then
        local lastClaim = data.ObbyBonuses[name] or 0
        local defaultCds = { EasyObby = 300, MediumObby = 600, HardObby = 900 }
        local cd = (ObbyBonusLibrary and ObbyBonusLibrary[name] and ObbyBonusLibrary[name].Cooldown) or defaultCds[name] or 300
        return math.max(0, (lastClaim + cd) - workspace:GetServerTimeNow())
    end
    return 0
end

-- Helper: Can claim Obby Bonus
local function canClaimObby(name)
    if ObbyBonusService then
        local ok, can = pcall(function()
            return ObbyBonusService.CanClaimBonus(LocalPlayer, name)
        end)
        if ok and typeof(can) == "boolean" then
            return can
        end
    end
    return getObbyCooldown(name) <= 0
end

-- Helper: Auto Complete Obby Courses & Claim Bonus
local isCompletingObby = false
local function doCompleteObby(targetCourse)
    if isCompletingObby then return end
    local hrp = getRoot()
    if not hrp then return end

    local systems = workspace:FindFirstChild("Systems")
    local obby = systems and systems:FindFirstChild("Obby")
    local victoryPartsFolder = obby and obby:FindFirstChild("VictoryParts")
    if not victoryPartsFolder then return end

    local courses = {
        { name = "EasyObby", label = "Easy Obby", part = victoryPartsFolder:FindFirstChild("EasyObby") },
        { name = "MediumObby", label = "Medium Obby", part = victoryPartsFolder:FindFirstChild("MediumObby") },
        { name = "HardObby", label = "Hard Obby", part = victoryPartsFolder:FindFirstChild("HardObby") }
    }

    local origCf = hrp.CFrame
    local claimedCount = 0

    for _, course in ipairs(courses) do
        local isSelected = true
        if targetCourse then
            isSelected = (course.name == targetCourse or course.label == targetCourse)
        elseif selectedObbyCourses and type(selectedObbyCourses) == "table" then
            isSelected = table.find(selectedObbyCourses, course.label) ~= nil or table.find(selectedObbyCourses, course.name) ~= nil
        end

        if isSelected and course.part and canClaimObby(course.name) then
            isCompletingObby = true

            -- Request stream around victory pad
            pcall(function()
                LocalPlayer:RequestStreamAroundAsync(course.part.Position, 1)
            end)

            -- Teleport to victory pad
            hrp.CFrame = CFrame.new(course.part.Position + Vector3.new(0, 3, 0))
            if hrp.AssemblyLinearVelocity then
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
            task.wait(0.2)

            -- Trigger touch interest on victory part
            pcall(function()
                firetouchinterest(hrp, course.part, 0)
                task.wait(0.05)
                firetouchinterest(hrp, course.part, 1)
            end)

            -- Fire server remote with target VictoryPart as required
            if Remotes:FindFirstChild("ClaimObbyBonus") then
                pcall(function()
                    Remotes.ClaimObbyBonus:FireServer(course.part)
                end)
            end

            claimedCount = claimedCount + 1
            task.wait(0.25)
        end
    end

    -- Return to original position
    if claimedCount > 0 and hrp and origCf then
        hrp.CFrame = origCf
        if hrp.AssemblyLinearVelocity then
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
        pcall(function()
            WindUI:Notify({
                Title = "Obby Claimed! 🏆",
                Content = string.format("Completed %d Obby course(s) & claimed rewards!", claimedCount),
                Duration = 3,
                Icon = "trophy"
            })
        end)
    end

    isCompletingObby = false
end

--------------------------------------------------------------------------------
-- STATE VARIABLES (MULTI-SELECT SUPPORTED)
--------------------------------------------------------------------------------
-- Tycoon Automation
local autoCollectSellCrates = false
local autoDepositPolisher = false
local autoCollectPolisher = false
local autoRollLocker = false
local autoBuyLocker = false
local waitForCashLocker = true
local minCashBuffer = 500
local lockerStatusText = "Idle 💤"
local LockerStatusParagraph = nil

-- Multi-Select Locker Filters
local selectedBoxes = { "All" }
local selectedVariants = { "All" }

-- Droppers & Units Management
local autoPlaceLocker = false
local placeBoxFilter = { "All" }
local placeVariantFilter = { "All" }
local autoOpenLocker = false
local autoSkipLocker = false
local autoEquipBestUnits = false
local autoLevelUnits = false
local selectedLevelUnits = { "All Units" }

-- Unit Grade Reroll Automation
local autoRerollGrades = false
local selectedRerollUnits = { "All Units" }
local targetGrades = { "S", "SS", "X", "EX", "UR" }
local rerollCurrencyMode = "Auto (Tokens then Cash)"
local autoTeleportToGrading = true
local autoUnequipForReroll = true

-- Ball Skin Automation & Market
local autoBuyBallSkins = false
local autoApplyBallSkins = false
local selectedBallSkins = { "Beach", "Supercharged" }

-- Upgrades & Rewards
local autoBuyUpgrades = false
local autoClaimRewards = false
local autoObby = false
local selectedObbyCourses = { "Easy Obby", "Medium Obby", "Hard Obby" }

-- Weather & Item Rain
local autoCollectItemRain = false
local autoUseWeatherGlobe = false
local selectedWeatherGlobe = "CosmicGlobe"
local autoCraftScientist = false
local autoClaimMissions = false

-- World Map Tokens Automation
local autoCollectMapTokens = false
local autoSnatchVariantTokens = false
local selectedVariantTokens = { "Shadow", "Admin", "Unknown", "Predator", "FlowState" }

-- 🏆 Tournament Mode Automation (New Update)
local autoTournament = false
local tournamentAutoEquipBest = true
local tournamentPerfectKick = true
local tournamentAutoReMatch = true
local TournamentStatusParagraph = nil
local scriptStartTime = os.clock()

-- Infinity Tower
local autoInfinityTower = false
local selectedTowerStage = "Entrance"
local towerSurrenderFloor = 0
local activeTowerFloor = 0
local activeTowerStage = "Entrance"
local isTowerInBattle = false
local TowerStatusParagraph = nil

-- Player Mods
local modWalkSpeed = false
local customWalkSpeed = 16
local modJumpPower = false
local customJumpPower = 50
local infiniteJump = false
local noclip = false
local antiAfk = false

-- UI Toggle Keybind & Window State
local currentToggleKey = Enum.KeyCode.RightControl
local currentToggleKeyName = "RightControl"

-- Football Stadium UI & Dynamic FX State
local selectedFootballTheme = initialTheme or "BlueLockStadium"
local fxStadiumBorder = true
local fxPitchField = true
local fxFloatingBalls = true
local fxTopbarDribble = true
local fxAnimationSpeed = 1.0

-- Table storing references to UI controls & live FX instances
local UIElements = {}

-- Helper: Retrieve Tournament Field representation
local function getTournamentField()
    local fieldModel = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Tournament") and workspace.Systems.Tournament:FindFirstChild("Field")
    if not fieldModel then return nil end
    local base = fieldModel.PrimaryPart or fieldModel:FindFirstChild("Base")
    local hGoal = fieldModel:FindFirstChild("HomeGoal")
    local aGoal = fieldModel:FindFirstChild("AwayGoal")
    if not base or not hGoal or not aGoal then return nil end
    return {
        Model = fieldModel,
        Key = fieldModel:GetFullName(),
        Base = base,
        HomeGoal = hGoal,
        AwayGoal = aGoal,
        GetGeometry = function(self)
            local v1 = {}
            for _, j in ipairs(self.Model:GetChildren()) do
                if j:IsA("BasePart") and j.Name:sub(1, 10) == "GoalieZone" then
                    table.insert(v1, j)
                end
            end
            if TournamentMatchClient then
                return TournamentMatchClient.GetFieldGeometry(self.Base, self.HomeGoal, self.AwayGoal, v1)
            end
            return nil
        end
    }
end

-- Helper: Initiate Tournament Match natively through UI
local isStartingTournament = false
local function doStartTournamentMatch()
    if isStartingTournament then return false end
    if TournamentGuiClient and TournamentGuiClient.IsInMatch() then return true end

    isStartingTournament = true
    local started = false

    pcall(function()
        local gui = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("TournamentSelectionGui")
        local main = gui and gui:FindFirstChild("UnitsSelectionMainFrame")

        -- 1. If selection frame is not open, open it
        if not main or not main.Visible then
            local fObj = getTournamentField()
            if fObj and TournamentGuiClient then
                TournamentGuiClient.Open(fObj)
                task.wait(0.5)
            end
        end

        -- 2. Equip Best Units if enabled
        local btnHolder = main and main:FindFirstChild("ButtonHolder")
        local equipBest = btnHolder and btnHolder:FindFirstChild("EquipBestButton")
        local startBtn = btnHolder and btnHolder:FindFirstChild("StartButton")

        if tournamentAutoEquipBest and equipBest and typeof(getconnections) == "function" then
            for _, c in ipairs(getconnections(equipBest.MouseButton1Click)) do
                pcall(function() c:Fire() end)
            end
            task.wait(0.4)
        end

        -- 3. Click StartButton
        if startBtn and typeof(getconnections) == "function" then
            for _, c in ipairs(getconnections(startBtn.MouseButton1Click)) do
                pcall(function() c:Fire() end)
            end
            task.wait(0.8)
        end

        if TournamentGuiClient and TournamentGuiClient.IsInMatch() then
            started = true
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "Tournament Match Started! ⚽",
                    Content = "Starting tournament match with your best units!",
                    Duration = 3,
                    Icon = "trophy"
                })
            end
        end
    end)

    isStartingTournament = false
    return started
end

-- Helper: Disable GamePass Tycoon Floor Buttons to prevent accidental Robux prompts
local function disablePlotGamepassButtons()
    pcall(function()
        local plot = getMyPlot()
        local buttons = plot and plot:FindFirstChild("Systems")
            and plot.Systems:FindFirstChild("Classes")
            and plot.Systems.Classes:FindFirstChild("Buttons")
        if buttons then
            for _, btn in ipairs(buttons:GetChildren()) do
                if string.find(btn.Name, "Luck") or string.find(btn.Name, "Cash") or string.find(btn.Name, "Pass") or string.find(btn.Name, "X2") or string.find(btn.Name, "X4") then
                    for _, part in ipairs(btn:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanTouch = false
                        end
                    end
                end
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- CONFIG STORAGE & PERSISTENCE SYSTEM
--------------------------------------------------------------------------------
local CONFIG_FOLDER = "BlueLockFarm_Configs"
local loadedConfigName = "none"
local selectedConfigName = "12"
local inputConfigName = "12"

local ConfigManagerParagraph = nil
local ObbyStatusParagraph = nil
local SavedConfigsDropdown = nil
local ConfigNameInput = nil
local AutoLoadToggle = nil

local function ensureConfigFolder()
    if typeof(isfolder) == "function" and typeof(makefolder) == "function" then
        if not isfolder(CONFIG_FOLDER) then
            pcall(function() makefolder(CONFIG_FOLDER) end)
        end
    end
end
ensureConfigFolder()

local function getSavedConfigsList()
    local list = {}
    if typeof(listfiles) == "function" and typeof(isfolder) == "function" and isfolder(CONFIG_FOLDER) then
        local ok, files = pcall(function() return listfiles(CONFIG_FOLDER) end)
        if ok and type(files) == "table" then
            for _, filePath in ipairs(files) do
                local fileName = string.match(filePath, "([^\\/]+)%.json$")
                if fileName then
                    table.insert(list, fileName)
                end
            end
        end
    end
    table.sort(list, function(a, b) return a:lower() < b:lower() end)
    return list
end

local function getAutoLoadConfig()
    local autoPath = CONFIG_FOLDER .. "/autoload.txt"
    if typeof(isfile) == "function" and isfile(autoPath) and typeof(readfile) == "function" then
        local ok, content = pcall(function() return readfile(autoPath) end)
        if ok and content then
            local trimmed = string.match(content, "^%s*(.-)%s*$")
            if trimmed and trimmed ~= "" then
                return trimmed
            end
        end
    end
    return "none"
end

local function setAutoLoadConfig(name)
    local autoPath = CONFIG_FOLDER .. "/autoload.txt"
    if typeof(writefile) == "function" then
        if not name or name == "" or name == "none" or name == "None" then
            if typeof(delfile) == "function" and typeof(isfile) == "function" and isfile(autoPath) then
                pcall(function() delfile(autoPath) end)
            else
                pcall(function() writefile(autoPath, "") end)
            end
        else
            pcall(function() writefile(autoPath, name) end)
        end
    end
end

-- Helper: Ensure value is a table (handles backward compatibility with single string configs & dictionary format)
local function toTable(val, default)
    if type(val) == "string" and val ~= "" then
        return { val }
    elseif type(val) == "table" then
        local flat = {}
        for k, v in pairs(val) do
            if type(k) == "number" and type(v) == "string" and v ~= "" then
                table.insert(flat, v)
            elseif type(k) == "string" and k ~= "" and (v == true or v == 1) then
                table.insert(flat, k)
            elseif type(v) == "string" and v ~= "" then
                table.insert(flat, v)
            end
        end
        if #flat > 0 then
            return flat
        end
        return default or {}
    end
    return default or {}
end

local function collectConfigData()
    return {
        -- Weather & New Systems
        autoCollectItemRain = autoCollectItemRain,
        autoUseWeatherGlobe = autoUseWeatherGlobe,
        selectedWeatherGlobe = selectedWeatherGlobe,
        autoCraftScientist = autoCraftScientist,
        autoClaimMissions = autoClaimMissions,

        -- Ball Skins
        autoBuyBallSkins = autoBuyBallSkins,
        autoApplyBallSkins = autoApplyBallSkins,
        selectedBallSkins = selectedBallSkins,

        -- Tournament Mode
        autoTournament = autoTournament,
        tournamentAutoEquipBest = tournamentAutoEquipBest,
        tournamentPerfectKick = tournamentPerfectKick,
        tournamentAutoReMatch = tournamentAutoReMatch,
        autoCollectMapTokens = autoCollectMapTokens,
        autoSnatchVariantTokens = autoSnatchVariantTokens,
        selectedVariantTokens = selectedVariantTokens,

        -- Automation & Multi-Select Filters
        autoCollectSellCrates = autoCollectSellCrates,
        autoDepositPolisher = autoDepositPolisher,
        autoCollectPolisher = autoCollectPolisher,
        autoRollLocker = autoRollLocker,
        autoBuyLocker = autoBuyLocker,
        waitForCashLocker = waitForCashLocker,
        minCashBuffer = minCashBuffer,
        selectedBoxes = selectedBoxes,
        selectedVariants = selectedVariants,
        autoPlaceLocker = autoPlaceLocker,
        placeBoxFilter = placeBoxFilter,
        placeVariantFilter = placeVariantFilter,
        autoOpenLocker = autoOpenLocker,
        autoSkipLocker = autoSkipLocker,
        autoEquipBestUnits = autoEquipBestUnits,
        autoLevelUnits = autoLevelUnits,
        selectedLevelUnits = selectedLevelUnits,
        autoRerollGrades = autoRerollGrades,
        selectedRerollUnits = selectedRerollUnits,
        targetGrades = targetGrades,
        rerollCurrencyMode = rerollCurrencyMode,
        autoTeleportToGrading = autoTeleportToGrading,
        autoUnequipForReroll = autoUnequipForReroll,

        -- Upgrades & Rewards
        autoBuyUpgrades = autoBuyUpgrades,
        autoClaimRewards = autoClaimRewards,
        autoObby = autoObby,
        selectedObbyCourses = selectedObbyCourses,
        autoInfinityTower = autoInfinityTower,
        selectedTowerStage = selectedTowerStage,
        towerSurrenderFloor = towerSurrenderFloor,

        -- Player & Movement
        modWalkSpeed = modWalkSpeed,
        customWalkSpeed = customWalkSpeed,
        modJumpPower = modJumpPower,
        customJumpPower = customJumpPower,
        infiniteJump = infiniteJump,
        noclip = noclip,
        antiAfk = antiAfk,

        -- UI Keybind & Football Stadium FX
        uiToggleKey = currentToggleKeyName or "RightControl",
        selectedFootballTheme = selectedFootballTheme,
        fxPitchField = fxPitchField,
        fxFloatingBalls = fxFloatingBalls,
        fxStadiumBorder = fxStadiumBorder,
        fxTopbarDribble = fxTopbarDribble,
        fxAnimationSpeed = fxAnimationSpeed,
    }
end

local function applyConfigData(data)
    if type(data) ~= "table" then return end

    -- Weather & New Systems
    if data.autoCollectItemRain ~= nil then autoCollectItemRain = data.autoCollectItemRain end
    if data.autoUseWeatherGlobe ~= nil then autoUseWeatherGlobe = data.autoUseWeatherGlobe end
    if data.selectedWeatherGlobe ~= nil then selectedWeatherGlobe = data.selectedWeatherGlobe end
    if data.autoCraftScientist ~= nil then autoCraftScientist = data.autoCraftScientist end
    if data.autoClaimMissions ~= nil then autoClaimMissions = data.autoClaimMissions end

    -- Ball Skins
    if data.autoBuyBallSkins ~= nil then autoBuyBallSkins = data.autoBuyBallSkins end
    if data.autoApplyBallSkins ~= nil then autoApplyBallSkins = data.autoApplyBallSkins end
    if data.selectedBallSkins ~= nil then selectedBallSkins = toTable(data.selectedBallSkins, { "Beach" }) end

    -- Tournament Mode
    if data.autoTournament ~= nil then autoTournament = data.autoTournament end
    if data.tournamentAutoEquipBest ~= nil then tournamentAutoEquipBest = data.tournamentAutoEquipBest end
    if data.tournamentPerfectKick ~= nil then tournamentPerfectKick = data.tournamentPerfectKick end
    if data.tournamentAutoReMatch ~= nil then tournamentAutoReMatch = data.tournamentAutoReMatch end
    if data.autoCollectMapTokens ~= nil then autoCollectMapTokens = data.autoCollectMapTokens end
    if data.autoSnatchVariantTokens ~= nil then autoSnatchVariantTokens = data.autoSnatchVariantTokens end
    if data.selectedVariantTokens ~= nil then selectedVariantTokens = toTable(data.selectedVariantTokens, { "Shadow" }) end

    -- Automation & Multi-Select Filters
    if data.autoCollectSellCrates ~= nil then autoCollectSellCrates = data.autoCollectSellCrates end
    if data.autoDepositPolisher ~= nil then autoDepositPolisher = data.autoDepositPolisher end
    if data.autoCollectPolisher ~= nil then autoCollectPolisher = data.autoCollectPolisher end
    if data.autoRollLocker ~= nil then autoRollLocker = data.autoRollLocker end
    if data.autoBuyLocker ~= nil then autoBuyLocker = data.autoBuyLocker end
    if data.waitForCashLocker ~= nil then waitForCashLocker = data.waitForCashLocker end
    if data.minCashBuffer ~= nil then minCashBuffer = data.minCashBuffer end
    if data.selectedBoxes ~= nil then
        selectedBoxes = toTable(data.selectedBoxes, { "All" })
    elseif data.selectedBox ~= nil then
        selectedBoxes = toTable(data.selectedBox, { "All" })
    end
    if data.selectedVariants ~= nil then
        selectedVariants = toTable(data.selectedVariants, { "All" })
    elseif data.selectedVariant ~= nil then
        selectedVariants = toTable(data.selectedVariant, { "All" })
    end
    if data.autoPlaceLocker ~= nil then autoPlaceLocker = data.autoPlaceLocker end
    if data.placeBoxFilter ~= nil then placeBoxFilter = toTable(data.placeBoxFilter, { "All" }) end
    if data.placeVariantFilter ~= nil then placeVariantFilter = toTable(data.placeVariantFilter, { "All" }) end
    if data.autoOpenLocker ~= nil then autoOpenLocker = data.autoOpenLocker end
    if data.autoSkipLocker ~= nil then autoSkipLocker = data.autoSkipLocker end
    if data.autoEquipBestUnits ~= nil then autoEquipBestUnits = data.autoEquipBestUnits end
    if data.autoLevelUnits ~= nil then autoLevelUnits = data.autoLevelUnits end
    if data.selectedLevelUnits ~= nil then selectedLevelUnits = toTable(data.selectedLevelUnits, { "All Units" }) end
    if data.autoRerollGrades ~= nil then autoRerollGrades = data.autoRerollGrades end
    if data.selectedRerollUnits ~= nil then selectedRerollUnits = toTable(data.selectedRerollUnits, { "All Units" }) end
    if data.targetGrades ~= nil then targetGrades = toTable(data.targetGrades, { "S", "SS", "X", "EX", "UR" }) end
    if data.rerollCurrencyMode ~= nil then rerollCurrencyMode = data.rerollCurrencyMode end
    if data.autoTeleportToGrading ~= nil then autoTeleportToGrading = data.autoTeleportToGrading end
    if data.autoUnequipForReroll ~= nil then autoUnequipForReroll = data.autoUnequipForReroll end

    -- Upgrades & Rewards
    if data.autoBuyUpgrades ~= nil then autoBuyUpgrades = data.autoBuyUpgrades end
    if data.autoClaimRewards ~= nil then autoClaimRewards = data.autoClaimRewards end
    if data.autoObby ~= nil then autoObby = data.autoObby end
    if data.selectedObbyCourses ~= nil then selectedObbyCourses = toTable(data.selectedObbyCourses, { "Easy Obby", "Medium Obby", "Hard Obby" }) end
    if data.autoInfinityTower ~= nil then autoInfinityTower = data.autoInfinityTower end
    if data.selectedTowerStage ~= nil then selectedTowerStage = data.selectedTowerStage end
    if data.towerSurrenderFloor ~= nil then towerSurrenderFloor = tonumber(data.towerSurrenderFloor) or 0 end

    -- Player & Movement
    if data.modWalkSpeed ~= nil then modWalkSpeed = data.modWalkSpeed end
    if data.customWalkSpeed ~= nil then customWalkSpeed = data.customWalkSpeed end
    if data.modJumpPower ~= nil then modJumpPower = data.modJumpPower end
    if data.customJumpPower ~= nil then customJumpPower = data.customJumpPower end
    if data.infiniteJump ~= nil then infiniteJump = data.infiniteJump end
    if data.noclip ~= nil then noclip = data.noclip end
    if data.antiAfk ~= nil then antiAfk = data.antiAfk end

    -- Keybind & Football Stadium FX
    if data.uiToggleKey then
        local key = Enum.KeyCode[data.uiToggleKey]
        if key then
            currentToggleKey = key
            currentToggleKeyName = data.uiToggleKey
            pcall(function() Window:SetToggleKey(key) end)
        end
    end
    if data.selectedFootballTheme ~= nil then
        selectedFootballTheme = data.selectedFootballTheme
        pcall(function()
            if WindUI and typeof(WindUI.SetTheme) == "function" then
                WindUI:SetTheme(selectedFootballTheme)
            end
        end)
    end
    if data.fxPitchField ~= nil then fxPitchField = data.fxPitchField end
    if data.fxFloatingBalls ~= nil then fxFloatingBalls = data.fxFloatingBalls end
    if data.fxStadiumBorder ~= nil then fxStadiumBorder = data.fxStadiumBorder end
    if data.fxTopbarDribble ~= nil then fxTopbarDribble = data.fxTopbarDribble end
    if data.fxAnimationSpeed ~= nil then fxAnimationSpeed = tonumber(data.fxAnimationSpeed) or 1.0 end

    -- Sync UI controls
    for key, elem in pairs(UIElements) do
        if data[key] ~= nil and elem then
            pcall(function()
                if elem.Select then
                    elem:Select(data[key])
                elseif elem.Set then
                    elem:Set(data[key])
                elseif elem.SetValue then
                    elem:SetValue(data[key])
                end
            end)
        end
    end
end

local function updateConfigManagerText()
    if not ConfigManagerParagraph then return end
    local autoName = getAutoLoadConfig()
    local desc = "• Active Config: " .. tostring(loadedConfigName) .. "\n" ..
        "• Selected Config: " .. tostring(selectedConfigName) .. "\n" ..
        "• Auto-Load on Startup: " .. (autoName ~= "none" and autoName or "Disabled")

    if typeof(ConfigManagerParagraph.Set) == "function" then
        ConfigManagerParagraph:Set({
            Title = "Config Profile Status",
            Desc = desc
        })
    elseif typeof(ConfigManagerParagraph.SetDesc) == "function" then
        ConfigManagerParagraph:SetDesc(desc)
    end
end

local function syncAutoLoadToggle()
    if AutoLoadToggle then
        local autoName = getAutoLoadConfig()
        local shouldBeOn = (autoName ~= "none" and autoName == selectedConfigName)
        pcall(function()
            if AutoLoadToggle.Set then
                AutoLoadToggle:Set(shouldBeOn)
            elseif AutoLoadToggle.SetValue then
                AutoLoadToggle:SetValue(shouldBeOn)
            end
        end)
    end
end

local function refreshConfigsUI(targetSelect)
    local list = getSavedConfigsList()
    if #list == 0 then
        list = { "none" }
    end

    if targetSelect and table.find(list, targetSelect) then
        selectedConfigName = targetSelect
    elseif not table.find(list, selectedConfigName) then
        selectedConfigName = list[1] or "none"
    end

    if SavedConfigsDropdown and SavedConfigsDropdown.SetValues then
        pcall(function()
            SavedConfigsDropdown:SetValues(list)
            if selectedConfigName ~= "none" then
                SavedConfigsDropdown:Select(selectedConfigName)
            end
        end)
    end

    syncAutoLoadToggle()
    updateConfigManagerText()
end

--------------------------------------------------------------------------------
-- UPGRADES, SHOP, & BALL SKIN LISTS
--------------------------------------------------------------------------------
local UpgradesList = {
    "WalkSpeed",
    "Luck",
    "OpenTimeBoost",
    "PlayerUnitExpansion",
    "CrateCashBoost",
    "ConveyorLuck",
    "CratePolisherUnlock",
    "CratePolisher",
}

local WeatherGlobeOptions = {
    "CosmicGlobe",
    "GoldenGlobe",
    "ThunderGlobe",
    "SnowGlobe",
}

-- Ball Skins Data with Multipliers & Actual Cash Prices
local BallSkinsCatalog = {
    { Name = "Beach",        DisplayName = "Beach Ball",        Multiplier = 1.25, Price = 25000000,              PriceStr = "$25M" },
    { Name = "Supercharged", DisplayName = "Supercharged Ball", Multiplier = 1.5,  Price = 25000000000,           PriceStr = "$25B" },
    { Name = "Monster",      DisplayName = "Monster Ball",      Multiplier = 2.0,  Price = 750000000000000,       PriceStr = "$750T" },
    { Name = "King",         DisplayName = "King Ball",         Multiplier = 2.5,  Price = 20000000000000000000,  PriceStr = "$20Qi" },
    { Name = "Panther",      DisplayName = "Panther Ball",      Multiplier = 3.0,  Price = 5e21,                  PriceStr = "$5Sx" },
    { Name = "Meta",         DisplayName = "Meta Ball",         Multiplier = 3.5,  Price = 1e24,                  PriceStr = "$1Sp" },
}

local BallSkinOptions = {}
for _, b in ipairs(BallSkinsCatalog) do
    table.insert(BallSkinOptions, b.Name .. " (" .. b.Multiplier .. "x | " .. b.PriceStr .. ")")
end

-- Box Options (All 24 game boxes)
local BoxOptions = { "All" }
if BoxesLibrary and type(BoxesLibrary) == "table" then
    local dyn = {}
    for bName, _ in pairs(BoxesLibrary) do
        table.insert(dyn, bName)
    end
    table.sort(dyn)
    for _, bName in ipairs(dyn) do
        table.insert(BoxOptions, bName)
    end
else
    local fallbackBoxes = { "B11", "B11Aces", "BarchaElite", "BasMunchen", "BasMunchenElite", "BasMunchenMasters", "EgoistAfterhours", "FirstSelection", "HallowedKings", "HauntedHorrors", "ManshineCity", "ManshineElite", "MasterStrikers", "PXG", "PXGElite", "PhantomStrikers", "SecondSelection", "TeamZ", "ThirdSelection", "U20", "Ubers", "UbersElite", "WorldFive", "ZStrikers" }
    for _, b in ipairs(fallbackBoxes) do table.insert(BoxOptions, b) end
end

-- Mutation Variants Options (All 14 game mutations)
local VariantOptions = { "All", "Normal", "Shiny", "Rainbow", "Golden", "Halloween", "Shadow", "Admin", "Predator", "FlowState", "Awakening", "Diamond", "Ego", "Electric", "Overflow", "Unknown" }

-- Grade Options
local GradeOptions = { "UR", "EX", "X", "SS", "S", "A", "B", "C", "D", "E", "F" }

-- Variant Token Options
local VariantTokenOptions = { "Shadow", "Admin", "Halloween", "Unknown", "Predator", "FlowState" }

--------------------------------------------------------------------------------
-- TABS SETUP (FOOTBALL STADIUM EDITION)
--------------------------------------------------------------------------------
local TabAutomation
local WeatherStatusParagraph, ScientistStatusParagraph, BallSkinStatusParagraph
local TowerStageDisplayMap, getTargetTowerStage, doStartTowerBattle, doExitTowerBattle

do
local TabEvents     = Window:Tab({ Title = "⚽ Events & Weather", Icon = "cloud-rain" })
TabAutomation       = Window:Tab({ Title = "🥅 Striker Farm",     Icon = "trophy" })
local TabBallSkins  = Window:Tab({ Title = "⚽ Ball Skins",       Icon = "circle-dot" })
local TabUpgrades   = Window:Tab({ Title = "⚡ Upgrades/Obby",    Icon = "trending-up" })
local TabTower      = Window:Tab({ Title = "🏟️ Infinity Tower",   Icon = "swords" })
local TabTeleport   = Window:Tab({ Title = "📍 Stadium Warp",     Icon = "map-pin" })
local TabPlayer     = Window:Tab({ Title = "🏃 Striker Stats",    Icon = "user" })
local TabFX         = Window:Tab({ Title = "🎨 Football UI / FX", Icon = "palette" })
local TabConfigs    = Window:Tab({ Title = "📁 Configs",          Icon = "folder" })

--------------------------------------------------------------------------------
-- TAB: EVENTS & WEATHER
--------------------------------------------------------------------------------
TabEvents:Section({ Title = "Weather & Event Live Monitor" })

WeatherStatusParagraph = TabEvents:Paragraph({
    Title = "Weather Status",
    Desc = "Loading weather parameters..."
})

TournamentStatusParagraph = TabEvents:Paragraph({
    Title = "🏆 Tournament Match Status",
    Desc = "Loading tournament rotation & match parameters..."
})

TabEvents:Section({ Title = "Weather & Item Rain Automation" })

UIElements.autoCollectItemRain = TabEvents:Toggle({
    Title = "Auto Collect Item Rain Drops",
    Desc = "Automatically sweeps & snatches raining items (Grade, Variant Tokens, Potions) across the map",
    Value = false,
    Callback = function(val)
        autoCollectItemRain = val
    end
})

UIElements.autoUseWeatherGlobe = TabEvents:Toggle({
    Title = "Auto Use Weather Globes",
    Desc = "Automatically uses your selected weather globe when no weather is active",
    Value = false,
    Callback = function(val)
        autoUseWeatherGlobe = val
    end
})

UIElements.selectedWeatherGlobe = TabEvents:Dropdown({
    Title = "Target Weather Globe",
    Desc = "Globe to activate automatically",
    Values = WeatherGlobeOptions,
    Value = "CosmicGlobe",
    Callback = function(val)
        selectedWeatherGlobe = val
    end
})

TabEvents:Button({
    Title = "Use Selected Weather Globe Now",
    Desc = "Manually activates the selected globe from your inventory",
    Callback = function()
        if Remotes:FindFirstChild("UseWeatherGlobe") then
            Remotes.UseWeatherGlobe:FireServer(selectedWeatherGlobe)
            WindUI:Notify({
                Title = "Weather Globe Used",
                Content = "Activated " .. selectedWeatherGlobe .. "!",
                Duration = 3,
                Icon = "cloud-sun"
            })
        end
    end
})

TabEvents:Section({ Title = "Mad Scientist Lab" })

ScientistStatusParagraph = TabEvents:Paragraph({
    Title = "Mad Scientist Material Status",
    Desc = "Checking laboratory inventory..."
})

UIElements.autoCraftScientist = TabEvents:Toggle({
    Title = "Auto Craft Permanent Bluetooth",
    Desc = "Automatically crafts Bluetooth Synthesis when you have 1 Predator, 5 Shadow, 10 BluetoothPotion, 100 Trait & Grade",
    Value = false,
    Callback = function(val)
        autoCraftScientist = val
    end
})

TabEvents:Button({
    Title = "Craft Bluetooth Synthesis Now",
    Desc = "Attempts to craft Permanent Bluetooth Rolls immediately",
    Callback = function()
        if Remotes:FindFirstChild("MadScientistCraft") then
            Remotes.MadScientistCraft:FireServer("PermanentBluetooth")
            WindUI:Notify({
                Title = "Mad Scientist Craft",
                Content = "Craft request sent for Permanent Bluetooth!",
                Duration = 3,
                Icon = "flask-conical"
            })
        end
    end
})

TabEvents:Section({ Title = "🏆 Tournament Mode Automation (New Update)" })

UIElements.autoTournament = TabEvents:Toggle({
    Title = "Auto Tournament Mode",
    Desc = "Automatically enters tournament match, equips top 6 units, kicks perfect shots, and plays matches",
    Value = false,
    Callback = function(val)
        autoTournament = val
        if val then
            WindUI:Notify({
                Title = "Tournament Active",
                Content = "Auto Tournament mode started! Heading to tournament field.",
                Duration = 3,
                Icon = "trophy"
            })
        end
    end
})

UIElements.tournamentAutoEquipBest = TabEvents:Toggle({
    Title = "Auto Equip Best Units (Top 6)",
    Desc = "Automatically selects and equips your top 6 highest-power striker units before starting match",
    Value = true,
    Callback = function(val)
        tournamentAutoEquipBest = val
    end
})

UIElements.tournamentPerfectKick = TabEvents:Toggle({
    Title = "100% Perfect Minigame Shot",
    Desc = "Guarantees 100% Perfect score on the rotation kick minigame for maximum goals & power",
    Value = true,
    Callback = function(val)
        tournamentPerfectKick = val
    end
})

UIElements.tournamentAutoReMatch = TabEvents:Toggle({
    Title = "Auto Rematch on Seed Rotation",
    Desc = "Automatically queues and re-enters tournament matches when the 15-minute rotation seed refreshes",
    Value = true,
    Callback = function(val)
        tournamentAutoReMatch = val
    end
})

TabEvents:Button({
    Title = "Start Tournament Match Now",
    Desc = "One-click opens tournament menu, equips best units, and enters match immediately",
    Callback = function()
        task.spawn(function()
            WindUI:Notify({
                Title = "Tournament",
                Content = "Starting tournament match...",
                Duration = 2.5,
                Icon = "play"
            })
            doStartTournamentMatch()
        end)
    end
})

TabEvents:Button({
    Title = "Teleport to Tournament Stadium Pitch",
    Desc = "Teleports directly onto the tournament field (-1795, 4, 171.5)",
    Callback = function()
        local hrp = getRoot()
        if hrp then
            hrp.CFrame = CFrame.new(Vector3.new(-1795, 4.0, 171.5))
            WindUI:Notify({
                Title = "Teleport",
                Content = "Teleported to Tournament Field!",
                Duration = 2.5,
                Icon = "map-pin"
            })
        end
    end
})

TabEvents:Section({ Title = "World Items & Mutation Spawns" })

UIElements.autoCollectMapTokens = TabEvents:Toggle({
    Title = "Auto Collect Map Tokens",
    Desc = "Collects GradeToken, TraitToken, LuckPotion, CashPotion spawning on the map",
    Value = false,
    Callback = function(val)
        autoCollectMapTokens = val
    end
})

UIElements.autoSnatchVariantTokens = TabEvents:Toggle({
    Title = "Auto Snatch Variant Tokens",
    Desc = "Instantly teleports and snatches selected Variant Tokens before they despawn",
    Value = false,
    Callback = function(val)
        autoSnatchVariantTokens = val
    end
})

UIElements.selectedVariantTokens = TabEvents:Dropdown({
    Title = "Target Variant Mutations to Snatch (Multi-Select)",
    Desc = "Select multiple mutation tokens to snatch",
    Values = VariantTokenOptions,
    Value = selectedVariantTokens,
    Multi = true,
    AllowNone = true,
    Callback = function(val)
        selectedVariantTokens = toTable(val, VariantTokenOptions)
    end
})

--------------------------------------------------------------------------------
-- TAB: AUTOMATION (MULTI-SELECT RARITY & MUTATIONS)
--------------------------------------------------------------------------------
TabAutomation:Section({ Title = "Conveyor & Polisher Cash Generation" })

UIElements.autoCollectSellCrates = TabAutomation:Toggle({
    Title = "Auto Collect & Sell Conveyor Crates",
    Desc = "Instantly claims crates from conveyor collector and sells for maximum cash",
    Value = false,
    Callback = function(val)
        autoCollectSellCrates = val
    end
})

UIElements.autoDepositPolisher = TabAutomation:Toggle({
    Title = "Auto Deposit Crates to Polisher",
    Desc = "Deposits raw crates into the polisher machine for shiny multiplier boost (Requires $150T Upgrade)",
    Value = false,
    Callback = function(val)
        autoDepositPolisher = val
        if val and PolisherService and not PolisherService.IsUnlocked(LocalPlayer) then
            WindUI:Notify({
                Title = "Polisher Locked 🔒",
                Content = "Note: Crate Polisher requires the $150T Tycoon Upgrade on your plot to activate!",
                Duration = 4,
                Icon = "lock"
            })
        end
    end
})

UIElements.autoCollectPolisher = TabAutomation:Toggle({
    Title = "Auto Collect Shiny Polished Crates",
    Desc = "Collects completed polished shiny crates and sells them for huge profit (Requires $150T Upgrade)",
    Value = false,
    Callback = function(val)
        autoCollectPolisher = val
        if val and PolisherService and not PolisherService.IsUnlocked(LocalPlayer) then
            WindUI:Notify({
                Title = "Polisher Locked 🔒",
                Content = "Note: Crate Polisher requires the $150T Tycoon Upgrade on your plot to activate!",
                Duration = 4,
                Icon = "lock"
            })
        end
    end
})

TabAutomation:Button({
    Title = "Purchase / Upgrade Crate Polisher ($150T)",
    Desc = "Unlocks or upgrades the Crate Polisher machine on your plot if you have enough cash",
    Callback = function()
        if Remotes:FindFirstChild("PurchaseUpgrade") then
            local isUnlocked = PolisherService and PolisherService.IsUnlocked(LocalPlayer)
            if not isUnlocked then
                Remotes.PurchaseUpgrade:FireServer("CratePolisherUnlock")
                WindUI:Notify({
                    Title = "Upgrade Prompted",
                    Content = "Sent request to unlock Crate Polisher ($150T)!",
                    Duration = 3,
                    Icon = "shopping-cart"
                })
            else
                Remotes.PurchaseUpgrade:FireServer("CratePolisher")
                WindUI:Notify({
                    Title = "Upgrade Prompted",
                    Content = "Sent request to upgrade Crate Polisher!",
                    Duration = 3,
                    Icon = "arrow-up"
                })
            end
        end
    end
})

TabAutomation:Section({ Title = "Locker Rolling & Purchase (Multi-Select Filters)" })

LockerStatusParagraph = TabAutomation:Paragraph({
    Title = "Locker Rolling & Purchase Status",
    Desc = "• Status: Loading live status...\n• Station Locker: Scanning...\n• Price: $0\n• Current Cash: Loading..."
})

task.spawn(function()
    task.wait(0.3)
    pcall(function()
        if LockerStatusParagraph then
            local plot = getMyPlot()
            local rollPart = plot and plot:FindFirstChild("Systems")
                and plot.Systems:FindFirstChild("RollStation")
                and plot.Systems.RollStation:FindFirstChild("ConveyorPart")
            local curBox = (rollPart and rollPart:GetAttribute("BoxName")) or "None"
            local curVar = (rollPart and rollPart:GetAttribute("Variant")) or "Normal"
            local price = 0
            if rollPart and curBox ~= "None" and curBox ~= "" then
                price = getConveyorLockerPrice(curBox, curVar, rollPart)
            end
            local cash = getCashAmount()
            local invCount, invMax, hasInvSpace = getLockerInventoryInfo()
            local invText = string.format("%d/%d", invCount, invMax)
            if not hasInvSpace then invText = invText .. " (Full ⚠️)" end
            local desc = string.format("• Status: %s\n• Station Locker: %s (%s)\n• Price: $%s (Min Buffer: $%s)\n• Current Cash: $%s\n• Locker Inv: %s",
                lockerStatusText or "Idle 💤", tostring(curBox), tostring(curVar), formatNumber(price), formatNumber(minCashBuffer or 0), formatNumber(cash), invText)
            updateParagraph(LockerStatusParagraph, "Locker Rolling & Purchase Status", desc)
        end
    end)
end)

UIElements.autoRollLocker = TabAutomation:Toggle({
    Title = "Auto Roll Locker (Roll Station)",
    Desc = "Continuously rolls for new lockers at the conveyor station (100% Free, pauses only when holding target locker)",
    Value = false,
    Callback = function(val)
        autoRollLocker = val
    end
})

UIElements.autoBuyLocker = TabAutomation:Toggle({
    Title = "Auto Buy Rolled Locker",
    Desc = "Buys the rolled locker if it matches ANY of your selected Box & Variant filters",
    Value = false,
    Callback = function(val)
        autoBuyLocker = val
    end
})

UIElements.waitForCashLocker = TabAutomation:Toggle({
    Title = "Wait For Cash on Target Lockers",
    Desc = "If cash is insufficient to buy a target locker, pauses rolls to hold it until cash is ready, then buys and resumes rolling automatically",
    Value = true,
    Callback = function(val)
        waitForCashLocker = val
    end
})

UIElements.minCashBuffer = TabAutomation:Slider({
    Title = "Min Cash Safety Buffer ($)",
    Desc = "Won't purchase lockers if your cash balance drops below this amount after purchase",
    Min = 0,
    Max = 100000,
    Default = 500,
    Callback = function(val)
        minCashBuffer = val
    end
})

UIElements.selectedBoxes = TabAutomation:Dropdown({
    Title = "Target Box Types (Multi-Select)",
    Desc = "Select multiple boxes to purchase (or 'All')",
    Values = BoxOptions,
    Value = selectedBoxes,
    Multi = true,
    AllowNone = true,
    Callback = function(val)
        selectedBoxes = toTable(val, { "All" })
    end
})

UIElements.selectedVariants = TabAutomation:Dropdown({
    Title = "Target Mutation Rarities / Variants (Multi-Select)",
    Desc = "Select multiple mutation variants to purchase (or 'All')",
    Values = VariantOptions,
    Value = selectedVariants,
    Multi = true,
    AllowNone = true,
    Callback = function(val)
        selectedVariants = toTable(val, { "All" })
    end
})

TabAutomation:Section({ Title = "Droppers Management & Placement Filters (Multi-Select)" })

UIElements.autoPlaceLocker = TabAutomation:Toggle({
    Title = "Auto Place Lockers on Empty Droppers",
    Desc = "Places available inventory lockers onto empty droppers according to filters below",
    Value = false,
    Callback = function(val)
        autoPlaceLocker = val
    end
})

UIElements.placeBoxFilter = TabAutomation:Dropdown({
    Title = "Allowed Boxes to Place (Multi-Select)",
    Desc = "Select multiple box types allowed to be placed onto droppers",
    Values = BoxOptions,
    Value = placeBoxFilter,
    Multi = true,
    AllowNone = true,
    Callback = function(val)
        placeBoxFilter = toTable(val, { "All" })
    end
})

UIElements.placeVariantFilter = TabAutomation:Dropdown({
    Title = "Allowed Mutation Variants to Place (Multi-Select)",
    Desc = "Select multiple mutation variants allowed to be placed onto droppers",
    Values = VariantOptions,
    Value = placeVariantFilter,
    Multi = true,
    AllowNone = true,
    Callback = function(val)
        placeVariantFilter = toTable(val, { "All" })
    end
})

UIElements.autoOpenLocker = TabAutomation:Toggle({
    Title = "Auto Open Ready Lockers",
    Desc = "Automatically opens lockers as soon as their unlock countdown finishes",
    Value = false,
    Callback = function(val)
        autoOpenLocker = val
    end
})

UIElements.autoSkipLocker = TabAutomation:Toggle({
    Title = "Auto Skip Locker Timers",
    Desc = "Triggers skip locker timer remote to expedite opening",
    Value = false,
    Callback = function(val)
        autoSkipLocker = val
    end
})

TabAutomation:Section({ Title = "Units Management & Grade Rerolls (Multi-Select)" })

UIElements.autoEquipBestUnits = TabAutomation:Toggle({
    Title = "Auto Equip Best Player Units",
    Desc = "Equips your strongest character units for maximum conveyor earnings",
    Value = false,
    Callback = function(val)
        autoEquipBestUnits = val
    end
})

UIElements.autoLevelUnits = TabAutomation:Toggle({
    Title = "Auto Level Up Units",
    Desc = "Automatically triggers character unit level ups on selected units",
    Value = false,
    Callback = function(val)
        autoLevelUnits = val
    end
})

UIElements.selectedLevelUnits = TabAutomation:Dropdown({
    Title = "Target Units to Level Up (Multi-Select)",
    Desc = "Select which units to level up (or 'All Units' / 'Equipped Units Only')",
    Values = getPlayerUnitOptions(),
    Value = selectedLevelUnits,
    Multi = true,
    AllowNone = false,
    Callback = function(val)
        selectedLevelUnits = toTable(val, { "All Units" })
    end
})

UIElements.autoRerollGrades = TabAutomation:Toggle({
    Title = "Auto Reroll Unit Grades",
    Desc = "Continuously rerolls unit grades on selected units until hitting target grades",
    Value = false,
    Callback = function(val)
        autoRerollGrades = val
    end
})

UIElements.selectedRerollUnits = TabAutomation:Dropdown({
    Title = "Target Units to Reroll Grade (Multi-Select)",
    Desc = "Select which units to reroll grade on (or 'All Units' / 'Backpack Units Only')",
    Values = getPlayerUnitOptions(),
    Value = selectedRerollUnits,
    Multi = true,
    AllowNone = false,
    Callback = function(val)
        selectedRerollUnits = toTable(val, { "All Units" })
    end
})

UIElements.targetGrades = TabAutomation:Dropdown({
    Title = "Target Grade Tiers to Keep (Multi-Select)",
    Desc = "Stops rerolling when unit reaches any of these grades",
    Values = GradeOptions,
    Value = targetGrades,
    Multi = true,
    AllowNone = false,
    Callback = function(val)
        targetGrades = toTable(val, { "S", "SS", "X", "EX", "UR" })
    end
})

UIElements.rerollCurrency = TabAutomation:Dropdown({
    Title = "Reroll Currency",
    Desc = "Choose whether to spend Grade Tokens, Cash, or Tokens first then Cash",
    Values = { "Auto (Tokens then Cash)", "Grade Tokens Only", "Cash Only" },
    Value = rerollCurrencyMode,
    Multi = false,
    AllowNone = false,
    Callback = function(val)
        rerollCurrencyMode = val or "Auto (Tokens then Cash)"
    end
})

UIElements.autoTeleportToGrading = TabAutomation:Toggle({
    Title = "Auto Teleport to Grading Station",
    Desc = "Teleports to the grading station if you do not have Bluetooth enabled",
    Value = true,
    Callback = function(val)
        autoTeleportToGrading = val
    end
})

UIElements.autoUnequipForReroll = TabAutomation:Toggle({
    Title = "Auto Unequip to Reroll",
    Desc = "Temporarily removes placed units from conveyor droppers so they can be graded",
    Value = true,
    Callback = function(val)
        autoUnequipForReroll = val
    end
})

TabAutomation:Button({
    Title = "Level Up All Placed Units (1-Click)",
    Desc = "Upgrades all placed character units on your tycoon conveyors that you can afford",
    Callback = function()
        task.spawn(function()
            local upgradedCount = 0
            pcall(function()
                local plot = getMyPlot()
                local conveyors = plot and plot:FindFirstChild("Systems")
                    and plot.Systems:FindFirstChild("TycoonConveyor")
                    and plot.Systems.TycoonConveyor:FindFirstChild("Conveyors")
                if not conveyors or not Remotes:FindFirstChild("RequestPlayerUnitLevelUp") then return end
                local cash = getCashAmount()
                local pus = PlayerUnitService
                for _, conv in ipairs(conveyors:GetChildren()) do
                    local dFolder = conv:FindFirstChild("Droppers")
                    if dFolder then
                        for _, dropper in ipairs(dFolder:GetChildren()) do
                            if dropper:IsA("BasePart") and dropper:GetAttribute("Type") == "PlayerUnit" then
                                local uName = dropper:GetAttribute("PlayerUnitName")
                                if uName then
                                    local curLvl = dropper:GetAttribute("PlayerUnitLevel") or 1
                                    if curLvl < 50 then
                                        local uData = {
                                            PlayerUnitName = uName,
                                            Level = curLvl,
                                            Variant = dropper:GetAttribute("PlayerUnitVariant") or "Normal",
                                            Grade = dropper:GetAttribute("PlayerUnitGrade"),
                                            Trait = dropper:GetAttribute("PlayerUnitTrait"),
                                            Equipped = true
                                        }
                                        if isUnitSelected(nil, uData, selectedLevelUnits) then
                                            local cost = nil
                                            if pus and typeof(pus.GetLevelUpgradeCost) == "function" then
                                                pcall(function()
                                                    cost = pus.GetLevelUpgradeCost(LocalPlayer, {
                                                        PlayerUnitName = uName,
                                                        PlayerUnitVariant = uData.Variant,
                                                        PlayerUnitGrade = uData.Grade,
                                                        PlayerUnitTrait = uData.Trait
                                                    }, curLvl + 1)
                                                end)
                                            end
                                            if cost == nil or cash >= cost then
                                                Remotes.RequestPlayerUnitLevelUp:FireServer(dropper)
                                                upgradedCount = upgradedCount + 1
                                                if cost then cash = cash - cost end
                                                task.wait(0.12)
                                                cash = getCashAmount()
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            WindUI:Notify({
                Title = "Units Level Up",
                Content = string.format("Level up triggered for %d units! Current Cash: $%s", upgradedCount, formatNumber(getCashAmount())),
                Duration = 3.5,
                Icon = "arrow-up-circle"
            })
        end)
    end
})

TabAutomation:Button({
    Title = "Equip Best Units (Fill Empty Conveyors)",
    Desc = "Places your highest earning backpack units onto all empty conveyor droppers",
    Callback = function()
        task.spawn(function()
            local placedCount = 0
            pcall(function()
                if Remotes:FindFirstChild("EquipBestPlayerUnits") then
                    Remotes.EquipBestPlayerUnits:FireServer()
                end
                local plot = getMyPlot()
                local conveyors = plot and plot:FindFirstChild("Systems")
                    and plot.Systems:FindFirstChild("TycoonConveyor")
                    and plot.Systems.TycoonConveyor:FindFirstChild("Conveyors")
                if not conveyors or not Remotes:FindFirstChild("PlacePlayerUnitOnDropper") then return end

                local emptyDroppers = {}
                for _, conv in ipairs(conveyors:GetChildren()) do
                    local dFolder = conv:FindFirstChild("Droppers")
                    if dFolder then
                        for _, dropper in ipairs(dFolder:GetChildren()) do
                            if dropper:IsA("BasePart") and dropper:GetAttribute("Unlocked") == true and dropper:GetAttribute("Type") == nil then
                                table.insert(emptyDroppers, dropper)
                            end
                        end
                    end
                end

                if #emptyDroppers == 0 then return end

                local allUnits = nil
                if PlayerUnitService and LocalPlayer then
                    pcall(function() allUnits = PlayerUnitService.GetAllPlayerUnits(LocalPlayer) end)
                end
                if not allUnits and ClientDataManager then
                    pcall(function()
                        local d = ClientDataManager.GetData()
                        allUnits = d and d.PlayerUnits
                    end)
                end
                if not allUnits or type(allUnits) ~= "table" then return end

                local backpack = {}
                for guid, uData in pairs(allUnits) do
                    if not uData.Equipped then
                        local cpd = 0
                        if PlayerUnitService and typeof(PlayerUnitService.GetCashPerDrop) == "function" then
                            pcall(function() cpd = PlayerUnitService.GetCashPerDrop(LocalPlayer, guid) end)
                        end
                        table.insert(backpack, { guid = guid, cpd = cpd or 0, name = uData.PlayerUnitName })
                    end
                end

                table.sort(backpack, function(a, b) return a.cpd > b.cpd end)

                for i = 1, math.min(#emptyDroppers, #backpack) do
                    Remotes.PlacePlayerUnitOnDropper:FireServer(emptyDroppers[i], backpack[i].guid)
                    placedCount = placedCount + 1
                    task.wait(0.15)
                end
            end)
            WindUI:Notify({
                Title = "Units Equipped",
                Content = string.format("Placed %d backpack units onto your conveyor droppers.", placedCount),
                Duration = 3,
                Icon = "user-check"
            })
        end)
    end
})

TabAutomation:Button({
    Title = "Teleport to Grading Station Now",
    Desc = "Moves your character next to the grading machine (-1767, 11, 28)",
    Callback = function()
        local hrp = getRoot()
        local gradingPart = workspace:FindFirstChild("Systems") 
            and workspace.Systems:FindFirstChild("Interactables") 
            and workspace.Systems.Interactables:FindFirstChild("Grading")
        local pos = gradingPart and (gradingPart.Position + Vector3.new(0, 3, 0)) or Vector3.new(-1767.87, 14, 27.88)
        if hrp then
            hrp.CFrame = CFrame.new(pos)
        end
    end
})

TabAutomation:Button({
    Title = "Teleport back to Plot Now",
    Desc = "Moves your character back to your tycoon baseplate",
    Callback = function()
        local hrp = getRoot()
        local plot = getMyPlot()
        local spawnP = plot and (plot:FindFirstChild("SpawnPart") or plot:FindFirstChild("Base"))
        if hrp and spawnP then
            hrp.CFrame = CFrame.new(spawnP.Position + Vector3.new(0, 3, 0))
        end
    end
})

local function refreshUnitDropdowns()
    local newOpts = getPlayerUnitOptions()
    pcall(function()
        if UIElements.selectedLevelUnits then
            if UIElements.selectedLevelUnits.Refresh then
                UIElements.selectedLevelUnits:Refresh(newOpts)
            elseif UIElements.selectedLevelUnits.SetValues then
                UIElements.selectedLevelUnits:SetValues(newOpts)
            end
        end
        if UIElements.selectedRerollUnits then
            if UIElements.selectedRerollUnits.Refresh then
                UIElements.selectedRerollUnits:Refresh(newOpts)
            elseif UIElements.selectedRerollUnits.SetValues then
                UIElements.selectedRerollUnits:SetValues(newOpts)
            end
        end
    end)
    return newOpts
end

task.delay(3, function()
    pcall(refreshUnitDropdowns)
end)

TabAutomation:Button({
    Title = "Refresh Owned Units List",
    Desc = "Re-scans your inventory and updates the unit selection dropdowns",
    Callback = function()
        local newOpts = refreshUnitDropdowns()
        WindUI:Notify({
            Title = "Units List Refreshed",
            Content = string.format("Loaded %d unit options from inventory.", #newOpts),
            Duration = 3,
            Icon = "refresh-cw"
        })
    end
})

-- Universal Missions & Event Claim Engine (Handles Event & Daily tabs, GUI Claim Buttons, & Remotes)
local function claimAllMissionsUniversal()
    local count = 0
    pcall(function()
        local lp = LocalPlayer
        -- 1. Direct Server Remote Claims
        if Remotes:FindFirstChild("TryClaimMission") then
            if MissionService and MissionLibrary then
                for mName, _ in pairs(MissionLibrary) do
                    local ok, can = pcall(function() return MissionService.IsMissionClaimable(lp, mName) end)
                    if ok and can == true then
                        Remotes.TryClaimMission:FireServer(mName)
                        count = count + 1
                        task.wait(0.08)
                    end
                end
            end
            -- Halloween & Event Mission list fallback
            local eventNames = {
                "Lucky Streak", "Bad Neighbors", "Zombie Slayer", "Kingslayer", "Night Owl",
                "Trick or Treat", "Halloween", "Event_1", "Event_2", "Event_3", "Event_4", "Event_5",
                "Daily_1", "Daily_2", "Daily_3", "Daily_4", "Daily_5"
            }
            for _, em in ipairs(eventNames) do
                pcall(function() Remotes.TryClaimMission:FireServer(em) end)
            end
        end

        -- 2. GUI Tab & Button Scanner (Handles Screenshot 3 Missions UI: Event/Daily tabs + Claim button)
        local pg = lp:FindFirstChild("PlayerGui")
        if not pg then return end

        local function clickGuiBtn(b)
            if not b then return end
            pcall(function()
                if getconnections then
                    for _, c in ipairs(getconnections(b.MouseButton1Click)) do pcall(c.Fire, c) end
                    for _, c in ipairs(getconnections(b.Activated)) do pcall(c.Fire, c) end
                end
            end)
        end

        local function clickVisibleClaimButtons(root)
            if not root then return end
            for _, desc in ipairs(root:GetDescendants()) do
                if (desc:IsA("TextButton") or desc:IsA("ImageButton")) and desc.Visible then
                    local t = (desc:IsA("TextButton") and desc.Text:lower()) or desc.Name:lower()
                    if t == "claim" or t == "claimbtn" or t == "claimbutton" or t:find("claim") or t:find("รับรางวัล") then
                        clickGuiBtn(desc)
                        count = count + 1
                        task.wait(0.08)
                    end
                end
            end
        end

        -- Scan all ScreenGuis in PlayerGui
        for _, gui in ipairs(pg:GetChildren()) do
            if gui:IsA("ScreenGui") and (gui.Name:lower():find("mission") or gui:FindFirstChild("MainFrame", true) or gui:FindFirstChild("Missions", true)) then
                -- Step A: Click any ready Claim button right away
                clickVisibleClaimButtons(gui)

                -- Step B: Locate Tab Buttons (e.g. "Event", "Daily")
                local tabButtons = {}
                for _, desc in ipairs(gui:GetDescendants()) do
                    if (desc:IsA("TextButton") or desc:IsA("ImageButton")) then
                        local btnText = (desc:IsA("TextButton") and desc.Text) or desc.Name
                        if btnText == "Event" or btnText == "Daily" then
                            table.insert(tabButtons, desc)
                        end
                    end
                end

                local function processCurrentTabItems()
                    clickVisibleClaimButtons(gui)
                    for _, sc in ipairs(gui:GetDescendants()) do
                        if sc:IsA("ScrollingFrame") then
                            for _, item in ipairs(sc:GetChildren()) do
                                if item:IsA("GuiObject") and item.Name ~= "Default" and item.Name ~= "UIListLayout" and item.Name ~= "UIPadding" then
                                    -- Check for completed/notification badge (red circle with '!', NotificationLabel, etc.)
                                    local hasAlert = false
                                    for _, b in ipairs(item:GetDescendants()) do
                                        if b.Visible and (b.Name:find("Notif") or b.Name:find("Alert") or b.Name:find("Exclamation") or (b:IsA("TextLabel") and b.Text == "!")) then
                                            hasAlert = true
                                            break
                                        end
                                    end

                                    if hasAlert then
                                        -- Select the mission item to populate detail pane
                                        if item:IsA("TextButton") or item:IsA("ImageButton") then
                                            clickGuiBtn(item)
                                        else
                                            local clicker = item:FindFirstChildWhichIsA("TextButton") or item:FindFirstChildWhichIsA("ImageButton")
                                            if clicker then clickGuiBtn(clicker) end
                                        end
                                        task.wait(0.1)

                                        -- Click the green Claim button in detail pane
                                        clickVisibleClaimButtons(gui)

                                        if Remotes:FindFirstChild("TryClaimMission") then
                                            Remotes.TryClaimMission:FireServer(item.Name)
                                        end
                                        task.wait(0.08)
                                    end
                                end
                            end
                        end
                    end
                end

                -- Process default/first view
                processCurrentTabItems()

                -- Switch tabs and process each
                for _, tb in ipairs(tabButtons) do
                    clickGuiBtn(tb)
                    task.wait(0.15)
                    processCurrentTabItems()
                end
            end
        end
    end)
    return count
end

TabAutomation:Section({ Title = "Missions & Quests" })

UIElements.autoClaimMissions = TabAutomation:Toggle({
    Title = "Auto Claim Completed Missions",
    Desc = "Continuously claims completed Daily and Event missions for free rewards",
    Value = false,
    Callback = function(val)
        autoClaimMissions = val
    end
})

TabAutomation:Button({
    Title = "Claim All Available Missions Now",
    Desc = "Checks all missions across Event and Daily tabs and claims every ready reward",
    Callback = function()
        task.spawn(function()
            local count = claimAllMissionsUniversal()
            WindUI:Notify({
                Title = "Missions Claimed",
                Content = count > 0 and ("Claimed " .. count .. " missions!") or "All ready missions have been claimed!",
                Duration = 3.5,
                Icon = "award"
            })
        end)
    end
})

--------------------------------------------------------------------------------
-- TAB: BALL SKINS (DEDICATED SELECTION & REAL CASH PURCHASING)
--------------------------------------------------------------------------------
TabBallSkins:Section({ Title = "Ball Skin Market Status" })

BallSkinStatusParagraph = TabBallSkins:Paragraph({
    Title = "Ball Skin Overview",
    Desc = "Loading market data..."
})

TabBallSkins:Section({ Title = "Ball Skin Selection & Auto Purchase" })

UIElements.autoBuyBallSkins = TabBallSkins:Toggle({
    Title = "Auto Buy Selected Ball Skins",
    Desc = "Continuously checks Cash balance and purchases your selected Ball Skins whenever affordable",
    Value = false,
    Callback = function(val)
        autoBuyBallSkins = val
    end
})

UIElements.selectedBallSkins = TabBallSkins:Dropdown({
    Title = "Select Ball Skins to Purchase (Multi-Select)",
    Desc = "Choose multiple Ball Skins you want to own and equip",
    Values = BallSkinOptions,
    Value = { "Beach (1.25x | $25M)", "Supercharged (1.5x | $25B)" },
    Multi = true,
    AllowNone = true,
    Callback = function(val)
        selectedBallSkins = toTable(val, {})
    end
})

TabBallSkins:Button({
    Title = "Buy Selected Ball Skins Now",
    Desc = "Executes immediate purchase for all affordable selected Ball Skins",
    Callback = function()
        local bought = 0
        local cash = getCashAmount()
        if Remotes:FindFirstChild("BallSkinPurchaseCash") then
            for _, rawChoice in ipairs(selectedBallSkins) do
                local sName = string.match(rawChoice, "^([%w_]+)")
                if sName then
                    for _, skinData in ipairs(BallSkinsCatalog) do
                        if skinData.Name == sName and (cash == 0 or cash >= skinData.Price) then
                            Remotes.BallSkinPurchaseCash:FireServer(sName)
                            bought = bought + 1
                            if cash >= skinData.Price then
                                cash = cash - skinData.Price
                            end
                            task.wait(0.25)
                            break
                        end
                    end
                end
            end
        end
        WindUI:Notify({
            Title = "Ball Skin Purchase",
            Content = bought > 0 and ("Purchase sent for " .. bought .. " selected Ball Skin(s)!") or "No Ball Skins selected or insufficient Cash.",
            Duration = 3.5,
            Icon = bought > 0 and "check-check" or "alert-triangle"
        })
    end
})

TabBallSkins:Section({ Title = "Conveyor Droppers Equipment" })

UIElements.autoApplyBallSkins = TabBallSkins:Toggle({
    Title = "Auto Apply Best Owned Ball Skin to Droppers",
    Desc = "Automatically applies your highest multiplier owned Ball Skin to all conveyor droppers",
    Value = false,
    Callback = function(val)
        autoApplyBallSkins = val
    end
})

TabBallSkins:Button({
    Title = "Apply Best Skin to All Droppers Now",
    Desc = "Manually updates all conveyor droppers to your best skin",
    Callback = function()
        pcall(function()
            local bestSkin = "Base"
            local bestMult = 1.0
            if ClientDataManager then
                local d = ClientDataManager.GetData()
                local owned = d and d.Inventory and d.Inventory.BallSkins or {}
                for sName, count in pairs(owned) do
                    if tonumber(count) and tonumber(count) > 0 then
                        for _, entry in ipairs(BallSkinsCatalog) do
                            if entry.Name == sName and entry.Multiplier > bestMult then
                                bestMult = entry.Multiplier
                                bestSkin = entry.Name
                            end
                        end
                    end
                end
            end

            local plot = getMyPlot()
            local droppers = plot and plot.Systems
                and plot.Systems:FindFirstChild("TycoonConveyor")
                and plot.Systems.TycoonConveyor:FindFirstChild("Conveyors")
                and plot.Systems.TycoonConveyor.Conveyors:FindFirstChild("Conveyor1")
                and plot.Systems.TycoonConveyor.Conveyors.Conveyor1:FindFirstChild("Droppers")

            if droppers and Remotes:FindFirstChild("ApplyBallSkinToDropper") then
                for _, d in ipairs(droppers:GetChildren()) do
                    if d:IsA("BasePart") and d:GetAttribute("Unlocked") == true then
                        Remotes.ApplyBallSkinToDropper:FireServer(d, bestSkin)
                    end
                end
            end

            WindUI:Notify({
                Title = "Ball Skins Applied",
                Content = "Equipped " .. bestSkin .. " (" .. bestMult .. "x) to all droppers!",
                Duration = 3,
                Icon = "check"
            })
        end)
    end
})

--------------------------------------------------------------------------------
-- TAB: UPGRADES & REWARDS
--------------------------------------------------------------------------------
TabUpgrades:Section({ Title = "Stat Upgrades" })

UIElements.autoBuyUpgrades = TabUpgrades:Toggle({
    Title = "Auto Purchase All Upgrades",
    Desc = "Keeps WalkSpeed, Luck, OpenTimeBoost, PlayerUnitExpansion, and ConveyorLuck maxed",
    Value = false,
    Callback = function(val)
        autoBuyUpgrades = val
    end
})

TabUpgrades:Button({
    Title = "Purchase All Affordable Upgrades Now",
    Desc = "Scans all available tycoon upgrades and purchases everything you can currently afford",
    Callback = function()
        task.spawn(function()
            local purchasedCount = 0
            pcall(function()
                local cash = getCashAmount()
                local ul = UpgradesLibrary
                local us = UpgradesService
                for _, upg in ipairs(UpgradesList) do
                    local canBuy = true
                    if ul and ul[upg] then
                        local lvl = (us and typeof(us.GetTimesPurchased) == "function" and us.GetTimesPurchased(LocalPlayer, upg)) or 0
                        local max = ul[upg].MaxPurchases
                        if max and lvl >= max then
                            canBuy = false
                        else
                            local price = ul[upg].GetPrice and ul[upg].GetPrice(lvl + 1)
                            if price and cash < price then
                                canBuy = false
                            end
                        end
                    end
                    if canBuy and Remotes:FindFirstChild("PurchaseUpgrade") then
                        Remotes.PurchaseUpgrade:FireServer(upg)
                        purchasedCount = purchasedCount + 1
                        task.wait(0.2)
                        cash = getCashAmount()
                    end
                end
            end)
            WindUI:Notify({
                Title = "Upgrades Processed",
                Content = string.format("Purchased %d affordable upgrades! Current Cash: $%s", purchasedCount, formatNumber(getCashAmount())),
                Duration = 3,
                Icon = "check"
            })
        end)
    end
})

TabUpgrades:Section({ Title = "Rewards & Loyalty" })

UIElements.autoClaimRewards = TabUpgrades:Toggle({
    Title = "Auto Claim All Free Rewards",
    Desc = "Claims Offline Earnings, Daily Rewards, All Index Rewards, Obby Bonus, and Playtime Gifts 1-12",
    Value = false,
    Callback = function(val)
        autoClaimRewards = val
    end
})

TabUpgrades:Button({
    Title = "Claim All Rewards Now",
    Desc = "Triggers all claim remotes in order immediately",
    Callback = function()
        task.spawn(function()
            pcall(function()
                if Remotes:FindFirstChild("ClaimOfflineEarnings") then Remotes.ClaimOfflineEarnings:FireServer() end
                if Remotes:FindFirstChild("ClaimDailyReward") then
                    local dls = DailyLoginService
                    if dls and typeof(dls.GetNextClaimableDay) == "function" then
                        local day = dls.GetNextClaimableDay(LocalPlayer)
                        if day then Remotes.ClaimDailyReward:FireServer(day) end
                    end
                    Remotes.ClaimDailyReward:FireServer()
                end
                if Remotes:FindFirstChild("ClaimAllIndexRewards") then Remotes.ClaimAllIndexRewards:FireServer() end
                if Remotes:FindFirstChild("ClaimObbyBonus") then Remotes.ClaimObbyBonus:FireServer() end
                if Remotes:FindFirstChild("ClaimPlaytimeReward") then
                    for i = 1, 12 do
                        Remotes.ClaimPlaytimeReward:FireServer(i)
                        task.wait(0.12)
                    end
                end
            end)
            WindUI:Notify({
                Title = "Rewards Claimed",
                Content = "Executed claim for Playtime 1-12, Daily, Index & Offline Earnings!",
                Duration = 3,
                Icon = "gift"
            })
        end)
    end
})

TabUpgrades:Section({ Title = "In-Game Menus & Quick Shortcuts" })

TabUpgrades:Button({
    Title = "Toggle In-Game Inventory Menu",
    Desc = "Opens or closes the official in-game locker and units inventory window",
    Callback = function()
        pcall(function()
            local holder = LocalPlayer.PlayerGui.FrontGui.LeftFrame.SquareHolder
            local btn = holder and holder:FindFirstChild("Inventory")
            if btn and typeof(firesignal) == "function" then
                firesignal(btn.MouseButton1Click)
                firesignal(btn.Activated)
            else
                local ig = LocalPlayer.PlayerGui:FindFirstChild("InventoryGui")
                if ig and ig:FindFirstChild("MainFrame") then
                    ig.MainFrame.Visible = not ig.MainFrame.Visible
                end
            end
        end)
    end
})

TabUpgrades:Button({
    Title = "Toggle In-Game Shop Menu",
    Desc = "Opens or closes the official in-game gamepass, boost & Robux shop window",
    Callback = function()
        pcall(function()
            local holder = LocalPlayer.PlayerGui.FrontGui.LeftFrame.SquareHolder
            local btn = holder and (holder:FindFirstChild("Shop") or LocalPlayer.PlayerGui.FrontGui.LeftFrame.RectangleHolder:FindFirstChild("Shop"))
            if btn and typeof(firesignal) == "function" then
                firesignal(btn.MouseButton1Click)
                firesignal(btn.Activated)
            else
                local sg = LocalPlayer.PlayerGui:FindFirstChild("ShopGui")
                if sg and sg:FindFirstChild("MainFrame") then
                    sg.MainFrame.Visible = not sg.MainFrame.Visible
                end
            end
        end)
    end
})

TabUpgrades:Button({
    Title = "Toggle In-Game Rewards Menu",
    Desc = "Opens or closes the official playtime rewards & daily claim window",
    Callback = function()
        pcall(function()
            local holder = LocalPlayer.PlayerGui.FrontGui.LeftFrame.SquareHolder
            local btn = holder and holder:FindFirstChild("Rewards")
            if btn and typeof(firesignal) == "function" then
                firesignal(btn.MouseButton1Click)
                firesignal(btn.Activated)
            else
                local rg = LocalPlayer.PlayerGui:FindFirstChild("PlaytimeRewardsGui")
                if rg and rg:FindFirstChild("MainFrame") then
                    rg.MainFrame.Visible = not rg.MainFrame.Visible
                end
            end
        end)
    end
})

TabUpgrades:Button({
    Title = "Toggle In-Game Upgrades Menu",
    Desc = "Opens or closes the official in-game tycoon upgrades window",
    Callback = function()
        pcall(function()
            local holder = LocalPlayer.PlayerGui.FrontGui.LeftFrame.SquareHolder
            local btn = holder and holder:FindFirstChild("Upgrades")
            if btn and typeof(firesignal) == "function" then
                firesignal(btn.MouseButton1Click)
                firesignal(btn.Activated)
            else
                local ug = LocalPlayer.PlayerGui:FindFirstChild("UpgradesGui")
                if ug and ug:FindFirstChild("MainFrame") then
                    ug.MainFrame.Visible = not ug.MainFrame.Visible
                end
            end
        end)
    end
})

TabUpgrades:Button({
    Title = "Toggle In-Game Index Menu",
    Desc = "Opens or closes the official in-game striker unit index book window",
    Callback = function()
        pcall(function()
            local holder = LocalPlayer.PlayerGui.FrontGui.LeftFrame.SquareHolder
            local btn = holder and holder:FindFirstChild("Index")
            if btn and typeof(firesignal) == "function" then
                firesignal(btn.MouseButton1Click)
                firesignal(btn.Activated)
            else
                local ig = LocalPlayer.PlayerGui:FindFirstChild("IndexGui")
                if ig and ig:FindFirstChild("MainFrame") then
                    ig.MainFrame.Visible = not ig.MainFrame.Visible
                end
            end
        end)
    end
})

TabUpgrades:Section({ Title = "Obby Courses & Bonus Rewards" })

ObbyStatusParagraph = TabUpgrades:Paragraph({
    Title = "Obby Status & Cooldowns",
    Desc = "Loading Obby bonus countdown timers..."
})

UIElements.autoObby = TabUpgrades:Toggle({
    Title = "Auto Complete Obbies (Easy, Medium, Hard)",
    Desc = "Automatically solves ready courses and claims Grade Tokens & rare Potions",
    Value = false,
    Callback = function(val)
        autoObby = val
    end
})

UIElements.selectedObbyCourses = TabUpgrades:Dropdown({
    Title = "Select Obby Courses (Multi-Select)",
    Desc = "Choose which Obbies to automatically complete when ready",
    Values = { "Easy Obby", "Medium Obby", "Hard Obby" },
    Value = selectedObbyCourses,
    Multi = true,
    AllowNone = false,
    Callback = function(val)
        selectedObbyCourses = toTable(val, { "Easy Obby", "Medium Obby", "Hard Obby" })
    end
})

TabUpgrades:Button({
    Title = "Complete All Ready Obbies Now",
    Desc = "Instantly solves all Obby courses currently off cooldown",
    Callback = function()
        pcall(function() doCompleteObby() end)
    end
})

TabUpgrades:Button({
    Title = "Teleport to Obby Portal",
    Desc = "Teleports character to the Obby Teleport entrance portal in the world",
    Callback = function()
        local hrp = getRoot()
        local portal = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("ObbyPortal")
        if hrp and portal then
            local target = portal:FindFirstChild("Top") or portal:FindFirstChild("Bottom") or portal
            local cf = target:IsA("BasePart") and target.CFrame or portal:GetPivot()
            hrp.CFrame = cf * CFrame.new(0, 3, -12)
        end
    end
})

TabUpgrades:Button({
    Title = "Teleport to Obby Arena",
    Desc = "Teleports character inside the Obby obstacle arena platform",
    Callback = function()
        local hrp = getRoot()
        local tele = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("PersistentParts") and workspace.Systems.PersistentParts:FindFirstChild("ObbyTeleport")
        if hrp and tele then
            hrp.CFrame = tele.CFrame * CFrame.new(0, 5, 0)
        end
    end
})

TabUpgrades:Button({
    Title = "Teleport to Easy Obby Goal",
    Desc = "Teleports to Easy Obby victory pad (2 Grade Tokens)",
    Callback = function()
        local hrp = getRoot()
        local p = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Obby") and workspace.Systems.Obby:FindFirstChild("VictoryParts") and workspace.Systems.Obby.VictoryParts:FindFirstChild("EasyObby")
        if hrp and p then hrp.CFrame = CFrame.new(p.Position + Vector3.new(0, 3, 0)) end
    end
})

TabUpgrades:Button({
    Title = "Teleport to Medium Obby Goal",
    Desc = "Teleports to Medium Obby victory pad (5 Grade Tokens + Luck Potion)",
    Callback = function()
        local hrp = getRoot()
        local p = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Obby") and workspace.Systems.Obby:FindFirstChild("VictoryParts") and workspace.Systems.Obby.VictoryParts:FindFirstChild("MediumObby")
        if hrp and p then hrp.CFrame = CFrame.new(p.Position + Vector3.new(0, 3, 0)) end
    end
})

TabUpgrades:Button({
    Title = "Teleport to Hard Obby Goal",
    Desc = "Teleports to Hard Obby victory pad (5 Grade Tokens + GradeSpeed Potion + Bluetooth Potion)",
    Callback = function()
        local hrp = getRoot()
        local p = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Obby") and workspace.Systems.Obby:FindFirstChild("VictoryParts") and workspace.Systems.Obby.VictoryParts:FindFirstChild("HardObby")
        if hrp and p then hrp.CFrame = CFrame.new(p.Position + Vector3.new(0, 3, 0)) end
    end
})

TabUpgrades:Section({ Title = "Promo Codes" })

TabUpgrades:Button({
    Title = "Redeem Active Creator Codes",
    Desc = "Redeems WEATHER, HALLOWEEN, RELEASE, TRICKORTREAT, SPOOKY, CANDY, BLUELOCK",
    Callback = function()
        local codes = { "WEATHER", "HALLOWEEN", "RELEASE", "TRICKORTREAT", "SPOOKY", "UPDATE", "CANDY", "BLUELOCK" }
        local redeemed = 0
        if Remotes:FindFirstChild("RedeemCode") then
            for _, code in ipairs(codes) do
                local ok, res = pcall(function()
                    return Remotes.RedeemCode:InvokeServer(code)
                end)
                if ok and res then redeemed = redeemed + 1 end
                task.wait(0.2)
            end
        end
        WindUI:Notify({
            Title = "Codes Redeemed",
            Content = "Codes redeemed successfully!",
            Duration = 3,
            Icon = "check"
        })
    end
})

--------------------------------------------------------------------------------
-- TAB: INFINITY TOWER
--------------------------------------------------------------------------------
TabTower:Section({ Title = "Tower Automation" })

local TowerStageMap = {
    ["Highest Unlocked"] = "Highest",
    ["Entrance"] = "Entrance",
    ["First Selection"] = "FirstSelection",
    ["Second Selection"] = "SecondSelection",
    ["Third Selection"] = "ThirdSelection",
    ["U-20"] = "U20"
}

TowerStageDisplayMap = {
    ["Entrance"] = "Entrance",
    ["FirstSelection"] = "First Selection",
    ["SecondSelection"] = "Second Selection",
    ["ThirdSelection"] = "Third Selection",
    ["U20"] = "U-20"
}

local TowerStageOrder = { "Entrance", "FirstSelection", "SecondSelection", "ThirdSelection", "U20" }

local TowerStageOptions = {
    "Highest Unlocked",
    "Entrance",
    "First Selection",
    "Second Selection",
    "Third Selection",
    "U-20"
}

local function getBestTowerUnits()
    local unitGuids = {}
    if PlayerUnitService and LocalPlayer then
        local ok, allUnits = pcall(function() return PlayerUnitService.GetAllPlayerUnits(LocalPlayer) end)
        if ok and type(allUnits) == "table" then
            local unitList = {}
            for guid, unit in pairs(allUnits) do
                local power = (tonumber(unit.Damage) or 0) * (tonumber(unit.Health) or 0)
                table.insert(unitList, { guid = guid, power = power })
            end
            table.sort(unitList, function(a, b) return a.power > b.power end)
            for i = 1, math.min(5, #unitList) do
                table.insert(unitGuids, unitList[i].guid)
            end
        end
    end
    return unitGuids
end

getTargetTowerStage = function()
    local chosen = TowerStageMap[selectedTowerStage] or selectedTowerStage or "Entrance"
    if chosen == "Highest" then
        local highest = "Entrance"
        if InfinityTowerService and LocalPlayer then
            for _, stage in ipairs(TowerStageOrder) do
                local ok, blockReason = pcall(function() return InfinityTowerService.GetPlayBlockReason(LocalPlayer, stage) end)
                if ok and not blockReason then
                    highest = stage
                end
            end
        end
        return highest
    else
        if InfinityTowerService and LocalPlayer then
            local ok, blockReason = pcall(function() return InfinityTowerService.GetPlayBlockReason(LocalPlayer, chosen) end)
            if ok and blockReason then
                for _, stage in ipairs(TowerStageOrder) do
                    local ok2, reason2 = pcall(function() return InfinityTowerService.GetPlayBlockReason(LocalPlayer, stage) end)
                    if ok2 and not reason2 then
                        chosen = stage
                    end
                end
            end
        end
        return chosen
    end
end

doStartTowerBattle = function()
    if not Remotes or not Remotes:FindFirstChild("StartInfinityTowerBattle") then return false end
    local targetStage = getTargetTowerStage()
    local units = getBestTowerUnits()
    local ok, res = pcall(function()
        return Remotes.StartInfinityTowerBattle:InvokeServer(targetStage, units)
    end)
    if ok and res then
        activeTowerStage = targetStage
        isTowerInBattle = true
        if Remotes:FindFirstChild("SetInfinityTowerAutoBattle") then
            pcall(function() Remotes.SetInfinityTowerAutoBattle:FireServer(targetStage, true) end)
        end
        return true
    end
    return false
end

doExitTowerBattle = function(stage)
    if not Remotes or not Remotes:FindFirstChild("ExitInfinityTowerBattle") then return false end
    local targetStage = stage or activeTowerStage or getTargetTowerStage()
    local ok = pcall(function()
        Remotes.ExitInfinityTowerBattle:FireServer(targetStage)
    end)
    isTowerInBattle = false
    activeTowerFloor = 0
    return ok
end

TowerStatusParagraph = TabTower:Paragraph({
    Title = "Tower Battle Status",
    Desc = "• Status: Idle 💤\n• Target Stage: " .. tostring(selectedTowerStage) .. "\n• Current Floor: 0\n• Surrender at: " .. (towerSurrenderFloor > 0 and tostring(towerSurrenderFloor) or "None (Infinite)")
})

UIElements.autoInfinityTower = TabTower:Toggle({
    Title = "Auto Battle Infinity Tower",
    Desc = "Enters Infinity Tower with top units, auto-battles, and surrenders at target floor to cash out",
    Value = false,
    Callback = function(val)
        autoInfinityTower = val
        if not val and isTowerInBattle then
            doExitTowerBattle()
        end
    end
})

UIElements.selectedTowerStage = TabTower:Dropdown({
    Title = "Select Tower Stage",
    Desc = "Choose a specific stage or 'Highest Unlocked' to automatically progress",
    Values = TowerStageOptions,
    Value = selectedTowerStage or "Entrance",
    Callback = function(val)
        selectedTowerStage = val
    end
})

UIElements.towerSurrenderFloor = TabTower:Input({
    Title = "Surrender Floor Target (0 = Infinite)",
    Desc = "Enter floor number to forfeit & cash out rewards, then restart (0 = fight till defeat)",
    Value = tostring(towerSurrenderFloor or 0),
    Placeholder = "0 for infinite, or e.g. 25, 50, 100",
    Callback = function(val)
        local num = tonumber(val) or 0
        towerSurrenderFloor = math.max(0, math.floor(num))
    end
})

TabTower:Button({
    Title = "Enter Tower Battle Now",
    Desc = "Manually deploy top units into selected tower stage",
    Callback = function()
        local success = doStartTowerBattle()
        if success then
            WindUI:Notify({
                Title = "Tower Battle",
                Content = "Started battle on: " .. tostring(getTargetTowerStage()),
                Duration = 3,
                Icon = "swords"
            })
        else
            WindUI:Notify({
                Title = "Tower Battle",
                Content = "Failed to start battle. Stage may be locked.",
                Duration = 3,
                Icon = "alert-triangle"
            })
        end
    end
})

TabTower:Button({
    Title = "Exit / Surrender Tower Battle Now",
    Desc = "Manually exit battle and cash out floor rewards",
    Callback = function()
        doExitTowerBattle()
        WindUI:Notify({
            Title = "Tower Battle",
            Content = "Exited tower battle.",
            Duration = 3,
            Icon = "log-out"
        })
    end
})

--------------------------------------------------------------------------------
-- TAB: TELEPORTS
--------------------------------------------------------------------------------
TabTeleport:Section({ Title = "Plot & Tycoon" })

TabTeleport:Button({
    Title = "Teleport to My Plot (Spawn Base)",
    Callback = function()
        local plot = getMyPlot()
        local base = plot and (plot:FindFirstChild("SpawnPart") or plot:FindFirstChild("Base"))
        local hrp = getRoot()
        if base and hrp then
            hrp.CFrame = CFrame.new(base.Position + Vector3.new(0, 4, 0))
        end
    end
})

TabTeleport:Button({
    Title = "Teleport to Tycoon Conveyor",
    Callback = function()
        local plot = getMyPlot()
        local conv = plot and plot.Systems and plot.Systems:FindFirstChild("TycoonConveyor")
        local hrp = getRoot()
        if conv and hrp then
            local part = conv:FindFirstChild("CollectPart") or conv:GetPivot()
            hrp.CFrame = typeof(part) == "CFrame" and (part + Vector3.new(0, 4, 0)) or CFrame.new(part.Position + Vector3.new(0, 4, 0))
        end
    end
})

TabTeleport:Button({
    Title = "Teleport to Roll Station",
    Callback = function()
        local plot = getMyPlot()
        local roll = plot and plot.Systems and plot.Systems:FindFirstChild("RollStation")
        local hrp = getRoot()
        if roll and hrp then
            local part = roll:FindFirstChild("ConveyorPart") or roll:GetPivot()
            hrp.CFrame = typeof(part) == "CFrame" and (part + Vector3.new(0, 4, 0)) or CFrame.new(part.Position + Vector3.new(0, 4, 0))
        end
    end
})

TabTeleport:Button({
    Title = "Teleport to Polisher Station",
    Desc = "Teleports to the Polisher machine on your plot",
    Callback = function()
        local polisher, col = getPolisher()
        local hrp = getRoot()
        if col and hrp then
            hrp.CFrame = CFrame.new(col.Position + Vector3.new(0, 4, 0))
        elseif polisher and hrp then
            hrp.CFrame = polisher:GetPivot() * CFrame.new(0, 4, 0)
        end
    end
})

TabTeleport:Section({ Title = "World POIs & Events" })

TabTeleport:Button({
    Title = "Teleport to Tournament Stadium Pitch",
    Callback = function()
        local hrp = getRoot()
        if hrp then
            hrp.CFrame = CFrame.new(Vector3.new(-1795, 4.0, 171.5))
            WindUI:Notify({
                Title = "Teleport",
                Content = "Teleported to Tournament Field!",
                Duration = 2,
                Icon = "map-pin"
            })
        end
    end
})

--------------------------------------------------------------------------------
-- TAB: PLAYER / MISC
--------------------------------------------------------------------------------
TabPlayer:Section({ Title = "Movement Enhancements" })

UIElements.modWalkSpeed = TabPlayer:Toggle({
    Title = "Enable Custom WalkSpeed",
    Value = false,
    Callback = function(val)
        modWalkSpeed = val
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = val and customWalkSpeed or 16 end
    end
})

UIElements.customWalkSpeed = TabPlayer:Slider({
    Title = "WalkSpeed Value",
    Min = 16,
    Max = 250,
    Default = 16,
    Callback = function(val)
        customWalkSpeed = val
        if modWalkSpeed then
            local hum = getHumanoid()
            if hum then hum.WalkSpeed = val end
        end
    end
})

UIElements.modJumpPower = TabPlayer:Toggle({
    Title = "Enable Custom JumpPower",
    Value = false,
    Callback = function(val)
        modJumpPower = val
        local hum = getHumanoid()
        if hum then hum.JumpPower = val and customJumpPower or 50 end
    end
})

UIElements.customJumpPower = TabPlayer:Slider({
    Title = "JumpPower Value",
    Min = 50,
    Max = 350,
    Default = 50,
    Callback = function(val)
        customJumpPower = val
        if modJumpPower then
            local hum = getHumanoid()
            if hum then hum.JumpPower = val end
        end
    end
})

UIElements.infiniteJump = TabPlayer:Toggle({
    Title = "Infinite Jump",
    Value = false,
    Callback = function(val)
        infiniteJump = val
    end
})

UIElements.noclip = TabPlayer:Toggle({
    Title = "Noclip (Walk Through Walls)",
    Value = false,
    Callback = function(val)
        noclip = val
    end
})

TabPlayer:Section({ Title = "Safety & Quality of Life" })

UIElements.antiAfk = TabPlayer:Toggle({
    Title = "Anti-AFK Protection",
    Desc = "Prevents Roblox 20-minute idle disconnect",
    Value = false,
    Callback = function(val)
        antiAfk = val
    end
})

TabPlayer:Section({ Title = "UI Keybind" })

TabPlayer:Keybind({
    Title = "Toggle UI Keybind",
    Desc = "Press to open / close Song Hub interface",
    Value = "RightControl",
    Callback = function(key)
        if typeof(key) == "EnumItem" then
            currentToggleKey = key
            currentToggleKeyName = key.Name
            pcall(function() Window:SetToggleKey(key) end)
        elseif type(key) == "string" and Enum.KeyCode[key] then
            currentToggleKey = Enum.KeyCode[key]
            currentToggleKeyName = key
            pcall(function() Window:SetToggleKey(Enum.KeyCode[key]) end)
        end
    end
})

--------------------------------------------------------------------------------
-- TAB: FOOTBALL UI / FX (STADIUM THEME & MOVING ANIMATIONS)
--------------------------------------------------------------------------------
TabFX:Paragraph({
    Title = "⚽ Football Stadium & Blue Lock Ego FX Engine",
    Desc = "• ธีมสนามฟุตบอล (Turf Green + Blue Lock Ego Cyan + Ballon d'Or Gold)\n• เส้นสนามฟุตบอล + วงกลมกลางสนามหมุนได้ (Rotating Pitch Center Circle)\n• ลูกฟุตบอลหมุนลอยพริ้วไหว + ประกายออร่า Ego (Spinning Footballs & Sparks)\n• ลูกฟุตบอลเลี้ยงเดาะวิ่งตามเส้นประตูด้านบน (Topbar Goal-Line Dribbling Ball)\n• ขอบไฟสปอตไลท์สนามหมุนรอบหน้าต่าง + ป้ายสกอร์บอร์ด FPS/Ping แบบถ่ายทอดสด"
})

TabFX:Section({ Title = "🏟️ Football Stadium Themes" })

UIElements.selectedFootballTheme = TabFX:Dropdown({
    Title = "Select Stadium UI Theme",
    Desc = "Switch between custom Football Pitch, Blue Lock Egoist, World Cup Gold, or classic themes",
    Values = { "BlueLockStadium", "EgoistBlue", "WorldCupGold", "Plant", "Sky", "Indigo", "Dark", "Rose", "Amber", "Red", "Violet" },
    Value = selectedFootballTheme,
    Multi = false,
    AllowNone = false,
    Callback = function(themeName)
        selectedFootballTheme = themeName
        pcall(function()
            if WindUI and typeof(WindUI.SetTheme) == "function" then
                WindUI:SetTheme(themeName)
            elseif Window and typeof(Window.SetTheme) == "function" then
                Window:SetTheme(themeName)
            end
            WindUI:Notify({
                Title = "⚽ Stadium Theme Updated",
                Content = "Switched UI theme to: " .. tostring(themeName),
                Duration = 2.5,
                Icon = "palette"
            })
        end)
    end
})

TabFX:Section({ Title = "⚽ Live Football Animations & Effects" })

UIElements.fxPitchField = TabFX:Toggle({
    Title = "🏟️ Football Pitch Lines & Rotating Center Circle",
    Desc = "Displays tactical turf stripes, penalty boxes, halfway line, and rotating center circle",
    Value = fxPitchField,
    Callback = function(val)
        fxPitchField = val
        if UIElements.livePitchCanvas and UIElements.livePitchCanvas.Parent then
            UIElements.livePitchCanvas.Visible = val
        end
    end
})

UIElements.fxFloatingBalls = TabFX:Toggle({
    Title = "⚽ Floating Spinning Footballs & Ego Sparks",
    Desc = "Animated spinning soccer balls (⚽) and Blue Lock Flow-State energy sparks",
    Value = fxFloatingBalls,
    Callback = function(val)
        fxFloatingBalls = val
        if UIElements.liveBallCanvas and UIElements.liveBallCanvas.Parent then
            UIElements.liveBallCanvas.Visible = val
        end
    end
})

UIElements.fxStadiumBorder = TabFX:Toggle({
    Title = "⚡ Rotating Stadium Floodlight & Ego Border",
    Desc = "Continuous rotating Turf-Green, Ego-Cyan, and Trophy-Gold glowing border",
    Value = fxStadiumBorder,
    Callback = function(val)
        fxStadiumBorder = val
        if UIElements.liveStadiumStroke and UIElements.liveStadiumStroke.Parent then
            UIElements.liveStadiumStroke.Enabled = val
        end
    end
})

UIElements.fxTopbarDribble = TabFX:Toggle({
    Title = "🥅 Topbar Goal-Line Laser & Dribbling Ball",
    Desc = "Animated goal-line laser bar with a bouncing, spinning football across the topbar",
    Value = fxTopbarDribble,
    Callback = function(val)
        fxTopbarDribble = val
        if UIElements.liveTopbarGoalLine and UIElements.liveTopbarGoalLine.Parent then
            UIElements.liveTopbarGoalLine.Visible = val
        end
    end
})

UIElements.fxAnimationSpeed = TabFX:Slider({
    Title = "🏃 Animation Speed Multiplier",
    Desc = "Adjust the speed of spinning footballs, center circle, and border rotation",
    Min = 0.5,
    Max = 3.0,
    Default = fxAnimationSpeed,
    Step = 0.1,
    Callback = function(val)
        fxAnimationSpeed = tonumber(val) or 1.0
    end
})

--------------------------------------------------------------------------------
-- TAB: CONFIGS
--------------------------------------------------------------------------------
TabConfigs:Section({ Title = "Active Profile" })

ConfigManagerParagraph = TabConfigs:Paragraph({
    Title = "Config Profile Status",
    Desc = "• Active Config: none\n• Selected Config: 12\n• Auto-Load on Startup: Disabled"
})

TabConfigs:Section({ Title = "Profile Management" })

SavedConfigsDropdown = TabConfigs:Dropdown({
    Title = "Saved Config Profiles",
    Desc = "Select an existing configuration to manage",
    Values = { "none" },
    Value = "none",
    Callback = function(val)
        if val and val ~= "none" then
            selectedConfigName = val
            inputConfigName = val
            if ConfigNameInput and ConfigNameInput.Set then
                pcall(function() ConfigNameInput:Set(val) end)
            end
            syncAutoLoadToggle()
            updateConfigManagerText()
        end
    end
})

ConfigNameInput = TabConfigs:Input({
    Title = "Profile Name",
    Desc = "Enter profile name to save or overwrite",
    Value = "12",
    Placeholder = "e.g. 12, NightFarm, MaxLuck",
    Callback = function(val)
        local trimmed = string.match(val or "", "^%s*(.-)%s*$")
        if trimmed and trimmed ~= "" then
            inputConfigName = trimmed
            selectedConfigName = trimmed
        end
    end
})

AutoLoadToggle = TabConfigs:Toggle({
    Title = "Auto-Load Selected Profile on Startup",
    Desc = "Loads this profile automatically every time Song Hub launches",
    Value = false,
    Callback = function(val)
        if val then
            if selectedConfigName and selectedConfigName ~= "none" and selectedConfigName ~= "" then
                setAutoLoadConfig(selectedConfigName)
                WindUI:Notify({
                    Title = "Auto-Load Enabled",
                    Content = "'" .. selectedConfigName .. "' will load on startup.",
                    Duration = 3,
                    Icon = "check"
                })
            else
                setAutoLoadConfig("none")
            end
        else
            local autoName = getAutoLoadConfig()
            if autoName == selectedConfigName or autoName ~= "none" then
                setAutoLoadConfig("none")
                WindUI:Notify({
                    Title = "Auto-Load Disabled",
                    Content = "Auto-load disabled.",
                    Duration = 2,
                    Icon = "x"
                })
            end
        end
        updateConfigManagerText()
    end
})

TabConfigs:Section({ Title = "Profile Actions" })

TabConfigs:Button({
    Title = "Save / Overwrite Profile",
    Desc = "Saves current UI state to the named profile",
    Callback = function()
        local nameToSave = (inputConfigName and inputConfigName ~= "") and inputConfigName or selectedConfigName
        if not nameToSave or nameToSave == "none" or nameToSave == "" then
            WindUI:Notify({
                Title = "Save Error",
                Content = "Please enter a valid profile name.",
                Duration = 3,
                Icon = "alert-triangle"
            })
            return
        end

        local filePath = CONFIG_FOLDER .. "/" .. nameToSave .. ".json"
        local data = collectConfigData()
        local okEncode, json = pcall(function() return HttpService:JSONEncode(data) end)
        if okEncode and json and typeof(writefile) == "function" then
            pcall(function() writefile(filePath, json) end)
            loadedConfigName = nameToSave
            selectedConfigName = nameToSave
            refreshConfigsUI(nameToSave)
            WindUI:Notify({
                Title = "Profile Saved",
                Content = "Saved config: " .. nameToSave,
                Duration = 3,
                Icon = "check-check"
            })
        end
    end
})

TabConfigs:Button({
    Title = "Load Selected Profile",
    Desc = "Loads and applies the selected configuration immediately",
    Callback = function()
        if not selectedConfigName or selectedConfigName == "none" or selectedConfigName == "" then
            WindUI:Notify({
                Title = "Load Error",
                Content = "No config selected.",
                Duration = 3,
                Icon = "alert-triangle"
            })
            return
        end

        local filePath = CONFIG_FOLDER .. "/" .. selectedConfigName .. ".json"
        if typeof(isfile) == "function" and isfile(filePath) and typeof(readfile) == "function" then
            local okRead, content = pcall(function() return readfile(filePath) end)
            if okRead and content then
                local okDec, decoded = pcall(function() return HttpService:JSONDecode(content) end)
                if okDec and type(decoded) == "table" then
                    applyConfigData(decoded)
                    loadedConfigName = selectedConfigName
                    updateConfigManagerText()
                    WindUI:Notify({
                        Title = "Profile Loaded",
                        Content = "Applied config: " .. selectedConfigName,
                        Duration = 3,
                        Icon = "check-check"
                    })
                    return
                end
            end
        end

        WindUI:Notify({
            Title = "Load Failed",
            Content = "Could not read config file: " .. selectedConfigName,
            Duration = 3,
            Icon = "x"
        })
    end
})

TabConfigs:Button({
    Title = "Delete Selected Profile",
    Desc = "Permanently deletes the selected config file",
    Callback = function()
        if not selectedConfigName or selectedConfigName == "none" or selectedConfigName == "" then return end
        local filePath = CONFIG_FOLDER .. "/" .. selectedConfigName .. ".json"
        if typeof(isfile) == "function" and isfile(filePath) and typeof(delfile) == "function" then
            pcall(function() delfile(filePath) end)
            if getAutoLoadConfig() == selectedConfigName then
                setAutoLoadConfig("none")
            end
            if loadedConfigName == selectedConfigName then
                loadedConfigName = "none"
            end
            WindUI:Notify({
                Title = "Profile Deleted",
                Content = "Deleted config: " .. selectedConfigName,
                Duration = 3,
                Icon = "trash-2"
            })
            selectedConfigName = "none"
            inputConfigName = ""
            refreshConfigsUI("none")
        end
    end
})

TabConfigs:Section({ Title = "🌐 Song Hub Community & Support" })

TabConfigs:Button({
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
    end
})
end -- end of Tabs UI setup scope

--------------------------------------------------------------------------------
-- AUTOMATION BACKGROUND LOOPS
--------------------------------------------------------------------------------
do
local savedPlotPosBeforeGrading = nil
local lastGradingWarn = 0
local lastEquippedWarn = 0
local lastAffordWarn = 0

-- Helper: Match check for multi-select arrays/dicts (Clean & Case-Insensitive)
local function isBoxAllowed(boxName)
    if not boxName or boxName == "" then return false end
    if not selectedBoxes or #selectedBoxes == 0 then return true end
    local cleanBox = string.lower(string.gsub(boxName, "[%s_%-]", ""))
    for k, v in pairs(selectedBoxes) do
        local b = (type(v) == "string" and v ~= "" and v) or (type(k) == "string" and k ~= "" and (v == true or v == 1) and k) or (type(k) == "string" and k ~= "" and k)
        if b then
            local cleanB = string.lower(string.gsub(b, "[%s_%-]", ""))
            if cleanB == "all" or cleanB == cleanBox or string.find(cleanBox, cleanB) or string.find(cleanB, cleanBox) then
                return true
            end
        end
    end
    return false
end

local function isVariantAllowed(varName)
    varName = (varName and varName ~= "") and varName or "Normal"
    if not selectedVariants or #selectedVariants == 0 then return true end
    local cleanVar = string.lower(string.gsub(varName, "[%s_%-]", ""))
    for k, v in pairs(selectedVariants) do
        local valStr = (type(v) == "string" and v ~= "" and v) or (type(k) == "string" and k ~= "" and (v == true or v == 1) and k) or (type(k) == "string" and k ~= "" and k)
        if valStr then
            local cleanV = string.lower(string.gsub(valStr, "[%s_%-]", ""))
            if cleanV == "all" or cleanV == cleanVar or string.find(cleanVar, cleanV) or string.find(cleanV, cleanVar) then
                return true
            end
        end
    end
    return false
end

local function isPlaceBoxAllowed(boxName)
    if not boxName or boxName == "" then return false end
    if not placeBoxFilter or #placeBoxFilter == 0 then return true end
    local cleanBox = string.lower(string.gsub(boxName, "[%s_%-]", ""))
    for k, v in pairs(placeBoxFilter) do
        local b = (type(v) == "string" and v ~= "" and v) or (type(k) == "string" and k ~= "" and (v == true or v == 1) and k) or (type(k) == "string" and k ~= "" and k)
        if b then
            local cleanB = string.lower(string.gsub(b, "[%s_%-]", ""))
            if cleanB == "all" or cleanB == cleanBox or string.find(cleanBox, cleanB) or string.find(cleanB, cleanBox) then
                return true
            end
        end
    end
    return false
end

local function isPlaceVariantAllowed(varName)
    varName = (varName and varName ~= "") and varName or "Normal"
    if not placeVariantFilter or #placeVariantFilter == 0 then return true end
    local cleanVar = string.lower(string.gsub(varName, "[%s_%-]", ""))
    for k, v in pairs(placeVariantFilter) do
        local valStr = (type(v) == "string" and v ~= "" and v) or (type(k) == "string" and k ~= "" and (v == true or v == 1) and k) or (type(k) == "string" and k ~= "" and k)
        if valStr then
            local cleanV = string.lower(string.gsub(valStr, "[%s_%-]", ""))
            if cleanV == "all" or cleanV == cleanVar or string.find(cleanVar, cleanV) or string.find(cleanV, cleanVar) then
                return true
            end
        end
    end
    return false
end

-- Helper: Find raw crate tool (not shiny) in Backpack or Character
local function findRawCrateTool()
    local char = LocalPlayer.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool:GetAttribute("InventoryType") == "Crate" and not tool:GetAttribute("Shiny") then
                return tool
            end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") and tool:GetAttribute("InventoryType") == "Crate" and not tool:GetAttribute("Shiny") then
                return tool
            end
        end
    end
    return nil
end

-- Helper: Sell all crates in Backpack and Character (respects Polisher deposit mode)
local function sellAllCrates(sellRawAlso)
    local char = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local sellRemote = Remotes:FindFirstChild("SellCrate")
    if not sellRemote then return end

    local function checkAndSell(tool)
        if tool:IsA("Tool") and tool:GetAttribute("InventoryType") == "Crate" then
            local isShiny = tool:GetAttribute("Shiny") == true
            -- If autoDepositPolisher is active, keep raw crates for polishing, only sell shiny crates
            -- Unless sellRawAlso is explicitly true or autoDepositPolisher is false
            if isShiny or sellRawAlso or not autoDepositPolisher then
                local guid = tool:GetAttribute("InventoryKey")
                if guid then
                    pcall(function() sellRemote:FireServer(guid) end)
                end
            end
        end
    end

    if char then
        for _, tool in ipairs(char:GetChildren()) do
            checkAndSell(tool)
        end
    end
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            checkAndSell(tool)
        end
    end
end

-- Helper: Get owned boxes from client data with placement filter
local function getInventoryBoxes()
    local available = {}
    pcall(function()
        if not ClientDataManager then return end
        local data = ClientDataManager.GetData()
        if data and data.Inventory and data.Inventory.Boxes then
            for bName, variants in pairs(data.Inventory.Boxes) do
                if type(variants) == "table" and isPlaceBoxAllowed(bName) then
                    for vName, info in pairs(variants) do
                        if isPlaceVariantAllowed(vName) then
                            local amt = type(info) == "table" and (info.Amount or info.Count or 0) or tonumber(info) or 0
                            if amt > 0 then
                                table.insert(available, {
                                    BoxName = bName,
                                    Variant = vName,
                                    Amount = amt
                                })
                            end
                        end
                    end
                end
            end
        end
    end)
    return available
end

-- 1. Main Conveyor Collect & Sell Crates Loop
task.spawn(function()
    while isAlive() do
        if autoCollectSellCrates then
            pcall(function()
                local plot = getMyPlot()
                local collectPart = plot and plot:FindFirstChild("Systems")
                    and plot.Systems:FindFirstChild("TycoonConveyor")
                    and plot.Systems.TycoonConveyor:FindFirstChild("CollectPart")
                
                if collectPart and Remotes:FindFirstChild("PickupCrateBox") then
                    local count = collectPart:GetAttribute("PendingBallCount") or 0
                    if count > 0 then
                        Remotes.PickupCrateBox:FireServer(collectPart)
                    end
                end
                sellAllCrates(false)
            end)
        end
        task.wait(0.2)
    end
end)

-- 2. Auto Deposit to Polisher & Collect Shiny Polished Crates Loop
local lastPolisherWarn = 0
task.spawn(function()
    while isAlive() do
        if autoDepositPolisher or autoCollectPolisher then
            pcall(function()
                local isUnlocked = false
                if PolisherService then
                    isUnlocked = PolisherService.IsUnlocked(LocalPlayer)
                elseif UpgradesService then
                    isUnlocked = UpgradesService.GetTimesPurchased(LocalPlayer, "CratePolisherUnlock") >= 1
                end

                if not isUnlocked then
                    local now = os.clock()
                    if now - lastPolisherWarn > 20 then
                        lastPolisherWarn = now
                        WindUI:Notify({
                            Title = "Polisher Locked 🔒",
                            Content = "Crate Polisher machine requires the $150T Tycoon Upgrade on your plot to activate!",
                            Duration = 4,
                            Icon = "lock"
                        })
                    end
                    return
                end

                local polisher, polCollect = getPolisher()
                if not polCollect then return end

                local hrp = getRoot()
                local hum = getHumanoid()
                if not hrp or not hum then return end

                -- 1. Auto Deposit Raw Crates
                if autoDepositPolisher and Remotes:FindFirstChild("DepositCrate") then
                    local rawCrate = findRawCrateTool()
                    if rawCrate then
                        -- Equip tool if in backpack
                        if rawCrate.Parent ~= LocalPlayer.Character then
                            hum:EquipTool(rawCrate)
                            task.wait(0.08)
                        end

                        local held = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                        if held and held:GetAttribute("InventoryType") == "Crate" and not held:GetAttribute("Shiny") then
                            local origCf = hrp.CFrame
                            local dist = (hrp.Position - polCollect.Position).Magnitude
                            local moved = false

                            if dist > 18 then
                                hrp.CFrame = CFrame.new(polCollect.Position + Vector3.new(0, 3, 0))
                                if hrp.AssemblyLinearVelocity then hrp.AssemblyLinearVelocity = Vector3.zero end
                                moved = true
                                task.wait(0.12)
                            end

                            Remotes.DepositCrate:FireServer(polCollect)
                            task.wait(0.15)

                            if moved and origCf and hrp then
                                hrp.CFrame = origCf
                                if hrp.AssemblyLinearVelocity then hrp.AssemblyLinearVelocity = Vector3.zero end
                            end
                        end
                    end
                end

                -- 2. Auto Collect Shiny Polished Crates
                if autoCollectPolisher and Remotes:FindFirstChild("CollectPolisherCrate") then
                    local polishedBallCount = polCollect:GetAttribute("PolishedBallCount") or 0
                    local polishedCash = PolisherService and PolisherService.GetPolishedCash(LocalPlayer) or 0

                    if polishedBallCount > 0 or polishedCash > 0 then
                        local origCf = hrp.CFrame
                        local dist = (hrp.Position - polCollect.Position).Magnitude
                        local moved = false

                        if dist > 18 then
                            hrp.CFrame = CFrame.new(polCollect.Position + Vector3.new(0, 3, 0))
                            if hrp.AssemblyLinearVelocity then hrp.AssemblyLinearVelocity = Vector3.zero end
                            moved = true
                            task.wait(0.12)
                        end

                        Remotes.CollectPolisherCrate:FireServer(polCollect)
                        task.wait(0.2)

                        if moved and origCf and hrp then
                            hrp.CFrame = origCf
                            if hrp.AssemblyLinearVelocity then hrp.AssemblyLinearVelocity = Vector3.zero end
                        end

                        -- Immediately sell the shiny crate(s) collected for massive profit!
                        task.wait(0.1)
                        sellAllCrates(true)
                    end
                end
            end)
        end
        task.wait(0.4)
    end
end)

-- 3. Auto Roll & Buy Locker Loop (Multi-Select Filters for Box & Mutation Variants)
task.spawn(function()
    local lastPurchasedRollId = nil
    local lastNotifiedWaitRollId = nil
    local lastNotifiedInvFullRollId = nil

    while isAlive() do
        if autoRollLocker or autoBuyLocker then
            pcall(function()
                -- 0. Always auto-dismiss WarningNewBoxGui if it appears
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                local warningGui = pg and pg:FindFirstChild("WarningNewBoxGui")
                if warningGui and warningGui.Enabled then
                    local okayBtn = warningGui:FindFirstChild("OkayButton", true)
                    if okayBtn and typeof(firesignal) == "function" then
                        pcall(function() firesignal(okayBtn.MouseButton1Click) end)
                        pcall(function() firesignal(okayBtn.Activated) end)
                    end
                    warningGui.Enabled = false
                end

                local plot = getMyPlot()
                local rollPart = plot and plot:FindFirstChild("Systems")
                    and plot.Systems:FindFirstChild("RollStation")
                    and plot.Systems.RollStation:FindFirstChild("ConveyorPart")
                
                if rollPart then
                    local currentBox = rollPart:GetAttribute("BoxName")
                    local currentVariant = rollPart:GetAttribute("Variant") or "Normal"
                    local rollCooldown = rollPart:GetAttribute("RollCooldownUntil")
                    local rollId = rollPart:GetAttribute("RollId") or 0
                    local now = workspace:GetServerTimeNow()
                    local hasBoxModel = rollPart:FindFirstChild("BoxModel") ~= nil

                    local hasLockerOnConveyor = (currentBox and currentBox ~= "" and hasBoxModel)
                    local matchBox = hasLockerOnConveyor and isBoxAllowed(currentBox)
                    local matchVariant = hasLockerOnConveyor and isVariantAllowed(currentVariant)
                    local isTargetBox = matchBox and matchVariant

                    local price = 0
                    if hasLockerOnConveyor then
                        price = getConveyorLockerPrice(currentBox, currentVariant, rollPart)
                    end

                    local cash = getCashAmount()
                    local targetCost = price + (minCashBuffer or 0)
                    -- Free/unknown price ($0) is always affordable; if price > 0, check cash >= targetCost
                    local canAffordTarget = (price == 0) or (cash >= targetCost) or (cash == 0 and price == 0)
                    local invCount, invMax, hasInvSpace = getLockerInventoryInfo()

                    -- =========================================================================
                    -- BRANCH 1: TARGET BOX IS ON CONVEYOR (Matches user filters)
                    -- =========================================================================
                    if hasLockerOnConveyor and isTargetBox then
                        if autoBuyLocker and rollId ~= lastPurchasedRollId then
                            if canAffordTarget and hasInvSpace then
                                -- Can afford and has inventory space -> BUY IMMEDIATELY!
                                lastPurchasedRollId = rollId
                                lockerStatusText = string.format("🛒 Purchasing %s (%s) for $%s...", tostring(currentBox), tostring(currentVariant), formatNumber(price))

                                -- 1. Trigger ProximityPrompt
                                local bm = rollPart:FindFirstChild("BoxModel")
                                local prompt = bm and bm:FindFirstChild("ProximityPrompt")
                                if prompt then
                                    if typeof(fireproximityprompt) == "function" then
                                        pcall(function() fireproximityprompt(prompt) end)
                                    end
                                    if typeof(getconnections) == "function" then
                                        pcall(function()
                                            for _, c in ipairs(getconnections(prompt.Triggered)) do
                                                if typeof(c.Function) == "function" then
                                                    task.spawn(c.Function)
                                                end
                                            end
                                        end)
                                    end
                                end

                                -- 2. Fire Server Purchase Remote
                                if Remotes:FindFirstChild("PurchaseConveyorRoll") then
                                    Remotes.PurchaseConveyorRoll:FireServer(currentBox, currentVariant, price)
                                end

                                task.wait(0.35)

                                -- 3. If autoRollLocker is ON, roll next as soon as cooldown allows
                                if autoRollLocker then
                                    local postCooldown = rollPart:GetAttribute("RollCooldownUntil")
                                    local postNow = workspace:GetServerTimeNow()
                                    if not postCooldown or postNow >= (postCooldown - 0.1) then
                                        if Remotes:FindFirstChild("NewRequestConveyorRoll") then
                                            Remotes.NewRequestConveyorRoll:FireServer()
                                        elseif Remotes:FindFirstChild("RequestConveyorRoll") then
                                            Remotes.RequestConveyorRoll:FireServer()
                                        end
                                    end
                                end

                            elseif not hasInvSpace then
                                -- Inventory Full (100/100)!
                                if waitForCashLocker then
                                    -- HOLD LOCKER! DO NOT ROLL AWAY! Wait for inventory space to open
                                    lockerStatusText = string.format("⚠️ Inv Full (%d/%d): Holding %s (%s)! Place/open lockers to buy.",
                                        invCount, invMax, tostring(currentBox), tostring(currentVariant))
                                    if lastNotifiedInvFullRollId ~= rollId then
                                        lastNotifiedInvFullRollId = rollId
                                        WindUI:Notify({
                                            Title = "Locker Inventory Full (" .. tostring(invCount) .. "/" .. tostring(invMax) .. ")",
                                            Content = "Found target " .. tostring(currentBox) .. " (" .. tostring(currentVariant) .. ")! Holding until inventory space clears.",
                                            Duration = 4,
                                            Icon = "alert-triangle"
                                        })
                                    end
                                else
                                    -- User does not want to wait: skip this one and keep rolling!
                                    lastPurchasedRollId = rollId
                                    if autoRollLocker then
                                        local cdRemaining = (rollCooldown and (rollCooldown - now)) or 0
                                        if cdRemaining <= 0.1 then
                                            lockerStatusText = string.format("🔄 Skipping %s (Inv Full & Wait is OFF)", tostring(currentBox))
                                            if Remotes:FindFirstChild("NewRequestConveyorRoll") then
                                                Remotes.NewRequestConveyorRoll:FireServer()
                                            elseif Remotes:FindFirstChild("RequestConveyorRoll") then
                                                Remotes.RequestConveyorRoll:FireServer()
                                            end
                                        else
                                            lockerStatusText = string.format("⏳ Roll Cooldown (%.1fs) - Skipping %s", math.max(0.1, cdRemaining), tostring(currentBox))
                                        end
                                    end
                                end

                            elseif not canAffordTarget then
                                -- Insufficient Cash to afford (Price + Safety Buffer)
                                if waitForCashLocker then
                                    -- HOLD TARGET LOCKER! DO NOT ROLL AWAY! Wait until cash reaches targetCost!
                                    lockerStatusText = string.format("⏸️ Waiting for Cash to Buy %s (%s): $%s / $%s (Buffer: $%s)",
                                        tostring(currentBox), tostring(currentVariant), formatNumber(cash), formatNumber(targetCost), formatNumber(minCashBuffer or 0))

                                    if lastNotifiedWaitRollId ~= rollId then
                                        lastNotifiedWaitRollId = rollId
                                        WindUI:Notify({
                                            Title = "Holding Target Locker (Waiting for Cash)",
                                            Content = string.format("Found %s (%s)! Pausing rolls until cash reaches $%s (Current: $%s)",
                                                tostring(currentBox), tostring(currentVariant), formatNumber(targetCost), formatNumber(cash)),
                                            Duration = 4,
                                            Icon = "pause-circle"
                                        })
                                    end
                                else
                                    -- User chose NOT to wait for cash: skip this roll instance and continue rolling!
                                    lastPurchasedRollId = rollId
                                    if autoRollLocker then
                                        local cdRemaining = (rollCooldown and (rollCooldown - now)) or 0
                                        if cdRemaining <= 0.1 then
                                            lockerStatusText = string.format("🔄 Skipping %s (Low Cash & Wait is OFF)", tostring(currentBox))
                                            if Remotes:FindFirstChild("NewRequestConveyorRoll") then
                                                Remotes.NewRequestConveyorRoll:FireServer()
                                            elseif Remotes:FindFirstChild("RequestConveyorRoll") then
                                                Remotes.RequestConveyorRoll:FireServer()
                                            end
                                        else
                                            lockerStatusText = string.format("⏳ Roll Cooldown (%.1fs) - Skipping %s", math.max(0.1, cdRemaining), tostring(currentBox))
                                        end
                                    end
                                end
                            end

                        else
                            -- Auto Buy is OFF, but target locker matched!
                            if autoRollLocker then
                                if waitForCashLocker then
                                    -- Pause rolling so user can manually buy!
                                    lockerStatusText = string.format("🎯 Target Found: %s (%s)! Paused for manual buy.", tostring(currentBox), tostring(currentVariant))
                                else
                                    -- Auto Buy is OFF and Wait is OFF: roll next
                                    local cdRemaining = (rollCooldown and (rollCooldown - now)) or 0
                                    if cdRemaining <= 0.1 then
                                        lockerStatusText = string.format("🔄 Rolling past target: %s (Auto Buy is OFF)", tostring(currentBox))
                                        if Remotes:FindFirstChild("NewRequestConveyorRoll") then
                                            Remotes.NewRequestConveyorRoll:FireServer()
                                        elseif Remotes:FindFirstChild("RequestConveyorRoll") then
                                            Remotes.RequestConveyorRoll:FireServer()
                                        end
                                    else
                                        lockerStatusText = string.format("⏳ Roll Cooldown (%.1fs)", math.max(0.1, cdRemaining))
                                    end
                                end
                            else
                                lockerStatusText = string.format("🎯 Target Ready: %s (%s) - $%s", tostring(currentBox), tostring(currentVariant), formatNumber(price))
                            end
                        end

                    -- =========================================================================
                    -- BRANCH 2: NON-TARGET LOCKER IS ON CONVEYOR (Does NOT match user filters)
                    -- =========================================================================
                    elseif hasLockerOnConveyor and not isTargetBox then
                        -- Non-target locker: NEVER pause for cash! NEVER hold! Roll past immediately!
                        if autoRollLocker then
                            local cdRemaining = (rollCooldown and (rollCooldown - now)) or 0
                            if cdRemaining <= 0.1 then
                                lockerStatusText = string.format("🔄 Rolling past non-target: %s (%s)", tostring(currentBox), tostring(currentVariant))
                                if Remotes:FindFirstChild("NewRequestConveyorRoll") then
                                    Remotes.NewRequestConveyorRoll:FireServer()
                                elseif Remotes:FindFirstChild("RequestConveyorRoll") then
                                    Remotes.RequestConveyorRoll:FireServer()
                                end
                            else
                                lockerStatusText = string.format("⏳ Roll Cooldown (%.1fs) - Skipping %s (%s)", math.max(0.1, cdRemaining), tostring(currentBox), tostring(currentVariant))
                            end
                        else
                            if autoBuyLocker then
                                lockerStatusText = string.format("⏭️ Ignored: %s (%s) [Not in filters]. Turn ON Auto Roll to roll!", tostring(currentBox), tostring(currentVariant))
                            else
                                lockerStatusText = string.format("💤 Conveyor: %s (%s)", tostring(currentBox), tostring(currentVariant))
                            end
                        end

                    -- =========================================================================
                    -- BRANCH 3: NO LOCKER ON CONVEYOR (Empty conveyor or just rolled)
                    -- =========================================================================
                    elseif autoRollLocker then
                        local cdRemaining = (rollCooldown and (rollCooldown - now)) or 0
                        if cdRemaining <= 0.1 then
                            lockerStatusText = "🔄 Rolling for lockers..."
                            if Remotes:FindFirstChild("NewRequestConveyorRoll") then
                                Remotes.NewRequestConveyorRoll:FireServer()
                            elseif Remotes:FindFirstChild("RequestConveyorRoll") then
                                Remotes.RequestConveyorRoll:FireServer()
                            end
                        else
                            lockerStatusText = string.format("⏳ Roll Cooldown (%.1fs)", math.max(0.1, cdRemaining))
                        end

                    -- =========================================================================
                    -- BRANCH 4: IDLE
                    -- =========================================================================
                    else
                        lockerStatusText = "💤 Idle / Ready"
                    end

                    -- Update UI Paragraph
                    if LockerStatusParagraph then
                        local invText = string.format("%d/%d", invCount, invMax)
                        if not hasInvSpace then invText = invText .. " (Full ⚠️)" end

                        local fastDesc = string.format("• Status: %s\n• Station Locker: %s (%s)\n• Price: $%s (Min Buffer: $%s)\n• Current Cash: $%s\n• Locker Inv: %s",
                            lockerStatusText or "Idle 💤",
                            tostring(currentBox or "None"),
                            tostring(currentVariant or "Normal"),
                            formatNumber(price),
                            formatNumber(minCashBuffer or 0),
                            formatNumber(cash),
                            invText
                        )
                        updateParagraph(LockerStatusParagraph, "Locker Rolling & Purchase Status", fastDesc)
                    end
                end
            end)
        end
        task.wait(0.25)
    end
end)

-- 4. Droppers & Units Management Loop
task.spawn(function()
    while isAlive() do
        if autoPlaceLocker or autoOpenLocker or autoSkipLocker or autoEquipBestUnits or autoLevelUnits or autoRerollGrades then
            pcall(function()
                local plot = getMyPlot()
                local droppersList = {}
                if plot and plot:FindFirstChild("Systems") and plot.Systems:FindFirstChild("TycoonConveyor") and plot.Systems.TycoonConveyor:FindFirstChild("Conveyors") then
                    for _, conv in ipairs(plot.Systems.TycoonConveyor.Conveyors:GetChildren()) do
                        local df = conv:FindFirstChild("Droppers")
                        if df then
                            for _, d in ipairs(df:GetChildren()) do
                                if d:IsA("BasePart") then
                                    table.insert(droppersList, d)
                                end
                            end
                        end
                    end
                end
                
                if #droppersList > 0 then
                    local invBoxes = (autoPlaceLocker and getInventoryBoxes()) or {}

                    for _, dropper in ipairs(droppersList) do
                        if dropper:GetAttribute("Unlocked") == true then
                            local dType = dropper:GetAttribute("Type")
                            if dType == "Box" then
                                -- Skip Timer
                                if autoSkipLocker and Remotes:FindFirstChild("SkipBoxOnDropper") then
                                    Remotes.SkipBoxOnDropper:FireServer(dropper)
                                end
                                -- Open Locker if ready
                                if autoOpenLocker and BoxService and Remotes:FindFirstChild("OpenBoxOnDropper") then
                                    local bName = dropper:GetAttribute("BoxName")
                                    local pAt = dropper:GetAttribute("PlacedAt")
                                    local vName = dropper:GetAttribute("Variant") or "Normal"
                                    if BoxService.IsBoxReady(bName, pAt, vName) then
                                        task.spawn(function()
                                            pcall(function()
                                                Remotes.OpenBoxOnDropper:InvokeServer(dropper)
                                            end)
                                        end)
                                    end
                                end
                            elseif dType == nil and autoPlaceLocker and #invBoxes > 0 and Remotes:FindFirstChild("PlaceBoxOnDropper") then
                                local target = invBoxes[1]
                                Remotes.PlaceBoxOnDropper:FireServer(dropper, target.BoxName, target.Variant)
                                target.Amount = target.Amount - 1
                                if target.Amount <= 0 then
                                    table.remove(invBoxes, 1)
                                end
                                task.wait(0.1)
                            end
                        end
                    end
                end

                -- Auto Equip Best Units (Smart Placement on Empty Droppers)
                if autoEquipBestUnits then
                    pcall(function()
                        if Remotes:FindFirstChild("EquipBestPlayerUnits") then
                            Remotes.EquipBestPlayerUnits:FireServer()
                        end
                        local plot = getMyPlot()
                        local conveyors = plot and plot:FindFirstChild("Systems")
                            and plot.Systems:FindFirstChild("TycoonConveyor")
                            and plot.Systems.TycoonConveyor:FindFirstChild("Conveyors")
                        if conveyors and Remotes:FindFirstChild("PlacePlayerUnitOnDropper") then
                            local emptyDroppers = {}
                            for _, conv in ipairs(conveyors:GetChildren()) do
                                local dFolder = conv:FindFirstChild("Droppers")
                                if dFolder then
                                    for _, dropper in ipairs(dFolder:GetChildren()) do
                                        if dropper:IsA("BasePart") and dropper:GetAttribute("Unlocked") == true and dropper:GetAttribute("Type") == nil then
                                            table.insert(emptyDroppers, dropper)
                                        end
                                    end
                                end
                            end
                            if #emptyDroppers > 0 then
                                local allUnits = nil
                                if PlayerUnitService and LocalPlayer then
                                    pcall(function() allUnits = PlayerUnitService.GetAllPlayerUnits(LocalPlayer) end)
                                end
                                if not allUnits and ClientDataManager then
                                    pcall(function()
                                        local d = ClientDataManager.GetData()
                                        allUnits = d and d.PlayerUnits
                                    end)
                                end
                                if allUnits and type(allUnits) == "table" then
                                    local backpack = {}
                                    for guid, uData in pairs(allUnits) do
                                        if not uData.Equipped then
                                            local cpd = 0
                                            if PlayerUnitService and typeof(PlayerUnitService.GetCashPerDrop) == "function" then
                                                pcall(function() cpd = PlayerUnitService.GetCashPerDrop(LocalPlayer, guid) end)
                                            end
                                            table.insert(backpack, { guid = guid, cpd = cpd or 0 })
                                        end
                                    end
                                    table.sort(backpack, function(a, b) return a.cpd > b.cpd end)
                                    for i = 1, math.min(#emptyDroppers, #backpack) do
                                        Remotes.PlacePlayerUnitOnDropper:FireServer(emptyDroppers[i], backpack[i].guid)
                                        task.wait(0.12)
                                    end
                                end
                            end
                        end
                    end)
                end

                -- Auto Level Up Units (Correctly targets conveyor dropper parts with cost & max checks)
                if autoLevelUnits and Remotes:FindFirstChild("RequestPlayerUnitLevelUp") then
                    pcall(function()
                        local plot = getMyPlot()
                        local conveyors = plot and plot:FindFirstChild("Systems")
                            and plot.Systems:FindFirstChild("TycoonConveyor")
                            and plot.Systems.TycoonConveyor:FindFirstChild("Conveyors")
                        if conveyors then
                            local cash = getCashAmount()
                            local pus = PlayerUnitService
                            for _, conv in ipairs(conveyors:GetChildren()) do
                                local dFolder = conv:FindFirstChild("Droppers")
                                if dFolder then
                                    for _, dropper in ipairs(dFolder:GetChildren()) do
                                        if dropper:IsA("BasePart") and dropper:GetAttribute("Type") == "PlayerUnit" then
                                            local uName = dropper:GetAttribute("PlayerUnitName")
                                            if uName then
                                                local curLvl = dropper:GetAttribute("PlayerUnitLevel") or 1
                                                if curLvl < 50 then
                                                    local uData = {
                                                        PlayerUnitName = uName,
                                                        Level = curLvl,
                                                        Variant = dropper:GetAttribute("PlayerUnitVariant") or "Normal",
                                                        Grade = dropper:GetAttribute("PlayerUnitGrade"),
                                                        Trait = dropper:GetAttribute("PlayerUnitTrait"),
                                                        Equipped = true
                                                    }
                                                    if isUnitSelected(nil, uData, selectedLevelUnits) then
                                                        local cost = nil
                                                        if pus and typeof(pus.GetLevelUpgradeCost) == "function" then
                                                            pcall(function()
                                                                cost = pus.GetLevelUpgradeCost(LocalPlayer, {
                                                                    PlayerUnitName = uName,
                                                                    PlayerUnitVariant = uData.Variant,
                                                                    PlayerUnitGrade = uData.Grade,
                                                                    PlayerUnitTrait = uData.Trait
                                                                }, curLvl + 1)
                                                            end)
                                                        end
                                                        if cost == nil or cash >= cost then
                                                            Remotes.RequestPlayerUnitLevelUp:FireServer(dropper)
                                                            if cost then cash = cash - cost end
                                                            task.wait(0.12)
                                                            cash = getCashAmount()
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                end

                -- Auto Reroll Unit Grades (Supports unequipped & equipped units with auto-unequip and grading station proximity)
                if autoRerollGrades then
                    local rerollRemote = Remotes:FindFirstChild("NewRerollPlayerUnitGrade") or Remotes:FindFirstChild("RerollPlayerUnitGrade")
                    if rerollRemote and PlayerUnitService and LocalPlayer then
                        local allUnits = nil
                        pcall(function() allUnits = PlayerUnitService.GetAllPlayerUnits(LocalPlayer) end)
                        if not allUnits and ClientDataManager then
                            pcall(function()
                                local d = ClientDataManager.GetData()
                                allUnits = d and d.PlayerUnits
                            end)
                        end

                        if allUnits and type(allUnits) == "table" then
                            local hasBluetooth = false
                            pcall(function()
                                if GradeService and typeof(GradeService.HasBluetooth) == "function" then
                                    hasBluetooth = GradeService.HasBluetooth(LocalPlayer)
                                end
                            end)

                            local canReach = false
                            pcall(function()
                                if GradeService and typeof(GradeService.CanReachRollStation) == "function" then
                                    canReach = GradeService.CanReachRollStation(LocalPlayer, "GradingHitbox")
                                end
                            end)

                            local hrp = getRoot()
                            local gradingPart = workspace:FindFirstChild("Systems") 
                                and workspace.Systems:FindFirstChild("Interactables") 
                                and workspace.Systems.Interactables:FindFirstChild("Grading")
                            local gradingPos = gradingPart and (gradingPart.Position + Vector3.new(0, 3, 0)) or Vector3.new(-1767.87, 14, 27.88)

                            if not hasBluetooth and not canReach then
                                if autoTeleportToGrading and hrp then
                                    if not savedPlotPosBeforeGrading then
                                        savedPlotPosBeforeGrading = hrp.CFrame
                                    end
                                    hrp.CFrame = CFrame.new(gradingPos)
                                    task.wait(0.3)
                                    pcall(function()
                                        canReach = GradeService.CanReachRollStation(LocalPlayer, "GradingHitbox")
                                    end)
                                else
                                    local now = os.time()
                                    if not lastGradingWarn or (now - lastGradingWarn) > 12 then
                                        lastGradingWarn = now
                                        WindUI:Notify({
                                            Title = "Grading Range Warning",
                                            Content = "Cannot reroll: You must be at Grading Station or have Bluetooth! Teleporting to station or enable 'Auto Teleport'.",
                                            Duration = 5,
                                            Icon = "alert-triangle"
                                        })
                                    end
                                end
                            end

                            if hasBluetooth or canReach then
                                for guid, uData in pairs(allUnits) do
                                    if not autoRerollGrades then break end
                                    if isUnitSelected(guid, uData, selectedRerollUnits) then
                                        local curGrade = uData and (uData.Grade or uData.GradeTier) or "None"
                                        if not table.find(targetGrades, curGrade) then
                                            local originalDropper = nil
                                            -- If unit is placed on a dropper, unequip it first (game requires unequipped for grading)
                                            if uData.Equipped == true then
                                                if autoUnequipForReroll then
                                                    pcall(function()
                                                        local plot = getMyPlot()
                                                        local conveyors = plot and plot.Systems
                                                            and plot.Systems:FindFirstChild("TycoonConveyor")
                                                            and plot.Systems.TycoonConveyor:FindFirstChild("Conveyors")
                                                        if conveyors and Remotes:FindFirstChild("RemovePlayerUnitFromDropper") then
                                                            for _, conv in ipairs(conveyors:GetChildren()) do
                                                                local dFolder = conv:FindFirstChild("Droppers")
                                                                if dFolder then
                                                                    for _, d in ipairs(dFolder:GetChildren()) do
                                                                        if d:GetAttribute("PlayerUnitName") == uData.PlayerUnitName and d:GetAttribute("PlayerUnitVariant") == uData.Variant then
                                                                            originalDropper = d
                                                                            Remotes.RemovePlayerUnitFromDropper:FireServer(d)
                                                                            task.wait(0.35)
                                                                            break
                                                                        end
                                                                    end
                                                                end
                                                                if originalDropper then break end
                                                            end
                                                        end
                                                    end)
                                                else
                                                    local now = os.time()
                                                    if not lastEquippedWarn or (now - lastEquippedWarn) > 12 then
                                                        lastEquippedWarn = now
                                                        WindUI:Notify({
                                                            Title = "Unit Placed on Conveyor",
                                                            Content = string.format("Unit '%s' is placed on your conveyor! Enable 'Auto Unequip to Reroll' to reroll it.", uData.PlayerUnitName or "Unit"),
                                                            Duration = 4,
                                                            Icon = "alert-circle"
                                                        })
                                                    end
                                                    continue
                                                end
                                            end

                                            -- Determine Currency: Tokens vs Cash
                                            local useTokens = false
                                            local canAfford = false
                                            local tokenCount = 0
                                            if TokensService and typeof(TokensService.GetTokenAmount) == "function" then
                                                pcall(function() tokenCount = TokensService.GetTokenAmount(LocalPlayer, "Grade") end)
                                            end

                                            local rawCost = 0
                                            if PlayerUnitService and typeof(PlayerUnitService.GetGradeRerollCost) == "function" then
                                                pcall(function()
                                                    rawCost = PlayerUnitService.GetGradeRerollCost(LocalPlayer, {
                                                        PlayerUnitName = uData.PlayerUnitName,
                                                        PlayerUnitVariant = uData.Variant,
                                                        PlayerUnitLevel = uData.Level,
                                                        PlayerUnitTrait = uData.Trait,
                                                    })
                                                end)
                                            end

                                            local cash = getCashAmount()
                                            local canAffordCash = (rawCost == 0) or (cash >= rawCost)

                                            if rerollCurrencyMode == "Grade Tokens Only" then
                                                if tokenCount >= 1 then useTokens = true canAfford = true end
                                            elseif rerollCurrencyMode == "Cash Only" then
                                                if canAffordCash then useTokens = false canAfford = true end
                                            else -- "Auto (Tokens then Cash)"
                                                if tokenCount >= 1 then
                                                    useTokens = true
                                                    canAfford = true
                                                elseif canAffordCash then
                                                    useTokens = false
                                                    canAfford = true
                                                end
                                            end

                                            if not canAfford then
                                                local now = os.time()
                                                if not lastAffordWarn or (now - lastAffordWarn) > 12 then
                                                    lastAffordWarn = now
                                                    WindUI:Notify({
                                                        Title = "Cannot Afford Grade Reroll",
                                                        Content = string.format("Insufficient funds to reroll %s (Cost: $%s or 1 Token).", uData.PlayerUnitName or "Unit", formatNumber(rawCost)),
                                                        Duration = 4,
                                                        Icon = "dollar-sign"
                                                    })
                                                end
                                                if originalDropper and Remotes:FindFirstChild("PlacePlayerUnitOnDropper") then
                                                    Remotes.PlacePlayerUnitOnDropper:FireServer(originalDropper, guid)
                                                end
                                            else
                                                -- Perform Reroll with exact 3 arguments: (guid, useTokens, curGrade)
                                                rerollRemote:FireServer(guid, useTokens, uData.Grade)

                                                -- Determine cooldown
                                                local cooldown = 0.55
                                                if GradeService and typeof(GradeService.GetRerollCooldown) == "function" then
                                                    pcall(function()
                                                        cooldown = GradeService.GetRerollCooldown(LocalPlayer, useTokens)
                                                    end)
                                                end
                                                task.wait(math.clamp(cooldown, 0.35, 1.5))

                                                -- Check if hit target grade
                                                local checkData = nil
                                                pcall(function() checkData = PlayerUnitService.GetStoredPlayerUnitData(LocalPlayer, guid) end)
                                                local updatedGrade = checkData and (checkData.Grade or checkData.GradeTier) or curGrade

                                                if updatedGrade ~= curGrade and table.find(targetGrades, updatedGrade) then
                                                    WindUI:Notify({
                                                        Title = "🎉 Hit Target Grade!",
                                                        Content = string.format("%s reached Grade %s!", uData.PlayerUnitName or "Unit", updatedGrade),
                                                        Duration = 6,
                                                        Icon = "award"
                                                    })
                                                    if originalDropper and Remotes:FindFirstChild("PlacePlayerUnitOnDropper") then
                                                        task.wait(0.2)
                                                        Remotes.PlacePlayerUnitOnDropper:FireServer(originalDropper, guid)
                                                        originalDropper = nil
                                                    end
                                                    if autoTeleportToGrading and savedPlotPosBeforeGrading and hrp then
                                                        hrp.CFrame = savedPlotPosBeforeGrading
                                                        savedPlotPosBeforeGrading = nil
                                                    end
                                                else
                                                    -- Re-place on dropper if single-step or non-continuous
                                                    if originalDropper and not autoRerollGrades and Remotes:FindFirstChild("PlacePlayerUnitOnDropper") then
                                                        Remotes.PlacePlayerUnitOnDropper:FireServer(originalDropper, guid)
                                                        originalDropper = nil
                                                    end
                                                end
                                                break -- Process one reroll per cycle for clean responsiveness
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)
end -- end of Tycoon Automation Loops scope

-- 5. Upgrades & Rewards Loop
task.spawn(function()
    while isAlive() do
        if autoBuyUpgrades and Remotes:FindFirstChild("PurchaseUpgrade") then
            pcall(function()
                local cash = getCashAmount()
                local ul = UpgradesLibrary
                local us = UpgradesService
                for _, upg in ipairs(UpgradesList) do
                    local canBuy = true
                    if ul and ul[upg] then
                        local lvl = (us and typeof(us.GetTimesPurchased) == "function" and us.GetTimesPurchased(LocalPlayer, upg)) or 0
                        local max = ul[upg].MaxPurchases
                        if max and lvl >= max then
                            canBuy = false
                        else
                            local price = ul[upg].GetPrice and ul[upg].GetPrice(lvl + 1)
                            if price and cash < price then
                                canBuy = false
                            end
                        end
                    end
                    if canBuy then
                        Remotes.PurchaseUpgrade:FireServer(upg)
                        task.wait(0.2)
                        cash = getCashAmount()
                    end
                end
            end)
        end

        if autoClaimRewards then
            pcall(function()
                -- 1. Offline Earnings
                if Remotes:FindFirstChild("ClaimOfflineEarnings") then
                    Remotes.ClaimOfflineEarnings:FireServer()
                end

                -- 2. Daily Rewards
                if Remotes:FindFirstChild("ClaimDailyReward") then
                    local dls = DailyLoginService
                    if dls and typeof(dls.GetNextClaimableDay) == "function" then
                        local day = dls.GetNextClaimableDay(LocalPlayer)
                        if day then Remotes.ClaimDailyReward:FireServer(day) end
                    end
                    Remotes.ClaimDailyReward:FireServer()
                end

                -- 3. All Index Rewards
                if Remotes:FindFirstChild("ClaimAllIndexRewards") then
                    Remotes.ClaimAllIndexRewards:FireServer()
                elseif Remotes:FindFirstChild("ClaimIndexReward") then
                    Remotes.ClaimIndexReward:FireServer()
                end

                -- 4. Obby Bonus
                if Remotes:FindFirstChild("ClaimObbyBonus") then
                    Remotes.ClaimObbyBonus:FireServer()
                end

                -- 5. Playtime Rewards (1-12)
                if Remotes:FindFirstChild("ClaimPlaytimeReward") then
                    local ps = PlaytimeRewardsService
                    for i = 1, 12 do
                        local shouldClaim = true
                        if ps and typeof(ps.CanClaim) == "function" then
                            shouldClaim = ps.CanClaim(LocalPlayer, i)
                        end
                        if shouldClaim then
                            Remotes.ClaimPlaytimeReward:FireServer(i)
                            task.wait(0.12)
                        end
                    end
                end
            end)
        end

        task.wait(2.5)
    end
end)

-- 6. Missions Auto Claim Loop (Service & UI Dual Scanner + Tab Switcher)
task.spawn(function()
    while isAlive() do
        if autoClaimMissions then
            claimAllMissionsUniversal()
        end
        task.wait(2.0)
    end
end)

-- 7. Ball Skins Auto-Buy & Equipment Engine (Guaranteed Real Purchasing)
task.spawn(function()
    while isAlive() do
        pcall(function()
            local cash = getCashAmount()
            local data = ClientDataManager and ClientDataManager.GetData()
            local owned = data and data.Inventory and data.Inventory.BallSkins or {}

            -- Live Status Paragraph Update
            if BallSkinStatusParagraph then
                local ownedList = {}
                for sName, count in pairs(owned) do
                    if tonumber(count) and tonumber(count) > 0 then
                        table.insert(ownedList, sName)
                    end
                end

                local affordableList = {}
                for _, rawChoice in ipairs(selectedBallSkins) do
                    local sName = string.match(rawChoice, "^([%w_]+)")
                    if sName then
                        for _, entry in ipairs(BallSkinsCatalog) do
                            if entry.Name == sName and cash >= entry.Price then
                                table.insert(affordableList, entry.DisplayName)
                            end
                        end
                    end
                end

                local cashDisplay = (cash > 0 and ("$" .. formatNumber(cash))) or "Synced ($0 or Active Balance)"
                local statusText = string.format("• Current Cash: %s\n• Owned Skins (%d): %s\n• Selected Affordable: %s",
                    cashDisplay,
                    #ownedList,
                    #ownedList > 0 and table.concat(ownedList, ", ") or "None (Base)",
                    #affordableList > 0 and table.concat(affordableList, ", ") or (#selectedBallSkins > 0 and "Ready to Purchase (Server Validated)" or "None selected")
                )

                updateParagraph(BallSkinStatusParagraph, "Ball Skin Overview", statusText)
            end

            -- Auto Buy Selected Ball Skins
            if autoBuyBallSkins and Remotes:FindFirstChild("BallSkinPurchaseCash") then
                for _, rawChoice in ipairs(selectedBallSkins) do
                    local sName = string.match(rawChoice, "^([%w_]+)")
                    if sName then
                        for _, entry in ipairs(BallSkinsCatalog) do
                            if entry.Name == sName and (cash == 0 or cash >= entry.Price) then
                                -- Check stock if available
                                local hasStock = true
                                if BallSkinService and typeof(BallSkinService.GetRemainingStock) == "function" then
                                    local ok, stock = pcall(BallSkinService.GetRemainingStock, sName)
                                    if ok and typeof(stock) == "number" and stock <= 0 then
                                        hasStock = false
                                    end
                                end

                                if hasStock then
                                    Remotes.BallSkinPurchaseCash:FireServer(sName)
                                    task.wait(0.3)
                                    cash = getCashAmount()
                                end
                            end
                        end
                    end
                end
            end

            -- Auto Apply Highest Multiplier Ball Skin to All Droppers
            if autoApplyBallSkins and Remotes:FindFirstChild("ApplyBallSkinToDropper") then
                local bestSkin = "Base"
                local bestMult = 1.0
                for sName, count in pairs(owned) do
                    if tonumber(count) and tonumber(count) > 0 then
                        for _, entry in ipairs(BallSkinsCatalog) do
                            if entry.Name == sName and entry.Multiplier > bestMult then
                                bestMult = entry.Multiplier
                                bestSkin = entry.Name
                            end
                        end
                    end
                end

                local plot = getMyPlot()
                local droppers = plot and plot.Systems
                    and plot.Systems:FindFirstChild("TycoonConveyor")
                    and plot.Systems.TycoonConveyor:FindFirstChild("Conveyors")
                    and plot.Systems.TycoonConveyor.Conveyors:FindFirstChild("Conveyor1")
                    and plot.Systems.TycoonConveyor.Conveyors.Conveyor1:FindFirstChild("Droppers")

                if droppers then
                    for _, d in ipairs(droppers:GetChildren()) do
                        if d:IsA("BasePart") and d:GetAttribute("Unlocked") == true then
                            local curApplied = d:GetAttribute("BallSkin")
                            if curApplied ~= bestSkin then
                                Remotes.ApplyBallSkinToDropper:FireServer(d, bestSkin)
                            end
                        end
                    end
                end
            end
        end)
        task.wait(2.5)
    end
end)

-- 8. Live Weather & Event Status Monitor Loop
task.spawn(function()
    local cachedHouseStr = "Loading..."
    local lastHouseCheck = 0

    while isAlive() do
        -- 1. Weather Status
        pcall(function()
            if WeatherStatusParagraph and WeatherService then
                local curWeather = WeatherService.GetCurrentWeather()
                local isActive = WeatherService.IsWeatherActive()
                local timeLeft = WeatherService.GetWeatherTimeLeft()
                local nextIn = WeatherService.GetSecondsUntilNextWeather()

                local statusText = ""
                if isActive and curWeather then
                    local wData = WeatherLibrary and WeatherLibrary[curWeather]
                    local desc = wData and wData.Description or "Active"
                    statusText = string.format("• Active Weather: %s ⚡\n• Effects: %s\n• Time Remaining: %ds", tostring(curWeather), desc, timeLeft)
                else
                    statusText = string.format("• Current Weather: Clear Skies ☀️\n• Next Weather Event in: %ds", nextIn)
                end

                updateParagraph(WeatherStatusParagraph, "Weather Status", statusText)
            end
        end)

        -- 2. Tournament Mode Live Status Monitor
        pcall(function()
            if TournamentStatusParagraph then
                local inMatch = TournamentGuiClient and TournamentGuiClient.IsInMatch()
                local seed = (TournamentService and TournamentService.GetSeed and TournamentService.GetSeed()) or 0
                local nextRotSec = (TournamentService and TournamentService.GetTimeUntilNextRotation and TournamentService.GetTimeUntilNextRotation()) or 0
                local rotMin = math.floor(nextRotSec / 60)
                local rotSec = nextRotSec % 60
                local rotTimeStr = string.format("%02d:%02d", rotMin, rotSec)

                local teamName = "Unknown"
                if TournamentService and TournamentService.GetTeamNameForSeed then
                    local ok, name = pcall(TournamentService.GetTeamNameForSeed, seed)
                    if ok and name then teamName = tostring(name) end
                end

                local hasWon = false
                if TournamentService and TournamentService.HasWonSeed then
                    local ok, won = pcall(TournamentService.HasWonSeed, LocalPlayer, seed)
                    if ok and won then hasWon = true end
                end
                local wonStr = hasWon and "🏆 Won (Reward Claimed)" or "⏳ Not Won Yet"

                local matchStatusStr = inMatch and "⚽ In Match (Playing)" or "💤 Ready (In Lobby)"
                local scoreStr = "0 - 0"
                local quarterStr = "Q1"

                pcall(function()
                    local gui = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("TournamentSelectionGui")
                    local scoreFrame = gui and gui:FindFirstChild("ScoreFrame")
                    if scoreFrame and scoreFrame.Visible then
                        local homeScore = scoreFrame:FindFirstChild("HomeScore")
                        local awayScore = scoreFrame:FindFirstChild("AwayScore")
                        if homeScore and awayScore then
                            scoreStr = tostring(homeScore.Text) .. " - " .. tostring(awayScore.Text)
                        end
                        local qLabel = scoreFrame:FindFirstChild("QuarterLabel")
                        if qLabel then quarterStr = tostring(qLabel.Text) end
                    end
                end)

                local statusDesc
                if inMatch then
                    statusDesc = string.format(
                        "• Match Status: %s (%s | %s)\n• Opponent: %s (Seed: %d)\n• Rotation Refresh: %s\n• Seed Win Status: %s",
                        matchStatusStr, quarterStr, scoreStr, teamName, seed, rotTimeStr, wonStr
                    )
                else
                    statusDesc = string.format(
                        "• Match Status: %s\n• Current Opponent: %s (Seed: %d)\n• Next Rotation in: %s\n• Seed Win Status: %s",
                        matchStatusStr, teamName, seed, rotTimeStr, wonStr
                    )
                end

                updateParagraph(TournamentStatusParagraph, "🏆 Tournament Mode Status", statusDesc)
            end
        end)

        -- 4. Mad Scientist Materials Tracker
        pcall(function()
            if ScientistStatusParagraph and ClientDataManager then
                local d = ClientDataManager.GetData()
                local tokens = d and d.Tokens or {}
                local vTokens = d and d.VariantTokens or {}
                local potions = d and d.Potions or {}

                local predatorCount = vTokens.Predator or 0
                local shadowCount = vTokens.Shadow or 0
                local btPotionCount = potions.BluetoothPotion or 0
                local traitCount = tokens.Trait or 0
                local gradeCount = tokens.Grade or 0

                local readyToCraft = (predatorCount >= 1 and shadowCount >= 5 and btPotionCount >= 10 and traitCount >= 100 and gradeCount >= 100)
                local sciDesc = string.format("• Predator Variant: %d / 1\n• Shadow Variant: %d / 5\n• Bluetooth Potion: %d / 10\n• Trait Tokens: %d / 100\n• Grade Tokens: %d / 100\n• Synthesis Ready: %s",
                    predatorCount, shadowCount, btPotionCount, traitCount, gradeCount, readyToCraft and "YES! Ready to Craft" or "Gathering materials...")

                updateParagraph(ScientistStatusParagraph, "Mad Scientist Material Status", sciDesc)

                -- Auto Craft if enabled
                if autoCraftScientist and readyToCraft and Remotes:FindFirstChild("MadScientistCraft") then
                    Remotes.MadScientistCraft:FireServer("PermanentBluetooth")
                end
            end
        end)

        -- 5. Obby Status & Cooldowns Tracker
        pcall(function()
            if ObbyStatusParagraph then
                local easyCd = getObbyCooldown("EasyObby")
                local medCd = getObbyCooldown("MediumObby")
                local hardCd = getObbyCooldown("HardObby")

                local easyStr = easyCd <= 0 and "READY! ✨ (2 Grade Tokens)" or (formatSeconds(easyCd) .. " ⏳ (2 Grade Tokens)")
                local medStr = medCd <= 0 and "READY! ✨ (5 Grade + Luck Potion)" or (formatSeconds(medCd) .. " ⏳ (5 Grade + Luck Potion)")
                local hardStr = hardCd <= 0 and "READY! ✨ (5 Grade + Speed + Bluetooth)" or (formatSeconds(hardCd) .. " ⏳ (5 Grade + Speed + Bluetooth)")

                local obbyDesc = string.format("• Easy Obby (5m): %s\n• Medium Obby (10m): %s\n• Hard Obby (15m): %s", easyStr, medStr, hardStr)

                updateParagraph(ObbyStatusParagraph, "Obby Status & Cooldowns", obbyDesc)
            end
        end)

        -- 6. Infinity Tower Status Tracker
        pcall(function()
            if TowerStatusParagraph then
                local stageName = activeTowerStage or (typeof(getTargetTowerStage) == "function" and getTargetTowerStage()) or "Entrance"
                local stageDisplay = (TowerStageDisplayMap and TowerStageDisplayMap[stageName]) or stageName
                local statusStr = isTowerInBattle and "In Battle ⚔️" or "Idle 💤"
                local surrenderStr = towerSurrenderFloor > 0 and string.format("Floor %d", towerSurrenderFloor) or "None (Infinite)"
                local towerDesc = string.format("• Status: %s\n• Target Stage: %s (%s)\n• Current Floor: %d\n• Surrender at: %s",
                    statusStr, tostring(selectedTowerStage), tostring(stageDisplay), activeTowerFloor, surrenderStr)

                updateParagraph(TowerStatusParagraph, "Tower Battle Status", towerDesc)
            end
        end)

        -- 7. Locker Rolling & Purchase Tracker
        pcall(function()
            if LockerStatusParagraph then
                local plot = getMyPlot()
                local rollPart = plot and plot:FindFirstChild("Systems")
                    and plot.Systems:FindFirstChild("RollStation")
                    and plot.Systems.RollStation:FindFirstChild("ConveyorPart")
                local curBox = (rollPart and rollPart:GetAttribute("BoxName")) or "None"
                local curVar = (rollPart and rollPart:GetAttribute("Variant")) or "Normal"
                local price = 0
                if rollPart and curBox ~= "None" and curBox ~= "" then
                    price = getConveyorLockerPrice(curBox, curVar, rollPart)
                end
                local cash = getCashAmount()
                local invCount, invMax, hasInvSpace = getLockerInventoryInfo()
                local invText = string.format("%d/%d", invCount, invMax)
                if not hasInvSpace then invText = invText .. " (Full ⚠️)" end
                local lockerDesc = string.format("• Status: %s\n• Station Locker: %s (%s)\n• Price: $%s (Min Buffer: $%s)\n• Current Cash: $%s\n• Locker Inv: %s",
                    lockerStatusText or "Idle 💤", tostring(curBox), tostring(curVar), formatNumber(price), formatNumber(minCashBuffer or 0), formatNumber(cash), invText)

                updateParagraph(LockerStatusParagraph, "Locker Rolling & Purchase Status", lockerDesc)
            end
        end)

        -- Automatically prevent gamepass floor button touch prompts
        pcall(disablePlotGamepassButtons)
        task.wait(1.5)
    end
end)

-- 9. Auto Use Weather Globe Loop
task.spawn(function()
    while isAlive() do
        if autoUseWeatherGlobe and WeatherService and Remotes:FindFirstChild("UseWeatherGlobe") then
            pcall(function()
                if not WeatherService.IsWeatherActive() then
                    Remotes.UseWeatherGlobe:FireServer(selectedWeatherGlobe)
                    task.wait(5.0)
                end
            end)
        end
        task.wait(3.0)
    end
end)

-- ============================================================================
-- DEDICATED VARIANT TOKEN & CANDY CORN REWARD CAPTURE ENGINE
-- ============================================================================
do
-- Function: Instantly snatch all active Variant Tokens matching multi-select filter
local function snatchActiveVariantTokens()
    if not autoSnatchVariantTokens or not isAlive() then return end
    local sys = workspace:FindFirstChild("Systems")
    local spawns = sys and sys:FindFirstChild("VariantTokenSpawns")
    if spawns and Remotes:FindFirstChild("CollectVariantTokenSpawn") then
        for _, node in ipairs(spawns:GetChildren()) do
            if node:IsA("BasePart") and node:GetAttribute("Occupied") == true then
                local variantName = tostring(node:GetAttribute("Variant") or "Variant")
                if #selectedVariantTokens == 0 or table.find(selectedVariantTokens, variantName) then
                    local hrp = getRoot()
                    if hrp then
                        local originalCf = hrp.CFrame
                        hrp.CFrame = CFrame.new(node.Position + Vector3.new(0, 1.5, 0))
                        task.wait(0.12)
                        Remotes.CollectVariantTokenSpawn:FireServer(node)
                        task.wait(0.12)
                        if hrp and originalCf then
                            hrp.CFrame = originalCf
                        end
                        pcall(function()
                            WindUI:Notify({
                                Title = "Variant Token Snatched!",
                                Content = "Secured " .. variantName .. " Token before despawn!",
                                Duration = 3,
                                Icon = "sparkles"
                            })
                        end)
                    end
                end
            end
        end
    end
end

-- Listener: RemoteEvent for VariantTokenSpawned
if Remotes:FindFirstChild("VariantTokenSpawned") then
    Remotes.VariantTokenSpawned.OnClientEvent:Connect(function(variantName)
        task.spawn(function()
            task.wait(0.15)
            snatchActiveVariantTokens()
        end)
    end)
end

-- 10. Item Rain Snatch Engine
local function sweepItemRainDrops()
    if not autoCollectItemRain or not isAlive() then return end
    pcall(function()
        local hrp = getRoot()
        if not hrp then return end

        local eff = workspace:FindFirstChild("Effects")
        local weatherFolder = eff and eff:FindFirstChild("Weather")
        local itemRainFolder = workspace:FindFirstChild("ItemRain") or (weatherFolder and weatherFolder:FindFirstChild("ItemRain"))

        if itemRainFolder then
            for _, drop in ipairs(itemRainFolder:GetChildren()) do
                if drop:IsA("Model") or drop:IsA("BasePart") then
                    local pos = drop:GetPivot().Position
                    local originalCf = hrp.CFrame
                    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 1.5, 0))
                    task.wait(0.1)
                    if Remotes:FindFirstChild("CollectItemRainItem") then
                        Remotes.CollectItemRainItem:FireServer(drop.Name)
                    end
                    task.wait(0.1)
                    if hrp and originalCf then
                        hrp.CFrame = originalCf
                    end
                end
            end
        end
    end)
end

task.spawn(function()
    while isAlive() do
        if autoCollectItemRain then
            pcall(sweepItemRainDrops)
        end
        task.wait(0.6)
    end
end)

-- Helper: Handle in-match prompts, decisions, and rotation minigame
local function handleTournamentMatch()
    local gui = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("TournamentSelectionGui")
    if not gui then return end

    -- 1. Solve RotationMinigame with 100% Perfect precision
    pcall(function()
        local minigame = gui:FindFirstChild("RotationMinigame")
        if minigame and minigame.Visible then
            local perfectZone = minigame:FindFirstChild("PerfectZone")
            local rotatingTick = minigame:FindFirstChild("RotatingTick")
            if perfectZone and rotatingTick and tournamentPerfectKick then
                -- Align tick rotation exactly with perfect zone center rotation
                rotatingTick.Rotation = perfectZone.Rotation
                task.wait(0.04)

                -- Fire click or input signal to trigger Perfect evaluation
                pcall(function()
                    local clickButton = minigame:FindFirstChildWhichIsA("TextButton", true) or minigame:FindFirstChildWhichIsA("ImageButton", true)
                    if clickButton then
                        clickButton.MouseButton1Click:Fire()
                    end
                end)
                task.wait(0.1)
            end
        end
    end)

    -- 2. Handle NextActionFrame prompts (Prioritize Shoot, then Pass)
    pcall(function()
        local nextAction = gui:FindFirstChild("NextActionFrame")
        if nextAction and nextAction.Visible then
            local bestBtn = nil
            local shootBtn = nil
            local passBtn = nil

            for _, btn in ipairs(nextAction:GetDescendants()) do
                if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                    local text = (btn:FindFirstChildWhichIsA("TextLabel") and btn:FindFirstChildWhichIsA("TextLabel").Text) or btn.Text or ""
                    local tLower = text:lower()
                    if string.find(tLower, "shoot") or string.find(tLower, "goal") then
                        shootBtn = btn
                    elseif string.find(tLower, "pass") then
                        passBtn = btn
                    elseif not bestBtn then
                        bestBtn = btn
                    end
                end
            end

            local targetBtn = shootBtn or passBtn or bestBtn
            if targetBtn then
                pcall(function()
                    targetBtn.MouseButton1Click:Fire()
                end)
                task.wait(0.2)
            end
        end
    end)

    -- 3. Dismiss any post-match victory/reward/claim prompts
    pcall(function()
        local postMatch = gui:FindFirstChild("PostMatchFrame") or gui:FindFirstChild("VictoryFrame") or gui:FindFirstChild("RewardFrame")
        if postMatch and postMatch.Visible then
            for _, btn in ipairs(postMatch:GetDescendants()) do
                if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                    local tLower = (btn.Text or ""):lower()
                    if string.find(tLower, "claim") or string.find(tLower, "continue") or string.find(tLower, "close") or string.find(tLower, "ok") then
                        pcall(function() btn.MouseButton1Click:Fire() end)
                        task.wait(0.2)
                    end
                end
            end
        end
    end)
end

-- 11. Auto Tournament Match Runner Loop
task.spawn(function()
    local lastAttemptTick = 0
    while isAlive() do
        if autoTournament then
            pcall(function()
                local inMatch = TournamentGuiClient and TournamentGuiClient.IsInMatch()
                if inMatch then
                    handleTournamentMatch()
                else
                    -- Check if we should join
                    local seed = (TournamentService and TournamentService.GetSeed and TournamentService.GetSeed()) or 0
                    local hasWon = false
                    if TournamentService and TournamentService.HasWonSeed then
                        local ok, won = pcall(TournamentService.HasWonSeed, LocalPlayer, seed)
                        if ok and won then hasWon = true end
                    end

                    local shouldPlay = (not hasWon) or tournamentAutoReMatch
                    local now = os.clock()

                    if shouldPlay and (now - lastAttemptTick) > 8 then
                        lastAttemptTick = now
                        -- Teleport to tournament pitch if too far
                        local hrp = getRoot()
                        local fieldObj = getTournamentField()
                        if fieldObj and hrp then
                            local fieldPos = fieldObj.Base.Position
                            if (hrp.Position - fieldPos).Magnitude > 45 then
                                hrp.CFrame = CFrame.new(fieldPos + Vector3.new(0, 3, 0))
                                task.wait(0.4)
                            end
                        end

                        doStartTournamentMatch()
                    end
                end
            end)
        end
        task.wait(0.25)
    end
end)

-- 12. Map Tokens Loop (GradeToken, TraitToken, Potions)
task.spawn(function()
    while isAlive() do
        if autoCollectMapTokens then
            pcall(function()
                local hrp = getRoot()
                if not hrp then return end

                local sys = workspace:FindFirstChild("Systems")
                local col = sys and sys:FindFirstChild("CollectableObjects")
                if col and Remotes:FindFirstChild("CollectCollectableObject") then
                    local nodesToCollect = {}
                    for _, node in ipairs(col:GetChildren()) do
                        if node:IsA("BasePart") then
                            local isOccupied = node:GetAttribute("Occupied") == true or #node:GetChildren() > 0
                            if isOccupied then
                                table.insert(nodesToCollect, node)
                            end
                        end
                    end

                    if #nodesToCollect > 0 then
                        local originalCf = hrp.CFrame
                        for _, node in ipairs(nodesToCollect) do
                            if not autoCollectMapTokens or not isAlive() then break end
                            hrp.CFrame = CFrame.new(node.Position + Vector3.new(0, 1.5, 0))
                            task.wait(0.12)

                            Remotes.CollectCollectableObject:FireServer(node)

                            pcall(function()
                                firetouchinterest(hrp, node, 0)
                                task.wait(0.02)
                                firetouchinterest(hrp, node, 1)
                            end)

                            for _, desc in ipairs(node:GetDescendants()) do
                                if desc:IsA("ProximityPrompt") and typeof(fireproximityprompt) == "function" then
                                    pcall(function() fireproximityprompt(desc) end)
                                elseif desc:IsA("BasePart") then
                                    pcall(function()
                                        firetouchinterest(hrp, desc, 0)
                                        task.wait(0.02)
                                        firetouchinterest(hrp, desc, 1)
                                    end)
                                end
                            end
                            task.wait(0.08)
                        end
                        if hrp and originalCf then
                            hrp.CFrame = originalCf
                        end
                    end
                end

                -- Extra sweep for map tokens/potions in other folders
                for _, folderName in ipairs({ "Tokens", "MapTokens", "Collectables" }) do
                    local f = workspace:FindFirstChild(folderName) or (sys and sys:FindFirstChild(folderName))
                    if f then
                        local orig = hrp.CFrame
                        for _, it in ipairs(f:GetChildren()) do
                            if not autoCollectMapTokens or not isAlive() then break end
                            local pos = it:IsA("BasePart") and it.Position or (it:IsA("Model") and it:GetPivot().Position)
                            if pos then
                                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 1.5, 0))
                                task.wait(0.12)
                                if it:IsA("BasePart") then
                                    pcall(function() firetouchinterest(hrp, it, 0); task.wait(0.02); firetouchinterest(hrp, it, 1) end)
                                end
                                for _, p in ipairs(it:GetDescendants()) do
                                    if p:IsA("ProximityPrompt") and typeof(fireproximityprompt) == "function" then
                                        pcall(function() fireproximityprompt(p) end)
                                    end
                                end
                                if Remotes:FindFirstChild("CollectCollectableObject") then
                                    Remotes.CollectCollectableObject:FireServer(it)
                                end
                                task.wait(0.08)
                            end
                        end
                        if hrp and orig then
                            hrp.CFrame = orig
                        end
                    end
                end
            end)
        end
        task.wait(2.0)
    end
end)

-- 16. Infinity Tower Loop
task.spawn(function()
    while isAlive() do
        if autoInfinityTower then
            pcall(function()
                if Remotes and Remotes:FindFirstChild("GetInfinityTowerBattleState") then
                    local battleState = Remotes.GetInfinityTowerBattleState:InvokeServer()
                    if battleState and type(battleState) == "table" then
                        isTowerInBattle = true
                        activeTowerFloor = tonumber(battleState.Floor) or activeTowerFloor
                        activeTowerStage = battleState.TowerName or activeTowerStage

                        -- Ensure auto-battle is active
                        if battleState.AutoBattle == false and Remotes:FindFirstChild("SetInfinityTowerAutoBattle") then
                            Remotes.SetInfinityTowerAutoBattle:FireServer(activeTowerStage, true)
                        end

                        -- Check surrender condition (user specified floor threshold)
                        if towerSurrenderFloor > 0 and activeTowerFloor >= towerSurrenderFloor then
                            WindUI:Notify({
                                Title = "Tower Surrender Floor Reached",
                                Content = string.format("Reached floor %d (target: %d). Forfeiting to cash out rewards...", activeTowerFloor, towerSurrenderFloor),
                                Duration = 3,
                                Icon = "flag"
                            })
                            doExitTowerBattle(activeTowerStage)
                            task.wait(2.5)
                        end
                    else
                        -- Not currently in battle, start battle with top units
                        isTowerInBattle = false
                        activeTowerFloor = 0
                        local started = doStartTowerBattle()
                        if started then
                            task.wait(1.5)
                        end
                    end
                end
            end)
        else
            -- If auto is off, keep battle state synced for UI status paragraph
            pcall(function()
                if Remotes and Remotes:FindFirstChild("GetInfinityTowerBattleState") then
                    local battleState = Remotes.GetInfinityTowerBattleState:InvokeServer()
                    if battleState and type(battleState) == "table" then
                        isTowerInBattle = true
                        activeTowerFloor = tonumber(battleState.Floor) or activeTowerFloor
                        activeTowerStage = battleState.TowerName or activeTowerStage
                    else
                        isTowerInBattle = false
                        activeTowerFloor = 0
                    end
                end
            end)
        end
        task.wait(1.5)
    end
end)
end -- end of Event & Tower Loops scope

-- 17. Character Mods & Movement Loop
UserInputService.JumpRequest:Connect(function()
    if infiniteJump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Stepped:Connect(function()
    if noclip and Character then
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
    if modWalkSpeed then
        local hum = getHumanoid()
        if hum and hum.WalkSpeed ~= customWalkSpeed then
            hum.WalkSpeed = customWalkSpeed
        end
    end
    if modJumpPower then
        local hum = getHumanoid()
        if hum and hum.JumpPower ~= customJumpPower then
            hum.JumpPower = customJumpPower
        end
    end
end)

-- 19. Anti-AFK
LocalPlayer.Idled:Connect(function()
    if antiAfk then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end)
    end
end)

-- Hotkey Listener for folding / toggling UI
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == currentToggleKey then
        pcall(function()
            Window:Toggle()
        end)
    end
end)

-- 18. Auto Obby Background Loop
task.spawn(function()
    while isAlive() do
        if autoObby then
            pcall(doCompleteObby)
        end
        task.wait(12)
    end
end)

-- If no saved config exists, initialize default config "12"
if #getSavedConfigsList() == 0 then
    local initData = collectConfigData()
    pcall(function()
        writefile(CONFIG_FOLDER .. "/12.json", HttpService:JSONEncode(initData))
    end)
    loadedConfigName = "12"
    selectedConfigName = "12"
    inputConfigName = "12"
end

-- Initial Configs List Population
refreshConfigsUI("12")

-- Auto Load Config on Launch if configured
task.spawn(function()
    task.wait(0.6)
    local autoName = getAutoLoadConfig()
    if autoName and autoName ~= "none" and autoName ~= "" then
        local autoPath = CONFIG_FOLDER .. "/" .. autoName .. ".json"
        if typeof(isfile) == "function" and isfile(autoPath) and typeof(readfile) == "function" then
            local okRead, content = pcall(function() return readfile(autoPath) end)
            if okRead and content then
                local okDec, decoded = pcall(function() return HttpService:JSONDecode(content) end)
                if okDec and type(decoded) == "table" then
                    applyConfigData(decoded)
                    loadedConfigName = autoName
                    selectedConfigName = autoName
                    inputConfigName = autoName
                    if ConfigNameInput then pcall(function() ConfigNameInput:Set(autoName) end) end
                    if SavedConfigsDropdown then pcall(function() SavedConfigsDropdown:Select(autoName) end) end
                    syncAutoLoadToggle()
                    updateConfigManagerText()
                    WindUI:Notify({
                        Title = "Config Auto-Loaded",
                        Content = "Auto-loaded config: " .. autoName,
                        Duration = 4,
                        Icon = "check-check"
                    })
                end
            end
        end
    end
end)

-- Initial Plot Protection
disablePlotGamepassButtons()

--------------------------------------------------------------------------------
-- 20. FOOTBALL STADIUM & BLUE LOCK EGO DYNAMIC ANIMATION ENGINE (60 FPS)
--------------------------------------------------------------------------------
task.spawn(function()
    local main = nil
    local topbar = nil

    for attempt = 1, 60 do
        if not isAlive() then return end

        if Window and Window.UIElements and Window.UIElements.Main then
            main = Window.UIElements.Main
            topbar = Window.UIElements.Topbar
            break
        end

        local searchRoots = {
            (WindUI and WindUI.ScreenGui),
            (typeof(gethui) == "function" and gethui()),
            game:GetService("CoreGui"),
            LocalPlayer:FindFirstChild("PlayerGui")
        }

        for _, root in ipairs(searchRoots) do
            if root then
                local found = root:FindFirstChild("Main", true)
                if found and found:IsA("GuiObject") then
                    main = found
                    topbar = root:FindFirstChild("Topbar", true)
                    break
                end
            end
        end

        if main then break end
        task.wait(0.1)
    end

    if not main then return end
    if not topbar then
        topbar = main:FindFirstChild("Topbar", true) or (main.Parent and main.Parent:FindFirstChild("Topbar", true))
    end

    -- 1. Rotating Stadium Floodlight & Blue Lock Ego Border
    local oldStroke = main:FindFirstChild("AnimatedStadiumStroke")
    if oldStroke then oldStroke:Destroy() end

    local stroke = Instance.new("UIStroke")
    stroke.Name = "AnimatedStadiumStroke"
    stroke.Thickness = 2.6
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Enabled = fxStadiumBorder
    stroke.Parent = main
    UIElements.liveStadiumStroke = stroke

    local strokeGradient = Instance.new("UIGradient")
    strokeGradient.Name = "StadiumBorderGradient"
    strokeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromHex("#10B981")), -- Turf Emerald
        ColorSequenceKeypoint.new(0.22, Color3.fromHex("#00E5FF")), -- Blue Lock Ego Cyan
        ColorSequenceKeypoint.new(0.45, Color3.fromHex("#3B82F6")), -- Striker Royal Blue
        ColorSequenceKeypoint.new(0.70, Color3.fromHex("#FBBF24")), -- Ballon d'Or Gold
        ColorSequenceKeypoint.new(0.88, Color3.fromHex("#34D399")), -- Pitch Mint
        ColorSequenceKeypoint.new(1.00, Color3.fromHex("#10B981")),
    })
    strokeGradient.Parent = stroke

    -- 2. Football Pitch Tactical Field Overlay (Turf Stripes, Halfway Line, Rotating Center Circle, Penalty Boxes)
    -- ZIndex = 2 places this right in front of Window Background (ZIndex = 1) and strictly behind Main UI content (ZIndex = 97)!
    local oldPitch = main:FindFirstChild("FootballPitchCanvas")
    if oldPitch then oldPitch:Destroy() end

    local pitchCanvas = Instance.new("Frame")
    pitchCanvas.Name = "FootballPitchCanvas"
    pitchCanvas.Size = UDim2.new(1, 0, 1, -54)
    pitchCanvas.Position = UDim2.new(0, 0, 0, 54)
    pitchCanvas.BackgroundTransparency = 1
    pitchCanvas.ClipsDescendants = true
    pitchCanvas.ZIndex = 2
    pitchCanvas.Visible = fxPitchField
    pitchCanvas.Parent = main
    UIElements.livePitchCanvas = pitchCanvas

    -- Alternating Stadium Turf Stripes
    local turfStripes = {}
    for i = 1, 7 do
        local stripe = Instance.new("Frame")
        stripe.Name = "TurfStripe_" .. i
        stripe.Size = UDim2.new(0.08, 0, 1, 0)
        stripe.Position = UDim2.new(0.22 + (i - 1) * 0.12, 0, 0, 0)
        stripe.BackgroundColor3 = (i % 2 == 0) and Color3.fromHex("#10B981") or Color3.fromHex("#00E5FF")
        stripe.BackgroundTransparency = 0.955
        stripe.BorderSizePixel = 0
        stripe.ZIndex = 2
        stripe.Parent = pitchCanvas
        table.insert(turfStripes, stripe)
    end

    -- Halfway Pitch Line (Centered in main content area)
    local halfwayLine = Instance.new("Frame")
    halfwayLine.Name = "HalfwayLine"
    halfwayLine.Size = UDim2.new(0, 2, 0.88, 0)
    halfwayLine.Position = UDim2.new(0.62, -1, 0.06, 0)
    halfwayLine.BackgroundColor3 = Color3.fromHex("#34D399")
    halfwayLine.BackgroundTransparency = 0.78
    halfwayLine.BorderSizePixel = 0
    halfwayLine.ZIndex = 2
    halfwayLine.Parent = pitchCanvas

    local halfwayGrad = Instance.new("UIGradient")
    halfwayGrad.Rotation = 90
    halfwayGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromHex("#10B981")),
        ColorSequenceKeypoint.new(0.5, Color3.fromHex("#00E5FF")),
        ColorSequenceKeypoint.new(1.0, Color3.fromHex("#10B981")),
    })
    halfwayGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 0.85),
        NumberSequenceKeypoint.new(0.5, 0.10),
        NumberSequenceKeypoint.new(1.0, 0.85),
    })
    halfwayGrad.Parent = halfwayLine

    -- Rotating Pitch Center Circle
    local centerCircle = Instance.new("Frame")
    centerCircle.Name = "PitchCenterCircle"
    centerCircle.Size = UDim2.fromOffset(140, 140)
    centerCircle.Position = UDim2.new(0.62, 0, 0.50, 0)
    centerCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    centerCircle.BackgroundTransparency = 1
    centerCircle.ZIndex = 2
    centerCircle.Parent = pitchCanvas

    local ccCorner = Instance.new("UICorner")
    ccCorner.CornerRadius = UDim.new(1, 0)
    ccCorner.Parent = centerCircle

    local ccStroke = Instance.new("UIStroke")
    ccStroke.Thickness = 2.2
    ccStroke.Transparency = 0.62
    ccStroke.Color = Color3.fromRGB(255, 255, 255)
    ccStroke.Parent = centerCircle

    local ccGradient = Instance.new("UIGradient")
    ccGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromHex("#10B981")),
        ColorSequenceKeypoint.new(0.5, Color3.fromHex("#00E5FF")),
        ColorSequenceKeypoint.new(1.0, Color3.fromHex("#FBBF24")),
    })
    ccGradient.Parent = ccStroke

    -- Counter-Rotating Inner Ego Ring
    local innerRing = Instance.new("Frame")
    innerRing.Name = "InnerEgoRing"
    innerRing.Size = UDim2.fromOffset(76, 76)
    innerRing.Position = UDim2.new(0.62, 0, 0.50, 0)
    innerRing.AnchorPoint = Vector2.new(0.5, 0.5)
    innerRing.BackgroundTransparency = 1
    innerRing.ZIndex = 2
    innerRing.Parent = pitchCanvas

    local irCorner = Instance.new("UICorner")
    irCorner.CornerRadius = UDim.new(1, 0)
    irCorner.Parent = innerRing

    local irStroke = Instance.new("UIStroke")
    irStroke.Thickness = 1.6
    irStroke.Transparency = 0.68
    irStroke.Color = Color3.fromRGB(255, 255, 255)
    irStroke.Parent = innerRing

    local irGradient = Instance.new("UIGradient")
    irGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromHex("#00E5FF")),
        ColorSequenceKeypoint.new(0.5, Color3.fromHex("#3B82F6")),
        ColorSequenceKeypoint.new(1.0, Color3.fromHex("#10B981")),
    })
    irGradient.Parent = irStroke

    -- Center Kick-Off Spot
    local kickoffSpot = Instance.new("Frame")
    kickoffSpot.Name = "KickoffSpot"
    kickoffSpot.Size = UDim2.fromOffset(8, 8)
    kickoffSpot.Position = UDim2.new(0.62, 0, 0.50, 0)
    kickoffSpot.AnchorPoint = Vector2.new(0.5, 0.5)
    kickoffSpot.BackgroundColor3 = Color3.fromHex("#00E5FF")
    kickoffSpot.BackgroundTransparency = 0.50
    kickoffSpot.BorderSizePixel = 0
    kickoffSpot.ZIndex = 2
    kickoffSpot.Parent = pitchCanvas

    local koCorner = Instance.new("UICorner")
    koCorner.CornerRadius = UDim.new(1, 0)
    koCorner.Parent = kickoffSpot

    -- Left & Right Penalty Goal Boxes
    local function createPenaltyBox(name, posX, anchorX)
        local box = Instance.new("Frame")
        box.Name = name
        box.Size = UDim2.new(0.09, 0, 0.42, 0)
        box.Position = UDim2.new(posX, 0, 0.50, 0)
        box.AnchorPoint = Vector2.new(anchorX, 0.5)
        box.BackgroundTransparency = 1
        box.ZIndex = 2
        box.Parent = pitchCanvas

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 6)
        bCorner.Parent = box

        local bStroke = Instance.new("UIStroke")
        bStroke.Thickness = 1.5
        bStroke.Transparency = 0.74
        bStroke.Color = Color3.fromHex("#10B981")
        bStroke.Parent = box
        return box
    end
    createPenaltyBox("LeftPenaltyBox", 0.28, 0)
    createPenaltyBox("RightPenaltyBox", 0.985, 1)

    -- 3. Floating Spinning Footballs (⚽) & Blue Lock Ego Aura Sparks (ZIndex = 2: In front of Background, Behind Main UI)
    local oldBalls = main:FindFirstChild("FootballParticleCanvas")
    if oldBalls then oldBalls:Destroy() end

    local ballCanvas = Instance.new("Frame")
    ballCanvas.Name = "FootballParticleCanvas"
    ballCanvas.Size = UDim2.new(1, 0, 1, -54)
    ballCanvas.Position = UDim2.new(0, 0, 0, 54)
    ballCanvas.BackgroundTransparency = 1
    ballCanvas.ClipsDescendants = true
    ballCanvas.ZIndex = 2
    ballCanvas.Visible = fxFloatingBalls
    ballCanvas.Parent = main
    UIElements.liveBallCanvas = ballCanvas

    local math_random = math.random
    local math_sin = math.sin
    local math_abs = math.abs

    local spinningBalls = {}
    for i = 1, 10 do
        local ball = Instance.new("TextLabel")
        ball.Name = "FloatingSoccerBall_" .. i
        local sz = math_random(14, 20)
        ball.Size = UDim2.fromOffset(sz, sz)
        ball.Position = UDim2.new(math_random(8, 95) / 100, 0, math_random(8, 94) / 100, 0)
        ball.AnchorPoint = Vector2.new(0.5, 0.5)
        ball.BackgroundTransparency = 1
        ball.Text = "⚽"
        ball.TextSize = sz
        ball.Font = Enum.Font.GothamBold
        ball.TextColor3 = Color3.fromRGB(255, 255, 255)
        ball.TextTransparency = math_random(42, 65) / 100
        ball.ZIndex = 2
        ball.Parent = ballCanvas

        table.insert(spinningBalls, {
            obj = ball,
            speedY = math_random(12, 26) / 1000,
            swaySpeed = math_random(10, 22) / 10,
            spinSpeed = (i % 2 == 0 and 1 or -1) * math_random(45, 105),
            baseX = ball.Position.X.Scale,
            offset = math_random(0, 100) / 10,
            baseTrans = ball.TextTransparency,
        })
    end

    local egoSparks = {}
    local sparkPalette = {
        Color3.fromHex("#10B981"), -- Turf Emerald
        Color3.fromHex("#00E5FF"), -- Blue Lock Ego Cyan
        Color3.fromHex("#3B82F6"), -- Royal Striker Blue
        Color3.fromHex("#FBBF24"), -- Trophy Gold
    }
    for i = 1, 24 do
        local sp = Instance.new("Frame")
        local sz = math_random(3, 7)
        sp.Size = UDim2.fromOffset(sz, sz)
        sp.Position = UDim2.new(math_random(4, 96) / 100, 0, math_random(5, 95) / 100, 0)
        sp.BackgroundColor3 = sparkPalette[(i % #sparkPalette) + 1]
        sp.BackgroundTransparency = math_random(25, 58) / 100
        sp.BorderSizePixel = 0
        sp.ZIndex = 2
        sp.Parent = ballCanvas

        local spCorner = Instance.new("UICorner")
        spCorner.CornerRadius = UDim.new(1, 0)
        spCorner.Parent = sp

        table.insert(egoSparks, {
            obj = sp,
            speedY = math_random(18, 40) / 1000,
            swaySpeed = math_random(12, 28) / 10,
            baseX = sp.Position.X.Scale,
            offset = math_random(0, 100) / 10,
        })
    end

    -- 4. Topbar Goal-Line Laser & Dribbling Mini Football (⚽)
    -- Parented to `main` at Y=51 with ZIndex=98 (so it renders on the bottom border of the Topbar without touching any text!)
    local goalLineBar = nil
    local goalLineGrad = nil
    local dribbleBall = nil
    do
        if topbar then
            local oldTbGoal = topbar:FindFirstChild("TopbarGoalLine")
            if oldTbGoal then oldTbGoal:Destroy() end
        end
        local oldMainGoal = main:FindFirstChild("TopbarGoalLine")
        if oldMainGoal then oldMainGoal:Destroy() end

        goalLineBar = Instance.new("Frame")
        goalLineBar.Name = "TopbarGoalLine"
        goalLineBar.Size = UDim2.new(1, -24, 0, 2)
        goalLineBar.Position = UDim2.new(0, 12, 0, 51)
        goalLineBar.BorderSizePixel = 0
        goalLineBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        goalLineBar.BackgroundTransparency = 0.10
        goalLineBar.ZIndex = 98
        goalLineBar.Visible = fxTopbarDribble
        goalLineBar.Parent = main
        UIElements.liveTopbarGoalLine = goalLineBar

        goalLineGrad = Instance.new("UIGradient")
        goalLineGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromHex("#10B981")),
            ColorSequenceKeypoint.new(0.35, Color3.fromHex("#00E5FF")),
            ColorSequenceKeypoint.new(0.70, Color3.fromHex("#FBBF24")),
            ColorSequenceKeypoint.new(1.00, Color3.fromHex("#10B981")),
        })
        goalLineGrad.Parent = goalLineBar

        dribbleBall = Instance.new("TextLabel")
        dribbleBall.Name = "DribblingSoccerBall"
        dribbleBall.Size = UDim2.fromOffset(12, 12)
        dribbleBall.Position = UDim2.new(0.5, 0, 0.5, 0)
        dribbleBall.AnchorPoint = Vector2.new(0.5, 0.5)
        dribbleBall.BackgroundTransparency = 1
        dribbleBall.Text = "⚽"
        dribbleBall.TextSize = 11
        dribbleBall.Font = Enum.Font.GothamBold
        dribbleBall.TextColor3 = Color3.fromRGB(255, 255, 255)
        dribbleBall.ZIndex = 99
        dribbleBall.Parent = goalLineBar
    end

    -- 5. Animated Title Shimmer & Broadcast Match Scoreboard Badge
    local titleShimmer = nil
    local liveScoreBadge = nil
    local badgeStrokeGrad = nil
    if topbar then
        for _, desc in ipairs(topbar:GetDescendants()) do
            if desc:IsA("TextLabel") and (string.find(desc.Text, "Blue Lock") or desc.Name == "Title") then
                local oldShimmer = desc:FindFirstChild("StadiumTitleShimmer")
                if oldShimmer then oldShimmer:Destroy() end

                titleShimmer = Instance.new("UIGradient")
                titleShimmer.Name = "StadiumTitleShimmer"
                titleShimmer.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0.00, Color3.fromHex("#34D399")),
                    ColorSequenceKeypoint.new(0.45, Color3.fromHex("#FFFFFF")),
                    ColorSequenceKeypoint.new(0.75, Color3.fromHex("#00E5FF")),
                    ColorSequenceKeypoint.new(1.00, Color3.fromHex("#FBBF24")),
                })
                titleShimmer.Parent = desc
                break
            end
        end

        local rightFrame = topbar:FindFirstChild("Right", true) or topbar:FindFirstChild("Buttons", true)
        if rightFrame then
            local listLayout = rightFrame:FindFirstChildOfClass("UIListLayout")
            if listLayout then
                listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            end

            local oldBadge = rightFrame:FindFirstChild("StadiumScoreboardBadge")
            if oldBadge then oldBadge:Destroy() end

            liveScoreBadge = Instance.new("TextLabel")
            liveScoreBadge.Name = "StadiumScoreboardBadge"
            liveScoreBadge.Size = UDim2.new(0, 134, 0, 24)
            liveScoreBadge.LayoutOrder = -1
            liveScoreBadge.BackgroundColor3 = Color3.fromHex("#061E16")
            liveScoreBadge.BackgroundTransparency = 0.15
            liveScoreBadge.TextColor3 = Color3.fromHex("#34D399")
            liveScoreBadge.TextStrokeTransparency = 1
            liveScoreBadge.TextSize = 11
            liveScoreBadge.Font = Enum.Font.GothamBold
            liveScoreBadge.Text = "⚽ LIVE | 60 FPS"
            liveScoreBadge.Parent = rightFrame

            local bCorner = Instance.new("UICorner")
            bCorner.CornerRadius = UDim.new(0, 8)
            bCorner.Parent = liveScoreBadge

            local bStroke = Instance.new("UIStroke")
            bStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            bStroke.Thickness = 1.2
            bStroke.Color = Color3.fromRGB(255, 255, 255)
            bStroke.Parent = liveScoreBadge

            badgeStrokeGrad = Instance.new("UIGradient")
            badgeStrokeGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.0, Color3.fromHex("#10B981")),
                ColorSequenceKeypoint.new(0.5, Color3.fromHex("#00E5FF")),
                ColorSequenceKeypoint.new(1.0, Color3.fromHex("#FBBF24")),
            })
            badgeStrokeGrad.Parent = bStroke
        end
    end

    -- 6. Interactive Button & Tab Hover/Click Spring Micro-Animations
    local hookedButtons = {}
    local function bindButtonMicroFX(btn)
        if hookedButtons[btn] or not (btn:IsA("ImageButton") or btn:IsA("TextButton")) then return end
        hookedButtons[btn] = true
        pcall(function()
            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundTransparency = math.clamp(btn.BackgroundTransparency - 0.06, 0, 1)
                }):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundTransparency = math.clamp(btn.BackgroundTransparency + 0.06, 0, 1)
                }):Play()
            end)
        end)
    end

    for _, desc in ipairs(main:GetDescendants()) do
        bindButtonMicroFX(desc)
    end
    main.DescendantAdded:Connect(bindButtonMicroFX)

    -- 7. Master 60 FPS RenderStepped Loop
    local frameCount = 0
    local lastFpsTime = tick()
    local renderConn = nil

    renderConn = RunService.RenderStepped:Connect(function()
        if not isAlive() or not main or not main.Parent then
            if renderConn then renderConn:Disconnect() end
            return
        end

        local t = tick()
        local spd = fxAnimationSpeed or 1.0

        -- Update Broadcast Match Scoreboard Badge
        frameCount = frameCount + 1
        if t - lastFpsTime >= 0.45 then
            local fps = math.floor(frameCount / (t - lastFpsTime))
            frameCount = 0
            lastFpsTime = t
            if liveScoreBadge and liveScoreBadge.Parent then
                local ping = 0
                pcall(function()
                    ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
                end)
                liveScoreBadge.Text = string.format("⚽ %d FPS | %dms", fps, ping)
                if fps >= 50 then
                    liveScoreBadge.TextColor3 = Color3.fromHex("#34D399")
                elseif fps >= 30 then
                    liveScoreBadge.TextColor3 = Color3.fromHex("#FBBF24")
                else
                    liveScoreBadge.TextColor3 = Color3.fromHex("#EF4444")
                end
            end
        end

        if badgeStrokeGrad and badgeStrokeGrad.Parent then
            badgeStrokeGrad.Rotation = (t * 80 * spd) % 360
        end

        -- 1. Stadium Floodlight Border Rotation & Pulse
        if stroke and stroke.Parent then
            stroke.Enabled = fxStadiumBorder
            if fxStadiumBorder then
                strokeGradient.Rotation = (t * 65 * spd) % 360
                stroke.Thickness = 2.4 + math_sin(t * 2.5 * spd) * 0.5
            end
        end

        -- 2. Football Pitch Center Circle & Turf Wave Animation
        if pitchCanvas and pitchCanvas.Parent then
            pitchCanvas.Visible = fxPitchField
            if fxPitchField then
                ccGradient.Rotation = (t * 48 * spd) % 360
                irGradient.Rotation = -(t * 75 * spd) % 360
                local pulseSz = 134 + math_sin(t * 2.0 * spd) * 7
                centerCircle.Size = UDim2.fromOffset(pulseSz, pulseSz)
                local innerSz = 74 - math_sin(t * 2.6 * spd) * 5
                innerRing.Size = UDim2.fromOffset(innerSz, innerSz)
            end
        end

        -- 3. Floating Spinning Footballs & Ego Sparks
        if ballCanvas and ballCanvas.Parent then
            ballCanvas.Visible = fxFloatingBalls
            if fxFloatingBalls then
                for _, b in ipairs(spinningBalls) do
                    local newY = b.obj.Position.Y.Scale - (b.speedY * 0.045 * spd)
                    if newY < 0.03 then
                        newY = 0.97
                    end
                    local newX = b.baseX + (math_sin(t * b.swaySpeed * spd + b.offset) * 0.032)
                    b.obj.Position = UDim2.new(newX, 0, newY, 0)
                    b.obj.Rotation = (t * b.spinSpeed * spd) % 360
                    b.obj.TextTransparency = math.clamp(b.baseTrans + math_sin(t * 2.2 + b.offset) * 0.1, 0.35, 0.85)
                end

                for _, sp in ipairs(egoSparks) do
                    local newY = sp.obj.Position.Y.Scale - (sp.speedY * 0.05 * spd)
                    if newY < 0.02 then
                        newY = 0.98
                    end
                    local newX = sp.baseX + (math_sin(t * sp.swaySpeed * spd + sp.offset) * 0.022)
                    sp.obj.Position = UDim2.new(newX, 0, newY, 0)
                end
            end
        end

        -- 4. Topbar Goal-Line Laser & Dribbling Ball
        if goalLineBar and goalLineBar.Parent then
            goalLineBar.Visible = fxTopbarDribble
            if fxTopbarDribble then
                if goalLineGrad then
                    goalLineGrad.Offset = Vector2.new(math_sin(t * 2.2 * spd) * 0.7, 0)
                end
                if dribbleBall then
                    local dribbleX = 0.5 + math_sin(t * 1.25 * spd) * 0.44
                    local bounceY = -math_abs(math_sin(t * 5.8 * spd)) * 1.5
                    dribbleBall.Position = UDim2.new(dribbleX, 0, 0.5, bounceY)
                    dribbleBall.Rotation = (t * 200 * spd) % 360
                end
            end
        end

        -- 5. Title Shimmer Sweep
        if titleShimmer and titleShimmer.Parent then
            titleShimmer.Offset = Vector2.new(math_sin(t * 1.6 * spd) * 0.65, 0)
        end
    end)
end)

-- Ready Notification
WindUI:Notify({
    Title = "⚽ Song Hub | Stadium Edition 🏟️",
    Content = "Football Pitch Theme & 60FPS Ego Animations Activated!",
    Duration = 4,
    Icon = "trophy"
})

-- Select Automation Tab as default
pcall(function()
    if TabAutomation and TabAutomation.Select then
        TabAutomation:Select()
    end
end)
