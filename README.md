# Analisador Sintático para a Linguagem TONTO (OntoUML Textual)

Este projeto implementa um **Analisador Sintático Ascendente (LALR)** para a linguagem **TONTO** (*Textual Ontology Language*), desenvolvido para a disciplina de **Compiladores** do Centro de Ciências Exatas e Naturais (CCEN) da **UFERSA**, sob orientação do **Prof. Patrício de Alencar Silva**.

---

## 👥 Equipe de Desenvolvimento e Divisão do Trabalho

O trabalho foi dividido rigorosamente em **3 partes iguais**:

| Integrante | Módulo / Responsabilidade | Entregáveis e Arquivos |
| :--- | :--- | :--- |
| **Gustavo** | **Infraestrutura, Pipeline de Build & Gramática Base**<br>• Configuração de build (CMake, Make, VS Code Tasks/Launch)<br>• Adaptação do analisador léxico Flex para propagação de tokens, valor semântico (`yylval`) e coordenadas (`yylloc`)<br>• Regras sintáticas do Bison para Pacotes, Tipos Nativos, `datatype` e `enum` | • `CMakeLists.txt`<br>• `Makefile`<br>• `.gitignore`<br>• `.vscode/tasks.json`<br>• `.vscode/launch.json`<br>• `grammar/lexerTonto.l`<br>• `grammar/parserTonto.y` (Parte 1) |
| **Mariana** | **Modelagem da Ontologia (AST) & Construtos Avançados**<br>• Modelagem orientada a objetos da árvore ontológica em C++17 (`OntologyModel`)<br>• Regras sintáticas do Bison para Generalizações (`genset`) em formato de bloco e inline, com restrições (`disjoint`, `complete`, etc.)<br>• Regras sintáticas para Relações internas (`<>--`) e externas (`@mediation`), com cardinalidades | • `include/OntologyModel.hpp`<br>• `src/OntologyModel.cpp`<br>• `grammar/parserTonto.y` (Parte 2: gensets e relações) |
| **Eduarda** | **Relatórios Visuais, Diagnóstico de Erros & Bateria de Testes**<br>• Gerador da **Tabela de Síntese** (Visualização 1 do PDF)<br>• Gerador do **Relatório de Diagnóstico de Erros** com sugestões práticas de tratamento (Visualização 2 do PDF)<br>• Orquestrador CLI (`main.cpp`), Runner multiplataforma (`run_tests.py`), suíte de testes e documentação | • `include/SyntaxReporter.hpp`<br>• `src/SyntaxReporter.cpp`<br>• `include/ErrorHandler.hpp`<br>• `src/ErrorHandler.cpp`<br>• `src/main.cpp`<br>• `run_tests.py`<br>• Pasta `testes/*.tonto`<br>• `README.md`<br>• `RELATORIO_DIVISAO.md` |

---

## 📋 Construtos da Linguagem Suportados

De acordo com as especificações do trabalho, o analisador valida:

1. **Declaração de Pacotes:** `package NomePacote` ou delimitado em bloco `package NomePacote { ... }`.
2. **Declaração de Classes e Atributos:** estereótipos OntoUML (`kind`, `subkind`, `role`, `phase`, `category`, `mixin`, `collective`, etc.) seguidos do nome da classe, herança (`specializes`), atributos com tipos e meta-atributos (`{const}`, `{ordered}`, `{derived}`).
3. **Tipos de Dados:** tipos nativos (`number`, `string`, `boolean`, `date`, `time`, `datetime`, `int`) e novos tipos estruturados (`datatype Endereco { rua: string, numero: int }`).
4. **Classes Enumeradas:** enumerações finitas (`enum EyeColor { Blue, Green, Brown, Black }`).
5. **Conjuntos de Generalização (Gensets):**
   - Formato em bloco: `[disjoint] [complete] genset FaixaEtaria { general Pessoa specifics Crianca, Adulto }`.
   - Formato inline: `[disjoint] [complete] genset FaixaEtaria where Crianca, Adulto specializes Pessoa`.
6. **Declarações de Relações:**
   - Internas a classes: `@componentOf [1] <>-- [1..*] Departamento`.
   - Externas: `@mediation relation Contrato [1..*] -- [1] Empregado` ou `material alocacao [1..*] (Aluno) <>-- (Turma)`.
   - Operadores relacionais: `--`, `<>--`, `--<>`, `..`.
   - Cardinalidades: `[1]`, `[0..1]`, `[1..*]`, `[0..*]`, `[*]`.
7. **Declaração de Instâncias:** indivíduos terminados com dígitos numéricos (`Aluno01`, `Docente2026`).

---

## 📊 Visualizações e Saídas Geradas

O analisador produz obrigatoriamente duas visualizações estruturadas:

### (1) Tabela de Síntese
- **Resumo Quantitativo Global:** contagem total de pacotes, classes, atributos, relações internas, relações externas, gensets, datatypes, enums e instâncias.
- **Mapeamento de Pacotes e Classes:** listagem detalhada de cada pacote e as classes contidas nele.
- **Detalhamento de Classes:** estereótipo, herança, atributos tipados com metadados e relações internas.
- **Detalhamento de Relações Externas:** estereótipo, domínio, operador, cardinalidades e imagem.
- **Detalhamento de Gensets:** nome, classe geral, classes específicas e restrições (`disjoint`, `complete`).
- **Detalhamento de DataTypes e Enums:** estruturas declaradas e listas de valores literais.

### (2) Relatório de Erros da Ontologia
- Detecção precisa de erros sintáticos (linha e coluna).
- Token causador da inconformidade e contexto do erro.
- **Sugestões Práticas de Tratamento:** orientação clara para o ontologista corrigir o código-fonte.

---

## 🚀 Como Compilar e Executar

### Pré-requisitos (Linux / Ubuntu / Mint / WSL)
```bash
sudo apt update
sudo apt install -y g++ flex bison cmake make
```

### 1. Compilação via CMake
```bash
# Cria o diretório de build e compila
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build

# Executa com um arquivo de teste
./build/tontoParser testes/01_modelo_completo_anexo.tonto
```

### 2. Compilação Direta via Makefile
```bash
# Compila tudo com make
make all

# Executa o teste padrão
make test

# Executa sobre um arquivo específico
./tontoParser testes/01_modelo_completo_anexo.tonto
```

### 3. Execução pelo VS Code
- **Compilar:** Pressione `Ctrl + Shift + B` (aciona a tarefa `Build Debug`).
- **Executar/Depurar:** Pressione `F5` para rodar o parser sobre o modelo completo do Anexo com depuração interativa via GDB.

---

## 🧪 Suíte de Testes Disponível

Na pasta `testes/`, encontram-se casos de teste estruturados:
- `01_modelo_completo_anexo.tonto`: Modelo formal OntoUML completo presente no Anexo (pág. 4) do PDF da UFERSA.
- `02_pacotes_classes.tonto`: Validação de pacotes, classes, atributos, datatypes e enums.
- `03_generalizacoes_genset.tonto`: Validação de gensets nos formatos bloco e inline.
- `04_relacoes_internas_externas.tonto`: Relações com cardinalidades, estereótipos e operadores.
- `05_erros_sintaticos.tonto`: Arquivo com erros intencionais para validar o diagnóstico e as sugestões de tratamento.
- `Universidade.tonto`: Teste do analisador léxico adaptado para a análise sintática.
