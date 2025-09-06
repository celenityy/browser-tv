/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package dev.celenity.tv.browser.ext

import android.content.Context
import android.view.accessibility.AccessibilityManager
import dev.celenity.tv.browser.webrender.WebRenderComponents
import dev.celenity.tv.browser.BrowserApplication

// Extension functions for the Context class

fun Context.getAccessibilityManager() = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager

// AccessibilityManager.isAccessibilityEnabled can be enabled for more things than just VoiceView. If we want
// VoiceView, we only need to check this one field; via comments on https://stackoverflow.com/a/12362545/582004.
fun Context.isVoiceViewEnabled() = getAccessibilityManager().isTouchExplorationEnabled

fun Context.getDimenPixelSize(dimen: Int) = resources.getDimensionPixelSize(dimen)

/**
 * Get the BrowserApplication object from a context.
 */
val Context.application: BrowserApplication
    get() = applicationContext as BrowserApplication

/**
 * Get the components of this application.
 */
val Context.webRenderComponents: WebRenderComponents
    get() = application.components
