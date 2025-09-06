/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package dev.celenity.tv.browser

import mozilla.components.browser.session.SessionManager
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito.`when`
import org.mockito.Mockito.mock
import org.mockito.Mockito.never
import org.mockito.Mockito.times
import org.mockito.Mockito.verify
import dev.celenity.tv.browser.helpers.BrowserRobolectricTestRunner
import dev.celenity.tv.browser.utils.ServiceLocator

@RunWith(BrowserRobolectricTestRunner::class)
class BrowserApplicationTest {

    private lateinit var application: BrowserApplication
    private lateinit var serviceLocator: ServiceLocator

    @Before
    fun setUp() {
        serviceLocator = mock(ServiceLocator::class.java)
        application = BrowserApplication().apply {
            serviceLocator = this@BrowserApplicationTest.serviceLocator
        }
    }

    @Test
    fun `WHEN onLowMemory is called THEN the sessionManager's onLowMemory method is called`() {
        val sessionManager = mock(SessionManager::class.java)
        `when`(serviceLocator.sessionManager).thenReturn(sessionManager)

        verify(sessionManager, never()).onLowMemory()
        application.onLowMemory()
        verify(sessionManager, times(1)).onLowMemory()
    }
}
