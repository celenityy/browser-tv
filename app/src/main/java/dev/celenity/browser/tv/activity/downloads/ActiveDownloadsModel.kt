package dev.celenity.browser.tv.activity.downloads

import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.os.ParcelFileDescriptor
import android.provider.MediaStore
import android.util.Log
import dev.celenity.browser.tv.BrowserTV
import dev.celenity.browser.tv.model.Download
import dev.celenity.browser.tv.service.downloads.DownloadTask
import dev.celenity.browser.tv.service.downloads.FileDownloadTask
import dev.celenity.browser.tv.singleton.AppDatabase
import dev.celenity.browser.tv.utils.observable.ObservableList
import dev.celenity.browser.tv.utils.activemodel.ActiveModel
import java.io.File

class ActiveDownloadsModel: ActiveModel() {
    val activeDownloads = ObservableList<DownloadTask>()
    private val listeners = java.util.ArrayList<Listener>()

    interface Listener {
        fun onDownloadUpdated(downloadInfo: Download)
        fun onDownloadError(downloadInfo: Download, responseCode: Int, responseMessage: String)
        fun onAllDownloadsComplete()
    }

    suspend fun deleteItem(download: Download) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val contentResolver = BrowserTV.instance.contentResolver
            val rowsDeleted = contentResolver.delete(Uri.parse(download.filepath), null)
            if (rowsDeleted < 1) {
                Log.e(FileDownloadTask.TAG, "Failed to delete file from MediaStore")
            }
        } else {
            File(download.filepath).delete()
        }
        AppDatabase.db.downloadDao().delete(download)
    }

    fun registerListener(listener: Listener) {
        listeners.add(listener)
    }

    fun unregisterListener(listener: Listener) {
        listeners.remove(listener)
    }

    fun cancelDownload(download: Download) {
        for (i in activeDownloads.indices) {
            val task = activeDownloads[i]
            if (task.downloadInfo.id == download.id) {
                task.downloadInfo.cancelled = true
                break
            }
        }
    }

    fun notifyListenersAboutError(task: DownloadTask, responseCode: Int, responseMessage: String) {
        for (i in listeners.indices) {
            listeners[i].onDownloadError(task.downloadInfo, responseCode, responseMessage)
        }
    }

    fun notifyListenersAboutDownloadProgress(task: DownloadTask) {
        for (i in listeners.indices) {
            listeners[i].onDownloadUpdated(task.downloadInfo)
        }
    }

    fun onDownloadEnded(task: DownloadTask) {
        activeDownloads.remove(task)
        if (activeDownloads.isEmpty()) {
            for (i in listeners.indices) {
                listeners[i].onAllDownloadsComplete()
            }
        }
    }
}
