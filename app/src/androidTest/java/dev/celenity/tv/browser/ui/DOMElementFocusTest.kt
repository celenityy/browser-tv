/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package dev.celenity.tv.browser.ui

import okhttp3.mockwebserver.MockWebServer
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import dev.celenity.tv.browser.ext.toUri
import dev.celenity.tv.browser.helpers.AndroidAssetDispatcher
import dev.celenity.tv.browser.helpers.MainActivityTestRule
import dev.celenity.tv.browser.ui.robots.BrowserRobot
import dev.celenity.tv.browser.ui.robots.navigationOverlay
import dev.celenity.tv.browser.webrender.FocusedDOMElementCacheInterface

/**
 * Ensures that, if the EngineView loses and regains focus, the focused DOM element maintains focus.
 * If the focused element changes, sites like YouTube TV may break. See
 * [FocusedDOMElementCacheInterface] for additional details on why this is necessary.
 */
class DOMElementFocusTest {

    @Rule @JvmField val activityTestRule = MainActivityTestRule()
    private lateinit var mockWebServer: MockWebServer

    @Before
    fun setUp() {
        mockWebServer = MockWebServer().apply {
            setDispatcher(AndroidAssetDispatcher())
            start()
        }
    }

    @After
    fun tearDown() {
        mockWebServer.shutdown()
    }

    /* ktlint-disable no-blank-line-before-rbrace */ // This imposes unreadable grouping.
    @Test
    fun domElementFocusTest() {
        val url = mockWebServer.url("pages/dom_element_focus_test.html").toString().toUri()!!
        navigationOverlay { }.enterUrlAndEnterToBrowser(url) {
            executeJS("document.querySelector('#input2').focus();")
            assertFocusedElementId("input2")

        // Opening and closing the overlay will move focus away and back to the EngineView.
        }.openOverlay { }.closeToBrowser {
            assertFocusedElementId("input2")
        }
    }

    private fun BrowserRobot.assertFocusedElementId(expectedId: String) {
        val focusedElementId = executeJS("return document.activeElement.id;")
        assertEquals(expectedId, focusedElementId)
    }
}
