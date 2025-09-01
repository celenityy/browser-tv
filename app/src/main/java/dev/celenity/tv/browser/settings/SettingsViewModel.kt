package dev.celenity.tv.browser.settings

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import mozilla.components.support.base.observer.Consumable
import dev.celenity.tv.browser.session.SessionRepo
import dev.celenity.tv.browser.webrender.EngineViewCache

class SettingsViewModel(
    private val settingsRepo: SettingsRepo,
    private val sessionRepo: SessionRepo
) : ViewModel() {
    private var _events = MutableLiveData<Consumable<SettingsFragment.Action>>()

    val events: LiveData<Consumable<SettingsFragment.Action>> = _events

    fun clearBrowsingData(engineViewCache: EngineViewCache) {
        sessionRepo.clearBrowsingData(engineViewCache)
        _events.value = Consumable.from(SettingsFragment.Action.SESSION_CLEARED)
    }
}
