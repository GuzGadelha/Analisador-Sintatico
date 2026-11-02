# Relatório de Divisão do Trabalho e Atribuições da Equipe
## Projeto: Analisador Sintático para a Linguagem TONTO (OntoUML)
### Disciplina: Compiladores — UFERSA / Prof. Patrício de Alencar Silva

---

## 1. Identificação da Equipe
- **Gustavo**
- **Mariana**
- **Eduarda**

---

## 2. Princípio de Divisão Equitativa

O projeto foi dividido em **3 partes estritamente iguais** em termos de complexidade computacional, relevância arquitetural e volume de código:

1. **Gustavo**: Camada de Infraestrutura, Automação de Build e Integração Léxico-Sintática Base (Flex $\rightarrow$ Bison).
2. **Mariana**: Camada de Modelagem Ontológica em C++17 (AST) e Gramática de Construtos Complexos (Generalizações e Relações).
3. **Eduarda**: Camada de Visualizações e Saídas (Tabela de Síntese e Diagnóstico de Erros com Sugestões), Orquestração CLI e Bateria de Testes.

---

## 3. Matriz Detalhada de Arquivos e Responsabilidades por Integrante

### 👤 GUSTAVO
**Módulo:** Infraestrutura, Pipeline de Build & Gramática Base  
**Arquivos sob sua responsabilidade:**
- `CMakeLists.txt` — Pipeline de compilação modular CMake com integração das ferramentas Flex e Bison.
- `Makefile` — Script de compilação direta multiplataforma com GNU Make.
- `.gitignore` — Regras de exclusão de binários e arquivos gerados no controle de versão Git.
- `.vscode/tasks.json` — Tarefas automatizadas de compilação (`Ctrl + Shift + B`) para Debug e Release.
- `.vscode/launch.json` — Configuração de execução e depuração com GDB (`F5`).
- `grammar/lexerTonto.l` — Especificação do analisador léxico no Flex adaptada para interface com o Bison:
  - Propagação de tokens com valor semântico (`yylval`).
  - Rastreamento exato de coordenadas por linha e coluna (`yylloc`).
  - Descarte seguro de comentários de linha e de bloco.
- `grammar/parserTonto.y` (Parte 1: Base) — Regras de produção iniciais:
  - Declaração de pacotes (`package Nome` e `package Nome { ... }`).
  - Declaração de classes simples e tipos nativos (`number`, `string`, `date`, `boolean`, `int`, etc.).
  - Declaração de novos tipos de dados (`datatype`) e classes enumeradas (`enum`).

---

### 👤 MARIANA
**Módulo:** Modelagem da Ontologia (AST) & Construtos Avançados  
**Arquivos sob sua responsabilidade:**
- `include/OntologyModel.hpp` — Interface e estruturas de dados em C++17 para representação em memória da ontologia:
  - `Attribute`: nomes, tipos e meta-atributos (`{const}`, `{ordered}`, `{derived}`).
  - `OntoClass`: estereótipo, herança direta via `specializes`, lista de atributos e relações internas.
  - `Relation`: estereótipo, domínio, imagem, cardinalidades (`[1]`, `[1..*]`), operadores relacionais (`--`, `<>--`, `--<>`, `..`) e escopo (interno/externo).
  - `GenSet`: classe geral, classes específicas, formato (bloco ou inline) e restrições taxonômicas (`disjoint`, `complete`, `overlapping`, `incomplete`).
  - `DataType` e `EnumClass`: suporte a tipos customizados e enums literais.
  - `Package` e `Ontology`: agregadores de escopo e métodos de cálculo estatístico.
- `src/OntologyModel.cpp` — Implementação dos métodos de manipulação, inserção e consulta da AST.
- `grammar/parserTonto.y` (Parte 2: Construtos Avançados):
  - Regras para conjuntos de generalização em bloco (`genset { general ... specifics ... }`).
  - Regras para conjuntos de generalização inline (`where ... specializes ...`).
  - Regras para relações internas de agregação/composição no corpo da classe (`@componentOf [1] <>-- [1..*] Departamento`).
  - Regras para relações externas estereotipadas (`@mediation relation ...`).

---

### 👤 EDUARDA
**Módulo:** Relatórios Visuais, Diagnóstico de Erros & Bateria de Testes  
**Arquivos sob sua responsabilidade:**
- `include/SyntaxReporter.hpp` & `src/SyntaxReporter.cpp` — Implementação da **Visualização 1: Tabela de Síntese**:
  - Resumo quantitativo global de todos os construtos.
  - Tabela de pacotes e classes pertencentes.
  - Detalhamento de classes, atributos tipados e relações internas.
  - Tabela de relações externas com cardinalidades.
  - Tabela de gensets com restrições de disjunção e completude.
  - Tabela de tipos estruturados e enums.
- `include/ErrorHandler.hpp` & `src/ErrorHandler.cpp` — Implementação da **Visualização 2: Relatório de Erros da Ontologia**:
  - Captura e registro de inconformidades sintáticas (`yyerror`).
  - Mapeamento exato de linha, coluna e token causador.
  - **Sugestões contextuais de tratamento**: orientações práticas para o ontologista sanar o erro.
- `src/main.cpp` — Ponto de entrada do executável C++, orquestrador de arquivos, parser e saídas.
- `run_tests.py` — Executor e validador multiplataforma em Python com saída das duas visualizações.
- Pasta `testes/` — Construção da suíte de validação:
  - `01_modelo_completo_anexo.tonto` (Modelo conceitual formal completo do Anexo do PDF).
  - `02_pacotes_classes.tonto` (Testes de classes e atributos).
  - `03_generalizacoes_genset.tonto` (Testes de genset bloco e inline).
  - `04_relacoes_internas_externas.tonto` (Testes de relações e cardinalidades).
  - `05_erros_sintaticos.tonto` (Testes de diagnóstico de erro e sugestões).
  - `Universidade.tonto` (Adaptação da ontologia base do analisador léxico).
- `README.md` & `RELATORIO_DIVISAO.md` — Documentação técnica completa e formalização da equipe.

---

## 4. Planejamento do Vídeo Explicativo de 05 Minutos (Obrigatório)

| Tempo | Apresentador | Conteúdo Demonstrado |
| :--- | :--- | :--- |
| **00:00 - 01:30** | **Gustavo** | • Introdução ao problema e escopo da linguagem TONTO.<br>• Apresentação da arquitetura do compilador e integração Flex $\rightarrow$ Bison.<br>• Demonstração das regras sintáticas de pacotes, tipos nativos/estruturados e enums. |
| **01:30 - 03:15** | **Mariana** | • Demonstração da modelagem da AST em C++17 (`OntologyModel`).<br>• Análise ascendente de relações internas (`<>--`) e externas (`@mediation`) com cardinalidades.<br>• Análise ascendente de conjuntos de generalização (`genset`) nos formatos inline e bloco. |
| **03:15 - 05:00** | **Eduarda** | • Execução ao vivo do analisador sobre o modelo completo do Anexo (`01_modelo_completo_anexo.tonto`).<br>• Demonstração da **Tabela de Síntese** estruturada.<br>• Execução do arquivo com erros (`05_erros_sintaticos.tonto`), exibindo o **Diagnóstico de Erros e as Sugestões de Tratamento**.<br>• Conclusão e considerações finais. |
