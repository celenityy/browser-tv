package dev.celenity.browser.tv.activity.history

import dev.celenity.browser.tv.model.HistoryItem
import dev.celenity.browser.tv.singleton.AppDatabase
import dev.celenity.browser.tv.utils.observable.ObservableValue
import dev.celenity.browser.tv.utils.activemodel.ActiveModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class HistoryModel: ActiveModel() {
    val lastLoadedItems = ObservableValue<List<HistoryItem>>(ArrayList())
    private var loading = false
    var searchQuery = ""


    fun loadItems(eraseOldResults: Boolean, offset: Long = 0) = modelScope.launch(Dispatchers.Main) {
        if (loading) {
            return@launch
        }
        loading = true

        lastLoadedItems.value = if ("" == searchQuery) {
            AppDatabase.db.historyDao().allByLimitOffset(offset)
        } else {
            AppDatabase.db.historyDao().search(searchQuery, searchQuery)
        }
        loading = false
    }
}
