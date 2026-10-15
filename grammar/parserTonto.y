%{
#include <iostream>
#include <string>
#include <vector>
#include <sstream>
#include "OntologyModel.hpp"
#include "ErrorHandler.hpp"

extern int yylex();
extern int yylineno;
extern char* yytext;
void yyerror(const char* s);

// Contexto temporário durante o parsing
static Tonto::OntoClass current_class;
static Tonto::DataType current_datatype;
static Tonto::EnumClass current_enum;
static Tonto::GenSet current_genset;
static Tonto::Relation current_relation;
%}

%locations

%union {
    std::string* sval;
    std::vector<std::string>* svec;
    Tonto::Attribute* attr;
    std::vector<Tonto::Attribute>* attr_vec;
    Tonto::Relation* rel;
}

/* Tokens de Palavras Reservadas */
%token TOKEN_PACKAGE
%token TOKEN_IMPORT
%token TOKEN_CLASS
%token TOKEN_GENSET
%token TOKEN_GENERAL
%token TOKEN_SPECIFICS
%token TOKEN_WHERE
%token TOKEN_SPECIALIZES
%token TOKEN_DISJOINT
%token TOKEN_COMPLETE
%token TOKEN_OVERLAPPING
%token TOKEN_INCOMPLETE
%token TOKEN_DATATYPE
%token TOKEN_ENUM
%token TOKEN_RELATION
%token TOKEN_FUNCTIONAL_COMPLEXES

/* Delimitadores e Operadores */
%token TOKEN_RELATION_LINK    /* -- */
%token TOKEN_COMP_AGG_LEFT     /* <>-- */
%token TOKEN_COMP_AGG_RIGHT    /* --<> */
%token TOKEN_RANGE             /* .. */
%token TOKEN_LBRACE            /* { */
%token TOKEN_RBRACE            /* } */
%token TOKEN_LPAREN            /* ( */
%token TOKEN_RPAREN            /* ) */
%token TOKEN_LBRACKET          /* [ */
%token TOKEN_RBRACKET          /* ] */
%token TOKEN_STAR              /* * */
%token TOKEN_AT                /* @ */
%token TOKEN_DOT               /* . */
%token TOKEN_COMMA             /* , */
%token TOKEN_COLON             /* : */

/* Tokens de Valores Semânticos */
%token <sval> TOKEN_CLASS_STEREO
%token <sval> TOKEN_RELATION_STEREO
%token <sval> TOKEN_NATIVE_TYPE
%token <sval> TOKEN_META_ATTR
%token <sval> TOKEN_CLASS_NAME
%token <sval> TOKEN_RELATION_NAME
%token <sval> TOKEN_INSTANCE_NAME
%token <sval> TOKEN_CUSTOM_DATATYPE
%token <sval> TOKEN_MULTIPLICITY

/* Tipos de não-terminais */
%type <sval> any_name class_identifier attr_identifier rel_identifier stereo_identifier
%type <sval> type_specifier rel_operator cardinality card_bound opt_cardinality
%type <sval> opt_rel_name opt_specializes restriction_kw
%type <svec> identifier_list opt_meta_attributes meta_attr_list opt_restrictions
%type <attr> attribute_decl
%type <rel> internal_relation_decl external_relation_decl

%start ontology_specification

%%

ontology_specification:
      package_declaration_list
    | element_list
    ;

package_declaration_list:
      package_declaration_list package_declaration
    | package_declaration
    ;

package_declaration:
      TOKEN_PACKAGE any_name TOKEN_LBRACE {
          Tonto::g_ontology.enter_package(*$2, @1.first_line, @1.first_column);
          delete $2;
      } element_list TOKEN_RBRACE
    | TOKEN_PACKAGE any_name {
          Tonto::g_ontology.enter_package(*$2, @1.first_line, @1.first_column);
          delete $2;
      } element_list
    ;

element_list:
      element_list element
    | /* vazio */
    ;

element:
      class_declaration
    | datatype_declaration
    | enum_declaration
    | genset_declaration
    | external_relation_decl {
          if ($1) {
              Tonto::g_ontology.add_relation(*$1);
              delete $1;
          }
      }
    | instance_declaration
    | import_declaration
    | error {
          // Recuperação sintática a nível de construto
          yyerrok;
      }
    ;

import_declaration:
      TOKEN_IMPORT any_name
      {
          delete $2;
      }
    ;

/* ==============================================================
   DECLARAÇÃO DE CLASSES E SEUS MEMBROS INTERNOS
   ============================================================== */

class_declaration:
      stereo_identifier class_identifier opt_specializes TOKEN_LBRACE {
          current_class = Tonto::OntoClass();
          current_class.name = *$2;
          current_class.stereotype = *$1;
          if ($3) { current_class.parent_class = *$3; delete $3; }
          current_class.line = @2.first_line;
          current_class.col = @2.first_column;
          delete $1; delete $2;
      } opt_class_body TOKEN_RBRACE {
          Tonto::g_ontology.add_class(current_class);
      }
    | stereo_identifier class_identifier opt_specializes {
          Tonto::OntoClass cls;
          cls.name = *$2;
          cls.stereotype = *$1;
          if ($3) { cls.parent_class = *$3; delete $3; }
          cls.line = @2.first_line;
          cls.col = @2.first_column;
          Tonto::g_ontology.add_class(cls);
          delete $1; delete $2;
      }
    | TOKEN_CLASS class_identifier opt_specializes TOKEN_LBRACE {
          current_class = Tonto::OntoClass();
          current_class.name = *$2;
          current_class.stereotype = "class";
          if ($3) { current_class.parent_class = *$3; delete $3; }
          current_class.line = @2.first_line;
          current_class.col = @2.first_column;
          delete $2;
      } opt_class_body TOKEN_RBRACE {
          Tonto::g_ontology.add_class(current_class);
      }
    | TOKEN_CLASS class_identifier opt_specializes {
          Tonto::OntoClass cls;
          cls.name = *$2;
          cls.stereotype = "class";
          if ($3) { cls.parent_class = *$3; delete $3; }
          cls.line = @2.first_line;
          cls.col = @2.first_column;
          Tonto::g_ontology.add_class(cls);
          delete $2;
      }
    ;

opt_specializes:
      TOKEN_SPECIALIZES class_identifier {
          $$ = $2;
      }
    | /* vazio */ {
          $$ = nullptr;
      }
    ;

opt_class_body:
      class_body
    | /* vazio */
    ;

class_body:
      class_body class_member
    | class_member
    ;

class_member:
      attribute_decl {
          if ($1) {
              current_class.attributes.push_back(*$1);
              delete $1;
          }
      }
    | internal_relation_decl {
          if ($1) {
              current_class.internal_relations.push_back(*$1);
              delete $1;
          }
      }
    | meta_attr_decl
    | error {
          yyerrok;
      }
    ;

attribute_decl:
      attr_identifier TOKEN_COLON type_specifier opt_meta_attributes {
          Tonto::Attribute* attr = new Tonto::Attribute();
          attr->name = *$1;
          attr->type = *$3;
          if ($4) {
              attr->meta_attributes = *$4;
              delete $4;
          }
          attr->line = @1.first_line;
          attr->col = @1.first_column;
          delete $1; delete $3;
          $$ = attr;
      }
    ;

meta_attr_decl:
      TOKEN_META_ATTR {
          delete $1;
      }
    ;

opt_meta_attributes:
      TOKEN_LBRACE meta_attr_list TOKEN_RBRACE {
          $$ = $2;
      }
    | /* vazio */ {
          $$ = nullptr;
      }
    ;

meta_attr_list:
      meta_attr_list TOKEN_COMMA TOKEN_META_ATTR {
          $1->push_back(*$3);
          delete $3;
          $$ = $1;
      }
    | meta_attr_list TOKEN_META_ATTR {
          $1->push_back(*$2);
          delete $2;
          $$ = $1;
      }
    | TOKEN_META_ATTR {
          std::vector<std::string>* vec = new std::vector<std::string>();
          vec->push_back(*$1);
          delete $1;
          $$ = vec;
      }
    ;

/* ==============================================================
   DECLARAÇÃO DE TIPOS DE DADOS E ENUMS
   ============================================================== */

datatype_declaration:
      TOKEN_DATATYPE class_identifier TOKEN_LBRACE {
          current_datatype = Tonto::DataType();
          current_datatype.name = *$2;
          current_datatype.line = @2.first_line;
          current_datatype.col = @2.first_column;
          delete $2;
      } opt_datatype_body TOKEN_RBRACE {
          Tonto::g_ontology.add_datatype(current_datatype);
      }
    | TOKEN_CUSTOM_DATATYPE {
          Tonto::DataType dt;
          dt.name = *$1;
          dt.line = @1.first_line;
          dt.col = @1.first_column;
          Tonto::g_ontology.add_datatype(dt);
          delete $1;
      }
    ;

opt_datatype_body:
      datatype_body
    | /* vazio */
    ;

datatype_body:
      datatype_body attribute_decl {
          if ($2) {
              current_datatype.fields.push_back(*$2);
              delete $2;
          }
      }
    | attribute_decl {
          if ($1) {
              current_datatype.fields.push_back(*$1);
              delete $1;
          }
      }
    ;

enum_declaration:
      TOKEN_ENUM class_identifier TOKEN_LBRACE identifier_list TOKEN_RBRACE {
          Tonto::EnumClass en;
          en.name = *$2;
          if ($4) {
              en.literals = *$4;
              delete $4;
          }
          en.line = @2.first_line;
          en.col = @2.first_column;
          Tonto::g_ontology.add_enum(en);
          delete $2;
      }
    ;

identifier_list:
      identifier_list TOKEN_COMMA any_name {
          $1->push_back(*$3);
          delete $3;
          $$ = $1;
      }
    | any_name {
          std::vector<std::string>* vec = new std::vector<std::string>();
          vec->push_back(*$1);
          delete $1;
          $$ = vec;
      }
    ;

/* ==============================================================
   GENERALIZAÇÕES (GENERALIZATION SETS / GENSET)
   ============================================================== */

genset_declaration:
      opt_restrictions TOKEN_GENSET class_identifier TOKEN_LBRACE {
          current_genset = Tonto::GenSet();
          current_genset.name = *$3;
          if ($1) {
              current_genset.restrictions = *$1;
              delete $1;
          }
          current_genset.is_inline = false;
          current_genset.line = @3.first_line;
          current_genset.col = @3.first_column;
          delete $3;
      } genset_body TOKEN_RBRACE {
          Tonto::g_ontology.add_genset(current_genset);
      }
    | opt_restrictions TOKEN_GENSET class_identifier TOKEN_WHERE identifier_list TOKEN_SPECIALIZES class_identifier {
          Tonto::GenSet gs;
          gs.name = *$3;
          if ($1) {
              gs.restrictions = *$1;
              delete $1;
          }
          if ($5) {
              gs.specific_classes = *$5;
              delete $5;
          }
          gs.general_class = *$7;
          gs.is_inline = true;
          gs.line = @3.first_line;
          gs.col = @3.first_column;
          Tonto::g_ontology.add_genset(gs);
          delete $3; delete $7;
      }
    ;

opt_restrictions:
      opt_restrictions restriction_kw {
          $1->push_back(*$2);
          delete $2;
          $$ = $1;
      }
    | /* vazio */ {
          $$ = new std::vector<std::string>();
      }
    ;

restriction_kw:
      TOKEN_DISJOINT    { $$ = new std::string("disjoint"); }
    | TOKEN_COMPLETE    { $$ = new std::string("complete"); }
    | TOKEN_OVERLAPPING { $$ = new std::string("overlapping"); }
    | TOKEN_INCOMPLETE  { $$ = new std::string("incomplete"); }
    ;

genset_body:
      genset_body genset_member
    | genset_member
    ;

genset_member:
      TOKEN_GENERAL class_identifier {
          current_genset.general_class = *$2;
          delete $2;
      }
    | TOKEN_SPECIFICS identifier_list {
          if ($2) {
              current_genset.specific_classes = *$2;
              delete $2;
          }
      }
    | restriction_kw {
          current_genset.restrictions.push_back(*$1);
          delete $1;
      }
    ;

/* ==============================================================
   RELAÇÕES INTERNAS E EXTERNAS COM OPERADORES E CARDINALIDADES
   ============================================================== */

internal_relation_decl:
      TOKEN_AT stereo_identifier opt_cardinality rel_operator opt_cardinality class_identifier opt_meta_attributes {
          Tonto::Relation* r = new Tonto::Relation();
          r->stereotype = *$2;
          r->is_internal = true;
          if ($3) { r->source_cardinality = *$3; delete $3; }
          r->rel_operator = *$4;
          if ($5) { r->target_cardinality = *$5; delete $5; }
          r->target_class = *$6;
          if ($7) { r->meta_attributes = *$7; delete $7; }
          r->line = @2.first_line;
          r->col = @2.first_column;
          delete $2; delete $4; delete $6;
          $$ = r;
      }
    | stereo_identifier opt_rel_name opt_cardinality rel_operator opt_cardinality class_identifier opt_meta_attributes {
          Tonto::Relation* r = new Tonto::Relation();
          r->stereotype = *$1;
          if ($2) { r->name = *$2; delete $2; }
          r->is_internal = true;
          if ($3) { r->source_cardinality = *$3; delete $3; }
          r->rel_operator = *$4;
          if ($5) { r->target_cardinality = *$5; delete $5; }
          r->target_class = *$6;
          if ($7) { r->meta_attributes = *$7; delete $7; }
          r->line = @1.first_line;
          r->col = @1.first_column;
          delete $1; delete $4; delete $6;
          $$ = r;
      }
    | opt_cardinality rel_operator opt_cardinality class_identifier opt_meta_attributes {
          Tonto::Relation* r = new Tonto::Relation();
          r->is_internal = true;
          if ($1) { r->source_cardinality = *$1; delete $1; }
          r->rel_operator = *$2;
          if ($3) { r->target_cardinality = *$3; delete $3; }
          r->target_class = *$4;
          if ($5) { r->meta_attributes = *$5; delete $5; }
          r->line = @2.first_line;
          r->col = @2.first_column;
          delete $2; delete $4;
          $$ = r;
      }
    ;

external_relation_decl:
      TOKEN_AT stereo_identifier TOKEN_RELATION opt_rel_name class_identifier opt_cardinality rel_operator opt_cardinality class_identifier opt_meta_attributes {
          Tonto::Relation* r = new Tonto::Relation();
          r->stereotype = *$2;
          if ($4) { r->name = *$4; delete $4; }
          r->source_class = *$5;
          if ($6) { r->source_cardinality = *$6; delete $6; }
          r->rel_operator = *$7;
          if ($8) { r->target_cardinality = *$8; delete $8; }
          r->target_class = *$9;
          if ($10) { r->meta_attributes = *$10; delete $10; }
          r->is_internal = false;
          r->line = @2.first_line;
          r->col = @2.first_column;
          delete $2; delete $5; delete $7; delete $9;
          $$ = r;
      }
    | stereo_identifier opt_rel_name opt_cardinality TOKEN_LPAREN class_identifier TOKEN_RPAREN rel_operator opt_cardinality TOKEN_LPAREN class_identifier TOKEN_RPAREN opt_meta_attributes {
          Tonto::Relation* r = new Tonto::Relation();
          r->stereotype = *$1;
          if ($2) { r->name = *$2; delete $2; }
          if ($3) { r->source_cardinality = *$3; delete $3; }
          r->source_class = *$5;
          r->rel_operator = *$7;
          if ($8) { r->target_cardinality = *$8; delete $8; }
          r->target_class = *$10;
          if ($12) { r->meta_attributes = *$12; delete $12; }
          r->is_internal = false;
          r->line = @1.first_line;
          r->col = @1.first_column;
          delete $1; delete $5; delete $7; delete $10;
          $$ = r;
      }
    | stereo_identifier opt_rel_name opt_cardinality class_identifier rel_operator opt_cardinality class_identifier opt_meta_attributes {
          Tonto::Relation* r = new Tonto::Relation();
          r->stereotype = *$1;
          if ($2) { r->name = *$2; delete $2; }
          if ($3) { r->source_cardinality = *$3; delete $3; }
          r->source_class = *$4;
          r->rel_operator = *$5;
          if ($6) { r->target_cardinality = *$6; delete $6; }
          r->target_class = *$7;
          if ($8) { r->meta_attributes = *$8; delete $8; }
          r->is_internal = false;
          r->line = @1.first_line;
          r->col = @1.first_column;
          delete $1; delete $4; delete $5; delete $7;
          $$ = r;
      }
    ;

opt_rel_name:
      rel_identifier { $$ = $1; }
    | class_identifier { $$ = $1; }
    | /* vazio */ { $$ = nullptr; }
    ;

rel_operator:
      TOKEN_RELATION_LINK    { $$ = new std::string("--"); }
    | TOKEN_COMP_AGG_LEFT    { $$ = new std::string("<>--"); }
    | TOKEN_COMP_AGG_RIGHT   { $$ = new std::string("--<>"); }
    | TOKEN_RANGE            { $$ = new std::string(".."); }
    ;

opt_cardinality:
      cardinality { $$ = $1; }
    | /* vazio */ { $$ = nullptr; }
    ;

cardinality:
      TOKEN_LBRACKET card_bound TOKEN_RBRACKET {
          $$ = new std::string("[" + *$2 + "]");
          delete $2;
      }
    | TOKEN_LBRACKET card_bound TOKEN_RANGE card_bound TOKEN_RBRACKET {
          $$ = new std::string("[" + *$2 + ".." + *$4 + "]");
          delete $2; delete $4;
      }
    ;

card_bound:
      TOKEN_MULTIPLICITY { $$ = $1; }
    | TOKEN_STAR         { $$ = new std::string("*"); }
    ;

/* ==============================================================
   DECLARAÇÃO DE INSTÂNCIAS (INDIVÍDUOS)
   ============================================================== */

instance_declaration:
      TOKEN_INSTANCE_NAME {
          Tonto::Instance inst;
          inst.name = *$1;
          inst.line = @1.first_line;
          inst.col = @1.first_column;
          Tonto::g_ontology.add_instance(inst);
          delete $1;
      }
    ;

/* ==============================================================
   AUXILIARES DE IDENTIFICADORES E TIPOS
   ============================================================== */

any_name:
      class_identifier { $$ = $1; }
    | attr_identifier  { $$ = $1; }
    ;

class_identifier:
      TOKEN_CLASS_NAME { $$ = $1; }
    ;

attr_identifier:
      TOKEN_RELATION_NAME { $$ = $1; }
    ;

rel_identifier:
      TOKEN_RELATION_NAME { $$ = $1; }
    ;

stereo_identifier:
      TOKEN_CLASS_STEREO    { $$ = $1; }
    | TOKEN_RELATION_STEREO { $$ = $1; }
    ;

type_specifier:
      TOKEN_NATIVE_TYPE {
          Tonto::g_ontology.record_native_type(*$1);
          $$ = $1;
      }
    | TOKEN_CUSTOM_DATATYPE {
          $$ = $1;
      }
    | class_identifier {
          $$ = $1;
      }
    ;

%%

void yyerror(const char* s) {
    std::string token = (yytext ? yytext : "");
    std::string msg = (s ? s : "Erro de sintaxe");
    Tonto::g_errorHandler.report_generic_error(yylloc.first_line, yylloc.first_column, msg + " no token '" + token + "'");
}
