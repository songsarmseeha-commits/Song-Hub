// ==============================================================================
// Hub Whitelist & Key System - Express API Server
// ==============================================================================

const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const path = require('path');
const fs = require('fs');
const config = require('./config');
const db = require('./database');

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// Root route guarantees index.html is served
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// ==============================================================================
// UNIVERSAL MULTI-GAME HUB LOADER & SCRIPT SERVING ROUTES
// ==============================================================================

// Universal Loadstring script endpoint (Clients execute this single URL)
app.get('/loader.luau', (req, res) => {
    const loaderPath = path.join(__dirname, 'Universal_Loader.luau');
    if (fs.existsSync(loaderPath)) {
        res.setHeader('Content-Type', 'text/plain; charset=utf-8');
        return res.send(fs.readFileSync(loaderPath, 'utf8'));
    }
    return res.status(404).send('-- Universal Loader file not found');
});

// Dynamic Game Script endpoint (Serves Anime Galaxies, Hunting Together, Blue Lock Farm)
app.get('/scripts/:gameName', (req, res) => {
    let name = req.params.gameName.replace(/[^a-zA-Z0-9_\-\.]/g, '');
    if (!name.endsWith('.luau') && !name.endsWith('.lua')) {
        name += '.luau';
    }
    const scriptPath = path.join(__dirname, 'games', name);
    if (fs.existsSync(scriptPath)) {
        res.setHeader('Content-Type', 'text/plain; charset=utf-8');
        return res.send(fs.readFileSync(scriptPath, 'utf8'));
    }
    return res.status(404).send('-- Game script not found for: ' + name);
});

// Simple session token memory store for admin login
const activeAdminTokens = new Set();

// Helper: Extract real client IP
function getClientIp(req) {
    return req.headers['cf-connecting-ip'] ||
           req.headers['x-forwarded-for']?.split(',')[0].trim() ||
           req.socket.remoteAddress || '127.0.0.1';
}

// Helper: Generate secure random key format (e.g. GALAXY-ABCD-1234-EF56)
function generateKey(prefix = 'GALAXY') {
    const p1 = crypto.randomBytes(2).toString('hex').toUpperCase();
    const p2 = crypto.randomBytes(2).toString('hex').toUpperCase();
    const p3 = crypto.randomBytes(2).toString('hex').toUpperCase();
    return `${prefix}-${p1}-${p2}-${p3}`;
}

// Admin Authentication Middleware
function requireAdmin(req, res, next) {
    const authHeader = req.headers['authorization'];
    const customPass = req.headers['x-admin-password'];
    let token = null;

    if (authHeader && authHeader.startsWith('Bearer ')) {
        token = authHeader.substring(7);
    }

    if ((token && activeAdminTokens.has(token)) || customPass === config.ADMIN_PASSWORD) {
        return next();
    }

    return res.status(401).json({ success: false, error: 'Unauthorized: Invalid Admin Credentials' });
}

// ==============================================================================
// 1. CLIENT VERIFICATION ENDPOINTS (ROBLOX SCRIPT INTEGRATION)
// ==============================================================================

// Verify endpoint supports both POST and GET for executor flexibility
async function handleVerify(req, res) {
    const ip = getClientIp(req);
    const body = req.body || {};
    const query = req.query || {};

    const key = (body.key || query.key || '').trim();
    const hwid = (body.hwid || query.hwid || '').trim();
    const userId = body.userId || query.userId || body.robloxUserId || query.robloxUserId;
    const username = (body.username || query.username || '').trim();

    // 1. Direct Whitelist Check (VIP / Owner / Staff bypass)
    if (userId) {
        const whitelistedUser = db.findWhitelistedUser(userId);
        if (whitelistedUser) {
            db.logAccess({
                keyString: null,
                robloxUserId: userId,
                username,
                hwid,
                ipAddress: ip,
                status: 'WHITELIST_BYPASS',
                message: `Direct whitelist authenticated as ${whitelistedUser.role}`
            });

            return res.json({
                success: true,
                whitelisted: true,
                role: whitelistedUser.role,
                keyType: 'VIP Permanent',
                expiresAt: null,
                message: `Welcome back, ${whitelistedUser.role} ${username || userId}!`
            });
        }
    }

    // 2. Validate Key presence
    if (!key) {
        db.logAccess({
            keyString: null,
            robloxUserId: userId,
            username,
            hwid,
            ipAddress: ip,
            status: 'INVALID',
            message: 'Verification request missing key'
        });

        return res.status(400).json({
            success: false,
            code: 'MISSING_KEY',
            message: 'Please enter a valid license key or register your Roblox UserID.'
        });
    }

    // 3. Find Key in Database
    const keyData = db.findKey(key);
    if (!keyData) {
        db.logAccess({
            keyString: key,
            robloxUserId: userId,
            username,
            hwid,
            ipAddress: ip,
            status: 'INVALID',
            message: 'Key does not exist'
        });

        return res.status(403).json({
            success: false,
            code: 'INVALID_KEY',
            message: 'The key provided is invalid or has not been issued.'
        });
    }

    // 4. Check if Key is Revoked/Suspended
    if (keyData.is_active === 0) {
        db.logAccess({
            keyString: key,
            robloxUserId: userId,
            username,
            hwid,
            ipAddress: ip,
            status: 'REVOKED',
            message: 'Key is disabled by administrator'
        });

        return res.status(403).json({
            success: false,
            code: 'KEY_REVOKED',
            message: 'This key has been suspended or revoked by the administrator.'
        });
    }

    // 5. Check if Key is Expired
    const now = Math.floor(Date.now() / 1000);
    if (keyData.expires_at && now > keyData.expires_at) {
        db.logAccess({
            keyString: key,
            robloxUserId: userId,
            username,
            hwid,
            ipAddress: ip,
            status: 'EXPIRED',
            message: 'Key has expired'
        });

        return res.status(403).json({
            success: false,
            code: 'KEY_EXPIRED',
            message: 'Your license key has expired. Please obtain a new key.'
        });
    }

    // 6. HWID Verification and First-Time Activation
    if (!keyData.hwid) {
        // First-time activation: bind key to this HWID
        db.activateKey(keyData.id, hwid, username, keyData.duration_seconds);
        const updated = db.findKey(key);

        db.logAccess({
            keyString: key,
            robloxUserId: userId,
            username,
            hwid,
            ipAddress: ip,
            status: 'SUCCESS',
            message: 'First time activation & HWID bound'
        });

        return res.json({
            success: true,
            whitelisted: false,
            role: 'User',
            keyType: keyData.key_type,
            activatedAt: updated.activated_at,
            expiresAt: updated.expires_at,
            message: 'License key activated and linked to this device successfully!'
        });
    } else {
        // Check HWID Match
        if (hwid && keyData.hwid !== hwid) {
            db.logAccess({
                keyString: key,
                robloxUserId: userId,
                username,
                hwid,
                ipAddress: ip,
                status: 'HWID_MISMATCH',
                message: `HWID mismatch! Key HWID: ${keyData.hwid.substring(0, 8)}... vs Request: ${hwid.substring(0, 8)}...`
            });

            return res.status(403).json({
                success: false,
                code: 'HWID_MISMATCH',
                message: 'This key is already linked to another device (HWID Mismatch). Contact administrator to reset.'
            });
        }

        // Successful return
        db.logAccess({
            keyString: key,
            robloxUserId: userId,
            username,
            hwid,
            ipAddress: ip,
            status: 'SUCCESS',
            message: 'Successful verification'
        });

        return res.json({
            success: true,
            whitelisted: false,
            role: 'User',
            keyType: keyData.key_type,
            activatedAt: keyData.activated_at,
            expiresAt: keyData.expires_at,
            message: 'License verified successfully!'
        });
    }
}

app.post('/api/v1/verify', handleVerify);
app.get('/api/v1/verify', handleVerify);

// ==============================================================================
// 2. ADMIN API ENDPOINTS (DASHBOARD OPERATIONS)
// ==============================================================================

// Admin Login
app.post('/api/v1/admin/login', (req, res) => {
    const { password } = req.body;
    if (password === config.ADMIN_PASSWORD) {
        const token = crypto.randomBytes(32).toString('hex');
        activeAdminTokens.add(token);
        return res.json({ success: true, token, hubName: config.HUB_NAME });
    }
    return res.status(401).json({ success: false, error: 'Incorrect Admin Password' });
});

// Admin Stats
app.get('/api/v1/admin/stats', requireAdmin, (req, res) => {
    const stats = db.getStats();
    res.json({ success: true, stats, hubName: config.HUB_NAME });
});

// Admin Keys List
app.get('/api/v1/admin/keys', requireAdmin, (req, res) => {
    const keys = db.getAllKeys();
    res.json({ success: true, keys });
});

// Admin Generate Keys (Supports 1 or multiple keys)
app.post('/api/v1/admin/keys/generate', requireAdmin, (req, res) => {
    const {
        count = 1,
        type = '24h',
        prefix = 'GALAXY',
        note = ''
    } = req.body;

    const durationMap = {
        '24h': 86400,
        '3d': 259200,
        '7d': 604800,
        '30d': 2592000,
        'Lifetime': 0
    };

    const durationSeconds = durationMap[type] !== undefined ? durationMap[type] : 86400;
    const generated = [];

    const numToCreate = Math.min(Math.max(parseInt(count) || 1, 1), 100);

    for (let i = 0; i < numToCreate; i++) {
        const keyStr = generateKey(prefix.toUpperCase().trim() || 'GALAXY');
        const record = db.createKey({
            keyString: keyStr,
            keyType: type,
            durationSeconds,
            note
        });
        generated.push(record);
    }

    res.json({ success: true, createdCount: generated.length, keys: generated });
});

// Admin Reset HWID for a Key
app.post('/api/v1/admin/keys/reset-hwid', requireAdmin, (req, res) => {
    const { id } = req.body;
    if (!id) return res.status(400).json({ success: false, error: 'Missing key id' });
    db.resetKeyHwid(id);
    res.json({ success: true, message: 'HWID successfully reset!' });
});

// Admin Toggle Key Active/Suspended
app.post('/api/v1/admin/keys/toggle', requireAdmin, (req, res) => {
    const { id, isActive } = req.body;
    if (id === undefined) return res.status(400).json({ success: false, error: 'Missing key id' });
    db.toggleKeyStatus(id, isActive);
    res.json({ success: true, message: `Key status set to ${isActive ? 'Active' : 'Suspended'}` });
});

// Admin Delete Key
app.delete('/api/v1/admin/keys/:id', requireAdmin, (req, res) => {
    const id = req.params.id;
    db.deleteKey(id);
    res.json({ success: true, message: 'Key deleted successfully' });
});

// Admin Whitelist List
app.get('/api/v1/admin/whitelist', requireAdmin, (req, res) => {
    const users = db.getAllWhitelistedUsers();
    res.json({ success: true, users });
});

// Admin Add Whitelist User
app.post('/api/v1/admin/whitelist/add', requireAdmin, (req, res) => {
    const { robloxUserId, username, role, note } = req.body;
    if (!robloxUserId) return res.status(400).json({ success: false, error: 'Roblox UserID is required' });

    db.addWhitelistedUser({
        robloxUserId: String(robloxUserId).trim(),
        username: (username || '').trim(),
        role: role || 'VIP',
        note: note || ''
    });

    res.json({ success: true, message: 'User added to whitelist successfully!' });
});

// Admin Remove Whitelist User
app.delete('/api/v1/admin/whitelist/:id', requireAdmin, (req, res) => {
    const id = req.params.id;
    db.removeWhitelistedUser(id);
    res.json({ success: true, message: 'User removed from whitelist' });
});

// Admin Access Logs
app.get('/api/v1/admin/logs', requireAdmin, (req, res) => {
    const limit = parseInt(req.query.limit) || 100;
    const logs = db.getRecentLogs(limit);
    res.json({ success: true, logs });
});

// ==============================================================================
// 3. FREE "GET KEY" MONETIZATION SYSTEM (LINKVERTISE & LOOTLABS)
// ==============================================================================

// Helper: Determine server public base URL
function getPublicHost(req) {
    if (config.PUBLIC_URL && !config.PUBLIC_URL.includes('localhost')) {
        return config.PUBLIC_URL.replace(/\/$/, '');
    }
    const proto = req.headers['x-forwarded-proto'] || req.protocol || 'http';
    const host = req.get('host') || `localhost:${config.PORT}`;
    return `${proto}://${host}`;
}

// Helper: Generate Linkvertise dynamic link with Base64 destination
function generateLinkvertiseUrl(destinationUrl, userId) {
    const pubId = userId || db.getSetting('linkvertise_user_id', config.GETKEY.LINKVERTISE_USER_ID);
    const targetBase64 = Buffer.from(encodeURI(destinationUrl)).toString('base64');
    const randomSlug = Math.floor(Math.random() * 90000) + 10000;
    return `https://link-to.net/${pubId}/${randomSlug}/dynamic/?r=${targetBase64}`;
}

// Helper: Generate LootLabs content locker via API
async function generateLootlabsUrl(destinationUrl, title = 'Song Hub Key Checkpoint') {
    const apiKey = db.getSetting('lootlabs_api_key', config.GETKEY.LOOTLABS_API_KEY);
    const tierId = Number(db.getSetting('lootlabs_tier_id', config.GETKEY.LOOTLABS_TIER_ID || 1));
    const tasks = Number(db.getSetting('lootlabs_number_of_tasks', config.GETKEY.LOOTLABS_NUMBER_OF_TASKS || 2));

    try {
        const response = await fetch('https://creators.lootlabs.gg/api/public/content_locker', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                title: String(title).slice(0, 30),
                url: destinationUrl,
                tier_id: tierId,
                number_of_tasks: tasks,
                theme: 1
            })
        });

        const data = await response.json();
        if (data && data.message && Array.isArray(data.message) && data.message[0] && data.message[0].loot_url) {
            return data.message[0].loot_url;
        }
        if (data && data.loot_url) {
            return data.loot_url;
        }
        console.warn('[LootLabs Warning] Response did not contain loot_url:', data);
        return destinationUrl;
    } catch (err) {
        console.error('[LootLabs API Error]:', err.message);
        return destinationUrl;
    }
}

// Serve Get Key Page
app.get('/getkey', (req, res) => {
    const p = path.resolve(__dirname, 'public', 'getkey.html');
    if (fs.existsSync(p)) {
        res.setHeader('Content-Type', 'text/html; charset=utf-8');
        return res.send(fs.readFileSync(p, 'utf8'));
    }
    return res.status(404).send('getkey.html not found');
});

// Initialize or resume Get Key session
app.get('/api/v1/getkey/init', (req, res) => {
    const hwid = (req.query.hwid || '').trim();
    const sessionIdParam = (req.query.session || '').trim();

    // 1. If HWID provided, check if user already has an active, valid key!
    if (hwid) {
        const activeKey = db.findActiveClaimedKeyByHwid(hwid);
        if (activeKey) {
            return res.json({
                success: true,
                isCompleted: true,
                claimedKey: activeKey.key_string,
                expiresAt: activeKey.expires_at,
                alreadyActive: true,
                message: 'You already have an active 24-hour key!'
            });
        }
    }

    // 2. Resume existing session if provided
    if (sessionIdParam) {
        const existingSession = db.findGetKeySession(sessionIdParam);
        const now = Math.floor(Date.now() / 1000);
        if (existingSession && existingSession.expires_at > now) {
            return res.json({
                success: true,
                sessionId: existingSession.session_id,
                currentStep: existingSession.current_step,
                totalSteps: existingSession.total_steps,
                provider: existingSession.provider,
                isCompleted: existingSession.is_completed === 1,
                claimedKey: existingSession.claimed_key
            });
        }
    }

    // 3. Create fresh session
    const sessionId = crypto.randomBytes(16).toString('hex');
    const totalSteps = parseInt(db.getSetting('getkey_steps', config.GETKEY.TOTAL_STEPS)) || 2;
    const provider = db.getSetting('getkey_mode', config.GETKEY.MODE) || 'dual';

    const session = db.createGetKeySession({
        sessionId,
        hwid: hwid || null,
        ipAddress: getClientIp(req),
        totalSteps,
        provider,
        durationMinutes: 45
    });

    res.json({
        success: true,
        sessionId: session.session_id,
        currentStep: session.current_step,
        totalSteps: session.total_steps,
        provider: session.provider,
        isCompleted: false,
        claimedKey: null
    });
});

// Generate Shortlink for current checkpoint step
app.get('/api/v1/getkey/link', async (req, res) => {
    const sessionId = (req.query.sessionId || '').trim();

    if (!sessionId) {
        return res.status(400).json({ success: false, error: 'Missing session ID' });
    }

    const session = db.findGetKeySession(sessionId);
    if (!session) {
        return res.status(404).json({ success: false, error: 'Session not found' });
    }

    const step = parseInt(req.query.step) || session.current_step || 1;

    const now = Math.floor(Date.now() / 1000);
    if (session.expires_at <= now) {
        return res.status(400).json({ success: false, error: 'Session expired. Please restart.' });
    }

    const host = getPublicHost(req);
    // Security HMAC signature to prevent bypass
    const sig = crypto.createHmac('sha256', config.API_SECRET_KEY).update(`${sessionId}_${step}`).digest('hex');
    const destinationUrl = `${host}/api/v1/getkey/callback?session=${sessionId}&step=${step}&sig=${sig}`;

    let redirectUrl = destinationUrl;
    const provider = session.provider;

    if (provider === 'lootlabs') {
        redirectUrl = await generateLootlabsUrl(destinationUrl, `Song Hub Key Step ${step}`);
    } else if (provider === 'linkvertise') {
        redirectUrl = generateLinkvertiseUrl(destinationUrl);
    } else {
        // Dual Provider Mode:
        // Step 1: LootLabs
        // Step 2: Linkvertise
        if (step === 1) {
            redirectUrl = await generateLootlabsUrl(destinationUrl, `Song Hub Key Step 1`);
        } else {
            redirectUrl = generateLinkvertiseUrl(destinationUrl);
        }
    }

    res.json({
        success: true,
        redirectUrl,
        step,
        provider
    });
});

// Checkpoint callback route (redirected here upon completing sponsor task)
app.get('/api/v1/getkey/callback', (req, res) => {
    const sessionId = (req.query.session || '').trim();
    const step = parseInt(req.query.step) || 1;
    const sig = (req.query.sig || '').trim();

    // Verify HMAC signature
    const expectedSig = crypto.createHmac('sha256', config.API_SECRET_KEY).update(`${sessionId}_${step}`).digest('hex');
    if (sig !== expectedSig) {
        return res.redirect(`/getkey?session=${sessionId}&error=invalid_signature`);
    }

    const session = db.findGetKeySession(sessionId);
    if (!session) {
        return res.redirect('/getkey?error=session_not_found');
    }

    const now = Math.floor(Date.now() / 1000);
    if (session.expires_at <= now) {
        return res.redirect('/getkey?error=session_expired');
    }

    // If more steps remain, advance step and return to Get Key page
    if (step < session.total_steps) {
        db.advanceSessionStep(sessionId, step + 1);
        return res.redirect(`/getkey?session=${sessionId}&stepSuccess=1`);
    }

    // All steps complete! Issue 24h key!
    const keyString = generateKey('GALAXY');
    const durationHours = parseInt(db.getSetting('getkey_duration_hours', config.GETKEY.KEY_DURATION_HOURS)) || 24;
    const durationSeconds = durationHours * 3600;

    const newKey = db.createKey({
        keyString,
        keyType: `${durationHours}h`,
        durationSeconds,
        note: `Free Key via GetKey (${session.provider} - Steps: ${session.total_steps})`
    });

    if (session.hwid) {
        db.activateKey(newKey.id, session.hwid, 'Free_User', durationSeconds);
    }

    db.completeSessionWithKey(sessionId, keyString);

    db.logAccess({
        keyString,
        robloxUserId: null,
        username: 'Free_Claimer',
        hwid: session.hwid,
        ipAddress: getClientIp(req),
        status: 'KEY_CLAIMED',
        message: `Successfully completed ${session.total_steps} GetKey checkpoints`
    });

    return res.redirect(`/getkey?session=${sessionId}&claimed=1`);
});

// Roblox Executor polling endpoint: check if a key was claimed for this HWID
app.get('/api/v1/getkey/check', (req, res) => {
    const hwid = (req.query.hwid || '').trim();
    if (!hwid) {
        return res.json({ success: true, hasKey: false, message: 'Missing HWID' });
    }

    const activeKey = db.findActiveClaimedKeyByHwid(hwid);
    if (activeKey) {
        return res.json({
            success: true,
            hasKey: true,
            key: activeKey.key_string,
            expiresAt: activeKey.expires_at,
            keyType: activeKey.key_type
        });
    }

    return res.json({ success: true, hasKey: false });
});

// Admin GetKey Settings API
app.get('/api/v1/admin/getkey/settings', requireAdmin, (req, res) => {
    const settings = {
        enabled: db.getSetting('getkey_enabled', config.GETKEY.ENABLED ? '1' : '0') === '1',
        mode: db.getSetting('getkey_mode', config.GETKEY.MODE),
        steps: parseInt(db.getSetting('getkey_steps', config.GETKEY.TOTAL_STEPS)) || 2,
        durationHours: parseInt(db.getSetting('getkey_duration_hours', config.GETKEY.KEY_DURATION_HOURS)) || 24,
        linkvertiseUserId: db.getSetting('linkvertise_user_id', config.GETKEY.LINKVERTISE_USER_ID),
        lootlabsApiKey: db.getSetting('lootlabs_api_key', config.GETKEY.LOOTLABS_API_KEY),
        lootlabsTierId: parseInt(db.getSetting('lootlabs_tier_id', config.GETKEY.LOOTLABS_TIER_ID)) || 1,
        lootlabsTasks: parseInt(db.getSetting('lootlabs_number_of_tasks', config.GETKEY.LOOTLABS_NUMBER_OF_TASKS)) || 2
    };
    res.json({ success: true, settings });
});

// Admin Update GetKey Settings API
app.post('/api/v1/admin/getkey/settings', requireAdmin, (req, res) => {
    const {
        enabled,
        mode,
        steps,
        durationHours,
        linkvertiseUserId,
        lootlabsApiKey,
        lootlabsTierId,
        lootlabsTasks
    } = req.body;

    if (enabled !== undefined) db.setSetting('getkey_enabled', enabled ? '1' : '0');
    if (mode) db.setSetting('getkey_mode', mode);
    if (steps) db.setSetting('getkey_steps', String(steps));
    if (durationHours) db.setSetting('getkey_duration_hours', String(durationHours));
    if (linkvertiseUserId) db.setSetting('linkvertise_user_id', String(linkvertiseUserId).trim());
    if (lootlabsApiKey) db.setSetting('lootlabs_api_key', String(lootlabsApiKey).trim());
    if (lootlabsTierId) db.setSetting('lootlabs_tier_id', String(lootlabsTierId));
    if (lootlabsTasks) db.setSetting('lootlabs_number_of_tasks', String(lootlabsTasks));

    res.json({ success: true, message: 'GetKey & Monetization settings updated successfully!' });
});

// Admin GetKey Sessions List API
app.get('/api/v1/admin/getkey/sessions', requireAdmin, (req, res) => {
    const limit = parseInt(req.query.limit) || 50;
    const sessions = db.getRecentGetKeySessions(limit);
    res.json({ success: true, sessions });
});

// ==============================================================================
// 4. START SERVER
// ==============================================================================

app.listen(config.PORT, () => {
    console.log(`========================================================`);
    console.log(`✨ ${config.HUB_NAME} - Whitelist & Key System Server`);
    console.log(`🚀 Server running on: http://localhost:${config.PORT}`);
    console.log(`🔐 Admin Panel: http://localhost:${config.PORT}/index.html`);
    console.log(`🔑 Default Admin Password: "${config.ADMIN_PASSWORD}"`);
    console.log(`========================================================`);
});
