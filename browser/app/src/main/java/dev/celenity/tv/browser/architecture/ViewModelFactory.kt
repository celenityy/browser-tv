/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package dev.celenity.tv.browser.architecture

import android.app.Application
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.ViewModelProviders
import dev.celenity.tv.browser.R
import dev.celenity.tv.browser.hint.HintContentFactory
import dev.celenity.tv.browser.navigationoverlay.ChannelTitles
import dev.celenity.tv.browser.navigationoverlay.NavigationOverlayViewModel
import dev.celenity.tv.browser.navigationoverlay.OverlayHintViewModel
import dev.celenity.tv.browser.navigationoverlay.ToolbarViewModel
import dev.celenity.tv.browser.settings.SettingsViewModel
import dev.celenity.tv.browser.utils.ServiceLocator
import dev.celenity.tv.browser.webrender.WebRenderHintViewModel
import dev.celenity.tv.browser.webrender.WebRenderViewModel

/**
 * Used by [ViewModelProviders] to instantiate [ViewModel]s with constructor arguments.
 *
 * This should be used through [BrowserViewModelProviders.of].
 * Example usage:
 * ```kotlin
 * val myViewModel = BrowserViewModelProviders.of(this).get(ExampleViewModel::class.java)
 * ```
 */
class ViewModelFactory(
    private val serviceLocator: ServiceLocator,
    private val app: Application
) : ViewModelProvider.Factory {

    private val resources = app.resources
    private val hintContentFactory = HintContentFactory(resources)

    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel?> create(modelClass: Class<T>): T {
        return when (modelClass) {
            ToolbarViewModel::class.java -> ToolbarViewModel(
                sessionRepo = serviceLocator.sessionRepo,
                pinnedTileRepo = serviceLocator.pinnedTileRepo
            ) as T

            SettingsViewModel::class.java -> SettingsViewModel(
                serviceLocator.settingsRepo,
                serviceLocator.sessionRepo
            ) as T

            NavigationOverlayViewModel::class.java -> NavigationOverlayViewModel(
                serviceLocator.screenController,
                ChannelTitles(
                    pinned = app.getString(R.string.pinned_tile_channel_title),
                    newsAndPolitics = resources.getString(R.string.news_channel_title),
                    sports = resources.getString(R.string.sports_channel_title),
                    music = resources.getString(R.string.music_channel_title),
                    food = resources.getString(R.string.food_channel_title)
                ),
                serviceLocator.channelRepo,
                ToolbarViewModel(
                        sessionRepo = serviceLocator.sessionRepo,
                        pinnedTileRepo = serviceLocator.pinnedTileRepo
                ),
                serviceLocator.fxaRepo,
                serviceLocator.fxaLoginUseCase
            ) as T

            OverlayHintViewModel::class.java -> OverlayHintViewModel(
                serviceLocator.sessionRepo,
                hintContentFactory.getCloseMenuHint()
            ) as T

            WebRenderHintViewModel::class.java -> WebRenderHintViewModel(
                serviceLocator.sessionRepo,
                serviceLocator.cursorModel,
                serviceLocator.screenController,
                hintContentFactory.getOpenMenuHint()
            ) as T

            WebRenderViewModel::class.java -> WebRenderViewModel(
                serviceLocator.screenController,
                serviceLocator.fxaLoginUseCase
            ) as T

        // This class needs to either return a ViewModel or throw, so we have no good way of silently handling
        // failures in production. However a failure could only occur if code requests a VM that we have not added
        // to this factory, so any problems should be caught in dev.
            else -> throw IllegalArgumentException(
                "A class was passed to ViewModelFactory#create that it does not " +
                    "know how to handle\nClass name: ${modelClass.simpleName}"
            )
        }
    }
}
