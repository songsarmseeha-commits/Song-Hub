// ==============================================================================
// SQLite Database Layer (Using native Node.js 22+ node:sqlite)
// ==============================================================================

const { DatabaseSync } = require('node:sqlite');
const path = require('path');
const config = require('./config');

const dbPath = path.resolve(__dirname, config.DB_PATH);
const db = new DatabaseSync(dbPath);

// Enable WAL mode for high concurrency
db.exec('PRAGMA journal_mode = WAL;');
db.exec('PRAGMA foreign_keys = ON;');

// Initialize Tables
db.exec(`
    CREATE TABLE IF NOT EXISTS keys (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key_string TEXT UNIQUE NOT NULL,
        key_type TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        hwid TEXT DEFAULT NULL,
        claimed_by TEXT DEFAULT NULL,
        created_at INTEGER NOT NULL,
        activated_at INTEGER DEFAULT NULL,
        expires_at INTEGER DEFAULT NULL,
        is_active INTEGER DEFAULT 1,
        note TEXT DEFAULT '',
        max_resets INTEGER DEFAULT 3,
        resets_count INTEGER DEFAULT 0,
        max_hwid INTEGER DEFAULT 1,
        max_sessions INTEGER DEFAULT 1
    );

    CREATE TABLE IF NOT EXISTS key_hwids (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key_id INTEGER NOT NULL,
        hwid TEXT NOT NULL,
        user_id TEXT DEFAULT NULL,
        username TEXT DEFAULT NULL,
        first_used_at INTEGER NOT NULL,
        last_used_at INTEGER NOT NULL,
        UNIQUE(key_id, hwid)
    );

    CREATE TABLE IF NOT EXISTS key_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key_id INTEGER NOT NULL,
        session_token TEXT UNIQUE NOT NULL,
        hwid TEXT NOT NULL,
        roblox_user_id TEXT DEFAULT NULL,
        username TEXT DEFAULT NULL,
        job_id TEXT DEFAULT NULL,
        place_id TEXT DEFAULT NULL,
        ip_address TEXT DEFAULT NULL,
        last_heartbeat INTEGER NOT NULL,
        created_at INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS whitelisted_users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        roblox_user_id TEXT UNIQUE NOT NULL,
        username TEXT DEFAULT '',
        role TEXT DEFAULT 'VIP',
        note TEXT DEFAULT '',
        created_at INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS access_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key_string TEXT DEFAULT NULL,
        roblox_user_id TEXT DEFAULT NULL,
        username TEXT DEFAULT NULL,
        hwid TEXT DEFAULT NULL,
        ip_address TEXT DEFAULT NULL,
        status TEXT NOT NULL,
        message TEXT DEFAULT '',
        timestamp INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS getkey_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT UNIQUE NOT NULL,
        hwid TEXT DEFAULT NULL,
        ip_address TEXT DEFAULT NULL,
        current_step INTEGER DEFAULT 1,
        total_steps INTEGER DEFAULT 2,
        provider TEXT DEFAULT 'dual',
        is_completed INTEGER DEFAULT 0,
        claimed_key TEXT DEFAULT NULL,
        created_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS system_settings (
        setting_key TEXT PRIMARY KEY,
        setting_value TEXT NOT NULL
    );
`);

// Safe Migrations for existing databases
try {
    db.exec('ALTER TABLE keys ADD COLUMN max_hwid INTEGER DEFAULT 1;');
} catch (e) {}

try {
    db.exec('ALTER TABLE keys ADD COLUMN max_sessions INTEGER DEFAULT 1;');
} catch (e) {}

// Backfill existing keys.hwid into key_hwids
try {
    const keysWithHwid = db.prepare('SELECT id, hwid, claimed_by, activated_at FROM keys WHERE hwid IS NOT NULL AND length(hwid) > 0').all();
    for (const k of keysWithHwid) {
        db.prepare(`
            INSERT OR IGNORE INTO key_hwids (key_id, hwid, username, first_used_at, last_used_at)
            VALUES (?, ?, ?, ?, ?)
        `).run(k.id, k.hwid, k.claimed_by || '', k.activated_at || Math.floor(Date.now() / 1000), Math.floor(Date.now() / 1000));
    }
} catch (e) {}

// Auto-seed default owner whitelist (Jixg_G5)
try {
    const ownerCheck = db.prepare('SELECT COUNT(*) as count FROM whitelisted_users WHERE roblox_user_id = ?').get('5026219314');
    if (ownerCheck && ownerCheck.count === 0) {
        const now = Math.floor(Date.now() / 1000);
        db.prepare('INSERT INTO whitelisted_users (roblox_user_id, username, role, note, created_at) VALUES (?, ?, ?, ?, ?)')
            .run('5026219314', 'Jixg_G5', 'Owner', 'Hub Creator (Auto-Seeded)', now);
    }
} catch (e) {}

// Database Operations
const Database = {
    // --- KEY OPERATIONS ---
    findKey(keyString) {
        const stmt = db.prepare('SELECT * FROM keys WHERE key_string = ?');
        return stmt.get(keyString);
    },

    findKeyById(id) {
        const stmt = db.prepare('SELECT * FROM keys WHERE id = ?');
        return stmt.get(id);
    },

    createKey({ keyString, keyType, durationSeconds, note, maxHwid = 1, maxSessions = 1 }) {
        const now = Math.floor(Date.now() / 1000);
        const parsedMaxHwid = Math.max(parseInt(maxHwid) || 1, 1);
        const parsedMaxSessions = Math.max(parseInt(maxSessions) || 1, 1);
        const stmt = db.prepare(`
            INSERT INTO keys (key_string, key_type, duration_seconds, created_at, note, max_hwid, max_sessions)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        `);
        stmt.run(keyString, keyType, durationSeconds, now, note || '', parsedMaxHwid, parsedMaxSessions);
        return this.findKey(keyString);
    },

    updateKey(id, { maxHwid, maxSessions, note, isActive, keyType }) {
        const current = this.findKeyById(id);
        if (!current) return null;

        const newMaxHwid = maxHwid !== undefined ? Math.max(parseInt(maxHwid) || 1, 1) : current.max_hwid;
        const newMaxSessions = maxSessions !== undefined ? Math.max(parseInt(maxSessions) || 1, 1) : current.max_sessions;
        const newNote = note !== undefined ? String(note) : current.note;
        const newActive = isActive !== undefined ? (isActive ? 1 : 0) : current.is_active;
        const newKeyType = keyType !== undefined ? String(keyType) : current.key_type;

        const stmt = db.prepare(`
            UPDATE keys
            SET max_hwid = ?, max_sessions = ?, note = ?, is_active = ?, key_type = ?
            WHERE id = ?
        `);
        stmt.run(newMaxHwid, newMaxSessions, newNote, newActive, newKeyType, id);
        return this.findKeyById(id);
    },

    activateKey(id, hwid, username, durationSeconds) {
        const now = Math.floor(Date.now() / 1000);
        let expiresAt = null;
        if (durationSeconds > 0) {
            expiresAt = now + durationSeconds;
        }
        const stmt = db.prepare(`
            UPDATE keys
            SET hwid = ?, claimed_by = ?, activated_at = ?, expires_at = ?
            WHERE id = ?
        `);
        stmt.run(hwid, username || '', now, expiresAt, id);
    },

    resetKeyHwid(id) {
        // Clear all bound HWIDs in key_hwids
        db.prepare('DELETE FROM key_hwids WHERE key_id = ?').run(id);

        const stmt = db.prepare(`
            UPDATE keys
            SET hwid = NULL, resets_count = resets_count + 1
            WHERE id = ?
        `);
        stmt.run(id);
    },

    toggleKeyStatus(id, isActive) {
        const stmt = db.prepare('UPDATE keys SET is_active = ? WHERE id = ?');
        stmt.run(isActive ? 1 : 0, id);
    },

    deleteKey(id) {
        db.prepare('DELETE FROM key_hwids WHERE key_id = ?').run(id);
        db.prepare('DELETE FROM key_sessions WHERE key_id = ?').run(id);
        const stmt = db.prepare('DELETE FROM keys WHERE id = ?');
        stmt.run(id);
    },

    getAllKeys() {
        const now = Math.floor(Date.now() / 1000);
        const activeThreshold = now - 75;
        const stmt = db.prepare(`
            SELECT k.*,
                   (SELECT COUNT(*) FROM key_hwids kh WHERE kh.key_id = k.id) as bound_hwids_count,
                   (SELECT COUNT(*) FROM key_sessions ks WHERE ks.key_id = k.id AND ks.last_heartbeat >= ?) as active_sessions_count
            FROM keys k
            ORDER BY k.id DESC
        `);
        return stmt.all(activeThreshold);
    },

    // --- HWID MANAGEMENT OPERATIONS ---
    getKeyHwids(keyId) {
        const stmt = db.prepare('SELECT * FROM key_hwids WHERE key_id = ? ORDER BY id ASC');
        return stmt.all(keyId);
    },

    countKeyHwids(keyId) {
        const stmt = db.prepare('SELECT COUNT(*) as count FROM key_hwids WHERE key_id = ?');
        return stmt.get(keyId).count;
    },

    isHwidBound(keyId, hwid) {
        if (!hwid) return false;
        const stmt = db.prepare('SELECT id FROM key_hwids WHERE key_id = ? AND hwid = ?');
        return !!stmt.get(keyId, hwid);
    },

    addKeyHwid(keyId, hwid, userId = null, username = null) {
        const now = Math.floor(Date.now() / 1000);
        const stmt = db.prepare(`
            INSERT INTO key_hwids (key_id, hwid, user_id, username, first_used_at, last_used_at)
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(key_id, hwid) DO UPDATE SET
                last_used_at = excluded.last_used_at,
                username = COALESCE(excluded.username, key_hwids.username),
                user_id = COALESCE(excluded.user_id, key_hwids.user_id)
        `);
        stmt.run(keyId, hwid, userId ? String(userId) : null, username || null, now, now);

        // Keep keys.hwid updated with the latest HWID
        db.prepare('UPDATE keys SET hwid = ? WHERE id = ?').run(hwid, keyId);
    },

    touchKeyHwid(keyId, hwid, username = null) {
        const now = Math.floor(Date.now() / 1000);
        db.prepare(`
            UPDATE key_hwids
            SET last_used_at = ?, username = COALESCE(?, username)
            WHERE key_id = ? AND hwid = ?
        `).run(now, username, keyId, hwid);
    },

    removeKeyHwid(keyId, hwid) {
        db.prepare('DELETE FROM key_hwids WHERE key_id = ? AND hwid = ?').run(keyId, hwid);
        // Refresh keys.hwid to first remaining HWID or NULL
        const remaining = db.prepare('SELECT hwid FROM key_hwids WHERE key_id = ? LIMIT 1').get(keyId);
        db.prepare('UPDATE keys SET hwid = ? WHERE id = ?').run(remaining ? remaining.hwid : null, keyId);
    },

    // --- CONCURRENT SESSION MANAGEMENT ---
    cleanStaleSessions(thresholdSeconds = 120) {
        const cutoff = Math.floor(Date.now() / 1000) - thresholdSeconds;
        db.prepare('DELETE FROM key_sessions WHERE last_heartbeat < ?').run(cutoff);
    },

    getActiveSessions(keyId, thresholdSeconds = 75) {
        this.cleanStaleSessions(120);
        const cutoff = Math.floor(Date.now() / 1000) - thresholdSeconds;
        const stmt = db.prepare(`
            SELECT * FROM key_sessions
            WHERE key_id = ? AND last_heartbeat >= ?
            ORDER BY last_heartbeat DESC
        `);
        return stmt.all(keyId, cutoff);
    },

    findSessionByToken(sessionToken) {
        if (!sessionToken) return null;
        const stmt = db.prepare('SELECT * FROM key_sessions WHERE session_token = ?');
        return stmt.get(sessionToken);
    },

    findSessionByHwidAndJob(keyId, hwid, jobId, thresholdSeconds = 75) {
        if (!keyId || !hwid || !jobId) return null;
        const cutoff = Math.floor(Date.now() / 1000) - thresholdSeconds;
        const stmt = db.prepare(`
            SELECT * FROM key_sessions
            WHERE key_id = ? AND hwid = ? AND job_id = ? AND last_heartbeat >= ?
            LIMIT 1
        `);
        return stmt.get(keyId, hwid, jobId, cutoff);
    },

    registerOrRefreshSession({ keyId, sessionToken, hwid, userId, username, jobId, placeId, ipAddress }) {
        const now = Math.floor(Date.now() / 1000);
        this.cleanStaleSessions(120);

        const stmt = db.prepare(`
            INSERT INTO key_sessions (key_id, session_token, hwid, roblox_user_id, username, job_id, place_id, ip_address, last_heartbeat, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(session_token) DO UPDATE SET
                last_heartbeat = excluded.last_heartbeat,
                ip_address = excluded.ip_address,
                username = COALESCE(excluded.username, key_sessions.username)
        `);
        stmt.run(keyId, sessionToken, hwid, userId ? String(userId) : null, username || null, jobId || null, placeId ? String(placeId) : null, ipAddress || null, now, now);
        return sessionToken;
    },

    updateSessionHeartbeat(sessionToken) {
        if (!sessionToken) return false;
        const now = Math.floor(Date.now() / 1000);
        const stmt = db.prepare('UPDATE key_sessions SET last_heartbeat = ? WHERE session_token = ?');
        stmt.run(now, sessionToken);
        return true;
    },

    closeSession(sessionToken) {
        if (!sessionToken) return;
        db.prepare('DELETE FROM key_sessions WHERE session_token = ?').run(sessionToken);
    },

    kickKeySessions(keyId) {
        db.prepare('DELETE FROM key_sessions WHERE key_id = ?').run(keyId);
    },

    // --- DIRECT WHITELIST OPERATIONS ---
    findWhitelistedUser(userId) {
        const stmt = db.prepare('SELECT * FROM whitelisted_users WHERE roblox_user_id = ?');
        return stmt.get(String(userId));
    },

    addWhitelistedUser({ robloxUserId, username, role, note }) {
        const now = Math.floor(Date.now() / 1000);
        const stmt = db.prepare(`
            INSERT INTO whitelisted_users (roblox_user_id, username, role, note, created_at)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(roblox_user_id) DO UPDATE SET
                username = excluded.username,
                role = excluded.role,
                note = excluded.note
        `);
        stmt.run(String(robloxUserId), username || '', role || 'VIP', note || '', now);
    },

    removeWhitelistedUser(id) {
        const stmt = db.prepare('DELETE FROM whitelisted_users WHERE id = ?');
        stmt.run(id);
    },

    getAllWhitelistedUsers() {
        const stmt = db.prepare('SELECT * FROM whitelisted_users ORDER BY id DESC');
        return stmt.all();
    },

    // --- LOGS & STATS ---
    logAccess({ keyString, robloxUserId, username, hwid, ipAddress, status, message }) {
        const now = Math.floor(Date.now() / 1000);
        const stmt = db.prepare(`
            INSERT INTO access_logs (key_string, roblox_user_id, username, hwid, ip_address, status, message, timestamp)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `);
        stmt.run(
            keyString || null,
            robloxUserId ? String(robloxUserId) : null,
            username || null,
            hwid || null,
            ipAddress || null,
            status,
            message || '',
            now
        );
    },

    getRecentLogs(limit = 100) {
        const stmt = db.prepare('SELECT * FROM access_logs ORDER BY id DESC LIMIT ?');
        return stmt.all(limit);
    },

    getStats() {
        const now = Math.floor(Date.now() / 1000);
        const totalKeys = db.prepare('SELECT COUNT(*) as count FROM keys').get().count;
        const activeKeys = db.prepare('SELECT COUNT(*) as count FROM keys WHERE is_active = 1').get().count;
        const boundKeys = db.prepare('SELECT COUNT(*) as count FROM keys WHERE hwid IS NOT NULL').get().count;
        const totalWhitelist = db.prepare('SELECT COUNT(*) as count FROM whitelisted_users').get().count;
        const totalExecutions = db.prepare("SELECT COUNT(*) as count FROM access_logs WHERE status IN ('SUCCESS', 'WHITELIST_BYPASS')").get().count;
        const totalFreeKeysClaimed = db.prepare("SELECT COUNT(*) as count FROM getkey_sessions WHERE is_completed = 1").get().count;
        const activeSessions = db.prepare('SELECT COUNT(*) as count FROM key_sessions WHERE last_heartbeat >= ?').get(now - 75).count;

        return {
            totalKeys,
            activeKeys,
            boundKeys,
            totalWhitelist,
            totalExecutions,
            totalFreeKeysClaimed,
            activeSessions
        };
    },

    // --- GET KEY CHECKPOINT SESSIONS ---
    createGetKeySession({ sessionId, hwid, ipAddress, totalSteps, provider, durationMinutes = 45 }) {
        const now = Math.floor(Date.now() / 1000);
        const expiresAt = now + (durationMinutes * 60);
        const stmt = db.prepare(`
            INSERT INTO getkey_sessions (session_id, hwid, ip_address, current_step, total_steps, provider, created_at, expires_at)
            VALUES (?, ?, ?, 1, ?, ?, ?, ?)
        `);
        stmt.run(sessionId, hwid || null, ipAddress || null, totalSteps || 2, provider || 'dual', now, expiresAt);
        return this.findGetKeySession(sessionId);
    },

    findGetKeySession(sessionId) {
        const stmt = db.prepare('SELECT * FROM getkey_sessions WHERE session_id = ?');
        return stmt.get(sessionId);
    },

    findActiveClaimedKeyByHwid(hwid) {
        if (!hwid) return null;
        const now = Math.floor(Date.now() / 1000);
        const stmt = db.prepare(`
            SELECT k.* FROM keys k
            JOIN key_hwids kh ON kh.key_id = k.id
            WHERE kh.hwid = ? AND k.is_active = 1 AND (k.expires_at IS NULL OR k.expires_at > ?)
            ORDER BY k.id DESC LIMIT 1
        `);
        return stmt.get(hwid, now);
    },

    advanceSessionStep(sessionId, nextStep) {
        const stmt = db.prepare('UPDATE getkey_sessions SET current_step = ? WHERE session_id = ?');
        stmt.run(nextStep, sessionId);
    },

    updateSessionProvider(sessionId, provider, totalSteps = 1) {
        const stmt = db.prepare('UPDATE getkey_sessions SET provider = ?, total_steps = ?, current_step = 1 WHERE session_id = ?');
        stmt.run(provider, totalSteps, sessionId);
    },

    completeSessionWithKey(sessionId, keyString) {
        const stmt = db.prepare('UPDATE getkey_sessions SET is_completed = 1, claimed_key = ? WHERE session_id = ?');
        stmt.run(keyString, sessionId);
    },

    getRecentGetKeySessions(limit = 50) {
        const stmt = db.prepare('SELECT * FROM getkey_sessions ORDER BY id DESC LIMIT ?');
        return stmt.all(limit);
    },

    // --- SYSTEM SETTINGS ---
    getSetting(key, defaultValue = null) {
        const stmt = db.prepare('SELECT setting_value FROM system_settings WHERE setting_key = ?');
        const row = stmt.get(key);
        return row ? row.setting_value : defaultValue;
    },

    setSetting(key, value) {
        const stmt = db.prepare(`
            INSERT INTO system_settings (setting_key, setting_value)
            VALUES (?, ?)
            ON CONFLICT(setting_key) DO UPDATE SET setting_value = excluded.setting_value
        `);
        stmt.run(key, String(value));
    },

    getAllSettings() {
        const stmt = db.prepare('SELECT * FROM system_settings');
        const rows = stmt.all();
        const settings = {};
        for (const row of rows) {
            settings[row.setting_key] = row.setting_value;
        }
        return settings;
    },

    // --- CLOUD BACKUP & RESTORE DATA ---
    exportData() {
        const keys = db.prepare('SELECT * FROM keys').all();
        const keyHwids = db.prepare('SELECT * FROM key_hwids').all();
        const whitelistedUsers = db.prepare('SELECT * FROM whitelisted_users').all();
        const settings = db.prepare('SELECT * FROM system_settings').all();
        
        return {
            version: 1,
            exported_at: Math.floor(Date.now() / 1000),
            keys: keys.map(k => {
                const hwids = keyHwids.filter(h => h.key_id === k.id);
                return { ...k, bound_hwids: hwids };
            }),
            whitelisted_users: whitelistedUsers,
            system_settings: settings
        };
    },

    importData(data, replace = false) {
        if (!data || typeof data !== 'object') throw new Error('Invalid backup data');
        let importedKeys = 0;
        let importedUsers = 0;

        // Import keys
        if (Array.isArray(data.keys)) {
            for (const k of data.keys) {
                if (!k.key_string) continue;
                const existing = db.prepare('SELECT id FROM keys WHERE key_string = ?').get(k.key_string);
                let keyId = existing ? existing.id : null;

                if (!existing) {
                    const stmt = db.prepare(`
                        INSERT INTO keys (
                            key_string, key_type, duration_seconds, hwid, claimed_by,
                            created_at, activated_at, expires_at, is_active, note,
                            max_resets, resets_count, max_hwid, max_sessions
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    `);
                    const info = stmt.run(
                        k.key_string, k.key_type || 'standard', k.duration_seconds || 86400,
                        k.hwid || null, k.claimed_by || null, k.created_at || Math.floor(Date.now() / 1000),
                        k.activated_at || null, k.expires_at || null, k.is_active !== undefined ? k.is_active : 1,
                        k.note || '', k.max_resets || 3, k.resets_count || 0,
                        k.max_hwid || 1, k.max_sessions || 1
                    );
                    keyId = info.lastInsertRowid;
                    importedKeys++;
                } else if (replace) {
                    db.prepare(`
                        UPDATE keys SET
                            key_type = ?, duration_seconds = ?, hwid = ?, claimed_by = ?,
                            created_at = ?, activated_at = ?, expires_at = ?, is_active = ?,
                            note = ?, max_resets = ?, resets_count = ?, max_hwid = ?, max_sessions = ?
                        WHERE id = ?
                    `).run(
                        k.key_type || 'standard', k.duration_seconds || 86400,
                        k.hwid || null, k.claimed_by || null, k.created_at || Math.floor(Date.now() / 1000),
                        k.activated_at || null, k.expires_at || null, k.is_active !== undefined ? k.is_active : 1,
                        k.note || '', k.max_resets || 3, k.resets_count || 0,
                        k.max_hwid || 1, k.max_sessions || 1, keyId
                    );
                    importedKeys++;
                }

                // Import bound HWIDs
                if (keyId && Array.isArray(k.bound_hwids)) {
                    for (const h of k.bound_hwids) {
                        if (h.hwid) {
                            try {
                                db.prepare(`
                                    INSERT OR REPLACE INTO key_hwids (key_id, hwid, user_id, username, first_used_at, last_used_at)
                                    VALUES (?, ?, ?, ?, ?, ?)
                                `).run(
                                    keyId, h.hwid, h.user_id || null, h.username || null,
                                    h.first_used_at || Math.floor(Date.now() / 1000),
                                    h.last_used_at || Math.floor(Date.now() / 1000)
                                );
                            } catch (e) {}
                        }
                    }
                }
            }
        }

        // Import whitelisted users
        if (Array.isArray(data.whitelisted_users)) {
            for (const u of data.whitelisted_users) {
                if (!u.roblox_user_id) continue;
                try {
                    db.prepare(`
                        INSERT OR REPLACE INTO whitelisted_users (roblox_user_id, username, role, note, created_at)
                        VALUES (?, ?, ?, ?, ?)
                    `).run(
                        String(u.roblox_user_id), u.username || '', u.role || 'VIP',
                        u.note || '', u.created_at || Math.floor(Date.now() / 1000)
                    );
                    importedUsers++;
                } catch (e) {}
            }
        }

        // Import settings
        if (Array.isArray(data.system_settings)) {
            for (const s of data.system_settings) {
                if (s.setting_key && s.setting_value !== undefined) {
                    try {
                        db.prepare(`
                            INSERT OR REPLACE INTO system_settings (setting_key, setting_value)
                            VALUES (?, ?)
                        `).run(s.setting_key, String(s.setting_value));
                    } catch (e) {}
                }
            }
        }

        return { importedKeys, importedUsers };
    }
};

module.exports = Database;
