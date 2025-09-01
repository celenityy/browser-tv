/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package org.mozilla.tv.firefox.channels

import android.content.Context
import org.mozilla.tv.firefox.architecture.KillswitchLocales
import java.util.Locale

/**
 * Data object that delivers custom configuration details to new channels
 */
data class ChannelConfig(
    val itemsMayBeRemoved: Boolean = false,
    val enabledInLocales: KillswitchLocales
) {
    companion object {
        fun getPinnedTileConfig(context: Context): ChannelConfig = ChannelConfig(
            itemsMayBeRemoved = true,
            enabledInLocales = KillswitchLocales.All
        )

        fun getTvGuideConfig(context: Context): ChannelConfig = ChannelConfig(
            itemsMayBeRemoved = true,
            enabledInLocales = KillswitchLocales.ActiveIn(Locale.US)
        )
    }
}
