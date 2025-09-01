/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package org.mozilla.tv.firefox.fxa

import io.reactivex.Observable
import mozilla.components.concept.sync.DeviceType
import mozilla.components.concept.sync.TabData
import mozilla.components.support.base.log.logger.Logger
import org.mozilla.tv.firefox.R
import org.mozilla.tv.firefox.framework.UnresolvedString

private val logger = Logger(FxaReceivedTab::class.java.simpleName)

/**
 * A data container for tabs received from a single device via FxA. While we currently support
 * only one tab, this container can actually contain multiple received tabs.
 *
 * This container exists to avoid exposing the underlying [DeviceEvent.TabReceived] events to
 * consumers.
 *
 * @param [tabReceivedNotificationText] If possible, this will describe where the tab came from
 * (e.g., "Sent from Severin's Pixel 2").  If we don't know those details, it will be more
 * vague (e.g., "Tab received")
 */
data class FxaReceivedTab(
    val url: String,
    val tabReceivedNotificationText: UnresolvedString,
    val metadata: Metadata
) {
    data class Metadata(
        val deviceType: DeviceType, // We expose the FxA DeviceType to avoid excessive boilerplate.
    )
}

/** An Exception thrown when during the receive tab process. */
private class ReceiveTabException(msg: String) : Exception(msg)
