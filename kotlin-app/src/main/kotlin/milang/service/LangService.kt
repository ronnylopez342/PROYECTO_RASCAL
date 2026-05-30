package milang.service

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import milang.model.RunResult
import java.io.File
import java.util.concurrent.TimeUnit

/**
 * Servicio que invoca Rascal como subproceso y devuelve el resultado parseado.
 *
 * Para Proyecto 4, esta app Kotlin funciona como runtime/interfaz para VeriLang.
 *
 * Estructura esperada al integrar:
 *
 *   proyecto_rascal/
 *   ├── rascal-shell-stable.jar
 *   ├── src/main/rascal/
 *   │   ├── Parser.rsc
 *   │   ├── Checker.rsc
 *   │   ├── Generator.rsc
 *   │   └── RunnerJson.rsc
 *   ├── instance/
 *   │   └── archivos .vl
 *   └── kotlin-app/
 *       └── src/main/kotlin/milang/...
 *
 * Kotlin abre una consola Rascal, le escribe:
 *   import RunnerJson;
 *   RunnerJson::main(["archivo"]);
 *   quit;
 *
 * RunnerJson devuelve un único JSON por stdout.
 */
class LangService {

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    private val projectRoot: File by lazy {
        val cwd = File(System.getProperty("user.dir")).canonicalFile

        val parent = cwd.parentFile?.canonicalFile
        if (parent != null && parent.resolve("src/main/rascal/RunnerJson.rsc").exists()) {
            parent
        } else if (cwd.resolve("src/main/rascal/RunnerJson.rsc").exists()) {
            cwd
        } else {
            parent ?: cwd
        }
    }

    private val rascalJar: File
        get() = projectRoot.resolve("rascal-shell-stable.jar")

    suspend fun run(filePath: String): RunResult = withContext(Dispatchers.IO) {
        try {
            println("[LangService] Ejecutando VeriLang desde Kotlin...")
            println("[LangService] projectRoot : ${projectRoot.absolutePath}")
            println("[LangService] archivo     : $filePath")
            println("[LangService] jar         : ${rascalJar.absolutePath}")

            val t0 = System.currentTimeMillis()
            val output = executeRascalInteractive(filePath)

            println("[LangService] tiempo      : ${System.currentTimeMillis() - t0} ms")
            println("[LangService] stdout      : ${output.length} chars")

            val jsonStr = extractJson(output)
            if (jsonStr == null) {
                return@withContext RunResult(
                    error = "Rascal no produjo JSON válido:\n$output"
                )
            }

            json.decodeFromString<RunResult>(jsonStr)
        } catch (e: Exception) {
            e.printStackTrace()
            RunResult(error = e.message ?: "Error desconocido")
        }
    }

    private fun executeRascalInteractive(filePath: String): String {
        if (!rascalJar.exists()) {
            throw RuntimeException(
                "No se encontró rascal-shell-stable.jar en ${rascalJar.absolutePath}"
            )
        }

        val normalizedPath = filePath.replace("\\", "/")
        val escapedPath = normalizedPath
            .replace("\\", "\\\\")
            .replace("\"", "\\\"")

        val commands = buildString {
            appendLine("import RunnerJson;")
            appendLine("RunnerJson::main([\"$escapedPath\"]);")
            appendLine("quit;")
        }

        val process = ProcessBuilder(
            "java",
            "-Dfile.encoding=UTF-8",
            "-jar",
            rascalJar.absolutePath
        )
            .directory(projectRoot)
            .redirectErrorStream(false)
            .start()

        process.outputStream.bufferedWriter().use { writer ->
            writer.write(commands)
            writer.flush()
        }

        val stdoutExecutor = java.util.concurrent.Executors.newSingleThreadExecutor()
        val stderrExecutor = java.util.concurrent.Executors.newSingleThreadExecutor()

        val stdoutFuture = stdoutExecutor.submit<String> {
            process.inputStream.bufferedReader().readText()
        }

        val stderrFuture = stderrExecutor.submit<String> {
            process.errorStream.bufferedReader().readText()
        }

        val finished = process.waitFor(180, TimeUnit.SECONDS)

        if (!finished) {
            process.destroyForcibly()
            stdoutExecutor.shutdownNow()
            stderrExecutor.shutdownNow()
            throw RuntimeException("Rascal tardó más de 180 segundos y fue detenido")
        }

        val stdout = stdoutFuture.get()
        val stderr = stderrFuture.get()

        stdoutExecutor.shutdown()
        stderrExecutor.shutdown()

        println("--- STDERR (${stderr.length} chars) ---")
        if (stderr.isNotBlank()) {
            println(stderr)
        }

        println("--- exit code: ${process.exitValue()} ---")

        if (process.exitValue() != 0 && stdout.isBlank()) {
            throw RuntimeException("Error de Rascal (exit ${process.exitValue()}):\n$stderr")
        }

        return stdout
    }

    private fun extractJson(output: String): String? {
        val clean = output
            .replace(Regex("\\x1b\\[[^a-zA-Z]*[a-zA-Z]"), "")
            .replace(Regex("\\x1b[^\\[\\x1b]"), "")

        var start = 0

        while (start < clean.length) {
            val brace = clean.indexOf('{', start)
            if (brace == -1) break

            var depth = 0
            var inString = false
            var escaped = false
            var end = -1

            for (i in brace until clean.length) {
                val c = clean[i]

                if (escaped) {
                    escaped = false
                    continue
                }

                if (c == '\\' && inString) {
                    escaped = true
                    continue
                }

                if (c == '"') {
                    inString = !inString
                    continue
                }

                if (!inString) {
                    if (c == '{') {
                        depth++
                    } else if (c == '}') {
                        depth--
                        if (depth == 0) {
                            end = i
                            break
                        }
                    }
                }
            }

            if (end != -1) {
                val candidate = clean.substring(brace, end + 1)

                try {
                    val parsed = Json.parseToJsonElement(candidate)
                    if (parsed is JsonObject && parsed.containsKey("success")) {
                        return candidate
                    }
                } catch (_: Exception) {
                    // Se ignora y se sigue buscando otro bloque JSON.
                }
            }

            start = brace + 1
        }

        return null
    }
}