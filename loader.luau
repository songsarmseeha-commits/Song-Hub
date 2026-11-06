-- ==============================================================================
-- 🚀 Self-Bypassing Executor Cache Engine
-- Ensures that EVEN IF an executor executes an old cached URL,
-- it will immediately fetch the freshest loader code from GitHub using a dynamic timestamp!
-- ==============================================================================
if getgenv and not getgenv()._SongHubFreshLoaded then
    getgenv()._SongHubFreshLoaded = true
    local buster = tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
    local freshUrl = "https://song-hub-avp8.onrender.com/load?v=" .. buster
    local ok, freshCode = pcall(game.HttpGet, game, freshUrl)
    if ok and type(freshCode) == "string" and #freshCode > 1000 then
        local fn = loadstring(freshCode)
        if fn then
            return fn()
        end
    end
end
if getgenv then
    getgenv()._SongHubFreshLoaded = nil
end

-- ==============================================================================
-- 👑 UNIVERSAL ALL-IN-ONE MULTI-GAME HUB LOADER WITH KEY SYSTEM
-- Supported Games:
--   1. ⚔️ Anime Galaxies (Lobby & Match Acts)
--   2. 🎃 Hunting Together (All Fields & Dungeons)
--   3. ⚽ Blue Lock Farm (Auto Obby, Polisher & Event Farm)
--   4. 🍗 Throw Food For Animals (Auto Farm & Auto Workout)
-- Protected with: Universal Whitelist & Key System Web Portal
-- ==============================================================================

-- 🛡️ Anti-Duplicate / Singleton Guard for Loader
-- Prevents duplicate loader executions from executor autoexecute + queue_on_teleport
if getgenv then
    local now = os.clock()
    -- 1. If game script is already running healthy with its UI window active, do NOT reload!
    if (getgenv()._HuntingTogetherRunning and getgenv()._HT_CurrentWindow)
        or (getgenv()._BlueLockFarmRunning and getgenv()._BLF_Window)
        or (getgenv()._AnimeGalaxiesRunning and getgenv()._AG_Window)
        or (getgenv()._ThrowFoodRunning and getgenv()._TF_Window) then
        print("[Universal Hub] 🛡️ Script is already running with active UI! Skipping duplicate loader run.")
        return
    end
    -- 2. If loader was executed in another thread less than 5 seconds ago, ignore duplicate run
    if getgenv()._UniversalLoaderLoading and (now - (getgenv()._UniversalLoaderTime or 0)) < 6 then
        print("[Universal Hub] ⏳ Loader is already starting in another thread, skipping duplicate run...")
        return
    end
    getgenv()._UniversalLoaderLoading = true
    getgenv()._UniversalLoaderTime = now
end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ⚙️ CONFIGURATION
local SERVER_HOST = "https://song-hub-avp8.onrender.com" -- Worldwide Live Cloud Server (Render)
local VERIFY_URL = SERVER_HOST .. "/api/v1/verify"
local GET_KEY_URL = SERVER_HOST .. "/getkey"
local KEY_SAVE_PATH = "UniversalHub/saved_key.txt"

-- Safe Executor HWID Fetcher
local function getHardwareId()
    if gethwid then return gethwid() end
    if get_hwid then return get_hwid() end
    if identifyexecutor then
        local exec = identifyexecutor()
        return exec .. "_" .. tostring(LocalPlayer.UserId)
    end
    return "DEVICE_" .. tostring(LocalPlayer.UserId)
end

-- Active Session State & Heartbeat Loop
local activeSessionToken = nil
local verifiedAuthKey = ""

local function startHeartbeatLoop(sessionToken, validKey)
    if not sessionToken then return end
    activeSessionToken = sessionToken

    task.spawn(function()
        while task.wait(30) do
            if not activeSessionToken or activeSessionToken ~= sessionToken then break end
            local requestFn = (syn and syn.request) or request or (http and http.request) or http_request
            if requestFn then
                pcall(function()
                    local hbRes = requestFn({
                        Url = SERVER_HOST .. "/api/v1/heartbeat",
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = HttpService:JSONEncode({
                            sessionToken = activeSessionToken,
                            key = validKey or "",
                            hwid = getHardwareId()
                        })
                    })
                    if hbRes and hbRes.StatusCode == 403 then
                        warn("[Universal Hub] ⚠️ Session terminated by server (revoked or session limit reached)!")
                        activeSessionToken = nil
                    end
                end)
            end
        end
    end)

    pcall(function()
        game:BindToClose(function()
            if activeSessionToken then
                local requestFn = (syn and syn.request) or request or (http and http.request) or http_request
                if requestFn then
                    pcall(requestFn, {
                        Url = SERVER_HOST .. "/api/v1/session/close",
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = HttpService:JSONEncode({ sessionToken = activeSessionToken })
                    })
                end
            end
        end)
    end)
end

-- ==============================================================================
-- 1. GAME DETECTION SYSTEM (แยก MAP อัตโนมัติ)
-- ==============================================================================
local function detectGame()
    local pId = game.PlaceId
    local uId = game.GameId

    -- Wait 1 second if IDs haven't initialized yet
    if uId == 0 or pId == 0 then
        task.wait(1)
        pId = game.PlaceId
        uId = game.GameId
    end

    -- 1. Anime Galaxies
    if uId == 10770748262 or pId == 83869074416117 or pId == 85423571424083 then
        return "anime_galaxies", "Anime Galaxies ✨", "anime_galaxies.luau"
    end

    -- 2. Hunting Together
    if uId == 10769401924 or pId == 117483759937632 or pId == 100618538481971 or pId == 91627865222791 or workspace:GetAttribute("PlaceRole") == "Dungeon" then
        return "hunting_together", "Hunting Together 🎃", "hunting_together.luau"
    end
    if game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Attack") then
        return "hunting_together", "Hunting Together 🎃", "hunting_together.luau"
    end

    -- 3. Blue Lock Farm
    if uId == 10700618962 or pId == 132767904294856 then
        return "blue_lock_farm", "Blue Lock Farm ⚽", "blue_lock_farm.luau"
    end
    if workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("PlotModels") then
        return "blue_lock_farm", "Blue Lock Farm ⚽", "blue_lock_farm.luau"
    end

    -- 4. Throw Food For Animals
    if uId == 10766972131 or pId == 120219252362013 then
        return "throw_food", "Throw Food For Animals 🍗", "throw_food.luau"
    end
    if game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Throw_Start") then
        return "throw_food", "Throw Food For Animals 🍗", "throw_food.luau"
    end

    -- 5. Raycity RB
    if uId == 10772794231 or pId == 117419079466193 or game:GetService("ReplicatedStorage"):FindFirstChild("RCDrive") or workspace:FindFirstChild("MyCar") then
        return "raycity_rb", "Raycity RB 🏎️", "raycity_rb.luau"
    end

    -- Fallback: Check MarketplaceService Game Title
    local ok, info = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(pId)
    end)
    if ok and info and info.Name then
        local title = info.Name:lower()
        if title:find("anime galaxies") then
            return "anime_galaxies", "Anime Galaxies ✨", "anime_galaxies.luau"
        elseif title:find("hunting together") then
            return "hunting_together", "Hunting Together 🎃", "hunting_together.luau"
        elseif title:find("blue lock") then
            return "blue_lock_farm", "Blue Lock Farm ⚽", "blue_lock_farm.luau"
        elseif title:find("throw food") then
            return "throw_food", "Throw Food For Animals 🍗", "throw_food.luau"
        elseif title:find("raycity") then
            return "raycity_rb", "Raycity RB 🏎️", "raycity_rb.luau"
        end
    end

    return nil, "Unsupported Game", nil
end

-- ==============================================================================
-- 2. HTTP VERIFICATION API
-- ==============================================================================
local function sendVerifyRequest(key)
    local requestFn = (syn and syn.request) or request or (http and http.request) or http_request
    if not requestFn then
        return false, { message = "Executor does not support HTTP requests!" }
    end

    local payload = HttpService:JSONEncode({
        key = key or "",
        hwid = getHardwareId(),
        userId = LocalPlayer.UserId,
        username = LocalPlayer.Name,
        gameId = game.GameId,
        placeId = game.PlaceId,
        jobId = game.JobId or "",
        sessionToken = activeSessionToken or ""
    })

    local success, response = pcall(requestFn, {
        Url = VERIFY_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = payload
    })

    if not success or not response then
        return false, { message = "Cannot connect to Whitelist Server (" .. SERVER_HOST .. ")" }
    end

    local data = nil
    pcall(function()
        data = HttpService:JSONDecode(response.Body)
    end)

    if not data then
        return false, { message = "Invalid response from Whitelist Server" }
    end

    return data.success == true, data
end

-- ==============================================================================
-- 3. SCRIPT EXECUTION ENGINE (ALWAYS FETCH LATEST FROM CLOUD)
-- ==============================================================================
-- ==============================================================================
-- 🌐 Global Server Hop & Teleport Auto-Reload Persistence
-- ==============================================================================
pcall(function()
    if getgenv and not getgenv()._SongHubTeleportHooked then
        getgenv()._SongHubTeleportHooked = true
        local qot = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
        if qot and LocalPlayer then
            LocalPlayer.OnTeleport:Connect(function(state)
                if state == Enum.TeleportState.Started or state == Enum.TeleportState.InProgress then
                    pcall(function()
                        qot([[loadstring(game:HttpGet("https://song-hub-avp8.onrender.com/load?v=" .. tostring(os.time())))()]])
                    end)
                end
            end)
        end
    end
end)

-- ==============================================================================
-- 🔄 Live In-Game Auto-Update Engine (Hot-Reloading)
-- Periodically checks GitHub release timestamp; if developer pushes update,
-- automatically reloads the script in real-time without player needing to do anything!
-- ==============================================================================
local function startLiveAutoUpdateChecker(scriptFileName, gameTitle, launchFn)
    if getgenv and getgenv()._SongHubLiveUpdateStarted then return end
    if getgenv then getgenv()._SongHubLiveUpdateStarted = true end

    task.spawn(function()
        local initialTime = os.time()
        -- Initial grace period: wait 120 seconds before first check
        task.wait(120)
        while task.wait(90) do
            pcall(function()
                local vUrl = "https://song-hub-avp8.onrender.com/version?v=" .. tostring(os.time()) .. "_" .. tostring(math.random(100, 999))
                local ok, res = pcall(game.HttpGet, game, vUrl)
                if ok and type(res) == "string" and #res > 10 then
                    local vData = HttpService:JSONDecode(res)
                    if vData and vData.updatedAt then
                        local updateTs = math.floor(vData.updatedAt / 1000)
                        if updateTs > (initialTime + 15) then
                            print(string.format("[Universal Hub] 🚀 New update detected on GitHub (%s)! Hot-reloading %s...", tostring(vData.updatedAt), gameTitle))
                            initialTime = updateTs
                            pcall(function()
                                local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
                                WindUI:Notify({
                                    Title = "🚀 Song Hub Auto-Updated!",
                                    Content = "Found new update from server! Reloading latest script version automatically...",
                                    Duration = 5,
                                    Icon = "refresh-cw"
                                })
                            end)
                            task.wait(1.5)
                            launchFn(scriptFileName, gameTitle)
                        end
                    end
                end
            end)
        end
    end)
end

local function launchGameScript(scriptFileName, gameTitle)
    print(string.format("[Universal Hub] 🚀 Launching latest script for %s...", gameTitle))
    if getgenv then
        getgenv()._UniversalLoaderLoading = false
    end

    -- 🛡️ Anti-Hook / Anti-Dump & Security Environment Verification
    local isEnvSecure = true
    pcall(function()
        if islclosure and islclosure(loadstring) then isEnvSecure = false end
        if iscclosure and not iscclosure(loadstring) then isEnvSecure = false end
        if islclosure and islclosure(game.HttpGet) then isEnvSecure = false end
        if getgenv then
            local g = getgenv()
            if g.SimpleSpyExecuted or g.Hydroxide or g.TurtleSpy or g.__HTTPSPY then
                isEnvSecure = false
            end
        end
    end)

    if not isEnvSecure then
        warn("[Universal Hub] 🛡️ Security Check Failed: Tampered environment, debugger, or HttpSpy detected!")
        return
    end

    local cacheBuster = tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
    local requestFn = (syn and syn.request) or request or (http and http.request) or http_request

    -- Request One-Time Cryptographic Execution Token from Render Server (Single-Use 25s TTL)
    local oneTimeToken = nil
    if requestFn then
        pcall(function()
            local tokenRes = requestFn({
                Url = SERVER_HOST .. "/api/v1/script-token",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({
                    key = verifiedAuthKey or "",
                    hwid = getHardwareId(),
                    userId = LocalPlayer.UserId,
                    gameName = scriptFileName
                })
            })
            if tokenRes and tokenRes.Body then
                local tData = HttpService:JSONDecode(tokenRes.Body)
                if tData and tData.success and tData.token then
                    oneTimeToken = tData.token
                end
            end
        end)
    end

    local candidateUrls = {}
    if oneTimeToken then
        -- Secure Render Production Server with One-Time Security Token (Primary & Protected)
        table.insert(candidateUrls, SERVER_HOST .. "/scripts/" .. scriptFileName .. "?token=" .. oneTimeToken .. "&v=" .. cacheBuster)
    end
    -- Resilient Cloud Endpoints (GitHub Raw & Direct Render)
    table.insert(candidateUrls, "https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/games/" .. scriptFileName .. "?v=" .. cacheBuster)
    table.insert(candidateUrls, "https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub-Server/main/games/" .. scriptFileName .. "?v=" .. cacheBuster)
    table.insert(candidateUrls, SERVER_HOST .. "/scripts/" .. scriptFileName .. "?v=" .. cacheBuster)

    for _, url in ipairs(candidateUrls) do
        local dlOk, code = pcall(function()
            return game:HttpGet(url)
        end)
        if dlOk and type(code) == "string" and #code > 500 and not code:find("403 Forbidden") and not code:find("404: Not Found") then
            local fn, err = loadstring(code)
            if fn then
                -- Automatically sync and overwrite local cache with freshest code
                pcall(function()
                    if writefile then
                        if not isfolder("UniversalHub") then makefolder("UniversalHub") end
                        writefile("UniversalHub/" .. scriptFileName, code)
                        if scriptFileName == "anime_galaxies.luau" then
                            if not isfolder("AnimeGalaxiesHub") then makefolder("AnimeGalaxiesHub") end
                            writefile("AnimeGalaxiesHub/AnimeGalaxies_Hub.luau", code)
                            writefile("AnimeGalaxies_Hub.luau", code)
                        end
                    end
                end)
                code = nil -- 🛡️ Scrub plaintext code string from RAM immediately!
                print("[Universal Hub] ✅ Securely loaded and compiled latest script into RAM.")
                task.spawn(fn)
                startLiveAutoUpdateChecker(scriptFileName, gameTitle, launchGameScript)
                return
            else
                warn("[Universal Hub] ⚠️ Compile error: " .. tostring(err))
            end
        end
    end

    warn("[Universal Hub] ⚠️ Failed to download from all cloud endpoints, checking offline cache...")

    -- 2. Fallback to local file only if server is unreachable
    local localCandidates = {
        "UniversalHub/" .. scriptFileName,
        "games/" .. scriptFileName,
        scriptFileName
    }

    if scriptFileName == "hunting_together.luau" then
        table.insert(localCandidates, "hunting_together_script.lua")
    elseif scriptFileName == "anime_galaxies.luau" then
        table.insert(localCandidates, "AnimeGalaxiesHub/AnimeGalaxies_Hub.luau")
        table.insert(localCandidates, "AnimeGalaxies_Hub.luau")
    elseif scriptFileName == "raycity_rb.luau" then
        table.insert(localCandidates, "RaycityHub/raycity_rb.luau")
        table.insert(localCandidates, "raycity_rb.luau")
    end

    for _, path in ipairs(localCandidates) do
        if isfile and isfile(path) then
            local ok, content = pcall(readfile, path)
            if ok and content and #content > 50 then
                local fn, err = loadstring(content)
                content = nil
                if fn then
                    print("[Universal Hub] Loaded from offline cache: " .. path)
                    task.spawn(fn)
                    return
                end
            end
        end
    end
end

-- ==============================================================================
-- 4. MAIN AUTHENTICATION & DISPATCH FLOW
-- ==============================================================================
task.spawn(function()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    local gameKey, gameTitle, scriptFileName = detectGame()
    if not gameKey then
        warn(string.format("[Universal Hub] ❌ Current game (PlaceId: %s) is not supported!", tostring(game.PlaceId)))
        pcall(function()
            local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
            WindUI:Notify({
                Title = "Universal Hub",
                Content = "Game not supported! (PlaceId: " .. tostring(game.PlaceId) .. ")\nSupported: Anime Galaxies, Hunting Together, Blue Lock Farm, Raycity RB",
                Duration = 6,
                Icon = "alert-triangle"
            })
        end)
        return
    end

    -- Step A: Check Direct Whitelist (VIP/Owner bypass)
    local wlOk, wlData = sendVerifyRequest("")
    if wlOk and wlData.whitelisted then
        verifiedAuthKey = "WHITELIST"
        print(string.format("[Universal Hub] 👑 Direct Whitelist Active: Welcome %s (%s)", LocalPlayer.Name, wlData.role or "VIP"))
        launchGameScript(scriptFileName, gameTitle)
        return
    end

    -- Step B: Check Locally Saved License Key
    if isfile and isfile(KEY_SAVE_PATH) then
        local savedKey = ""
        pcall(function() savedKey = readfile(KEY_SAVE_PATH) end)
        if savedKey and #savedKey > 3 then
            local cleanSaved = savedKey:gsub("%s+", "")
            local keyOk, keyData = sendVerifyRequest(cleanSaved)
            if keyOk then
                verifiedAuthKey = cleanSaved
                print(string.format("[Universal Hub] 🔑 License Key Active: %s (Type: %s)", savedKey, keyData.keyType or "Active"))
                if keyData and keyData.sessionToken then
                    startHeartbeatLoop(keyData.sessionToken, cleanSaved)
                end
                launchGameScript(scriptFileName, gameTitle)
                return
            end
        end
    end

    -- Step B.2: Auto-Check Claimed Key by Device HWID (Get Key Portal)
    pcall(function()
        local requestFn = (syn and syn.request) or request or (http and http.request) or http_request
        if requestFn then
            local hwid = getHardwareId()
            local checkRes = requestFn({
                Url = SERVER_HOST .. "/api/v1/getkey/check?hwid=" .. HttpService:UrlEncode(hwid),
                Method = "GET",
                Headers = { ["Accept"] = "application/json" }
            })
            if checkRes and checkRes.Body then
                local cd = HttpService:JSONDecode(checkRes.Body)
                if cd and cd.hasKey and cd.key then
                    local autoOk, autoData = sendVerifyRequest(cd.key)
                    if autoOk then
                        verifiedAuthKey = cd.key
                        pcall(function()
                            if not isfolder("UniversalHub") then makefolder("UniversalHub") end
                            writefile(KEY_SAVE_PATH, cd.key)
                        end)
                        print(string.format("[Universal Hub] ⚡ Auto-Detected Claimed Key for HWID: %s", cd.key))
                        if autoData and autoData.sessionToken then
                            startHeartbeatLoop(autoData.sessionToken, cd.key)
                        end
                        launchGameScript(scriptFileName, gameTitle)
                        return
                    end
                end
            end
        end
    end)

    -- Step C: Key Required -> Open Sleek Key System Window
    local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

    local Window = WindUI:CreateWindow({
        Title = "Universal Hub | Key Verification",
        Icon = "shield-check",
        Author = gameTitle,
        Folder = "UniversalHub",
        Size = UDim2.fromOffset(500, 420),
        Transparent = true,
        Theme = "Dark",
        Acrylic = false,
        Resizable = false
    })

    local TabKey = Window:Tab({ Title = "License Key", Icon = "key" })

    TabKey:Paragraph({
        Title = "Authentication Required",
        Desc = "Detected Game: " .. gameTitle .. "\nPlease enter your license key to unlock access.\nDirect whitelisted players are verified automatically.\nYou can also claim a free 24-hour key below!",
        Image = "lock"
    })

    local inputKey = ""

    local KeyInput = TabKey:Input({
        Title = "Enter License Key",
        Desc = "Paste your license key here (e.g. PREMIUM-XXXX-XXXX)",
        Placeholder = "PREMIUM-XXXX-XXXX",
        Callback = function(txt)
            if txt and #txt > 0 then
                inputKey = txt:gsub("[%s%c'\"]+", ""):upper()
            end
        end
    })

    -- Background scanner to hook real-time text changes from the TextBox
    task.spawn(function()
        for i = 1, 20 do
            task.wait(0.25)
            local roots = {
                (typeof(gethui) == "function" and gethui()) or nil,
                game:GetService("CoreGui"),
                LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
            }
            local found = false
            for _, root in ipairs(roots) do
                if root then
                    for _, d in ipairs(root:GetDescendants()) do
                        if d:IsA("TextBox") and (d.PlaceholderText:find("XXXX") or d.PlaceholderText:find("Key") or d.Name:lower():find("input")) then
                            d:GetPropertyChangedSignal("Text"):Connect(function()
                                if d.Text and #d.Text > 0 then
                                    inputKey = d.Text:gsub("[%s%c'\"]+", ""):upper()
                                end
                            end)
                            d.FocusLost:Connect(function()
                                if d.Text and #d.Text > 0 then
                                    inputKey = d.Text:gsub("[%s%c'\"]+", ""):upper()
                                end
                            end)
                            found = true
                            break
                        end
                    end
                end
                if found then break end
            end
            if found then break end
        end
    end)

    local function handleSuccessfulUnlock(validKey, msg, resultData)
        verifiedAuthKey = validKey or ""
        if resultData and resultData.sessionToken then
            startHeartbeatLoop(resultData.sessionToken, validKey)
        end

        -- Save key locally so player never has to type it again!
        pcall(function()
            if not isfolder("UniversalHub") then makefolder("UniversalHub") end
            writefile(KEY_SAVE_PATH, validKey)
        end)

        WindUI:Notify({
            Title = "Access Granted! ✨",
            Content = (msg or "Welcome!") .. "\nLoading " .. gameTitle .. "...",
            Duration = 3,
            Icon = "sparkles"
        })

        task.wait(0.6)

        -- Completely clean up the Key Verification WindUI from all possible roots
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

        task.wait(0.2)
        task.spawn(function()
            launchGameScript(scriptFileName, gameTitle)
        end)
    end

    TabKey:Button({
        Title = "📋 Paste Key & Verify",
        Desc = "Read key from clipboard, paste and verify automatically (Fast & Easy)",
        Icon = "clipboard-check",
        Callback = function()
            local clip = ""
            if getclipboard then
                pcall(function() clip = getclipboard() end)
            elseif get_clipboard then
                pcall(function() clip = get_clipboard() end)
            end

            local cleanClip = (clip or ""):gsub("[%s%c'\"]+", ""):upper()
            if cleanClip and #cleanClip >= 6 then
                inputKey = cleanClip
                WindUI:Notify({ Title = "Key Pasted!", Content = "Verifying key: " .. cleanClip, Duration = 2, Icon = "check-circle" })
                local ok, result = sendVerifyRequest(cleanClip)
                if ok then
                    handleSuccessfulUnlock(cleanClip, result.message, result)
                else
                    WindUI:Notify({
                        Title = "Access Denied ❌",
                        Content = result.message or "Invalid or expired key!",
                        Duration = 4,
                        Icon = "x-circle"
                    })
                end
            else
                WindUI:Notify({
                    Title = "Clipboard Empty / No Key",
                    Content = "Please copy your key to clipboard first!",
                    Duration = 3,
                    Icon = "alert-circle"
                })
            end
        end
    })

    TabKey:Button({
        Title = "🔓 Verify & Unlock Hub",
        Desc = "Authenticate entered key with server and launch script",
        Icon = "check-circle",
        Callback = function()
            -- Extract key robustly from multiple sources
            local keyToTest = inputKey
            if not keyToTest or #keyToTest == 0 then
                if KeyInput and KeyInput.Value and #KeyInput.Value > 0 then
                    keyToTest = KeyInput.Value:gsub("[%s%c'\"]+", ""):upper()
                end
            end

            -- Check all TextBoxes across GUI roots
            if not keyToTest or #keyToTest == 0 then
                local roots = {
                    (typeof(gethui) == "function" and gethui()) or nil,
                    game:GetService("CoreGui"),
                    LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
                }
                for _, root in ipairs(roots) do
                    if root then
                        for _, d in ipairs(root:GetDescendants()) do
                            if d:IsA("TextBox") and #d.Text > 0 then
                                local candidate = d.Text:gsub("[%s%c'\"]+", ""):upper()
                                if #candidate >= 6 and not candidate:find("GALAXY%-XXXX") and not candidate:find("PREMIUM%-XXXX") then
                                    keyToTest = candidate
                                    break
                                end
                            end
                        end
                    end
                    if keyToTest and #keyToTest > 0 then break end
                end
            end

            -- Fallback: check clipboard if user copied but forgot to paste
            if not keyToTest or #keyToTest == 0 then
                local clip = ""
                if getclipboard then
                    pcall(function() clip = getclipboard() end)
                elseif get_clipboard then
                    pcall(function() clip = get_clipboard() end)
                end
                local cleanClip = (clip or ""):gsub("[%s%c'\"]+", ""):upper()
                if cleanClip and #cleanClip >= 8 and (cleanClip:find("GALAXY%-") or cleanClip:find("PREMIUM%-") or cleanClip:find("%-")) then
                    keyToTest = cleanClip
                end
            end

            if not keyToTest or #keyToTest == 0 then
                WindUI:Notify({ Title = "Error", Content = "Please enter a license key or click 'Paste Key & Verify'!", Duration = 3, Icon = "alert-circle" })
                return
            end

            WindUI:Notify({ Title = "Verifying", Content = "Contacting authentication server...", Duration = 2, Icon = "loader" })
            local ok, result = sendVerifyRequest(keyToTest)

            if ok then
                handleSuccessfulUnlock(keyToTest, result.message, result)
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
        Title = "⚡ Auto-Check Claimed Key",
        Desc = "Auto-detect and unlock if you completed the checkpoint",
        Icon = "zap",
        Callback = function()
            WindUI:Notify({ Title = "Checking...", Content = "Querying server for completed checkpoint...", Duration = 2, Icon = "loader" })
            local requestFn = (syn and syn.request) or request or (http and http.request) or http_request
            if not requestFn then
                WindUI:Notify({ Title = "Error", Content = "HTTP requests not supported", Duration = 3, Icon = "alert-circle" })
                return
            end

            local hwid = getHardwareId()
            local checkUrl = SERVER_HOST .. "/api/v1/getkey/check?hwid=" .. HttpService:UrlEncode(hwid)
            local res = nil
            local reqOk = pcall(function()
                res = requestFn({
                    Url = checkUrl,
                    Method = "GET",
                    Headers = { ["Accept"] = "application/json" }
                })
            end)

            if not reqOk or not res or not res.Body then
                WindUI:Notify({ Title = "Error", Content = "Failed to communicate with authentication server", Duration = 3, Icon = "x-circle" })
                return
            end

            local cd = nil
            pcall(function() cd = HttpService:JSONDecode(res.Body) end)

            if cd and cd.hasKey and cd.key then
                WindUI:Notify({
                    Title = "Key Found! 🎉",
                    Content = "Valid Key: " .. cd.key .. "\nUnlocking Hub...",
                    Duration = 3,
                    Icon = "check-circle"
                })
                local vOk, vData = sendVerifyRequest(cd.key)
                if vOk then
                    handleSuccessfulUnlock(cd.key, vData.message, vData)
                else
                    WindUI:Notify({ Title = "Error", Content = vData.message or "Key verification failed", Duration = 3, Icon = "x-circle" })
                end
            else
                WindUI:Notify({
                    Title = "No Key Claimed Yet ⏳",
                    Content = "You haven't completed the checkpoint yet.\nClick 'Get Free 24h Key' to start!",
                    Duration = 4,
                    Icon = "clock"
                })
            end
        end
    })

    TabKey:Button({
        Title = "🟣 Get Free Key via LootLabs",
        Desc = "Copy LootLabs checkpoint link (Fast & Mobile Friendly)",
        Icon = "layers",
        Callback = function()
            local hwid = getHardwareId()
            local portalUrl = SERVER_HOST .. "/getkey?hwid=" .. HttpService:UrlEncode(hwid) .. "&provider=lootlabs"
            if setclipboard then
                setclipboard(portalUrl)
            end
            WindUI:Notify({
                Title = "LootLabs Link Copied! 📋",
                Content = "LootLabs URL copied! Open it in your browser:\n" .. portalUrl,
                Duration = 6,
                Icon = "clipboard-check"
            })
        end
    })

    TabKey:Button({
        Title = "🔵 Get Free Key via Linkvertise",
        Desc = "Copy Linkvertise checkpoint link",
        Icon = "external-link",
        Callback = function()
            local hwid = getHardwareId()
            local portalUrl = SERVER_HOST .. "/getkey?hwid=" .. HttpService:UrlEncode(hwid) .. "&provider=linkvertise"
            if setclipboard then
                setclipboard(portalUrl)
            end
            WindUI:Notify({
                Title = "Linkvertise Link Copied! 📋",
                Content = "Linkvertise URL copied! Open it in your browser:\n" .. portalUrl,
                Duration = 6,
                Icon = "clipboard-check"
            })
        end
    })

    TabKey:Button({
        Title = "📋 Copy My Hardware ID (HWID)",
        Desc = "Copy your device HWID to send to admin",
        Icon = "cpu",
        Callback = function()
            local hwid = getHardwareId()
            if setclipboard then
                setclipboard(hwid)
                WindUI:Notify({ Title = "HWID Copied", Content = "HWID copied to clipboard!", Duration = 3, Icon = "clipboard-check" })
            end
        end
    })

    TabKey:Button({
        Title = "💬 Join Discord Community",
        Desc = "Copy Discord invite link (https://discord.gg/cecytf4MHE) to clipboard",
        Icon = "message-circle",
        Callback = function()
            local discordLink = "https://discord.gg/cecytf4MHE"
            if setclipboard then
                setclipboard(discordLink)
            end
            WindUI:Notify({
                Title = "Discord Link Copied! 💬",
                Content = "Discord: " .. discordLink .. "\nJoin Song Hub Discord for support, updates & keys!",
                Duration = 5,
                Icon = "clipboard-check"
            })
        end
    })
end)

