-- ==============================================================================
-- Anime Galaxies Hub | All-in-One Ultimate Automation Edition ✨
-- Target Game: Anime Galaxies (PlaceId: 83869074416117, 85423571424083)
-- UniverseId: 10770748262
-- UI Framework: WindUI + Custom Dynamic Particle & Chroma FX Engine
-- Made for: Hood_u7
-- ==============================================================================

-- 0. Anti-Multi Window Lock (Strict Debounce to prevent multiple UIs opening simultaneously)
if getgenv()._AG_STARTING and (os.clock() - (getgenv()._AG_START_TIME or 0)) < 2.5 then
    return -- An instance is already launching right now!
end
getgenv()._AG_STARTING = true
getgenv()._AG_START_TIME = os.clock()

task.delay(2.5, function()
    getgenv()._AG_STARTING = nil
end)

-- 0.1 Wait for game to be fully loaded
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- 0.2 Universe/Place check to prevent running in other games on autoexec
local placeId = game.PlaceId
local universeId = game.GameId

if universeId == 0 or placeId == 0 then
    task.wait(1)
    placeId = game.PlaceId
    universeId = game.GameId
end

local isAnimeGalaxies = (universeId == 10770748262 or placeId == 83869074416117 or placeId == 85423571424083)

if not isAnimeGalaxies and not getgenv().AnimeGalaxiesBypassPlaceCheck then
    getgenv()._AG_STARTING = nil
    warn(string.format("[AnimeGalaxiesHub] Notice: Current UniverseId is %s, PlaceId is %s. Hub is designed for Anime Galaxies (10770748262). To bypass check and test anywhere, run: getgenv().AnimeGalaxiesBypassPlaceCheck = true", tostring(universeId), tostring(placeId)))
    return
end

-- 0.3 Shutdown previous running instance and loops (Strict Singleton)
if getgenv().AnimeGalaxiesHubShutdown then
    pcall(getgenv().AnimeGalaxiesHubShutdown)
    task.wait(0.25)
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
    getgenv()._AG_RUNNING = nil
    getgenv()._AG_STARTING = nil
    if teleportConnection then
        pcall(function() teleportConnection:Disconnect() end)
        teleportConnection = nil
    end
end
getgenv()._AG_RUNNING = true

-- 0.4 Clean up all existing UI instances across CoreGui, RobloxGui, gethui, and PlayerGui
local function destroyOldUIs()
    local searchParents = {}
    pcall(function()
        if gethui then table.insert(searchParents, gethui()) end
    end)
    pcall(function()
        local cg = game:GetService("CoreGui")
        table.insert(searchParents, cg)
        local rg = cg:FindFirstChild("RobloxGui")
        if rg then table.insert(searchParents, rg) end
    end)
    local lp = game:GetService("Players").LocalPlayer
    if lp and lp:FindFirstChild("PlayerGui") then
        table.insert(searchParents, lp.PlayerGui)
    end
    for _, parent in ipairs(searchParents) do
        if parent then
            pcall(function()
                for _, c in ipairs(parent:GetChildren()) do
                    if c.Name == "WindUI" or c.Name:find("WindUI") or c.Name:find("AnimeGalaxies") or (c:IsA("ScreenGui") and c:FindFirstChild("Main", true)) then
                        c:Destroy()
                    end
                end
            end)
        end
    end
end
destroyOldUIs()
task.wait(0.2)

local WindUI = nil
local UI = {}
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
        local raw = game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua")
        if raw and #raw > 10000 then
            pcall(function() if writefile then writefile("WindUI_cache.lua", raw) end end)
            WindUI = loadstring(raw)()
        end
    end)
end
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
    getgenv()._AG_STARTING = nil
    warn("[AnimeGalaxiesHub] Error: Could not download WindUI framework. Check network connection.")
    return
end

-- Safe notification wrapper to protect against upstream UI element mismatches
local rawNotify = WindUI.Notify
WindUI.Notify = function(self, ...)
    local args = {...}
    local conf = args[1] or self
    if type(conf) == "table" and conf.Icon then
        conf.Icon = nil
    end
    pcall(function()
        if type(self) == "table" and self.CreateWindow then
            rawNotify(self, unpack(args))
        else
            rawNotify(self)
        end
    end)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Character = LocalPlayer.Character
local Humanoid = Character and Character:WaitForChild("Humanoid", 5)
local RootPart = Character and Character:WaitForChild("HumanoidRootPart", 5)

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid", 10)
    RootPart = char:WaitForChild("HumanoidRootPart", 10)
end)

-- Safe Remote Service Access
local NetworkClient = nil
local GameInfo = {}
pcall(function()
    NetworkClient = require(ReplicatedStorage.Master.Modules.Network_Client)
end)
pcall(function()
    local master = ReplicatedStorage:FindFirstChild("Master")
    local info = master and master:FindFirstChild("Information")
    if info then
        if info:FindFirstChild("Champions") then
            GameInfo.Champions = require(info.Champions)
        end
        if info:FindFirstChild("LevelRewards") then
            GameInfo.LevelRewards = require(info.LevelRewards)
        end
    end
end)

local function publishRemote(topic, data)
    if NetworkClient and NetworkClient.Publish then
        if NetworkClient.Topics and not NetworkClient.Topics[topic] then
            return
        end
        -- Prevent spamming non-existent topics in Match place
        if game.PlaceId == 85423571424083 then
            local validMatchTopics = {
                Controls = true, GameSpeed = true, Effects = true, HandleEnemy = true,
                HandleTower = true, Notification = true, Invitation = true, SkipWave = true,
                EndGame = true, Welcome = true, Hitbox = true, Aftermath = true,
                Settings = true, Passives = true, BossAbility = true, EnemySync = true,
                PvpAttack = true, AfkRejoin = true
            }
            if not validMatchTopics[topic] then return end
        end
        pcall(function()
            NetworkClient:Publish(topic, data)
        end)
    end
end

-- Centralized Match End & Round Life Cycle Helper
local function getMatchEndGui()
    local sg = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("ScreenGui")
    local rr = (sg and (sg:FindFirstChild("RoundResult") or sg:FindFirstChild("GameEnd")))
        or (LocalPlayer:FindFirstChild("PlayerGui") and (LocalPlayer.PlayerGui:FindFirstChild("RoundResult", true) or LocalPlayer.PlayerGui:FindFirstChild("GameEnd", true)))
    
    if not rr or not rr:IsA("GuiObject") then
        return nil, false, false
    end

    -- Strict verification that RoundResult is ACTUALLY VISIBLE ON SCREEN (not hidden offscreen at -8016 pixels)
    local isActuallyOnScreen = (rr.Visible == true)
        and (rr.AbsolutePosition.X >= 0)
        and (rr.Position.X.Scale >= -0.2)

    local gf = workspace:FindFirstChild("Game")
    local started = gf and gf:FindFirstChild("Started") and gf.Started.Value
    local towerHp = gf and gf:FindFirstChild("TowerHealth") and gf.TowerHealth.Value or 500
    local curWave = gf and gf:FindFirstChild("CurrentWave") and gf.CurrentWave.Value or 1
    local totalWave = gf and gf:FindFirstChild("TotalWaves") and gf.TotalWaves.Value or 5

    -- If match is still actively running with base health > 0 and UI is not on screen, match is NOT ended
    if started == true and towerHp > 0 and not isActuallyOnScreen then
        return nil, false, false
    end

    -- Match has ended if:
    -- 1) RoundResult is genuinely visible on screen
    -- 2) Tower HP is 0 (Defeat)
    -- 3) Started turned false after reaching final wave
    if isActuallyOnScreen or (towerHp <= 0) or (started == false and curWave >= totalWave) then
        local isVictory = false
        pcall(function()
            local title = (rr:FindFirstChild("Content") and rr.Content:FindFirstChild("Title"))
                or rr:FindFirstChild("Title", true)
            if title and title:IsA("TextLabel") then
                local txt = title.Text:upper()
                if txt:find("VICTORY") or txt:find("WIN") or txt:find("CLEAR") then
                    isVictory = true
                elseif txt:find("DEFEAT") or txt:find("LOSS") or txt:find("FAILED") then
                    isVictory = false
                end
            end
        end)

        if towerHp <= 0 then
            isVictory = false
        elseif curWave >= totalWave and (started == false or isVictory) then
            isVictory = true
        end

        return rr, true, isVictory
    end

    return nil, false, false
end

UI.lastMatchEndActionTick = 0
UI.matchEndActionDispatched = false

local function triggerMatchEndAction(preferredAction)
    if UI.matchEndActionDispatched then
        return
    end
    if tick() - (UI.lastMatchEndActionTick or 0) < 6.0 then
        return
    end

    local rr, hasEnded, isVictory = getMatchEndGui()
    if not hasEnded then
        return
    end

    UI.lastMatchEndActionTick = tick()
    UI.matchEndActionDispatched = true

    local action = preferredAction or "Next"
    pcall(function()
        local lp = game:GetService("Players").LocalPlayer

        local function triggerBtn(btn)
            if not btn or not btn.Visible or btn.AbsolutePosition.X < 0 then return false end
            pcall(function()
                if getconnections then
                    for _, ev in ipairs({"Activated", "MouseButton1Click", "TouchTap"}) do
                        if btn[ev] then
                            for _, c in ipairs(getconnections(btn[ev])) do pcall(function() c:Fire() end) end
                        end
                    end
                end
                if firesignal then
                    for _, ev in ipairs({"Activated", "MouseButton1Click", "TouchTap"}) do
                        if btn[ev] then pcall(function() firesignal(btn[ev]) end) end
                    end
                end
                local vim = game:GetService("VirtualInputManager")
                if vim and btn.AbsolutePosition and btn.AbsoluteSize then
                    local pos = btn.AbsolutePosition
                    local size = btn.AbsoluteSize
                    vim:SendMouseButtonEvent(pos.X + size.X / 2, pos.Y + size.Y / 2, 0, true, game, 1)
                    task.wait(0.04)
                    vim:SendMouseButtonEvent(pos.X + size.X / 2, pos.Y + size.Y / 2, 0, false, game, 1)
                end
            end)
            return true
        end

        -- Search for specific action button in RoundResult GUI strictly when on screen
        local clickedButton = false
        if rr and rr.Visible and rr.AbsolutePosition.X >= 0 then
            local buttons = (rr:FindFirstChild("Content") and rr.Content:FindFirstChild("GameInfo") and rr.Content.GameInfo:FindFirstChild("Buttons"))
                or rr:FindFirstChild("Buttons", true)
            if buttons then
                if action == "Next" and buttons:FindFirstChild("Next") and buttons.Next.Visible then
                    triggerBtn(buttons.Next)
                    clickedButton = true
                elseif action == "Replay" and buttons:FindFirstChild("Replay") and buttons.Replay.Visible then
                    triggerBtn(buttons.Replay)
                    clickedButton = true
                elseif action == "Return" and buttons:FindFirstChild("Return") and buttons.Return.Visible then
                    triggerBtn(buttons.Return)
                    clickedButton = true
                end
            end
        end

        -- On-screen fallback search strictly for buttons that are genuinely on-screen
        if action == "Next" and not clickedButton and lp and lp:FindFirstChild("PlayerGui") then
            for _, desc in ipairs(lp.PlayerGui:GetDescendants()) do
                if desc:IsA("GuiObject") and desc.Visible and desc.AbsolutePosition.X >= 0 then
                    local text = (desc:IsA("TextLabel") or desc:IsA("TextButton")) and desc.Text:lower() or ""
                    local name = desc.Name:lower()
                    if text:find("next battle", 1, true) or text:find("next stage", 1, true) or name == "next" or name == "nextbattle" then
                        local btn = desc:IsA("GuiButton") and desc or desc:FindFirstAncestorWhichIsA("GuiButton") or (desc.Parent and desc.Parent:IsA("GuiButton") and desc.Parent)
                        if btn and btn.Visible ~= false and btn.AbsolutePosition.X >= 0 then
                            triggerBtn(btn)
                            clickedButton = true
                            break
                        end
                    end
                end
            end
        end

        -- Always dispatch authoritative remotes to the server strictly when match is truly over
        if action == "Next" then
            if selectedGameMode == "Tower" or towerAutoJoin then
                publishRemote("Tower", { Action = "Next" })
                publishRemote("Tower", { Action = "NextBattle" })
                publishRemote("Tower", "Next")
            else
                publishRemote("EndGame", "Next")
                publishRemote("EndGame", { Action = "Next" })
            end
            if WindUI then
                WindUI:Notify({
                    Title = "Next Battle ⏩",
                    Content = "🏆 ชนะแล้ว! กด Next Battle เข้าเล่นด่าน/ชั้นถัดไปทันที",
                    Duration = 3,
                    Icon = "fast-forward"
                })
            end
        elseif action == "Replay" then
            if selectedGameMode == "Tower" or towerAutoJoin then
                publishRemote("Tower", { Action = "Replay" })
            else
                publishRemote("EndGame", "Replay")
                publishRemote("EndGame", { Action = "Replay" })
            end
            if WindUI then
                WindUI:Notify({
                    Title = "Replay Match 🔄",
                    Content = "🔄 กด Replay เริ่มเล่นด่านเดิมซ้ำ",
                    Duration = 3,
                    Icon = "refresh-cw"
                })
            end
        elseif action == "Return" then
            publishRemote("EndGame", "Return")
            publishRemote("EndGame", { Action = "Return" })
            publishRemote("Room", { Action = "Leave" })
            if WindUI then
                WindUI:Notify({
                    Title = "Return To Lobby 🚪",
                    Content = "🚪 ออกจากแมตช์และกลับล็อบบี้เรียบร้อย",
                    Duration = 3,
                    Icon = "log-out"
                })
            end
        end
    end)
end

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

local MACRO_FOLDER = "AnimeGalaxiesHub/Macros"
pcall(function()
    if not isfolder("AnimeGalaxiesHub") then makefolder("AnimeGalaxiesHub") end
    if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
    if not isfolder(MACRO_FOLDER) then makefolder(MACRO_FOLDER) end
end)

local matchCombatEngine = "TD Macro" -- "TD Macro" or "Smart Play AI"

local function getSavedMacroList(ensureName)
    local names = {}
    local seen = {}
    pcall(function()
        if not isfolder("AnimeGalaxiesHub") then makefolder("AnimeGalaxiesHub") end
        if not isfolder(MACRO_FOLDER) then makefolder(MACRO_FOLDER) end
        if isfolder(MACRO_FOLDER) and listfiles then
            for _, f in ipairs(listfiles(MACRO_FOLDER)) do
                local clean = f:match("([^\\/]+)%.[jJ][sS][oO][nN]$")
                if clean and not seen[clean] then
                    seen[clean] = true
                    table.insert(names, clean)
                end
            end
        end
    end)
    if ensureName and #ensureName > 0 and not seen[ensureName] then
        seen[ensureName] = true
        table.insert(names, ensureName)
    end
    if not seen["1"] and isfile and isfile(MACRO_FOLDER .. "/1.json") then
        table.insert(names, "1")
        seen["1"] = true
    end
    if not seen["Default_Tower_Farm"] then
        table.insert(names, "Default_Tower_Farm")
        seen["Default_Tower_Farm"] = true
    end
    table.sort(names)
    return names
end

-- State Variables Initialization
local selectedGameMode = "Story"
local selectedWorld = "Hidden Village"
local selectedStage = 1
local isNightmare = false
local autoNextStage = true
local selectedRaid = "King of Curses"
local selectedChallenge = "Rotating"
local selectedEndlessMap = "Hidden Village"
local roomFriendsOnly = true
local autoCreateAndStart = false
local autoLoopNextMatch = true
local autoStoryFarm = false
local autoTowerStart = false
local selectedTowerFloor = 1
local autoNextTowerFloor = true
local autoForfeitTowerIfBlocked = true

-- Dedicated Tower Climb System (Banana/Black Hub Clone)
local towerAutoJoin = false
local towerCurrentFloor = 1
local towerTeam = "Equipped Team"
local towerAfterLoss = "Start New Run" -- "Start New Run", "Retry Floor", "Return To Lobby"
local towerJoinPriority = 1
local towerEnableStopAt = false
local towerStopAtBattle = 22
local towerAtStopBattle = "Forfeit And Restart" -- "Forfeit And Restart", "Return To Lobby", "Continue Climbing"

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
local macroLockSpeed2x = true
local macroAutoSkipWave = true
local isRecordingMacro = false
local recordingStartTime = 0
local lastActionTime = 0
local towerAddedConn = nil
local towerChangedConns = {}
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
local FXHandles = {
    Stroke = nil,
    ParticleCanvas = nil,
    NeonBar = nil,
}

local function updateDropdown(dropdown, newValues, selectedValue)
    if not dropdown then return end
    pcall(function()
        local list = (type(newValues) == "table") and newValues or {}

        dropdown.Values = list

        if type(dropdown.Refresh) == "function" then
            dropdown:Refresh(list)
        elseif type(dropdown.SetValues) == "function" then
            dropdown:SetValues(list)
        end

        if selectedValue then
            if type(dropdown.Select) == "function" then
                dropdown:Select(selectedValue)
            elseif type(dropdown.SetValue) == "function" then
                dropdown:SetValue(selectedValue)
            else
                dropdown.Value = selectedValue
            end

            pcall(function()
                if dropdown.UIElements and dropdown.UIElements.Dropdown and dropdown.UIElements.Dropdown.Frame then
                    local lbl = dropdown.UIElements.Dropdown.Frame.Frame.TextLabel
                    if lbl and lbl:IsA("TextLabel") then
                        lbl.Text = tostring(selectedValue)
                    end
                end
            end)
        end
    end)
end

local function getSavedConfigsList(ensureName)
    local names = {}
    local seen = {}
    pcall(function()
        if not isfolder("AnimeGalaxiesHub") then makefolder("AnimeGalaxiesHub") end
        if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
        if isfolder(CONFIG_FOLDER) then
            for _, f in ipairs(listfiles(CONFIG_FOLDER)) do
                local clean = f:match("([^\\/]+)%.[jJ][sS][oO][nN]$")
                if clean and not seen[clean] then
                    seen[clean] = true
                    table.insert(names, clean)
                end
            end
        end
    end)
    if ensureName and #ensureName > 0 and not seen[ensureName] then
        seen[ensureName] = true
        table.insert(names, ensureName)
    end
    if not seen["Default_Config"] then
        table.insert(names, "Default_Config")
        seen["Default_Config"] = true
    end
    table.sort(names)
    return names
end

local function serializeConfig()
    return {
        SelectedGameMode = selectedGameMode,
        SelectedWorld = selectedWorld,
        SelectedStage = selectedStage,
        Nightmare = isNightmare,
        AutoNextStage = autoNextStage,
        SelectedRaid = selectedRaid,
        SelectedChallenge = selectedChallenge,
        SelectedEndlessMap = selectedEndlessMap,
        RoomFriendsOnly = roomFriendsOnly,
        AutoCreateAndStart = autoCreateAndStart,
        AutoLoopNextMatch = autoLoopNextMatch,
        AutoStoryFarm = autoStoryFarm,
        AutoTower = autoTowerStart,
        SelectedTowerFloor = selectedTowerFloor,
        AutoNextTowerFloor = autoNextTowerFloor,
        AutoForfeitTowerIfBlocked = autoForfeitTowerIfBlocked,

        -- Tower Climb System
        TowerAutoJoin = towerAutoJoin,
        TowerCurrentFloor = towerCurrentFloor,
        TowerTeam = towerTeam,
        TowerAfterLoss = towerAfterLoss,
        TowerJoinPriority = towerJoinPriority,
        TowerEnableStopAt = towerEnableStopAt,
        TowerStopAtBattle = towerStopAtBattle,
        TowerAtStopBattle = towerAtStopBattle,

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
        MatchCombatEngine = matchCombatEngine,

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
    if data.SelectedGameMode ~= nil then selectedGameMode = data.SelectedGameMode end
    if data.SelectedWorld ~= nil then selectedWorld = data.SelectedWorld end
    if data.SelectedStage ~= nil then selectedStage = data.SelectedStage end
    if data.Nightmare ~= nil then isNightmare = data.Nightmare end
    if data.AutoNextStage ~= nil then autoNextStage = data.AutoNextStage end
    if data.SelectedRaid ~= nil then selectedRaid = data.SelectedRaid end
    if data.SelectedChallenge ~= nil then selectedChallenge = data.SelectedChallenge end
    if data.SelectedEndlessMap ~= nil then selectedEndlessMap = data.SelectedEndlessMap end
    if data.RoomFriendsOnly ~= nil then roomFriendsOnly = data.RoomFriendsOnly end
    if data.AutoCreateAndStart ~= nil then autoCreateAndStart = data.AutoCreateAndStart end
    if data.AutoLoopNextMatch ~= nil then autoLoopNextMatch = data.AutoLoopNextMatch end
    if data.AutoStoryFarm ~= nil then autoStoryFarm = data.AutoStoryFarm end
    if data.AutoTower ~= nil then autoTowerStart = data.AutoTower end
    if data.SelectedTowerFloor ~= nil then selectedTowerFloor = data.SelectedTowerFloor end
    if data.AutoNextTowerFloor ~= nil then autoNextTowerFloor = data.AutoNextTowerFloor end
    if data.AutoForfeitTowerIfBlocked ~= nil then autoForfeitTowerIfBlocked = data.AutoForfeitTowerIfBlocked end

    -- Tower Climb System
    if data.TowerAutoJoin ~= nil then towerAutoJoin = data.TowerAutoJoin end
    if data.TowerCurrentFloor ~= nil then towerCurrentFloor = data.TowerCurrentFloor end
    if data.TowerTeam ~= nil then towerTeam = data.TowerTeam end
    if data.TowerAfterLoss ~= nil then towerAfterLoss = data.TowerAfterLoss end
    if data.TowerJoinPriority ~= nil then towerJoinPriority = data.TowerJoinPriority end
    if data.TowerEnableStopAt ~= nil then towerEnableStopAt = data.TowerEnableStopAt end
    if data.TowerStopAtBattle ~= nil then towerStopAtBattle = data.TowerStopAtBattle end
    if data.TowerAtStopBattle ~= nil then towerAtStopBattle = data.TowerAtStopBattle end

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
    if data.MatchCombatEngine ~= nil then matchCombatEngine = data.MatchCombatEngine end

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
        if not isfolder("AnimeGalaxiesHub") then makefolder("AnimeGalaxiesHub") end
        if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
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
    repeat task.wait(0.5) until game:IsLoaded() and game:GetService("Players").LocalPlayer
    local universeId = game.GameId
    local placeId = game.PlaceId
    local attempts = 0
    while (universeId == 0 or placeId == 0) and attempts < 20 do
        attempts = attempts + 1
        task.wait(0.5)
        universeId = game.GameId
        placeId = game.PlaceId
    end

    if universeId == 10770748262 or placeId == 83869074416117 or placeId == 85423571424083 then
        local configPath = "AnimeGalaxiesHub/Configs/Default_Config.json"
        if isfile and isfile(configPath) then
            local ok, content = pcall(readfile, configPath)
            if ok and content and #content > 0 then
                local decodeOk, data = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), content)
                if decodeOk and type(data) == "table" then
                    if data.AutoExecuteMaster == false or data.AutoTeleportQueue == false then
                        return
                    end
                end
            end
        end

        if getgenv()._AG_STARTING or getgenv()._AG_RUNNING then
            return
        end

        local candidates = {
            "AnimeGalaxiesHub/AnimeGalaxies_Hub.luau",
            "AnimeGalaxies_Hub.luau",
            "AnimeGalaxiesHub/AnimeGalaxies_Hub.lua",
            "AnimeGalaxies_Hub.lua"
        }
        for _, p in ipairs(candidates) do
            if isfile and isfile(p) then
                local ok, content = pcall(readfile, p)
                if ok and content and #content > 1000 then
                    local fn, err = loadstring(content)
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
local function armTeleportQueue()
    if not hasQueueTeleport then return end
    if not autoExecuteMaster or not autoTeleportQueue then return end

    pcall(function()
        rawQueueTeleport(getTeleportLoaderCode())
    end)
end

local function updateTeleportQueueState(enabled)
    if teleportConnection then
        pcall(function() teleportConnection:Disconnect() end)
        teleportConnection = nil
    end

    autoTeleportQueue = enabled

    if enabled and autoExecuteMaster and hasQueueTeleport then
        -- 1. Arm queue immediately into executor's internal memory
        armTeleportQueue()

        -- 2. Hook LocalPlayer.OnTeleport as a continuous fail-safe
        local lp = Players.LocalPlayer or game:GetService("Players").LocalPlayer
        if lp then
            teleportConnection = lp.OnTeleport:Connect(function(state)
                armTeleportQueue()
            end)
        end
    end
end

-- Universal AutoExec File Manager (Clean, Single Master Loader - NO Duplicate Files)
local function updateAutoExecFileState(enabled)
    local loaderSnippet = [=[-- Anime Galaxies Hub Official AutoExec Loader
task.spawn(function()
    repeat task.wait(0.5) until game:IsLoaded() and game:GetService("Players").LocalPlayer
    local universeId = game.GameId
    local placeId = game.PlaceId
    if universeId == 0 or placeId == 0 then
        task.wait(1.5)
        universeId = game.GameId
        placeId = game.PlaceId
    end

    -- Only execute when in Anime Galaxies
    if universeId ~= 10770748262 and placeId ~= 83869074416117 and placeId ~= 85423571424083 then
        return
    end

    -- Anti-Multi Window Lock
    if getgenv()._AG_STARTING or getgenv()._AG_RUNNING then
        return
    end

    task.wait(1.5)

    if getgenv()._AG_STARTING or getgenv()._AG_RUNNING then
        return
    end

    local candidates = {
        "AnimeGalaxiesHub/AnimeGalaxies_Hub.luau",
        "AnimeGalaxies_Hub.luau"
    }

    for _, path in ipairs(candidates) do
        if isfile and isfile(path) then
            local ok, content = pcall(readfile, path)
            if ok and content and #content > 1000 then
                local fn = loadstring(content)
                if fn then return fn() end
            end
        end
    end
end)
]=]

    -- 1. Safely remove all legacy duplicate loaders from old versions
    local legacyPaths = {
        "autoexec/Anime Galaxies_hub.luau",
        "autoexec/AnimeGalaxies_Hub.luau",
        "autoexec/anime.luau",
        "../autoexec/Anime Galaxies_hub.luau",
        "../autoexec/AnimeGalaxies_Hub.luau",
        "../autoexec/anime.luau",
        "../autoexec/A G.luau"
    }
    for _, p in ipairs(legacyPaths) do
        pcall(function()
            if isfile and isfile(p) then delfile(p) end
        end)
    end

    -- 2. Write to only ONE master loader
    local masterPaths = {
        "autoexec/AnimeGalaxies.luau",
        "../autoexec/AnimeGalaxies.luau"
    }

    if enabled then
        local wrote = false
        for _, p in ipairs(masterPaths) do
            pcall(function()
                writefile(p, loaderSnippet)
                wrote = true
            end)
        end
        return wrote
    else
        for _, p in ipairs(masterPaths) do
            pcall(function()
                if isfile and isfile(p) then delfile(p) end
            end)
        end
        return true
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
    Title = "Anime Galaxies Hub ✨ [v1.5]",
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

-- UI successfully initialized: release startup debounce lock
getgenv()._AG_STARTING = nil

-- ==============================================================================
-- TABS CONFIGURATION
-- ==============================================================================
local Tabs = {
    Main      = Window:Tab({ Title = "Auto Farm & Story", Icon = "swords" }),
    Tower     = Window:Tab({ Title = "Tower Climb", Icon = "castle" }),
    Smart     = Window:Tab({ Title = "Smart Play AI", Icon = "cpu" }),
    Macro     = Window:Tab({ Title = "TD Macro Config", Icon = "gamepad-2" }),
    Rewards   = Window:Tab({ Title = "Auto Rewards", Icon = "gift" }),
    Summon    = Window:Tab({ Title = "Auto Summon", Icon = "sparkles" }),
    Units     = Window:Tab({ Title = "Auto Units & Stats", Icon = "layers" }),
    Teleports = Window:Tab({ Title = "Teleports", Icon = "map-pin" }),
    Player    = Window:Tab({ Title = "Player & Misc", Icon = "user" }),
    FX        = Window:Tab({ Title = "FX & Themes", Icon = "palette" }),
    Config    = Window:Tab({ Title = "Config & AutoExec", Icon = "settings" }),
}

-- ==============================================================================
-- TAB 1: AUTO FARM & STORY (MATCH / ROOM / TOWER)
-- ==============================================================================
UI.farmStatusPara = Tabs.Main:Paragraph({
    Title = "Player & Match Status (สถานะห้องและโหมด)",
    Desc = "โหมด: Story | เป้าหมาย: Hidden Village (Act 1)\nสถานะ: ⚪ อยู่ในล็อบบี้ (In Lobby)\nระบบสร้างห้องและเริ่มอัตโนมัติ: ⚪ ปิดใช้งาน",
    Image = "swords"
})

Tabs.Main:Section({ Title = "🎮 Game Mode Selection (เลือกโหมดที่ต้องการเล่น)" })

Tabs.Main:Dropdown({
    Title = "Select Game Mode (เลือกโหมด)",
    Desc = "เลือกโหมดเกมที่ต้องการให้บอทเข้าเล่น (Story, Raids, Challenges, Endless) *สำหรับโหมด Tower ให้ไปที่แท็บ Tower Climb",
    Values = { "Story", "Raids", "Challenges", "Endless" },
    Value = (selectedGameMode == "Tower" and "Story" or selectedGameMode),
    Callback = function(val)
        selectedGameMode = val
        triggerAutoSave()
    end
})

Tabs.Main:Section({ Title = "🗺️ Mode Settings (ตั้งค่าด่านและแผนที่ของแต่ละโหมด)" })

Tabs.Main:Dropdown({
    Title = "Story World / Map (เลือกโลก Story)",
    Desc = "เลือกโลกที่ต้องการจะให้บอทลงด่านโหมดเนื้อเรื่อง",
    Values = { "Hidden Village", "Desert Kingdom", "Dragon City", "Hollow World", "Cursed High School" },
    Value = selectedWorld,
    Callback = function(val)
        selectedWorld = val
        triggerAutoSave()
    end
})

Tabs.Main:Dropdown({
    Title = "Story Stage (เลือกด่าน 1 - 5)",
    Desc = "เลือกหมายเลขด่านของโหมด Story",
    Values = { "1", "2", "3", "4", "5" },
    Value = tostring(selectedStage),
    Callback = function(val)
        selectedStage = tonumber(val) or 1
        triggerAutoSave()
    end
})

Tabs.Main:Toggle({
    Title = "Nightmare Mode (โหมดฝันร้าย)",
    Desc = "เปิดโหมดความยาก Nightmare สำหรับ Story และ Raids",
    Value = isNightmare,
-- Icon = "skull",
    Callback = function(state)
        isNightmare = state
        triggerAutoSave()
    end
})

Tabs.Main:Dropdown({
    Title = "Select Raid (เลือกด่าน Raids)",
    Desc = "เลือกด่านบอสเรดที่ต้องการให้บอทลงฟาร์ม",
    Values = { "King of Curses", "Caged Island", "Raid 1", "Raid 2" },
    Value = selectedRaid,
    Callback = function(val)
        selectedRaid = val
        triggerAutoSave()
    end
})

Tabs.Main:Dropdown({
    Title = "Select Challenge (เลือกด่าน Challenges)",
    Desc = "เลือกด่านความท้าทายเพื่อฟาร์มวัตถุดิบวิวัฒนาการ",
    Values = { "Rotating", "Daily", "Weekly", "Challenge 1", "Challenge 2" },
    Value = selectedChallenge,
    Callback = function(val)
        selectedChallenge = val
        triggerAutoSave()
    end
})

Tabs.Main:Dropdown({
    Title = "Endless Map (เลือกแผนที่ Endless)",
    Desc = "เลือกแผนที่สำหรับเล่นโหมด Endless",
    Values = { "Hidden Village", "Desert Kingdom", "Dragon City", "Hollow World", "Cursed High School" },
    Value = selectedEndlessMap,
    Callback = function(val)
        selectedEndlessMap = val
        triggerAutoSave()
    end
})

Tabs.Main:Section({ Title = "🚀 Room Creation & Auto-Start (ระบบสร้างห้องและเริ่มอัตโนมัติ)" })

UI.autoStartToggle = Tabs.Main:Toggle({
    Title = "🔄 เปิดระบบสร้างห้องและเริ่มเกมอัตโนมัติ (Auto Create & Start)",
    Desc = "บอทจะหาห้องว่าง วาปเข้าห้อง ตั้งค่าแมพตามโหมด และกดเริ่มเกมให้อัตโนมัติแบบลูปต่อเนื่อง",
    Value = autoCreateAndStart,
    Callback = function(state)
        autoCreateAndStart = state
        if state and selectedGameMode ~= "Tower" then
            towerAutoJoin = false
            pcall(function()
                if UI.towerAutoJoinToggle and UI.towerAutoJoinToggle.SetValue then
                    UI.towerAutoJoinToggle:SetValue(false)
                end
            end)
        end
        triggerAutoSave()
        WindUI:Notify({
            Title = "Auto Room & Match",
            Content = state and "เปิดระบบสร้างห้องและเริ่มเกมอัตโนมัติแล้ว!" or "ปิดระบบสร้างห้องอัตโนมัติแล้ว",
            Duration = 3,
            Icon = state and "circle-play" or "circle-x"
        })
    end
})

Tabs.Main:Toggle({
    Title = "⏩ ชนะแล้วกด Next เข้าด่าน/ชั้นถัดไปทันที (Auto Next Battle / Stage)",
    Desc = "เมื่อเคลียร์ด่านหรือหอคอยชนะ บอทจะกดปุ่ม Next Battle เพื่อเล่นชั้นหรือด่านถัดไปทันทีในห้องเดิม โดยไม่ต้องสร้างห้องใหม่!",
    Value = (autoNextStage ~= false),
    Callback = function(state)
        autoNextStage = state
        triggerAutoSave()
    end
})

Tabs.Main:Dropdown({
    Title = "🏆 เมื่อจบเกมชนะ (Action on Victory)",
    Desc = "เลือกคำสั่งเมื่อจบเกมชนะ: 'Next' (กด Next Battle เข้าด่าน/ชั้นถัดไปทันที ไม่ต้องออกห้อง/สร้างใหม่), 'Replay' (เล่นด่านเดิมซ้ำ), 'Return' (กลับล็อบบี้)",
    Values = { "Next", "Replay", "Return" },
    Value = smartMatchEndAction or "Next",
    Callback = function(val)
        smartMatchEndAction = val
        triggerAutoSave()
    end
})

Tabs.Main:Toggle({
    Title = "🔒 ห้องเฉพาะเพื่อน / ส่วนตัว (Friends Only Room)",
    Desc = "สร้างห้องแบบส่วนตัว เพื่อไม่ให้คนนอกเข้ามารบกวน",
    Value = roomFriendsOnly,
-- Icon = "shield-check",
    Callback = function(state)
        roomFriendsOnly = state
        triggerAutoSave()
    end
})

Tabs.Main:Toggle({
    Title = "🔁 วนลูปเล่นรอบใหม่ต่อเนื่อง (Auto Loop Next Match)",
    Desc = "เมื่อจบเกม จะกดรับของรางวัลและกลับห้องเริ่มรอบใหม่ให้อัตโนมัติ",
    Value = autoLoopNextMatch,
-- Icon = "repeat",
    Callback = function(state)
        autoLoopNextMatch = state
        triggerAutoSave()
    end
})

Tabs.Main:Section({ Title = "⚔️ Match Combat Engine (ระบบการเล่นในแมตช์)" })

UI.mainCombatEngineDropdown = nil
UI.mainCombatEngineDropdown = Tabs.Main:Dropdown({
    Title = "🎮 เลือกระบบเล่นในแมตช์ (Match Combat Engine)",
    Desc = "เลือกว่าเมื่อเข้าด่าน (Story, Raids, Challenges, Endless) จะให้บอทเล่นด้วยระบบใด",
    Values = { "▶️ เล่นตาม TD Macro (Macro Playback)", "🧠 คำนวณอัตโนมัติ (Smart Play AI)" },
    Value = (matchCombatEngine == "TD Macro") and "▶️ เล่นตาม TD Macro (Macro Playback)" or "🧠 คำนวณอัตโนมัติ (Smart Play AI)",
    Callback = function(val)
        if val:find("Macro") then
            matchCombatEngine = "TD Macro"
            macroPlaybackEnabled = true
            smartPlayEnabled = false
        else
            matchCombatEngine = "Smart Play AI"
            macroPlaybackEnabled = false
            smartPlayEnabled = true
        end
        triggerAutoSave()
        WindUI:Notify({
            Title = "Match Engine",
            Content = "เลือกระบบเล่นในแมตช์: " .. val,
            Duration = 3,
            Icon = "swords"
        })
    end
})

UI.mainMacroFileDropdown = nil
UI.mainMacroFileDropdown = Tabs.Main:Dropdown({
    Title = "📂 เลือกไฟล์ TD Macro ที่ต้องการเล่น (Active Macro)",
    Desc = "เลือกไฟล์ Macro ที่บันทึกไว้สำหรับรันในแมตช์ (เช่น 1, Default_Tower_Farm)",
    Values = getSavedMacroList(selectedFileToLoad),
    Value = selectedFileToLoad,
    Callback = function(val)
        selectedFileToLoad = val
        pcall(function() loadMacroConfig(val) end)
        triggerAutoSave()
    end
})

UI.mainMacroPlayToggle = nil
UI.mainMacroPlayToggle = Tabs.Main:Toggle({
    Title = "▶️ เปิดเล่น Macro (Enable Macro Playback)",
    Desc = "เปิดระบบทำงานอัตโนมัติตามสเต็ปที่อัดไว้",
    Value = macroPlaybackEnabled,
    Callback = function(state)
        macroPlaybackEnabled = state
        if state then smartPlayEnabled = false end
        currentMacroStep = 0
        table.clear(playbackTowers)
        triggerAutoSave()
        updateMacroStatus()
        WindUI:Notify({
            Title = "TD Macro",
            Content = state and "▶️ เริ่มเล่น Macro แล้ว!" or "⏹️ หยุดเล่น Macro แล้ว",
            Duration = 3,
        })
    end
})

UI.mainMacroLoopToggle = nil
UI.mainMacroLoopToggle = Tabs.Main:Toggle({
    Title = "🔁 วนลูปเล่นซ้ำทุกรอบ (Loop on Next Match)",
    Desc = "วนลูป Macro ซ้ำให้อัตโนมัติเมื่อเริ่มเกมรอบใหม่",
    Value = macroLoopEnabled,
    Callback = function(state)
        macroLoopEnabled = state
        triggerAutoSave()
    end
})

Tabs.Main:Toggle({
    Title = "⚡ เร่งสปีดเกม 2x (Auto 2x Speed)",
    Desc = "เร่งความเร็วเกมเป็น 2 เท่าตลอดแมตช์",
    Value = macroLockSpeed2x,
    Callback = function(state)
        macroLockSpeed2x = state
        triggerAutoSave()
    end
})

Tabs.Main:Toggle({
    Title = "⏩ ข้ามเวฟอัตโนมัติ (Auto Skip Wave)",
    Desc = "กดยืนยันข้ามเวฟอัตโนมัติเมื่อเลือดฐานปลอดภัย",
    Value = macroAutoSkipWave,
    Callback = function(state)
        macroAutoSkipWave = state
        triggerAutoSave()
    end
})

Tabs.Main:Section({ Title = "⚡ Manual Room Actions (สั่งการห้องทันที 1 คลิก)" })

-- World and Raid Index Mappings
local WORLD_INDEX_MAP = {
    ["Hidden Village"] = 1,
    ["Desert Kingdom"] = 2,
    ["Dragon City"] = 3,
    ["Hollow World"] = 4,
    ["Cursed High School"] = 5,
}

local RAID_INDEX_MAP = {
    ["King of Curses"] = 1,
    ["Caged Island"] = 2,
    ["Raid 1"] = 1,
    ["Raid 2"] = 2,
    ["Raid 3"] = 1,
    ["Raid 4"] = 2,
    ["Raid 5"] = 1,
}

-- Helper to find the official game UI Controller for Rooms
local function getOfficialRooms()
    local found = nil
    pcall(function()
        local ifc = ReplicatedStorage:FindFirstChild("Master")
            and ReplicatedStorage.Master:FindFirstChild("Modules")
            and ReplicatedStorage.Master.Modules:FindFirstChild("Interface_Client")
        if ifc then
            for _, name in ipairs({"RoomsUi", "Rooms", "RoomUi", "Room", "Matchmaking", "TowerUi"}) do
                local rModule = ifc:FindFirstChild(name)
                if rModule and rModule:IsA("ModuleScript") then
                    local ok, res = pcall(require, rModule)
                    if ok and type(res) == "table" and (res.OnSolo or res.OnCreate or res.OnStart) then
                        found = res
                        break
                    end
                end
            end
        end
    end)
    if found then return found end

    pcall(function()
        if filtergc then
            local matches = filtergc("table", {OnSolo = true, OnCreate = true, OnStart = true}, false)
            for _, t in ipairs(matches) do
                if rawget(t, "OnSolo") and type(rawget(t, "OnSolo")) == "function" and rawget(t, "OnCreate") and rawget(t, "OnStart") then
                    found = t
                    break
                end
            end
        end
        if not found and getgc then
            for _, t in ipairs(getgc(false)) do
                if type(t) == "table" and rawget(t, "OnSolo") and type(rawget(t, "OnSolo")) == "function" and rawget(t, "OnCreate") then
                    found = t
                    break
                end
            end
        end
    end)
    return found
end

-- Authentic Door Finder matching the game's exact freeDoor() implementation
local function findFreeDoor(mode)
    if not workspace:FindFirstChild("Rooms") then return nil end
    local query = (mode or "Story"):lower()
    if query == "raids" then query = "raid" end
    if query == "challenges" then query = "challenge" end

    for _, room in ipairs(workspace.Rooms:GetChildren()) do
        local rName = room.Name:lower()
        if rName:find(query, 1, true) ~= nil then
            local door = room:FindFirstChild("Door")
            local detailsUI = room:FindFirstChild("DetailsUI", true)
            local count = detailsUI and detailsUI:FindFirstChild("Count")
            local isReady = door and door:GetAttribute("Ready") == true
            local isCountZero = (not count) or (count.Value == 0)
            if door and door:IsA("BasePart") and (not isReady) and isCountZero then
                return door, room
            end
        end
    end

    -- Fallback: Any door matching mode with < 4 players
    for _, room in ipairs(workspace.Rooms:GetChildren()) do
        local rName = room.Name:lower()
        if rName:find(query, 1, true) ~= nil then
            local door = room:FindFirstChild("Door") or room:FindFirstChildWhichIsA("BasePart")
            if door then
                local isReady = door:GetAttribute("Ready") == true
                local detailsUI = room:FindFirstChild("DetailsUI", true)
                local count = detailsUI and detailsUI:FindFirstChild("Count")
                if not isReady and ((not count) or count.Value < 4) then
                    return door, room
                end
            end
        end
    end

    return nil
end

-- ==============================================================================
-- DEDICATED TOWER SYSTEM CONTROLLER (NATIVE OFFICIAL LAUNCHER)
-- ==============================================================================
local function getTowerTeamList()
    local team = {}
    local data = LocalPlayer:FindFirstChild("Data")
    if data then
        local towerFolder = data:FindFirstChild("Tower")
        local teamVal = towerFolder and towerFolder:FindFirstChild("Team")
        if teamVal and teamVal:IsA("StringValue") and #teamVal.Value > 2 then
            local ok, parsed = pcall(function() return HttpService:JSONDecode(teamVal.Value) end)
            if ok and type(parsed) == "table" and #parsed > 0 then
                return parsed
            end
        end
        pcall(function()
            local unitsMod = require(ReplicatedStorage.Master.Modules.UI_Client.Units)
            local list = unitsMod.list(data)
            for i = 1, math.min(#list, 4) do
                table.insert(team, list[i].Id)
            end
        end)
    end
    return team
end

local autoUseTowerCheckpoint = true

local function getTowerScreenGui()
    local lp = game:GetService("Players").LocalPlayer
    local pg = lp and lp:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local fs = pg:FindFirstChild("FusionScreens")
    local s = pg:FindFirstChild("Screens")
    return (fs and fs:FindFirstChild("Tower")) or (s and s:FindFirstChild("Tower"))
end

local function clickTowerStartButton()
    local towerGui = getTowerScreenGui()
    if not towerGui then return false end
    local startBtn = towerGui:FindFirstChild("Start", true)
    if startBtn and startBtn:IsA("GuiButton") then
        local fired = false
        pcall(function()
            if getconnections then
                for _, c in ipairs(getconnections(startBtn.Activated)) do
                    c:Fire()
                    fired = true
                end
                for _, c in ipairs(getconnections(startBtn.MouseButton1Click)) do
                    c:Fire()
                    fired = true
                end
            end
        end)
        if not fired and firesignal then
            pcall(function() firesignal(startBtn.Activated) fired = true end)
        end
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            local pos = startBtn.AbsolutePosition
            local sz = startBtn.AbsoluteSize
            vim:SendMouseButtonEvent(pos.X + sz.X / 2, pos.Y + sz.Y / 2, 0, true, game, 1)
            task.wait(0.04)
            vim:SendMouseButtonEvent(pos.X + sz.X / 2, pos.Y + sz.Y / 2, 0, false, game, 1)
            fired = true
        end)
        return fired
    end
    return false
end

local function clickTowerForfeitButton()
    local towerGui = getTowerScreenGui()
    if not towerGui then return false end
    local forfeitBtn = towerGui:FindFirstChild("Forfeit", true)
    if forfeitBtn and forfeitBtn:IsA("GuiButton") then
        local fired = false
        pcall(function()
            if getconnections then
                for _, c in ipairs(getconnections(forfeitBtn.Activated)) do
                    c:Fire()
                    fired = true
                end
                for _, c in ipairs(getconnections(forfeitBtn.MouseButton1Click)) do
                    c:Fire()
                    fired = true
                end
            end
        end)
        if not fired and firesignal then
            pcall(function() firesignal(forfeitBtn.Activated) fired = true end)
        end
        return fired
    end
    return false
end

local function clickUseCheckpointGui()
    return clickTowerStartButton()
end

local function startTowerBattle()
    -- 1. Ensure Tower screen is open
    local towerGui = getTowerScreenGui()
    if not towerGui or not towerGui.Visible then
        pcall(function()
            local ifc = require(ReplicatedStorage.Master.Modules.Interface_Client)
            if ifc then
                if type(ifc.Open) == "function" then
                    ifc:Open("Tower")
                elseif type(ifc.SetScreen) == "function" then
                    ifc:SetScreen("Tower")
                end
            end
        end)
        task.wait(0.3)
        towerGui = getTowerScreenGui()
    end

    -- 2. Click the Start / Continue button on the Tower Screen
    if towerGui then
        clickTowerStartButton()
    end

    -- 3. Auto equip specified team for Tower
    if towerTeam and towerTeam ~= "Equipped Team" then
        local tNum = tonumber(towerTeam:match("%d+"))
        if tNum then
            pcall(function()
                publishRemote("Units", { Action = "EquipTeam", Team = tNum })
                publishRemote("Units", { Action = "SetTeam", Team = tNum })
                publishRemote("Team", { Action = "Equip", Slot = tNum })
            end)
        end
    end

    local teamList = getTowerTeamList()
    local targetFloor = towerCurrentFloor or selectedTowerFloor or 1

    -- 4. Invoke native controller
    pcall(function()
        local towerScreen = require(ReplicatedStorage.Master.Modules.UI_Client.Screens.Tower)
        if towerScreen then
            if type(towerScreen.OnBattle) == "function" then
                towerScreen.OnBattle()
            end
            if type(towerScreen.OnContinue) == "function" then
                towerScreen.OnContinue()
            end
            if type(towerScreen.OnStart) == "function" then
                towerScreen.OnStart({ Floor = targetFloor, Team = teamList })
            end
        end
    end)

    -- 5. Official Network_Client Publish with all supported action variants
    pcall(function()
        local net = require(ReplicatedStorage.Master.Modules.Network_Client)
        if net and net.Publish then
            net.Publish(net, "Tower", { Action = "Start", Floor = targetFloor, Team = teamList })
            net.Publish(net, "Tower", { Action = "Continue", Floor = targetFloor, Team = teamList })
            net.Publish(net, "Tower", { Action = "Battle", Floor = targetFloor, Team = teamList })
            net.Publish(net, "Tower", "Start")
            net.Publish(net, "Tower", "Battle")
        end
    end)

    -- 6. Direct RemoteService Handler Fallback
    publishRemote("Tower", { Action = "Start", Floor = targetFloor, Team = teamList })
    publishRemote("Tower", { Action = "Continue", Floor = targetFloor, Team = teamList })
    publishRemote("Tower", { Action = "Battle", Floor = targetFloor, Team = teamList })
    publishRemote("Tower", "Start")
    publishRemote("Tower", "Battle")

    WindUI:Notify({
        Title = "Battle Tower 🟢",
        Content = string.format("ส่งคำสั่งเริ่มเล่น Tower (ชั้น %d) เรียบร้อย!", targetFloor),
        Duration = 3,
        Icon = "play"
    })
    return true
end

local function forfeitTower()
    -- 1. Click on-screen "Forfeit" button if Tower screen is open
    clickTowerForfeitButton()

    -- 2. Call native controller if available
    pcall(function()
        local towerScreen = require(ReplicatedStorage.Master.Modules.UI_Client.Screens.Tower)
        if towerScreen and type(towerScreen.OnForfeit) == "function" then
            towerScreen.OnForfeit()
        end
    end)

    -- 3. Publish remote
    pcall(function()
        local net = require(ReplicatedStorage.Master.Modules.Network_Client)
        if net and net.Publish then
            net.Publish(net, "Tower", { Action = "Forfeit" })
        end
    end)
    publishRemote("Tower", { Action = "Forfeit" })

    towerCurrentFloor = 1
    selectedTowerFloor = 1
    pcall(function()
        if UI.towerCurrentFloorSlider and UI.towerCurrentFloorSlider.SetValue then
            UI.towerCurrentFloorSlider:SetValue(1)
        end
        if UI.towerFloorSlider and UI.towerFloorSlider.SetValue then
            UI.towerFloorSlider:SetValue(1)
        end
    end)
    triggerAutoSave()
    WindUI:Notify({ Title = "Tower Climb", Content = "🏳️ ยอมแพ้และรีเซ็ตหอคอยกลับไปเริ่มต้นชั้น 1 เรียบร้อย!", Duration = 3, Icon = "rotate-ccw" })
end

-- Robust Room Creator & Enter (Story, Raids, Challenges, Endless, Tower)
local function enterOrActionRoom(mode, forceSolo)
    mode = mode or selectedGameMode
    local isSolo = if forceSolo ~= nil then forceSolo else not roomFriendsOnly

    if mode == "Tower" then
        return startTowerBattle()
    end

    -- If creating room for Story/Raids/Challenges/Endless, check if blocked by unfinished Tower run:
    local data = LocalPlayer:FindFirstChild("Data")
    local towerFolder = data and data:FindFirstChild("Tower")
    local activeVal = towerFolder and towerFolder:FindFirstChild("Active")
    local checkpointVal = towerFolder and towerFolder:FindFirstChild("Checkpoint")
    local hasActiveTower = (activeVal and activeVal.Value == true)
    local hasCheckpoint = (checkpointVal and checkpointVal.Value > 0)

    if (hasActiveTower or hasCheckpoint) and autoForfeitTowerIfBlocked then
        -- Automatically forfeit blocking Tower run so room creation succeeds!
        forfeitTower()
        task.wait(0.6)
    end

    local worldIdx = WORLD_INDEX_MAP[selectedWorld] or 1
    local raidIdx = RAID_INDEX_MAP[selectedRaid] or 1

    local key = {}
    local options = {
        FriendsOnly = roomFriendsOnly,
        Nightmare = isNightmare,
    }

    if mode == "Story" then
        key = { Mode = "Story", World = worldIdx, Stage = selectedStage }
    elseif mode == "Raids" then
        key = { Mode = "Raid", Raid = raidIdx }
    elseif mode == "Challenges" then
        key = { Mode = "Challenge", Tier = selectedChallenge or "Rotating" }
        options = { FriendsOnly = roomFriendsOnly }
    elseif mode == "Endless" then
        key = { Mode = "Endless" }
        options = { FriendsOnly = roomFriendsOnly }
    end

    -- 1. Native Official Controller (Reliable Native Start & Automatic Door Touch)
    local offRooms = getOfficialRooms()
    if offRooms then
        local called = false
        local success = pcall(function()
            if isSolo and type(offRooms.OnSolo) == "function" then
                called = true
                offRooms.OnSolo(key, options)
            elseif type(offRooms.OnCreate) == "function" then
                called = true
                offRooms.OnCreate(key, options)
            end
        end)
        if success and called then
            WindUI:Notify({ Title = "Room", Content = "🚀 สร้างห้อง & เริ่มเล่น " .. mode .. " ทันที!", Duration = 3, Icon = "circle-play" })
            return true
        end
    end

    -- 2. Fallback: Find free door and teleport directly
    local door, room = findFreeDoor(mode)
    if door and Character then
        door.CanCollide = false
        pcall(function()
            Character:PivotTo(door.CFrame)
        end)
        task.wait(0.2)
        for _, part in ipairs(Character:GetChildren()) do
            if part:IsA("BasePart") then
                pcall(function() firetouchinterest(part, door, 0) end)
            end
        end
        task.wait(0.3)

        -- Publish Room Config
        if mode == "Story" then
            publishRemote("Room", {
                Action = "SelectMap",
                MapName = selectedWorld,
                Stage = selectedStage,
                FriendsOnly = roomFriendsOnly,
                Nightmare = isNightmare,
            })
        elseif mode == "Raids" then
            publishRemote("Room", {
                Action = "SelectMap",
                MapName = selectedRaid,
                FriendsOnly = roomFriendsOnly,
                Nightmare = isNightmare,
            })
        elseif mode == "Challenges" then
            publishRemote("Room", {
                Action = "SelectMap",
                ChallengeTier = selectedChallenge or "Rotating",
                FriendsOnly = roomFriendsOnly,
            })
        elseif mode == "Endless" then
            publishRemote("Room", {
                Action = "SelectMap",
                MapName = selectedEndlessMap or "Endless Maze",
                FriendsOnly = roomFriendsOnly,
            })
        end

        task.wait(0.5)
        publishRemote("Room", {Action = "Start"})
        publishRemote("Controls", {Action = "VoteStart"})
        WindUI:Notify({ Title = "Room", Content = "Created & Sent Start for " .. mode .. "!", Duration = 3, Icon = "door-open" })
        return true
    end

    return false
end

Tabs.Main:Button({
    Title = "🚪 เข้า/สร้างห้องโหมดที่เลือกทันที (Instant Enter/Create Room)",
    Desc = "ค้นหาประตูห้องของโหมดที่เลือก วาปเข้าห้องและตั้งค่าด่านทันที",
    Icon = "door-open",
    Callback = function()
        enterOrActionRoom(selectedGameMode, false)
    end
})

Tabs.Main:Button({
    Title = "🚀 สร้างห้อง & เริ่มเกมคนเดียวทันที (Instant Solo Start)",
    Desc = "สร้างห้องและสั่งกดเริ่มเล่นคนเดียวทันที 1 คลิก (Solo Start)",
    Icon = "circle-play",
    Callback = function()
        enterOrActionRoom(selectedGameMode, true)
    end
})

Tabs.Main:Button({
    Title = "❌ ออกจากห้องปัจจุบัน (Instant Leave Room)",
    Desc = "ออกจากห้องเตรียมตัวทันที 1 ครั้ง",
    Icon = "circle-x",
    Callback = function()
        local offRooms = getOfficialRooms()
        if offRooms and offRooms.OnLeave then
            pcall(offRooms.OnLeave)
        end
        publishRemote("Room", {Action = "Leave"})
        WindUI:Notify({ Title = "Room", Content = "Left Room!", Duration = 3, Icon = "log-out" })
    end
})

-- ==============================================================================
-- TAB TOWER: TOWER CLIMB SYSTEM 🏰 (CONSOLIDATED ALL-IN-ONE ENGINE)
-- ==============================================================================
UI.towerJoinStatusPara = Tabs.Tower:Paragraph({
    Title = "🏰 Tower Status (สถานะระบบสร้างห้องและไต่หอคอย)",
    Desc = "Status: [IDLE] | ชั้นเป้าหมาย: Floor " .. tostring(towerCurrentFloor or selectedTowerFloor or 1) .. "\\nAuto Tower: ⚪ ปิดอยู่ | Checkpoint: ตรวจสอบ...",
    Image = "castle"
})

Tabs.Tower:Section({ Title = "🏰 TOWER CLIMB & AUTO BATTLE (สร้างห้องและเริ่ม Tower อัตโนมัติ)" })

UI.towerAutoJoinToggle = Tabs.Tower:Toggle({
    Title = "⚡ เปิดใช้งาน Auto Tower (สร้างห้อง/ลุยหอคอยอัตโนมัติ)",
    Desc = "สร้างห้องและเข้าไต่หอคอย (Tower) อัตโนมัติ รองรับทั้งเริ่มชั้นใหม่และใช้ Checkpoint ลุยต่อ 100% AFK",
    Value = towerAutoJoin,
    Callback = function(val)
        towerAutoJoin = val
        if val then
            selectedGameMode = "Tower"
            autoCreateAndStart = false
            pcall(function()
                if UI.autoStartToggle and UI.autoStartToggle.SetValue then
                    UI.autoStartToggle:SetValue(false)
                end
                if UI.modeDropdown and UI.modeDropdown.SetValue then
                    UI.modeDropdown:SetValue("Tower")
                end
            end)
            matchCombatEngine = "Smart Play AI"
            smartPlayEnabled = true
        end
        triggerAutoSave()
    end
})

UI.towerCurrentFloorSlider = Tabs.Tower:Slider({
    Title = "Floor Selection (เลือกชั้นเป้าหมาย / ชั้นที่ต้องการเริ่ม)",
    Desc = "กำหนดชั้น Tower ที่ต้องการเริ่มเล่น (ระบบจะบวกเพิ่มทีละ 1 ชั้นเมื่อชนะ)",
    Value = {
        Min = 1,
        Max = 100,
        Default = towerCurrentFloor or selectedTowerFloor or 1,
    },
    Callback = function(val)
        towerCurrentFloor = math.floor(val)
        selectedTowerFloor = towerCurrentFloor
        triggerAutoSave()
    end
})
UI.towerFloorSlider = UI.towerCurrentFloorSlider

UI.towerAutoUseCheckpointToggle = Tabs.Tower:Toggle({
    Title = "🟢 Auto Use Checkpoint (กดใช้ Checkpoint อัตโนมัติเมื่อมีเซฟค้างอยู่)",
    Desc = "เมื่อมี Checkpoint ค้างอยู่ (เช่น ชั้น 35) ระบบจะกดปุ่ม Use Checkpoint ลุยต่อทันที ไม่ต้องกลัวติดแจ้งเตือน 'Finish or forfeit your current Battle Tower run first'",
    Value = (autoUseTowerCheckpoint ~= false),
    Callback = function(state)
        autoUseTowerCheckpoint = state
        triggerAutoSave()
    end
})

UI.towerAutoNextFloorToggle = Tabs.Tower:Toggle({
    Title = "⏩ ชนะแล้วกด Next Battle ลุยชั้นถัดไปทันที (Auto Next Battle)",
    Desc = "เมื่อเคลียร์ชั้น Tower ชนะ จะกดปุ่ม Next Battle ลุยชั้นถัดไปทันทีในห้องเดิม โดยไม่ต้องกลับล็อบบี้หรือสร้างห้องใหม่!",
    Value = (autoNextTowerFloor ~= false),
    Callback = function(state)
        autoNextTowerFloor = state
        triggerAutoSave()
    end
})

UI.towerTeamDropdown = Tabs.Tower:Dropdown({
    Title = "Tower Team (เลือกทีมสำหรับ Tower)",
    Desc = "เลือกทีมยูนิตที่ต้องการสวมใส่ก่อนเข้าหอคอย",
    Values = { "Equipped Team", "Team 1", "Team 2", "Team 3", "Team 4" },
    Value = towerTeam,
    Callback = function(val)
        towerTeam = val
        triggerAutoSave()
    end
})

UI.towerAfterLossDropdown = Tabs.Tower:Dropdown({
    Title = "After A Loss (เมื่อพ่ายแพ้)",
    Desc = "เลือกการกระทำเมื่อพ่ายแพ้ในชั้นนั้นๆ (Start New Run, Retry Floor, Return To Lobby)",
    Values = { "Start New Run", "Retry Floor", "Return To Lobby" },
    Value = towerAfterLoss,
    Callback = function(val)
        towerAfterLoss = val
        triggerAutoSave()
    end
})

UI.towerJoinPrioritySlider = Tabs.Tower:Slider({
    Title = "Join Priority (ความสำคัญ)",
    Desc = "กำหนดความสำคัญในการเข้าห้องและเริ่มแมตช์ (1 - 10)",
    Value = {
        Min = 1,
        Max = 10,
        Default = towerJoinPriority,
    },
    Callback = function(val)
        towerJoinPriority = math.floor(val)
        triggerAutoSave()
    end
})

Tabs.Tower:Section({ Title = "🛑 LEAVE / STOP AT BATTLE (กำหนดจุดหยุดพักหรือยอมแพ้)" })

UI.towerEnableStopAtToggle = Tabs.Tower:Toggle({
    Title = "Enable Leave At Battle (เปิดจุดหยุดพัก)",
    Desc = "เมื่อไต่ถึงชั้นที่กำหนด ให้ทำตามเงื่อนไขที่เลือก (Forfeit And Restart, Return To Lobby, Continue Climbing)",
    Value = towerEnableStopAt,
    Callback = function(val)
        towerEnableStopAt = val
        triggerAutoSave()
    end
})

UI.towerStopAtBattleSlider = Tabs.Tower:Slider({
    Title = "Stop At Battle (หยุดที่ชั้น)",
    Desc = "เลือกชั้นที่ต้องการให้ระบบหยุดหรือรีเซ็ตกลับมาชั้น 1 (ค่าเริ่มต้น: 22)",
    Value = {
        Min = 1,
        Max = 100,
        Default = towerStopAtBattle or 22,
    },
    Callback = function(val)
        towerStopAtBattle = math.floor(val)
        triggerAutoSave()
    end
})

UI.towerAtStopBattleDropdown = Tabs.Tower:Dropdown({
    Title = "At Stop Battle (การกระทำเมื่อถึงชั้นที่กำหนด)",
    Desc = "เลือกการกระทำเมื่อเคลียร์ถึงชั้น Stop At Battle (Forfeit And Restart, Return To Lobby, Continue Climbing)",
    Values = { "Forfeit And Restart", "Return To Lobby", "Continue Climbing" },
    Value = towerAtStopBattle,
    Callback = function(val)
        towerAtStopBattle = val
        triggerAutoSave()
    end
})

Tabs.Tower:Section({ Title = "🚪 Manual Tower Controls (สร้างห้อง/เริ่มหอคอยด้วยตัวเอง & Checkpoint)" })

Tabs.Tower:Button({
    Title = "🟢 กดใช้ Checkpoint ทันที (Use Checkpoint & Enter)",
    Desc = "กดปุ่ม Use Checkpoint บนหน้าจอ และส่งคำสั่งลุยชั้น Checkpoint ต่อทันที",
    Icon = "play",
    Callback = function()
        startTowerBattle()
    end
})

Tabs.Tower:Button({
    Title = "🏰 เข้า/สร้างห้อง Tower ทันที (Instant Enter/Start Tower)",
    Desc = "ส่งคำสั่งเข้าหรือสร้างห้องหอคอย Tower ตามชั้นที่เลือกทันที 1 คลิก",
    Icon = "castle",
    Callback = function()
        startTowerBattle()
    end
})

Tabs.Tower:Button({
    Title = "🏳️ ยอมแพ้หอคอยที่ค้างอยู่ (Forfeit Tower Run)",
    Desc = "ส่งคำสั่งยอมแพ้ เพื่อรีเซ็ตกลับชั้น 1 หรือปลดล็อคการสร้างห้องโหมด Story/Raids ที่ติดแจ้งเตือน",
    Icon = "rotate-ccw",
    Callback = function()
        forfeitTower()
    end
})

Tabs.Tower:Button({
    Title = "🔄 Restore Defaults",
    Desc = "รีเซ็ตการตั้งค่าฝั่ง TOWER CLIMB กลับเป็นค่าเริ่มต้น",
    Icon = "rotate-ccw",
    Callback = function()
        towerAutoJoin = false
        towerTeam = "Equipped Team"
        towerAfterLoss = "Start New Run"
        towerJoinPriority = 1
        towerEnableStopAt = false
        towerStopAtBattle = 22
        towerAtStopBattle = "Forfeit And Restart"
        autoUseTowerCheckpoint = true
        autoNextTowerFloor = true

        pcall(function()
            if UI.towerAutoJoinToggle and UI.towerAutoJoinToggle.SetValue then UI.towerAutoJoinToggle:SetValue(false) end
            if UI.towerTeamDropdown and UI.towerTeamDropdown.SetValue then UI.towerTeamDropdown:SetValue("Equipped Team") end
            if UI.towerAfterLossDropdown and UI.towerAfterLossDropdown.SetValue then UI.towerAfterLossDropdown:SetValue("Start New Run") end
            if UI.towerJoinPrioritySlider and UI.towerJoinPrioritySlider.SetValue then UI.towerJoinPrioritySlider:SetValue(1) end
            if UI.towerEnableStopAtToggle and UI.towerEnableStopAtToggle.SetValue then UI.towerEnableStopAtToggle:SetValue(false) end
            if UI.towerStopAtBattleSlider and UI.towerStopAtBattleSlider.SetValue then UI.towerStopAtBattleSlider:SetValue(22) end
            if UI.towerAtStopBattleDropdown and UI.towerAtStopBattleDropdown.SetValue then UI.towerAtStopBattleDropdown:SetValue("Forfeit And Restart") end
            if UI.towerAutoUseCheckpointToggle and UI.towerAutoUseCheckpointToggle.SetValue then UI.towerAutoUseCheckpointToggle:SetValue(true) end
            if UI.towerAutoNextFloorToggle and UI.towerAutoNextFloorToggle.SetValue then UI.towerAutoNextFloorToggle:SetValue(true) end
        end)

        triggerAutoSave()
        WindUI:Notify({ Title = "Tower Climb", Content = "Restored defaults successfully!", Duration = 3, Icon = "check" })
    end
})

-- Background loop for Auto Farm & Room Automation & Tower Climb
task.spawn(function()
    local lastEnterAttempt = 0
    while scriptRunning do
        task.wait(1.5)
        pcall(function()
            local gameFolder = workspace:FindFirstChild("Game")
            local inMatch = (game.PlaceId == 85423571424083)
                or (gameFolder and gameFolder:FindFirstChild("Started") and gameFolder.Started.Value == true)

            local currentLoc = "⚪ In Lobby (อยู่ในล็อบบี้)"
            local inRoom = Character and Character:GetAttribute("InRoom")
            if inMatch then
                currentLoc = "🟢 In Match (กำลังเล่นแมตช์)"
            elseif inRoom then
                currentLoc = "🟡 In Room (อยู่ในห้องเตรียมตัว)"
            end

            -- Update Status Paragraph (TabMain)
            if UI.farmStatusPara and UI.farmStatusPara.SetDesc then
                local targetDesc = selectedWorld .. " (Act " .. tostring(selectedStage) .. ")"
                if selectedGameMode == "Raids" then
                    targetDesc = selectedRaid
                elseif selectedGameMode == "Challenges" then
                    targetDesc = selectedChallenge
                elseif selectedGameMode == "Endless" then
                    targetDesc = selectedEndlessMap .. " (Endless)"
                elseif selectedGameMode == "Tower" then
                    targetDesc = "Floor " .. tostring(towerCurrentFloor or selectedTowerFloor or 1)
                end

                UI.farmStatusPara:SetDesc(string.format(
                    "โหมดปัจจุบัน: %s\nเป้าหมาย: %s [Nightmare: %s]\nตำแหน่ง: %s\nระบบสร้างห้องและเริ่มอัตโนมัติ: %s",
                    selectedGameMode,
                    targetDesc,
                    isNightmare and "เปิด" or "ปิด",
                    currentLoc,
                    autoCreateAndStart and "🟢 เปิดใช้งาน (Active)" or "⚪ ปิดใช้งาน (Idle)"
                ))
            end

            -- Update Status Paragraphs (TabTower)
            if UI.towerJoinStatusPara and UI.towerJoinStatusPara.SetDesc then
                local joinStatusText = "[IDLE]"
                if towerAutoJoin then
                    if inMatch then
                        joinStatusText = "[IN BATTLE]"
                    elseif inRoom then
                        joinStatusText = "[IN ROOM]"
                    else
                        joinStatusText = "[JOINING]"
                    end
                end
                UI.towerJoinStatusPara:SetDesc(string.format(
                    "Status: %s\nAuto Join: %s | Team: %s\nPriority: %d | After Loss: %s",
                    joinStatusText,
                    towerAutoJoin and "🟢 ON" or "⚪ OFF",
                    towerTeam or "Equipped Team",
                    towerJoinPriority or 1,
                    towerAfterLoss or "Start New Run"
                ))
            end

            if UI.towerClimbStatusPara and UI.towerClimbStatusPara.SetDesc then
                local climbStatusText = towerAutoJoin and (inMatch and "[BATTLING]" or "[READY]") or "[IDLE]"
                local stopRuleText = towerEnableStopAt and (string.format("หยุด/กระทำที่ Floor %d (%s)", towerStopAtBattle or 22, towerAtStopBattle or "Forfeit And Restart")) or "ไต่ต่อเนื่องไม่จำกัดชั้น"
                UI.towerClimbStatusPara:SetDesc(string.format(
                    "Status: %s\nชั้นปัจจุบัน (Current Floor): Floor %d\nเงื่อนไขการหยุด: %s",
                    climbStatusText,
                    towerCurrentFloor or 1,
                    stopRuleText
                ))
            end

            -- Tower Climb Dedicated Automation
            if towerAutoJoin then
                if inMatch then
                    -- Ensure Smart Play AI is active during tower
                    if not smartPlayEnabled then
                        smartPlayEnabled = true
                        matchCombatEngine = "Smart Play AI"
                    end

                    -- Check Match Result
                    local rr, hasEnded, isVictory = getMatchEndGui()
                    if hasEnded then
                        if not UI.matchEndActionDispatched then
                            UI.matchEndActionDispatched = true
                            local towerAction = "Next"
                            if isVictory then
                                local reachedStop = towerEnableStopAt and (towerCurrentFloor >= (towerStopAtBattle or 22))
                                if reachedStop then
                                    if towerAtStopBattle == "Forfeit And Restart" then
                                        WindUI:Notify({ Title = "Tower Climb", Content = "🎯 ถึงชั้นเป้าหมาย Floor " .. tostring(towerStopAtBattle) .. " แล้ว! ส่งคำสั่ง Forfeit และเริ่มใหม่ชั้น 1", Duration = 4, Icon = "rotate-ccw" })
                                        forfeitTower()
                                        towerAction = "Return"
                                    elseif towerAtStopBattle == "Return To Lobby" then
                                        WindUI:Notify({ Title = "Tower Climb", Content = "🏁 ถึงชั้นเป้าหมาย Floor " .. tostring(towerStopAtBattle) .. " แล้ว! ปิดระบบและกลับล็อบบี้", Duration = 4, Icon = "check-check" })
                                        towerAutoJoin = false
                                        pcall(function()
                                            if UI.towerAutoJoinToggle and UI.towerAutoJoinToggle.SetValue then UI.towerAutoJoinToggle:SetValue(false) end
                                        end)
                                        towerAction = "Return"
                                    elseif towerAtStopBattle == "Continue Climbing" then
                                        towerCurrentFloor = towerCurrentFloor + 1
                                        selectedTowerFloor = towerCurrentFloor
                                        towerAction = "Next"
                                        WindUI:Notify({ Title = "Tower Climb", Content = "⚔️ ผ่านชั้นเป้าหมายแล้ว! กด Next ไต่ต่อเนื่องไปยัง Floor " .. tostring(towerCurrentFloor), Duration = 4, Icon = "trending-up" })
                                    end
                                else
                                    towerCurrentFloor = towerCurrentFloor + 1
                                    selectedTowerFloor = towerCurrentFloor
                                    towerAction = "Next"
                                    WindUI:Notify({ Title = "Tower Climb", Content = "🏆 ชนะชั้นเดิมแล้ว! กด Next เลื่อนไปชั้น Floor " .. tostring(towerCurrentFloor) .. " ทันที ไม่ต้องสร้างห้องใหม่", Duration = 3, Icon = "trending-up" })
                                end
                            else
                                -- Loss / Defeat
                                if towerAfterLoss == "Start New Run" then
                                    WindUI:Notify({ Title = "Tower Climb", Content = "❌ แพ้การต่อสู้! ส่งคำสั่ง Forfeit และเริ่มรันใหม่ที่ชั้น 1", Duration = 4, Icon = "rotate-ccw" })
                                    forfeitTower()
                                    towerAction = "Return"
                                elseif towerAfterLoss == "Retry Floor" then
                                    WindUI:Notify({ Title = "Tower Climb", Content = "🔄 แพ้การต่อสู้! กด Replay เล่นชั้นเดิมซ้ำ: Floor " .. tostring(towerCurrentFloor), Duration = 4, Icon = "refresh-cw" })
                                    towerAction = "Replay"
                                elseif towerAfterLoss == "Return To Lobby" then
                                    WindUI:Notify({ Title = "Tower Climb", Content = "⛔ แพ้การต่อสู้! ปิดระบบและกลับล็อบบี้ตามที่ตั้งค่าไว้", Duration = 4, Icon = "log-out" })
                                    towerAutoJoin = false
                                    pcall(function()
                                        if UI.towerAutoJoinToggle and UI.towerAutoJoinToggle.SetValue then UI.towerAutoJoinToggle:SetValue(false) end
                                    end)
                                    towerAction = "Return"
                                end
                            end

                            pcall(function()
                                if UI.towerCurrentFloorSlider and UI.towerCurrentFloorSlider.SetValue then
                                    UI.towerCurrentFloorSlider:SetValue(towerCurrentFloor)
                                end
                            end)
                            triggerAutoSave()

                            triggerMatchEndAction(towerAction)
                        end
                    else
                        UI.matchEndActionDispatched = false
                    end
                else
                    UI.matchEndActionDispatched = false
                    -- In Lobby: auto start tower battle
                    if tick() - lastEnterAttempt > 3.0 then
                        lastEnterAttempt = tick()
                        startTowerBattle()
                    end
                end

            -- Main Auto Farm & Room Engine (TabMain)
            elseif autoCreateAndStart then
                if inMatch then
                    -- Auto arm match engine
                    if matchCombatEngine == "TD Macro" then
                        if not macroPlaybackEnabled then
                            macroPlaybackEnabled = true
                            smartPlayEnabled = false
                            currentMacroStep = 0
                        end
                        if #activeConfig.Steps == 0 and selectedFileToLoad and #selectedFileToLoad > 0 then
                            pcall(function() loadMacroConfig(selectedFileToLoad) end)
                        end
                    elseif matchCombatEngine == "Smart Play AI" then
                        if not smartPlayEnabled then
                            smartPlayEnabled = true
                            macroPlaybackEnabled = false
                        end
                    end

                    -- In Match: handle match end & stage advancement
                    if autoLoopNextMatch then
                        local rr, hasEnded, isVictory = getMatchEndGui()
                        if hasEnded then
                            if not UI.matchEndActionDispatched then
                                UI.matchEndActionDispatched = true
                                local chosenAction = "Next"
                                if isVictory then
                                    if autoNextStage and selectedGameMode == "Story" then
                                        if selectedStage < 5 then
                                            selectedStage = selectedStage + 1
                                            chosenAction = "Next" -- Next stage in-place without rejoining!
                                            WindUI:Notify({ Title = "Next Stage ⏩", Content = "🏆 ชนะ Act เดิมแล้ว! กด Next Battle ลุยด่าน " .. tostring(selectedStage) .. " ทันที ไม่ต้องสร้างห้องใหม่", Duration = 3, Icon = "fast-forward" })
                                        else
                                            -- Act 5 beaten: Next world requires returning to lobby to create new world room
                                            local worlds = { "Hidden Village", "Desert Kingdom", "Dragon City", "Hollow World", "Cursed High School" }
                                            for idx, w in ipairs(worlds) do
                                                if w == selectedWorld and idx < #worlds then
                                                    selectedWorld = worlds[idx + 1]
                                                    selectedStage = 1
                                                    chosenAction = "Return"
                                                    WindUI:Notify({ Title = "World Cleared! 🌍", Content = "🎉 เคลียร์ Act 5 จบโลกแล้ว! กำลังกลับล็อบบี้เพื่อสร้างห้องโลกใหม่: " .. selectedWorld, Duration = 4, Icon = "globe" })
                                                    break
                                                end
                                            end
                                        end
                                    elseif autoNextTowerFloor and selectedGameMode == "Tower" then
                                        selectedTowerFloor = (selectedTowerFloor or 1) + 1
                                        towerCurrentFloor = selectedTowerFloor
                                        chosenAction = "Next" -- Next tower floor in-place!
                                        pcall(function()
                                            if UI.towerCurrentFloorSlider and UI.towerCurrentFloorSlider.SetValue then
                                                UI.towerCurrentFloorSlider:SetValue(towerCurrentFloor)
                                            end
                                        end)
                                        triggerAutoSave()
                                        WindUI:Notify({ Title = "Tower ⏩", Content = "🏆 ชนะชั้นเดิมแล้ว! กด Next Battle เลื่อนไปชั้น Floor " .. tostring(selectedTowerFloor) .. " ทันที", Duration = 3, Icon = "trending-up" })
                                    else
                                        chosenAction = smartMatchEndAction or "Next"
                                    end
                                else
                                    -- Defeat: Retry or Return based on setting
                                    if smartMatchEndAction == "Replay" then
                                        chosenAction = "Replay"
                                        WindUI:Notify({ Title = "Match Defeat", Content = "🔄 แพ้การต่อสู้! กด Replay เล่นด่านเดิมซ้ำ", Duration = 3, Icon = "refresh-cw" })
                                    else
                                        chosenAction = "Return"
                                    end
                                end

                                triggerAutoSave()
                                triggerMatchEndAction(chosenAction)
                            end
                        else
                            UI.matchEndActionDispatched = false
                        end
                    end
                else
                    UI.matchEndActionDispatched = false
                    -- Outside Match (Lobby or In Room)
                    local inRoom = Character and Character:GetAttribute("InRoom")

                    if inRoom then
                        -- If we are in room, start it!
                        local offRooms = getOfficialRooms()
                        if offRooms and offRooms.OnStart then
                            pcall(offRooms.OnStart)
                        end
                        publishRemote("Room", {Action = "Start"})
                        publishRemote("Controls", {Action = "VoteStart"})
                        task.wait(2.5)
                    else
                        -- In Lobby: auto enter & start room
                        if tick() - lastEnterAttempt > 3.5 then
                            lastEnterAttempt = tick()
                            enterOrActionRoom(selectedGameMode, not roomFriendsOnly)
                        end
                    end
                end
            end
        end)
    end
end)


-- ==============================================================================
-- TAB 2: SMART PLAY AI 🧠 (AUTONOMOUS TOWER DEFENSE MATCH ENGINE)
-- ==============================================================================
UI.smartStatusPara = Tabs.Smart:Paragraph({
    Title = "Smart Play Status (สถานะระบบอัจฉริยะ)",
    Desc = "Status: ⚪ Idle | Mode: In Lobby / Waiting for match\nWave: --/-- | Base HP: --\nCash: ¥-- | Placed Towers: 0",
    Image = "cpu"
})

Tabs.Smart:Section({ Title = "Smart Play Controls (เปิดใช้งานโหมดอัจฉริยะ)" })

Tabs.Smart:Toggle({
    Title = "Enable Smart Play AI (โหมดเล่นอัตโนมัติอัจฉริยะ)",
    Desc = "บอทจะคำนวณจุดวางยูนิตที่ดีที่สุด อัปเกรดยูนิต กดสกิล และเปลี่ยนด่านให้อัตโนมัติ โดยไม่ต้องอัด Macro เอง!",
    Value = smartPlayEnabled,
-- Icon = "cpu",
    Callback = function(state)
        smartPlayEnabled = state
        triggerAutoSave()
        WindUI:Notify({
            Title = "Smart Play AI",
            Content = state and "Smart Play AI STARTED! Autonomous match play active." or "Smart Play AI STOPPED.",
            Duration = 3.5,
-- Icon = state and "circle-play" or "circle-x"
        })
    end
})

Tabs.Smart:Dropdown({
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

Tabs.Smart:Section({ Title = "Tactics & Placement (การวางและอัปเกรด)" })

Tabs.Smart:Dropdown({
    Title = "Placement Bias (ตำแหน่งจัดวางยูนิต)",
    Desc = "ตำแหน่งทางยุทธศาสตร์ที่ต้องการให้บอทเล็งวางยูนิต",
    Values = { "Best", "Front", "Back" },
    Value = smartPlacementBias,
    Callback = function(val)
        smartPlacementBias = val
        triggerAutoSave()
    end
})

Tabs.Smart:Dropdown({
    Title = "Upgrade Priority (ลำดับการอัปเกรด)",
    Desc = "เลือกรูปแบบที่ต้องการให้อัปเกรดยูนิตในสนาม",
    Values = { "Focus Carry", "Spread Evenly", "Cheapest First", "Any" },
    Value = smartUpgradePriority,
    Callback = function(val)
        smartUpgradePriority = val
        triggerAutoSave()
    end
})

Tabs.Smart:Toggle({
    Title = "Save Cash For Placements (สำรองเงินค่าวาง)",
    Desc = "กันเงินสำรองไว้สำหรับวางยูนิตจำเป็น ไม่ผลาญเงินไปกับอัปเกรดจนหมด",
    Value = smartSaveForPlacements,
-- Icon = "shield-check",
    Callback = function(state)
        smartSaveForPlacements = state
        triggerAutoSave()
    end
})

Tabs.Smart:Toggle({
    Title = "Sell Farms On Final Wave (ขายฟาร์มเวฟสุดท้าย)",
    Desc = "ขายตัวฟาร์มเงินคืนทุนในเวฟสุดท้าย เพื่อนำเงินทั้งหมดมาอัปเกรดตัวดาเมจสู้บอส",
    Value = smartSellFarmsFinalWave,
-- Icon = "trash-2",
    Callback = function(state)
        smartSellFarmsFinalWave = state
        triggerAutoSave()
    end
})

Tabs.Smart:Section({ Title = "Combat & Match Flow (การต่อสู้และจบเกม)" })

Tabs.Smart:Toggle({
    Title = "Auto Cast Tower Abilities (กดสกิลยูนิตอัตโนมัติ)",
    Desc = "ตรวจจับยูนิตที่มีท่าไม้ตาย (เช่น Fireball, Roar, Pound Cannon) และกดใช้งานให้อัตโนมัติทันทีที่พร้อม",
    Value = smartAutoAbilities,
-- Icon = "sparkles",
    Callback = function(state)
        smartAutoAbilities = state
        triggerAutoSave()
    end
})

Tabs.Smart:Toggle({
    Title = "Smart Target Switching (ปรับโหมดเล็งอัตโนมัติ)",
    Desc = "ปรับตัวดาเมจเดี่ยว/บอสไปเล็ง Strongest และตัวตีหมู่ไปเล็ง First ให้อัตโนมัติ",
    Value = smartAutoTargeting,
-- Icon = "crosshair",
    Callback = function(state)
        smartAutoTargeting = state
        triggerAutoSave()
    end
})

Tabs.Smart:Toggle({
    Title = "Lock 2x Game Speed (เร่งสปีด 2x ตลอดเวลา)",
    Desc = "บังคับเปิดความเร็วเกม 2x ตลอดแมตช์เพื่อความรวดเร็วในการฟาร์ม",
    Value = smartLockSpeed2x,
-- Icon = "zap",
    Callback = function(state)
        smartLockSpeed2x = state
        triggerAutoSave()
    end
})

Tabs.Smart:Toggle({
    Title = "Smart Wave Skip (ข้ามเวฟอัตโนมัติ)",
    Desc = "ส่งคำสั่งข้ามเวฟอัตโนมัติเมื่อเลือดป้อม (Base HP) ปลอดภัย",
    Value = smartAutoSkipWave,
-- Icon = "fast-forward",
    Callback = function(state)
        smartAutoSkipWave = state
        triggerAutoSave()
    end
})

Tabs.Smart:Dropdown({
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
        if UI.smartStatusPara and UI.smartStatusPara.SetDesc then
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
                
                UI.smartStatusPara:SetDesc(string.format(
                    "Status: %s | Strategy: %s\nMap: %s (Act %d) | Wave: %d/%d\nBase HP: %d | Cash: ¥%d | Placed Towers: %d",
                    smartPlayEnabled and "🟢 Running" or "⚪ Paused",
                    smartStrategy,
                    mapName, stage, wave, totalWaves,
                    hp, money, myTowers
                ))
            else
                UI.smartStatusPara:SetDesc(string.format(
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
                local rr, hasEnded, isVictory = getMatchEndGui()
                if hasEnded then
                    triggerMatchEndAction(smartMatchEndAction)
                end
            end)
        end
    end
end)

-- ==============================================================================
-- TAB 3: TOWER DEFENSE MACRO CONFIG (SAVE / LOAD / RECORD / PLAY)
-- ==============================================================================
-- Macro system uses global MACRO_FOLDER & getSavedMacroList defined above

local function getEquippedUnitInfo(slotNumber)
    local info = {
        Slot = slotNumber,
        Name = "Slot " .. tostring(slotNumber),
        RealId = nil,
    }
    pcall(function()
        local unitsFolder = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Units")
        if unitsFolder then
            for _, u in ipairs(unitsFolder:GetChildren()) do
                for _, idF in ipairs(u:GetChildren()) do
                    local eq = idF:FindFirstChild("Equipped")
                    if eq and eq.Value == slotNumber then
                        info.Name = u.Name
                        info.RealId = idF.Name
                        return
                    end
                end
            end
        end
    end)
    return info
end

local function getEquippedUnitInSlot(slotNumber)
    return getEquippedUnitInfo(slotNumber).Name
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

UI.macroStatusPara = nil
UI.macroStepsSummaryPara = nil
UI.savedConfigsDropdown = nil

-- Helper to get champion placement price and upgrade table
local function getChampionInfo(unitName)
    local info = { Price = 800, Upgrades = {} }
    pcall(function()
        local Champions = require(ReplicatedStorage.Master.Information.Champions)
        local c = Champions(unitName)
        if c then
            info.Price = c.Price or info.Price
            info.Upgrades = c.Upgrades or info.Upgrades
        end
    end)
    return info
end

local function getPlacementCost(unitName)
    return getChampionInfo(unitName).Price or 800
end

local function getUpgradeCost(unitName, targetTier)
    local c = getChampionInfo(unitName)
    if c and c.Upgrades and c.Upgrades[targetTier] then
        return c.Upgrades[targetTier].Cost or 0
    end
    return 0
end

-- Universal Sanitizer for Macro Configs (Self-Healing Engine)
-- Fixes broken legacy configs (TargetLevel=60, missing TowerIndex, UUID desyncs)
local function sanitizeMacroConfig(cfg)
    if not cfg or type(cfg) ~= "table" then return cfg end
    if not cfg.Steps or type(cfg.Steps) ~= "table" then
        cfg.Steps = {}
        return cfg
    end

    local towers = {}
    local towerTiers = {}
    local cleaned = {}

    for i, s in ipairs(cfg.Steps) do
        local step = {}
        for k, v in pairs(s) do step[k] = v end
        step.Step = i

        local act = step.Action or "Place"
        step.Action = act

        if act == "Place" then
            local towerIdx = #towers + 1
            step.TowerIndex = step.TowerIndex or towerIdx
            step.TargetTier = 0
            step.Cost = (step.Cost and step.Cost > 0) and step.Cost or getPlacementCost(step.Unit)
            table.insert(towers, {
                index = step.TowerIndex,
                unit = step.Unit,
                x = step.X or 0,
                y = step.Y or 0,
                z = step.Z or 0,
                id = step.TowerId
            })
            towerTiers[step.TowerIndex] = 0
            table.insert(cleaned, step)

        elseif act == "Upgrade" then
            local matchedIdx = step.TowerIndex
            if not matchedIdx then
                -- Match by TowerId if available
                if step.TowerId then
                    for _, tw in ipairs(towers) do
                        if tw.id == step.TowerId then
                            matchedIdx = tw.index
                            break
                        end
                    end
                end
                -- Match by closest position & unit name
                if not matchedIdx and step.X and step.Z then
                    local closestDist = 999999
                    for _, tw in ipairs(towers) do
                        local dist = math.sqrt((tw.x - step.X)^2 + (tw.z - step.Z)^2)
                        if dist < closestDist and (not step.Unit or step.Unit == tw.unit or dist < 2.5) then
                            closestDist = dist
                            matchedIdx = tw.index
                        end
                    end
                end
            end
            matchedIdx = matchedIdx or 1
            step.TowerIndex = matchedIdx
            towerTiers[matchedIdx] = (towerTiers[matchedIdx] or 0) + 1
            step.TargetTier = towerTiers[matchedIdx]
            step.Cost = (step.Cost and step.Cost > 0) and step.Cost or getUpgradeCost(step.Unit, step.TargetTier)
            table.insert(cleaned, step)

        elseif act == "Sell" then
            local matchedIdx = step.TowerIndex
            if not matchedIdx and step.X and step.Z then
                local closestDist = 999999
                for _, tw in ipairs(towers) do
                    local dist = math.sqrt((tw.x - step.X)^2 + (tw.z - step.Z)^2)
                    if dist < closestDist and (not step.Unit or step.Unit == tw.unit or dist < 2.5) then
                        closestDist = dist
                        matchedIdx = tw.index
                    end
                end
            end
            step.TowerIndex = matchedIdx or 1
            table.insert(cleaned, step)
        else
            table.insert(cleaned, step)
        end
    end

    cfg.Steps = cleaned
    return cfg
end

local function formatStepsDesc(steps)
    if not steps or #steps == 0 then
        return "ยังไม่มีสเต็ปที่บันทึก\n👉 กด '🔴 เริ่มอัด Macro สด' แล้วไปวางตัว/อัปเกรดในเกมได้เลย ระบบจะบันทึกให้อัตโนมัติ\n👉 หรือกด '📍 บันทึกจุดที่ยืนอยู่' เพื่อจับพิกัดทันที 1 คลิก"
    end
    local lines = {}
    for i, s in ipairs(steps) do
        local act = s.Action or "Place"
        local unitLabel = s.Unit or ("Slot " .. tostring(s.Slot or 1))
        local twIdx = s.TowerIndex or i
        if act == "Place" then
            local costStr = (s.Cost and s.Cost > 0) and string.format(" (¥%s)", tostring(s.Cost)) or ""
            table.insert(lines, string.format("#%d: [🎯 วาง] Unit #%d: %s%s ที่ (%.1f, %.1f) [รอ %.1fวิ]",
                s.Step or i, twIdx, unitLabel, costStr, s.X or 0, s.Z or 0, s.Delay or 1.5))
        elseif act == "Upgrade" then
            local costStr = (s.Cost and s.Cost > 0) and string.format(" (¥%s)", tostring(s.Cost)) or ""
            table.insert(lines, string.format("#%d: [⚡ อัปเกรด] Unit #%d: %s -> Tier %d%s [รอ %.1fวิ]",
                s.Step or i, twIdx, unitLabel, s.TargetTier or 1, costStr, s.Delay or 1.0))
        elseif act == "Sell" then
            table.insert(lines, string.format("#%d: [💰 ขาย] Unit #%d: %s ที่ (%.1f, %.1f) [รอ %.1fวิ]",
                s.Step or i, twIdx, unitLabel, s.X or 0, s.Z or 0, s.Delay or 1.0))
        end
    end
    return table.concat(lines, "\n")
end

local function updateMacroStatus()
    if UI.macroStepsSummaryPara and UI.macroStepsSummaryPara.SetDesc then
        UI.macroStepsSummaryPara:SetDesc(formatStepsDesc(activeConfig.Steps))
    end
    if UI.macroStatusPara and UI.macroStatusPara.SetDesc then
        local statusText = "⚪ พักอยู่ (Idle)"
        if isRecordingMacro then
            statusText = string.format("🔴 กำลังอัด Macro... (อัดแล้ว %d สเต็ป)", #activeConfig.Steps)
        elseif macroPlaybackEnabled then
            statusText = string.format("🟢 กำลังเล่น Macro... (สเต็ป %d / %d)", currentMacroStep, #activeConfig.Steps)
        end
        UI.macroStatusPara:SetDesc(string.format("คอนฟิก: %s\nจำนวนสเต็ป: %d สเต็ป\nสถานะ: %s\nคำแนะนำ: กด '🔴 เริ่มอัด' แล้วไปวางตัวในเกมได้เลย!",
            activeConfig.Name,
            #activeConfig.Steps,
            statusText
        ))
    end
end

local function loadMacroConfig(name)
    name = (name and #name > 0) and name or selectedFileToLoad
    name = name:gsub('[%\\/%:%*%?%"%<%>%|]', "_")
    local success = false
    pcall(function()
        local path = MACRO_FOLDER .. "/" .. name .. ".json"
        if not isfile(path) then
            path = MACRO_FOLDER .. "/Default_Tower_Farm.json"
        end
        if isfile(path) then
            local json = readfile(path)
            local data = HttpService:JSONDecode(json)
            if type(data) == "table" then
                activeConfig = sanitizeMacroConfig(data)
                activeConfig.Name = data.Name or name
                macroNameInput = activeConfig.Name
                selectedFileToLoad = name
                if data.AutoStart ~= nil then macroAutoStart = data.AutoStart end
                if data.AutoNext ~= nil then macroLoopEnabled = data.AutoNext end
                if data.AutoUpgrade ~= nil then macroAutoUpgrade = data.AutoUpgrade end
                success = true
                currentMacroStep = 0
                updateMacroStatus()
                WindUI:Notify({
                    Title = "Macro Auto-Loaded 📂",
                    Content = string.format("โหลด '%s' สำเร็จ (%d สเต็ป)", activeConfig.Name, #activeConfig.Steps),
                    Duration = 3,
                    Icon = "folder-check"
                })
            end
        end
    end)
    return success
end

-- ==============================================================================
-- 100% PRECISE DUAL-ENGINE MACRO RECORDING SYSTEM
-- ==============================================================================
local recordedPlacements = {}   -- list of placed towers: { index, unit, realId, pos, rotY, id, tier }
local recordedTowersById = {}   -- map of UUID -> recordedPlacements item
-- [Duplicate tower connections removed]


local function recordPlaceStep(unitName, realId, pos, rotY, towerId)
    if not isRecordingMacro then return end

    -- Check duplicate placement within 1.0 stud
    for _, tw in ipairs(recordedPlacements) do
        local dist = (Vector3.new(tw.pos.X, 0, tw.pos.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude
        if dist < 1.0 then
            if towerId and not tw.id then
                tw.id = towerId
                recordedTowersById[towerId] = tw
            end
            return
        end
    end

    local now = tick()
    local delay = (lastActionTime > 0) and math.clamp(math.floor((now - lastActionTime) * 10) / 10, 0.5, 30) or 1.5
    lastActionTime = now

    local slotNum = 1
    for s = 1, 6 do
        local inf = getEquippedUnitInfo(s)
        if (realId and inf.RealId == realId) or inf.Name == unitName then
            slotNum = s
            if not realId then realId = inf.RealId end
            break
        end
    end

    local twIdx = #recordedPlacements + 1
    local cost = getPlacementCost(unitName)

    local twRecord = {
        index = twIdx,
        unit = unitName,
        realId = realId,
        pos = pos,
        rotY = rotY,
        id = towerId,
        tier = 0
    }
    table.insert(recordedPlacements, twRecord)
    if towerId then
        recordedTowersById[towerId] = twRecord
    end

    local newStep = {
        Step = #activeConfig.Steps + 1,
        Action = "Place",
        TowerIndex = twIdx,
        Slot = slotNum,
        Unit = unitName,
        RealId = realId,
        TowerId = towerId,
        X = math.floor(pos.X * 10) / 10,
        Y = math.floor(pos.Y * 10) / 10,
        Z = math.floor(pos.Z * 10) / 10,
        Rotation = math.floor(rotY),
        TargetTier = 0,
        Cost = cost,
        Delay = delay,
    }
    table.insert(activeConfig.Steps, newStep)
    updateMacroStatus()

    WindUI:Notify({
        Title = "Step Recorded 🎯",
        Content = string.format("#%d: วาง %s (Unit #%d) ที่ (%.1f, %.1f)", newStep.Step, unitName, twIdx, newStep.X, newStep.Z),
        Duration = 2.5,
        Icon = "circle-check"
    })
end

local function recordUpgradeStep(towerInst, towerId)
    if not isRecordingMacro then return end
    towerInst = towerInst or (towerId and workspace:FindFirstChild("Towers") and workspace.Towers:FindFirstChild(towerId))
    if not towerInst then return end

    local id = towerId or towerInst.Name
    local twRecord = recordedTowersById[id]
    if not twRecord then
        local pos = towerInst:GetPivot().Position
        local closestDist = 999999
        for _, tw in ipairs(recordedPlacements) do
            local dist = (Vector3.new(tw.pos.X, 0, tw.pos.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude
            if dist < closestDist and dist < 3.0 then
                closestDist = dist
                twRecord = tw
            end
        end
    end

    local twIdx = twRecord and twRecord.index or 1
    local unitName = twRecord and twRecord.unit or (towerInst:GetAttribute("Name") or towerInst.Name)
    local curTier = twRecord and twRecord.tier or (towerInst:GetAttribute("Tier") or 0)
    local newTier = curTier + 1
    if twRecord then twRecord.tier = newTier end

    local now = tick()
    local delay = (lastActionTime > 0) and math.clamp(math.floor((now - lastActionTime) * 10) / 10, 0.5, 30) or 1.0
    lastActionTime = now

    local pos = twRecord and twRecord.pos or towerInst:GetPivot().Position
    local cost = getUpgradeCost(unitName, newTier)

    local upgStep = {
        Step = #activeConfig.Steps + 1,
        Action = "Upgrade",
        TowerIndex = twIdx,
        TowerId = id,
        Unit = unitName,
        X = math.floor(pos.X * 10) / 10,
        Y = math.floor(pos.Y * 10) / 10,
        Z = math.floor(pos.Z * 10) / 10,
        TargetTier = newTier,
        Cost = cost,
        Delay = delay,
    }
    table.insert(activeConfig.Steps, upgStep)
    updateMacroStatus()

    WindUI:Notify({
        Title = "Upgrade Recorded ⚡",
        Content = string.format("#%d: อัปเกรด %s (Unit #%d) -> Tier %d", upgStep.Step, unitName, twIdx, newTier),
        Duration = 2.5,
        Icon = "wand"
    })
end

local function recordSellStep(towerInst, towerId)
    if not isRecordingMacro then return end
    towerInst = towerInst or (towerId and workspace:FindFirstChild("Towers") and workspace.Towers:FindFirstChild(towerId))
    local id = towerId or (towerInst and towerInst.Name)
    local twRecord = id and recordedTowersById[id]
    if not twRecord and towerInst then
        local pos = towerInst:GetPivot().Position
        for _, tw in ipairs(recordedPlacements) do
            local dist = (Vector3.new(tw.pos.X, 0, tw.pos.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude
            if dist < 3.0 then
                twRecord = tw
                break
            end
        end
    end

    local twIdx = twRecord and twRecord.index or 1
    local unitName = twRecord and twRecord.unit or (towerInst and (towerInst:GetAttribute("Name") or towerInst.Name) or "Tower")
    local pos = twRecord and twRecord.pos or (towerInst and towerInst:GetPivot().Position or Vector3.new(0, 0, 0))

    local now = tick()
    local delay = (lastActionTime > 0) and math.clamp(math.floor((now - lastActionTime) * 10) / 10, 0.5, 30) or 1.0
    lastActionTime = now

    local sellStep = {
        Step = #activeConfig.Steps + 1,
        Action = "Sell",
        TowerIndex = twIdx,
        TowerId = id,
        Unit = unitName,
        X = math.floor(pos.X * 10) / 10,
        Y = math.floor(pos.Y * 10) / 10,
        Z = math.floor(pos.Z * 10) / 10,
        Delay = delay,
    }
    table.insert(activeConfig.Steps, sellStep)
    updateMacroStatus()

    WindUI:Notify({
        Title = "Sell Recorded 💰",
        Content = string.format("#%d: ขาย %s (Unit #%d)", sellStep.Step, unitName, twIdx),
        Duration = 2.5,
        Icon = "trash-2"
    })
end

-- Network Publish Hook for 100% accurate live recording
local networkHookInstalled = false
local function ensureNetworkRecordingHook()
    if networkHookInstalled then return end
    if not NetworkClient or not NetworkClient.Publish then return end
    networkHookInstalled = true
    local originalPublish = NetworkClient.Publish
    NetworkClient.Publish = function(self, topic, data)
        local actualSelf = self
        local actualTopic = topic
        local actualData = data
        if type(self) == "string" then
            actualTopic = self
            actualData = topic
        end

        if isRecordingMacro and actualTopic == "HandleTower" and type(actualData) == "table" then
            pcall(function()
                if actualData.Action == "Place" and actualData.TowerPosition then
                    local pos = actualData.TowerPosition
                    local unitName = actualData.Tower or "Unknown"
                    local realId = actualData.RealId
                    local rotY = (actualData.TowerOrientation and actualData.TowerOrientation.Y) or 0
                    recordPlaceStep(unitName, realId, pos, rotY, nil)
                elseif actualData.Action == "Upgrade" and actualData.Id then
                    recordUpgradeStep(nil, tostring(actualData.Id))
                elseif actualData.Action == "Sell" and actualData.Id then
                    recordSellStep(nil, tostring(actualData.Id))
                end
            end)
        end
        return originalPublish(actualSelf, actualTopic, actualData)
    end
end

local function startMacroRecording()
    if isRecordingMacro then return end
    isRecordingMacro = true
    recordingStartTime = tick()
    lastActionTime = tick()
    activeConfig.Steps = {}
    table.clear(recordedPlacements)
    table.clear(recordedTowersById)
    updateMacroStatus()

    pcall(ensureNetworkRecordingHook)

    WindUI:Notify({
        Title = "Macro Recorder",
        Content = "🔴 เริ่มอัด Macro สดแล้ว! วางตัวหรืออัปเกรดยูนิตในเกมได้เลย ระบบจับให้อัตโนมัติ",
        Duration = 4,
        Icon = "circle-dot"
    })

    if towerAddedConn then
        pcall(function() towerAddedConn:Disconnect() end)
        towerAddedConn = nil
    end
    for _, conn in ipairs(towerChangedConns) do
        pcall(function() conn:Disconnect() end)
    end
    towerChangedConns = {}

    local function onNewTower(tower)
        task.wait(0.15)
        if not isRecordingMacro then return end

        local owner = tower:GetAttribute("Owner")
        if owner and owner ~= LocalPlayer.Name then return end

        local unitName = tower:GetAttribute("Name") or tower.Name
        local pivot = tower:GetPivot()
        local pos = pivot.Position
        local rotY = math.floor(pivot.Rotation.Y * 10) / 10
        local realId = tower:GetAttribute("RealId")

        recordPlaceStep(unitName, realId, pos, rotY, tower.Name)

        -- Listen for Tier attribute changes (Upgrade)
        local lastRecordedTier = tower:GetAttribute("Tier") or 0
        local cTier = tower:GetAttributeChangedSignal("Tier"):Connect(function()
            if not isRecordingMacro then return end
            local curTier = tower:GetAttribute("Tier") or 0
            if curTier > lastRecordedTier then
                lastRecordedTier = curTier
                local lastS = activeConfig.Steps[#activeConfig.Steps]
                if not (lastS and lastS.Action == "Upgrade" and lastS.TowerId == tower.Name and lastS.TargetTier == curTier) then
                    recordUpgradeStep(tower, tower.Name)
                end
            end
        end)
        table.insert(towerChangedConns, cTier)

        -- Listen for AncestryChanged (Sell)
        local cAnc = tower.AncestryChanged:Connect(function(_, parent)
            if parent == nil and isRecordingMacro then
                local lastS = activeConfig.Steps[#activeConfig.Steps]
                if not (lastS and lastS.Action == "Sell" and lastS.TowerId == tower.Name) then
                    recordSellStep(tower, tower.Name)
                end
            end
        end)
        table.insert(towerChangedConns, cAnc)
    end

    local towersFolder = workspace:FindFirstChild("Towers")
    if towersFolder then
        towerAddedConn = towersFolder.ChildAdded:Connect(onNewTower)
    else
        task.spawn(function()
            local folder = workspace:WaitForChild("Towers", 30)
            if folder and isRecordingMacro then
                towerAddedConn = folder.ChildAdded:Connect(onNewTower)
            end
        end)
    end
end

local function stopMacroRecording()
    if not isRecordingMacro then return end
    isRecordingMacro = false

    if towerAddedConn then
        pcall(function() towerAddedConn:Disconnect() end)
        towerAddedConn = nil
    end
    for _, conn in ipairs(towerChangedConns) do
        pcall(function() conn:Disconnect() end)
    end
    towerChangedConns = {}

    pcall(function()
        if not isfolder("AnimeGalaxiesHub") then makefolder("AnimeGalaxiesHub") end
        if not isfolder(MACRO_FOLDER) then makefolder(MACRO_FOLDER) end

        activeConfig = sanitizeMacroConfig(activeConfig)

        local saveName = (macroNameInput and #macroNameInput > 0) and macroNameInput or (activeConfig.Name or "My_Tower_Macro")
        saveName = saveName:gsub('[%\\/%:%*%?%"%<%>%|]', "_")
        activeConfig.Name = saveName
        local json = HttpService:JSONEncode(activeConfig)
        local path = MACRO_FOLDER .. "/" .. saveName .. ".json"
        writefile(path, json)

        selectedFileToLoad = saveName
        if UI.savedConfigsDropdown then
            local updatedList = getSavedMacroList(saveName)
            updateDropdown(UI.savedConfigsDropdown, updatedList, saveName)
        end
    end)

    updateMacroStatus()

    WindUI:Notify({
        Title = "Macro Recorder",
        Content = string.format("⏹️ หยุดอัดแล้ว! บันทึกสำเร็จ %d สเต็ป และเซฟลงไฟล์เรียบร้อย!", #activeConfig.Steps),
        Duration = 4,
        Icon = "circle-check"
    })
end

local function quickRecordCurrentSpot()
    pcall(function()
        local pos = RootPart and RootPart.Position or Vector3.new(0, 0, 0)
        local nextSlot = ((#activeConfig.Steps) % 6) + 1
        local slotInfo = getEquippedUnitInfo(nextSlot)
        local unitName = slotInfo.Name

        local now = tick()
        local delay = (lastActionTime > 0) and math.clamp(math.floor((now - lastActionTime) * 10) / 10, 0.5, 30) or 1.5
        lastActionTime = now

        local rotY = RootPart and math.floor(RootPart.Orientation.Y) or 0
        local twIdx = #recordedPlacements + 1
        local cost = getPlacementCost(unitName)

        local twRecord = {
            index = twIdx,
            unit = unitName,
            realId = slotInfo.RealId,
            pos = pos,
            rotY = rotY,
            tier = 0
        }
        table.insert(recordedPlacements, twRecord)

        local newStep = {
            Step = #activeConfig.Steps + 1,
            Action = "Place",
            TowerIndex = twIdx,
            Slot = nextSlot,
            Unit = unitName,
            RealId = slotInfo.RealId,
            X = math.floor(pos.X * 10) / 10,
            Y = math.floor(pos.Y * 10) / 10,
            Z = math.floor(pos.Z * 10) / 10,
            Rotation = rotY,
            TargetTier = 0,
            Cost = cost,
            Delay = delay,
        }
        table.insert(activeConfig.Steps, newStep)
        updateMacroStatus()

        WindUI:Notify({
            Title = "Step Added 📍",
            Content = string.format("บันทึกจุดที่ยืน #%d: Slot %d (%s) ที่ (%.1f, %.1f)", newStep.Step, nextSlot, unitName, newStep.X, newStep.Z),
            Duration = 3,
            Icon = "map-pin"
        })
    end)
end

UI.macroStatusPara = Tabs.Macro:Paragraph({
    Title = "🎮 TD Macro Controller (ระบบจัดการ Macro)",
    Desc = "สถานะ: ⚪ พักอยู่ (Idle)\nคอนฟิก: My_Tower_Macro | สเต็ป: 0 สเต็ป\nคำแนะนำ: กด '🔴 อัด Macro' แล้ววางตัว/อัปเกรดได้เลย!",
    Image = "gamepad-2"
})

Tabs.Macro:Section({ Title = "🔴 ระบบอัด Macro สด (Live Recorder)" })

Tabs.Macro:Button({
    Title = "🔴 อัด Macro สด (Start Record)",
    Desc = "วางและอัปเกรดยูนิตในเกม ระบบจะจับอัตโนมัติ",
    Icon = "circle-dot",
    Callback = function()
        startMacroRecording()
    end
})

Tabs.Macro:Button({
    Title = "⏹️ หยุดอัด Macro (Stop Record)",
    Desc = "หยุดอัด และบันทึกคอนฟิกลงเครื่องอัตโนมัติทันที",
    Icon = "square",
    Callback = function()
        stopMacroRecording()
    end
})

Tabs.Macro:Button({
    Title = "📍 บันทึกจุดที่ยืนปัจจุบัน 1 คลิก (Quick Record Spot)",
    Desc = "เดินไปจุดที่ต้องการ แล้วกดเพื่อบันทึกพิกัดวางยูนิตทันที",
    Icon = "map-pin",
    Callback = function()
        quickRecordCurrentSpot()
    end
})

Tabs.Macro:Button({
    Title = "🧹 ล้างสเต็ปที่อัดทั้งหมด (Clear Steps)",
    Desc = "ล้างรายการสเต็ปที่กำลังอัดเพื่อเริ่มใหม่",
    Icon = "trash-2",
    Callback = function()
        activeConfig.Steps = {}
        table.clear(recordedPlacements)
        table.clear(recordedTowersById)
        updateMacroStatus()
        WindUI:Notify({ Title = "Macro Cleared", Content = "ล้างสเต็ปทั้งหมดแล้ว!", Duration = 2, Icon = "trash-2" })
    end
})

Tabs.Macro:Section({ Title = "▶️ เล่น Macro อัตโนมัติ (Playback Controls)" })

Tabs.Macro:Toggle({
    Title = "▶️ เปิดเล่น Macro (Enable Macro Playback)",
    Desc = "เปิดระบบทำงานอัตโนมัติตามสเต็ปที่อัดไว้",
    Value = macroPlaybackEnabled,
-- Icon = "play",
    Callback = function(state)
        macroPlaybackEnabled = state
        currentMacroStep = 0
        table.clear(playbackTowers)
        triggerAutoSave()
        updateMacroStatus()
        WindUI:Notify({
            Title = "TD Macro",
            Content = state and "▶️ เริ่มเล่น Macro แล้ว!" or "⏹️ หยุดเล่น Macro แล้ว",
            Duration = 3,
-- Icon = state and "circle-play" or "circle-x"
        })
    end
})

Tabs.Macro:Toggle({
    Title = "🔁 วนลูปเล่นซ้ำทุกรอบ (Loop on Next Match)",
    Desc = "วนลูป Macro ซ้ำให้อัตโนมัติเมื่อเริ่มเกมรอบใหม่",
    Value = macroLoopEnabled,
-- Icon = "repeat",
    Callback = function(state)
        macroLoopEnabled = state
        triggerAutoSave()
    end
})

Tabs.Macro:Toggle({
    Title = "⚡ เร่งสปีดเกม 2x (Auto 2x Speed)",
    Desc = "เร่งความเร็วเกมเป็น 2 เท่าตลอดแมตช์",
    Value = macroLockSpeed2x,
-- Icon = "zap",
    Callback = function(state)
        macroLockSpeed2x = state
        triggerAutoSave()
    end
})

Tabs.Macro:Toggle({
    Title = "⏭️ ข้ามเวฟอัตโนมัติ (Auto Skip Wave)",
    Desc = "ข้ามเวฟอัตโนมัติเมื่อเลือดป้อมอยู่ในระดับปลอดภัย",
    Value = macroAutoSkipWave,
-- Icon = "fast-forward",
    Callback = function(state)
        macroAutoSkipWave = state
        triggerAutoSave()
    end
})

Tabs.Macro:Toggle({
    Title = "⏩ กดเริ่มแมตช์อัตโนมัติ (Auto Start Match)",
    Desc = "กดเริ่มแมตช์และกดเล่นต่อรอบให้อัตโนมัติ",
    Value = macroAutoStart,
-- Icon = "circle-play",
    Callback = function(state)
        macroAutoStart = state
        triggerAutoSave()
    end
})

Tabs.Macro:Toggle({
    Title = "🛠️ อัปเกรดยูนิตต่อเนื่อง (Auto Upgrade Units)",
    Desc = "ส่งคำสั่งอัปเกรดยูนิตที่วางไว้ต่อเนื่อง",
    Value = macroAutoUpgrade,
-- Icon = "wand",
    Callback = function(state)
        macroAutoUpgrade = state
        triggerAutoSave()
    end
})

Tabs.Macro:Section({ Title = "📁 จัดการไฟล์ Macro (Save / Load)" })

Tabs.Macro:Input({
    Title = "Macro Config Name",
    Desc = "พิมพ์ชื่อคอนฟิกสำหรับบันทึก (Save/Load)",
    Value = macroNameInput,
    Placeholder = "Enter config name...",
    Callback = function(text)
        if text and #text > 0 then
            macroNameInput = text:gsub('[%\\/%:%*%?%"%<%>%|]', "_")
            activeConfig.Name = macroNameInput
            triggerAutoSave()
            updateMacroStatus()
        end
    end
})

UI.savedConfigsDropdown = Tabs.Macro:Dropdown({
    Title = "Select Saved Config",
    Desc = "เลือกไฟล์ Macro (ระบบโหลดอัตโนมัติทันทีที่เลือก)",
    Values = getSavedMacroList(),
    Value = selectedFileToLoad,
    Callback = function(val)
        if val and #val > 0 then
            loadMacroConfig(val)
            triggerAutoSave()
        end
    end
})

Tabs.Macro:Button({
    Title = "💾 Save / Overwrite Macro Config",
    Desc = "บันทึกสเต็ปและค่าคอนฟิกลงไฟล์ JSON ทันที",
    Icon = "save",
    Callback = function()
        pcall(function()
            if not isfolder("AnimeGalaxiesHub") then makefolder("AnimeGalaxiesHub") end
            if not isfolder(MACRO_FOLDER) then makefolder(MACRO_FOLDER) end

            local saveName = (macroNameInput and #macroNameInput > 0) and macroNameInput or (activeConfig.Name or "My_Tower_Macro")
            saveName = saveName:gsub('[%\\/%:%*%?%"%<%>%|]', "_")
            activeConfig.Name = saveName
            activeConfig.AutoStart = macroAutoStart
            activeConfig.AutoNext = macroLoopEnabled
            activeConfig.AutoUpgrade = macroAutoUpgrade

            activeConfig = sanitizeMacroConfig(activeConfig)

            local json = HttpService:JSONEncode(activeConfig)
            local path = MACRO_FOLDER .. "/" .. saveName .. ".json"
            writefile(path, json)

            selectedFileToLoad = saveName
            local updatedList = getSavedMacroList(saveName)
            if UI.savedConfigsDropdown then
                updateDropdown(UI.savedConfigsDropdown, updatedList, saveName)
            end

            updateMacroStatus()
            WindUI:Notify({ Title = "Macro Saved", Content = "Saved config: " .. activeConfig.Name .. " (" .. tostring(#activeConfig.Steps) .. " steps)", Duration = 3.5, Icon = "save" })
        end)
    end
})

Tabs.Macro:Button({
    Title = "📂 Load Selected Macro Config",
    Desc = "โหลดคอนฟิกจากไฟล์ที่เลือกมาใช้งาน",
    Icon = "folder-open",
    Callback = function()
        loadMacroConfig(selectedFileToLoad)
    end
})

Tabs.Macro:Button({
    Title = "🗑️ Delete Selected Config",
    Desc = "ลบไฟล์คอนฟิกที่เลือกออกจากเครื่อง",
    Icon = "trash-2",
    Callback = function()
        pcall(function()
            local path = MACRO_FOLDER .. "/" .. selectedFileToLoad .. ".json"
            if isfile(path) then
                delfile(path)
                local updatedList = getSavedMacroList()
                local nextSelected = updatedList[1] or "Default_Tower_Farm"
                selectedFileToLoad = nextSelected
                if UI.savedConfigsDropdown then
                    updateDropdown(UI.savedConfigsDropdown, updatedList, nextSelected)
                end
                loadMacroConfig(nextSelected)
                WindUI:Notify({ Title = "Macro Deleted", Content = "Deleted " .. selectedFileToLoad, Duration = 3, Icon = "trash-2" })
            end
        end)
    end
})

Tabs.Macro:Button({
    Title = "🔄 Refresh Config List",
    Desc = "รีเฟรชรายชื่อคอนฟิกในโฟลเดอร์",
    Icon = "refresh-cw",
    Callback = function()
        if UI.savedConfigsDropdown then
            local updatedList = getSavedMacroList(selectedFileToLoad)
            updateDropdown(UI.savedConfigsDropdown, updatedList, selectedFileToLoad)
            WindUI:Notify({ Title = "Macro", Content = "Refreshed macro list!", Duration = 2, Icon = "circle-check" })
        end
    end
})

Tabs.Macro:Section({ Title = "📋 รายการสเต็ปที่บันทึกไว้ (Recorded Steps)" })

UI.macroStepsSummaryPara = Tabs.Macro:Paragraph({
    Title = "Recorded Steps Summary (รายการสเต็ป)",
    Desc = formatStepsDesc(activeConfig.Steps),
    Image = "file-text"
})

-- ==============================================================================
-- 100% DETERMINISTIC PLAYBACK ENGINE (STATE-AWARE & CASH-SAFE)
-- ==============================================================================
local playbackTowers = {} -- maps towerIndex -> live tower Model in current match

local function findPlacedTowerNear(targetPos, maxDist, unitName)
    maxDist = maxDist or 4.5
    local towersFolder = workspace:FindFirstChild("Towers")
    if not towersFolder then return nil end
    local closest, closestDist = nil, maxDist
    for _, t in ipairs(towersFolder:GetChildren()) do
        local owner = t:GetAttribute("Owner")
        if not owner or owner == LocalPlayer.Name then
            local tName = t:GetAttribute("Name") or t.Name
            if not unitName or tName == unitName then
                local ok, pivot = pcall(function() return t:GetPivot() end)
                if ok and pivot then
                    local dist = (Vector3.new(pivot.Position.X, 0, pivot.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude
                    if dist < closestDist then
                        closest = t
                        closestDist = dist
                    end
                end
            end
        end
    end
    return closest
end

local function executeMacroStep(step)
    if not step or not macroPlaybackEnabled or not scriptRunning then return false end
    local stepPos = Vector3.new(step.X or 0, step.Y or 0, step.Z or 0)
    local twIdx = step.TowerIndex or step.twIdx or step.Step or 1

    local function getMoney()
        local m = LocalPlayer:FindFirstChild("Money")
        return m and m.Value or 999999
    end

    local function waitSufficientMoney(requiredCost)
        if not requiredCost or requiredCost <= 0 then return true end
        local waitStart = tick()
        while macroPlaybackEnabled and scriptRunning and getMoney() < requiredCost do
            local gameFolder = workspace:FindFirstChild("Game")
            local inMatch = (game.PlaceId == 85423571424083) or (gameFolder and gameFolder:FindFirstChild("Started") and gameFolder.Started.Value)
            if not inMatch then return false end

            if UI.macroStatusPara and UI.macroStatusPara.SetDesc then
                UI.macroStatusPara:SetDesc(string.format("🟡 กำลังรอเงินสำหรับสเต็ป #%d (%s)\nเงินที่มี: ¥%s / ต้องการ: ¥%s\nสถานะ: กำลังรอรอบเงินจากเวฟ...",
                    step.Step or twIdx, step.Unit or "Tower", formatNumber(getMoney()), formatNumber(requiredCost)))
            end
            task.wait(0.5)
            if tick() - waitStart > 90 then
                return false
            end
        end
        return true
    end

    if step.Action == "Place" or not step.Action then
        -- Check if already placed in playbackTowers or nearby
        if playbackTowers[twIdx] and playbackTowers[twIdx].Parent then
            return true
        end
        local existing = findPlacedTowerNear(stepPos, 3.5, step.Unit)
        if existing then
            playbackTowers[twIdx] = existing
            return true
        end

        local cost = (step.Cost and step.Cost > 0) and step.Cost or getPlacementCost(step.Unit)
        if not waitSufficientMoney(cost) then return false end

        -- Teleport character close to placement spot locally
        pcall(function()
            if RootPart and (step.X ~= 0 or step.Z ~= 0) then
                RootPart.CFrame = CFrame.new(Vector3.new(step.X, step.Y + 2.5, step.Z))
            end
        end)
        task.wait(0.15)

        local slotInfo = getEquippedUnitInfo(step.Slot or 1)
        local unitName = step.Unit or slotInfo.Name
        local realId = step.RealId or slotInfo.RealId or "1"
        local rotY = step.Rotation or 0

        local placePayload = {
            Action = "Place",
            Tower = unitName,
            TowerPosition = stepPos,
            TowerOrientation = Vector3.new(0, rotY, 0),
            RealId = realId,
            NoPhantom = true,
        }

        local attempts = 0
        local maxAttempts = 6
        while macroPlaybackEnabled and scriptRunning and attempts < maxAttempts do
            attempts = attempts + 1

            pcall(function()
                if RootPart and (step.X ~= 0 or step.Z ~= 0) then
                    RootPart.CFrame = CFrame.new(Vector3.new(step.X, step.Y + 2.5, step.Z))
                end
            end)

            publishRemote("HandleTower", placePayload)

            pcall(function()
                local Towers_Client = require(ReplicatedStorage.Master.Modules.Towers_Client)
                if Towers_Client and Towers_Client.PlaceAt then
                    Towers_Client:PlaceAt(unitName, stepPos, Vector3.new(0, rotY, 0), realId)
                end
            end)

            task.wait(0.6)

            local tower = findPlacedTowerNear(stepPos, 4.5, unitName)
            if tower then
                playbackTowers[twIdx] = tower
                WindUI:Notify({
                    Title = "Macro Playback 🎯",
                    Content = string.format("วาง %s (Unit #%d) เรียบร้อยที่ (%.1f, %.1f)", unitName, twIdx, step.X, step.Z),
                    Duration = 2,
                    Icon = "circle-check"
                })
                return true
            end
        end
        return false

    elseif step.Action == "Upgrade" then
        local targetTower = playbackTowers[twIdx]
        if not (targetTower and targetTower.Parent) then
            targetTower = findPlacedTowerNear(stepPos, 4.5, step.Unit)
            if targetTower then playbackTowers[twIdx] = targetTower end
        end

        if not targetTower then
            targetTower = findPlacedTowerNear(stepPos, 7.0)
            if targetTower then playbackTowers[twIdx] = targetTower end
        end

        if not targetTower then
            local towersFolder = workspace:FindFirstChild("Towers")
            if towersFolder then
                local closestT, closestDist = nil, 999999
                for _, t in ipairs(towersFolder:GetChildren()) do
                    local owner = t:GetAttribute("Owner")
                    if not owner or owner == LocalPlayer.Name then
                        local tName = t:GetAttribute("Name") or t.Name
                        if not step.Unit or tName == step.Unit then
                            local ok, p = pcall(function() return t:GetPivot().Position end)
                            if ok and p then
                                local dist = (Vector3.new(p.X, 0, p.Z) - Vector3.new(stepPos.X, 0, stepPos.Z)).Magnitude
                                if dist < closestDist then
                                    closestDist = dist
                                    closestT = t
                                end
                            end
                        end
                    end
                end
                if closestT and closestDist < 12.0 then
                    targetTower = closestT
                    playbackTowers[twIdx] = targetTower
                end
            end
        end

        if not targetTower then
            return false
        end

        local currentTier = targetTower:GetAttribute("Tier") or 0
        local targetTier = step.TargetTier or (currentTier + 1)
        if currentTier >= targetTier then
            return true
        end

        local cost = (step.Cost and step.Cost > 0) and step.Cost or getUpgradeCost(step.Unit or targetTower.Name, targetTier)
        if not waitSufficientMoney(cost) then return false end

        -- Position close to tower
        pcall(function()
            if RootPart then
                local hrp = targetTower:FindFirstChild("HumanoidRootPart")
                if hrp then
                    RootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2.5, 2))
                end
            end
        end)
        task.wait(0.1)

        local attempts = 0
        local maxAttempts = 6
        while macroPlaybackEnabled and scriptRunning and attempts < maxAttempts do
            attempts = attempts + 1

            publishRemote("HandleTower", {
                Action = "Upgrade",
                Id = targetTower.Name
            })

            pcall(function()
                local Towers_Client = require(ReplicatedStorage.Master.Modules.Towers_Client)
                if Towers_Client and Towers_Client.Upgrade then
                    Towers_Client:Upgrade(targetTower)
                end
            end)

            task.wait(0.6)

            local newTier = targetTower:GetAttribute("Tier") or 0
            if newTier >= targetTier then
                WindUI:Notify({
                    Title = "Macro Playback ⚡",
                    Content = string.format("อัปเกรด %s (Unit #%d) สำเร็จ (Tier %d)", step.Unit or targetTower.Name, twIdx, newTier),
                    Duration = 2,
                    Icon = "wand"
                })
                return true
            end
        end
        return false

    elseif step.Action == "Sell" then
        local targetTower = playbackTowers[twIdx] or findPlacedTowerNear(stepPos, 4.5, step.Unit)
        if targetTower and targetTower.Parent then
            publishRemote("HandleTower", {
                Action = "Sell",
                Id = targetTower.Name,
                Name = targetTower:GetAttribute("Name") or targetTower.Name
            })
            pcall(function()
                local Towers_Client = require(ReplicatedStorage.Master.Modules.Towers_Client)
                if Towers_Client and Towers_Client.Sell then
                    Towers_Client:Sell(targetTower)
                end
            end)
            playbackTowers[twIdx] = nil
            task.wait(0.4)
        end
        return true
    end

    return true
end

-- Background loop for Macro Playback (Deterministic with Safe Retry and Round Reset)
task.spawn(function()
    local isWaitingForNewRound = false
    local lastEndGameSent = 0
    local stepFailAttempts = 0
    local lastStepAttempted = 0

    while scriptRunning do
        task.wait(0.5)
        if macroPlaybackEnabled and #activeConfig.Steps > 0 then
            pcall(function()
                local gameFolder = workspace:FindFirstChild("Game")
                local inMatch = (game.PlaceId == 85423571424083)
                    or (gameFolder and gameFolder:FindFirstChild("Started") and gameFolder.Started.Value == true)

                local rr, hasEnded, isVictory = getMatchEndGui()

                -- 1. Check Match End state (RoundResult visible)
                if hasEnded then
                    isWaitingForNewRound = true
                    if macroLoopEnabled and (tick() - lastEndGameSent > 3) then
                        lastEndGameSent = tick()
                        triggerMatchEndAction(smartMatchEndAction or "Next")
                    end
                    if UI.macroStatusPara and UI.macroStatusPara.SetDesc then
                        UI.macroStatusPara:SetDesc(string.format(
                            "คอนฟิก: %s\nจำนวน: %d สเต็ป\nสถานะ: 🏁 จบรอบแล้ว! กำลังวนซ้ำรอบถัดไป...",
                            activeConfig.Name,
                            #activeConfig.Steps
                        ))
                    end
                    return
                end

                if inMatch then
                    local currentWave = gameFolder and gameFolder:FindFirstChild("CurrentWave") and gameFolder.CurrentWave.Value or 1
                    local totalDuration = gameFolder and gameFolder:FindFirstChild("TotalDuration") and gameFolder.TotalDuration.Value or 0
                    local towersFolder = workspace:FindFirstChild("Towers")
                    local towerCount = towersFolder and #towersFolder:GetChildren() or 0

                    -- 2. Detect New Round or Round Reset to repeat Macro from Step 1
                    local isNewRound = false
                    if isWaitingForNewRound and not hasEnded then
                        isNewRound = true
                    elseif (currentMacroStep > 0) and (currentWave <= 1) and (towerCount == 0 or totalDuration < 12) then
                        isNewRound = true
                    end

                    if isNewRound then
                        isWaitingForNewRound = false
                        currentMacroStep = 0
                        stepFailAttempts = 0
                        lastStepAttempted = 0
                        table.clear(playbackTowers)
                        updateMacroStatus()
                        WindUI:Notify({
                            Title = "TD Macro",
                            Content = "🔁 เริ่มรอบใหม่! รันสเต็ปคำสั่ง Macro ซ้ำตั้งแต่ต้นอัตโนมัติ",
                            Duration = 3,
                            Icon = "rotate-cw"
                        })
                        task.wait(2)
                        return
                    end

                    -- 3. Lock 2x Speed
                    if macroLockSpeed2x then
                        publishRemote("GameSpeed", {Speed = 2})
                        publishRemote("Settings", {Name = "Speed", Value = 2})
                    end

                    -- 4. Auto Skip Wave
                    if macroAutoSkipWave then
                        local hp = gameFolder and gameFolder:FindFirstChild("TowerHealth") and gameFolder.TowerHealth.Value or 500
                        if hp >= 350 then
                            publishRemote("SkipWave", true)
                            publishRemote("Settings", {Name = "Auto Skip Wave", Value = true})
                        end
                    end

                    -- 5. Execute Macro Steps Sequentially (Only advance when step SUCCEEDS)
                    local nextStepIdx = currentMacroStep + 1
                    if nextStepIdx <= #activeConfig.Steps then
                        local step = activeConfig.Steps[nextStepIdx]
                        if step then
                            if nextStepIdx ~= lastStepAttempted then
                                lastStepAttempted = nextStepIdx
                                stepFailAttempts = 0
                                local waitTime = math.clamp(step.Delay or 1.5, 0.4, 30)
                                task.wait(waitTime)
                            end

                            if macroPlaybackEnabled and not hasEnded then
                                local ok = executeMacroStep(step)
                                if ok then
                                    currentMacroStep = nextStepIdx
                                    stepFailAttempts = 0
                                    updateMacroStatus()
                                else
                                    stepFailAttempts = stepFailAttempts + 1
                                    if stepFailAttempts >= 15 then
                                        warn("[Macro Playback] Step #" .. tostring(step.Step or nextStepIdx) .. " timed out after 15 attempts. Advancing.")
                                        currentMacroStep = nextStepIdx
                                        stepFailAttempts = 0
                                    else
                                        task.wait(0.8)
                                    end
                                    updateMacroStatus()
                                end
                            end
                        end
                    else
                        -- Finished all recorded steps: continuous auto-upgrade if enabled
                        if macroAutoUpgrade then
                            if towersFolder then
                                for _, tower in ipairs(towersFolder:GetChildren()) do
                                    if tower:GetAttribute("Owner") == LocalPlayer.Name or not tower:GetAttribute("Owner") then
                                        publishRemote("HandleTower", {Action = "Upgrade", Id = tower.Name})
                                        pcall(function()
                                            local Towers_Client = require(ReplicatedStorage.Master.Modules.Towers_Client)
                                            if Towers_Client and Towers_Client.Upgrade then
                                                Towers_Client:Upgrade(tower)
                                            end
                                        end)
                                    end
                                end
                            end
                        end
                    end
                else
                    -- Outside Match (Lobby or waiting in room)
                    if macroAutoStart then
                        publishRemote("Room", {Action = "Start"})
                        publishRemote("Controls", {Action = "VoteStart"})
                    end
                end
            end)
        end
    end
end)

-- ==============================================================================
-- TAB 4: AUTO REWARDS & CODES
-- ==============================================================================
Tabs.Rewards:Section({ Title = "Automatic Reward Claims" })

Tabs.Rewards:Toggle({
    Title = "Auto Claim Daily Rewards",
    Desc = "รับของขวัญประจำวันอัตโนมัติเมื่อครบเวลา",
    Value = autoDaily,
-- Icon = "calendar-check",
    Callback = function(state)
        autoDaily = state
        triggerAutoSave()
    end
})

Tabs.Rewards:Toggle({
    Title = "Auto Claim Season Pass",
    Desc = "รับรางวัลเลเวล Battle Pass / Season Pass อัตโนมัติ",
    Value = autoSeasonPass,
-- Icon = "award",
    Callback = function(state)
        autoSeasonPass = state
        triggerAutoSave()
    end
})

Tabs.Rewards:Toggle({
    Title = "Auto Claim Index Unit Rewards",
    Desc = "รับของรางวัลจากการสะสมตัวละครในสมุด Index อัตโนมัติ",
    Value = autoIndex,
-- Icon = "book-open",
    Callback = function(state)
        autoIndex = state
        triggerAutoSave()
    end
})

Tabs.Rewards:Toggle({
    Title = "Auto Claim All Quests",
    Desc = "รับรางวัลเควสที่ทำสำเร็จทั้งหมด (Daily, Weekly, Infinite, Event)",
    Value = autoQuests,
-- Icon = "check",
    Callback = function(state)
        autoQuests = state
        triggerAutoSave()
    end
})

Tabs.Rewards:Toggle({
    Title = "Auto Claim Level Milestones",
    Desc = "รับรางวัลทุกครั้งที่เลเวลอัปตาม Milestones (Gems, Stat Tokens, Trait Crystals)",
    Value = autoLevelMilestones,
-- Icon = "badge-check",
    Callback = function(state)
        autoLevelMilestones = state
        triggerAutoSave()
    end
})

Tabs.Rewards:Section({ Title = "One-Click Quick Claims & Codes" })

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

Tabs.Rewards:Button({
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
        if GameInfo.LevelRewards and LocalPlayer:FindFirstChild("Data") then
            local claimable = GameInfo.LevelRewards.claimable(LocalPlayer.Data)
            for _, lvl in ipairs(claimable) do
                publishRemote("LevelRewards", {Level = lvl})
            end
        end
        WindUI:Notify({ Title = "Rewards", Content = "Triggered claim for all rewards!", Duration = 3, Icon = "sparkles" })
    end
})

Tabs.Rewards:Button({
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
        if game.PlaceId == 83869074416117 then
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
        if autoLevelMilestones and GameInfo.LevelRewards and LocalPlayer:FindFirstChild("Data") then
            pcall(function()
                local claimable = GameInfo.LevelRewards.claimable(LocalPlayer.Data)
                for _, lvl in ipairs(claimable) do
                    publishRemote("LevelRewards", {Level = lvl})
                end
            end)
        end
        end
    end
end)

-- ==============================================================================
-- TAB 5: AUTO SUMMON & GACHA
-- ==============================================================================
Tabs.Summon:Section({ Title = "Auto Summon Controls" })

Tabs.Summon:Dropdown({
    Title = "Select Banner",
    Desc = "เลือกตู้ตัวละครที่ต้องการสุ่ม",
    Values = { "Standard", "Special" },
    Value = summonBanner,
    Callback = function(val)
        summonBanner = val
        triggerAutoSave()
    end
})

Tabs.Summon:Dropdown({
    Title = "Pull Amount",
    Desc = "เลือกจำนวนครั้งต่อการสุ่ม",
    Values = { "1", "10" },
    Value = tostring(summonCount),
    Callback = function(val)
        summonCount = tonumber(val) or 10
        triggerAutoSave()
    end
})

Tabs.Summon:Toggle({
    Title = "Auto Summon (Spam Pull)",
    Desc = "สุ่มตัวละครต่อเนื่องอัตโนมัติเมื่อเพชรพอ",
    Value = autoSummon,
-- Icon = "repeat",
    Callback = function(state)
        autoSummon = state
        triggerAutoSave()
    end
})

Tabs.Summon:Toggle({
    Title = "Auto Open Event Capsules",
    Desc = "เปิดแคปซูลอีเวนต์อัตโนมัติเมื่อได้รับในกระเป๋า",
    Value = autoCapsules,
-- Icon = "package",
    Callback = function(state)
        autoCapsules = state
        triggerAutoSave()
    end
})

Tabs.Summon:Button({
    Title = "Summon Once (ทันที)",
    Desc = "กดสุ่มตามตู้และจำนวนที่เลือก 1 ครั้ง",
    Icon = "sparkles",
    Callback = function()
        publishRemote("Summon", {Amount = summonCount, Type = summonBanner})
        WindUI:Notify({ Title = "Summon", Content = "Summoned " .. tostring(summonCount) .. "x on " .. summonBanner, Duration = 3, Icon = "gift" })
    end
})

Tabs.Summon:Section({ Title = "Built-in Autosell Settings" })

Tabs.Summon:Toggle({
    Title = "Autosell: Rare Units",
    Desc = "เปิดระบบขายตัวละครระดับ Rare อัตโนมัติเวลาสุ่มได้",
    Value = false,
-- Icon = "trash-2",
    Callback = function(state)
        publishRemote("Settings", {Name = "Rare", Value = state})
    end
})

Tabs.Summon:Toggle({
    Title = "Autosell: Epic Units",
    Desc = "เปิดระบบขายตัวละครระดับ Epic อัตโนมัติเวลาสุ่มได้",
    Value = false,
-- Icon = "trash-2",
    Callback = function(state)
        publishRemote("Settings", {Name = "Epic", Value = state})
    end
})

Tabs.Summon:Toggle({
    Title = "Autosell: Legendary Units",
    Desc = "เปิดระบบขายตัวละครระดับ Legendary อัตโนมัติเวลาสุ่มได้",
    Value = false,
-- Icon = "trash-2",
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
Tabs.Units:Section({ Title = "Unit Protection & Cleanup" })

Tabs.Units:Toggle({
    Title = "Auto Lock Mythic & Secret",
    Desc = "ตรวจจับและล็อคตัวละครระดับ Mythic และ Secret ทุกตัวอัตโนมัติ เพื่อป้องกันการเผลอขาย",
    Value = autoLockHighRarity,
-- Icon = "lock",
    Callback = function(state)
        autoLockHighRarity = state
        triggerAutoSave()
    end
})

Tabs.Units:Button({
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

Tabs.Units:Section({ Title = "Auto Feeding (Level Up)" })

Tabs.Units:Button({
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

Tabs.Units:Section({ Title = "Auto Trait & Stat Reroll" })

UI.ownedDropdown = Tabs.Units:Dropdown({
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

Tabs.Units:Button({
    Title = "Refresh Owned Units Dropdown",
    Desc = "อัปเดตรายชื่อตัวละครในเมนูเลือกตัว",
    Icon = "refresh-cw",
    Callback = function()
        if UI.ownedDropdown then
            local updatedUnits = getOwnedUnitsList()
            updateDropdown(UI.ownedDropdown, updatedUnits, updatedUnits[1])
            WindUI:Notify({ Title = "Units", Content = "Refreshed units list!", Duration = 2, Icon = "check" })
        end
    end
})

Tabs.Units:Toggle({
    Title = "Auto Trait Roll Loop",
    Desc = "สุ่ม Trait ให้ตัวละครที่เลือกอย่างต่อเนื่อง (ใช้ Trait Crystals)",
    Value = autoTraitRoll,
-- Icon = "dices",
    Callback = function(state)
        autoTraitRoll = state
        triggerAutoSave()
    end
})

Tabs.Units:Toggle({
    Title = "Auto Stat Roll Loop",
    Desc = "สุ่ม Stats (Damage, Cooldown, Range) ให้ตัวละครที่เลือกต่อเนื่อง (ใช้ Stat Tokens)",
    Value = autoStatRoll,
-- Icon = "wand",
    Callback = function(state)
        autoStatRoll = state
        triggerAutoSave()
    end
})

-- Background loop for Unit Management, Lock, and Rolls
task.spawn(function()
    while scriptRunning do
        task.wait(2)
        if autoLockHighRarity and GameInfo.Champions and LocalPlayer:FindFirstChild("Data") then
            pcall(function()
                local units = LocalPlayer.Data.Units
                for _, u in ipairs(units:GetChildren()) do
                    local champ = GameInfo.Champions(u.Name)
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
Tabs.Teleports:Section({ Title = "Lobby Teleports" })

local function safeTeleport(targetPos)
    if RootPart then
        RootPart.CFrame = CFrame.new(targetPos) + Vector3.new(0, 3, 0)
    end
end

Tabs.Teleports:Button({
    Title = "Teleport: Codes Area (บ่อน้ำโค้ด)",
    Desc = "วาปไปยังจุดเติมโค้ดรับรางวัล",
    Icon = "key",
    Callback = function()
        safeTeleport(Vector3.new(-264.10, 624.5, 257.07))
        WindUI:Notify({ Title = "Teleport", Content = "Teleported to Codes Area", Duration = 3, Icon = "map-pin" })
    end
})

Tabs.Teleports:Button({
    Title = "Teleport: Summon Area (แท่นสุ่ม)",
    Desc = "วาปไปยังแท่นสุ่มตัวละคร Gacha",
    Icon = "sparkles",
    Callback = function()
        safeTeleport(Vector3.new(-17.55, 630.0, 332.52))
        WindUI:Notify({ Title = "Teleport", Content = "Teleported to Summon Area", Duration = 3, Icon = "map-pin" })
    end
})

Tabs.Teleports:Button({
    Title = "Teleport: Evolve Area (จุดวิวัฒนาการ)",
    Desc = "วาปไปยังจุดอัปเกรด/วิวัฒนาการตัวละคร",
    Icon = "zap",
    Callback = function()
        safeTeleport(Vector3.new(-344.60, 629.0, 698.09))
        WindUI:Notify({ Title = "Teleport", Content = "Teleported to Evolve Area", Duration = 3, Icon = "map-pin" })
    end
})

Tabs.Teleports:Button({
    Title = "Teleport: Battle / Play Area (ลงแมพ)",
    Desc = "วาปไปยังจุดเลือกด่านและลงต่อสู้",
    Icon = "swords",
    Callback = function()
        safeTeleport(Vector3.new(-343.32, 628.5, 96.54))
        WindUI:Notify({ Title = "Teleport", Content = "Teleported to Battle Area", Duration = 3, Icon = "map-pin" })
    end
})

Tabs.Teleports:Button({
    Title = "Teleport to AFK Chamber",
    Desc = "วาปเข้าห้อง AFK เพื่อรับเพชรและของรางวัลตลอดเวลา",
    Icon = "coffee",
    Callback = function()
        armTeleportQueue()
        publishRemote("Teleport", {Area = "AFK"})
        WindUI:Notify({ Title = "Teleport", Content = "Teleporting to AFK Chamber...", Duration = 3, Icon = "coffee" })
    end
})

-- ==============================================================================
-- TAB 8: PLAYER & MISC
-- ==============================================================================
Tabs.Player:Section({ Title = "Character & Movement" })

Tabs.Player:Slider({
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

Tabs.Player:Toggle({
    Title = "Enable WalkSpeed",
    Desc = "เปิด/ปิด การใช้งานความเร็วที่กำหนด",
    Value = speedEnabled,
-- Icon = "zap",
    Callback = function(state)
        speedEnabled = state
        if Humanoid then
            Humanoid.WalkSpeed = state and customSpeed or 16
        end
        triggerAutoSave()
    end
})

Tabs.Player:Slider({
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

Tabs.Player:Toggle({
    Title = "Enable JumpPower",
    Desc = "เปิด/ปิด การใช้งานแรงกระโดดที่กำหนด",
    Value = jumpEnabled,
-- Icon = "arrow-up",
    Callback = function(state)
        jumpEnabled = state
        if Humanoid then
            Humanoid.JumpPower = state and customJump or 50
        end
        triggerAutoSave()
    end
})

Tabs.Player:Toggle({
    Title = "Infinite Jump",
    Desc = "กระโดดกลางอากาศได้ต่อเนื่องไม่จำกัด",
    Value = infJump,
-- Icon = "feather",
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

Tabs.Player:Toggle({
    Title = "Noclip",
    Desc = "เดินทะลุกำแพงและสิ่งกีดขวางทุกชนิด",
    Value = noclip,
-- Icon = "ghost",
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

Tabs.Player:Section({ Title = "Utility & Protection" })

Tabs.Player:Toggle({
    Title = "Anti-AFK (กันหลุด 20 นาที)",
    Desc = "ป้องกัน Roblox เตะออกจากเกมเวลาเปิดฟาร์มทิ้งไว้",
    Value = antiAfkEnabled,
-- Icon = "shield-check",
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

Tabs.Player:Button({
    Title = "Rejoin Server",
    Desc = "เชื่อมต่อกลับเข้าเซิร์ฟเวอร์เดิมใหม่อีกครั้ง",
    Icon = "refresh-cw",
    Callback = function()
        armTeleportQueue()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

-- ==============================================================================
-- TAB 9: DYNAMIC FX & UI CUSTOMIZATION
-- ==============================================================================
Tabs.FX:Section({ Title = "Live Animated Effects" })

Tabs.FX:Toggle({
    Title = "Rotating Chroma Glow Border",
    Desc = "ขอบแสงนีออนไล่เฉดสีหมุนวนรอบหน้าต่างอย่างต่อเนื่อง",
    Value = fxChromaEnabled,
-- Icon = "sparkles",
    Callback = function(state)
        fxChromaEnabled = state
        if FXHandles.Stroke and FXHandles.Stroke.Parent then
            FXHandles.Stroke.Enabled = state
        end
        triggerAutoSave()
    end
})

Tabs.FX:Toggle({
    Title = "Cosmic Floating Particles",
    Desc = "ละอองดาวคอสมิกลอยพริ้วไหวในพื้นหลังเมนู",
    Value = fxParticlesEnabled,
-- Icon = "sparkles",
    Callback = function(state)
        fxParticlesEnabled = state
        if FXHandles.ParticleCanvas and FXHandles.ParticleCanvas.Parent then
            FXHandles.ParticleCanvas.Visible = state
        end
        triggerAutoSave()
    end
})

Tabs.FX:Toggle({
    Title = "Laser Pulse Underline",
    Desc = "เส้นแสงเลเซอร์ใต้ Title Bar ส่องสว่างแบบไดนามิก",
    Value = fxLaserBarEnabled,
-- Icon = "zap",
    Callback = function(state)
        fxLaserBarEnabled = state
        if FXHandles.NeonBar and FXHandles.NeonBar.Parent then
            FXHandles.NeonBar.Visible = state
        end
        triggerAutoSave()
    end
})

Tabs.FX:Slider({
    Title = "FX Animation Speed",
    Desc = "ปรับความเร็วของการหมุนและการเคลื่อนไหวของแอนิเมชัน",
    Value = { Min = 0.5, Max = 3, Default = fxSpeed },
    Step = 0.1,
    Callback = function(val)
        fxSpeed = val
        triggerAutoSave()
    end
})

Tabs.FX:Section({ Title = "Themes & Transparency" })

Tabs.FX:Dropdown({
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

Tabs.FX:Slider({
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

UI.configStatusPara = Tabs.Config:Paragraph({
    Title = "Configuration & Persistence Status",
    Desc = getStatusText(),
    Image = "settings"
})

local function updateConfigStatusText()
    if UI.configStatusPara and UI.configStatusPara.SetDesc then
        UI.configStatusPara:SetDesc(getStatusText())
    end
end

Tabs.Config:Section({ Title = "Profile Management (Save / Load)" })

Tabs.Config:Input({
    Title = "Config Profile Name",
    Desc = "พิมพ์ชื่อโปรไฟล์การตั้งค่าที่ต้องการเซฟ",
    Value = currentConfigName,
    Placeholder = "Default_Config",
    Callback = function(text)
        if text and #text > 0 then
            currentConfigName = text:gsub("[%\\/%:%*%?%\"%<%>%|]", "_")
        end
    end
})

UI.savedConfigsDrop = nil
UI.savedConfigsDrop = Tabs.Config:Dropdown({
    Title = "Select Saved Profile",
    Desc = "เลือกไฟล์คอนฟิก (โหลดอัตโนมัติทันทีที่เลือก)",
    Values = getSavedConfigsList(),
    Value = currentConfigName,
    Callback = function(val)
        if val and #val > 0 then
            currentConfigName = val
            local ok = loadConfigFromFile(val)
            if ok then
                updateConfigStatusText()
                WindUI:Notify({ Title = "Config Auto-Loaded 📂", Content = "โหลดโปรไฟล์ " .. val .. " อัตโนมัติเรียบร้อย!", Duration = 3, Icon = "folder-check" })
            end
        end
    end
})

Tabs.Config:Button({
    Title = "💾 Save Current Configuration",
    Desc = "บันทึกการตั้งค่าทั้งหมด (ทุกแท็บ ทุกสวิตช์) ลงไฟล์ทันที",
    Icon = "save",
    Callback = function()
        local saveName = (currentConfigName and #currentConfigName > 0) and currentConfigName or "Default_Config"
        saveName = saveName:gsub("[%\\/%:%*%?%\"%<%>%|]", "_")
        currentConfigName = saveName
        saveConfigToFile(saveName)
        if UI.savedConfigsDrop then
            local updatedList = getSavedConfigsList(saveName)
            updateDropdown(UI.savedConfigsDrop, updatedList, saveName)
        end
        updateConfigStatusText()
        WindUI:Notify({ Title = "Config Saved", Content = "Saved settings to: " .. saveName .. ".json", Duration = 3.5, Icon = "save" })
    end
})

Tabs.Config:Button({
    Title = "📂 Load Selected Configuration",
    Desc = "โหลดการตั้งค่าจากไฟล์ที่เลือกมาใช้งานทันที",
    Icon = "folder-open",
    Callback = function()
        local ok = loadConfigFromFile(currentConfigName)
        if ok then
            if UI.savedConfigsDrop then
                updateDropdown(UI.savedConfigsDrop, getSavedConfigsList(currentConfigName), currentConfigName)
            end
            updateConfigStatusText()
            WindUI:Notify({ Title = "Config Loaded", Content = "Successfully loaded " .. currentConfigName .. "!", Duration = 3.5, Icon = "folder-check" })
        else
            WindUI:Notify({ Title = "Config Error", Content = "Could not find file: " .. currentConfigName, Duration = 3, Icon = "circle-x" })
        end
    end
})

Tabs.Config:Button({
    Title = "🗑️ Delete Selected Profile",
    Desc = "ลบไฟล์คอนฟิกที่เลือกออกจากเครื่อง",
    Icon = "trash-2",
    Callback = function()
        pcall(function()
            if currentConfigName == "Default_Config" then
                WindUI:Notify({ Title = "Notice", Content = "Cannot delete Default_Config!", Duration = 3, Icon = "alert-circle" })
                return
            end
            local path = CONFIG_FOLDER .. "/" .. currentConfigName .. ".json"
            if isfile(path) then
                delfile(path)
                currentConfigName = "Default_Config"
                if UI.savedConfigsDrop then
                    local updatedList = getSavedConfigsList("Default_Config")
                    updateDropdown(UI.savedConfigsDrop, updatedList, "Default_Config")
                end
                updateConfigStatusText()
                WindUI:Notify({ Title = "Config Deleted", Content = "Deleted profile!", Duration = 3, Icon = "trash-2" })
            end
        end)
    end
})

Tabs.Config:Button({
    Title = "🔄 Refresh Profiles List",
    Desc = "รีเฟรชรายชื่อโปรไฟล์ในเครื่อง",
    Icon = "refresh-cw",
    Callback = function()
        if UI.savedConfigsDrop then
            local updatedList = getSavedConfigsList(currentConfigName)
            updateDropdown(UI.savedConfigsDrop, updatedList, currentConfigName)
            WindUI:Notify({ Title = "Config", Content = "Refreshed profiles list!", Duration = 2, Icon = "circle-check" })
        end
    end
})

Tabs.Config:Button({
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

        currentConfigName = "Default_Config"
        saveConfigToFile("Default_Config")
        if UI.savedConfigsDrop then
            local updatedList = getSavedConfigsList("Default_Config")
            updateDropdown(UI.savedConfigsDrop, updatedList, "Default_Config")
        end
        updateConfigStatusText()
        WindUI:Notify({ Title = "Config", Content = "Reset all settings to default!", Duration = 3, Icon = "refresh-cw" })
    end
})

Tabs.Config:Toggle({
    Title = "Auto-Save Settings On Change",
    Desc = "เมื่อเปิดใช้งาน ทุกครั้งที่มีการเปิด/ปิดสวิตช์ ปรับสไลเดอร์ หรือเลือกเมนู จะเซฟลงไฟล์ทันทีอัตโนมัติ",
    Value = autoSaveConfig,
-- Icon = "shield-check",
    Callback = function(state)
        autoSaveConfig = state
        triggerAutoSave()
        updateConfigStatusText()
    end
})

Tabs.Config:Section({ Title = "Universal Auto-Execute Engine (Cross-Executor)" })

Tabs.Config:Paragraph({
    Title = "About Universal Auto-Execute",
    Desc = "⚡ ระบบ Auto-Execute สากล (เหมือน Hub ชั้นนำทั่วไป):\n• สามารถ เปิด/ปิด ได้ตลอดเวลาผ่านสวิตช์ด้านล่าง\n• ไม่ผูกติดกับ Real อย่างเดียว: ใช้งานได้กับทุกโปรแกรม (Wave, Solara, Delta, Codex, Arceus X, Fluxus ฯลฯ)\n• เมื่อวาปข้ามแมพ/ลงด่าน: ใช้ระบบ queue_on_teleport รันสคริปต์ต่อเนื่องอัตโนมัติในทุกโปรแกรม\n• เมื่อเข้าเกมใหม่: มีระบบ AutoExec File และโค้ดคัดลอกสำหรับใส่โฟลเดอร์ autoexec ของทุกค่าย",
    Image = "sparkles"
})

UI.universalAutoExecToggle = nil
UI.universalAutoExecToggle = Tabs.Config:Toggle({
    Title = "⚡ เปิดใช้งาน Universal Auto-Execute (One-Click Auto-Run)",
    Desc = "เปิดปุ๊บระบบจะติดตั้ง AutoExec และ Teleport Queue ให้อัตโนมัติทุก Executor ทันที 1 คลิก",
    Value = autoExecuteMaster and autoExecFile and autoTeleportQueue,
    Callback = function(state)
        autoExecuteMaster = state
        autoTeleportQueue = state
        autoExecFile = state
        local changed = updateAutoExecFileState(state)
        updateTeleportQueueState(state)
        triggerAutoSave()
        updateConfigStatusText()
        WindUI:Notify({
            Title = "Universal Auto-Execute",
            Content = state and "Universal Auto-Execute Enabled 🟢 (AutoExec & Queue Active)" or "Universal Auto-Execute Disabled 🔴",
            Duration = 3.5,
        })
    end
})

UI.universalLoaderSnippet = [=[-- Anime Galaxies Hub Universal AutoExec Loader
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
            "AnimeGalaxies_Hub.luau",
            "AnimeGalaxies_Hub.lua",
            "AnimeGalaxiesHub/AnimeGalaxies_Hub.luau",
            "AnimeGalaxiesHub/AnimeGalaxies_Hub.lua"
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

Tabs.Config:Button({
    Title = "📋 Copy Universal AutoExec Loader",
    Desc = "คัดลอกโค้ด Loader สากลสำหรับนำไปใส่ในโฟลเดอร์ autoexec ของโปรแกรมรันสคริปต์ทุกตัว",
    Icon = "clipboard",
    Callback = function()
        local ok = false
        if copyToClipboard then
            local pcallOk = pcall(copyToClipboard, UI.universalLoaderSnippet)
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

Tabs.Config:Button({
    Title = "⚡ Force Clean Old Ghost UIs (ล้าง UI ค้าง)",
    Desc = "กดเพื่อบังคับล้าง UI ที่ค้างอยู่ในหน่วยความจำทันที 1 ครั้ง",
    Icon = "trash-2",
    Callback = function()
        destroyOldUIs()
        WindUI:Notify({ Title = "UI Clean", Content = "Cleaned ghost UIs from memory!", Duration = 2.5, Icon = "check" })
    end
})

Tabs.Config:Section({ Title = "🌐 Song Hub Community & Support" })

Tabs.Config:Button({
    Title = "💬 Join Discord Community",
    Desc = "Copy Discord invite link to your clipboard (https://discord.gg/cecytf4MHE)",
    Icon = "message-circle",
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
    FXHandles.Stroke = stroke

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
        FXHandles.NeonBar = neonBar

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
    FXHandles.ParticleCanvas = particleCanvas

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
    Tabs.Main:Select()
end)

-- Auto-load active macro config on boot
pcall(function()
    loadMacroConfig(selectedFileToLoad)
end)

getgenv()._AG_STARTING = nil

-- Initial notification
WindUI:Notify({
    Title = "Anime Galaxies Hub ✨ [v1.5]",
    Content = "All Modes Auto Farm & Room Creator Loaded! Welcome, " .. tostring(LocalPlayer.Name) .. "!",
    Duration = 5,
    Icon = "sparkles",
})


