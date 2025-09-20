package dev.celenity.browser.tv.activity.main.view.tabs

import androidx.recyclerview.widget.DiffUtil
import dev.celenity.browser.tv.model.WebTabState

class TabsDiffUtillCallback(val oldList: List<WebTabState>, val newList: List<WebTabState>): DiffUtil.Callback() {
    override fun getOldListSize(): Int = oldList.size

    override fun getNewListSize(): Int = newList.size

    override fun areItemsTheSame(oldItemPosition: Int, newItemPosition: Int): Boolean {
        return oldList[oldItemPosition].id == newList[newItemPosition].id
    }

    override fun areContentsTheSame(oldItemPosition: Int, newItemPosition: Int): Boolean =
        areItemsTheSame(oldItemPosition, newItemPosition)
}
