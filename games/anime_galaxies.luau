-- ==============================================================================
-- Anime Galaxies Hub | All-in-One Ultimate Automation Edition ✨
-- Target Game: Anime Galaxies (PlaceId: 83869074416117, 85423571424083)
-- UniverseId: 10770748262
-- UI Framework: WindUI + Custom Dynamic Particle & Chroma FX Engine
-- Made for: Hood_u7
-- ==============================================================================

-- 0. Wait for game to be fully loaded
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- 0.1 Universe/Place check to prevent running in other games on autoexec
local placeId = game.PlaceId
local universeId = game.GameId

if universeId == 0 or placeId == 0 then
    task.wait(1)
    placeId = game.PlaceId
    universeId = game.GameId
end

local isAnimeGalaxies = (universeId == 10770748262 or placeId == 83869074416117 or placeId == 85423571424083)

if not isAnimeGalaxies and not getgenv().AnimeGalaxiesBypassPlaceCheck then
    warn(string.format("[AnimeGalaxiesHub] Notice: Current UniverseId is %s, PlaceId is %s. Hub is designed for Anime Galaxies (10770748262). To bypass check and test anywhere, run: getgenv().AnimeGalaxiesBypassPlaceCheck = true", tostring(universeId), tostring(placeId)))
    return
end

-- 0.2 Shutdown previous running instance and loops (Strict Singleton)
if getgenv().AnimeGalaxiesHubShutdown then
    pcall(getgenv().AnimeGalaxiesHubShutdown)
    task.wait(0.2)
end

local executorName = "Universal Executor"
pcall(function()
    if identifyexecutor then
        executorName = identifyexecutor()
    elseif getexecutorname then
        executorName = getexecutorname()
    end
end)

local rawQueueTeleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport) or (getgenv and getgenv().queue_on_teleport)
local hasQueueTeleport = (type(rawQueueTeleport) == "function")
local copyToClipboard = setclipboard or toclipboard or (Clipboard and Clipboard.set) or (syn and syn.write_clipboard)

local scriptRunning = true
local teleportConnection = nil

getgenv().AnimeGalaxiesHubShutdown = function()
    scriptRunning = false
    if teleportConnection then
        pcall(function() teleportConnection:Disconnect() end)
        teleportConnection = nil
    end
end

-- 0.3 Clean up all existing UI instances across CoreGui, gethui, and PlayerGui
local function destroyOldUIs()
    local searchParents = { (gethui and gethui()), game:GetService("CoreGui") }
    local lp = game:GetService("Players").LocalPlayer
    if lp and lp:FindFirstChild("PlayerGui") then
        table.insert(searchParents, lp.PlayerGui)
    end
    for _, parent in ipairs(searchParents) do
        if parent then
            pcall(function()
                for _, c in ipairs(parent:GetChildren()) do
                    if c.Name == "WindUI" or c.Name:find("WindUI") or c.Name:find("AnimeGalaxies") or (c:IsA("ScreenGui") and c.Name == "ScreenGui" and c:FindFirstChild("Main", true)) then
                        c:Destroy()
                    end
                end
            end)
        end
    end
end
destroyOldUIs()
task.wait(0.15)

local WindUI = nil
pcall(function()
    WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not WindUI then
    pcall(function()
        WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end)
end
if not WindUI then
    warn("[AnimeGalaxiesHub] Error: Could not download WindUI framework. Check network connection.")
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
end)

-- Safe Remote Service Access
local NetworkClient = nil
pcall(function()
    NetworkClient = require(ReplicatedStorage.Master.Modules.Network_Client)
end)

local function publishRemote(topic, data)
    if NetworkClient and NetworkClient.Publish then
        pcall(function()
            NetworkClient:Publish(topic, data)
        end)
    end
end

-- Load Game Information Modules safely
local ChampionsInfo = nil
local LevelRewardsInfo = nil
local TraitsInfo = nil
local WorldsInfo = nil

pcall(function()
    ChampionsInfo = require(ReplicatedStorage.Master.Information.Champions)
end)
pcall(function()
    LevelRewardsInfo = require(ReplicatedStorage.Master.Information.LevelRewards)
end)
pcall(function()
    TraitsInfo = require(ReplicatedStorage.Master.Information.Traits)
end)
pcall(function()
    WorldsInfo = require(ReplicatedStorage.Master.Information.Worlds)
end)

-- Helper: Get list of player's owned units
local function getOwnedUnitsList()
    local list = {}
    pcall(function()
        local unitsFolder = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Units")
        if unitsFolder then
            for _, u in ipairs(unitsFolder:GetChildren()) do
                for _, idF in ipairs(u:GetChildren()) do
                    table.insert(list, u.Name .. " (ID: " .. idF.Name .. ")")
                end
            end
        end
    end)
    if #list == 0 then
        table.insert(list, "None")
    end
    return list
end

-- ==============================================================================
-- CONFIGURATION & SETTINGS ENGINE (SAVE / LOAD / AUTO-EXECUTE SYNC)
-- ==============================================================================
local CONFIG_FOLDER = "AnimeGalaxiesHub/Configs"
pcall(function()
    if not isfolder("AnimeGalaxiesHub") then makefolder("AnimeGalaxiesHub") end
    if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
end)

local currentConfigName = "Default_Config"
local autoSaveConfig = true
local autoExecuteMaster = true
local autoTeleportQueue = true
local autoExecFile = true

-- State Variables Initialization
local selectedWorld = "Hidden Village"
local selectedStage = 1
local isNightmare = false
local autoStoryFarm = false
local autoTowerStart = false
local autoStartMatch = false
local autoLeaveMatch = false

local smartPlayEnabled = false
local smartStrategy = "Balanced"
local smartPlacementBias = "Best"
local smartUpgradePriority = "Focus Carry"
local smartAutoAbilities = true
local smartAutoTargeting = true
local smartSellFarmsFinalWave = true
local smartSaveForPlacements = true
local smartLockSpeed2x = true
local smartAutoSkipWave = true
local smartMatchEndAction = "Next"

local macroPlaybackEnabled = false
local macroAutoStart = true
local macroLoopEnabled = true
local macroAutoUpgrade = true
local currentMacroStep = 0
local selectedBuilderSlot = 1
local selectedTargetLevel = 5
local selectedStepDelay = 1.5
local macroNameInput = "My_Tower_Macro"
local selectedFileToLoad = "Default_Tower_Farm"

local autoDaily = true
local autoSeasonPass = true
local autoIndex = true
local autoQuests = true
local autoLevelMilestones = true

local autoSummon = false
local summonCount = 10
local summonBanner = "Standard"
local autoCapsules = false

local autoLockHighRarity = true
local autoTraitRoll = false
local autoStatRoll = false
local selectedTargetUnit = "Tango"
local selectedTargetId = "1"

local customSpeed = 16
local speedEnabled = false
local customJump = 50
local jumpEnabled = false
local infJump = false
local noclip = false
local antiAfkEnabled = true

local fxChromaEnabled = true
local fxParticlesEnabled = true
local fxLaserBarEnabled = true
local fxSpeed = 1.0
local selectedBaseTheme = "Dark"
local selectedTransparency = 0

-- Live FX object references for instant reactivity
local currentStroke = nil
local currentParticleCanvas = nil
local currentNeonBar = nil

local function getSavedConfigsList()
    local names = {}
    pcall(function()
        if isfolder(CONFIG_FOLDER) then
            for _, f in ipairs(listfiles(CONFIG_FOLDER)) do
                local clean = f:match("([^\\/]+)%.json$")
                if clean then
                    table.insert(names, clean)
                end
            end
        end
    end)
    if #names == 0 then
        table.insert(names, "Default_Config")
    end
    return names
end

local function serializeConfig()
    return {
        SelectedWorld = selectedWorld,
        SelectedStage = selectedStage,
        Nightmare = isNightmare,
        AutoStoryFarm = autoStoryFarm,
        AutoTower = autoTowerStart,
        AutoStartMatch = autoStartMatch,
        AutoLeaveMatch = autoLeaveMatch,

        SmartPlayEnabled = smartPlayEnabled,
        SmartStrategy = smartStrategy,
        SmartPlacementBias = smartPlacementBias,
        SmartUpgradePriority = smartUpgradePriority,
        SmartSaveForPlacements = smartSaveForPlacements,
        SmartSellFarmsFinalWave = smartSellFarmsFinalWave,
        SmartAutoAbilities = smartAutoAbilities,
        SmartAutoTargeting = smartAutoTargeting,
        SmartLockSpeed2x = smartLockSpeed2x,
        SmartAutoSkipWave = smartAutoSkipWave,
        SmartMatchEndAction = smartMatchEndAction,

        MacroPlaybackEnabled = macroPlaybackEnabled,
        MacroLoopEnabled = macroLoopEnabled,
        MacroAutoUpgrade = macroAutoUpgrade,
        MacroAutoStart = macroAutoStart,
        SelectedFileToLoad = selectedFileToLoad,

        AutoDaily = autoDaily,
        AutoSeasonPass = autoSeasonPass,
        AutoIndex = autoIndex,
        AutoQuests = autoQuests,
        AutoLevelMilestones = autoLevelMilestones,

        AutoSummon = autoSummon,
        SummonBanner = summonBanner,
        SummonCount = summonCount,
        AutoCapsules = autoCapsules,

        AutoLockHighRarity = autoLockHighRarity,
        AutoTraitRoll = autoTraitRoll,
        AutoStatRoll = autoStatRoll,
        SelectedTargetUnit = selectedTargetUnit,

        CustomSpeed = customSpeed,
        SpeedEnabled = speedEnabled,
        CustomJump = customJump,
        JumpEnabled = jumpEnabled,
        InfJump = infJump,
        Noclip = noclip,
        AntiAfkEnabled = antiAfkEnabled,

        FxChromaEnabled = fxChromaEnabled,
        FxParticlesEnabled = fxParticlesEnabled,
        FxLaserBarEnabled = fxLaserBarEnabled,
        FxSpeed = fxSpeed,
        BaseTheme = selectedBaseTheme,
        UiTransparency = selectedTransparency,

        AutoSaveConfig = autoSaveConfig,
        AutoExecuteMaster = autoExecuteMaster,
        AutoTeleportQueue = autoTeleportQueue,
        AutoExecFile = autoExecFile,
        LastSaved = os.time(),
    }
end

local function applyConfig(data)
    if type(data) ~= "table" then return end
    if data.SelectedWorld ~= nil then selectedWorld = data.SelectedWorld end
    if data.SelectedStage ~= nil then selectedStage = data.SelectedStage end
    if data.Nightmare ~= nil then isNightmare = data.Nightmare end
    if data.AutoStoryFarm ~= nil then autoStoryFarm = data.AutoStoryFarm end
    if data.AutoTower ~= nil then autoTowerStart = data.AutoTower end
    if data.AutoStartMatch ~= nil then autoStartMatch = data.AutoStartMatch end
    if data.AutoLeaveMatch ~= nil then autoLeaveMatch = data.AutoLeaveMatch end

    if data.SmartPlayEnabled ~= nil then smartPlayEnabled = data.SmartPlayEnabled end
    if data.SmartStrategy ~= nil then smartStrategy = data.SmartStrategy end
    if data.SmartPlacementBias ~= nil then smartPlacementBias = data.SmartPlacementBias end
    if data.SmartUpgradePriority ~= nil then smartUpgradePriority = data.SmartUpgradePriority end
    if data.SmartSaveForPlacements ~= nil then smartSaveForPlacements = data.SmartSaveForPlacements end
    if data.SmartSellFarmsFinalWave ~= nil then smartSellFarmsFinalWave = data.SmartSellFarmsFinalWave end
    if data.SmartAutoAbilities ~= nil then smartAutoAbilities = data.SmartAutoAbilities end
    if data.SmartAutoTargeting ~= nil then smartAutoTargeting = data.SmartAutoTargeting end
    if data.SmartLockSpeed2x ~= nil then smartLockSpeed2x = data.SmartLockSpeed2x end
    if data.SmartAutoSkipWave ~= nil then smartAutoSkipWave = data.SmartAutoSkipWave end
    if data.SmartMatchEndAction ~= nil then smartMatchEndAction = data.SmartMatchEndAction end

    if data.MacroPlaybackEnabled ~= nil then macroPlaybackEnabled = data.MacroPlaybackEnabled end
    if data.MacroLoopEnabled ~= nil then macroLoopEnabled = data.MacroLoopEnabled end
    if data.MacroAutoUpgrade ~= nil then macroAutoUpgrade = data.MacroAutoUpgrade end
    if data.MacroAutoStart ~= nil then macroAutoStart = data.MacroAutoStart end
    if data.SelectedFileToLoad ~= nil then selectedFileToLoad = data.SelectedFileToLoad end

    if data.AutoDaily ~= nil then autoDaily = data.AutoDaily end
    if data.AutoSeasonPass ~= nil then autoSeasonPass = data.AutoSeasonPass end
    if data.AutoIndex ~= nil then autoIndex = data.AutoIndex end
    if data.AutoQuests ~= nil then autoQuests = data.AutoQuests end
    if data.AutoLevelMilestones ~= nil then autoLevelMilestones = data.AutoLevelMilestones end

    if data.AutoSummon ~= nil then autoSummon = data.AutoSummon end
    if data.SummonBanner ~= nil then summonBanner = data.SummonBanner end
    if data.SummonCount ~= nil then summonCount = data.SummonCount end
    if data.AutoCapsules ~= nil then autoCapsules = data.AutoCapsules end

    if data.AutoLockHighRarity ~= nil then autoLockHighRarity = data.AutoLockHighRarity end
    if data.AutoTraitRoll ~= nil then autoTraitRoll = data.AutoTraitRoll end
    if data.AutoStatRoll ~= nil then autoStatRoll = data.AutoStatRoll end
    if data.SelectedTargetUnit ~= nil then selectedTargetUnit = data.SelectedTargetUnit end

    if data.CustomSpeed ~= nil then customSpeed = data.CustomSpeed end
    if data.SpeedEnabled ~= nil then speedEnabled = data.SpeedEnabled end
    if data.CustomJump ~= nil then customJump = data.CustomJump end
    if data.JumpEnabled ~= nil then jumpEnabled = data.JumpEnabled end
    if data.InfJump ~= nil then infJump = data.InfJump end
    if data.Noclip ~= nil then noclip = data.Noclip end
    if data.AntiAfkEnabled ~= nil then antiAfkEnabled = data.AntiAfkEnabled end

    if data.FxChromaEnabled ~= nil then fxChromaEnabled = data.FxChromaEnabled end
    if data.FxParticlesEnabled ~= nil then fxParticlesEnabled = data.FxParticlesEnabled end
    if data.FxLaserBarEnabled ~= nil then fxLaserBarEnabled = data.FxLaserBarEnabled end
    if data.FxSpeed ~= nil then fxSpeed = data.FxSpeed end
    if data.BaseTheme ~= nil then selectedBaseTheme = data.BaseTheme end
    if data.UiTransparency ~= nil then selectedTransparency = data.UiTransparency end
    if data.AutoSaveConfig ~= nil then autoSaveConfig = data.AutoSaveConfig end
    if data.AutoExecuteMaster ~= nil then autoExecuteMaster = data.AutoExecuteMaster end
    if data.AutoTeleportQueue ~= nil then
        autoTeleportQueue = data.AutoTeleportQueue
        if updateTeleportQueueState then
            updateTeleportQueueState(autoTeleportQueue)
        end
    end
    if data.AutoExecFile ~= nil then autoExecFile = data.AutoExecFile end
end

local function saveConfigToFile(name)
    name = (name and #name > 0) and name or currentConfigName
    name = name:gsub("[%\\/%:%*%?%\"%<%>%|]", "_")
    pcall(function()
        local data = serializeConfig()
        local json = HttpService:JSONEncode(data)
        writefile(CONFIG_FOLDER .. "/" .. name .. ".json", json)
        if name ~= "Default_Config" then
            writefile(CONFIG_FOLDER .. "/Default_Config.json", json)
        end
    end)
end

local function loadConfigFromFile(name)
    name = (name and #name > 0) and name or currentConfigName
    local loaded = false
    pcall(function()
        local path = CONFIG_FOLDER .. "/" .. name .. ".json"
        if not isfile(path) then
            path = CONFIG_FOLDER .. "/Default_Config.json"
        end
        if isfile(path) then
            local json = readfile(path)
            local data = HttpService:JSONDecode(json)
            applyConfig(data)
            loaded = true
        end
    end)
    return loaded
end

local function triggerAutoSave()
    if autoSaveConfig then
        task.spawn(function()
            saveConfigToFile(currentConfigName)
        end)
    end
end

-- Universal Cross-Executor Teleport Loader Generator
local function getTeleportLoaderCode()
    return [=[-- Anime Galaxies Hub Universal Teleport Loader
task.spawn(function()
    repeat task.wait() until game:IsLoaded()
    local placeId = game.PlaceId
    local universeId = game.GameId
    if universeId == 10770748262 or placeId == 83869074416117 or placeId == 85423571424083 then
        local candidates = {
            "AnimeGalaxiesHub/AnimeGalaxies_Hub.luau",
            "AnimeGalaxiesHub/AnimeGalaxies_Hub.lua",
            "AnimeGalaxies_Hub.luau",
            "AnimeGalaxies_Hub.lua"
        }
        for _, p in ipairs(candidates) do
            if isfile and isfile(p) then
                local ok, content = pcall(readfile, p)
                if ok and content and #content > 0 then
                    local fn = loadstring(content)
                    if fn then
                        return fn()
                    end
                end
            end
        end
    end
end)]=]
end

-- Universal Teleport Queue Manager (queue_on_teleport)
local function updateTeleportQueueState(enabled)
    if teleportConnection then
        pcall(function() teleportConnection:Disconnect() end)
        teleportConnection = nil
    end

    if enabled and autoExecuteMaster and hasQueueTeleport then
        local lp = Players.LocalPlayer
        if lp then
            teleportConnection = lp.OnTeleport:Connect(function(state)
                if state == Enum.TeleportState.Started or state == Enum.TeleportState.InProgress then
                    pcall(function()
                        rawQueueTeleport(getTeleportLoaderCode())
                    end)
                end
            end)
        end
    end
end

-- Universal AutoExec File Manager (writefile / delfile across executor autoexec paths)
local function updateAutoExecFileState(enabled)
    local loaderSnippet = [=[-- Anime Galaxies Hub Universal AutoExec Loader
task.spawn(function()
    repeat task.wait() until game:IsLoaded()
    local placeId = game.PlaceId
    local universeId = game.GameId
    if universeId == 10770748262 or placeId == 83869074416117 or placeId == 85423571424083 then
        local configPath = "AnimeGalaxiesHub/Configs/Default_Config.json"
        if isfile and isfile(configPath) then
            local ok, content = pcall(readfile, configPath)
            if ok and content and #content > 0 then
                local decodeOk, data = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), content)
                if decodeOk and type(data) == "table" then
                    if data.AutoExecuteMaster == false or data.AutoExecFile == false then
                        return
                    end
                end
            end
        end
        local candidates = {
            "AnimeGalaxiesHub/AnimeGalaxies_Hub.luau",
            "AnimeGalaxiesHub/AnimeGalaxies_Hub.lua",
            "AnimeGalaxies_Hub.luau",
            "AnimeGalaxies_Hub.lua"
        }
        for _, p in ipairs(candidates) do
            if isfile and isfile(p) then
                local ok, content = pcall(readfile, p)
                if ok and content and #content > 0 then
                    local fn = loadstring(content)
                    if fn then return fn() end
                end
            end
        end
    end
end)]=]

    local targetPaths = {
        "autoexec/Anime Galaxies_hub.luau",
        "autoexec/AnimeGalaxies_Hub.luau",
        "autoexec/AnimeGalaxies.luau",
        "autoexec/anime.luau",
        "../autoexec/Anime Galaxies_hub.luau",
        "../autoexec/AnimeGalaxies_Hub.luau",
        "../autoexec/anime.luau"
    }

    if enabled then
        local wrote = false
        for _, p in ipairs(targetPaths) do
            pcall(function()
                writefile(p, loaderSnippet)
                wrote = true
            end)
        end
        return wrote
    else
        local deleted = false
        for _, p in ipairs(targetPaths) do
            pcall(function()
                if isfile and isfile(p) then
                    delfile(p)
                    deleted = true
                end
            end)
        end
        return deleted
    end
end

-- Auto-load saved config before building interface
loadConfigFromFile("Default_Config")

-- Initialize universal teleport queue based on config
updateTeleportQueueState(autoTeleportQueue)

-- ==============================================================================
-- CREATE MODERN ANIMATED WINDOW
-- ==============================================================================
local Window = WindUI:CreateWindow({
    Title = "Anime Galaxies Hub",
    Icon = "sparkles",
    Author = "Hood_u7 Edition ✨",
    Folder = "AnimeGalaxiesHub",
    Size = UDim2.fromOffset(640, 520),
    MinSize = Vector2.new(560, 400),
    MaxSize = Vector2.new(880, 680),
    Transparent = true,
    Theme = selectedBaseTheme or "Dark",
    SideBarWidth = 195,
    Acrylic = false,
    Resizable = true,
    OpenButton = {
        Title = "Anime Galaxies Hub",
        Icon = "sparkles",
        CornerRadius = UDim.new(0, 16),
        StrokeThickness = 2,
        Color = ColorSequence.new(
            Color3.fromHex("A855F7"),
            Color3.fromHex("EC4899")
        ),
        Enabled = true,
        Draggable = true,
    },
    User = {
        Enabled = true,
        Anonymous = false,
    }
})

-- ==============================================================================
-- TABS CONFIGURATION
-- ==============================================================================
local TabMain      = Window:Tab({ Title = "Auto Farm & Story", Icon = "swords" })
local TabSmart     = Window:Tab({ Title = "Smart Play AI", Icon = "cpu" })
local TabMacro     = Window:Tab({ Title = "TD Macro Config", Icon = "gamepad-2" })
local TabRewards   = Window:Tab({ Title = "Auto Rewards", Icon = "gift" })
local TabSummon    = Window:Tab({ Title = "Auto Summon", Icon = "sparkles" })
local TabUnits     = Window:Tab({ Title = "Auto Units & Stats", Icon = "layers" })
local TabTeleports = Window:Tab({ Title = "Teleports", Icon = "map-pin" })
local TabPlayer    = Window:Tab({ Title = "Player & Misc", Icon = "user" })
local TabFX        = Window:Tab({ Title = "FX & Themes", Icon = "palette" })
local TabConfig    = Window:Tab({ Title = "Config & AutoExec", Icon = "settings" })

-- ==============================================================================
-- TAB 1: AUTO FARM & STORY (MATCH / ROOM / TOWER)
-- ==============================================================================
TabMain:Paragraph({
    Title = "Player Status",
    Desc = "Username: " .. LocalPlayer.Name .. " (" .. LocalPlayer.DisplayName .. ")\nStatus: Connected to Anime Galaxies [UPDATE 0]",
    Image = "user-check"
})

TabMain:Section({ Title = "Story & Map Automation" })

TabMain:Dropdown({
    Title = "Select World / Map",
    Desc = "เลือกโลกที่ต้องการจะให้บอทลงด่าน",
    Values = { "Hidden Village", "Desert Kingdom", "Dragon City", "Hollow World", "Cursed High School" },
    Value = selectedWorld,
    Callback = function(val)
        selectedWorld = val
        triggerAutoSave()
    end
})

TabMain:Dropdown({
    Title = "Select Stage (ด่าน)",
    Desc = "เลือกหมายเลขด่านที่ต้องการฟาร์ม (1 - 5)",
    Values = { "1", "2", "3", "4", "5" },
    Value = tostring(selectedStage),
    Callback = function(val)
        selectedStage = tonumber(val) or 1
        triggerAutoSave()
    end
})

TabMain:Toggle({
    Title = "Nightmare Mode",
    Desc = "เปิดโหมดความยากระดับ Nightmare เพื่อรับของรางวัลพิเศษ",
    Value = isNightmare,
    Icon = "skull",
    Callback = function(state)
        isNightmare = state
        triggerAutoSave()
    end
})

local function findFreeDoor(mode)
    mode = mode or "Story"
    if not workspace:FindFirstChild("Rooms") then return nil end
    for _, room in ipairs(workspace.Rooms:GetChildren()) do
        if room.Name:find(mode, 1, true) then
            local door = room:FindFirstChild("Door")
            local isReady = door and door:GetAttribute("Ready") == true
            if door and not isReady then
                return door
            end
        end
    end
    return nil
end

TabMain:Toggle({
    Title = "Auto Story Farm Loop",
    Desc = "บอทจะหาวาปเข้าห้องว่าง เลือกด่าน และกดเริ่มเกมให้อัตโนมัติแบบลูปไม่รู้จบ",
    Value = autoStoryFarm,
    Icon = "play",
    Callback = function(state)
        autoStoryFarm = state
        triggerAutoSave()
    end
})

TabMain:Section({ Title = "Tower Automation" })

TabMain:Toggle({
    Title = "Auto Tower (Start / Continue)",
    Desc = "เล่นโหมด Tower และกดเล่นต่อรอบให้อัตโนมัติ",
    Value = autoTowerStart,
    Icon = "castle",
    Callback = function(state)
        autoTowerStart = state
        triggerAutoSave()
    end
})

TabMain:Section({ Title = "Room Controls" })

TabMain:Toggle({
    Title = "Auto Start Current Room",
    Desc = "เมื่ออยู่ในห้องเตรียมตัว จะส่งคำสั่งเริ่มเกมให้อัตโนมัติ",
    Value = autoStartMatch,
    Icon = "circle-play",
    Callback = function(state)
        autoStartMatch = state
        triggerAutoSave()
    end
})

TabMain:Toggle({
    Title = "Auto Leave Current Room",
    Desc = "ออกจากห้องทันทีเมื่อต้องการออก",
    Value = autoLeaveMatch,
    Icon = "circle-x",
    Callback = function(state)
        autoLeaveMatch = state
        triggerAutoSave()
    end
})

TabMain:Button({
    Title = "Instant Start Room",
    Desc = "กดเริ่มเกมในห้องทันที 1 ครั้ง",
    Icon = "circle-play",
    Callback = function()
        publishRemote("Room", {Action = "Start"})
        WindUI:Notify({ Title = "Room", Content = "Started Room!", Duration = 3, Icon = "circle-check" })
    end
})

TabMain:Button({
    Title = "Instant Leave Room",
    Desc = "ออกจากห้องปัจจุบันทันที 1 ครั้ง",
    Icon = "circle-x",
    Callback = function()
        publishRemote("Room", {Action = "Leave"})
        WindUI:Notify({ Title = "Room", Content = "Left Room!", Duration = 3, Icon = "log-out" })
    end
})

-- Background loop for Farm & Story
task.spawn(function()
    while scriptRunning do
        task.wait(2)
        if autoStoryFarm then
            local inRoom = Character and Character:GetAttribute("InRoom")
            if not inRoom then
                local door = findFreeDoor("Story")
                if door and RootPart then
                    RootPart.CFrame = door.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.8)
                end
            else
                publishRemote("Room", {
                    Action = "SelectMap",
                    MapName = selectedWorld,
                    Stage = selectedStage,
                    FriendsOnly = true,
                    Nightmare = isNightmare,
                })
                task.wait(0.5)
                publishRemote("Room", {Action = "Start"})
                task.wait(3)
            end
        end

        if autoStartMatch then
            publishRemote("Room", {Action = "Start"})
        end
        if autoLeaveMatch then
            publishRemote("Room", {Action = "Leave"})
        end
        if autoTowerStart then
            publishRemote("Tower", {Action = "Start"})
            task.wait(1)
            publishRemote("Tower", {Action = "Continue"})
        end
    end
end)

-- ==============================================================================
-- TAB 2: SMART PLAY AI 🧠 (AUTONOMOUS TOWER DEFENSE MATCH ENGINE)
-- ==============================================================================
local smartStatusPara = TabSmart:Paragraph({
    Title = "Smart Play Status (สถานะระบบอัจฉริยะ)",
    Desc = "Status: ⚪ Idle | Mode: In Lobby / Waiting for match\nWave: --/-- | Base HP: --\nCash: ¥-- | Placed Towers: 0",
    Image = "cpu"
})

TabSmart:Section({ Title = "Smart Play Controls (เปิดใช้งานโหมดอัจฉริยะ)" })

TabSmart:Toggle({
    Title = "Enable Smart Play AI (โหมดเล่นอัตโนมัติอัจฉริยะ)",
    Desc = "บอทจะคำนวณจุดวางยูนิตที่ดีที่สุด อัปเกรดยูนิต กดสกิล และเปลี่ยนด่านให้อัตโนมัติ โดยไม่ต้องอัด Macro เอง!",
    Value = smartPlayEnabled,
    Icon = "cpu",
    Callback = function(state)
        smartPlayEnabled = state
        triggerAutoSave()
        WindUI:Notify({
            Title = "Smart Play AI",
            Content = state and "Smart Play AI STARTED! Autonomous match play active." or "Smart Play AI STOPPED.",
            Duration = 3.5,
            Icon = state and "circle-play" or "circle-x"
        })
    end
})

TabSmart:Dropdown({
    Title = "AI Play Strategy (กลยุทธ์การเล่น)",
    Desc = "เลือกรูปแบบและเป้าหมายของ AI ในการจัดสรรเงินและยูนิต",
    Values = { "Balanced", "Aggressive", "Greedy Economy", "Boss Killer" },
    Value = smartStrategy,
    Callback = function(val)
        smartStrategy = val
        triggerAutoSave()
        WindUI:Notify({ Title = "Strategy Changed", Content = "AI Strategy set to: " .. val, Duration = 2.5, Icon = "zap" })
    end
})

TabSmart:Section({ Title = "Tactics & Placement (การวางและอัปเกรด)" })

TabSmart:Dropdown({
    Title = "Placement Bias (ตำแหน่งจัดวางยูนิต)",
    Desc = "ตำแหน่งทางยุทธศาสตร์ที่ต้องการให้บอทเล็งวางยูนิต",
    Values = { "Best", "Front", "Back" },
    Value = smartPlacementBias,
    Callback = function(val)
        smartPlacementBias = val
        triggerAutoSave()
    end
})

TabSmart:Dropdown({
    Title = "Upgrade Priority (ลำดับการอัปเกรด)",
    Desc = "เลือกรูปแบบที่ต้องการให้อัปเกรดยูนิตในสนาม",
    Values = { "Focus Carry", "Spread Evenly", "Cheapest First", "Any" },
    Value = smartUpgradePriority,
    Callback = function(val)
        smartUpgradePriority = val
        triggerAutoSave()
    end
})

TabSmart:Toggle({
    Title = "Save Cash For Placements (สำรองเงินค่าวาง)",
    Desc = "กันเงินสำรองไว้สำหรับวางยูนิตจำเป็น ไม่ผลาญเงินไปกับอัปเกรดจนหมด",
    Value = smartSaveForPlacements,
    Icon = "shield-check",
    Callback = function(state)
        smartSaveForPlacements = state
        triggerAutoSave()
    end
})

TabSmart:Toggle({
    Title = "Sell Farms On Final Wave (ขายฟาร์มเวฟสุดท้าย)",
    Desc = "ขายตัวฟาร์มเงินคืนทุนในเวฟสุดท้าย เพื่อนำเงินทั้งหมดมาอัปเกรดตัวดาเมจสู้บอส",
    Value = smartSellFarmsFinalWave,
    Icon = "trash-2",
    Callback = function(state)
        smartSellFarmsFinalWave = state
        triggerAutoSave()
    end
})

TabSmart:Section({ Title = "Combat & Match Flow (การต่อสู้และจบเกม)" })

TabSmart:Toggle({
    Title = "Auto Cast Tower Abilities (กดสกิลยูนิตอัตโนมัติ)",
    Desc = "ตรวจจับยูนิตที่มีท่าไม้ตาย (เช่น Fireball, Roar, Pound Cannon) และกดใช้งานให้อัตโนมัติทันทีที่พร้อม",
    Value = smartAutoAbilities,
    Icon = "sparkles",
    Callback = function(state)
        smartAutoAbilities = state
        triggerAutoSave()
    end
})

TabSmart:Toggle({
    Title = "Smart Target Switching (ปรับโหมดเล็งอัตโนมัติ)",
    Desc = "ปรับตัวดาเมจเดี่ยว/บอสไปเล็ง Strongest และตัวตีหมู่ไปเล็ง First ให้อัตโนมัติ",
    Value = smartAutoTargeting,
    Icon = "crosshair",
    Callback = function(state)
        smartAutoTargeting = state
        triggerAutoSave()
    end
})

TabSmart:Toggle({
    Title = "Lock 2x Game Speed (เร่งสปีด 2x ตลอดเวลา)",
    Desc = "บังคับเปิดความเร็วเกม 2x ตลอดแมตช์เพื่อความรวดเร็วในการฟาร์ม",
    Value = smartLockSpeed2x,
    Icon = "zap",
    Callback = function(state)
        smartLockSpeed2x = state
        triggerAutoSave()
    end
})

TabSmart:Toggle({
    Title = "Smart Wave Skip (ข้ามเวฟอัตโนมัติ)",
    Desc = "ส่งคำสั่งข้ามเวฟอัตโนมัติเมื่อเลือดป้อม (Base HP) ปลอดภัย",
    Value = smartAutoSkipWave,
    Icon = "fast-forward",
    Callback = function(state)
        smartAutoSkipWave = state
        triggerAutoSave()
    end
})

TabSmart:Dropdown({
    Title = "Match Completion Action (เมื่อจบแมตช์)",
    Desc = "การกระทำอัตโนมัติเมื่อชนะการต่อสู้ในแมตช์",
    Values = { "Next", "Replay", "Return" },
    Value = smartMatchEndAction,
    Callback = function(val)
        smartMatchEndAction = val
        triggerAutoSave()
    end
})

-- Background loop for Smart Play AI
task.spawn(function()
    while scriptRunning do
        task.wait(0.8)
        local gameFolder = workspace:FindFirstChild("Game")
        local inMatch = gameFolder and gameFolder:FindFirstChild("Started") and gameFolder.Started.Value
        
        -- Live tracker update
        if smartStatusPara and smartStatusPara.SetDesc then
            if inMatch then
                local wave = gameFolder:FindFirstChild("CurrentWave") and gameFolder.CurrentWave.Value or 0
                local totalWaves = gameFolder:FindFirstChild("TotalWaves") and gameFolder.TotalWaves.Value or 0
                local mapName = gameFolder:FindFirstChild("Map") and gameFolder.Map.Value or "Story"
                local stage = gameFolder:FindFirstChild("Stage") and gameFolder.Stage.Value or 1
                local hp = gameFolder:FindFirstChild("TowerHealth") and gameFolder.TowerHealth.Value or 0
                local money = LocalPlayer:FindFirstChild("Money") and LocalPlayer.Money.Value or 0
                local myTowers = 0
                if workspace:FindFirstChild("Towers") then
                    for _, t in ipairs(workspace.Towers:GetChildren()) do
                        if t:GetAttribute("Owner") == LocalPlayer.Name then
                            myTowers = myTowers + 1
                        end
                    end
                end
                
                smartStatusPara:SetDesc(string.format(
                    "Status: %s | Strategy: %s\nMap: %s (Act %d) | Wave: %d/%d\nBase HP: %d | Cash: ¥%d | Placed Towers: %d",
                    smartPlayEnabled and "🟢 Running" or "⚪ Paused",
                    smartStrategy,
                    mapName, stage, wave, totalWaves,
                    hp, money, myTowers
                ))
            else
                smartStatusPara:SetDesc(string.format(
                    "Status: %s\nMode: In Lobby / Waiting for match to start...",
                    smartPlayEnabled and "🟡 Armed (Waiting for match)" or "⚪ Idle"
                ))
            end
        end
        
        -- Smart Play execution
        if smartPlayEnabled and inMatch then
            pcall(function()
                -- 1. Game speed
                if smartLockSpeed2x then
                    publishRemote("GameSpeed", {Speed = 2})
                end
                
                -- 2. Wave skip when safe
                if smartAutoSkipWave then
                    local hp = gameFolder:FindFirstChild("TowerHealth") and gameFolder.TowerHealth.Value or 500
                    if hp >= 350 then
                        publishRemote("Settings", {Name = "Auto Skip Wave", Value = true})
                    end
                end
                
                -- 3. Match native AutoPlay setup & trigger
                local upgMode = "Focus"
                if smartUpgradePriority == "Spread Evenly" then
                    upgMode = "Spread"
                elseif smartUpgradePriority == "Cheapest First" or smartUpgradePriority == "Any" then
                    upgMode = "Any"
                end
                local isGreedy = (smartStrategy == "Greedy Economy")
                
                publishRemote("Settings", {
                    Name = "AutoPlay",
                    Value = HttpService:JSONEncode({
                        Upgrades = upgMode,
                        Placement = smartPlacementBias,
                        FarmsFirst = isGreedy,
                        SaveForPlacements = smartSaveForPlacements,
                        SellFarmsLastWave = smartSellFarmsFinalWave,
                        StartOn = true,
                        Slots = {"Max", "Max", "Max", "Max", "Max", "Max"}
                    })
                })
                
                pcall(function()
                    local AutoPlayUi = require(ReplicatedStorage.Master.Modules.Interface_Client.AutoPlayUi)
                    if AutoPlayUi and not AutoPlayUi.Active then
                        AutoPlayUi.Toggle()
                    end
                end)
                
                -- 4. Cast tower abilities
                if smartAutoAbilities and workspace:FindFirstChild("Towers") then
                    local Abilities_Client = nil
                    pcall(function()
                        Abilities_Client = require(ReplicatedStorage.Master.Modules.Abilities_Client)
                    end)
                    for _, tower in ipairs(workspace.Towers:GetChildren()) do
                        if tower:GetAttribute("Owner") == LocalPlayer.Name and tower:GetAttribute("Ability") then
                            pcall(function()
                                if Abilities_Client and Abilities_Client.UseSkill then
                                    Abilities_Client:UseSkill(tower)
                                end
                            end)
                        end
                    end
                end
                
                -- 5. Smart Target Priority
                if smartAutoTargeting and workspace:FindFirstChild("Towers") then
                    local Towers_Client = nil
                    pcall(function()
                        Towers_Client = require(ReplicatedStorage.Master.Modules.Towers_Client)
                    end)
                    if Towers_Client then
                        for _, tower in ipairs(workspace.Towers:GetChildren()) do
                            if tower:GetAttribute("Owner") == LocalPlayer.Name then
                                local currentTarget = tower:GetAttribute("AttackType")
                                local unitName = tower:GetAttribute("Name")
                                local desiredTarget = (smartStrategy == "Boss Killer" or unitName == "Tango") and "Strongest" or "First"
                                if currentTarget and currentTarget ~= desiredTarget then
                                    pcall(function()
                                        Towers_Client:ChangeTarget(tower)
                                    end)
                                end
                            end
                        end
                    end
                end
                
                -- 6. Match End Auto Actions
                local sg = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("ScreenGui")
                local gameEnd = sg and sg:FindFirstChild("GameEnd")
                if gameEnd and gameEnd.Visible then
                    publishRemote("EndGame", smartMatchEndAction)
                end
            end)
        end
    end
end)

-- ==============================================================================
-- TAB 3: TOWER DEFENSE MACRO CONFIG (SAVE / LOAD / RECORD / PLAY)
-- ==============================================================================
local MACRO_FOLDER = "AnimeGalaxiesHub/Macros"
pcall(function()
    if not isfolder("AnimeGalaxiesHub") then makefolder("AnimeGalaxiesHub") end
    if not isfolder(MACRO_FOLDER) then makefolder(MACRO_FOLDER) end
end)

local function getSavedMacroList()
    local names = {}
    pcall(function()
        if isfolder(MACRO_FOLDER) then
            for _, f in ipairs(listfiles(MACRO_FOLDER)) do
                local clean = f:match("([^\\/]+)%.json$")
                if clean then
                    table.insert(names, clean)
                end
            end
        end
    end)
    if #names == 0 then
        table.insert(names, "Default_Tower_Farm")
    end
    return names
end

local function getEquippedUnitInSlot(slotNumber)
    local unitName = "Slot " .. tostring(slotNumber)
    pcall(function()
        local unitsFolder = LocalPlayer.Data.Units
        for _, u in ipairs(unitsFolder:GetChildren()) do
            for _, idF in ipairs(u:GetChildren()) do
                local eq = idF:FindFirstChild("Equipped")
                if eq and eq.Value == slotNumber then
                    unitName = u.Name
                    return
                end
            end
        end
    end)
    return unitName
end

local activeConfig = {
    Name = "My_Tower_Macro",
    Mode = "Tower",
    Created = os.time(),
    AutoStart = true,
    AutoNext = true,
    AutoUpgrade = true,
    Steps = {}
}

local function formatStepsDesc(steps)
    if not steps or #steps == 0 then
        return "No steps recorded yet.\nClick '➕ Record Step At Current Position' to record unit placement steps."
    end
    local lines = {}
    for i, s in ipairs(steps) do
        table.insert(lines, string.format("#%d: Slot %d (%s) at (%.1f, %.1f, %.1f) -> Lvl %d [Delay: %.1fs]",
            s.Step or i, s.Slot or 1, s.Unit or ("Slot " .. tostring(s.Slot)), s.X or 0, s.Y or 0, s.Z or 0, s.TargetLevel or 1, s.Delay or 1.0))
    end
    return table.concat(lines, "\n")
end

local macroStatusPara = TabMacro:Paragraph({
    Title = "Active Macro Profile",
    Desc = "Config: My_Tower_Macro\nTotal Steps: 0\nStatus: ⚪ Idle | Loop: Ready",
    Image = "gamepad-2"
})

TabMacro:Section({ Title = "Profile Management (Save / Load)" })

TabMacro:Input({
    Title = "Macro Config Name",
    Desc = "พิมพ์ชื่อคอนฟิกสำหรับบันทึก (Save/Load)",
    Value = macroNameInput,
    Placeholder = "Enter config name...",
    Callback = function(text)
        if text and #text > 0 then
            macroNameInput = text:gsub("[%\\/%:%*%?%\"%<%>%|]", "_")
            activeConfig.Name = macroNameInput
            triggerAutoSave()
        end
    end
})

local savedConfigsDropdown = nil
savedConfigsDropdown = TabMacro:Dropdown({
    Title = "Select Saved Config",
    Desc = "เลือกไฟล์คอนฟิกที่บันทึกไว้ในเครื่อง",
    Values = getSavedMacroList(),
    Value = selectedFileToLoad,
    Callback = function(val)
        selectedFileToLoad = val
        triggerAutoSave()
    end
})

TabMacro:Button({
    Title = "💾 Save / Overwrite Macro Config",
    Desc = "บันทึกสเต็ปและค่าคอนฟิกลงไฟล์ JSON ทันที",
    Icon = "save",
    Callback = function()
        pcall(function()
            activeConfig.Name = macroNameInput
            activeConfig.AutoStart = macroAutoStart
            activeConfig.AutoNext = macroLoopEnabled
            activeConfig.AutoUpgrade = macroAutoUpgrade
            local json = HttpService:JSONEncode(activeConfig)
            local path = MACRO_FOLDER .. "/" .. activeConfig.Name .. ".json"
            writefile(path, json)
            
            if savedConfigsDropdown then
                savedConfigsDropdown:SetValues(getSavedMacroList())
            end
            WindUI:Notify({ Title = "Macro Saved", Content = "Saved config: " .. activeConfig.Name .. " (" .. tostring(#activeConfig.Steps) .. " steps)", Duration = 3.5, Icon = "save" })
        end)
    end
})

local macroStepsSummaryPara = nil

TabMacro:Button({
    Title = "📂 Load Selected Macro Config",
    Desc = "โหลดคอนฟิกจากไฟล์ที่เลือกมาใช้งาน",
    Icon = "folder-open",
    Callback = function()
        pcall(function()
            local path = MACRO_FOLDER .. "/" .. selectedFileToLoad .. ".json"
            if isfile(path) then
                local data = HttpService:JSONDecode(readfile(path))
                activeConfig = data
                macroNameInput = data.Name or selectedFileToLoad
                
                if macroStepsSummaryPara and macroStepsSummaryPara.SetDesc then
                    macroStepsSummaryPara:SetDesc(formatStepsDesc(activeConfig.Steps))
                end
                if macroStatusPara and macroStatusPara.SetDesc then
                    macroStatusPara:SetDesc(string.format("Config: %s\nTotal Steps: %d\nStatus: %s",
                        activeConfig.Name,
                        #activeConfig.Steps,
                        macroPlaybackEnabled and "🟢 Running" or "⚪ Idle"
                    ))
                end
                WindUI:Notify({ Title = "Macro Loaded", Content = "Loaded " .. activeConfig.Name .. " with " .. tostring(#activeConfig.Steps) .. " steps!", Duration = 3.5, Icon = "folder-check" })
            else
                WindUI:Notify({ Title = "Error", Content = "File not found: " .. selectedFileToLoad, Duration = 3, Icon = "circle-x" })
            end
        end)
    end
})

TabMacro:Button({
    Title = "🗑️ Delete Selected Config",
    Desc = "ลบไฟล์คอนฟิกที่เลือกออกจากเครื่อง",
    Icon = "trash-2",
    Callback = function()
        pcall(function()
            local path = MACRO_FOLDER .. "/" .. selectedFileToLoad .. ".json"
            if isfile(path) then
                delfile(path)
                if savedConfigsDropdown then
                    savedConfigsDropdown:SetValues(getSavedMacroList())
                end
                WindUI:Notify({ Title = "Macro Deleted", Content = "Deleted " .. selectedFileToLoad, Duration = 3, Icon = "trash-2" })
            end
        end)
    end
})

TabMacro:Button({
    Title = "🔄 Refresh Config List",
    Desc = "รีเฟรชรายชื่อคอนฟิกในโฟลเดอร์",
    Icon = "refresh-cw",
    Callback = function()
        if savedConfigsDropdown then
            savedConfigsDropdown:SetValues(getSavedMacroList())
            WindUI:Notify({ Title = "Macro", Content = "Refreshed macro list!", Duration = 2, Icon = "circle-check" })
        end
    end
})

TabMacro:Section({ Title = "Macro Step Builder (สร้างสเต็ปการเล่น)" })

TabMacro:Dropdown({
    Title = "Select Unit Slot to Place",
    Desc = "เลือก Slot ยูนิตในทีมที่จะใช้วาง (Slot 1 ถึง 6)",
    Values = { "Slot 1", "Slot 2", "Slot 3", "Slot 4", "Slot 5", "Slot 6" },
    Value = "Slot " .. tostring(selectedBuilderSlot),
    Callback = function(val)
        local num = tonumber(val:match("%d+"))
        if num then selectedBuilderSlot = num end
    end
})

TabMacro:Slider({
    Title = "Target Upgrade Level",
    Desc = "ระดับเป้าหมายที่ต้องการให้อัปเกรดหลังวาง (1 - 10)",
    Value = { Min = 1, Max = 10, Default = selectedTargetLevel },
    Step = 1,
    Callback = function(val)
        selectedTargetLevel = val
    end
})

TabMacro:Slider({
    Title = "Step Delay After Action",
    Desc = "เวลาหน่วง (วินาที) หลังทำสเต็ปนี้เสร็จก่อนไปสเต็ปถัดไป",
    Value = { Min = 0.5, Max = 10, Default = selectedStepDelay },
    Step = 0.5,
    Callback = function(val)
        selectedStepDelay = val
    end
})

TabMacro:Button({
    Title = "➕ Record Step At Current Position (บันทึกจุดที่ยืนอยู่)",
    Desc = "จับพิกัด (X, Y, Z) ปัจจุบันของผู้เล่นและบันทึกเป็นสเต็ปใหม่ทันที",
    Icon = "circle-plus",
    Callback = function()
        pcall(function()
            local pos = RootPart and RootPart.Position or Vector3.new(0, 0, 0)
            local unitName = getEquippedUnitInSlot(selectedBuilderSlot)
            local newStep = {
                Step = #activeConfig.Steps + 1,
                Slot = selectedBuilderSlot,
                Unit = unitName,
                X = math.floor(pos.X * 10) / 10,
                Y = math.floor(pos.Y * 10) / 10,
                Z = math.floor(pos.Z * 10) / 10,
                TargetLevel = selectedTargetLevel,
                Delay = selectedStepDelay,
            }
            table.insert(activeConfig.Steps, newStep)
            
            if macroStepsSummaryPara and macroStepsSummaryPara.SetDesc then
                macroStepsSummaryPara:SetDesc(formatStepsDesc(activeConfig.Steps))
            end
            if macroStatusPara and macroStatusPara.SetDesc then
                macroStatusPara:SetDesc(string.format("Config: %s\nTotal Steps: %d\nStatus: %s",
                    activeConfig.Name,
                    #activeConfig.Steps,
                    macroPlaybackEnabled and "🟢 Running" or "⚪ Idle"
                ))
            end
            WindUI:Notify({ Title = "Step Added", Content = string.format("Added Step %d: %s at (%.1f, %.1f, %.1f)", newStep.Step, unitName, newStep.X, newStep.Y, newStep.Z), Duration = 3, Icon = "circle-check" })
        end)
    end
})

TabMacro:Button({
    Title = "🗑️ Clear All Recorded Steps",
    Desc = "ล้างสเต็ปทั้งหมดในคอนฟิกปัจจุบัน",
    Icon = "trash-2",
    Callback = function()
        activeConfig.Steps = {}
        if macroStepsSummaryPara and macroStepsSummaryPara.SetDesc then
            macroStepsSummaryPara:SetDesc(formatStepsDesc(activeConfig.Steps))
        end
        if macroStatusPara and macroStatusPara.SetDesc then
            macroStatusPara:SetDesc(string.format("Config: %s\nTotal Steps: 0\nStatus: %s",
                activeConfig.Name,
                macroPlaybackEnabled and "🟢 Running" or "⚪ Idle"
            ))
        end
        WindUI:Notify({ Title = "Macro", Content = "Cleared all recorded steps!", Duration = 2.5, Icon = "trash-2" })
    end
})

macroStepsSummaryPara = TabMacro:Paragraph({
    Title = "Recorded Steps Summary (รายการสเต็ป)",
    Desc = formatStepsDesc(activeConfig.Steps),
    Image = "file-text"
})

TabMacro:Section({ Title = "Macro Playback Controls (เปิดใช้งาน Macro)" })

TabMacro:Toggle({
    Title = "Enable TD Macro Playback",
    Desc = "เปิดระบบทำงานอัตโนมัติตามสเต็ป Macro ที่บันทึกไว้",
    Value = macroPlaybackEnabled,
    Icon = "play",
    Callback = function(state)
        macroPlaybackEnabled = state
        currentMacroStep = 0
        triggerAutoSave()
        if macroStatusPara and macroStatusPara.SetDesc then
            macroStatusPara:SetDesc(string.format("Config: %s\nTotal Steps: %d\nStatus: %s",
                activeConfig.Name,
                #activeConfig.Steps,
                macroPlaybackEnabled and "🟢 Running" or "⚪ Idle"
            ))
        end
        WindUI:Notify({ Title = "TD Macro", Content = state and "Macro playback STARTED!" or "Macro playback STOPPED.", Duration = 3, Icon = state and "circle-play" or "circle-x" })
    end
})

TabMacro:Toggle({
    Title = "Loop Macro On Next Match",
    Desc = "วนลูป Macro ซ้ำให้อัตโนมัติเมื่อเริ่มเกมรอบใหม่",
    Value = macroLoopEnabled,
    Icon = "repeat",
    Callback = function(state)
        macroLoopEnabled = state
        triggerAutoSave()
    end
})

TabMacro:Toggle({
    Title = "Auto Upgrade Placed Units",
    Desc = "ส่งคำสั่งอัปเกรดยูนิตที่วางไว้ต่อเนื่องจนถึง Target Level",
    Value = macroAutoUpgrade,
    Icon = "wand",
    Callback = function(state)
        macroAutoUpgrade = state
        triggerAutoSave()
    end
})

TabMacro:Toggle({
    Title = "Auto Start & Continue Match",
    Desc = "กดเริ่มแมตช์และกดเล่นต่อรอบให้อัตโนมัติ",
    Value = macroAutoStart,
    Icon = "circle-play",
    Callback = function(state)
        macroAutoStart = state
        triggerAutoSave()
    end
})

-- Background loop for Macro Playback
task.spawn(function()
    while scriptRunning do
        task.wait(1)
        if macroPlaybackEnabled and #activeConfig.Steps > 0 then
            pcall(function()
                if macroAutoStart then
                    publishRemote("Room", {Action = "Start"})
                    publishRemote("Tower", {Action = "Start"})
                    task.wait(0.5)
                    publishRemote("Tower", {Action = "Continue"})
                end
                
                if currentMacroStep < #activeConfig.Steps then
                    currentMacroStep = currentMacroStep + 1
                    local step = activeConfig.Steps[currentMacroStep]
                    if step then
                        if RootPart and step.X and step.Y and step.Z then
                            pcall(function()
                                RootPart.CFrame = CFrame.new(Vector3.new(step.X, step.Y, step.Z))
                            end)
                        end
                        
                        pcall(function()
                            publishRemote("Tower", {Action = "Start"})
                        end)
                        
                        if macroAutoUpgrade then
                            pcall(function()
                                publishRemote("Tower", {Action = "Continue"})
                            end)
                        end
                        
                        task.wait(step.Delay or 1.5)
                    end
                elseif macroLoopEnabled then
                    task.wait(3)
                    currentMacroStep = 0
                end
            end)
        end
    end
end)

-- ==============================================================================
-- TAB 4: AUTO REWARDS & CODES
-- ==============================================================================
TabRewards:Section({ Title = "Automatic Reward Claims" })

TabRewards:Toggle({
    Title = "Auto Claim Daily Rewards",
    Desc = "รับของขวัญประจำวันอัตโนมัติเมื่อครบเวลา",
    Value = autoDaily,
    Icon = "calendar-check",
    Callback = function(state)
        autoDaily = state
        triggerAutoSave()
    end
})

TabRewards:Toggle({
    Title = "Auto Claim Season Pass",
    Desc = "รับรางวัลเลเวล Battle Pass / Season Pass อัตโนมัติ",
    Value = autoSeasonPass,
    Icon = "award",
    Callback = function(state)
        autoSeasonPass = state
        triggerAutoSave()
    end
})

TabRewards:Toggle({
    Title = "Auto Claim Index Unit Rewards",
    Desc = "รับของรางวัลจากการสะสมตัวละครในสมุด Index อัตโนมัติ",
    Value = autoIndex,
    Icon = "book-open",
    Callback = function(state)
        autoIndex = state
        triggerAutoSave()
    end
})

TabRewards:Toggle({
    Title = "Auto Claim All Quests",
    Desc = "รับรางวัลเควสที่ทำสำเร็จทั้งหมด (Daily, Weekly, Infinite, Event)",
    Value = autoQuests,
    Icon = "check",
    Callback = function(state)
        autoQuests = state
        triggerAutoSave()
    end
})

TabRewards:Toggle({
    Title = "Auto Claim Level Milestones",
    Desc = "รับรางวัลทุกครั้งที่เลเวลอัปตาม Milestones (Gems, Stat Tokens, Trait Crystals)",
    Value = autoLevelMilestones,
    Icon = "badge-check",
    Callback = function(state)
        autoLevelMilestones = state
        triggerAutoSave()
    end
})

TabRewards:Section({ Title = "One-Click Quick Claims & Codes" })

local knownCodes = {
    "1KLIKES",
    "100KVIS",
    "1KFAV",
    "RELEASE",
    "TRAITS",
    "UPDATE1",
    "THANKYOU",
    "100KLIKES",
    "GALAXYEVENT",
    "GALAXYGEMS",
    "2KCCU",
    "3KCCU",
    "INVITED"
}

TabRewards:Button({
    Title = "Claim All Pending Rewards Now",
    Desc = "กดปุ่มเดียวเพื่อส่งคำสั่งรับรางวัลทุกหมวดหมู่ทันที 1 ครั้ง",
    Icon = "gift",
    Callback = function()
        publishRemote("Rewards", {Type = "Daily"})
        publishRemote("Rewards", {Type = "SeasonPass"})
        publishRemote("Rewards", {Type = "IndexReward"})
        for i = 1, 6 do
            publishRemote("Rewards", {Type = "Quest", Category = "Daily", Index = i})
            publishRemote("Rewards", {Type = "Quest", Category = "Weekly", Index = i})
            publishRemote("Rewards", {Type = "Quest", Category = "Infinite", Index = i})
            publishRemote("Rewards", {Type = "Quest", Category = "Event", Index = i})
        end
        if LevelRewardsInfo and LocalPlayer:FindFirstChild("Data") then
            local claimable = LevelRewardsInfo.claimable(LocalPlayer.Data)
            for _, lvl in ipairs(claimable) do
                publishRemote("LevelRewards", {Level = lvl})
            end
        end
        WindUI:Notify({ Title = "Rewards", Content = "Triggered claim for all rewards!", Duration = 3, Icon = "sparkles" })
    end
})

TabRewards:Button({
    Title = "Redeem All Active Codes",
    Desc = "กดปุ่มเดียวเติมโค้ดรับเพชรและไอเทมทั้งหมดฟรี!",
    Icon = "key",
    Callback = function()
        WindUI:Notify({ Title = "Codes", Content = "Redeeming all codes...", Duration = 3, Icon = "loader" })
        task.spawn(function()
            for _, code in ipairs(knownCodes) do
                publishRemote("Rewards", {Type = "Code", Code = code})
                task.wait(0.25)
            end
            WindUI:Notify({ Title = "Codes", Content = "All active codes redeemed successfully!", Duration = 5, Icon = "sparkles" })
        end)
    end
})

-- Background loop for rewards
task.spawn(function()
    while scriptRunning do
        task.wait(4)
        if autoDaily then
            publishRemote("Rewards", {Type = "Daily"})
        end
        if autoSeasonPass then
            publishRemote("Rewards", {Type = "SeasonPass"})
        end
        if autoIndex then
            publishRemote("Rewards", {Type = "IndexReward"})
        end
        if autoQuests then
            for i = 1, 6 do
                publishRemote("Rewards", {Type = "Quest", Category = "Daily", Index = i})
                publishRemote("Rewards", {Type = "Quest", Category = "Weekly", Index = i})
                publishRemote("Rewards", {Type = "Quest", Category = "Infinite", Index = i})
                publishRemote("Rewards", {Type = "Quest", Category = "Event", Index = i})
            end
        end
        if autoLevelMilestones and LevelRewardsInfo and LocalPlayer:FindFirstChild("Data") then
            pcall(function()
                local claimable = LevelRewardsInfo.claimable(LocalPlayer.Data)
                for _, lvl in ipairs(claimable) do
                    publishRemote("LevelRewards", {Level = lvl})
                end
            end)
        end
    end
end)

-- ==============================================================================
-- TAB 5: AUTO SUMMON & GACHA
-- ==============================================================================
TabSummon:Section({ Title = "Auto Summon Controls" })

TabSummon:Dropdown({
    Title = "Select Banner",
    Desc = "เลือกตู้ตัวละครที่ต้องการสุ่ม",
    Values = { "Standard", "Special" },
    Value = summonBanner,
    Callback = function(val)
        summonBanner = val
        triggerAutoSave()
    end
})

TabSummon:Dropdown({
    Title = "Pull Amount",
    Desc = "เลือกจำนวนครั้งต่อการสุ่ม",
    Values = { "1", "10" },
    Value = tostring(summonCount),
    Callback = function(val)
        summonCount = tonumber(val) or 10
        triggerAutoSave()
    end
})

TabSummon:Toggle({
    Title = "Auto Summon (Spam Pull)",
    Desc = "สุ่มตัวละครต่อเนื่องอัตโนมัติเมื่อเพชรพอ",
    Value = autoSummon,
    Icon = "repeat",
    Callback = function(state)
        autoSummon = state
        triggerAutoSave()
    end
})

TabSummon:Toggle({
    Title = "Auto Open Event Capsules",
    Desc = "เปิดแคปซูลอีเวนต์อัตโนมัติเมื่อได้รับในกระเป๋า",
    Value = autoCapsules,
    Icon = "package",
    Callback = function(state)
        autoCapsules = state
        triggerAutoSave()
    end
})

TabSummon:Button({
    Title = "Summon Once (ทันที)",
    Desc = "กดสุ่มตามตู้และจำนวนที่เลือก 1 ครั้ง",
    Icon = "sparkles",
    Callback = function()
        publishRemote("Summon", {Amount = summonCount, Type = summonBanner})
        WindUI:Notify({ Title = "Summon", Content = "Summoned " .. tostring(summonCount) .. "x on " .. summonBanner, Duration = 3, Icon = "gift" })
    end
})

TabSummon:Section({ Title = "Built-in Autosell Settings" })

TabSummon:Toggle({
    Title = "Autosell: Rare Units",
    Desc = "เปิดระบบขายตัวละครระดับ Rare อัตโนมัติเวลาสุ่มได้",
    Value = false,
    Icon = "trash-2",
    Callback = function(state)
        publishRemote("Settings", {Name = "Rare", Value = state})
    end
})

TabSummon:Toggle({
    Title = "Autosell: Epic Units",
    Desc = "เปิดระบบขายตัวละครระดับ Epic อัตโนมัติเวลาสุ่มได้",
    Value = false,
    Icon = "trash-2",
    Callback = function(state)
        publishRemote("Settings", {Name = "Epic", Value = state})
    end
})

TabSummon:Toggle({
    Title = "Autosell: Legendary Units",
    Desc = "เปิดระบบขายตัวละครระดับ Legendary อัตโนมัติเวลาสุ่มได้",
    Value = false,
    Icon = "trash-2",
    Callback = function(state)
        publishRemote("Settings", {Name = "Legendary", Value = state})
    end
})

task.spawn(function()
    while scriptRunning do
        task.wait(1)
        if autoSummon then
            publishRemote("Summon", {Amount = summonCount, Type = summonBanner})
        end
        if autoCapsules then
            publishRemote("Summon", {Amount = 1, Type = "Event"})
        end
    end
end)

-- ==============================================================================
-- TAB 6: AUTO UNITS & STATS (MANAGEMENT, ROLLS, FEEDING)
-- ==============================================================================
TabUnits:Section({ Title = "Unit Protection & Cleanup" })

TabUnits:Toggle({
    Title = "Auto Lock Mythic & Secret",
    Desc = "ตรวจจับและล็อคตัวละครระดับ Mythic และ Secret ทุกตัวอัตโนมัติ เพื่อป้องกันการเผลอขาย",
    Value = autoLockHighRarity,
    Icon = "lock",
    Callback = function(state)
        autoLockHighRarity = state
        triggerAutoSave()
    end
})

TabUnits:Button({
    Title = "Auto Sell All Duplicates (ขายตัวซ้ำ)",
    Desc = "สแกนหาตัวละครระดับ Rare/Epic ที่ซ้ำ ไม่ได้ใส่ และไม่ได้ล็อค แล้วส่งคำสั่งขายทั้งหมดทันที",
    Icon = "trash-2",
    Callback = function()
        local toSell = {}
        pcall(function()
            local units = LocalPlayer.Data.Units
            for _, u in ipairs(units:GetChildren()) do
                local kids = u:GetChildren()
                if #kids > 1 then
                    for i = 2, #kids do
                        local idF = kids[i]
                        local isEq = idF:FindFirstChild("Equipped") and idF.Equipped.Value > 0
                        local isLocked = idF:FindFirstChild("Locked") ~= nil
                        if not isEq and not isLocked then
                            table.insert(toSell, {Name = u.Name, Id = idF.Name})
                        end
                    end
                end
            end
        end)
        if #toSell > 0 then
            publishRemote("Unit", {Action = "Sell", Selling = toSell})
            WindUI:Notify({ Title = "Units", Content = "Sold " .. tostring(#toSell) .. " duplicate units!", Duration = 3.5, Icon = "trash-2" })
        else
            WindUI:Notify({ Title = "Units", Content = "No unlocked duplicates found to sell.", Duration = 2.5, Icon = "circle-check" })
        end
    end
})

TabUnits:Section({ Title = "Auto Feeding (Level Up)" })

TabUnits:Button({
    Title = "Feed All Food to Equipped Units",
    Desc = "ป้อนอาหารที่มีทั้งหมด (Ramen, Meat, Super Bean ฯลฯ) ให้ตัวละครที่ใส่อยู่ทันที",
    Icon = "coffee",
    Callback = function()
        pcall(function()
            local units = LocalPlayer.Data.Units
            local foods = { "Ramen", "Meat", "Super Bean", "Soul Chocolate", "Bread" }
            for _, u in ipairs(units:GetChildren()) do
                for _, idF in ipairs(u:GetChildren()) do
                    if idF:FindFirstChild("Equipped") and idF.Equipped.Value > 0 then
                        local payload = { Action = "Feed", Name = u.Name, Id = idF.Name }
                        for _, food in ipairs(foods) do
                            payload[food] = 50
                        end
                        publishRemote("Unit", payload)
                    end
                end
            end
        end)
        WindUI:Notify({ Title = "Feeding", Content = "Fed available food to equipped units!", Duration = 3, Icon = "coffee" })
    end
})

TabUnits:Section({ Title = "Auto Trait & Stat Reroll" })

local ownedDropdown = TabUnits:Dropdown({
    Title = "Select Unit for Rolls",
    Desc = "เลือกตัวละครในกระเป๋าที่ต้องการสุ่ม Trait หรือ Stats",
    Values = getOwnedUnitsList(),
    Value = getOwnedUnitsList()[1] or "None",
    Callback = function(val)
        local uName, uId = val:match("^(.-)%s*%(ID:%s*(%d+)%)")
        if uName and uId then
            selectedTargetUnit = uName
            selectedTargetId = uId
            triggerAutoSave()
        end
    end
})

TabUnits:Button({
    Title = "Refresh Owned Units Dropdown",
    Desc = "อัปเดตรายชื่อตัวละครในเมนูเลือกตัว",
    Icon = "refresh-cw",
    Callback = function()
        ownedDropdown:SetValues(getOwnedUnitsList())
        WindUI:Notify({ Title = "Units", Content = "Refreshed units list!", Duration = 2, Icon = "check" })
    end
})

TabUnits:Toggle({
    Title = "Auto Trait Roll Loop",
    Desc = "สุ่ม Trait ให้ตัวละครที่เลือกอย่างต่อเนื่อง (ใช้ Trait Crystals)",
    Value = autoTraitRoll,
    Icon = "dices",
    Callback = function(state)
        autoTraitRoll = state
        triggerAutoSave()
    end
})

TabUnits:Toggle({
    Title = "Auto Stat Roll Loop",
    Desc = "สุ่ม Stats (Damage, Cooldown, Range) ให้ตัวละครที่เลือกต่อเนื่อง (ใช้ Stat Tokens)",
    Value = autoStatRoll,
    Icon = "wand",
    Callback = function(state)
        autoStatRoll = state
        triggerAutoSave()
    end
})

-- Background loop for Unit Management, Lock, and Rolls
task.spawn(function()
    while scriptRunning do
        task.wait(2)
        if autoLockHighRarity and ChampionsInfo and LocalPlayer:FindFirstChild("Data") then
            pcall(function()
                local units = LocalPlayer.Data.Units
                for _, u in ipairs(units:GetChildren()) do
                    local champ = ChampionsInfo(u.Name)
                    local rarity = champ and champ.Rarity
                    if rarity == "Mythic" or rarity == "Secret" then
                        for _, idF in ipairs(u:GetChildren()) do
                            if not idF:FindFirstChild("Locked") then
                                publishRemote("Unit", {Action = "Lock", UnitName = u.Name, Id = idF.Name})
                            end
                        end
                    end
                end
            end)
        end

        if autoTraitRoll and selectedTargetUnit and selectedTargetId then
            publishRemote("Traits", {Name = selectedTargetUnit, Id = selectedTargetId})
        end

        if autoStatRoll and selectedTargetUnit and selectedTargetId then
            publishRemote("StatRoll", {
                Unit = {Name = selectedTargetUnit, Id = selectedTargetId},
                ToRoll = {"Damage", "Cooldown", "Range"}
            })
        end
    end
end)

-- ==============================================================================
-- TAB 7: TELEPORTS
-- ==============================================================================
TabTeleports:Section({ Title = "Lobby Teleports" })

local function safeTeleport(targetPos)
    if RootPart then
        RootPart.CFrame = CFrame.new(targetPos) + Vector3.new(0, 3, 0)
    end
end

TabTeleports:Button({
    Title = "Teleport: Codes Area (บ่อน้ำโค้ด)",
    Desc = "วาปไปยังจุดเติมโค้ดรับรางวัล",
    Icon = "key",
    Callback = function()
        safeTeleport(Vector3.new(-264.10, 624.5, 257.07))
        WindUI:Notify({ Title = "Teleport", Content = "Teleported to Codes Area", Duration = 3, Icon = "map-pin" })
    end
})

TabTeleports:Button({
    Title = "Teleport: Summon Area (แท่นสุ่ม)",
    Desc = "วาปไปยังแท่นสุ่มตัวละคร Gacha",
    Icon = "sparkles",
    Callback = function()
        safeTeleport(Vector3.new(-17.55, 630.0, 332.52))
        WindUI:Notify({ Title = "Teleport", Content = "Teleported to Summon Area", Duration = 3, Icon = "map-pin" })
    end
})

TabTeleports:Button({
    Title = "Teleport: Evolve Area (จุดวิวัฒนาการ)",
    Desc = "วาปไปยังจุดอัปเกรด/วิวัฒนาการตัวละคร",
    Icon = "zap",
    Callback = function()
        safeTeleport(Vector3.new(-344.60, 629.0, 698.09))
        WindUI:Notify({ Title = "Teleport", Content = "Teleported to Evolve Area", Duration = 3, Icon = "map-pin" })
    end
})

TabTeleports:Button({
    Title = "Teleport: Battle / Play Area (ลงแมพ)",
    Desc = "วาปไปยังจุดเลือกด่านและลงต่อสู้",
    Icon = "swords",
    Callback = function()
        safeTeleport(Vector3.new(-343.32, 628.5, 96.54))
        WindUI:Notify({ Title = "Teleport", Content = "Teleported to Battle Area", Duration = 3, Icon = "map-pin" })
    end
})

TabTeleports:Button({
    Title = "Teleport to AFK Chamber",
    Desc = "วาปเข้าห้อง AFK เพื่อรับเพชรและของรางวัลตลอดเวลา",
    Icon = "coffee",
    Callback = function()
        publishRemote("Teleport", {Area = "AFK"})
        WindUI:Notify({ Title = "Teleport", Content = "Teleporting to AFK Chamber...", Duration = 3, Icon = "coffee" })
    end
})

-- ==============================================================================
-- TAB 8: PLAYER & MISC
-- ==============================================================================
TabPlayer:Section({ Title = "Character & Movement" })

TabPlayer:Slider({
    Title = "WalkSpeed",
    Desc = "ปรับความเร็วในการเดินของตัวละคร",
    Value = { Min = 16, Max = 150, Default = customSpeed },
    Step = 1,
    Callback = function(val)
        customSpeed = val
        if speedEnabled and Humanoid then
            Humanoid.WalkSpeed = customSpeed
        end
        triggerAutoSave()
    end
})

TabPlayer:Toggle({
    Title = "Enable WalkSpeed",
    Desc = "เปิด/ปิด การใช้งานความเร็วที่กำหนด",
    Value = speedEnabled,
    Icon = "zap",
    Callback = function(state)
        speedEnabled = state
        if Humanoid then
            Humanoid.WalkSpeed = state and customSpeed or 16
        end
        triggerAutoSave()
    end
})

TabPlayer:Slider({
    Title = "JumpPower",
    Desc = "ปรับแรงกระโดดของตัวละคร",
    Value = { Min = 50, Max = 200, Default = customJump },
    Step = 1,
    Callback = function(val)
        customJump = val
        if jumpEnabled and Humanoid then
            Humanoid.JumpPower = customJump
        end
        triggerAutoSave()
    end
})

TabPlayer:Toggle({
    Title = "Enable JumpPower",
    Desc = "เปิด/ปิด การใช้งานแรงกระโดดที่กำหนด",
    Value = jumpEnabled,
    Icon = "arrow-up",
    Callback = function(state)
        jumpEnabled = state
        if Humanoid then
            Humanoid.JumpPower = state and customJump or 50
        end
        triggerAutoSave()
    end
})

TabPlayer:Toggle({
    Title = "Infinite Jump",
    Desc = "กระโดดกลางอากาศได้ต่อเนื่องไม่จำกัด",
    Value = infJump,
    Icon = "feather",
    Callback = function(state)
        infJump = state
        triggerAutoSave()
    end
})

UserInputService.JumpRequest:Connect(function()
    if infJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

TabPlayer:Toggle({
    Title = "Noclip",
    Desc = "เดินทะลุกำแพงและสิ่งกีดขวางทุกชนิด",
    Value = noclip,
    Icon = "ghost",
    Callback = function(state)
        noclip = state
        triggerAutoSave()
    end
})

RunService.Stepped:Connect(function()
    if speedEnabled and Humanoid and Humanoid.WalkSpeed ~= customSpeed then
        Humanoid.WalkSpeed = customSpeed
    end
    if jumpEnabled and Humanoid and Humanoid.JumpPower ~= customJump then
        Humanoid.JumpPower = customJump
    end
    if noclip and Character then
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

TabPlayer:Section({ Title = "Utility & Protection" })

TabPlayer:Toggle({
    Title = "Anti-AFK (กันหลุด 20 นาที)",
    Desc = "ป้องกัน Roblox เตะออกจากเกมเวลาเปิดฟาร์มทิ้งไว้",
    Value = antiAfkEnabled,
    Icon = "shield-check",
    Callback = function(state)
        antiAfkEnabled = state
        triggerAutoSave()
    end
})

LocalPlayer.Idled:Connect(function()
    if antiAfkEnabled then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end
end)

TabPlayer:Button({
    Title = "Rejoin Server",
    Desc = "เชื่อมต่อกลับเข้าเซิร์ฟเวอร์เดิมใหม่อีกครั้ง",
    Icon = "refresh-cw",
    Callback = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

-- ==============================================================================
-- TAB 9: DYNAMIC FX & UI CUSTOMIZATION
-- ==============================================================================
TabFX:Section({ Title = "Live Animated Effects" })

TabFX:Toggle({
    Title = "Rotating Chroma Glow Border",
    Desc = "ขอบแสงนีออนไล่เฉดสีหมุนวนรอบหน้าต่างอย่างต่อเนื่อง",
    Value = fxChromaEnabled,
    Icon = "sparkles",
    Callback = function(state)
        fxChromaEnabled = state
        if currentStroke and currentStroke.Parent then
            currentStroke.Enabled = state
        end
        triggerAutoSave()
    end
})

TabFX:Toggle({
    Title = "Cosmic Floating Particles",
    Desc = "ละอองดาวคอสมิกลอยพริ้วไหวในพื้นหลังเมนู",
    Value = fxParticlesEnabled,
    Icon = "sparkles",
    Callback = function(state)
        fxParticlesEnabled = state
        if currentParticleCanvas and currentParticleCanvas.Parent then
            currentParticleCanvas.Visible = state
        end
        triggerAutoSave()
    end
})

TabFX:Toggle({
    Title = "Laser Pulse Underline",
    Desc = "เส้นแสงเลเซอร์ใต้ Title Bar ส่องสว่างแบบไดนามิก",
    Value = fxLaserBarEnabled,
    Icon = "zap",
    Callback = function(state)
        fxLaserBarEnabled = state
        if currentNeonBar and currentNeonBar.Parent then
            currentNeonBar.Visible = state
        end
        triggerAutoSave()
    end
})

TabFX:Slider({
    Title = "FX Animation Speed",
    Desc = "ปรับความเร็วของการหมุนและการเคลื่อนไหวของแอนิเมชัน",
    Value = { Min = 0.5, Max = 3, Default = fxSpeed },
    Step = 0.1,
    Callback = function(val)
        fxSpeed = val
        triggerAutoSave()
    end
})

TabFX:Section({ Title = "Themes & Transparency" })

TabFX:Dropdown({
    Title = "Select Base Theme",
    Desc = "เปลี่ยนธีมสีของหน้าต่างเมนูได้ทันที (Dark, Rose, Plant, Amber, Red, Indigo, Sky, Violet, Light)",
    Values = { "Dark", "Rose", "Plant", "Amber", "Red", "Indigo", "Sky", "Violet", "Light" },
    Value = selectedBaseTheme or "Dark",
    Callback = function(themeName)
        pcall(function()
            selectedBaseTheme = themeName
            if WindUI and WindUI.SetTheme then
                WindUI:SetTheme(themeName)
            elseif Window and Window.SetTheme then
                Window:SetTheme(themeName)
            end
            triggerAutoSave()
            WindUI:Notify({ Title = "Theme Changed", Content = "Theme switched to " .. themeName, Duration = 2.5, Icon = "palette" })
        end)
    end
})

TabFX:Slider({
    Title = "UI Transparency",
    Desc = "ปรับระดับความโปร่งใสของหน้าต่าง",
    Value = { Min = 0, Max = 1, Default = selectedTransparency or 0 },
    Step = 0.1,
    Callback = function(val)
        selectedTransparency = val
        pcall(function()
            if Window and Window.SetBackgroundTransparency then
                Window:SetBackgroundTransparency(val)
            elseif Window and Window.ToggleTransparency then
                Window:ToggleTransparency(val > 0)
            end
        end)
        triggerAutoSave()
    end
})

-- TAB 10: CONFIG & AUTO-EXECUTE (SAVE / LOAD / SINGLETON SYNC)
-- ==============================================================================
local function getStatusText()
    return string.format(
        "Current Executor: %s\nTeleport Hook (UNC): %s\nActive Profile: %s\nAuto-Save on Change: %s\n----------------------------------------\nMaster Auto-Execute: %s\nTeleport Re-Execute (Cross-Executor): %s\nAutoExec File (Game Launch): %s\nSingleton Window Guard: 🟢 Enabled (1 Window Only)",
        executorName,
        hasQueueTeleport and "🟢 Supported" or "🟡 Not Detected",
        currentConfigName,
        autoSaveConfig and "🟢 ON" or "⚪ OFF",
        autoExecuteMaster and "🟢 ON" or "🔴 OFF",
        (autoExecuteMaster and autoTeleportQueue and hasQueueTeleport) and "🟢 ON" or "⚪ OFF",
        (autoExecuteMaster and autoExecFile) and "🟢 Active" or "⚪ Disabled"
    )
end

local configStatusPara = TabConfig:Paragraph({
    Title = "Configuration & Persistence Status",
    Desc = getStatusText(),
    Image = "settings"
})

local function updateConfigStatusText()
    if configStatusPara and configStatusPara.SetDesc then
        configStatusPara:SetDesc(getStatusText())
    end
end

TabConfig:Section({ Title = "Profile Management (Save / Load)" })

TabConfig:Input({
    Title = "Config Profile Name",
    Desc = "พิมพ์ชื่อโปรไฟล์การตั้งค่าที่ต้องการเซฟ",
    Value = currentConfigName,
    Placeholder = "Default_Config",
    Callback = function(text)
        if text and #text > 0 then
            currentConfigName = text:gsub("[^%w_%-]", "_")
        end
    end
})

local savedConfigsDrop = nil
savedConfigsDrop = TabConfig:Dropdown({
    Title = "Select Saved Profile",
    Desc = "เลือกไฟล์คอนฟิกที่เซฟไว้ในเครื่อง",
    Values = getSavedConfigsList(),
    Value = currentConfigName,
    Callback = function(val)
        currentConfigName = val
    end
})

TabConfig:Button({
    Title = "💾 Save Current Configuration",
    Desc = "บันทึกการตั้งค่าทั้งหมด (ทุกแท็บ ทุกสวิตช์) ลงไฟล์ทันที",
    Icon = "save",
    Callback = function()
        saveConfigToFile(currentConfigName)
        if savedConfigsDrop then
            savedConfigsDrop:SetValues(getSavedConfigsList())
        end
        updateConfigStatusText()
        WindUI:Notify({ Title = "Config Saved", Content = "Saved settings to: " .. currentConfigName .. ".json", Duration = 3.5, Icon = "save" })
    end
})

TabConfig:Button({
    Title = "📂 Load Selected Configuration",
    Desc = "โหลดการตั้งค่าจากไฟล์ที่เลือกมาใช้งานทันที",
    Icon = "folder-open",
    Callback = function()
        local ok = loadConfigFromFile(currentConfigName)
        if ok then
            updateConfigStatusText()
            WindUI:Notify({ Title = "Config Loaded", Content = "Successfully loaded " .. currentConfigName .. "!", Duration = 3.5, Icon = "folder-check" })
        else
            WindUI:Notify({ Title = "Config Error", Content = "Could not find file: " .. currentConfigName, Duration = 3, Icon = "circle-x" })
        end
    end
})

TabConfig:Button({
    Title = "🔄 Reset All Settings to Defaults",
    Desc = "คืนค่าการตั้งค่าทั้งหมดกลับเป็นค่าเริ่มต้น",
    Icon = "refresh-cw",
    Callback = function()
        selectedWorld = "Hidden Village"
        selectedStage = 1
        isNightmare = false
        autoStoryFarm = false
        autoTowerStart = false
        autoStartMatch = false
        autoLeaveMatch = false

        smartPlayEnabled = false
        smartStrategy = "Balanced"
        smartPlacementBias = "Best"
        smartUpgradePriority = "Focus Carry"
        smartSaveForPlacements = true
        smartSellFarmsFinalWave = true
        smartAutoAbilities = true
        smartAutoTargeting = true
        smartLockSpeed2x = true
        smartAutoSkipWave = true
        smartMatchEndAction = "Next"

        autoDaily = true
        autoSeasonPass = true
        autoIndex = true
        autoQuests = true
        autoLevelMilestones = true

        autoSummon = false
        summonBanner = "Standard"
        summonCount = 10
        autoCapsules = false

        autoLockHighRarity = true
        autoTraitRoll = false
        autoStatRoll = false

        speedEnabled = false
        customSpeed = 16
        jumpEnabled = false
        customJump = 50
        infJump = false
        noclip = false
        antiAfkEnabled = true

        fxChromaEnabled = true
        fxParticlesEnabled = true
        fxLaserBarEnabled = true
        fxSpeed = 1.0

        autoExecuteMaster = true
        autoTeleportQueue = true
        autoExecFile = true

        saveConfigToFile("Default_Config")
        updateConfigStatusText()
        WindUI:Notify({ Title = "Config", Content = "Reset all settings to default!", Duration = 3, Icon = "refresh-cw" })
    end
})

TabConfig:Toggle({
    Title = "Auto-Save Settings On Change",
    Desc = "เมื่อเปิดใช้งาน ทุกครั้งที่มีการเปิด/ปิดสวิตช์ ปรับสไลเดอร์ หรือเลือกเมนู จะเซฟลงไฟล์ทันทีอัตโนมัติ",
    Value = autoSaveConfig,
    Icon = "shield-check",
    Callback = function(state)
        autoSaveConfig = state
        triggerAutoSave()
        updateConfigStatusText()
    end
})

TabConfig:Section({ Title = "Universal Auto-Execute Engine (Cross-Executor)" })

TabConfig:Paragraph({
    Title = "About Universal Auto-Execute",
    Desc = "⚡ ระบบ Auto-Execute สากล (เหมือน Hub ชั้นนำทั่วไป):\n• สามารถ เปิด/ปิด ได้ตลอดเวลาผ่านสวิตช์ด้านล่าง\n• ไม่ผูกติดกับ Real อย่างเดียว: ใช้งานได้กับทุกโปรแกรม (Wave, Solara, Delta, Codex, Arceus X, Fluxus ฯลฯ)\n• เมื่อวาปข้ามแมพ/ลงด่าน: ใช้ระบบ queue_on_teleport รันสคริปต์ต่อเนื่องอัตโนมัติในทุกโปรแกรม\n• เมื่อเข้าเกมใหม่: มีระบบ AutoExec File และโค้ดคัดลอกสำหรับใส่โฟลเดอร์ autoexec ของทุกค่าย",
    Image = "sparkles"
})

local masterExecToggle = nil
masterExecToggle = TabConfig:Toggle({
    Title = "Master Auto-Execute (สวิตช์หลัก Auto-Execute)",
    Desc = "เปิด/ปิด ระบบรันอัตโนมัติทั้งหมด (หากปิด: สคริปต์จะไม่รันขึ้นมาเองทั้งตอนเข้าเกมและตอนวาปข้ามแมพ)",
    Value = autoExecuteMaster,
    Icon = "power",
    Callback = function(state)
        autoExecuteMaster = state
        updateTeleportQueueState(autoTeleportQueue)
        triggerAutoSave()
        updateConfigStatusText()
        WindUI:Notify({
            Title = "Auto-Execute",
            Content = state and "Master Auto-Execute Enabled 🟢" or "Master Auto-Execute Disabled 🔴",
            Duration = 3,
            Icon = state and "power" or "power-off"
        })
    end
})

local teleportQueueToggle = nil
teleportQueueToggle = TabConfig:Toggle({
    Title = "Auto Re-Execute on Teleport (วาปข้ามแมพ/ลงด่าน)",
    Desc = "รันสคริปต์อัตโนมัติเมื่อวาปเปลี่ยนห้อง / ลงดันเจี้ยน / ย้ายเซิร์ฟเวอร์ (ทำงานผ่าน queue_on_teleport รองรับทุกโปรแกรม)",
    Value = autoTeleportQueue,
    Icon = "repeat",
    Callback = function(state)
        autoTeleportQueue = state
        updateTeleportQueueState(state)
        triggerAutoSave()
        updateConfigStatusText()
        WindUI:Notify({
            Title = "Teleport Queue",
            Content = state and "Teleport Auto Re-Execute Enabled 🟢" or "Teleport Auto Re-Execute Disabled ⚪",
            Duration = 3,
            Icon = "repeat"
        })
    end
})

local autoExecFileToggle = nil
autoExecFileToggle = TabConfig:Toggle({
    Title = "AutoExec File on Game Launch (เข้าเกมใหม่)",
    Desc = "เปิด/ปิด ไฟล์ AutoExec ในเครื่อง เพื่อให้เปิด Hub ขึ้นมาทันทีเมื่อเปิดเกม Roblox (สามารถปิดเพื่อลบไฟล์ออกได้)",
    Value = autoExecFile,
    Icon = "file-code-2",
    Callback = function(state)
        autoExecFile = state
        local changed = updateAutoExecFileState(state)
        triggerAutoSave()
        updateConfigStatusText()
        WindUI:Notify({
            Title = "AutoExec File",
            Content = state and (changed and "AutoExec Loader Installed! 📁" or "AutoExec File Enabled (Saved to Config)") or "AutoExec Loader Removed! 🗑️",
            Duration = 3.5,
            Icon = state and "file-plus" or "file-minus"
        })
    end
})

local universalLoaderSnippet = [=[-- Anime Galaxies Hub Universal AutoExec Loader
-- Paste this file into your executor's "autoexec" folder (Works on Real, Wave, Solara, Delta, Codex, Arceus X, etc.)
task.spawn(function()
    repeat task.wait() until game:IsLoaded()
    local placeId = game.PlaceId
    local universeId = game.GameId
    if universeId == 10770748262 or placeId == 83869074416117 or placeId == 85423571424083 then
        local configPath = "AnimeGalaxiesHub/Configs/Default_Config.json"
        if isfile and isfile(configPath) then
            local ok, content = pcall(readfile, configPath)
            if ok and content and #content > 0 then
                local decodeOk, data = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), content)
                if decodeOk and type(data) == "table" then
                    if data.AutoExecuteMaster == false or data.AutoExecFile == false then
                        return
                    end
                end
            end
        end
        local candidates = {
            "AnimeGalaxiesHub/AnimeGalaxies_Hub.luau",
            "AnimeGalaxiesHub/AnimeGalaxies_Hub.lua",
            "AnimeGalaxies_Hub.luau",
            "AnimeGalaxies_Hub.lua"
        }
        for _, p in ipairs(candidates) do
            if isfile and isfile(p) then
                local ok, content = pcall(readfile, p)
                if ok and content and #content > 0 then
                    local fn = loadstring(content)
                    if fn then return fn() end
                end
            end
        end
    end
end)]=]

TabConfig:Button({
    Title = "📋 Copy Universal AutoExec Loader",
    Desc = "คัดลอกโค้ด Loader สากลสำหรับนำไปใส่ในโฟลเดอร์ autoexec ของโปรแกรมรันสคริปต์ทุกตัว",
    Icon = "clipboard",
    Callback = function()
        local ok = false
        if copyToClipboard then
            local pcallOk = pcall(copyToClipboard, universalLoaderSnippet)
            ok = pcallOk
        end
        if ok then
            WindUI:Notify({
                Title = "Clipboard",
                Content = "Universal AutoExec Loader copied to clipboard!",
                Duration = 4,
                Icon = "clipboard-check"
            })
        else
            WindUI:Notify({
                Title = "Clipboard Notice",
                Content = "Loader is also stored in workspace/AnimeGalaxiesHub!",
                Duration = 4,
                Icon = "alert-circle"
            })
        end
    end
})

TabConfig:Button({
    Title = "⚡ Force Clean Old Ghost UIs (ล้าง UI ค้าง)",
    Desc = "กดเพื่อบังคับล้าง UI ที่ค้างอยู่ในหน่วยความจำทันที 1 ครั้ง",
    Icon = "trash-2",
    Callback = function()
        destroyOldUIs()
        WindUI:Notify({ Title = "UI Clean", Content = "Cleaned ghost UIs from memory!", Duration = 2.5, Icon = "check" })
    end
})

-- ==============================================================================
-- ATTACH DYNAMIC MOVING ANIMATION ENGINE & FX
-- ==============================================================================
task.spawn(function()
    local main = nil
    local topbar = nil

    -- Robust loop to locate the Window main frame (up to 60 retries / 6 seconds)
    for attempt = 1, 60 do
        if not scriptRunning then return end

        if Window and Window.UIElements and Window.UIElements.Main then
            main = Window.UIElements.Main
            topbar = Window.UIElements.Topbar
            break
        end

        local searchRoots = {
            (WindUI and WindUI.ScreenGui),
            (gethui and gethui()),
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

    if not main then
        warn("[AnimeGalaxiesHub] Could not locate WindUI Main frame for dynamic FX.")
        return
    end

    if not topbar then
        topbar = main:FindFirstChild("Topbar", true) or (main.Parent and main.Parent:FindFirstChild("Topbar", true))
    end

    -- 1. Animated Rotating Chroma Glow Border
    local oldStroke = main:FindFirstChild("AnimatedGlowStroke")
    if oldStroke then oldStroke:Destroy() end

    local stroke = Instance.new("UIStroke")
    stroke.Name = "AnimatedGlowStroke"
    stroke.Thickness = 2.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Enabled = fxChromaEnabled
    stroke.Parent = main
    currentStroke = stroke

    local gradient = Instance.new("UIGradient")
    gradient.Name = "RainbowGradient"
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromHex("#EC4899")),
        ColorSequenceKeypoint.new(0.20, Color3.fromHex("#A855F7")),
        ColorSequenceKeypoint.new(0.40, Color3.fromHex("#3B82F6")),
        ColorSequenceKeypoint.new(0.60, Color3.fromHex("#06B6D4")),
        ColorSequenceKeypoint.new(0.80, Color3.fromHex("#10B981")),
        ColorSequenceKeypoint.new(1.00, Color3.fromHex("#EC4899")),
    })
    gradient.Parent = stroke

    -- 2. Animated Laser Pulse Underline on Topbar
    local neonBar = nil
    local barGradient = nil
    if topbar then
        local oldBar = topbar:FindFirstChild("NeonGlowBar")
        if oldBar then oldBar:Destroy() end

        neonBar = Instance.new("Frame")
        neonBar.Name = "NeonGlowBar"
        neonBar.Size = UDim2.new(1, 0, 0, 2)
        neonBar.Position = UDim2.new(0, 0, 1, -2)
        neonBar.BorderSizePixel = 0
        neonBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        neonBar.ZIndex = 10
        neonBar.Visible = fxLaserBarEnabled
        neonBar.Parent = topbar
        currentNeonBar = neonBar

        barGradient = Instance.new("UIGradient")
        barGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.0, Color3.fromHex("#3B82F6")),
            ColorSequenceKeypoint.new(0.5, Color3.fromHex("#EC4899")),
            ColorSequenceKeypoint.new(1.0, Color3.fromHex("#A855F7")),
        })
        barGradient.Parent = neonBar
    end

    -- 3. Animated Title Shimmer Effect
    local titleLabel = nil
    if topbar then
        for _, desc in ipairs(topbar:GetDescendants()) do
            if desc:IsA("TextLabel") and (desc.Text:find("Anime Galaxies") or desc.Name == "Title") then
                titleLabel = desc
                break
            end
        end
    end

    local shimmer = nil
    if titleLabel then
        local oldShimmer = titleLabel:FindFirstChild("TitleShimmer")
        if oldShimmer then oldShimmer:Destroy() end

        shimmer = Instance.new("UIGradient")
        shimmer.Name = "TitleShimmer"
        shimmer.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromHex("#C084FC")),
            ColorSequenceKeypoint.new(0.50, Color3.fromHex("#FFFFFF")),
            ColorSequenceKeypoint.new(1.00, Color3.fromHex("#F472B6")),
        })
        shimmer.Parent = titleLabel
    end

    -- 4. Floating Cosmic Particle Layer
    local oldCanvas = main:FindFirstChild("CosmicParticles")
    if oldCanvas then oldCanvas:Destroy() end

    local particleCanvas = Instance.new("Frame")
    particleCanvas.Name = "CosmicParticles"
    particleCanvas.Size = UDim2.new(1, 0, 1, 0)
    particleCanvas.BackgroundTransparency = 1
    particleCanvas.ClipsDescendants = true
    particleCanvas.ZIndex = 1
    particleCanvas.Visible = fxParticlesEnabled
    particleCanvas.Parent = main
    currentParticleCanvas = particleCanvas

    local particles = {}
    local math_random = math.random
    local math_sin = math.sin

    for i = 1, 28 do
        local p = Instance.new("Frame")
        local sz = math_random(3, 7)
        p.Size = UDim2.fromOffset(sz, sz)
        p.Position = UDim2.new(math_random(3, 97) / 100, 0, math_random(5, 95) / 100, 0)
        p.BackgroundColor3 = (i % 4 == 0) and Color3.fromHex("#06B6D4") or ((i % 3 == 0) and Color3.fromHex("#10B981") or ((i % 2 == 0) and Color3.fromHex("#A855F7") or Color3.fromHex("#EC4899")))
        p.BackgroundTransparency = math_random(30, 70) / 100
        p.BorderSizePixel = 0
        p.ZIndex = 1
        p.Parent = particleCanvas

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = p

        table.insert(particles, {
            obj = p,
            speed = math_random(15, 40) / 1000,
            swaySpeed = math_random(1, 3),
            baseX = p.Position.X.Scale,
            offset = math_random(0, 100) / 10
        })
    end

    -- 5. Real-Time FPS / Ping Live Counter Badge on Topbar
    local liveBadge = nil
    if topbar then
        local rightFrame = topbar:FindFirstChild("Right", true) or topbar:FindFirstChild("Buttons", true)
        if rightFrame then
            local oldBadge = rightFrame:FindFirstChild("LiveStatsBadge")
            if oldBadge then oldBadge:Destroy() end

            liveBadge = Instance.new("TextLabel")
            liveBadge.Name = "LiveStatsBadge"
            liveBadge.Size = UDim2.new(0, 115, 0, 24)
            liveBadge.LayoutOrder = -1
            liveBadge.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
            liveBadge.BackgroundTransparency = 0.3
            liveBadge.TextColor3 = Color3.fromHex("#A3E635")
            liveBadge.TextSize = 11
            liveBadge.Font = Enum.Font.GothamMedium
            liveBadge.Text = "⚡ 144 FPS"
            liveBadge.Parent = rightFrame

            local bCorner = Instance.new("UICorner")
            bCorner.CornerRadius = UDim.new(0, 8)
            bCorner.Parent = liveBadge

            local bStroke = Instance.new("UIStroke")
            bStroke.Thickness = 1
            bStroke.Color = Color3.fromRGB(60, 60, 75)
            bStroke.Parent = liveBadge
        end
    end

    -- 6. Continuous RenderStepped Animation Loop
    local frameCount = 0
    local lastFpsUpdate = tick()
    local currentFps = 60
    local renderConn = nil

    renderConn = RunService.RenderStepped:Connect(function(dt)
        if not scriptRunning then
            if renderConn then renderConn:Disconnect() end
            return
        end

        local t = tick()

        -- FPS & Ping calculation
        frameCount = frameCount + 1
        if t - lastFpsUpdate >= 0.4 then
            currentFps = math.floor(frameCount / (t - lastFpsUpdate))
            frameCount = 0
            lastFpsUpdate = t
            if liveBadge and liveBadge.Parent then
                local ping = 0
                pcall(function()
                    ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
                end)
                liveBadge.Text = string.format("⚡ %d FPS | %dms", currentFps, ping)
                if currentFps >= 50 then
                    liveBadge.TextColor3 = Color3.fromHex("#A3E635")
                elseif currentFps >= 30 then
                    liveBadge.TextColor3 = Color3.fromHex("#FACC15")
                else
                    liveBadge.TextColor3 = Color3.fromHex("#EF4444")
                end
            end
        end

        -- 1. Chroma Border Rotation
        if stroke and stroke.Parent then
            stroke.Enabled = fxChromaEnabled
            if fxChromaEnabled then
                gradient.Rotation = (t * 60 * fxSpeed) % 360
            end
        end

        -- 2. Laser Underline Pulse
        if neonBar and neonBar.Parent then
            neonBar.Visible = fxLaserBarEnabled
            if fxLaserBarEnabled and barGradient then
                barGradient.Offset = Vector2.new(math_sin(t * 2 * fxSpeed) * 0.7, 0)
            end
        end

        -- 3. Title Shimmer Sweep
        if shimmer and shimmer.Parent then
            shimmer.Offset = Vector2.new(math_sin(t * 1.5 * fxSpeed) * 0.6, 0)
        end

        -- 4. Floating Cosmic Particles Animation
        if particleCanvas and particleCanvas.Parent then
            particleCanvas.Visible = fxParticlesEnabled
            if fxParticlesEnabled then
                for _, pt in ipairs(particles) do
                    local newY = pt.obj.Position.Y.Scale - (pt.speed * 0.05 * fxSpeed)
                    if newY < 0.02 then
                        newY = 0.98
                    end
                    local newX = pt.baseX + (math_sin(t * pt.swaySpeed + pt.offset) * 0.02)
                    pt.obj.Position = UDim2.new(newX, 0, newY, 0)
                end
            end
        end
    end)
end)

-- Select first tab automatically
pcall(function()
    TabMain:Select()
end)

-- Initial notification
WindUI:Notify({
    Title = "Anime Galaxies Hub ✨",
    Content = "All-in-One Automation Edition Loaded! Welcome, Hood_u7!",
    Duration = 5,
    Icon = "sparkles",
})
