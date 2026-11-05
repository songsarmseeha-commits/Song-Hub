-- ==============================================================================
-- 👑 SONG HUB | ALL-IN-ONE MULTI-GAME HUB LOADER WITH ANIMATED KEY SYSTEM
-- Supported Games:
--   1. ⚔️ Anime Galaxies (Lobby & Match Acts)
--   2. 🎃 Hunting Together (All Fields & Dungeons)
--   3. ⚽ Blue Lock Farm (Auto Obby, Polisher & Event Farm)
-- Protected with: Song Hub Whitelist & Key System Web Portal
-- ==============================================================================

-- 🛡️ Anti-Duplicate / Singleton Guard for Loader
-- Prevents duplicate loader executions from executor autoexecute + queue_on_teleport
if getgenv then
    local now = os.clock()
    -- 1. If game script is already running healthy with its UI window active, do NOT reload!
    if getgenv()._HuntingTogetherRunning == true and getgenv()._HT_CurrentWindow then
        print("[Song Hub] 🛡️ Script is already running with active UI! Skipping duplicate loader run.")
        return
    end
    -- 2. If loader was executed in another thread less than 5 seconds ago, ignore duplicate run
    if getgenv()._UniversalLoaderLoading and (now - (getgenv()._UniversalLoaderTime or 0)) < 6 then
        print("[Song Hub] ⏳ Loader is already starting in another thread, skipping duplicate run...")
        return
    end
    getgenv()._UniversalLoaderLoading = true
    getgenv()._UniversalLoaderTime = now
end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    pcall(function()
        LocalPlayer = Players.PlayerAdded:Wait()
    end)
    LocalPlayer = Players.LocalPlayer
end

-- ⚙️ CONFIGURATION
local SERVER_HOST = "https://song-hub-avp8.onrender.com" -- Worldwide Live Cloud Server (Render)
local VERIFY_URL = SERVER_HOST .. "/api/v1/verify"
local GET_KEY_URL = SERVER_HOST .. "/getkey"
local KEY_SAVE_PATH = "UniversalHub/saved_key.txt"

-- Safe Executor HWID Fetcher
local function getHardwareId()
    if gethwid then return gethwid() end
    if get_hwid then return get_hwid() end
    local uid = tostring((LocalPlayer and LocalPlayer.UserId) or 0)
    if identifyexecutor then
        local exec = identifyexecutor()
        return exec .. "_" .. uid
    end
    return "DEVICE_" .. uid
end

-- Active Session State & Heartbeat Loop
local activeSessionToken = nil

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
                        warn("[Song Hub] ⚠️ Session terminated by server (revoked or session limit reached)!")
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

    local lp = LocalPlayer or Players.LocalPlayer
    local payload = HttpService:JSONEncode({
        key = key or "",
        hwid = getHardwareId(),
        userId = (lp and lp.UserId) or 0,
        username = (lp and lp.Name) or "Player",
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
        return false, { message = "Cannot connect to Song Hub Server (" .. SERVER_HOST .. ")" }
    end

    local data = nil
    pcall(function()
        data = HttpService:JSONDecode(response.Body)
    end)

    if not data then
        return false, { message = "Invalid response from Song Hub Server" }
    end

    return data.success == true, data
end

-- ==============================================================================
-- 3. SCRIPT EXECUTION ENGINE (ALWAYS FETCH LATEST FROM CLOUD)
-- ==============================================================================
local function launchGameScript(scriptFileName, gameTitle)
    print(string.format("[Song Hub] 🚀 Launching latest script for %s...", gameTitle))
    if getgenv then
        getgenv()._UniversalLoaderLoading = false
    end

    local cacheBuster = tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
    local candidateUrls = {
        -- 1. Official GitHub Raw (Fastest 200ms, 99.99% uptime, no sleep/cold start)
        "https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/games/" .. scriptFileName .. "?v=" .. cacheBuster,
        -- 2. Live Render Production Server
        SERVER_HOST .. "/scripts/" .. scriptFileName .. "?v=" .. cacheBuster,
        -- 3. Secondary GitHub Server Repo
        "https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub-Server/main/games/" .. scriptFileName .. "?v=" .. cacheBuster,
    }

    for _, url in ipairs(candidateUrls) do
        local dlOk, code = pcall(function()
            return game:HttpGet(url)
        end)
        if dlOk and type(code) == "string" and #code > 500 then
            local fn, err = loadstring(code)
            if fn then
                print("[Song Hub] ✅ Downloaded and compiled latest script from: " .. url)
                pcall(function()
                    if writefile then
                        if not isfolder("UniversalHub") then makefolder("UniversalHub") end
                        writefile("UniversalHub/" .. scriptFileName, code)
                        if scriptFileName == "hunting_together.luau" then
                            writefile("hunting_together_script.lua", code)
                            writefile("hunting_together.luau", code)
                        end
                    end
                end)
                task.spawn(fn)
                return
            else
                warn("[Song Hub] ⚠️ Compile error from " .. url .. ": " .. tostring(err))
            end
        end
    end

    warn("[Song Hub] ⚠️ Failed to download from all cloud endpoints, checking offline cache...")

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
    end

    for _, path in ipairs(localCandidates) do
        if isfile and isfile(path) then
            local ok, content = pcall(readfile, path)
            if ok and content and #content > 50 then
                local fn, err = loadstring(content)
                if fn then
                    print("[Song Hub] Loaded from offline cache: " .. path)
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
    if not LocalPlayer then
        LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
    end

    local gameKey, gameTitle, scriptFileName = detectGame()
    if not gameKey then
        warn(string.format("[Song Hub] ❌ Current game (PlaceId: %s) is not supported!", tostring(game.PlaceId)))
        pcall(function()
            local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
            WindUI:Notify({
                Title = "👑 Song Hub",
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
        print(string.format("[Song Hub] 👑 Direct Whitelist Active: Welcome %s (%s)", tostring(LocalPlayer and LocalPlayer.Name or "VIP"), wlData.role or "VIP"))
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
                print(string.format("[Song Hub] 🔑 License Key Active: %s (Type: %s)", savedKey, keyData.keyType or "Active"))
                if keyData and keyData.sessionToken then
                    startHeartbeatLoop(keyData.sessionToken, savedKey)
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
                        pcall(function()
                            if not isfolder("UniversalHub") then makefolder("UniversalHub") end
                            writefile(KEY_SAVE_PATH, cd.key)
                        end)
                        print(string.format("[Song Hub] ⚡ Auto-Detected Claimed Key for HWID: %s", cd.key))
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

    -- Step C: Key Required -> Open Song Hub Animated Key System Window
    local WindUI = nil
    if isfile and isfile("WindUI_cache.lua") and readfile then
        local ok, res = pcall(function() return loadstring(readfile("WindUI_cache.lua"))() end)
        if ok and res and type(res) == "table" and res.CreateWindow then
            WindUI = res
        end
    end
    if not WindUI then
        local content = game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua")
        WindUI = loadstring(content)()
        if writefile and content then
            pcall(function() writefile("WindUI_cache.lua", content) end)
        end
    end

    -- Read user's saved theme preference if available
    local savedThemeName = "🎃 Skull King's Crypt (สุสานราชาโครงกระดูก)"
    local savedAnimEnabled = true
    local savedStyleName = "Auto (ตามธีมดันเจี้ยน)"
    local savedGlass = 28
    local userCfgPath = "HuntingTogether_Config_" .. tostring((LocalPlayer and LocalPlayer.UserId) or 0) .. ".json"
    pcall(function()
        if isfile and readfile and isfile(userCfgPath) then
            local dec = HttpService:JSONDecode(readfile(userCfgPath))
            if type(dec) == "table" then
                if dec.UITheme then savedThemeName = dec.UITheme end
                if dec.UIBackgroundAnimation ~= nil then savedAnimEnabled = dec.UIBackgroundAnimation end
                if dec.UIAnimationStyle then savedStyleName = dec.UIAnimationStyle end
                if dec.UIGlassTransparency then savedGlass = tonumber(dec.UIGlassTransparency) or 28 end
            end
        end
    end)

    local Window = WindUI:CreateWindow({
        Title = "👑 Song Hub | Key Verification",
        Icon = "shield-check",
        Author = "Song Hub • " .. gameTitle,
        Folder = "UniversalHub",
        Size = UDim2.fromOffset(530, 445),
        Transparent = true,
        Theme = "Dark",
        Acrylic = false,
        Resizable = false
    })

    -- ==================== 🎨 SONG HUB KEY UI ANIMATED BACKGROUND & THEME ENGINE ====================
    local keyAnimConn = nil
    local THEME_PRESETS = {
        ["🎃 Skull King's Crypt (สุสานราชาโครงกระดูก)"] = {
            Id = "SongKey_SkullKing", Effect = "Embers",
            Accent = "#1F1135", Background = "#0C0716", Dialog = "#150C26", Outline = "#FF7A18",
            Text = "#FFF7ED", Placeholder = "#B794F4", Button = "#391E5A", Icon = "#FB923C",
            Toggle = "#F97316", Slider = "#F97316", SliderIcon = "#FDBA74", Checkbox = "#F97316",
            Primary = "#F97316", ElementBackground = "#211238", PanelBackground = "#170C29", LabelBackground = "#090410",
            Grad1 = Color3.fromHex("#0D0618"), Grad2 = Color3.fromHex("#23103A"), Grad3 = Color3.fromHex("#2A1119"),
            Orb1 = Color3.fromHex("#FF6B1A"), Orb2 = Color3.fromHex("#9333EA"), Orb3 = Color3.fromHex("#E11D48"),
            Particle1 = Color3.fromHex("#FF8A00"), Particle2 = Color3.fromHex("#C084FC"), RuneColor = Color3.fromHex("#FB923C"),
        },
        ["🩸 Blood Moon Abyss (ห้วงเหวจันทร์สีเลือด)"] = {
            Id = "SongKey_BloodMoon", Effect = "BloodMist",
            Accent = "#2A0912", Background = "#110408", Dialog = "#1C060C", Outline = "#FF1E42",
            Text = "#FFF1F2", Placeholder = "#FDA4AF", Button = "#4C0D1D", Icon = "#FB7185",
            Toggle = "#E11D48", Slider = "#F43F5E", SliderIcon = "#FDA4AF", Checkbox = "#E11D48",
            Primary = "#E11D48", ElementBackground = "#2D0A14", PanelBackground = "#1F060D", LabelBackground = "#0C0205",
            Grad1 = Color3.fromHex("#110307"), Grad2 = Color3.fromHex("#300813"), Grad3 = Color3.fromHex("#1F050B"),
            Orb1 = Color3.fromHex("#FF1E42"), Orb2 = Color3.fromHex("#9F1239"), Orb3 = Color3.fromHex("#FB7185"),
            Particle1 = Color3.fromHex("#FF2A55"), Particle2 = Color3.fromHex("#FCA5A5"), RuneColor = Color3.fromHex("#F43F5E"),
        },
        ["❄️ Soulfrost Catacombs (สุสานน้ำแข็งวิญญาณ)"] = {
            Id = "SongKey_Soulfrost", Effect = "Snowfall",
            Accent = "#0C223B", Background = "#06101E", Dialog = "#0A192F", Outline = "#38BDF8",
            Text = "#F0F9FF", Placeholder = "#7DD3FC", Button = "#15365C", Icon = "#38BDF8",
            Toggle = "#0EA5E9", Slider = "#38BDF8", SliderIcon = "#BAE6FD", Checkbox = "#0EA5E9",
            Primary = "#0EA5E9", ElementBackground = "#0F2744", PanelBackground = "#0A1B30", LabelBackground = "#040B14",
            Grad1 = Color3.fromHex("#050E1A"), Grad2 = Color3.fromHex("#0D2847"), Grad3 = Color3.fromHex("#091E36"),
            Orb1 = Color3.fromHex("#00E5FF"), Orb2 = Color3.fromHex("#0284C7"), Orb3 = Color3.fromHex("#7DD3FC"),
            Particle1 = Color3.fromHex("#E0F2FE"), Particle2 = Color3.fromHex("#38BDF8"), RuneColor = Color3.fromHex("#38BDF8"),
        },
        ["🔮 Shadow Monarch's Sanctum (วิหารจักรพรรดิเงา)"] = {
            Id = "SongKey_ShadowMonarch", Effect = "ShadowAura",
            Accent = "#180E36", Background = "#080514", Dialog = "#110926", Outline = "#A855F7",
            Text = "#FAF5FF", Placeholder = "#C084FC", Button = "#2E1663", Icon = "#C084FC",
            Toggle = "#9333EA", Slider = "#A855F7", SliderIcon = "#E9D5FF", Checkbox = "#9333EA",
            Primary = "#9333EA", ElementBackground = "#1C103D", PanelBackground = "#120A29", LabelBackground = "#06030F",
            Grad1 = Color3.fromHex("#070412"), Grad2 = Color3.fromHex("#1E0F42"), Grad3 = Color3.fromHex("#11183D"),
            Orb1 = Color3.fromHex("#A855F7"), Orb2 = Color3.fromHex("#4F46E5"), Orb3 = Color3.fromHex("#C084FC"),
            Particle1 = Color3.fromHex("#A855F7"), Particle2 = Color3.fromHex("#60A5FA"), RuneColor = Color3.fromHex("#C084FC"),
        },
        ["🐉 Tempest Dragon Shrine (วิหารมังกรวายุคลั่ง)"] = {
            Id = "SongKey_TempestDragon", Effect = "WindStream",
            Accent = "#0B2922", Background = "#051310", Dialog = "#081F1A", Outline = "#10B981",
            Text = "#ECFDF5", Placeholder = "#6EE7B7", Button = "#13473B", Icon = "#34D399",
            Toggle = "#10B981", Slider = "#34D399", SliderIcon = "#A7F3D0", Checkbox = "#10B981",
            Primary = "#10B981", ElementBackground = "#0E3028", PanelBackground = "#09211B", LabelBackground = "#030D0A",
            Grad1 = Color3.fromHex("#04100D"), Grad2 = Color3.fromHex("#0D332A"), Grad3 = Color3.fromHex("#08222B"),
            Orb1 = Color3.fromHex("#10B981"), Orb2 = Color3.fromHex("#0D9488"), Orb3 = Color3.fromHex("#6EE7B7"),
            Particle1 = Color3.fromHex("#34D399"), Particle2 = Color3.fromHex("#99F6E4"), RuneColor = Color3.fromHex("#34D399"),
        },
        ["🌋 Infernal Magma Core (แกนกลางลาวานรก)"] = {
            Id = "SongKey_MagmaCore", Effect = "MagmaSparks",
            Accent = "#2B1309", Background = "#120804", Dialog = "#1F0D06", Outline = "#F97316",
            Text = "#FFFBEB", Placeholder = "#FDBA74", Button = "#4D200E", Icon = "#FB923C",
            Toggle = "#EA580C", Slider = "#F97316", SliderIcon = "#FDE047", Checkbox = "#EA580C",
            Primary = "#EA580C", ElementBackground = "#30150A", PanelBackground = "#210E07", LabelBackground = "#0D0502",
            Grad1 = Color3.fromHex("#120703"), Grad2 = Color3.fromHex("#331408"), Grad3 = Color3.fromHex("#290B08"),
            Orb1 = Color3.fromHex("#F97316"), Orb2 = Color3.fromHex("#DC2626"), Orb3 = Color3.fromHex("#FACC15"),
            Particle1 = Color3.fromHex("#FB923C"), Particle2 = Color3.fromHex("#FDE047"), RuneColor = Color3.fromHex("#F97316"),
        },
        ["🏛️ Pharaoh's Golden Vault (มหาพีระมิดฟาโรห์ทองคำ)"] = {
            Id = "SongKey_GoldenVault", Effect = "GoldenStarlight",
            Accent = "#291F09", Background = "#120D04", Dialog = "#1C1506", Outline = "#F59E0B",
            Text = "#FEFCE8", Placeholder = "#FDE047", Button = "#47350F", Icon = "#FBBF24",
            Toggle = "#D97706", Slider = "#F59E0B", SliderIcon = "#FEF08A", Checkbox = "#D97706",
            Primary = "#F59E0B", ElementBackground = "#2E230A", PanelBackground = "#1F1707", LabelBackground = "#0A0802",
            Grad1 = Color3.fromHex("#120D03"), Grad2 = Color3.fromHex("#2E2208"), Grad3 = Color3.fromHex("#1F1408"),
            Orb1 = Color3.fromHex("#F59E0B"), Orb2 = Color3.fromHex("#CA8A04"), Orb3 = Color3.fromHex("#FDE047"),
            Particle1 = Color3.fromHex("#FDE047"), Particle2 = Color3.fromHex("#F59E0B"), RuneColor = Color3.fromHex("#FBBF24"),
        },
        ["🌸 Cursed Sakura Shrine (ศาลเจ้าซากุระต้องสาป)"] = {
            Id = "SongKey_CursedSakura", Effect = "SakuraPetals",
            Accent = "#2B0F24", Background = "#120610", Dialog = "#1F0A1A", Outline = "#EC4899",
            Text = "#FDF2F8", Placeholder = "#F9A8D4", Button = "#4D1940", Icon = "#F472B6",
            Toggle = "#DB2777", Slider = "#EC4899", SliderIcon = "#FBCFE8", Checkbox = "#DB2777",
            Primary = "#EC4899", ElementBackground = "#301129", PanelBackground = "#210B1C", LabelBackground = "#0A0308",
            Grad1 = Color3.fromHex("#12050F"), Grad2 = Color3.fromHex("#2E0E27"), Grad3 = Color3.fromHex("#1F0924"),
            Orb1 = Color3.fromHex("#EC4899"), Orb2 = Color3.fromHex("#9333EA"), Orb3 = Color3.fromHex("#F9A8D4"),
            Particle1 = Color3.fromHex("#F9A8D4"), Particle2 = Color3.fromHex("#F43F5E"), RuneColor = Color3.fromHex("#F472B6"),
        },
        ["🌑 Classic Dark (สีดำคลาสสิก)"] = {
            Id = "Dark", Effect = "GoldenStarlight",
            Grad1 = Color3.fromHex("#0E0E10"), Grad2 = Color3.fromHex("#18181C"), Grad3 = Color3.fromHex("#121216"),
            Orb1 = Color3.fromHex("#3B82F6"), Orb2 = Color3.fromHex("#6366F1"), Orb3 = Color3.fromHex("#60A5FA"),
            Particle1 = Color3.fromHex("#93C5FD"), Particle2 = Color3.fromHex("#A5B4FC"), RuneColor = Color3.fromHex("#60A5FA"),
        },
    }

    local THEME_NAMES = {
        "🎃 Skull King's Crypt (สุสานราชาโครงกระดูก)",
        "🩸 Blood Moon Abyss (ห้วงเหวจันทร์สีเลือด)",
        "❄️ Soulfrost Catacombs (สุสานน้ำแข็งวิญญาณ)",
        "🔮 Shadow Monarch's Sanctum (วิหารจักรพรรดิเงา)",
        "🐉 Tempest Dragon Shrine (วิหารมังกรวายุคลั่ง)",
        "🌋 Infernal Magma Core (แกนกลางลาวานรก)",
        "🏛️ Pharaoh's Golden Vault (มหาพีระมิดฟาโรห์ทองคำ)",
        "🌸 Cursed Sakura Shrine (ศาลเจ้าซากุระต้องสาป)",
        "🌑 Classic Dark (สีดำคลาสสิก)",
    }

    local STYLE_MAP = {
        ["Auto (ตามธีมดันเจี้ยน)"] = "Auto",
        ["🔥 Soul Embers & Runes (ไฟวิญญาณ & รูนเวท)"] = "Embers",
        ["🩸 Blood Moon Mist (ละอองจันทร์สีเลือด)"] = "BloodMist",
        ["❄️ Soulfrost Blizzard (พายุหิมะน้ำแข็ง)"] = "Snowfall",
        ["🔮 Shadow Monarch Aura (ออร่าจักรพรรดิเงา)"] = "ShadowAura",
        ["🐉 Tempest Wind Stream (สายลมมังกรวายุ)"] = "WindStream",
        ["🌋 Molten Magma Sparks (สะเก็ดลาวานรก)"] = "MagmaSparks",
        ["✨ Celestial Starlight (ละอองดาวทองคำ)"] = "GoldenStarlight",
        ["🌸 Cursed Sakura Petals (กลีบซากุระต้องสาป)"] = "SakuraPetals",
    }

    local STYLE_NAMES = {
        "Auto (ตามธีมดันเจี้ยน)",
        "🔥 Soul Embers & Runes (ไฟวิญญาณ & รูนเวท)",
        "🩸 Blood Moon Mist (ละอองจันทร์สีเลือด)",
        "❄️ Soulfrost Blizzard (พายุหิมะน้ำแข็ง)",
        "🔮 Shadow Monarch Aura (ออร่าจักรพรรดิเงา)",
        "🐉 Tempest Wind Stream (สายลมมังกรวายุ)",
        "🌋 Molten Magma Sparks (สะเก็ดลาวานรก)",
        "✨ Celestial Starlight (ละอองดาวทองคำ)",
        "🌸 Cursed Sakura Petals (กลีบซากุระต้องสาป)",
    }

    for _, preset in pairs(THEME_PRESETS) do
        if preset.Id ~= "Dark" then
            pcall(function()
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
                    ElementBackgroundTransparency = savedGlass / 100,
                    PanelBackground = Color3.fromHex(preset.PanelBackground),
                    PanelBackgroundTransparency = 0.86,
                    LabelBackground = Color3.fromHex(preset.LabelBackground),
                    LabelBackgroundTransparency = 0.75,
                })
            end)
        end
    end

    local mainWinFrame = Window and Window.UIElements and Window.UIElements.Main
    local animCanvas, bgGrad, borderGrad = nil, nil, nil
    local outerRing, innerRing, runeDiamond = nil, nil, nil
    local outerStroke, innerStroke, diamondStroke = nil, nil, nil
    local orbs, particles = {}, {}
    local activePreset = THEME_PRESETS[savedThemeName] or THEME_PRESETS["🎃 Skull King's Crypt (สุสานราชาโครงกระดูก)"]

    if mainWinFrame then
        pcall(function()
            animCanvas = Instance.new("Frame")
            animCanvas.Name = "SongKeyAnimCanvas"
            animCanvas.Size = UDim2.fromScale(1, 1)
            animCanvas.Position = UDim2.fromScale(0, 0)
            animCanvas.BackgroundColor3 = Color3.new(1, 1, 1)
            animCanvas.BackgroundTransparency = 0.08
            animCanvas.BorderSizePixel = 0
            animCanvas.ClipsDescendants = true
            animCanvas.ZIndex = 5
            animCanvas.Visible = (savedAnimEnabled ~= false)
            animCanvas.Parent = mainWinFrame

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 12)
            corner.Parent = animCanvas

            bgGrad = Instance.new("UIGradient")
            bgGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, activePreset.Grad1),
                ColorSequenceKeypoint.new(0.52, activePreset.Grad2),
                ColorSequenceKeypoint.new(1, activePreset.Grad3),
            })
            bgGrad.Rotation = 35
            bgGrad.Parent = animCanvas

            local borderStroke = Instance.new("UIStroke")
            borderStroke.Thickness = 1.8
            borderStroke.Transparency = 0.30
            borderStroke.Color = Color3.new(1, 1, 1)
            borderStroke.Parent = animCanvas

            borderGrad = Instance.new("UIGradient")
            borderGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, activePreset.Orb1),
                ColorSequenceKeypoint.new(0.5, activePreset.Orb2),
                ColorSequenceKeypoint.new(1, activePreset.Orb3),
            })
            borderGrad.Parent = borderStroke

            local orbConfigs = {
                { Pos = UDim2.fromScale(0.20, 0.24), Size = UDim2.fromOffset(240, 240), Col = activePreset.Orb1 },
                { Pos = UDim2.fromScale(0.82, 0.76), Size = UDim2.fromOffset(260, 260), Col = activePreset.Orb2 },
                { Pos = UDim2.fromScale(0.64, 0.28), Size = UDim2.fromOffset(210, 210), Col = activePreset.Orb3 },
            }
            for idx, oc in ipairs(orbConfigs) do
                local orb = Instance.new("Frame")
                orb.AnchorPoint = Vector2.new(0.5, 0.5)
                orb.Position = oc.Pos
                orb.Size = oc.Size
                orb.BackgroundColor3 = oc.Col
                orb.BackgroundTransparency = 0.86
                orb.BorderSizePixel = 0
                orb.ZIndex = 6
                orb.Parent = animCanvas
                local oCorner = Instance.new("UICorner")
                oCorner.CornerRadius = UDim.new(1, 0)
                oCorner.Parent = orb
                local oGrad = Instance.new("UIGradient")
                oGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.15),
                    NumberSequenceKeypoint.new(0.65, 0.55),
                    NumberSequenceKeypoint.new(1, 1),
                })
                oGrad.Parent = orb
                table.insert(orbs, { Frame = orb, BaseX = oc.Pos.X.Scale, BaseY = oc.Pos.Y.Scale, Phase = idx * 2.1 })
            end

            local sealCenter = UDim2.new(0.66, 0, 0.54, 0)
            outerRing = Instance.new("Frame")
            outerRing.AnchorPoint = Vector2.new(0.5, 0.5)
            outerRing.Position = sealCenter
            outerRing.Size = UDim2.fromOffset(220, 220)
            outerRing.BackgroundTransparency = 1
            outerRing.ZIndex = 6
            outerRing.Parent = animCanvas
            local orCorner = Instance.new("UICorner")
            orCorner.CornerRadius = UDim.new(1, 0)
            orCorner.Parent = outerRing
            outerStroke = Instance.new("UIStroke")
            outerStroke.Thickness = 1.5
            outerStroke.Transparency = 0.74
            outerStroke.Color = activePreset.RuneColor
            outerStroke.Parent = outerRing
            local orGrad = Instance.new("UIGradient")
            orGrad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.1),
                NumberSequenceKeypoint.new(0.5, 0.85),
                NumberSequenceKeypoint.new(1, 0.1),
            })
            orGrad.Parent = outerStroke

            innerRing = Instance.new("Frame")
            innerRing.AnchorPoint = Vector2.new(0.5, 0.5)
            innerRing.Position = sealCenter
            innerRing.Size = UDim2.fromOffset(154, 154)
            innerRing.BackgroundTransparency = 1
            innerRing.ZIndex = 6
            innerRing.Parent = animCanvas
            local irCorner = Instance.new("UICorner")
            irCorner.CornerRadius = UDim.new(1, 0)
            irCorner.Parent = innerRing
            innerStroke = Instance.new("UIStroke")
            innerStroke.Thickness = 1.2
            innerStroke.Transparency = 0.76
            innerStroke.Color = activePreset.Orb1
            innerStroke.Parent = innerRing

            runeDiamond = Instance.new("Frame")
            runeDiamond.AnchorPoint = Vector2.new(0.5, 0.5)
            runeDiamond.Position = sealCenter
            runeDiamond.Size = UDim2.fromOffset(108, 108)
            runeDiamond.Rotation = 45
            runeDiamond.BackgroundTransparency = 1
            runeDiamond.ZIndex = 6
            runeDiamond.Parent = animCanvas
            local rdCorner = Instance.new("UICorner")
            rdCorner.CornerRadius = UDim.new(0, 14)
            rdCorner.Parent = runeDiamond
            diamondStroke = Instance.new("UIStroke")
            diamondStroke.Thickness = 1.2
            diamondStroke.Transparency = 0.78
            diamondStroke.Color = activePreset.Particle2
            diamondStroke.Parent = runeDiamond

            for i = 1, 26 do
                local p = Instance.new("Frame")
                p.AnchorPoint = Vector2.new(0.5, 0.5)
                local sz = math.random(4, 8)
                p.Size = UDim2.fromOffset(sz, sz)
                p.Position = UDim2.fromScale(math.random() * 0.96 + 0.02, math.random())
                p.BackgroundColor3 = (i % 2 == 0) and activePreset.Particle1 or activePreset.Particle2
                p.BackgroundTransparency = 0.35 + (math.random() * 0.35)
                p.BorderSizePixel = 0
                p.ZIndex = 7
                p.Parent = animCanvas
                local pCorner = Instance.new("UICorner")
                pCorner.CornerRadius = UDim.new(1, 0)
                pCorner.Parent = p
                local pStroke = Instance.new("UIStroke")
                pStroke.Thickness = 1.1
                pStroke.Transparency = 0.55
                pStroke.Color = (i % 2 == 0) and activePreset.Orb1 or activePreset.Orb2
                pStroke.Parent = p
                table.insert(particles, {
                    Frame = p, Corner = pCorner, Stroke = pStroke,
                    X = math.random() * 0.96 + 0.02, Y = math.random(),
                    Speed = 0.045 + math.random() * 0.085,
                    SwayAmp = 0.015 + math.random() * 0.035,
                    SwayFreq = 1.2 + math.random() * 2.2,
                    Phase = math.random() * 6.28, BaseSize = sz,
                })
            end
        end)
    end

    local function getEffectStyle()
        local mapped = STYLE_MAP[savedStyleName] or "Auto"
        if mapped == "Auto" then
            return (activePreset and activePreset.Effect) or "Embers"
        end
        return mapped
    end

    local function applyKeyGlass()
        if not mainWinFrame then return end
        local alpha = (savedAnimEnabled ~= false) and math.clamp(savedGlass / 100, 0, 0.75) or 0
        pcall(function()
            local bgImg = mainWinFrame:FindFirstChild("Background")
            if bgImg and bgImg:IsA("ImageLabel") then
                bgImg.ImageTransparency = (savedAnimEnabled ~= false) and 0.18 or 0
            end
            for _, d in ipairs(mainWinFrame:GetDescendants()) do
                if d.Name == "GlassBackground" and d:IsA("ImageLabel") then
                    d.ImageTransparency = alpha
                end
            end
        end)
    end

    local function updateKeyParticles()
        local eff = getEffectStyle()
        for i, pt in ipairs(particles) do
            pcall(function()
                pt.Frame.BackgroundColor3 = (i % 2 == 0) and activePreset.Particle1 or activePreset.Particle2
                pt.Stroke.Color = (i % 2 == 0) and activePreset.Orb1 or activePreset.Orb2
                if eff == "WindStream" then
                    pt.Frame.Size = UDim2.fromOffset(pt.BaseSize * 3.2, math.max(2, math.floor(pt.BaseSize * 0.45)))
                    pt.Frame.Rotation = -16
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

    local function saveThemeToUserConfig()
        pcall(function()
            if writefile then
                local existing = {}
                if isfile and isfile(userCfgPath) and readfile then
                    local ok, dec = pcall(function() return HttpService:JSONDecode(readfile(userCfgPath)) end)
                    if ok and type(dec) == "table" then existing = dec end
                end
                existing.UITheme = savedThemeName
                existing.UIBackgroundAnimation = savedAnimEnabled
                existing.UIAnimationStyle = savedStyleName
                existing.UIGlassTransparency = savedGlass
                writefile(userCfgPath, HttpService:JSONEncode(existing))
            end
        end)
    end

    local function applyKeyTheme(themeLabel, notifyUser)
        local preset = THEME_PRESETS[themeLabel] or THEME_PRESETS["🎃 Skull King's Crypt (สุสานราชาโครงกระดูก)"]
        activePreset = preset
        savedThemeName = themeLabel
        pcall(function()
            WindUI:SetTheme(preset.Id)
            if bgGrad then
                bgGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, preset.Grad1),
                    ColorSequenceKeypoint.new(0.52, preset.Grad2),
                    ColorSequenceKeypoint.new(1, preset.Grad3),
                })
            end
            if borderGrad then
                borderGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, preset.Orb1),
                    ColorSequenceKeypoint.new(0.5, preset.Orb2),
                    ColorSequenceKeypoint.new(1, preset.Orb3),
                })
            end
            if orbs[1] then orbs[1].Frame.BackgroundColor3 = preset.Orb1 end
            if orbs[2] then orbs[2].Frame.BackgroundColor3 = preset.Orb2 end
            if orbs[3] then orbs[3].Frame.BackgroundColor3 = preset.Orb3 end
            if outerStroke then outerStroke.Color = preset.RuneColor end
            if innerStroke then innerStroke.Color = preset.Orb1 end
            if diamondStroke then diamondStroke.Color = preset.Particle2 end
            updateKeyParticles()
            applyKeyGlass()
        end)
        saveThemeToUserConfig()
        if notifyUser and WindUI and WindUI.Notify then
            WindUI:Notify({ Title = "🎨 Song Hub Theme", Content = "เปลี่ยนธีมเป็น: " .. tostring(themeLabel), Duration = 2, Icon = "palette" })
        end
    end

    local animClock = 0
    keyAnimConn = RunService.RenderStepped:Connect(function(dt)
        if not animCanvas or not savedAnimEnabled or Window.Closed then return end
        local step = math.min(dt, 0.05)
        animClock = animClock + step
        if bgGrad then bgGrad.Rotation = 35 + math.sin(animClock * 0.45) * 28 end
        if borderGrad then borderGrad.Rotation = (animClock * 42) % 360 end
        for _, ob in ipairs(orbs) do
            ob.Frame.Position = UDim2.fromScale(
                ob.BaseX + math.sin(animClock * 0.55 + ob.Phase) * 0.08,
                ob.BaseY + math.cos(animClock * 0.42 + ob.Phase) * 0.08
            )
            ob.Frame.BackgroundTransparency = 0.86 + math.sin(animClock * 1.3 + ob.Phase) * 0.045
        end
        if outerRing then outerRing.Rotation = (animClock * 14) % 360 end
        if innerRing then innerRing.Rotation = (-animClock * 22) % 360 end
        if runeDiamond then
            runeDiamond.Rotation = (45 + animClock * 9) % 360
            local pulse = 108 + math.sin(animClock * 1.8) * 7
            runeDiamond.Size = UDim2.fromOffset(pulse, pulse)
        end
        local eff = getEffectStyle()
        for _, pt in ipairs(particles) do
            if eff == "Snowfall" then
                pt.Y = pt.Y + step * pt.Speed * 0.85
                pt.X = pt.X + step * 0.025
                if pt.Y > 1.06 then pt.Y = -0.06; pt.X = math.random() * 0.96 + 0.02 end
                if pt.X > 1.04 then pt.X = -0.04 end
                pt.Frame.Position = UDim2.fromScale(pt.X + math.sin(animClock * pt.SwayFreq + pt.Phase) * pt.SwayAmp, pt.Y)
                pt.Frame.BackgroundTransparency = 0.35 + math.sin(animClock * 2.2 + pt.Phase) * 0.22
            elseif eff == "WindStream" then
                pt.X = pt.X + step * pt.Speed * 2.6
                pt.Y = pt.Y - step * pt.Speed * 0.55
                if pt.X > 1.08 or pt.Y < -0.06 then pt.X = -0.08; pt.Y = math.random() * 0.95 + 0.05 end
                pt.Frame.Position = UDim2.fromScale(pt.X, pt.Y + math.sin(animClock * pt.SwayFreq + pt.Phase) * (pt.SwayAmp * 0.5))
                pt.Frame.BackgroundTransparency = 0.42 + math.sin(animClock * 3.0 + pt.Phase) * 0.25
            elseif eff == "SakuraPetals" then
                pt.Y = pt.Y + step * pt.Speed * 0.75
                pt.X = pt.X - step * pt.Speed * 0.45
                if pt.Y > 1.06 or pt.X < -0.06 then pt.Y = -0.06; pt.X = math.random() * 1.1 end
                pt.Frame.Position = UDim2.fromScale(pt.X + math.sin(animClock * pt.SwayFreq + pt.Phase) * pt.SwayAmp, pt.Y)
                pt.Frame.Rotation = (animClock * 65 + pt.Phase * 40) % 360
                pt.Frame.BackgroundTransparency = 0.32 + math.sin(animClock * 2.0 + pt.Phase) * 0.20
            elseif eff == "GoldenStarlight" then
                pt.Y = pt.Y - step * pt.Speed * 0.35
                if pt.Y < -0.05 then pt.Y = 1.05; pt.X = math.random() * 0.96 + 0.02 end
                pt.Frame.Position = UDim2.fromScale(pt.X + math.sin(animClock * 0.8 + pt.Phase) * (pt.SwayAmp * 0.5), pt.Y)
                local twinkle = math.sin(animClock * 3.5 + pt.Phase)
                local s = math.max(3, pt.BaseSize + twinkle * 2.5)
                pt.Frame.Size = UDim2.fromOffset(s, s)
                pt.Frame.BackgroundTransparency = 0.45 - twinkle * 0.30
            else
                local boost = (eff == "MagmaSparks" and 1.45) or (eff == "ShadowAura" and 1.15) or 1.0
                pt.Y = pt.Y - step * pt.Speed * boost
                if pt.Y < -0.06 then pt.Y = 1.06; pt.X = math.random() * 0.96 + 0.02 end
                pt.Frame.Position = UDim2.fromScale(pt.X + math.sin(animClock * pt.SwayFreq + pt.Phase) * pt.SwayAmp, pt.Y)
                pt.Frame.BackgroundTransparency = 0.35 + math.sin(animClock * 2.6 + pt.Phase) * 0.25
            end
        end
    end)

    local TabKey = Window:Tab({ Title = "License Key", Icon = "key" })
    local TabTheme = Window:Tab({ Title = "UI Theme", Icon = "palette" })

    TabKey:Paragraph({
        Title = "👑 Welcome to Song Hub | ยินดีต้อนรับสู่ Song Hub",
        Desc = "🎮 แมพที่ตรวจพบ (Detected Game): " .. gameTitle .. "\n🔑 กรุณาใส่คีย์เพื่อปลดล็อคการใช้งานสคริปต์ (หรือกดรับคีย์ฟรี 24 ชั่วโมงด้านล่าง)\n✨ ผู้เล่นระดับ VIP / Whitelist จะเข้าใช้งานได้อัตโนมัติ",
        Image = "shield-check"
    })

    local inputKey = ""

    local KeyInput = TabKey:Input({
        Title = "Enter Song Hub Key (ใส่คีย์ของคุณที่นี่)",
        Desc = "วางรหัส License Key ของคุณ (เช่น SONG-XXXX-XXXX)",
        Placeholder = "SONG-XXXX-XXXX",
        Callback = function(txt)
            inputKey = (txt or ""):gsub("%s+", "")
        end
    })

    local function handleSuccessfulUnlock(validKey, msg, resultData)
        if keyAnimConn then
            pcall(function() keyAnimConn:Disconnect() end)
            keyAnimConn = nil
        end

        if resultData and resultData.sessionToken then
            startHeartbeatLoop(resultData.sessionToken, validKey)
        end

        -- Save key locally so player never has to type it again!
        pcall(function()
            if not isfolder("UniversalHub") then makefolder("UniversalHub") end
            writefile(KEY_SAVE_PATH, validKey)
        end)

        WindUI:Notify({
            Title = "👑 Song Hub Unlocked! ✨",
            Content = (msg or "ยืนยันคีย์สำเร็จ!") .. "\nกำลังเปิดสคริปต์ " .. gameTitle .. "...",
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
        Title = "🔓 Verify & Unlock Song Hub (ยืนยันคีย์และเปิดโปร)",
        Desc = "ตรวจสอบคีย์กับเซิร์ฟเวอร์และเปิดใช้งาน Song Hub ทันที",
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
                WindUI:Notify({ Title = "⚠️ กรุณาใส่คีย์", Content = "โปรดวางรหัส License Key ในช่องก่อนกดยืนยัน!", Duration = 3, Icon = "alert-circle" })
                return
            end

            WindUI:Notify({ Title = "🔄 กำลังตรวจสอบคีย์...", Content = "กำลังเชื่อมต่อกับเซิร์ฟเวอร์ Song Hub...", Duration = 2, Icon = "loader" })
            local ok, result = sendVerifyRequest(keyToTest)

            if ok then
                handleSuccessfulUnlock(keyToTest, result.message, result)
            else
                WindUI:Notify({
                    Title = "Access Denied ❌",
                    Content = result.message or "คีย์ไม่ถูกต้องหรือหมดอายุแล้ว!",
                    Duration = 4,
                    Icon = "x-circle"
                })
            end
        end
    })

    TabKey:Button({
        Title = "⚡ Auto-Check Claimed Key (เช็คคีย์อัตโนมัติหลังทำด่านเสร็จ)",
        Desc = "หากทำด่านรับคีย์บนเว็บเสร็จแล้ว กดปุ่มนี้เพื่อดึงคีย์และเข้าใช้งานทันทีโดยไม่ต้องก๊อปวาง",
        Icon = "zap",
        Callback = function()
            WindUI:Notify({ Title = "Checking...", Content = "กำลังตรวจเช็คคีย์ของเครื่องคุณจากเซิร์ฟเวอร์...", Duration = 2, Icon = "loader" })
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
                    Content = "ตรวจพบคีย์: " .. cd.key .. "\nกำลังปลดล็อค Song Hub...",
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
                    Content = "ยังไม่พบคีย์ที่รับไว้ กดปุ่มรับคีย์ฟรีด้านล่างเพื่อคัดลอกลิงก์ไปเปิดในเบราว์เซอร์ได้เลย!",
                    Duration = 4,
                    Icon = "clock"
                })
            end
        end
    })

    TabKey:Button({
        Title = "🟣 Get Free Key via LootLabs (รับคีย์ฟรีผ่าน LootLabs)",
        Desc = "คัดลอกลิงก์รับคีย์ฟรี 24 ชั่วโมงผ่าน LootLabs (ทำง่าย รองรับมือถือ)",
        Icon = "layers",
        Callback = function()
            local hwid = getHardwareId()
            local portalUrl = SERVER_HOST .. "/getkey?hwid=" .. HttpService:UrlEncode(hwid) .. "&provider=lootlabs"
            if setclipboard then
                setclipboard(portalUrl)
            end
            WindUI:Notify({
                Title = "LootLabs Link Copied! 📋",
                Content = "คัดลอกลิงก์รับคีย์แล้ว! นำไปวางในเบราว์เซอร์เพื่อรับคีย์ได้เลย:\n" .. portalUrl,
                Duration = 6,
                Icon = "clipboard-check"
            })
        end
    })

    TabKey:Button({
        Title = "🔵 Get Free Key via Linkvertise (รับคีย์ฟรีผ่าน Linkvertise)",
        Desc = "คัดลอกลิงก์รับคีย์ฟรี 24 ชั่วโมงผ่าน Linkvertise",
        Icon = "external-link",
        Callback = function()
            local hwid = getHardwareId()
            local portalUrl = SERVER_HOST .. "/getkey?hwid=" .. HttpService:UrlEncode(hwid) .. "&provider=linkvertise"
            if setclipboard then
                setclipboard(portalUrl)
            end
            WindUI:Notify({
                Title = "Linkvertise Link Copied! 📋",
                Content = "คัดลอกลิงก์รับคีย์แล้ว! นำไปวางในเบราว์เซอร์เพื่อรับคีย์ได้เลย:\n" .. portalUrl,
                Duration = 6,
                Icon = "clipboard-check"
            })
        end
    })

    TabKey:Button({
        Title = "📋 Copy My Hardware ID (คัดลอก HWID ส่งแอดมิน)",
        Desc = "คัดลอกรหัสเครื่อง HWID ของคุณเพื่อส่งให้แอดมินทำ Whitelist ถาวร",
        Icon = "cpu",
        Callback = function()
            local hwid = getHardwareId()
            if setclipboard then
                setclipboard(hwid)
                WindUI:Notify({ Title = "HWID Copied", Content = "คัดลอกรหัส HWID เรียบร้อยแล้ว!", Duration = 3, Icon = "clipboard-check" })
            end
        end
    })

    -- ==================== TAB 2: KEY UI THEME & ANIMATION CUSTOMIZATION ====================
    TabTheme:Section({ Title = "🎨 Song Hub Theme & Background FX", Opened = true })

    TabTheme:Dropdown({
        Title = "Select Dungeon Theme (เลือกธีมสี Song Hub)",
        Desc = "เลือกธีมสีและบรรยากาศพื้นหลัง (จะถูกบันทึกไปใช้ต่อในหน้าสคริปต์หลักด้วยอัตโนมัติ)",
        Values = THEME_NAMES,
        Value = savedThemeName,
        Callback = function(selected)
            applyKeyTheme(selected, true)
        end,
    })

    TabTheme:Toggle({
        Title = "Animated Background Effect (เปิดเอฟเฟกต์เคลื่อนไหวพื้นหลัง)",
        Desc = "แสดงวงเวทรูนดันเจี้ยนและละอองพลังงานเคลื่อนไหวด้านหลังหน้าต่างใส่คีย์",
        Value = savedAnimEnabled ~= false,
        Callback = function(state)
            savedAnimEnabled = state
            if animCanvas then animCanvas.Visible = state end
            applyKeyGlass()
            saveThemeToUserConfig()
        end,
    })

    TabTheme:Dropdown({
        Title = "Background Particle Style (รูปแบบเอฟเฟกต์ละอองพื้นหลัง)",
        Values = STYLE_NAMES,
        Value = savedStyleName,
        Callback = function(selected)
            savedStyleName = selected
            updateKeyParticles()
            saveThemeToUserConfig()
        end,
    })

    task.defer(function()
        task.wait(0.2)
        pcall(function() TabKey:Select() end)
        applyKeyTheme(savedThemeName, false)
    end)
end)
