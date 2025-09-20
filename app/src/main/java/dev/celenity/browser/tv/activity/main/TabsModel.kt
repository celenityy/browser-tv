package com.phlox.tvwebbrowser.activity.main

import android.view.View
import android.view.ViewGroup
import com.phlox.tvwebbrowser.TVBro
import com.phlox.tvwebbrowser.model.WebTabState
import com.phlox.tvwebbrowser.singleton.AppDatabase
import com.phlox.tvwebbrowser.utils.Utils
import com.phlox.tvwebbrowser.utils.activemodel.ActiveModel
import com.phlox.tvwebbrowser.utils.observable.ObservableList
import com.phlox.tvwebbrowser.utils.observable.ObservableValue
import com.phlox.tvwebbrowser.webengine.WebEngineWindowProviderCallback
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class TabsModel : ActiveModel() {
    companion object {
        var TAG: String = TabsModel::class.java.simpleName
    }

    var loaded = false
    val currentTab = ObservableValue<WebTabState?>(null)
    val tabsStates = ObservableList<WebTabState>()
    private val config = TVBro.config
    private var incognitoMode = config.incognitoMode

    init {
        tabsStates.subscribe({
            //auto-update positions on any list change
            var positionsChanged = false
            tabsStates.forEachIndexed { index, webTabState ->
                if (webTabState.position != index) {
                    webTabState.position = index
                    positionsChanged = true
                }
            }
            if (positionsChanged) {
                val tabsListClone = listOf(*tabsStates.toTypedArray())
                modelScope.launch(Dispatchers.Main) {
                    val tabsDao = AppDatabase.db.tabsDao()
                    tabsDao.updatePositions(tabsListClone)
                }
            }
        }, false)
    }

    fun loadState() = modelScope.launch(Dispatchers.Main) {
        if (loaded) {
            //check is incognito mode changed
            if (incognitoMode != config.incognitoMode) {
                incognitoMode = config.incognitoMode
                loaded = false
            } else {
                return@launch
            }
        }
        val tabsDao = AppDatabase.db.tabsDao()
        tabsStates.replaceAll(tabsDao.getAll(config.incognitoMode))
        loaded = true
    }

    fun saveTab(tab: WebTabState) = modelScope.launch(Dispatchers.Main) {
        val tabsDB = AppDatabase.db.tabsDao()
        if (tab.selected) {
            tabsDB.unselectAll(config.incognitoMode)
        }
        tab.saveWebViewStateToFile()
        if (tab.id != 0L) {
            tabsDB.update(tab)
        } else {
            tab.id = tabsDB.insert(tab)
        }
    }

    fun onCloseTab(tab: WebTabState) {
        tab.webEngine.onDetachFromWindow(completely = true, destroyTab = true)
        tabsStates.remove(tab)
        modelScope.launch(Dispatchers.Main) {
            val tabsDB = AppDatabase.db.tabsDao()
            tabsDB.delete(tab)
            launch { tab.removeFiles() }
        }
    }

    fun onCloseAllTabs() = modelScope.launch(Dispatchers.Main) {
        val tabsClone = ArrayList(tabsStates)
        tabsStates.clear()
        val tabsDB = AppDatabase.db.tabsDao()
        tabsDB.deleteAll(config.incognitoMode)
        withContext(Dispatchers.IO) {
            tabsClone.forEach { it.removeFiles() }
        }
    }

    fun onDetachActivity() {
        for (tab in tabsStates) {
            tab.webEngine.onDetachFromWindow(completely = true, destroyTab = false)
        }
    }

    fun changeTab(
        newTab: WebTabState,
        webViewProvider: (tab: WebTabState) -> View?,
        webViewParent: ViewGroup,
        fullScreenViewParent: ViewGroup,
        webEngineWindowProviderCallback: WebEngineWindowProviderCallback
    ) {
        if (currentTab.value == newTab) return
        tabsStates.forEach {
            it.selected = false
        }
        currentTab.value?.apply {
            webEngine.onDetachFromWindow(completely = false, destroyTab = false)
            onPause()
            saveTab(this)
        }

        newTab.selected = true
        currentTab.value = newTab
        var wv = newTab.webEngine.getView()
        var needReloadUrl = false
        if (wv == null) {
            wv = webViewProvider(newTab)
            if (wv == null) {
                return
            }
            needReloadUrl = !newTab.restoreWebView()
        }
        newTab.webEngine.onAttachToWindow(webEngineWindowProviderCallback, webViewParent, fullScreenViewParent)
        if (needReloadUrl) {
            newTab.webEngine.loadUrl(newTab.url)
        }
        newTab.webEngine.setNetworkAvailable(Utils.isNetworkConnected(TVBro.instance))
    }
}