/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package dev.celenity.tv.browser.onboarding

import android.os.Bundle
import android.preference.PreferenceManager
import androidx.appcompat.app.AppCompatActivity
import kotlinx.android.synthetic.main.receive_tab_preboarding.buttonNotNow
import kotlinx.android.synthetic.main.receive_tab_preboarding.buttonSignIn
import kotlinx.android.synthetic.main.receive_tab_preboarding.descriptionText
import dev.celenity.tv.browser.BrowserApplication
import dev.celenity.tv.browser.MainActivity
import dev.celenity.tv.browser.R

/**
 * Manages an onboarding screen, which is shown once to users upon app start in order
 * to educate them about receive tab functionality.
 */
class ReceiveTabPreboardingActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.receive_tab_preboarding)

        descriptionText.text = resources.getString(
            R.string.fxa_preboarding_instruction1,
            resources.getString(R.string.app_name),
            resources.getString(R.string.app_name_extended_tv)
        )

        buttonSignIn.setOnClickListener {
            @Suppress("DEPRECATION") // Couldn't work out a better way to do this. If you
            // think of one, please replace this
            (application as BrowserApplication).mainActivityCommandBus
                .onNext(MainActivity.Command.BEGIN_LOGIN)
            finish()
        }

        buttonNotNow.setOnClickListener {
            finish()
        }

        setOnboardReceiveTabsShown()
    }

    private fun setOnboardReceiveTabsShown() {
        PreferenceManager.getDefaultSharedPreferences(this)
                .edit()
                .putBoolean(ONBOARD_RECEIVE_TABS_SHOWN_PREF, true)
                .apply()
    }

    companion object {
        const val ONBOARD_RECEIVE_TABS_SHOWN_PREF = "onboard_receive_tabs_shown"
    }
}
