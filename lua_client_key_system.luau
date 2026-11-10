-- ==============================================================================
-- 🚀 Song Hub | Client-Side Whitelist & Key System Authentication Module
-- ==============================================================================
-- Fast Edge Authentication powered by Cloudflare Workers (0-5ms latency, 100% Free)
-- Add this snippet at the top of Universal_Loader.luau or any game script.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ⚙️ CONFIGURATION
-- Paste your Cloudflare Worker URL here (e.g. "https://song-hub-whitelist.yourname.workers.dev")
local CLOUDFLARE_URL = "https://song-hub-whitelist.yourname.workers.dev" -- <-- วาง URL ของ Cloudflare Worker ที่นี่
local SERVER_VERIFY_URL = CLOUDFLARE_URL .. "/api/verify-key"
local GET_KEY_PORTAL_URL = CLOUDFLARE_URL .. "/getkey"
local DISCORD_INVITE_URL = "https://discord.gg/your-discord-here"
local KEY_SAVE_PATH = "SongHub/saved_license_key.txt"

-- Safe HWID Fingerprinting function
local function getHardwareId()
    if gethwid then return gethwid() end
    if get_hwid then return get_hwid() end
    if identifyexecutor then
        local exec = identifyexecutor()
        return exec .. "_" .. tostring(LocalPlayer.UserId)
    end
    return "DEVICE_" .. tostring(LocalPlayer.UserId)
end

-- HTTP POST/GET Request Helper
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

    if not success or not response then
        return false, { message = "Could not connect to Whitelist Server! Check your connection or Worker URL." }
    end

    local data = nil
    pcall(function()
        data = HttpService:JSONDecode(response.Body)
    end)

    if not data then
        return false, { message = "Server returned invalid response." }
    end

    return data.success == true, data
end

-- ==============================================================================
-- AUTHENTICATION PIPELINE
-- ==============================================================================

local function authenticateUser(callbackOnSuccess)
    -- Step 1: Check Direct Roblox UserID Whitelist (VIP/Owner auto-bypass)
    local wlOk, wlData = sendVerifyRequest("")
    if wlOk and wlData.whitelisted then
        print(string.format("[Song Hub] ✅ Direct Whitelist passed! Welcome %s (%s)", LocalPlayer.Name, wlData.role or "VIP/Owner"))
        if callbackOnSuccess then callbackOnSuccess(wlData) end
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
                if callbackOnSuccess then callbackOnSuccess(keyData) end
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
        Desc = "Paste your license key here (e.g. GALAXY-XXXX or FREE-XXXX)",
        Placeholder = "GALAXY-XXXX-XXXX-XXXX",
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
                -- Save key locally so user doesn't need to re-enter
                if writefile then
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

                -- Execute main Hub script!
                if callbackOnSuccess then
                    callbackOnSuccess(result)
                end
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
end

return {
    authenticate = authenticateUser,
    verifyRequest = sendVerifyRequest,
    getHwid = getHardwareId
}
