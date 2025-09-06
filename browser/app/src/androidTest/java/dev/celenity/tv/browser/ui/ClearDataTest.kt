/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@file:Suppress("TestFunctionName")

package dev.celenity.tv.browser.ui

import org.junit.Ignore
import org.junit.Rule
import org.junit.Test
import dev.celenity.tv.browser.helpers.MainActivityTestRule
import dev.celenity.tv.browser.helpers.MockWebServerHelper
import dev.celenity.tv.browser.ui.robots.engineInternals
import dev.celenity.tv.browser.ui.robots.navigationOverlay

/**
 * A test to verify that session data is erased when "Clear data" is pressed.
 */
class ClearDataTest {

    @get:Rule val activityTestRule = MainActivityTestRule()

    /* ktlint-disable no-blank-line-before-rbrace */ // This imposes unreadable grouping.
    @Test
    @Ignore("""
        This test asserts that back/forward behavior works as intended after clearing data. For whatever reason, after
        clearing data our SessionLoadedIdlingResource never allows testing to proceed, causing the test to timeout. After
        investigation, it seems that SystemEngineSession#onPageFinished is never called after clearing data. It is
        unknown at this time why
        See #1360
    """)
    fun WHEN_data_is_cleared_THEN_back_and_forward_should_be_unavailable() {
        val endpoints = MockWebServerHelper
                .initMockWebServerAndReturnEndpoints("This is Mozilla", "This is Google", "This is YouTube")

        navigationOverlay {
            assertCanGoBackForward(false, false)
        }.enterUrlAndEnterToBrowser(endpoints[0]) {
        }.openOverlay {
            assertCanGoBackForward(false, false)

        }.enterUrlAndEnterToBrowser(endpoints[1]) {
        }.openOverlay {
            assertCanGoBackForward(true, false)

        }.enterUrlAndEnterToBrowser(endpoints[2]) {
        }.openOverlay {
        }.goBack {
        }.openOverlay {
            assertCanGoBackForward(true, true)

            engineInternals {
                addCookie()
                assertCookieExists()
            }
            linearNavigateToSettings()
        }.openSettingsCleardataTile {
        }.clearAllDataToOverlay {
            assertCanGoBackForward(false, false)

            engineInternals {
                assertCookieDoesNotExist()
            }
        }.enterUrlAndEnterToBrowser(endpoints[1]) {
        }.openOverlay {
            assertCanGoBackForward(false, false)

        }.enterUrlAndEnterToBrowser(endpoints[2]) {
        }.openOverlay {
            assertCanGoBackForward(true, false)

        }.enterUrlAndEnterToBrowser(endpoints[0]) {
        }.openOverlay {
            assertCanGoBackForward(true, false)

        }.goBack {
        }.openOverlay {
            assertCanGoBackForward(true, true)

        }
    }
}
