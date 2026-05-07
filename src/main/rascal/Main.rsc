module Main

import IO;
import ParseTree;
import Parser;
import Generator;

int main(loc archivo) {
    Tree cst = parseMainModule(archivo);
    str result = generator(cst);

    println(result);

    writeFile(
        |project://rascaldslverilang/instance/output/testGenerator.vl|,
        result
    );

    return 0;
}