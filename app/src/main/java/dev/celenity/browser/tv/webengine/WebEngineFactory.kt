package dev.celenity.browser.tv.webengine

import android.app.Activity
import android.content.Context
import androidx.annotation.UiThread
import dev.celenity.browser.tv.BrowserTV
import dev.celenity.browser.tv.Config
import dev.celenity.browser.tv.activity.main.view.CursorLayout
import dev.celenity.browser.tv.model.WebTabState
import dev.celenity.browser.tv.utils.AndroidBug5497Workaround
import dev.celenity.browser.tv.webengine.gecko.GeckoWebEngine
import dev.celenity.browser.tv.webengine.gecko.HomePageHelper

object WebEngineFactory {
    @UiThread
    suspend fun initialize(context: Context, webViewContainer: CursorLayout) {
        if (BrowserTV.config.isWebEngineGecko()) {
            GeckoWebEngine.initialize(context, webViewContainer)
            HomePageHelper.prepareHomePageFiles()
        } else {
            AndroidBug5497Workaround.assistActivity(context as Activity)
        }
    }

    @Suppress("KotlinConstantConditions")
    fun createWebEngine(tab: WebTabState): WebEngine {
        return GeckoWebEngine(tab)
    }

    suspend fun clearCache(ctx: Context) {
        if (BrowserTV.config.isWebEngineGecko()) {
            GeckoWebEngine.clearCache(ctx)
        } else {
            // We only support GeckoView
        }
    }

    fun onThemeSettingUpdated(value: Config.Theme) {
        if (BrowserTV.config.isWebEngineGecko()) {
            GeckoWebEngine.onThemeSettingUpdated(value)
        }
    }
}
