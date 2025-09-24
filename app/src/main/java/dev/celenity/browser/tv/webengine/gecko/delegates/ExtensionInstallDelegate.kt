package dev.celenity.browser.tv.webengine.gecko.delegates

import android.app.Activity
import android.app.AlertDialog
import android.content.Context
import android.content.DialogInterface
import android.content.Intent
import android.graphics.Color
import android.graphics.PorterDuff
import android.net.Uri
import android.os.Build
import android.text.InputType
import android.text.format.DateFormat
import android.util.Log
import android.view.InflateException
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.AbsListView
import android.widget.AdapterView.OnItemClickListener
import android.widget.ArrayAdapter
import android.widget.CheckedTextView
import android.widget.DatePicker
import android.widget.EditText
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.ScrollView
import android.widget.Spinner
import android.widget.TextView
import android.widget.TimePicker
import dev.celenity.browser.tv.R
import dev.celenity.browser.tv.webengine.gecko.GeckoWebEngine
import kotlinx.coroutines.runBlocking
import org.mozilla.geckoview.AllowOrDeny
import org.mozilla.geckoview.GeckoResult
import org.mozilla.geckoview.WebExtension
import org.mozilla.geckoview.WebExtensionController
import java.text.ParseException
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

class ExtensionInstallDelegate: WebExtensionController.PromptDelegate {

    override fun onInstallPromptRequest(
        extension: WebExtension,
        permissions: Array<out String>,
        origins: Array<out String>,
        dataCollectionPermissions: Array<out String>,
    ): GeckoResult<WebExtension.PermissionPromptResponse>? {
        return GeckoResult.fromValue(
            WebExtension.PermissionPromptResponse(
                true, // isPermissionsGranted
                true, // isPrivateModeGranted
                false // Data collection (isTechnicalAndInteractionDataGranted)
            )
        )
    }

    override fun onOptionalPrompt(
        extension: WebExtension,
        permissions: Array<out String>,
        origins: Array<out String>,
        dataCollectionPermissions: Array<out String>,
    ): GeckoResult<AllowOrDeny> {
        return GeckoResult.allow()
    }

    override fun onUpdatePrompt(
        extension: WebExtension,
        newPermissions: Array<out String>,
        newOrigins: Array<out String>,
        newDataCollectionPermissions: Array<out String>,
    ): GeckoResult<AllowOrDeny> {
        return GeckoResult.allow()
    }
}
