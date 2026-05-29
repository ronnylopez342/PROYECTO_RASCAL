module Checker

import Syntax;
 
extend analysis::typepal::TypePal;
import ParseTree;
import String;

data AType
    = boolType()
    | intType()
    | realType()
    | stringType()
    | charType()
    | userType(str name)
    | functionType(list[AType] signature)
;

data IdRole
    = variableId()
    | operatorId()
    | spaceId()
;

/*
 * Guarda el tipo de elemento de cada estructura tipada.
 *
 * Ejemplo:
 *   defspace Set : Element end
 *
 * queda guardado como:
 *   "Set" -> userType("Element")
 */
map[str, AType] typedSpaceElementTypes = ();

AType domainToType((Domain) `bool`)   = boolType();
AType domainToType((Domain) `int`)    = intType();
AType domainToType((Domain) `real`)   = realType();
AType domainToType((Domain) `string`) = stringType();
AType domainToType((Domain) `char`)   = charType();
AType domainToType((Domain) `<ID name>`) = userType("<name>");

void useDomainIfUserDefined(Domain d, Collector c) {
    if (domainToType(d) is userType) {
        c.use(d, {spaceId()});
    }
}

void registerTypedSpaces(Tree pt) {
    typedSpaceElementTypes = ();

    if (pt has top) {
        pt = pt.top;
    }

    visit(pt) {
        case (Space) `defspace <ID name> : <Domain elementType> end`: {
            typedSpaceElementTypes["<name>"] = domainToType(elementType);
        }

        case (Space) `defspace <ID sub> \< <ID super> : <Domain elementType> end`: {
            typedSpaceElementTypes["<sub>"] = domainToType(elementType);
        }
    }
}

AType quantifiedVariableType(str domainName) {
    if (domainName in typedSpaceElementTypes) {
        return typedSpaceElementTypes[domainName];
    }

    return userType(domainName);
}

/*
 * Nodos contenedores.
 * Estos collect evitan los mensajes informativos de TypePal:
 * "Missing collect for ..."
 */

void collect(
    current: (MainModule) `defmodule <ID moduleName> <FileImport* fileImports> <Body body> end`,
    Collector c
) {
    collect(body, c);
}

void collect(
    current: (Body) `<Statement* statements>`,
    Collector c
) {
    for (s <- statements) {
        collect(s, c);
    }
}

void collect(
    current: (Statement) `<Space space>`,
    Collector c
) {
    collect(space, c);
}

void collect(
    current: (Statement) `<Operator operator>`,
    Collector c
) {
    collect(operator, c);
}

void collect(
    current: (Statement) `<Variables variables>`,
    Collector c
) {
    collect(variables, c);
}

void collect(
    current: (Statement) `<Rule rule>`,
    Collector c
) {
    collect(rule, c);
}

void collect(
    current: (Statement) `<Expression expression>`,
    Collector c
) {
    collect(expression, c);
}

void collect(
    current: (Statement) `<AttributeList attributeList>`,
    Collector c
) {
    collect(attributeList, c);
}

void collect(
    current: (Variables) `defvar <VarDecl+ vars> end`,
    Collector c
) {
    for (v <- vars) {
        collect(v, c);
    }
}

void collect(
    current: (Expression) `defexpression <TopExp exp> end`,
    Collector c
) {
    collect(exp, c);
    c.fact(current, exp);
}

void collect(
    current: (AttributeList) `[ <Attribute+ attributes> ]`,
    Collector c
) {
    for (a <- attributes) {
        collect(a, c);
    }
}

/*
 * Espacios.
 */

void collect(
    current: (Space) `defspace <ID name> end`,
    Collector c
) {
    c.define("<name>", spaceId(), name, defType(userType("<name>")));
}

void collect(
    current: (Space) `defspace <ID name> : <Domain elementType> end`,
    Collector c
) {
    c.define("<name>", spaceId(), name, defType(userType("<name>")));
    useDomainIfUserDefined(elementType, c);
}

void collect(
    current: (Space) `defspace <ID sub> \< <ID super> end`,
    Collector c
) {
    c.define("<sub>", spaceId(), sub, defType(userType("<sub>")));
    c.use(super, {spaceId()});
}

void collect(
    current: (Space) `defspace <ID sub> \< <ID super> : <Domain elementType> end`,
    Collector c
) {
    c.define("<sub>", spaceId(), sub, defType(userType("<sub>")));
    c.use(super, {spaceId()});
    useDomainIfUserDefined(elementType, c);
}

/*
 * Variables.
 */

void collect(
    current: (VarDecl) `<ID name> : <Domain d>`,
    Collector c
) {
    c.define(
        "<name>",
        variableId(),
        name,
        defType(domainToType(d))
    );

    useDomainIfUserDefined(d, c);
}

/*
 * Operadores.
 */

void collect(
    current: (Operator) `defoperator <ID name> : <Domain d1> -\> <Domain d2> end`,
    Collector c
) {
    c.define(
        "<name>",
        operatorId(),
        name,
        defType(functionType([
            domainToType(d1),
            domainToType(d2)
        ]))
    );

    useDomainIfUserDefined(d1, c);
    useDomainIfUserDefined(d2, c);
}

void collect(
    current: (Operator) `defoperator <ID name> : <Domain d1> -\> <Domain d2> -\> <Domain d3> end`,
    Collector c
) {
    c.define(
        "<name>",
        operatorId(),
        name,
        defType(functionType([
            domainToType(d1),
            domainToType(d2),
            domainToType(d3)
        ]))
    );

    useDomainIfUserDefined(d1, c);
    useDomainIfUserDefined(d2, c);
    useDomainIfUserDefined(d3, c);
}

/*
 * Reglas.
 */

void collect(
    current: (Rule) `defrule <Invocation left> -\> <Invocation right> end`,
    Collector c
) {
    collect(left, c);
    collect(right, c);

    c.calculate(
        "rule",
        current,
        [left, right],
        AType(Solver s) {
            s.requireEqual(
                left,
                right,
                error(current, "Los dos lados de la regla deben producir el mismo tipo")
            );

            return s.getType(left);
        }
    );
}

/*
 * Invocaciones.
 */

void collect(
    current: (Invocation) `(<ID opName> <Primary p1>)`,
    Collector c
) {
    c.use(opName, {operatorId()});
    c.fact(opName, opName);

    collect(p1, c);

    c.calculate(
        "unary invocation",
        current,
        [opName, p1],
        AType(Solver s) {
            AType opType = s.getType(opName);

            if (functionType(signature) := opType) {
                if (size(signature) != 2) {
                    s.report(
                        error(
                            current,
                            "La invocacion unaria requiere un operador con un argumento y un retorno"
                        )
                    );

                    return signature[size(signature) - 1];
                }

                s.requireEqual(
                    p1,
                    signature[0],
                    error(p1, "El argumento no coincide con el tipo esperado por el operador")
                );

                return signature[1];
            }

            s.report(
                error(
                    opName,
                    "El identificador usado en la invocacion no tiene una firma de operador valida"
                )
            );

            return boolType();
        }
    );
}

void collect(
    current: (Invocation) `(<ID opName> <Primary p1> <Primary p2>)`,
    Collector c
) {
    c.use(opName, {operatorId()});
    c.fact(opName, opName);

    collect(p1, c);
    collect(p2, c);

    c.calculate(
        "binary invocation",
        current,
        [opName, p1, p2],
        AType(Solver s) {
            AType opType = s.getType(opName);

            if (functionType(signature) := opType) {
                if (size(signature) != 3) {
                    s.report(
                        error(
                            current,
                            "La invocacion binaria requiere un operador con dos argumentos y un retorno"
                        )
                    );

                    return signature[size(signature) - 1];
                }

                s.requireEqual(
                    p1,
                    signature[0],
                    error(p1, "El primer argumento no coincide con el tipo esperado por el operador")
                );

                s.requireEqual(
                    p2,
                    signature[1],
                    error(p2, "El segundo argumento no coincide con el tipo esperado por el operador")
                );

                return signature[2];
            }

            s.report(
                error(
                    opName,
                    "El identificador usado en la invocacion no tiene una firma de operador valida"
                )
            );

            return boolType();
        }
    );
}

/*
 * Atributos.
 */

void collect(
    current: (Attribute) `<ID name> : <Domain d>`,
    Collector c
) {
    c.define(
        "<name>",
        operatorId(),
        name,
        defType(domainToType(d))
    );

    useDomainIfUserDefined(d, c);
}

void collect(
    current: (Attribute) `<ID name>`,
    Collector c
) {
    c.define(
        "<name>",
        operatorId(),
        name,
        defType(boolType())
    );
}

/*
 * Primarios.
 */

void collect(
    current: (Primary) `<ID name>`,
    Collector c
) {
    c.use(name, {variableId(), operatorId(), spaceId()});
    c.fact(current, name);
}

void collect(
    current: (Primary) `<INT _>`,
    Collector c
) {
    c.fact(current, intType());
}

void collect(
    current: (Primary) `<FLOAT _>`,
    Collector c
) {
    c.fact(current, realType());
}

void collect(
    current: (Primary) `true`,
    Collector c
) {
    c.fact(current, boolType());
}

void collect(
    current: (Primary) `false`,
    Collector c
) {
    c.fact(current, boolType());
}

void collect(
    current: (Primary) `<STRING _>`,
    Collector c
) {
    c.fact(current, stringType());
}

void collect(
    current: (Primary) `<CHAR _>`,
    Collector c
) {
    c.fact(current, charType());
}

void collect(
    current: (Primary) `(<TopExp e>)`,
    Collector c
) {
    collect(e, c);
    c.fact(current, e);
}

/*
 * Expresiones.
 */

void collect(
    current: (TopExp) `(<Quantifier q> <ID var> in <ID domain> . <TopExp body>)`,
    Collector c
) {
    c.use(domain, {spaceId()});

    c.enterScope(current);

    c.define(
        "<var>",
        variableId(),
        var,
        defType(quantifiedVariableType("<domain>"))
    );

    collect(body, c);

    c.leaveScope(current);

    c.calculate(
        "quantifier",
        current,
        [body],
        AType(Solver s) {
            s.requireEqual(
                body,
                boolType(),
                error(body, "El cuerpo del cuantificador debe tener tipo booleano")
            );

            return boolType();
        }
    );
}

void collect(
    current: (TopExp) `<OrExp e>`,
    Collector c
) {
    collect(e, c);
    c.fact(current, e);
}

void collect(
    current: (RelExp) `<Primary p1> <RelOp _> <Primary p2>`,
    Collector c
) {
    collect(p1, c);
    collect(p2, c);

    c.calculate(
        "relation",
        current,
        [p1, p2],
        AType(Solver s) {
            s.requireEqual(
                p1,
                p2,
                error(current, "Los dos lados de la relacion deben tener el mismo tipo")
            );

            return boolType();
        }
    );
}

void collect(
    current: (RelExp) `<Primary p1> <ID op> <Primary p2>`,
    Collector c
) {
    c.use(op, {operatorId()});
    c.fact(op, op);

    collect(p1, c);
    collect(p2, c);

    c.calculate(
        "custom infix operator",
        current,
        [op, p1, p2],
        AType(Solver s) {
            AType opType = s.getType(op);

            if (functionType(signature) := opType) {
                if (size(signature) != 3) {
                    s.report(
                        error(
                            op,
                            "El operador infijo debe tener exactamente dos argumentos y un tipo de retorno"
                        )
                    );

                    return signature[size(signature) - 1];
                }

                s.requireEqual(
                    p1,
                    signature[0],
                    error(p1, "El lado izquierdo del operador no coincide con su firma")
                );

                s.requireEqual(
                    p2,
                    signature[1],
                    error(p2, "El lado derecho del operador no coincide con su firma")
                );

                return signature[2];
            }

            s.report(
                error(
                    op,
                    "El operador infijo no tiene una firma valida"
                )
            );

            return boolType();
        }
    );
}

void collect(
    current: (RelExp) `<Primary p>`,
    Collector c
) {
    collect(p, c);
    c.fact(current, p);
}

void collect(
    current: (OrExp) `<OrExp l> or <AndExp r>`,
    Collector c
) {
    collect(l, c);
    collect(r, c);

    c.calculate(
        "or",
        current,
        [l, r],
        AType(Solver s) {
            s.requireEqual(
                l,
                boolType(),
                error(l, "El lado izquierdo de or debe tener tipo booleano")
            );

            s.requireEqual(
                r,
                boolType(),
                error(r, "El lado derecho de or debe tener tipo booleano")
            );

            return boolType();
        }
    );
}

void collect(
    current: (OrExp) `<AndExp a>`,
    Collector c
) {
    collect(a, c);
    c.fact(current, a);
}

void collect(
    current: (AndExp) `<AndExp l> and <NotExp r>`,
    Collector c
) {
    collect(l, c);
    collect(r, c);

    c.calculate(
        "and",
        current,
        [l, r],
        AType(Solver s) {
            s.requireEqual(
                l,
                boolType(),
                error(l, "El lado izquierdo de and debe tener tipo booleano")
            );

            s.requireEqual(
                r,
                boolType(),
                error(r, "El lado derecho de and debe tener tipo booleano")
            );

            return boolType();
        }
    );
}

void collect(
    current: (AndExp) `<NotExp n>`,
    Collector c
) {
    collect(n, c);
    c.fact(current, n);
}

void collect(
    current: (NotExp) `not <RelExp e>`,
    Collector c
) {
    collect(e, c);

    c.calculate(
        "not",
        current,
        [e],
        AType(Solver s) {
            s.requireEqual(
                e,
                boolType(),
                error(e, "El operador not solo puede aplicarse a expresiones booleanas")
            );

            return boolType();
        }
    );
}

void collect(
    current: (NotExp) `<RelExp e>`,
    Collector c
) {
    collect(e, c);
    c.fact(current, e);
}

/*
 * Subtipado.
 */

bool subtype(AType t, AType t) = true;
default bool subtype(AType _, AType _) = false;

/*
 * Entrada publica del checker.
 */

public TModel modulesTModelFromTree(Tree pt) {
    if (pt has top) {
        pt = pt.top;
    }

    registerTypedSpaces(pt);

    TypePalConfig cfg = getModulesConfig();
    Collector c = newCollector("collectAndSolve", pt, cfg);
    collect(pt, c);
    return newSolver(pt, c.run()).run();
}

private TypePalConfig getModulesConfig() = tconfig(
    verbose = false,
    logTModel = false,
    logAttempts = false,
    logSolverIterations = false,
    logSolverSteps = false,
    isSubType = subtype
);