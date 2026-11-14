import fs from 'fs';
import path from 'path';

const ROOT = 'C:\\Users\\USER\\.gemini\\antigravity\\scratch\\hub-whitelist-system';
const WORKER_DIR = path.join(ROOT, 'cloudflare-worker');
const SRC_DIR = path.join(WORKER_DIR, 'src');

// Read frontend assets
const indexHtml = fs.readFileSync(path.join(ROOT, 'public', 'index.html'), 'utf8');
const getkeyHtml = fs.readFileSync(path.join(ROOT, 'public', 'getkey.html'), 'utf8');
const appJs = fs.readFileSync(path.join(ROOT, 'public', 'app.js'), 'utf8');
const styleCss = fs.readFileSync(path.join(ROOT, 'public', 'style.css'), 'utf8');
const loaderLuau = fs.readFileSync(path.join(ROOT, 'Universal_Loader.luau'), 'utf8');

// Combine app.js and style.css into indexHtml for self-contained single-page serving
let bundledIndexHtml = indexHtml
  .replace('<link rel="stylesheet" href="style.css">', `<style>${styleCss}</style>`)
  .replace('<script src="app.js"></script>', `<script>${appJs}</script>`);

let bundledGetkeyHtml = getkeyHtml
  .replace('<link rel="stylesheet" href="style.css">', `<style>${styleCss}</style>`);

console.log('Bundled HTML sizes:', {
  indexHtml: bundledIndexHtml.length,
  getkeyHtml: bundledGetkeyHtml.length
});

const workerTemplate = `// ==============================================================================
// 🚀 SONG HUB - CLOUDFLARE WORKER (WHITELIST & KEY SYSTEM)
// Fast Edge Deployment • 100% Free • Zero Spin-Down • Enterprise DDoS Defense
// ==============================================================================

const CONFIG = {
    DEFAULT_ADMIN_PASSWORD: "ttt0871457806",
    DEFAULT_API_SECRET: "galaxy_hub_super_secret_salt_2026",
    DEFAULT_HUB_NAME: "Song Hub | Universal Whitelist",
    GETKEY: {
        LINKVERTISE_USER_ID: "9176777",
        LOOTLABS_API_KEY: "8580e9cc7da836b61e43050d86e2ea52465c2bb5d33a873d948df7e73683ab18",
        MODE: "dual", // "dual", "lootlabs", "linkvertise"
        KEY_DURATION_HOURS: 24
    }
};

// Embedded Frontend Assets
const INDEX_HTML = ${JSON.stringify(bundledIndexHtml)};
const GETKEY_HTML = ${JSON.stringify(bundledGetkeyHtml)};
const FALLBACK_LOADER_LUAU = ${JSON.stringify(loaderLuau)};

// Active Admin Tokens Map (Edge In-Memory)
const activeAdminSessions = new Map();

// Crypto Helper: HMAC SHA256
async function hmacSha256(message, secret) {
    const enc = new TextEncoder();
    const key = await crypto.subtle.importKey(
        "raw",
        enc.encode(secret),
        { name: "HMAC", hash: "SHA-256" },
        false,
        ["sign"]
    );
    const signature = await crypto.subtle.sign("HMAC", key, enc.encode(message));
    return Array.from(new Uint8Array(signature)).map(b => b.toString(16).padStart(2, '0')).join('');
}

// Helper: Random Key Generator (GALAXY-XXXX-XXXX-XXXX)
function generateKeyString(prefix = "GALAXY") {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    const segment = () => Array.from({ length: 4 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
    return \`\${prefix}-\${segment()}-\${segment()}-\${segment()}\`;
}

const KEY_DURATION_MAP = {
    "24h": 86400,
    "Free 24h": 86400,
    "3d": 259200,
    "7d": 604800,
    "Weekly": 604800,
    "30d": 2592000,
    "Monthly": 2592000,
    "Lifetime": 0
};

function resolveKeyDurationSeconds(rawType, durationHours) {
    if (durationHours !== undefined && durationHours !== null && !isNaN(durationHours)) {
        return Math.max(0, parseInt(durationHours, 10) * 3600);
    }
    if (rawType && KEY_DURATION_MAP[rawType] !== undefined) {
        return KEY_DURATION_MAP[rawType];
    }
    return undefined;
}

function generateHex(len = 16) {
    const arr = new Uint8Array(len);
    crypto.getRandomValues(arr);
    return Array.from(arr).map(b => b.toString(16).padStart(2, '0')).join('');
}

function normalizeVerifiedKey(raw) {
    const normalized = String(raw || "")
        .replace(/[\\u200B-\\u200D\\uFEFF\\u00A0]/g, "")
        .replace(/[\\u2010-\\u2015\\u2212\\uFE58\\uFE63\\uFF0D]/g, "-")
        .toUpperCase();
    const knownMatch = normalized.match(/(?:FREE|GALAXY|PREMIUM|SONGHUB|VIP)(?:\\s*-\\s*[A-Z0-9]{2,16}){2,4}/);
    if (knownMatch) return knownMatch[0].replace(/\\s+/g, "");
    const genericMatch = normalized.match(/[A-Z0-9]{2,16}(?:-[A-Z0-9]{2,16}){2,4}/);
    if (genericMatch) return genericMatch[0];
    return normalized.replace(/[^A-Z0-9_-]+/g, "").trim();
}

async function createWhitelistToken(userId, secret, nowSec = Math.floor(Date.now() / 1000)) {
    const exp = nowSec + 86400;
    const payload = \`wl.\${String(userId).trim()}.\${exp}\`;
    const sig = await hmacSha256(payload, secret);
    return \`\${payload}.\${sig.slice(0, 32)}\`;
}

async function verifyWhitelistToken(token, secret, nowSec = Math.floor(Date.now() / 1000)) {
    if (typeof token !== "string" || !token.startsWith("wl.")) {
        return { valid: false, reason: "INVALID_TOKEN_FORMAT" };
    }
    const parts = token.split(".");
    if (parts.length !== 4 || parts[0] !== "wl") {
        return { valid: false, reason: "INVALID_TOKEN_FORMAT" };
    }
    const [, userId, expStr, sig] = parts;
    const exp = Number(expStr);
    if (!userId || !Number.isFinite(exp) || exp <= 0) {
        return { valid: false, reason: "INVALID_TOKEN_PAYLOAD" };
    }
    if (nowSec >= exp) {
        return { valid: false, reason: "TOKEN_EXPIRED" };
    }
    const expected = (await hmacSha256(\`wl.\${userId}.\${expStr}\`, secret)).slice(0, 32);
    if (sig.length !== expected.length) {
        return { valid: false, reason: "INVALID_TOKEN_SIG" };
    }
    let diff = 0;
    for (let i = 0; i < expected.length; i++) {
        diff |= expected.charCodeAt(i) ^ sig.charCodeAt(i);
    }
    if (diff !== 0) {
        return { valid: false, reason: "INVALID_TOKEN_SIG" };
    }
    return { valid: true, userId, exp };
}

// Module-level fallback storage for when D1 is not attached yet
const globalFallbackStore = {
    keys: new Map(),
    hwids: new Map(),
    sessions: new Map(),
    whitelist: new Map(),
    logs: [],
    getkeySessions: new Map(),
    settings: new Map()
};

// Database Abstraction (Cloudflare D1 with In-Memory fallback for instant test)
class DatabaseHandler {
    constructor(db) {
        this.db = db;
        this.memoryStore = globalFallbackStore;
    }

    async getSetting(key, defVal = '') {
        if (this.db) {
            try {
                await this.db.prepare("CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)").run();
                const row = await this.db.prepare("SELECT value FROM settings WHERE key = ?").bind(key).first();
                if (row) return row.value;
            } catch (e) {}
        }
        return this.memoryStore.settings.has(key) ? this.memoryStore.settings.get(key) : defVal;
    }

    async setSetting(key, value) {
        if (this.db) {
            try {
                await this.db.prepare("CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)").run();
                await this.db.prepare("INSERT INTO settings (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = ?").bind(key, String(value), String(value)).run();
                return;
            } catch (e) {}
        }
        this.memoryStore.settings.set(key, String(value));
    }

    async findWhitelistedUser(userId) {
        const idStr = String(userId).trim();
        if (this.db) {
            try {
                const res = await this.db.prepare("SELECT * FROM whitelisted_users WHERE roblox_user_id = ?").bind(idStr).first();
                if (res) return res;
            } catch (e) {
                console.error("D1 Whitelist error:", e);
            }
        }
        return this.memoryStore.whitelist.get(idStr) || null;
    }

    async getAllWhitelistedUsers() {
        if (this.db) {
            try {
                const { results } = await this.db.prepare("SELECT * FROM whitelisted_users ORDER BY id DESC").all();
                return results || [];
            } catch (e) {}
        }
        return Array.from(this.memoryStore.whitelist.values()).reverse();
    }

    async addWhitelistedUser(robloxUserId, username, role, note) {
        const now = Math.floor(Date.now() / 1000);
        const idStr = String(robloxUserId).trim();
        if (this.db) {
            try {
                const res = await this.db.prepare(
                    "INSERT INTO whitelisted_users (roblox_user_id, username, role, note, created_at) VALUES (?, ?, ?, ?, ?)"
                ).bind(idStr, username || '', role || 'VIP', note || '', now).run();
                return { id: res.meta?.last_row_id || Date.now(), roblox_user_id: idStr, username, role, note, created_at: now };
            } catch (e) {
                console.error("D1 addWhitelistedUser error:", e);
            }
        }
        const user = {
            id: this.memoryStore.whitelist.size + 1,
            roblox_user_id: idStr,
            username: username || '',
            role: role || 'VIP',
            note: note || '',
            created_at: now
        };
        this.memoryStore.whitelist.set(idStr, user);
        return user;
    }

    async removeWhitelistedUser(id) {
        if (this.db) {
            try {
                await this.db.prepare("DELETE FROM whitelisted_users WHERE id = ? OR roblox_user_id = ?").bind(id, String(id)).run();
                return;
            } catch (e) {}
        }
        for (const [k, v] of this.memoryStore.whitelist.entries()) {
            if (String(v.id) === String(id) || String(v.roblox_user_id) === String(id)) {
                this.memoryStore.whitelist.delete(k);
                break;
            }
        }
    }

    async findKey(keyString) {
        const kStr = String(keyString).trim().toUpperCase();
        if (this.db) {
            try {
                let res = await this.db.prepare("SELECT * FROM keys WHERE key_string = ?").bind(kStr).first();
                if (!res) {
                    res = await this.db.prepare("SELECT * FROM keys WHERE UPPER(TRIM(key_string)) = ?").bind(kStr).first();
                }
                if (res) return res;
            } catch (e) {
                console.error("D1 findKey error:", e);
            }
        }
        return this.memoryStore.keys.get(kStr) || null;
    }

    async ensureSessionTable() {
        if (this.db) {
            try {
                await this.db.prepare(\`
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
                    )
                \`).run();
            } catch (e) {}
        }
    }

    async purgeExpiredAndInactiveSessions(nowSec = Math.floor(Date.now() / 1000), windowSeconds = 90) {
        await this.ensureSessionTable();
        const cutoff = nowSec - windowSeconds;
        if (this.db) {
            try {
                await this.db.prepare(\`
                    DELETE FROM key_sessions
                    WHERE last_heartbeat <= ?
                       OR key_id NOT IN (SELECT id FROM keys)
                       OR key_id IN (
                           SELECT id FROM keys
                           WHERE is_active = 0 OR (expires_at IS NOT NULL AND expires_at > 0 AND expires_at <= ?)
                       )
                \`).bind(cutoff, nowSec).run();
                return;
            } catch (e) {
                console.error("D1 purgeExpiredAndInactiveSessions error:", e);
            }
        }
        const validKeysById = new Map();
        for (const k of this.memoryStore.keys.values()) {
            validKeysById.set(Number(k.id), k);
        }
        for (const [tok, s] of this.memoryStore.sessions.entries()) {
            const k = validKeysById.get(Number(s.key_id));
            if (
                s.last_heartbeat <= cutoff ||
                !k ||
                k.is_active === 0 ||
                (k.expires_at && k.expires_at > 0 && nowSec >= k.expires_at)
            ) {
                this.memoryStore.sessions.delete(tok);
            }
        }
    }

    async getActiveSessions(keyId, windowSeconds = 90) {
        await this.ensureSessionTable();
        const nowSec = Math.floor(Date.now() / 1000);
        const cutoff = nowSec - windowSeconds;
        if (this.db) {
            try {
                const keyRow = await this.db.prepare("SELECT id, is_active, expires_at FROM keys WHERE id = ?").bind(keyId).first();
                if (!keyRow || keyRow.is_active === 0 || (keyRow.expires_at && keyRow.expires_at > 0 && nowSec >= keyRow.expires_at)) {
                    await this.kickKeySessions(keyId);
                    return [];
                }
                await this.db.prepare("DELETE FROM key_sessions WHERE key_id = ? AND last_heartbeat <= ?").bind(keyId, cutoff).run();
                const { results } = await this.db.prepare(
                    "SELECT * FROM key_sessions WHERE key_id = ? AND last_heartbeat > ?"
                ).bind(keyId, cutoff).all();
                return results || [];
            } catch (e) {}
        }
        let memKey = null;
        for (const k of this.memoryStore.keys.values()) {
            if (Number(k.id) === Number(keyId)) { memKey = k; break; }
        }
        if (!memKey || memKey.is_active === 0 || (memKey.expires_at && memKey.expires_at > 0 && nowSec >= memKey.expires_at)) {
            await this.kickKeySessions(keyId);
            return [];
        }
        return Array.from(this.memoryStore.sessions.values()).filter(s => s.key_id === Number(keyId) && s.last_heartbeat > cutoff);
    }

    async verifySessionHeartbeat(sessionToken, touch = true) {
        await this.ensureSessionTable();
        const nowSec = Math.floor(Date.now() / 1000);
        if (!sessionToken) {
            return { active: false, code: "MISSING_SESSION", message: "Missing session token." };
        }
        if (this.db) {
            try {
                const row = await this.db.prepare(\`
                    SELECT ks.*, k.id AS joined_key_id, k.key_string, k.key_type, k.is_active, k.expires_at, k.max_sessions
                    FROM key_sessions ks
                    LEFT JOIN keys k ON k.id = ks.key_id
                    WHERE ks.session_token = ?
                \`).bind(sessionToken).first();
                if (!row) {
                    return { active: false, code: "SESSION_INVALID", message: "Session has ended or was closed by admin." };
                }
                if (!row.joined_key_id) {
                    await this.closeKeySession(sessionToken);
                    return { active: false, code: "KEY_DELETED", message: "Your license key no longer exists." };
                }
                if (row.is_active === 0) {
                    await this.kickKeySessions(row.key_id);
                    return { active: false, code: "KEY_REVOKED", message: "Your license key has been revoked or suspended." };
                }
                if (row.expires_at && row.expires_at > 0 && nowSec >= row.expires_at) {
                    await this.kickKeySessions(row.key_id);
                    return { active: false, code: "KEY_EXPIRED", message: "Your license key has expired.", expiresAt: row.expires_at };
                }
                if (touch) {
                    await this.db.prepare("UPDATE key_sessions SET last_heartbeat = ? WHERE session_token = ?").bind(nowSec, sessionToken).run();
                }
                return {
                    active: true,
                    keyId: row.key_id,
                    keyString: row.key_string,
                    keyType: row.key_type,
                    expiresAt: (row.expires_at && row.expires_at > 0) ? row.expires_at : null
                };
            } catch (e) {
                console.error("D1 verifySessionHeartbeat error:", e);
                return { active: false, code: "DB_ERROR", message: "Session verification failed." };
            }
        }
        const s = this.memoryStore.sessions.get(sessionToken);
        if (!s) {
            return { active: false, code: "SESSION_INVALID", message: "Session has ended or was closed by admin." };
        }
        let foundKey = null;
        for (const k of this.memoryStore.keys.values()) {
            if (Number(k.id) === Number(s.key_id)) {
                foundKey = k;
                break;
            }
        }
        if (!foundKey) {
            this.memoryStore.sessions.delete(sessionToken);
            return { active: false, code: "KEY_DELETED", message: "Your license key no longer exists." };
        }
        if (foundKey.is_active === 0) {
            await this.kickKeySessions(foundKey.id);
            return { active: false, code: "KEY_REVOKED", message: "Your license key has been revoked or suspended." };
        }
        if (foundKey.expires_at && foundKey.expires_at > 0 && nowSec >= foundKey.expires_at) {
            await this.kickKeySessions(foundKey.id);
            return { active: false, code: "KEY_EXPIRED", message: "Your license key has expired.", expiresAt: foundKey.expires_at };
        }
        if (touch) {
            s.last_heartbeat = nowSec;
        }
        return {
            active: true,
            keyId: foundKey.id,
            keyString: foundKey.key_string,
            keyType: foundKey.key_type,
            expiresAt: (foundKey.expires_at && foundKey.expires_at > 0) ? foundKey.expires_at : null
        };
    }

    async createKeySession(keyId, sessionToken, hwid, userId, username, jobId, placeId, ip) {
        await this.ensureSessionTable();
        const now = Math.floor(Date.now() / 1000);
        if (this.db) {
            try {
                await this.db.prepare(
                    "INSERT INTO key_sessions (key_id, session_token, hwid, roblox_user_id, username, job_id, place_id, ip_address, last_heartbeat, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
                ).bind(keyId, sessionToken, hwid || '', String(userId || ''), String(username || ''), jobId || '', placeId || '', ip || '', now, now).run();
                return;
            } catch (e) {
                console.error("D1 createKeySession error:", e);
            }
        }
        this.memoryStore.sessions.set(sessionToken, {
            key_id: Number(keyId), session_token: sessionToken, hwid, roblox_user_id: userId, username, job_id: jobId, place_id: placeId, ip_address: ip, last_heartbeat: now, created_at: now
        });
    }

    async updateSessionHeartbeat(sessionToken) {
        return this.verifySessionHeartbeat(sessionToken, true);
    }

    async closeKeySession(sessionToken, releaseIdleHwid = false) {
        let closedKeyId = null;
        let closedHwid = null;
        if (this.db) {
            try {
                const row = await this.db.prepare("SELECT key_id, hwid FROM key_sessions WHERE session_token = ?").bind(sessionToken).first();
                if (row) {
                    closedKeyId = row.key_id;
                    closedHwid = row.hwid;
                }
                await this.db.prepare("DELETE FROM key_sessions WHERE session_token = ?").bind(sessionToken).run();
                if (releaseIdleHwid && closedKeyId) {
                    const cutoff = Math.floor(Date.now() / 1000) - 90;
                    const rem = await this.db.prepare(
                        "SELECT id, hwid FROM key_sessions WHERE key_id = ? AND last_heartbeat > ?"
                    ).bind(closedKeyId, cutoff).all();
                    const activeList = (rem && rem.results) || [];
                    if (activeList.length === 0) {
                        await this.resetKeyHwid(closedKeyId);
                    } else if (closedHwid && !activeList.some(s => s.hwid === closedHwid)) {
                        await this.removeKeyHwid(closedKeyId, closedHwid);
                    }
                }
                return;
            } catch (e) {}
        }
        const s = this.memoryStore.sessions.get(sessionToken);
        if (s) {
            closedKeyId = s.key_id;
            closedHwid = s.hwid;
        }
        this.memoryStore.sessions.delete(sessionToken);
        if (releaseIdleHwid && closedKeyId) {
            const cutoff = Math.floor(Date.now() / 1000) - 90;
            const activeList = Array.from(this.memoryStore.sessions.values()).filter(
                sess => sess.key_id === Number(closedKeyId) && sess.last_heartbeat > cutoff
            );
            if (activeList.length === 0) {
                await this.resetKeyHwid(closedKeyId);
            } else if (closedHwid && !activeList.some(sess => sess.hwid === closedHwid)) {
                await this.removeKeyHwid(closedKeyId, closedHwid);
            }
        }
    }

    async kickKeySessions(keyId) {
        if (this.db) {
            try {
                await this.db.prepare("DELETE FROM key_sessions WHERE key_id = ?").bind(keyId).run();
                return;
            } catch (e) {}
        }
        for (const [k, v] of this.memoryStore.sessions.entries()) {
            if (v.key_id === Number(keyId)) this.memoryStore.sessions.delete(k);
        }
    }

    async getAllKeys() {
        await this.ensureSessionTable();
        const nowSec = Math.floor(Date.now() / 1000);
        const cutoff = nowSec - 90;
        await this.purgeExpiredAndInactiveSessions(nowSec, 90);
        if (this.db) {
            try {
                const { results } = await this.db.prepare(\`
                    SELECT k.*, 
                           (SELECT COUNT(*) FROM key_hwids kh WHERE kh.key_id = k.id) as bound_hwids_count,
                           (SELECT COUNT(*) FROM key_sessions ks WHERE ks.key_id = k.id AND ks.last_heartbeat > ? AND k.is_active = 1 AND (k.expires_at IS NULL OR k.expires_at = 0 OR k.expires_at > ?)) as active_sessions_count
                    FROM keys k ORDER BY k.id DESC
                \`).bind(cutoff, nowSec).all();
                return results || [];
            } catch (e) {
                console.error("D1 getAllKeys error:", e);
            }
        }
        return Array.from(this.memoryStore.keys.values()).map(k => {
            const bound = Array.from(this.memoryStore.hwids.values()).filter(h => h.key_id === k.id).length;
            const isKeyValid = k.is_active !== 0 && (!k.expires_at || k.expires_at <= 0 || nowSec < k.expires_at);
            const active = isKeyValid
                ? Array.from(this.memoryStore.sessions.values()).filter(s => s.key_id === k.id && s.last_heartbeat > cutoff).length
                : 0;
            return { ...k, bound_hwids_count: bound, active_sessions_count: active };
        }).reverse();
    }

    async getKeyHwids(keyId) {
        if (this.db) {
            try {
                const { results } = await this.db.prepare("SELECT * FROM key_hwids WHERE key_id = ?").bind(keyId).all();
                return results || [];
            } catch (e) {}
        }
        return Array.from(this.memoryStore.hwids.values()).filter(h => h.key_id === Number(keyId));
    }

    async addKeyHwid(keyId, hwid, userId, username) {
        const now = Math.floor(Date.now() / 1000);
        if (this.db) {
            try {
                await this.db.prepare(\`
                    INSERT INTO key_hwids (key_id, hwid, user_id, username, first_used_at, last_used_at)
                    VALUES (?, ?, ?, ?, ?, ?)
                    ON CONFLICT(key_id, hwid) DO UPDATE SET
                        last_used_at = excluded.last_used_at,
                        user_id = CASE WHEN excluded.user_id != '' THEN excluded.user_id ELSE key_hwids.user_id END,
                        username = CASE WHEN excluded.username != '' THEN excluded.username ELSE key_hwids.username END
                \`).bind(keyId, hwid, String(userId || ''), String(username || ''), now, now).run();
                return;
            } catch (e) {}
        }
        const memKey = \`\${keyId}_\${hwid}\`;
        const prev = this.memoryStore.hwids.get(memKey);
        this.memoryStore.hwids.set(memKey, {
            key_id: Number(keyId),
            hwid,
            user_id: userId || (prev ? prev.user_id : ''),
            username: username || (prev ? prev.username : ''),
            first_used_at: prev ? prev.first_used_at : now,
            last_used_at: now
        });
    }

    async activateKey(keyId, durationSeconds) {
        const now = Math.floor(Date.now() / 1000);
        const expiresAt = durationSeconds > 0 ? now + durationSeconds : null;
        if (this.db) {
            try {
                await this.db.prepare("UPDATE keys SET activated_at = ?, expires_at = ? WHERE id = ?").bind(now, expiresAt, keyId).run();
                return { activatedAt: now, expiresAt };
            } catch (e) {}
        }
        for (const [k, v] of this.memoryStore.keys.entries()) {
            if (v.id === Number(keyId)) {
                v.activated_at = now;
                v.expires_at = expiresAt;
                break;
            }
        }
        return { activatedAt: now, expiresAt };
    }

    async insertKey(record) {
        const now = Math.floor(Date.now() / 1000);
        if (this.db) {
            try {
                const res = await this.db.prepare(
                    "INSERT INTO keys (key_string, key_type, duration_seconds, is_active, note, max_hwid, max_sessions, created_at) VALUES (?, ?, ?, 1, ?, ?, ?, ?)"
                ).bind(record.key_string, record.key_type, record.duration_seconds, record.note || '', record.max_hwid || 1, record.max_sessions || 1, now).run();
                return { id: res.meta?.last_row_id || Date.now(), ...record, is_active: 1, created_at: now };
            } catch (e) {
                console.error("D1 insertKey error:", e);
            }
        }
        const id = this.memoryStore.keys.size + 1;
        const entry = { id, ...record, is_active: 1, created_at: now };
        this.memoryStore.keys.set(record.key_string, entry);
        return entry;
    }

    async deleteKey(id) {
        await this.ensureSessionTable();
        if (this.db) {
            try {
                await this.db.prepare("DELETE FROM key_hwids WHERE key_id = ?").bind(id).run();
                await this.db.prepare("DELETE FROM key_sessions WHERE key_id = ?").bind(id).run();
                await this.db.prepare("DELETE FROM keys WHERE id = ?").bind(id).run();
                return;
            } catch (e) {}
        }
        await this.kickKeySessions(id);
        for (const [k, v] of this.memoryStore.hwids.entries()) {
            if (v.key_id === Number(id)) this.memoryStore.hwids.delete(k);
        }
        for (const [k, v] of this.memoryStore.keys.entries()) {
            if (v.id === Number(id)) {
                this.memoryStore.keys.delete(k);
                break;
            }
        }
    }

    async toggleKey(id, isActive) {
        const val = isActive ? 1 : 0;
        if (this.db) {
            try {
                await this.db.prepare("UPDATE keys SET is_active = ? WHERE id = ?").bind(val, id).run();
                if (val === 0) await this.kickKeySessions(id);
                return;
            } catch (e) {}
        }
        for (const v of this.memoryStore.keys.values()) {
            if (v.id === Number(id)) {
                v.is_active = val;
                break;
            }
        }
        if (val === 0) await this.kickKeySessions(id);
    }

    async resetKeyHwid(id) {
        if (this.db) {
            try {
                await this.db.prepare("DELETE FROM key_hwids WHERE key_id = ?").bind(id).run();
                await this.db.prepare("UPDATE keys SET hwid = NULL WHERE id = ?").bind(id).run();
                return;
            } catch (e) {}
        }
        for (const [k, v] of this.memoryStore.hwids.entries()) {
            if (v.key_id === Number(id)) this.memoryStore.hwids.delete(k);
        }
        for (const v of this.memoryStore.keys.values()) {
            if (v.id === Number(id)) v.hwid = null;
        }
    }

    async removeKeyHwid(id, hwid) {
        if (this.db) {
            try {
                await this.db.prepare("DELETE FROM key_hwids WHERE key_id = ? AND hwid = ?").bind(id, hwid).run();
                return;
            } catch (e) {}
        }
        this.memoryStore.hwids.delete(\`\${id}_\${hwid}\`);
    }

    async editKey(id, updates) {
        const nowSec = Math.floor(Date.now() / 1000);
        const computeUpdatedTiming = (existing) => {
            if (!existing) return { durationSeconds: null, expiresAt: undefined, expiredNow: false };
            const resolvedDur = (updates.durationSeconds !== undefined && updates.durationSeconds !== null && !isNaN(updates.durationSeconds))
                ? Math.max(0, Number(updates.durationSeconds))
                : resolveKeyDurationSeconds(updates.keyType, updates.durationHours);
            if (resolvedDur === undefined) {
                return { durationSeconds: null, expiresAt: undefined, expiredNow: false };
            }
            if (resolvedDur === 0) {
                return { durationSeconds: 0, expiresAt: null, expiredNow: false };
            }
            // Non-zero timed key (24h, 3d, 7d, 30d)
            if (!existing.activated_at || existing.activated_at <= 0) {
                return { durationSeconds: resolvedDur, expiresAt: null, expiredNow: false };
            }
            const typeOrDurChanged = (updates.keyType !== undefined && updates.keyType !== existing.key_type)
                || Number(existing.duration_seconds) !== resolvedDur
                || !existing.expires_at;
            if (!typeOrDurChanged) {
                return { durationSeconds: resolvedDur, expiresAt: existing.expires_at, expiredNow: false };
            }
            const candidateExp = Number(existing.activated_at) + resolvedDur;
            const nextExp = candidateExp > nowSec ? candidateExp : (nowSec + resolvedDur);
            return { durationSeconds: resolvedDur, expiresAt: nextExp, expiredNow: nowSec >= nextExp };
        };

        if (this.db) {
            try {
                const existing = await this.db.prepare("SELECT * FROM keys WHERE id = ?").bind(id).first();
                if (!existing) return;
                const timing = computeUpdatedTiming(existing);
                await this.db.prepare(
                    "UPDATE keys SET note = COALESCE(?, note), max_hwid = COALESCE(?, max_hwid), max_sessions = COALESCE(?, max_sessions), is_active = COALESCE(?, is_active), key_type = COALESCE(?, key_type), duration_seconds = COALESCE(?, duration_seconds) WHERE id = ?"
                ).bind(
                    updates.note !== undefined ? updates.note : null,
                    updates.maxHwid !== undefined ? updates.maxHwid : null,
                    updates.maxSessions !== undefined ? updates.maxSessions : null,
                    updates.isActive !== undefined ? (updates.isActive ? 1 : 0) : null,
                    updates.keyType !== undefined ? updates.keyType : null,
                    timing.durationSeconds !== null ? timing.durationSeconds : null,
                    id
                ).run();
                if (timing.expiresAt !== undefined) {
                    await this.db.prepare("UPDATE keys SET expires_at = ? WHERE id = ?").bind(timing.expiresAt, id).run();
                }
                if (updates.isActive === false || timing.expiredNow) {
                    await this.kickKeySessions(id);
                }
                return;
            } catch (e) {
                console.error("D1 editKey error:", e);
            }
        }
        for (const v of this.memoryStore.keys.values()) {
            if (v.id === Number(id)) {
                const timing = computeUpdatedTiming(v);
                if (updates.note !== undefined) v.note = updates.note;
                if (updates.maxHwid !== undefined) v.max_hwid = updates.maxHwid;
                if (updates.maxSessions !== undefined) v.max_sessions = updates.maxSessions;
                if (updates.isActive !== undefined) v.is_active = updates.isActive ? 1 : 0;
                if (updates.keyType !== undefined) v.key_type = updates.keyType;
                if (timing.durationSeconds !== null) v.duration_seconds = timing.durationSeconds;
                if (timing.expiresAt !== undefined) v.expires_at = timing.expiresAt;
                if (updates.isActive === false || timing.expiredNow) {
                    await this.kickKeySessions(id);
                }
                break;
            }
        }
    }

    async getRecentLogs(limit = 100) {
        if (this.db) {
            try {
                const { results } = await this.db.prepare("SELECT * FROM access_logs ORDER BY id DESC LIMIT ?").bind(limit).all();
                return results || [];
            } catch (e) {}
        }
        return this.memoryStore.logs.slice(0, limit);
    }

    async getStats() {
        const nowSec = Math.floor(Date.now() / 1000);
        if (this.db) {
            try {
                const totalKeys = (await this.db.prepare("SELECT COUNT(*) as count FROM keys").first())?.count || 0;
                const activeKeys = (await this.db.prepare("SELECT COUNT(*) as count FROM keys WHERE is_active = 1 AND (expires_at IS NULL OR expires_at = 0 OR expires_at > ?)").bind(nowSec).first())?.count || 0;
                const totalWhitelist = (await this.db.prepare("SELECT COUNT(*) as count FROM whitelisted_users").first())?.count || 0;
                const totalLogs = (await this.db.prepare("SELECT COUNT(*) as count FROM access_logs").first())?.count || 0;
                return { totalKeys, activeKeys, boundKeys: 0, totalWhitelist, totalLogs };
            } catch (e) {}
        }
        return {
            totalKeys: this.memoryStore.keys.size,
            activeKeys: Array.from(this.memoryStore.keys.values()).filter(k => k.is_active === 1 && (!k.expires_at || k.expires_at <= 0 || nowSec < k.expires_at)).length,
            boundKeys: 0,
            totalWhitelist: this.memoryStore.whitelist.size,
            totalLogs: this.memoryStore.logs.length
        };
    }

    async findGetKeySession(sessionId) {
        if (!sessionId) return null;
        if (this.db) {
            try {
                const res = await this.db.prepare("SELECT * FROM getkey_sessions WHERE session_id = ?").bind(sessionId).first();
                if (res) return res;
            } catch (e) {}
        }
        return this.memoryStore.getkeySessions.get(sessionId) || null;
    }

    async createGetKeySession(session) {
        const now = Math.floor(Date.now() / 1000);
        const expiresAt = now + (session.durationMinutes || 45) * 60;
        if (this.db) {
            try {
                await this.db.prepare(
                    "INSERT INTO getkey_sessions (session_id, hwid, ip_address, current_step, total_steps, provider, is_completed, claimed_key, created_at, expires_at) VALUES (?, ?, ?, 1, ?, ?, 0, NULL, ?, ?)"
                ).bind(session.sessionId, session.hwid || null, session.ipAddress || null, session.totalSteps || 2, session.provider || 'dual', now, expiresAt).run();
            } catch (e) {
                console.error("D1 createGetKeySession error:", e);
            }
        }
        const record = {
            session_id: session.sessionId,
            hwid: session.hwid || null,
            ip_address: session.ipAddress || null,
            current_step: 1,
            total_steps: session.totalSteps || 2,
            provider: session.provider || 'dual',
            is_completed: 0,
            claimed_key: null,
            created_at: now,
            expires_at: expiresAt
        };
        this.memoryStore.getkeySessions.set(session.sessionId, record);
        return record;
    }

    async updateSessionProvider(sessionId, provider, totalSteps) {
        if (this.db) {
            try {
                await this.db.prepare("UPDATE getkey_sessions SET provider = ?, total_steps = ? WHERE session_id = ?").bind(provider, totalSteps, sessionId).run();
            } catch (e) {}
        }
        const s = this.memoryStore.getkeySessions.get(sessionId);
        if (s) { s.provider = provider; s.total_steps = totalSteps; }
    }

    async advanceSessionStep(sessionId, nextStep) {
        if (this.db) {
            try {
                await this.db.prepare("UPDATE getkey_sessions SET current_step = ? WHERE session_id = ?").bind(nextStep, sessionId).run();
            } catch (e) {}
        }
        const s = this.memoryStore.getkeySessions.get(sessionId);
        if (s) { s.current_step = nextStep; }
    }

    async completeSessionWithKey(sessionId, key) {
        if (this.db) {
            try {
                await this.db.prepare("UPDATE getkey_sessions SET is_completed = 1, claimed_key = ? WHERE session_id = ?").bind(key, sessionId).run();
            } catch (e) {}
        }
        const s = this.memoryStore.getkeySessions.get(sessionId);
        if (s) { s.is_completed = 1; s.claimed_key = key; }
    }

    async logAccess(log) {
        const now = Math.floor(Date.now() / 1000);
        if (this.db) {
            try {
                await this.db.prepare(
                    "INSERT INTO access_logs (key_string, roblox_user_id, username, hwid, ip_address, status, message, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
                ).bind(log.key_string || null, String(log.roblox_user_id || ''), String(log.username || ''), String(log.hwid || ''), String(log.ip_address || ''), log.status, log.message || '', now).run();
                return;
            } catch (e) {}
        }
        this.memoryStore.logs.unshift({ ...log, timestamp: now });
        if (this.memoryStore.logs.length > 200) this.memoryStore.logs.pop();
    }
}

// Request Router
export default {
    async fetch(request, env, ctx) {
        const url = new URL(request.url);
        const path = url.pathname;
        const method = request.method;

        // Security CORS headers
        const corsHeaders = {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Admin-Password, X-HWID, X-Roblox-UserId",
            "Access-Control-Max-Age": "86400"
        };

        if (method === "OPTIONS") {
            return new Response(null, { headers: corsHeaders });
        }

        const softStatus = url.searchParams.get("softStatus") === "1";
        const json = (data, status = 200) => new Response(JSON.stringify(data), {
            status: softStatus ? 200 : status,
            headers: {
                ...corsHeaders,
                "Content-Type": "application/json; charset=utf-8",
                "Cache-Control": "no-store, no-cache, must-revalidate"
            }
        });

        const text = (content, status = 200, contentType = "text/plain; charset=utf-8") => new Response(content, {
            status,
            headers: {
                ...corsHeaders,
                "Content-Type": contentType,
                "Cache-Control": "no-store, no-cache, must-revalidate"
            }
        });

        const clientIp = request.headers.get("cf-connecting-ip") || request.headers.get("x-forwarded-for") || "127.0.0.1";
        const db = new DatabaseHandler(env.DB);
        const adminPass = env.ADMIN_PASSWORD || CONFIG.DEFAULT_ADMIN_PASSWORD;
        const apiSecret = env.API_SECRET_KEY || CONFIG.DEFAULT_API_SECRET;

        // Helper: Auth Check
        const isAuthorizedAdmin = () => {
            const auth = request.headers.get("authorization");
            const customPass = request.headers.get("x-admin-password");
            if (customPass === adminPass) return true;
            if (auth && auth.startsWith("Bearer ")) {
                const token = auth.substring(7);
                const s = activeAdminSessions.get(token);
                if (s && Date.now() < s.expiresAt) return true;
            }
            return false;
        };

        // ----------------------------------------------------------------------
        // 1. FRONTEND WEB PAGES
        // ----------------------------------------------------------------------
        if (path === "/" || path === "/admin") {
            return text(INDEX_HTML, 200, "text/html; charset=utf-8");
        }
        if (path === "/getkey") {
            return text(GETKEY_HTML, 200, "text/html; charset=utf-8");
        }

        // ----------------------------------------------------------------------
        // 2. UNIVERSAL LOADER (Zero-Cache Edge Embedded) & GAME SCRIPT PROXY
        // ----------------------------------------------------------------------
        if (path === "/loader.luau" || path === "/loader" || path === "/load") {
            return text(FALLBACK_LOADER_LUAU, 200, "text/plain; charset=utf-8");
        }

        const validateEdgeToken = async (rawToken, touch = false) => {
            const nowSec = Math.floor(Date.now() / 1000);
            const tok = String(rawToken || "").trim();
            if (!tok) {
                return { valid: false, code: "MISSING_TOKEN", message: "Authentication token is required.", serverTime: nowSec };
            }
            if (tok.startsWith("wl.")) {
                const parsed = await verifyWhitelistToken(tok, apiSecret, nowSec);
                if (!parsed.valid) {
                    return { valid: false, code: parsed.reason || "INVALID_TOKEN", message: "Whitelist session expired. Re-execute loader.", serverTime: nowSec };
                }
                const wlUser = await db.findWhitelistedUser(parsed.userId);
                if (!wlUser) {
                    return { valid: false, code: "WHITELIST_REMOVED", message: "Your whitelist access has been removed.", serverTime: nowSec };
                }
                const refreshedToken = (parsed.exp - nowSec < 3600) ? await createWhitelistToken(parsed.userId, apiSecret, nowSec) : null;
                return { valid: true, whitelisted: true, expiresAt: null, serverTime: nowSec, refreshedToken };
            }
            const res = await db.verifySessionHeartbeat(tok, touch);
            if (!res.active) {
                return { valid: false, code: res.code, message: res.message, expiresAt: res.expiresAt || null, serverTime: nowSec };
            }
            return { valid: true, whitelisted: false, keyType: res.keyType, expiresAt: res.expiresAt, serverTime: nowSec };
        };

        if (path.startsWith("/scripts/")) {
            const edgeToken = url.searchParams.get("token") || request.headers.get("x-session-token") || "";
            const authCheck = await validateEdgeToken(edgeToken, false);
            if (!authCheck.valid) {
                return text(\`-- ACCESS_DENIED: \${authCheck.message || authCheck.code || "Your license key has expired or session is invalid."}\`, 403, "text/plain; charset=utf-8");
            }
            const gameFile = path.replace("/scripts/", "").replace(/[^a-zA-Z0-9_\\-\\.]/g, "");
            const fileName = gameFile.endsWith(".luau") || gameFile.endsWith(".lua") ? gameFile : gameFile + ".luau";
            try {
                const ghUrl = \`https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/games/\${fileName}?v=\${Date.now()}\`;
                const ghRes = await fetch(ghUrl, { headers: { "User-Agent": "Cloudflare-Worker-Proxy", "Cache-Control": "no-cache" } });
                if (ghRes.ok) {
                    const code = await ghRes.text();
                    return text(code, 200, "text/plain; charset=utf-8");
                }
            } catch (e) {}
            return text(\`-- Game script not found for \${fileName}\`, 404);
        }

        if (path === "/version") {
            return json({ version: "1.0.8", updatedAt: Date.now(), cloudflare: true });
        }

        // ----------------------------------------------------------------------
        // 3. CLIENT KEY & WHITELIST VERIFICATION API
        // ----------------------------------------------------------------------
        if (path === "/api/verify-key" || path === "/api/v1/verify") {
            let body = {};
            if (method === "POST") {
                try { body = await request.json(); } catch (e) {}
            }
            const nowSec = Math.floor(Date.now() / 1000);
            const key = normalizeVerifiedKey(body.key || url.searchParams.get("key") || "");
            const userId = body.userId || url.searchParams.get("userId") || request.headers.get("x-roblox-userid");
            const username = String(body.username || url.searchParams.get("username") || "").trim();
            const rawHwid = String(body.hwid || url.searchParams.get("hwid") || request.headers.get("x-hwid") || "").trim();
            const hwid = rawHwid || (userId ? \`USER_\${String(userId).trim()}\` : \`IP_\${clientIp}\`);

            // Direct Whitelist Check
            if (userId) {
                const whitelisted = await db.findWhitelistedUser(userId);
                if (whitelisted) {
                    const wlToken = await createWhitelistToken(userId, apiSecret, nowSec);
                    await db.logAccess({
                        key_string: null, roblox_user_id: userId, username, hwid, ip_address: clientIp,
                        status: "WHITELIST_BYPASS", message: \`Authenticated via Direct Whitelist (\${whitelisted.role})\`
                    });
                    return json({
                        success: true,
                        whitelisted: true,
                        role: whitelisted.role,
                        keyType: "VIP Permanent",
                        expiresAt: null,
                        serverTime: nowSec,
                        sessionToken: wlToken,
                        message: \`Welcome back, \${whitelisted.role} \${username || userId}!\`
                    });
                }
            }

            if (!key) {
                return json({ success: false, code: "MISSING_KEY", serverTime: nowSec, message: "Please provide a valid license key." }, 400);
            }

            const keyData = await db.findKey(key);
            if (!keyData) {
                await db.logAccess({ key_string: key, roblox_user_id: userId, username, hwid, ip_address: clientIp, status: "INVALID", message: "Key not found" });
                return json({ success: false, code: "INVALID_KEY", serverTime: nowSec, message: "Key does not exist." }, 403);
            }

            if (keyData.is_active === 0) {
                await db.kickKeySessions(keyData.id);
                await db.logAccess({ key_string: key, roblox_user_id: userId, username, hwid, ip_address: clientIp, status: "REVOKED", message: "Key revoked by admin" });
                return json({ success: false, code: "KEY_REVOKED", serverTime: nowSec, message: "This key has been suspended or revoked." }, 403);
            }

            if (keyData.expires_at && keyData.expires_at > 0 && nowSec >= keyData.expires_at) {
                await db.kickKeySessions(keyData.id);
                await db.logAccess({ key_string: key, roblox_user_id: userId, username, hwid, ip_address: clientIp, status: "EXPIRED", message: "Key expired" });
                return json({ success: false, code: "KEY_EXPIRED", expiresAt: keyData.expires_at, serverTime: nowSec, message: "Your license key has expired." }, 403);
            }

            // Reject already-expired keys before mutating bound HWIDs or activating
            if (keyData.expires_at && keyData.expires_at > 0 && nowSec >= keyData.expires_at) {
                await db.kickKeySessions(keyData.id);
                await db.logAccess({ key_string: key, roblox_user_id: userId, username, hwid, ip_address: clientIp, status: "EXPIRED", message: "Key expired" });
                return json({ success: false, code: "KEY_EXPIRED", expiresAt: keyData.expires_at, serverTime: nowSec, message: "Your license key has expired." }, 403);
            }

            // Purge stale/idle sessions (> 90s since heartbeat) before evaluating HWID & session limits
            let activeSessions = await db.getActiveSessions(keyData.id, 90);
            let boundHwids = await db.getKeyHwids(keyData.id);

            // Auto-release any bound HWIDs with zero active sessions (client exited cleanly or timed out > 90s)
            if (boundHwids.length > 0) {
                const activeHwidSet = new Set(activeSessions.map(s => s.hwid));
                const staleHwids = boundHwids.filter(bh => !activeHwidSet.has(bh.hwid));
                if (staleHwids.length > 0) {
                    if (staleHwids.length === boundHwids.length) {
                        await db.resetKeyHwid(keyData.id);
                        boundHwids = [];
                    } else {
                        for (const bh of staleHwids) {
                            await db.removeKeyHwid(keyData.id, bh.hwid);
                        }
                        boundHwids = boundHwids.filter(bh => activeHwidSet.has(bh.hwid));
                    }
                }
            }

            const maxHwid = keyData.max_hwid || 1;
            const isBound = boundHwids.some(h => h.hwid === hwid);

            if (!isBound) {
                // Allow seamless HWID rotation for the exact same Roblox userId (< 90s crash/re-exec/server-hop),
                // provided no other Roblox userId currently holds an active session on that HWID.
                if (boundHwids.length >= maxHwid && userId) {
                    const userStr = String(userId).trim();
                    const replaceable = boundHwids.filter(bh => {
                        const sessionsOnHwid = activeSessions.filter(s => s.hwid === bh.hwid);
                        return sessionsOnHwid.length > 0
                            ? sessionsOnHwid.every(s => s.roblox_user_id && String(s.roblox_user_id).trim() === userStr)
                            : (bh.user_id && String(bh.user_id).trim() === userStr);
                    });
                    if (replaceable.length > 0) {
                        for (const bh of replaceable) {
                            for (const s of activeSessions) {
                                if (s.hwid === bh.hwid && s.roblox_user_id && String(s.roblox_user_id).trim() === userStr) {
                                    await db.closeKeySession(s.session_token, false);
                                }
                            }
                            await db.removeKeyHwid(keyData.id, bh.hwid);
                        }
                        activeSessions = await db.getActiveSessions(keyData.id, 90);
                        boundHwids = await db.getKeyHwids(keyData.id);
                    }
                }

                if (boundHwids.some(h => h.hwid === hwid) || boundHwids.length < maxHwid) {
                    await db.addKeyHwid(keyData.id, hwid, userId, username);
                } else {
                    await db.logAccess({ key_string: key, roblox_user_id: userId, username, hwid, ip_address: clientIp, status: "HWID_MISMATCH", message: "Max devices exceeded (active session on another HWID)" });
                    return json({ success: false, code: "HWID_MISMATCH", serverTime: nowSec, message: "Key is already active on another device. Exit the script on that device or wait 90s before re-using." }, 403);
                }
            } else {
                await db.addKeyHwid(keyData.id, hwid, userId, username);
            }

            let effectiveExpiresAt = (keyData.expires_at && keyData.expires_at > 0) ? keyData.expires_at : null;
            if (!keyData.activated_at) {
                const actRes = await db.activateKey(keyData.id, keyData.duration_seconds);
                effectiveExpiresAt = actRes ? actRes.expiresAt : (keyData.duration_seconds > 0 ? nowSec + keyData.duration_seconds : null);
            }

            if (effectiveExpiresAt && effectiveExpiresAt > 0 && nowSec >= effectiveExpiresAt) {
                await db.kickKeySessions(keyData.id);
                await db.logAccess({ key_string: key, roblox_user_id: userId, username, hwid, ip_address: clientIp, status: "EXPIRED", message: "Key expired" });
                return json({ success: false, code: "KEY_EXPIRED", expiresAt: effectiveExpiresAt, serverTime: nowSec, message: "Your license key has expired." }, 403);
            }

            // Live Session Tracking & Limit Check
            const jobId = body.jobId || url.searchParams.get("jobId") || "";
            const userStr = userId ? String(userId).trim() : "";
            let session = activeSessions.find(s => {
                if (userStr && s.roblox_user_id) {
                    return String(s.roblox_user_id).trim() === userStr && s.hwid === hwid;
                }
                if (userStr && !s.roblox_user_id) {
                    return s.hwid === hwid || (jobId && s.job_id === jobId);
                }
                return (hwid && s.hwid === hwid) || (jobId && s.job_id === jobId);
            });

            let sessionToken = session ? session.session_token : null;
            if (!session) {
                if (activeSessions.length >= (keyData.max_sessions || 1)) {
                    await db.logAccess({ key_string: key, roblox_user_id: userId, username, hwid, ip_address: clientIp, status: "SESSION_LIMIT", message: \`Max sessions (\${keyData.max_sessions}) exceeded\` });
                    return json({ success: false, code: "MAX_SESSIONS_EXCEEDED", serverTime: nowSec, message: \`Session limit reached (\${activeSessions.length}/\${keyData.max_sessions} Live). Close other Roblox instances or wait 60s.\` }, 403);
                }
                sessionToken = generateHex(24);
                const reqPlaceId = body.placeId || url.searchParams.get("placeId") || "";
                await db.createKeySession(keyData.id, sessionToken, hwid, userId, username, jobId, reqPlaceId, clientIp);
            } else {
                await db.updateSessionHeartbeat(sessionToken);
            }

            await db.logAccess({ key_string: key, roblox_user_id: userId, username, hwid, ip_address: clientIp, status: "SUCCESS", message: "Key verified successfully" });
            return json({
                success: true,
                whitelisted: false,
                keyType: keyData.key_type,
                expiresAt: effectiveExpiresAt,
                serverTime: nowSec,
                durationSeconds: keyData.duration_seconds,
                sessionToken: sessionToken,
                maxSessions: keyData.max_sessions || 1,
                activeSessionsCount: (activeSessions.length + (session ? 0 : 1)),
                message: "Authentication successful! Welcome to Song Hub."
            });
        }

        // Quick Whitelist Check
        if (path === "/api/check-whitelist" || path === "/api/v1/check-whitelist") {
            const userId = url.searchParams.get("userId") || (method === "POST" ? (await request.json().catch(() => ({}))).userId : null);
            if (!userId) return json({ success: false, whitelisted: false });
            const user = await db.findWhitelistedUser(userId);
            return json({
                success: true,
                whitelisted: !!user,
                role: user ? user.role : null,
                userId: String(userId)
            });
        }

        // Heartbeat
        // Heartbeat Endpoint for Real-Time Live Session Tracking & Strict Expiry Enforcement
        if (path === "/api/v1/heartbeat" || path === "/api/heartbeat") {
            let body = {};
            if (method === "POST") {
                try { body = await request.json(); } catch (e) {}
            }
            const nowSec = Math.floor(Date.now() / 1000);
            const sessionToken = String(body.sessionToken || url.searchParams.get("sessionToken") || request.headers.get("x-session-token") || "").trim();
            if (!sessionToken) {
                return json({ success: false, active: false, code: "MISSING_SESSION", serverTime: nowSec, message: "Missing sessionToken", error: "Missing sessionToken" }, 400);
            }
            const check = await validateEdgeToken(sessionToken, true);
            if (!check.valid) {
                return json({
                    success: false,
                    active: false,
                    code: check.code || "SESSION_INVALID",
                    message: check.message || "Your license key has expired or session ended.",
                    expiresAt: check.expiresAt || null,
                    serverTime: check.serverTime
                }, 403);
            }
            return json({
                success: true,
                active: true,
                whitelisted: !!check.whitelisted,
                keyType: check.keyType || (check.whitelisted ? "VIP Permanent" : undefined),
                expiresAt: check.expiresAt || null,
                serverTime: check.serverTime,
                refreshedToken: check.refreshedToken || undefined
            });
        }

        // Close Session Endpoint when client exits game (auto-releases idle HWID on clean exit)
        if (path === "/api/v1/session/close" || path === "/api/session/close") {
            let body = {};
            if (method === "POST") {
                try { body = await request.json(); } catch (e) {}
            }
            const sessionToken = body.sessionToken || url.searchParams.get("sessionToken") || "";
            if (sessionToken) {
                await db.closeKeySession(sessionToken, true);
            }
            return json({ success: true, message: "Session closed" });
        }

        // ----------------------------------------------------------------------
        // 4. FREE GET KEY / MONETIZATION FLOW (LOOTLABS & LINKVERTISE)
        // ----------------------------------------------------------------------
        if (path === "/api/v1/getkey/init") {
            const cfgEnabled = (await db.getSetting("getkey_enabled", "1")) !== "0";
            if (!cfgEnabled) {
                return json({ success: false, error: "Get Key system is currently disabled by administrator." }, 403);
            }

            const hwid = url.searchParams.get("hwid") || "";
            const sessionParam = url.searchParams.get("session") || "";
            const cfgMode = String(await db.getSetting("getkey_mode", "dual")).toLowerCase();
            const cfgSteps = Math.max(1, Math.min(parseInt(await db.getSetting("getkey_steps", "2")) || 2, 10));
            const cfgDurationHours = parseInt(await db.getSetting("getkey_duration_hours", "24")) || 24;
            const queryProvider = String(url.searchParams.get("provider") || "").toLowerCase();

            if (sessionParam) {
                const existing = await db.findGetKeySession(sessionParam);
                if (existing) {
                    if (existing.is_completed === 1 && existing.claimed_key) {
                        return json({
                            success: true,
                            sessionId: existing.session_id,
                            currentStep: existing.total_steps,
                            totalSteps: existing.total_steps,
                            provider: existing.provider,
                            configuredMode: cfgMode,
                            durationHours: cfgDurationHours,
                            isCompleted: true,
                            claimedKey: existing.claimed_key
                        });
                    }
                    let effSteps = Number(existing.total_steps) || cfgSteps;
                    let effProvider = String(existing.provider || cfgMode).toLowerCase();
                    const needsProviderNormalize = (cfgMode === "dual" && effProvider !== "lootlabs" && effProvider !== "linkvertise");
                    if (Number(existing.current_step) <= 1 && (effSteps !== cfgSteps || (cfgMode !== "dual" && effProvider !== cfgMode) || needsProviderNormalize)) {
                        effSteps = cfgSteps;
                        if (cfgMode === "dual") {
                            if (queryProvider === "lootlabs" || queryProvider === "linkvertise") {
                                effProvider = queryProvider;
                            } else if (effProvider !== "lootlabs" && effProvider !== "linkvertise") {
                                effProvider = "lootlabs";
                            }
                        } else {
                            effProvider = cfgMode;
                        }
                        await db.updateSessionProvider(existing.session_id, effProvider, effSteps);
                    }
                    return json({
                        success: true,
                        sessionId: existing.session_id,
                        currentStep: existing.current_step,
                        totalSteps: effSteps,
                        provider: effProvider,
                        configuredMode: cfgMode,
                        durationHours: cfgDurationHours,
                        isCompleted: existing.is_completed === 1,
                        claimedKey: existing.claimed_key
                    });
                }
            }

            let initProvider = cfgMode;
            if (cfgMode === "dual") {
                initProvider = (queryProvider === "linkvertise") ? "linkvertise" : "lootlabs";
            }
            const totalSteps = cfgSteps;
            const sessionId = generateHex(16);
            await db.createGetKeySession({
                sessionId,
                hwid,
                ipAddress: clientIp,
                provider: initProvider,
                totalSteps
            });

            return json({
                success: true,
                sessionId,
                currentStep: 1,
                totalSteps,
                provider: initProvider,
                configuredMode: cfgMode,
                durationHours: cfgDurationHours,
                isCompleted: false,
                claimedKey: null
            });
        }

        if (path === "/api/v1/getkey/switch-provider") {
            let body = {};
            try { body = await request.json(); } catch (e) {}
            const sessionId = body.sessionId || "";
            const reqProv = String(body.provider || "lootlabs").toLowerCase();
            const cfgMode = String(await db.getSetting("getkey_mode", "dual")).toLowerCase();
            const cfgSteps = Math.max(1, Math.min(parseInt(await db.getSetting("getkey_steps", "2")) || 2, 10));

            let resolvedProvider = cfgMode;
            if (cfgMode === "dual") {
                resolvedProvider = (reqProv === "linkvertise") ? "linkvertise" : "lootlabs";
            }

            let totalSteps = cfgSteps;
            if (sessionId) {
                const existing = await db.findGetKeySession(sessionId);
                if (existing) {
                    if (existing.is_completed === 1) {
                        return json({
                            success: true,
                            provider: existing.provider,
                            totalSteps: Number(existing.total_steps) || cfgSteps,
                            configuredMode: cfgMode
                        });
                    }
                    totalSteps = (Number(existing.current_step) > 1 && Number(existing.total_steps))
                        ? Number(existing.total_steps)
                        : cfgSteps;
                }
                await db.updateSessionProvider(sessionId, resolvedProvider, totalSteps);
            }
            return json({ success: true, provider: resolvedProvider, totalSteps, configuredMode: cfgMode });
        }

        if (path === "/api/v1/getkey/link") {
            const sessionId = url.searchParams.get("sessionId") || "";
            let step = Math.max(1, parseInt(url.searchParams.get("step") || "1") || 1);
            const host = url.origin;

            let session = null;
            if (sessionId) {
                session = await db.findGetKeySession(sessionId);
            }
            const cfgMode = String(await db.getSetting("getkey_mode", "dual")).toLowerCase();
            const cfgSteps = Math.max(1, Math.min(parseInt(await db.getSetting("getkey_steps", "2")) || 2, 10));
            const totalSteps = session ? (Number(session.total_steps) || cfgSteps) : cfgSteps;
            if (step > totalSteps) step = totalSteps;
            if (session && step > Number(session.current_step || 1)) {
                step = Number(session.current_step || 1);
            }

            const sig = await hmacSha256(\`\${sessionId}_\${step}\`, apiSecret);
            const destinationUrl = \`\${host}/api/v1/getkey/callback?session=\${sessionId}&step=\${step}&sig=\${sig}\`;

            const sessionProvider = String(session ? session.provider : (url.searchParams.get("provider") || cfgMode)).toLowerCase();
            let stepProvider = "lootlabs";
            if (cfgMode === "linkvertise" || (cfgMode === "dual" && sessionProvider === "linkvertise")) {
                stepProvider = "linkvertise";
            } else if (cfgMode === "lootlabs" || (cfgMode === "dual" && sessionProvider === "lootlabs")) {
                stepProvider = "lootlabs";
            } else {
                stepProvider = (step % 2 === 1) ? "lootlabs" : "linkvertise";
            }

            let redirectUrl = destinationUrl;

            if (stepProvider === "linkvertise") {
                const pubId = await db.getSetting("getkey_linkvertise_id", CONFIG.GETKEY.LINKVERTISE_USER_ID);
                const b64 = btoa(encodeURI(destinationUrl));
                const slug = Math.floor(Math.random() * 90000) + 10000;
                redirectUrl = \`https://link-to.net/\${pubId}/\${slug}/dynamic/?r=\${b64}\`;
            } else {
                const lootKey = await db.getSetting("getkey_lootlabs_key", CONFIG.GETKEY.LOOTLABS_API_KEY);
                const lootTier = parseInt(await db.getSetting("getkey_lootlabs_tier", "1")) || 1;
                const lootTasks = parseInt(await db.getSetting("getkey_lootlabs_tasks", "2")) || 2;
                try {
                    const llRes = await fetch("https://creators.lootlabs.gg/api/public/content_locker", {
                        method: "POST",
                        headers: {
                            "Authorization": \`Bearer \${lootKey}\`,
                            "Content-Type": "application/json"
                        },
                        body: JSON.stringify({
                            title: \`Song Hub Key Checkpoint \${step}/\${totalSteps}\`,
                            url: destinationUrl,
                            tier_id: lootTier,
                            number_of_tasks: lootTasks,
                            theme: 1
                        })
                    });
                    const llData = await llRes.json();
                    if (llData && llData.loot_url) redirectUrl = llData.loot_url;
                    else if (llData && llData.message && llData.message[0] && llData.message[0].loot_url) redirectUrl = llData.message[0].loot_url;
                } catch (e) {
                    console.error("Lootlabs error:", e);
                }
            }

            return json({ success: true, redirectUrl, step, totalSteps, provider: stepProvider });
        }

        if (path === "/api/v1/getkey/callback") {
            const sessionId = url.searchParams.get("session") || "";
            const step = parseInt(url.searchParams.get("step") || "1") || 1;
            const sig = url.searchParams.get("sig") || "";

            const expectedSig = await hmacSha256(\`\${sessionId}_\${step}\`, apiSecret);
            if (sig !== expectedSig) {
                return Response.redirect(\`\${url.origin}/getkey?error=invalid_signature\`, 302);
            }

            const session = await db.findGetKeySession(sessionId);
            if (session && session.is_completed === 1 && session.claimed_key) {
                return Response.redirect(\`\${url.origin}/getkey?session=\${sessionId}&claimed=1&key=\${session.claimed_key}\`, 302);
            }

            const cfgSteps = Math.max(1, Math.min(parseInt(await db.getSetting("getkey_steps", "2")) || 2, 10));
            const totalSteps = session ? Math.max(1, Number(session.total_steps) || cfgSteps) : cfgSteps;
            const currentStep = session ? Math.max(1, Number(session.current_step) || 1) : 1;

            if (session && step < currentStep) {
                return Response.redirect(\`\${url.origin}/getkey?session=\${sessionId}&step=\${currentStep}\`, 302);
            }
            if (session && step > currentStep) {
                return Response.redirect(\`\${url.origin}/getkey?session=\${sessionId}&step=\${currentStep}&error=step_order\`, 302);
            }

            if (step < totalSteps) {
                await db.advanceSessionStep(sessionId, step + 1);
                return Response.redirect(\`\${url.origin}/getkey?session=\${sessionId}&step=\${step + 1}&stepSuccess=1\`, 302);
            }

            // All checkpoints completed! Generate Free Key using configured limits
            const freeKey = generateKeyString("FREE");
            const durationHours = parseInt(await db.getSetting("getkey_duration_hours", "24")) || 24;
            const maxHwid = parseInt(await db.getSetting("getkey_max_hwid", "1")) || 1;
            const maxSessions = parseInt(await db.getSetting("getkey_max_sessions", "1")) || 1;

            await db.insertKey({
                key_string: freeKey,
                key_type: \`Free \${durationHours}h\`,
                duration_seconds: durationHours * 3600,
                note: \`Claimed via GetKey Portal (\${session ? session.provider : 'linkvertise'})\`,
                max_hwid: maxHwid,
                max_sessions: maxSessions
            });

            if (sessionId) {
                await db.completeSessionWithKey(sessionId, freeKey);
            }

            return Response.redirect(\`\${url.origin}/getkey?session=\${sessionId}&claimed=1&key=\${freeKey}\`, 302);
        }

        // ----------------------------------------------------------------------
        // 5. ADMIN DASHBOARD API (FULL EMULATION OF SERVER.JS)
        // ----------------------------------------------------------------------
        if (path === "/api/admin/login" || path === "/api/v1/admin/login") {
            let body = {};
            try { body = await request.json(); } catch (e) {}
            if (body.password === adminPass) {
                const token = generateHex(24);
                activeAdminSessions.set(token, { expiresAt: Date.now() + 24 * 3600 * 1000 });
                return json({ success: true, token, message: "Login successful!" });
            }
            return json({ success: false, error: "Incorrect admin password" }, 401);
        }

        // Protected Admin Endpoints
        if (path.startsWith("/api/admin/") || path.startsWith("/api/v1/admin/")) {
            if (!isAuthorizedAdmin()) {
                return json({ success: false, error: "Unauthorized: Invalid or expired Admin credentials" }, 401);
            }

            // Logout
            if (path.endsWith("/logout")) {
                const auth = request.headers.get("authorization");
                if (auth && auth.startsWith("Bearer ")) {
                    activeAdminSessions.delete(auth.substring(7));
                }
                return json({ success: true, message: "Logged out" });
            }

            // Stats
            if (path.endsWith("/stats")) {
                const stats = await db.getStats();
                return json({
                    success: true,
                    stats,
                    hubName: env.HUB_NAME || CONFIG.DEFAULT_HUB_NAME
                });
            }

            // Keys List (GET)
            if (method === "GET" && (path === "/api/admin/keys" || path === "/api/v1/admin/keys")) {
                const keys = await db.getAllKeys();
                return json({ success: true, keys });
            }

            // Generate Key(s) (POST)
            if (path.endsWith("/keys/generate") || path.endsWith("/generate-key")) {
                const body = await request.json().catch(() => ({}));
                const count = Math.min(Math.max(parseInt(body.count) || 1, 1), 100);
                const rawType = body.type || body.keyType || "Free 24h";
                const prefix = String(body.prefix || "GALAXY").trim().toUpperCase();
                const note = String(body.note || "Created from Cloudflare Admin").trim();
                const maxHwid = Math.min(Math.max(parseInt(body.maxHwid) || 1, 1), 50);
                const maxSessions = Math.min(Math.max(parseInt(body.maxSessions) || 1, 1), 50);

                const resolvedDur = resolveKeyDurationSeconds(rawType, body.durationHours);
                const durationSeconds = resolvedDur !== undefined ? resolvedDur : 86400;

                const generated = [];
                for (let i = 0; i < count; i++) {
                    const newKey = generateKeyString(prefix || "GALAXY");
                    const record = await db.insertKey({
                        key_string: newKey,
                        key_type: rawType,
                        duration_seconds: durationSeconds,
                        note,
                        max_hwid: maxHwid,
                        max_sessions: maxSessions
                    });
                    generated.push(record);
                }

                return json({
                    success: true,
                    createdCount: generated.length,
                    keys: generated,
                    key: generated[0]?.key_string,
                    keyType: rawType,
                    durationSeconds
                });
            }

            // Edit Key
            if (path.endsWith("/keys/edit")) {
                const body = await request.json().catch(() => ({}));
                if (!body.id) return json({ success: false, error: "Missing key id" }, 400);
                await db.editKey(body.id, body);
                return json({ success: true, message: "Key updated" });
            }

            // Reset HWID
            if (path.endsWith("/keys/reset-hwid")) {
                const body = await request.json().catch(() => ({}));
                if (!body.id) return json({ success: false, error: "Missing key id" }, 400);
                await db.resetKeyHwid(body.id);
                return json({ success: true, message: "HWID reset successfully" });
            }

            // Toggle Key Status
            if (path.endsWith("/keys/toggle")) {
                const body = await request.json().catch(() => ({}));
                if (body.id === undefined) return json({ success: false, error: "Missing key id" }, 400);
                await db.toggleKey(body.id, body.isActive);
                return json({ success: true, message: "Key status toggled" });
            }

            // Kick Sessions
            if (path.endsWith("/keys/kick-sessions")) {
                const body = await request.json().catch(() => ({}));
                if (body.id) {
                    await db.kickKeySessions(body.id);
                }
                return json({ success: true, message: "All sessions kicked successfully" });
            }

            // Get Key HWIDs: /api/v1/admin/keys/:id/hwids
            const hwidMatch = path.match(/\\/keys\\/(\\d+)\\/hwids$/);
            if (hwidMatch) {
                const keyId = hwidMatch[1];
                const hwids = await db.getKeyHwids(keyId);
                return json({ success: true, hwids });
            }

            // Remove Specific HWID
            if (path.endsWith("/keys/remove-hwid")) {
                const body = await request.json().catch(() => ({}));
                if (!body.id || !body.hwid) return json({ success: false, error: "Missing key id or hwid" }, 400);
                await db.removeKeyHwid(body.id, body.hwid);
                return json({ success: true, message: "HWID removed successfully" });
            }

            // Delete Key: DELETE /api/v1/admin/keys/:id
            if (method === "DELETE") {
                const keyDelMatch = path.match(/\\/keys\\/(\\d+)$/);
                if (keyDelMatch) {
                    await db.deleteKey(keyDelMatch[1]);
                    return json({ success: true, message: "Key deleted" });
                }
            }

            // Whitelist List (GET)
            if (method === "GET" && (path === "/api/admin/whitelist" || path === "/api/v1/admin/whitelist")) {
                const users = await db.getAllWhitelistedUsers();
                return json({ success: true, users });
            }

            // Add Whitelist (POST)
            if (path.endsWith("/whitelist/add")) {
                const body = await request.json().catch(() => ({}));
                if (!body.robloxUserId) return json({ success: false, error: "Roblox UserID is required" }, 400);
                const user = await db.addWhitelistedUser(body.robloxUserId, body.username, body.role, body.note);
                return json({ success: true, user, message: "User added to whitelist" });
            }

            // Delete Whitelist: DELETE /api/v1/admin/whitelist/:id
            if (method === "DELETE") {
                const wlDelMatch = path.match(/\\/whitelist\\/([a-zA-Z0-9_]+)$/);
                if (wlDelMatch) {
                    await db.removeWhitelistedUser(wlDelMatch[1]);
                    return json({ success: true, message: "User removed from whitelist" });
                }
            }

            // Logs (GET)
            if (path.endsWith("/logs")) {
                const limit = parseInt(url.searchParams.get("limit") || "100");
                const logs = await db.getRecentLogs(limit);
                return json({ success: true, logs });
            }

            // GetKey Settings (GET & POST)
            if (path.endsWith("/getkey/settings")) {
                if (method === "POST") {
                    const body = await request.json().catch(() => ({}));
                    const mode = String(body.mode || "dual").toLowerCase();
                    const steps = Math.max(1, Math.min(parseInt(body.steps) || 2, 10));
                    const durationHours = Math.max(1, Math.min(parseInt(body.durationHours) || 24, 720));
                    const maxHwid = Math.max(1, Math.min(parseInt(body.maxHwid !== undefined ? body.maxHwid : 1) || 1, 50));
                    const maxSessions = Math.max(1, Math.min(parseInt(body.maxSessions !== undefined ? body.maxSessions : 1) || 1, 50));
                    const lootlabsTierId = Math.max(1, Math.min(parseInt(body.lootlabsTierId) || 1, 4));
                    const lootlabsTasks = Math.max(1, Math.min(parseInt(body.lootlabsTasks) || 2, 10));

                    await db.setSetting("getkey_enabled", body.enabled ? "1" : "0");
                    await db.setSetting("getkey_mode", mode);
                    await db.setSetting("getkey_steps", String(steps));
                    await db.setSetting("getkey_duration_hours", String(durationHours));
                    await db.setSetting("getkey_max_hwid", String(maxHwid));
                    await db.setSetting("getkey_max_sessions", String(maxSessions));
                    await db.setSetting("getkey_linkvertise_id", body.linkvertiseUserId || CONFIG.GETKEY.LINKVERTISE_USER_ID);
                    await db.setSetting("getkey_lootlabs_key", body.lootlabsApiKey || CONFIG.GETKEY.LOOTLABS_API_KEY);
                    await db.setSetting("getkey_lootlabs_tier", String(lootlabsTierId));
                    await db.setSetting("getkey_lootlabs_tasks", String(lootlabsTasks));
                    return json({
                        success: true,
                        message: "Settings saved successfully",
                        settings: {
                            enabled: !!body.enabled,
                            mode,
                            steps,
                            durationHours,
                            maxHwid,
                            maxSessions,
                            linkvertiseUserId: body.linkvertiseUserId || CONFIG.GETKEY.LINKVERTISE_USER_ID,
                            lootlabsApiKey: body.lootlabsApiKey || CONFIG.GETKEY.LOOTLABS_API_KEY,
                            lootlabsTierId,
                            lootlabsTasks,
                            requireCaptcha: false
                        }
                    });
                } else {
                    const maxHwid = parseInt(await db.getSetting("getkey_max_hwid", "1")) || 1;
                    const maxSessions = parseInt(await db.getSetting("getkey_max_sessions", "1")) || 1;
                    const durationHours = parseInt(await db.getSetting("getkey_duration_hours", "24")) || 24;
                    const steps = Math.max(1, Math.min(parseInt(await db.getSetting("getkey_steps", "2")) || 2, 10));
                    const lootlabsTierId = parseInt(await db.getSetting("getkey_lootlabs_tier", "1")) || 1;
                    const lootlabsTasks = parseInt(await db.getSetting("getkey_lootlabs_tasks", "2")) || 2;
                    return json({
                        success: true,
                        settings: {
                            enabled: (await db.getSetting("getkey_enabled", "1")) === "1",
                            mode: await db.getSetting("getkey_mode", "dual"),
                            steps,
                            durationHours,
                            maxHwid,
                            maxSessions,
                            linkvertiseUserId: await db.getSetting("getkey_linkvertise_id", CONFIG.GETKEY.LINKVERTISE_USER_ID),
                            lootlabsApiKey: await db.getSetting("getkey_lootlabs_key", CONFIG.GETKEY.LOOTLABS_API_KEY),
                            lootlabsTierId,
                            lootlabsTasks,
                            requireCaptcha: false
                        }
                    });
                }
            }

            // GetKey Sessions
            if (path.endsWith("/getkey/sessions")) {
                let sessions = [];
                if (env.DB) {
                    try {
                        const res = await env.DB.prepare("SELECT * FROM getkey_sessions ORDER BY id DESC LIMIT 50").all();
                        sessions = res.results || [];
                    } catch (e) {}
                } else {
                    sessions = Array.from(db.memoryStore.getkeySessions.values()).reverse().slice(0, 50);
                }
                return json({ success: true, sessions });
            }

            // Database Backup & Restore
            if (path.endsWith("/database/backup")) {
                const keys = await db.getAllKeys();
                const whitelist = await db.getAllWhitelistedUsers();
                const logs = await db.getRecentLogs(100);
                return json({
                    success: true,
                    backup: {
                        keys,
                        whitelist,
                        logs,
                        exportedAt: new Date().toISOString()
                    }
                });
            }

            if (path.endsWith("/database/restore")) {
                const body = await request.json().catch(() => ({}));
                const payload = body.backup || body;
                if (payload.keys && Array.isArray(payload.keys)) {
                    for (const k of payload.keys) {
                        await db.insertKey(k);
                    }
                }
                if (payload.whitelist && Array.isArray(payload.whitelist)) {
                    for (const u of payload.whitelist) {
                        await db.addWhitelistedUser(u.roblox_user_id || u.robloxUserId, u.username, u.role, u.note);
                    }
                }
                return json({ success: true, message: "Backup restored successfully" });
            }

            // Cloud sync placeholders (in Cloudflare, D1 is already globally distributed in cloud!)
            if (path.endsWith("/database/sync-cloud") || path.endsWith("/database/pull-cloud")) {
                return json({ success: true, message: "Cloudflare D1 is natively cloud-synced across global edge locations" });
            }
        }

        return json({ success: false, error: "Route not found" }, 404);
    }
};
`;

fs.writeFileSync(path.join(SRC_DIR, 'index.js'), workerTemplate, 'utf8');
console.log('✅ Generated Cloudflare Worker src/index.js successfully!');
