module Plugin

import IO;
import ParseTree;
import util::Reflective;
import util::IDEServices;
import util::LanguageServer;
import Relation;

import Syntax;
import Checker;
import Generator;
import Implode;

PathConfig pcfg = getProjectPathConfig(|project://rascaldslverilang|);
Language tdslLang = language(pcfg, "VL", "vl", "Plugin", "contribs");

data Command = gen(Tree cst);

Summary tdslSummarizer(loc l, start[MainModule] input) {
    TModel tm = modulesTModelFromTree(input);
    UseDef defs = getUseDef(tm);
    return summary(l,
        messages    = {<m.at, m> | m <- getMessages(tm), !(m is info)},
        definitions = defs
    );
}

set[LanguageService] contribs() = {
    parser(start[MainModule] (str program, loc src) {
        return parse(#start[MainModule], program, src);
    }),
    lenses(rel[loc src, Command lens] (start[MainModule] p) {
        return {
            <p.src, gen(p, title="Generate text file")>
        };
    }),
    summarizer(tdslSummarizer),

    executor(exec)
};

value exec(gen(Tree cst)) {
    str rVal = generator(cst);
    loc outputFile = |project://rascaldslverilang/instance/output/generator.vl|;
    writeFile(outputFile, rVal);
    edit(outputFile);
    return ("result": true);
}

void main() {
    registerLanguage(tdslLang);
    println("Plugin loaded!");
}