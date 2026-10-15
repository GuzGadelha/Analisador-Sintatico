CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -Iinclude -Ibuild

LEX = flex
YACC = bison

SRC_DIR = src
GRAMMAR_DIR = grammar
BUILD_DIR = build
TARGET = tontoParser

all: $(BUILD_DIR) $(TARGET)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/parserTonto.tab.cpp $(BUILD_DIR)/parserTonto.tab.hpp: $(GRAMMAR_DIR)/parserTonto.y
	$(YACC) -d -o $(BUILD_DIR)/parserTonto.tab.cpp $(GRAMMAR_DIR)/parserTonto.y

$(BUILD_DIR)/lex.yy.cpp: $(GRAMMAR_DIR)/lexerTonto.l $(BUILD_DIR)/parserTonto.tab.hpp
	$(LEX) -o $(BUILD_DIR)/lex.yy.cpp $(GRAMMAR_DIR)/lexerTonto.l

$(TARGET): $(BUILD_DIR)/parserTonto.tab.cpp $(BUILD_DIR)/lex.yy.cpp $(SRC_DIR)/main.cpp $(SRC_DIR)/OntologyModel.cpp $(SRC_DIR)/SyntaxReporter.cpp $(SRC_DIR)/ErrorHandler.cpp
	$(CXX) $(CXXFLAGS) -o $(TARGET) \
		$(SRC_DIR)/main.cpp \
		$(SRC_DIR)/OntologyModel.cpp \
		$(SRC_DIR)/SyntaxReporter.cpp \
		$(SRC_DIR)/ErrorHandler.cpp \
		$(BUILD_DIR)/parserTonto.tab.cpp \
		$(BUILD_DIR)/lex.yy.cpp

clean:
	rm -rf $(BUILD_DIR) $(TARGET) saida.txt

test: $(TARGET)
	./$(TARGET) testes/01_modelo_completo_anexo.tonto

.PHONY: all clean test
