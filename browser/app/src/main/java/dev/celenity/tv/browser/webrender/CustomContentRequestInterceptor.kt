/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package dev.celenity.tv.browser.webrender

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat.startActivity
import mozilla.components.browser.errorpages.ErrorType
import mozilla.components.concept.engine.EngineSession
import mozilla.components.concept.engine.request.RequestInterceptor
import dev.celenity.tv.browser.R
import dev.celenity.tv.browser.ext.serviceLocator
import dev.celenity.tv.browser.utils.BuildConstants.getInterceptionResponseContent
import dev.celenity.tv.browser.utils.URLs

/**
 * [RequestInterceptor] implementation to inject custom content for browser:* pages.
 */
class CustomContentRequestInterceptor(
    private val context: Context
) : RequestInterceptor {

    private var currentPageURL = ""

    override fun onLoadRequest(session: EngineSession, uri: String): RequestInterceptor.InterceptionResponse.Content? {
        currentPageURL = uri

        return when (uri) {
            URLs.APP_URL_HOME ->
                RequestInterceptor.InterceptionResponse.Content("<html></html>")

            URLs.URL_ABOUT -> getInterceptionResponseContent(
                LocalizedContent.generateAboutPage(context))

            URLs.URL_GPL -> getInterceptionResponseContent(
                LocalizedContent.generatePage(context, R.raw.gpl))

            else -> null
        }
    }

    override fun onErrorRequest(session: EngineSession, errorType: ErrorType, uri: String?): RequestInterceptor.ErrorResponse? {
        return uri?.let {
            val data = ErrorPage.loadErrorPage(context, uri, errorType)
            RequestInterceptor.ErrorResponse(data, uri)
        }
    }
}
