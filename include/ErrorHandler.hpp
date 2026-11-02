#ifndef ERROR_HANDLER_HPP
#define ERROR_HANDLER_HPP

#include <string>
#include <vector>
#include <iostream>

namespace Tonto {

struct SyntaxError {
    int line = 0;
    int col = 0;
    std::string token_found;
    std::string message;
    std::string suggestion;
};

class ErrorHandler {
private:
    std::vector<SyntaxError> errors;

public:
    ErrorHandler() = default;

    void report_error(int line, int col, const std::string& token_found,
                      const std::string& message, const std::string& suggestion);

    void report_generic_error(int line, int col, const std::string& msg);

    bool has_errors() const;
    int get_error_count() const;
    const std::vector<SyntaxError>& get_errors() const;

    void print_error_report(std::ostream& out = std::cout) const;
    void clear();
};

extern ErrorHandler g_errorHandler;

} // namespace Tonto

#endif // ERROR_HANDLER_HPP
