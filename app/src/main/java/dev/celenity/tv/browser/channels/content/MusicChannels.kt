/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package dev.celenity.tv.browser.channels.content

import dev.celenity.tv.browser.R
import dev.celenity.tv.browser.channels.ChannelTile
import dev.celenity.tv.browser.channels.TileSource

fun ChannelContent.getMusicChannels(): List<ChannelTile> = listOf(
    ChannelTile(
        url = "https://www.npr.org/stations/",
        title = "NPR",
        subtitle = null,
        setImage = setImage(R.drawable.tile_music_npr),
        tileSource = TileSource.MUSIC,
        id = "nprStations"
    ),
    ChannelTile(
        url = "https://bandcamp.com/#discover",
        title = "Bandcamp",
        subtitle = null,
        setImage = setImage(R.drawable.tile_music_bandcamp),
        tileSource = TileSource.MUSIC,
        id = "bandcamp"
    )
)
