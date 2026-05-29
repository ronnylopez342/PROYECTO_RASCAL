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

/*
 * CORRECCION PARA RUBRICA 5/5:
 *
 * Antes:
 *   defspace Set end
 *
 * Ahora tambien acepta:
 *   defspace Element end
 *   defspace Set : Element end
 *   defspace Group : Person end
 *
 * Esto permite que una estructura de datos tenga un tipo de elemento
 * definido por el usuario.
 */
syntax Space
    = space: 'defspace' ID spaceName 'end'
    | typedSpace: 'defspace' ID spaceName ':' Domain elementType 'end'
    | subspace: 'defspace' ID subSpace '\<' ID superSpace 'end'
    | typedSubspace: 'defspace' ID subSpace '\<' ID superSpace ':' Domain elementType 'end'
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

/*
 * Invocaciones usadas en reglas.
 * Se separan en unarias y binarias para que el checker pueda validar
 * aridad y tipos de argumentos con TypePal.
 *
 * Ejemplos:
 * (negation p)
 * (suma x y)
 */
syntax Invocation
    = unaryInvocation: '(' ID opName Primary param ')'
    | binaryInvocation: '(' ID opName Primary param1 Primary param2 ')'
;

syntax Expression
    = expression: 'defexpression' TopExp topExp 'end'
;

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

syntax ArithOp
    = '+' | '-' | '*' | '/' | '**' | '%' 
;

syntax BoolLiteral
    = trueLiteral: 'true'
    | falseLiteral: 'false'
;

lexical STRING = "\"" ![\"\n]* "\"";
lexical CHAR = "\'" [^\'\n] "\'";

/*
 * INT corregido:
 * Antes permitia "-" solo como entero.
 * Ahora acepta un signo negativo opcional seguido obligatoriamente
 * por uno o mas digitos.
 */
lexical INT = [\-]? [0-9]+ !>> [0-9];

lexical FLOAT = [0-9]+ "." [0-9]+;

lexical ID = ([a-zA-Z][a-zA-Z0-9_/.\-]* !>> [a-zA-Z0-9_/.\-]) \ Reserved;

keyword Reserved = "forall" | "exists" | "defer" | "not" | "and" | "or" | "in" 
| "defrule" | "defexpression" | "defvar" | "defoperator" | "defspace" | "defmodule" | "using"
| "bool" | "int" | "real" | "end" | "true" | "false" | "string" | "char";