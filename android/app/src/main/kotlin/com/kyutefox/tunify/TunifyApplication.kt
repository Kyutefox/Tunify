package com.kyutefox.tunify

import android.app.Application
import androidx.work.WorkManager

class TunifyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Cancel stale WorkManager tasks left over from previous installs that
        // included the workmanager Flutter plugin as a transitive dependency.
        try {
            WorkManager.getInstance(this).cancelAllWork()
        } catch (_: Exception) {}
    }
}
