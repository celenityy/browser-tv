package dev.celenity.browser.tv.activity.main.dialogs.settings

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.text.Html
import android.util.AttributeSet
import android.view.LayoutInflater
import android.view.View
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.ScrollView
import dev.celenity.browser.tv.BrowserTV
import dev.celenity.browser.tv.BuildConfig
import dev.celenity.browser.tv.R
import dev.celenity.browser.tv.activity.IncognitoModeMainActivity
import dev.celenity.browser.tv.activity.main.AutoUpdateModel
import dev.celenity.browser.tv.activity.main.MainActivity
import dev.celenity.browser.tv.activity.main.SettingsModel
import dev.celenity.browser.tv.databinding.ViewSettingsVersionBinding
import dev.celenity.browser.tv.utils.activemodel.ActiveModelsRepository
import dev.celenity.browser.tv.utils.activity

@SuppressLint("SetTextI18n")
class VersionSettingsView @JvmOverloads constructor(
        context: Context, attrs: AttributeSet? = null, defStyleAttr: Int = 0
) : ScrollView(context, attrs, defStyleAttr) {
    private var vb = ViewSettingsVersionBinding.inflate(LayoutInflater.from(getContext()), this, true)
    var config = BrowserTV.config
    var settingsModel = ActiveModelsRepository.get(SettingsModel::class, activity!!)
    var autoUpdateModel = ActiveModelsRepository.get(AutoUpdateModel::class, activity!!)
    var callback: Callback? = null

    interface Callback {
        fun onNeedToCloseSettings()
    }

    init {
        vb.tvVersion.text = context.getString(R.string.version_s, BuildConfig.VERSION_NAME)

        val engineVersion = if (settingsModel.config.isWebEngineGecko()) {"GeckoView: " + 
            org.mozilla.geckoview.BuildConfig.MOZ_APP_VERSION
        } else {
            "unknown"
        }
        vb.tvWebViewVersion.text = engineVersion

        vb.tvLink.text = Html.fromHtml("<p><u>https://github.com/celenityy/browser-tv</u></p>")
        vb.tvLink.setOnClickListener {
            loadUrl(vb.tvLink.text.toString())
        }

        vb.tvBroLink.setOnClickListener {
            loadUrl("https://github.com/truefedex/tv-bro")
        }

        if (BuildConfig.BUILT_IN_AUTO_UPDATE) {
            vb.chkAutoCheckUpdates.isChecked = autoUpdateModel.needAutoCheckUpdates

            vb.chkAutoCheckUpdates.setOnCheckedChangeListener { buttonView, isChecked ->
                autoUpdateModel.saveAutoCheckUpdates(isChecked)

                updateUIVisibility()
            }

            vb.spUpdateChannel.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
                override fun onItemSelected(
                    parent: AdapterView<*>,
                    view: View,
                    position: Int,
                    id: Long
                ) {
                    val selectedChannel =
                        autoUpdateModel.updateChecker.versionCheckResult!!.availableChannels[position]
                    if (selectedChannel == config.updateChannel) return
                    config.updateChannel = selectedChannel
                    autoUpdateModel.checkUpdate(true) {
                        updateUIVisibility()
                    }
                }

                override fun onNothingSelected(parent: AdapterView<*>) {

                }
            }

            vb.btnUpdate.setOnClickListener {
                callback?.onNeedToCloseSettings()
                autoUpdateModel.showUpdateDialogIfNeeded(activity as MainActivity, true)
            }

            updateUIVisibility()
        } else {
            vb.chkAutoCheckUpdates.visibility = View.INVISIBLE
        }
    }

    private fun loadUrl(url: String) {
        callback?.onNeedToCloseSettings()
        val activityClass = if (settingsModel.config.incognitoMode)
            IncognitoModeMainActivity::class.java else MainActivity::class.java
        val intent = Intent(activity, activityClass)
        intent.data = Uri.parse(url)
        activity?.startActivity(intent)
    }

    private fun updateUIVisibility() {
        if (autoUpdateModel.updateChecker.versionCheckResult == null) {
            autoUpdateModel.checkUpdate(false) {
                if (autoUpdateModel.updateChecker.versionCheckResult != null) {
                    updateUIVisibility()
                }
            }
            return
        }

        vb.tvUpdateChannel.visibility = if (autoUpdateModel.needAutoCheckUpdates) View.VISIBLE else View.INVISIBLE
        vb.spUpdateChannel.visibility = if (autoUpdateModel.needAutoCheckUpdates) View.VISIBLE else View.INVISIBLE

        if (autoUpdateModel.needAutoCheckUpdates) {
            val adapter = ArrayAdapter(context, android.R.layout.simple_spinner_item,
                autoUpdateModel.updateChecker.versionCheckResult!!.availableChannels)
            adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
            vb.spUpdateChannel.adapter = adapter
            val selected = autoUpdateModel.updateChecker.versionCheckResult!!.availableChannels.indexOf(config.updateChannel)
            if (selected != -1) {
                val tmp = vb.spUpdateChannel.onItemSelectedListener
                vb.spUpdateChannel.onItemSelectedListener = null
                vb.spUpdateChannel.setSelection(selected)
                vb.spUpdateChannel.onItemSelectedListener = tmp
            }
        }

        val hasUpdate = autoUpdateModel.updateChecker.hasUpdate()
        vb.tvNewVersion.visibility = if (autoUpdateModel.needAutoCheckUpdates && hasUpdate) View.VISIBLE else View.INVISIBLE
        vb.btnUpdate.visibility = if (autoUpdateModel.needAutoCheckUpdates && hasUpdate) View.VISIBLE else View.INVISIBLE
        if (hasUpdate) {
            vb.tvNewVersion.text = context.getString(R.string.new_version_available_s, autoUpdateModel.updateChecker.versionCheckResult!!.latestVersionName)
        }
    }
}
