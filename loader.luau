-- ==============================================================================
-- 🚀 SONG HUB - UNIVERSAL KEYLESS LOADER (PURE GITHUB DIRECT)
-- Supported Games:
--   1. ⚔️ Anime Galaxies (PlaceId: 83869074416117 / 85423571424083)
--   2. 🎃 Hunting Together (Universe: 10769401924 / Place: 117483759937632)
--   3. ⚽ Blue Lock Farm (Universe: 10700618962 / Place: 132767904294856)
--   4. 🍗 Throw Food For Animals (Universe: 10766972131 / Place: 120219252362013)
--   5. 🏎️ Raycity RB (Universe: 10772794231 / Place: 117419079466193)
--   6. ⚔️ GloryBound (Universe: 10768652372 / Place: 137629355240872)
-- ==============================================================================

if getgenv then
    if getgenv()._SongHubLoading and (os.clock() - (getgenv()._SongHubLastLoad or 0)) < 6 then
        print("[Song Hub] 🛡️ Loader is already loading. Skipping duplicate call.")
        return
    end
    getgenv()._SongHubLoading = true
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

-- Detect Game
local function detectGame()
    local pId = game.PlaceId
    local uId = game.GameId
    local t0 = tick()
    while (uId == 0 or pId == 0) and (tick() - t0 < 3) do
        task.wait(0.2)
        pId = game.PlaceId
        uId = game.GameId
    end

    -- 1. GloryBound ⚔️ (Check first or by unique remotes)
    if uId == 10768652372 or pId == 137629355240872
        or (game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and (game:GetService("ReplicatedStorage").Remotes:FindFirstChild("TrainRep") or game:GetService("ReplicatedStorage").Remotes:FindFirstChild("TrainStop")))
        or (workspace:FindFirstChild("Lobby") and workspace.Lobby:FindFirstChild("Gym"))
        or (workspace:FindFirstChild("Lobby") and workspace.Lobby:FindFirstChild("Stations") and workspace.Lobby.Stations:FindFirstChild("RebirthShrine")) then
        return "GloryBound ⚔️", "glorybound.luau"
    end

    -- 2. Anime Galaxies ✨
    if uId == 10770748262 or pId == 83869074416117 or pId == 85423571424083
        or (game:GetService("ReplicatedStorage"):FindFirstChild("Master") and game:GetService("ReplicatedStorage").Master:FindFirstChild("Modules") and game:GetService("ReplicatedStorage").Master.Modules:FindFirstChild("Network_Client"))
        or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("FusionHUD")) then
        return "Anime Galaxies ✨", "anime_galaxies.luau"
    end

    -- 3. Hunting Together 🎃 (DO NOT check generic Attack remote!)
    if uId == 10769401924 or pId == 117483759937632 or pId == 100618538481971 or pId == 91627865222791
        or workspace:GetAttribute("PlaceRole") == "Dungeon"
        or (game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and (game:GetService("ReplicatedStorage").Remotes:FindFirstChild("PickupDrop") or game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CardAction")))
        or workspace:FindFirstChild("ActiveMonsters") then
        return "Hunting Together 🎃", "hunting_together.luau"
    end

    -- 4. Blue Lock Farm ⚽
    if uId == 10700618962 or pId == 132767904294856
        or (workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("PlotModels")) then
        return "Blue Lock Farm ⚽", "blue_lock_farm.luau"
    end

    -- 5. Throw Food For Animals 🍗
    if uId == 10766972131 or pId == 120219252362013
        or (game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Throw_Start")) then
        return "Throw Food For Animals 🍗", "throw_food.luau"
    end

    -- 6. Raycity RB 🏎️
    if uId == 10772794231 or pId == 117419079466193 or game:GetService("ReplicatedStorage"):FindFirstChild("RCDrive") or workspace:FindFirstChild("MyCar") then
        return "Raycity RB 🏎️", "raycity_rb.luau"
    end

    -- Fallback: MarketplaceService Title
    local ok, info = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(pId) end)
    if ok and info and info.Name then
        local t = info.Name:lower()
        if t:find("glorybound") or t:find("gladiator") or t:find("trials") then return "GloryBound ⚔️", "glorybound.luau" end
        if t:find("anime galaxies") then return "Anime Galaxies ✨", "anime_galaxies.luau" end
        if t:find("hunting together") then return "Hunting Together 🎃", "hunting_together.luau" end
        if t:find("blue lock") then return "Blue Lock Farm ⚽", "blue_lock_farm.luau" end
        if t:find("throw food") then return "Throw Food For Animals 🍗", "throw_food.luau" end
        if t:find("raycity") then return "Raycity RB 🏎️", "raycity_rb.luau" end
    end

    return nil, nil
end

local gameTitle, scriptFileName = detectGame()
if not scriptFileName then
    warn("[Song Hub] ❌ Current game (PlaceId: " .. tostring(game.PlaceId) .. ") is not supported!")
    return
end

-- Guard against duplicate executions across autoexec and teleport queue
if getgenv and getgenv()._GloryBoundRunning and scriptFileName == "glorybound.luau" and (os.clock() - (getgenv()._GB_LastStartTime or 0)) < 15 then
    print("[Song Hub] 🛡️ GloryBound is already running. Skipping duplicate execution.")
    if getgenv then getgenv()._SongHubLoading = false end
    return
end

print(string.format("[Song Hub] 🔓 Keyless Direct Mode: Fetching %s directly from GitHub...", gameTitle))

-- Always fetch freshest code directly from GitHub with cache buster
local cacheBuster = tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
local urls = {
    "https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/games/" .. scriptFileName .. "?v=" .. cacheBuster,
    "https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub-Server/main/games/" .. scriptFileName .. "?v=" .. cacheBuster
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
    if isfile and isfile("games/" .. scriptFileName) then
        local ok, localCode = pcall(readfile, "games/" .. scriptFileName)
        if ok and type(localCode) == "string" and #localCode > 500 then
            scriptCode = localCode
        end
    end
end

if scriptCode then
    -- Auto-install into autoexec folder so it runs automatically on rejoin
    pcall(function()
        if writefile then
            if makefolder then pcall(makefolder, "autoexec") end
            writefile("autoexec/SongHub.luau", 'loadstring(game:HttpGet("https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/loader.luau"))()')
        end
    end)
    -- Cache locally for offline resilience
    pcall(function()
        if writefile then
            pcall(writefile, "games/" .. scriptFileName, scriptCode)
        end
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
    warn("[Song Hub] ❌ Could not download script from GitHub! Please check your connection.")
end
