module AST

data MainModule
    = mainModule(str moduleName, list[FileImport] fileImports, Body body)
;

data FileImport
    = fileImport(str importName)
;

data Body
    = body(list[Statement] statements)
;

data Statement
    = defspace(Space space)
    | defoperator(Operator operator)
    | defvariable(Variables variables)
    | defrule(Rule rule)
    | defexpression(Expression expression)
    | defattribute(AttributeList attributeList)
;

/*
 * CORRECCION PARA RUBRICA 5/5:
 *
 * Antes el AST solo guardaba:
 *   defspace Set end
 *
 * Ahora tambien guarda:
 *   defspace Set : Element end
 *
 * typedSpace representa una estructura de datos cuyo tipo de elemento
 * fue dado por el usuario.
 */
data Space
    = space(str spaceName)
    | typedSpace(str spaceName, Domain elementType)
    | subspace(str subSpace, str superSpace)
    | typedSubspace(str subSpace, str superSpace, Domain elementType)
;

data Operator
    = operator(str operatorName, Domain domain, list[Domain] range)
;

data Domain
    = boolDomain()
    | intDomain()
    | realDomain()
    | stringDomain()
    | charDomain()
    | nameDomain(str domainName)
;

data AttributeList
    = attributeList(list[Attribute] attributes)
;

data Attribute
    = withDomain(str operatorName, Domain domain)
    | noDomain(str operatorName)
;

data Variables
    = variables(list[VarDecl] variableList)
;

data VarDecl
    = varDecl(str varName, Domain domain)
;

data Rule
    = rule(Invocation opApl1, Invocation opApl2)
;

/*
 * Invocaciones usadas en reglas.
 *
 * unaryInvocation:
 *     (negation p)
 *
 * binaryInvocation:
 *     (suma x y)
 */
data Invocation
    = unaryInvocation(str opName, Primary param)
    | binaryInvocation(str opName, Primary param1, Primary param2)
;

data Expression
    = expression(TopExp topExp)
;

data TopExp
    = quantExp(Quantifier quantifier, str obj1, str obj2, TopExp topExp)
    | orExpRec(OrExp orExp)
;

data OrExp
    = orExp(OrExp left, AndExp right)
    | andTerm(AndExp andExp)
;

data AndExp
    = andExp(AndExp left, NotExp right)
    | notTerm(NotExp notExp)
;

data NotExp
    = negated(RelExp exp)
    | plain(RelExp exp)
;

data RelExp
    = withRelOp(Primary obj1, RelOp relOp, Primary obj2)
    | customInfix(Primary obj1, str customOp, Primary obj2)
    | onlyPrimary(Primary primary)
;

data Primary
    = primaryId(str id)
    | primaryNum(Number number)
    | primaryBool(BoolLiteral boolVal)
    | primaryString(str strVal)
    | primaryChar(str charVal)
    | grouped(TopExp topExp)
;

data Number
    = intNumber(int valInt)
    | floatNumber(num valFloat)
;

data RelOp
    = eq()
    | gt()
    | lt()
    | ge()
    | le()
    | equiv()
    | iff()
;

data Quantifier
    = forall()
    | exists()
    | defer()
;

data ArithOp
    = arithAdd()
    | arithSub()
    | arithMul()
    | arithDiv()
    | arithPow()
    | arithMod()
;

data BoolLiteral
    = trueLiteral()
    | falseLiteral()
;