#include <iostream>
#include <fstream>
#include <cstdio>
#include "OntologyModel.hpp"
#include "SyntaxReporter.hpp"
#include "ErrorHandler.hpp"

extern int yyparse();
extern FILE* yyin;
extern void reset_lexer_coordinates();

int main(int argc, char** argv) {
    std::cout << "\n===============================================================================\n";
    std::cout << "          ANALISADOR SINTATICO PARA A LINGUAGEM TONTO (OntoUML Textual)        \n";
    std::cout << "                 Compiladores - UFERSA / Prof. Patricio de Alencar Silva       \n";
    std::cout << "                 Equipe: Gustavo, Mariana e Eduarda                            \n";
    std::cout << "===============================================================================\n\n";

    if (argc > 1) {
        FILE* file = fopen(argv[1], "r");
        if (!file) {
            std::cerr << "Erro fatal: Nao foi possivel abrir o arquivo \"" << argv[1] << "\".\n";
            return 1;
        }
        yyin = file;
        std::cout << "Processando ontologia a partir do arquivo: \"" << argv[1] << "\"\n";
    } else {
        std::cout << "Aviso: Nenhum arquivo fornecido. Lendo codigo da entrada padrao (Ctrl+D para encerrar):\n";
    }

    reset_lexer_coordinates();
    Tonto::g_ontology.clear();
    Tonto::g_errorHandler.clear();

    // Executa a análise sintática ascendente (Bison)
    int parse_result = yyparse();

    // 1. Apresenta a Visualização 1: TABELA DE SÍNTESE
    Tonto::SyntaxReporter::print_summary_table(Tonto::g_ontology);

    // 2. Apresenta a Visualização 2: RELATÓRIO DE ERROS DA ONTOLOGIA
    Tonto::g_errorHandler.print_error_report();

    if (argc > 1 && yyin) {
        fclose(yyin);
    }

    if (parse_result != 0 || Tonto::g_errorHandler.has_errors()) {
        std::cerr << "\n[Status]: Analise concluida com inconformidades sintaticas identificadas.\n";
        return 1;
    }

    std::cout << "\n[Status]: Analise sintatica concluida com SUCESSO! Ontologia 100% compativel.\n\n";
    return 0;
}
