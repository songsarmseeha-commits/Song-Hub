// ==============================================================================
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
const INDEX_HTML = "<!DOCTYPE html>\n<html lang=\"en\" class=\"dark\">\n<head>\n    <meta charset=\"UTF-8\">\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n    <title>Anime Galaxies Hub | Whitelist & Key System</title>\n    <!-- Tailwind CSS CDN -->\n    <script src=\"https://cdn.tailwindcss.com\"></script>\n    <script>\n        tailwind.config = {\n            darkMode: 'class',\n            theme: {\n                extend: {\n                    colors: {\n                        brand: {\n                            purple: '#8b5cf6',\n                            pink: '#ec4899',\n                            cyan: '#06b6d4',\n                            dark: '#09090b',\n                            card: '#121217',\n                            border: '#27272a'\n                        }\n                    }\n                }\n            }\n        }\n    </script>\n    <!-- Lucide Icons -->\n    <script src=\"https://unpkg.com/lucide@latest\"></script>\n    <style>/* Custom Glassmorphism & Animations */\n::-webkit-scrollbar {\n    width: 6px;\n    height: 6px;\n}\n\n::-webkit-scrollbar-track {\n    background: #09090b;\n}\n\n::-webkit-scrollbar-thumb {\n    background: #27272a;\n    border-radius: 9999px;\n}\n\n::-webkit-scrollbar-thumb:hover {\n    background: #3f3f46;\n}\n\n.active-tab {\n    border-color: #8b5cf6 !important;\n    color: #ffffff !important;\n}\n\n/* Toast animation */\n@keyframes slideIn {\n    from {\n        transform: translateX(100%);\n        opacity: 0;\n    }\n    to {\n        transform: translateX(0);\n        opacity: 1;\n    }\n}\n\n.toast {\n    animation: slideIn 0.25s cubic-bezier(0.16, 1, 0.3, 1) forwards;\n}\n\n</style>\n</head>\n<body class=\"bg-[#09090b] text-gray-100 min-h-screen flex flex-col font-sans selection:bg-purple-500 selection:text-white\">\n\n    <!-- TOP NAVIGATION BAR -->\n    <header class=\"border-b border-brand-border bg-[#0d0d12]/80 backdrop-blur sticky top-0 z-40\">\n        <div class=\"max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between\">\n            <div class=\"flex items-center space-x-3\">\n                <div class=\"w-10 h-10 rounded-xl bg-gradient-to-tr from-purple-600 via-pink-500 to-cyan-400 p-[2px] shadow-lg shadow-purple-500/20\">\n                    <div class=\"w-full h-full bg-[#09090b] rounded-[10px] flex items-center justify-center\">\n                        <i data-lucide=\"shield-check\" class=\"w-5 h-5 text-purple-400\"></i>\n                    </div>\n                </div>\n                <div>\n                    <h1 class=\"text-lg font-bold bg-gradient-to-r from-purple-400 via-pink-400 to-cyan-400 bg-clip-text text-transparent\" id=\"navHubName\">\n                        Anime Galaxies Hub\n                    </h1>\n                    <p class=\"text-xs text-gray-400\">Whitelist & License Management Portal</p>\n                </div>\n            </div>\n\n            <!-- Header Right Menu -->\n            <div class=\"flex items-center space-x-3\">\n                <a href=\"https://discord.gg/Cpcg9wU5k\" target=\"_blank\" class=\"px-3 py-1.5 rounded-lg bg-indigo-500/10 hover:bg-indigo-500/20 text-indigo-300 font-semibold border border-indigo-500/20 text-xs flex items-center gap-1.5 transition\">\n                    <i data-lucide=\"message-square\" class=\"w-3.5 h-3.5\"></i> Discord\n                </a>\n                <span id=\"authBadge\" class=\"hidden text-xs px-2.5 py-1 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 items-center gap-1.5\">\n                    <span class=\"w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse\"></span> Admin Connected\n                </span>\n                <button id=\"logoutBtn\" class=\"hidden text-xs px-3 py-1.5 rounded-lg border border-red-500/20 text-red-400 hover:bg-red-500/10 transition flex items-center gap-1.5\">\n                    <i data-lucide=\"log-out\" class=\"w-3.5 h-3.5\"></i> Logout\n                </button>\n            </div>\n        </div>\n    </header>\n\n    <!-- LOGIN MODAL (OVERLAY WHEN NOT AUTHENTICATED) -->\n    <div id=\"loginModal\" class=\"fixed inset-0 bg-black/80 backdrop-blur-md z-50 flex items-center justify-center p-4\">\n        <div class=\"bg-[#121217] border border-brand-border rounded-2xl p-6 sm:p-8 max-w-md w-full shadow-2xl relative overflow-hidden\">\n            <div class=\"absolute -top-24 -right-24 w-48 h-48 bg-purple-600/20 rounded-full blur-3xl pointer-events-none\"></div>\n            <div class=\"absolute -bottom-24 -left-24 w-48 h-48 bg-pink-600/20 rounded-full blur-3xl pointer-events-none\"></div>\n\n            <div class=\"text-center mb-6\">\n                <div class=\"w-14 h-14 mx-auto mb-3 rounded-2xl bg-purple-500/10 border border-purple-500/20 flex items-center justify-center\">\n                    <i data-lucide=\"lock\" class=\"w-7 h-7 text-purple-400\"></i>\n                </div>\n                <h2 class=\"text-xl font-bold text-white\">Administrator Access</h2>\n                <p class=\"text-xs text-gray-400 mt-1\">Please enter your master password to access the panel</p>\n            </div>\n\n            <form id=\"loginForm\" class=\"space-y-4\">\n                <div>\n                    <label class=\"block text-xs font-medium text-gray-300 mb-1.5\">Admin Password</label>\n                    <div class=\"relative\">\n                        <input type=\"password\" id=\"adminPasswordInput\" placeholder=\"••••••••\" required\n                            class=\"w-full px-4 py-2.5 bg-[#18181f] border border-brand-border rounded-xl text-sm focus:outline-none focus:border-purple-500 focus:ring-1 focus:ring-purple-500 text-white placeholder-gray-500 transition\">\n                        <i data-lucide=\"key\" class=\"w-4 h-4 text-gray-500 absolute right-3.5 top-3\"></i>\n                    </div>\n                </div>\n\n                <div id=\"loginError\" class=\"hidden text-xs text-red-400 bg-red-500/10 border border-red-500/20 rounded-lg p-2.5 text-center\"></div>\n\n                <button type=\"submit\" class=\"w-full py-2.5 rounded-xl font-medium text-sm text-white bg-gradient-to-r from-purple-600 via-pink-600 to-purple-600 hover:opacity-95 transition shadow-lg shadow-purple-600/25 flex items-center justify-center gap-2\">\n                    <span>Unlock Dashboard</span>\n                    <i data-lucide=\"arrow-right\" class=\"w-4 h-4\"></i>\n                </button>\n            </form>\n        </div>\n    </div>\n\n    <!-- MAIN DASHBOARD CONTENT -->\n    <main class=\"flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8\">\n\n        <!-- TOP STATS CARDS -->\n        <div class=\"grid grid-cols-2 md:grid-cols-4 gap-4\">\n            <!-- Stat 1 -->\n            <div class=\"bg-brand-card border border-brand-border rounded-2xl p-4 sm:p-5 relative overflow-hidden group hover:border-purple-500/40 transition\">\n                <div class=\"flex items-center justify-between mb-2\">\n                    <span class=\"text-xs font-medium text-gray-400\">Total Keys</span>\n                    <span class=\"p-2 rounded-xl bg-purple-500/10 text-purple-400 border border-purple-500/20\"><i data-lucide=\"key\" class=\"w-4 h-4\"></i></span>\n                </div>\n                <div class=\"text-2xl font-bold text-white\" id=\"statTotalKeys\">0</div>\n                <div class=\"text-[11px] text-gray-500 mt-1\">Generated licenses</div>\n            </div>\n\n            <!-- Stat 2 -->\n            <div class=\"bg-brand-card border border-brand-border rounded-2xl p-4 sm:p-5 relative overflow-hidden group hover:border-emerald-500/40 transition\">\n                <div class=\"flex items-center justify-between mb-2\">\n                    <span class=\"text-xs font-medium text-gray-400\">Active Keys</span>\n                    <span class=\"p-2 rounded-xl bg-emerald-500/10 text-emerald-400 border border-emerald-500/20\"><i data-lucide=\"check-circle\" class=\"w-4 h-4\"></i></span>\n                </div>\n                <div class=\"text-2xl font-bold text-emerald-400\" id=\"statActiveKeys\">0</div>\n                <div class=\"text-[11px] text-gray-500 mt-1\">Unrevoked & usable</div>\n            </div>\n\n            <!-- Stat 3 -->\n            <div class=\"bg-brand-card border border-brand-border rounded-2xl p-4 sm:p-5 relative overflow-hidden group hover:border-cyan-500/40 transition\">\n                <div class=\"flex items-center justify-between mb-2\">\n                    <span class=\"text-xs font-medium text-gray-400\">HWID Bound</span>\n                    <span class=\"p-2 rounded-xl bg-cyan-500/10 text-cyan-400 border border-cyan-500/20\"><i data-lucide=\"cpu\" class=\"w-4 h-4\"></i></span>\n                </div>\n                <div class=\"text-2xl font-bold text-cyan-400\" id=\"statBoundKeys\">0</div>\n                <div class=\"text-[11px] text-gray-500 mt-1\">Linked to devices</div>\n            </div>\n\n            <!-- Stat 4 -->\n            <div class=\"bg-brand-card border border-brand-border rounded-2xl p-4 sm:p-5 relative overflow-hidden group hover:border-pink-500/40 transition\">\n                <div class=\"flex items-center justify-between mb-2\">\n                    <span class=\"text-xs font-medium text-gray-400\">Direct Whitelist</span>\n                    <span class=\"p-2 rounded-xl bg-pink-500/10 text-pink-400 border border-pink-500/20\"><i data-lucide=\"user-check\" class=\"w-4 h-4\"></i></span>\n                </div>\n                <div class=\"text-2xl font-bold text-pink-400\" id=\"statTotalWhitelist\">0</div>\n                <div class=\"text-[11px] text-gray-500 mt-1\">Roblox VIP/Owner bypass</div>\n            </div>\n        </div>\n\n        <!-- NAVIGATION TABS -->\n        <div class=\"border-b border-brand-border flex space-x-2 sm:space-x-4 overflow-x-auto pb-1 text-sm font-medium\">\n            <button class=\"nav-tab active-tab flex items-center gap-2 px-4 py-2.5 border-b-2 font-semibold transition\" data-target=\"tab-keys\">\n                <i data-lucide=\"key-round\" class=\"w-4 h-4\"></i> Key System & Generator\n            </button>\n            <button class=\"nav-tab text-gray-400 hover:text-white flex items-center gap-2 px-4 py-2.5 border-b-2 border-transparent transition\" data-target=\"tab-whitelist\">\n                <i data-lucide=\"shield-alert\" class=\"w-4 h-4\"></i> Direct Whitelist (VIP)\n            </button>\n            <button class=\"nav-tab text-gray-400 hover:text-white flex items-center gap-2 px-4 py-2.5 border-b-2 border-transparent transition\" data-target=\"tab-logs\">\n                <i data-lucide=\"scroll-text\" class=\"w-4 h-4\"></i> Verification Logs\n            </button>\n            <button class=\"nav-tab text-gray-400 hover:text-white flex items-center gap-2 px-4 py-2.5 border-b-2 border-transparent transition\" data-target=\"tab-integration\">\n                <i data-lucide=\"code-2\" class=\"w-4 h-4\"></i> Luau Integration Code\n            </button>\n            <button class=\"nav-tab text-gray-400 hover:text-white flex items-center gap-2 px-4 py-2.5 border-b-2 border-transparent transition\" data-target=\"tab-monetization\">\n                <i data-lucide=\"circle-dollar-sign\" class=\"w-4 h-4 text-emerald-400\"></i> Get Key & Monetization\n            </button>\n            <button class=\"nav-tab text-gray-400 hover:text-white flex items-center gap-2 px-4 py-2.5 border-b-2 border-transparent transition\" data-target=\"tab-backup\">\n                <i data-lucide=\"cloud\" class=\"w-4 h-4 text-cyan-400\"></i> Database Backup & Cloud\n            </button>\n        </div>\n\n        <!-- ================================================================== -->\n        <!-- TAB 1: KEY MANAGEMENT & GENERATOR -->\n        <!-- ================================================================== -->\n        <div id=\"tab-keys\" class=\"tab-pane space-y-6\">\n\n            <!-- GENERATOR & ACTIONS BAR -->\n            <div class=\"bg-brand-card border border-brand-border rounded-2xl p-5 sm:p-6 shadow-xl space-y-4\">\n                <div class=\"flex flex-col sm:flex-row sm:items-center justify-between gap-4\">\n                    <div>\n                        <h3 class=\"text-base font-bold text-white flex items-center gap-2\">\n                            <i data-lucide=\"plus-circle\" class=\"w-5 h-5 text-purple-400\"></i> Generate License Keys\n                        </h3>\n                        <p class=\"text-xs text-gray-400 mt-0.5\">Create single or bulk keys with custom expiry and prefix</p>\n                    </div>\n                </div>\n\n                <form id=\"generateKeyForm\" class=\"grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-3 pt-2\">\n                    <div>\n                        <label class=\"block text-xs font-medium text-gray-400 mb-1\">Key Prefix</label>\n                        <input type=\"text\" id=\"genPrefix\" value=\"GALAXY\" placeholder=\"GALAXY\"\n                            class=\"w-full px-3 py-2 bg-[#18181f] border border-brand-border rounded-xl text-xs text-white uppercase focus:outline-none focus:border-purple-500\">\n                    </div>\n\n                    <div>\n                        <label class=\"block text-xs font-medium text-gray-400 mb-1\">Duration</label>\n                        <select id=\"genType\" class=\"w-full px-3 py-2 bg-[#18181f] border border-brand-border rounded-xl text-xs text-white focus:outline-none focus:border-purple-500\">\n                            <option value=\"24h\">24 Hours (Trial)</option>\n                            <option value=\"3d\">3 Days</option>\n                            <option value=\"7d\">7 Days (Standard)</option>\n                            <option value=\"30d\">30 Days (Monthly)</option>\n                            <option value=\"Lifetime\" selected>Lifetime (Permanent)</option>\n                        </select>\n                    </div>\n\n                    <div>\n                        <label class=\"block text-xs font-medium text-gray-400 mb-1 flex items-center justify-between\">\n                            <span>HWID Limit</span>\n                            <span class=\"text-[10px] text-cyan-400\">Devices</span>\n                        </label>\n                        <input type=\"number\" id=\"genMaxHwid\" value=\"1\" min=\"1\" max=\"50\" placeholder=\"1\"\n                            class=\"w-full px-3 py-2 bg-[#18181f] border border-brand-border rounded-xl text-xs text-white focus:outline-none focus:border-purple-500\" title=\"Max distinct hardware devices allowed\">\n                    </div>\n\n                    <div>\n                        <label class=\"block text-xs font-medium text-gray-400 mb-1 flex items-center justify-between\">\n                            <span>Session Limit</span>\n                            <span class=\"text-[10px] text-emerald-400\">Windows</span>\n                        </label>\n                        <input type=\"number\" id=\"genMaxSessions\" value=\"1\" min=\"1\" max=\"50\" placeholder=\"1\"\n                            class=\"w-full px-3 py-2 bg-[#18181f] border border-brand-border rounded-xl text-xs text-white focus:outline-none focus:border-purple-500\" title=\"Max concurrent Roblox game instances allowed\">\n                    </div>\n\n                    <div>\n                        <label class=\"block text-xs font-medium text-gray-400 mb-1\">Amount</label>\n                        <input type=\"number\" id=\"genCount\" value=\"1\" min=\"1\" max=\"50\"\n                            class=\"w-full px-3 py-2 bg-[#18181f] border border-brand-border rounded-xl text-xs text-white focus:outline-none focus:border-purple-500\">\n                    </div>\n\n                    <div>\n                        <label class=\"block text-xs font-medium text-gray-400 mb-1\">Note / Buyer</label>\n                        <input type=\"text\" id=\"genNote\" placeholder=\"Discord User / Buyer\"\n                            class=\"w-full px-3 py-2 bg-[#18181f] border border-brand-border rounded-xl text-xs text-white focus:outline-none focus:border-purple-500\">\n                    </div>\n\n                    <div class=\"flex items-end col-span-2 sm:col-span-1\">\n                        <button type=\"submit\" class=\"w-full py-2 bg-gradient-to-r from-purple-600 to-pink-600 hover:opacity-90 text-white font-medium text-xs rounded-xl shadow-lg shadow-purple-500/20 transition flex items-center justify-center gap-1.5 h-[36px]\">\n                            <i data-lucide=\"sparkles\" class=\"w-4 h-4\"></i> Generate Keys\n                        </button>\n                    </div>\n                </form>\n            </div>\n\n            <!-- KEYS TABLE -->\n            <div class=\"bg-brand-card border border-brand-border rounded-2xl overflow-hidden shadow-xl\">\n                <div class=\"p-4 sm:p-5 border-b border-brand-border flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3\">\n                    <div class=\"flex items-center gap-2\">\n                        <i data-lucide=\"database\" class=\"w-4 h-4 text-purple-400\"></i>\n                        <h4 class=\"text-sm font-bold text-white\">Issued License Keys</h4>\n                        <span id=\"keysCountBadge\" class=\"text-xs px-2 py-0.5 rounded-full bg-purple-500/10 text-purple-400 border border-purple-500/20\">0</span>\n                    </div>\n\n                    <div class=\"flex items-center gap-2\">\n                        <div class=\"relative flex-1 sm:w-64\">\n                            <input type=\"text\" id=\"searchKeyInput\" placeholder=\"Search key, user or note...\"\n                                class=\"w-full pl-8 pr-3 py-1.5 bg-[#18181f] border border-brand-border rounded-xl text-xs text-white placeholder-gray-500 focus:outline-none focus:border-purple-500\">\n                            <i data-lucide=\"search\" class=\"w-3.5 h-3.5 text-gray-500 absolute left-2.5 top-2.5\"></i>\n                        </div>\n                        <button id=\"refreshKeysBtn\" class=\"p-1.5 rounded-xl border border-brand-border text-gray-400 hover:text-white hover:bg-[#18181f] transition\">\n                            <i data-lucide=\"refresh-cw\" class=\"w-4 h-4\"></i>\n                        </button>\n                    </div>\n                </div>\n\n                <div class=\"overflow-x-auto\">\n                    <table class=\"w-full text-left text-xs text-gray-300\">\n                        <thead class=\"bg-[#18181f] text-gray-400 uppercase font-semibold text-[11px] border-b border-brand-border\">\n                            <tr>\n                                <th class=\"px-4 py-3\">License Key</th>\n                                <th class=\"px-4 py-3\">Type</th>\n                                <th class=\"px-4 py-3\">HWID Limit</th>\n                                <th class=\"px-4 py-3\">Sessions (Live)</th>\n                                <th class=\"px-4 py-3\">Claimed / Note</th>\n                                <th class=\"px-4 py-3\">Expires At</th>\n                                <th class=\"px-4 py-3\">Status</th>\n                                <th class=\"px-4 py-3 text-right\">Actions</th>\n                            </tr>\n                        </thead>\n                        <tbody id=\"keysTableBody\" class=\"divide-y divide-brand-border\">\n                            <tr>\n                                <td colspan=\"8\" class=\"px-4 py-8 text-center text-gray-500\">Loading keys...</td>\n                            </tr>\n                        </tbody>\n                    </table>\n                </div>\n            </div>\n        </div>\n\n        <!-- ================================================================== -->\n        <!-- TAB 2: DIRECT WHITELIST (VIP / STAFF) -->\n        <!-- ================================================================== -->\n        <div id=\"tab-whitelist\" class=\"tab-pane hidden space-y-6\">\n            <div class=\"bg-brand-card border border-brand-border rounded-2xl p-5 sm:p-6 shadow-xl space-y-4\">\n                <div>\n                    <h3 class=\"text-base font-bold text-white flex items-center gap-2\">\n                        <i data-lucide=\"user-plus\" class=\"w-5 h-5 text-pink-400\"></i> Add Direct Whitelisted User\n                    </h3>\n                    <p class=\"text-xs text-gray-400 mt-0.5\">Whitelisted players bypass the key prompt entirely and get instant access</p>\n                </div>\n\n                <form id=\"addWhitelistForm\" class=\"grid grid-cols-1 sm:grid-cols-4 gap-3 pt-2\">\n                    <div>\n                        <label class=\"block text-xs font-medium text-gray-400 mb-1\">Roblox UserID <span class=\"text-pink-400\">*</span></label>\n                        <input type=\"text\" id=\"wlUserId\" placeholder=\"e.g. 5183921820\" required\n                            class=\"w-full px-3 py-2 bg-[#18181f] border border-brand-border rounded-xl text-xs text-white focus:outline-none focus:border-pink-500\">\n                    </div>\n\n                    <div>\n                        <label class=\"block text-xs font-medium text-gray-400 mb-1\">Roblox Username</label>\n                        <input type=\"text\" id=\"wlUsername\" placeholder=\"e.g. Hood_u7\"\n                            class=\"w-full px-3 py-2 bg-[#18181f] border border-brand-border rounded-xl text-xs text-white focus:outline-none focus:border-pink-500\">\n                    </div>\n\n                    <div>\n                        <label class=\"block text-xs font-medium text-gray-400 mb-1\">Role / Rank</label>\n                        <select id=\"wlRole\" class=\"w-full px-3 py-2 bg-[#18181f] border border-brand-border rounded-xl text-xs text-white focus:outline-none focus:border-pink-500\">\n                            <option value=\"Owner\">Owner 👑</option>\n                            <option value=\"Admin\">Admin 🛡️</option>\n                            <option value=\"VIP\" selected>VIP ✨</option>\n                            <option value=\"Tester\">Beta Tester 🧪</option>\n                        </select>\n                    </div>\n\n                    <div class=\"flex items-end\">\n                        <button type=\"submit\" class=\"w-full py-2 bg-gradient-to-r from-pink-600 to-purple-600 hover:opacity-90 text-white font-medium text-xs rounded-xl shadow-lg shadow-pink-500/20 transition flex items-center justify-center gap-1.5 h-[36px]\">\n                            <i data-lucide=\"shield-check\" class=\"w-4 h-4\"></i> Whitelist Player\n                        </button>\n                    </div>\n                </form>\n            </div>\n\n            <!-- WHITELIST TABLE -->\n            <div class=\"bg-brand-card border border-brand-border rounded-2xl overflow-hidden shadow-xl\">\n                <div class=\"p-4 sm:p-5 border-b border-brand-border flex items-center justify-between\">\n                    <div class=\"flex items-center gap-2\">\n                        <i data-lucide=\"users\" class=\"w-4 h-4 text-pink-400\"></i>\n                        <h4 class=\"text-sm font-bold text-white\">Whitelisted Players</h4>\n                        <span id=\"whitelistCountBadge\" class=\"text-xs px-2 py-0.5 rounded-full bg-pink-500/10 text-pink-400 border border-pink-500/20\">0</span>\n                    </div>\n                </div>\n\n                <div class=\"overflow-x-auto\">\n                    <table class=\"w-full text-left text-xs text-gray-300\">\n                        <thead class=\"bg-[#18181f] text-gray-400 uppercase font-semibold text-[11px] border-b border-brand-border\">\n                            <tr>\n                                <th class=\"px-4 py-3\">Roblox UserID</th>\n                                <th class=\"px-4 py-3\">Username</th>\n                                <th class=\"px-4 py-3\">Role</th>\n                                <th class=\"px-4 py-3\">Added Date</th>\n                                <th class=\"px-4 py-3 text-right\">Actions</th>\n                            </tr>\n                        </thead>\n                        <tbody id=\"whitelistTableBody\" class=\"divide-y divide-brand-border\">\n                            <tr>\n                                <td colspan=\"5\" class=\"px-4 py-8 text-center text-gray-500\">Loading whitelisted players...</td>\n                            </tr>\n                        </tbody>\n                    </table>\n                </div>\n            </div>\n        </div>\n\n        <!-- ================================================================== -->\n        <!-- TAB 3: VERIFICATION LOGS -->\n        <!-- ================================================================== -->\n        <div id=\"tab-logs\" class=\"tab-pane hidden space-y-6\">\n            <div class=\"bg-brand-card border border-brand-border rounded-2xl overflow-hidden shadow-xl\">\n                <div class=\"p-4 sm:p-5 border-b border-brand-border flex items-center justify-between\">\n                    <div class=\"flex items-center gap-2\">\n                        <i data-lucide=\"activity\" class=\"w-4 h-4 text-cyan-400\"></i>\n                        <h4 class=\"text-sm font-bold text-white\">Live Execution & Verification Stream</h4>\n                    </div>\n                    <button id=\"refreshLogsBtn\" class=\"text-xs px-3 py-1.5 rounded-xl border border-brand-border text-gray-400 hover:text-white hover:bg-[#18181f] transition flex items-center gap-1.5\">\n                        <i data-lucide=\"refresh-cw\" class=\"w-3.5 h-3.5\"></i> Refresh Logs\n                    </button>\n                </div>\n\n                <div class=\"overflow-x-auto\">\n                    <table class=\"w-full text-left text-xs text-gray-300\">\n                        <thead class=\"bg-[#18181f] text-gray-400 uppercase font-semibold text-[11px] border-b border-brand-border\">\n                            <tr>\n                                <th class=\"px-4 py-3\">Time</th>\n                                <th class=\"px-4 py-3\">Status</th>\n                                <th class=\"px-4 py-3\">User</th>\n                                <th class=\"px-4 py-3\">Key</th>\n                                <th class=\"px-4 py-3\">HWID / IP</th>\n                                <th class=\"px-4 py-3\">Message</th>\n                            </tr>\n                        </thead>\n                        <tbody id=\"logsTableBody\" class=\"divide-y divide-brand-border\">\n                            <tr>\n                                <td colspan=\"6\" class=\"px-4 py-8 text-center text-gray-500\">Loading logs...</td>\n                            </tr>\n                        </tbody>\n                    </table>\n                </div>\n            </div>\n        </div>\n\n        <!-- ================================================================== -->\n        <!-- TAB 4: LUAU SCRIPT INTEGRATION -->\n        <!-- ================================================================== -->\n        <div id=\"tab-integration\" class=\"tab-pane hidden space-y-6\">\n            <div class=\"bg-brand-card border border-brand-border rounded-2xl p-6 shadow-xl space-y-4\">\n                <div class=\"flex items-center justify-between\">\n                    <div>\n                        <h3 class=\"text-base font-bold text-white flex items-center gap-2\">\n                            <i data-lucide=\"terminal\" class=\"w-5 h-5 text-purple-400\"></i> Luau Integration Snippet\n                        </h3>\n                        <p class=\"text-xs text-gray-400 mt-1\">Copy and insert this header snippet at the top of your Hub script to protect it with this Whitelist/Key System</p>\n                    </div>\n\n                    <button id=\"copyLuaCodeBtn\" class=\"px-3.5 py-2 bg-purple-600 hover:bg-purple-500 text-white rounded-xl text-xs font-medium transition flex items-center gap-1.5 shadow-lg shadow-purple-600/20\">\n                        <i data-lucide=\"copy\" class=\"w-4 h-4\"></i> Copy Lua Code\n                    </button>\n                </div>\n\n                <div class=\"relative\">\n                    <pre class=\"bg-[#09090d] border border-brand-border p-4 rounded-xl text-xs text-purple-300 font-mono overflow-x-auto max-h-[480px]\" id=\"luaCodeSnippet\">-- Loading snippet...</pre>\n                </div>\n            </div>\n        </div>\n\n        <!-- ================================================================== -->\n        <!-- TAB 5: GET KEY & MONETIZATION SETTINGS -->\n        <!-- ================================================================== -->\n        <div id=\"tab-monetization\" class=\"tab-pane hidden space-y-6\">\n\n            <!-- QUICK PORTAL LINK & STATUS -->\n            <div class=\"bg-gradient-to-r from-emerald-950/40 via-cyan-950/30 to-purple-950/40 border border-emerald-500/30 rounded-2xl p-6 shadow-xl flex flex-col md:flex-row items-center justify-between gap-4\">\n                <div class=\"flex items-center gap-4\">\n                    <div class=\"w-12 h-12 rounded-xl bg-emerald-500/20 border border-emerald-500/40 flex items-center justify-center text-emerald-400 shadow-lg shadow-emerald-500/20\">\n                        <i data-lucide=\"coins\" class=\"w-6 h-6\"></i>\n                    </div>\n                    <div>\n                        <h3 class=\"text-lg font-bold text-white flex items-center gap-2\">\n                            <span>Get Key Checkpoint Gateway</span>\n                            <span class=\"px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-500/20 text-emerald-300 border border-emerald-500/30\">Active</span>\n                        </h3>\n                        <p class=\"text-xs text-gray-300 mt-0.5\">Players complete Linkvertise & LootLabs tasks to receive free temporary keys.</p>\n                        <div class=\"flex items-center gap-2 mt-2\">\n                            <span class=\"text-xs text-gray-400\">Public URL:</span>\n                            <code id=\"monetizeUrlPreview\" class=\"text-xs font-mono text-emerald-300 bg-black/40 px-2 py-0.5 rounded border border-emerald-500/20\">http://localhost:3000/getkey</code>\n                        </div>\n                    </div>\n                </div>\n\n                <div class=\"flex items-center gap-2.5 w-full md:w-auto\">\n                    <a href=\"/getkey\" target=\"_blank\" class=\"flex-1 md:flex-initial px-4 py-2.5 rounded-xl bg-emerald-500 hover:bg-emerald-400 text-black font-bold text-xs shadow-lg shadow-emerald-500/25 flex items-center justify-center gap-2 transition\">\n                        <i data-lucide=\"external-link\" class=\"w-4 h-4\"></i>\n                        <span>Open User Portal</span>\n                    </a>\n                    <button onclick=\"navigator.clipboard.writeText(window.location.origin + '/getkey'); showToast('Get Key URL copied to clipboard!', 'success');\" class=\"px-3.5 py-2.5 rounded-xl bg-white/5 hover:bg-white/10 border border-white/10 text-gray-300 text-xs font-semibold flex items-center gap-1.5 transition\">\n                        <i data-lucide=\"copy\" class=\"w-4 h-4\"></i>\n                        <span>Copy Link</span>\n                    </button>\n                </div>\n            </div>\n\n            <!-- MONETIZATION CONFIGURATION FORM -->\n            <div class=\"bg-brand-card border border-brand-border rounded-2xl p-6 shadow-xl space-y-6\">\n                <div>\n                    <h3 class=\"text-base font-bold text-white flex items-center gap-2\">\n                        <i data-lucide=\"sliders\" class=\"w-5 h-5 text-emerald-400\"></i> Monetization & Checkpoint Settings\n                    </h3>\n                    <p class=\"text-xs text-gray-400 mt-1\">Configure your shortlink provider keys, ad tier levels, and checkpoint steps.</p>\n                </div>\n\n                <form id=\"getkeySettingsForm\" class=\"space-y-5\">\n                    <div class=\"grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4\">\n                        <!-- Provider Mode -->\n                        <div>\n                            <label class=\"block text-xs font-semibold text-gray-300 mb-1.5\">Checkpoint Mode</label>\n                            <select id=\"cfgGetkeyMode\" class=\"w-full bg-[#09090d] border border-brand-border rounded-xl px-3 py-2 text-xs text-gray-200 focus:outline-none focus:border-emerald-500\">\n                                <option value=\"dual\">User Choice / Dual (LootLabs or Linkvertise)</option>\n                                <option value=\"lootlabs\">LootLabs Only (1 - 5 Steps)</option>\n                                <option value=\"linkvertise\">Linkvertise Only (1 - 5 Steps)</option>\n                            </select>\n                            <p class=\"text-[10px] text-gray-500 mt-1\">User Choice lets visitors pick LootLabs or Linkvertise</p>\n                        </div>\n\n                        <!-- Number of Steps -->\n                        <div>\n                            <label class=\"block text-xs font-semibold text-gray-300 mb-1.5\">Total Checkpoints (Steps)</label>\n                            <select id=\"cfgGetkeySteps\" class=\"w-full bg-[#09090d] border border-brand-border rounded-xl px-3 py-2 text-xs text-gray-200 focus:outline-none focus:border-emerald-500\">\n                                <option value=\"1\">1 Step (Quick for Players)</option>\n                                <option value=\"2\">2 Steps (Standard & High Revenue)</option>\n                                <option value=\"3\">3 Steps (High Revenue)</option>\n                                <option value=\"4\">4 Steps (Ultra Revenue)</option>\n                                <option value=\"5\">5 Steps (Max Revenue)</option>\n                            </select>\n                            <p class=\"text-[10px] text-gray-500 mt-1\">Required tasks before key release</p>\n                        </div>\n\n                        <!-- Key Duration -->\n                        <div>\n                            <label class=\"block text-xs font-semibold text-gray-300 mb-1.5\">Free Key Duration (Hours)</label>\n                            <input id=\"cfgGetkeyDuration\" type=\"number\" min=\"1\" max=\"168\" value=\"24\" class=\"w-full bg-[#09090d] border border-brand-border rounded-xl px-3 py-2 text-xs text-gray-200 focus:outline-none focus:border-emerald-500\">\n                            <p class=\"text-[10px] text-gray-500 mt-1\">Key validity before re-checkpointing</p>\n                        </div>\n\n                        <!-- Free Key HWID Limit -->\n                        <div>\n                            <label class=\"block text-xs font-semibold text-gray-300 mb-1.5 flex items-center justify-between\">\n                                <span>Free Key HWID Limit</span>\n                                <span class=\"text-[10px] text-cyan-400\">Devices</span>\n                            </label>\n                            <input id=\"cfgGetkeyMaxHwid\" type=\"number\" min=\"1\" max=\"20\" value=\"1\" placeholder=\"1\" class=\"w-full bg-[#09090d] border border-brand-border rounded-xl px-3 py-2 text-xs text-gray-200 focus:outline-none focus:border-emerald-500\">\n                            <p class=\"text-[10px] text-gray-500 mt-1\">Max allowed devices per free key</p>\n                        </div>\n\n                        <!-- Free Key Session Limit -->\n                        <div>\n                            <label class=\"block text-xs font-semibold text-gray-300 mb-1.5 flex items-center justify-between\">\n                                <span>Free Key Session Limit</span>\n                                <span class=\"text-[10px] text-emerald-400\">Windows</span>\n                            </label>\n                            <input id=\"cfgGetkeyMaxSessions\" type=\"number\" min=\"1\" max=\"20\" value=\"1\" placeholder=\"1\" class=\"w-full bg-[#09090d] border border-brand-border rounded-xl px-3 py-2 text-xs text-gray-200 focus:outline-none focus:border-emerald-500\">\n                            <p class=\"text-[10px] text-gray-500 mt-1\">Max concurrent Roblox instances</p>\n                        </div>\n                    </div>\n\n                    <!-- API Keys Section -->\n                    <div class=\"pt-4 border-t border-brand-border/60 grid grid-cols-1 md:grid-cols-2 gap-4\">\n                        <!-- Linkvertise User ID -->\n                        <div class=\"p-4 rounded-xl bg-cyan-950/20 border border-cyan-500/20 space-y-2\">\n                            <div class=\"flex items-center justify-between\">\n                                <span class=\"text-xs font-bold text-cyan-300 flex items-center gap-1.5\">\n                                    <i data-lucide=\"zap\" class=\"w-4 h-4\"></i> Linkvertise Provider\n                                </span>\n                                <span class=\"text-[10px] text-gray-400\">Account ID</span>\n                            </div>\n                            <div>\n                                <label class=\"block text-[11px] font-medium text-gray-400 mb-1\">User ID (Publisher ID)</label>\n                                <input id=\"cfgLinkvertiseId\" type=\"text\" placeholder=\"e.g. 9176777\" class=\"w-full bg-[#09090d] border border-brand-border rounded-xl px-3 py-2 text-xs font-mono text-cyan-200 focus:outline-none focus:border-cyan-500\">\n                            </div>\n                            <p class=\"text-[10px] text-gray-400\">Used for dynamic link redirection (`link-to.net/ID/...`)</p>\n                        </div>\n\n                        <!-- LootLabs API Token -->\n                        <div class=\"p-4 rounded-xl bg-purple-950/20 border border-purple-500/20 space-y-2\">\n                            <div class=\"flex items-center justify-between\">\n                                <span class=\"text-xs font-bold text-purple-300 flex items-center gap-1.5\">\n                                    <i data-lucide=\"layers\" class=\"w-4 h-4\"></i> LootLabs Provider\n                                </span>\n                                <span class=\"text-[10px] text-gray-400\">API Bearer Token</span>\n                            </div>\n                            <div>\n                                <label class=\"block text-[11px] font-medium text-gray-400 mb-1\">LootLabs API Key</label>\n                                <input id=\"cfgLootlabsKey\" type=\"text\" placeholder=\"e.g. 8580e9cc7da8...\" class=\"w-full bg-[#09090d] border border-brand-border rounded-xl px-3 py-2 text-xs font-mono text-purple-200 focus:outline-none focus:border-purple-500\">\n                            </div>\n                            <div class=\"grid grid-cols-2 gap-2 pt-1\">\n                                <div>\n                                    <label class=\"block text-[10px] font-medium text-gray-400 mb-1\">Ad Tier (1-4)</label>\n                                    <select id=\"cfgLootlabsTier\" class=\"w-full bg-[#09090d] border border-brand-border rounded-lg px-2.5 py-1.5 text-xs text-gray-200\">\n                                        <option value=\"1\">Tier 1 - Trending</option>\n                                        <option value=\"2\">Tier 2 - Gaming Offers</option>\n                                        <option value=\"3\">Tier 3 - Profit Max</option>\n                                        <option value=\"4\">Tier 4 - Max Profit</option>\n                                    </select>\n                                </div>\n                                <div>\n                                    <label class=\"block text-[10px] font-medium text-gray-400 mb-1\">Tasks Count</label>\n                                    <select id=\"cfgLootlabsTasks\" class=\"w-full bg-[#09090d] border border-brand-border rounded-lg px-2.5 py-1.5 text-xs text-gray-200\">\n                                        <option value=\"1\">1 Task</option>\n                                        <option value=\"2\">2 Tasks (Recommended)</option>\n                                        <option value=\"3\">3 Tasks</option>\n                                    </select>\n                                </div>\n                            </div>\n                        </div>\n                    </div>\n\n                    <div class=\"flex items-center justify-between pt-2\">\n                        <div class=\"flex items-center space-x-2\">\n                            <input id=\"cfgGetkeyEnabled\" type=\"checkbox\" checked class=\"w-4 h-4 rounded border-brand-border text-emerald-600 focus:ring-emerald-500 bg-[#09090d]\">\n                            <label for=\"cfgGetkeyEnabled\" class=\"text-xs font-semibold text-gray-300\">Enable Get Key System</label>\n                        </div>\n\n                        <button type=\"submit\" id=\"saveGetkeySettingsBtn\" class=\"px-5 py-2.5 bg-emerald-600 hover:bg-emerald-500 text-black font-extrabold rounded-xl text-xs transition shadow-lg shadow-emerald-600/20 flex items-center gap-2\">\n                            <i data-lucide=\"save\" class=\"w-4 h-4\"></i> Save Monetization Settings\n                        </button>\n                    </div>\n                </form>\n            </div>\n\n            <!-- RECENT GET KEY SESSIONS TABLE -->\n            <div class=\"bg-brand-card border border-brand-border rounded-2xl p-6 shadow-xl space-y-4\">\n                <div class=\"flex items-center justify-between\">\n                    <div>\n                        <h3 class=\"text-base font-bold text-white flex items-center gap-2\">\n                            <i data-lucide=\"history\" class=\"w-5 h-5 text-cyan-400\"></i> Recent Checkpoint Sessions\n                        </h3>\n                        <p class=\"text-xs text-gray-400 mt-1\">Live tracking of players completing shortlinks and generating free keys</p>\n                    </div>\n                    <button id=\"refreshSessionsBtn\" class=\"px-3 py-1.5 bg-white/5 hover:bg-white/10 text-gray-300 rounded-lg text-xs font-medium transition flex items-center gap-1.5\">\n                        <i data-lucide=\"refresh-cw\" class=\"w-3.5 h-3.5\"></i> Refresh\n                    </button>\n                </div>\n\n                <div class=\"overflow-x-auto\">\n                    <table class=\"w-full text-left text-xs text-gray-300\">\n                        <thead class=\"bg-white/5 text-gray-400 uppercase font-semibold text-[11px]\">\n                            <tr>\n                                <th class=\"p-3\">Session ID</th>\n                                <th class=\"p-3\">IP Address</th>\n                                <th class=\"p-3\">Device HWID</th>\n                                <th class=\"p-3\">Provider</th>\n                                <th class=\"p-3\">Progress</th>\n                                <th class=\"p-3\">Status</th>\n                                <th class=\"p-3\">Claimed Key</th>\n                                <th class=\"p-3\">Time</th>\n                            </tr>\n                        </thead>\n                        <tbody id=\"sessionsTableBody\" class=\"divide-y divide-brand-border\">\n                            <tr>\n                                <td colspan=\"8\" class=\"p-4 text-center text-gray-500\">Loading sessions...</td>\n                            </tr>\n                        </tbody>\n                    </table>\n                </div>\n            </div>\n\n        </div>\n\n        <!-- ================================================================== -->\n        <!-- TAB 6: DATABASE CLOUD PERSISTENCE & BACKUP -->\n        <!-- ================================================================== -->\n        <div id=\"tab-backup\" class=\"tab-pane hidden space-y-6\">\n\n            <!-- Cloud Persistence Status Card -->\n            <div class=\"bg-[#121217] border border-cyan-500/20 rounded-2xl p-6 relative overflow-hidden shadow-xl\">\n                <div class=\"absolute -top-12 -right-12 w-40 h-40 bg-cyan-500/10 rounded-full blur-2xl pointer-events-none\"></div>\n                <div class=\"flex flex-col sm:flex-row sm:items-center justify-between gap-4\">\n                    <div class=\"flex items-start gap-4\">\n                        <div class=\"w-12 h-12 rounded-xl bg-cyan-500/10 border border-cyan-500/30 flex items-center justify-center shrink-0\">\n                            <i data-lucide=\"cloud-lightning\" class=\"w-6 h-6 text-cyan-400\"></i>\n                        </div>\n                        <div>\n                            <div class=\"flex items-center gap-2\">\n                                <h3 class=\"text-base font-bold text-white\">Cloud Database Persistence</h3>\n                                <span class=\"px-2.5 py-0.5 rounded-full text-[10px] font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 flex items-center gap-1\">\n                                    <span class=\"w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse\"></span> Active (Auto-Restore on Deploy)\n                                </span>\n                            </div>\n                            <p class=\"text-xs text-gray-400 mt-1 max-w-2xl leading-relaxed\">\n                                ระบบป้องกันฐานข้อมูลสูญหายอัตโนมัติ: เซิร์ฟเวอร์จะทำการสำรองข้อมูลคีย์, HWID, และรายชื่อ Whitelist ไปยัง Private Cloud Storage อัตโนมัติทุกครั้งที่มีการเปลี่ยนแปลง \n                                แม้ Render จะมีการ Redeploy หรือ Restart เซิร์ฟเวอร์จะกู้คืนข้อมูลเดิมกลับมาอัตโนมัติ 100%!\n                            </p>\n                        </div>\n                    </div>\n                    <div class=\"flex flex-wrap items-center gap-2\">\n                        <button id=\"btnForceCloudSync\" onclick=\"forceSyncCloud()\" class=\"px-3.5 py-2 rounded-xl bg-cyan-600/20 hover:bg-cyan-600/30 border border-cyan-500/30 text-cyan-300 text-xs font-semibold transition flex items-center gap-1.5\">\n                            <i data-lucide=\"cloud-upload\" class=\"w-4 h-4\"></i> Sync to Cloud Now\n                        </button>\n                        <button id=\"btnForceCloudPull\" onclick=\"forcePullCloud()\" class=\"px-3.5 py-2 rounded-xl bg-purple-600/20 hover:bg-purple-600/30 border border-purple-500/30 text-purple-300 text-xs font-semibold transition flex items-center gap-1.5\">\n                            <i data-lucide=\"cloud-download\" class=\"w-4 h-4\"></i> Pull from Cloud\n                        </button>\n                    </div>\n                </div>\n            </div>\n\n            <!-- Manual File Backup & Restore Card -->\n            <div class=\"grid grid-cols-1 md:grid-cols-2 gap-6\">\n\n                <!-- Export / Download Backup -->\n                <div class=\"bg-[#121217] border border-brand-border rounded-2xl p-6 space-y-4\">\n                    <div class=\"flex items-center gap-3\">\n                        <div class=\"w-10 h-10 rounded-xl bg-purple-500/10 border border-purple-500/20 flex items-center justify-center\">\n                            <i data-lucide=\"download\" class=\"w-5 h-5 text-purple-400\"></i>\n                        </div>\n                        <div>\n                            <h4 class=\"text-sm font-bold text-white\">Download Backup (ดาวน์โหลดไฟล์สำรอง)</h4>\n                            <p class=\"text-xs text-gray-400\">บันทึกข้อมูลคีย์และระบบทั้งหมดเป็นไฟล์ JSON ลงคอมพิวเตอร์ของคุณ</p>\n                        </div>\n                    </div>\n                    <p class=\"text-xs text-gray-400 leading-relaxed\">\n                        คุณสามารถดาวน์โหลดไฟล์สำรองเก็บไว้ในเครื่องได้ตลอดเวลา สำหรับนำไปย้ายโฮสต์ กู้คืน หรือเก็บประวัติความปลอดภัย\n                    </p>\n                    <button onclick=\"downloadDatabaseBackup()\" class=\"w-full py-2.5 rounded-xl bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-500 hover:to-pink-500 text-white font-semibold text-xs shadow-lg shadow-purple-600/20 transition flex items-center justify-center gap-2\">\n                        <i data-lucide=\"file-down\" class=\"w-4 h-4\"></i> Download Full Backup (.json)\n                    </button>\n                </div>\n\n                <!-- Import / Restore Backup -->\n                <div class=\"bg-[#121217] border border-brand-border rounded-2xl p-6 space-y-4\">\n                    <div class=\"flex items-center gap-3\">\n                        <div class=\"w-10 h-10 rounded-xl bg-pink-500/10 border border-pink-500/20 flex items-center justify-center\">\n                            <i data-lucide=\"upload\" class=\"w-5 h-5 text-pink-400\"></i>\n                        </div>\n                        <div>\n                            <h4 class=\"text-sm font-bold text-white\">Restore from Backup (กู้คืนจากไฟล์)</h4>\n                            <p class=\"text-xs text-gray-400\">อัปโหลดไฟล์ JSON เพื่อกู้คืนคีย์และ Whitelist ทั้งหมด</p>\n                        </div>\n                    </div>\n                    <p class=\"text-xs text-gray-400 leading-relaxed\">\n                        เลือกไฟล์สำรอง JSON ที่เคยดาวน์โหลดไว้ ระบบจะทำการนำเข้าคีย์และรายชื่อผู้ใช้กลับมาทันที\n                    </p>\n                    <div class=\"flex gap-2\">\n                        <input type=\"file\" id=\"backupFileInput\" accept=\".json\" class=\"hidden\" onchange=\"handleBackupFileSelected(event)\">\n                        <button onclick=\"document.getElementById('backupFileInput').click()\" class=\"flex-1 py-2.5 rounded-xl bg-white/5 hover:bg-white/10 border border-brand-border text-gray-200 font-semibold text-xs transition flex items-center justify-center gap-2\">\n                            <i data-lucide=\"folder-open\" class=\"w-4 h-4 text-pink-400\"></i> Select Backup File (.json)\n                        </button>\n                    </div>\n                    <div id=\"restoreStatus\" class=\"text-xs text-gray-400 hidden\"></div>\n                </div>\n\n            </div>\n\n        </div>\n\n    </main>\n\n    <!-- EDIT KEY MODAL -->\n    <div id=\"editKeyModal\" class=\"fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4 hidden\">\n        <div class=\"bg-[#121217] border border-brand-border rounded-2xl max-w-md w-full p-6 shadow-2xl space-y-4\">\n            <div class=\"flex items-center justify-between pb-3 border-b border-brand-border\">\n                <div class=\"flex items-center gap-2\">\n                    <i data-lucide=\"sliders\" class=\"w-5 h-5 text-purple-400\"></i>\n                    <h3 class=\"text-sm font-bold text-white\">Edit License Key Limits</h3>\n                </div>\n                <button onclick=\"closeEditKeyModal()\" class=\"text-gray-400 hover:text-white transition\">\n                    <i data-lucide=\"x\" class=\"w-4 h-4\"></i>\n                </button>\n            </div>\n\n            <form id=\"editKeyForm\" class=\"space-y-3\">\n                <input type=\"hidden\" id=\"editKeyId\">\n                <div>\n                    <label class=\"block text-xs font-medium text-gray-400 mb-1\">Key String</label>\n                    <input type=\"text\" id=\"editKeyString\" readonly class=\"w-full px-3 py-2 bg-black/40 border border-brand-border rounded-xl text-xs font-mono text-purple-300\">\n                </div>\n\n                <div class=\"grid grid-cols-2 gap-3\">\n                    <div>\n                        <label class=\"block text-xs font-medium text-gray-400 mb-1\">HWID Limit (Devices)</label>\n                        <input type=\"number\" id=\"editMaxHwid\" min=\"1\" max=\"50\" required\n                            class=\"w-full px-3 py-2 bg-[#18181f] border border-brand-border rounded-xl text-xs text-white focus:outline-none focus:border-purple-500\">\n                    </div>\n                    <div>\n                        <label class=\"block text-xs font-medium text-gray-400 mb-1\">Session Limit (Windows)</label>\n                        <input type=\"number\" id=\"editMaxSessions\" min=\"1\" max=\"50\" required\n                            class=\"w-full px-3 py-2 bg-[#18181f] border border-brand-border rounded-xl text-xs text-white focus:outline-none focus:border-purple-500\">\n                    </div>\n                </div>\n\n                <div class=\"grid grid-cols-2 gap-3\">\n                    <div>\n                        <label class=\"block text-xs font-medium text-gray-400 mb-1\">Duration / Type</label>\n                        <select id=\"editKeyType\" class=\"w-full px-3 py-2 bg-[#18181f] border border-brand-border rounded-xl text-xs text-white focus:outline-none focus:border-purple-500\">\n                            <option value=\"24h\">24 Hours</option>\n                            <option value=\"3d\">3 Days</option>\n                            <option value=\"7d\">7 Days</option>\n                            <option value=\"30d\">30 Days</option>\n                            <option value=\"Lifetime\">Lifetime</option>\n                        </select>\n                    </div>\n                    <div>\n                        <label class=\"block text-xs font-medium text-gray-400 mb-1\">Key Status</label>\n                        <select id=\"editKeyStatus\" class=\"w-full px-3 py-2 bg-[#18181f] border border-brand-border rounded-xl text-xs text-white focus:outline-none focus:border-purple-500\">\n                            <option value=\"1\">Active</option>\n                            <option value=\"0\">Suspended</option>\n                        </select>\n                    </div>\n                </div>\n\n                <div>\n                    <label class=\"block text-xs font-medium text-gray-400 mb-1\">Note / Buyer</label>\n                    <input type=\"text\" id=\"editNote\" placeholder=\"Discord User / Buyer\"\n                        class=\"w-full px-3 py-2 bg-[#18181f] border border-brand-border rounded-xl text-xs text-white focus:outline-none focus:border-purple-500\">\n                </div>\n\n                <div class=\"flex items-center justify-end gap-2 pt-3 border-t border-brand-border\">\n                    <button type=\"button\" onclick=\"closeEditKeyModal()\" class=\"px-4 py-2 rounded-xl border border-brand-border text-xs text-gray-400 hover:text-white transition\">Cancel</button>\n                    <button type=\"submit\" class=\"px-4 py-2 bg-gradient-to-r from-purple-600 to-pink-600 text-white font-semibold text-xs rounded-xl shadow-lg transition\">Save Changes</button>\n                </div>\n            </form>\n        </div>\n    </div>\n\n    <!-- VIEW BOUND HWIDS MODAL -->\n    <div id=\"hwidListModal\" class=\"fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4 hidden\">\n        <div class=\"bg-[#121217] border border-brand-border rounded-2xl max-w-lg w-full p-6 shadow-2xl space-y-4\">\n            <div class=\"flex items-center justify-between pb-3 border-b border-brand-border\">\n                <div class=\"flex items-center gap-2\">\n                    <i data-lucide=\"cpu\" class=\"w-5 h-5 text-cyan-400\"></i>\n                    <div>\n                        <h3 class=\"text-sm font-bold text-white\">Linked Hardware Devices</h3>\n                        <p id=\"modalKeyTitle\" class=\"text-xs font-mono text-purple-300\">KEY-XXXX</p>\n                    </div>\n                </div>\n                <button onclick=\"closeHwidModal()\" class=\"text-gray-400 hover:text-white transition\">\n                    <i data-lucide=\"x\" class=\"w-4 h-4\"></i>\n                </button>\n            </div>\n\n            <div class=\"overflow-y-auto max-h-60 space-y-2\" id=\"hwidModalList\">\n                <!-- Dynamically populated list of devices -->\n            </div>\n\n            <div class=\"flex items-center justify-between pt-3 border-t border-brand-border\">\n                <button type=\"button\" id=\"btnModalResetAllHwids\" class=\"px-3.5 py-1.5 rounded-xl border border-red-500/30 text-red-400 hover:bg-red-500/10 text-xs font-medium transition flex items-center gap-1.5\">\n                    <i data-lucide=\"rotate-ccw\" class=\"w-3.5 h-3.5\"></i> Reset All Devices\n                </button>\n                <button type=\"button\" onclick=\"closeHwidModal()\" class=\"px-4 py-1.5 rounded-xl bg-white/10 hover:bg-white/15 text-white text-xs font-medium transition\">Close</button>\n            </div>\n        </div>\n    </div>\n\n    <!-- TOAST NOTIFICATION CONTAINER -->\n    <div id=\"toastContainer\" class=\"fixed bottom-5 right-5 z-50 flex flex-col gap-2\"></div>\n\n    <script>// ==============================================================================\n// Admin Dashboard Interactive Controller\n// ==============================================================================\n\n// Base API URL: Handles both http://localhost:3000 and direct file:// opening\nconst API_BASE = (window.location.protocol === 'file:' || !window.location.host) \n    ? 'http://localhost:3000' \n    : '';\n\nlet adminToken = localStorage.getItem('hub_admin_token') || '';\nlet allKeysCache = [];\n\n// Safe Lucide icon renderer\nfunction safeRenderIcons() {\n    if (window.lucide && typeof window.lucide.createIcons === 'function') {\n        try {\n            window.safeRenderIcons();\n        } catch (e) {\n            console.warn('Lucide icon render warning:', e);\n        }\n    }\n}\n\n// Safe Lucide icon renderer\nfunction safeRenderIcons() {\n    if (window.lucide && typeof window.lucide.createIcons === 'function') {\n        try {\n            window.lucide.createIcons();\n        } catch (e) {\n            console.warn('Lucide icon render warning:', e);\n        }\n    }\n}\n\n// Show Toast\nfunction showToast(message, type = 'success') {\n    const container = document.getElementById('toastContainer');\n    if (!container) return;\n    const toast = document.createElement('div');\n    const bg = type === 'success' ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-400' : 'bg-red-500/10 border-red-500/30 text-red-400';\n    const icon = type === 'success' ? 'check-circle' : 'alert-circle';\n\n    toast.className = `toast px-4 py-3 rounded-xl border text-xs font-medium shadow-2xl backdrop-blur-md flex items-center gap-2 ${bg}`;\n    toast.innerHTML = `<i data-lucide=\"${icon}\" class=\"w-4 h-4\"></i> <span>${message}</span>`;\n    container.appendChild(toast);\n    safeRenderIcons();\n\n    setTimeout(() => {\n        toast.style.opacity = '0';\n        toast.style.transform = 'translateX(100%)';\n        toast.style.transition = 'all 0.3s ease';\n        setTimeout(() => toast.remove(), 300);\n    }, 3200);\n}\n\n// Authenticated API request helper\nasync function apiRequest(endpoint, options = {}) {\n    const headers = options.headers || {};\n    if (adminToken) {\n        headers['Authorization'] = `Bearer ${adminToken}`;\n    }\n    headers['Content-Type'] = 'application/json';\n\n    const fullUrl = endpoint.startsWith('http') ? endpoint : `${API_BASE}${endpoint}`;\n\n    try {\n        const res = await fetch(fullUrl, { ...options, headers });\n        if (res.status === 401) {\n            localStorage.removeItem('hub_admin_token');\n            adminToken = '';\n            showLoginModal();\n            throw new Error('Session expired');\n        }\n        return await res.json();\n    } catch (err) {\n        console.error('API Error:', err);\n        throw err;\n    }\n}\n\n// Show/Hide Login Modal\nfunction showLoginModal() {\n    document.getElementById('loginModal').classList.remove('hidden');\n    document.getElementById('authBadge').classList.add('hidden');\n    document.getElementById('authBadge').classList.remove('flex');\n    document.getElementById('logoutBtn').classList.add('hidden');\n    document.getElementById('logoutBtn').classList.remove('flex');\n}\n\nfunction hideLoginModal() {\n    document.getElementById('loginModal').classList.add('hidden');\n    document.getElementById('authBadge').classList.remove('hidden');\n    document.getElementById('authBadge').classList.add('flex');\n    document.getElementById('logoutBtn').classList.remove('hidden');\n    document.getElementById('logoutBtn').classList.add('flex');\n}\n\n// Initialize and Load Data\nasync function initDashboard() {\n    if (!adminToken) {\n        showLoginModal();\n        return;\n    }\n\n    hideLoginModal();\n    await Promise.all([\n        loadStats(),\n        loadKeys(),\n        loadWhitelist(),\n        loadLogs(),\n        loadGetkeySettings(),\n        loadGetkeySessions()\n    ]);\n    renderLuaSnippet();\n}\n\n// Stats\nasync function loadStats() {\n    try {\n        const res = await apiRequest('/api/v1/admin/stats');\n        if (res.success) {\n            document.getElementById('statTotalKeys').textContent = res.stats.totalKeys;\n            document.getElementById('statActiveKeys').textContent = res.stats.activeKeys;\n            document.getElementById('statBoundKeys').textContent = res.stats.boundKeys;\n            document.getElementById('statTotalWhitelist').textContent = res.stats.totalWhitelist;\n            if (res.hubName) {\n                document.getElementById('navHubName').textContent = res.hubName;\n            }\n        }\n    } catch (e) {}\n}\n\n// Load Keys\nasync function loadKeys() {\n    const tbody = document.getElementById('keysTableBody');\n    try {\n        const res = await apiRequest('/api/v1/admin/keys');\n        if (res.success) {\n            allKeysCache = res.keys;\n            document.getElementById('keysCountBadge').textContent = res.keys.length;\n            renderKeysTable(res.keys);\n        }\n    } catch (e) {\n        tbody.innerHTML = `<tr><td colspan=\"7\" class=\"px-4 py-8 text-center text-red-400\">Failed to load keys</td></tr>`;\n    }\n}\n\nfunction renderKeysTable(keys) {\n    const tbody = document.getElementById('keysTableBody');\n    if (!keys || keys.length === 0) {\n        tbody.innerHTML = `<tr><td colspan=\"8\" class=\"px-4 py-8 text-center text-gray-500\">No license keys found. Generate one above!</td></tr>`;\n        return;\n    }\n\n    tbody.innerHTML = keys.map(k => {\n        const now = Math.floor(Date.now() / 1000);\n        const isExpired = k.expires_at && now > k.expires_at;\n\n        let statusBadge = '';\n        if (!k.is_active) {\n            statusBadge = '<span class=\"px-2 py-0.5 rounded-full bg-red-500/10 text-red-400 border border-red-500/20 text-[10px]\">Suspended</span>';\n        } else if (isExpired) {\n            statusBadge = '<span class=\"px-2 py-0.5 rounded-full bg-yellow-500/10 text-yellow-400 border border-yellow-500/20 text-[10px]\">Expired</span>';\n        } else if (k.hwid || (k.bound_hwids_count && k.bound_hwids_count > 0)) {\n            statusBadge = '<span class=\"px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-[10px]\">Active (Used)</span>';\n        } else {\n            statusBadge = '<span class=\"px-2 py-0.5 rounded-full bg-cyan-500/10 text-cyan-400 border border-cyan-500/20 text-[10px]\">Unclaimed</span>';\n        }\n\n        const boundCount = k.bound_hwids_count !== undefined ? k.bound_hwids_count : (k.hwid ? 1 : 0);\n        const maxHwid = k.max_hwid || 1;\n        const hwidChip = `\n            <button onclick=\"openHwidModal(${k.id})\" class=\"inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg border border-cyan-500/30 bg-cyan-950/20 text-cyan-300 font-mono text-[11px] hover:border-cyan-400 transition\" title=\"Click to view bound devices (${boundCount}/${maxHwid})\">\n                <i data-lucide=\"cpu\" class=\"w-3 h-3 text-cyan-400\"></i>\n                <span>${boundCount}/${maxHwid}</span>\n            </button>\n        `;\n\n        const activeSessions = k.active_sessions_count || 0;\n        const maxSessions = k.max_sessions || 1;\n        const sessionChip = activeSessions > 0\n            ? `<span class=\"inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg border border-emerald-500/30 bg-emerald-950/20 text-emerald-400 font-mono text-[11px] font-semibold\" title=\"${activeSessions} active instance(s)\">\n                 <span class=\"w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse\"></span>\n                 <span>${activeSessions}/${maxSessions} Live</span>\n               </span>`\n            : `<span class=\"inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg border border-brand-border bg-black/20 text-gray-400 font-mono text-[11px]\" title=\"No active instances\">\n                 <span class=\"w-1.5 h-1.5 rounded-full bg-gray-500\"></span>\n                 <span>0/${maxSessions} Idle</span>\n               </span>`;\n\n        const userOrNote = k.claimed_by || k.note || '<span class=\"text-gray-500\">-</span>';\n\n        const expiresDisplay = k.expires_at\n            ? new Date(k.expires_at * 1000).toLocaleString('th-TH', { dateStyle: 'short', timeStyle: 'short' })\n            : (k.duration_seconds === 0 ? '<span class=\"text-purple-400 font-semibold\">Never (Lifetime)</span>' : '<span class=\"text-gray-500\">Upon Activation</span>');\n\n        return `\n            <tr class=\"hover:bg-[#16161d] transition\">\n                <td class=\"px-4 py-3 font-mono font-medium text-white flex items-center gap-2\">\n                    <span>${k.key_string}</span>\n                    <button onclick=\"copyToClipboard('${k.key_string}')\" class=\"text-gray-500 hover:text-purple-400 transition\" title=\"Copy Key\">\n                        <i data-lucide=\"copy\" class=\"w-3.5 h-3.5\"></i>\n                    </button>\n                </td>\n                <td class=\"px-4 py-3 font-semibold text-purple-300\">${k.key_type}</td>\n                <td class=\"px-4 py-3\">${hwidChip}</td>\n                <td class=\"px-4 py-3\">${sessionChip}</td>\n                <td class=\"px-4 py-3 text-gray-300 truncate max-w-[140px]\">${userOrNote}</td>\n                <td class=\"px-4 py-3 text-gray-400\">${expiresDisplay}</td>\n                <td class=\"px-4 py-3\">${statusBadge}</td>\n                <td class=\"px-4 py-3 text-right space-x-1\">\n                    <button onclick=\"openEditKeyModal(${k.id})\" class=\"p-1.5 rounded-lg border border-brand-border text-gray-400 hover:text-purple-400 hover:border-purple-500/40 transition\" title=\"Edit HWID & Session Limits\">\n                        <i data-lucide=\"sliders\" class=\"w-3.5 h-3.5\"></i>\n                    </button>\n                    <button onclick=\"kickSessions(${k.id})\" class=\"p-1.5 rounded-lg border border-brand-border text-gray-400 hover:text-orange-400 hover:border-orange-500/40 transition\" title=\"Kick all active Roblox game sessions\">\n                        <i data-lucide=\"zap-off\" class=\"w-3.5 h-3.5\"></i>\n                    </button>\n                    <button onclick=\"resetHwid(${k.id})\" class=\"p-1.5 rounded-lg border border-brand-border text-gray-400 hover:text-cyan-400 hover:border-cyan-500/40 transition\" title=\"Reset All Linked HWIDs\">\n                        <i data-lucide=\"rotate-ccw\" class=\"w-3.5 h-3.5\"></i>\n                    </button>\n                    <button onclick=\"toggleKey(${k.id}, ${k.is_active ? 0 : 1})\" class=\"p-1.5 rounded-lg border border-brand-border text-gray-400 hover:text-yellow-400 transition\" title=\"${k.is_active ? 'Suspend Key' : 'Activate Key'}\">\n                        <i data-lucide=\"${k.is_active ? 'pause' : 'play'}\" class=\"w-3.5 h-3.5\"></i>\n                    </button>\n                    <button onclick=\"deleteKey(${k.id})\" class=\"p-1.5 rounded-lg border border-brand-border text-gray-400 hover:text-red-400 transition\" title=\"Delete Key\">\n                        <i data-lucide=\"trash-2\" class=\"w-3.5 h-3.5\"></i>\n                    </button>\n                </td>\n            </tr>\n        `;\n    }).join('');\n\n    safeRenderIcons();\n}\n\n// Load Whitelist\nasync function loadWhitelist() {\n    const tbody = document.getElementById('whitelistTableBody');\n    try {\n        const res = await apiRequest('/api/v1/admin/whitelist');\n        if (res.success) {\n            document.getElementById('whitelistCountBadge').textContent = res.users.length;\n            renderWhitelistTable(res.users);\n        }\n    } catch (e) {\n        tbody.innerHTML = `<tr><td colspan=\"5\" class=\"px-4 py-8 text-center text-red-400\">Failed to load whitelist</td></tr>`;\n    }\n}\n\nfunction renderWhitelistTable(users) {\n    const tbody = document.getElementById('whitelistTableBody');\n    if (!users || users.length === 0) {\n        tbody.innerHTML = `<tr><td colspan=\"5\" class=\"px-4 py-8 text-center text-gray-500\">No whitelisted Roblox users. Add one above!</td></tr>`;\n        return;\n    }\n\n    tbody.innerHTML = users.map(u => {\n        const dateStr = new Date(u.created_at * 1000).toLocaleDateString('th-TH');\n        return `\n            <tr class=\"hover:bg-[#16161d] transition\">\n                <td class=\"px-4 py-3 font-mono font-medium text-pink-300\">${u.roblox_user_id}</td>\n                <td class=\"px-4 py-3 text-white font-medium\">${u.username || '<span class=\"text-gray-500\">Not specified</span>'}</td>\n                <td class=\"px-4 py-3\">\n                    <span class=\"px-2 py-0.5 rounded-full bg-pink-500/10 text-pink-400 border border-pink-500/20 text-[10px] font-semibold\">${u.role}</span>\n                </td>\n                <td class=\"px-4 py-3 text-gray-400\">${dateStr}</td>\n                <td class=\"px-4 py-3 text-right\">\n                    <button onclick=\"deleteWhitelistUser(${u.id})\" class=\"p-1.5 rounded-lg border border-brand-border text-gray-400 hover:text-red-400 transition\" title=\"Remove User\">\n                        <i data-lucide=\"trash-2\" class=\"w-3.5 h-3.5\"></i>\n                    </button>\n                </td>\n            </tr>\n        `;\n    }).join('');\n\n    safeRenderIcons();\n}\n\n// Load Logs\nasync function loadLogs() {\n    const tbody = document.getElementById('logsTableBody');\n    try {\n        const res = await apiRequest('/api/v1/admin/logs?limit=50');\n        if (res.success) {\n            renderLogsTable(res.logs);\n        }\n    } catch (e) {\n        tbody.innerHTML = `<tr><td colspan=\"6\" class=\"px-4 py-8 text-center text-red-400\">Failed to load logs</td></tr>`;\n    }\n}\n\nfunction renderLogsTable(logs) {\n    const tbody = document.getElementById('logsTableBody');\n    if (!logs || logs.length === 0) {\n        tbody.innerHTML = `<tr><td colspan=\"6\" class=\"px-4 py-8 text-center text-gray-500\">No access logs recorded yet.</td></tr>`;\n        return;\n    }\n\n    tbody.innerHTML = logs.map(l => {\n        const time = new Date(l.timestamp * 1000).toLocaleTimeString('th-TH');\n        let badgeClass = 'bg-gray-500/10 text-gray-400 border-gray-500/20';\n        if (l.status === 'SUCCESS' || l.status === 'WHITELIST_BYPASS') {\n            badgeClass = 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20';\n        } else if (l.status === 'HWID_MISMATCH') {\n            badgeClass = 'bg-yellow-500/10 text-yellow-400 border-yellow-500/20';\n        } else {\n            badgeClass = 'bg-red-500/10 text-red-400 border-red-500/20';\n        }\n\n        return `\n            <tr class=\"hover:bg-[#16161d] transition font-mono text-[11px]\">\n                <td class=\"px-4 py-2.5 text-gray-400\">${time}</td>\n                <td class=\"px-4 py-2.5\">\n                    <span class=\"px-2 py-0.5 rounded-full border text-[10px] ${badgeClass}\">${l.status}</span>\n                </td>\n                <td class=\"px-4 py-2.5 text-white\">${l.username || l.roblox_user_id || '-'}</td>\n                <td class=\"px-4 py-2.5 text-purple-300\">${l.key_string || '-'}</td>\n                <td class=\"px-4 py-2.5 text-gray-400\">${l.hwid ? l.hwid.substring(0, 10) + '...' : (l.ip_address || '-')}</td>\n                <td class=\"px-4 py-2.5 text-gray-300 font-sans\">${l.message}</td>\n            </tr>\n        `;\n    }).join('');\n\n    safeRenderIcons();\n}\n\n// Actions\nwindow.copyToClipboard = function(text) {\n    navigator.clipboard.writeText(text);\n    showToast(`Key copied to clipboard: ${text}`);\n};\n\nwindow.resetHwid = async function(id) {\n    if (!confirm('Are you sure you want to reset HWID for this key?')) return;\n    try {\n        const res = await apiRequest('/api/v1/admin/keys/reset-hwid', {\n            method: 'POST',\n            body: JSON.stringify({ id })\n        });\n        if (res.success) {\n            showToast('HWID reset successfully!');\n            loadKeys();\n            loadStats();\n        }\n    } catch (e) {\n        showToast('Failed to reset HWID', 'error');\n    }\n};\n\nwindow.toggleKey = async function(id, isActive) {\n    try {\n        const res = await apiRequest('/api/v1/admin/keys/toggle', {\n            method: 'POST',\n            body: JSON.stringify({ id, isActive: !!isActive })\n        });\n        if (res.success) {\n            showToast(res.message);\n            loadKeys();\n            loadStats();\n        }\n    } catch (e) {\n        showToast('Failed to toggle key status', 'error');\n    }\n};\n\nwindow.deleteKey = async function(id) {\n    if (!confirm('Are you sure you want to permanently delete this key?')) return;\n    try {\n        const res = await apiRequest(`/api/v1/admin/keys/${id}`, { method: 'DELETE' });\n        if (res.success) {\n            showToast('Key deleted');\n            loadKeys();\n            loadStats();\n        }\n    } catch (e) {\n        showToast('Failed to delete key', 'error');\n    }\n};\n\nwindow.deleteWhitelistUser = async function(id) {\n    if (!confirm('Remove this player from the whitelist?')) return;\n    try {\n        const res = await apiRequest(`/api/v1/admin/whitelist/${id}`, { method: 'DELETE' });\n        if (res.success) {\n            showToast('Player removed from whitelist');\n            loadWhitelist();\n            loadStats();\n        }\n    } catch (e) {\n        showToast('Failed to remove player', 'error');\n    }\n};\n\n// Form: Generate Keys\ndocument.getElementById('generateKeyForm').addEventListener('submit', async (e) => {\n    e.preventDefault();\n    const prefix = document.getElementById('genPrefix').value;\n    const type = document.getElementById('genType').value;\n    const count = parseInt(document.getElementById('genCount').value) || 1;\n    const note = document.getElementById('genNote').value;\n    const maxHwid = parseInt(document.getElementById('genMaxHwid')?.value) || 1;\n    const maxSessions = parseInt(document.getElementById('genMaxSessions')?.value) || 1;\n\n    try {\n        const res = await apiRequest('/api/v1/admin/keys/generate', {\n            method: 'POST',\n            body: JSON.stringify({ prefix, type, count, note, maxHwid, maxSessions })\n        });\n\n        if (res.success) {\n            showToast(`Generated ${res.createdCount} new license key(s) (HWID Limit: ${maxHwid} | Session Limit: ${maxSessions})!`);\n            document.getElementById('genNote').value = '';\n            loadKeys();\n            loadStats();\n        }\n    } catch (e) {\n        showToast('Failed to generate keys', 'error');\n    }\n});\n\n// Kick all active sessions for a key\nwindow.kickSessions = async function(id) {\n    if (!confirm('Kick all active Roblox game instances for this key?')) return;\n    try {\n        const res = await apiRequest('/api/v1/admin/keys/kick-sessions', {\n            method: 'POST',\n            body: JSON.stringify({ id })\n        });\n        if (res.success) {\n            showToast(res.message);\n            loadKeys();\n            loadStats();\n        }\n    } catch (e) {\n        showToast('Failed to kick sessions', 'error');\n    }\n};\n\n// Edit Key Modal Controller\nlet currentEditingKeyId = null;\nwindow.openEditKeyModal = function(id) {\n    const k = allKeysCache.find(x => x.id === id);\n    if (!k) return;\n\n    currentEditingKeyId = id;\n    document.getElementById('editKeyId').value = k.id;\n    document.getElementById('editKeyString').value = k.key_string;\n    document.getElementById('editMaxHwid').value = k.max_hwid || 1;\n    document.getElementById('editMaxSessions').value = k.max_sessions || 1;\n    document.getElementById('editKeyType').value = k.key_type || '24h';\n    document.getElementById('editKeyStatus').value = k.is_active ? '1' : '0';\n    document.getElementById('editNote').value = k.note || '';\n\n    document.getElementById('editKeyModal').classList.remove('hidden');\n    safeRenderIcons();\n};\n\nwindow.closeEditKeyModal = function() {\n    document.getElementById('editKeyModal').classList.add('hidden');\n    currentEditingKeyId = null;\n};\n\n// Form: Save Edited Key\nconst editKeyForm = document.getElementById('editKeyForm');\nif (editKeyForm) {\n    editKeyForm.addEventListener('submit', async (e) => {\n        e.preventDefault();\n        const id = currentEditingKeyId;\n        if (!id) return;\n\n        const maxHwid = parseInt(document.getElementById('editMaxHwid').value) || 1;\n        const maxSessions = parseInt(document.getElementById('editMaxSessions').value) || 1;\n        const keyType = document.getElementById('editKeyType').value;\n        const isActive = document.getElementById('editKeyStatus').value === '1';\n        const note = document.getElementById('editNote').value;\n\n        try {\n            const res = await apiRequest('/api/v1/admin/keys/edit', {\n                method: 'POST',\n                body: JSON.stringify({ id, maxHwid, maxSessions, keyType, isActive, note })\n            });\n\n            if (res.success) {\n                showToast('Key settings and limits updated!');\n                closeEditKeyModal();\n                loadKeys();\n                loadStats();\n            }\n        } catch (err) {\n            showToast('Failed to update key limits', 'error');\n        }\n    });\n}\n\n// Bound Devices (HWIDs) Modal Controller\nlet currentHwidKeyId = null;\nwindow.openHwidModal = async function(id) {\n    currentHwidKeyId = id;\n    const k = allKeysCache.find(x => x.id === id);\n    const keyTitle = document.getElementById('modalKeyTitle');\n    const container = document.getElementById('hwidModalList');\n\n    if (keyTitle) {\n        keyTitle.textContent = k ? `${k.key_string} (Limit: ${k.max_hwid || 1})` : `Key #${id}`;\n    }\n    container.innerHTML = '<div class=\"p-4 text-center text-xs text-gray-500\">Loading bound devices...</div>';\n    document.getElementById('hwidListModal').classList.remove('hidden');\n    safeRenderIcons();\n\n    try {\n        const res = await apiRequest(`/api/v1/admin/keys/${id}/hwids`);\n        if (res.success) {\n            renderHwidModalList(id, res.hwids || []);\n        }\n    } catch (e) {\n        container.innerHTML = '<div class=\"p-4 text-center text-xs text-red-400\">Failed to load linked devices</div>';\n    }\n};\n\nwindow.closeHwidModal = function() {\n    document.getElementById('hwidListModal').classList.add('hidden');\n    currentHwidKeyId = null;\n};\n\nfunction renderHwidModalList(keyId, hwids) {\n    const container = document.getElementById('hwidModalList');\n    if (!hwids || hwids.length === 0) {\n        container.innerHTML = '<div class=\"p-4 text-center text-xs text-gray-500 italic\">No devices registered for this key yet.</div>';\n        return;\n    }\n\n    container.innerHTML = hwids.map((h, idx) => {\n        const firstUsed = new Date(h.first_used_at * 1000).toLocaleString('th-TH', { dateStyle: 'short', timeStyle: 'short' });\n        const lastUsed = new Date(h.last_used_at * 1000).toLocaleString('th-TH', { dateStyle: 'short', timeStyle: 'short' });\n\n        return `\n            <div class=\"p-3 rounded-xl bg-black/40 border border-brand-border flex items-center justify-between text-xs\">\n                <div class=\"space-y-1\">\n                    <div class=\"flex items-center gap-2\">\n                        <span class=\"w-5 h-5 rounded-full bg-cyan-500/20 text-cyan-400 flex items-center justify-center text-[10px] font-bold\">#${idx + 1}</span>\n                        <code class=\"font-mono text-cyan-300 font-semibold truncate max-w-[200px]\" title=\"${h.hwid}\">${h.hwid}</code>\n                        ${h.username ? `<span class=\"text-gray-400 text-[11px]\">(${h.username})</span>` : ''}\n                    </div>\n                    <div class=\"text-[10px] text-gray-500 flex items-center gap-3\">\n                        <span>First: ${firstUsed}</span>\n                        <span>Last: ${lastUsed}</span>\n                    </div>\n                </div>\n                <button onclick=\"removeSpecificHwid(${keyId}, '${h.hwid}')\" class=\"px-2.5 py-1 rounded-lg border border-red-500/30 text-red-400 hover:bg-red-500/10 text-[11px] transition\" title=\"Unlink Device\">\n                    Remove\n                </button>\n            </div>\n        `;\n    }).join('');\n\n    safeRenderIcons();\n}\n\nwindow.removeSpecificHwid = async function(keyId, hwid) {\n    if (!confirm(`Unlink this device from the key?`)) return;\n    try {\n        const res = await apiRequest('/api/v1/admin/keys/remove-hwid', {\n            method: 'POST',\n            body: JSON.stringify({ id: keyId, hwid })\n        });\n        if (res.success) {\n            showToast('Device unlinked successfully');\n            openHwidModal(keyId);\n            loadKeys();\n            loadStats();\n        }\n    } catch (e) {\n        showToast('Failed to unlink device', 'error');\n    }\n};\n\nconst btnModalResetAll = document.getElementById('btnModalResetAllHwids');\nif (btnModalResetAll) {\n    btnModalResetAll.onclick = function() {\n        if (currentHwidKeyId) {\n            resetHwid(currentHwidKeyId);\n            closeHwidModal();\n        }\n    };\n}\n\n// Form: Add Whitelist\ndocument.getElementById('addWhitelistForm').addEventListener('submit', async (e) => {\n    e.preventDefault();\n    const robloxUserId = document.getElementById('wlUserId').value;\n    const username = document.getElementById('wlUsername').value;\n    const role = document.getElementById('wlRole').value;\n\n    try {\n        const res = await apiRequest('/api/v1/admin/whitelist/add', {\n            method: 'POST',\n            body: JSON.stringify({ robloxUserId, username, role })\n        });\n\n        if (res.success) {\n            showToast('Player whitelisted successfully!');\n            document.getElementById('wlUserId').value = '';\n            document.getElementById('wlUsername').value = '';\n            loadWhitelist();\n            loadStats();\n        }\n    } catch (e) {\n        showToast('Failed to whitelist player', 'error');\n    }\n});\n\n// Search filter\ndocument.getElementById('searchKeyInput').addEventListener('input', (e) => {\n    const q = e.target.value.toLowerCase().trim();\n    if (!q) {\n        renderKeysTable(allKeysCache);\n        return;\n    }\n    const filtered = allKeysCache.filter(k =>\n        k.key_string.toLowerCase().includes(q) ||\n        (k.claimed_by && k.claimed_by.toLowerCase().includes(q)) ||\n        (k.note && k.note.toLowerCase().includes(q))\n    );\n    renderKeysTable(filtered);\n});\n\n// Tab Switcher\ndocument.querySelectorAll('.nav-tab').forEach(btn => {\n    btn.addEventListener('click', () => {\n        document.querySelectorAll('.nav-tab').forEach(b => {\n            b.classList.remove('active-tab');\n            b.classList.add('text-gray-400', 'border-transparent');\n        });\n        btn.classList.add('active-tab');\n        btn.classList.remove('text-gray-400', 'border-transparent');\n\n        const target = btn.dataset.target;\n        document.querySelectorAll('.tab-pane').forEach(p => p.classList.add('hidden'));\n        document.getElementById(target).classList.remove('hidden');\n    });\n});\n\n// Login Form Submit\ndocument.getElementById('loginForm').addEventListener('submit', async (e) => {\n    e.preventDefault();\n    const password = document.getElementById('adminPasswordInput').value;\n    const errEl = document.getElementById('loginError');\n    errEl.classList.add('hidden');\n\n    try {\n        const res = await fetch(API_BASE + '/api/v1/admin/login', {\n            method: 'POST',\n            headers: { 'Content-Type': 'application/json' },\n            body: JSON.stringify({ password })\n        });\n        const data = await res.json();\n        if (data.success) {\n            adminToken = data.token;\n            localStorage.setItem('hub_admin_token', adminToken);\n            document.getElementById('adminPasswordInput').value = '';\n            showToast('Welcome to Hub Whitelist Admin Panel!');\n            initDashboard();\n        } else {\n            errEl.textContent = data.error || 'Password incorrect';\n            errEl.classList.remove('hidden');\n        }\n    } catch (err) {\n        errEl.textContent = 'Server connection error';\n        errEl.classList.remove('hidden');\n    }\n});\n\n// Logout\ndocument.getElementById('logoutBtn').addEventListener('click', () => {\n    adminToken = '';\n    localStorage.removeItem('hub_admin_token');\n    showLoginModal();\n    showToast('Logged out of admin panel');\n});\n\n// Refresh buttons\ndocument.getElementById('refreshKeysBtn').addEventListener('click', () => { loadKeys(); loadStats(); });\ndocument.getElementById('refreshLogsBtn').addEventListener('click', () => loadLogs());\n\n// Render Luau Integration Code\nfunction renderLuaSnippet() {\n    const host = (window.location.protocol === 'file:' || !window.location.host)\n        ? 'http://localhost:3000'\n        : window.location.origin;\n\n    const snippet = `-- ==============================================================================\n-- 👑 UNIVERSAL ALL-IN-ONE LOADSTRING (RUN THIS IN ANY EXECUTOR)\n-- Supports: Anime Galaxies | Hunting Together | Blue Lock Farm | Throw Food For Animals\n-- Auto-Detects Current Map + Protected by Key System & Direct Whitelist\n-- ==============================================================================\n\n-- 🌐 Option 1: Official GitHub Raw (แจกให้ผู้เล่นรันได้เลย - เสถียรและเร็วที่สุด):\nloadstring(game:HttpGet(\"https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/loader.luau?v=\" .. tostring(os.time())))()\n\n-- ⚡ Option 2: Direct Server Endpoint:\n-- loadstring(game:HttpGet(\"${host}/loader.luau\"))()\n\n-- ==============================================================================\n-- 💡 HOW IT WORKS:\n-- 1. Executes universal authentication via ${host}\n-- 2. Checks Direct Whitelist (Roblox UserID) or Locally Cached Key\n-- 3. If no key, displays the modern Key Verification Dialog\n-- 4. Automatically detects which game you are currently playing:\n--    • Anime Galaxies (Lobby & Match Acts) -> Loads Anime Galaxies Hub\n--    • Hunting Together (Fields & Dungeons) -> Loads Hunting Together Hub\n--    • Blue Lock Farm (Striker Farm & Events) -> Loads Blue Lock Farm Hub\n--    • Throw Food For Animals (Auto Farm & Workout) -> Loads Throw Food Hub\n-- ==============================================================================`;\n\n    document.getElementById('luaCodeSnippet').textContent = snippet;\n}\n\ndocument.getElementById('copyLuaCodeBtn').addEventListener('click', () => {\n    const code = document.getElementById('luaCodeSnippet').textContent;\n    navigator.clipboard.writeText(code);\n    showToast('Luau Integration snippet copied to clipboard!');\n});\n\n// ==============================================================================\n// GET KEY & MONETIZATION SETTINGS\n// ==============================================================================\n\nasync function loadGetkeySettings() {\n    try {\n        const previewEl = document.getElementById('monetizeUrlPreview');\n        if (previewEl) {\n            const host = (window.location.protocol === 'file:' || !window.location.host) ? 'http://localhost:3000' : window.location.origin;\n            previewEl.textContent = `${host}/getkey`;\n        }\n\n        const res = await apiRequest('/api/v1/admin/getkey/settings');\n        if (res.success && res.settings) {\n            const s = res.settings;\n            if (document.getElementById('cfgGetkeyEnabled')) document.getElementById('cfgGetkeyEnabled').checked = !!s.enabled;\n            if (document.getElementById('cfgGetkeyMode')) document.getElementById('cfgGetkeyMode').value = s.mode || 'dual';\n            if (document.getElementById('cfgGetkeySteps')) document.getElementById('cfgGetkeySteps').value = String(s.steps || 2);\n            if (document.getElementById('cfgGetkeyDuration')) document.getElementById('cfgGetkeyDuration').value = s.durationHours || 24;\n            if (document.getElementById('cfgGetkeyMaxHwid')) document.getElementById('cfgGetkeyMaxHwid').value = s.maxHwid || 1;\n            if (document.getElementById('cfgGetkeyMaxSessions')) document.getElementById('cfgGetkeyMaxSessions').value = s.maxSessions || 1;\n            if (document.getElementById('cfgLinkvertiseId')) document.getElementById('cfgLinkvertiseId').value = s.linkvertiseUserId || '';\n            if (document.getElementById('cfgLootlabsKey')) document.getElementById('cfgLootlabsKey').value = s.lootlabsApiKey || '';\n            if (document.getElementById('cfgLootlabsTier')) document.getElementById('cfgLootlabsTier').value = String(s.lootlabsTierId || 1);\n            if (document.getElementById('cfgLootlabsTasks')) document.getElementById('cfgLootlabsTasks').value = String(s.lootlabsTasks || 2);\n        }\n    } catch (e) {\n        console.error('Failed to load getkey settings:', e);\n    }\n}\n\nasync function saveGetkeySettings(e) {\n    if (e) e.preventDefault();\n    const btn = document.getElementById('saveGetkeySettingsBtn');\n    const originalText = btn.innerHTML;\n    btn.innerHTML = '<i data-lucide=\"loader-2\" class=\"w-4 h-4 animate-spin\"></i> Saving...';\n    btn.disabled = true;\n\n    try {\n        const payload = {\n            enabled: document.getElementById('cfgGetkeyEnabled').checked,\n            mode: document.getElementById('cfgGetkeyMode').value,\n            steps: parseInt(document.getElementById('cfgGetkeySteps').value) || 2,\n            durationHours: parseInt(document.getElementById('cfgGetkeyDuration').value) || 24,\n            maxHwid: parseInt(document.getElementById('cfgGetkeyMaxHwid')?.value) || 1,\n            maxSessions: parseInt(document.getElementById('cfgGetkeyMaxSessions')?.value) || 1,\n            linkvertiseUserId: document.getElementById('cfgLinkvertiseId').value.trim(),\n            lootlabsApiKey: document.getElementById('cfgLootlabsKey').value.trim(),\n            lootlabsTierId: parseInt(document.getElementById('cfgLootlabsTier').value) || 1,\n            lootlabsTasks: parseInt(document.getElementById('cfgLootlabsTasks').value) || 2\n        };\n\n        const res = await apiRequest('/api/v1/admin/getkey/settings', {\n            method: 'POST',\n            body: JSON.stringify(payload)\n        });\n\n        if (res.success) {\n            await loadGetkeySettings();\n            showToast('Monetization settings saved successfully!', 'success');\n        } else {\n            showToast(res.error || 'Failed to save settings', 'error');\n        }\n    } catch (err) {\n        showToast('Error connecting to server', 'error');\n    } finally {\n        btn.innerHTML = originalText;\n        btn.disabled = false;\n        safeRenderIcons();\n    }\n}\n\nasync function loadGetkeySessions() {\n    const tbody = document.getElementById('sessionsTableBody');\n    if (!tbody) return;\n\n    try {\n        const res = await apiRequest('/api/v1/admin/getkey/sessions');\n        if (!res.success || !res.sessions || res.sessions.length === 0) {\n            tbody.innerHTML = `<tr><td colspan=\"8\" class=\"p-6 text-center text-gray-500\">No checkpoint sessions recorded yet</td></tr>`;\n            return;\n        }\n\n        tbody.innerHTML = res.sessions.map(s => {\n            const isDone = s.is_completed === 1 || s.status === 'completed';\n            const statusBadge = isDone\n                ? `<span class=\"px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-500/20 text-emerald-400 border border-emerald-500/30\">Completed</span>`\n                : `<span class=\"px-2 py-0.5 rounded-full text-[10px] font-bold bg-cyan-500/20 text-cyan-400 border border-cyan-500/30\">${s.status || 'In Progress'}</span>`;\n\n            const providerBadge = s.provider === 'dual'\n                ? `<span class=\"text-[10px] font-bold text-amber-300 bg-amber-500/10 px-2 py-0.5 rounded border border-amber-500/20\">Loot + Linkv</span>`\n                : s.provider === 'lootlabs'\n                ? `<span class=\"text-[10px] font-bold text-purple-300 bg-purple-500/10 px-2 py-0.5 rounded border border-purple-500/20\">LootLabs</span>`\n                : `<span class=\"text-[10px] font-bold text-cyan-300 bg-cyan-500/10 px-2 py-0.5 rounded border border-cyan-500/20\">Linkvertise</span>`;\n\n            const keyDisplay = s.claimed_key\n                ? `<div class=\"flex items-center gap-1.5\"><code class=\"text-[11px] font-mono text-emerald-300\">${s.claimed_key}</code><button onclick=\"navigator.clipboard.writeText('${s.claimed_key}'); showToast('Key copied!', 'success');\" class=\"text-gray-400 hover:text-white\"><i data-lucide=\"copy\" class=\"w-3 h-3\"></i></button></div>`\n                : `<span class=\"text-gray-500\">-</span>`;\n\n            const hwidDisplay = s.hwid\n                ? `<span title=\"${s.hwid}\" class=\"font-mono text-[11px] text-gray-400\">${s.hwid.length > 14 ? s.hwid.slice(0, 14) + '...' : s.hwid}</span>`\n                : `<span class=\"text-gray-500\">-</span>`;\n\n            const rawTs = Number(s.created_at || 0);\n            const dateStr = rawTs > 0 ? new Date(rawTs < 1e12 ? rawTs * 1000 : rawTs).toLocaleString() : '-';\n            const sid = String(s.session_id || s.id || '');\n            const totalS = Number(s.total_steps || 1);\n            const doneS = s.step_completed !== undefined ? s.step_completed : (isDone ? totalS : Math.max(0, Number(s.current_step || 1) - 1));\n\n            return `\n                <tr class=\"hover:bg-white/[0.02] transition\">\n                    <td class=\"p-3 font-mono text-[11px] text-gray-400\">${sid.slice(0, 8)}...</td>\n                    <td class=\"p-3 text-gray-300 font-mono text-[11px]\">${s.ip_address || '-'}</td>\n                    <td class=\"p-3\">${hwidDisplay}</td>\n                    <td class=\"p-3\">${providerBadge}</td>\n                    <td class=\"p-3 font-bold text-white text-[11px]\">Step ${doneS} / ${totalS}</td>\n                    <td class=\"p-3\">${statusBadge}</td>\n                    <td class=\"p-3\">${keyDisplay}</td>\n                    <td class=\"p-3 text-gray-400 text-[11px]\">${dateStr}</td>\n                </tr>\n            `;\n        }).join('');\n\n        safeRenderIcons();\n    } catch (e) {\n        tbody.innerHTML = `<tr><td colspan=\"8\" class=\"p-4 text-center text-red-400\">Failed to load sessions</td></tr>`;\n    }\n}\n\nif (document.getElementById('getkeySettingsForm')) {\n    document.getElementById('getkeySettingsForm').addEventListener('submit', saveGetkeySettings);\n}\nif (document.getElementById('refreshSessionsBtn')) {\n    document.getElementById('refreshSessionsBtn').addEventListener('click', loadGetkeySessions);\n}\n\n// Run\nwindow.addEventListener('DOMContentLoaded', () => {\n    safeRenderIcons();\n    initDashboard();\n});\n\n// ==============================================================================\n// DATABASE CLOUD PERSISTENCE & BACKUP CONTROLLER\n// ==============================================================================\n\n// Download Database JSON Backup\nasync function downloadDatabaseBackup() {\n    try {\n        showToast('Preparing database backup...', 'success');\n        const res = await fetch(`${API_BASE}/api/v1/admin/database/backup`, {\n            headers: { 'Authorization': `Bearer ${adminToken}` }\n        });\n        if (!res.ok) throw new Error('Backup download failed: HTTP ' + res.status);\n        const blob = await res.blob();\n        const url = window.URL.createObjectURL(blob);\n        const a = document.createElement('a');\n        a.href = url;\n        a.download = `song_hub_backup_${new Date().toISOString().slice(0, 10)}.json`;\n        document.body.appendChild(a);\n        a.click();\n        window.URL.revokeObjectURL(url);\n        a.remove();\n        showToast('Backup downloaded successfully!', 'success');\n    } catch (err) {\n        showToast(err.message, 'error');\n    }\n}\n\n// Restore Database from JSON file\nasync function handleBackupFileSelected(event) {\n    const file = event.target.files[0];\n    if (!file) return;\n\n    const statusEl = document.getElementById('restoreStatus');\n    if (statusEl) {\n        statusEl.classList.remove('hidden');\n        statusEl.textContent = 'Reading and importing backup file...';\n        statusEl.className = 'text-xs text-yellow-400 mt-2';\n    }\n\n    try {\n        const text = await file.text();\n        const json = JSON.parse(text);\n\n        const res = await apiRequest('/api/v1/admin/database/restore?replace=true', {\n            method: 'POST',\n            body: JSON.stringify(json)\n        });\n\n        if (res.success) {\n            showToast(res.message || 'Database restored successfully!', 'success');\n            if (statusEl) {\n                statusEl.textContent = res.message;\n                statusEl.className = 'text-xs text-emerald-400 mt-2';\n            }\n            // Refresh keys and whitelist lists\n            if (typeof loadAllKeys === 'function') loadAllKeys();\n            if (typeof loadWhitelistUsers === 'function') loadWhitelistUsers();\n            if (typeof loadStats === 'function') loadStats();\n        } else {\n            throw new Error(res.error || 'Restore failed');\n        }\n    } catch (err) {\n        showToast(err.message, 'error');\n        if (statusEl) {\n            statusEl.textContent = 'Error: ' + err.message;\n            statusEl.className = 'text-xs text-red-400 mt-2';\n        }\n    } finally {\n        event.target.value = '';\n    }\n}\n\n// Force Sync to Cloud Secret Gist\nasync function forceSyncCloud() {\n    const btn = document.getElementById('btnForceCloudSync');\n    if (btn) btn.disabled = true;\n    showToast('Syncing database to Cloud Storage...', 'success');\n    try {\n        const res = await apiRequest('/api/v1/admin/database/sync-cloud', { method: 'POST' });\n        if (res.success) {\n            showToast(res.message, 'success');\n        } else {\n            throw new Error(res.error || 'Cloud sync failed');\n        }\n    } catch (err) {\n        showToast(err.message, 'error');\n    } finally {\n        if (btn) btn.disabled = false;\n    }\n}\n\n// Force Pull from Cloud Secret Gist\nasync function forcePullCloud() {\n    const btn = document.getElementById('btnForceCloudPull');\n    if (btn) btn.disabled = true;\n    showToast('Pulling snapshot from Cloud Storage...', 'success');\n    try {\n        const res = await apiRequest('/api/v1/admin/database/pull-cloud', { method: 'POST' });\n        if (res.success) {\n            showToast(res.message, 'success');\n            if (typeof loadAllKeys === 'function') loadAllKeys();\n            if (typeof loadWhitelistUsers === 'function') loadWhitelistUsers();\n            if (typeof loadStats === 'function') loadStats();\n        } else {\n            throw new Error(res.error || 'Pull failed');\n        }\n    } catch (err) {\n        showToast(err.message, 'error');\n    } finally {\n        if (btn) btn.disabled = false;\n    }\n}\n\n\n\n</script>\n</body>\n</html>\n\n";
const GETKEY_HTML = "<!DOCTYPE html>\n<html lang=\"en\" class=\"dark\">\n<head>\n    <meta charset=\"UTF-8\">\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n    <title>Song Hub | Free Key Checkpoint System</title>\n    <!-- Tailwind CSS CDN -->\n    <script src=\"https://cdn.tailwindcss.com\"></script>\n    <script>\n        tailwind.config = {\n            darkMode: 'class',\n            theme: {\n                extend: {\n                    colors: {\n                        brand: {\n                            purple: '#8b5cf6',\n                            pink: '#ec4899',\n                            cyan: '#06b6d4',\n                            emerald: '#10b981',\n                            dark: '#09090b',\n                            card: '#121217',\n                            border: '#27272a'\n                        }\n                    }\n                }\n            }\n        }\n    </script>\n    <!-- Lucide Icons -->\n    <script src=\"https://unpkg.com/lucide@latest\"></script>\n    <!-- Canvas Confetti -->\n    <script src=\"https://cdn.jsdelivr.net/npm/canvas-confetti@1.9.2/dist/confetti.browser.min.js\"></script>\n    <style>/* Custom Glassmorphism & Animations */\n::-webkit-scrollbar {\n    width: 6px;\n    height: 6px;\n}\n\n::-webkit-scrollbar-track {\n    background: #09090b;\n}\n\n::-webkit-scrollbar-thumb {\n    background: #27272a;\n    border-radius: 9999px;\n}\n\n::-webkit-scrollbar-thumb:hover {\n    background: #3f3f46;\n}\n\n.active-tab {\n    border-color: #8b5cf6 !important;\n    color: #ffffff !important;\n}\n\n/* Toast animation */\n@keyframes slideIn {\n    from {\n        transform: translateX(100%);\n        opacity: 0;\n    }\n    to {\n        transform: translateX(0);\n        opacity: 1;\n    }\n}\n\n.toast {\n    animation: slideIn 0.25s cubic-bezier(0.16, 1, 0.3, 1) forwards;\n}\n\n</style>\n    <style>\n        .glow-border {\n            box-shadow: 0 0 25px -5px rgba(139, 92, 246, 0.3);\n        }\n        .glow-emerald {\n            box-shadow: 0 0 25px -5px rgba(16, 185, 129, 0.4);\n        }\n    </style>\n</head>\n<body class=\"bg-[#09090b] text-gray-100 min-h-screen flex flex-col font-sans selection:bg-purple-500 selection:text-white relative overflow-x-hidden\">\n\n    <!-- Ambient Background Glow -->\n    <div class=\"fixed top-0 left-1/2 -translate-x-1/2 w-[700px] h-[350px] bg-gradient-to-r from-purple-600/20 via-cyan-500/20 to-emerald-500/20 blur-[130px] pointer-events-none rounded-full\"></div>\n\n    <!-- Header Navigation -->\n    <header class=\"border-b border-brand-border bg-[#0d0d12]/80 backdrop-blur sticky top-0 z-40\">\n        <div class=\"max-w-5xl mx-auto px-4 h-16 flex items-center justify-between\">\n            <div class=\"flex items-center space-x-3\">\n                <div class=\"w-10 h-10 rounded-xl bg-gradient-to-tr from-purple-600 via-cyan-500 to-emerald-400 p-[2px] shadow-lg shadow-purple-500/25\">\n                    <div class=\"w-full h-full bg-[#0d0d12] rounded-[10px] flex items-center justify-center\">\n                        <i data-lucide=\"key\" class=\"w-5 h-5 text-cyan-400\"></i>\n                    </div>\n                </div>\n                <div>\n                    <h1 class=\"font-bold text-lg leading-tight bg-gradient-to-r from-white via-gray-200 to-gray-400 bg-clip-text text-transparent\">\n                        Song Hub | Key System\n                    </h1>\n                    <p class=\"text-xs text-emerald-400 font-medium flex items-center space-x-1\">\n                        <span class=\"w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse\"></span>\n                        <span>Free Monetized Checkpoint Gateway</span>\n                    </p>\n                </div>\n            </div>\n            <a href=\"https://discord.gg/Cpcg9wU5k\" target=\"_blank\" class=\"px-3.5 py-1.5 rounded-lg bg-white/5 hover:bg-white/10 border border-white/10 text-xs font-semibold text-gray-300 flex items-center space-x-2 transition\">\n                <i data-lucide=\"message-square\" class=\"w-4 h-4 text-purple-400\"></i>\n                <span>Discord Community</span>\n            </a>\n        </div>\n    </header>\n\n    <!-- Main Container -->\n    <main class=\"flex-1 max-w-3xl w-full mx-auto px-4 py-8 relative z-10 flex flex-col justify-center\">\n\n        <!-- Card Container -->\n        <div class=\"bg-brand-card/90 border border-brand-border rounded-2xl p-6 md:p-8 backdrop-blur-xl glow-border\">\n            \n            <!-- Hero Title -->\n            <div class=\"text-center mb-8\">\n                <div class=\"inline-flex items-center space-x-2 px-3 py-1 rounded-full bg-purple-500/10 border border-purple-500/20 text-purple-400 text-xs font-semibold uppercase tracking-wider mb-3\">\n                    <i data-lucide=\"shield-check\" class=\"w-3.5 h-3.5\"></i>\n                    <span>Official Free Access Portal</span>\n                </div>\n                <h2 class=\"text-2xl md:text-3xl font-extrabold text-white tracking-tight\">\n                    Get Your Free <span id=\"heroDurationText\" class=\"bg-gradient-to-r from-purple-400 via-pink-400 to-cyan-400 bg-clip-text text-transparent\">24-Hour Access Key</span>\n                </h2>\n                <p id=\"heroSubtitle\" class=\"text-gray-400 text-sm mt-2 max-w-md mx-auto\">\n                    Complete the required sponsor checkpoints to generate your license key instantly.\n                </p>\n            </div>\n\n            <!-- Device HWID Tag (If present) -->\n            <div id=\"hwidBadge\" class=\"hidden mb-6 p-3 rounded-xl bg-black/40 border border-brand-border/70 flex items-center justify-between text-xs\">\n                <div class=\"flex items-center space-x-2.5 text-gray-400\">\n                    <i data-lucide=\"cpu\" class=\"w-4 h-4 text-cyan-400\"></i>\n                    <span>Device HWID:</span>\n                    <code id=\"hwidText\" class=\"font-mono text-gray-300 font-semibold truncate max-w-[200px] md:max-w-xs\">Unknown</code>\n                </div>\n                <span class=\"px-2 py-0.5 rounded-full bg-cyan-500/10 text-cyan-400 font-medium border border-cyan-500/20\">Auto-Linked</span>\n            </div>\n\n            <!-- Step Progress Indicator -->\n            <div id=\"progressContainer\" class=\"mb-8\">\n                <div class=\"relative mb-2\">\n                    <!-- Progress Line -->\n                    <div class=\"absolute left-0 top-1/2 -translate-y-1/2 h-1 bg-white/10 w-full z-0 rounded-full\"></div>\n                    <div id=\"progressBar\" class=\"absolute left-0 top-1/2 -translate-y-1/2 h-1 bg-gradient-to-r from-purple-500 to-cyan-500 w-0 z-0 transition-all duration-500 rounded-full\"></div>\n\n                    <div id=\"progressDotsRow\" class=\"flex items-center justify-between relative z-10\">\n                        <div id=\"step1Dot\" class=\"w-9 h-9 rounded-full bg-brand-dark border-2 border-purple-500 flex items-center justify-center font-bold text-xs text-white shadow-lg shadow-purple-500/30 transition\">\n                            1\n                        </div>\n                        <div id=\"step2Dot\" class=\"w-9 h-9 rounded-full bg-brand-dark border-2 border-brand-border flex items-center justify-center font-bold text-xs text-gray-400 transition\">\n                            2\n                        </div>\n                        <div id=\"claimDot\" class=\"w-9 h-9 rounded-full bg-brand-dark border-2 border-brand-border flex items-center justify-center font-bold text-xs text-gray-400 transition\">\n                            <i data-lucide=\"check\" class=\"w-4 h-4\"></i>\n                        </div>\n                    </div>\n                </div>\n                <div id=\"progressLabelsRow\" class=\"flex justify-between text-[11px] font-semibold text-gray-400 px-1\">\n                    <span id=\"step1Label\" class=\"text-purple-400\">Step 1: LootLabs</span>\n                    <span id=\"step2Label\">Step 2: Linkvertise</span>\n                    <span id=\"claimLabel\">Claim Key</span>\n                </div>\n            </div>\n\n            <!-- Alert Box (Errors/Success) -->\n            <div id=\"alertBox\" class=\"hidden mb-6 p-4 rounded-xl text-sm flex items-start space-x-3\">\n                <i id=\"alertIcon\" data-lucide=\"alert-circle\" class=\"w-5 h-5 flex-shrink-0 mt-0.5\"></i>\n                <div id=\"alertContent\"></div>\n            </div>\n\n            <!-- Provider Selection Toggle (Choose LootLabs or Linkvertise) -->\n            <div id=\"providerSelectContainer\" class=\"mb-6 p-4 rounded-xl bg-black/40 border border-brand-border/70 space-y-3\">\n                <div class=\"flex items-center justify-between\">\n                    <span class=\"text-xs font-bold text-gray-300 flex items-center gap-1.5\">\n                        <i data-lucide=\"sliders-horizontal\" class=\"w-4 h-4 text-purple-400\"></i>\n                        <span>Choose Checkpoint Sponsor:</span>\n                    </span>\n                    <span id=\"providerSelectHint\" class=\"text-[10px] text-gray-400\">Select provider to complete checkpoints</span>\n                </div>\n                <div class=\"grid grid-cols-2 gap-3\">\n                    <!-- LootLabs Option -->\n                    <button type=\"button\" id=\"btnOptLootlabs\" onclick=\"selectProvider('lootlabs')\" class=\"p-3 rounded-xl border border-purple-500/60 bg-purple-950/30 text-left transition flex items-center justify-between\">\n                        <div class=\"flex items-center space-x-2.5\">\n                            <div class=\"w-8 h-8 rounded-lg bg-purple-500/20 text-purple-400 flex items-center justify-center\">\n                                <i data-lucide=\"layers\" class=\"w-4 h-4\"></i>\n                            </div>\n                            <div>\n                                <div class=\"text-xs font-bold text-white flex items-center gap-1\">\n                                    <span>LootLabs</span>\n                                    <span class=\"text-[9px] px-1.5 py-0.2 rounded bg-purple-500/20 text-purple-300 font-semibold\">Recommended</span>\n                                </div>\n                                <div id=\"optLootlabsSub\" class=\"text-[10px] text-gray-400\">Fast Tasks</div>\n                            </div>\n                        </div>\n                        <div id=\"dotLootlabs\" class=\"w-4 h-4 rounded-full border-2 border-purple-500 flex items-center justify-center\">\n                            <div class=\"w-2 h-2 rounded-full bg-purple-500\"></div>\n                        </div>\n                    </button>\n\n                    <!-- Linkvertise Option -->\n                    <button type=\"button\" id=\"btnOptLinkvertise\" onclick=\"selectProvider('linkvertise')\" class=\"p-3 rounded-xl border border-brand-border/60 bg-black/20 text-left transition flex items-center justify-between\">\n                        <div class=\"flex items-center space-x-2.5\">\n                            <div class=\"w-8 h-8 rounded-lg bg-cyan-500/20 text-cyan-400 flex items-center justify-center\">\n                                <i data-lucide=\"zap\" class=\"w-4 h-4\"></i>\n                            </div>\n                            <div>\n                                <div class=\"text-xs font-bold text-white\">Linkvertise</div>\n                                <div id=\"optLinkvertiseSub\" class=\"text-[10px] text-gray-400\">Standard Shortener</div>\n                            </div>\n                        </div>\n                        <div id=\"dotLinkvertise\" class=\"w-4 h-4 rounded-full border-2 border-gray-600 flex items-center justify-center\">\n                            <div class=\"w-2 h-2 rounded-full bg-transparent\"></div>\n                        </div>\n                    </button>\n                </div>\n            </div>\n\n            <!-- STEP 1: LOOTLABS CHECKPOINT -->\n            <div id=\"cardStep1\" class=\"space-y-4\">\n                <div class=\"p-5 rounded-xl bg-purple-950/20 border border-purple-500/30 relative overflow-hidden\">\n                    <div class=\"flex items-center justify-between mb-3\">\n                        <div class=\"flex items-center space-x-3\">\n                            <div class=\"w-10 h-10 rounded-lg bg-purple-500/20 flex items-center justify-center text-purple-400\">\n                                <i data-lucide=\"layers\" class=\"w-5 h-5\"></i>\n                            </div>\n                            <div>\n                                <h3 id=\"step1Title\" class=\"font-bold text-white text-base\">Checkpoint 1: LootLabs Sponsor Task</h3>\n                                <p id=\"step1Desc\" class=\"text-xs text-gray-400\">Complete tasks on LootLabs to verify Step 1</p>\n                            </div>\n                        </div>\n                        <span id=\"step1Badge\" class=\"px-2.5 py-1 rounded-full text-xs font-semibold bg-purple-500/20 text-purple-300 border border-purple-500/30\">\n                            Ready\n                        </span>\n                    </div>\n                    <p id=\"step1Note\" class=\"text-xs text-gray-300 mb-4 leading-relaxed\">\n                        Click the button below to open LootLabs in a new tab. After finishing the quick tasks, your 24-hour key will be generated!\n                    </p>\n                    <button id=\"btnStartStep1\" onclick=\"handleStartCheckpoint(1)\" class=\"w-full py-3.5 px-4 rounded-xl bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 text-white font-bold text-sm shadow-lg shadow-purple-600/30 flex items-center justify-center space-x-2 transition transform active:scale-[0.99]\">\n                        <i data-lucide=\"external-link\" class=\"w-4 h-4\"></i>\n                        <span>Start Checkpoint 1 (LootLabs)</span>\n                    </button>\n                </div>\n            </div>\n\n            <!-- STEP 2: LINKVERTISE CHECKPOINT -->\n            <div id=\"cardStep2\" class=\"hidden space-y-4\">\n                <div class=\"p-5 rounded-xl bg-cyan-950/20 border border-cyan-500/30 relative overflow-hidden\">\n                    <div class=\"flex items-center justify-between mb-3\">\n                        <div class=\"flex items-center space-x-3\">\n                            <div class=\"w-10 h-10 rounded-lg bg-cyan-500/20 flex items-center justify-center text-cyan-400\">\n                                <i data-lucide=\"zap\" class=\"w-5 h-5\"></i>\n                            </div>\n                            <div>\n                                <h3 id=\"step2Title\" class=\"font-bold text-white text-base\">Checkpoint 2: Linkvertise Task</h3>\n                                <p id=\"step2Desc\" class=\"text-xs text-gray-400\">Complete this step to unlock your key</p>\n                            </div>\n                        </div>\n                        <span id=\"step2Badge\" class=\"px-2.5 py-1 rounded-full text-xs font-semibold bg-cyan-500/20 text-cyan-300 border border-cyan-500/30\">\n                            Final Step\n                        </span>\n                    </div>\n                    <p id=\"step2Note\" class=\"text-xs text-gray-300 mb-4 leading-relaxed\">\n                        Click below to view the Linkvertise sponsor page. Once finished, your personal 24-hour key will be generated instantly on this page!\n                    </p>\n                    <button id=\"btnStartStep2\" onclick=\"handleStartCheckpoint(2)\" class=\"w-full py-3.5 px-4 rounded-xl bg-gradient-to-r from-cyan-600 to-blue-600 hover:from-cyan-500 hover:to-blue-500 text-white font-bold text-sm shadow-lg shadow-cyan-600/30 flex items-center justify-center space-x-2 transition transform active:scale-[0.99]\">\n                        <i data-lucide=\"external-link\" class=\"w-4 h-4\"></i>\n                        <span>Start Final Checkpoint (Linkvertise)</span>\n                    </button>\n                </div>\n            </div>\n\n            <!-- CLAIMED KEY VICTORY CARD -->\n            <div id=\"cardClaimed\" class=\"hidden space-y-6 text-center\">\n                <div class=\"w-16 h-16 rounded-2xl bg-emerald-500/20 border border-emerald-500/40 text-emerald-400 mx-auto flex items-center justify-center shadow-lg shadow-emerald-500/30\">\n                    <i data-lucide=\"sparkles\" class=\"w-8 h-8\"></i>\n                </div>\n                <div>\n                    <h3 class=\"text-2xl font-black text-white\">🎉 Access Granted!</h3>\n                    <p id=\"claimedDurationSubtitle\" class=\"text-sm text-gray-400 mt-1\">Your Free License Key is ready:</p>\n                </div>\n\n                <!-- Key Display Box -->\n                <div class=\"p-4 rounded-2xl bg-black/60 border-2 border-emerald-500/40 flex flex-col sm:flex-row items-center justify-between gap-3 glow-emerald\">\n                    <div class=\"flex items-center space-x-3 w-full sm:w-auto\">\n                        <i data-lucide=\"key\" class=\"w-5 h-5 text-emerald-400 flex-shrink-0\"></i>\n                        <span id=\"claimedKeyText\" class=\"font-mono text-lg sm:text-xl font-black tracking-wider text-emerald-300 select-all break-all\">\n                            GALAXY-XXXX-XXXX-XXXX\n                        </span>\n                    </div>\n                    <button onclick=\"copyClaimedKey()\" class=\"w-full sm:w-auto px-5 py-2.5 rounded-xl bg-emerald-500 hover:bg-emerald-400 text-black font-extrabold text-sm shadow-md shadow-emerald-500/30 flex items-center justify-center space-x-2 transition\">\n                        <i data-lucide=\"clipboard-copy\" class=\"w-4 h-4\"></i>\n                        <span id=\"copyBtnText\">Copy Key</span>\n                    </button>\n                </div>\n\n                <!-- Key Info & Return Action -->\n                <div class=\"grid grid-cols-2 gap-3 text-left text-xs\">\n                    <div class=\"p-3 rounded-xl bg-white/5 border border-white/5\">\n                        <span class=\"text-gray-400 block mb-0.5\">Duration:</span>\n                        <span id=\"claimedDurationValue\" class=\"font-bold text-white\">24 Hours Active</span>\n                    </div>\n                    <div class=\"p-3 rounded-xl bg-white/5 border border-white/5\">\n                        <span class=\"text-gray-400 block mb-0.5\">Auto-Unlock in Game:</span>\n                        <span class=\"font-bold text-emerald-400\">Ready in Roblox!</span>\n                    </div>\n                </div>\n\n                <div class=\"p-4 rounded-xl bg-purple-500/10 border border-purple-500/20 text-xs text-purple-200 text-left\">\n                    💡 <strong>Pro Tip:</strong> Paste this key into the in-game Key Verification box, or simply click <strong>\"⚡ Auto-Check Claimed Key\"</strong> inside Roblox to unlock instantly without typing!\n                </div>\n            </div>\n\n            <!-- VIP Lifetime Skip Ad Notice -->\n            <div class=\"mt-8 pt-6 border-t border-brand-border/60 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-gray-400\">\n                <div class=\"flex items-center space-x-2.5\">\n                    <i data-lucide=\"crown\" class=\"w-5 h-5 text-amber-400 flex-shrink-0\"></i>\n                    <span>Tired of checkpoints? Get <strong>Permanent VIP Whitelist</strong> to skip all keys forever.</span>\n                </div>\n                <a href=\"https://discord.gg/Cpcg9wU5k\" target=\"_blank\" class=\"px-3.5 py-1.5 rounded-lg bg-amber-500/10 hover:bg-amber-500/20 text-amber-300 font-semibold border border-amber-500/20 flex-shrink-0 transition\">\n                    Get VIP Whitelist\n                </a>\n            </div>\n\n        </div>\n\n    </main>\n\n    <!-- Footer -->\n    <footer class=\"border-t border-brand-border py-4 text-center text-xs text-gray-500\">\n        &copy; 2026 Song Hub | Universal Roblox Multi-Game Automation System. All rights reserved.\n    </footer>\n\n    <!-- Client Script -->\n    <script>\n        lucide.createIcons();\n\n        // State\n        let sessionData = null;\n        const urlParams = new URLSearchParams(window.location.search);\n        const hwidParam = urlParams.get('hwid') || '';\n        const sessionParam = urlParams.get('session') || '';\n        const claimedParam = urlParams.get('claimed');\n        const stepSuccess = urlParams.get('stepSuccess');\n        const errorParam = urlParams.get('error');\n        let selectedProvider = (urlParams.get('provider') || '').toLowerCase();\n\n        if (hwidParam) {\n            document.getElementById('hwidBadge').classList.remove('hidden');\n            document.getElementById('hwidText').innerText = hwidParam;\n        }\n\n        function getStepProvider(stepNum, totalSteps, mode, chosenProvider) {\n            const m = (mode || 'dual').toLowerCase();\n            if (m === 'linkvertise') return 'linkvertise';\n            if (m === 'lootlabs') return 'lootlabs';\n            if (chosenProvider === 'linkvertise') return 'linkvertise';\n            if (chosenProvider === 'lootlabs') return 'lootlabs';\n            return (stepNum % 2 === 1) ? 'lootlabs' : 'linkvertise';\n        }\n\n        function updateProviderUI(p) {\n            selectedProvider = p;\n            const btnLoot = document.getElementById('btnOptLootlabs');\n            const btnLinkv = document.getElementById('btnOptLinkvertise');\n            const dotLoot = document.getElementById('dotLootlabs');\n            const dotLinkv = document.getElementById('dotLinkvertise');\n\n            if (!btnLoot || !btnLinkv) return;\n\n            if (p === 'lootlabs') {\n                btnLoot.className = 'p-3 rounded-xl border-2 border-purple-500 bg-purple-950/40 text-left transition flex items-center justify-between shadow-lg shadow-purple-500/20';\n                dotLoot.innerHTML = '<div class=\"w-2 h-2 rounded-full bg-purple-500\"></div>';\n                dotLoot.className = 'w-4 h-4 rounded-full border-2 border-purple-500 flex items-center justify-center';\n\n                btnLinkv.className = 'p-3 rounded-xl border border-brand-border/60 bg-black/20 text-left transition flex items-center justify-between opacity-70 hover:opacity-100';\n                dotLinkv.innerHTML = '<div class=\"w-2 h-2 rounded-full bg-transparent\"></div>';\n                dotLinkv.className = 'w-4 h-4 rounded-full border-2 border-gray-600 flex items-center justify-center';\n            } else {\n                btnLinkv.className = 'p-3 rounded-xl border-2 border-cyan-500 bg-cyan-950/40 text-left transition flex items-center justify-between shadow-lg shadow-cyan-500/20';\n                dotLinkv.innerHTML = '<div class=\"w-2 h-2 rounded-full bg-cyan-500\"></div>';\n                dotLinkv.className = 'w-4 h-4 rounded-full border-2 border-cyan-500 flex items-center justify-center';\n\n                btnLoot.className = 'p-3 rounded-xl border border-brand-border/60 bg-black/20 text-left transition flex items-center justify-between opacity-70 hover:opacity-100';\n                dotLoot.innerHTML = '<div class=\"w-2 h-2 rounded-full bg-transparent\"></div>';\n                dotLoot.className = 'w-4 h-4 rounded-full border-2 border-gray-600 flex items-center justify-center';\n            }\n        }\n\n        async function selectProvider(p) {\n            if (!sessionData || sessionData.isCompleted || sessionData.configuredMode !== 'dual') return;\n            updateProviderUI(p);\n            sessionData.provider = p;\n            renderStep(sessionData.currentStep || 1, sessionData.totalSteps || 1);\n            if (sessionData.sessionId) {\n                try {\n                    const res = await fetch('/api/v1/getkey/switch-provider', {\n                        method: 'POST',\n                        headers: { 'Content-Type': 'application/json' },\n                        body: JSON.stringify({ sessionId: sessionData.sessionId, provider: p })\n                    });\n                    const data = await res.json();\n                    if (data && data.success) {\n                        sessionData.provider = data.provider || p;\n                        sessionData.totalSteps = data.totalSteps || sessionData.totalSteps || 1;\n                        renderStep(sessionData.currentStep || 1, sessionData.totalSteps);\n                    }\n                } catch (e) {}\n            }\n        }\n\n        function applyDurationText(hours) {\n            const h = parseInt(hours) || 24;\n            const heroEl = document.getElementById('heroDurationText');\n            const subEl = document.getElementById('claimedDurationSubtitle');\n            const valEl = document.getElementById('claimedDurationValue');\n            if (heroEl) heroEl.innerText = `${h}-Hour Access Key`;\n            if (subEl) subEl.innerText = `Your ${h}-Hour Free License Key is ready:`;\n            if (valEl) valEl.innerText = `${h} Hours Active`;\n        }\n\n        function renderProgressSteps(currentStep, totalSteps, completedAll = false) {\n            const dotsRow = document.getElementById('progressDotsRow');\n            const labelsRow = document.getElementById('progressLabelsRow');\n            const progressBar = document.getElementById('progressBar');\n            const mode = (sessionData && sessionData.configuredMode) || (sessionData && sessionData.provider) || 'dual';\n\n            let dotsHtml = '';\n            let labelsHtml = '';\n\n            for (let i = 1; i <= totalSteps; i++) {\n                const chosenP = (sessionData && sessionData.provider) || selectedProvider;\n                const sp = getStepProvider(i, totalSteps, mode, chosenP);\n                const isDone = completedAll || i < currentStep;\n                const isCurrent = !completedAll && i === currentStep;\n                const activeColor = sp === 'linkvertise' ? 'border-cyan-500 shadow-cyan-500/30' : 'border-purple-500 shadow-purple-500/30';\n                const doneColor = sp === 'linkvertise' ? 'bg-cyan-600 border-cyan-500' : 'bg-purple-600 border-purple-500';\n                const labelActive = sp === 'linkvertise' ? 'text-cyan-400' : 'text-purple-400';\n                const provName = sp === 'linkvertise' ? 'Linkvertise' : 'LootLabs';\n\n                if (isDone) {\n                    dotsHtml += `<div class=\"w-9 h-9 rounded-full ${doneColor} border-2 flex items-center justify-center font-bold text-xs text-white transition\"><i data-lucide=\"check\" class=\"w-4 h-4\"></i></div>`;\n                    labelsHtml += `<span class=\"${labelActive}\">Step ${i}: ${provName}</span>`;\n                } else if (isCurrent) {\n                    dotsHtml += `<div class=\"w-9 h-9 rounded-full bg-brand-dark border-2 ${activeColor} flex items-center justify-center font-bold text-xs text-white shadow-lg transition\">${i}</div>`;\n                    labelsHtml += `<span class=\"${labelActive}\">Step ${i}: ${provName}</span>`;\n                } else {\n                    dotsHtml += `<div class=\"w-9 h-9 rounded-full bg-brand-dark border-2 border-brand-border flex items-center justify-center font-bold text-xs text-gray-400 transition\">${i}</div>`;\n                    labelsHtml += `<span>Step ${i}: ${provName}</span>`;\n                }\n            }\n\n            if (completedAll) {\n                dotsHtml += `<div id=\"claimDot\" class=\"w-9 h-9 rounded-full bg-emerald-600 border-2 border-emerald-400 flex items-center justify-center font-bold text-xs text-white shadow-lg shadow-emerald-500/40 transition\"><i data-lucide=\"check\" class=\"w-4 h-4\"></i></div>`;\n                labelsHtml += `<span id=\"claimLabel\" class=\"text-emerald-400\">Claim Key</span>`;\n                if (progressBar) progressBar.style.width = '100%';\n            } else {\n                dotsHtml += `<div id=\"claimDot\" class=\"w-9 h-9 rounded-full bg-brand-dark border-2 border-brand-border flex items-center justify-center font-bold text-xs text-gray-400 transition\"><i data-lucide=\"check\" class=\"w-4 h-4\"></i></div>`;\n                labelsHtml += `<span id=\"claimLabel\">Claim Key</span>`;\n                const pct = totalSteps <= 1 ? 35 : Math.min(90, Math.round(((currentStep - 0.5) / totalSteps) * 90));\n                if (progressBar) progressBar.style.width = `${pct}%`;\n            }\n\n            if (dotsRow) dotsRow.innerHTML = dotsHtml;\n            if (labelsRow) labelsRow.innerHTML = labelsHtml;\n        }\n\n        // Initialize Session\n        async function initSession() {\n            try {\n                if (errorParam === 'invalid_signature') {\n                    showAlert('error', 'Verification signature invalid or expired. Please try again.');\n                } else if (errorParam === 'step_order') {\n                    showAlert('error', 'Please complete the checkpoints in sequence.');\n                }\n\n                const provQuery = selectedProvider ? `&provider=${encodeURIComponent(selectedProvider)}` : '';\n                const res = await fetch(`/api/v1/getkey/init?hwid=${encodeURIComponent(hwidParam)}&session=${encodeURIComponent(sessionParam)}${provQuery}`);\n                const data = await res.json();\n\n                if (!data.success) {\n                    showAlert('error', data.error || 'Failed to initialize Get Key session');\n                    return;\n                }\n\n                sessionData = data;\n                if (data.durationHours) applyDurationText(data.durationHours);\n\n                // Case 1: Already has active key or session claimed\n                if (data.isCompleted && data.claimedKey) {\n                    showClaimedKey(data.claimedKey);\n                    return;\n                }\n\n                const keyParam = urlParams.get('key');\n                if (keyParam) {\n                    showClaimedKey(keyParam);\n                    return;\n                }\n\n                // Case 2: Render active step\n                renderStep(data.currentStep, data.totalSteps);\n\n                if (stepSuccess) {\n                    showAlert('success', `Checkpoint completed! (${data.currentStep} / ${data.totalSteps})`);\n                }\n            } catch (err) {\n                showAlert('error', 'Cannot reach key server. Please check your internet connection.');\n            }\n        }\n\n        function renderStep(currentStep, totalSteps) {\n            const total = Math.max(1, parseInt(totalSteps) || 1);\n            const cur = Math.min(Math.max(1, parseInt(currentStep) || 1), total);\n            const cfgMode = (sessionData && sessionData.configuredMode) || (sessionData && sessionData.provider) || 'dual';\n            const provSelectBox = document.getElementById('providerSelectContainer');\n\n            if (provSelectBox) {\n                if (cfgMode === 'dual') {\n                    provSelectBox.classList.remove('hidden');\n                    const activeProv = (sessionData && sessionData.provider === 'linkvertise') || (!sessionData?.provider && selectedProvider === 'linkvertise')\n                        ? 'linkvertise'\n                        : 'lootlabs';\n                    updateProviderUI(activeProv);\n                    const hintEl = document.getElementById('providerSelectHint');\n                    const lootSub = document.getElementById('optLootlabsSub');\n                    const linkSub = document.getElementById('optLinkvertiseSub');\n                    if (hintEl) hintEl.innerText = total > 1 ? `Applies to all ${total} checkpoints` : 'Select one provider to get key';\n                    if (lootSub) lootSub.innerText = `${total} Checkpoint${total > 1 ? 's' : ''} • Fast Tasks`;\n                    if (linkSub) linkSub.innerText = `${total} Checkpoint${total > 1 ? 's' : ''} • Standard Shortener`;\n                } else {\n                    provSelectBox.classList.add('hidden');\n                }\n            }\n\n            const chosenProv = (sessionData && sessionData.provider) || selectedProvider || 'lootlabs';\n            const stepProvider = getStepProvider(cur, total, cfgMode, chosenProv);\n            const durHours = (sessionData && sessionData.durationHours) || 24;\n\n            renderProgressSteps(cur, total, false);\n\n            const cardStep1 = document.getElementById('cardStep1');\n            const cardStep2 = document.getElementById('cardStep2');\n            const cardClaimed = document.getElementById('cardClaimed');\n            cardClaimed.classList.add('hidden');\n\n            const isFinal = cur === total;\n            const badgeText = total === 1 ? '1 Step Only' : (isFinal ? `Final Step (${cur}/${total})` : `Step ${cur} of ${total}`);\n\n            if (stepProvider === 'linkvertise') {\n                cardStep1.classList.add('hidden');\n                cardStep2.classList.remove('hidden');\n                document.getElementById('step2Title').innerText = `Checkpoint ${cur}/${total}: Linkvertise Task`;\n                document.getElementById('step2Badge').innerText = badgeText;\n                document.getElementById('step2Desc').innerText = isFinal\n                    ? `Complete this final Linkvertise task to unlock your ${durHours}-hour key!`\n                    : `Complete Linkvertise checkpoint ${cur} of ${total} to advance to the next step.`;\n                document.getElementById('btnStartStep2').innerHTML = `<i data-lucide=\"external-link\" class=\"w-4 h-4\"></i><span>${isFinal ? `Start Final Checkpoint ${cur}/${total} (Linkvertise)` : `Start Checkpoint ${cur}/${total} (Linkvertise)`}</span>`;\n                document.getElementById('btnStartStep2').onclick = function() { handleStartCheckpoint(cur); };\n            } else {\n                cardStep1.classList.remove('hidden');\n                cardStep2.classList.add('hidden');\n                document.getElementById('step1Title').innerText = `Checkpoint ${cur}/${total}: LootLabs Sponsor Task`;\n                document.getElementById('step1Badge').innerText = badgeText;\n                document.getElementById('step1Desc').innerText = isFinal\n                    ? `Complete this final LootLabs task to receive your ${durHours}-hour key!`\n                    : `Complete LootLabs checkpoint ${cur} of ${total} to advance to the next step.`;\n                document.getElementById('step1Note').innerText = isFinal\n                    ? `Click the button below to complete Checkpoint ${cur} of ${total}. Once finished, your ${durHours}-hour key will be generated immediately!`\n                    : `Click the button below to complete Checkpoint ${cur} of ${total}. After completing it, you will automatically return for Checkpoint ${cur + 1} of ${total}.`;\n                document.getElementById('btnStartStep1').innerHTML = `<i data-lucide=\"external-link\" class=\"w-4 h-4\"></i><span>${isFinal ? `Start Final Checkpoint ${cur}/${total} (LootLabs)` : `Start Checkpoint ${cur}/${total} (LootLabs)`}</span>`;\n                document.getElementById('btnStartStep1').onclick = function() { handleStartCheckpoint(cur); };\n            }\n            lucide.createIcons();\n        }\n\n        async function handleStartCheckpoint(step) {\n            if (!sessionData || !sessionData.sessionId) {\n                showAlert('error', 'Session not initialized.');\n                return;\n            }\n\n            const btn = !document.getElementById('cardStep1').classList.contains('hidden')\n                ? document.getElementById('btnStartStep1')\n                : document.getElementById('btnStartStep2');\n            btn.disabled = true;\n            btn.innerHTML = '<i data-lucide=\"loader\" class=\"w-4 h-4 animate-spin\"></i><span>Generating Sponsor Link...</span>';\n            lucide.createIcons();\n\n            try {\n                const res = await fetch(`/api/v1/getkey/link?sessionId=${encodeURIComponent(sessionData.sessionId)}&step=${step}`);\n                const data = await res.json();\n\n                if (data.success && data.redirectUrl) {\n                    btn.innerHTML = '<i data-lucide=\"check\" class=\"w-4 h-4\"></i><span>Redirecting...</span>';\n                    window.location.href = data.redirectUrl;\n                } else {\n                    btn.disabled = false;\n                    btn.innerHTML = `<i data-lucide=\"external-link\" class=\"w-4 h-4\"></i><span>Retry Checkpoint ${step}</span>`;\n                    showAlert('error', data.error || 'Failed to generate monetized link');\n                }\n            } catch (err) {\n                btn.disabled = false;\n                btn.innerHTML = `<i data-lucide=\"external-link\" class=\"w-4 h-4\"></i><span>Retry Checkpoint ${step}</span>`;\n                showAlert('error', 'Network error generating sponsor link.');\n            }\n        }\n\n        function showClaimedKey(key) {\n            const provSelectBox = document.getElementById('providerSelectContainer');\n            if (provSelectBox) provSelectBox.classList.add('hidden');\n            document.getElementById('cardStep1').classList.add('hidden');\n            document.getElementById('cardStep2').classList.add('hidden');\n            document.getElementById('cardClaimed').classList.remove('hidden');\n            document.getElementById('claimedKeyText').innerText = key;\n\n            const total = (sessionData && sessionData.totalSteps) || 1;\n            renderProgressSteps(total, total, true);\n\n            // Confetti Blast\n            if (typeof confetti === 'function') {\n                confetti({\n                    particleCount: 100,\n                    spread: 70,\n                    origin: { y: 0.6 }\n                });\n            }\n            lucide.createIcons();\n        }\n\n        function copyClaimedKey() {\n            const key = document.getElementById('claimedKeyText').innerText.trim();\n            if (!key) return;\n\n            navigator.clipboard.writeText(key).then(() => {\n                const copyBtnText = document.getElementById('copyBtnText');\n                copyBtnText.innerText = 'Copied!';\n                setTimeout(() => { copyBtnText.innerText = 'Copy Key'; }, 2500);\n            });\n        }\n\n        function showAlert(type, message) {\n            const box = document.getElementById('alertBox');\n            const icon = document.getElementById('alertIcon');\n            const content = document.getElementById('alertContent');\n\n            box.classList.remove('hidden');\n            if (type === 'error') {\n                box.className = 'mb-6 p-4 rounded-xl text-sm flex items-start space-x-3 bg-red-950/40 border border-red-500/30 text-red-300';\n                icon.setAttribute('data-lucide', 'alert-circle');\n            } else {\n                box.className = 'mb-6 p-4 rounded-xl text-sm flex items-start space-x-3 bg-emerald-950/40 border border-emerald-500/30 text-emerald-300';\n                icon.setAttribute('data-lucide', 'check-circle');\n            }\n            content.innerText = message;\n            lucide.createIcons();\n        }\n\n        // Run\n        initSession();\n    </script>\n</body>\n</html>\n";
const FALLBACK_LOADER_LUAU = "-- ==============================================================================\n-- 🚀 SONG HUB - UNIVERSAL LOADER (POWERED BY CLOUDFLARE EDGE AUTH)\n-- Supported Games:\n--   1. ⚔️  Anime Galaxies (PlaceId: 83869074416117 / 85423571424083)\n--   2. 🎃 Hunting Together (Universe: 10769401924 / Place: 117483759937632)\n--   3. ⚽ Blue Lock Farm (Universe: 10700618962 / Place: 132767904294856)\n--   4. 🥪 Throw Food For Animals (Universe: 10766972131 / Place: 120219252362013)\n--   5. 🏎️  Raycity RB (Universe: 10772794231 / Place: 117419079466193)\n--   6. ⚔️  GloryBound (Universe: 10768652372 / Place: 137629355240872)\n--   7. 📖 Era dos Grimórios (Universe: 10770749098 / Place: 120299741604934)\n--   8. 🐟 Net a Fish! (Universe: 10771053183 / Place: 93898234979111)\n-- ==============================================================================\n\nif getgenv then\n    getgenv()._SongHubLoading = false\n    getgenv()._SongHubLastLoad = os.clock()\n    getgenv()._SongHubRevokeCallbacks = getgenv()._SongHubRevokeCallbacks or {}\n    getgenv()._SongHubSessionGeneration = tonumber(getgenv()._SongHubSessionGeneration) or 0\nend\n\nif not game:IsLoaded() then\n    pcall(function() game.Loaded:Wait() end)\n    local t0 = tick()\n    while not game:IsLoaded() and (tick() - t0) < 20 do\n        task.wait(0.25)\n    end\nend\n\nlocal Players = game:GetService(\"Players\")\nlocal LocalPlayer = Players.LocalPlayer\nif not LocalPlayer then\n    local t0 = tick()\n    while not Players.LocalPlayer and (tick() - t0) < 15 do\n        task.wait(0.25)\n    end\n    LocalPlayer = Players.LocalPlayer\nend\n\n-- ==============================================================================\n-- 1. DETECT GAME\n-- ==============================================================================\nlocal function detectGame()\n    local pId = game.PlaceId\n    local uId = game.GameId\n    local t0 = tick()\n    while (uId == 0 or pId == 0) and (tick() - t0 < 3) do\n        task.wait(0.2)\n        pId = game.PlaceId\n        uId = game.GameId\n    end\n\n    -- 0. Jump for Cases🎲\n    if uId == 10767621216 or pId == 93545804988403\n        or (game:GetService(\"ReplicatedStorage\"):FindFirstChild(\"CasesConfig\") and game:GetService(\"ReplicatedStorage\"):FindFirstChild(\"Remotes\") and game:GetService(\"ReplicatedStorage\").Remotes:FindFirstChild(\"RequestKick\")) then\n        return \"Jump for Cases🎲\", \"jump_for_cases.luau\"\n    end\n\n    -- 0. Net a Fish! 🐟\n    if uId == 10771053183 or pId == 93898234979111\n        or (game:GetService(\"ReplicatedStorage\"):FindFirstChild(\"Remotes\") and game:GetService(\"ReplicatedStorage\").Remotes:FindFirstChild(\"ThrowNet\")) then\n        return \"Net a Fish! 🐟\", \"net_a_fish.luau\"\n    end\n\n    -- 0.1 Era dos Grimórios 📖 (Check first)\n    if uId == 10770749098 or pId == 120299741604934\n        or (game:GetService(\"ReplicatedStorage\"):FindFirstChild(\"Rep_Core\") and game:GetService(\"ReplicatedStorage\").Rep_Core:FindFirstChild(\"Magics\"))\n        or (game:GetService(\"ReplicatedStorage\"):FindFirstChild(\"Rep_Core\") and game:GetService(\"ReplicatedStorage\").Rep_Core:FindFirstChild(\"Events\") and game:GetService(\"ReplicatedStorage\").Rep_Core.Events:FindFirstChild(\"GrimoireSpinsV2\")) then\n        return \"Era dos Grimórios 📖\", \"era_dos_grimorios.luau\"\n    end\n\n    -- 1. GloryBound ⚔️  (Check first or by unique remotes)\n    if uId == 10768652372 or pId == 137629355240872\n        or (game:GetService(\"ReplicatedStorage\"):FindFirstChild(\"Remotes\") and (game:GetService(\"ReplicatedStorage\").Remotes:FindFirstChild(\"TrainRep\") or game:GetService(\"ReplicatedStorage\").Remotes:FindFirstChild(\"TrainStop\")))\n        or (workspace:FindFirstChild(\"Lobby\") and workspace.Lobby:FindFirstChild(\"Gym\"))\n        or (workspace:FindFirstChild(\"Lobby\") and workspace.Lobby:FindFirstChild(\"Stations\") and workspace.Lobby.Stations:FindFirstChild(\"RebirthShrine\")) then\n        return \"GloryBound ⚔️\", \"glorybound.luau\"\n    end\n\n    -- 2. Anime Galaxies ✨\n    if uId == 10770748262 or pId == 83869074416117 or pId == 85423571424083\n        or (game:GetService(\"ReplicatedStorage\"):FindFirstChild(\"Remotes\") and game:GetService(\"ReplicatedStorage\").Remotes:FindFirstChild(\"TowerDefense\")) then\n        return \"Anime Galaxies ✨\", \"anime_galaxies.luau\"\n    end\n\n    -- 3. Hunting Together 🎃\n    if uId == 10769401924 or pId == 117483759937632 or game:GetService(\"ReplicatedStorage\"):FindFirstChild(\"HalloweenRemotes\") or workspace:FindFirstChild(\"Pumpkins\") then\n        return \"Hunting Together 🎃\", \"hunting_together.luau\"\n    end\n\n    -- 4. Blue Lock Farm ⚽\n    if uId == 10700618962 or pId == 132767904294856 or game:GetService(\"ReplicatedStorage\"):FindFirstChild(\"FootballRemotes\") or workspace:FindFirstChild(\"Goals\") then\n        return \"Blue Lock Farm ⚽\", \"blue_lock_farm.luau\"\n    end\n\n    -- 5. Throw Food For Animals 🥪\n    if uId == 10766972131 or pId == 120219252362013 or game:GetService(\"ReplicatedStorage\"):FindFirstChild(\"AnimalRemotes\") or workspace:FindFirstChild(\"FeederStands\") then\n        return \"Throw Food For Animals 🥪\", \"throw_food.luau\"\n    end\n\n    -- 6. Raycity RB 🏎️\n    if uId == 10772794231 or pId == 117419079466193 or game:GetService(\"ReplicatedStorage\"):FindFirstChild(\"RCDrive\") or workspace:FindFirstChild(\"MyCar\") then\n        return \"Raycity RB 🏎️\", \"raycity_rb.luau\"\n    end\n\n    -- Fallback: MarketplaceService Title\n    local ok, info = pcall(function() return game:GetService(\"MarketplaceService\"):GetProductInfo(pId) end)\n    if ok and info and info.Name then\n        local t = info.Name:lower()\n        if t:find(\"jump for cases\") or t:find(\"jump for case\") then return \"Jump for Cases🎲\", \"jump_for_cases.luau\" end\n        if t:find(\"net a fish\") or t:find(\"fishing\") then return \"Net a Fish! 🐟\", \"net_a_fish.luau\" end\n        if t:find(\"grimorio\") or t:find(\"grimoire\") or t:find(\"clover\") then return \"Era dos Grimórios 📖\", \"era_dos_grimorios.luau\" end\n        if t:find(\"glorybound\") or t:find(\"gladiator\") or t:find(\"trials\") then return \"GloryBound ⚔️\", \"glorybound.luau\" end\n        if t:find(\"anime galaxies\") then return \"Anime Galaxies ✨\", \"anime_galaxies.luau\" end\n        if t:find(\"hunting together\") then return \"Hunting Together 🎃\", \"hunting_together.luau\" end\n        if t:find(\"blue lock\") then return \"Blue Lock Farm ⚽\", \"blue_lock_farm.luau\" end\n        if t:find(\"throw food\") then return \"Throw Food For Animals 🥪\", \"throw_food.luau\" end\n        if t:find(\"raycity\") then return \"Raycity RB 🏎️\", \"raycity_rb.luau\" end\n    end\n\n    return nil, nil\nend\n\nlocal gameTitle, scriptFileName = detectGame()\nif not scriptFileName then\n    warn(\"[Song Hub] ❌ Current game (PlaceId: \" .. tostring(game.PlaceId) .. \") is not supported!\")\n    return\nend\n\nlocal cleanFileName = scriptFileName:gsub(\"^games/\", \"\"):gsub(\"^/\", \"\")\n\n-- Guard against duplicate executions\nif getgenv and getgenv()._GloryBoundRunning and getgenv()._GB_Window and cleanFileName == \"glorybound.luau\" and not getgenv()._GB_ForceReload then\n    print(\"[Song Hub] 🛡️ GloryBound is already running with active UI. Skipping duplicate execution.\")\n    if getgenv then getgenv()._SongHubLoading = false end\n    return\nend\n\n-- ==============================================================================\n-- 2. CLOUDFLARE EDGE AUTHENTICATION (WHITELIST & KEY SYSTEM)\n-- ==============================================================================\nlocal HttpService = game:GetService(\"HttpService\")\nlocal CLOUDFLARE_URL = \"https://song-hub-whitelist.song-hub-cloudflare-worker.workers.dev\"\nlocal SERVER_VERIFY_URL = CLOUDFLARE_URL .. \"/api/verify-key\"\nlocal GET_KEY_PORTAL_URL = CLOUDFLARE_URL .. \"/getkey\"\nlocal DISCORD_INVITE_URL = \"https://discord.gg/Cpcg9wU5k\"\nlocal KEY_SAVE_PATH = \"SongHub/saved_license_key.txt\"\n\nlocal function getHardwareId()\n    if gethwid then return gethwid() end\n    if get_hwid then return get_hwid() end\n    if identifyexecutor then\n        local exec = identifyexecutor()\n        return exec .. \"_\" .. tostring(LocalPlayer.UserId)\n    end\n    return \"DEVICE_\" .. tostring(LocalPlayer.UserId)\nend\n\nlocal function sendVerifyRequest(key)\n    local requestFn = (syn and syn.request) or request or (http and http.request) or http_request\n    if not requestFn then\n        return false, { message = \"Your executor does not support HTTP requests!\" }\n    end\n\n    local cleanReqKey = (type(key) == \"string\") and key:gsub(\"[^%w%-_]+\", \"\") or \"\"\n    local payload = HttpService:JSONEncode({\n        key = cleanReqKey,\n        hwid = getHardwareId(),\n        userId = LocalPlayer.UserId,\n        username = LocalPlayer.Name,\n        jobId = game.JobId or \"\",\n        placeId = tostring(game.PlaceId or \"\")\n    })\n\n    local success, response = pcall(requestFn, {\n        Url = SERVER_VERIFY_URL,\n        Method = \"POST\",\n        Headers = { [\"Content-Type\"] = \"application/json\" },\n        Body = payload\n    })\n\n    local rawBody = response and (response.Body or response.body)\n    if not success or not response or type(rawBody) ~= \"string\" then\n        return false, { message = \"Could not connect to Cloudflare Auth Edge!\" }\n    end\n\n    local data = nil\n    pcall(function() data = HttpService:JSONDecode(rawBody) end)\n    if not data then return false, { message = \"Server returned invalid response.\" } end\n    return data.success == true, data\nend\n\nlocal openKeyVerificationWindow\n\nlocal function clearSavedLicenseKey()\n    pcall(function()\n        if delfile and isfile and isfile(KEY_SAVE_PATH) then\n            delfile(KEY_SAVE_PATH)\n        end\n    end)\nend\n\nlocal function destroyAllSongHubUIs()\n    if getgenv then\n        local cbs = getgenv()._SongHubRevokeCallbacks\n        if type(cbs) == \"table\" then\n            getgenv()._SongHubRevokeCallbacks = {}\n            for _, cb in pairs(cbs) do\n                if type(cb) == \"function\" then\n                    pcall(cb)\n                end\n            end\n        end\n\n        if getgenv().AnimeGalaxiesHubShutdown then\n            pcall(getgenv().AnimeGalaxiesHubShutdown)\n        end\n\n        local winKeys = {\n            \"_SongHubKeyPromptWindow\", \"_HT_CurrentWindow\", \"__BlueLockFarmWindow\",\n            \"__ThrowFoodWindow\", \"_JFC_Window\", \"_NetAFish_Window\",\n            \"_Grimorio_Window\", \"_GB_Window\", \"__RaycityHubWindow\", \"_AG_Window\"\n        }\n        getgenv()._SongHubKeyPromptOpen = false\n        for _, k in ipairs(winKeys) do\n            local w = getgenv()[k]\n            if w and type(w) == \"table\" and w.Destroy then\n                pcall(function() w:Destroy() end)\n            end\n            getgenv()[k] = nil\n        end\n\n        if getgenv()._HT_WindUI and type(getgenv()._HT_WindUI) == \"table\" then\n            pcall(function()\n                local wui = getgenv()._HT_WindUI\n                if wui.ScreenGui then wui.ScreenGui:Destroy() end\n                if wui.NotificationGui then wui.NotificationGui:Destroy() end\n                if wui.DropdownGui then wui.DropdownGui:Destroy() end\n                if wui.TooltipGui then wui.TooltipGui:Destroy() end\n            end)\n            getgenv()._HT_WindUI = nil\n        end\n\n        getgenv()._HT_ScriptRunId = -1\n        getgenv()._HuntingTogetherRunning = false\n        getgenv()._AG_RUNNING = nil\n        getgenv().__BlueLockFarmRunId = -1\n        getgenv()._GrimorioRunId = -1\n        getgenv()._GloryBoundRunId = -1\n        getgenv()._JumpForCasesRunning = -1\n        getgenv()._NetAFishRunId = -1\n        getgenv().__RaycityHubRunId = -1\n        getgenv().__ThrowFoodRunId = -1\n    end\n\n    pcall(function()\n        local containers = {}\n        pcall(function() if gethui then table.insert(containers, gethui()) end end)\n        pcall(function()\n            local cg = game:GetService(\"CoreGui\")\n            table.insert(containers, cg)\n            local rg = cg:FindFirstChild(\"RobloxGui\")\n            if rg then table.insert(containers, rg) end\n        end)\n        pcall(function()\n            if LocalPlayer then\n                local pg = LocalPlayer:FindFirstChildOfClass(\"PlayerGui\")\n                if pg then table.insert(containers, pg) end\n            end\n        end)\n        for _, root in ipairs(containers) do\n            if root then\n                for _, c in ipairs(root:GetChildren()) do\n                    if c:IsA(\"ScreenGui\") then\n                        local n = c.Name\n                        if n:find(\"WindUI\", 1, true)\n                            or n:find(\"SongHub\", 1, true)\n                            or n:find(\"Raycity\", 1, true)\n                            or n:find(\"Hunting\", 1, true)\n                            or n:find(\"BlueLock\", 1, true)\n                            or n:find(\"AnimeGalaxies\", 1, true)\n                            or n:find(\"Grimorio\", 1, true)\n                            or n:find(\"GloryBound\", 1, true)\n                            or n:find(\"NetAFish\", 1, true)\n                            or n:find(\"ThrowFood\", 1, true)\n                            or n:find(\"JumpForCases\", 1, true)\n                            or n:find(\"JFC\", 1, true)\n                        then\n                            pcall(function() c:Destroy() end)\n                        end\n                    end\n                end\n            end\n        end\n    end)\nend\n\nlocal function shutdownActiveScript(reason, reopenPrompt)\n    local msg = (type(reason) == \"string\" and #reason > 0) and reason or \"Your license key has expired or session was terminated.\"\n    warn(\"[Song Hub] 🔒 Session Ended: \" .. msg)\n\n    if getgenv then\n        if getgenv()._SongHubShuttingDown then\n            return\n        end\n        getgenv()._SongHubShuttingDown = true\n        getgenv()._SongHubSessionExpired = true\n        getgenv()._SongHubSessionGeneration = (tonumber(getgenv()._SongHubSessionGeneration) or 0) + 1\n        getgenv()._SongHubHeartbeatRunning = false\n        getgenv()._SongHubLoading = false\n        getgenv()._SongHubAuth = {\n            valid = false,\n            revoked = true,\n            reason = msg,\n            endedClock = os.clock(),\n        }\n        local activeThread = getgenv()._SongHubActiveGameThread\n        getgenv()._SongHubActiveGameThread = nil\n        if activeThread then\n            pcall(task.cancel, activeThread)\n        end\n    end\n\n    clearSavedLicenseKey()\n    destroyAllSongHubUIs()\n\n    if getgenv then\n        getgenv()._SongHubShuttingDown = false\n    end\n\n    if reopenPrompt ~= false and type(openKeyVerificationWindow) == \"function\" then\n        task.spawn(function()\n            task.wait(0.2)\n            openKeyVerificationWindow(msg)\n        end)\n    end\nend\n\nlocal function applyAuthenticatedSession(authData, activeKey)\n    local serverTime = tonumber(authData and authData.serverTime)\n    local expiresAt = tonumber(authData and authData.expiresAt)\n    local whitelisted = (authData and authData.whitelisted == true) or false\n    local expiresAtClock = nil\n\n    if expiresAt and expiresAt > 0 then\n        local baseTime = (serverTime and serverTime > 0) and serverTime or os.time()\n        local remainingSec = expiresAt - baseTime\n        if remainingSec <= 0 then\n            return false, \"Your license key has expired.\"\n        end\n        expiresAtClock = os.clock() + remainingSec\n    end\n\n    if getgenv then\n        getgenv()._SongHubSessionGeneration = (tonumber(getgenv()._SongHubSessionGeneration) or 0) + 1\n        getgenv()._SongHubSessionExpired = false\n        getgenv()._SongHubShuttingDown = false\n        getgenv()._SongHubKeyPromptOpen = false\n        getgenv()._SongHubAuth = {\n            valid = true,\n            revoked = false,\n            whitelisted = whitelisted,\n            key = activeKey or \"\",\n            sessionToken = (authData and authData.sessionToken) or \"\",\n            expiresAt = expiresAt,\n            serverTime = serverTime,\n            expiresAtClock = expiresAtClock,\n            verifiedClock = os.clock(),\n        }\n    end\n    return true, nil\nend\n\nlocal function startSessionHeartbeat(sessionToken, activeKey, authInfo)\n    if not sessionToken or #sessionToken == 0 then return end\n    local myGen = getgenv and getgenv()._SongHubSessionGeneration or 0\n    if getgenv then getgenv()._SongHubHeartbeatRunning = true end\n\n    local currentToken = sessionToken\n    if getgenv and type(getgenv()._SongHubAuth) == \"table\" and getgenv()._SongHubAuth.sessionToken and #getgenv()._SongHubAuth.sessionToken > 0 then\n        currentToken = getgenv()._SongHubAuth.sessionToken\n    elseif type(authInfo) == \"table\" and tonumber(authInfo.expiresAt) and tonumber(authInfo.expiresAt) > 0 then\n        applyAuthenticatedSession(authInfo, activeKey)\n        myGen = getgenv and getgenv()._SongHubSessionGeneration or myGen\n    end\n\n    task.spawn(function()\n        local heartbeatUrl = CLOUDFLARE_URL .. \"/api/v1/heartbeat\"\n        local requestFn = (syn and syn.request) or request or (http and http.request) or http_request\n\n        while true do\n            if getgenv and (getgenv()._SongHubSessionExpired == true or getgenv()._SongHubSessionGeneration ~= myGen) then\n                break\n            end\n\n            local authState = getgenv and getgenv()._SongHubAuth\n            local expiresAtClock = authState and tonumber(authState.expiresAtClock) or nil\n            local waitSec = 20\n            if expiresAtClock then\n                local left = expiresAtClock - os.clock()\n                if left <= 0 then\n                    waitSec = 0\n                elseif left < waitSec then\n                    waitSec = math.max(0.5, left)\n                end\n            end\n\n            if waitSec > 0 then\n                task.wait(waitSec)\n            end\n\n            if getgenv and (getgenv()._SongHubSessionExpired == true or getgenv()._SongHubSessionGeneration ~= myGen) then\n                break\n            end\n\n            authState = getgenv and getgenv()._SongHubAuth\n            expiresAtClock = authState and tonumber(authState.expiresAtClock) or nil\n\n            local okReq, resp = false, nil\n            if requestFn then\n                okReq, resp = pcall(requestFn, {\n                    Url = heartbeatUrl,\n                    Method = \"POST\",\n                    Headers = { [\"Content-Type\"] = \"application/json\" },\n                    Body = HttpService:JSONEncode({\n                        sessionToken = currentToken,\n                        key = activeKey or \"\"\n                    })\n                })\n            end\n\n            if getgenv and (getgenv()._SongHubSessionExpired == true or getgenv()._SongHubSessionGeneration ~= myGen) then\n                break\n            end\n\n            local shouldRevoke = false\n            local revokeReason = \"Your license key has expired or session was closed.\"\n            local gotValidAck = false\n\n            if okReq and type(resp) == \"table\" then\n                local status = tonumber(resp.StatusCode or resp.status_code) or 200\n                local rawBody = resp.Body or resp.body\n                local decoded = nil\n                if type(rawBody) == \"string\" and #rawBody > 0 then\n                    pcall(function() decoded = HttpService:JSONDecode(rawBody) end)\n                end\n\n                if status == 401 or status == 403 then\n                    shouldRevoke = true\n                    if type(decoded) == \"table\" and type(decoded.message) == \"string\" and #decoded.message > 0 then\n                        revokeReason = decoded.message\n                    end\n                elseif type(decoded) == \"table\" and (decoded.active == false or decoded.success == false) then\n                    shouldRevoke = true\n                    if type(decoded.message) == \"string\" and #decoded.message > 0 then\n                        revokeReason = decoded.message\n                    end\n                elseif status >= 200 and status < 300 and type(decoded) == \"table\" and decoded.active == true then\n                    gotValidAck = true\n                    if type(decoded.refreshedToken) == \"string\" and #decoded.refreshedToken > 0 then\n                        currentToken = decoded.refreshedToken\n                        if authState then authState.sessionToken = currentToken end\n                    end\n                    local newExp = tonumber(decoded.expiresAt)\n                    local newSrv = tonumber(decoded.serverTime)\n                    if decoded.whitelisted == true and (not newExp or newExp <= 0) then\n                        if authState then\n                            authState.expiresAt = nil\n                            authState.expiresAtClock = nil\n                        end\n                        expiresAtClock = nil\n                    elseif newExp and newExp > 0 then\n                        local baseT = (newSrv and newSrv > 0) and newSrv or os.time()\n                        local rem = newExp - baseT\n                        if rem <= 0 then\n                            shouldRevoke = true\n                            revokeReason = \"Your license key has expired.\"\n                        elseif authState then\n                            authState.expiresAt = newExp\n                            authState.serverTime = newSrv\n                            authState.expiresAtClock = os.clock() + rem\n                            expiresAtClock = authState.expiresAtClock\n                        end\n                    end\n                end\n            end\n\n            if not shouldRevoke and not gotValidAck and expiresAtClock and os.clock() >= expiresAtClock then\n                shouldRevoke = true\n                revokeReason = \"Your license key has expired.\"\n            end\n\n            if shouldRevoke then\n                shutdownActiveScript(revokeReason, true)\n                break\n            end\n\n            if not requestFn or (not gotValidAck and waitSec == 0) then\n                task.wait(5)\n            end\n        end\n\n        if getgenv and getgenv()._SongHubSessionGeneration == myGen then\n            getgenv()._SongHubHeartbeatRunning = false\n        end\n    end)\n\n    pcall(function()\n        if LocalPlayer and LocalPlayer.OnTeleport then\n            LocalPlayer.OnTeleport:Connect(function()\n                if getgenv and getgenv()._SongHubSessionGeneration ~= myGen then return end\n                pcall(function()\n                    local requestFn = (syn and syn.request) or request or (http and http.request) or http_request\n                    if requestFn then\n                        requestFn({\n                            Url = CLOUDFLARE_URL .. \"/api/v1/session/close\",\n                            Method = \"POST\",\n                            Headers = { [\"Content-Type\"] = \"application/json\" },\n                            Body = HttpService:JSONEncode({ sessionToken = currentToken })\n                        })\n                    end\n                end)\n            end)\n        end\n    end)\nend\n\nlocal lastFetchError = nil\nlocal lastFetchDenied = false\nlocal lastFetchDeniedReason = nil\nlocal function fetchVerifiedLua(url)\n    lastFetchError = nil\n    lastFetchDenied = false\n    lastFetchDeniedReason = nil\n\n    local function checkAccessDeniedText(body)\n        if type(body) == \"string\" then\n            local head = body:sub(1, 512):gsub(\"^%s+\", \"\")\n            local deniedMsg = head:match(\"^%-%-%s*ACCESS_DENIED:%s*(.-)[\\r\\n]\") or head:match(\"^%-%-%s*ACCESS_DENIED:%s*(.+)$\")\n            if deniedMsg or head:find(\"ACCESS_DENIED\", 1, true) then\n                lastFetchDenied = true\n                lastFetchDeniedReason = deniedMsg or \"Access denied: Your license key has expired or session is invalid.\"\n                lastFetchError = lastFetchDeniedReason\n                return true\n            end\n        end\n        return false\n    end\n\n    local function isValidCode(body)\n        if checkAccessDeniedText(body) then\n            return nil\n        end\n        if type(body) ~= \"string\" or #body <= 500 then\n            lastFetchError = \"body too short (\" .. tostring(type(body) == \"string\" and #body or type(body)) .. \")\"\n            return nil\n        end\n        local head = body:sub(1, 512):gsub(\"^%s+\", \"\")\n        if head == \"\" or head:sub(1, 1) == \"<\" then\n            lastFetchError = \"HTML or empty response\"\n            return nil\n        end\n        if head:find(\"403\" .. \": Forbidden\", 1, true) or head:find(\"404\" .. \": Not Found\", 1, true) or head:find(\"-- Game script\" .. \" not found\", 1, true) or head:find(\"DEPLOYMENT_DISABLED\", 1, true) then\n            lastFetchError = \"HTTP error response: \" .. head:sub(1, 48)\n            return nil\n        end\n        local fn, err = loadstring(body)\n        if fn then\n            return fn\n        end\n        lastFetchError = \"loadstring error: \" .. tostring(err)\n        return nil\n    end\n\n    local httpGet403 = false\n    local ok1, res1 = pcall(function()\n        return game:HttpGet(url)\n    end)\n    if ok1 then\n        local fn = isValidCode(res1)\n        if fn then\n            return res1, fn\n        end\n        if lastFetchDenied then return nil, nil end\n    else\n        local errStr = tostring(res1)\n        lastFetchError = \"game:HttpGet error: \" .. errStr\n        if errStr:find(\"403\", 1, true) or errStr:find(\"Forbidden\", 1, true) then\n            httpGet403 = true\n        end\n    end\n\n    if type(HttpGet) == \"function\" and not httpGet403 then\n        local ok2, res2 = pcall(HttpGet, url)\n        if ok2 then\n            local fn = isValidCode(res2)\n            if fn then\n                return res2, fn\n            end\n            if lastFetchDenied then return nil, nil end\n        end\n    end\n\n    local requestFn = (syn and syn.request) or request or (http and http.request) or http_request\n    if requestFn then\n        local reqTries = {\n            {\n                Url = url,\n                Method = \"GET\",\n                Headers = {\n                    [\"Cache-Control\"] = \"no-cache, no-store, must-revalidate\",\n                    [\"Pragma\"] = \"no-cache\",\n                }\n            },\n            {\n                Url = url,\n                Method = \"GET\",\n            }\n        }\n        for _, reqOpts in ipairs(reqTries) do\n            local rOk, resp = pcall(requestFn, reqOpts)\n            if rOk and type(resp) == \"table\" then\n                local status = tonumber(resp.StatusCode or resp.status_code) or 200\n                local body = resp.Body or resp.body\n                if status == 401 or status == 403 then\n                    if not checkAccessDeniedText(body) then\n                        lastFetchDenied = true\n                        lastFetchDeniedReason = \"Access denied (HTTP \" .. tostring(status) .. \"): Key expired or invalid session.\"\n                        lastFetchError = lastFetchDeniedReason\n                    end\n                    return nil, nil\n                elseif status >= 200 and status < 300 and type(body) == \"string\" then\n                    local fn = isValidCode(body)\n                    if fn then\n                        return body, fn\n                    end\n                    if lastFetchDenied then return nil, nil end\n                else\n                    lastFetchError = \"request status \" .. tostring(status)\n                end\n            elseif not rOk then\n                lastFetchError = \"request error: \" .. tostring(resp)\n            end\n        end\n    elseif httpGet403 then\n        lastFetchDenied = true\n        lastFetchDeniedReason = \"Access denied (HTTP 403): Key expired or invalid session.\"\n    end\n\n    return nil, nil\nend\n\nlocal function launchGameScript(sessionToken, activeKey)\n    if getgenv and getgenv()._SongHubSessionExpired == true then\n        if getgenv then getgenv()._SongHubLoading = false end\n        return\n    end\n\n    print(string.format(\"[Song Hub] 🚀 Launching %s securely...\", gameTitle))\n    local tokenQuery = (sessionToken and #sessionToken > 0) and (\"&token=\" .. sessionToken) or \"\"\n    local keyQuery = (activeKey and #activeKey > 0) and (\"&key=\" .. activeKey) or \"\"\n\n    local scriptCode, compiledFn = nil, nil\n    for attempt = 1, 2 do\n        local cacheBuster = tostring(os.time()) .. \"_\" .. tostring(math.random(1000, 9999)) .. \"_\" .. tostring(attempt)\n        local edgeUrl = CLOUDFLARE_URL .. \"/scripts/\" .. cleanFileName .. \"?v=\" .. cacheBuster .. tokenQuery .. keyQuery\n        scriptCode, compiledFn = fetchVerifiedLua(edgeUrl)\n        if compiledFn then\n            break\n        end\n        if lastFetchDenied then\n            warn(\"[Song Hub] 🔒 Edge rejected script launch: \" .. tostring(lastFetchDeniedReason))\n            shutdownActiveScript(lastFetchDeniedReason or \"Access denied: Your license key has expired or session is invalid.\", true)\n            return\n        end\n\n        local ghUrl = \"https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/games/\" .. cleanFileName .. \"?v=\" .. cacheBuster\n        scriptCode, compiledFn = fetchVerifiedLua(ghUrl)\n        if compiledFn then\n            break\n        end\n        if attempt < 2 then\n            task.wait(0.75)\n        end\n    end\n\n    if not compiledFn then\n        warn(\"[Song Hub] ⚠️ Failed to download from online endpoints! (\" .. tostring(lastFetchError) .. \") Checking local backup...\")\n        if isfile and isfile(\"games/\" .. cleanFileName) then\n            local ok, localCode = pcall(readfile, \"games/\" .. cleanFileName)\n            if ok and type(localCode) == \"string\" and #localCode > 500 then\n                local fn = loadstring(localCode)\n                if fn then\n                    scriptCode = localCode\n                    compiledFn = fn\n                end\n            end\n        end\n    else\n        pcall(function()\n            if delfile and isfile and isfile(\"games/\" .. cleanFileName) then\n                delfile(\"games/\" .. cleanFileName)\n            end\n        end)\n    end\n\n    if getgenv and getgenv()._SongHubSessionExpired == true then\n        if getgenv then getgenv()._SongHubLoading = false end\n        return\n    end\n\n    if compiledFn then\n        pcall(function()\n            if writefile then\n                if makefolder then pcall(makefolder, \"autoexec\") end\n                writefile(\"autoexec/SongHub.luau\", 'local ok,s=pcall(function() return game:HttpGet(\"https://song-hub-whitelist.song-hub-cloudflare-worker.workers.dev/loader.luau?v=\"..tostring(os.time())) end); if not ok or type(s)~=\"string\" or #s<500 then ok,s=pcall(function() return game:HttpGet(\"https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/loader.luau?v=\"..tostring(os.time())) end) end; if ok and type(s)==\"string\" and #s>500 then local f=loadstring(s); if f then f() end end')\n            end\n        end)\n-- [Security] Local file dump removed to prevent code leak\n\n        print(\"[Song Hub] ✅ Successfully compiled \" .. gameTitle .. \" (Online Latest)! Launching UI...\")\n        if getgenv then getgenv()._SongHubLoading = false end\n        local gameThread = task.spawn(compiledFn)\n        if getgenv then getgenv()._SongHubActiveGameThread = gameThread end\n    else\n        if getgenv then getgenv()._SongHubLoading = false end\n        warn(\"[Song Hub] ❌ Could not download or compile \" .. scriptFileName .. \" from GitHub / Cloudflare!\")\n    end\nend\n\n-- ==============================================================================\n-- 3. AUTHENTICATION PIPELINE\n-- ==============================================================================\nlocal function loadStep3WindUI()\n    local urls = {\n        \"https://github.com/Footagesus/WindUI/releases/latest/download/main.lua\",\n        \"https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua\",\n    }\n    for _, u in ipairs(urls) do\n        local _, fn = fetchVerifiedLua(u)\n        if fn then\n            local okW, ui = pcall(fn)\n            if okW and type(ui) == \"table\" and ui.CreateWindow then\n                return ui\n            end\n        end\n    end\n    if isfile and readfile and isfile(\"WindUI_cache.lua\") then\n        local okC, cached = pcall(readfile, \"WindUI_cache.lua\")\n        if okC and type(cached) == \"string\" and #cached > 10000 then\n            local fn = loadstring(cached)\n            if fn then\n                local okW, ui = pcall(fn)\n                if okW and type(ui) == \"table\" and ui.CreateWindow then\n                    return ui\n                end\n            end\n        end\n    end\n    return nil\nend\n\nopenKeyVerificationWindow = function(statusMessage)\n    if getgenv then\n        if getgenv()._SongHubKeyPromptOpen and getgenv()._SongHubKeyPromptWindow then\n            return\n        end\n        getgenv()._SongHubKeyPromptOpen = true\n    end\n\n    local WindUI = loadStep3WindUI()\n    if not WindUI then\n        if getgenv then\n            getgenv()._SongHubKeyPromptOpen = false\n            getgenv()._SongHubLoading = false\n        end\n        warn(\"[Song Hub] ❌ Failed to load WindUI framework for Key System! Reason: \" .. tostring(lastFetchError))\n        return\n    end\n\n    if getgenv and getgenv()._SongHubKeyPromptWindow then\n        pcall(function() getgenv()._SongHubKeyPromptWindow:Destroy() end)\n        getgenv()._SongHubKeyPromptWindow = nil\n    end\n\n    local Window = WindUI:CreateWindow({\n        Title = \"Song Hub | Key System\",\n        Icon = \"shield-check\",\n        Author = \"Cloudflare Edge Auth\",\n        Folder = \"SongHub\",\n        Size = UDim2.fromOffset(480, 380),\n        Transparent = true,\n        Theme = \"Dark\",\n        Acrylic = false,\n        Resizable = false\n    })\n\n    if getgenv then\n        getgenv()._SongHubKeyPromptWindow = Window\n        pcall(function()\n            Window:OnDestroy(function()\n                if getgenv()._SongHubKeyPromptWindow == Window then\n                    getgenv()._SongHubKeyPromptWindow = nil\n                    getgenv()._SongHubKeyPromptOpen = false\n                end\n            end)\n        end)\n    end\n\n    -- ==============================================================================\n    -- 🖱️ UI CLICKABILITY & MODAL ENHANCER (FIX UNCLICKABLE UI BUG)\n    -- Ensures WindUI is always topmost (DisplayOrder 999999) and mouse cursor is\n    -- permanently freed from vehicle camera LockCenter so all buttons/dropdowns work.\n    -- ==============================================================================\n    pcall(function()\n        local UserInputService = game:GetService(\"UserInputService\")\n        local roots = {\n            (typeof(gethui) == \"function\" and gethui()) or nil,\n            game:GetService(\"CoreGui\"),\n            LocalPlayer and LocalPlayer:FindFirstChild(\"PlayerGui\")\n        }\n\n        local function elevateGui(sg)\n            if sg:IsA(\"ScreenGui\") then\n                local name = sg.Name\n                if name:find(\"WindUI\") or name:find(\"RaycityHub\") or name:find(\"SongHub\") then\n                    sg.DisplayOrder = 999999\n                    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling\n\n                    if not sg:FindFirstChild(\"_MouseUnlockerModal\") then\n                        local modalBtn = Instance.new(\"TextButton\")\n                        modalBtn.Name = \"_MouseUnlockerModal\"\n                        modalBtn.Size = UDim2.new(0, 0, 0, 0)\n                        modalBtn.Position = UDim2.new(0, 0, 0, 0)\n                        modalBtn.BackgroundTransparency = 1\n                        modalBtn.Text = \"\"\n                        modalBtn.Modal = true\n                        modalBtn.Active = false\n                        modalBtn.Selectable = false\n                        modalBtn.Parent = sg\n                    end\n                end\n            end\n        end\n\n        for _, root in ipairs(roots) do\n            if root then\n                for _, desc in ipairs(root:GetDescendants()) do\n                    elevateGui(desc)\n                end\n                root.DescendantAdded:Connect(function(desc)\n                    task.wait(0.02)\n                    elevateGui(desc)\n                end)\n            end\n        end\n\n        UserInputService.MouseIconEnabled = true\n        if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then\n            UserInputService.MouseBehavior = Enum.MouseBehavior.Default\n        end\n    end)\n\n    local TabKey = Window:Tab({ Title = \"Key Verification\", Icon = \"key\" })\n\n    local hasNotice = (type(statusMessage) == \"string\" and #statusMessage > 0)\n    local descText = hasNotice\n        and (\"⚠️ \" .. statusMessage .. \"\\n\\nPlease enter a new valid license key or claim a free 24h key below.\")\n        or \"This Hub is protected by Song Hub Edge Whitelist.\\nPlease enter your key to continue.\\nDirect whitelisted users bypass this automatically.\"\n\n    TabKey:Paragraph({\n        Title = hasNotice and \"License Verification Required\" or \"License Key Required\",\n        Desc = descText,\n        Image = hasNotice and \"alert-triangle\" or \"lock\"\n    })\n\n    if hasNotice then\n        pcall(function()\n            WindUI:Notify({\n                Title = \"Session Ended 🔒\",\n                Content = statusMessage,\n                Duration = 6,\n                Icon = \"alert-triangle\"\n            })\n        end)\n    end\n\n    local function sanitizeLicenseKey(raw)\n        if type(raw) ~= \"string\" then return \"\" end\n        return raw:gsub(\"[^%w%-_]+\", \"\")\n    end\n\n    local inputKey = \"\"\n    local isVerifying = false\n\n    local function readLiveInputBox()\n        local foundText = \"\"\n        pcall(function()\n            local containers = {\n                (typeof(gethui) == \"function\" and gethui()) or nil,\n                game:GetService(\"CoreGui\"),\n                LocalPlayer and LocalPlayer:FindFirstChildOfClass(\"PlayerGui\"),\n            }\n            for _, root in ipairs(containers) do\n                if root then\n                    for _, desc in ipairs(root:GetDescendants()) do\n                        if desc:IsA(\"TextBox\") then\n                            local ph = desc.PlaceholderText or \"\"\n                            if ph:find(\"SONGHUB\", 1, true) then\n                                local t = desc.Text or \"\"\n                                if #t > 0 then\n                                    foundText = t\n                                end\n                            end\n                        end\n                    end\n                end\n            end\n        end)\n        return foundText\n    end\n\n    TabKey:Input({\n        Title = \"Enter License Key\",\n        Desc = \"Paste your license key here (e.g. SONGHUB-XXXX)\",\n        Placeholder = \"SONGHUB-XXXX-XXXX-XXXX\",\n        Callback = function(txt)\n            local clean = sanitizeLicenseKey(txt)\n            if #clean > 0 or #(txt or \"\") == 0 then\n                inputKey = clean\n            end\n        end\n    })\n\n    TabKey:Button({\n        Title = \"🔓 Verify & Unlock Song Hub\",\n        Desc = \"Verify key and start script\",\n        Icon = \"check-circle\",\n        Callback = function()\n            if isVerifying then return end\n\n            local liveBoxText = sanitizeLicenseKey(readLiveInputBox())\n            if #liveBoxText > 0 then\n                inputKey = liveBoxText\n            else\n                inputKey = sanitizeLicenseKey(inputKey)\n            end\n\n            if #inputKey == 0 then\n                WindUI:Notify({ Title = \"Error\", Content = \"Please enter a license key!\", Duration = 3, Icon = \"alert-circle\" })\n                return\n            end\n\n            isVerifying = true\n            WindUI:Notify({ Title = \"Verifying\", Content = \"Contacting Cloudflare Edge...\", Duration = 2, Icon = \"loader\" })\n            local ok, result = sendVerifyRequest(inputKey)\n\n            if ok then\n                local authOk, authErr = applyAuthenticatedSession(result, inputKey)\n                if not authOk then\n                    isVerifying = false\n                    clearSavedLicenseKey()\n                    WindUI:Notify({\n                        Title = \"Access Denied ❌\",\n                        Content = authErr or \"Invalid or expired key!\",\n                        Duration = 4,\n                        Icon = \"x-circle\"\n                    })\n                    return\n                end\n\n                if writefile then\n                    if makefolder then pcall(makefolder, \"SongHub\") end\n                    pcall(writefile, KEY_SAVE_PATH, inputKey)\n                end\n\n                startSessionHeartbeat(result.sessionToken, inputKey, result)\n\n                WindUI:Notify({\n                    Title = \"Access Granted! ✨\",\n                    Content = (result and result.message) or \"Welcome to Song Hub!\",\n                    Duration = 4,\n                    Icon = \"sparkles\"\n                })\n\n                local unlockedToken = result and result.sessionToken or \"\"\n                local unlockedKey = inputKey\n                task.spawn(function()\n                    task.wait(0.9)\n                    if getgenv then\n                        getgenv()._SongHubKeyPromptOpen = false\n                        getgenv()._SongHubKeyPromptWindow = nil\n                    end\n                    pcall(function() Window:Destroy() end)\n                    task.wait(0.05)\n                    launchGameScript(unlockedToken, unlockedKey)\n                end)\n            else\n                isVerifying = false\n                local errCode = result and result.code\n                if errCode == \"KEY_EXPIRED\" or errCode == \"KEY_REVOKED\" or errCode == \"INVALID_KEY\" then\n                    clearSavedLicenseKey()\n                end\n                WindUI:Notify({\n                    Title = \"Access Denied ❌\",\n                    Content = (result and result.message) or \"Invalid or expired key!\",\n                    Duration = 4,\n                    Icon = \"x-circle\"\n                })\n            end\n        end\n    })\n\n    TabKey:Button({\n        Title = \"🌐 Get Free 24h Key (Web Portal)\",\n        Desc = \"Copy GetKey Web Portal URL to clipboard\",\n        Icon = \"link\",\n        Callback = function()\n            if setclipboard then\n                setclipboard(GET_KEY_PORTAL_URL)\n                WindUI:Notify({ Title = \"Copied\", Content = \"GetKey URL copied to clipboard! Paste into browser.\", Duration = 4, Icon = \"clipboard-check\" })\n            end\n        end\n    })\n\n    TabKey:Button({\n        Title = \"💬 Join Discord Community\",\n        Desc = \"Copy Discord invite link to clipboard\",\n        Icon = \"external-link\",\n        Callback = function()\n            if setclipboard then\n                setclipboard(DISCORD_INVITE_URL)\n                WindUI:Notify({ Title = \"Copied\", Content = \"Discord invite link copied to clipboard!\", Duration = 3, Icon = \"clipboard-check\" })\n            end\n        end\n    })\nend\n\n-- Step 1: Check Direct Roblox UserID Whitelist (VIP/Owner auto-bypass)\nlocal wlOk, wlData = sendVerifyRequest(\"\")\nif wlOk and wlData.whitelisted then\n    local authOk = applyAuthenticatedSession(wlData, \"\")\n    if authOk then\n        print(string.format(\"[Song Hub] ✅ Direct Whitelist passed! Welcome %s (%s)\", LocalPlayer.Name, wlData.role or \"VIP/Owner\"))\n        startSessionHeartbeat(wlData.sessionToken or \"\", \"\", wlData)\n        launchGameScript(wlData.sessionToken or \"\", \"\")\n        return\n    end\nend\n\n-- Step 2: Check Locally Saved Key\nlocal initialPromptReason = nil\nif isfile and isfile(KEY_SAVE_PATH) then\n    local savedKey = \"\"\n    pcall(function() savedKey = readfile(KEY_SAVE_PATH) end)\n    if savedKey and #savedKey > 3 then\n        local cleanSavedKey = savedKey:gsub(\"%s+\", \"\")\n        local keyOk, keyData = sendVerifyRequest(cleanSavedKey)\n        if keyOk then\n            local authOk, authErr = applyAuthenticatedSession(keyData, cleanSavedKey)\n            if authOk then\n                print(string.format(\"[Song Hub] ✅ Key Verified from Cache! Type: %s (Live Sessions: %s/%s)\", keyData.keyType or \"Active\", tostring(keyData.activeSessionsCount or 1), tostring(keyData.maxSessions or 1)))\n                startSessionHeartbeat(keyData.sessionToken, cleanSavedKey, keyData)\n                launchGameScript(keyData.sessionToken, cleanSavedKey)\n                return\n            else\n                clearSavedLicenseKey()\n                shutdownActiveScript(authErr, false)\n                initialPromptReason = authErr\n            end\n        elseif type(keyData) == \"table\" then\n            local code = keyData.code\n            if code == \"KEY_EXPIRED\" or code == \"KEY_REVOKED\" or code == \"INVALID_KEY\" or code == \"HWID_MISMATCH\" then\n                clearSavedLicenseKey()\n                shutdownActiveScript(keyData.message or \"Saved key is no longer valid.\", false)\n            end\n            if type(keyData.message) == \"string\" and #keyData.message > 0 then\n                initialPromptReason = keyData.message\n            end\n        end\n    end\nend\n\n-- Step 3: Prompt User for Key via WindUI\nopenKeyVerificationWindow(initialPromptReason)\n";

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
    return `${prefix}-${segment()}-${segment()}-${segment()}`;
}

function generateHex(len = 16) {
    const arr = new Uint8Array(len);
    crypto.getRandomValues(arr);
    return Array.from(arr).map(b => b.toString(16).padStart(2, '0')).join('');
}

async function createWhitelistToken(userId, secret, nowSec = Math.floor(Date.now() / 1000)) {
    const exp = nowSec + 86400;
    const payload = `wl.${String(userId).trim()}.${exp}`;
    const sig = await hmacSha256(payload, secret);
    return `${payload}.${sig.slice(0, 32)}`;
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
    const expected = (await hmacSha256(`wl.${userId}.${expStr}`, secret)).slice(0, 32);
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
                const res = await this.db.prepare("SELECT * FROM keys WHERE key_string = ?").bind(kStr).first();
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
                await this.db.prepare(`
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
                `).run();
            } catch (e) {}
        }
    }

    async purgeExpiredAndInactiveSessions(nowSec = Math.floor(Date.now() / 1000), windowSeconds = 90) {
        await this.ensureSessionTable();
        const cutoff = nowSec - windowSeconds;
        if (this.db) {
            try {
                await this.db.prepare(`
                    DELETE FROM key_sessions
                    WHERE last_heartbeat <= ?
                       OR key_id NOT IN (SELECT id FROM keys)
                       OR key_id IN (
                           SELECT id FROM keys
                           WHERE is_active = 0 OR (expires_at IS NOT NULL AND expires_at > 0 AND expires_at <= ?)
                       )
                `).bind(cutoff, nowSec).run();
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
                const row = await this.db.prepare(`
                    SELECT ks.*, k.id AS joined_key_id, k.key_string, k.key_type, k.is_active, k.expires_at, k.max_sessions
                    FROM key_sessions ks
                    LEFT JOIN keys k ON k.id = ks.key_id
                    WHERE ks.session_token = ?
                `).bind(sessionToken).first();
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

    async closeKeySession(sessionToken) {
        if (this.db) {
            try {
                await this.db.prepare("DELETE FROM key_sessions WHERE session_token = ?").bind(sessionToken).run();
                return;
            } catch (e) {}
        }
        this.memoryStore.sessions.delete(sessionToken);
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
                const { results } = await this.db.prepare(`
                    SELECT k.*, 
                           (SELECT COUNT(*) FROM key_hwids kh WHERE kh.key_id = k.id) as bound_hwids_count,
                           (SELECT COUNT(*) FROM key_sessions ks WHERE ks.key_id = k.id AND ks.last_heartbeat > ? AND k.is_active = 1 AND (k.expires_at IS NULL OR k.expires_at = 0 OR k.expires_at > ?)) as active_sessions_count
                    FROM keys k ORDER BY k.id DESC
                `).bind(cutoff, nowSec).all();
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
                await this.db.prepare(
                    "INSERT INTO key_hwids (key_id, hwid, user_id, username, first_used_at, last_used_at) VALUES (?, ?, ?, ?, ?, ?)"
                ).bind(keyId, hwid, String(userId || ''), String(username || ''), now, now).run();
                return;
            } catch (e) {}
        }
        this.memoryStore.hwids.set(`${keyId}_${hwid}`, {
            key_id: Number(keyId), hwid, user_id: userId, username, first_used_at: now, last_used_at: now
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
        this.memoryStore.hwids.delete(`${id}_${hwid}`);
    }

    async editKey(id, updates) {
        if (this.db) {
            try {
                await this.db.prepare(
                    "UPDATE keys SET note = COALESCE(?, note), max_hwid = COALESCE(?, max_hwid), max_sessions = COALESCE(?, max_sessions), is_active = COALESCE(?, is_active), key_type = COALESCE(?, key_type) WHERE id = ?"
                ).bind(
                    updates.note !== undefined ? updates.note : null,
                    updates.maxHwid !== undefined ? updates.maxHwid : null,
                    updates.maxSessions !== undefined ? updates.maxSessions : null,
                    updates.isActive !== undefined ? (updates.isActive ? 1 : 0) : null,
                    updates.keyType !== undefined ? updates.keyType : null,
                    id
                ).run();
                if (updates.isActive === false) {
                    await this.kickKeySessions(id);
                }
                return;
            } catch (e) {}
        }
        for (const v of this.memoryStore.keys.values()) {
            if (v.id === Number(id)) {
                if (updates.note !== undefined) v.note = updates.note;
                if (updates.maxHwid !== undefined) v.max_hwid = updates.maxHwid;
                if (updates.maxSessions !== undefined) v.max_sessions = updates.maxSessions;
                if (updates.isActive !== undefined) v.is_active = updates.isActive ? 1 : 0;
                if (updates.keyType !== undefined) v.key_type = updates.keyType;
                break;
            }
        }
        if (updates.isActive === false) {
            await this.kickKeySessions(id);
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

        const json = (data, status = 200) => new Response(JSON.stringify(data), {
            status,
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
        // 2. UNIVERSAL LOADER & GITHUB RAW SCRIPT PROXY (100% Zero-Cache)
        // ----------------------------------------------------------------------
        if (path === "/loader.luau" || path === "/loader" || path === "/load") {
            try {
                const ghUrl = `https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/Universal_Loader.luau?v=${Date.now()}`;
                const ghRes = await fetch(ghUrl, { headers: { "User-Agent": "Cloudflare-Worker-Proxy", "Cache-Control": "no-cache" } });
                if (ghRes.ok) {
                    const code = await ghRes.text();
                    return text(code, 200, "text/plain; charset=utf-8");
                }
            } catch (e) {}
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
                return text(`-- ACCESS_DENIED: ${authCheck.message || authCheck.code || "Your license key has expired or session is invalid."}`, 403, "text/plain; charset=utf-8");
            }
            const gameFile = path.replace("/scripts/", "").replace(/[^a-zA-Z0-9_\-\.]/g, "");
            const fileName = gameFile.endsWith(".luau") || gameFile.endsWith(".lua") ? gameFile : gameFile + ".luau";
            try {
                const ghUrl = `https://raw.githubusercontent.com/songsarmseeha-commits/Song-Hub/main/games/${fileName}?v=${Date.now()}`;
                const ghRes = await fetch(ghUrl, { headers: { "User-Agent": "Cloudflare-Worker-Proxy", "Cache-Control": "no-cache" } });
                if (ghRes.ok) {
                    const code = await ghRes.text();
                    return text(code, 200, "text/plain; charset=utf-8");
                }
            } catch (e) {}
            return text(`-- Game script not found for ${fileName}`, 404);
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
            const key = String(body.key || url.searchParams.get("key") || "").replace(/[\s'"]/g, "").toUpperCase();
            const hwid = String(body.hwid || url.searchParams.get("hwid") || request.headers.get("x-hwid") || "").trim();
            const userId = body.userId || url.searchParams.get("userId") || request.headers.get("x-roblox-userid");
            const username = String(body.username || url.searchParams.get("username") || "").trim();

            // Direct Whitelist Check
            if (userId) {
                const whitelisted = await db.findWhitelistedUser(userId);
                if (whitelisted) {
                    const wlToken = await createWhitelistToken(userId, apiSecret, nowSec);
                    await db.logAccess({
                        key_string: null, roblox_user_id: userId, username, hwid, ip_address: clientIp,
                        status: "WHITELIST_BYPASS", message: `Authenticated via Direct Whitelist (${whitelisted.role})`
                    });
                    return json({
                        success: true,
                        whitelisted: true,
                        role: whitelisted.role,
                        keyType: "VIP Permanent",
                        expiresAt: null,
                        serverTime: nowSec,
                        sessionToken: wlToken,
                        message: `Welcome back, ${whitelisted.role} ${username || userId}!`
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

            // HWID Check
            const boundHwids = await db.getKeyHwids(keyData.id);
            const isBound = boundHwids.some(h => h.hwid === hwid);

            if (!isBound) {
                if (boundHwids.length < (keyData.max_hwid || 1)) {
                    await db.addKeyHwid(keyData.id, hwid, userId, username);
                } else {
                    await db.logAccess({ key_string: key, roblox_user_id: userId, username, hwid, ip_address: clientIp, status: "HWID_MISMATCH", message: "Max devices exceeded" });
                    return json({ success: false, code: "HWID_MISMATCH", serverTime: nowSec, message: "Key is already bound to another device. Reset HWID in Discord." }, 403);
                }
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
            const activeSessions = await db.getActiveSessions(keyData.id, 90);
            const jobId = body.jobId || url.searchParams.get("jobId") || "";
            let session = activeSessions.find(s => (hwid && s.hwid === hwid) || (jobId && s.job_id === jobId) || (userId && String(s.roblox_user_id) === String(userId)));

            let sessionToken = session ? session.session_token : null;
            if (!session) {
                if (activeSessions.length >= (keyData.max_sessions || 1)) {
                    await db.logAccess({ key_string: key, roblox_user_id: userId, username, hwid, ip_address: clientIp, status: "SESSION_LIMIT", message: `Max sessions (${keyData.max_sessions}) exceeded` });
                    return json({ success: false, code: "MAX_SESSIONS_EXCEEDED", serverTime: nowSec, message: `Session limit reached (${activeSessions.length}/${keyData.max_sessions} Live). Close other Roblox instances or wait 60s.` }, 403);
                }
                sessionToken = generateHex(24);
                await db.createKeySession(keyData.id, sessionToken, hwid, userId, username, jobId, body.placeId, clientIp);
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

        // Close Session Endpoint when client exits game
        if (path === "/api/v1/session/close" || path === "/api/session/close") {
            let body = {};
            if (method === "POST") {
                try { body = await request.json(); } catch (e) {}
            }
            const sessionToken = body.sessionToken || url.searchParams.get("sessionToken") || "";
            if (sessionToken) {
                await db.closeKeySession(sessionToken);
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

            const sig = await hmacSha256(`${sessionId}_${step}`, apiSecret);
            const destinationUrl = `${host}/api/v1/getkey/callback?session=${sessionId}&step=${step}&sig=${sig}`;

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
                redirectUrl = `https://link-to.net/${pubId}/${slug}/dynamic/?r=${b64}`;
            } else {
                const lootKey = await db.getSetting("getkey_lootlabs_key", CONFIG.GETKEY.LOOTLABS_API_KEY);
                const lootTier = parseInt(await db.getSetting("getkey_lootlabs_tier", "1")) || 1;
                const lootTasks = parseInt(await db.getSetting("getkey_lootlabs_tasks", "2")) || 2;
                try {
                    const llRes = await fetch("https://creators.lootlabs.gg/api/public/content_locker", {
                        method: "POST",
                        headers: {
                            "Authorization": `Bearer ${lootKey}`,
                            "Content-Type": "application/json"
                        },
                        body: JSON.stringify({
                            title: `Song Hub Key Checkpoint ${step}/${totalSteps}`,
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

            const expectedSig = await hmacSha256(`${sessionId}_${step}`, apiSecret);
            if (sig !== expectedSig) {
                return Response.redirect(`${url.origin}/getkey?error=invalid_signature`, 302);
            }

            const session = await db.findGetKeySession(sessionId);
            if (session && session.is_completed === 1 && session.claimed_key) {
                return Response.redirect(`${url.origin}/getkey?session=${sessionId}&claimed=1&key=${session.claimed_key}`, 302);
            }

            const cfgSteps = Math.max(1, Math.min(parseInt(await db.getSetting("getkey_steps", "2")) || 2, 10));
            const totalSteps = session ? Math.max(1, Number(session.total_steps) || cfgSteps) : cfgSteps;
            const currentStep = session ? Math.max(1, Number(session.current_step) || 1) : 1;

            if (session && step < currentStep) {
                return Response.redirect(`${url.origin}/getkey?session=${sessionId}&step=${currentStep}`, 302);
            }
            if (session && step > currentStep) {
                return Response.redirect(`${url.origin}/getkey?session=${sessionId}&step=${currentStep}&error=step_order`, 302);
            }

            if (step < totalSteps) {
                await db.advanceSessionStep(sessionId, step + 1);
                return Response.redirect(`${url.origin}/getkey?session=${sessionId}&step=${step + 1}&stepSuccess=1`, 302);
            }

            // All checkpoints completed! Generate Free Key using configured limits
            const freeKey = generateKeyString("FREE");
            const durationHours = parseInt(await db.getSetting("getkey_duration_hours", "24")) || 24;
            const maxHwid = parseInt(await db.getSetting("getkey_max_hwid", "1")) || 1;
            const maxSessions = parseInt(await db.getSetting("getkey_max_sessions", "1")) || 1;

            await db.insertKey({
                key_string: freeKey,
                key_type: `Free ${durationHours}h`,
                duration_seconds: durationHours * 3600,
                note: `Claimed via GetKey Portal (${session ? session.provider : 'linkvertise'})`,
                max_hwid: maxHwid,
                max_sessions: maxSessions
            });

            if (sessionId) {
                await db.completeSessionWithKey(sessionId, freeKey);
            }

            return Response.redirect(`${url.origin}/getkey?session=${sessionId}&claimed=1&key=${freeKey}`, 302);
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

                const durationMap = {
                    "24h": 86400,
                    "Free 24h": 86400,
                    "3d": 259200,
                    "7d": 604800,
                    "Weekly": 7 * 86400,
                    "30d": 2592000,
                    "Monthly": 30 * 86400,
                    "Lifetime": 0
                };

                let durationSeconds = durationMap[rawType] !== undefined ? durationMap[rawType] : 86400;
                if (body.durationHours && !isNaN(body.durationHours)) {
                    durationSeconds = parseInt(body.durationHours) * 3600;
                }

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
            const hwidMatch = path.match(/\/keys\/(\d+)\/hwids$/);
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
                const keyDelMatch = path.match(/\/keys\/(\d+)$/);
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
                const wlDelMatch = path.match(/\/whitelist\/([a-zA-Z0-9_]+)$/);
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
