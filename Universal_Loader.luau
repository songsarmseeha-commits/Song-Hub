-- ==============================================================================
-- 🚀 SONG HUB - UNIVERSAL LOADER (POWERED BY CLOUDFLARE EDGE AUTH)
-- Supported Games:
--   1. ⚔️  Anime Galaxies (PlaceId: 83869074416117 / 85423571424083)
--   2. 🎃 Hunting Together (Universe: 10769401924 / Place: 117483759937632)
--   3. ⚽ Blue Lock Farm (Universe: 10700618962 / Place: 132767904294856)
--   4. 🥪 Throw Food For Animals (Universe: 10766972131 / Place: 120219252362013)
--   5. 🏎️  Raycity RB (Universe: 10772794231 / Place: 117419079466193)
--   6. ⚔️  GloryBound (Universe: 10768652372 / Place: 137629355240872)
--   7. 📖 Era dos Grimórios (Universe: 10770749098 / Place: 120299741604934)
--   8. 🐟 Net a Fish! (Universe: 10771053183 / Place: 93898234979111)
-- ==============================================================================

if getgenv then
    getgenv()._SongHubLoading = false
    getgenv()._SongHubLastLoad = os.clock()
end

if not game:IsLoaded() then
    pcall(function() game.Loaded:Wait() end)
    local t0 = tick()
    while not game:IsLoaded() and (tick() - t0) < 20 do
        task.wait(0.25)
    end
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    local t0 = tick()
    while not Players.LocalPlayer and (tick() - t0) < 15 do
        task.wait(0.25)
    end
    LocalPlayer = Players.LocalPlayer
end

-- ==============================================================================
-- 1. DETECT GAME
-- ==============================================================================
local function detectGame()
    local pId = game.PlaceId
    local uId = game.GameId
    local t0 = tick()
    while (uId == 0 or pId == 0) and (tick() - t0 < 3) do
        task.wait(0.2)
        pId = game.PlaceId
        uId = game.GameId
    end

    -- 0. Net a Fish! 🐟
    if uId == 10771053183 or pId == 93898234979111
        or (game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("ThrowNet")) then
        return "Net a Fish! 🐟", "net_a_fish.luau"
    end

    -- 0.1 Era dos Grimórios 📖 (Check first)
    if uId == 10770749098 or pId == 120299741604934
        or (game:GetService("ReplicatedStorage"):FindFirstChild("Rep_Core") and game:GetService("ReplicatedStorage").Rep_Core:FindFirstChild("Magics"))
        or (game:GetService("ReplicatedStorage"):FindFirstChild("Rep_Core") and game:GetService("ReplicatedStorage").Rep_Core:FindFirstChild("Events") and game:GetService("ReplicatedStorage").Rep_Core.Events:FindFirstChild("GrimoireSpinsV2")) then
        return "Era dos Grimórios 📖", "era_dos_grimorios.luau"
    end

    -- 1. GloryBound ⚔️  (Check first or by unique remotes)
    if uId == 10768652372 or pId == 137629355240872
        or (game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and (game:GetService("ReplicatedStorage").Remotes:FindFirstChild("TrainRep") or game:GetService("ReplicatedStorage").Remotes:FindFirstChild("TrainStop")))
        or (workspace:FindFirstChild("Lobby") and workspace.Lobby:FindFirstChild("Gym"))
        or (workspace:FindFirstChild("Lobby") and workspace.Lobby:FindFirstChild("Stations") and workspace.Lobby.Stations:FindFirstChild("RebirthShrine")) then
        return "GloryBound ⚔️", "glorybound.luau"
    end

    -- 2. Anime Galaxies ✨
    if uId == 10770748262 or pId == 83869074416117 or pId == 85423571424083
        or (game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("TowerDefense")) then
        return "Anime Galaxies ✨", "anime_galaxies.luau"
    end

    -- 3. Hunting Together 🎃
    if uId == 10769401924 or pId == 117483759937632 or game:GetService("ReplicatedStorage"):FindFirstChild("HalloweenRemotes") or workspace:FindFirstChild("Pumpkins") then
        return "Hunting Together 🎃", "hunting_together.luau"
    end

    -- 4. Blue Lock Farm ⚽
    if uId == 10700618962 or pId == 132767904294856 or game:GetService("ReplicatedStorage"):FindFirstChild("FootballRemotes") or workspace:FindFirstChild("Goals") then
        return "Blue Lock Farm ⚽", "blue_lock_farm.luau"
    end

    -- 5. Throw Food For Animals 🥪
    if uId == 10766972131 or pId == 120219252362013 or game:GetService("ReplicatedStorage"):FindFirstChild("AnimalRemotes") or workspace:FindFirstChild("FeederStands") then
        return "Throw Food For Animals 🥪", "throw_food.luau"
    end

    -- 6. Raycity RB 🏎️
    if uId == 10772794231 or pId == 117419079466193 or game:GetService("ReplicatedStorage"):FindFirstChild("RCDrive") or workspace:FindFirstChild("MyCar") then
        return "Raycity RB 🏎️", "raycity_rb.luau"
    end

    -- Fallback: MarketplaceService Title
    local ok, info = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(pId) end)
    if ok and info and info.Name then
        local t = info.Name:lower()
        if t:find("net a fish") or t:find("fishing") then return "Net a Fish! 🐟", "net_a_fish.luau" end
        if t:find("grimorio") or t:find("grimoire") or t:find("clover") then return "Era dos Grimórios 📖", "era_dos_grimorios.luau" end
        if t:find("glorybound") or t:find("gladiator") or t:find("trials") then return "GloryBound ⚔️", "glorybound.luau" end
        if t:find("anime galaxies") then return "Anime Galaxies ✨", "anime_galaxies.luau" end
        if t:find("hunting together") then return "Hunting Together 🎃", "hunting_together.luau" end
        if t:find("blue lock") then return "Blue Lock Farm ⚽", "blue_lock_farm.luau" end
        if t:find("throw food") then return "Throw Food For Animals 🥪", "throw_food.luau" end
        if t:find("raycity") then return "Raycity RB 🏎️", "raycity_rb.luau" end
    end

    return nil, nil
end

local gameTitle, scriptFileName = detectGame()
if not scriptFileName then
    warn("[Song Hub] ❌ Current game (PlaceId: " .. tostring(game.PlaceId) .. ") is not supported!")
    return
end

local cleanFileName = scriptFileName:gsub("^games/", ""):gsub("^/", "")

-- Guard against duplicate executions
if getgenv and getgenv()._GloryBoundRunning and getgenv()._GB_Window and cleanFileName == "glorybound.luau" and not getgenv()._GB_ForceReload then
    print("[Song Hub] 🛡️ GloryBound is already running with active UI. Skipping duplicate execution.")
    if getgenv then getgenv()._SongHubLoading = false end
    return
end

-- ==============================================================================
-- 2. CLOUDFLARE EDGE AUTHENTICATION (WHITELIST & KEY SYSTEM)
-- ==============================================================================
local HttpService = game:GetService("HttpService")
local CLOUDFLARE_URL = "https://song-hub-whitelist.song-hub-cloudflare-worker.workers.dev"
local SERVER_VERIFY_URL = CLOUDFLARE_URL .. "/api/verify-key"
local GET_KEY_PORTAL_URL = CLOUDFLARE_URL .. "/getkey"
local DISCORD_INVITE_URL = "https://discord.gg/your-discord-here"
local KEY_SAVE_PATH = "SongHub/saved_license_key.txt"

local function getHardwareId()
    if gethwid then return gethwid() end
    if get_hwid then return get_hwid() end
    if identifyexecutor then
        local exec = identifyexecutor()
        return exec .. "_" .. tostring(LocalPlayer.UserId)
    end
    return "DEVICE_" .. tostring(LocalPlayer.UserId)
end

local function sendVerifyRequest(key)
    local requestFn = (syn and syn.request) or request or (http and http.request) or http_request
    if not requestFn then
        return false, { message = "Your executor does not support HTTP requests!" }
    end

    local payload = HttpService:JSONEncode({
        key = key or "",
        hwid = getHardwareId(),
        userId = LocalPlayer.UserId,
        username = LocalPlayer.Name
    })

    local success, response = pcall(requestFn, {
        Url = SERVER_VERIFY_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = payload
    })

    if not success or not response or not response.Body then
        return false, { message = "Could not connect to Cloudflare Auth Edge!" }
    end

    local data = nil
    pcall(function() data = HttpService:JSONDecode(response.Body) end)
    if not data then return false, { message = "Server returned invalid response." } end
    return data.success == true, data
end

local function launchGameScript()
    print(string.format("[Song Hub] 🚀 Launching %s directly from GitHub...", gameTitle))
    local cacheBuster = tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
    local urls = {
        "https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/games/" .. cleanFileName .. "?v=" .. cacheBuster,
        "https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub-Server/main/games/" .. cleanFileName .. "?v=" .. cacheBuster
    }

    local scriptCode = nil
    for _, url in ipairs(urls) do
        local ok, res = pcall(game.HttpGet, game, url)
        if ok and type(res) == "string" and #res > 500 and not res:find("403: Forbidden") and not res:find("404: Not Found") then
            scriptCode = res
            break
        end
    end

    if not scriptCode then
        warn("[Song Hub] ⚠️ Failed to download from GitHub! Checking local backup...")
        if isfile and isfile("games/" .. cleanFileName) then
            local ok, localCode = pcall(readfile, "games/" .. cleanFileName)
            if ok and type(localCode) == "string" and #localCode > 500 then
                scriptCode = localCode
            end
        end
    end

    if scriptCode then
        pcall(function()
            if writefile then
                if makefolder then pcall(makefolder, "autoexec") end
                writefile("autoexec/SongHub.luau", 'loadstring(game:HttpGet("https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/loader.luau"))()')
            end
        end)
        pcall(function()
            if writefile then pcall(writefile, "games/" .. cleanFileName, scriptCode) end
        end)

        local fn, err = loadstring(scriptCode)
        if fn then
            print("[Song Hub] ✅ Successfully compiled " .. gameTitle .. "! Launching UI...")
            if getgenv then getgenv()._SongHubLoading = false end
            task.spawn(fn)
        else
            if getgenv then getgenv()._SongHubLoading = false end
            warn("[Song Hub] ❌ Compile error in " .. scriptFileName .. ": " .. tostring(err))
        end
    else
        if getgenv then getgenv()._SongHubLoading = false end
        warn("[Song Hub] ❌ Could not download script from GitHub!")
    end
end

-- ==============================================================================
-- 3. AUTHENTICATION PIPELINE
-- ==============================================================================
-- Step 1: Check Direct Roblox UserID Whitelist (VIP/Owner auto-bypass)
local wlOk, wlData = sendVerifyRequest("")
if wlOk and wlData.whitelisted then
    print(string.format("[Song Hub] ✅ Direct Whitelist passed! Welcome %s (%s)", LocalPlayer.Name, wlData.role or "VIP/Owner"))
    launchGameScript()
    return
end

-- Step 2: Check Locally Saved Key
if isfile and isfile(KEY_SAVE_PATH) then
    local savedKey = ""
    pcall(function() savedKey = readfile(KEY_SAVE_PATH) end)
    if savedKey and #savedKey > 3 then
        local keyOk, keyData = sendVerifyRequest(savedKey:gsub("%s+", ""))
        if keyOk then
            print(string.format("[Song Hub] ✅ Key Verified from Cache! Type: %s", keyData.keyType or "Active"))
            launchGameScript()
            return
        end
    end
end

-- Step 3: Prompt User for Key via WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Song Hub | Key System",
    Icon = "shield-check",
    Author = "Cloudflare Edge Auth",
    Folder = "SongHub",
    Size = UDim2.fromOffset(480, 380),
    Transparent = true,
    Theme = "Dark",
    Acrylic = false,
    Resizable = false
})

local TabKey = Window:Tab({ Title = "Key Verification", Icon = "key" })

TabKey:Paragraph({
    Title = "License Key Required",
    Desc = "This Hub is protected by Song Hub Edge Whitelist.\nPlease enter your key to continue.\nDirect whitelisted users bypass this automatically.",
    Image = "lock"
})

local inputKey = ""

TabKey:Input({
    Title = "Enter License Key",
    Desc = "Paste your license key here (e.g. SONGHUB-XXXX)",
    Placeholder = "SONGHUB-XXXX-XXXX-XXXX",
    Callback = function(txt)
        inputKey = txt:gsub("%s+", "")
    end
})

TabKey:Button({
    Title = "🔓 Verify & Unlock Song Hub",
    Desc = "Verify key and start script",
    Icon = "check-circle",
    Callback = function()
        if #inputKey == 0 then
            WindUI:Notify({ Title = "Error", Content = "Please enter a license key!", Duration = 3, Icon = "alert-circle" })
            return
        end

        WindUI:Notify({ Title = "Verifying", Content = "Contacting Cloudflare Edge...", Duration = 2, Icon = "loader" })
        local ok, result = sendVerifyRequest(inputKey)

        if ok then
            if writefile then
                if makefolder then pcall(makefolder, "SongHub") end
                pcall(writefile, KEY_SAVE_PATH, inputKey)
            end

            WindUI:Notify({
                Title = "Access Granted! ✨",
                Content = result.message or "Welcome to Song Hub!",
                Duration = 4,
                Icon = "sparkles"
            })

            task.wait(1.2)
            pcall(function() Window:Destroy() end)
            launchGameScript()
        else
            WindUI:Notify({
                Title = "Access Denied ❌",
                Content = result.message or "Invalid or expired key!",
                Duration = 4,
                Icon = "x-circle"
            })
        end
    end
})

TabKey:Button({
    Title = "🌐 Get Free 24h Key (Web Portal)",
    Desc = "Copy GetKey Web Portal URL to clipboard",
    Icon = "link",
    Callback = function()
        if setclipboard then
            setclipboard(GET_KEY_PORTAL_URL)
            WindUI:Notify({ Title = "Copied", Content = "GetKey URL copied to clipboard! Paste into browser.", Duration = 4, Icon = "clipboard-check" })
        end
    end
})

TabKey:Button({
    Title = "💬 Join Discord Community",
    Desc = "Copy Discord invite link to clipboard",
    Icon = "external-link",
    Callback = function()
        if setclipboard then
            setclipboard(DISCORD_INVITE_URL)
            WindUI:Notify({ Title = "Copied", Content = "Discord invite link copied to clipboard!", Duration = 3, Icon = "clipboard-check" })
        end
    end
})
