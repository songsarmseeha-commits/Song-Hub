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
    getgenv()._SongHubRevokeCallbacks = getgenv()._SongHubRevokeCallbacks or {}
    getgenv()._SongHubSessionGeneration = tonumber(getgenv()._SongHubSessionGeneration) or 0
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

    -- 0. Jump for Cases🎲
    if uId == 10767621216 or pId == 93545804988403
        or (game:GetService("ReplicatedStorage"):FindFirstChild("CasesConfig") and game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("RequestKick")) then
        return "Jump for Cases🎲", "jump_for_cases.luau"
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
        if t:find("jump for cases") or t:find("jump for case") then return "Jump for Cases🎲", "jump_for_cases.luau" end
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
local DISCORD_INVITE_URL = "https://discord.gg/Cpcg9wU5k"
local KEY_SAVE_PATH = "SongHub/saved_license_key.txt"

local function sanitizeLicenseKey(raw)
    if type(raw) ~= "string" then return "" end
    local s = raw
        :gsub("\226\128[\139\140\141]", "") -- zero-width space/joiner
        :gsub("\239\187\191", "")            -- UTF-8 BOM
        :gsub("\194\160", " ")               -- NBSP
        :gsub("\226\128[\144\145\146\147\148\149]", "-") -- Unicode hyphens/dashes -> ASCII -
        :gsub("\226\136\146", "-")           -- minus sign
        :gsub("\239\188\141", "-")           -- fullwidth hyphen-minus
        :upper()
        :gsub("%s*%-%s*", "-")

    local extracted =
        s:match("FREE%-%w+%-%w+%-%w+") or
        s:match("GALAXY%-%w+%-%w+%-%w+") or
        s:match("PREMIUM%-%w+%-%w+%-%w+") or
        s:match("SONGHUB%-%w+%-%w+%-%w+") or
        s:match("VIP%-%w+%-%w+%-%w+") or
        s:match("%w%w+%-%w%w+%-%w%w+%-%w%w+%-%w%w+") or
        s:match("%w%w+%-%w%w+%-%w%w+%-%w%w+") or
        s:match("%w%w+%-%w%w+%-%w%w+")
    if extracted then
        return extracted
    end
    return s:gsub("[^%w%-_]+", "")
end

local function getHardwareId()
    local function tryHwid(fn)
        if type(fn) ~= "function" then return nil end
        local ok, res = pcall(fn)
        if ok and res ~= nil then
            local trimmed = tostring(res):gsub("[%c]", ""):gsub("^%s+", ""):gsub("%s+$", "")
            if #trimmed > 0 and trimmed ~= "nil" then
                return trimmed
            end
        end
        return nil
    end

    local hw = tryHwid(gethwid) or tryHwid(get_hwid)
    if hw then return hw end

    local okClient, clientId = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if okClient and clientId and #tostring(clientId) > 0 then
        return "RBX_" .. tostring(clientId):gsub("[%c]", "")
    end

    local uid = LocalPlayer and LocalPlayer.UserId or 0
    if identifyexecutor then
        local okExec, exec = pcall(identifyexecutor)
        if okExec and exec and #tostring(exec) > 0 then
            return tostring(exec):gsub("[%c]", "") .. "_" .. tostring(uid)
        end
    end
    return "DEVICE_" .. tostring(uid)
end

local function getRequestFunctions()
    local fns = {}
    local seen = {}
    local function addFn(name, fn)
        if type(fn) == "function" and not seen[fn] then
            seen[fn] = true
            table.insert(fns, { name = name, fn = fn })
        end
    end
    addFn("request", request)
    addFn("http.request", type(http) == "table" and http.request or nil)
    addFn("http_request", http_request)
    addFn("syn.request", type(syn) == "table" and syn.request or nil)
    addFn("fluxus.request", type(fluxus) == "table" and fluxus.request or nil)
    addFn("krnl.request", type(krnl) == "table" and krnl.request or nil)
    return fns
end

local function extractHttpBody(resp)
    if type(resp) == "string" then
        return 200, resp
    end
    if type(resp) == "table" then
        local status = tonumber(resp.StatusCode or resp.status_code or resp.Status or resp.status)
        local body = resp.Body or resp.body or resp.Content or resp.content or resp.Data or resp.data or resp.responseText
        return status, body
    end
    return nil, nil
end

local function buildEdgeQueryUrl(endpointPath, queryParams)
    local parts = { "softStatus=1", "_ts=" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999)) }
    if type(queryParams) == "table" then
        for k, v in pairs(queryParams) do
            if v ~= nil then
                local cleanVal = tostring(v):gsub("[%c]", "")
                local okEnc, encoded = pcall(function() return HttpService:UrlEncode(cleanVal) end)
                table.insert(parts, tostring(k) .. "=" .. (okEnc and encoded or cleanVal))
            end
        end
    end
    return CLOUDFLARE_URL .. endpointPath .. "?" .. table.concat(parts, "&")
end

local function decodeEdgeJson(rawBody)
    if type(rawBody) ~= "string" then return nil end
    local trimmed = rawBody:gsub("^%s+", ""):gsub("%s+$", "")
    if #trimmed == 0 or trimmed:sub(1, 1) ~= "{" then
        return nil
    end
    local data = nil
    pcall(function() data = HttpService:JSONDecode(trimmed) end)
    if type(data) == "table" and (data.success ~= nil or data.active ~= nil or data.code ~= nil or data.message ~= nil) then
        return data
    end
    return nil
end

local function performEdgeRequest(endpointPath, method, payloadTable, queryParams)
    local reqFns = getRequestFunctions()
    local postUrl = CLOUDFLARE_URL .. endpointPath
    local queryUrl = buildEdgeQueryUrl(endpointPath, queryParams)
    local encodedBody = (method == "POST" and type(payloadTable) == "table") and HttpService:JSONEncode(payloadTable) or nil
    local diags = {}

    local function tryRequestMode(useMode)
        for _, entry in ipairs(reqFns) do
            local opts = (useMode == "POST" and encodedBody) and {
                Url = postUrl,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json", ["Accept"] = "application/json" },
                Body = encodedBody
            } or {
                Url = queryUrl,
                Method = "GET"
            }
            local okCall, resp = pcall(entry.fn, opts)
            if okCall and resp ~= nil then
                local status, rawBody = extractHttpBody(resp)
                local decoded = decodeEdgeJson(rawBody)
                if decoded then
                    if getgenv then getgenv()._SongHubPreferredTransport = "request" end
                    return true, decoded, status or 200
                end
                local snippet = (type(rawBody) == "string" and #rawBody > 0) and (rawBody:sub(1, 32):gsub("[\r\n]+", " ")) or "empty"
                table.insert(diags, entry.name .. ":" .. useMode .. "=s" .. tostring(status) .. "(" .. snippet .. ")")
            else
                table.insert(diags, entry.name .. ":" .. useMode .. "=err")
            end
        end
        return false, nil, nil
    end

    local function tryHttpGetFns()
        local getFns = {
            { name = "game:HttpGet", fn = function(u) return game:HttpGet(u) end },
        }
        if type(HttpGet) == "function" then
            table.insert(getFns, { name = "HttpGet", fn = function(u) return HttpGet(u) end })
        end
        table.insert(getFns, { name = "HttpGetAsync", fn = function(u) return game:HttpGetAsync(u) end })

        for _, g in ipairs(getFns) do
            local okGet, rawBody = pcall(g.fn, queryUrl)
            if okGet and type(rawBody) == "string" then
                local decoded = decodeEdgeJson(rawBody)
                if decoded then
                    if getgenv then getgenv()._SongHubPreferredTransport = "httpget" end
                    return true, decoded, 200
                end
                local snippet = #rawBody > 0 and (rawBody:sub(1, 32):gsub("[\r\n]+", " ")) or "empty"
                table.insert(diags, g.name .. "=bad(" .. snippet .. ")")
            else
                local errMsg = tostring(rawBody):gsub("[\r\n]+", " "):sub(1, 44)
                table.insert(diags, g.name .. "=err(" .. errMsg .. ")")
            end
        end
        return false, nil, nil
    end

    local preferHttpGet = getgenv and getgenv()._SongHubPreferredTransport == "httpget"
    if preferHttpGet then
        local okG, decG, stG = tryHttpGetFns()
        if okG then return true, decG, stG end
        if method == "POST" and encodedBody then
            local okP, decP, stP = tryRequestMode("POST")
            if okP then return true, decP, stP end
        end
        local okR, decR, stR = tryRequestMode("GET")
        if okR then return true, decR, stR end
    else
        if method == "POST" and encodedBody then
            local okP, decP, stP = tryRequestMode("POST")
            if okP then return true, decP, stP end
        end
        local okG, decG, stG = tryHttpGetFns()
        if okG then return true, decG, stG end
        local okR, decR, stR = tryRequestMode("GET")
        if okR then return true, decR, stR end
    end

    local diagStr = #diags > 0 and (" [" .. table.concat(diags, "; "):sub(1, 140) .. "]") or " [No HTTP transport]"
    return false, nil, diagStr
end

local function closeSessionRemote(sessionToken)
    if type(sessionToken) ~= "string" or #sessionToken == 0 then return end
    pcall(function()
        performEdgeRequest("/api/v1/session/close", "POST", { sessionToken = sessionToken }, { sessionToken = sessionToken })
    end)
end

local function sendVerifyRequest(key)
    local cleanReqKey = sanitizeLicenseKey(key)
    local hwid = getHardwareId()
    local uid = LocalPlayer and LocalPlayer.UserId or 0
    local uname = LocalPlayer and LocalPlayer.Name or ""
    local jid = game.JobId or ""
    local pid = tostring(game.PlaceId or "")
    local payloadTable = {
        key = cleanReqKey,
        hwid = hwid,
        userId = uid,
        username = uname,
        jobId = jid,
        placeId = pid
    }

    local okEdge, data, extra = performEdgeRequest("/api/verify-key", "POST", payloadTable, payloadTable)
    if not okEdge or type(data) ~= "table" then
        return false, { message = "Could not connect to Cloudflare Auth Edge!" .. (type(extra) == "string" and extra or "") }
    end
    return data.success == true, data
end

local openKeyVerificationWindow

local function clearSavedLicenseKey()
    pcall(function()
        if delfile and isfile and isfile(KEY_SAVE_PATH) then
            delfile(KEY_SAVE_PATH)
        end
    end)
end

local function destroyAllSongHubUIs()
    if getgenv then
        local cbs = getgenv()._SongHubRevokeCallbacks
        if type(cbs) == "table" then
            getgenv()._SongHubRevokeCallbacks = {}
            for _, cb in pairs(cbs) do
                if type(cb) == "function" then
                    pcall(cb)
                end
            end
        end

        if getgenv().AnimeGalaxiesHubShutdown then
            pcall(getgenv().AnimeGalaxiesHubShutdown)
        end

        local winKeys = {
            "_SongHubKeyPromptWindow", "_HT_CurrentWindow", "__BlueLockFarmWindow",
            "__ThrowFoodWindow", "_JFC_Window", "_NetAFish_Window",
            "_Grimorio_Window", "_GB_Window", "__RaycityHubWindow", "_AG_Window"
        }
        getgenv()._SongHubKeyPromptOpen = false
        for _, k in ipairs(winKeys) do
            local w = getgenv()[k]
            if w and type(w) == "table" and w.Destroy then
                pcall(function() w:Destroy() end)
            end
            getgenv()[k] = nil
        end

        if getgenv()._HT_WindUI and type(getgenv()._HT_WindUI) == "table" then
            pcall(function()
                local wui = getgenv()._HT_WindUI
                if wui.ScreenGui then wui.ScreenGui:Destroy() end
                if wui.NotificationGui then wui.NotificationGui:Destroy() end
                if wui.DropdownGui then wui.DropdownGui:Destroy() end
                if wui.TooltipGui then wui.TooltipGui:Destroy() end
            end)
            getgenv()._HT_WindUI = nil
        end

        getgenv()._HT_ScriptRunId = -1
        getgenv()._HuntingTogetherRunning = false
        getgenv()._AG_RUNNING = nil
        getgenv().__BlueLockFarmRunId = -1
        getgenv()._GrimorioRunId = -1
        getgenv()._GloryBoundRunId = -1
        getgenv()._JumpForCasesRunning = -1
        getgenv()._NetAFishRunId = -1
        getgenv().__RaycityHubRunId = -1
        getgenv().__ThrowFoodRunId = -1
    end

    pcall(function()
        local containers = {}
        pcall(function() if gethui then table.insert(containers, gethui()) end end)
        pcall(function()
            local cg = game:GetService("CoreGui")
            table.insert(containers, cg)
            local rg = cg:FindFirstChild("RobloxGui")
            if rg then table.insert(containers, rg) end
        end)
        pcall(function()
            if LocalPlayer then
                local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
                if pg then table.insert(containers, pg) end
            end
        end)
        for _, root in ipairs(containers) do
            if root then
                for _, c in ipairs(root:GetChildren()) do
                    if c:IsA("ScreenGui") then
                        local n = c.Name
                        if n:find("WindUI", 1, true)
                            or n:find("SongHub", 1, true)
                            or n:find("Raycity", 1, true)
                            or n:find("Hunting", 1, true)
                            or n:find("BlueLock", 1, true)
                            or n:find("AnimeGalaxies", 1, true)
                            or n:find("Grimorio", 1, true)
                            or n:find("GloryBound", 1, true)
                            or n:find("NetAFish", 1, true)
                            or n:find("ThrowFood", 1, true)
                            or n:find("JumpForCases", 1, true)
                            or n:find("JFC", 1, true)
                        then
                            pcall(function() c:Destroy() end)
                        end
                    end
                end
            end
        end
    end)
end

local function shutdownActiveScript(reason, reopenPrompt)
    local msg = (type(reason) == "string" and #reason > 0) and reason or "Your license key has expired or session was terminated."
    warn("[Song Hub] 🔒 Session Ended: " .. msg)

    if getgenv then
        if getgenv()._SongHubShuttingDown then
            return
        end
        getgenv()._SongHubShuttingDown = true
        local activeSessionToken = getgenv()._SongHubAuth and getgenv()._SongHubAuth.sessionToken
        getgenv()._SongHubSessionExpired = true
        getgenv()._SongHubSessionGeneration = (tonumber(getgenv()._SongHubSessionGeneration) or 0) + 1
        getgenv()._SongHubHeartbeatRunning = false
        getgenv()._SongHubLoading = false
        getgenv()._SongHubAuth = {
            valid = false,
            revoked = true,
            reason = msg,
            endedClock = os.clock(),
        }
        if type(activeSessionToken) == "string" and #activeSessionToken > 0 then
            task.spawn(closeSessionRemote, activeSessionToken)
        end
        local activeThread = getgenv()._SongHubActiveGameThread
        getgenv()._SongHubActiveGameThread = nil
        if activeThread then
            pcall(task.cancel, activeThread)
        end
    end

    clearSavedLicenseKey()
    destroyAllSongHubUIs()

    if getgenv then
        getgenv()._SongHubShuttingDown = false
    end

    if reopenPrompt ~= false and type(openKeyVerificationWindow) == "function" then
        task.spawn(function()
            task.wait(0.2)
            openKeyVerificationWindow(msg)
        end)
    end
end

local function applyAuthenticatedSession(authData, activeKey)
    local serverTime = tonumber(authData and authData.serverTime)
    local expiresAt = tonumber(authData and authData.expiresAt)
    local whitelisted = (authData and authData.whitelisted == true) or false
    local expiresAtClock = nil

    if expiresAt and expiresAt > 0 then
        local baseTime = (serverTime and serverTime > 0) and serverTime or os.time()
        local remainingSec = expiresAt - baseTime
        if remainingSec <= 0 then
            return false, "Your license key has expired."
        end
        expiresAtClock = os.clock() + remainingSec
    end

    if getgenv then
        getgenv()._SongHubSessionGeneration = (tonumber(getgenv()._SongHubSessionGeneration) or 0) + 1
        getgenv()._SongHubSessionExpired = false
        getgenv()._SongHubShuttingDown = false
        getgenv()._SongHubKeyPromptOpen = false
        getgenv()._SongHubAuth = {
            valid = true,
            revoked = false,
            whitelisted = whitelisted,
            key = activeKey or "",
            sessionToken = (authData and authData.sessionToken) or "",
            expiresAt = expiresAt,
            serverTime = serverTime,
            expiresAtClock = expiresAtClock,
            verifiedClock = os.clock(),
        }
    end
    return true, nil
end

local function startSessionHeartbeat(sessionToken, activeKey, authInfo)
    if not sessionToken or #sessionToken == 0 then return end
    local myGen = getgenv and getgenv()._SongHubSessionGeneration or 0
    if getgenv then getgenv()._SongHubHeartbeatRunning = true end

    local currentToken = sessionToken
    if getgenv and type(getgenv()._SongHubAuth) == "table" and getgenv()._SongHubAuth.sessionToken and #getgenv()._SongHubAuth.sessionToken > 0 then
        currentToken = getgenv()._SongHubAuth.sessionToken
    elseif type(authInfo) == "table" and tonumber(authInfo.expiresAt) and tonumber(authInfo.expiresAt) > 0 then
        applyAuthenticatedSession(authInfo, activeKey)
        myGen = getgenv and getgenv()._SongHubSessionGeneration or myGen
    end

    task.spawn(function()
        while true do
            if getgenv and (getgenv()._SongHubSessionExpired == true or getgenv()._SongHubSessionGeneration ~= myGen) then
                break
            end

            local authState = getgenv and getgenv()._SongHubAuth
            local expiresAtClock = authState and tonumber(authState.expiresAtClock) or nil
            local waitSec = 60
            if expiresAtClock then
                local left = expiresAtClock - os.clock()
                if left <= 0 then
                    waitSec = 0
                elseif left < waitSec then
                    waitSec = math.max(0.5, left)
                end
            end

            if waitSec > 0 then
                task.wait(waitSec)
            end

            if getgenv and (getgenv()._SongHubSessionExpired == true or getgenv()._SongHubSessionGeneration ~= myGen) then
                break
            end

            authState = getgenv and getgenv()._SongHubAuth
            expiresAtClock = authState and tonumber(authState.expiresAtClock) or nil

            local hbPayload = {
                sessionToken = currentToken,
                key = activeKey or ""
            }
            local okReq, decoded = performEdgeRequest("/api/v1/heartbeat", "POST", hbPayload, hbPayload)

            if getgenv and (getgenv()._SongHubSessionExpired == true or getgenv()._SongHubSessionGeneration ~= myGen) then
                break
            end

            local shouldRevoke = false
            local revokeReason = "Your license key has expired or session was closed."
            local gotValidAck = false

            if okReq and type(decoded) == "table" then
                if decoded.active == false or decoded.success == false then
                    shouldRevoke = true
                    if type(decoded.message) == "string" and #decoded.message > 0 then
                        revokeReason = decoded.message
                    end
                elseif decoded.active == true then
                    gotValidAck = true
                    if type(decoded.refreshedToken) == "string" and #decoded.refreshedToken > 0 then
                        currentToken = decoded.refreshedToken
                        if authState then authState.sessionToken = currentToken end
                    end
                    local newExp = tonumber(decoded.expiresAt)
                    local newSrv = tonumber(decoded.serverTime)
                    if decoded.whitelisted == true and (not newExp or newExp <= 0) then
                        if authState then
                            authState.expiresAt = nil
                            authState.expiresAtClock = nil
                        end
                        expiresAtClock = nil
                    elseif newExp and newExp > 0 then
                        local baseT = (newSrv and newSrv > 0) and newSrv or os.time()
                        local rem = newExp - baseT
                        if rem <= 0 then
                            shouldRevoke = true
                            revokeReason = "Your license key has expired."
                        elseif authState then
                            authState.expiresAt = newExp
                            authState.serverTime = newSrv
                            authState.expiresAtClock = os.clock() + rem
                            expiresAtClock = authState.expiresAtClock
                        end
                    end
                end
            end

            if not shouldRevoke and not gotValidAck and expiresAtClock and os.clock() >= expiresAtClock then
                shouldRevoke = true
                revokeReason = "Your license key has expired."
            end

            if shouldRevoke then
                shutdownActiveScript(revokeReason, true)
                break
            end

            if not gotValidAck and waitSec == 0 then
                task.wait(5)
            end
        end

        if getgenv and getgenv()._SongHubSessionGeneration == myGen then
            getgenv()._SongHubHeartbeatRunning = false
        end
    end)

    -- Clean session exit hooks: release server session & idle HWID when teleport completes, player leaves, or game closes
    local closedSent = false
    local function handleClientExit()
        if closedSent then return end
        if getgenv and getgenv()._SongHubSessionGeneration ~= myGen then return end
        closedSent = true
        closeSessionRemote(currentToken)
    end

    pcall(function()
        if LocalPlayer and LocalPlayer.OnTeleport then
            local conn
            conn = LocalPlayer.OnTeleport:Connect(function(state)
                if getgenv and getgenv()._SongHubSessionGeneration ~= myGen then
                    if conn then pcall(function() conn:Disconnect() end) end
                    return
                end
                if state == Enum.TeleportState.InProgress then
                    handleClientExit()
                end
            end)
        end
    end)

    pcall(function()
        local Players = game:GetService("Players")
        if Players and Players.PlayerRemoving then
            local conn
            conn = Players.PlayerRemoving:Connect(function(plr)
                if getgenv and getgenv()._SongHubSessionGeneration ~= myGen then
                    if conn then pcall(function() conn:Disconnect() end) end
                    return
                end
                if plr == LocalPlayer then
                    handleClientExit()
                end
            end)
        end
    end)

    pcall(function()
        if LocalPlayer and LocalPlayer.AncestryChanged then
            local conn
            conn = LocalPlayer.AncestryChanged:Connect(function(_, parent)
                if getgenv and getgenv()._SongHubSessionGeneration ~= myGen then
                    if conn then pcall(function() conn:Disconnect() end) end
                    return
                end
                if not parent then
                    handleClientExit()
                end
            end)
        end
    end)

    pcall(function()
        game:BindToClose(function()
            handleClientExit()
        end)
    end)
end

local lastFetchError = nil
local lastFetchDenied = false
local lastFetchDeniedReason = nil
local function fetchVerifiedLua(url)
    lastFetchError = nil
    lastFetchDenied = false
    lastFetchDeniedReason = nil

    local function checkAccessDeniedText(body)
        if type(body) == "string" then
            local head = body:sub(1, 512):gsub("^%s+", "")
            local deniedMsg = head:match("^%-%-%s*ACCESS_DENIED:%s*(.-)[\r\n]") or head:match("^%-%-%s*ACCESS_DENIED:%s*(.+)$")
            if deniedMsg or head:find("ACCESS_DENIED", 1, true) then
                lastFetchDenied = true
                lastFetchDeniedReason = deniedMsg or "Access denied: Your license key has expired or session is invalid."
                lastFetchError = lastFetchDeniedReason
                return true
            end
        end
        return false
    end

    local function isValidCode(body)
        if checkAccessDeniedText(body) then
            return nil
        end
        if type(body) ~= "string" or #body <= 500 then
            lastFetchError = "body too short (" .. tostring(type(body) == "string" and #body or type(body)) .. ")"
            return nil
        end
        local head = body:sub(1, 512):gsub("^%s+", "")
        if head == "" or head:sub(1, 1) == "<" then
            lastFetchError = "HTML or empty response"
            return nil
        end
        if head:find("403" .. ": Forbidden", 1, true) or head:find("404" .. ": Not Found", 1, true) or head:find("-- Game script" .. " not found", 1, true) or head:find("DEPLOYMENT_DISABLED", 1, true) then
            lastFetchError = "HTTP error response: " .. head:sub(1, 48)
            return nil
        end
        local fn, err = loadstring(body)
        if fn then
            return fn
        end
        lastFetchError = "loadstring error: " .. tostring(err)
        return nil
    end

    local httpGet403 = false
    local ok1, res1 = pcall(function()
        return game:HttpGet(url)
    end)
    if ok1 then
        local fn = isValidCode(res1)
        if fn then
            return res1, fn
        end
        if lastFetchDenied then return nil, nil end
    else
        local errStr = tostring(res1)
        lastFetchError = "game:HttpGet error: " .. errStr
        if errStr:find("403", 1, true) or errStr:find("Forbidden", 1, true) then
            httpGet403 = true
        end
    end

    if type(HttpGet) == "function" and not httpGet403 then
        local ok2, res2 = pcall(HttpGet, url)
        if ok2 then
            local fn = isValidCode(res2)
            if fn then
                return res2, fn
            end
            if lastFetchDenied then return nil, nil end
        end
    end

    local requestFn = (syn and syn.request) or request or (http and http.request) or http_request
    if requestFn then
        local reqTries = {
            {
                Url = url,
                Method = "GET",
                Headers = {
                    ["Cache-Control"] = "no-cache, no-store, must-revalidate",
                    ["Pragma"] = "no-cache",
                }
            },
            {
                Url = url,
                Method = "GET",
            }
        }
        for _, reqOpts in ipairs(reqTries) do
            local rOk, resp = pcall(requestFn, reqOpts)
            if rOk and type(resp) == "table" then
                local status = tonumber(resp.StatusCode or resp.status_code) or 200
                local body = resp.Body or resp.body
                if status == 401 or status == 403 then
                    if not checkAccessDeniedText(body) then
                        lastFetchDenied = true
                        lastFetchDeniedReason = "Access denied (HTTP " .. tostring(status) .. "): Key expired or invalid session."
                        lastFetchError = lastFetchDeniedReason
                    end
                    return nil, nil
                elseif status >= 200 and status < 300 and type(body) == "string" then
                    local fn = isValidCode(body)
                    if fn then
                        return body, fn
                    end
                    if lastFetchDenied then return nil, nil end
                else
                    lastFetchError = "request status " .. tostring(status)
                end
            elseif not rOk then
                lastFetchError = "request error: " .. tostring(resp)
            end
        end
    elseif httpGet403 then
        lastFetchDenied = true
        lastFetchDeniedReason = "Access denied (HTTP 403): Key expired or invalid session."
    end

    return nil, nil
end

local function launchGameScript(sessionToken, activeKey)
    if getgenv and getgenv()._SongHubSessionExpired == true then
        if getgenv then getgenv()._SongHubLoading = false end
        return
    end

    print(string.format("[Song Hub] 🚀 Launching %s securely...", gameTitle))
    local tokenQuery = (sessionToken and #sessionToken > 0) and ("&token=" .. sessionToken) or ""
    local keyQuery = (activeKey and #activeKey > 0) and ("&key=" .. activeKey) or ""

    local scriptCode, compiledFn = nil, nil
    for attempt = 1, 2 do
        local cacheBuster = tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999)) .. "_" .. tostring(attempt)
        local edgeUrl = CLOUDFLARE_URL .. "/scripts/" .. cleanFileName .. "?v=" .. cacheBuster .. tokenQuery .. keyQuery
        scriptCode, compiledFn = fetchVerifiedLua(edgeUrl)
        if compiledFn then
            break
        end
        if lastFetchDenied then
            warn("[Song Hub] 🔒 Edge rejected script launch: " .. tostring(lastFetchDeniedReason))
            shutdownActiveScript(lastFetchDeniedReason or "Access denied: Your license key has expired or session is invalid.", true)
            return
        end

        local ghUrl = "https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/games/" .. cleanFileName .. "?v=" .. cacheBuster
        scriptCode, compiledFn = fetchVerifiedLua(ghUrl)
        if compiledFn then
            break
        end
        if attempt < 2 then
            task.wait(0.75)
        end
    end

    if not compiledFn then
        warn("[Song Hub] ⚠️ Failed to download from online endpoints! (" .. tostring(lastFetchError) .. ") Checking local backup...")
        if isfile and isfile("games/" .. cleanFileName) then
            local ok, localCode = pcall(readfile, "games/" .. cleanFileName)
            if ok and type(localCode) == "string" and #localCode > 500 then
                local fn = loadstring(localCode)
                if fn then
                    scriptCode = localCode
                    compiledFn = fn
                end
            end
        end
    else
        pcall(function()
            if delfile and isfile and isfile("games/" .. cleanFileName) then
                delfile("games/" .. cleanFileName)
            end
        end)
    end

    if getgenv and getgenv()._SongHubSessionExpired == true then
        if getgenv then getgenv()._SongHubLoading = false end
        return
    end

    if compiledFn then
        pcall(function()
            if writefile then
                if makefolder then pcall(makefolder, "autoexec") end
                writefile("autoexec/SongHub.luau", 'local ok,s=pcall(function() return game:HttpGet("https://song-hub-whitelist.song-hub-cloudflare-worker.workers.dev/loader.luau?v="..tostring(os.time())) end); if not ok or type(s)~="string" or #s<500 then ok,s=pcall(function() return game:HttpGet("https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/loader.luau?v="..tostring(os.time())) end) end; if ok and type(s)=="string" and #s>500 then local f=loadstring(s); if f then f() end end')
            end
        end)
-- [Security] Local file dump removed to prevent code leak

        print("[Song Hub] ✅ Successfully compiled " .. gameTitle .. " (Online Latest)! Launching UI...")
        if getgenv then getgenv()._SongHubLoading = false end
        local gameThread = task.spawn(compiledFn)
        if getgenv then getgenv()._SongHubActiveGameThread = gameThread end
    else
        if getgenv then getgenv()._SongHubLoading = false end
        warn("[Song Hub] ❌ Could not download or compile " .. scriptFileName .. " from GitHub / Cloudflare!")
    end
end

-- ==============================================================================
-- 3. AUTHENTICATION PIPELINE
-- ==============================================================================
local function loadStep3WindUI()
    local urls = {
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
        "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
    }
    for _, u in ipairs(urls) do
        local _, fn = fetchVerifiedLua(u)
        if fn then
            local okW, ui = pcall(fn)
            if okW and type(ui) == "table" and ui.CreateWindow then
                return ui
            end
        end
    end
    if isfile and readfile and isfile("WindUI_cache.lua") then
        local okC, cached = pcall(readfile, "WindUI_cache.lua")
        if okC and type(cached) == "string" and #cached > 10000 then
            local fn = loadstring(cached)
            if fn then
                local okW, ui = pcall(fn)
                if okW and type(ui) == "table" and ui.CreateWindow then
                    return ui
                end
            end
        end
    end
    return nil
end

openKeyVerificationWindow = function(statusMessage)
    if getgenv then
        if getgenv()._SongHubKeyPromptOpen and getgenv()._SongHubKeyPromptWindow then
            return
        end
        getgenv()._SongHubKeyPromptOpen = true
    end

    local WindUI = loadStep3WindUI()
    if not WindUI then
        if getgenv then
            getgenv()._SongHubKeyPromptOpen = false
            getgenv()._SongHubLoading = false
        end
        warn("[Song Hub] ❌ Failed to load WindUI framework for Key System! Reason: " .. tostring(lastFetchError))
        return
    end

    if getgenv and getgenv()._SongHubKeyPromptWindow then
        pcall(function() getgenv()._SongHubKeyPromptWindow:Destroy() end)
        getgenv()._SongHubKeyPromptWindow = nil
    end

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

    if getgenv then
        getgenv()._SongHubKeyPromptWindow = Window
        pcall(function()
            Window:OnDestroy(function()
                if getgenv()._SongHubKeyPromptWindow == Window then
                    getgenv()._SongHubKeyPromptWindow = nil
                    getgenv()._SongHubKeyPromptOpen = false
                end
            end)
        end)
    end

    -- ==============================================================================
    -- 🖱️ UI CLICKABILITY & MODAL ENHANCER (FIX UNCLICKABLE UI BUG)
    -- Ensures WindUI is always topmost (DisplayOrder 999999) and mouse cursor is
    -- permanently freed from vehicle camera LockCenter so all buttons/dropdowns work.
    -- ==============================================================================
    pcall(function()
        local UserInputService = game:GetService("UserInputService")
        local roots = {
            (typeof(gethui) == "function" and gethui()) or nil,
            game:GetService("CoreGui"),
            LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        }

        local function elevateGui(sg)
            if sg:IsA("ScreenGui") then
                local name = sg.Name
                if name:find("WindUI") or name:find("RaycityHub") or name:find("SongHub") then
                    sg.DisplayOrder = 999999
                    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

                    if not sg:FindFirstChild("_MouseUnlockerModal") then
                        local modalBtn = Instance.new("TextButton")
                        modalBtn.Name = "_MouseUnlockerModal"
                        modalBtn.Size = UDim2.new(0, 0, 0, 0)
                        modalBtn.Position = UDim2.new(0, 0, 0, 0)
                        modalBtn.BackgroundTransparency = 1
                        modalBtn.Text = ""
                        modalBtn.Modal = true
                        modalBtn.Active = false
                        modalBtn.Selectable = false
                        modalBtn.Parent = sg
                    end
                end
            end
        end

        for _, root in ipairs(roots) do
            if root then
                for _, desc in ipairs(root:GetDescendants()) do
                    elevateGui(desc)
                end
                root.DescendantAdded:Connect(function(desc)
                    task.wait(0.02)
                    elevateGui(desc)
                end)
            end
        end

        UserInputService.MouseIconEnabled = true
        if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
    end)

    local TabKey = Window:Tab({ Title = "Key Verification", Icon = "key" })

    local hasNotice = (type(statusMessage) == "string" and #statusMessage > 0)
    local descText = hasNotice
        and ("⚠️ " .. statusMessage .. "\n\nPlease enter a new valid license key or claim a free 24h key below.")
        or "This Hub is protected by Song Hub Edge Whitelist.\nPlease enter your key to continue.\nDirect whitelisted users bypass this automatically."

    local StatusParagraph = TabKey:Paragraph({
        Title = hasNotice and "License Verification Required" or "License Key Required",
        Desc = descText,
        Image = hasNotice and "alert-triangle" or "lock"
    })

    local function setPromptStatus(title, desc, image)
        pcall(function()
            if StatusParagraph and type(StatusParagraph.SetTitle) == "function" then
                StatusParagraph:SetTitle(title)
            end
            if StatusParagraph and type(StatusParagraph.SetDesc) == "function" then
                StatusParagraph:SetDesc(desc)
            elseif StatusParagraph and type(StatusParagraph.SetContent) == "function" then
                StatusParagraph:SetContent(desc)
            end
            if image and StatusParagraph and type(StatusParagraph.SetImage) == "function" then
                StatusParagraph:SetImage(image)
            end
        end)
    end

    if hasNotice then
        pcall(function()
            WindUI:Notify({
                Title = "Session Ended 🔒",
                Content = statusMessage,
                Duration = 6,
                Icon = "alert-triangle"
            })
        end)
    end

    local inputKey = ""
    local isVerifying = false
    local KeyInputObj = nil

    local function readLiveInputBox()
        local foundText = ""
        pcall(function()
            local containers = {
                (typeof(gethui) == "function" and gethui()) or nil,
                game:GetService("CoreGui"),
                LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui"),
            }
            for _, root in ipairs(containers) do
                if root then
                    for _, desc in ipairs(root:GetDescendants()) do
                        if desc:IsA("TextBox") and desc.Visible then
                            local sg = desc:FindFirstAncestorWhichIsA("ScreenGui")
                            if not sg or sg.Enabled then
                                local visOk = true
                                local cur = desc.Parent
                                while cur and cur ~= sg and visOk do
                                    if cur:IsA("GuiObject") and not cur.Visible then
                                        visOk = false
                                    end
                                    cur = cur.Parent
                                end
                                if visOk then
                                    local ph = desc.PlaceholderText or ""
                                    if ph:find("SONGHUB", 1, true) then
                                        local t = desc.Text or ""
                                        if #t > 0 then
                                            foundText = t
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
        if #foundText > 0 then return foundText end
        pcall(function()
            if KeyInputObj and type(KeyInputObj.Value) == "string" and #KeyInputObj.Value > 0 then
                foundText = KeyInputObj.Value
            end
        end)
        return foundText
    end

    KeyInputObj = TabKey:Input({
        Title = "Enter License Key",
        Desc = "Paste your license key here (e.g. FREE-XXXX or SONGHUB-XXXX)",
        Placeholder = "SONGHUB-XXXX-XXXX-XXXX",
        Callback = function(txt)
            local clean = sanitizeLicenseKey(txt)
            if #clean > 0 or #(txt or "") == 0 then
                inputKey = clean
            end
        end
    })

    TabKey:Button({
        Title = "🔓 Verify & Unlock Song Hub",
        Desc = "Verify key and start script",
        Icon = "check-circle",
        Callback = function()
            if isVerifying then return end

            local liveBoxText = sanitizeLicenseKey(readLiveInputBox())
            if #liveBoxText > 0 then
                inputKey = liveBoxText
            else
                inputKey = sanitizeLicenseKey(inputKey)
            end

            if #inputKey == 0 then
                setPromptStatus("Key Required", "Please paste or type your license key into the box below first.", "alert-circle")
                WindUI:Notify({ Title = "Error", Content = "Please enter a license key!", Duration = 3, Icon = "alert-circle" })
                return
            end

            isVerifying = true
            setPromptStatus("Verifying Key...", "Contacting Cloudflare Edge for key: " .. inputKey, "loader")
            WindUI:Notify({ Title = "Verifying", Content = "Contacting Cloudflare Edge...", Duration = 2, Icon = "loader" })
            local ok, result = sendVerifyRequest(inputKey)

            if ok then
                local authOk, authErr = applyAuthenticatedSession(result, inputKey)
                if not authOk then
                    isVerifying = false
                    clearSavedLicenseKey()
                    local errMsg = authErr or "Invalid or expired key!"
                    setPromptStatus("Access Denied ❌", errMsg, "x-circle")
                    WindUI:Notify({
                        Title = "Access Denied ❌",
                        Content = errMsg,
                        Duration = 5,
                        Icon = "x-circle"
                    })
                    return
                end

                if writefile then
                    if makefolder then pcall(makefolder, "SongHub") end
                    pcall(writefile, KEY_SAVE_PATH, inputKey)
                end

                startSessionHeartbeat(result.sessionToken, inputKey, result)

                WindUI:Notify({
                    Title = "Access Granted! ✨",
                    Content = (result and result.message) or "Welcome to Song Hub!",
                    Duration = 4,
                    Icon = "sparkles"
                })

                local unlockedToken = result and result.sessionToken or ""
                local unlockedKey = inputKey
                task.spawn(function()
                    task.wait(0.9)
                    if getgenv then
                        getgenv()._SongHubKeyPromptOpen = false
                        getgenv()._SongHubKeyPromptWindow = nil
                    end
                    pcall(function() Window:Destroy() end)
                    task.wait(0.05)
                    launchGameScript(unlockedToken, unlockedKey)
                end)
            else
                isVerifying = false
                local errCode = result and result.code
                if errCode == "KEY_EXPIRED" or errCode == "KEY_REVOKED" or errCode == "INVALID_KEY" then
                    clearSavedLicenseKey()
                end
                local errMsg = (result and result.message) or "Invalid or expired key!"
                setPromptStatus("Access Denied ❌", errMsg, "x-circle")
                WindUI:Notify({
                    Title = "Access Denied ❌",
                    Content = errMsg,
                    Duration = 5,
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
end

-- Step 1: Check Locally Saved Key first (Edge /api/verify-key already checks Direct Whitelist before key validation,
-- avoiding an extra HTTP request + D1 read for returning users)
local initialPromptReason = nil
local cleanSavedKey = ""
if isfile and isfile(KEY_SAVE_PATH) then
    local savedKey = ""
    pcall(function() savedKey = readfile(KEY_SAVE_PATH) end)
    if savedKey and #savedKey > 3 then
        cleanSavedKey = sanitizeLicenseKey(savedKey)
    end
end

if #cleanSavedKey > 3 then
    local keyOk, keyData = sendVerifyRequest(cleanSavedKey)
    if keyOk then
        local isWl = keyData.whitelisted == true
        local activeKeyArg = isWl and "" or cleanSavedKey
        local authOk, authErr = applyAuthenticatedSession(keyData, activeKeyArg)
        if authOk then
            if isWl then
                print(string.format("[Song Hub] ✅ Direct Whitelist passed! Welcome %s (%s)", LocalPlayer.Name, keyData.role or "VIP/Owner"))
            else
                print(string.format("[Song Hub] ✅ Key Verified from Cache! Type: %s (Live Sessions: %s/%s)", keyData.keyType or "Active", tostring(keyData.activeSessionsCount or 1), tostring(keyData.maxSessions or 1)))
            end
            startSessionHeartbeat(keyData.sessionToken or "", activeKeyArg, keyData)
            launchGameScript(keyData.sessionToken or "", activeKeyArg)
            return
        else
            if not isWl then
                clearSavedLicenseKey()
            end
            shutdownActiveScript(authErr, false)
            initialPromptReason = authErr
        end
    elseif type(keyData) == "table" then
        local code = keyData.code
        if code == "KEY_EXPIRED" or code == "KEY_REVOKED" or code == "INVALID_KEY" then
            clearSavedLicenseKey()
            shutdownActiveScript(keyData.message or "Saved key is no longer valid.", false)
        end
        if type(keyData.message) == "string" and #keyData.message > 0 then
            initialPromptReason = keyData.message
        end
    end
else
    -- Step 2: No saved key -> Check Direct Roblox UserID Whitelist (VIP/Owner auto-bypass)
    local wlOk, wlData = sendVerifyRequest("")
    if wlOk and wlData.whitelisted then
        local authOk = applyAuthenticatedSession(wlData, "")
        if authOk then
            print(string.format("[Song Hub] ✅ Direct Whitelist passed! Welcome %s (%s)", LocalPlayer.Name, wlData.role or "VIP/Owner"))
            startSessionHeartbeat(wlData.sessionToken or "", "", wlData)
            launchGameScript(wlData.sessionToken or "", "")
            return
        end
    end
end

-- Step 3: Prompt User for Key via WindUI
openKeyVerificationWindow(initialPromptReason)
