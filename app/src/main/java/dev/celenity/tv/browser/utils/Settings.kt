/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package dev.celenity.tv.browser.utils

import android.content.Context
import android.content.SharedPreferences
import android.content.res.Resources
import android.preference.PreferenceManager
import androidx.annotation.VisibleForTesting
import mozilla.components.concept.engine.EngineSession.TrackingProtectionPolicy
import mozilla.components.concept.engine.EngineSession.TrackingProtectionPolicy.CookiePolicy
import mozilla.components.concept.engine.EngineSession.TrackingProtectionPolicy.TrackingCategory
import dev.celenity.tv.browser.R
import dev.celenity.tv.browser.channels.ChannelConfig
import dev.celenity.tv.browser.channels.ChannelOnboardingActivity
import dev.celenity.tv.browser.components.locale.LocaleManager
import dev.celenity.tv.browser.ext.languageAndMaybeCountryMatch
import dev.celenity.tv.browser.ext.serviceLocator
import dev.celenity.tv.browser.onboarding.OnboardingActivity
import dev.celenity.tv.browser.onboarding.ReceiveTabPreboardingActivity

/**
 * A simple wrapper for SharedPreferences that makes reading preference a little bit easier.
 */
class Settings private constructor(context: Context) {
    companion object {
        private var instance: Settings? = null

        @JvmStatic
        @Synchronized
        fun getInstance(context: Context): Settings {
            if (instance == null) {
                instance = Settings(context.applicationContext)
            }
            return instance ?: throw AssertionError("Instance cleared")
        }

        const val TRACKING_PROTECTION_ENABLED_PREF = "tracking_protection_enabled"
        const val TRACKING_PROTECTION_ENABLED_DEFAULT = true

        const val FXA_ONBOARD_SHOWN_PREF = "fxa_onboard_shown"

        @VisibleForTesting internal fun reset() {
            instance = null
        }
    }

    private val preferences: SharedPreferences = PreferenceManager.getDefaultSharedPreferences(context)
    private val resources: Resources = context.resources

    val defaultSearchEngineName: String?
        get() = preferences.getString(getPreferenceKey(R.string.pref_key_search_engine), null)

    fun shouldShowTurboModeOnboarding(): Boolean =
            !preferences.getBoolean(OnboardingActivity.ONBOARD_SHOWN_PREF, false)

    fun shouldShowFxaOnboarding(): Boolean =
            !preferences.getBoolean(FXA_ONBOARD_SHOWN_PREF, false)

    fun shouldShowReceiveTabsPreboarding(): Boolean =
        !preferences.getBoolean(ReceiveTabPreboardingActivity.ONBOARD_RECEIVE_TABS_SHOWN_PREF, false)

    fun shouldShowTVOnboarding(localeManager: LocaleManager, context: Context): Boolean {
        // Note that this method duplicates some logic found in KillswitchLayout. Make sure
        // that any changes made in one place are reflected in the other as well.
        val channelConfig = ChannelConfig.getTvGuideConfig(context)
        val currentLocale = localeManager.getCurrentLocale(context)

        return !preferences.getBoolean(ChannelOnboardingActivity.TV_ONBOARDING_SHOWN_PREF, false) &&
                currentLocale.languageAndMaybeCountryMatch(channelConfig.enabledInLocales)
    }

    fun shouldAutocompleteFromShippedDomainList() = true

    private fun getPreferenceKey(resourceId: Int): String =
            resources.getString(resourceId)

    // Accessible via TurboMode.isEnabled()
    internal var isBlockingEnabled: Boolean // Delegates to shared prefs; could be custom delegate.
        get() = preferences.getBoolean(Settings.TRACKING_PROTECTION_ENABLED_PREF,
                TRACKING_PROTECTION_ENABLED_DEFAULT)
        set(value) = preferences.edit().putBoolean(TRACKING_PROTECTION_ENABLED_PREF, value).apply()

    /**
     * Get the tracking protection policy which is a combination of tracker categories that should be blocked.
     */
    val trackingProtectionPolicy: TrackingProtectionPolicy
        get() {
            return if (isBlockingEnabled) {
                TrackingProtectionPolicy.recommended()
            } else {
                TrackingProtectionPolicy.select(
                    // These defaults are from TrackingProtectionPolicy.none().
                    trackingCategories = arrayOf(TrackingCategory.NONE),
                    cookiePolicy = CookiePolicy.ACCEPT_ALL
                )
            }
        }
}
