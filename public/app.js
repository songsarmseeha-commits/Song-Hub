// ==============================================================================
// Admin Dashboard Interactive Controller
// ==============================================================================

// Base API URL: Handles both http://localhost:3000 and direct file:// opening
const API_BASE = (window.location.protocol === 'file:' || !window.location.host) 
    ? 'http://localhost:3000' 
    : '';

let adminToken = localStorage.getItem('hub_admin_token') || '';
let allKeysCache = [];

// Safe Lucide icon renderer
function safeRenderIcons() {
    if (window.lucide && typeof window.lucide.createIcons === 'function') {
        try {
            window.safeRenderIcons();
        } catch (e) {
            console.warn('Lucide icon render warning:', e);
        }
    }
}

// Safe Lucide icon renderer
function safeRenderIcons() {
    if (window.lucide && typeof window.lucide.createIcons === 'function') {
        try {
            window.lucide.createIcons();
        } catch (e) {
            console.warn('Lucide icon render warning:', e);
        }
    }
}

// Show Toast
function showToast(message, type = 'success') {
    const container = document.getElementById('toastContainer');
    if (!container) return;
    const toast = document.createElement('div');
    const bg = type === 'success' ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-400' : 'bg-red-500/10 border-red-500/30 text-red-400';
    const icon = type === 'success' ? 'check-circle' : 'alert-circle';

    toast.className = `toast px-4 py-3 rounded-xl border text-xs font-medium shadow-2xl backdrop-blur-md flex items-center gap-2 ${bg}`;
    toast.innerHTML = `<i data-lucide="${icon}" class="w-4 h-4"></i> <span>${message}</span>`;
    container.appendChild(toast);
    safeRenderIcons();

    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateX(100%)';
        toast.style.transition = 'all 0.3s ease';
        setTimeout(() => toast.remove(), 300);
    }, 3200);
}

// Authenticated API request helper
async function apiRequest(endpoint, options = {}) {
    const headers = options.headers || {};
    if (adminToken) {
        headers['Authorization'] = `Bearer ${adminToken}`;
    }
    headers['Content-Type'] = 'application/json';

    const fullUrl = endpoint.startsWith('http') ? endpoint : `${API_BASE}${endpoint}`;

    try {
        const res = await fetch(fullUrl, { ...options, headers });
        if (res.status === 401) {
            localStorage.removeItem('hub_admin_token');
            adminToken = '';
            showLoginModal();
            throw new Error('Session expired');
        }
        return await res.json();
    } catch (err) {
        console.error('API Error:', err);
        throw err;
    }
}

// Show/Hide Login Modal
function showLoginModal() {
    document.getElementById('loginModal').classList.remove('hidden');
    document.getElementById('authBadge').classList.add('hidden');
    document.getElementById('authBadge').classList.remove('flex');
    document.getElementById('logoutBtn').classList.add('hidden');
    document.getElementById('logoutBtn').classList.remove('flex');
}

function hideLoginModal() {
    document.getElementById('loginModal').classList.add('hidden');
    document.getElementById('authBadge').classList.remove('hidden');
    document.getElementById('authBadge').classList.add('flex');
    document.getElementById('logoutBtn').classList.remove('hidden');
    document.getElementById('logoutBtn').classList.add('flex');
}

// Initialize and Load Data
async function initDashboard() {
    if (!adminToken) {
        showLoginModal();
        return;
    }

    hideLoginModal();
    await Promise.all([
        loadStats(),
        loadKeys(),
        loadWhitelist(),
        loadLogs(),
        loadGetkeySettings(),
        loadGetkeySessions()
    ]);
    renderLuaSnippet();
}

// Stats
async function loadStats() {
    try {
        const res = await apiRequest('/api/v1/admin/stats');
        if (res.success) {
            document.getElementById('statTotalKeys').textContent = res.stats.totalKeys;
            document.getElementById('statActiveKeys').textContent = res.stats.activeKeys;
            document.getElementById('statBoundKeys').textContent = res.stats.boundKeys;
            document.getElementById('statTotalWhitelist').textContent = res.stats.totalWhitelist;
            if (res.hubName) {
                document.getElementById('navHubName').textContent = res.hubName;
            }
        }
    } catch (e) {}
}

// Load Keys
async function loadKeys() {
    const tbody = document.getElementById('keysTableBody');
    try {
        const res = await apiRequest('/api/v1/admin/keys');
        if (res.success) {
            allKeysCache = res.keys;
            document.getElementById('keysCountBadge').textContent = res.keys.length;
            renderKeysTable(res.keys);
        }
    } catch (e) {
        tbody.innerHTML = `<tr><td colspan="7" class="px-4 py-8 text-center text-red-400">Failed to load keys</td></tr>`;
    }
}

function renderKeysTable(keys) {
    const tbody = document.getElementById('keysTableBody');
    if (!keys || keys.length === 0) {
        tbody.innerHTML = `<tr><td colspan="7" class="px-4 py-8 text-center text-gray-500">No license keys found. Generate one above!</td></tr>`;
        return;
    }

    tbody.innerHTML = keys.map(k => {
        const now = Math.floor(Date.now() / 1000);
        const isExpired = k.expires_at && now > k.expires_at;

        let statusBadge = '';
        if (!k.is_active) {
            statusBadge = '<span class="px-2 py-0.5 rounded-full bg-red-500/10 text-red-400 border border-red-500/20 text-[10px]">Suspended</span>';
        } else if (isExpired) {
            statusBadge = '<span class="px-2 py-0.5 rounded-full bg-yellow-500/10 text-yellow-400 border border-yellow-500/20 text-[10px]">Expired</span>';
        } else if (k.hwid) {
            statusBadge = '<span class="px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-[10px]">Active (Used)</span>';
        } else {
            statusBadge = '<span class="px-2 py-0.5 rounded-full bg-cyan-500/10 text-cyan-400 border border-cyan-500/20 text-[10px]">Unclaimed</span>';
        }

        const hwidDisplay = k.hwid
            ? `<div class="flex items-center gap-1 font-mono text-[11px] text-cyan-400">
                 <span>${k.hwid.substring(0, 10)}...</span>
                 <button onclick="resetHwid(${k.id})" title="Reset HWID" class="p-1 hover:text-white"><i data-lucide="rotate-ccw" class="w-3 h-3"></i></button>
               </div>`
            : '<span class="text-gray-500 italic">None (Unbound)</span>';

        const expiresDisplay = k.expires_at
            ? new Date(k.expires_at * 1000).toLocaleString('th-TH', { dateStyle: 'short', timeStyle: 'short' })
            : (k.duration_seconds === 0 ? '<span class="text-purple-400 font-semibold">Never (Lifetime)</span>' : '<span class="text-gray-500">Upon Activation</span>');

        return `
            <tr class="hover:bg-[#16161d] transition">
                <td class="px-4 py-3 font-mono font-medium text-white flex items-center gap-2">
                    <span>${k.key_string}</span>
                    <button onclick="copyToClipboard('${k.key_string}')" class="text-gray-500 hover:text-purple-400 transition" title="Copy Key">
                        <i data-lucide="copy" class="w-3.5 h-3.5"></i>
                    </button>
                </td>
                <td class="px-4 py-3 font-semibold text-purple-300">${k.key_type}</td>
                <td class="px-4 py-3">${hwidDisplay}</td>
                <td class="px-4 py-3">${k.claimed_by || '<span class="text-gray-500">-</span>'}</td>
                <td class="px-4 py-3 text-gray-400">${expiresDisplay}</td>
                <td class="px-4 py-3">${statusBadge}</td>
                <td class="px-4 py-3 text-right space-x-1">
                    <button onclick="toggleKey(${k.id}, ${k.is_active ? 0 : 1})" class="p-1.5 rounded-lg border border-brand-border text-gray-400 hover:text-yellow-400 transition" title="${k.is_active ? 'Suspend Key' : 'Activate Key'}">
                        <i data-lucide="${k.is_active ? 'pause' : 'play'}" class="w-3.5 h-3.5"></i>
                    </button>
                    <button onclick="deleteKey(${k.id})" class="p-1.5 rounded-lg border border-brand-border text-gray-400 hover:text-red-400 transition" title="Delete Key">
                        <i data-lucide="trash-2" class="w-3.5 h-3.5"></i>
                    </button>
                </td>
            </tr>
        `;
    }).join('');

    safeRenderIcons();
}

// Load Whitelist
async function loadWhitelist() {
    const tbody = document.getElementById('whitelistTableBody');
    try {
        const res = await apiRequest('/api/v1/admin/whitelist');
        if (res.success) {
            document.getElementById('whitelistCountBadge').textContent = res.users.length;
            renderWhitelistTable(res.users);
        }
    } catch (e) {
        tbody.innerHTML = `<tr><td colspan="5" class="px-4 py-8 text-center text-red-400">Failed to load whitelist</td></tr>`;
    }
}

function renderWhitelistTable(users) {
    const tbody = document.getElementById('whitelistTableBody');
    if (!users || users.length === 0) {
        tbody.innerHTML = `<tr><td colspan="5" class="px-4 py-8 text-center text-gray-500">No whitelisted Roblox users. Add one above!</td></tr>`;
        return;
    }

    tbody.innerHTML = users.map(u => {
        const dateStr = new Date(u.created_at * 1000).toLocaleDateString('th-TH');
        return `
            <tr class="hover:bg-[#16161d] transition">
                <td class="px-4 py-3 font-mono font-medium text-pink-300">${u.roblox_user_id}</td>
                <td class="px-4 py-3 text-white font-medium">${u.username || '<span class="text-gray-500">Not specified</span>'}</td>
                <td class="px-4 py-3">
                    <span class="px-2 py-0.5 rounded-full bg-pink-500/10 text-pink-400 border border-pink-500/20 text-[10px] font-semibold">${u.role}</span>
                </td>
                <td class="px-4 py-3 text-gray-400">${dateStr}</td>
                <td class="px-4 py-3 text-right">
                    <button onclick="deleteWhitelistUser(${u.id})" class="p-1.5 rounded-lg border border-brand-border text-gray-400 hover:text-red-400 transition" title="Remove User">
                        <i data-lucide="trash-2" class="w-3.5 h-3.5"></i>
                    </button>
                </td>
            </tr>
        `;
    }).join('');

    safeRenderIcons();
}

// Load Logs
async function loadLogs() {
    const tbody = document.getElementById('logsTableBody');
    try {
        const res = await apiRequest('/api/v1/admin/logs?limit=50');
        if (res.success) {
            renderLogsTable(res.logs);
        }
    } catch (e) {
        tbody.innerHTML = `<tr><td colspan="6" class="px-4 py-8 text-center text-red-400">Failed to load logs</td></tr>`;
    }
}

function renderLogsTable(logs) {
    const tbody = document.getElementById('logsTableBody');
    if (!logs || logs.length === 0) {
        tbody.innerHTML = `<tr><td colspan="6" class="px-4 py-8 text-center text-gray-500">No access logs recorded yet.</td></tr>`;
        return;
    }

    tbody.innerHTML = logs.map(l => {
        const time = new Date(l.timestamp * 1000).toLocaleTimeString('th-TH');
        let badgeClass = 'bg-gray-500/10 text-gray-400 border-gray-500/20';
        if (l.status === 'SUCCESS' || l.status === 'WHITELIST_BYPASS') {
            badgeClass = 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20';
        } else if (l.status === 'HWID_MISMATCH') {
            badgeClass = 'bg-yellow-500/10 text-yellow-400 border-yellow-500/20';
        } else {
            badgeClass = 'bg-red-500/10 text-red-400 border-red-500/20';
        }

        return `
            <tr class="hover:bg-[#16161d] transition font-mono text-[11px]">
                <td class="px-4 py-2.5 text-gray-400">${time}</td>
                <td class="px-4 py-2.5">
                    <span class="px-2 py-0.5 rounded-full border text-[10px] ${badgeClass}">${l.status}</span>
                </td>
                <td class="px-4 py-2.5 text-white">${l.username || l.roblox_user_id || '-'}</td>
                <td class="px-4 py-2.5 text-purple-300">${l.key_string || '-'}</td>
                <td class="px-4 py-2.5 text-gray-400">${l.hwid ? l.hwid.substring(0, 10) + '...' : (l.ip_address || '-')}</td>
                <td class="px-4 py-2.5 text-gray-300 font-sans">${l.message}</td>
            </tr>
        `;
    }).join('');

    safeRenderIcons();
}

// Actions
window.copyToClipboard = function(text) {
    navigator.clipboard.writeText(text);
    showToast(`Key copied to clipboard: ${text}`);
};

window.resetHwid = async function(id) {
    if (!confirm('Are you sure you want to reset HWID for this key?')) return;
    try {
        const res = await apiRequest('/api/v1/admin/keys/reset-hwid', {
            method: 'POST',
            body: JSON.stringify({ id })
        });
        if (res.success) {
            showToast('HWID reset successfully!');
            loadKeys();
            loadStats();
        }
    } catch (e) {
        showToast('Failed to reset HWID', 'error');
    }
};

window.toggleKey = async function(id, isActive) {
    try {
        const res = await apiRequest('/api/v1/admin/keys/toggle', {
            method: 'POST',
            body: JSON.stringify({ id, isActive: !!isActive })
        });
        if (res.success) {
            showToast(res.message);
            loadKeys();
            loadStats();
        }
    } catch (e) {
        showToast('Failed to toggle key status', 'error');
    }
};

window.deleteKey = async function(id) {
    if (!confirm('Are you sure you want to permanently delete this key?')) return;
    try {
        const res = await apiRequest(`/api/v1/admin/keys/${id}`, { method: 'DELETE' });
        if (res.success) {
            showToast('Key deleted');
            loadKeys();
            loadStats();
        }
    } catch (e) {
        showToast('Failed to delete key', 'error');
    }
};

window.deleteWhitelistUser = async function(id) {
    if (!confirm('Remove this player from the whitelist?')) return;
    try {
        const res = await apiRequest(`/api/v1/admin/whitelist/${id}`, { method: 'DELETE' });
        if (res.success) {
            showToast('Player removed from whitelist');
            loadWhitelist();
            loadStats();
        }
    } catch (e) {
        showToast('Failed to remove player', 'error');
    }
};

// Form: Generate Keys
document.getElementById('generateKeyForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const prefix = document.getElementById('genPrefix').value;
    const type = document.getElementById('genType').value;
    const count = parseInt(document.getElementById('genCount').value) || 1;
    const note = document.getElementById('genNote').value;

    try {
        const res = await apiRequest('/api/v1/admin/keys/generate', {
            method: 'POST',
            body: JSON.stringify({ prefix, type, count, note })
        });

        if (res.success) {
            showToast(`Generated ${res.createdCount} new license key(s)!`);
            document.getElementById('genNote').value = '';
            loadKeys();
            loadStats();
        }
    } catch (e) {
        showToast('Failed to generate keys', 'error');
    }
});

// Form: Add Whitelist
document.getElementById('addWhitelistForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const robloxUserId = document.getElementById('wlUserId').value;
    const username = document.getElementById('wlUsername').value;
    const role = document.getElementById('wlRole').value;

    try {
        const res = await apiRequest('/api/v1/admin/whitelist/add', {
            method: 'POST',
            body: JSON.stringify({ robloxUserId, username, role })
        });

        if (res.success) {
            showToast('Player whitelisted successfully!');
            document.getElementById('wlUserId').value = '';
            document.getElementById('wlUsername').value = '';
            loadWhitelist();
            loadStats();
        }
    } catch (e) {
        showToast('Failed to whitelist player', 'error');
    }
});

// Search filter
document.getElementById('searchKeyInput').addEventListener('input', (e) => {
    const q = e.target.value.toLowerCase().trim();
    if (!q) {
        renderKeysTable(allKeysCache);
        return;
    }
    const filtered = allKeysCache.filter(k =>
        k.key_string.toLowerCase().includes(q) ||
        (k.claimed_by && k.claimed_by.toLowerCase().includes(q)) ||
        (k.note && k.note.toLowerCase().includes(q))
    );
    renderKeysTable(filtered);
});

// Tab Switcher
document.querySelectorAll('.nav-tab').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.nav-tab').forEach(b => {
            b.classList.remove('active-tab');
            b.classList.add('text-gray-400', 'border-transparent');
        });
        btn.classList.add('active-tab');
        btn.classList.remove('text-gray-400', 'border-transparent');

        const target = btn.dataset.target;
        document.querySelectorAll('.tab-pane').forEach(p => p.classList.add('hidden'));
        document.getElementById(target).classList.remove('hidden');
    });
});

// Login Form Submit
document.getElementById('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const password = document.getElementById('adminPasswordInput').value;
    const errEl = document.getElementById('loginError');
    errEl.classList.add('hidden');

    try {
        const res = await fetch(API_BASE + '/api/v1/admin/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ password })
        });
        const data = await res.json();
        if (data.success) {
            adminToken = data.token;
            localStorage.setItem('hub_admin_token', adminToken);
            document.getElementById('adminPasswordInput').value = '';
            showToast('Welcome to Hub Whitelist Admin Panel!');
            initDashboard();
        } else {
            errEl.textContent = data.error || 'Password incorrect';
            errEl.classList.remove('hidden');
        }
    } catch (err) {
        errEl.textContent = 'Server connection error';
        errEl.classList.remove('hidden');
    }
});

// Logout
document.getElementById('logoutBtn').addEventListener('click', () => {
    adminToken = '';
    localStorage.removeItem('hub_admin_token');
    showLoginModal();
    showToast('Logged out of admin panel');
});

// Refresh buttons
document.getElementById('refreshKeysBtn').addEventListener('click', () => { loadKeys(); loadStats(); });
document.getElementById('refreshLogsBtn').addEventListener('click', () => loadLogs());

// Render Luau Integration Code
function renderLuaSnippet() {
    const host = (window.location.protocol === 'file:' || !window.location.host)
        ? 'http://localhost:3000'
        : window.location.origin;

    const snippet = `-- ==============================================================================
-- 👑 UNIVERSAL ALL-IN-ONE LOADSTRING (RUN THIS IN ANY EXECUTOR)
-- Supports: Anime Galaxies | Hunting Together | Blue Lock Farm
-- Auto-Detects Current Map + Protected by Key System & Direct Whitelist
-- ==============================================================================

-- 🌐 Option 1: Official GitHub Raw (แจกให้คนอื่นรันได้เลย):
loadstring(game:HttpGet("https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/loader.luau"))()

-- ⚡ Option 2: Direct Server Endpoint:
-- loadstring(game:HttpGet("${host}/loader.luau"))()

-- ==============================================================================
-- 💡 HOW IT WORKS:
-- 1. Executes universal authentication via ${host}
-- 2. Checks Direct Whitelist (Roblox UserID) or Locally Cached Key
-- 3. If no key, displays the modern Key Verification Dialog
-- 4. Automatically detects which game you are currently playing:
--    • Anime Galaxies (Lobby & Match Acts) -> Loads Anime Galaxies Hub
--    • Hunting Together (Fields & Dungeons) -> Loads Hunting Together Hub
--    • Blue Lock Farm (Auto Obby, Polisher) -> Loads Blue Lock Farm Hub
-- ==============================================================================`;

    document.getElementById('luaCodeSnippet').textContent = snippet;
}

document.getElementById('copyLuaCodeBtn').addEventListener('click', () => {
    const code = document.getElementById('luaCodeSnippet').textContent;
    navigator.clipboard.writeText(code);
    showToast('Luau Integration snippet copied to clipboard!');
});

// ==============================================================================
// GET KEY & MONETIZATION SETTINGS
// ==============================================================================

async function loadGetkeySettings() {
    try {
        const previewEl = document.getElementById('monetizeUrlPreview');
        if (previewEl) {
            const host = (window.location.protocol === 'file:' || !window.location.host) ? 'http://localhost:3000' : window.location.origin;
            previewEl.textContent = `${host}/getkey`;
        }

        const res = await apiRequest('/api/v1/admin/getkey/settings');
        if (res.success && res.settings) {
            const s = res.settings;
            if (document.getElementById('cfgGetkeyEnabled')) document.getElementById('cfgGetkeyEnabled').checked = !!s.enabled;
            if (document.getElementById('cfgGetkeyMode')) document.getElementById('cfgGetkeyMode').value = s.mode || 'dual';
            if (document.getElementById('cfgGetkeySteps')) document.getElementById('cfgGetkeySteps').value = String(s.steps || 2);
            if (document.getElementById('cfgGetkeyDuration')) document.getElementById('cfgGetkeyDuration').value = s.durationHours || 24;
            if (document.getElementById('cfgLinkvertiseId')) document.getElementById('cfgLinkvertiseId').value = s.linkvertiseUserId || '';
            if (document.getElementById('cfgLootlabsKey')) document.getElementById('cfgLootlabsKey').value = s.lootlabsApiKey || '';
            if (document.getElementById('cfgLootlabsTier')) document.getElementById('cfgLootlabsTier').value = String(s.lootlabsTierId || 1);
            if (document.getElementById('cfgLootlabsTasks')) document.getElementById('cfgLootlabsTasks').value = String(s.lootlabsTasks || 2);
        }
    } catch (e) {
        console.error('Failed to load getkey settings:', e);
    }
}

async function saveGetkeySettings(e) {
    if (e) e.preventDefault();
    const btn = document.getElementById('saveGetkeySettingsBtn');
    const originalText = btn.innerHTML;
    btn.innerHTML = '<i data-lucide="loader-2" class="w-4 h-4 animate-spin"></i> Saving...';
    btn.disabled = true;

    try {
        const payload = {
            enabled: document.getElementById('cfgGetkeyEnabled').checked,
            mode: document.getElementById('cfgGetkeyMode').value,
            steps: parseInt(document.getElementById('cfgGetkeySteps').value) || 2,
            durationHours: parseInt(document.getElementById('cfgGetkeyDuration').value) || 24,
            linkvertiseUserId: document.getElementById('cfgLinkvertiseId').value.trim(),
            lootlabsApiKey: document.getElementById('cfgLootlabsKey').value.trim(),
            lootlabsTierId: parseInt(document.getElementById('cfgLootlabsTier').value) || 1,
            lootlabsTasks: parseInt(document.getElementById('cfgLootlabsTasks').value) || 2
        };

        const res = await apiRequest('/api/v1/admin/getkey/settings', {
            method: 'POST',
            body: JSON.stringify(payload)
        });

        if (res.success) {
            showToast('Monetization settings saved successfully!', 'success');
        } else {
            showToast(res.error || 'Failed to save settings', 'error');
        }
    } catch (err) {
        showToast('Error connecting to server', 'error');
    } finally {
        btn.innerHTML = originalText;
        btn.disabled = false;
        safeRenderIcons();
    }
}

async function loadGetkeySessions() {
    const tbody = document.getElementById('sessionsTableBody');
    if (!tbody) return;

    try {
        const res = await apiRequest('/api/v1/admin/getkey/sessions');
        if (!res.success || !res.sessions || res.sessions.length === 0) {
            tbody.innerHTML = `<tr><td colspan="8" class="p-6 text-center text-gray-500">No checkpoint sessions recorded yet</td></tr>`;
            return;
        }

        tbody.innerHTML = res.sessions.map(s => {
            const statusBadge = s.status === 'completed'
                ? `<span class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">Completed</span>`
                : s.status === 'active'
                ? `<span class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-cyan-500/20 text-cyan-400 border border-cyan-500/30">In Progress</span>`
                : `<span class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-gray-500/20 text-gray-400 border border-gray-500/30">${s.status}</span>`;

            const providerBadge = s.provider === 'dual'
                ? `<span class="text-[10px] font-bold text-amber-300 bg-amber-500/10 px-2 py-0.5 rounded border border-amber-500/20">Loot + Linkv</span>`
                : s.provider === 'lootlabs'
                ? `<span class="text-[10px] font-bold text-purple-300 bg-purple-500/10 px-2 py-0.5 rounded border border-purple-500/20">LootLabs</span>`
                : `<span class="text-[10px] font-bold text-cyan-300 bg-cyan-500/10 px-2 py-0.5 rounded border border-cyan-500/20">Linkvertise</span>`;

            const keyDisplay = s.claimed_key
                ? `<div class="flex items-center gap-1.5"><code class="text-[11px] font-mono text-emerald-300">${s.claimed_key}</code><button onclick="navigator.clipboard.writeText('${s.claimed_key}'); showToast('Key copied!', 'success');" class="text-gray-400 hover:text-white"><i data-lucide="copy" class="w-3 h-3"></i></button></div>`
                : `<span class="text-gray-500">-</span>`;

            const hwidDisplay = s.hwid
                ? `<span title="${s.hwid}" class="font-mono text-[11px] text-gray-400">${s.hwid.length > 14 ? s.hwid.slice(0, 14) + '...' : s.hwid}</span>`
                : `<span class="text-gray-500">-</span>`;

            const dateStr = s.created_at ? new Date(s.created_at).toLocaleString() : '-';

            return `
                <tr class="hover:bg-white/[0.02] transition">
                    <td class="p-3 font-mono text-[11px] text-gray-400">${s.id.slice(0, 8)}...</td>
                    <td class="p-3 text-gray-300 font-mono text-[11px]">${s.ip_address || '-'}</td>
                    <td class="p-3">${hwidDisplay}</td>
                    <td class="p-3">${providerBadge}</td>
                    <td class="p-3 font-bold text-white text-[11px]">Step ${s.step_completed} / ${s.total_steps}</td>
                    <td class="p-3">${statusBadge}</td>
                    <td class="p-3">${keyDisplay}</td>
                    <td class="p-3 text-gray-400 text-[11px]">${dateStr}</td>
                </tr>
            `;
        }).join('');

        safeRenderIcons();
    } catch (e) {
        tbody.innerHTML = `<tr><td colspan="8" class="p-4 text-center text-red-400">Failed to load sessions</td></tr>`;
    }
}

if (document.getElementById('getkeySettingsForm')) {
    document.getElementById('getkeySettingsForm').addEventListener('submit', saveGetkeySettings);
}
if (document.getElementById('refreshSessionsBtn')) {
    document.getElementById('refreshSessionsBtn').addEventListener('click', loadGetkeySessions);
}

// Run
window.addEventListener('DOMContentLoaded', () => {
    safeRenderIcons();
    initDashboard();
});



