package com.fzmanager.fz_manager

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
                "deleteApiKey" -> { getPreferences(MODE_PRIVATE).edit().remove("api_key").apply(); result.success(true) }
                "checkManageStorage" -> result.success(isAllFilesAccess())
                "rootAvailable" -> result.success(isRootAvailable())
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

    private fun isRootAvailable(): Boolean =
        runCatching {
            val p = ProcessBuilder("su", "-c", "id").start()
            val out = p.inputStream.bufferedReader().readText()
            p.waitFor(3, java.util.concurrent.TimeUnit.SECONDS)
            out.contains("uid=0")
        }.getOrDefault(false)

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

    @Suppress("unused")
    private fun readEncrypted(): String? {
        val payload = getPreferences(MODE_PRIVATE).getString("api_key", null) ?: return null
        val bytes = Base64.decode(payload, Base64.NO_WRAP)
        val iv = bytes.copyOfRange(0, 12)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, secretKey(), GCMParameterSpec(128, iv))
        return String(cipher.doFinal(bytes.copyOfRange(12, bytes.size)), Charsets.UTF_8)
    }
}
