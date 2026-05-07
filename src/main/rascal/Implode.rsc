module Implode

import Syntax;
import Parser;
import AST;

import ParseTree;
import Node;

public MainModule implodeMain(Tree pt) = implode(#MainModule, pt);
public MainModule load(loc l) = implodeMain(parseMainModule(l));
