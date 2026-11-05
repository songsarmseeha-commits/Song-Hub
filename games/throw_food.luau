--[[
    ========================================================================
    Song Hub | [🍖] Throw Food For Animals (All-in-One Auto Hub)
    Game: Throw Food For Animals (by Goofy Chupacabra)
    PlaceId: 120219252362013 | UniverseId: 10766972131
    Engineered by: Song Hub / Antigravity
    
    Complete Feature Set:
      - 🍖 Auto Farm (Fast / Instant Throw):
          * Rapid throw cycle: Throw_Start -> Throw_Resolve (1.0 Perfect) -> Throw_Complete
          * Custom delay slider (1.5s - 5.0s, default 1.6s)
          * Auto align to launch line (0, 3.2, -39)
          * Auto Super Lucky Throw when available (Throw_UseSuper)
          * 10x faster progression without waiting for flight animations!
      - 💪 Auto Workout (Throw Power & Levels):
          * Auto Pull-Up Training on plot (TrainingController.Start)
          * Instant Auto Tap Bonus (<10ms reaction) via Training_Bonus event
          * Auto Upgrade Stand for higher XP multipliers (Stand_Upgrade)
      - 🐾 Plot & Animals:
          * Auto Equip Best Animals on plot (Plot_EquipBest)
          * Auto Sell Backpack Animals (Plot_SellAll)
          * Auto Upgrade Fence capacity (Plot_UpgradeFence)
          * Manual instant action buttons
      - 🎁 Rewards & Shop:
          * Auto Claim Free Shop Gifts (Shop_ClaimFree)
          * Auto Claim Offline Cash (Offline_Claim)
          * Auto Buy & Equip Best Food (Shop_Buy & Shop_Equip)
      - ⚡ Ring Rush Minigame:
          * Auto Report and complete Ring Rush (RingRush_Report & RingRush_End)
      - 🚀 Movement & Teleports:
          * WalkSpeed & JumpPower modifiers
          * Anti-AFK system (never disconnect)
          * Plot, Training Bar, Upgrade Sign, Throw Line, and Plot teleports
    ========================================================================
]]

-- 🛡️ Anti-Duplicate / Singleton Guard
getgenv().__ThrowFoodRunId = (getgenv().__ThrowFoodRunId or 0) + 1
local currentRunId = getgenv().__ThrowFoodRunId
local function isAlive()
    return getgenv().__ThrowFoodRunId == currentRunId
end

-- Clean up any previous WindUI windows
if getgenv().__ThrowFoodWindow and typeof(getgenv().__ThrowFoodWindow.Destroy) == "function" then
    pcall(function() getgenv().__ThrowFoodWindow:Destroy() end)
    getgenv().__ThrowFoodWindow = nil
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
end)

-- Safe Module Resolvers
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))
local FoodsConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("FoodsConfig"))
local AreaUtil = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AreaUtil"))

local Controllers = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("Controllers")
local ThrowController = require(Controllers:WaitForChild("ThrowController"))
local TrainingController = require(Controllers:WaitForChild("TrainingController"))
local DataController = require(Controllers:WaitForChild("DataController"))

-- ⚙️ CONFIGURATION TABLE (Keeps local variable count < 200)
local CFG = {
    -- Auto Throw
    AutoThrow = false,
    ThrowDelay = 1.6,
    AutoSuperThrow = true,
    ForcePerfectMeter = true,
    
    -- Auto Workout
    AutoWorkout = false,
    AutoTapBonus = true,
    AutoUpgradeStand = false,
    
    -- Plot & Animals
    AutoEquipBest = false,
    EquipInterval = 5,
    AutoSellAll = false,
    SellInterval = 10,
    AutoUpgradeFence = false,
    
    -- Rewards & Shop
    AutoClaimFree = true,
    AutoClaimOffline = true,
    AutoBuyFood = false,
    
    -- Ring Rush
    AutoRingRush = true,
    
    -- Movement & Safety
    WalkSpeed = 16,
    JumpPower = 50,
    ModifySpeed = false,
    ModifyJump = false,
    AntiAFK = true
}

local STATE = {
    isThrowing = false,
    isTraining = false,
    lastThrowTime = 0,
    lastSellTime = 0,
    lastEquipTime = 0,
    lastUpgradeTime = 0,
    lastRewardCheck = 0,
    totalThrows = 0,
    totalEarned = 0
}

-- 🛠️ HELPER FUNCTIONS
local function getMyPlot()
    local plotIdx = LocalPlayer:GetAttribute("PlotIndex")
    if not plotIdx then return nil end
    local plots = workspace:FindFirstChild("Plots")
    return plots and plots:FindFirstChild(tostring(plotIdx))
end

local function getHRP()
    local char = LocalPlayer.Character or Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character or Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function pivotTo(cf)
    local char = LocalPlayer.Character or Character
    if char then
        char:PivotTo(cf)
    end
end

local function alignToThrowLine()
    local hrp = getHRP()
    if hrp then
        local targetPos = Vector3.new(0, 3.2, -39)
        if (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(0, 0, -39)).Magnitude > 4 or hrp.Position.Z > -38.5 then
            pivotTo(CFrame.new(targetPos))
            task.wait(0.2)
        end
    end
end

-- ==============================================================================
-- 🚀 CORE AUTOMATION LOGIC
-- ==============================================================================

-- 1. Fast Auto Throw (Instant Throw Farm)
local function performFastThrow()
    if not isAlive() then return false end
    if STATE.isThrowing then return false end
    
    local now = os.clock()
    if now - STATE.lastThrowTime < CFG.ThrowDelay then return false end
    
    -- If training is active, stop it first to allow throwing
    if TrainingController.IsRunning() then
        TrainingController.Stop()
        task.wait(0.35)
    end
    
    STATE.isThrowing = true
    alignToThrowLine()
    
    -- Auto Super Throw if toggled
    if CFG.AutoSuperThrow then
        pcall(function()
            Remotes.Invoke("Throw_UseSuper")
        end)
    end
    
    local startRes = Remotes.Invoke("Throw_Start")
    if startRes and startRes.Ok then
        STATE.lastThrowTime = os.clock()
        
        -- Resolve throw with 1.0 (100% Perfect Power)
        local meterVal = CFG.ForcePerfectMeter and 1.0 or 0.95
        local resolveRes = Remotes.Invoke("Throw_Resolve", meterVal)
        
        task.wait(0.05)
        local completeRes = Remotes.Invoke("Throw_Complete")
        
        STATE.totalThrows = STATE.totalThrows + 1
        STATE.isThrowing = false
        return true, resolveRes, completeRes
    elseif startRes and startRes.Reason == "TooFar" then
        -- Reposition character precisely and wait for server replication
        alignToThrowLine()
        task.wait(0.3)
    end
    
    STATE.isThrowing = false
    return false, startRes
end

-- 2. Stand & Fence Upgrades
local function performUpgradeStand()
    local plot = getMyPlot()
    local hrp = getHRP()
    if not plot or not hrp then return false end
    
    local oldCF = hrp.CFrame
    local upPos = plot.Position + GameConfig.Plot.UpgradeButtonOffset
    pivotTo(CFrame.new(upPos + Vector3.new(0, 2.5, 0)))
    task.wait(0.25)
    
    local res = Remotes.Invoke("Stand_Upgrade")
    task.wait(0.1)
    
    -- If auto workout is active, return to workout station, else restore position
    if not CFG.AutoWorkout then
        pivotTo(oldCF)
    end
    return res and res.Ok
end

local function performUpgradeFence()
    local plot = getMyPlot()
    local hrp = getHRP()
    if not plot or not hrp then return false end
    
    local oldCF = hrp.CFrame
    local upPos = plot.Position + GameConfig.Plot.UpgradeButtonOffset
    pivotTo(CFrame.new(upPos + Vector3.new(0, 2.5, 0)))
    task.wait(0.25)
    
    local res = Remotes.Invoke("Plot_UpgradeFence")
    task.wait(0.1)
    
    if not CFG.AutoWorkout then
        pivotTo(oldCF)
    end
    return res and res.Ok
end

-- 3. Equip Best & Sell All Animals
local function performEquipBest()
    local res = Remotes.Invoke("Plot_EquipBest")
    return res and res.Ok
end

local function performSellAll()
    local res = Remotes.Invoke("Plot_SellAll")
    return res and res.Ok
end

-- 4. Shop & Free Rewards
local function performClaimFree()
    local res = Remotes.Invoke("Shop_ClaimFree")
    return res and res.Ok
end

local function performClaimOffline()
    local res = Remotes.Invoke("Offline_Claim")
    return res and res.Ok
end

local function performBuyAndEquipBestFood()
    local count = FoodsConfig.Count()
    local highestOwned = 1
    for i = 1, count do
        local buyRes = Remotes.Invoke("Shop_Buy", i)
        if (buyRes and buyRes.Ok) or (buyRes and buyRes.Reason == "Owned") then
            highestOwned = i
        end
    end
    if highestOwned > 0 then
        Remotes.Invoke("Shop_Equip", highestOwned)
    end
    return highestOwned
end

-- 5. Auto Workout (Pull-up Training)
local function performAutoWorkout()
    if not isAlive() then return end
    if CFG.AutoThrow or STATE.isThrowing then return end
    if TrainingController.IsRunning() then return end
    
    local plot = getMyPlot()
    if not plot then return end
    
    local spotPos = plot.Position + GameConfig.Plot.TrainingSpotOffset
    pivotTo(CFrame.new(spotPos + Vector3.new(0, 2, 0)))
    task.wait(0.25)
    
    TrainingController.Start()
end

-- 6. Instant Auto Tap Bonus Listener (<10ms reaction)
local bonusConnection = Remotes.Event("Training_Bonus").OnClientEvent:Connect(function(bonusData, expires)
    if not isAlive() then return end
    if CFG.AutoTapBonus then
        task.spawn(function()
            local bonusId = type(bonusData) == "table" and bonusData.Id or bonusData
            pcall(function()
                Remotes.Invoke("Training_TapBonus", bonusId)
            end)
        end)
    end
end)

-- 7. Anti-AFK Connection
local idledConnection = LocalPlayer.Idled:Connect(function()
    if not isAlive() then return end
    if CFG.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end
end)

-- 8. WalkSpeed & JumpPower Loop
RunService.Heartbeat:Connect(function()
    if not isAlive() then return end
    local hum = getHumanoid()
    if hum then
        if CFG.ModifySpeed and hum.WalkSpeed ~= CFG.WalkSpeed then
            hum.WalkSpeed = CFG.WalkSpeed
        end
        if CFG.ModifyJump and hum.JumpPower ~= CFG.JumpPower then
            hum.JumpPower = CFG.JumpPower
        end
    end
end)

-- ==============================================================================
-- 🔄 BACKGROUND AUTOMATION THREADS
-- ==============================================================================

-- Loop 1: Auto Throw Loop
task.spawn(function()
    while isAlive() do
        if CFG.AutoThrow then
            pcall(performFastThrow)
            task.wait(CFG.ThrowDelay)
        else
            task.wait(0.5)
        end
    end
end)

-- Loop 2: Auto Workout Loop
task.spawn(function()
    while isAlive() do
        if CFG.AutoWorkout and not CFG.AutoThrow and not STATE.isThrowing then
            if not TrainingController.IsRunning() then
                pcall(performAutoWorkout)
            end
            task.wait(2)
        else
            task.wait(1)
        end
    end
end)

-- Loop 3: Periodic Management (Equip Best, Sell All, Upgrade Stand/Fence, Rewards)
task.spawn(function()
    while isAlive() do
        task.wait(1)
        local now = os.clock()
        
        -- Auto Equip Best Animals
        if CFG.AutoEquipBest and (now - STATE.lastEquipTime >= CFG.EquipInterval) then
            STATE.lastEquipTime = now
            pcall(performEquipBest)
        end
        
        -- Auto Sell Animals in Backpack
        if CFG.AutoSellAll and (now - STATE.lastSellTime >= CFG.SellInterval) then
            STATE.lastSellTime = now
            pcall(performSellAll)
        end
        
        -- Auto Upgrade Stand
        if CFG.AutoUpgradeStand and (now - STATE.lastUpgradeTime >= 15) then
            STATE.lastUpgradeTime = now
            pcall(performUpgradeStand)
        end
        
        -- Auto Upgrade Fence
        if CFG.AutoUpgradeFence and (now - STATE.lastUpgradeTime >= 15) then
            pcall(performUpgradeFence)
        end
        
        -- Auto Free Rewards & Offline Earnings
        if (now - STATE.lastRewardCheck >= 30) then
            STATE.lastRewardCheck = now
            if CFG.AutoClaimFree then pcall(performClaimFree) end
            if CFG.AutoClaimOffline then pcall(performClaimOffline) end
            if CFG.AutoBuyFood then pcall(performBuyAndEquipBestFood) end
        end
    end
end)

-- ==============================================================================
-- 🎨 WINDUI USER INTERFACE CREATION
-- ==============================================================================

local WindUI
if isfile and isfile("WindUI_cache.lua") then
    local cached = readfile("WindUI_cache.lua")
    if cached and #cached > 1000 then
        pcall(function() WindUI = loadstring(cached)() end)
    end
end
if not WindUI then
    local content = game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua")
    WindUI = loadstring(content)()
    if writefile and content then
        pcall(function() writefile("WindUI_cache.lua", content) end)
    end
end

-- Purge residual window objects in cached WindUI
pcall(function()
    if WindUI and WindUI.ScreenGui and WindUI.ScreenGui:FindFirstChild("Window") then
        for _, w in ipairs(WindUI.ScreenGui.Window:GetChildren()) do
            pcall(function() w:Destroy() end)
        end
    end
end)

local Window = WindUI:CreateWindow({
    Title = "Throw Food For Animals | Song Hub",
    Icon = "utensils",
    Folder = "SongHub_ThrowFood",
    Size = UDim2.fromOffset(590, 480),
    Theme = "Dark",
    OpenButton = {
        Title = "Throw Food Hub",
        Icon = "utensils",
        Enabled = true,
        Draggable = true,
    }
})
getgenv().__ThrowFoodWindow = Window

-- TABS
local TabFarm = Window:Tab({ Title = "Auto Farm", Icon = "flame" })
local TabWorkout = Window:Tab({ Title = "Auto Workout", Icon = "zap" })
local TabPlot = Window:Tab({ Title = "Plot & Animals", Icon = "box" })
local TabShop = Window:Tab({ Title = "Rewards & Shop", Icon = "gift" })
local TabPlayer = Window:Tab({ Title = "Movement & World", Icon = "user" })

-- ------------------------------------------------------------------------------
-- 🍖 TAB 1: AUTO FARM (THROW FOOD)
-- ------------------------------------------------------------------------------
TabFarm:Section({ Title = "🍗 Fast Food Throw Farm" })

TabFarm:Toggle({
    Title = "Auto Throw Food (Fast Farm)",
    Desc = "Rapidly throws food without waiting for long flight animations (10x faster!)",
    Value = CFG.AutoThrow,
    Callback = function(v)
        CFG.AutoThrow = v
        if v then
            CFG.AutoWorkout = false -- Avoid conflicting with workout
            WindUI:Notify({ Title = "Auto Throw Started", Content = "Auto throwing food with 100% perfect meter power!", Duration = 3, Icon = "play" })
        end
    end
})

TabFarm:Slider({
    Title = "Throw Interval Delay",
    Desc = "Delay between throws (Server cooldown is 1.5s, recommended: 1.6s)",
    Value = { Min = 1.5, Max = 5.0, Default = 1.6 },
    Callback = function(v)
        CFG.ThrowDelay = tonumber(v) or 1.6
    end
})

TabFarm:Toggle({
    Title = "Auto Super Lucky Throw",
    Desc = "Automatically activates Super Throw when available for maximum animal rarity!",
    Value = CFG.AutoSuperThrow,
    Callback = function(v)
        CFG.AutoSuperThrow = v
    end
})

TabFarm:Toggle({
    Title = "Force 100% Perfect Power",
    Desc = "Always throws with maximum 1.0 (PERFECT!) meter power for greatest distance",
    Value = CFG.ForcePerfectMeter,
    Callback = function(v)
        CFG.ForcePerfectMeter = v
    end
})

TabFarm:Section({ Title = "⚡ Manual Quick Actions" })

TabFarm:Button({
    Title = "Throw Food Once (Fast)",
    Desc = "Executes a single instant throw at maximum distance right now",
    Icon = "arrow-right",
    Callback = function()
        local ok, resolveRes, completeRes = performFastThrow()
        if ok and resolveRes then
            WindUI:Notify({
                Title = "Throw Successful! 🎯",
                Content = string.format("Distance: %.1f studs | Area: %s", resolveRes.Distance or 0, tostring(resolveRes.AreaIndex or 1)),
                Duration = 3,
                Icon = "check-circle"
            })
        else
            WindUI:Notify({ Title = "Throw Notice", Content = "Could not throw (Check cooldown or distance)", Duration = 2.5, Icon = "alert-circle" })
        end
    end
})

-- ------------------------------------------------------------------------------
-- 💪 TAB 2: AUTO WORKOUT (THROW POWER & LEVEL)
-- ------------------------------------------------------------------------------
TabWorkout:Section({ Title = "🏋️ Auto Pull-Up Workout" })

TabWorkout:Toggle({
    Title = "Auto Workout / Training",
    Desc = "Automatically goes to your plot's pull-up station and trains Throw Power",
    Value = CFG.AutoWorkout,
    Callback = function(v)
        CFG.AutoWorkout = v
        if v then
            CFG.AutoThrow = false -- Avoid conflicting with throw
            WindUI:Notify({ Title = "Auto Workout Started", Content = "Training pull-ups on plot to gain Throw Power!", Duration = 3, Icon = "play" })
        else
            if TrainingController.IsRunning() then
                TrainingController.Stop()
            end
        end
    end
})

TabWorkout:Toggle({
    Title = "Instant Auto Tap Bonus (2x XP)",
    Desc = "Reacts instantly (<10ms) to every Training Bonus event for double XP!",
    Value = CFG.AutoTapBonus,
    Callback = function(v)
        CFG.AutoTapBonus = v
    end
})

TabWorkout:Toggle({
    Title = "Auto Upgrade Training Stand",
    Desc = "Automatically upgrades your pull-up stand when affordable to boost XP gain",
    Value = CFG.AutoUpgradeStand,
    Callback = function(v)
        CFG.AutoUpgradeStand = v
    end
})

TabWorkout:Section({ Title = "⚡ Manual Workout Actions" })

TabWorkout:Button({
    Title = "Start Pull-Up Workout Now",
    Desc = "Starts pull-up training immediately",
    Icon = "play",
    Callback = function()
        performAutoWorkout()
    end
})

TabWorkout:Button({
    Title = "Stop Workout Now",
    Desc = "Stops current training session",
    Icon = "square",
    Callback = function()
        if TrainingController.IsRunning() then
            TrainingController.Stop()
            WindUI:Notify({ Title = "Stopped", Content = "Training session stopped.", Duration = 2, Icon = "check" })
        end
    end
})

TabWorkout:Button({
    Title = "Upgrade Training Stand Now",
    Desc = "Attempts to upgrade pull-up stand right now",
    Icon = "chevrons-up",
    Callback = function()
        local ok = performUpgradeStand()
        if ok then
            WindUI:Notify({ Title = "Success! ⭐", Content = "Training stand successfully upgraded!", Duration = 3, Icon = "check-circle" })
        else
            WindUI:Notify({ Title = "Notice", Content = "Cannot upgrade stand yet (Check cash or plot)", Duration = 2.5, Icon = "alert-circle" })
        end
    end
})

-- ------------------------------------------------------------------------------
-- 🐾 TAB 3: PLOT & ANIMALS
-- ------------------------------------------------------------------------------
TabPlot:Section({ Title = "🐾 Animal & Plot Management" })

TabPlot:Toggle({
    Title = "Auto Equip Best Animals",
    Desc = "Automatically places your highest $/s animals on your plot",
    Value = CFG.AutoEquipBest,
    Callback = function(v)
        CFG.AutoEquipBest = v
    end
})

TabPlot:Toggle({
    Title = "Auto Sell Backpack Animals",
    Desc = "Automatically sells unequipped animals stored in your backpack for money",
    Value = CFG.AutoSellAll,
    Callback = function(v)
        CFG.AutoSellAll = v
    end
})

TabPlot:Toggle({
    Title = "Auto Upgrade Fence Capacity",
    Desc = "Automatically upgrades plot fence to increase max animal placement capacity",
    Value = CFG.AutoUpgradeFence,
    Callback = function(v)
        CFG.AutoUpgradeFence = v
    end
})

TabPlot:Section({ Title = "⚡ Instant Plot Actions" })

TabPlot:Button({
    Title = "⭐ Equip Best Animals Now",
    Desc = "Places the most valuable animals on your plot immediately",
    Icon = "star",
    Callback = function()
        local ok = performEquipBest()
        if ok then
            WindUI:Notify({ Title = "Best Animals Equipped! 🎉", Content = "Your top income animals are now active on your plot!", Duration = 3, Icon = "check-circle" })
        end
    end
})

TabPlot:Button({
    Title = "💰 Sell All Backpack Animals Now",
    Desc = "Sells all unequipped animals in backpack for instant cash",
    Icon = "dollar-sign",
    Callback = function()
        local ok = performSellAll()
        if ok then
            WindUI:Notify({ Title = "Animals Sold! 💵", Content = "Backpack animals sold successfully!", Duration = 3, Icon = "check-circle" })
        else
            WindUI:Notify({ Title = "Notice", Content = "No animals in backpack to sell.", Duration = 2, Icon = "info" })
        end
    end
})

TabPlot:Button({
    Title = "Fence Upgrade Now",
    Desc = "Upgrades fence to unlock more animal slots",
    Icon = "layout",
    Callback = function()
        local ok = performUpgradeFence()
        if ok then
            WindUI:Notify({ Title = "Fence Upgraded! 🏗️", Content = "Plot animal capacity increased!", Duration = 3, Icon = "check-circle" })
        else
            WindUI:Notify({ Title = "Notice", Content = "Cannot upgrade fence yet (Need more money)", Duration = 2.5, Icon = "alert-circle" })
        end
    end
})

-- ------------------------------------------------------------------------------
-- 🎁 TAB 4: REWARDS & SHOP
-- ------------------------------------------------------------------------------
TabShop:Section({ Title = "🎁 Free Earnings & Gifts" })

TabShop:Toggle({
    Title = "Auto Claim Free Shop Gifts",
    Desc = "Automatically claims free shop items and gifts every 30 seconds",
    Value = CFG.AutoClaimFree,
    Callback = function(v)
        CFG.AutoClaimFree = v
    end
})

TabShop:Toggle({
    Title = "Auto Claim Offline Earnings",
    Desc = "Automatically claims accumulated offline earnings",
    Value = CFG.AutoClaimOffline,
    Callback = function(v)
        CFG.AutoClaimOffline = v
    end
})

TabShop:Toggle({
    Title = "Auto Buy & Equip Best Food",
    Desc = "Automatically buys any new food unlocked and equips the highest owned food",
    Value = CFG.AutoBuyFood,
    Callback = function(v)
        CFG.AutoBuyFood = v
    end
})

TabShop:Section({ Title = "⚡ Manual Reward Actions" })

TabShop:Button({
    Title = "Claim Free Shop Gift Now",
    Desc = "Claims the daily / free gift immediately",
    Icon = "gift",
    Callback = function()
        local ok = performClaimFree()
        if ok then
            WindUI:Notify({ Title = "Reward Claimed! 🎁", Content = "Free shop reward claimed successfully!", Duration = 3, Icon = "check-circle" })
        else
            WindUI:Notify({ Title = "Notice", Content = "No free gift ready to claim yet.", Duration = 2, Icon = "info" })
        end
    end
})

TabShop:Button({
    Title = "Claim Offline Cash Now",
    Desc = "Claims offline earnings cash immediately",
    Icon = "clock",
    Callback = function()
        local ok = performClaimOffline()
        if ok then
            WindUI:Notify({ Title = "Claimed! 💵", Content = "Offline earnings added to your balance!", Duration = 3, Icon = "check-circle" })
        else
            WindUI:Notify({ Title = "Notice", Content = "No offline earnings waiting.", Duration = 2, Icon = "info" })
        end
    end
})

TabShop:Button({
    Title = "Buy & Equip Highest Food Now",
    Desc = "Buys all affordable foods and equips the best one",
    Icon = "shopping-bag",
    Callback = function()
        local highest = performBuyAndEquipBestFood()
        WindUI:Notify({ Title = "Food Updated! 🍖", Content = "Equipped food #" .. tostring(highest), Duration = 3, Icon = "check-circle" })
    end
})

-- ------------------------------------------------------------------------------
-- 🚀 TAB 5: MOVEMENT & WORLD TELEPORTS
-- ------------------------------------------------------------------------------
TabPlayer:Section({ Title = "🏃 Movement Enhancements" })

TabPlayer:Toggle({
    Title = "Modify WalkSpeed",
    Desc = "Enables custom player movement speed",
    Value = CFG.ModifySpeed,
    Callback = function(v)
        CFG.ModifySpeed = v
        if not v then
            local hum = getHumanoid()
            if hum then hum.WalkSpeed = 16 end
        end
    end
})

TabPlayer:Slider({
    Title = "WalkSpeed Value",
    Desc = "Player walking speed",
    Value = { Min = 16, Max = 150, Default = 16 },
    Callback = function(v)
        CFG.WalkSpeed = tonumber(v) or 16
    end
})

TabPlayer:Toggle({
    Title = "Modify JumpPower",
    Desc = "Enables custom player jump height",
    Value = CFG.ModifyJump,
    Callback = function(v)
        CFG.ModifyJump = v
        if not v then
            local hum = getHumanoid()
            if hum then hum.JumpPower = 50 end
        end
    end
})

TabPlayer:Slider({
    Title = "JumpPower Value",
    Desc = "Player jump force",
    Value = { Min = 50, Max = 250, Default = 50 },
    Callback = function(v)
        CFG.JumpPower = tonumber(v) or 50
    end
})

TabPlayer:Toggle({
    Title = "Anti-AFK Protection",
    Desc = "Prevents Roblox 20-minute idle disconnection",
    Value = CFG.AntiAFK,
    Callback = function(v)
        CFG.AntiAFK = v
    end
})

TabPlayer:Section({ Title = "📍 Quick Teleports" })

TabPlayer:Button({
    Title = "Teleport: My Plot (Entrance)",
    Desc = "Teleports to the entrance of your assigned plot",
    Icon = "home",
    Callback = function()
        local plot = getMyPlot()
        if plot then
            pivotTo(CFrame.new(plot.Position + GameConfig.Plot.EntranceOffset))
            WindUI:Notify({ Title = "Teleported", Content = "Arrived at Plot Entrance.", Duration = 2, Icon = "check" })
        end
    end
})

TabPlayer:Button({
    Title = "Teleport: Pull-Up Bar (Workout)",
    Desc = "Teleports to your plot's workout pull-up bar",
    Icon = "activity",
    Callback = function()
        local plot = getMyPlot()
        if plot then
            pivotTo(CFrame.new(plot.Position + GameConfig.Plot.TrainingSpotOffset + Vector3.new(0, 2, 0)))
            WindUI:Notify({ Title = "Teleported", Content = "Arrived at Pull-Up Station.", Duration = 2, Icon = "check" })
        end
    end
})

TabPlayer:Button({
    Title = "Teleport: Upgrade Sign",
    Desc = "Teleports in front of the Stand & Fence Upgrade Sign",
    Icon = "chevrons-up",
    Callback = function()
        local plot = getMyPlot()
        if plot then
            pivotTo(CFrame.new(plot.Position + GameConfig.Plot.UpgradeButtonOffset + Vector3.new(0, 2, 0)))
            WindUI:Notify({ Title = "Teleported", Content = "Arrived at Upgrade Sign.", Duration = 2, Icon = "check" })
        end
    end
})

TabPlayer:Button({
    Title = "Teleport: Throw Line (Starter Area)",
    Desc = "Teleports to the food launch line",
    Icon = "crosshair",
    Callback = function()
        pivotTo(CFrame.new(0, 3.2, -39))
        WindUI:Notify({ Title = "Teleported", Content = "Arrived at Throw Line.", Duration = 2, Icon = "check" })
    end
})

TabPlayer:Button({
    Title = "Teleport: Food Shop Circle",
    Desc = "Teleports to the Food Shop purchase circle on your plot",
    Icon = "shopping-cart",
    Callback = function()
        local plot = getMyPlot()
        if plot then
            pivotTo(CFrame.new(plot.Position + GameConfig.Plot.ShopCircleOffset + Vector3.new(0, 2, 0)))
            WindUI:Notify({ Title = "Teleported", Content = "Arrived at Food Shop Circle.", Duration = 2, Icon = "check" })
        end
    end
})

TabPlayer:Button({
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

-- Welcome Notification
WindUI:Notify({
    Title = "Song Hub Loaded! 🍗",
    Content = "Throw Food For Animals Hub v1.0 active!\nAuto Farm & Workout ready to roll.",
    Duration = 5,
    Icon = "check-circle"
})

print("[Song Hub] ✅ Throw Food For Animals Hub successfully initialized!")
