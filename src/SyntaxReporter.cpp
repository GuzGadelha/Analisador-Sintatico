#include "SyntaxReporter.hpp"
#include <iomanip>
#include <sstream>

namespace Tonto {

void SyntaxReporter::print_summary_table(const Ontology& ont, std::ostream& out) {
    out << "\n" << std::string(90, '=') << "\n";
    out << std::setw(58) << "TABELA DE SINTESE DOS CONSTRUTOS DA ONTOLOGIA" << "\n";
    out << std::string(90, '=') << "\n";

    //resumo geral
    out << "\n[1] RESUMO QUANTITATIVO GLOBAL\n";
    out << std::string(90, '-') << "\n";
    out << std::left << std::setw(50) << "CATEGORIA DO CONSTRUTO" << "QUANTIDADE" << "\n";
    out << std::string(90, '-') << "\n";
    out << std::left << std::setw(50) << "Pacotes (Packages)" << ont.get_total_packages() << "\n";
    out << std::left << std::setw(50) << "Classes Ontologicas" << ont.get_total_classes() << "\n";
    out << std::left << std::setw(50) << "Atributos Declarados" << ont.get_total_attributes() << "\n";
    out << std::left << std::setw(50) << "Relacoes Internas (escopo de classe)" << ont.get_total_internal_relations() << "\n";
    out << std::left << std::setw(50) << "Relacoes Externas (escopo global)" << ont.get_total_external_relations() << "\n";
    out << std::left << std::setw(50) << "Conjuntos de Generalizacao (Gensets)" << ont.get_total_gensets() << "\n";
    out << std::left << std::setw(50) << "Novos Tipos de Dados (DataTypes)" << ont.get_total_datatypes() << "\n";
    out << std::left << std::setw(50) << "Classes Enumeradas (Enums)" << ont.get_total_enums() << "\n";
    out << std::left << std::setw(50) << "Instancias de Individuos" << ont.get_total_instances() << "\n";
    out << std::string(90, '-') << "\n";

    // mapeamento
    out << "\n[2] PACOTES E SUAS RESPECTIVAS CLASSES\n";
    out << std::string(90, '-') << "\n";
    for (const auto& pkg : ont.get_packages()) {
        out << " Pacote: \"" << pkg.name << "\" (Linha " << pkg.line << ")\n";
        if (pkg.classes.empty()) {
            out << "   -> Nenhuma classe declarada explicitamente neste pacote.\n";
        } else {
            out << "   Classes pertencentes (" << pkg.classes.size() << "):\n";
            for (const auto& cls : pkg.classes) {
                out << "     • [" << (cls.stereotype.empty() ? "class" : cls.stereotype) << "] "
                    << cls.name;
                if (!cls.parent_class.empty()) {
                    out << " specializes " << cls.parent_class;
                }
                out << " (" << cls.attributes.size() << " atributos, "
                    << cls.internal_relations.size() << " relacoes internas)\n";
            }
        }
        out << "\n";
    }

    // detalhamento das classes
    out << "[3] DETALHAMENTO DE CLASSES E ATRIBUTOS\n";
    out << std::string(90, '-') << "\n";
    for (const auto& pkg : ont.get_packages()) {
        for (const auto& cls : pkg.classes) {
            out << " Classe: " << cls.name << " <<" << (cls.stereotype.empty() ? "class" : cls.stereotype) << ">>";
            if (!cls.parent_class.empty()) {
                out << " : specializes " << cls.parent_class;
            }
            out << " [Pacote: " << pkg.name << "]\n";

            if (cls.attributes.empty()) {
                out << "   (Sem atributos declarados)\n";
            } else {
                for (const auto& attr : cls.attributes) {
                    out << "   + " << attr.name << ": " << attr.type;
                    if (!attr.meta_attributes.empty()) {
                        out << " {";
                        for (size_t i = 0; i < attr.meta_attributes.size(); ++i) {
                            out << attr.meta_attributes[i] << (i + 1 < attr.meta_attributes.size() ? ", " : "");
                        }
                        out << "}";
                    }
                    out << "\n";
                }
            }

            if (!cls.internal_relations.empty()) {
                out << "   Relacoes Internas:\n";
                for (const auto& r : cls.internal_relations) {
                    out << "     -> " << (r.stereotype.empty() ? "" : "@" + r.stereotype + " ")
                        << r.source_cardinality << " " << r.rel_operator << " "
                        << r.target_cardinality << " " << r.target_class;
                    if (!r.name.empty()) out << " (" << r.name << ")";
                    out << "\n";
                }
            }
            out << "\n";
        }
    }

    // detalhamento das relacoes externas
    out << "[4] RELACOES EXTERNAS (FORA DO ESCOPO DE CLASSE)\n";
    out << std::string(90, '-') << "\n";
    bool has_ext = false;
    for (const auto& pkg : ont.get_packages()) {
        for (const auto& r : pkg.external_relations) {
            has_ext = true;
            out << " • " << (r.stereotype.empty() ? "relation" : "@" + r.stereotype + " relation");
            if (!r.name.empty()) out << " " << r.name;
            out << "\n     Dominio : " << r.source_class << " " << r.source_cardinality
                << "\n     Operador: " << r.rel_operator
                << "\n     Imagem  : " << r.target_class << " " << r.target_cardinality << "\n";
            if (!r.meta_attributes.empty()) {
                out << "     Metadados: { ";
                for (const auto& m : r.meta_attributes) out << m << " ";
                out << "}\n";
            }
            out << "\n";
        }
    }
    if (!has_ext) {
        out << " (Nenhuma relacao externa encontrada)\n\n";
    }

    // 5. Conjuntos de Generalização (Gensets)
    out << "[5] CONJUNTOS DE GENERALIZACAO (GENSETS)\n";
    out << std::string(90, '-') << "\n";
    bool has_genset = false;
    for (const auto& pkg : ont.get_packages()) {
        for (const auto& gs : pkg.gensets) {
            has_genset = true;
            out << " • Genset: \"" << gs.name << "\" [Formato: " << (gs.is_inline ? "Inline" : "Bloco") << "]\n";
            out << "     Classe-Mae (General)   : " << gs.general_class << "\n";
            out << "     Classes-Filhas (Specifics): ";
            for (size_t i = 0; i < gs.specific_classes.size(); ++i) {
                out << gs.specific_classes[i] << (i + 1 < gs.specific_classes.size() ? ", " : "");
            }
            out << "\n     Restricoes             : ";
            if (gs.restrictions.empty()) {
                out << "nenhuma (padrao)";
            } else {
                for (const auto& rest : gs.restrictions) out << "[" << rest << "] ";
            }
            out << "\n\n";
        }
    }
    if (!has_genset) {
        out << " (Nenhum genset encontrado)\n\n";
    }

    // 6. Novos Tipos e Classes Enumeradas
    out << "[6] DECLARACOES DE TIPOS E ENUMS\n";
    out << std::string(90, '-') << "\n";
    for (const auto& pkg : ont.get_packages()) {
        if (!pkg.datatypes.empty()) {
            out << " Novos Tipos Estruturados (DataTypes):\n";
            for (const auto& dt : pkg.datatypes) {
                out << "   datatype " << dt.name << " {\n";
                for (const auto& f : dt.fields) {
                    out << "      " << f.name << ": " << f.type << "\n";
                }
                out << "   }\n";
            }
        }
        if (!pkg.enums.empty()) {
            out << " Classes Enumeradas (Enums):\n";
            for (const auto& en : pkg.enums) {
                out << "   enum " << en.name << " { ";
                for (size_t i = 0; i < en.literals.size(); ++i) {
                    out << en.literals[i] << (i + 1 < en.literals.size() ? ", " : "");
                }
                out << " }\n";
            }
        }
    }

    out << std::string(90, '=') << "\n";
}

} // namespace Tonto
