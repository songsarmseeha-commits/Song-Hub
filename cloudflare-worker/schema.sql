-- ==============================================================================
-- Cloudflare D1 Database Schema - Song Hub Whitelist & Key System
-- ==============================================================================

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

CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY,
    value TEXT
);

-- Secondary indexes chosen to cut D1 rows_read without adding write amplification on heartbeats/logs
CREATE INDEX IF NOT EXISTS idx_key_sessions_key_id ON key_sessions(key_id);
CREATE INDEX IF NOT EXISTS idx_keys_upper_trim ON keys(UPPER(TRIM(key_string)));

-- Seed default whitelisted owner / admin
INSERT OR IGNORE INTO whitelisted_users (roblox_user_id, username, role, note, created_at)
VALUES ('5026261400', 'abdulloh', 'Owner', 'System Owner & Developer', strftime('%s', 'now'));

