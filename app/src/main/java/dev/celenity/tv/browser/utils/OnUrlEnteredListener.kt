/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package dev.celenity.tv.browser.utils

import dev.celenity.tv.browser.widget.InlineAutocompleteEditText.AutocompleteResult

// I'd define this in MainActivity but it's not kotlin so it can't have a default implementation.
interface OnUrlEnteredListener {
    fun onNonTextInputUrlEntered(urlStr: String) {}
    fun onTextInputUrlEntered(urlStr: String, autocompleteResult: AutocompleteResult?) {}
}
