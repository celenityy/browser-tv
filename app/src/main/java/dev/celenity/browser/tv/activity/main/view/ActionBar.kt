package dev.celenity.browser.tv.activity.main.view

import android.content.Context
import android.transition.TransitionManager
import android.util.AttributeSet
import android.view.KeyEvent
import android.view.LayoutInflater
import android.view.View.OnFocusChangeListener
import android.view.View.OnKeyListener
import android.view.animation.Animation
import android.view.animation.AnimationUtils
import android.view.inputmethod.InputMethodManager
import android.widget.ImageButton
import android.widget.LinearLayout
import androidx.appcompat.app.AppCompatActivity
import dev.celenity.browser.tv.BrowserTV
import dev.celenity.browser.tv.Config
import dev.celenity.browser.tv.R
import dev.celenity.browser.tv.activity.downloads.ActiveDownloadsModel
import dev.celenity.browser.tv.databinding.ViewActionbarBinding
import dev.celenity.browser.tv.utils.Utils
import dev.celenity.browser.tv.utils.activemodel.ActiveModelsRepository
import dev.celenity.browser.tv.webengine.gecko.HomePageHelper

class ActionBar @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null
) : LinearLayout(context, attrs) {

    private val vb = ViewActionbarBinding.inflate( LayoutInflater.from(context),this)
    var callback: Callback? = null
    private var downloadAnimation: Animation? = null
    private var downloadsModel = ActiveModelsRepository.get(ActiveDownloadsModel::class, context)
    private var extendedAddressBarMode = false

    interface Callback {
        fun closeWindow()
        fun showDownloads()
        fun showFavorites()
        fun showHistory()
        fun showSettings()
        fun initiateVoiceSearch()
        fun search(text: String)
        fun onExtendedAddressBarMode()
        fun onUrlInputDone()
        fun toggleIncognitoMode()
    }

    private val etUrlFocusChangeListener = OnFocusChangeListener { _, focused ->
        if (focused) {
            enterExtendedAddressBarMode()

            val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager

            imm.showSoftInput(vb.etUrl, InputMethodManager.SHOW_IMPLICIT)
            postDelayed(//workaround an android TV bug
                {
                    vb.etUrl.selectAll()
                }, 500)
        }
    }

    private val etUrlKeyListener = OnKeyListener { view, i, keyEvent ->
        when (keyEvent.keyCode) {
            KeyEvent.KEYCODE_ENTER -> {
                if (keyEvent.action == KeyEvent.ACTION_UP) {
                    val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
                    imm.hideSoftInputFromWindow(vb.etUrl.windowToken, 0)
                    callback?.search(vb.etUrl.text.toString())
                    dismissExtendedAddressBarMode()
                    callback?.onUrlInputDone()
                }
                return@OnKeyListener true
            }
        }
        false
    }

    init {
        init()
    }

    fun init() {
        orientation = HORIZONTAL

        if (isInEditMode) return

        val incognitoMode = BrowserTV.config.incognitoMode

        vb.ibMenu.setOnClickListener { callback?.closeWindow() }
        vb.ibDownloads.setOnClickListener { callback?.showDownloads() }
        vb.ibFavorites.setOnClickListener { callback?.showFavorites() }
        vb.ibHistory.setOnClickListener { callback?.showHistory() }
        vb.ibIncognito.setOnClickListener { callback?.toggleIncognitoMode() }
        vb.ibSettings.setOnClickListener { callback?.showSettings() }

        if (Utils.isFireTV(context)) {
            vb.ibMenu.nextFocusRightId = R.id.ibHistory
            removeView(vb.ibVoiceSearch)
        } else {
            vb.ibVoiceSearch.setOnClickListener { callback?.initiateVoiceSearch() }
        }

        vb.ibIncognito.isChecked = incognitoMode

        vb.etUrl.onFocusChangeListener = etUrlFocusChangeListener

        vb.etUrl.setOnKeyListener(etUrlKeyListener)


        downloadsModel.activeDownloads.subscribe(context as AppCompatActivity) {
            if (it.isNotEmpty()) {
                if (downloadAnimation == null) {
                    downloadAnimation = AnimationUtils.loadAnimation(context, R.anim.infinite_fadeinout_anim)
                    vb.ibDownloads.startAnimation(downloadAnimation)
                }
            } else {
                downloadAnimation?.apply {
                    this.reset()
                    vb.ibDownloads.clearAnimation()
                    downloadAnimation = null
                }
            }
        }
    }

    fun setAddressBoxText(text: String) {
        if (text == HomePageHelper.HOME_PAGE_URL) {
            vb.etUrl.setText("")
        } else {
            vb.etUrl.setText(text)
        }
    }

    fun setAddressBoxTextColor(color: Int) {
        vb.etUrl.setTextColor(color)
    }

    private fun enterExtendedAddressBarMode() {
        if (extendedAddressBarMode) return
        extendedAddressBarMode = true
        for (i in 0 until childCount) {
            val child = getChildAt(i)
            if (child is ImageButton) {
                child.visibility = GONE
            }
        }
        TransitionManager.beginDelayedTransition(this)
        callback?.onExtendedAddressBarMode()
    }

    fun dismissExtendedAddressBarMode() {
        if (!extendedAddressBarMode) return
        extendedAddressBarMode = false
        for (i in 0 until childCount) {
            val child = getChildAt(i)
            if (child is ImageButton) {
                child.visibility = VISIBLE
            }
        }
    }

    fun catchFocus() {
        vb.ibMenu.requestFocus()
    }
}
