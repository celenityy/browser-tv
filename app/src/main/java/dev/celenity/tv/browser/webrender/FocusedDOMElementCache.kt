/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package dev.celenity.tv.browser.webrender

import mozilla.components.concept.engine.EngineView
import dev.celenity.tv.browser.ext.cacheDomElement
import dev.celenity.tv.browser.ext.restoreDomElement

class FocusedDOMElementCache(private val engineView: EngineView) :
        FocusedDOMElementCacheInterface {

    override fun cache() {
        engineView.cacheDomElement()
    }

    override fun restore() {
        engineView.restoreDomElement()
    }
}
