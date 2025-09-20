package dev.celenity.browser.tv

import android.app.Activity
import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.appcompat.app.AppCompatDelegate
import dev.celenity.browser.tv.activity.main.MainActivity
import dev.celenity.browser.tv.utils.activemodel.ActiveModelsRepository
import java.net.CookieHandler
import java.net.CookieManager
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit
import kotlin.system.exitProcess

/**
 * Created by PDT on 09.09.2016.
 */
class BrowserTV : Application(), Application.ActivityLifecycleCallbacks {
    companion object {
        lateinit var instance: BrowserTV
        const val CHANNEL_ID_DOWNLOADS: String = "downloads"
        const val MAIN_PREFS_NAME = "main.xml"
        val TAG = BrowserTV::class.simpleName

        val config: Config get() = instance._config
    }

    lateinit var threadPool: ThreadPoolExecutor
        private set

    private lateinit var _config: Config
    var needToExitProcessAfterMainActivityFinish = false
    var needRestartMainActivityAfterExitingProcess = false
    override fun onCreate() {
        Log.i(TAG, "onCreate")
        super.onCreate()

        instance = this

        _config = Config(getSharedPreferences(MAIN_PREFS_NAME, MODE_MULTI_PROCESS))

        val maxThreadsInOfflineJobsPool = Runtime.getRuntime().availableProcessors()
        threadPool = ThreadPoolExecutor(0, maxThreadsInOfflineJobsPool, 20,
                TimeUnit.SECONDS, ArrayBlockingQueue(maxThreadsInOfflineJobsPool))

        initWebEngineStuff()

        initNotificationChannels()

        ActiveModelsRepository.init(this)

        when (_config.theme.value) {
            Config.Theme.BLACK -> AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_YES)
            Config.Theme.WHITE -> AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_NO)
            else -> AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM)
        }

        registerActivityLifecycleCallbacks(this)
    }

    @Suppress("KotlinConstantConditions")
    private fun initWebEngineStuff() {
        Log.i(TAG, "initWebEngineStuff")
        val cookieManager = CookieManager()
        CookieHandler.setDefault(cookieManager)
    }

    private fun initNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = getString(R.string.downloads)
            val descriptionText = getString(R.string.downloads_notifications_description)
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(CHANNEL_ID_DOWNLOADS, name, importance)
            channel.description = descriptionText
            val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
    override fun onActivityStarted(activity: Activity) {}
    override fun onActivityResumed(activity: Activity) {}
    override fun onActivityPaused(activity: Activity) {}
    override fun onActivityStopped(activity: Activity) {}
    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}

    override fun onActivityDestroyed(activity: Activity) {
        Log.i(TAG, "onActivityDestroyed: " + activity.javaClass.simpleName)
        if (needToExitProcessAfterMainActivityFinish && activity is MainActivity) {
            Log.i(TAG, "onActivityDestroyed: exiting process")
            if (needRestartMainActivityAfterExitingProcess) {
                Log.i(TAG, "onActivityDestroyed: restarting main activity")
                val intent = Intent(this@BrowserTV, MainActivity::class.java)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                startActivity(intent)
            }
            exitProcess(0)
        }
    }
}
