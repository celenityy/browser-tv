/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package dev.celenity.tv.browser.ext

import android.content.Context
import mozilla.components.concept.engine.EngineSession

// This is only required for [SystemEngineSession]
fun EngineSession.resetView(@Suppress("UNUSED_PARAMETER") context: Context) { }
