package com.kyutefox.tunify

import android.app.Application
import android.os.Build
import android.util.Log
import androidx.work.WorkManager
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.atomic.AtomicReference

class TunifyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Cancel stale WorkManager tasks left over from previous installs that
        // included the workmanager Flutter plugin as a transitive dependency.
        try {
            WorkManager.getInstance(this).cancelAllWork()
        } catch (_: Exception) {}

        Thread { maybeStartBundledBackend() }.start()
    }

    private fun maybeStartBundledBackend() {
        val exe = resolveBundledBackendExecutable()
        if (!exe.exists()) {
            Log.i(
                TAG,
                "Bundled backend: libtunify_backend_exec.so not packaged (skip). " +
                    "nativeLibraryDir=${applicationInfo.nativeLibraryDir} sourceDir=${applicationInfo.sourceDir}",
            )
            return
        }
        synchronized(TunifyApplication::class.java) {
            if (isHealthy()) {
                Log.i(TAG, "Bundled backend: already healthy")
                return
            }
            val existing = backendProcess.get()
            if (existing != null) {
                try {
                    existing.exitValue()
                    backendProcess.compareAndSet(existing, null)
                } catch (_: IllegalThreadStateException) {
                    // Child still running from this VM; do not spawn a second copy.
                    Log.i(TAG, "Bundled backend: child process still running")
                    return
                }
            }
            try {
                val pb = ProcessBuilder(exe.absolutePath)
                val dbFile = File(filesDir, BUNDLED_DB_FILENAME)
                pb.environment()["APP_RUNTIME_KIND"] = "bundled"
                pb.environment()["APP_HOST"] = BUNDLED_HOST
                pb.environment()["APP_PORT"] = BUNDLED_PORT.toString()
                pb.environment()["APP_HOME_PROVIDER"] = BUNDLED_HOME_PROVIDER
                pb.environment()["DATABASE_URL"] = "sqlite:${dbFile.absolutePath}"
                pb.directory(filesDir)
                pb.redirectErrorStream(true)
                val logFile = File(cacheDir, "tunify_rust_backend.log")
                pb.redirectOutput(ProcessBuilder.Redirect.appendTo(logFile))
                val p = pb.start()
                backendProcess.set(p)
                Log.i(TAG, "Bundled backend: started from ${exe.absolutePath}")
            } catch (e: Exception) {
                Log.e(TAG, "Bundled backend: ProcessBuilder failed", e)
            }
        }
    }

    private fun resolveBundledBackendExecutable(): File {
        val exeName = "libtunify_backend_exec.so"
        val nativeDir = applicationInfo.nativeLibraryDir?.let(::File)
        if (nativeDir != null) {
            val candidate = File(nativeDir, exeName)
            if (candidate.exists()) return candidate
        }
        val sourceParent = File(applicationInfo.sourceDir).parentFile
        val abi = Build.SUPPORTED_ABIS.firstOrNull().orEmpty()
        val fallbacks =
            listOfNotNull(
                sourceParent?.let { File(it, "lib/arm64/$exeName") },
                sourceParent?.let { File(it, "lib/$abi/$exeName") },
            )
        for (candidate in fallbacks) {
            if (candidate.exists()) return candidate
        }
        return nativeDir?.let { File(it, exeName) } ?: File(exeName)
    }

    private fun isHealthy(): Boolean =
        try {
            val c = URL("http://$BUNDLED_HOST:$BUNDLED_PORT/health").openConnection() as HttpURLConnection
            c.connectTimeout = 250
            c.readTimeout = 250
            c.responseCode == 200
        } catch (_: Exception) {
            false
        }

    companion object {
        private const val TAG = "TunifyBackend"
        private const val BUNDLED_HOST = "127.0.0.1"
        private const val BUNDLED_PORT = 8080
        private const val BUNDLED_HOME_PROVIDER = "youtube"
        private const val BUNDLED_DB_FILENAME = "tunify.db"
        private val backendProcess = AtomicReference<Process?>()
    }
}
