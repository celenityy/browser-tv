/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package dev.celenity.tv.browser.engine

import androidx.test.core.app.ApplicationProvider
import mozilla.components.browser.engine.system.SystemEngine
import mozilla.components.concept.engine.EngineSession
import mozilla.components.concept.engine.request.RequestInterceptor
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito.mock
import dev.celenity.tv.browser.webrender.CustomContentRequestInterceptor
import dev.celenity.tv.browser.helpers.BrowserRobolectricTestRunner

@RunWith(BrowserRobolectricTestRunner::class)
class CustomContentRequestInterceptorTest {
    @Before
    fun setup() {
        SystemEngine.defaultUserAgent = "test-ua-string"
    }

    @Test
    fun `Interceptor should return content for browser-home`() {
        val result = testInterceptor("browser:home")

        assertNotNull(result)
        assertEquals("<html></html>", result!!.data)
        assertEquals("text/html", result.mimeType)
        assertEquals("UTF-8", result.encoding)
    }

    @Test
    fun `Interceptor should return content for browser-about`() {
        val result = testInterceptor("browser:about")

        assertNotNull(result)
        assertTrue(result!!.data.isNotEmpty())
        assertEquals("text/html", result.mimeType)
        assertEquals("UTF-8", result.encoding)
    }

    @Test
    fun `Interceptor should not intercept normal URLs`() {
        assertNull(testInterceptor("https://www.mozilla.org"))
        assertNull(testInterceptor("https://youtube.com/tv"))
    }

    @Test
    fun `Interceptor should return different content for browser-home and browser-about`() {
        val browserAbout = testInterceptor("browser:about")
        val browserHome = testInterceptor("browser:home")

        assertEquals(browserAbout!!.mimeType, browserHome!!.mimeType)
        assertEquals(browserAbout.encoding, browserHome.encoding)
        assertNotEquals(browserAbout.data, browserHome.data)
    }

    private fun testInterceptor(url: String): RequestInterceptor.InterceptionResponse.Content? {
        val interceptor = CustomContentRequestInterceptor(ApplicationProvider.getApplicationContext())
        return interceptor.onLoadRequest(mock(EngineSession::class.java), url)
    }
}
