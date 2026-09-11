package com.fzmanager.fz_manager

import android.content.Intent
import android.net.Uri
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** Android host for FZ Manager. API credentials never cross into source files. */
class FzActivity : FlutterActivity() {
    private val channelName = "fz_manager/secure"
    private val alias = "fz_manager_api_key"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveApiKey" -> {
                    val value = call.argument<String>("value")
                    if (value.isNullOrBlank()) result.error("EMPTY_KEY", "API key is empty", null)
                    else try { saveEncrypted(value); result.success(true) }
                    catch (error: Exception) { result.error("KEYSTORE", error.message, null) }
                }
                "hasApiKey" -> result.success(getPreferences(MODE_PRIVATE).contains("api_key"))
                "getApiKey" -> {
                    try {
                        val value = readEncrypted()
                        if (value.isNullOrEmpty()) result.success(null)
                        else result.success(value)
                    } catch (error: Exception) { result.error("KEYSTORE", error.message, null) }
                }
                "deleteApiKey" -> { getPreferences(MODE_PRIVATE).edit().remove("api_key").apply(); result.success(true) }
                "checkManageStorage" -> result.success(isAllFilesAccess())
                "openManageStorageSettings" -> {
                    try {
                        val intent = Intent(
                            android.provider.Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            startActivity(Intent(android.provider.Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION))
                            result.success(true)
                        } catch (e2: Exception) { result.error("SETTINGS", e2.message, null) }
                    }
                }
                "startMusicEffect" -> { startMusicWatcher(); result.success(true) }
                "stopMusicEffect" -> { stopMusicWatcher(); result.success(true) }
                "rootAvailable" -> {
                    // Runs off the main thread: su can block for seconds.
                    Thread {
                        val ok = isRootAvailable()
                        android.os.Handler(android.os.Looper.getMainLooper()).post { result.success(ok) }
                    }.start()
                }
                "rootProbe" -> {
                    Thread {
                        val probe = buildRootProbe()
                        android.os.Handler(android.os.Looper.getMainLooper()).post { result.success(probe) }
                    }.start()
                }
                "rootExec" -> {
                    val cmd = call.argument<String>("command") ?: ""
                    if (cmd.isBlank()) { result.error("EMPTY", "Empty command", null); return@setMethodCallHandler }
                    result.success(runRoot(cmd))
                }
                "readFile" -> {
                    val path = call.argument<String>("path") ?: ""
                    try { result.success(String(java.io.File(path).readBytes(), Charsets.UTF_8)) }
                    catch (e: Exception) { result.error("READ", e.message, null) }
                }
                "writeFile" -> {
                    val path = call.argument<String>("path") ?: ""
                    val content = call.argument<String>("content") ?: ""
                    try { java.io.File(path).writeText(content); result.success(true) }
                    catch (e: Exception) { result.error("WRITE", e.message, null) }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isAllFilesAccess(): Boolean =
        android.os.Environment.isExternalStorageManager()

    private fun isRootAvailable(): Boolean {
        val idOut = execCapture("su -c 'id'", 3)
        if (idOut.contains("uid=0")) return true
        val whoamiOut = execCapture("su -c 'whoami'", 3)
        return whoamiOut.trim() == "root"
    }

    /**
     * Deep root probe for the Root/Kernel sections:
     *  - su presence and elevation check (uid=0)
     *  - Magisk / KernelSU / APatch / SuperSU / KSU detection
     *  - SELinux status, kernel version, manager app info
     *  - write-capability test on /data/local/tmp
     */
    private fun buildRootProbe(): Map<String, Any> {
        val info = LinkedHashMap<String, Any>()

        val suPaths = listOf(
            "/system/bin/su", "/system/xbin/su", "/sbin/su",
            "/su/bin/su", "/data/adb/magisk/magisk", "/data/adb/ksu/bin/su",
            "/data/adb/ap/bin/su", "/data/adb/magisk", "/data/adb",
        )
        val foundBinaries = suPaths.filter { java.io.File(it).exists() || java.io.File(it).canExecute() }
        info["suBinaries"] = foundBinaries

        val idOut = execCapture("su -c 'id 2>/dev/null || echo NO_SU'", 4)
        val rootGranted = idOut.contains("uid=0")
        info["rootGranted"] = rootGranted
        info["idOutput"] = idOut.trim()

        // Managers
        val kver = execCapture("uname -r 2>/dev/null", 3).trim()
        val hasKsu = kver.contains("ksu", true) || kver.contains("K9", true) ||
            execCapture("grep -qi ksu /proc/version 2>/dev/null && echo KSU || true", 3).contains("KSU") ||
            java.io.File("/data/adb/ksu").exists()
        val hasApatch = java.io.File("/data/adb/ap").exists() ||
            kver.contains("apatch", true)
        val magiskOut = execCapture("magisk -v 2>/dev/null || echo NOMAGISK", 4)
        val hasMagisk = !magiskOut.contains("NOMAGISK") && magiskOut.isNotBlank() && rootGranted
        val superSU = execCapture("su -c 'ls /system/xbin/daemonsu 2>/dev/null'", 3).contains("daemonsu") ||
            packageExists("eu.chainfire.supersu")
        val magiskApp = packageExists("com.topjohnwu.magisk")
        val ksudOut = execCapture("ls /data/adb/ksud 2>/dev/null || true", 3)

        info["manager"] = when {
            hasApatch -> "APatch"
            hasKsu -> "KernelSU"
            hasMagisk -> "Magisk"
            superSU -> "SuperSU"
            rootGranted -> "Unknown (root granted)"
            else -> "None"
        }
        info["hasMagisk"] = hasMagisk
        info["hasKernelSU"] = hasKsu
        info["hasAPatch"] = hasApatch
        info["hasSuperSU"] = superSU
        info["magiskVersion"] = magiskOut.replace("NOMAGISK", "").trim()
        info["ksud"] = ksudOut.isNotBlank()

        info["kernel"] = kver
        info["androidVersion"] = android.os.Build.VERSION.RELEASE
        info["sdkInt"] = android.os.Build.VERSION.SDK_INT
        info["device"] = "${android.os.Build.MANUFACTURER} ${android.os.Build.MODEL}"
        info["selinux"] = execCapture("getenforce 2>/dev/null", 3).trim()

        // Package manager checks for root-management apps
        val managers = mapOf(
            "com.topjohnwu.magisk" to "Magisk",
            "me.weishu.kernelsu" to "KernelSU",
            "io.github.vvb2060.magisk" to "Magisk Delta",
            "eu.chainfire.supersu" to "SuperSU",
            "me.garfieldhan.apatch" to "APatch",
        ).filter { packageExists(it.key) }
        info["managerApps"] = managers.values.toList()

        // Write capability test (only when root granted)
        if (rootGranted) {
            val testFile = "/data/local/tmp/fz_root_test_${System.currentTimeMillis()}"
            val wrote = execCapture("su -c 'echo FZ > $testFile 2>/dev/null && cat $testFile 2>/dev/null'", 4)
            execCapture("su -c 'rm -f $testFile 2>/dev/null'", 3)
            info["canWrite"] = wrote.contains("FZ")
            info["canRemount"] = !execCapture("su -c 'mount -o remount,rw / 2>&1' 2>&1 || true", 4).contains("Read-only")
        } else {
            info["canWrite"] = false
            info["canRemount"] = false
        }

        info["checkedAt"] = System.currentTimeMillis()
        return info
    }

    private fun execCapture(command: String, timeoutSec: Int): String = try {
        val p = ProcessBuilder("/system/bin/sh", "-c", command)
            .redirectErrorStream(true)
            .start()
        val out = p.inputStream.bufferedReader().readText()
        p.waitFor(timeoutSec.toLong(), java.util.concurrent.TimeUnit.SECONDS)
        out
    } catch (e: Exception) {
        ""
    }

    private fun packageExists(pkg: String): Boolean = try {
        packageManager.getPackageInfo(pkg, 0)
        true
    } catch (e: Exception) {
        false
    }

    private fun runRoot(command: String): Map<String, Any> {
        return try {
            val p = ProcessBuilder("su", "-c", command).start()
            val out = p.inputStream.bufferedReader().readText()
            val err = p.errorStream.bufferedReader().readText()
            val done = p.waitFor(5, java.util.concurrent.TimeUnit.SECONDS)
            mapOf(
                "ok" to done,
                "stdout" to out,
                "stderr" to err,
            )
        } catch (e: Exception) {
            mapOf("ok" to false, "stdout" to "", "stderr" to (e.message ?: "error"))
        }
    }

    private fun secretKey(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(alias, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .build())
        return generator.generateKey()
    }

    private fun saveEncrypted(value: String) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, secretKey())
        val encrypted = cipher.doFinal(value.toByteArray(Charsets.UTF_8))
        val payload = Base64.encodeToString(cipher.iv + encrypted, Base64.NO_WRAP)
        getPreferences(MODE_PRIVATE).edit().putString("api_key", payload).apply()
    }

    private fun readEncrypted(): String? {
        val payload = getPreferences(MODE_PRIVATE).getString("api_key", null) ?: return null
        val bytes = Base64.decode(payload, Base64.NO_WRAP)
        val iv = bytes.copyOfRange(0, 12)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, secretKey(), GCMParameterSpec(128, iv))
        return String(cipher.doFinal(bytes.copyOfRange(12, bytes.size)), Charsets.UTF_8)
    }

    // --- Live music effect ---------------------------------------------------
    // When enabled, a lightweight watcher polls AudioManager.isMusicActive and
    // surfaces a live, animated "now playing" notification (dynamic-island /
    // live-notification style) without any audio playback by the app itself.
    private var musicWatcher: Runnable? = null
    private val musicHandler by lazy { android.os.Handler(android.os.Looper.getMainLooper()) }

    private fun startMusicWatcher() {
        stopMusicWatcher()
        val r = object : Runnable {
            override fun run() {
                updateMusicNotification()
                musicHandler.postDelayed(this, 2000)
            }
        }
        musicWatcher = r
        musicHandler.post(r)
    }

    private fun stopMusicWatcher() {
        musicWatcher?.let { musicHandler.removeCallbacks(it) }
        musicWatcher = null
        val nm = getSystemService(NOTIFICATION_SERVICE) as android.app.NotificationManager
        nm.cancel(NOTIF_ID)
    }

    private fun updateMusicNotification() {
        val am = getSystemService(AUDIO_SERVICE) as android.media.AudioManager
        val playing = am.isMusicActive
        val nm = getSystemService(NOTIFICATION_SERVICE) as android.app.NotificationManager
        if (!playing) {
            nm.cancel(NOTIF_ID)
            return
        }
        val channelId = "fz_music"
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            val ch = android.app.NotificationChannel(
                channelId, "FZ Manager music effect",
                android.app.NotificationManager.IMPORTANCE_LOW
            ).apply {
                setShowBadge(false)
                if (android.os.Build.VERSION.SDK_INT >= 29) {
                    vibrationPattern = longArrayOf(0, 180, 140, 180)
                }
            }
            nm.createNotificationChannel(ch)
        }
        val builder = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            android.app.Notification.Builder(this, channelId)
        } else {
            @Suppress("DEPRECATION") android.app.Notification.Builder(this)
        }
        val style = android.app.Notification.MediaStyle()
            .setShowActionsInCompactView(0, 1, 2)
        val note = builder
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle("♪ FZ Manager")
            .setContentText("Музыка играет — островок активен")
            .setStyle(style)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(android.app.Notification.CATEGORY_CALL)
            .setVisibility(android.app.Notification.VISIBILITY_PUBLIC)
            .build()
        try {
            nm.notify(NOTIF_ID, note)
        } catch (e: Exception) { /* ignore */ }
    }

    companion object {
        private const val NOTIF_ID = 7731
    }
}
