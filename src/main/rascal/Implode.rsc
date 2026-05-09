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
 * Como Syntax.rsc y AST.rsc ya tienen las mismas etiquetas
 * principales, Rascal puede hacer el implode automaticamente.
 *
 * Cambio relacionado con Proyecto 3:
 * Invocation ahora usa list[Primary] en AST.rsc.
 * No se necesita una funcion manual aqui porque el implode
 * puede convertir Primary+ params hacia list[Primary] params.
 */
public MainModule implodeMain(Tree pt) = implode(#MainModule, pt);

public MainModule load(loc l) = implodeMain(parseMainModule(l));