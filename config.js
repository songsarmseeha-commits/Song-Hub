// ==============================================================================
// Hub Whitelist & Key System Configuration
// ==============================================================================

module.exports = {
    // Port to run the server on
    PORT: process.env.PORT || 3000,

    // Public domain/host URL for Get Key redirects (e.g. http://localhost:3000 or https://your-hub.domain.com)
    PUBLIC_URL: process.env.PUBLIC_URL || "https://song-hub-avp8.onrender.com",

    // Admin dashboard login password
    ADMIN_PASSWORD: process.env.ADMIN_PASSWORD || "ttt0871457806",

    // Secret salt used for request signature verification (optional anti-tamper)
    API_SECRET_KEY: process.env.API_SECRET_KEY || "galaxy_hub_super_secret_salt_2026",

    // Hub name shown in dashboard and notifications
    HUB_NAME: "Song Hub | Universal Whitelist",

    // Database file path
    DB_PATH: "./whitelist.db",

    // ==========================================================================
    // Monetization & Free "Get Key" System (Linkvertise + LootLabs)
    // ==========================================================================
    GETKEY: {
        ENABLED: true,
        // Mode options: "dual" (Step 1 LootLabs -> Step 2 Linkvertise), "lootlabs", "linkvertise"
        MODE: process.env.GETKEY_MODE || "dual",
        TOTAL_STEPS: 2, // 1 or 2 checkpoints
        KEY_DURATION_HOURS: 24, // Free key validity (24 hours)
        MAX_HWID: 1, // Free key HWID limit (Max allowed devices)
        MAX_SESSIONS: 1, // Free key concurrent session limit (Max simultaneous instances)

        // Linkvertise Configuration
        LINKVERTISE_USER_ID: process.env.LINKVERTISE_USER_ID || "9176777",

        // LootLabs Configuration
        LOOTLABS_API_KEY: process.env.LOOTLABS_API_KEY || "8580e9cc7da836b61e43050d86e2ea52465c2bb5d33a873d948df7e73683ab18",
        LOOTLABS_TIER_ID: 1, // 1: Trending & Recommended, 2: Gaming Offers
        LOOTLABS_NUMBER_OF_TASKS: 2, // 1 to 5
        LOOTLABS_THEME: 1
    }
};

