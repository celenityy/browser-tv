/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package dev.celenity.tv.browser.architecture

import androidx.lifecycle.ViewModel
import org.junit.Assert.assertNotNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import dev.celenity.tv.browser.MainActivity
import org.robolectric.Robolectric
import dev.celenity.tv.browser.helpers.BrowserRobolectricTestRunner
import dev.celenity.tv.browser.navigationoverlay.ToolbarViewModel

@RunWith(BrowserRobolectricTestRunner::class)
class BrowserViewModelProvidersTest {

    private lateinit var mainActivity: MainActivity

    @Before
    fun setUp() {
        // Ideally, we'd run the Activity through onCreate but Robolectric fails on WebView shadow creation.
        mainActivity = Robolectric.buildActivity(MainActivity::class.java).get()
    }

    @Test(expected = IllegalArgumentException::class)
    fun `WHEN passed an unknown ViewModel THEN of(FragmentActivity) throws an exception`() {
        BrowserViewModelProviders.of(mainActivity).get(UnknownViewModel::class.java)
    }

    @Test
    fun `WHEN passed a valid ViewModel THEN of(FragmentActivity) returns a non-null value`() {
        assertNotNull(BrowserViewModelProviders.of(mainActivity).get(ToolbarViewModel::class.java))
    }
}

private class UnknownViewModel : ViewModel()
