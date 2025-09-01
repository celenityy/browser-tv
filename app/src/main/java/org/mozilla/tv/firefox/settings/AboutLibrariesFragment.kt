/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package org.mozilla.tv.firefox.settings

import mozilla.components.support.license.LibrariesListFragment
import org.mozilla.tv.firefox.R

/**
 * Displays the list of software licenses used within the app and it's full license content.
 */
class AboutLibrariesFragment : LibrariesListFragment() {
    override val licenseData = LicenseData(
        licenses = R.raw.third_party_licenses,
        metadata = R.raw.third_party_license_metadata,
    )

    override fun onResume() {
        super.onResume()

        val appName = getString(R.string.firefox_tv_brand_name)
        val pageTitle = getString(R.string.open_source_licenses_title, appName)
    }
}
