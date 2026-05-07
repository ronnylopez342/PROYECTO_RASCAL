module Generator

import AST;
import Parser;
import Implode;
import String;
import List;
import IO;
import ParseTree;

void main() {
    Tree cst = parseMainModule(|project://rascaldslverilang/instance/spec3.vl|);
    str result = generator(cst);

    println(result);

    writeFile(
        |project://rascaldslverilang/instance/output/testGenerator2.vl|,
        result
    );
}

//Generador
str generator(Tree cst) {
    MainModule ast = implodeMain(cst);
    return generate(ast);
}

// MainModule and Imports
str generate(mainModule(str moduleName, list[FileImport] fileImports, Body body)) {
    return "defmodule <moduleName>\n"
         + "<intercalate("\n", [generate(i) | i <- fileImports])>\n"
         + "<generate(body)>\n"
         + "end";
}

str generate(fileImport(str importName)) = "using <importName>";

//Body
str generate(body(list[Statement] statements)) = intercalate("\n", [generate(s) | s <- statements]);

str generate(defspace(Space space)) = generate(space);
str generate(defoperator(Operator operator)) = generate(operator);
str generate(defvariable(Variables variables)) = generate(variables);
str generate(defrule(Rule rule)) = generate(rule);
str generate(defexpression(Expression expression)) = generate(expression);
str generate(defattribute(AttributeList attributeList)) = generate(attributeList);

//Space
str generate(space(str spaceName)) = "defspace <spaceName> end";
str generate(subspace(str sub, str super)) = "defspace <sub> \< <super> end";

//Operator
str generate(operator(str opName, Domain domain, list[Domain] range)) {
    str ranges = intercalate(" ", ["-\> <generate(d)>" | d <- range]);
    return "defoperator <opName> : <generate(domain)> <ranges> end";
}

//Domain
str generate(boolDomain()) = "bool";
str generate(intDomain()) = "int";
str generate(realDomain()) = "real";
str generate(stringDomain()) = "string";
str generate(charDomain()) = "char";
str generate(nameDomain(str name)) = name;

//Attributes
str generate(attributeList(list[Attribute] attributes)) = "[<intercalate(" ", [generate(x) | x <- attributes])>]";
str generate(withDomain(str opName, Domain domain)) = "<opName>:<generate(domain)>";
str generate(noDomain(str opName)) = opName;

//Variables
str generate(variables(list[VarDecl] variableList)) = "defvar <intercalate(" ", [generate(x) | x <- variableList])> end";
str generate(varDecl(str name, Domain domain)) = "<name>:<generate(domain)>";

//Rules
str generate(rule(Invocation i1, Invocation i2)) = "defrule <generate(i1)> -\> <generate(i2)> end";
str generate(invocation(str name, list[str] params)) = "(<name> <intercalate(" ", params)>)";

//Expression
str generate(expression(TopExp t)) = "defexpression <generate(t)> end";
str generate(quantExp(Quantifier q, str o1, str o2, FollowExp f)) = "(<generate(q)> <o1> in <o2> <generate(f)>)";
str generate(orExpRec(OrExp orExp)) = generate(orExp);

//FollowExp
str generate(nextExp(TopExp topExp)) = ". <generate(topExp)>";
str generate(attributes(AttributeList attrs)) = " <generate(attrs)>";

//OrExp
str generate(orExp(OrExp left, AndExp right)) = "<generate(left)> or <generate(right)>";
str generate(andTerm(AndExp a)) = generate(a);

//AndExp
str generate(andExp(AndExp left, NotExp right)) = "<generate(left)> and <generate(right)>";
str generate(notTerm(NotExp n)) = generate(n);

//NotExp
str generate(negated(RelExp exp)) = "not <generate(exp)>";
str generate(plain(RelExp exp)) = generate(exp);

//RelExp
str generate(withRelOp(Primary p1, RelOp op, Primary p2)) = "<generate(p1)> <generate(op)> <generate(p2)>";
str generate(customInfix(Primary p1, str op, Primary p2)) = "<generate(p1)> <op> <generate(p2)>";
str generate(onlyPrimary(Primary p)) = generate(p);

//Primary
str generate(primaryId(str id)) = id;
str generate(primaryNum(Number n)) = generate(n);
str generate(primaryBool(BoolLiteral b)) = generate(b);
str generate(primaryString(str val)) = val;
str generate(primaryChar(str c)) = c;
str generate(grouped(OrExp e)) = "(<generate(e)>)"; 

//Number
str generate(intNumber(int valInt)) = "<valInt>";
str generate(floatNumber(num valFloat)) = "<valFloat>";

//RelOp
str generate(eq()) = "=";
str generate(ge()) = "\>=";
str generate(le()) = "\<=";
str generate(equiv()) = "≡";
str generate(iff()) = "\<\>";

//Quantifier
str generate(forall()) = "forall";
str generate(exists()) = "exists";
str generate(defer()) = "defer";

//BoolLiteral
str generate(trueLiteral()) = "true";
str generate(falseLiteral()) = "false";