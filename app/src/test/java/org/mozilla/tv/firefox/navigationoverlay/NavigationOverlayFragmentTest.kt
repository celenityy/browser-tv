/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package org.mozilla.tv.firefox.navigationoverlay

import android.view.KeyEvent
import io.mockk.MockKAnnotations
import io.mockk.impl.annotations.MockK
import io.mockk.verify
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mozilla.tv.firefox.helpers.KeyEventHelper
import org.mozilla.tv.firefox.helpers.FirefoxRobolectricTestRunner

@RunWith(FirefoxRobolectricTestRunner::class)
class NavigationOverlayFragmentTest {

    private lateinit var navigationOverlayFragment: NavigationOverlayFragment

    @Before
    fun setUp() {
        MockKAnnotations.init(this)

        navigationOverlayFragment = NavigationOverlayFragment()
    }

    private fun getNonDpadSelectEvents(): List<KeyEvent> = KeyEventHelper.getRandomKeyEventsExcept(listOf(
        KeyEvent.KEYCODE_DPAD_CENTER,
        KeyEvent.KEYCODE_ENTER
    ))

    private fun getDpadSelectDownEvents(): List<KeyEvent> = KeyEventHelper.getDownUpKeyEvents(listOf(
        KeyEvent.KEYCODE_DPAD_CENTER,
        KeyEvent.KEYCODE_ENTER
    )).filter { it.action == KeyEvent.ACTION_DOWN }
}
