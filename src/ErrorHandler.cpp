#include "ErrorHandler.hpp"
#include <iomanip>
#include <sstream>

namespace Tonto {

ErrorHandler g_errorHandler;

void ErrorHandler::report_error(int line, int col, const std::string& token_found,
                                const std::string& message, const std::string& suggestion) {
    errors.push_back({line, col, token_found, message, suggestion});
}

void ErrorHandler::report_generic_error(int line, int col, const std::string& msg) {
    std::string tip = "Verifique a sintaxe em torno deste ponto. Certifique-se de que todas as chaves '{ }', parenteses '( )' e colchetes '[ ]' foram fechados corretamente.";
    
    // Heurísticas contextuais de tratamento de erros para a linguagem Tonto
    if (msg.find("syntax error") != std::string::npos || msg.find("erro sintatico") != std::string::npos) {
        if (msg.find("package") != std::string::npos) {
            tip = "Declaracao de pacote incorreta. Cada ontologia Tonto deve iniciar com 'package <NomeDoPacote>' ou 'package <Nome> { ... }'.";
        } else if (msg.find("genset") != std::string::npos || msg.find("where") != std::string::npos) {
            tip = "Estrutura de generalizacao (genset) malformada. Use 'genset Nome { general Mae specifics Filha1, Filha2 }' ou 'genset Nome where Filha1, Filha2 specializes Mae'.";
        } else if (msg.find("relation") != std::string::npos || msg.find("specializes") != std::string::npos) {
            tip = "Verifique os operadores relacionais (-- , <>-- , --<> ou ..) e cardinalidades como [1] ou [1..*].";
        } else if (msg.find("enum") != std::string::npos) {
            tip = "Classes enumeradas devem seguir o formato 'enum NomeEnum { Item1, Item2, ... }'.";
        } else if (msg.find("datatype") != std::string::npos) {
            tip = "Novos tipos estruturados devem ser declarados com 'datatype Nome { campo: tipo }'.";
        }
    }

    errors.push_back({line, col, "", msg, tip});
}

bool ErrorHandler::has_errors() const {
    return !errors.empty();
}

int ErrorHandler::get_error_count() const {
    return static_cast<int>(errors.size());
}

const std::vector<SyntaxError>& ErrorHandler::get_errors() const {
    return errors;
}

void ErrorHandler::print_error_report(std::ostream& out) const {
    out << "\n" << std::string(85, '=') << "\n";
    out << std::setw(55) << "RELATORIO DE ERROS DA ONTOLOGIA (DIAGNOSTICO E TRATAMENTO)" << "\n";
    out << std::string(85, '=') << "\n";

    if (errors.empty()) {
        out << " -> NENHUM ERRO SINTATICO ENCONTRADO. Ontologia estruturalmente valida!\n";
        out << std::string(85, '=') << "\n";
        return;
    }

    out << " Total de inconformidades detectadas: " << errors.size() << "\n";
    out << std::string(85, '-') << "\n";

    int index = 1;
    for (const auto& err : errors) {
        out << "[Erro #" << index++ << "] Linha " << err.line << ", Coluna " << err.col << ":\n";
        if (!err.token_found.empty()) {
            out << "   Token Encontrado : \"" << err.token_found << "\"\n";
        }
        out << "   Diagnostico      : " << err.message << "\n";
        out << "   -> Sugestao de Tratamento : " << err.suggestion << "\n\n";
    }
    out << std::string(85, '=') << "\n";
}

void ErrorHandler::clear() {
    errors.clear();
}

} // namespace Tonto
