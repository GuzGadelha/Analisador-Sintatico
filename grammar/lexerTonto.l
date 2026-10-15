%{
#include <iostream>
#include <string>
#include "OntologyModel.hpp"
#include "ErrorHandler.hpp"
#include "parserTonto.tab.hpp"

extern YYLTYPE yylloc;
static int current_col = 1;

#define YY_USER_ACTION \
    yylloc.first_line = yylineno; \
    yylloc.first_column = current_col; \
    yylloc.last_line = yylineno; \
    yylloc.last_column = current_col + yyleng - 1; \
    current_col += yyleng;
%}

%option noyywrap
%option yylineno

CUSTOM_DATATYPE    [a-zA-Z]+"DataType"
INSTANCE_NAME      [a-zA-Z][a-zA-Z_]*[0-9]+
CLASS_NAME         [A-Z][a-zA-Z0-9_]*
RELATION_NAME      [a-z][a-zA-Z0-9_]*

%%

[ \t\r]+           { /* ignora espacos em branco */ }
\n                 { current_col = 1; }
"//"[^\r\n]*       { /* ignora comentarios de linha */ }
"/*"([^*]|\*+[^*/])*\*+"/" { /* ignora comentarios de bloco */ }

"--"               { return TOKEN_RELATION_LINK; }
"<>--"             { return TOKEN_COMP_AGG_LEFT; }
"--<>"             { return TOKEN_COMP_AGG_RIGHT; }
".."               { return TOKEN_RANGE; }
"{"                { return TOKEN_LBRACE; }
"}"                { return TOKEN_RBRACE; }
"("                { return TOKEN_LPAREN; }
")"                { return TOKEN_RPAREN; }
"["                { return TOKEN_LBRACKET; }
"]"                { return TOKEN_RBRACKET; }
"*"                { return TOKEN_STAR; }
"@"                { return TOKEN_AT; }
"."                { return TOKEN_DOT; }
","                { return TOKEN_COMMA; }
":"                { return TOKEN_COLON; }

[0-9]+             { yylval.sval = new std::string(yytext); return TOKEN_MULTIPLICITY; }

"package"              { return TOKEN_PACKAGE; }
"import"               { return TOKEN_IMPORT; }
"class"                { return TOKEN_CLASS; }
"genset"               { return TOKEN_GENSET; }
"general"              { return TOKEN_GENERAL; }
"specifics"            { return TOKEN_SPECIFICS; }
"where"                { return TOKEN_WHERE; }
"specializes"          { return TOKEN_SPECIALIZES; }
"disjoint"             { return TOKEN_DISJOINT; }
"complete"             { return TOKEN_COMPLETE; }
"overlapping"          { return TOKEN_OVERLAPPING; }
"incomplete"           { return TOKEN_INCOMPLETE; }
"datatype"             { return TOKEN_DATATYPE; }
"enum"                 { return TOKEN_ENUM; }
"relation"             { return TOKEN_RELATION; }
"functional-complexes" { return TOKEN_FUNCTIONAL_COMPLEXES; }

"kind"                 { yylval.sval = new std::string(yytext); return TOKEN_CLASS_STEREO; }
"phase"                { yylval.sval = new std::string(yytext); return TOKEN_CLASS_STEREO; }
"role"                 { yylval.sval = new std::string(yytext); return TOKEN_CLASS_STEREO; }
"subkind"              { yylval.sval = new std::string(yytext); return TOKEN_CLASS_STEREO; }
"category"             { yylval.sval = new std::string(yytext); return TOKEN_CLASS_STEREO; }
"event"                { yylval.sval = new std::string(yytext); return TOKEN_CLASS_STEREO; }
"situation"            { yylval.sval = new std::string(yytext); return TOKEN_CLASS_STEREO; }
"process"              { yylval.sval = new std::string(yytext); return TOKEN_CLASS_STEREO; }
"mixin"                { yylval.sval = new std::string(yytext); return TOKEN_CLASS_STEREO; }
"phaseMixin"           { yylval.sval = new std::string(yytext); return TOKEN_CLASS_STEREO; }
"roleMixin"            { yylval.sval = new std::string(yytext); return TOKEN_CLASS_STEREO; }
"collective"           { yylval.sval = new std::string(yytext); return TOKEN_CLASS_STEREO; }
"quantity"             { yylval.sval = new std::string(yytext); return TOKEN_CLASS_STEREO; }
"intrinsicMode"        { yylval.sval = new std::string(yytext); return TOKEN_CLASS_STEREO; }
"extrinsicMode"        { yylval.sval = new std::string(yytext); return TOKEN_CLASS_STEREO; }
"mode"                 { yylval.sval = new std::string(yytext); return TOKEN_CLASS_STEREO; }
"quality"              { yylval.sval = new std::string(yytext); return TOKEN_CLASS_STEREO; }
"historicalRole"       { yylval.sval = new std::string(yytext); return TOKEN_CLASS_STEREO; }
"historicalRoleMixin"  { yylval.sval = new std::string(yytext); return TOKEN_CLASS_STEREO; }

"aggregation"          { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"material"             { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"derivation"           { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"comparative"          { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"composition"          { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"inherence"            { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"constitution"         { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"mediation"            { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"characterization"     { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"subCollectionOf"      { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"subQualityOf"         { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"instantiation"        { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"externalDependence"   { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"componentOf"          { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"memberOf"             { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"termination"          { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"participational"      { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"participation"        { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"historicalDependence" { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"creation"             { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"manifestation"        { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"bringsAbout"          { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"triggers"             { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"value"                { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }
"formal"               { yylval.sval = new std::string(yytext); return TOKEN_RELATION_STEREO; }

"number"               { yylval.sval = new std::string(yytext); return TOKEN_NATIVE_TYPE; }
"string"               { yylval.sval = new std::string(yytext); return TOKEN_NATIVE_TYPE; }
"boolean"              { yylval.sval = new std::string(yytext); return TOKEN_NATIVE_TYPE; }
"time"                 { yylval.sval = new std::string(yytext); return TOKEN_NATIVE_TYPE; }
"date"                 { yylval.sval = new std::string(yytext); return TOKEN_NATIVE_TYPE; }
"datetime"             { yylval.sval = new std::string(yytext); return TOKEN_NATIVE_TYPE; }
"int"                  { yylval.sval = new std::string(yytext); return TOKEN_NATIVE_TYPE; }

"ordered"              { yylval.sval = new std::string(yytext); return TOKEN_META_ATTR; }
"const"                { yylval.sval = new std::string(yytext); return TOKEN_META_ATTR; }
"derived"              { yylval.sval = new std::string(yytext); return TOKEN_META_ATTR; }
"subsets"              { yylval.sval = new std::string(yytext); return TOKEN_META_ATTR; }
"redefines"            { yylval.sval = new std::string(yytext); return TOKEN_META_ATTR; }

{CUSTOM_DATATYPE}      { yylval.sval = new std::string(yytext); return TOKEN_CUSTOM_DATATYPE; }
{INSTANCE_NAME}        { yylval.sval = new std::string(yytext); return TOKEN_INSTANCE_NAME; }
{CLASS_NAME}           { yylval.sval = new std::string(yytext); return TOKEN_CLASS_NAME; }
{RELATION_NAME}        { yylval.sval = new std::string(yytext); return TOKEN_RELATION_NAME; }

[0-9]+[a-zA-Z_]+       {
    Tonto::g_errorHandler.report_error(yylloc.first_line, yylloc.first_column, yytext,
        "Identificador invalido iniciado com digitos.",
        "Identificadores em Tonto nao podem comecar com numeros. Renomeie iniciando por letra.");
}

.                      {
    std::string s(yytext);
    std::string tip = "Caractere desconhecido ou caractere especial fora de contexto. Remova ou corrija o simbolo.";
    if (s == "\"" || s == "'") tip = "Aspas literais nao sao permitidas na declaracao sintatica de construtos Tonto.";
    Tonto::g_errorHandler.report_error(yylloc.first_line, yylloc.first_column, s,
        "Caractere inesperado na analise sintatica.", tip);
}

%%

void reset_lexer_coordinates() {
    current_col = 1;
    yylineno = 1;
}
