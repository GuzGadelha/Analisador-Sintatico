cmake_minimum_required(VERSION 3.10)
project(TontoCompiler CXX)

set(CMAKE_CXX_STANDARD 17)

# Encontra pacotes do Flex e Bison
find_package(BISON REQUIRED)
find_package(FLEX REQUIRED)

# Gera o Parser com Bison (produz parserTonto.tab.cpp e parserTonto.tab.hpp)
BISON_TARGET(ParserGrammar grammar/parserTonto.y ${CMAKE_CURRENT_BINARY_DIR}/parserTonto.tab.cpp)

# Gera o Lexer com Flex (produz rulesTonto.yy.cpp)
FLEX_TARGET(LexerRules grammar/rulesTonto.l ${CMAKE_CURRENT_BINARY_DIR}/rulesTonto.yy.cpp)

# Garante que o Flex espera o Bison terminar de gerar o cabeçalho
ADD_FLEX_BISON_DEPENDENCY(LexerRules ParserGrammar)

# Diretórios de include
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include ${CMAKE_CURRENT_BINARY_DIR})

# Arquivos fonte do projeto (conforme a estrutura das suas pastas)
file(GLOB SOURCES 
    "src/*.cpp"
    ${BISON_ParserGrammar_OUTPUTS}
    ${FLEX_LexerRules_OUTPUTS}
)

add_executable(tonto_compiler
    src/main.cpp
    src/ErrorHandler.cpp
    src/OntologyModel.cpp
    src/SyntaxReporter.cpp
    ${BISON_ParserGrammar_OUTPUTS}
    ${FLEX_LexerRules_OUTPUTS}
)