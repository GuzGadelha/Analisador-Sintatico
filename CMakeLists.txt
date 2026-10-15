cmake_minimum_required(VERSION 3.10)
project(TontoParser LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}
)

find_package(BISON REQUIRED)
find_package(FLEX REQUIRED)

BISON_TARGET(TontoBisonParser
    ${CMAKE_CURRENT_SOURCE_DIR}/grammar/parserTonto.y
    ${CMAKE_CURRENT_BINARY_DIR}/parserTonto.tab.cpp
    DEFINES_FILE ${CMAKE_CURRENT_BINARY_DIR}/parserTonto.tab.hpp
)

FLEX_TARGET(TontoFlexScanner
    ${CMAKE_CURRENT_SOURCE_DIR}/grammar/lexerTonto.l
    ${CMAKE_CURRENT_BINARY_DIR}/lex.yy.cpp
)

ADD_FLEX_BISON_DEPENDENCY(TontoFlexScanner TontoBisonParser)

set(SOURCES
    src/main.cpp
    src/OntologyModel.cpp
    src/SyntaxReporter.cpp
    src/ErrorHandler.cpp
    ${BISON_TontoBisonParser_OUTPUTS}
    ${FLEX_TontoFlexScanner_OUTPUTS}
)

add_executable(tontoParser ${SOURCES})
