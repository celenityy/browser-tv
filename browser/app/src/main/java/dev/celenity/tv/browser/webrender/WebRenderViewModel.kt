/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package dev.celenity.tv.browser.webrender

import androidx.lifecycle.ViewModel
import io.reactivex.Observable
import dev.celenity.tv.browser.R
import dev.celenity.tv.browser.ScreenController
import dev.celenity.tv.browser.ScreenControllerStateMachine.ActiveScreen
import dev.celenity.tv.browser.fxa.FxaLoginUseCase

class WebRenderViewModel(
    screenController: ScreenController,
    fxaLoginUseCase: FxaLoginUseCase
) : ViewModel() {

    val onFxaLoginSuccess = fxaLoginUseCase.onLoginSuccess

    val focusRequests: Observable<Int> = screenController.currentActiveScreen
            .filter { currentScreen -> currentScreen == ActiveScreen.WEB_RENDER }
            .map { R.id.engineView }
}
