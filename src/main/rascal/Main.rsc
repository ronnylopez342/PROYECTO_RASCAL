module Main

import IO;
import ParseTree;

import Parser;
import Generator;
import Checker;

import analysis::typepal::TypePal;

/*
 * Main por defecto.
 * Ejecuta el ejemplo principal actualizado del proyecto.
 *
 * Se usa cwd:/// para evitar rutas absolutas del computador local
 * y evitar problemas del esquema project:// en la terminal de VS Code.
 *
 * Para que funcione, se debe abrir/ejecutar Rascal desde la raiz del proyecto,
 * donde existe la carpeta instance/.
 */
int main() {
    return main(|cwd:///instance/spec_types.vl|);
}

/*
 * Main con archivo.
 *
 * Flujo completo:
 * 1. Parsear el archivo .vl
 * 2. Ejecutar el checker con TypePal
 * 3. Si hay errores reales, mostrarlos y detener
 * 4. Si no hay errores, generar codigo VeriLang
 * 5. Mostrar el resultado en consola
 *
 * Nota:
 * El enunciado pide mostrar el resultado en consola.
 * Por eso Main.rsc no depende de escribir archivos de salida.
 * Los archivos generados de evidencia se mantienen en instance/output/.
 */
int main(loc archivo) {
    println("========================================");
    println("Ejecucion de programa VeriLang");
    println("========================================");

    println("Archivo de entrada:");
    println(archivo);

    println("\n1. Parseando archivo...");
    Tree cst = parseMainModule(archivo);
    println("Parser ejecutado correctamente.");

    println("\n2. Ejecutando checker con TypePal...");
    TModel tm = modulesTModelFromTree(cst);

    list[Message] errors = [
        m
        | m <- getMessages(tm),
          m is error
    ];

    if (errors != []) {
        println("\nEl programa contiene errores semanticos:");

        for (m <- errors) {
            println(m);
        }

        println("\nNo se genera codigo porque el programa no paso el chequeo semantico.");
        println("========================================");

        return 1;
    }

    println("Checker ejecutado correctamente.");
    println("No se encontraron errores semanticos.");

    println("\n3. Generando codigo VeriLang...");
    str result = generator(cst);

    println("\nResultado generado:");
    println("----------------------------------------");
    println(result);
    println("----------------------------------------");

    println("\nEjecucion finalizada correctamente.");
    println("========================================");

    return 0;
}