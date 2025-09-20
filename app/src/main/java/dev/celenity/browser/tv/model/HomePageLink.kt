package com.phlox.tvwebbrowser.model

import com.phlox.tvwebbrowser.TVBro
import org.json.JSONObject
import java.util.*

class HomePageLink(
    val title: String,
    val url: String,
    val favicon: String? = null,
    val favoriteId: Long? = null,
    val order: Int? = null
) {
    fun toJsonObj(): JSONObject {
        return JSONObject().apply {
            put("title", title)
            put("url", url)
            put("favicon", favicon)
            put("favoriteId", favoriteId)
            put("order", order)
        }
    }

    companion object {
        fun fromHistoryItem(item: HistoryItem): HomePageLink {
            return HomePageLink(item.title, item.url)
        }

        fun fromBookmarkItem(item: FavoriteItem): HomePageLink {
            return HomePageLink(item.title?: "", item.url?: "", item.favicon, item.id, item.order)
        }
    }
}
