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

AType domainToType((Domain) `bool`)   = boolType();
AType domainToType((Domain) `int`)    = intType();
AType domainToType((Domain) `real`)   = realType();
AType domainToType((Domain) `string`) = stringType();
AType domainToType((Domain) `char`)   = charType();
AType domainToType((Domain) `<ID name>`) = userType("<name>");

void collect(
    current: (Space) `defspace <ID name> end`,
    Collector c
) {
    c.define("<name>", spaceId(), name, defType(userType("<name>")));
    collect(name, c);
}

void collect(
    current: (Space) `defspace <ID sub> \< <ID super> end`,
    Collector c
) {
    c.define("<sub>", spaceId(), sub, defType(userType("<sub>")));
    c.use(super, {spaceId()});
}

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
}

void collect(
    current: (Operator) `defoperator <ID name> : <Domain first> -\> <Domain last> end`,
    Collector c
) {
    c.define(
        "<name>",
        operatorId(),
        name,
        defType(functionType([domainToType(first), domainToType(last)]))
    );
    if (domainToType(first) is userType) c.use(first, {spaceId()});
    if (domainToType(last) is userType)  c.use(last,  {spaceId()});
}

void collect(
    current: (Invocation) `(<ID opName> <ID+ params>)`,
    Collector c
) {
    
    c.use(opName, {operatorId()});
    
    for (p <- params) {
        c.use(p, {variableId(), spaceId()});
    }
}

void collect(
    current: (Primary) `<ID name>`,
    Collector c
) {
    c.use(name, {variableId(), operatorId(), spaceId()});
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
    current: (RelExp) `<Primary p1> <RelOp _> <Primary p2>`,
    Collector c
) {
    c.requireEqual(
        typeof(p1),
        typeof(p2),
        error(current, "Los dos lados de la relación deben tener el mismo tipo")
    );
    collect(p1, c);
    collect(p2, c);
}

void collect(
    current: (RelExp) `<Primary p1> <ID op> <Primary p2>`,
    Collector c
) {
    c.use(op, {operatorId()});
    collect(p1, c);
    collect(p2, c);
}

void collect(
    current: (RelExp) `<Primary p>`,
    Collector c
) {
    collect(p, c);
}

void collect(current: (Primary) `(<OrExp e>)`, Collector c) {
    collect(e, c);
}

void collect(current: (OrExp) `<OrExp l> or <AndExp r>`, Collector c) {
    collect(l, c);
    collect(r, c);
}

void collect(current: (OrExp) `<AndExp a>`, Collector c) {
    collect(a, c);
}

void collect(current: (AndExp) `<AndExp l> and <NotExp r>`, Collector c) {
    collect(l, c);
    collect(r, c);
}

void collect(current: (AndExp) `<NotExp n>`, Collector c) {
    collect(n, c);
}

void collect(current: (NotExp) `not <RelExp e>`, Collector c) {
    collect(e, c);
}

void collect(current: (NotExp) `<RelExp e>`, Collector c) {
    collect(e, c);
}

bool subtype(AType t, AType t) = true;
default bool subtype(AType _, AType _) = false;

public TModel modulesTModelFromTree(Tree pt) {
    if (pt has top) pt = pt.top;
    TypePalConfig cfg = getModulesConfig();
    Collector c = newCollector("collectAndSolve", pt, cfg);
    collect(pt, c);
    return newSolver(pt, c.run()).run();
}

private TypePalConfig getModulesConfig() = tconfig(
    verbose = true,
    logTModel = true,
    logAttempts = true,
    logSolverIterations = true,
    logSolverSteps = true,
    isSubType = subtype
);