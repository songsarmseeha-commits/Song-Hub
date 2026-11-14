-- ==============================================================================
-- 🚀 SONG HUB [v1.0] - [🎲] JUMP FOR CASES! 🦘
-- Game: [🎲] Jump for Cases
-- PlaceId: 93545804988403 | UniverseId: 10767621216
-- Features:
--     - 🦘 Smart Auto Farm (Automated KickZone Warp, Power Lock, Case Collect & Return)
--     - ⚡ Native AutoKick + Sprint Booster (Assists Built-in AutoKick with 48 WS)
--     - 🎲 Fast Case Opener (Instant Cutscene Skip via _ShowCasesOpening)
--     - 📦 Auto Open All Cases (Multi-Open 3x/2x/1x for all owned cases)
--     - 🎯 Auto Open Selected Case (Configurable case target)
--     - ⚡ Auto Speed Upgrades (Auto buy speed tiers with Cash attribute)
--     - 🏋️ Auto Buy & Equip Best Weight (Barbell progression from WeightsConfig)
--     - 🔁 Auto Rebirth (Automatic prestige multiplier upgrade)
--     - 💎 Auto Claim Index Gems (RequestClaimAllIndexGems)
--     - 🎁 Auto Daily & Free Rewards (Daily claim, Free Wheel spin, Offline cash, Forever reward)
--     - 📍 Teleports (Runway, Collect Zone, Base, Sell Shop, Main Shop, Speed Shop, Cave, Tunnel)
--     - 🏃 Player Physics (WalkSpeed, JumpPower, InfJump, NoClip, Fly)
--     - 🛡️ 24/7 Anti-AFK
-- ==============================================================================

-- Strict Game Validation
local isJumpForCases = (game.PlaceId == 93545804988403 or game.GameId == 10767621216
    or (game:GetService("ReplicatedStorage"):FindFirstChild("CasesConfig") and game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("RequestKick")))

if not isJumpForCases then
    warn("[Song Hub] ❌ This script is exclusively for Jump for Cases🎲 (PlaceId: 93545804988403)! Exiting.")
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
local Workspace = game:GetService("Workspace")
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
local EXEC_ID = tick()
if getgenv then
    if getgenv()._JumpForCasesRunning and getgenv()._JFC_Window then
        pcall(function()
            getgenv()._JFC_Window:Destroy()
        end)
    end
    getgenv()._JumpForCasesRunning = EXEC_ID
    getgenv()._JFC_BlockWaveHit = false
    getgenv()._JFC_ForcePerfectKick = false
end

local function isScriptAlive()
    if getgenv and (getgenv()._SongHubSessionExpired == true or (type(getgenv()._SongHubAuth) == "table" and getgenv()._SongHubAuth.revoked == true)) then
        return false
    end
    return (not getgenv) or (getgenv()._JumpForCasesRunning == EXEC_ID)
end

-- ==============================================================================
-- 🛡️ 24/7 ANTI-AFK SYSTEM
-- ==============================================================================
task.spawn(function()
    if getgenv and getgenv()._JFCAntiAfkActive then return end
    if getgenv then getgenv()._JFCAntiAfkActive = true end

    LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end)
end)

-- Auto Dismiss Respawn / Lost Popups
task.spawn(function()
    while true do
        task.wait(0.8)
        pcall(function()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local gameGui = pg and pg:FindFirstChild("Game")
            local frames = gameGui and gameGui:FindFirstChild("Frames")
            if frames then
                local rf = frames:FindFirstChild("RespawnFrame")
                if rf and rf.Visible then
                    local eb = rf:FindFirstChild("ExitButton", true)
                    if eb and typeof(firesignal) == "function" then
                        firesignal(eb.Activated)
                    else
                        rf.Visible = false
                    end
                end
            end
        end)
    end
end)

-- ==============================================================================
-- 📦 REMOTES & GAME CONFIGS
-- ==============================================================================
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 20)

local RequestKick = Remotes and Remotes:FindFirstChild("RequestKick")
local RequestAutoKick = Remotes and Remotes:FindFirstChild("RequestAutoKick")
local RequestAutoReturn = Remotes and Remotes:FindFirstChild("RequestAutoReturn")
local RequestFreeTpHome = Remotes and Remotes:FindFirstChild("RequestFreeTpHome")
local RequestOpenCase = Remotes and Remotes:FindFirstChild("RequestOpenCase")
local RequestOpenCaseMulti = Remotes and Remotes:FindFirstChild("RequestOpenCaseMulti")
local RequestEquipBrainrot = Remotes and Remotes:FindFirstChild("RequestEquipBrainrot")
local RequestSpeedUpgrade = Remotes and Remotes:FindFirstChild("RequestSpeedUpgrade")
local RequestBuyWeight = Remotes and Remotes:FindFirstChild("RequestBuyWeight")
local RequestEquipWeight = Remotes and Remotes:FindFirstChild("RequestEquipWeight")
local WeightShopStateSync = Remotes and Remotes:FindFirstChild("WeightShopStateSync")
local RequestRebirth = Remotes and Remotes:FindFirstChild("RequestRebirth")
local RequestClaimAllIndexGems = Remotes and Remotes:FindFirstChild("RequestClaimAllIndexGems")
local RequestDailyClaim = Remotes and Remotes:FindFirstChild("RequestDailyClaim")
local RequestSpinWheel = Remotes and Remotes:FindFirstChild("RequestSpinWheel")
local RequestClaimOffline = Remotes and Remotes:FindFirstChild("RequestClaimOffline")
local RequestCollectForeverReward = Remotes and Remotes:FindFirstChild("RequestCollectForeverReward")
local FallRewardEvent = Remotes and Remotes:FindFirstChild("FallRewardEvent")
local BoostKick = Remotes and Remotes:FindFirstChild("BoostKick")
local RespawnPrompt = Remotes and Remotes:FindFirstChild("RespawnPrompt")
local RedeemCode = Remotes and Remotes:FindFirstChild("RedeemCode")
local SellShopRequest = Remotes and Remotes:FindFirstChild("SellShopRequest")
local RequestSetSetting = Remotes and Remotes:FindFirstChild("RequestSetSetting")
local RequestSelectHotbar = Remotes and Remotes:FindFirstChild("RequestSelectHotbar")
local StrengthBonus = Remotes and Remotes:FindFirstChild("StrengthBonus")
local OsuTrain = Remotes and Remotes:FindFirstChild("OsuTrain")
local BasePetsRequest = Remotes and Remotes:FindFirstChild("BasePetsRequest")
local RequestBasePad = Remotes and Remotes:FindFirstChild("RequestBasePad")
local BasePadInfo = Remotes and Remotes:FindFirstChild("BasePadInfo")
local RequestCollect = Remotes and Remotes:FindFirstChild("RequestCollect")
local RequestSlotLevel = Remotes and Remotes:FindFirstChild("RequestSlotLevel")
local RequestSlotSignSync = Remotes and Remotes:FindFirstChild("RequestSlotSignSync")
local SlotSignSync = Remotes and Remotes:FindFirstChild("SlotSignSync")
local BaseLevelResult = Remotes and Remotes:FindFirstChild("BaseLevelResult")
local CaseOpened = Remotes and Remotes:FindFirstChild("CaseOpened")
local ItemObtained = Remotes and Remotes:FindFirstChild("ItemObtained")

-- Load Game Configs safely
local BrainrotData = nil
pcall(function()
    BrainrotData = require(ReplicatedStorage:WaitForChild("BrainrotData", 10))
end)

local CasesConfig = nil
pcall(function()
    CasesConfig = require(ReplicatedStorage:WaitForChild("CasesConfig", 10))
end)

local WeightsConfig = nil
pcall(function()
    WeightsConfig = require(ReplicatedStorage:WaitForChild("WeightsConfig", 10))
end)

local SpeedUpgradesConfig = nil
pcall(function()
    SpeedUpgradesConfig = require(ReplicatedStorage:WaitForChild("SpeedUpgradesConfig", 10))
end)

-- Build case names list
local CaseNamesList = {}
if CasesConfig and type(CasesConfig.Order) == "table" then
    for i = #CasesConfig.Order, 1, -1 do
        table.insert(CaseNamesList, CasesConfig.Order[i])
    end
else
    CaseNamesList = {
        "Basic", "Common", "Sand", "Copper", "Haunted", "RoyalBlue", "RoyalRed",
        "Legendary", "Golden", "Mythic", "Lava", "Bubblegum", "Radioactive", "Galaxy",
        "ShopDiamond", "ShopIce", "Moonwake", "Godly", "Oceania", "Secret", "OG",
        "BlackDiamond", "Diamond", "Ice", "Void", "BlackHole", "Cyber", "ReactorCore"
    }
end

-- ==============================================================================
-- ⚙️ CONFIGURATION (ALL DEFAULTS STRICTLY FALSE)
-- ==============================================================================
local Config = {
    -- Auto Kick / Farm
    MasterAutoFarm = false,
    InstantPerfectKick = false,
    CutsceneBypass = false,
    SafeAntiWave = false,
    NativeAutoKickSync = false,
    ReturnSprintBoost = false,
    InstantWarpReturn = false,
    
    -- Auto Case Opening
    FastOpenSkip = false,
    InstantRevealBypass = false,
    AutoOpenMutatedCases = false,
    AutoOpenAll = false,
    AutoOpenSelected = false,
    SelectedCase = CaseNamesList[1] or "Basic",
    CaseOpenDelay = 0.35,

    -- VVIP Overdrive (Smart AI Expedition, Auto-Sell, Max Level & Gem Boosts)
    AutoSmartExpedition = false,
    ExpeditionStrategy = "Smart Best EV (Auto Win%)",
    ExpeditionDuration = "Fast (1-1.7h)",
    AutoSellJunkPets = false,
    AutoSellMaxRarity = "Up to Mythic",
    InstantMaxLevelUnits = false,
    AutoClaimEventPass = false,
    AutoBuyGemBoost = false,
    SelectedGemBoost = "2x Luck (150 Gems)",

    -- Auto Upgrades & Base
    AutoEquipBest = false,
    AutoCollectMoney = false,
    AutoUpgradeUnits = false,
    UnitUpgradePriority = "Best ROI ($/s per $)",
    AutoTrain = false,
    AutoTrainX2 = false,
    AutoSpeedUpgrade = false,
    SpeedUpgradeTier = 1,
    AutoBuyWeight = false,
    AutoEquipWeight = false,
    AutoRebirth = false,

    -- Auto Claims
    AutoClaimIndexGems = false,
    AutoClaimDaily = false,
    AutoSpinWheel = false,
    AutoClaimOffline = false,
    AutoForeverRewards = false,

    -- Player Mods
    WalkSpeedEnabled = false,
    WalkSpeedValue = 32,
    JumpPowerEnabled = false,
    JumpPowerValue = 75,
    InfiniteJump = false,
    NoClip = false,
    FlyEnabled = false,
    FlySpeed = 50,

    -- UI Visuals & Animation (Eye-Care Aurora Engine)
    UITheme = "🌌 Aurora Borealis (แสงเหนือออโรร่า)",
    UIAnimationStyle = "🌌 Aurora Flow (แสงเหนือไหลนุ่มๆ)",
    UIBackgroundAnimation = true,
    UIAnimationSpeed = 8,

    -- Hotkey & Config Persistence
    UIToggleKey = "RightControl",
    AutoSaveConfig = true,
    SpeedUpgradeTierLabel = "+1 Speed (Tier 1)",
}

-- Clone clean default config for Reset to Default
local DefaultConfig = {}
for k, v in pairs(Config) do
    DefaultConfig[k] = v
end

-- ==============================================================================
-- 💾 PERSISTENT CONFIG & AUTO-LOAD ENGINE (PRE-UI INITIALIZATION)
-- ==============================================================================
local CfgSys = {
    ROOT_FOLDER = "SongHub_JumpForCases",
    PROFILES_FOLDER = "SongHub_JumpForCases/configs",
    AUTOLOAD_PATH = "SongHub_JumpForCases/autoload.txt",
    loadedProfile = "default",
    selectedProfile = "default",
    inputProfile = "default",
    isBatchApplying = false,
    wasAutoLoaded = false,
    autoSavePending = false,
    RegisteredControls = {},
}

do
    local function ensureConfigFolders()
        if typeof(isfolder) == "function" and typeof(makefolder) == "function" then
            pcall(function()
                if not isfolder(CfgSys.ROOT_FOLDER) then
                    makefolder(CfgSys.ROOT_FOLDER)
                end
                if not isfolder(CfgSys.PROFILES_FOLDER) then
                    makefolder(CfgSys.PROFILES_FOLDER)
                end
            end)
        end
    end
    ensureConfigFolders()

    function CfgSys.sanitizeProfileName(raw)
        local s = tostring(raw or ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("[^%w_%-%s]", "")
        if s == "" or s:lower() == "none" then
            return "default"
        end
        return s
    end

    function CfgSys.getSavedProfilesList()
        ensureConfigFolders()
        local list = {}
        local seen = {}
        if typeof(listfiles) == "function" and typeof(isfolder) == "function" and isfolder(CfgSys.PROFILES_FOLDER) then
            local ok, files = pcall(function() return listfiles(CfgSys.PROFILES_FOLDER) end)
            if ok and type(files) == "table" then
                for _, filePath in ipairs(files) do
                    local name = string.match(filePath, "([^\\/]+)%.json$")
                    if name and name ~= "" and not seen[name] then
                        seen[name] = true
                        table.insert(list, name)
                    end
                end
            end
        end
        if not seen["default"] then
            table.insert(list, 1, "default")
        end
        table.sort(list, function(a, b)
            if a == "default" then return true end
            if b == "default" then return false end
            return a:lower() < b:lower()
        end)
        return list
    end

    function CfgSys.getAutoLoadProfile()
        if typeof(isfile) == "function" and typeof(readfile) == "function" then
            if isfile(CfgSys.AUTOLOAD_PATH) then
                local ok, txt = pcall(function() return readfile(CfgSys.AUTOLOAD_PATH) end)
                if ok and txt then
                    local trimmed = txt:gsub("^%s+", ""):gsub("%s+$", "")
                    if trimmed ~= "" then
                        return trimmed
                    end
                end
            else
                if typeof(writefile) == "function" then
                    pcall(function() writefile(CfgSys.AUTOLOAD_PATH, "default") end)
                end
                return "default"
            end
        end
        return "default"
    end

    function CfgSys.setAutoLoadProfile(profileName)
        ensureConfigFolders()
        if typeof(writefile) == "function" then
            local val = (profileName and profileName ~= "" and profileName ~= "none") and CfgSys.sanitizeProfileName(profileName) or "none"
            pcall(function() writefile(CfgSys.AUTOLOAD_PATH, val) end)
        end
    end

    function CfgSys.syncTierFromConfig()
        if Config.SpeedUpgradeTier == 2 then
            Config.SpeedUpgradeTierLabel = "+5 Speed (Tier 2)"
        elseif Config.SpeedUpgradeTier == 3 then
            Config.SpeedUpgradeTierLabel = "+12 Speed (Tier 3)"
        else
            Config.SpeedUpgradeTier = 1
            Config.SpeedUpgradeTierLabel = "+1 Speed (Tier 1)"
        end
    end

    function CfgSys.saveProfileToDisk(profileName)
        ensureConfigFolders()
        local cleanName = CfgSys.sanitizeProfileName(profileName or CfgSys.selectedProfile)
        CfgSys.syncTierFromConfig()
        local payload = {}
        for k, v in pairs(Config) do
            local t = type(v)
            if t == "boolean" or t == "number" or t == "string" then
                payload[k] = v
            end
        end
        local okEnc, jsonStr = pcall(function() return HttpService:JSONEncode(payload) end)
        if okEnc and jsonStr and typeof(writefile) == "function" then
            local filePath = CfgSys.PROFILES_FOLDER .. "/" .. cleanName .. ".json"
            local okWrite = pcall(function() writefile(filePath, jsonStr) end)
            if okWrite then
                CfgSys.loadedProfile = cleanName
                CfgSys.selectedProfile = cleanName
                return true, cleanName
            end
        end
        return false, cleanName
    end

    function CfgSys.loadProfileFromDisk(profileName)
        ensureConfigFolders()
        local cleanName = CfgSys.sanitizeProfileName(profileName)
        local filePath = CfgSys.PROFILES_FOLDER .. "/" .. cleanName .. ".json"
        if typeof(isfile) == "function" and isfile(filePath) and typeof(readfile) == "function" then
            local okRead, raw = pcall(function() return readfile(filePath) end)
            if okRead and raw and #raw > 2 then
                local okDec, data = pcall(function() return HttpService:JSONDecode(raw) end)
                if okDec and type(data) == "table" then
                    for k, v in pairs(data) do
                        if DefaultConfig[k] ~= nil and type(v) == type(DefaultConfig[k]) then
                            Config[k] = v
                        end
                    end
                    if Config.SpeedUpgradeTierLabel then
                        if tostring(Config.SpeedUpgradeTierLabel):find("+5") then
                            Config.SpeedUpgradeTier = 2
                        elseif tostring(Config.SpeedUpgradeTierLabel):find("+12") then
                            Config.SpeedUpgradeTier = 3
                        else
                            Config.SpeedUpgradeTier = 1
                        end
                    end
                    CfgSys.syncTierFromConfig()
                    CfgSys.loadedProfile = cleanName
                    CfgSys.selectedProfile = cleanName
                    CfgSys.inputProfile = cleanName
                    return true, data
                end
            end
        end
        return false, nil
    end

    function CfgSys.scheduleAutoSave()
        if CfgSys.isBatchApplying or not Config.AutoSaveConfig then return end
        if CfgSys.autoSavePending then return end
        CfgSys.autoSavePending = true
        task.delay(0.4, function()
            CfgSys.autoSavePending = false
            if isScriptAlive() and Config.AutoSaveConfig and not CfgSys.isBatchApplying then
                CfgSys.saveProfileToDisk(CfgSys.selectedProfile)
            end
        end)
    end

    function CfgSys.resolveKeyCode(keyNameOrItem)
        if typeof(keyNameOrItem) == "EnumItem" then
            return keyNameOrItem, keyNameOrItem.Name
        elseif type(keyNameOrItem) == "string" and keyNameOrItem ~= "" then
            local ok, kc = pcall(function() return Enum.KeyCode[keyNameOrItem] end)
            if ok and kc then
                return kc, keyNameOrItem
            end
        end
        return Enum.KeyCode.RightControl, "RightControl"
    end

    local startupAutoProfile = CfgSys.getAutoLoadProfile()
    if startupAutoProfile and startupAutoProfile ~= "none" then
        local okLoaded = CfgSys.loadProfileFromDisk(startupAutoProfile)
        if okLoaded then
            CfgSys.wasAutoLoaded = true
        else
            CfgSys.selectedProfile = CfgSys.sanitizeProfileName(startupAutoProfile)
            CfgSys.inputProfile = CfgSys.selectedProfile
        end
    end
end

-- Target Key Positions
local POS_KICK_ZONE = Vector3.new(207.25, 22.5, 104.95)
local POS_COLLECT_ZONE = Vector3.new(199.87, 24.0, 81.01)
local POS_BASE_SPAWN = Vector3.new(269.22, 34.22, -19.42)

-- Teleport Locations Map
local TeleportLocations = {
    ["🦘 Runway / Kick Zone"] = POS_KICK_ZONE,
    ["📦 Collect Zone"] = POS_COLLECT_ZONE,
    ["🏠 Base / Spawn"] = POS_BASE_SPAWN,
    ["💰 Sell Shop"] = Vector3.new(325.32, 23.85, 83.00),
    ["🛒 Main Shop"] = Vector3.new(300.04, 23.87, 82.64),
    ["⚡ Speed Shop"] = Vector3.new(276.13, 23.71, 81.73),
    ["🕳️ Secret Cave"] = Vector3.new(-15109.9, 57836.0, 109.1),
    ["🚇 Tunnel"] = Vector3.new(408.2, 12.0, -262.7),
}

-- ==============================================================================
-- 🛠️ UTILITY FUNCTIONS
-- ==============================================================================
local function getHRP()
    local char = LocalPlayer.Character
    if char then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function getHumanoid()
    local char = LocalPlayer.Character
    if char then
        return char:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

local function teleportTo(targetPos)
    local hrp = getHRP()
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 2, 0))
    end
end

local function parseCash(val)
    if type(val) == "number" then return val end
    if type(val) ~= "string" then return 0 end
    local clean = val:gsub(",", ""):gsub("%$", ""):lower():gsub("%s+", "")
    local num = tonumber(clean:match("[%d%.]+")) or 0
    if clean:find("k") then return num * 1e3
    elseif clean:find("m") then return num * 1e6
    elseif clean:find("b") then return num * 1e9
    elseif clean:find("t") then return num * 1e12
    elseif clean:find("qa") then return num * 1e15
    elseif clean:find("qi") then return num * 1e18
    elseif clean:find("sx") then return num * 1e21
    elseif clean:find("sp") then return num * 1e24
    elseif clean:find("oc") then return num * 1e27
    elseif clean:find("no") then return num * 1e30
    elseif clean:find("dc") then return num * 1e33
    end
    return num
end

-- Jump for Cases stores Cash as an Attribute on LocalPlayer
local function getPlayerCash()
    local attr = LocalPlayer:GetAttribute("Cash")
    if attr ~= nil then
        return parseCash(attr)
    end
    if LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Cash") then
        return parseCash(LocalPlayer.leaderstats.Cash.Value)
    end
    return 0
end

local function getCaseCount(caseName)
    local attr = LocalPlayer:GetAttribute("Cases_" .. caseName)
    return tonumber(attr) or 0
end

local function isHoldingCase()
    local attr = LocalPlayer:GetAttribute("_HoldingCase")
    return type(attr) == "string" and attr ~= ""
end

local function isFlightActive()
    return LocalPlayer:GetAttribute("_IsKicking") == true
end

local function isSpinActive()
    return LocalPlayer:GetAttribute("_FallSpinning") == true
end

local function isInKickSession()
    return LocalPlayer:GetAttribute("_InKickSession") == true
end

local function isRespawnOffer()
    return LocalPlayer:GetAttribute("_RespawnOffer") == true
end

local function getNormalWalkSpeed()
    local speedAttr = tonumber(LocalPlayer:GetAttribute("Speed")) or 14
    local baseSpd = (SpeedUpgradesConfig and tonumber(SpeedUpgradesConfig.BaseSpeed)) or 14
    return math.clamp(40 + math.max(0, speedAttr - baseSpd), 40, 50)
end

local TURBO_RETURN_SPEED = 500
local SAFEZONE_Z_FALLBACK = 122.75

local function getSafezoneZ()
    local invis = Workspace:FindFirstChild("InvisWalls")
    local sz = invis and invis:FindFirstChild("Safezone")
    if sz and sz:IsA("BasePart") then
        return sz.Position.Z
    end
    return SAFEZONE_Z_FALLBACK
end

-- Fastest verified anti-wave return WalkSpeed while carrying a case (outruns Zone 9-11 waves safely)
local function getSafeReturnSpeed()
    if Config.MasterAutoFarm or Config.ReturnSprintBoost then
        return TURBO_RETURN_SPEED
    end
    return getNormalWalkSpeed()
end

local function closeRespawnPopup()
    if RespawnPrompt then
        pcall(function()
            RespawnPrompt:FireServer({ kind = "decline" })
        end)
    end
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local rf = pg and pg:FindFirstChild("RespawnFrame", true)
        if rf and rf.Visible then
            rf.Visible = false
        end
    end)
end

local function syncNetworkGuardFlags()
    if getgenv then
        getgenv()._JFC_FallRewardEvent = FallRewardEvent
        getgenv()._JFC_RequestKick = RequestKick
        getgenv()._JFC_BlockWaveHit = (Config.MasterAutoFarm or Config.SafeAntiWave) == true
        getgenv()._JFC_ForcePerfectKick = (Config.MasterAutoFarm or Config.InstantPerfectKick) == true
    end
end

local function ensureNetworkHooks()
    syncNetworkGuardFlags()
    if not (getgenv and typeof(hookmetamethod) == "function" and typeof(getnamecallmethod) == "function") then
        return
    end
    if getgenv()._JFC_HookInstalled then
        return
    end
    getgenv()._JFC_HookInstalled = true
    local origNamecall
    origNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" or method == "fireServer" then
            if getgenv()._JFC_BlockWaveHit and self == getgenv()._JFC_FallRewardEvent then
                local arg1 = ...
                if type(arg1) == "table" and arg1.kind == "waveHit" then
                    return nil
                end
            elseif getgenv()._JFC_ForcePerfectKick and self == getgenv()._JFC_RequestKick then
                local arg1 = ...
                if type(arg1) == "table" and arg1.tier ~= nil and arg1.tier ~= "Perfect" then
                    return origNamecall(self, { tier = "Perfect" })
                end
            end
        end
        return origNamecall(self, ...)
    end)
end

ensureNetworkHooks()

-- ==============================================================================
-- 🎨 WINDUI INITIALIZATION
-- ==============================================================================
local WindUI = nil
local okWind, errWind = pcall(function()
    return loadstring(game:HttpGet("https://tree-hub.vercel.app/api/ui/main"))()
end)

if okWind and errWind then
    WindUI = errWind
else
    local okWind2, errWind2 = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end)
    if okWind2 and errWind2 then
        WindUI = errWind2
    end
end

if not WindUI then
    warn("[Song Hub] ❌ Failed to load WindUI!")
    return
end

-- ==============================================================================
-- 🌸 EYE-CARE PASTEL & AURORA THEME PRESETS (SOFT, VIBRANT & NON-HARSH)
-- ==============================================================================
local UI_THEME_PRESETS = {
    ["🌌 Aurora Borealis (แสงเหนือออโรร่า)"] = {
        Id = "JFC_AuroraBorealis",
        Effect = "AuroraFlow",
        Accent = "#132A38",
        Background = "#0A101D",
        Dialog = "#0F172A",
        Outline = "#5EEAD4",
        Text = "#F1F5F9",
        Placeholder = "#94A3B8",
        Button = "#1E3A5F",
        Icon = "#7DD3FC",
        Toggle = "#2DD4BF",
        Slider = "#38BDF8",
        SliderIcon = "#BAE6FD",
        Checkbox = "#2DD4BF",
        Primary = "#5EEAD4",
        ElementBackground = "#152238",
        PanelBackground = "#0E1729",
        LabelBackground = "#0B1322",
        Grad1 = Color3.fromHex("#090F1C"),
        Grad2 = Color3.fromHex("#112236"),
        Grad3 = Color3.fromHex("#151932"),
        Orb1 = Color3.fromHex("#5EEAD4"), -- Soft Aqua Mint
        Orb2 = Color3.fromHex("#7DD3FC"), -- Pastel Sky Blue
        Orb3 = Color3.fromHex("#C4B5FD"), -- Soft Lavender
        Orb4 = Color3.fromHex("#F9A8D4"), -- Gentle Rose
        Particle1 = Color3.fromHex("#99F6E4"),
        Particle2 = Color3.fromHex("#BAE6FD"),
        TitleSheen = Color3.fromHex("#A7F3D0"),
    },
    ["🌸 Sakura Twilight (ซากุระยามสนธยา)"] = {
        Id = "JFC_SakuraTwilight",
        Effect = "SakuraPetals",
        Accent = "#2D1630",
        Background = "#110B1A",
        Dialog = "#191026",
        Outline = "#F9A8D4",
        Text = "#FDF2F8",
        Placeholder = "#D8B4FE",
        Button = "#3B1D4A",
        Icon = "#F472B6",
        Toggle = "#EC4899",
        Slider = "#C084FC",
        SliderIcon = "#FBCFE8",
        Checkbox = "#F472B6",
        Primary = "#F9A8D4",
        ElementBackground = "#211533",
        PanelBackground = "#160E24",
        LabelBackground = "#120A1E",
        Grad1 = Color3.fromHex("#110A19"),
        Grad2 = Color3.fromHex("#231332"),
        Grad3 = Color3.fromHex("#19112E"),
        Orb1 = Color3.fromHex("#F9A8D4"), -- Sakura Pink
        Orb2 = Color3.fromHex("#C4B5FD"), -- Soft Wisteria
        Orb3 = Color3.fromHex("#FDBA74"), -- Warm Sunset Peach
        Orb4 = Color3.fromHex("#A5B4FC"), -- Periwinkle
        Particle1 = Color3.fromHex("#FBCFE8"),
        Particle2 = Color3.fromHex("#DDD6FE"),
        TitleSheen = Color3.fromHex("#F9A8D4"),
    },
    ["🌊 Ocean Serenity (มหาสมุทรครามสบายตา)"] = {
        Id = "JFC_OceanSerenity",
        Effect = "OceanBubbles",
        Accent = "#0F293D",
        Background = "#07121C",
        Dialog = "#0C1D2C",
        Outline = "#67E8F9",
        Text = "#F0F9FF",
        Placeholder = "#7DD3FC",
        Button = "#163B56",
        Icon = "#38BDF8",
        Toggle = "#06B6D4",
        Slider = "#38BDF8",
        SliderIcon = "#CFFAFE",
        Checkbox = "#22D3EE",
        Primary = "#67E8F9",
        ElementBackground = "#112638",
        PanelBackground = "#0A1926",
        LabelBackground = "#081420",
        Grad1 = Color3.fromHex("#061019"),
        Grad2 = Color3.fromHex("#0E2538"),
        Grad3 = Color3.fromHex("#0B1D30"),
        Orb1 = Color3.fromHex("#67E8F9"), -- Pearl Cyan
        Orb2 = Color3.fromHex("#6EE7B7"), -- Seafoam Mint
        Orb3 = Color3.fromHex("#818CF8"), -- Soft Indigo
        Orb4 = Color3.fromHex("#7DD3FC"), -- Sky Blue
        Particle1 = Color3.fromHex("#A5F3FC"),
        Particle2 = Color3.fromHex("#A7F3D0"),
        TitleSheen = Color3.fromHex("#67E8F9"),
    },
    ["🍃 Matcha Zen (มัทฉะเซนธรรมชาติ)"] = {
        Id = "JFC_MatchaZen",
        Effect = "StarlightFirefly",
        Accent = "#142E24",
        Background = "#09130F",
        Dialog = "#0E1F18",
        Outline = "#6EE7B7",
        Text = "#F0FDF4",
        Placeholder = "#86EFAC",
        Button = "#1B3D2F",
        Icon = "#34D399",
        Toggle = "#10B981",
        Slider = "#34D399",
        SliderIcon = "#D1FAE5",
        Checkbox = "#10B981",
        Primary = "#6EE7B7",
        ElementBackground = "#132820",
        PanelBackground = "#0C1A15",
        LabelBackground = "#091410",
        Grad1 = Color3.fromHex("#08110E"),
        Grad2 = Color3.fromHex("#12261E"),
        Grad3 = Color3.fromHex("#0F201D"),
        Orb1 = Color3.fromHex("#6EE7B7"), -- Matcha Mint
        Orb2 = Color3.fromHex("#A7F3D0"), -- Soft Sage
        Orb3 = Color3.fromHex("#FDE68A"), -- Warm Honey Tea
        Orb4 = Color3.fromHex("#5EEAD4"), -- Aqua Leaf
        Particle1 = Color3.fromHex("#A7F3D0"),
        Particle2 = Color3.fromHex("#FEF08A"),
        TitleSheen = Color3.fromHex("#A7F3D0"),
    },
    ["🌙 Velvet Amethyst (อเมทิสต์มิดไนท์)"] = {
        Id = "JFC_VelvetAmethyst",
        Effect = "StarlightFirefly",
        Accent = "#22183B",
        Background = "#0D0A1A",
        Dialog = "#141029",
        Outline = "#C4B5FD",
        Text = "#EEF2FF",
        Placeholder = "#A5B4FC",
        Button = "#2E2152",
        Icon = "#A78BFA",
        Toggle = "#8B5CF6",
        Slider = "#818CF8",
        SliderIcon = "#E0E7FF",
        Checkbox = "#8B5CF6",
        Primary = "#C4B5FD",
        ElementBackground = "#1A1433",
        PanelBackground = "#120E24",
        LabelBackground = "#0E0B1D",
        Grad1 = Color3.fromHex("#0C0918"),
        Grad2 = Color3.fromHex("#1B1435"),
        Grad3 = Color3.fromHex("#131730"),
        Orb1 = Color3.fromHex("#C4B5FD"), -- Soft Lilac
        Orb2 = Color3.fromHex("#818CF8"), -- Periwinkle
        Orb3 = Color3.fromHex("#F0ABFC"), -- Pastel Orchid
        Orb4 = Color3.fromHex("#7DD3FC"), -- Starlight Sky
        Particle1 = Color3.fromHex("#DDD6FE"),
        Particle2 = Color3.fromHex("#C7D2FE"),
        TitleSheen = Color3.fromHex("#DDD6FE"),
    },
}

local UI_THEME_NAMES = {
    "🌌 Aurora Borealis (แสงเหนือออโรร่า)",
    "🌸 Sakura Twilight (ซากุระยามสนธยา)",
    "🌊 Ocean Serenity (มหาสมุทรครามสบายตา)",
    "🍃 Matcha Zen (มัทฉะเซนธรรมชาติ)",
    "🌙 Velvet Amethyst (อเมทิสต์มิดไนท์)",
}

local UI_STYLE_MAP = {
    ["Auto (ตามธีมอัตโนมัติ)"] = "Auto",
    ["🌌 Aurora Flow (แสงเหนือไหลนุ่มๆ)"] = "AuroraFlow",
    ["🌸 Sakura Petals (กลีบซากุระลอยช้าๆ)"] = "SakuraPetals",
    ["✨ Starlight Firefly (ละอองดาวหิ่งห้อย)"] = "StarlightFirefly",
    ["🌊 Ocean Bubbles (ฟองอากาศใต้น้ำ)"] = "OceanBubbles",
    ["🧘 Minimal Glow Only (เฉพาะแสงออร่า ไม่เอาละออง)"] = "MinimalGlow",
}

local UI_STYLE_NAMES = {
    "Auto (ตามธีมอัตโนมัติ)",
    "🌌 Aurora Flow (แสงเหนือไหลนุ่มๆ)",
    "🌸 Sakura Petals (กลีบซากุระลอยช้าๆ)",
    "✨ Starlight Firefly (ละอองดาวหิ่งห้อย)",
    "🌊 Ocean Bubbles (ฟองอากาศใต้น้ำ)",
    "🧘 Minimal Glow Only (เฉพาะแสงออร่า ไม่เอาละออง)",
}

pcall(function()
    if WindUI and typeof(WindUI.AddTheme) == "function" then
        for _, preset in pairs(UI_THEME_PRESETS) do
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
                ElementBackgroundTransparency = 0.16,
                PanelBackground = Color3.fromHex(preset.PanelBackground),
                PanelBackgroundTransparency = 0.85,
                LabelBackground = Color3.fromHex(preset.LabelBackground),
                LabelBackgroundTransparency = 0.72,
            })
        end
    end
end)

local defaultThemeId = (WindUI and WindUI.Themes and WindUI.Themes["JFC_AuroraBorealis"]) and "JFC_AuroraBorealis" or "Dark"
if Config.UITheme and UI_THEME_PRESETS[Config.UITheme] then
    local savedThemeId = UI_THEME_PRESETS[Config.UITheme].Id
    if WindUI and WindUI.Themes and WindUI.Themes[savedThemeId] then
        defaultThemeId = savedThemeId
    end
end

CfgSys.toggleKeyEnum, CfgSys.toggleKeyName = CfgSys.resolveKeyCode(Config.UIToggleKey)
Config.UIToggleKey = CfgSys.toggleKeyName

local Window = WindUI:CreateWindow({
    Title = "Song Hub  •  Jump for Cases",
    Icon = "sparkles",
    Author = "Aurora Eye-Care Edition",
    Folder = "SongHub_JumpForCases",
    Size = UDim2.fromOffset(650, 460),
    SideBarWidth = 185,
    Transparent = true,
    Theme = defaultThemeId,
    ToggleKey = CfgSys.toggleKeyEnum,
    OpenButton = {
        Title = "🎲 Song Hub | Jump for Cases",
        Icon = "sparkles",
        CornerRadius = UDim.new(0, 14),
        StrokeThickness = 2,
        Color = ColorSequence.new(
            Color3.fromHex("#5EEAD4"),
            Color3.fromHex("#818CF8")
        ),
        Enabled = true,
        Draggable = true,
    },
})

if getgenv then
    getgenv()._JFC_Window = Window
    getgenv()._SongHubRevokeCallbacks = getgenv()._SongHubRevokeCallbacks or {}
    getgenv()._SongHubRevokeCallbacks["JumpForCases"] = function()
        if getgenv()._JumpForCasesRunning == EXEC_ID then
            getgenv()._JumpForCasesRunning = -1
        end
        pcall(function() Window:Destroy() end)
    end
end

pcall(function()
    if Window and typeof(Window.SetToggleKey) == "function" then
        Window:SetToggleKey(CfgSys.toggleKeyEnum)
    end
    if Window and typeof(Window.EditOpenButton) == "function" then
        Window:EditOpenButton({
            Title = "🎲 Song Hub | Jump for Cases",
            Icon = "sparkles",
            CornerRadius = UDim.new(0, 14),
            StrokeThickness = 2,
            Color = ColorSequence.new(
                Color3.fromHex("#5EEAD4"),
                Color3.fromHex("#818CF8")
            ),
        })
    end
    if Window and typeof(Window.Tag) == "function" then
        Window:Tag({
            Title = "✨ Aurora UI",
            Color = Color3.fromHex("#2DD4BF"),
        })
    end
end)

-- ==============================================================================
-- 🌌 PROCEDURAL AURORA & EYE-SOOTHING ANIMATION ENGINE (60 FPS, ZERO EYE STRAIN)
-- ==============================================================================
local uiAnimConn = nil
do
    local mainWinFrame = Window and Window.UIElements and Window.UIElements.Main
    local activePreset = UI_THEME_PRESETS[Config.UITheme] or UI_THEME_PRESETS["🌌 Aurora Borealis (แสงเหนือออโรร่า)"]
    local animCanvas, borderFrame = nil, nil
    local bgGrad, borderGrad, topLineGrad, titleGrad = nil, nil, nil, nil
    local outerHalo, innerHalo, outerHaloStroke, innerHaloStroke = nil, nil, nil, nil
    local orbs = {}
    local particles = {}

    if mainWinFrame then
        pcall(function()
            for _, childName in ipairs({ "JFC_AuroraCanvas", "JFC_BorderFrame" }) do
                local old = mainWinFrame:FindFirstChild(childName)
                if old then old:Destroy() end
            end

            -- 1. Deep Velvet Backdrop Canvas (ZIndex 4: blocks noisy 3D world text behind UI)
            animCanvas = Instance.new("Frame")
            animCanvas.Name = "JFC_AuroraCanvas"
            animCanvas.Size = UDim2.fromScale(1, 1)
            animCanvas.Position = UDim2.fromScale(0, 0)
            animCanvas.BackgroundColor3 = Color3.new(1, 1, 1)
            animCanvas.BackgroundTransparency = 0.04
            animCanvas.BorderSizePixel = 0
            animCanvas.ClipsDescendants = true
            animCanvas.ZIndex = 4
            animCanvas.Parent = mainWinFrame

            local cCorner = Instance.new("UICorner")
            cCorner.CornerRadius = UDim.new(0, 12)
            cCorner.Parent = animCanvas

            bgGrad = Instance.new("UIGradient")
            bgGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, activePreset.Grad1),
                ColorSequenceKeypoint.new(0.5, activePreset.Grad2),
                ColorSequenceKeypoint.new(1, activePreset.Grad3),
            })
            bgGrad.Rotation = 35
            bgGrad.Parent = animCanvas

            -- 2. Four Ultra-Soft Breathing Aurora Mist Orbs (ZIndex 5)
            local orbDefs = {
                { Pos = UDim2.fromScale(0.18, 0.22), Size = UDim2.fromOffset(310, 310), Col = activePreset.Orb1 },
                { Pos = UDim2.fromScale(0.84, 0.76), Size = UDim2.fromOffset(340, 340), Col = activePreset.Orb2 },
                { Pos = UDim2.fromScale(0.65, 0.24), Size = UDim2.fromOffset(270, 270), Col = activePreset.Orb3 },
                { Pos = UDim2.fromScale(0.28, 0.80), Size = UDim2.fromOffset(250, 250), Col = activePreset.Orb4 },
            }
            for idx, od in ipairs(orbDefs) do
                local orb = Instance.new("Frame")
                orb.Name = "AuroraOrb_" .. idx
                orb.AnchorPoint = Vector2.new(0.5, 0.5)
                orb.Position = od.Pos
                orb.Size = od.Size
                orb.BackgroundColor3 = od.Col
                orb.BackgroundTransparency = 0.88
                orb.BorderSizePixel = 0
                orb.ZIndex = 5
                orb.Parent = animCanvas

                local oCorner = Instance.new("UICorner")
                oCorner.CornerRadius = UDim.new(1, 0)
                oCorner.Parent = orb

                local oGrad = Instance.new("UIGradient")
                oGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.20),
                    NumberSequenceKeypoint.new(0.60, 0.62),
                    NumberSequenceKeypoint.new(1, 1),
                })
                oGrad.Parent = orb

                table.insert(orbs, {
                    Frame = orb,
                    BaseX = od.Pos.X.Scale,
                    BaseY = od.Pos.Y.Scale,
                    Phase = idx * 1.65,
                })
            end

            -- 3. Soft Counter-Rotating Celestial Halo Rings (ZIndex 5)
            local haloCenter = UDim2.fromScale(0.64, 0.54)

            outerHalo = Instance.new("Frame")
            outerHalo.Name = "CelestialOuterHalo"
            outerHalo.AnchorPoint = Vector2.new(0.5, 0.5)
            outerHalo.Position = haloCenter
            outerHalo.Size = UDim2.fromOffset(260, 260)
            outerHalo.BackgroundTransparency = 1
            outerHalo.ZIndex = 5
            outerHalo.Parent = animCanvas
            local ohCorner = Instance.new("UICorner")
            ohCorner.CornerRadius = UDim.new(1, 0)
            ohCorner.Parent = outerHalo
            outerHaloStroke = Instance.new("UIStroke")
            outerHaloStroke.Thickness = 1.2
            outerHaloStroke.Transparency = 0.82
            outerHaloStroke.Color = activePreset.Orb1
            outerHaloStroke.Parent = outerHalo
            local ohGrad = Instance.new("UIGradient")
            ohGrad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.15),
                NumberSequenceKeypoint.new(0.5, 0.90),
                NumberSequenceKeypoint.new(1, 0.15),
            })
            ohGrad.Parent = outerHaloStroke

            innerHalo = Instance.new("Frame")
            innerHalo.Name = "CelestialInnerHalo"
            innerHalo.AnchorPoint = Vector2.new(0.5, 0.5)
            innerHalo.Position = haloCenter
            innerHalo.Size = UDim2.fromOffset(180, 180)
            innerHalo.BackgroundTransparency = 1
            innerHalo.ZIndex = 5
            innerHalo.Parent = animCanvas
            local ihCorner = Instance.new("UICorner")
            ihCorner.CornerRadius = UDim.new(1, 0)
            ihCorner.Parent = innerHalo
            innerHaloStroke = Instance.new("UIStroke")
            innerHaloStroke.Thickness = 1.0
            innerHaloStroke.Transparency = 0.84
            innerHaloStroke.Color = activePreset.Orb3
            innerHaloStroke.Parent = innerHalo
            local ihGrad = Instance.new("UIGradient")
            ihGrad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.85),
                NumberSequenceKeypoint.new(0.5, 0.15),
                NumberSequenceKeypoint.new(1, 0.85),
            })
            ihGrad.Parent = innerHaloStroke

            -- 4. 18 Gentle Pastel Floating Motes / Petals / Ribbons (ZIndex 6)
            for i = 1, 18 do
                local p = Instance.new("Frame")
                p.Name = "AuroraMote_" .. i
                p.AnchorPoint = Vector2.new(0.5, 0.5)
                local sz = math.random(4, 7)
                p.Size = UDim2.fromOffset(sz, sz)
                p.Position = UDim2.fromScale(math.random() * 0.94 + 0.03, math.random())
                p.BackgroundColor3 = (i % 2 == 0) and activePreset.Particle1 or activePreset.Particle2
                p.BackgroundTransparency = 0.52 + (math.random() * 0.28)
                p.BorderSizePixel = 0
                p.ZIndex = 6
                p.Parent = animCanvas

                local pCorner = Instance.new("UICorner")
                pCorner.CornerRadius = UDim.new(1, 0)
                pCorner.Parent = p

                local pStroke = Instance.new("UIStroke")
                pStroke.Thickness = 1
                pStroke.Transparency = 0.68
                pStroke.Color = (i % 2 == 0) and activePreset.Orb1 or activePreset.Orb2
                pStroke.Parent = p

                table.insert(particles, {
                    Frame = p,
                    Corner = pCorner,
                    Stroke = pStroke,
                    X = math.random() * 0.94 + 0.03,
                    Y = math.random(),
                    Speed = 0.028 + math.random() * 0.045,
                    SwayAmp = 0.012 + math.random() * 0.024,
                    SwayFreq = 0.9 + math.random() * 1.4,
                    Phase = math.random() * 6.28,
                    BaseSize = sz,
                })
            end

            -- 5. Silky Rotating Pastel Border & Topbar Flowing Ribbon (ZIndex 98)
            borderFrame = Instance.new("Frame")
            borderFrame.Name = "JFC_BorderFrame"
            borderFrame.Size = UDim2.fromScale(1, 1)
            borderFrame.Position = UDim2.fromScale(0, 0)
            borderFrame.BackgroundTransparency = 1
            borderFrame.BorderSizePixel = 0
            borderFrame.ZIndex = 98
            borderFrame.Parent = mainWinFrame

            local bfCorner = Instance.new("UICorner")
            bfCorner.CornerRadius = UDim.new(0, 12)
            bfCorner.Parent = borderFrame

            local bfStroke = Instance.new("UIStroke")
            bfStroke.Thickness = 1.7
            bfStroke.Transparency = 0.28
            bfStroke.Color = Color3.new(1, 1, 1)
            bfStroke.Parent = borderFrame

            borderGrad = Instance.new("UIGradient")
            borderGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, activePreset.Orb1),
                ColorSequenceKeypoint.new(0.35, activePreset.Orb2),
                ColorSequenceKeypoint.new(0.70, activePreset.Orb3),
                ColorSequenceKeypoint.new(1, activePreset.Orb4),
            })
            borderGrad.Rotation = 0
            borderGrad.Parent = bfStroke

            local topBarLine = Instance.new("Frame")
            topBarLine.Name = "TopbarAuroraLine"
            topBarLine.Position = UDim2.new(0, 16, 0, 48)
            topBarLine.Size = UDim2.new(1, -32, 0, 1)
            topBarLine.BackgroundColor3 = Color3.new(1, 1, 1)
            topBarLine.BackgroundTransparency = 0.25
            topBarLine.BorderSizePixel = 0
            topBarLine.ZIndex = 98
            topBarLine.Parent = borderFrame

            topLineGrad = Instance.new("UIGradient")
            topLineGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, activePreset.Orb2),
                ColorSequenceKeypoint.new(0.5, activePreset.Orb1),
                ColorSequenceKeypoint.new(1, activePreset.Orb3),
            })
            topLineGrad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.18, 0.15),
                NumberSequenceKeypoint.new(0.5, 0.05),
                NumberSequenceKeypoint.new(0.82, 0.15),
                NumberSequenceKeypoint.new(1, 1),
            })
            topLineGrad.Parent = topBarLine

            -- 6. Soft Shimmer Gradient on Window Title Text
            local innerMain = mainWinFrame:FindFirstChild("Main")
            local topbar = innerMain and innerMain:FindFirstChild("Topbar")
            local left = topbar and topbar:FindFirstChild("Left")
            local titleHolder = left and left:FindFirstChild("Title")
            local titleLbl = titleHolder and titleHolder:FindFirstChild("Title")
            if titleLbl and titleLbl:IsA("TextLabel") then
                local oldTG = titleLbl:FindFirstChildOfClass("UIGradient")
                if oldTG then oldTG:Destroy() end
                titleGrad = Instance.new("UIGradient")
                titleGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHex("#FFFFFF")),
                    ColorSequenceKeypoint.new(0.5, activePreset.TitleSheen),
                    ColorSequenceKeypoint.new(1, activePreset.Orb2),
                })
                titleGrad.Parent = titleLbl
            end
        end)
    end

    local function getActiveEffectStyle()
        local chosen = Config.UIAnimationStyle or "Auto (ตามธีมอัตโนมัติ)"
        local mapped = UI_STYLE_MAP[chosen] or "Auto"
        if mapped == "Auto" then
            return (activePreset and activePreset.Effect) or "AuroraFlow"
        end
        return mapped
    end

    local function updateParticleShapes()
        local eff = getActiveEffectStyle()
        local showParticles = (Config.UIBackgroundAnimation ~= false) and (eff ~= "MinimalGlow")
        for i, pt in ipairs(particles) do
            pcall(function()
                pt.Frame.Visible = showParticles
                pt.Frame.BackgroundColor3 = (i % 2 == 0) and activePreset.Particle1 or activePreset.Particle2
                pt.Stroke.Color = (i % 2 == 0) and activePreset.Orb1 or activePreset.Orb2
                if eff == "AuroraFlow" then
                    pt.Frame.Size = UDim2.fromOffset(pt.BaseSize * 2.8, math.max(3, math.floor(pt.BaseSize * 0.55)))
                    pt.Frame.Rotation = -14
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

    local function applyAuroraTheme(themeLabel, notifyUser)
        local preset = UI_THEME_PRESETS[themeLabel] or UI_THEME_PRESETS["🌌 Aurora Borealis (แสงเหนือออโรร่า)"]
        activePreset = preset
        Config.UITheme = themeLabel

        pcall(function()
            if WindUI and WindUI.SetTheme then
                WindUI:SetTheme(preset.Id)
            elseif Window and Window.SetTheme then
                Window:SetTheme(preset.Id)
            end
        end)

        pcall(function()
            if bgGrad then
                bgGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, preset.Grad1),
                    ColorSequenceKeypoint.new(0.5, preset.Grad2),
                    ColorSequenceKeypoint.new(1, preset.Grad3),
                })
            end
            if borderGrad then
                borderGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, preset.Orb1),
                    ColorSequenceKeypoint.new(0.35, preset.Orb2),
                    ColorSequenceKeypoint.new(0.70, preset.Orb3),
                    ColorSequenceKeypoint.new(1, preset.Orb4),
                })
            end
            if topLineGrad then
                topLineGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, preset.Orb2),
                    ColorSequenceKeypoint.new(0.5, preset.Orb1),
                    ColorSequenceKeypoint.new(1, preset.Orb3),
                })
            end
            if titleGrad then
                titleGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHex("#FFFFFF")),
                    ColorSequenceKeypoint.new(0.5, preset.TitleSheen),
                    ColorSequenceKeypoint.new(1, preset.Orb2),
                })
            end
            if orbs[1] then orbs[1].Frame.BackgroundColor3 = preset.Orb1 end
            if orbs[2] then orbs[2].Frame.BackgroundColor3 = preset.Orb2 end
            if orbs[3] then orbs[3].Frame.BackgroundColor3 = preset.Orb3 end
            if orbs[4] then orbs[4].Frame.BackgroundColor3 = preset.Orb4 end
            if outerHaloStroke then outerHaloStroke.Color = preset.Orb1 end
            if innerHaloStroke then innerHaloStroke.Color = preset.Orb3 end
            updateParticleShapes()
        end)

        if notifyUser and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "🎨 เปลี่ยนธีมสำเร็จ",
                Content = "ใช้ธีม: " .. tostring(themeLabel),
                Duration = 2.5,
                Icon = "palette",
            })
        end
    end

    updateParticleShapes()

    local animClock = 0
    uiAnimConn = RunService.RenderStepped:Connect(function(dt)
        if not isScriptAlive() then return end
        if not animCanvas or Config.UIBackgroundAnimation == false then return end
        if Window.Closed or not mainWinFrame or not mainWinFrame.Visible then return end

        local speedMult = math.clamp((tonumber(Config.UIAnimationSpeed) or 8) / 10, 0.15, 2.5)
        local step = math.min(dt, 0.05) * speedMult
        animClock = animClock + step

        -- 1. Calmly oscillate background gradient & rotate pastel border
        if bgGrad then
            bgGrad.Rotation = 35 + math.sin(animClock * 0.35) * 22
        end
        if borderGrad then
            borderGrad.Rotation = (animClock * 26) % 360
        end
        if topLineGrad then
            topLineGrad.Offset = Vector2.new(math.sin(animClock * 0.85) * 0.32, 0)
        end
        if titleGrad then
            titleGrad.Offset = Vector2.new(math.sin(animClock * 0.70) * 0.28, 0)
        end

        -- 2. Slow-breathing ambient aurora mist orbs
        for _, ob in ipairs(orbs) do
            local ox = ob.BaseX + math.sin(animClock * 0.42 + ob.Phase) * 0.075
            local oy = ob.BaseY + math.cos(animClock * 0.34 + ob.Phase) * 0.075
            ob.Frame.Position = UDim2.fromScale(ox, oy)
            ob.Frame.BackgroundTransparency = 0.88 + math.sin(animClock * 0.95 + ob.Phase) * 0.035
        end

        -- 3. Counter-rotate celestial halo rings very gently
        if outerHalo then
            outerHalo.Rotation = (animClock * 9) % 360
        end
        if innerHalo then
            innerHalo.Rotation = (-animClock * 14) % 360
        end

        -- 4. Gentle floating motes
        local eff = getActiveEffectStyle()
        if eff == "MinimalGlow" then return end

        for _, pt in ipairs(particles) do
            if eff == "AuroraFlow" then
                pt.X = pt.X + step * pt.Speed * 1.35
                pt.Y = pt.Y - step * pt.Speed * 0.32
                if pt.X > 1.06 or pt.Y < -0.05 then
                    pt.X = -0.06
                    pt.Y = math.random() * 0.92 + 0.04
                end
                local py = pt.Y + math.sin(animClock * pt.SwayFreq + pt.Phase) * (pt.SwayAmp * 0.6)
                pt.Frame.Position = UDim2.fromScale(pt.X, py)
                pt.Frame.BackgroundTransparency = 0.56 + math.sin(animClock * 1.8 + pt.Phase) * 0.18
            elseif eff == "SakuraPetals" then
                pt.Y = pt.Y + step * pt.Speed * 0.65
                pt.X = pt.X - step * pt.Speed * 0.35
                if pt.Y > 1.05 or pt.X < -0.05 then
                    pt.Y = -0.05
                    pt.X = math.random() * 1.05
                end
                local px = pt.X + math.sin(animClock * pt.SwayFreq + pt.Phase) * pt.SwayAmp
                pt.Frame.Position = UDim2.fromScale(px, pt.Y)
                pt.Frame.Rotation = (animClock * 42 + pt.Phase * 30) % 360
                pt.Frame.BackgroundTransparency = 0.50 + math.sin(animClock * 1.5 + pt.Phase) * 0.18
            elseif eff == "OceanBubbles" then
                pt.Y = pt.Y - step * pt.Speed * 0.60
                if pt.Y < -0.05 then
                    pt.Y = 1.05
                    pt.X = math.random() * 0.94 + 0.03
                end
                local px = pt.X + math.sin(animClock * pt.SwayFreq + pt.Phase) * pt.SwayAmp
                pt.Frame.Position = UDim2.fromScale(px, pt.Y)
                pt.Frame.BackgroundTransparency = 0.58 + math.sin(animClock * 1.6 + pt.Phase) * 0.16
            else
                -- StarlightFirefly
                pt.Y = pt.Y - step * pt.Speed * 0.38
                if pt.Y < -0.05 then
                    pt.Y = 1.05
                    pt.X = math.random() * 0.94 + 0.03
                end
                local px = pt.X + math.sin(animClock * 0.75 + pt.Phase) * (pt.SwayAmp * 0.65)
                pt.Frame.Position = UDim2.fromScale(px, pt.Y)
                local twinkle = math.sin(animClock * 2.2 + pt.Phase)
                local s = math.max(3, pt.BaseSize + twinkle * 1.8)
                pt.Frame.Size = UDim2.fromOffset(s, s)
                pt.Frame.BackgroundTransparency = 0.58 - twinkle * 0.20
            end
        end
    end)

    Window._JFCThemeEngine = {
        ThemeNames = UI_THEME_NAMES,
        StyleNames = UI_STYLE_NAMES,
        ApplyTheme = applyAuroraTheme,
        UpdateParticles = updateParticleShapes,
        SetAnimEnabled = function(enabled)
            Config.UIBackgroundAnimation = enabled
            if animCanvas then
                for _, ob in ipairs(orbs) do ob.Frame.Visible = enabled end
                if outerHalo then outerHalo.Visible = enabled end
                if innerHalo then innerHalo.Visible = enabled end
            end
            updateParticleShapes()
        end,
    }

    task.defer(function()
        task.wait(0.2)
        applyAuroraTheme(Config.UITheme, false)
        pcall(function() Window:SelectTab(1) end)
    end)
end

WindUI:Notify({
    Title = "✨ Song Hub Aurora Loaded!",
    Content = "Jump for Cases🎲 • Eye-Care Smooth UI Ready",
    Duration = 4,
    Icon = "sparkles",
})

-- ==============================================================================
-- 📑 TABS & AUTOMATIC CONFIG BINDING WRAPPER
-- ==============================================================================
local function wrapTabForConfig(rawTab)
    local TITLE_TO_CONFIG_KEY = {
        ["Master Auto Farm (Turbo Bypass)"] = "MasterAutoFarm",
        ["Instant Perfect Kick (+ Launch Bypass)"] = "InstantPerfectKick",
        ["Cutscene & Spin Bypass (~8.7s Skip)"] = "CutsceneBypass",
        ["Safe Anti-Wave (No Wave Death)"] = "SafeAntiWave",
        ["Native AutoKick Sync"] = "NativeAutoKickSync",
        ["Turbo Return Bypass (500 WS Anti-Wave)"] = "ReturnSprintBoost",
        ["Instant Warp Return"] = "InstantWarpReturn",
        ["Fast Open (Skip Animation)"] = "FastOpenSkip",
        ["Instant 0s Reveal & Auto Luck Clover"] = "InstantRevealBypass",
        ["Auto Open All Mutated & Event Cases (3x)"] = "AutoOpenMutatedCases",
        ["Auto Open All Owned Cases"] = "AutoOpenAll",
        ["Open Delay (s)"] = "CaseOpenDelay",
        ["Select Target Case"] = "SelectedCase",
        ["Auto Open Selected Case"] = "AutoOpenSelected",
        ["Smart AI Auto-Expedition (1,500 Gems/Day)"] = "AutoSmartExpedition",
        ["Expedition Risk Strategy"] = "ExpeditionStrategy",
        ["Expedition Duration"] = "ExpeditionDuration",
        ["Smart Auto-Sell Junk Brainrots (Anywhere)"] = "AutoSellJunkPets",
        ["Auto-Sell Max Rarity Filter"] = "AutoSellMaxRarity",
        ["1-Click Max Level Units (Lv.1 -> Lv.100)"] = "InstantMaxLevelUnits",
        ["Auto Claim Event Pass & Perm Quests"] = "AutoClaimEventPass",
        ["Auto Buy Gem Shop Boosts"] = "AutoBuyGemBoost",
        ["Target Gem Boost"] = "SelectedGemBoost",
        ["Auto Equip Best Units (Place Best)"] = "AutoEquipBest",
        ["Auto Collect Money (Base Cash)"] = "AutoCollectMoney",
        ["Auto Upgrade Units (Level Up Best)"] = "AutoUpgradeUnits",
        ["Unit Upgrade Priority"] = "UnitUpgradePriority",
        ["Auto Train (Auto Lift Barbell)"] = "AutoTrain",
        ["Auto Train X2 (Claim X2 & Rush x5)"] = "AutoTrainX2",
        ["Auto Buy Speed Upgrades"] = "AutoSpeedUpgrade",
        ["Speed Upgrade Tier"] = "SpeedUpgradeTierLabel",
        ["Auto Buy Best Affordable Weight"] = "AutoBuyWeight",
        ["Auto Equip Best Weight"] = "AutoEquipWeight",
        ["Auto Rebirth"] = "AutoRebirth",
        ["Auto Claim Index Gems"] = "AutoClaimIndexGems",
        ["Auto Claim Daily Reward"] = "AutoClaimDaily",
        ["Auto Free Wheel Spin"] = "AutoSpinWheel",
        ["Auto Claim Offline Cash"] = "AutoClaimOffline",
        ["Auto Forever Rewards"] = "AutoForeverRewards",
        ["Enable Custom WalkSpeed"] = "WalkSpeedEnabled",
        ["WalkSpeed Value"] = "WalkSpeedValue",
        ["Enable Custom JumpPower"] = "JumpPowerEnabled",
        ["JumpPower Value"] = "JumpPowerValue",
        ["Infinite Jump"] = "InfiniteJump",
        ["NoClip"] = "NoClip",
        ["Fly"] = "FlyEnabled",
        ["Fly Speed"] = "FlySpeed",
        ["UI Color Theme (โทนสีสบายตา)"] = "UITheme",
        ["Animation Effect Style (รูปแบบเอฟเฟกต์)"] = "UIAnimationStyle",
        ["Smooth Animated Effects (เปิดเอฟเฟกต์เคลื่อนไหว)"] = "UIBackgroundAnimation",
        ["Animation Speed (ความเร็วการเคลื่อนไหว)"] = "UIAnimationSpeed",
    }
    return setmetatable({}, {
        __index = function(_, method)
            local origMethod = rawTab[method]
            if type(origMethod) ~= "function" then
                return origMethod
            end
            if method == "Toggle" or method == "Dropdown" or method == "Slider" then
                return function(_, opts)
                    local cfgKey = opts and opts.Title and TITLE_TO_CONFIG_KEY[opts.Title]
                    local origCb = opts and opts.Callback
                    if cfgKey and Config[cfgKey] ~= nil then
                        if method == "Toggle" or method == "Dropdown" then
                            opts.Default = Config[cfgKey]
                            opts.Value = Config[cfgKey]
                        elseif method == "Slider" and type(opts.Value) == "table" then
                            opts.Value.Default = Config[cfgKey]
                        end
                    end
                    if cfgKey and origCb then
                        opts.Callback = function(val)
                            if cfgKey == "SpeedUpgradeTierLabel" then
                                Config.SpeedUpgradeTierLabel = val
                            else
                                Config[cfgKey] = val
                            end
                            origCb(val)
                            CfgSys.scheduleAutoSave()
                        end
                    end
                    local ctrl = origMethod(rawTab, opts)
                    if cfgKey then
                        CfgSys.RegisteredControls[cfgKey] = {
                            elem = ctrl,
                            kind = method,
                            callback = origCb,
                        }
                    end
                    return ctrl
                end
            end
            return function(_, ...)
                return origMethod(rawTab, ...)
            end
        end
    })
end

local TabFarm = wrapTabForConfig(Window:Tab({ Title = "Auto Farm", Icon = "zap" }))
CfgSys.TabPremium = wrapTabForConfig(Window:Tab({ Title = "VVIP Overdrive", Icon = "crown" }))
local TabCases = wrapTabForConfig(Window:Tab({ Title = "Cases", Icon = "package" }))
local TabUpgrades = wrapTabForConfig(Window:Tab({ Title = "Upgrades", Icon = "trending-up" }))
local TabClaims = wrapTabForConfig(Window:Tab({ Title = "Claims & Codes", Icon = "gift" }))
local TabTeleports = wrapTabForConfig(Window:Tab({ Title = "Teleports", Icon = "map-pin" }))
local TabPlayer = wrapTabForConfig(Window:Tab({ Title = "Player", Icon = "user" }))
local TabSettings = wrapTabForConfig(Window:Tab({ Title = "Settings", Icon = "settings" }))

-- ==============================================================================
-- 🦘 TAB: AUTO FARM / JUMP
-- ==============================================================================
TabFarm:Section({ Title = "🚀 Smart Master Auto Farm" })

TabFarm:Toggle({
    Title = "Master Auto Farm (Turbo Bypass)",
    Desc = "Launch bypass + cutscene skip (~8.7s saved) + 500 WS anti-wave return + instant warp loop",
    Default = false,
    Callback = function(v)
        Config.MasterAutoFarm = v
        syncNetworkGuardFlags()
    end,
})

TabFarm:Toggle({
    Title = "Instant Perfect Kick (+ Launch Bypass)",
    Desc = "Forces Perfect tier and fires launch bypass immediately (~0.13s instead of ~3.3s)",
    Default = false,
    Callback = function(v)
        Config.InstantPerfectKick = v
        syncNetworkGuardFlags()
    end,
})

TabFarm:Toggle({
    Title = "Cutscene & Spin Bypass (~8.7s Skip)",
    Desc = "Skips FallReward wave/reveal cutscene immediately after landing so return starts at once",
    Default = false,
    Callback = function(v)
        Config.CutsceneBypass = v
    end,
})

TabFarm:Toggle({
    Title = "Safe Anti-Wave (No Wave Death)",
    Desc = "Blocks tsunami wave hit reports so you never die or lose a case mid-return",
    Default = false,
    Callback = function(v)
        Config.SafeAntiWave = v
        syncNetworkGuardFlags()
    end,
})

TabFarm:Section({ Title = "⚙️ Built-in AutoKick & Return Speed" })

TabFarm:Toggle({
    Title = "Native AutoKick Sync",
    Desc = "Toggles the game's official AutoKick feature",
    Default = false,
    Callback = function(v)
        Config.NativeAutoKickSync = v
        if RequestAutoKick then
            pcall(function()
                RequestAutoKick:FireServer({ on = v })
            end)
        end
        if RequestSetSetting then
            pcall(function()
                RequestSetSetting:FireServer({ key = "AutoKick", value = v })
            end)
        end
    end,
})

TabFarm:Toggle({
    Title = "Turbo Return Bypass (500 WS Anti-Wave)",
    Desc = "Skips wave cutscene and runs back at 500 WS via Heartbeat MoveTo + auto SafeClaim",
    Default = false,
    Callback = function(v)
        Config.ReturnSprintBoost = v
    end,
})

TabFarm:Toggle({
    Title = "Instant Warp Return",
    Desc = "Instantly warps back to Kick Zone the moment a case finishes depositing in Safezone",
    Default = false,
    Callback = function(v)
        Config.InstantWarpReturn = v
    end,
})

-- Kick Minigame Smart Auto-Lock (Waits for Perfect fraction >= 0.925 when minigame opens)
local rsFarmLockConn
rsFarmLockConn = RunService.RenderStepped:Connect(function()
    if not isScriptAlive() then
        if rsFarmLockConn then
            rsFarmLockConn:Disconnect()
            rsFarmLockConn = nil
        end
        return
    end
    if not (Config.MasterAutoFarm or Config.InstantPerfectKick) then
        return
    end
    local renv = getrenv and getrenv()
    local KickAuto = (renv and renv._G and renv._G.KickAuto) or _G.KickAuto
    if type(KickAuto) == "table" and type(KickAuto.state) == "function" and type(KickAuto.lock) == "function" then
        local state = KickAuto.state()
        if state and state.minigameActive and not state.locked then
            local oscFreq = tonumber(state.oscFreq) or 0.55
            local period = oscFreq * 2
            local elapsed = os.clock() - (tonumber(state.startTime) or os.clock())
            local phase = period > 0 and (elapsed % period) or 0
            local frac = phase < oscFreq and (phase / oscFreq) or (1 - (phase - oscFreq) / oscFreq)
            if frac >= 0.925 then
                KickAuto.lock()
            end
        end
    end
end)

-- Kick Windup Launch Bypass + FallReward Cutscene Skipper (scoped cleanly to EXEC_ID)
local kickingBypassConn
local launchDispatchedForKick = false
local function dispatchLaunchBypass()
    if launchDispatchedForKick or not RequestKick or not isFlightActive() then
        return false
    end
    if not (Config.MasterAutoFarm or Config.InstantPerfectKick) then
        return false
    end
    launchDispatchedForKick = true
    pcall(function()
        RequestKick:FireServer({ action = "launch" })
    end)
    return true
end

kickingBypassConn = LocalPlayer:GetAttributeChangedSignal("_IsKicking"):Connect(function()
    if not isScriptAlive() then
        if kickingBypassConn then
            kickingBypassConn:Disconnect()
            kickingBypassConn = nil
        end
        return
    end
    if isFlightActive() then
        dispatchLaunchBypass()
    else
        launchDispatchedForKick = false
    end
end)

local fallRewardSkipConn
if FallRewardEvent then
    fallRewardSkipConn = FallRewardEvent.OnClientEvent:Connect(function(data)
        if not isScriptAlive() then
            if fallRewardSkipConn then
                fallRewardSkipConn:Disconnect()
                fallRewardSkipConn = nil
            end
            return
        end
        if not (Config.MasterAutoFarm or Config.CutsceneBypass or Config.ReturnSprintBoost) then
            return
        end
        if type(data) == "table" and data.kind == "begin" and (data.player == nil or data.player == LocalPlayer) then
            task.defer(function()
                if isScriptAlive() and FallRewardEvent then
                    pcall(function()
                        FallRewardEvent:FireServer({ kind = "waveCutsceneDone" })
                    end)
                end
            end)
        end
    end)
end

-- Fastest Server-Safe Turbo Return Helper (500 WS via Heartbeat MoveTo + Camera/SafeClaim Guard)
local function performReturnWalk(shouldContinue)
    local startT = os.clock()
    local lastProgressZ = nil
    local lastProgressT = os.clock()
    local safeZ = getSafezoneZ()
    local safeClaimed = false

    local hbConn
    hbConn = RunService.Heartbeat:Connect(function()
        if not isScriptAlive() or not isHoldingCase() or not shouldContinue() then
            return
        end
        local hum = getHumanoid()
        local hrp = getHRP()
        if not hum or not hrp or hum.Health <= 0 or isRespawnOffer() then
            return
        end

        local cam = Workspace.CurrentCamera
        if cam and cam.CameraType ~= Enum.CameraType.Custom then
            cam.CameraType = Enum.CameraType.Custom
        end

        local targetPos = Vector3.new(POS_KICK_ZONE.X, hrp.Position.Y, POS_KICK_ZONE.Z)
        if hrp.Position.Z >= safeZ then
            if not Config.WalkSpeedEnabled then
                hum.WalkSpeed = getSafeReturnSpeed()
            end
            hum:MoveTo(targetPos)
        else
            if not Config.WalkSpeedEnabled then
                hum.WalkSpeed = getNormalWalkSpeed()
            end
            hum:MoveTo(targetPos)
            if not safeClaimed and FallRewardEvent then
                safeClaimed = true
                pcall(function()
                    FallRewardEvent:FireServer({ kind = "safeClaim" })
                end)
            end
        end
    end)

    while isScriptAlive() and isHoldingCase() and shouldContinue() and (os.clock() - startT) < 90 do
        syncNetworkGuardFlags()
        local hum = getHumanoid()
        local hrp = getHRP()
        if not hum or not hrp or hum.Health <= 0 or isRespawnOffer() then
            break
        end

        -- Re-issue safeClaim rapidly once inside Safezone until _HoldingCase clears
        local curZ = hrp.Position.Z
        if curZ < safeZ and FallRewardEvent then
            safeClaimed = true
            pcall(function()
                FallRewardEvent:FireServer({ kind = "safeClaim" })
            end)
        else
            -- Unstick / hop over stairs if forward progress stalls while far out
            if not lastProgressZ or (lastProgressZ - curZ) >= 2 then
                lastProgressZ = curZ
                lastProgressT = os.clock()
            elseif curZ > safeZ and (os.clock() - lastProgressT) > 1.0 then
                hum.Jump = true
                lastProgressT = os.clock()
            end
        end

        task.wait(0.05)
    end

    if hbConn then
        hbConn:Disconnect()
        hbConn = nil
    end

    local hum = getHumanoid()
    if hum and hum.Health > 0 and not Config.WalkSpeedEnabled then
        hum.WalkSpeed = getNormalWalkSpeed()
    end
end

-- Instant Perfect Kick Bypass (~0.13s charge -> Perfect -> launch skip)
local function performInstantPerfectKick()
    local hrp = getHRP()
    local hum = getHumanoid()
    if not hrp or not hum or hum.Health <= 0 then
        return false
    end
    if isHoldingCase() or isFlightActive() or isSpinActive() then
        return false
    end
    if isRespawnOffer() then
        closeRespawnPopup()
        task.wait(0.25)
        if isRespawnOffer() then
            return false
        end
    end

    local distToKick = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(POS_KICK_ZONE.X, 0, POS_KICK_ZONE.Z)).Magnitude
    if distToKick > 10 then
        teleportTo(POS_KICK_ZONE)
        task.wait(0.08)
    end

    local renv = getrenv and getrenv()
    local KickAuto = (renv and renv._G and renv._G.KickAuto) or _G.KickAuto
    local ready = true
    if not isInKickSession() and type(KickAuto) == "table" and type(KickAuto.state) == "function" then
        local tZone = os.clock()
        while (os.clock() - tZone) < 0.45 do
            local st = KickAuto.state()
            if st and st.inZone then
                ready = true
                break
            end
            ready = false
            task.wait(0.03)
        end
    end

    if not ready and not isInKickSession() then
        teleportTo(POS_KICK_ZONE)
        task.wait(0.08)
    end

    if RequestKick then
        launchDispatchedForKick = false
        if not isInKickSession() then
            pcall(function()
                RequestKick:FireServer({ action = "charge" })
            end)
            task.wait(0.06)
        end
        pcall(function()
            RequestKick:FireServer({ tier = "Perfect" })
        end)
        local tWait = os.clock()
        local lastRetry = os.clock()
        while isScriptAlive() and (os.clock() - tWait) < 1.2 do
            if isFlightActive() then
                dispatchLaunchBypass()
                return true
            end
            if isHoldingCase() then
                return true
            end
            if (os.clock() - lastRetry) >= 0.14 then
                lastRetry = os.clock()
                if not isInKickSession() then
                    pcall(function()
                        RequestKick:FireServer({ action = "charge" })
                    end)
                    task.wait(0.05)
                end
                pcall(function()
                    RequestKick:FireServer({ tier = "Perfect" })
                end)
            end
            task.wait(0.02)
        end
        if isFlightActive() then
            dispatchLaunchBypass()
            return true
        end
    end
    return false
end

-- Standalone Return Sprint Boost & Instant Warp Return (when MasterAutoFarm is OFF)
task.spawn(function()
    local safeZ = getSafezoneZ()
    while isScriptAlive() do
        task.wait(0.1)
        syncNetworkGuardFlags()
        if not Config.MasterAutoFarm then
            if Config.ReturnSprintBoost and isHoldingCase() then
                performReturnWalk(function()
                    return (not Config.MasterAutoFarm) and Config.ReturnSprintBoost
                end)
            end

            if Config.InstantWarpReturn and not isHoldingCase() and not isFlightActive() and not isSpinActive() and not isRespawnOffer() then
                local hum = getHumanoid()
                local hrp = getHRP()
                if hum and hrp and hum.Health > 0 then
                    local distToKick = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(POS_KICK_ZONE.X, 0, POS_KICK_ZONE.Z)).Magnitude
                    local distToCollect = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(POS_COLLECT_ZONE.X, 0, POS_COLLECT_ZONE.Z)).Magnitude
                    if hrp.Position.Z < safeZ and distToCollect < 95 and distToKick > 12 then
                        teleportTo(POS_KICK_ZONE)
                        task.wait(0.15)
                    end
                end
            end
        end
    end
end)

-- Master Auto Farm Main Loop
task.spawn(function()
    local boostFiredForFlight = false
    local fieldWaitStart = 0
    local safeZ = getSafezoneZ()
    while isScriptAlive() do
        task.wait(0.05)
        syncNetworkGuardFlags()
        if Config.MasterAutoFarm then
            local hrp = getHRP()
            local hum = getHumanoid()
            if hrp and hum and hum.Health > 0 then
                if isRespawnOffer() then
                    closeRespawnPopup()
                    task.wait(0.25)
                elseif isHoldingCase() then
                    boostFiredForFlight = false
                    fieldWaitStart = 0
                    performReturnWalk(function()
                        return Config.MasterAutoFarm
                    end)
                    -- Instant snap back to KickZone once safely deposited inside Safezone
                    hrp = getHRP()
                    if hrp and not isHoldingCase() and not isFlightActive() and not isSpinActive() and not isRespawnOffer() then
                        local distToKick = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(POS_KICK_ZONE.X, 0, POS_KICK_ZONE.Z)).Magnitude
                        if hrp.Position.Z < safeZ and distToKick > 10 then
                            teleportTo(POS_KICK_ZONE)
                        end
                    end
                elseif isFlightActive() or isSpinActive() then
                    fieldWaitStart = 0
                    -- Wait cleanly through flight until FallReward cutscene bypass hands off case
                    if isFlightActive() then
                        dispatchLaunchBypass()
                        if not boostFiredForFlight then
                            boostFiredForFlight = true
                            if BoostKick then
                                pcall(function() BoostKick:FireServer() end)
                            end
                        end
                    end
                elseif isInKickSession() and hrp.Position.Z > safeZ then
                    -- Landed in field waiting for FallRewardEvent case handoff
                    if fieldWaitStart == 0 then
                        fieldWaitStart = os.clock()
                    end
                    if FallRewardEvent and (Config.CutsceneBypass or Config.MasterAutoFarm) then
                        pcall(function()
                            FallRewardEvent:FireServer({ kind = "waveCutsceneDone" })
                        end)
                    end
                    if (os.clock() - fieldWaitStart) > 1.8 then
                        fieldWaitStart = 0
                        teleportTo(POS_KICK_ZONE)
                        performInstantPerfectKick()
                    end
                else
                    boostFiredForFlight = false
                    fieldWaitStart = 0
                    performInstantPerfectKick()
                end
            else
                boostFiredForFlight = false
                fieldWaitStart = 0
            end
        else
            boostFiredForFlight = false
            fieldWaitStart = 0
        end
    end
end)

-- ==============================================================================
-- 🎲 TAB: CASES & OPENING
-- ==============================================================================
TabCases:Section({ Title = "⚡ Fast Case Opening" })

TabCases:Toggle({
    Title = "Fast Open (Skip Animation)",
    Desc = "Completely skips case opening animations and popups",
    Default = false,
    Callback = function(v)
        Config.FastOpenSkip = v
        pcall(function()
            LocalPlayer:SetAttribute("_ShowCasesOpening", not v)
        end)
        if RequestSetSetting then
            pcall(function()
                RequestSetSetting:FireServer({ key = "ShowCasesOpening", value = not v })
            end)
        end
    end,
})

TabCases:Section({ Title = "📦 Auto Open Owned Cases" })

TabCases:Toggle({
    Title = "Auto Open All Owned Cases",
    Desc = "Loops through all owned cases in inventory and opens them",
    Default = false,
    Callback = function(v)
        Config.AutoOpenAll = v
    end,
})

TabCases:Slider({
    Title = "Open Delay (s)",
    Desc = "Delay between opening batches",
    Value = {
        Min = 0.15,
        Max = 2.0,
        Default = 0.35,
    },
    Step = 0.05,
    Callback = function(v)
        Config.CaseOpenDelay = v
    end,
})

TabCases:Section({ Title = "🎯 Target Case Opener" })

TabCases:Dropdown({
    Title = "Select Target Case",
    Values = CaseNamesList,
    Default = CaseNamesList[1] or "Basic",
    Callback = function(v)
        Config.SelectedCase = v
    end,
})

TabCases:Toggle({
    Title = "Auto Open Selected Case",
    Desc = "Continuously opens the chosen case whenever available",
    Default = false,
    Callback = function(v)
        Config.AutoOpenSelected = v
    end,
})

-- Case Opener Helper Function (Supports Regular, Event & Mutated Cases + 3x Multi-Open)
local function openCaseInstance(caseName)
    local count = getCaseCount(caseName)
    if count <= 0 then return false end

    -- Cannot open cases mid-flight
    if isFlightActive() then
        return false
    end

    -- Equip case if not already holding this exact case key
    local alreadyEquipped = false
    pcall(function()
        local char = LocalPlayer.Character
        local held = char and char:FindFirstChild("_HeldConfig")
        if held and held:GetAttribute("IsCase") == true and held:GetAttribute("CaseKey") == caseName then
            alreadyEquipped = true
        end
    end)
    if not alreadyEquipped and RequestEquipBrainrot then
        pcall(function()
            RequestEquipBrainrot:FireServer("case::" .. caseName)
        end)
        task.wait(0.06)
    end

    -- Multi-open 3x if count >= 3, 2x if count == 2, else 1x
    if count >= 3 and RequestOpenCaseMulti then
        pcall(function()
            RequestOpenCaseMulti:FireServer({ case = caseName, count = 3 })
        end)
    elseif count == 2 and RequestOpenCaseMulti then
        pcall(function()
            RequestOpenCaseMulti:FireServer({ case = caseName, count = 2 })
        end)
    elseif RequestOpenCase then
        pcall(function()
            RequestOpenCase:FireServer(caseName)
        end)
    end

    -- Dismiss reveal popup if Fast Open or Instant Reveal Bypass is enabled
    if Config.FastOpenSkip or Config.InstantRevealBypass then
        pcall(function()
            local renv = getrenv and getrenv()
            local g = (renv and renv._G) or _G
            if g then
                g._SpinGen = (tonumber(g._SpinGen) or 0) + 1
                _G._SpinGen = g._SpinGen
                if type(g.StopCaseReveal) == "function" then g.StopCaseReveal() end
                if type(g.StopCaseOpening) == "function" then g.StopCaseOpening() end
            end
        end)
    end

    return true
end

-- ==============================================================================
-- 👑 TAB: VVIP OVERDRIVE ENGINE (AI EXPEDITION • MUTATED CASES • AUTO-SELL • 0s REVEAL)
-- ==============================================================================
do
    local TabPremium = CfgSys.TabPremium
    CfgSys.OverdriveConns = {}
    local overdriveConns = CfgSys.OverdriveConns
    local RequestRevealComplete = Remotes:FindFirstChild("RequestRevealComplete")
    local AutoOpenRevealClosed = Remotes:FindFirstChild("AutoOpenRevealClosed")
    local LuckFound = Remotes:FindFirstChild("LuckFound")
    local LuckCaseClear = Remotes:FindFirstChild("LuckCaseClear")
    local SpinUIState = Remotes:FindFirstChild("SpinUIState")
    local FuseGetPets = Remotes:FindFirstChild("FuseGetPets")
    local ExpeditionSync = Remotes:FindFirstChild("ExpeditionSync")
    local ExpeditionResult = Remotes:FindFirstChild("ExpeditionResult")
    local RequestSendExpedition = Remotes:FindFirstChild("RequestSendExpedition")
    local RequestCollectExpedition = Remotes:FindFirstChild("RequestCollectExpedition")
    local SellShopRequest = Remotes:FindFirstChild("SellShopRequest")
    local RequestSlotLevelMax = Remotes:FindFirstChild("RequestSlotLevelMax")
    local RequestEventPassClaim = Remotes:FindFirstChild("RequestEventPassClaim")
    local RequestEventPassState = Remotes:FindFirstChild("RequestEventPassState")
    local EventPassSync = Remotes:FindFirstChild("EventPassSync")
    local RequestClaimPermQuest = Remotes:FindFirstChild("RequestClaimPermQuest")
    local RequestBuyGemItem = Remotes:FindFirstChild("RequestBuyGemItem")

    local ExpeditionConfig = nil
    pcall(function()
        ExpeditionConfig = require(ReplicatedStorage:WaitForChild("ExpeditionConfig", 3))
    end)

    -- Live Overdrive Telemetry
    local statsCasesSkipped = 0
    local statsCloversClaimed = 0
    local statsPetsSold = 0
    local statsCashFromSell = 0
    local statsExpeditionsSent = 0
    local statsExpeditionsClaimed = 0
    local activeExpeditions = {}
    local eventPassState = { level = 0, owned = false, freeClaimed = {}, paidClaimed = {} }
    local lastExpeditionDispatchAt = 0

    local BASE_CASE_SET = {}
    local BASE_CASE_RANK = {}
    for idx, name in ipairs(CaseNamesList) do
        BASE_CASE_SET[name] = true
        BASE_CASE_RANK[name] = idx
    end

    local function getCasePriorityScore(caseKey)
        local isMut = caseKey:find("_MUT_") ~= nil
        local baseName = isMut and caseKey:match("^(.-)_MUT_") or caseKey
        local rank = BASE_CASE_RANK[baseName] or 15
        return (isMut and 1000 or 0) + rank
    end

    local function scanOwnedCases(onlyMutatedOrEvent)
        local list = {}
        local totalBase = 0
        local totalMutOrEvent = 0
        local attrs = LocalPlayer:GetAttributes()
        for k, v in pairs(attrs) do
            if type(k) == "string" and k:sub(1, 6) == "Cases_" then
                local cnt = tonumber(v) or 0
                if cnt > 0 then
                    local caseKey = k:sub(7)
                    local isMutOrSpecial = (caseKey:find("_MUT_") ~= nil) or (not BASE_CASE_SET[caseKey])
                    if isMutOrSpecial then
                        totalMutOrEvent = totalMutOrEvent + cnt
                    else
                        totalBase = totalBase + cnt
                    end
                    if (not onlyMutatedOrEvent) or isMutOrSpecial then
                        table.insert(list, {
                            key = caseKey,
                            count = cnt,
                            score = getCasePriorityScore(caseKey),
                        })
                    end
                end
            end
        end
        table.sort(list, function(a, b)
            if a.score ~= b.score then
                return a.score > b.score
            end
            return a.count > b.count
        end)
        return list, totalBase, totalMutOrEvent
    end

    -- 1. Instant 0s Case Reveal & Auto Luck Clover Harvester Hook
    local function hideSpinOverlayCleanly()
        pcall(function()
            local renv = getrenv and getrenv()
            local g = (renv and renv._G) or _G
            if g then
                g._SpinGen = (tonumber(g._SpinGen) or 0) + 1
                _G._SpinGen = g._SpinGen
                if type(g.SetUIHidden) == "function" then
                    pcall(g.SetUIHidden, "CaseSpin", false)
                end
                if type(g._SetAutoBackdrop) == "function" then
                    pcall(g._SetAutoBackdrop, false, true)
                end
            end
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if pg then
                for _, d in ipairs(pg:GetDescendants()) do
                    if d.Name == "SpinningFrame" and d:IsA("GuiObject") then
                        d.Visible = false
                    end
                end
            end
            for _, b in ipairs(game:GetService("Lighting"):GetChildren()) do
                if b:IsA("BlurEffect") then
                    b.Size = 0
                end
            end
        end)
    end

    if CaseOpened and CaseOpened.OnClientEvent then
        local revealConn = CaseOpened.OnClientEvent:Connect(function(data)
            if not isScriptAlive() then return end
            if not (Config.InstantRevealBypass or Config.FastOpenSkip) then return end

            statsCasesSkipped = statsCasesSkipped + (tonumber(type(data) == "table" and data.Count) or 1)
            hideSpinOverlayCleanly()

            if type(data) == "table" then
                -- Harvest all Luck Clover tokens in single or 3x multi-lanes
                if LuckFound then
                    if type(data.Stages) == "table" then
                        for _, st in ipairs(data.Stages) do
                            if type(st) == "table" and type(st.Token) == "string" and st.Token ~= "" then
                                statsCloversClaimed = statsCloversClaimed + 1
                                pcall(function() LuckFound:FireServer({ Token = st.Token }) end)
                            end
                        end
                    end
                    if type(data.Rounds) == "table" then
                        for _, rd in ipairs(data.Rounds) do
                            if type(rd) == "table" and type(rd.Lanes) == "table" then
                                for _, ln in ipairs(rd.Lanes) do
                                    if type(ln) == "table" and type(ln.Stages) == "table" then
                                        for _, st in ipairs(ln.Stages) do
                                            if type(st) == "table" and type(st.Token) == "string" and st.Token ~= "" then
                                                statsCloversClaimed = statsCloversClaimed + 1
                                                pcall(function() LuckFound:FireServer({ Token = st.Token }) end)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                -- Immediately complete server reveal lock so next case opens in 0.2s instead of 8s
                if RequestRevealComplete then
                    if type(data.RevealId) == "string" and data.RevealId ~= "" then
                        pcall(function() RequestRevealComplete:FireServer({ id = data.RevealId }) end)
                    end
                    if type(data.RevealIds) == "table" and #data.RevealIds > 0 then
                        pcall(function() RequestRevealComplete:FireServer({ ids = data.RevealIds }) end)
                    end
                end
                if AutoOpenRevealClosed and type(data.RevealIds) == "table" and data.RevealIds[1] then
                    pcall(function() AutoOpenRevealClosed:FireServer({ id = data.RevealIds[1] }) end)
                end
                if LuckCaseClear then
                    pcall(function() LuckCaseClear:FireServer() end)
                end
                if SpinUIState then
                    pcall(function() SpinUIState:FireServer(false) end)
                end
            end

            task.delay(0.08, hideSpinOverlayCleanly)
            task.delay(0.25, hideSpinOverlayCleanly)
        end)
        table.insert(overdriveConns, revealConn)
    end

    -- 2. Smart AI Expedition Engine (1,500 Free Gems/Day + Bonus Brainrots)
    if ExpeditionSync and ExpeditionSync.OnClientEvent then
        local expSyncConn = ExpeditionSync.OnClientEvent:Connect(function(payload)
            if not isScriptAlive() then return end
            if type(payload) == "table" and type(payload.Expeditions) == "table" then
                activeExpeditions = payload.Expeditions
            end
        end)
        table.insert(overdriveConns, expSyncConn)
    end

    if ExpeditionResult and ExpeditionResult.OnClientEvent then
        local expResConn = ExpeditionResult.OnClientEvent:Connect(function(payload)
            if not isScriptAlive() then return end
            if type(payload) == "table" then
                if payload.kind == "send" and payload.ok then
                    statsExpeditionsSent = statsExpeditionsSent + 1
                elseif payload.kind == "collect" and payload.ok then
                    statsExpeditionsClaimed = statsExpeditionsClaimed + 1
                end
            end
        end)
        table.insert(overdriveConns, expResConn)
    end

    local function runSmartExpeditionCycle(forceNotify)
        if not ExpeditionConfig or not RequestSendExpedition or not RequestCollectExpedition then
            return false
        end

        local nowServer = os.time()
        local activeCount = 0
        for _, exp in ipairs(activeExpeditions) do
            if type(exp) == "table" and exp.id then
                local endT = tonumber(exp.endTime) or 0
                if endT > 0 and nowServer >= endT then
                    pcall(function()
                        RequestCollectExpedition:FireServer(tostring(exp.id))
                    end)
                else
                    activeCount = activeCount + 1
                end
            end
        end

        local maxActive = tonumber(ExpeditionConfig.MaxActiveExpeditions) or 2
        if activeCount >= maxActive then
            if forceNotify then
                WindUI:Notify({
                    Title = "🚀 Expeditions Running",
                    Content = string.format("กำลังส่งสำรวจครบ %d/%d ทีมแล้ว (รอเก็บเพชรอัตโนมัติ)", activeCount, maxActive),
                    Duration = 3,
                    Icon = "compass",
                })
            end
            return false
        end

        if os.clock() - lastExpeditionDispatchAt < 6.5 and not forceNotify then
            return false
        end

        local okPets, pets = pcall(function()
            return FuseGetPets and FuseGetPets:InvokeServer() or nil
        end)
        if not okPets or type(pets) ~= "table" or #pets == 0 then
            return false
        end

        -- Sort unequipped pets by ExpeditionConfig.BrainrotPower descending
        table.sort(pets, function(a, b)
            local pa = 0
            local pb = 0
            pcall(function()
                pa = ExpeditionConfig.BrainrotPower(a)
                pb = ExpeditionConfig.BrainrotPower(b)
            end)
            return pa > pb
        end)

        local maxSlots = tonumber(ExpeditionConfig.FreeBrainrotSlots) or 2
        local chosenTeam = {}
        local chosenUids = {}
        for i = 1, math.min(maxSlots, #pets) do
            if pets[i] and pets[i].uid then
                table.insert(chosenTeam, pets[i])
                table.insert(chosenUids, pets[i].uid)
            end
        end
        if #chosenUids == 0 then
            return false
        end

        local teamPower = 0
        pcall(function()
            teamPower = ExpeditionConfig.TeamPower(chosenTeam)
        end)

        local rebirths = tonumber(LocalPlayer:GetAttribute("Rebirths")) or 0
        local bestDestKey = ExpeditionConfig.DefaultDestKey or "forest"
        for _, dest in ipairs(ExpeditionConfig.Destinations or {}) do
            local dKey = dest.key
            local unlocked = false
            pcall(function()
                unlocked = ExpeditionConfig.IsDestinationUnlocked(dKey, rebirths)
            end)
            if unlocked then
                bestDestKey = dKey
            end
        end

        local durKey = (Config.ExpeditionDuration == "Long (8x Gems)") and "long" or "fast"
        local riskKey = "safe"
        if Config.ExpeditionStrategy == "Safe (97% Win)" then
            riskKey = "safe"
        elseif Config.ExpeditionStrategy == "Risky (2.2x Gems)" then
            riskKey = "risky"
        elseif Config.ExpeditionStrategy == "Insane (4.5x Gems)" then
            riskKey = "insane"
        else
            -- Smart Best EV (Auto Win%): pick highest expected gems with solid win rate
            local bestScore = -1
            for _, rKey in ipairs({ "safe", "risky", "insane" }) do
                local winChance = 0.5
                local promised = 100
                pcall(function()
                    winChance = ExpeditionConfig.SuccessChance(rKey, teamPower, bestDestKey, #chosenTeam, durKey)
                    promised = ExpeditionConfig.PromisedGems(teamPower, durKey, rKey, bestDestKey)
                end)
                local failFrac = (rKey == "safe" and 0.5) or (rKey == "risky" and 0.3) or 0.1
                local ev = promised * (winChance + (1 - winChance) * failFrac)
                if winChance >= 0.65 and ev > bestScore then
                    bestScore = ev
                    riskKey = rKey
                end
            end
        end

        lastExpeditionDispatchAt = os.clock()
        pcall(function()
            RequestSendExpedition:FireServer({
                uids = chosenUids,
                durationKey = durKey,
                riskKey = riskKey,
                destKey = bestDestKey,
            })
        end)

        if forceNotify then
            WindUI:Notify({
                Title = "🚀 ส่งทีมสำรวจสำเร็จ!",
                Content = string.format("ด่าน: %s • โหมด: %s (%s) • สัตว์ %d ตัว", tostring(bestDestKey):upper(), tostring(riskKey):upper(), tostring(durKey):upper(), #chosenUids),
                Duration = 3.5,
                Icon = "rocket",
            })
        end
        return true
    end

    -- 3. Smart Auto-Sell Junk Brainrots (Anywhere on Map)
    local RARITY_ORDER_LIST = {
        "Common",
        "Uncommon",
        "Rare",
        "Epic",
        "Legendary",
        "Mythic",
        "Godly",
        "Secret",
        "BrainrotGod",
        "Celestial",
    }
    local RARITY_LABEL_TO_INDEX = {
        ["Up to Rare"] = 3,
        ["Up to Epic"] = 4,
        ["Up to Legendary"] = 5,
        ["Up to Mythic"] = 6,
        ["Up to Godly"] = 7,
        ["Up to Secret"] = 8,
        ["Up to BrainrotGod"] = 9,
        ["Up to Celestial"] = 10,
    }

    local function runAutoSellJunk(forceNotify)
        if not SellShopRequest then return false end
        local maxIdx = RARITY_LABEL_TO_INDEX[Config.AutoSellMaxRarity] or 6
        local raritiesToSell = {}
        for i = 1, maxIdx do
            table.insert(raritiesToSell, RARITY_ORDER_LIST[i])
        end
        local ok, res = pcall(function()
            return SellShopRequest:InvokeServer({
                kind = "brainrotAll",
                rarities = raritiesToSell,
            })
        end)
        if ok and type(res) == "table" and res.ok then
            local soldCnt = tonumber(res.count) or 0
            local soldPrice = tonumber(res.price) or 0
            if soldCnt > 0 then
                statsPetsSold = statsPetsSold + soldCnt
                statsCashFromSell = statsCashFromSell + soldPrice
                if forceNotify then
                    WindUI:Notify({
                        Title = "🧹 ขายสัตว์ขยะสำเร็จ!",
                        Content = string.format("ขายไป %d ตัว (%s) ได้เงิน +$%s", soldCnt, tostring(Config.AutoSellMaxRarity), tostring(soldPrice)),
                        Duration = 3,
                        Icon = "trash-2",
                    })
                end
                return true
            elseif forceNotify then
                WindUI:Notify({
                    Title = "🧹 กระเป๋าสะอาดแล้ว!",
                    Content = "ไม่มีสัตว์ระดับต่ำกว่าที่ตั้งไว้ในกระเป๋า",
                    Duration = 2.5,
                    Icon = "check-circle",
                })
            end
        end
        return false
    end

    -- 4. Event Pass & Perm Quest Auto-Claimer + Gem Boost Buyer
    if EventPassSync and EventPassSync.OnClientEvent then
        local epConn = EventPassSync.OnClientEvent:Connect(function(state)
            if not isScriptAlive() then return end
            if type(state) == "table" then
                eventPassState.level = tonumber(state.level) or eventPassState.level
                eventPassState.owned = state.owned == true
                if type(state.freeClaimed) == "table" then eventPassState.freeClaimed = state.freeClaimed end
                if type(state.paidClaimed) == "table" then eventPassState.paidClaimed = state.paidClaimed end
            end
        end)
        table.insert(overdriveConns, epConn)
    end
    if RequestEventPassState then
        task.defer(function()
            pcall(function() RequestEventPassState:FireServer() end)
        end)
    end

    local GEM_BOOST_MAP = {
        ["2x Luck (150 Gems)"] = { key = "GemLuck2x", btn = 1, cost = 150 },
        ["4x Luck (500 Gems)"] = { key = "GemLuck4x", btn = 1, cost = 500 },
        ["8x Luck (1000 Gems)"] = { key = "GemLuck8x", btn = 1, cost = 1000 },
        ["2x Strength (150 Gems)"] = { key = "GemStrength2x", btn = 1, cost = 150 },
        ["4x Strength (500 Gems)"] = { key = "GemStrength4x", btn = 1, cost = 500 },
        ["8x Strength (1000 Gems)"] = { key = "GemStrength8x", btn = 1, cost = 1000 },
    }

    -- Build VVIP Overdrive Tab UI
    TabPremium:Section({ Title = "👑 VVIP Overdrive Telemetry (สถานะระบบอัจฉริยะ)" })

    local overdriveStatusParagraph = TabPremium:Paragraph({
        Title = "📊 Live Overdrive Monitor",
        Desc = "กำลังซิงค์ข้อมูลกระเป๋า, กล่องกลายพันธุ์ และทีมสำรวจเพชร...",
    })

    local function updateOverdriveTelemetry()
        pcall(function()
            if not overdriveStatusParagraph or not overdriveStatusParagraph.SetDesc then return end
            local _, baseCnt, mutCnt = scanOwnedCases(false)
            local gems = tonumber(LocalPlayer:GetAttribute("Gems")) or 0
            local expToday = tonumber(LocalPlayer:GetAttribute("ExpGemsToday")) or 0
            local reb = tonumber(LocalPlayer:GetAttribute("Rebirths")) or 0
            local line1 = string.format("📦 กล่องทั่วไป: %d ใบ | 🧬 กล่องกลายพันธุ์/อีเวนต์: %d ใบ", baseCnt, mutCnt)
            local line2 = string.format("💎 เพชรทั้งหมด: %d | 🚀 เพชรสำรวจวันนี้: %d/1,500 (ทีมสำรวจ: %d/2)", gems, expToday, #activeExpeditions)
            local line3 = string.format("⚡ ข้ามอนิเมชันเปิดกล่อง: %d ใบ (เก็บใบโคลเวอร์ Luck: %d) | 🧹 ขายสัตว์ขยะ: %d ตัว (Rebirths: %d)", statsCasesSkipped, statsCloversClaimed, statsPetsSold, reb)
            overdriveStatusParagraph:SetDesc(line1 .. "\n" .. line2 .. "\n" .. line3)
        end)
    end

    TabPremium:Section({ Title = "🧬 Hyper Case & Mutation Overdrive (เปิดกล่องกลายพันธุ์ 0 วินาที)" })

    TabPremium:Toggle({
        Title = "Instant 0s Reveal & Auto Luck Clover",
        Desc = "ข้ามวงล้อสุ่มกล่อง 8 วินาทียกชุดทันที + เก็บเหรียญโคลเวอร์เพิ่มดวง (Luck Token) ในกล่องให้อัตโนมัติ 100%",
        Default = false,
        Callback = function(v)
            Config.InstantRevealBypass = v
            if v then
                hideSpinOverlayCleanly()
            end
        end,
    })

    TabPremium:Toggle({
        Title = "Auto Open All Mutated & Event Cases (3x)",
        Desc = "สแกนและเปิดกล่องกลายพันธุ์ทุกธาตุ (Lightning, Plasma, Wet, Bubblegum, Lava, Frozen ฯลฯ) และกล่องอีเวนต์แบบ 3x อัตโนมัติ",
        Default = false,
        Callback = function(v)
            Config.AutoOpenMutatedCases = v
        end,
    })

    TabPremium:Button({
        Title = "🧬 Open All Mutated & Event Cases Now (เปิดกล่องกลายพันธุ์ทันที)",
        Callback = function()
            task.spawn(function()
                local mutList = scanOwnedCases(true)
                if #mutList == 0 then
                    WindUI:Notify({
                        Title = "🧬 ไม่พบกล่องกลายพันธุ์",
                        Content = "ตอนนี้ไม่มีกล่องกลายพันธุ์หรือกล่องอีเวนต์ในกระเป๋า",
                        Duration = 2.5,
                        Icon = "info",
                    })
                    return
                end
                local prevBypass = Config.InstantRevealBypass
                Config.InstantRevealBypass = true
                local openedStacks = 0
                for _, item in ipairs(mutList) do
                    if isFlightActive() then break end
                    if openCaseInstance(item.key) then
                        openedStacks = openedStacks + 1
                        task.wait(0.24)
                    end
                end
                Config.InstantRevealBypass = prevBypass
                updateOverdriveTelemetry()
                WindUI:Notify({
                    Title = "🧬 เปิดกล่องกลายพันธุ์สำเร็จ!",
                    Content = string.format("สั่งเปิดกล่องกลายพันธุ์/อีเวนต์ไป %d ชุดเรียบร้อย", openedStacks),
                    Duration = 3,
                    Icon = "sparkles",
                })
            end)
        end,
    })

    TabPremium:Section({ Title = "🚀 Smart AI Auto-Expedition (ฟาร์มเพชรฟรี 1,500 Gems/วัน)" })

    TabPremium:Toggle({
        Title = "Smart AI Auto-Expedition (1,500 Gems/Day)",
        Desc = "คำนวณพลังสัตว์และส่งทีมที่เก่งที่สุดในกระเป๋าไปสำรวจด่านสูงสุด + กดรับเพชรและสัตว์โบนัสอัตโนมัติจากทุกที่ในแมพ",
        Default = false,
        Callback = function(v)
            Config.AutoSmartExpedition = v
            if v then
                task.spawn(function()
                    runSmartExpeditionCycle(false)
                end)
            end
        end,
    })

    TabPremium:Dropdown({
        Title = "Expedition Risk Strategy",
        Values = {
            "Smart Best EV (Auto Win%)",
            "Safe (97% Win)",
            "Risky (2.2x Gems)",
            "Insane (4.5x Gems)",
        },
        Default = "Smart Best EV (Auto Win%)",
        Callback = function(v)
            Config.ExpeditionStrategy = v
        end,
    })

    TabPremium:Dropdown({
        Title = "Expedition Duration",
        Values = { "Fast (1-1.7h)", "Long (8x Gems)" },
        Default = "Fast (1-1.7h)",
        Callback = function(v)
            Config.ExpeditionDuration = v
        end,
    })

    TabPremium:Button({
        Title = "🚀 Dispatch & Claim Expedition Now (ส่งสำรวจ/รับเพชรทันที)",
        Callback = function()
            task.spawn(function()
                runSmartExpeditionCycle(true)
                updateOverdriveTelemetry()
            end)
        end,
    })

    TabPremium:Section({ Title = "🧹 Smart Auto-Sell & 1-Click Max Level (จัดการฐานและกระเป๋า)" })

    TabPremium:Toggle({
        Title = "Smart Auto-Sell Junk Brainrots (Anywhere)",
        Desc = "ขายสัตว์ขยะที่ไม่ได้วางในฐานอัตโนมัติจากทุกที่ในแมพ (ป้องกันกระเป๋า 2,000 ช่องเต็มตอนเปิดกล่องรัวๆ)",
        Default = false,
        Callback = function(v)
            Config.AutoSellJunkPets = v
            if v then
                task.spawn(function()
                    runAutoSellJunk(false)
                end)
            end
        end,
    })

    TabPremium:Dropdown({
        Title = "Auto-Sell Max Rarity Filter",
        Values = {
            "Up to Rare",
            "Up to Epic",
            "Up to Legendary",
            "Up to Mythic",
            "Up to Godly",
            "Up to Secret",
            "Up to BrainrotGod",
            "Up to Celestial",
        },
        Default = "Up to Mythic",
        Callback = function(v)
            Config.AutoSellMaxRarity = v
        end,
    })

    TabPremium:Button({
        Title = "🧹 Clean & Sell Junk Brainrots Now (ล้างสัตว์ขยะทันที)",
        Callback = function()
            task.spawn(function()
                runAutoSellJunk(true)
                updateOverdriveTelemetry()
            end)
        end,
    })

    TabPremium:Toggle({
        Title = "1-Click Max Level Units (Lv.1 -> Lv.100)",
        Desc = "อัปเกรดสัตว์ในฐานแบบข้ามขั้นถึงเลเวลสูงสุดที่เงินพอในคลิกเดียว (RequestSlotLevelMax)",
        Default = false,
        Callback = function(v)
            Config.InstantMaxLevelUnits = v
        end,
    })

    TabPremium:Button({
        Title = "⚡ Max-Level All Placed Units Now (อัปสัตว์ทุกตัวให้ตันทันที)",
        Callback = function()
            task.spawn(function()
                if not RequestSlotLevelMax then return end
                local fired = 0
                for slotIdx = 1, 30 do
                    pcall(function()
                        RequestSlotLevelMax:FireServer({ slot = slotIdx })
                        fired = fired + 1
                    end)
                    task.wait(0.03)
                end
                WindUI:Notify({
                    Title = "⚡ Max-Level Dispatched!",
                    Content = "สั่งอัปเลเวลสูงสุดให้สัตว์ทุกช่องในฐานเรียบร้อย!",
                    Duration = 2.5,
                    Icon = "zap",
                })
            end)
        end,
    })

    TabPremium:Section({ Title = "💎 Auto Event Pass, Perm Quests & Gem Boosts" })

    TabPremium:Toggle({
        Title = "Auto Claim Event Pass & Perm Quests",
        Desc = "รับของรางวัล Battlepass (Event Pass) ทุกเลเวลและเควสต์ถาวร (Velociraptor) อัตโนมัติ",
        Default = false,
        Callback = function(v)
            Config.AutoClaimEventPass = v
        end,
    })

    TabPremium:Toggle({
        Title = "Auto Buy Gem Shop Boosts",
        Desc = "ใช้เพชรซื้อบัฟคูณดวงเปิดกล่อง (Luck) หรือคูณพลังยกเวท (Strength) อัตโนมัติ",
        Default = false,
        Callback = function(v)
            Config.AutoBuyGemBoost = v
        end,
    })

    TabPremium:Dropdown({
        Title = "Target Gem Boost",
        Values = {
            "2x Luck (150 Gems)",
            "4x Luck (500 Gems)",
            "8x Luck (1000 Gems)",
            "2x Strength (150 Gems)",
            "4x Strength (500 Gems)",
            "8x Strength (1000 Gems)",
        },
        Default = "2x Luck (150 Gems)",
        Callback = function(v)
            Config.SelectedGemBoost = v
        end,
    })

    -- Background Workers for VVIP Overdrive
    task.spawn(function()
        local lastSellAt = 0
        local lastExpAt = 0
        local lastPassAt = 0
        local lastBoostAt = 0
        while isScriptAlive() do
            task.wait(1.0)
            updateOverdriveTelemetry()

            local now = os.clock()
            if Config.AutoSmartExpedition and (now - lastExpAt) >= 5.0 then
                lastExpAt = now
                pcall(runSmartExpeditionCycle, false)
            end

            if Config.AutoSellJunkPets and (now - lastSellAt) >= 6.0 then
                lastSellAt = now
                pcall(runAutoSellJunk, false)
            end

            if Config.AutoClaimEventPass and (now - lastPassAt) >= 8.0 then
                lastPassAt = now
                pcall(function()
                    if RequestEventPassState then
                        RequestEventPassState:FireServer()
                    end
                    if RequestEventPassClaim then
                        local maxLvl = math.max(tonumber(eventPassState.level) or 0, 30)
                        for lvl = 1, maxLvl do
                            if not eventPassState.freeClaimed[tostring(lvl)] then
                                RequestEventPassClaim:FireServer("Free", lvl)
                            end
                            if eventPassState.owned and not eventPassState.paidClaimed[tostring(lvl)] then
                                RequestEventPassClaim:FireServer("Paid", lvl)
                            end
                        end
                    end
                    if RequestClaimPermQuest then
                        RequestClaimPermQuest:InvokeServer({})
                    end
                end)
            end

            if Config.AutoBuyGemBoost and RequestBuyGemItem and (now - lastBoostAt) >= 35.0 then
                local boostCfg = GEM_BOOST_MAP[Config.SelectedGemBoost]
                local curGems = tonumber(LocalPlayer:GetAttribute("Gems")) or 0
                if boostCfg and curGems >= boostCfg.cost then
                    lastBoostAt = now
                    pcall(function()
                        RequestBuyGemItem:FireServer({ key = boostCfg.key, btn = boostCfg.btn })
                    end)
                end
            end
        end
    end)

    -- Expose scanOwnedCases on CfgSys so AutoOpenAll can also open Mutated & Event cases!
    CfgSys.ScanOwnedCases = scanOwnedCases
end

-- Auto Case Opener Background Worker (Upgraded with Mutated & Event Case Scanner)
task.spawn(function()
    while isScriptAlive() do
        task.wait(0.12)
        if (Config.AutoOpenSelected or Config.AutoOpenAll or Config.AutoOpenMutatedCases) and not isFlightActive() then
            local delaySec = (Config.InstantRevealBypass or Config.FastOpenSkip)
                and math.min(tonumber(Config.CaseOpenDelay) or 0.25, 0.25)
                or (tonumber(Config.CaseOpenDelay) or 0.35)

            if Config.AutoOpenSelected and Config.SelectedCase then
                if openCaseInstance(Config.SelectedCase) then
                    task.wait(delaySec)
                else
                    task.wait(0.4)
                end
            elseif Config.AutoOpenMutatedCases and not Config.AutoOpenAll then
                local mutList = CfgSys.ScanOwnedCases and CfgSys.ScanOwnedCases(true) or {}
                if #mutList > 0 then
                    for _, item in ipairs(mutList) do
                        if not Config.AutoOpenMutatedCases or isFlightActive() then break end
                        if openCaseInstance(item.key) then
                            task.wait(delaySec)
                        end
                    end
                else
                    task.wait(0.6)
                end
            elseif Config.AutoOpenAll then
                local allList = CfgSys.ScanOwnedCases and CfgSys.ScanOwnedCases(false) or {}
                if #allList > 0 then
                    for _, item in ipairs(allList) do
                        if not Config.AutoOpenAll or isFlightActive() then break end
                        if openCaseInstance(item.key) then
                            task.wait(delaySec)
                        end
                    end
                else
                    task.wait(0.6)
                end
            end
        end
    end
end)

-- Fast Open Attribute Enforcer
task.spawn(function()
    while true do
        task.wait(1.5)
        if Config.FastOpenSkip then
            pcall(function()
                if LocalPlayer:GetAttribute("_ShowCasesOpening") ~= false then
                    LocalPlayer:SetAttribute("_ShowCasesOpening", false)
                end
            end)
        end
    end
end)

-- ==============================================================================
-- ⚡ TAB: AUTO UPGRADES
-- ==============================================================================
local trainBonusConn = nil
local osuTrainConn = nil
local pendingOsuCircles = {}
local lastOsuHitAt = 0
local lastHotbarSelectAt = 0
local sbOfferActive = false

local function getEquippedWeightTool()
    local char = LocalPlayer.Character
    if not char then
        return nil
    end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") and child:GetAttribute("_IsWeightTool") then
            return child
        end
    end
    return nil
end

local function findHotbarWeightSlot()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local gameGui = pg and pg:FindFirstChild("Game")
    local hud = gameGui and gameGui:FindFirstChild("HUD")
    local hudFrame = hud and hud:FindFirstChild("HUDFrame")
    local invBottom = hudFrame and hudFrame:FindFirstChild("InventoryBottom")
    local slotsLayout = invBottom and invBottom:FindFirstChild("SlotsLayout")
    if not slotsLayout then
        return nil
    end

    local slotButtons = {}
    for _, child in ipairs(slotsLayout:GetChildren()) do
        if child:IsA("GuiObject") then
            table.insert(slotButtons, child)
        end
    end
    table.sort(slotButtons, function(a, b)
        return a.LayoutOrder < b.LayoutOrder
    end)

    for idx, btn in ipairs(slotButtons) do
        local weightLabel = btn:FindFirstChild("WeightName", true)
        if weightLabel and weightLabel:IsA("TextLabel") and weightLabel.Text ~= "" then
            local orderLabel = btn:FindFirstChild("OrderNumber", true)
            local orderNum = orderLabel and orderLabel:IsA("TextLabel") and tonumber(orderLabel.Text)
            return orderNum or idx
        end
    end
    return nil
end

local function equipWeightInHand()
    local now = os.clock()
    if now - lastHotbarSelectAt < 0.75 then
        return false
    end
    lastHotbarSelectAt = now

    local slot = findHotbarWeightSlot()
    if RequestSelectHotbar and slot then
        if LocalPlayer:GetAttribute("ActiveHotbar") == slot and not getEquippedWeightTool() then
            pcall(function()
                RequestSelectHotbar:FireServer(0)
            end)
            task.wait(0.08)
        end
        pcall(function()
            RequestSelectHotbar:FireServer(slot)
        end)
        return true
    end

    if type(_G.HoldFirstWeight) == "function" then
        local ok, res = pcall(_G.HoldFirstWeight)
        if ok and res == true then
            return true
        end
    end
    return false
end

local function tryClaimStrengthBonus()
    if not (isScriptAlive() and Config.AutoTrainX2 and StrengthBonus) then
        return
    end
    sbOfferActive = false
    pcall(function()
        StrengthBonus:FireServer({ kind = "claim" })
    end)
end

local function hasVisibleStrengthBonusButton()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local ku = pg and pg:FindFirstChild("KickUpgrades")
    if not ku then
        return false
    end
    for _, child in ipairs(ku:GetChildren()) do
        if child:IsA("GuiObject") and child.Name ~= "Bonus" and child.Name ~= "PopBonus" and child.Name ~= "_PopBonusFly" and child.Visible then
            return true
        end
    end
    return false
end

local function scheduleOsuHit(circleId, spawnAt, life)
    local id = tonumber(circleId)
    local info = id and pendingOsuCircles[id]
    if not info or info.scheduled or not OsuTrain then
        return
    end
    info.scheduled = true
    local safeLife = math.max(0.25, tonumber(life) or 1.5)
    local elapsed = math.max(0, os.clock() - (spawnAt or os.clock()))
    -- APPROACH_AT = 0.7 gives PERFECT! hits within PERFECT_WINDOW while guarding MIN_HIT_INTERVAL (0.09s)
    local idealDelay = math.clamp(safeLife * 0.7 - elapsed, 0, math.max(0.05, safeLife - elapsed - 0.12))

    task.delay(idealDelay, function()
        if not isScriptAlive() or not Config.AutoTrainX2 or not OsuTrain then
            if pendingOsuCircles[id] then
                pendingOsuCircles[id].scheduled = false
            end
            return
        end
        if not pendingOsuCircles[id] then
            return
        end
        local gap = os.clock() - lastOsuHitAt
        if gap < 0.105 then
            task.wait(0.105 - gap)
        end
        if not isScriptAlive() or not Config.AutoTrainX2 or not pendingOsuCircles[id] or not OsuTrain then
            if pendingOsuCircles[id] then
                pendingOsuCircles[id].scheduled = false
            end
            return
        end
        lastOsuHitAt = os.clock()
        pendingOsuCircles[id] = nil
        pcall(function()
            OsuTrain:FireServer({ kind = "hit", id = id })
        end)
    end)
end

if StrengthBonus then
    trainBonusConn = StrengthBonus.OnClientEvent:Connect(function(payload)
        if not isScriptAlive() then
            if trainBonusConn then
                trainBonusConn:Disconnect()
                trainBonusConn = nil
            end
            return
        end
        if type(payload) ~= "table" then
            return
        end
        if payload.kind == "offer" then
            sbOfferActive = true
            if Config.AutoTrainX2 then
                task.delay(0.05, function()
                    if isScriptAlive() and Config.AutoTrainX2 and sbOfferActive then
                        tryClaimStrengthBonus()
                    end
                end)
            end
        elseif payload.kind == "hide" or payload.kind == "claimed" then
            sbOfferActive = false
        end
    end)
end

if OsuTrain then
    osuTrainConn = OsuTrain.OnClientEvent:Connect(function(payload)
        if not isScriptAlive() then
            if osuTrainConn then
                osuTrainConn:Disconnect()
                osuTrainConn = nil
            end
            return
        end
        if type(payload) ~= "table" then
            return
        end
        local kind = payload.kind
        if kind == "start" or kind == "stop" then
            table.clear(pendingOsuCircles)
        elseif kind == "spawn" and payload.id then
            local id = tonumber(payload.id)
            if id then
                local now = os.clock()
                local life = tonumber(payload.life) or 1.5
                pendingOsuCircles[id] = { spawnAt = now, life = life }
                if Config.AutoTrainX2 then
                    scheduleOsuHit(id, now, life)
                end
            end
        elseif (kind == "hit" or kind == "miss") and payload.id then
            local id = tonumber(payload.id)
            if id then
                pendingOsuCircles[id] = nil
            end
        end
    end)
end

-- ==============================================================================
-- ⬆️ TAB: UPGRADES & STATS
-- ==============================================================================
local slotSignCache = {}
local slotSignCachePlot = nil
local pendingBaseCash = 0
local lastUpgradedSlot = nil
local upgradePendingUntil = 0
local equipBestLastFire = 0

local function getMyPlot()
    local plotIdx = LocalPlayer:GetAttribute("BasePlot")
    if plotIdx == nil then
        return nil, nil
    end
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then
        local mapFolder = Workspace:FindFirstChild("Map")
        plots = mapFolder and mapFolder:FindFirstChild("Plots")
    end
    local plot = plots and plots:FindFirstChild("Plot" .. tostring(plotIdx))
    return plot, plotIdx
end

local function tryEquipBestUnits(force)
    if not BasePetsRequest or not isScriptAlive() then
        return false
    end
    local now = os.clock()
    if not force and (now - equipBestLastFire) < 1.8 then
        return false
    end
    equipBestLastFire = now
    pcall(function()
        BasePetsRequest:FireServer("PlaceBest")
    end)
    if RequestSlotSignSync then
        task.delay(0.35, function()
            if isScriptAlive() then
                pcall(function()
                    RequestSlotSignSync:FireServer()
                end)
            end
        end)
    end
    return true
end

local function getPendingCollectCash(plot)
    if pendingBaseCash > 0 then
        return pendingBaseCash
    end
    if not plot then
        return 0
    end
    local ca = plot:FindFirstChild("Collect All")
    local infoGui = ca and ca:FindFirstChild("InfoGUI")
    local textLabels = infoGui and infoGui:FindFirstChild("TextLabels")
    local moneyLbl = textLabels and textLabels:FindFirstChild("Money")
    if moneyLbl and moneyLbl:IsA("TextLabel") then
        return parseCash(moneyLbl.Text)
    end
    return 0
end

local function performAutoCollectStep()
    local plot, plotIdx = getMyPlot()
    if not plot or not plotIdx then
        return
    end
    if LocalPlayer:GetAttribute("Flag_AutoCollect") == true and RequestBasePad then
        if getPendingCollectCash(plot) <= 0 then
            return
        end
        pcall(function()
            local renv = getrenv and getrenv()
            local mc = (renv and renv._G and renv._G.MoneyController) or _G.MoneyController
            if type(mc) == "table" and type(mc.SilenceCollects) == "function" then
                mc.SilenceCollects(2.5)
            end
        end)
        pcall(function()
            RequestBasePad:FireServer("Collect", true)
        end)
        pendingBaseCash = 0
        return
    end

    -- Fallback for players without Flag_AutoCollect: collect nearby non-$0 floor plates
    if not RequestCollect then
        return
    end
    local hrp = getHRP()
    local floors = plot:FindFirstChild("Floors")
    if not hrp or not floors then
        return
    end
    for _, fl in ipairs(floors:GetChildren()) do
        local sm = fl:FindFirstChild("SlotModels")
        if sm then
            for _, slotFolder in ipairs(sm:GetChildren()) do
                local slotNum = tonumber(slotFolder.Name)
                local unitModel = slotFolder:FindFirstChildOfClass("Model")
                local pad = unitModel and unitModel:FindFirstChild("Slot1")
                if slotNum and pad and pad:IsA("BasePart") and (hrp.Position - pad.Position).Magnitude <= 58 then
                    local sg = pad:FindFirstChildOfClass("SurfaceGui")
                    local tl = sg and sg:FindFirstChildOfClass("TextLabel")
                    if tl and type(tl.Text) == "string" and tl.Text ~= "" and tl.Text ~= "$0" then
                        pcall(function()
                            RequestCollect:FireServer(plotIdx, slotNum)
                        end)
                    end
                end
            end
        end
    end
end

local function computeUnitIncome(cfg)
    local stat = tonumber(cfg:GetAttribute("Stat")) or 0
    if stat <= 0 and BrainrotData and type(BrainrotData.ComputeStat) == "function" then
        local ok, computed = pcall(
            BrainrotData.ComputeStat,
            cfg:GetAttribute("Name"),
            cfg:GetAttribute("Mutation") or "None",
            cfg:GetAttribute("Variant") or "None",
            cfg:GetAttribute("NeonTier") or 0
        )
        stat = ok and (tonumber(computed) or 0) or 0
    end
    local lv = math.clamp(math.floor(tonumber(cfg:GetAttribute("Level")) or 1), 1, 100)
    local rebirthMult = tonumber(LocalPlayer:GetAttribute("RebirthMult")) or 1
    return stat * (1.247 ^ math.max(0, lv - 1)) * rebirthMult
end

local function findBestUnitUpgradeSlot(plot, plotIdx)
    if not plot then
        return nil
    end
    if slotSignCachePlot ~= plotIdx then
        slotSignCachePlot = plotIdx
        table.clear(slotSignCache)
    end
    local slotConfigs = plot:FindFirstChild("SlotConfigs")
    if not slotConfigs then
        return nil
    end

    local cash = getPlayerCash()
    local priority = Config.UnitUpgradePriority
    local bestSlot = nil
    local bestScore = -math.huge
    local bestIncome = -1

    for _, cfg in ipairs(slotConfigs:GetChildren()) do
        if cfg:IsA("Configuration") then
            local slotNum = tonumber(cfg.Name)
            local name = cfg:GetAttribute("Name")
            local sync = slotNum and slotSignCache[slotNum]
            if slotNum and type(name) == "string" and name ~= "" and type(sync) == "table" then
                local lv = math.floor(tonumber(cfg:GetAttribute("Level")) or tonumber(sync.level) or 1)
                local isFree = (sync.free == true)
                local cost = isFree and 0 or tonumber(sync.nextCost)
                local eligible = (lv < 100) and (sync.max ~= true) and (sync.paid ~= true)
                    and (isFree or (type(cost) == "number" and cost <= cash))
                if eligible then
                    local inc = computeUnitIncome(cfg)
                    local score
                    if priority == "Lowest Cost First" then
                        score = -cost
                    elseif priority == "Highest $/s First" then
                        score = inc
                    else
                        score = (isFree or cost <= 0) and (1e30 + inc) or ((inc * 0.247) / cost)
                    end
                    if score > bestScore or (score == bestScore and inc > bestIncome) then
                        bestScore = score
                        bestIncome = inc
                        bestSlot = slotNum
                    end
                end
            end
        end
    end
    return bestSlot
end

local slotSignSyncConn = SlotSignSync and SlotSignSync.OnClientEvent:Connect(function(data)
    if not isScriptAlive() then
        if slotSignSyncConn then slotSignSyncConn:Disconnect(); slotSignSyncConn = nil end
        return
    end
    if type(data) == "table" and type(data.slot) == "number" then
        local myPlotIdx = LocalPlayer:GetAttribute("BasePlot")
        if data.plot ~= nil and data.plot ~= myPlotIdx then
            return
        end
        if slotSignCachePlot ~= myPlotIdx then
            slotSignCachePlot = myPlotIdx
            table.clear(slotSignCache)
        end
        slotSignCache[data.slot] = data
        if lastUpgradedSlot == data.slot then
            upgradePendingUntil = 0
        end
    end
end)

local baseLevelResultConn = BaseLevelResult and BaseLevelResult.OnClientEvent:Connect(function(data)
    if not isScriptAlive() then
        if baseLevelResultConn then baseLevelResultConn:Disconnect(); baseLevelResultConn = nil end
        return
    end
    if type(data) == "table" and data.slot and data.slot == lastUpgradedSlot then
        upgradePendingUntil = 0
    end
end)

local basePadInfoConn = BasePadInfo and BasePadInfo.OnClientEvent:Connect(function(val)
    if not isScriptAlive() then
        if basePadInfoConn then basePadInfoConn:Disconnect(); basePadInfoConn = nil end
        return
    end
    pendingBaseCash = math.max(0, tonumber(val) or 0)
end)

local equipTriggerConns = {}
for _, evt in ipairs({ CaseOpened, ItemObtained }) do
    if evt and evt.OnClientEvent then
        local c
        c = evt.OnClientEvent:Connect(function()
            if not isScriptAlive() then
                if c then c:Disconnect() end
                return
            end
            if Config.AutoEquipBest then
                task.delay(0.35, function()
                    if isScriptAlive() and Config.AutoEquipBest then
                        tryEquipBestUnits(false)
                    end
                end)
            end
        end)
        table.insert(equipTriggerConns, c)
    end
end

TabUpgrades:Section({ Title = "🏠 Base Units, Money & Upgrades" })

TabUpgrades:Toggle({
    Title = "Auto Equip Best Units (Place Best)",
    Desc = "Automatically places your highest $/s brainrots onto base slots cleanly (no popup spam)",
    Default = false,
    Callback = function(v)
        Config.AutoEquipBest = v
        if v then
            task.spawn(function()
                tryEquipBestUnits(true)
            end)
        end
    end,
})

TabUpgrades:Toggle({
    Title = "Auto Collect Money (Base Cash)",
    Desc = "Automatically collects all generated cash from your base from anywhere on the map",
    Default = false,
    Callback = function(v)
        Config.AutoCollectMoney = v
        if v then
            task.spawn(performAutoCollectStep)
        end
    end,
})

TabUpgrades:Toggle({
    Title = "Auto Upgrade Units (Level Up Best)",
    Desc = "Automatically levels up placed brainrots using the selected upgrade priority",
    Default = false,
    Callback = function(v)
        Config.AutoUpgradeUnits = v
        if v and RequestSlotSignSync then
            pcall(function() RequestSlotSignSync:FireServer() end)
        end
    end,
})

TabUpgrades:Dropdown({
    Title = "Unit Upgrade Priority",
    Values = { "Best ROI ($/s per $)", "Highest $/s First", "Lowest Cost First" },
    Default = "Best ROI ($/s per $)",
    Callback = function(v)
        Config.UnitUpgradePriority = v
    end,
})

TabUpgrades:Section({ Title = "💪 Auto Train & X2 Bonus" })

TabUpgrades:Toggle({
    Title = "Auto Train (Auto Lift Barbell)",
    Desc = "Auto-equips barbell & lifts rapidly for Strength and 3x Aura (auto-pauses while farming cases)",
    Default = false,
    Callback = function(v)
        Config.AutoTrain = v
    end,
})

TabUpgrades:Toggle({
    Title = "Auto Train X2 (Claim X2 & Rush x5)",
    Desc = "Auto-claims floating X2 Strength bonus and auto-hits Training Rush circles (PERFECT up to x5.0)",
    Default = false,
    Callback = function(v)
        Config.AutoTrainX2 = v
        if v then
            if sbOfferActive or hasVisibleStrengthBonusButton() then
                tryClaimStrengthBonus()
            end
            local now = os.clock()
            for id, info in pairs(pendingOsuCircles) do
                if now - info.spawnAt < info.life + 0.15 then
                    scheduleOsuHit(id, info.spawnAt, info.life)
                else
                    pendingOsuCircles[id] = nil
                end
            end
        end
    end,
})

TabUpgrades:Section({ Title = "⚡ Speed Upgrades" })

TabUpgrades:Toggle({
    Title = "Auto Buy Speed Upgrades",
    Desc = "Automatically buys speed upgrades with Cash attribute",
    Default = false,
    Callback = function(v)
        Config.AutoSpeedUpgrade = v
    end,
})

TabUpgrades:Dropdown({
    Title = "Speed Upgrade Tier",
    Values = { "+1 Speed (Tier 1)", "+5 Speed (Tier 2)", "+12 Speed (Tier 3)" },
    Default = "+1 Speed (Tier 1)",
    Callback = function(v)
        if v:find("+5") then
            Config.SpeedUpgradeTier = 2
        elseif v:find("+12") then
            Config.SpeedUpgradeTier = 3
        else
            Config.SpeedUpgradeTier = 1
        end
    end,
})

TabUpgrades:Section({ Title = "🏋️ Weight Training (Power)" })

TabUpgrades:Toggle({
    Title = "Auto Buy Best Affordable Weight",
    Desc = "Automatically buys the strongest barbell your Cash can afford",
    Default = false,
    Callback = function(v)
        Config.AutoBuyWeight = v
    end,
})

TabUpgrades:Toggle({
    Title = "Auto Equip Best Weight",
    Desc = "Automatically equips your strongest barbell",
    Default = false,
    Callback = function(v)
        Config.AutoEquipWeight = v
    end,
})

TabUpgrades:Section({ Title = "🔁 Rebirth" })

TabUpgrades:Toggle({
    Title = "Auto Rebirth",
    Desc = "Automatically rebirths when power requirements are reached",
    Default = false,
    Callback = function(v)
        Config.AutoRebirth = v
    end,
})

-- Auto Train Worker (equips & lifts barbell cleanly)
task.spawn(function()
    while isScriptAlive() do
        if Config.AutoTrain then
            local farmBusy = Config.MasterAutoFarm and (isHoldingCase() or isFlightActive() or isSpinActive() or isInKickSession() or isRespawnOffer())
            local safeToLift = not farmBusy and not isHoldingCase() and not isFlightActive() and not isSpinActive() and not isRespawnOffer()
            if safeToLift then
                local tool = getEquippedWeightTool()
                if not tool then
                    equipWeightInHand()
                    task.wait(0.2)
                else
                    pcall(function()
                        tool:Activate()
                    end)
                end
            end
            task.wait(0.14)
        else
            task.wait(0.35)
        end
    end
end)

-- Auto Upgrades Worker
task.spawn(function()
    local lastSync = 0
    while isScriptAlive() do
        task.wait(1.2)

        -- Auto Speed Upgrade
        if Config.AutoSpeedUpgrade and RequestSpeedUpgrade then
            pcall(function()
                RequestSpeedUpgrade:FireServer({ index = Config.SpeedUpgradeTier, introFree = false })
            end)
        end

        -- Auto Weight Upgrades
        if (Config.AutoBuyWeight or Config.AutoEquipWeight) and WeightsConfig and WeightsConfig.Weights then
            -- Sync state periodically
            if tick() - lastSync > 10 and WeightShopStateSync then
                lastSync = tick()
                pcall(function() WeightShopStateSync:FireServer() end)
            end

            local currentCash = getPlayerCash()
            local bestAffordable = nil
            local highestGain = 0

            for name, wData in pairs(WeightsConfig.Weights) do
                local price = tonumber(wData.Price) or 0
                local gain = tonumber(wData.StrengthGain or wData.Power) or 0
                if price <= currentCash and gain > highestGain then
                    highestGain = gain
                    bestAffordable = name
                end
            end

            if Config.AutoBuyWeight and bestAffordable and RequestBuyWeight then
                pcall(function()
                    RequestBuyWeight:FireServer({ key = bestAffordable })
                end)
            end

            if Config.AutoEquipWeight and bestAffordable and RequestEquipWeight then
                pcall(function()
                    RequestEquipWeight:FireServer({ key = bestAffordable })
                end)
            end
        end

        -- Auto Rebirth
        if Config.AutoRebirth and RequestRebirth then
            pcall(function()
                RequestRebirth:FireServer({ mode = "rebirth" })
            end)
        end
    end
end)

-- Auto Base & Units Worker (Equip Best, Collect Money, Upgrade Units)
task.spawn(function()
    local lastEquipLoop = 0
    local lastCollectLoop = 0
    local lastSlotSync = 0
    while isScriptAlive() do
        local anyActive = Config.AutoEquipBest or Config.AutoCollectMoney or Config.AutoUpgradeUnits
        if not anyActive then
            task.wait(0.25)
        else
            local now = os.clock()

            if Config.AutoCollectMoney and (now - lastCollectLoop) >= 0.75 then
                lastCollectLoop = now
                performAutoCollectStep()
            end

            if Config.AutoEquipBest and (now - lastEquipLoop) >= 3.5 then
                lastEquipLoop = now
                tryEquipBestUnits(false)
            end

            if (Config.AutoUpgradeUnits or Config.InstantMaxLevelUnits) and RequestSlotLevel then
                local plot, plotIdx = getMyPlot()
                if plot and plotIdx then
                    if RequestSlotSignSync and (next(slotSignCache) == nil or (now - lastSlotSync) >= 4.5) then
                        lastSlotSync = now
                        pcall(function() RequestSlotSignSync:FireServer() end)
                    end
                    if now >= upgradePendingUntil then
                        local bestSlot = findBestUnitUpgradeSlot(plot, plotIdx)
                        if bestSlot then
                            lastUpgradedSlot = bestSlot
                            upgradePendingUntil = now + 0.28
                            pcall(function()
                                local maxRem = Config.InstantMaxLevelUnits and Remotes:FindFirstChild("RequestSlotLevelMax")
                                if maxRem then
                                    maxRem:FireServer({ slot = bestSlot })
                                else
                                    RequestSlotLevel:FireServer({ slot = bestSlot })
                                end
                            end)
                        end
                    end
                end
            end

            task.wait(0.14)
        end
    end
end)

-- ==============================================================================
-- 🎁 TAB: CLAIMS & CODES
-- ==============================================================================
TabClaims:Section({ Title = "💎 Free Rewards" })

TabClaims:Toggle({
    Title = "Auto Claim Index Gems",
    Desc = "Collects all completed index gems automatically",
    Default = false,
    Callback = function(v)
        Config.AutoClaimIndexGems = v
    end,
})

TabClaims:Toggle({
    Title = "Auto Claim Daily Reward",
    Desc = "Collects the daily login reward streak",
    Default = false,
    Callback = function(v)
        Config.AutoClaimDaily = v
    end,
})

TabClaims:Toggle({
    Title = "Auto Free Wheel Spin",
    Desc = "Spins the lucky wheel whenever a free spin is available",
    Default = false,
    Callback = function(v)
        Config.AutoSpinWheel = v
    end,
})

TabClaims:Toggle({
    Title = "Auto Claim Offline Cash",
    Desc = "Collects accumulated offline earnings",
    Default = false,
    Callback = function(v)
        Config.AutoClaimOffline = v
    end,
})

TabClaims:Toggle({
    Title = "Auto Forever Rewards",
    Desc = "Claims progress milestones on the Forever track",
    Default = false,
    Callback = function(v)
        Config.AutoForeverRewards = v
    end,
})

TabClaims:Section({ Title = "🔑 Redeem Codes" })

local codeInputText = ""
TabClaims:Input({
    Title = "Promo Code",
    Placeholder = "Enter code here...",
    Default = "",
    Callback = function(v)
        codeInputText = v
    end,
})

TabClaims:Button({
    Title = "Redeem Code",
    Callback = function()
        if #codeInputText == 0 then
            WindUI:Notify({ Title = "Code Empty", Content = "Please enter a code first!", Duration = 2, Icon = "alert-circle" })
            return
        end
        if RedeemCode then
            local ok, res = pcall(function()
                return RedeemCode:InvokeServer(codeInputText)
            end)
            if ok then
                WindUI:Notify({ Title = "Code Redeemed!", Content = "Code submitted: " .. codeInputText, Duration = 3, Icon = "check-circle" })
            else
                WindUI:Notify({ Title = "Redeem Failed", Content = tostring(res), Duration = 3, Icon = "x-circle" })
            end
        end
    end,
})

-- Claims Worker Loop
task.spawn(function()
    while true do
        task.wait(3.0)
        -- Index Gems
        if Config.AutoClaimIndexGems and RequestClaimAllIndexGems then
            pcall(function()
                RequestClaimAllIndexGems:FireServer()
            end)
        end

        -- Daily Claim
        if Config.AutoClaimDaily and RequestDailyClaim then
            if LocalPlayer:GetAttribute("Daily_Claimable") == true then
                pcall(function()
                    RequestDailyClaim:FireServer()
                end)
            end
        end

        -- Wheel Spin
        if Config.AutoSpinWheel and RequestSpinWheel then
            pcall(function()
                RequestSpinWheel:FireServer({ mode = "free" })
            end)
        end

        -- Offline Earnings
        if Config.AutoClaimOffline and RequestClaimOffline then
            pcall(function()
                RequestClaimOffline:FireServer()
            end)
        end

        -- Forever Rewards (Iterate first 10 milestones)
        if Config.AutoForeverRewards and RequestCollectForeverReward then
            for i = 1, 10 do
                if not Config.AutoForeverRewards then break end
                pcall(function()
                    RequestCollectForeverReward:FireServer(i)
                end)
                task.wait(0.2)
            end
        end
    end
end)

-- ==============================================================================
-- 📍 TAB: TELEPORTS
-- ==============================================================================
TabTeleports:Section({ Title = "📍 Fast Map Teleports" })

for name, pos in pairs(TeleportLocations) do
    TabTeleports:Button({
        Title = name,
        Callback = function()
            teleportTo(pos)
            WindUI:Notify({ Title = "Teleported", Content = "Moved to " .. name, Duration = 2, Icon = "map-pin" })
        end,
    })
end

-- ==============================================================================
-- 🏃 TAB: PLAYER PHYSICS & MOVEMENT
-- ==============================================================================
TabPlayer:Section({ Title = "🏃 Movement Speed & Jump" })

TabPlayer:Toggle({
    Title = "Enable Custom WalkSpeed",
    Default = false,
    Callback = function(v)
        Config.WalkSpeedEnabled = v
        local hum = getHumanoid()
        if hum and not v then
            hum.WalkSpeed = 16
        end
    end,
})

TabPlayer:Slider({
    Title = "WalkSpeed Value",
    Value = {
        Min = 16,
        Max = 250,
        Default = 32,
    },
    Step = 2,
    Callback = function(v)
        Config.WalkSpeedValue = v
    end,
})

TabPlayer:Toggle({
    Title = "Enable Custom JumpPower",
    Default = false,
    Callback = function(v)
        Config.JumpPowerEnabled = v
        local hum = getHumanoid()
        if hum and not v then
            hum.JumpPower = 50
        end
    end,
})

TabPlayer:Slider({
    Title = "JumpPower Value",
    Value = {
        Min = 50,
        Max = 350,
        Default = 75,
    },
    Step = 5,
    Callback = function(v)
        Config.JumpPowerValue = v
    end,
})

TabPlayer:Section({ Title = "🕊️ Flight & NoClip" })

TabPlayer:Toggle({
    Title = "Infinite Jump",
    Desc = "Jump continuously in the air",
    Default = false,
    Callback = function(v)
        Config.InfiniteJump = v
    end,
})

TabPlayer:Toggle({
    Title = "NoClip",
    Desc = "Walk through walls and obstacles",
    Default = false,
    Callback = function(v)
        Config.NoClip = v
    end,
})

TabPlayer:Toggle({
    Title = "Fly",
    Desc = "Smoothly fly across the entire world",
    Default = false,
    Callback = function(v)
        Config.FlyEnabled = v
    end,
})

TabPlayer:Slider({
    Title = "Fly Speed",
    Value = {
        Min = 20,
        Max = 200,
        Default = 50,
    },
    Step = 5,
    Callback = function(v)
        Config.FlySpeed = v
    end,
})

-- Infinite Jump Listener
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local hum = getHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- NoClip Heartbeat Loop
RunService.Stepped:Connect(function()
    if Config.NoClip then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- Player Speed & Jump Enforcer Loop
RunService.Heartbeat:Connect(function()
    local hum = getHumanoid()
    if hum then
        if Config.WalkSpeedEnabled and hum.WalkSpeed ~= Config.WalkSpeedValue then
            hum.WalkSpeed = Config.WalkSpeedValue
        end
        if Config.JumpPowerEnabled and hum.JumpPower ~= Config.JumpPowerValue then
            hum.JumpPower = Config.JumpPowerValue
        end
    end
end)

-- Fly System
task.spawn(function()
    local bodyGyro, bodyVel
    while true do
        task.wait(0.1)
        local hrp = getHRP()
        local hum = getHumanoid()

        if Config.FlyEnabled and hrp and hum then
            if not bodyGyro or not bodyGyro.Parent then
                bodyGyro = Instance.new("BodyGyro")
                bodyGyro.P = 9e4
                bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                bodyGyro.CFrame = hrp.CFrame
                bodyGyro.Parent = hrp
            end

            if not bodyVel or not bodyVel.Parent then
                bodyVel = Instance.new("BodyVelocity")
                bodyVel.Velocity = Vector3.new(0, 0, 0)
                bodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bodyVel.Parent = hrp
            end

            while Config.FlyEnabled and hrp and hum do
                local cam = workspace.CurrentCamera
                local moveDir = Vector3.new(0, 0, 0)

                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveDir = moveDir + (cam.CFrame.LookVector)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveDir = moveDir - (cam.CFrame.LookVector)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveDir = moveDir - (cam.CFrame.RightVector)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveDir = moveDir + (cam.CFrame.RightVector)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    moveDir = moveDir + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    moveDir = moveDir - Vector3.new(0, 1, 0)
                end

                if moveDir.Magnitude > 0 then
                    moveDir = moveDir.Unit * Config.FlySpeed
                end

                bodyVel.Velocity = moveDir
                bodyGyro.CFrame = cam.CFrame
                RunService.RenderStepped:Wait()
            end

            if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
            if bodyVel then bodyVel:Destroy() bodyVel = nil end
        else
            if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
            if bodyVel then bodyVel:Destroy() bodyVel = nil end
        end
    end
end)

-- ==============================================================================
-- ⚙️ TAB: SETTINGS, HOTKEYS & CONFIG MANAGER
-- ==============================================================================
local hotkeyInputConn = nil
do
    local ConfigStatusParagraph = nil
    local SavedProfilesDropdown = nil
    local ProfileNameInput = nil
    local AutoLoadToggleCtrl = nil
    local AutoSaveToggleCtrl = nil
    local HotkeyKeybindCtrl = nil
    local HotkeyDropdownCtrl = nil
    local lastHotkeyToggleAt = 0

    local HOTKEY_CHOICES = {
        "RightControl",
        "RightShift",
        "LeftControl",
        "LeftAlt",
        "Insert",
        "End",
        "Home",
        "F1",
        "F2",
        "F4",
        "F8",
        "K",
        "M",
        "Backquote",
    }

    local function updateConfigStatusDisplay()
        if not ConfigStatusParagraph then return end
        local autoProf = CfgSys.getAutoLoadProfile()
        local autoText = (autoProf and autoProf ~= "none") and ("เปิดอยู่ (" .. tostring(autoProf) .. ")") or "ปิด (Disabled)"
        local saveText = Config.AutoSaveConfig and "เปิด (Auto-Save ON)" or "ปิด (Manual Only)"
        local desc = string.format(
            "• โปรไฟล์ที่ใช้งานอยู่ (Active): %s\n• โปรไฟล์ที่เลือก (Selected): %s\n• โหลดอัตโนมัติ (Auto-Load): %s\n• บันทึกอัตโนมัติ (Auto-Save): %s\n• ปุ่มลัดพับหน้าต่าง (UI Hotkey): [%s]",
            tostring(CfgSys.loadedProfile),
            tostring(CfgSys.selectedProfile),
            autoText,
            saveText,
            tostring(Config.UIToggleKey or "RightControl")
        )
        pcall(function()
            if typeof(ConfigStatusParagraph.Set) == "function" then
                ConfigStatusParagraph:Set({ Title = "📊 สถานะโปรไฟล์และการตั้งค่า (Config Status)", Desc = desc })
            elseif typeof(ConfigStatusParagraph.SetDesc) == "function" then
                ConfigStatusParagraph:SetDesc(desc)
            end
        end)
    end

    local function applyUIToggleKey(newKey, notifyUser)
        local kc, kName = CfgSys.resolveKeyCode(newKey)
        CfgSys.toggleKeyEnum = kc
        CfgSys.toggleKeyName = kName
        Config.UIToggleKey = kName
        pcall(function()
            if Window and typeof(Window.SetToggleKey) == "function" then
                Window:SetToggleKey(kc)
            end
        end)
        if HotkeyDropdownCtrl and table.find(HOTKEY_CHOICES, kName) then
            pcall(function()
                if HotkeyDropdownCtrl.Select then
                    HotkeyDropdownCtrl:Select(kName)
                elseif HotkeyDropdownCtrl.Set then
                    HotkeyDropdownCtrl:Set(kName)
                end
            end)
        end
        updateConfigStatusDisplay()
        CfgSys.scheduleAutoSave()
        if notifyUser and WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "⌨️ ตั้งปุ่มลัด UI แล้ว",
                Content = "กดปุ่ม [" .. kName .. "] เพื่อพับ/เปิดหน้าต่าง UI",
                Duration = 2.5,
                Icon = "keyboard",
            })
        end
    end

    hotkeyInputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not isScriptAlive() then return end
        if UserInputService:GetFocusedTextBox() then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == CfgSys.toggleKeyEnum then
            local now = os.clock()
            if now - lastHotkeyToggleAt < 0.25 then return end
            lastHotkeyToggleAt = now
            local closedBefore = Window and Window.Closed
            task.delay(0.04, function()
                if not isScriptAlive() or not Window or Window.Destroyed then return end
                if Window.Closed == closedBefore and typeof(Window.Toggle) == "function" then
                    pcall(function() Window:Toggle() end)
                end
            end)
        end
    end)

    local function applyConfigToAllControls()
        CfgSys.isBatchApplying = true
        pcall(function()
            for cfgKey, info in pairs(CfgSys.RegisteredControls) do
                local val = Config[cfgKey]
                if val ~= nil and info and info.elem then
                    pcall(function()
                        if info.kind == "Dropdown" then
                            if info.elem.Select then
                                info.elem:Select(val)
                            elseif info.elem.Set then
                                info.elem:Set(val)
                            end
                        else
                            if info.elem.Set then
                                info.elem:Set(val)
                            elseif info.elem.SetValue then
                                info.elem:SetValue(val)
                            end
                        end
                    end)
                    if info.callback then
                        pcall(info.callback, val)
                    end
                end
            end
            if Config.UIToggleKey then
                applyUIToggleKey(Config.UIToggleKey, false)
            end
            if AutoSaveToggleCtrl then
                pcall(function()
                    if AutoSaveToggleCtrl.Set then
                        AutoSaveToggleCtrl:Set(Config.AutoSaveConfig)
                    elseif AutoSaveToggleCtrl.SetValue then
                        AutoSaveToggleCtrl:SetValue(Config.AutoSaveConfig)
                    end
                end)
            end
            syncNetworkGuardFlags()
        end)
        CfgSys.isBatchApplying = false
        updateConfigStatusDisplay()
    end

    local function syncAutoLoadToggleUI()
        if not AutoLoadToggleCtrl then return end
        local autoProf = CfgSys.getAutoLoadProfile()
        local isEnabledForSelected = (autoProf ~= "none" and autoProf == CfgSys.selectedProfile)
        pcall(function()
            if AutoLoadToggleCtrl.Set then
                AutoLoadToggleCtrl:Set(isEnabledForSelected)
            elseif AutoLoadToggleCtrl.SetValue then
                AutoLoadToggleCtrl:SetValue(isEnabledForSelected)
            end
        end)
    end

    local function refreshProfilesDropdown(selectTarget)
        local list = CfgSys.getSavedProfilesList()
        if selectTarget and table.find(list, selectTarget) then
            CfgSys.selectedProfile = selectTarget
        elseif not table.find(list, CfgSys.selectedProfile) then
            CfgSys.selectedProfile = list[1] or "default"
        end
        if SavedProfilesDropdown then
            pcall(function()
                if SavedProfilesDropdown.Refresh then
                    SavedProfilesDropdown:Refresh(list)
                elseif SavedProfilesDropdown.SetValues then
                    SavedProfilesDropdown:SetValues(list)
                end
                if SavedProfilesDropdown.Select then
                    SavedProfilesDropdown:Select(CfgSys.selectedProfile)
                end
            end)
        end
        syncAutoLoadToggleUI()
        updateConfigStatusDisplay()
    end

    -- 1. UI HOTKEY SECTION
    TabSettings:Section({ Title = "⌨️ UI Toggle Hotkey (ปุ่มลัดพับ/เปิดหน้าต่าง UI)" })

    pcall(function()
        if typeof(TabSettings.Keybind) == "function" then
            HotkeyKeybindCtrl = TabSettings:Keybind({
                Title = "Toggle UI Keybind (กดเพื่อเปลี่ยนปุ่มลัด)",
                Desc = "Click and press any key on your keyboard to fold or reopen the Song Hub window",
                Value = Config.UIToggleKey or "RightControl",
                Callback = function(key)
                    applyUIToggleKey(key, true)
                end,
            })
        end
    end)

    HotkeyDropdownCtrl = TabSettings:Dropdown({
        Title = "Quick Select Hotkey (เลือกปุ่มลัดด่วน)",
        Desc = "Select a shortcut key to fold/unfold the UI window (Default: RightControl)",
        Values = HOTKEY_CHOICES,
        Value = table.find(HOTKEY_CHOICES, Config.UIToggleKey) and Config.UIToggleKey or "RightControl",
        Callback = function(v)
            if v and v ~= Config.UIToggleKey then
                applyUIToggleKey(v, true)
            end
        end,
    })

    TabSettings:Button({
        Title = "🔽 Fold / Minimize UI Window Now (พับหน้าต่างตอนนี้)",
        Desc = "Minimizes the UI window immediately (press [" .. tostring(Config.UIToggleKey or "RightControl") .. "] or click the floating button to reopen)",
        Callback = function()
            if Window and typeof(Window.Toggle) == "function" then
                pcall(function() Window:Toggle() end)
            end
        end,
    })

    -- 2. SAVE CONFIG & AUTO-LOAD SECTION
    TabSettings:Section({ Title = "💾 Save Config & Auto-Load (บันทึกและโหลดอัตโนมัติ)" })

    ConfigStatusParagraph = TabSettings:Paragraph({
        Title = "📊 สถานะโปรไฟล์และการตั้งค่า (Config Status)",
        Desc = "Loading profile status...",
    })

    SavedProfilesDropdown = TabSettings:Dropdown({
        Title = "Saved Config Profiles (เลือกโปรไฟล์ที่บันทึกไว้)",
        Desc = "Select a saved configuration profile",
        Values = CfgSys.getSavedProfilesList(),
        Value = CfgSys.selectedProfile,
        Callback = function(v)
            if v and v ~= "" then
                CfgSys.selectedProfile = CfgSys.sanitizeProfileName(v)
                CfgSys.inputProfile = CfgSys.selectedProfile
                syncAutoLoadToggleUI()
                updateConfigStatusDisplay()
            end
        end,
    })

    ProfileNameInput = TabSettings:Input({
        Title = "Profile Name (ชื่อโปรไฟล์สำหรับบันทึกใหม่)",
        Desc = "Type a profile name (e.g. default, afk_farm, max_speed)",
        Value = CfgSys.selectedProfile,
        Placeholder = "default",
        Callback = function(v)
            local clean = CfgSys.sanitizeProfileName(v)
            CfgSys.inputProfile = clean
            CfgSys.selectedProfile = clean
            updateConfigStatusDisplay()
        end,
    })

    AutoLoadToggleCtrl = TabSettings:Toggle({
        Title = "Auto-Load Selected Profile on Startup (โหลดอัตโนมัติเมื่อรันสคริปต์)",
        Desc = "Automatically loads and activates this profile every time you execute the script",
        Default = (CfgSys.getAutoLoadProfile() ~= "none"),
        Callback = function(v)
            if v then
                local target = CfgSys.sanitizeProfileName(CfgSys.selectedProfile)
                CfgSys.setAutoLoadProfile(target)
                CfgSys.saveProfileToDisk(target)
                WindUI:Notify({
                    Title = "✅ เปิด Auto-Load แล้ว",
                    Content = "จะโหลดโปรไฟล์ '" .. target .. "' อัตโนมัติทุกครั้งที่รันสคริปต์",
                    Duration = 2.5,
                    Icon = "check-circle",
                })
            else
                CfgSys.setAutoLoadProfile("none")
                WindUI:Notify({
                    Title = "ℹ️ ปิด Auto-Load แล้ว",
                    Content = "ยกเลิกการโหลดตั้งค่าอัตโนมัติตอนเริ่มรัน",
                    Duration = 2,
                    Icon = "x-circle",
                })
            end
            updateConfigStatusDisplay()
        end,
    })

    AutoSaveToggleCtrl = TabSettings:Toggle({
        Title = "Auto-Save When Settings Change (บันทึกอัตโนมัติเมื่อเปลี่ยนค่า)",
        Desc = "Automatically saves your changes to the active profile whenever you toggle any option",
        Default = Config.AutoSaveConfig,
        Callback = function(v)
            Config.AutoSaveConfig = v
            if v then
                CfgSys.saveProfileToDisk(CfgSys.selectedProfile)
            end
            updateConfigStatusDisplay()
        end,
    })

    TabSettings:Button({
        Title = "💾 Save / Overwrite Profile (บันทึกการตั้งค่าปัจจุบัน)",
        Desc = "Saves all current toggles, sliders, theme, and hotkey into the selected profile",
        Callback = function()
            local targetName = CfgSys.sanitizeProfileName((CfgSys.inputProfile ~= "" and CfgSys.inputProfile) or CfgSys.selectedProfile)
            local ok, savedName = CfgSys.saveProfileToDisk(targetName)
            refreshProfilesDropdown(savedName)
            if ok then
                WindUI:Notify({
                    Title = "💾 บันทึก Config สำเร็จ!",
                    Content = "บันทึกโปรไฟล์ '" .. savedName .. "' เรียบร้อยแล้ว",
                    Duration = 3,
                    Icon = "check-circle",
                })
            else
                WindUI:Notify({
                    Title = "❌ บันทึกไม่สำเร็จ",
                    Content = "Executor ของคุณอาจไม่รองรับ writefile",
                    Duration = 3,
                    Icon = "alert-circle",
                })
            end
        end,
    })

    TabSettings:Button({
        Title = "📂 Load Selected Profile (โหลดโปรไฟล์ที่เลือก)",
        Desc = "Loads and applies all settings from the selected profile immediately",
        Callback = function()
            local ok = CfgSys.loadProfileFromDisk(CfgSys.selectedProfile)
            if ok then
                applyConfigToAllControls()
                WindUI:Notify({
                    Title = "📂 โหลด Config สำเร็จ!",
                    Content = "ใช้งานโปรไฟล์ '" .. tostring(CfgSys.selectedProfile) .. "' เรียบร้อยแล้ว",
                    Duration = 3,
                    Icon = "check-circle",
                })
            else
                WindUI:Notify({
                    Title = "⚠️ ไม่พบไฟล์โปรไฟล์",
                    Content = "ยังไม่ได้บันทึกโปรไฟล์ชื่อ '" .. tostring(CfgSys.selectedProfile) .. "' (กด Save ก่อนครับ)",
                    Duration = 3,
                    Icon = "alert-circle",
                })
            end
        end,
    })

    TabSettings:Button({
        Title = "🗑️ Delete Selected Profile (ลบโปรไฟล์ที่เลือก)",
        Desc = "Deletes the selected profile JSON file from disk",
        Callback = function()
            local target = CfgSys.sanitizeProfileName(CfgSys.selectedProfile)
            local filePath = CfgSys.PROFILES_FOLDER .. "/" .. target .. ".json"
            if typeof(isfile) == "function" and isfile(filePath) and typeof(delfile) == "function" then
                pcall(function() delfile(filePath) end)
                if CfgSys.getAutoLoadProfile() == target then
                    CfgSys.setAutoLoadProfile("default")
                end
                CfgSys.selectedProfile = "default"
                CfgSys.inputProfile = "default"
                refreshProfilesDropdown("default")
                WindUI:Notify({
                    Title = "🗑️ ลบโปรไฟล์แล้ว",
                    Content = "ลบโปรไฟล์ '" .. target .. "' เรียบร้อยแล้ว",
                    Duration = 2.5,
                    Icon = "trash",
                })
            else
                WindUI:Notify({
                    Title = "ℹ️ ไม่มีไฟล์ให้ลบ",
                    Content = "ไม่พบไฟล์โปรไฟล์ '" .. target .. "' บนดิสก์",
                    Duration = 2.5,
                    Icon = "info",
                })
            end
        end,
    })

    TabSettings:Button({
        Title = "🔄 Reset All Settings to Default (รีเซ็ตค่าเริ่มต้นทั้งหมด)",
        Desc = "Turns off all farm toggles and restores default UI & player settings",
        Callback = function()
            for k, v in pairs(DefaultConfig) do
                Config[k] = v
            end
            applyConfigToAllControls()
            if Config.AutoSaveConfig then
                CfgSys.saveProfileToDisk(CfgSys.selectedProfile)
            end
            WindUI:Notify({
                Title = "🔄 รีเซ็ตค่าเริ่มต้นแล้ว",
                Content = "คืนค่าปุ่มทั้งหมดกลับเป็นค่าเริ่มต้นเรียบร้อย",
                Duration = 2.5,
                Icon = "refresh-cw",
            })
        end,
    })

    -- 3. UI THEME & SMOOTH EFFECTS SECTION
    TabSettings:Section({ Title = "🎨 UI Theme & Smooth Effects (สบายตา)" })

    TabSettings:Dropdown({
        Title = "UI Color Theme (โทนสีสบายตา)",
        Desc = "Choose from 5 curated soft pastel & midnight eye-care themes",
        Values = (Window._JFCThemeEngine and Window._JFCThemeEngine.ThemeNames) or { "🌌 Aurora Borealis (แสงเหนือออโรร่า)" },
        Value = Config.UITheme,
        Callback = function(v)
            if Window._JFCThemeEngine and Window._JFCThemeEngine.ApplyTheme then
                Window._JFCThemeEngine.ApplyTheme(v, not CfgSys.isBatchApplying)
            end
        end,
    })

    TabSettings:Dropdown({
        Title = "Animation Effect Style (รูปแบบเอฟเฟกต์)",
        Desc = "Switch between Aurora Flow, Sakura Petals, Starlight Firefly, Bubbles, or Minimal Glow",
        Values = (Window._JFCThemeEngine and Window._JFCThemeEngine.StyleNames) or { "Auto (ตามธีมอัตโนมัติ)" },
        Value = Config.UIAnimationStyle,
        Callback = function(v)
            Config.UIAnimationStyle = v
            if Window._JFCThemeEngine and Window._JFCThemeEngine.UpdateParticles then
                Window._JFCThemeEngine.UpdateParticles()
            end
        end,
    })

    TabSettings:Toggle({
        Title = "Smooth Animated Effects (เปิดเอฟเฟกต์เคลื่อนไหว)",
        Desc = "Soft breathing aurora glow, rotating pastel border, and gentle floating motes",
        Default = Config.UIBackgroundAnimation,
        Callback = function(v)
            if Window._JFCThemeEngine and Window._JFCThemeEngine.SetAnimEnabled then
                Window._JFCThemeEngine.SetAnimEnabled(v)
            end
        end,
    })

    TabSettings:Slider({
        Title = "Animation Speed (ความเร็วการเคลื่อนไหว)",
        Desc = "Adjust how fast the aurora & particles flow (Default: 8 = 0.8x Calm)",
        Step = 1,
        Value = {
            Min = 2,
            Max = 20,
            Default = Config.UIAnimationSpeed or 8,
        },
        Callback = function(v)
            Config.UIAnimationSpeed = tonumber(v) or 8
        end,
    })

    TabSettings:Section({ Title = "🌐 Server Management" })

    TabSettings:Button({
        Title = "Rejoin Server",
        Callback = function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end,
    })

    TabSettings:Button({
        Title = "Server Hop",
        Callback = function()
            local ts = game:GetService("TeleportService")
            local servers = {}
            local req = (syn and syn.request) or request or http_request
            if req then
                local res = req({ Url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId) })
                if res and res.Body then
                    local data = HttpService:JSONDecode(res.Body)
                    if data and data.data then
                        for _, s in ipairs(data.data) do
                            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                                table.insert(servers, s.id)
                            end
                        end
                    end
                end
            end
            if #servers > 0 then
                ts:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
            else
                ts:Teleport(game.PlaceId, LocalPlayer)
            end
        end,
    })

    TabSettings:Button({
        Title = "Unload Script",
        Callback = function()
            Config.MasterAutoFarm = false
            Config.InstantPerfectKick = false
            Config.CutsceneBypass = false
            Config.SafeAntiWave = false
            Config.NativeAutoKickSync = false
            Config.ReturnSprintBoost = false
            Config.InstantWarpReturn = false
            Config.AutoOpenAll = false
            Config.AutoOpenSelected = false
            Config.AutoOpenMutatedCases = false
            Config.FastOpenSkip = false
            Config.InstantRevealBypass = false
            Config.AutoSmartExpedition = false
            Config.AutoSellJunkPets = false
            Config.InstantMaxLevelUnits = false
            Config.AutoClaimEventPass = false
            Config.AutoBuyGemBoost = false
            Config.AutoEquipBest = false
            Config.AutoCollectMoney = false
            Config.AutoUpgradeUnits = false
            Config.AutoSpeedUpgrade = false
            Config.AutoTrain = false
            Config.AutoTrainX2 = false
            Config.AutoBuyWeight = false
            Config.AutoEquipWeight = false
            Config.AutoRebirth = false
            Config.WalkSpeedEnabled = false
            Config.JumpPowerEnabled = false
            Config.InfiniteJump = false
            Config.NoClip = false
            Config.FlyEnabled = false
            Config.UIBackgroundAnimation = false
            syncNetworkGuardFlags()

            if getgenv then
                getgenv()._JumpForCasesRunning = false
            end

            if hotkeyInputConn then
                pcall(function() hotkeyInputConn:Disconnect() end)
                hotkeyInputConn = nil
            end
            if uiAnimConn then
                pcall(function() uiAnimConn:Disconnect() end)
                uiAnimConn = nil
            end
            if slotSignSyncConn then
                pcall(function() slotSignSyncConn:Disconnect() end)
                slotSignSyncConn = nil
            end
            if baseLevelResultConn then
                pcall(function() baseLevelResultConn:Disconnect() end)
                baseLevelResultConn = nil
            end
            if basePadInfoConn then
                pcall(function() basePadInfoConn:Disconnect() end)
                basePadInfoConn = nil
            end
            for _, c in ipairs(equipTriggerConns) do
                pcall(function() c:Disconnect() end)
            end
            table.clear(equipTriggerConns)
            if type(CfgSys.OverdriveConns) == "table" then
                for _, c in ipairs(CfgSys.OverdriveConns) do
                    pcall(function() c:Disconnect() end)
                end
                table.clear(CfgSys.OverdriveConns)
            end
            table.clear(slotSignCache)
            if kickingBypassConn then
                pcall(function() kickingBypassConn:Disconnect() end)
                kickingBypassConn = nil
            end
            if fallRewardSkipConn then
                pcall(function() fallRewardSkipConn:Disconnect() end)
                fallRewardSkipConn = nil
            end
            if trainBonusConn then
                pcall(function() trainBonusConn:Disconnect() end)
                trainBonusConn = nil
            end
            if osuTrainConn then
                pcall(function() osuTrainConn:Disconnect() end)
                osuTrainConn = nil
            end
            table.clear(pendingOsuCircles)

            local hum = getHumanoid()
            if hum then
                hum.WalkSpeed = getNormalWalkSpeed()
                hum.JumpPower = 50
            end

            Window:Destroy()
        end,
    })

    TabSettings:Section({ Title = "ℹ️ Information" })
    TabSettings:Paragraph({ Title = "Song Hub", Desc = "Jump for Cases🎲 v1.3 • Aurora Eye-Care Edition\nAuto-Save Config • Auto-Load • Custom UI Hotkey" })

    updateConfigStatusDisplay()
    if CfgSys.wasAutoLoaded then
        task.defer(function()
            applyConfigToAllControls()
            WindUI:Notify({
                Title = "📂 Auto-Loaded Config!",
                Content = "โหลดตั้งค่าจากโปรไฟล์ '" .. tostring(CfgSys.loadedProfile) .. "' อัตโนมัติแล้ว (ปุ่มพับ UI: " .. tostring(Config.UIToggleKey) .. ")",
                Duration = 3.5,
                Icon = "check-circle",
            })
        end)
    else
        task.defer(function()
            CfgSys.saveProfileToDisk(CfgSys.selectedProfile)
            refreshProfilesDropdown(CfgSys.selectedProfile)
        end)
    end
end

pcall(function() Window:SelectTab(1) end)

print("[Song Hub] ✅ Jump for Cases🎲 script loaded successfully.")
