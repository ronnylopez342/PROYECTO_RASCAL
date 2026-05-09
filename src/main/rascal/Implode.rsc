module Implode

import Syntax;
import Parser;
import AST;

import ParseTree;
import Node;

/*
 * Convierte el arbol concreto producido por el parser
 * en el AST definido en AST.rsc.
 *
 * Como Syntax.rsc y AST.rsc tienen etiquetas alineadas,
 * Rascal puede hacer el implode automaticamente.
 *
 * En esta version final, Invocation se separa en:
 *
 * - unaryInvocation(str opName, Primary param)
 * - binaryInvocation(str opName, Primary param1, Primary param2)
 *
 * Esto permite que Checker.rsc valide aridad y tipos de argumentos
 * en reglas como:
 *
 * defrule (negation p) -> (negation z) end
 * defrule (suma x y) -> (suma y x) end
 */
public MainModule implodeMain(Tree pt) = implode(#MainModule, pt);

public MainModule load(loc l) = implodeMain(parseMainModule(l));