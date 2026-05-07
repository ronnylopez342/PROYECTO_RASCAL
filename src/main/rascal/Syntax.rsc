module Syntax

layout Layout = [\ \t\n\r]* !>> [\ \t\n\r];

start syntax MainModule
    = mainModule: 'defmodule' ID moduleName 
    FileImport* fileImports
    Body body
    'end'
;

syntax FileImport
    = fileImport: 'using' ID importName
;

// Falta añadir Equation y Relation que no se agregan al no tener reglas de producción definidas
syntax Body
    = body: Statement* statements
;

syntax Statement
    = defspace: Space space
    | defoperator: Operator operator
    | defvariable: Variables variables
    | defrule: Rule rule
    | defexpression: Expression expression
    | defattribute: AttributeList attributeList
;

syntax Space
    = space: 'defspace' ID spaceName 'end'
    | subspace: 'defspace' ID subSpace '\<' ID superSpace 'end'
;

syntax Operator
    = operator: 'defoperator' ID operatorName ':' Domain domain ('-\>' Domain)+ range 'end'
;

syntax Domain
    = boolDomain: 'bool'
    | intDomain: 'int'
    | realDomain: 'real'
    | stringDomain: 'string'
    | charDomain: 'char'
    | nameDomain: ID domainName
;

syntax AttributeList
    = attributeList: '[' Attribute+ attributes ']'
;

syntax Attribute
    = withDomain: ID operatorName ':' Domain domain
    | noDomain: ID operatorName
;

syntax Variables
    = variables: 'defvar' VarDecl+ variableList 'end'
;

syntax VarDecl
    = varDecl: ID varName ':' Domain domain
;

syntax Rule
    = rule: 'defrule' Invocation opApl1 '-\>' Invocation opApl2 'end'
;

syntax Invocation
    = invocation: '(' ID opName ID+ params ')'
;

syntax Expression
    = expression: 'defexpression' TopExp topExp 'end'
;

/*
 * Corrección del feedback del monitor:
 * El cuantificador ya no puede terminar solo con AttributeList.
 * Ahora siempre debe tener cuerpo después del punto:
 * (forall x in Set . expresion)
 */
syntax TopExp
    = quantExp: '(' Quantifier quantifier ID obj1 'in' ID obj2 '.' TopExp topExp ')'
    | orExpRec: OrExp orExp
;

syntax OrExp
    = orExp: OrExp left 'or' AndExp right 
    | andTerm: AndExp andExp
;

syntax AndExp
    = andExp: AndExp left 'and' NotExp right 
    | notTerm: NotExp notExp
;

syntax NotExp
    = negated: 'not' RelExp exp
    | plain: RelExp exp
;

syntax RelExp
    = withRelOp: Primary obj1 RelOp relOp Primary obj2 
    | customInfix: Primary obj1 ID customOp Primary obj2
    | onlyPrimary: Primary primary
;

syntax Primary
    = primaryId: ID id
    | primaryNum: Number number
    | primaryBool: BoolLiteral boolVal
    | primaryString: STRING strVal
    | primaryChar: CHAR charVal
    | grouped: '(' TopExp topExp ')'
;

syntax Number
    = intNumber: INT valInt
    | floatNumber: FLOAT valFloat
;

syntax RelOp
    = eq: '=' 
    | gt: '\>'
    | lt: '\<'
    | ge: '\>=' 
    | le: '\<=' 
    | equiv: '≡' 
    | iff: '\<\>' 
;

syntax Quantifier
    = forall: 'forall' 
    | exists: 'exists' 
    | defer: 'defer'
;

// No utilizado todavía, pero pertenece al lenguaje
syntax ArithOp
    = '+' | '-' | '*' | '/' | '**' | '%' 
;

syntax BoolLiteral
    = trueLiteral: 'true'
    | falseLiteral: 'false'
;

lexical STRING = "\"" ![\"\n]* "\"";
lexical CHAR = "\'" [^\'\n] "\'";

lexical INT = [0-9]+ !>> [0-9];
lexical FLOAT = [0-9]+ "." [0-9]+ !>> [0-9];

lexical ID = ([a-zA-Z][a-zA-Z0-9_/.\-]* !>> [a-zA-Z0-9_/.\-]) \ Reserved;

keyword Reserved 
    = "forall" 
    | "exists" 
    | "defer" 
    | "not" 
    | "and" 
    | "or" 
    | "in" 
    | "defrule" 
    | "defexpression" 
    | "defvar" 
    | "defoperator" 
    | "defspace" 
    | "defmodule" 
    | "using"
    | "bool" 
    | "int" 
    | "real" 
    | "end"
    | "true"
    | "false" 
    | "string" 
    | "char"
;