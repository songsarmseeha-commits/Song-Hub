-- ==============================================================================
-- 👑 UNIVERSAL ALL-IN-ONE MULTI-GAME HUB LOADER WITH KEY SYSTEM
-- Supported Games:
--   1. ⚔️ Anime Galaxies (Lobby & Match Acts)
--   2. 🎃 Hunting Together (All Fields & Dungeons)
--   3. ⚽ Blue Lock Farm (Auto Obby, Polisher & Event Farm)
-- Protected with: Universal Whitelist & Key System Web Portal
-- ==============================================================================

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
        placeId = game.PlaceId
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
-- 3. SCRIPT EXECUTION ENGINE
-- ==============================================================================
local function launchGameScript(scriptFileName, gameTitle)
    print(string.format("[Universal Hub] 🚀 Launching script for %s...", gameTitle))

    -- Try local file first (fastest, works offline in workspace)
    local localCandidates = {
        "games/" .. scriptFileName,
        "UniversalHub/" .. scriptFileName,
        scriptFileName
    }

    if scriptFileName == "anime_galaxies.luau" then
        table.insert(localCandidates, "AnimeGalaxiesHub/AnimeGalaxies_Hub.luau")
        table.insert(localCandidates, "AnimeGalaxies_Hub.luau")
    end

    for _, path in ipairs(localCandidates) do
        if isfile and isfile(path) then
            local ok, content = pcall(readfile, path)
            if ok and content and #content > 50 then
                local fn, err = loadstring(content)
                if fn then
                    print("[Universal Hub] Loaded from local file: " .. path)
                    task.spawn(fn)
                    return
                else
                    warn("[Universal Hub] Failed to compile local file (" .. path .. "): " .. tostring(err))
                end
            end
        end
    end

    -- Fallback: Fetch directly from Whitelist Server
    local url = SERVER_HOST .. "/scripts/" .. scriptFileName .. "?v=" .. tostring(tick())
    local dlOk, code = pcall(game.HttpGet, game, url)
    if dlOk and code and #code > 50 then
        local fn, err = loadstring(code)
        if fn then
            print("[Universal Hub] Downloaded and executed from server: " .. url)
            task.spawn(fn)
            return
        else
            warn("[Universal Hub] Error compiling script: " .. tostring(err))
        end
    else
        warn("[Universal Hub] Failed to download script from: " .. url)
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
                Content = "Game not supported! (PlaceId: " .. tostring(game.PlaceId) .. ")\nSupported: Anime Galaxies, Hunting Together, Blue Lock Farm",
                Duration = 6,
                Icon = "alert-triangle"
            })
        end)
        return
    end

    -- Step A: Check Direct Whitelist (VIP/Owner bypass)
    local wlOk, wlData = sendVerifyRequest("")
    if wlOk and wlData.whitelisted then
        print(string.format("[Universal Hub] 👑 Direct Whitelist Active: Welcome %s (%s)", LocalPlayer.Name, wlData.role or "VIP"))
        launchGameScript(scriptFileName, gameTitle)
        return
    end

    -- Step B: Check Locally Saved License Key
    if isfile and isfile(KEY_SAVE_PATH) then
        local savedKey = ""
        pcall(function() savedKey = readfile(KEY_SAVE_PATH) end)
        if savedKey and #savedKey > 3 then
            local keyOk, keyData = sendVerifyRequest(savedKey:gsub("%s+", ""))
            if keyOk then
                print(string.format("[Universal Hub] 🔑 License Key Active: %s (Type: %s)", savedKey, keyData.keyType or "Active"))
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
                        pcall(function()
                            if not isfolder("UniversalHub") then makefolder("UniversalHub") end
                            writefile(KEY_SAVE_PATH, cd.key)
                        end)
                        print(string.format("[Universal Hub] ⚡ Auto-Detected Claimed Key for HWID: %s", cd.key))
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
        Desc = "Paste your license key here (e.g. GALAXY-XXXX-XXXX)",
        Placeholder = "GALAXY-XXXX-XXXX",
        Callback = function(txt)
            inputKey = (txt or ""):gsub("%s+", "")
        end
    })

    local function handleSuccessfulUnlock(validKey, msg)
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
        Title = "🔓 Verify & Unlock Hub",
        Desc = "Authenticate entered key with server and launch script",
        Icon = "check-circle",
        Callback = function()
            -- Extract key robustly from Callback variable, Input Object, or internal TextBox
            local keyToTest = inputKey
            if not keyToTest or #keyToTest == 0 then
                if KeyInput and KeyInput.Value and #KeyInput.Value > 0 then
                    keyToTest = KeyInput.Value:gsub("%s+", "")
                end
            end
            if not keyToTest or #keyToTest == 0 then
                if KeyInput and KeyInput.ElementFrame then
                    for _, d in ipairs(KeyInput.ElementFrame:GetDescendants()) do
                        if d:IsA("TextBox") and #d.Text > 0 then
                            keyToTest = d.Text:gsub("%s+", "")
                            break
                        end
                    end
                end
            end

            if not keyToTest or #keyToTest == 0 then
                WindUI:Notify({ Title = "Error", Content = "Please enter a license key!", Duration = 3, Icon = "alert-circle" })
                return
            end

            WindUI:Notify({ Title = "Verifying", Content = "Contacting authentication server...", Duration = 2, Icon = "loader" })
            local ok, result = sendVerifyRequest(keyToTest)

            if ok then
                handleSuccessfulUnlock(keyToTest, result.message)
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
                    handleSuccessfulUnlock(cd.key, vData.message)
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
        Title = "🔑 Get Free 24h Key (LootLabs / Linkvertise)",
        Desc = "Copy Get Key link to browser to claim free 24-hour key",
        Icon = "external-link",
        Callback = function()
            local hwid = getHardwareId()
            local portalUrl = SERVER_HOST .. "/getkey?hwid=" .. HttpService:UrlEncode(hwid)
            if setclipboard then
                setclipboard(portalUrl)
            end
            WindUI:Notify({
                Title = "Link Copied! 📋",
                Content = "Get Key URL copied! Open it in your browser:\n" .. portalUrl,
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
end)

