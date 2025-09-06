/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package dev.celenity.tv.browser.fxa

import io.mockk.MockKAnnotations
import io.mockk.every
import io.mockk.impl.annotations.MockK
import io.mockk.mockk
import io.mockk.verify
import io.reactivex.Observable
import mozilla.components.concept.sync.DeviceType
import mozilla.components.concept.sync.TabData
import org.junit.Before
import org.junit.Test
import dev.celenity.tv.browser.R
import dev.celenity.tv.browser.framework.UnresolvedString

class FxaReceivedTabTest {

    @Before
    fun before() {
        MockKAnnotations.init(this)
    }

    @Test
    fun `WHEN one receive tab event occurs with two URLs and a non-null device THEN the corresponding event is emitted`() {
        val expectedDeviceName = "Expected device name"
        val expectedTabUrls = getTwoExpectedTabUrls()
        val expected = FxaReceivedTab(
            expectedTabUrls[0],
            UnresolvedString(R.string.fxa_tab_sent_toast, listOf(expectedDeviceName)),
            FxaReceivedTab.Metadata(DeviceType.DESKTOP, 2)
        )

        val inputTabData = expectedTabUrls.mapIndexed { i, url -> TabData("tab title $i", url) }
    }

    @Test
    fun `WHEN a receive tab event occurs with two URLs and a null device THEN the corresponding event is emitted`() {
        val expectedTabUrls = getTwoExpectedTabUrls()
        val expected = FxaReceivedTab(
            expectedTabUrls[0],
            UnresolvedString(R.string.fxa_tab_sent_toast_no_device),
            FxaReceivedTab.Metadata(DeviceType.UNKNOWN, 2)
        )

        val inputTabData = expectedTabUrls.mapIndexed { i, url -> TabData("tab title $i", url) }
    }

    private fun getTwoExpectedTabUrls() = listOf(
        "https://google.com",
        "https://android.com"
    )

    @Test
    fun `WHEN a receive tab event occurs with blank and non-blank URLs THEN an event with tabs with blank URLs filtered out is emitted`() {
        val expectedTabUrls = getTwoExpectedTabUrls()
        val expected = FxaReceivedTab(
            expectedTabUrls[0],
            UnresolvedString(R.string.fxa_tab_sent_toast_no_device),
            FxaReceivedTab.Metadata(DeviceType.UNKNOWN, 2)
        )

        val inputTabUrls = listOf(" ", "") + expectedTabUrls + listOf("  ", "", " ")
        val inputTabData = inputTabUrls.mapIndexed { i, url -> TabData("tab title $i", url) }
    }
}
