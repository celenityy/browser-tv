/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package dev.celenity.tv.browser.ui

import androidx.test.espresso.web.webdriver.Locator
import androidx.test.filters.FlakyTest

import org.junit.Rule
import org.junit.Test
import dev.celenity.tv.browser.ext.toUri
import dev.celenity.tv.browser.helpers.MainActivityTestRule
import dev.celenity.tv.browser.ui.robots.navigationOverlay

/**
 * Tests that the browser can successfully load pages from the network. This works with our other UI tests
 * which should load content from the disk to make them less fragile.
 *
 * This test loads a few pages off the network and verifies their content to ensure they're actually loaded.
 * Verification is minimal to reduce the chance of the test breaking from the web page changing.
 */
@FlakyTest(detail = "Requires network access")
class NetworkPageLoadTest {

    @Rule @JvmField val activityTestRule = MainActivityTestRule()

    /* ktlint-disable no-blank-line-before-rbrace */ // This imposes unreadable grouping.
    @Test
    fun networkPageLoadTest() {
        navigationOverlay {
        // Work around for #1444: on emulators with turbo mode enabled, the url bar will display
        // any url loaded by the page in addition to the primary url. We disable turbo mode to
        // ensure we only see the primary url and can assert it correctly.
        }.toggleTurbo {
        }.openOverlay {
            assertTurboIsSelected(false)
        }.enterUrlAndEnterToBrowser("https://www.mozilla.org".toUri()!!) {
            assertDOMElementExists(Locator.CLASS_NAME, "c-navigation-logo-image") // mozilla logo
        }.openOverlay {
            assertURLBarTextContains("www.mozilla.org")
        }.enterUrlAndEnterToBrowser("https://support.mozilla.org".toUri()!!) {
            assertDOMElementExists(Locator.CLASS_NAME, "sumo-nav--logo")
        }.openOverlay {
            assertURLBarTextContains("support.mozilla.org")
        }
    }
}
