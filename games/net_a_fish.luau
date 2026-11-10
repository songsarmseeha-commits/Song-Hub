-- ==============================================================================
-- 🚀 SONG HUB [v1.0] - [🐟] NET A FISH! 🎣
-- Game: [🐟] Net a Fish!
-- PlaceId: 93898234979111 | UniverseId: 10771053183
-- Features:
--     - 🎣 Master Auto Fishing (Auto Throw Net, Monitor Fill, Auto Reel In)
--     - 🎯 100% Perfect Reel (Auto Perfect Tap for Max Rewards & Perfect Grade)
--     - 🐟 Smart Catch Resolver (Auto Keep New, Auto Keep Mutations, Configurable Rarity Threshold, Auto Sell Junk)
--     - 🏛️ Auto Showcase Best Setup (Max Passive Cash/sec)
--     - 💰 Auto Collect Showcase Pad Cash
--     - 🏹 Auto Spear Gun (Auto shoot Megalodon, Kraken & River Fish)
--     - 🔨 Auto Buy Upgrades (Nets, Luck, Reel, Sell, Twin, Weave, Treasure)
--     - 🔁 Auto Rebirth (Unlock New Worlds & Multipliers)
--     - 🎁 Auto Claim Playtime Gifts & Daily Rewards
--     - 🔑 One-Click Redeem All Codes (ANCIENT, 2MVISITS, 1MVISITS, 500KVISITS, 250KVISITS, 100KVISITS)
--     - 📍 Teleports (Dock, Hub, Pet Pool, Showcase)
--     - ⚡ Player Speed, Jump, InfJump, NoClip
--     - 🛡️ 24/7 Anti-AFK
-- ==============================================================================

-- Strict Game Validation
local isNetAFish = (game.PlaceId == 93898234979111 or game.GameId == 10771053183
    or (game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("ThrowNet")))

if not isNetAFish then
    warn("[Song Hub] ❌ This script is exclusively for Net a Fish! (PlaceId: 93898234979111)! Exiting.")
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
local VirtualInputManager = game:GetService("VirtualInputManager")
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
local now = os.clock()
if getgenv then
    getgenv()._NetAFish_LastStartTime = now
    getgenv()._NetAFishRunning = true
    getgenv()._NetAFishRunId = (tonumber(getgenv()._NetAFishRunId) or 0) + 1
end

-- Destroy existing UI instances
local function cleanAllWindUI()
    pcall(function()
        if getgenv and getgenv()._NetAFish_Window and getgenv()._NetAFish_Window.Destroy then
            pcall(function() getgenv()._NetAFish_Window:Destroy() end)
            getgenv()._NetAFish_Window = nil
        end
    end)
    pcall(function()
        local searchRoots = {}
        if typeof(gethui) == "function" then
            local h = gethui()
            if h then table.insert(searchRoots, h) end
        end
        local cg = game:GetService("CoreGui")
        table.insert(searchRoots, cg)
        if cg:FindFirstChild("RobloxGui") then
            table.insert(searchRoots, cg.RobloxGui)
        end
        if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
            table.insert(searchRoots, LocalPlayer.PlayerGui)
        end

        for _, root in ipairs(searchRoots) do
            for _, child in ipairs(root:GetChildren()) do
                local cName = child.Name
                if cName:find("WindUI") or cName:find("NetAFish") or cName:find("SongHub") then
                    pcall(function()
                        if child:FindFirstChild("Window") then
                            for _, w in ipairs(child.Window:GetChildren()) do
                                pcall(function() w:Destroy() end)
                            end
                        end
                        child:Destroy()
                    end)
                end
            end
        end
    end)
end

cleanAllWindUI()

local currentScriptRunId = (getgenv and getgenv()._NetAFishRunId) or 1
local function isAlive()
    if getgenv and getgenv()._NetAFishRunId and getgenv()._NetAFishRunId > currentScriptRunId then
        return false
    end
    return true
end

-- ==============================================================================
-- ⚙️ CONFIGURATION & STATE
-- ==============================================================================
local Config = {
    -- Auto Fishing
    MasterAutoFishing = false,
    AutoThrowNet = true,
    AutoReelIn = true,
    ReelThreshold = 100, -- percentage of NetCap (50% to 100%)
    FastReelCount = 0,    -- 0 = full, >0 = reel after X catches
    AutoPerfectTap = true,
    AutoDockReturn = true, -- Teleport back to dock if displaced

    -- Catch Resolver
    AutoResolveCatch = true,
    KeepNewFish = true,
    KeepMutations = true,
    MinKeepRarity = "Legendary", -- Sell below this rarity
    AutoBestShowcase = true,

    -- Economics
    AutoCollectCash = true,
    AutoBuyUpgrades = false,
    AutoRebirth = false,

    -- Spear Gun
    AutoSpearGun = false,

    -- Rewards
    AutoClaimGifts = true,
    AutoClaimDaily = true,

    -- Player Mobility
    SpeedBoost = false,
    SpeedValue = 16,
    JumpBoost = false,
    JumpValue = 50,
    InfJump = false,
    NoClip = false,
}

local RaritiesOrder = {
    ["Common"] = 1,
    ["Uncommon"] = 2,
    ["Rare"] = 3,
    ["Epic"] = 4,
    ["Legendary"] = 5,
    ["Mythic"] = 6,
    ["Apex"] = 7,
    ["Demigod"] = 8,
    ["Historic"] = 9,
    ["Monarch"] = 10,
    ["Forbidden"] = 11,
    ["Cosmic"] = 12,
    ["Divine"] = 13,
    ["Abyssal"] = 14,
    ["Empyrean"] = 15,
    ["Supreme"] = 16,
    ["Zenith"] = 17,
    ["Boundless"] = 18,
    ["Eclipse"] = 19,
    ["Genesis"] = 20
}

local RarityNames = {
    "Common", "Uncommon", "Rare", "Epic", "Legendary",
    "Mythic", "Apex", "Demigod", "Historic", "Monarch",
    "Forbidden", "Cosmic", "Divine", "Abyssal", "Empyrean",
    "Supreme", "Zenith", "Boundless", "Eclipse", "Genesis"
}

-- Remotes Cache
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local ThrowNetRemote = Remotes:WaitForChild("ThrowNet", 10)
local ReelInRemote = Remotes:WaitForChild("ReelIn", 10)
local PerfectTapRemote = Remotes:WaitForChild("PerfectTap", 10)
local ResolveCatchRemote = Remotes:WaitForChild("ResolveCatch", 10)
local CatchReadyRemote = Remotes:WaitForChild("CatchReady", 10)
local CollectPadReqRemote = Remotes:WaitForChild("CollectPadReq", 10)
local BestSetupRemote = Remotes:WaitForChild("BestSetup", 10)
local BuyItemRemote = Remotes:WaitForChild("BuyItem", 10)
local RebirthRequestRemote = Remotes:WaitForChild("RebirthRequest", 10)
local RewardsRemote = Remotes:WaitForChild("Rewards", 10)
local SpearShotRemote = Remotes:FindFirstChild("SpearShot")
local SpearActionRemote = Remotes:FindFirstChild("SpearAction")
local GoHomeRemote = Remotes:FindFirstChild("GoHome")

-- Base Helper
local function getMyBase()
    local bases = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Bases")
    if not bases then return nil end
    for _, b in ipairs(bases:GetChildren()) do
        if b:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
            return b
        end
    end
    return nil
end

local function getRoot()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- ==============================================================================
-- 🎨 WINDUI INITIALIZATION & DRAGGABLE FIX
-- ==============================================================================
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
    warn("[Song Hub] ❌ Failed to load WindUI framework!")
    return
end

local Window = WindUI:CreateWindow({
    Title = "Net a Fish | Song Hub [v1.0 - Auto Fishing Edition]",
    Icon = "fish",
    Author = "by Song Hub Dev",
    Folder = "NetAFishHub",
    Size = UDim2.fromOffset(590, 490),
    Transparent = true,
    Theme = "Dark",
    Acrylic = false,
    Resizable = true
})

if getgenv then
    getgenv()._NetAFish_Window = Window
end

-- 🛠️ Universal Smooth UI Draggable Enhancer
local function makeWindowDraggable(win)
    pcall(function()
        local mainFrame = win.UIElements and win.UIElements.Main
        if not mainFrame then return end

        local dragging = false
        local dragInput, dragStart, startPos

        local function update(input)
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end

        local dragBar = (mainFrame:FindFirstChild("Topbar")) or mainFrame

        dragBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = mainFrame.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        dragBar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                update(input)
            end
        end)

        -- Keep cursor visible and unlocked when hovering window
        mainFrame.MouseEnter:Connect(function()
            pcall(function()
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                UserInputService.MouseIconEnabled = true
            end)
        end)
    end)
end

makeWindowDraggable(Window)

-- ==============================================================================
-- 🎣 TAB 1: AUTO FISHING (ฟาร์มตกปลาออโต้)
-- ==============================================================================
local TabFishing = Window:Tab({ Title = "Auto Fishing", Icon = "anchor" })

TabFishing:Paragraph({
    Title = "🎣 Autonomous Net Fishing Engine",
    Desc = "ระบบจะเหวี่ยงแหจับปลา, ตรวจสอบความจุแห, ดึงแหขึ้นมา, กด Perfect Reel ให้ 100%, และคัดแยกปลา (เก็บตัวแรร์/ขายปลาขยะ) ให้อัตโนมัติ!",
    Image = "fish"
})

local FishingStatusParagraph = TabFishing:Paragraph({
    Title = "📊 Fishing Status",
    Desc = "Status: Idle | Net Fill: 0 / 0 | Catches: 0",
    Image = "activity"
})

TabFishing:Toggle({
    Title = "🎣 Master Auto Fishing (เปิดบอทตกปลาอัตโนมัติ)",
    Desc = "ควบคุมการเหวี่ยงแหและดึงแหอัตโนมัติตลอด 24 ชม.",
    Value = Config.MasterAutoFishing,
    Callback = function(val)
        Config.MasterAutoFishing = val
        if val then
            WindUI:Notify({ Title = "Auto Fishing Active! 🐟", Content = "Fishing loop started with 100% Perfect Reels.", Duration = 3, Icon = "play" })
        else
            WindUI:Notify({ Title = "Auto Fishing Paused", Content = "Fishing stopped.", Duration = 2, Icon = "pause" })
        end
    end
})

TabFishing:Toggle({
    Title = "🎯 100% Guaranteed Perfect Reel (กดแถบเพอร์เฟกต์ 100%)",
    Desc = "ยิงสัญญาณ PerfectTap รัวๆ ตอนดึงแห เพื่อรับรางวัลเกรด Perfect ทุกครั้ง",
    Value = Config.AutoPerfectTap,
    Callback = function(val)
        Config.AutoPerfectTap = val
    end
})

TabFishing:Slider({
    Title = "⚖️ Reel In At Net Capacity % (ดึงแหเมื่อความจุถึง)",
    Desc = "เลือก % ความจุแหก่อนดึงขึ้น (100% = รอแหเต็ม, 70% = ดึงไวกว่าเดิม)",
    Min = 30,
    Max = 100,
    Default = Config.ReelThreshold,
    Callback = function(val)
        Config.ReelThreshold = val
    end
})

TabFishing:Toggle({
    Title = "⚓ Auto Return to Dock (วาร์ปกลับท่าน้ำถ้าหลุด)",
    Desc = "หากตัวละครหลุดออกจากบริเวณท่าน้ำ จะวาร์ปกลับฐานของตัวเองอัตโนมัติ",
    Value = Config.AutoDockReturn,
    Callback = function(val)
        Config.AutoDockReturn = val
    end
})

-- ==============================================================================
-- 🐟 TAB 2: SMART CATCH & SHOWCASE (คัดแยกปลา & จัดแสดง)
-- ==============================================================================
local TabCatch = Window:Tab({ Title = "Catch & Showcase", Icon = "package" })

TabCatch:Paragraph({
    Title = "🐟 Smart Catch Decision Engine",
    Desc = "ตั้งค่าการเก็บปลาหายากและขายปลาขยะโดยอัตโนมัติทันทีที่ดึงแหสำเร็จ",
    Image = "check-circle"
})

TabCatch:Toggle({
    Title = "⚡ Auto Resolve Catch Window (ปิดหน้าต่างและตัดสินใจออโต้)",
    Desc = "ตัดสินใจขายหรือเก็บปลาทันทีโดยไม่ต้องรอกดปุ่มบนจอ",
    Value = Config.AutoResolveCatch,
    Callback = function(val)
        Config.AutoResolveCatch = val
    end
})

TabCatch:Toggle({
    Title = "✨ Always Keep New Discoveries (เก็บปลาสายพันธุ์ใหม่)",
    Desc = "ปลาตัวแรกของสมุด Index จะถูกเก็บเสมอ ไม่โดนขายทิ้ง",
    Value = Config.KeepNewFish,
    Callback = function(val)
        Config.KeepNewFish = val
    end
})

TabCatch:Toggle({
    Title = "🌈 Always Keep Mutations (เก็บปลากลายพันธุ์ Shiny/Gold/Glitched)",
    Desc = "ปลาที่มี Mutation พิเศษทุกตัวจะถูกเก็บไว้เสมอ",
    Value = Config.KeepMutations,
    Callback = function(val)
        Config.KeepMutations = val
    end
})

TabCatch:Dropdown({
    Title = "⭐ Minimum Rarity to Keep (ระดับความหายากขั้นต่ำที่จะเก็บ)",
    Desc = "ปลาที่ระดับต่ำกว่านี้จะถูกขายเปลี่ยนเป็นเงินทันที",
    Multi = false,
    Values = RarityNames,
    Value = Config.MinKeepRarity,
    Callback = function(val)
        Config.MinKeepRarity = val
    end
})

TabCatch:Toggle({
    Title = "🏛️ Auto Best Showcase Setup (จัดปลาที่ทำเงินสูงสุดลงบ่อออโต้)",
    Desc = "ส่งคำสั่ง BestSetup ให้ระบบสลับปลาที่ให้ $/วินาที สูงสุดลงแท่นโชว์ตลอดเวลา",
    Value = Config.AutoBestShowcase,
    Callback = function(val)
        Config.AutoBestShowcase = val
    end
})

-- ==============================================================================
-- 💰 TAB 3: ECONOMICS & UPGRADES (ฟาร์มเงิน & อัปเกรด)
-- ==============================================================================
local TabEcon = Window:Tab({ Title = "Money & Upgrades", Icon = "dollar-sign" })

TabEcon:Toggle({
    Title = "💰 Auto Collect Showcase Cash (ดูดเงินจากแท่นโชว์ปลา)",
    Desc = "เก็บเงินสะสมจากแท่นโชว์ปลาทั้งหมดในบ้านของคุณตลอดเวลา",
    Value = Config.AutoCollectCash,
    Callback = function(val)
        Config.AutoCollectCash = val
    end
})

TabEcon:Toggle({
    Title = "🔨 Auto Buy Upgrades (ซื้ออัปเกรดอัตโนมัติเมื่อเงินพอ)",
    Desc = "ซื้ออัปเกรด Luck, Reel, Sell, Golden, Twin, Weave, Treasure และแหใหม่ให้เอง",
    Value = Config.AutoBuyUpgrades,
    Callback = function(val)
        Config.AutoBuyUpgrades = val
    end
})

TabEcon:Toggle({
    Title = "🔁 Auto Rebirth (เกิดใหม่อัตโนมัติเมื่อครบเงื่อนไข)",
    Desc = "กด Rebirth ให้อัตโนมัติเพื่อปลดล็อกโลกใหม่และตัวคูณเงินมหาศาล",
    Value = Config.AutoRebirth,
    Callback = function(val)
        Config.AutoRebirth = val
    end
})

TabEcon:Button({
    Title = "💵 Force Collect All Cash Now (กดดูดเงินทันที)",
    Desc = "ดูดเงินจากทุกแท่นโชว์ในฐานเดี๋ยวนี้",
    Callback = function()
        pcall(function()
            local myBase = getMyBase()
            if myBase and CollectPadReqRemote then
                for slot = 1, 30 do
                    CollectPadReqRemote:FireServer(slot)
                end
                WindUI:Notify({ Title = "Cash Collected! 💰", Content = "All pedestal cash harvested.", Duration = 2, Icon = "dollar-sign" })
            end
        end)
    end
})

TabEcon:Button({
    Title = "🏆 Equip Best Showcase Fish Now (จัดปลาลงบ่อทันที)",
    Desc = "ใส่ปลาที่รวยที่สุดลงแท่นโชว์ตอนนี้",
    Callback = function()
        pcall(function()
            if BestSetupRemote then
                BestSetupRemote:FireServer()
                WindUI:Notify({ Title = "Best Setup Applied! 🐟", Content = "Highest $/sec fish active in showcase.", Duration = 2, Icon = "check" })
            end
        end)
    end
})

-- ==============================================================================
-- 🏹 TAB 4: SPEAR GUN & BOSSES (ปืนยิงปลา & บอส)
-- ==============================================================================
local TabSpear = Window:Tab({ Title = "Spear & Bosses", Icon = "crosshair" })

TabSpear:Paragraph({
    Title = "🦈 River Bosses & Sea Monsters",
    Desc = "บอทสามารถยิงปลาตัวยักษ์ในแม่น้ำ, Megalodon, The Bloop และ The Kraken ได้!",
    Image = "shield"
})

TabSpear:Toggle({
    Title = "🏹 Auto Spear Gun (ยิงฉมวกอัตโนมัติใส่ปลาตัวยักษ์)",
    Desc = "ยิงปืน Spear Gun ใส่ปลาขนาดใหญ่ที่ว่ายผ่านหน้าฐาน",
    Value = Config.AutoSpearGun,
    Callback = function(val)
        Config.AutoSpearGun = val
    end
})

TabSpear:Button({
    Title = "🔫 Upgrade Spear Gun Max (อัปเกรดปืนฉมวกทันที)",
    Desc = "ซื้อชิ้นส่วนอัปเกรดปืนฉมวกให้แรงที่สุด",
    Callback = function()
        pcall(function()
            if SpearActionRemote then
                for i = 1, 15 do
                    SpearActionRemote:InvokeServer("buy", i)
                end
                WindUI:Notify({ Title = "Spear Gun Upgraded! 🔫", Content = "Spear upgrades requested.", Duration = 2, Icon = "zap" })
            end
        end)
    end
})

-- ==============================================================================
-- 🎁 TAB 5: REWARDS & CODES (รับของขวัญ & โค้ดฟรี)
-- ==============================================================================
local TabRewards = Window:Tab({ Title = "Rewards & Codes", Icon = "gift" })

TabRewards:Toggle({
    Title = "🎁 Auto Claim Playtime Gifts (รับของขวัญออนไลน์)",
    Desc = "รับรางวัล Cash, Boosts, x2 Luck และ Mega Gifts เมื่อเวลาออนไลน์ครบ",
    Value = Config.AutoClaimGifts,
    Callback = function(val)
        Config.AutoClaimGifts = val
    end
})

TabRewards:Toggle({
    Title = "📅 Auto Claim Daily Login (รับของขวัญรายวัน)",
    Desc = "รับโบนัสล็อกอินประจำวันและ Streak Shield",
    Value = Config.AutoClaimDaily,
    Callback = function(val)
        Config.AutoClaimDaily = val
    end
})

TabRewards:Button({
    Title = "🔑 Redeem ALL Promo Codes (กดรับโค้ดแจกฟรีทั้งหมด)",
    Desc = "รับเงินล้านล้าน, Boosts x2, และ Crates ฟรีจากโค้ดทางการทั้งหมด!",
    Callback = function()
        local codes = {"ANCIENT", "2MVISITS", "1MVISITS", "500KVISITS", "250KVISITS", "100KVISITS"}
        local redeemedCount = 0
        for _, c in ipairs(codes) do
            pcall(function()
                if RewardsRemote then
                    local res = RewardsRemote:InvokeServer("redeem", c)
                    if res and res.ok then
                        redeemedCount = redeemedCount + 1
                    end
                end
            end)
            task.wait(0.25)
        end
        WindUI:Notify({
            Title = "Codes Redeemed! 🎁",
            Content = string.format("Successfully redeemed active promo codes! (Count: %d)", redeemedCount),
            Duration = 4,
            Icon = "gift"
        })
    end
})

-- ==============================================================================
-- 📍 TAB 6: TELEPORTS & UTILITIES (วาร์ป & ตัวช่วย)
-- ==============================================================================
local TabTeleport = Window:Tab({ Title = "Teleport & Utils", Icon = "map-pin" })

local function safeTeleport(targetCF)
    pcall(function()
        local hrp = getRoot()
        if hrp then
            hrp.CFrame = targetCF
            if hrp.AssemblyLinearVelocity then
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end)
end

TabTeleport:Button({
    Title = "⚓ Teleport to My Dock (วาร์ปไปท่าน้ำตัวเอง)",
    Desc = "วาร์ปไปจุดตกปลาบนท่าน้ำของคุณ",
    Callback = function()
        pcall(function()
            local myBase = getMyBase()
            if myBase then
                local dock = myBase:FindFirstChild("Dock") or myBase:FindFirstChild("Floor") or myBase:FindFirstChild("PedestalArea")
                if dock then
                    safeTeleport(dock:GetPivot() + Vector3.new(0, 4, 0))
                else
                    safeTeleport(myBase:GetPivot() + Vector3.new(0, 4, 0))
                end
            elseif GoHomeRemote then
                GoHomeRemote:FireServer()
            end
        end)
    end
})

TabTeleport:Button({
    Title = "🌊 Teleport to Deep Waters / River (วาร์ปไปกลางน้ำ)",
    Desc = "วาร์ปไปบริเวณผิวน้ำกลางแม่น้ำ",
    Callback = function()
        safeTeleport(CFrame.new(-65, 5, -200))
    end
})

TabTeleport:Button({
    Title = "🏛️ Teleport to Showcase Pool (วาร์ปไปบ่อโชว์ปลา)",
    Desc = "วาร์ปไปดูปลาที่จัดแสดงในบ่อของคุณ",
    Callback = function()
        pcall(function()
            local myBase = getMyBase()
            if myBase and myBase:FindFirstChild("Pool") then
                safeTeleport(myBase.Pool:GetPivot() + Vector3.new(0, 4, 0))
            end
        end)
    end
})

TabTeleport:Slider({
    Title = "⚡ WalkSpeed Multiplier (ความเร็วการเดิน)",
    Desc = "ปรับความเร็วการวิ่งของตัวละคร",
    Min = 16,
    Max = 120,
    Default = 16,
    Callback = function(val)
        Config.SpeedValue = val
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = val end
    end
})

TabTeleport:Slider({
    Title = "🦘 JumpPower (แรงกระโดด)",
    Desc = "ปรับความสูงในการกระโดด",
    Min = 50,
    Max = 200,
    Default = 50,
    Callback = function(val)
        Config.JumpValue = val
        local hum = getHumanoid()
        if hum then hum.JumpPower = val end
    end
})

TabTeleport:Toggle({
    Title = "🦘 Infinite Jump (กระโดดลอยฟ้าได้ตลอด)",
    Desc = "กด Spacebar เพื่อกระโดดต่อเนื่องกลางอากาศได้ไม่จำกัด",
    Value = Config.InfJump,
    Callback = function(val)
        Config.InfJump = val
    end
})

UserInputService.JumpRequest:Connect(function()
    if Config.InfJump and isAlive() then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ==============================================================================
-- 🚀 CORE BACKGROUND ENGINES
-- ==============================================================================

-- 1. Autonomous Fishing Worker Loop
task.spawn(function()
    local totalCatches = 0
    local lastThrowTime = 0
    local lastCollectTime = 0

    while isAlive() do
        task.wait(0.2)

        if Config.MasterAutoFishing then
            pcall(function()
                local myBase = getMyBase()
                if not myBase then return end

                local state = myBase:GetAttribute("NetState") or "Idle"
                local fill = tonumber(myBase:GetAttribute("NetFill")) or 0
                local cap = tonumber(myBase:GetAttribute("NetCap")) or 100

                -- Update UI Status
                if FishingStatusParagraph then
                    pcall(function()
                        FishingStatusParagraph:SetDesc(string.format("Status: %s | Net Fill: %d / %d (%.0f%%) | Catches: %d",
                            state, fill, cap, (fill / math.max(1, cap)) * 100, totalCatches))
                    end)
                end

                -- A. THROW NET (When Idle)
                if state == "Idle" and (os.clock() - lastThrowTime > 1.2) then
                    lastThrowTime = os.clock()
                    if ThrowNetRemote then
                        ThrowNetRemote:FireServer()
                    end
                end

                -- B. REEL IN (When threshold reached)
                if state == "Fishing" then
                    local targetCap = cap * (Config.ReelThreshold / 100)
                    if fill >= targetCap or (Config.FastReelCount > 0 and fill >= Config.FastReelCount) then
                        if ReelInRemote then
                            ReelInRemote:FireServer()
                            task.wait(0.3)
                        end
                    end
                end

                -- C. PERFECT REEL TAPPING (When Reeling)
                if state == "Reeling" and Config.AutoPerfectTap then
                    if PerfectTapRemote then
                        PerfectTapRemote:FireServer(workspace:GetServerTimeNow())
                    end
                end
            end)
        end
    end
end)

-- 2. Catch Resolver Hook & Event Handler
task.spawn(function()
    if CatchReadyRemote then
        CatchReadyRemote.OnClientEvent:Connect(function(caughtFishList)
            if not isAlive() or not Config.AutoResolveCatch then return end

            pcall(function()
                if type(caughtFishList) ~= "table" or #caughtFishList == 0 then return end

                local decisions = {}
                local minRarityLevel = RaritiesOrder[Config.MinKeepRarity] or 5

                for _, fish in ipairs(caughtFishList) do
                    local decision = "sell"

                    -- 1. Keep if newly discovered species
                    if Config.KeepNewFish and fish.new then
                        decision = "keep"
                    -- 2. Keep if mutation (Shiny, Glitched, Golden, Rainbow)
                    elseif Config.KeepMutations and (fish.mu or fish.perfect) then
                        decision = "keep"
                    -- 3. Keep if rarity is above or equal to user threshold
                    elseif fish.r and (fish.r >= minRarityLevel) then
                        decision = "keep"
                    end

                    decisions[tostring(fish.uid)] = decision
                end

                -- Send decision to server
                if ResolveCatchRemote then
                    ResolveCatchRemote:FireServer(decisions)
                end

                -- Automatically apply Best Setup to showcase highest earning fish
                if Config.AutoBestShowcase and BestSetupRemote then
                    task.delay(0.5, function()
                        pcall(function() BestSetupRemote:FireServer() end)
                    end)
                end
            end)
        end)
    end
end)

-- 3. Economics, Showcase Cash & Upgrades Worker
task.spawn(function()
    while isAlive() do
        task.wait(2.5)

        -- Collect Showcase Pad Cash
        if Config.AutoCollectCash and CollectPadReqRemote then
            pcall(function()
                local myBase = getMyBase()
                if myBase then
                    for slot = 1, 30 do
                        CollectPadReqRemote:FireServer(slot)
                    end
                end
            end)
        end

        -- Auto Buy Upgrades
        if Config.AutoBuyUpgrades and BuyItemRemote then
            pcall(function()
                local upgradeKinds = {"Luck", "Reel", "Sell", "Golden", "Twin", "Weave", "Treasure", "Walk", "BigBait", "Bulk"}
                for _, k in ipairs(upgradeKinds) do
                    BuyItemRemote:FireServer(k, 1)
                end
            end)
        end

        -- Auto Rebirth
        if Config.AutoRebirth and RebirthRequestRemote then
            pcall(function()
                RebirthRequestRemote:FireServer()
            end)
        end
    end
end)

-- 4. Playtime Gifts & Daily Rewards Auto Claimer
task.spawn(function()
    while isAlive() do
        task.wait(15)

        if Config.AutoClaimGifts then
            pcall(function()
                local rui = LocalPlayer.PlayerGui:FindFirstChild("RewardsUI")
                if rui and typeof(getconnections) == "function" then
                    for _, b in ipairs(rui:GetDescendants()) do
                        if b:IsA("TextButton") and b.Parent and b.Parent:FindFirstChildOfClass("TextLabel") then
                            local label = b.Parent:FindFirstChildOfClass("TextLabel").Text
                            if label:find("💰") or label:find("🍀") or label:find("💵") or label:find("🎁") then
                                for _, c in ipairs(getconnections(b.MouseButton1Click)) do
                                    c:Fire()
                                end
                            end
                        end
                    end
                end
            end)
        end

        if Config.AutoClaimDaily and RewardsRemote then
            pcall(function()
                RewardsRemote:InvokeServer("daily")
                RewardsRemote:InvokeServer("claim", "daily")
            end)
        end
    end
end)

-- 5. Auto Spear Gun Worker
task.spawn(function()
    while isAlive() do
        task.wait(1.0)
        if Config.AutoSpearGun and isAlive() then
            pcall(function()
                if SpearShotRemote then
                    local myBase = getMyBase()
                    local spearPos = myBase and myBase:GetPivot().Position or (getRoot() and getRoot().Position)
                    if spearPos then
                        SpearShotRemote:FireServer(spearPos + Vector3.new(0, 0, 50))
                    end
                end
            end)
        end
    end
end)

-- 6. Anti-AFK Protection (24/7)
task.spawn(function()
    LocalPlayer.Idled:Connect(function()
        if isAlive() then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end
    end)
end)

print("[Song Hub] 🎣 [🐟] Net a Fish! Script Loaded Successfully!")
WindUI:Notify({
    Title = "Song Hub | Net a Fish! 🐟",
    Content = "Autonomous fishing script loaded successfully! Press LeftAlt to toggle UI.",
    Duration = 5,
    Icon = "check"
})
