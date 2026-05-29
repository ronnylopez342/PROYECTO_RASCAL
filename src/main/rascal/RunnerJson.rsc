module RunnerJson

import Parser;
import Checker;
import Generator;

import ParseTree;
import Message;
import IO;
import List;
import String;

import analysis::typepal::TypePal;

/*
 * RunnerJson.rsc
 *
 * Este modulo es el puente entre la aplicacion Kotlin y VeriLang.
 *
 * Kotlin ejecutara este modulo, le pasara la ruta de un archivo .vl,
 * y este modulo devolvera exactamente un objeto JSON por stdout.
 *
 * Flujo:
 * 1. Leer archivo .vl
 * 2. Parsear con parseMainModule
 * 3. Chequear con TypePal usando modulesTModelFromTree
 * 4. Si hay errores, devolver JSON con success=false
 * 5. Si no hay errores, generar codigo VeriLang con generator
 * 6. Devolver JSON con success=true
 */

str esc(str s) =
    replaceAll(
        replaceAll(
            replaceAll(
                replaceAll(
                    replaceAll(s, "\\", "\\\\"),
                    "\"", "\\\""
                ),
                "\r", "\\r"
            ),
            "\n", "\\n"
        ),
        "\t", "\\t"
    );

str jsonArr(list[str] items) =
    "[<intercalate(", ", ["\"<esc(i)>\"" | i <- items])>]";

str jsonResult(
    bool success,
    str modName,
    bool parseOk,
    bool tcOk,
    bool semOk,
    list[str] tcErrs,
    list[str] semErrs,
    list[str] output,
    str err,
    str codigoFormateado,
    str resumen
) =
    "{\"success\":<success>,"
    + "\"module\":\"<esc(modName)>\","
    + "\"parseOk\":<parseOk>,"
    + "\"typeCheckOk\":<tcOk>,"
    + "\"semanticOk\":<semOk>,"
    + "\"typeErrors\":<jsonArr(tcErrs)>,"
    + "\"semanticErrors\":<jsonArr(semErrs)>,"
    + "\"output\":<jsonArr(output)>,"
    + "\"error\":\"<esc(err)>\","
    + "\"codigoFormateado\":\"<esc(codigoFormateado)>\","
    + "\"resumen\":\"<esc(resumen)>\"}";

/*
 * Convierte una ruta recibida desde Kotlin en un loc usable por Rascal.
 *
 * Kotlin normalmente enviara una ruta absoluta de Windows, por ejemplo:
 * C:\Users\Roni\archivo.vl
 *
 * Se normalizan los backslashes a slashes para construir:
 * file:///C:/Users/Roni/archivo.vl
 *
 * Si llega una ruta relativa, se interpreta desde cwd:///.
 */
loc pathToLoc(str rawPath) {
    str p = replaceAll(rawPath, "\\", "/");

    if (startsWith(p, "file:///")) {
        return |file:///| + substring(p, 8);
    }

    if (startsWith(p, "cwd:///")) {
        return |cwd:///| + substring(p, 7);
    }

    if (size(p) >= 2 && substring(p, 1, 2) == ":") {
        return |file:///| + p;
    }

    if (startsWith(p, "/")) {
        return |file:///| + p;
    }

    return |cwd:///| + p;
}

str moduleNameFromTree(Tree cst) {
    str txt = "<cst>";

    /*
     * No dependemos del AST para extraer el nombre, porque para la app
     * basta con reportar un nombre descriptivo. El codigo generado ya
     * contiene el modulo real.
     */
    return "VeriLang";
}

void main(list[str] args) {
    loc file;

    try {
        file = isEmpty(args)
            ? |cwd:///instance/spec_types.vl|
            : pathToLoc(args[0]);
    } catch e: {
        println(jsonResult(
            false,
            "VeriLang",
            false,
            false,
            false,
            [],
            [],
            [],
            "No se pudo interpretar la ruta del archivo: <e>",
            "",
            ""
        ));
        return;
    }

    Tree cst;

    try {
        cst = parseMainModule(file);
    } catch ParseError(loc at): {
        println(jsonResult(
            false,
            "VeriLang",
            false,
            false,
            false,
            [],
            [],
            [],
            "Error de parsing en <at>",
            "",
            ""
        ));
        return;
    } catch e: {
        println(jsonResult(
            false,
            "VeriLang",
            false,
            false,
            false,
            [],
            [],
            [],
            "Error de parsing: <e>",
            "",
            ""
        ));
        return;
    }

    TModel tm;

    try {
        tm = modulesTModelFromTree(cst);
    } catch e: {
        println(jsonResult(
            false,
            "VeriLang",
            true,
            false,
            false,
            [],
            [],
            [],
            "Error ejecutando TypePal: <e>",
            "",
            ""
        ));
        return;
    }

    list[Message] errors = [
        m
        | m <- getMessages(tm),
          m is error
    ];

    list[str] errorTexts = ["<m>" | m <- errors];

    if (errors != []) {
        println(jsonResult(
            false,
            "VeriLang",
            true,
            false,
            false,
            errorTexts,
            errorTexts,
            [],
            "",
            "",
            "El programa VeriLang contiene errores semanticos."
        ));
        return;
    }

    str generated;

    try {
        generated = generator(cst);
    } catch e: {
        println(jsonResult(
            false,
            "VeriLang",
            true,
            true,
            true,
            [],
            [],
            [],
            "Error generando codigo VeriLang: <e>",
            "",
            ""
        ));
        return;
    }

    println(jsonResult(
        true,
        "VeriLang",
        true,
        true,
        true,
        [],
        [],
        [generated],
        "",
        generated,
        "Programa VeriLang parseado, chequeado y generado correctamente."
    ));
}