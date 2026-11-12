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
if getgenv then
    if getgenv()._JumpForCasesRunning and getgenv()._JFC_Window then
        pcall(function()
            getgenv()._JFC_Window:Destroy()
        end)
    end
    getgenv()._JumpForCasesRunning = true
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
local RedeemCode = Remotes and Remotes:FindFirstChild("RedeemCode")
local SellShopRequest = Remotes and Remotes:FindFirstChild("SellShopRequest")
local RequestSetSetting = Remotes and Remotes:FindFirstChild("RequestSetSetting")

-- Load Game Configs safely
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
    NativeAutoKickSync = false,
    ReturnSprintBoost = false,
    
    -- Auto Case Opening
    FastOpenSkip = false,
    AutoOpenAll = false,
    AutoOpenSelected = false,
    SelectedCase = CaseNamesList[1] or "Basic",
    CaseOpenDelay = 0.35,

    -- Auto Upgrades
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
}

-- Target Key Positions
local POS_KICK_ZONE = Vector3.new(207.25, 27.8, 104.95)
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

local function isInKickSession()
    return LocalPlayer:GetAttribute("_InKickSession") == true or LocalPlayer:GetAttribute("_IsKicking") == true
end

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

local Window = WindUI:CreateWindow({
    Title = "Song Hub",
    Icon = "rbxassetid://135165335432475",
    Author = "Song",
    Folder = "SongHub_JumpForCases",
    Size = UDim2.fromOffset(620, 440),
    Transparent = true,
    Theme = "Dark",
})

if getgenv then
    getgenv()._JFC_Window = Window
end

WindUI:Notify({
    Title = "Song Hub Loaded!",
    Content = "Jump for Cases🎲 script loaded successfully.",
    Duration = 4,
    Icon = "check-circle",
})

-- ==============================================================================
-- 📑 TABS
-- ==============================================================================
local TabFarm = Window:Tab({ Title = "Auto Farm", Icon = "zap" })
local TabCases = Window:Tab({ Title = "Cases", Icon = "package" })
local TabUpgrades = Window:Tab({ Title = "Upgrades", Icon = "arrow-up-circle" })
local TabClaims = Window:Tab({ Title = "Claims & Codes", Icon = "gift" })
local TabTeleports = Window:Tab({ Title = "Teleports", Icon = "map-pin" })
local TabPlayer = Window:Tab({ Title = "Player", Icon = "user" })
local TabSettings = Window:Tab({ Title = "Settings", Icon = "settings" })

-- ==============================================================================
-- 🦘 TAB: AUTO FARM / JUMP
-- ==============================================================================
TabFarm:Section({ Title = "🚀 Smart Master Auto Farm" })

TabFarm:Toggle({
    Title = "Master Auto Farm (Full Automation)",
    Desc = "Auto warps to Kick Zone, locks perfect jump, collects cases & returns",
    Default = false,
    Callback = function(v)
        Config.MasterAutoFarm = v
    end,
})

TabFarm:Section({ Title = "⚙️ Built-in AutoKick & Sprint Return" })

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
    Title = "Return Sprint Boost (Safe Speed)",
    Desc = "Accelerates walk back speed to 48 WS when returning with a case",
    Default = false,
    Callback = function(v)
        Config.ReturnSprintBoost = v
    end,
})

-- Kick Minigame Auto-Lock Helper (Hooks into RenderStepped)
RunService.RenderStepped:Connect(function()
    if Config.MasterAutoFarm then
        local renv = getrenv and getrenv()
        local KickAuto = (renv and renv._G and renv._G.KickAuto) or _G.KickAuto
        if type(KickAuto) == "table" and type(KickAuto.state) == "function" and type(KickAuto.lock) == "function" then
            local state = KickAuto.state()
            if state and state.minigameActive and not state.locked then
                -- Lock jump timing
                KickAuto.lock()
            end
        end
    end
end)

-- Safe Sprint Booster for Case Return (Bypasses the 75-second slow walk safely)
task.spawn(function()
    while true do
        task.wait(0.25)
        if Config.ReturnSprintBoost or Config.MasterAutoFarm then
            local hum = getHumanoid()
            if hum and isHoldingCase() and not Config.WalkSpeedEnabled then
                -- Anti-cheat safe speed cap is 48-50 WS
                hum.WalkSpeed = 48
            end
        end
    end
end)

-- Master Auto Farm Main Loop
task.spawn(function()
    while true do
        task.wait(0.3)
        if Config.MasterAutoFarm then
            local hrp = getHRP()
            local hum = getHumanoid()
            local renv = getrenv and getrenv()
            local KickAuto = (renv and renv._G and renv._G.KickAuto) or _G.KickAuto

            if hrp and hum then
                -- Phase 1: Case Return / Deposit
                if isHoldingCase() then
                    -- Guide character towards CollectZone
                    hum:MoveTo(Vector3.new(POS_COLLECT_ZONE.X, hrp.Position.Y, POS_COLLECT_ZONE.Z))
                    hum.WalkSpeed = 48

                    local tDeposit = tick()
                    while isHoldingCase() and (tick() - tDeposit) < 15 and Config.MasterAutoFarm do
                        task.wait(0.2)
                        -- If close enough to CollectZone, touch it
                        local dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(POS_COLLECT_ZONE.X, 0, POS_COLLECT_ZONE.Z)).Magnitude
                        if dist < 12 then
                            task.wait(0.3)
                        end
                    end

                    -- Once deposited, fire server auto return to runway
                    if not isHoldingCase() and RequestAutoReturn then
                        pcall(function() RequestAutoReturn:FireServer() end)
                        task.wait(0.5)
                    end
                end

                -- Phase 2: Flight / In Kick Session Wait
                if isInKickSession() then
                    -- Wait until flight finishes and player lands
                    local tFlight = tick()
                    while isInKickSession() and (tick() - tFlight) < 25 and Config.MasterAutoFarm do
                        task.wait(0.3)
                        -- Dismiss wave cutscene if stuck
                        if FallRewardEvent and LocalPlayer:GetAttribute("_IsKicking") == false then
                            pcall(function()
                                FallRewardEvent:FireServer({ kind = "waveCutsceneDone" })
                            end)
                        end
                    end
                end

                -- Phase 3: Initiate Kick from KickZone
                if not isInKickSession() and not isHoldingCase() and Config.MasterAutoFarm then
                    local distToKick = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(POS_KICK_ZONE.X, 0, POS_KICK_ZONE.Z)).Magnitude
                    if distToKick > 8 then
                        teleportTo(POS_KICK_ZONE)
                        task.wait(0.35)
                    end

                    -- Check zone readiness
                    local inZone = false
                    if type(KickAuto) == "table" and type(KickAuto.state) == "function" then
                        local st = KickAuto.state()
                        inZone = st and st.inZone
                    else
                        inZone = true
                    end

                    if inZone then
                        -- Start kick charge
                        if type(KickAuto) == "table" and type(KickAuto.press) == "function" then
                            KickAuto.press()
                            task.wait(0.15)
                            if type(KickAuto.lock) == "function" then
                                KickAuto.lock()
                            end
                        elseif RequestKick then
                            pcall(function() RequestKick:FireServer({ action = "charge" }) end)
                            task.wait(0.12)
                            pcall(function() RequestKick:FireServer({ tier = "Perfect" }) end)
                        end

                        -- Wait for launch to initiate
                        task.wait(1.0)
                    else
                        -- Re-align position
                        teleportTo(POS_KICK_ZONE)
                        task.wait(0.5)
                    end
                end
            end
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
    Min = 0.15,
    Max = 2.0,
    Step = 0.05,
    Default = 0.35,
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

-- Case Opener Helper Function
local function openCaseInstance(caseName)
    local count = getCaseCount(caseName)
    if count <= 0 then return false end

    -- Cannot open cases mid-flight or during kick session
    if isInKickSession() then
        return false
    end

    -- Equip case
    if RequestEquipBrainrot then
        pcall(function()
            RequestEquipBrainrot:FireServer("case::" .. caseName)
        end)
    end
    task.wait(0.08)

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

    -- Dismiss reveal popup if Fast Open is enabled
    if Config.FastOpenSkip then
        pcall(function()
            local renv = getrenv and getrenv()
            local g = (renv and renv._G) or _G
            if g then
                if type(g.StopCaseReveal) == "function" then g.StopCaseReveal() end
                if type(g.StopCaseOpening) == "function" then g.StopCaseOpening() end
            end
        end)
    end

    return true
end

-- Auto Case Opener Background Worker
task.spawn(function()
    while true do
        task.wait(0.15)
        if (Config.AutoOpenSelected or Config.AutoOpenAll) and not isInKickSession() then
            if Config.AutoOpenSelected and Config.SelectedCase then
                if openCaseInstance(Config.SelectedCase) then
                    task.wait(Config.CaseOpenDelay)
                else
                    task.wait(0.4)
                end
            elseif Config.AutoOpenAll then
                local openedAny = false
                for _, caseName in ipairs(CaseNamesList) do
                    if not Config.AutoOpenAll or isInKickSession() then break end
                    if getCaseCount(caseName) > 0 then
                        openCaseInstance(caseName)
                        openedAny = true
                        task.wait(Config.CaseOpenDelay)
                    end
                end
                if not openedAny then
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

-- Auto Upgrades Worker
task.spawn(function()
    local lastSync = 0
    while true do
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
    Min = 16,
    Max = 250,
    Step = 2,
    Default = 32,
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
    Min = 50,
    Max = 350,
    Step = 5,
    Default = 75,
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
    Min = 20,
    Max = 200,
    Step = 5,
    Default = 50,
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
-- ⚙️ TAB: SETTINGS & HUB
-- ==============================================================================
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
        Config.NativeAutoKickSync = false
        Config.ReturnSprintBoost = false
        Config.AutoOpenAll = false
        Config.AutoOpenSelected = false
        Config.FastOpenSkip = false
        Config.AutoSpeedUpgrade = false
        Config.AutoBuyWeight = false
        Config.AutoEquipWeight = false
        Config.AutoRebirth = false
        Config.WalkSpeedEnabled = false
        Config.JumpPowerEnabled = false
        Config.InfiniteJump = false
        Config.NoClip = false
        Config.FlyEnabled = false

        if getgenv then
            getgenv()._JumpForCasesRunning = false
        end

        local hum = getHumanoid()
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end

        Window:Destroy()
    end,
})

TabSettings:Section({ Title = "ℹ️ Information" })
TabSettings:Paragraph({ Title = "Song Hub", Desc = "Jump for Cases🎲 v1.0\nMade with WindUI" })

print("[Song Hub] ✅ Jump for Cases🎲 script loaded successfully.")
