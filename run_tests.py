#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Analisador Sintático TONTO - Runner e Validador de Testes (Python / C++)
Executa a análise sintática de ontologias escritas em TONTO, gerando:
(1) Tabela de Síntese dos construtos encontrados
(2) Relatório de Erros da Ontologia com sugestões de tratamento
Compatível com Windows, Linux e macOS.
"""

import sys
import os
import re
from typing import List, Dict, Any, Optional

class Attribute:
    def __init__(self, name: str, attr_type: str, meta: List[str] = None, line: int = 0, col: int = 0):
        self.name = name
        self.attr_type = attr_type
        self.meta = meta or []
        self.line = line
        self.col = col

class Relation:
    def __init__(self, name: str = "", stereo: str = "", is_internal: bool = False,
                 source: str = "", target: str = "", source_mult: str = "",
                 target_mult: str = "", op: str = "--", meta: List[str] = None,
                 line: int = 0, col: int = 0):
        self.name = name
        self.stereo = stereo
        self.is_internal = is_internal
        self.source = source
        self.target = target
        self.source_mult = source_mult
        self.target_mult = target_mult
        self.op = op
        self.meta = meta or []
        self.line = line
        self.col = col

class OntoClass:
    def __init__(self, name: str, stereo: str = "class", parent: str = "", line: int = 0, col: int = 0):
        self.name = name
        self.stereo = stereo
        self.parent = parent
        self.attributes: List[Attribute] = []
        self.internal_relations: List[Relation] = []
        self.line = line
        self.col = col

class DataType:
    def __init__(self, name: str, line: int = 0, col: int = 0):
        self.name = name
        self.fields: List[Attribute] = []
        self.line = line
        self.col = col

class EnumClass:
    def __init__(self, name: str, literals: List[str] = None, line: int = 0, col: int = 0):
        self.name = name
        self.literals = literals or []
        self.line = line
        self.col = col

class GenSet:
    def __init__(self, name: str, general: str = "", specifics: List[str] = None,
                 restrictions: List[str] = None, is_inline: bool = False, line: int = 0, col: int = 0):
        self.name = name
        self.general = general
        self.specifics = specifics or []
        self.restrictions = restrictions or []
        self.is_inline = is_inline
        self.line = line
        self.col = col

class Package:
    def __init__(self, name: str, line: int = 0, col: int = 0):
        self.name = name
        self.line = line
        self.col = col
        self.classes: List[OntoClass] = []
        self.datatypes: List[DataType] = []
        self.enums: List[EnumClass] = []
        self.gensets: List[GenSet] = []
        self.external_relations: List[Relation] = []
        self.instances: List[str] = []

class SyntaxErrorRecord:
    def __init__(self, line: int, col: int, token: str, message: str, suggestion: str):
        self.line = line
        self.col = col
        self.token = token
        self.message = message
        self.suggestion = suggestion

class TontoParser:
    CLASS_STEREOTYPES = {
        "kind", "subkind", "role", "phase", "category", "mixin", "phaseMixin",
        "roleMixin", "collective", "quantity", "mode", "intrinsicMode",
        "extrinsicMode", "quality", "historicalRole", "historicalRoleMixin",
        "event", "situation", "process", "relator"
    }

    RELATION_STEREOTYPES = {
        "material", "derivation", "comparative", "mediation", "characterization",
        "subCollectionOf", "subQualityOf", "instantiation", "externalDependence",
        "componentOf", "memberOf", "termination", "participational", "participation",
        "historicalDependence", "creation", "manifestation", "bringsAbout", "triggers",
        "composition", "aggregation", "inherence", "value", "formal", "constitution"
    }

    RESTRICTIONS = {"disjoint", "complete", "overlapping", "incomplete"}

    def __init__(self):
        self.packages: List[Package] = []
        self.current_package: Package = Package("default", 1, 1)
        self.packages.append(self.current_package)
        self.errors: List[SyntaxErrorRecord] = []

    def parse_file(self, filepath: str):
        with open(filepath, "r", encoding="utf-8", errors="replace") as f:
            code = f.read()
        return self.parse_text(code, filepath)

    def parse_text(self, code: str, filename: str = ""):
        self.packages = []
        self.current_package = Package("default", 1, 1)
        self.packages.append(self.current_package)
        self.errors = []

        lines = code.splitlines()
        
        # Tokenizer básico preservando coordenadas
        tokens = self._tokenize(code)
        idx = 0
        n = len(tokens)

        while idx < n:
            tok = tokens[idx]
            ttype, tval, tline, tcol = tok

            if tval == "package":
                idx += 1
                if idx < n and tokens[idx][0] in ("CLASS_NAME", "RELATION_NAME", "IDENT"):
                    pkg_name = tokens[idx][1]
                    idx += 1
                    pkg = Package(pkg_name, tline, tcol)
                    self.current_package = pkg
                    self.packages.append(pkg)
                    if idx < n and tokens[idx][1] == "{":
                        idx += 1
                else:
                    self.errors.append(SyntaxErrorRecord(
                        tline, tcol, tval,
                        "Declaracao de pacote incompleta ou invalida.",
                        "Especifique o nome do pacote logo apos a palavra 'package', por exemplo: 'package MeuModelo {'"
                    ))
                    idx += 1

            elif tval == "datatype":
                idx += 1
                if idx < n and tokens[idx][0] in ("CLASS_NAME", "IDENT"):
                    dt_name = tokens[idx][1]
                    idx += 1
                    dt = DataType(dt_name, tline, tcol)
                    if idx < n and tokens[idx][1] == "{":
                        idx += 1
                        while idx < n and tokens[idx][1] != "}":
                            if tokens[idx][1] == ":":
                                idx += 1
                                continue
                            if idx + 2 < n and tokens[idx+1][1] == ":":
                                fname = tokens[idx][1]
                                ftype = tokens[idx+2][1]
                                dt.fields.append(Attribute(fname, ftype, [], tokens[idx][2], tokens[idx][3]))
                                idx += 3
                            else:
                                idx += 1
                        if idx < n and tokens[idx][1] == "}":
                            idx += 1
                    self.current_package.datatypes.append(dt)
                else:
                    self.errors.append(SyntaxErrorRecord(
                        tline, tcol, tval,
                        "Nome do tipo de dado (datatype) ausente ou invalido.",
                        "Declare com 'datatype NomeTipo { campo: tipo }'."
                    ))
                    idx += 1

            elif tval == "enum":
                idx += 1
                if idx < n and tokens[idx][0] in ("CLASS_NAME", "IDENT"):
                    en_name = tokens[idx][1]
                    idx += 1
                    en = EnumClass(en_name, [], tline, tcol)
                    if idx < n and tokens[idx][1] == "{":
                        idx += 1
                        while idx < n and tokens[idx][1] != "}":
                            if tokens[idx][1] != ",":
                                en.literals.append(tokens[idx][1])
                            idx += 1
                        if idx < n and tokens[idx][1] == "}":
                            idx += 1
                    self.current_package.enums.append(en)
                else:
                    self.errors.append(SyntaxErrorRecord(
                        tline, tcol, tval,
                        "Nome da classe enumerada ausente.",
                        "Utilize o formato 'enum NomeEnum { Item1, Item2, ... }'."
                    ))
                    idx += 1

            elif tval in self.RESTRICTIONS or tval == "genset":
                # Generalização
                restrictions = []
                while idx < n and tokens[idx][1] in self.RESTRICTIONS:
                    restrictions.append(tokens[idx][1])
                    idx += 1
                if idx < n and tokens[idx][1] == "genset":
                    idx += 1
                    if idx < n and tokens[idx][0] in ("CLASS_NAME", "IDENT"):
                        gs_name = tokens[idx][1]
                        idx += 1
                        gs = GenSet(gs_name, restrictions=restrictions, line=tline, col=tcol)
                        
                        # Formato inline: genset Name where X, Y specializes Z
                        if idx < n and tokens[idx][1] == "where":
                            gs.is_inline = True
                            idx += 1
                            while idx < n and tokens[idx][1] != "specializes":
                                if tokens[idx][1] != ",":
                                    gs.specifics.append(tokens[idx][1])
                                idx += 1
                            if idx < n and tokens[idx][1] == "specializes":
                                idx += 1
                                if idx < n:
                                    gs.general = tokens[idx][1]
                                    idx += 1
                            self.current_package.gensets.append(gs)

                        # Formato em bloco: genset Name { general ... specifics ... }
                        elif idx < n and tokens[idx][1] == "{":
                            idx += 1
                            closed = False
                            while idx < n and tokens[idx][1] != "}":
                                if tokens[idx][1] == "general":
                                    idx += 1
                                    if idx < n:
                                        gs.general = tokens[idx][1]
                                        idx += 1
                                elif tokens[idx][1] == "specifics":
                                    idx += 1
                                    while idx < n and tokens[idx][1] not in ("}", "general", "disjoint", "complete", "overlapping", "incomplete"):
                                        if tokens[idx][1] != ",":
                                            gs.specifics.append(tokens[idx][1])
                                        idx += 1
                                elif tokens[idx][1] in self.RESTRICTIONS:
                                    if tokens[idx][1] not in gs.restrictions:
                                        gs.restrictions.append(tokens[idx][1])
                                    idx += 1
                                else:
                                    idx += 1
                            if idx < n and tokens[idx][1] == "}":
                                closed = True
                                idx += 1
                            if not closed:
                                self.errors.append(SyntaxErrorRecord(
                                    tline, tcol, gs_name,
                                    "Chave '}' de fechamento do bloco genset ausente.",
                                    "Adicione '}' para encerrar a definicao do genset."
                                ))
                            self.current_package.gensets.append(gs)
                        else:
                            self.current_package.gensets.append(gs)
                    else:
                        self.errors.append(SyntaxErrorRecord(
                            tline, tcol, tval,
                            "Identificador do genset ausente.",
                            "Forneca um nome para o genset, ex: 'genset MeuGenset { ... }'."
                        ))
                        idx += 1
                else:
                    idx += 1

            elif tval == "@" or (tval in self.RELATION_STEREOTYPES and idx + 1 < n and tokens[idx+1][1] in ("relation", "--", "<>--", "--<>") or (idx+2 < n and tokens[idx+2][1] in ("--", "<>--", "--<>"))):
                # Relação externa
                stereo = ""
                if tval == "@":
                    idx += 1
                    if idx < n:
                        stereo = tokens[idx][1]
                        idx += 1
                elif tval in self.RELATION_STEREOTYPES:
                    stereo = tval
                    idx += 1

                rel_name = ""
                if idx < n and tokens[idx][1] == "relation":
                    idx += 1
                
                # Verifica se há nome de relação ou classe
                src = ""
                src_mult = ""
                op = "--"
                tgt_mult = ""
                tgt = ""

                # parsing simplificado de relacao externa
                while idx < n and tokens[idx][1] not in ("\n", ";", "}") and tokens[idx][1] not in self.CLASS_STEREOTYPES and tokens[idx][1] != "@":
                    cur = tokens[idx][1]
                    if cur in ("--", "<>--", "--<>", ".."):
                        op = cur
                    elif cur.startswith("["):
                        if not op or op == "--" and not src:
                            src_mult = cur
                        else:
                            tgt_mult = cur
                    elif cur.isupper() or tokens[idx][0] == "CLASS_NAME":
                        if not src:
                            src = cur
                        else:
                            tgt = cur
                    elif cur.islower() and not rel_name:
                        rel_name = cur
                    idx += 1

                if src or tgt:
                    r = Relation(rel_name, stereo, False, src, tgt, src_mult, tgt_mult, op, line=tline, col=tcol)
                    self.current_package.external_relations.append(r)
                else:
                    self.errors.append(SyntaxErrorRecord(
                        tline, tcol, stereo,
                        "Declaracao de relacao malformada ou incompleta.",
                        "Especifique as classes conectadas e os operadores relacionais, ex: '@mediation relation Contrato [1..*] -- [1] Empregado'."
                    ))

            elif tval in self.CLASS_STEREOTYPES or tval == "class":
                # Declaração de Classe
                stereo = tval
                idx += 1
                if idx < n and tokens[idx][0] in ("CLASS_NAME", "IDENT"):
                    cls_name = tokens[idx][1]
                    idx += 1
                    parent = ""
                    if idx < n and tokens[idx][1] == "specializes":
                        idx += 1
                        if idx < n:
                            parent = tokens[idx][1]
                            idx += 1
                    
                    cls = OntoClass(cls_name, stereo, parent, tline, tcol)

                    if idx < n and tokens[idx][1] == "{":
                        idx += 1
                        while idx < n and tokens[idx][1] != "}":
                            # Verifica relações internas
                            if tokens[idx][1] in ("@", "<>--", "--<>", "--", "..") or (tokens[idx][1].startswith("[") and idx + 1 < n and tokens[idx+1][1] in ("<>--", "--<>", "--", "..")):
                                # relacao interna
                                r_stereo = ""
                                if tokens[idx][1] == "@":
                                    idx += 1
                                    if idx < n:
                                        r_stereo = tokens[idx][1]
                                        idx += 1
                                s_mult = ""
                                if idx < n and tokens[idx][1].startswith("["):
                                    s_mult = tokens[idx][1]
                                    idx += 1
                                r_op = "<>--"
                                if idx < n and tokens[idx][1] in ("--", "<>--", "--<>", ".."):
                                    r_op = tokens[idx][1]
                                    idx += 1
                                t_mult = ""
                                if idx < n and tokens[idx][1].startswith("["):
                                    t_mult = tokens[idx][1]
                                    idx += 1
                                t_class = ""
                                if idx < n and tokens[idx][0] in ("CLASS_NAME", "IDENT"):
                                    t_class = tokens[idx][1]
                                    idx += 1
                                cls.internal_relations.append(Relation("", r_stereo, True, cls_name, t_class, s_mult, t_mult, r_op, line=tokens[idx-1][2], col=tokens[idx-1][3]))
                            elif idx + 1 < n and tokens[idx+1][1] == ":":
                                attr_name = tokens[idx][1]
                                attr_line = tokens[idx][2]
                                attr_col = tokens[idx][3]
                                idx += 2
                                if idx < n and tokens[idx][1] not in ("}", "\n", ";"):
                                    attr_type = tokens[idx][1]
                                    idx += 1
                                    meta = []
                                    if idx < n and tokens[idx][1] == "{":
                                        idx += 1
                                        while idx < n and tokens[idx][1] != "}":
                                            if tokens[idx][1] != ",":
                                                meta.append(tokens[idx][1])
                                            idx += 1
                                        if idx < n and tokens[idx][1] == "}":
                                            idx += 1
                                    cls.attributes.append(Attribute(attr_name, attr_type, meta, attr_line, attr_col))
                                else:
                                    self.errors.append(SyntaxErrorRecord(
                                        attr_line, attr_col, attr_name,
                                        f"Tipo do atributo '{attr_name}' ausente na classe '{cls_name}'.",
                                        "Especifique um tipo valido, como 'string', 'int', 'date' ou um tipo personalizado."
                                    ))
                            else:
                                idx += 1
                        if idx < n and tokens[idx][1] == "}":
                            idx += 1
                    
                    self.current_package.classes.append(cls)
                else:
                    self.errors.append(SyntaxErrorRecord(
                        tline, tcol, tval,
                        f"Identificador de classe ausente ou invalido apos '{tval}'.",
                        "Nomes de classe devem iniciar com letra maiuscula e nao conter caracteres invalidos."
                    ))
                    idx += 1

            elif ttype == "CUSTOM_DATATYPE":
                self.current_package.datatypes.append(DataType(tval, tline, tcol))
                idx += 1

            elif ttype == "INSTANCE_NAME":
                self.current_package.instances.append(tval)
                idx += 1

            elif ttype == "ERROR_DIGIT_ID":
                self.errors.append(SyntaxErrorRecord(
                    tline, tcol, tval,
                    "Identificador invalido iniciado com digitos.",
                    "Identificadores em Tonto nao podem comecar com numeros. Altere iniciando por letra."
                ))
                idx += 1

            elif ttype == "ERROR_CHAR":
                self.errors.append(SyntaxErrorRecord(
                    tline, tcol, tval,
                    "Caractere especial inesperado na analise sintatica.",
                    "Remova o caractere ou verifique a pontuacao do modelo."
                ))
                idx += 1

            elif tval == "}":
                # Fechamento de pacote ou escopo
                idx += 1
            else:
                idx += 1

        # Limpeza de pacotes vazios redundantes
        self.packages = [p for p in self.packages if p.name != "default" or p.classes or p.datatypes or p.enums or p.gensets or p.external_relations or p.instances]
        if not self.packages:
            self.packages = [self.current_package]

    def _tokenize(self, text: str):
        tokens = []
        lines = text.splitlines(True)
        
        # Regex tokens
        re_comment_line = re.compile(r"^//.*")
        re_mult = re.compile(r"^\[([0-9]+|\*|\.\.|[0-9]+\.\.[0-9]+|[0-9]+\.\.\*)\]")
        re_num_id = re.compile(r"^[0-9]+[a-zA-Z_]+")
        re_custom_dt = re.compile(r"^[a-zA-Z]+DataType\b")
        re_instance = re.compile(r"^[a-zA-Z][a-zA-Z_]*[0-9]+\b")
        re_class_name = re.compile(r"^[A-Z][a-zA-Z0-9_]*\b")
        re_rel_name = re.compile(r"^[a-z][a-zA-Z0-9_]*\b")
        re_symbols = re.compile(r"^(<>--|--<>|--|\.\.|[{}(),:@])")

        for line_num, line in enumerate(lines, 1):
            col = 1
            idx = 0
            n = len(line)
            while idx < n:
                # Espaços
                if line[idx].isspace():
                    col += 1
                    idx += 1
                    continue

                sub = line[idx:]

                # Comentário de linha
                if sub.startswith("//"):
                    break

                # Cardinalidades [1..*], [1], etc.
                m = re_mult.match(sub)
                if m:
                    tokens.append(("CARDINALITY", m.group(0), line_num, col))
                    length = len(m.group(0))
                    idx += length
                    col += length
                    continue

                # Símbolos compostos e simples
                m = re_symbols.match(sub)
                if m:
                    tokens.append(("SYMBOL", m.group(0), line_num, col))
                    length = len(m.group(0))
                    idx += length
                    col += length
                    continue

                # Identificador inválido iniciado com número
                m = re_num_id.match(sub)
                if m:
                    tokens.append(("ERROR_DIGIT_ID", m.group(0), line_num, col))
                    length = len(m.group(0))
                    idx += length
                    col += length
                    continue

                # Custom datatype
                m = re_custom_dt.match(sub)
                if m:
                    tokens.append(("CUSTOM_DATATYPE", m.group(0), line_num, col))
                    length = len(m.group(0))
                    idx += length
                    col += length
                    continue

                # Instância (termina com número)
                m = re_instance.match(sub)
                if m:
                    tokens.append(("INSTANCE_NAME", m.group(0), line_num, col))
                    length = len(m.group(0))
                    idx += length
                    col += length
                    continue

                # Nome de classe ou palavra-chave
                m = re_class_name.match(sub)
                if m:
                    tokens.append(("CLASS_NAME", m.group(0), line_num, col))
                    length = len(m.group(0))
                    idx += length
                    col += length
                    continue

                # Nome de relação / palavra-chave minúscula
                m = re_rel_name.match(sub)
                if m:
                    tokens.append(("RELATION_NAME", m.group(0), line_num, col))
                    length = len(m.group(0))
                    idx += length
                    col += length
                    continue

                # Caractere não reconhecido
                tokens.append(("ERROR_CHAR", line[idx], line_num, col))
                idx += 1
                col += 1

        return tokens

    def print_summary_table(self):
        print("\n" + "=" * 90)
        print(f"{'TABELA DE SINTESE DOS CONSTRUTOS DA ONTOLOGIA':^90}")
        print("=" * 90)

        total_pkgs = len(self.packages)
        total_classes = sum(len(p.classes) for p in self.packages)
        total_attrs = sum(len(c.attributes) for p in self.packages for c in p.classes) + sum(len(d.fields) for p in self.packages for d in p.datatypes)
        total_internal_rels = sum(len(c.internal_relations) for p in self.packages for c in p.classes)
        total_ext_rels = sum(len(p.external_relations) for p in self.packages)
        total_gensets = sum(len(p.gensets) for p in self.packages)
        total_dts = sum(len(p.datatypes) for p in self.packages)
        total_enums = sum(len(p.enums) for p in self.packages)
        total_insts = sum(len(p.instances) for p in self.packages)

        print("\n[1] RESUMO QUANTITATIVO GLOBAL")
        print("-" * 90)
        print(f"{'CATEGORIA DO CONSTRUTO':<50}{'QUANTIDADE'}")
        print("-" * 90)
        print(f"{'Pacotes (Packages)':<50}{total_pkgs}")
        print(f"{'Classes Ontologicas':<50}{total_classes}")
        print(f"{'Atributos Declarados':<50}{total_attrs}")
        print(f"{'Relacoes Internas (escopo de classe)':<50}{total_internal_rels}")
        print(f"{'Relacoes Externas (escopo global)':<50}{total_ext_rels}")
        print(f"{'Conjuntos de Generalizacao (Gensets)':<50}{total_gensets}")
        print(f"{'Novos Tipos de Dados (DataTypes)':<50}{total_dts}")
        print(f"{'Classes Enumeradas (Enums)':<50}{total_enums}")
        print(f"{'Instancias de Individuos':<50}{total_insts}")
        print("-" * 90)

        print("\n[2] PACOTES E SUAS RESPECTIVAS CLASSES")
        print("-" * 90)
        for pkg in self.packages:
            print(f" Pacote: \"{pkg.name}\" (Linha {pkg.line})")
            if not pkg.classes:
                print("   -> Nenhuma classe declarada explicitamente neste pacote.")
            else:
                print(f"   Classes pertencentes ({len(pkg.classes)}):")
                for cls in pkg.classes:
                    parent_info = f" specializes {cls.parent}" if cls.parent else ""
                    print(f"     • [{cls.stereo}] {cls.name}{parent_info} ({len(cls.attributes)} atributos, {len(cls.internal_relations)} relacoes internas)")
            print()

        print("[3] DETALHAMENTO DE CLASSES E ATRIBUTOS")
        print("-" * 90)
        for pkg in self.packages:
            for cls in pkg.classes:
                parent_info = f" : specializes {cls.parent}" if cls.parent else ""
                print(f" Classe: {cls.name} <<{cls.stereo}>>{parent_info} [Pacote: {pkg.name}]")
                if not cls.attributes:
                    print("   (Sem atributos declarados)")
                else:
                    for attr in cls.attributes:
                        meta_info = f" {{{', '.join(attr.meta)}}}" if attr.meta else ""
                        print(f"   + {attr.name}: {attr.attr_type}{meta_info}")
                if cls.internal_relations:
                    print("   Relacoes Internas:")
                    for r in cls.internal_relations:
                        st = f"@{r.stereo} " if r.stereo else ""
                        print(f"     -> {st}{r.source_mult} {r.op} {r.target_mult} {r.target}")
                print()

        print("[4] RELACOES EXTERNAS (FORA DO ESCOPO DE CLASSE)")
        print("-" * 90)
        has_ext = False
        for pkg in self.packages:
            for r in pkg.external_relations:
                has_ext = True
                st = f"@{r.stereo} relation" if r.stereo else "relation"
                name_str = f" {r.name}" if r.name else ""
                print(f" • {st}{name_str}")
                print(f"     Dominio : {r.source} {r.source_mult}")
                print(f"     Operador: {r.op}")
                print(f"     Imagem  : {r.target} {r.target_mult}")
                if r.meta:
                    print(f"     Metadados: {{ {', '.join(r.meta)} }}")
                print()
        if not has_ext:
            print(" (Nenhuma relacao externa encontrada)\n")

        print("[5] CONJUNTOS DE GENERALIZACAO (GENSETS)")
        print("-" * 90)
        has_genset = False
        for pkg in self.packages:
            for gs in pkg.gensets:
                has_genset = True
                fmt = "Inline" if gs.is_inline else "Bloco"
                print(f" • Genset: \"{gs.name}\" [Formato: {fmt}]")
                print(f"     Classe-Mae (General)   : {gs.general}")
                print(f"     Classes-Filhas (Specifics): {', '.join(gs.specifics)}")
                rests = " ".join(f"[{r}]" for r in gs.restrictions) if gs.restrictions else "nenhuma (padrao)"
                print(f"     Restricoes             : {rests}")
                print()
        if not has_genset:
            print(" (Nenhum genset encontrado)\n")

        print("[6] DECLARACOES DE TIPOS E ENUMS")
        print("-" * 90)
        for pkg in self.packages:
            if pkg.datatypes:
                print(" Novos Tipos Estruturados (DataTypes):")
                for dt in pkg.datatypes:
                    if dt.fields:
                        print(f"   datatype {dt.name} {{")
                        for f in dt.fields:
                            print(f"      {f.name}: {f.attr_type}")
                        print("   }")
                    else:
                        print(f"   {dt.name}")
            if pkg.enums:
                print(" Classes Enumeradas (Enums):")
                for en in pkg.enums:
                    print(f"   enum {en.name} {{ {', '.join(en.literals)} }}")
        print("=" * 90)

    def print_error_report(self):
        print("\n" + "=" * 85)
        print(f"{'RELATORIO DE ERROS DA ONTOLOGIA (DIAGNOSTICO E TRATAMENTO)':^85}")
        print("=" * 85)

        if not self.errors:
            print(" -> NENHUM ERRO SINTATICO ENCONTRADO. Ontologia estruturalmente valida!")
            print("=" * 85)
            return

        print(f" Total de inconformidades detectadas: {len(self.errors)}")
        print("-" * 85)
        for idx, err in enumerate(self.errors, 1):
            print(f"[Erro #{idx}] Linha {err.line}, Coluna {err.col}:")
            if err.token:
                print(f"   Token Encontrado : \"{err.token}\"")
            print(f"   Diagnostico      : {err.message}")
            print(f"   -> Sugestao de Tratamento : {err.suggestion}\n")
        print("=" * 85)

def main():
    print("\n" + "=" * 80)
    print("       ANALISADOR SINTATICO TONTO - RUNNER DE TESTES E VALIDACAO       ")
    print("         UFERSA / Compiladores - Prof. Patricio de Alencar Silva       ")
    print("         Equipe: Gustavo, Mariana e Eduarda                            ")
    print("=" * 80 + "\n")

    parser = TontoParser()

    if len(sys.argv) > 1:
        filepath = sys.argv[1]
        if not os.path.exists(filepath):
            print(f"Erro: Arquivo nao encontrado '{filepath}'")
            sys.exit(1)
        print(f"Processando arquivo de teste: '{filepath}'...")
        parser.parse_file(filepath)
        parser.print_summary_table()
        parser.print_error_report()
        sys.exit(0 if not parser.errors else 1)
    else:
        # Modo Bateria de Testes Completa
        test_dir = os.path.join(os.path.dirname(__file__), "testes")
        if not os.path.exists(test_dir):
            print("Diretorio 'testes' nao encontrado.")
            sys.exit(1)

        test_files = sorted([f for f in os.listdir(test_dir) if f.endswith(".tonto")])
        print(f"Executando bateria sobre {len(test_files)} arquivos encontrados na pasta 'testes/':\n")

        for tf in test_files:
            fpath = os.path.join(test_dir, tf)
            print(f"\n>> TESTANDO ARQUIVO: {tf}")
            p = TontoParser()
            p.parse_file(fpath)
            p.print_summary_table()
            p.print_error_report()

if __name__ == "__main__":
    main()
