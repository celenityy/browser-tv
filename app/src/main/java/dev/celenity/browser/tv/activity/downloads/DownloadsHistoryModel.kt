package dev.celenity.browser.tv.activity.downloads

import dev.celenity.browser.tv.model.Download
import dev.celenity.browser.tv.singleton.AppDatabase
import dev.celenity.browser.tv.utils.observable.ObservableValue
import dev.celenity.browser.tv.utils.activemodel.ActiveModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class DownloadsHistoryModel: ActiveModel() {
  val allItems = ArrayList<Download>()
  val lastLoadedItems = ObservableValue<List<Download>>(ArrayList())
  private var loading = false

  fun loadNextItems() = modelScope.launch(Dispatchers.Main) {
    if (loading) {
      return@launch
    }
    loading = true

    val newItems = AppDatabase.db.downloadDao().allByLimitOffset(allItems.size.toLong())
    lastLoadedItems.value = newItems
    allItems.addAll(newItems)

    loading = false
  }
}
