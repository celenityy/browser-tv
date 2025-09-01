/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package dev.celenity.tv.browser.settings

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import androidx.fragment.app.Fragment
import androidx.lifecycle.Observer
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.disposables.CompositeDisposable
import io.reactivex.disposables.Disposable
import kotlinx.android.synthetic.main.settings_screen_buttons.view.cancel_action
import kotlinx.android.synthetic.main.settings_screen_buttons.view.confirm_action
import kotlinx.android.synthetic.main.settings_screen_fxa_profile.view.avatarImage
import kotlinx.android.synthetic.main.settings_screen_fxa_profile.view.backButton
import kotlinx.android.synthetic.main.settings_screen_fxa_profile.view.buttonBrowserTabs
import kotlinx.android.synthetic.main.settings_screen_fxa_profile.view.buttonSignOut
import kotlinx.android.synthetic.main.settings_screen_fxa_profile.view.signedInAs
import kotlinx.android.synthetic.main.settings_screen_fxa_profile.view.userDisplayName
import kotlinx.android.synthetic.main.settings_screen_switch.toggle
import kotlinx.android.synthetic.main.settings_screen_switch.view.description
import kotlinx.android.synthetic.main.settings_screen_switch.view.toggle
import dev.celenity.tv.browser.R
import dev.celenity.tv.browser.architecture.BrowserViewModelProviders
import dev.celenity.tv.browser.channels.SettingsScreen
import dev.celenity.tv.browser.channels.SettingsTile
import dev.celenity.tv.browser.ext.serviceLocator
import dev.celenity.tv.browser.fxa.FxaRepo
import dev.celenity.tv.browser.utils.PicassoWrapper
import dev.celenity.tv.browser.utils.RoundCornerTransformation
import dev.celenity.tv.browser.utils.ServiceLocator

const val KEY_SETTINGS_TYPE = "KEY_SETTINGS_TYPE"

/** The settings for the app. */
class SettingsFragment : Fragment() {
    enum class Action {
        SESSION_CLEARED
    }

    var compositeDisposable = CompositeDisposable()
    private lateinit var serviceLocator: ServiceLocator

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        serviceLocator = context!!.serviceLocator

        val settingsVM = BrowserViewModelProviders.of(this@SettingsFragment).get(SettingsViewModel::class.java)
        val type: SettingsTile = SettingsScreen.valueOf(arguments!!.getString(KEY_SETTINGS_TYPE)!!)
        val view = when (type) {
            SettingsScreen.CLEAR_COOKIES -> setupClearCookiesScreen(inflater, container, settingsVM)
            SettingsScreen.FXA_PROFILE -> setupFxaProfileScreen(inflater, container)
            else -> {
                return container!!
            }
        }
        view.findViewById<ImageButton>(R.id.backButton).setOnClickListener {
            serviceLocator.screenController.handleBack(fragmentManager!!)
        }

        return view
    }

    private fun setupClearCookiesScreen(
        inflater: LayoutInflater,
        parentView: ViewGroup?,
        settingsViewModel: SettingsViewModel
    ): View {
        settingsViewModel.events.observe(viewLifecycleOwner, Observer {
            it?.consume { event ->
                when (event) {
                    Action.SESSION_CLEARED -> {
                        activity?.recreate()
                    }
                }
                true
            }
        })

        val view = inflater.inflate(R.layout.settings_screen_buttons, parentView, false)
        view.confirm_action.setOnClickListener {
            settingsViewModel.clearBrowsingData(serviceLocator.engineViewCache)
            serviceLocator.screenController.handleBack(fragmentManager!!)
        }
        view.cancel_action.setOnClickListener {
            serviceLocator.screenController.handleBack(fragmentManager!!)
        }
        return view
    }

    private fun setupFxaProfileScreen(
        inflater: LayoutInflater,
        parentView: ViewGroup?
    ): View {
        val view = inflater.inflate(R.layout.settings_screen_fxa_profile, parentView, false)

        setupFxaText(view)
        setupFxaProfileClickListeners(view)
        observeFxaProfile(view)
            .forEach { compositeDisposable.add(it) }

        val fxaRepo = serviceLocator.fxaRepo
        view.buttonBrowserTabs.setOnClickListener {
            fxaRepo.showFxaOnboardingScreen(context!!)
        }

        return view
    }

    private fun setupFxaText(view: View) {
        val appName = resources.getString(R.string.app_name)
        view.buttonBrowserTabs.text = resources.getString(R.string.fxa_settings_primary_button, appName)
        // Username is positioned and styled differently, so it is left blank here
        // and set on another TextView
        view.signedInAs.text = resources.getString(R.string.fxa_settings_body, "")
    }

    private fun setupFxaProfileClickListeners(view: View) {
        val screenController = serviceLocator.screenController
        val fxaRepo = serviceLocator.fxaRepo

        view.buttonSignOut.setOnClickListener {
            fxaRepo.logout()
            screenController.handleBack(fragmentManager!!)
        }
        view.backButton.setOnClickListener {
            screenController.handleBack(fragmentManager!!)
        }
    }

    private fun observeFxaProfile(view: View): List<Disposable> {
        val accountState = context!!.serviceLocator.fxaRepo.accountState

        return listOf(
            accountState
                .ofType(FxaRepo.AccountState.AuthenticatedWithProfile::class.java)
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe {
                    view.userDisplayName.text = it.profile.displayName
                    it.profile.avatarSetStrategy
                        .setTransformation(RoundCornerTransformation(view.avatarImage.width.toFloat()))
                        .invoke(view.avatarImage)
                },
            accountState
                .filter { it::class.java != FxaRepo.AccountState.AuthenticatedWithProfile::class.java }
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe {
                    view.userDisplayName.text = ""
                    view.signedInAs.text = resources.getString(R.string.fxa_settings_body_no_display_name)
                    PicassoWrapper.client.load(R.drawable.ic_default_avatar).into(view.avatarImage)
                }
        )
    }

    override fun onDestroyView() {
        super.onDestroyView()
        compositeDisposable.clear()
    }

    companion object {
        const val FRAGMENT_TAG = "settings"

        fun newInstance(type: SettingsScreen): SettingsFragment {
            return SettingsFragment().apply {
                arguments = Bundle().apply {
                    putString(KEY_SETTINGS_TYPE, type.toString())
                }
            }
        }
    }
}
