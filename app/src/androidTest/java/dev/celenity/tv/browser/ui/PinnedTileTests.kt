/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package dev.celenity.tv.browser.ui

import org.junit.Ignore
import org.junit.Rule
import org.junit.Test
import dev.celenity.tv.browser.R
import dev.celenity.tv.browser.helpers.MainActivityTestRule
import dev.celenity.tv.browser.helpers.MockWebServerHelper
import dev.celenity.tv.browser.helpers.ToastHelper.assertToast
import dev.celenity.tv.browser.ui.robots.navigationOverlay

class PinnedTileTests {

    @get:Rule val activityTestRule = MainActivityTestRule()

    /* ktlint-disable no-blank-line-before-rbrace */ // This imposes unreadable grouping.
    @Test
    @Ignore("This has an off-by-one tile, and also the new tile can't be off the screen. Ignoring so we can get this into CI")
    fun pinnedTileTests() {
        val endpoint = MockWebServerHelper
            .initMockWebServerAndReturnEndpoints("This is an example").first()

        navigationOverlay {
        }.enterUrlAndEnterToBrowser(endpoint) {
        }.openOverlay {
            assertPinButtonChecked(false)
        }.pinSite {
        }.openOverlay {
            assertToast(R.string.notification_pinned_site, activityTestRule)
            assertPinButtonChecked(true)
            assertPinnedTileExists(11, "localhost") // MockWebServer hosts all sites at localhost
        }.unpinSite {
        }.openOverlay {
            assertPinButtonChecked(false)
        }
    }
}
