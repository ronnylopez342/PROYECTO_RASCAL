module Parser

import Syntax;
import ParseTree;

public start[MainModule] parseMainModule(str src, loc origin) = parse(#start[MainModule], src, origin);
public start[MainModule] parseMainModule(loc origin) = parse(#start[MainModule], origin);
