package dev.celenity.browser.tv.activity.main

import android.os.Build
import android.util.Log
import dev.celenity.browser.tv.BrowserTV
import dev.celenity.browser.tv.BuildConfig
import dev.celenity.browser.tv.Config
import dev.celenity.browser.tv.model.FavoriteItem
import dev.celenity.browser.tv.model.HistoryItem
import dev.celenity.browser.tv.model.HomePageLink
import dev.celenity.browser.tv.model.WebTabState
import dev.celenity.browser.tv.singleton.AppDatabase
import dev.celenity.browser.tv.utils.UpdateChecker
import dev.celenity.browser.tv.utils.activemodel.ActiveModel
import dev.celenity.browser.tv.utils.deleteDirectory
import dev.celenity.browser.tv.utils.observable.ObservableList
import dev.celenity.browser.tv.webengine.gecko.HomePageHelper
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class MainActivityViewModel: ActiveModel() {
    companion object {
        var TAG: String = MainActivityViewModel::class.java.simpleName
        const val WEB_VIEW_DATA_FOLDER = "app_webview"
        const val WEB_VIEW_CACHE_FOLDER = "WebView"
        const val WEB_VIEW_DATA_BACKUP_DIRECTORY_SUFFIX = "_backup"
        const val INCOGNITO_DATA_DIRECTORY_SUFFIX = "incognito"
    }

    var loaded = false
    var lastHistoryItem: HistoryItem? = null
    private var lastHistoryItemSaveJob: Job? = null
    val homePageLinks = ObservableList<HomePageLink>()
    val config = BrowserTV.config

    fun loadState() = modelScope.launch(Dispatchers.Main) {
        Log.d(TAG, "loadState")
        if (loaded) return@launch
        checkVersionCodeAndRunMigrations()
        initHistory()
        loadHomePageLinks()
        loaded = true
    }

    private suspend fun checkVersionCodeAndRunMigrations() {
        Log.d(TAG, "checkVersionCodeAndRunMigrations")
        if (config.appVersionCodeMark != BuildConfig.VERSION_CODE) {
            Log.i(TAG, "App version code changed from ${config.appVersionCodeMark} to ${BuildConfig.VERSION_CODE}")
            config.appVersionCodeMark = BuildConfig.VERSION_CODE
            withContext(Dispatchers.IO) {
                UpdateChecker.clearTempFilesIfAny(BrowserTV.instance)
            }
        }
    }

    private suspend fun initHistory() {
        Log.d(TAG, "initHistory")
        val count = AppDatabase.db.historyDao().count()
        if (count > 5000) {
            val c = Calendar.getInstance()
            c.add(Calendar.MONTH, -3)
            AppDatabase.db.historyDao().deleteWhereTimeLessThan(c.time.time)
        }
        try {
            val result = AppDatabase.db.historyDao().last()
            if (result.isNotEmpty()) {
                lastHistoryItem = result[0]
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private suspend fun loadHomePageLinks() {
        Log.d(TAG, "loadHomePageLinks")
        val config = BrowserTV.config
        if (config.homePageMode == Config.HomePageMode.HOME_PAGE) {
            when (config.homePageLinksMode) {
                Config.HomePageLinksMode.MOST_VISITED -> {
                    homePageLinks.replaceAll(
                        AppDatabase.db.historyDao().frequentlyUsedUrls()
                            .map { HomePageLink.fromHistoryItem(it) })
                }
                Config.HomePageLinksMode.LATEST_HISTORY -> {
                    homePageLinks.replaceAll(
                        AppDatabase.db.historyDao().last(8)
                            .map { HomePageLink.fromHistoryItem(it) })
                }
                Config.HomePageLinksMode.BOOKMARKS -> {
                    val favorites = ArrayList<FavoriteItem>()
                    favorites.addAll(AppDatabase.db.favoritesDao().getHomePageBookmarks())
                    homePageLinks.replaceAll(favorites.map { HomePageLink.fromBookmarkItem(it) })
                }
            }
        }
    }

    fun logVisitedHistory(title: String?, url: String, faviconHash: String?) {
        Log.d(TAG, "logVisitedHistory: $url")
        if ((url == lastHistoryItem?.url) || url == HomePageHelper.HOME_PAGE_URL || !url.startsWith("http", true)) {
            return
        }

        val now = System.currentTimeMillis()
        val minVisitedInterval = 5000L //5 seconds

        lastHistoryItem?.let {
            if ((!it.saved) && (it.time + minVisitedInterval) > now) {
                lastHistoryItemSaveJob?.cancel()
            }
        }

        val item = HistoryItem()
        item.url = url
        item.title = title ?: ""
        item.time = now
        item.favicon = faviconHash
        lastHistoryItem = item
        lastHistoryItemSaveJob = modelScope.launch(Dispatchers.Main) {
            delay(minVisitedInterval)
            item.id = AppDatabase.db.historyDao().insert(item)
            item.saved = true
        }
    }

    fun onTabTitleUpdated(tab: WebTabState) {
        Log.d(TAG, "onTabTitleUpdated: ${tab.url} ${tab.title}")
        if (BrowserTV.config.incognitoMode) return
        val lastHistoryItem = lastHistoryItem ?: return
        if (tab.url == lastHistoryItem.url) {
            lastHistoryItem.title = tab.title
            if (lastHistoryItem.saved) {
                modelScope.launch(Dispatchers.Main) {
                    AppDatabase.db.historyDao().updateTitle(lastHistoryItem.id, lastHistoryItem.title)
                }
            }
        }
    }

    fun prepareSwitchToIncognito() {
        Log.d(TAG, "prepareSwitchToIncognito")
        if (BrowserTV.config.isWebEngineGecko()) return
        //to isolate incognito mode data:
        //in api >= 28 we just use another directory for WebView data
        //on earlier apis we backup-ing existing WebView data directory
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val incognitoWebViewData = File(
                BrowserTV.instance.filesDir.parentFile!!.absolutePath +
                        "/" + WEB_VIEW_DATA_FOLDER + "_" + INCOGNITO_DATA_DIRECTORY_SUFFIX
            )
            if (incognitoWebViewData.exists()) {
                Log.i(TAG, "Looks like we already in incognito mode")
                return
            }
        } else {
            val webViewData = File(
                BrowserTV.instance.filesDir.parentFile!!.absolutePath +
                        "/" + WEB_VIEW_DATA_FOLDER
            )
            val backupedWebViewData = File(
                BrowserTV.instance.filesDir.parentFile!!.absolutePath +
                        "/" + WEB_VIEW_DATA_FOLDER + WEB_VIEW_DATA_BACKUP_DIRECTORY_SUFFIX
            )
            if (backupedWebViewData.exists()) {
                Log.i(TAG, "Looks like we already in incognito mode")
                return
            }
            webViewData.renameTo(backupedWebViewData)
            val webViewCache =
                File(BrowserTV.instance.cacheDir.absolutePath + "/" + WEB_VIEW_CACHE_FOLDER)
            val backupedWebViewCache = File(
                BrowserTV.instance.cacheDir.absolutePath + "/" + WEB_VIEW_CACHE_FOLDER +
                        WEB_VIEW_DATA_BACKUP_DIRECTORY_SUFFIX
            )
            webViewCache.renameTo(backupedWebViewCache)
        }
    }

    fun clearIncognitoData() = modelScope.launch(Dispatchers.IO) {
        Log.d(TAG, "clearIncognitoData")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val webViewData = File(
                BrowserTV.instance.filesDir.parentFile!!.absolutePath +
                        "/" + WEB_VIEW_DATA_FOLDER + "_" + INCOGNITO_DATA_DIRECTORY_SUFFIX
            )
            deleteDirectory(webViewData)
            var webViewCache =
                File(
                    BrowserTV.instance.cacheDir.absolutePath + "/" + WEB_VIEW_CACHE_FOLDER +
                            "_" + INCOGNITO_DATA_DIRECTORY_SUFFIX
                )
            if (!webViewCache.exists()) {
                webViewCache = File(
                    BrowserTV.instance.cacheDir.absolutePath + "/" +
                            WEB_VIEW_CACHE_FOLDER.lowercase(Locale.getDefault()) +
                            "_" + INCOGNITO_DATA_DIRECTORY_SUFFIX
                )
            }
            deleteDirectory(webViewCache)
        } else {
            val webViewData = File(
                BrowserTV.instance.filesDir.parentFile!!.absolutePath +
                        "/" + WEB_VIEW_DATA_FOLDER
            )
            deleteDirectory(webViewData)
            val webViewCache =
                File(BrowserTV.instance.cacheDir.absolutePath + "/" + WEB_VIEW_CACHE_FOLDER)
            deleteDirectory(webViewCache)

            val backupedWebViewData = File(
                BrowserTV.instance.filesDir.parentFile!!.absolutePath +
                        "/" + WEB_VIEW_DATA_FOLDER + WEB_VIEW_DATA_BACKUP_DIRECTORY_SUFFIX
            )
            backupedWebViewData.renameTo(webViewData)
            val backupedWebViewCache = File(
                BrowserTV.instance.cacheDir.absolutePath + "/" + WEB_VIEW_CACHE_FOLDER +
                        WEB_VIEW_DATA_BACKUP_DIRECTORY_SUFFIX
            )
            backupedWebViewCache.renameTo(webViewCache)
        }
    }

    override fun onClear() {

    }

    fun removeHomePageLink(bookmark: HomePageLink) = modelScope.launch {
        homePageLinks.remove(bookmark)
        bookmark.favoriteId?.let {
            AppDatabase.db.favoritesDao().delete(it)
        }
    }

    fun onHomePageLinkEdited(item: FavoriteItem) = modelScope.launch {
        if (item.id == 0L) {
            val lastInsertRowId = AppDatabase.db.favoritesDao().insert(item)
            item.id = lastInsertRowId
            homePageLinks.add(HomePageLink.fromBookmarkItem(item))
        } else {
            AppDatabase.db.favoritesDao().update(item)
            val index = homePageLinks.indexOfFirst { it.favoriteId == item.id }
            if (index != -1) {
                homePageLinks[index] = HomePageLink.fromBookmarkItem(item)
            }
        }
    }
}
