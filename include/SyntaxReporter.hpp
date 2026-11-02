#ifndef SYNTAX_REPORTER_HPP
#define SYNTAX_REPORTER_HPP

#include "OntologyModel.hpp"
#include <iostream>

namespace Tonto {

class SyntaxReporter {
public:
    static void print_summary_table(const Ontology& ont, std::ostream& out = std::cout);
    static void print_json_summary(const Ontology& ont, std::ostream& out = std::cout);
};

} // namespace Tonto

#endif // SYNTAX_REPORTER_HPP
