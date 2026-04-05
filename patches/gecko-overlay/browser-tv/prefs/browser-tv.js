// Browser TV Gecko preferences...

/// Actual preferences are set at `browser-tv.cfg` (located at `patches/build/gecko/browser-tv.cfg` within the Browser TV source repo)
// This is just a "bootstrap" of sorts...

/// Set-up AutoConfig
// https://support.mozilla.org/kb/customizing-firefox-using-autoconfig
pref("general.config.sandbox_enabled", true, locked); // Ensure AutoConfig is sandboxed
pref("autoadmin.global_config_url", "", locked); // Ensure we do not allow remote configuration
pref("general.config.filename", "browser-tv.cfg", locked);
pref("general.config.obscure_value", 0, locked);
pref("general.config.vendor", "browser-tv", locked);

pref("browser.browser.tv.applied.prefs", true, locked);
