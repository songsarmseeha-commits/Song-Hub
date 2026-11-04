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
        resets_count INTEGER DEFAULT 0
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

// Auto-seed default owner whitelist (Jixg_G5)
try {
    const ownerCheck = db.prepare('SELECT COUNT(*) as count FROM whitelisted_users WHERE roblox_user_id = ?').get('5026219314');
    if (ownerCheck && ownerCheck.count === 0) {
        const now = Math.floor(Date.now() / 1000);
        db.prepare('INSERT INTO whitelisted_users (roblox_user_id, username, role, note, created_at) VALUES (?, ?, ?, ?, ?)')
            .run('5026219314', 'Jixg_G5', 'Owner', 'Hub Creator (Auto-Seeded)', now);
    }
} catch (e) {}

// Helper Queries
const Database = {
    // --- KEY OPERATIONS ---
    findKey(keyString) {
        const stmt = db.prepare('SELECT * FROM keys WHERE key_string = ?');
        return stmt.get(keyString);
    },

    createKey({ keyString, keyType, durationSeconds, note }) {
        const now = Math.floor(Date.now() / 1000);
        const stmt = db.prepare(`
            INSERT INTO keys (key_string, key_type, duration_seconds, created_at, note)
            VALUES (?, ?, ?, ?, ?)
        `);
        stmt.run(keyString, keyType, durationSeconds, now, note || '');
        return this.findKey(keyString);
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
        const stmt = db.prepare('DELETE FROM keys WHERE id = ?');
        stmt.run(id);
    },

    getAllKeys() {
        const stmt = db.prepare('SELECT * FROM keys ORDER BY id DESC');
        return stmt.all();
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
        const totalKeys = db.prepare('SELECT COUNT(*) as count FROM keys').get().count;
        const activeKeys = db.prepare('SELECT COUNT(*) as count FROM keys WHERE is_active = 1').get().count;
        const boundKeys = db.prepare('SELECT COUNT(*) as count FROM keys WHERE hwid IS NOT NULL').get().count;
        const totalWhitelist = db.prepare('SELECT COUNT(*) as count FROM whitelisted_users').get().count;
        const totalExecutions = db.prepare("SELECT COUNT(*) as count FROM access_logs WHERE status IN ('SUCCESS', 'WHITELIST_BYPASS')").get().count;
        const totalFreeKeysClaimed = db.prepare("SELECT COUNT(*) as count FROM getkey_sessions WHERE is_completed = 1").get().count;

        return {
            totalKeys,
            activeKeys,
            boundKeys,
            totalWhitelist,
            totalExecutions,
            totalFreeKeysClaimed
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
            SELECT * FROM keys
            WHERE hwid = ? AND is_active = 1 AND (expires_at IS NULL OR expires_at > ?)
            ORDER BY id DESC LIMIT 1
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
    }
};

module.exports = Database;

