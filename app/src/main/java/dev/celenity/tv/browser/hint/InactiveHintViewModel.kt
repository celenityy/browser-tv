/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package dev.celenity.tv.browser.hint

import io.reactivex.Observable

class InactiveHintViewModel : HintViewModel {
    override val isDisplayed: Observable<Boolean> = Observable.just(false)
    override val hints: Observable<List<HintContent>> = Observable.just(listOf())
}
