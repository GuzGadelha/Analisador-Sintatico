# Analisador Sintático para a Linguagem TONTO (OntoUML Textual)

Este projeto implementa um **Analisador Sintático Ascendente (LALR)** para a linguagem **TONTO** (*Textual Ontology Language*), desenvolvido para a disciplina de **Compiladores** do Centro de Ciências Exatas e Naturais (CCEN) da **UFERSA**, sob orientação do **Prof. Patrício de Alencar Silva**.

A implementação principal utiliza **C++17**, com **Flex** para análise léxica e **Bison** para análise sintática. O projeto também disponibiliza uma implementação independente em Python para executar e demonstrar a análise dos arquivos de teste.

---

## 👥 Equipe de Desenvolvimento e Divisão do Trabalho

O desenvolvimento foi organizado em três frentes principais:

| Integrante | Módulo / Responsabilidade | Entregáveis e Arquivos |
| :--- | :--- | :--- |
| **Gustavo** | **Infraestrutura, Pipeline de Build e Gramática Base**<br>• Configuração de compilação com CMake, Make e VS Code.<br>• Integração do analisador léxico Flex com o Bison, incluindo tokens, valores semânticos (`yylval`) e coordenadas (`yylloc`).<br>• Regras sintáticas para pacotes, classes, tipos e enums. | • `CMakeLists.txt`<br>• `Makefile`<br>• `.gitignore`<br>• `.vscode/tasks.json`<br>• `.vscode/launch.json`<br>• `grammar/rulesTonto.l`<br>• `grammar/parserTonto.y` (parte da gramática) |
| **Mariana** | **Modelagem da Ontologia e Construtos Avançados**<br>• Modelagem das estruturas da ontologia em C++17.<br>• Regras sintáticas para conjuntos de generalização (`genset`), em formato de bloco e inline.<br>• Regras para relações internas e externas, cardinalidades e operadores. | • `include/OntologyModel.hpp`<br>• `src/OntologyModel.cpp`<br>• `grammar/parserTonto.y` (parte da gramática) |
| **Eduarda** | **Relatórios, Diagnóstico de Erros e Testes**<br>• Implementação da tabela de síntese da ontologia.<br>• Implementação do relatório de erros e sugestões de tratamento.<br>• Orquestração da execução pelo programa principal e implementação do runner em Python.<br>• Organização dos arquivos de teste e documentação. | • `include/SyntaxReporter.hpp`<br>• `src/SyntaxReporter.cpp`<br>• `include/ErrorHandler.hpp`<br>• `src/ErrorHandler.cpp`<br>• `src/main.cpp`<br>• `run_tests.py`<br>• Pasta `testes/`<br>• `README.md`<br>• `RELATORIO_DIVISAO.md` |

---

## 📋 Construtos da Linguagem Suportados

A gramática implementada contempla os seguintes elementos da linguagem TONTO:

1. **Declaração de Pacotes:** permite declarar pacotes com ou sem bloco delimitado por chaves.

   ```tonto
   package Universidade

   package Universidade {
       // declarações
   }
   ```

2. **Declaração de Classes e Atributos:** reconhece classes com estereótipos OntoUML, como `kind`, `subkind`, `role`, `phase`, `category`, `mixin`, `collective`, `quantity`, `mode`, `quality`, `event` e outros presentes no analisador léxico. Também permite indicar especialização por meio de `specializes`, declarar atributos tipados e utilizar meta-atributos como `const`, `ordered`, `derived`, `subsets` e `redefines`.

   ```tonto
   kind Person {
       name: string
       age: int
   }

   role Student specializes Person {
       registration: number
   }
   ```

3. **Tipos de Dados:** reconhece tipos nativos, como `number`, `string`, `boolean`, `time`, `date`, `datetime` e `int`, além de declarações de tipos estruturados (`datatype`).

   ```tonto
   datatype Address {
       street: string
       number: int
   }
   ```

4. **Classes Enumeradas:** permite declarar enumerações com uma lista de valores.

   ```tonto
   enum EyeColor {
       Blue, Green, Brown, Black
   }
   ```

5. **Conjuntos de Generalização (Gensets):** reconhece conjuntos de generalização nos formatos de bloco e inline, com restrições como `disjoint`, `complete`, `overlapping` e `incomplete`.

   **Formato em bloco:**
   ```tonto
   genset AgeGroup {
       general Person
       specifics Child, Adult
       disjoint
       complete
   }
   ```

   **Formato inline:**
   ```tonto
   disjoint complete genset AgeGroup where Child, Adult specializes Person
   ```

6. **Declarações de Relações:** reconhece relações internas ao corpo de classes e relações externas, incluindo estereótipos, operadores e cardinalidades.

   **Relação interna:**
   ```tonto
   kind Company {
       @componentOf [1] <>-- [1..*] Department
   }
   ```

   **Relação externa:**
   ```tonto
   @mediation relation Contract [1..*] -- [1] Employee
   ```

   Operadores reconhecidos:
   - `--`
   - `<>--`
   - `--<>`
   - `..`

   Exemplos de cardinalidades:
   - `[1]`
   - `[0..1]`
   - `[1..*]`
   - `[0..*]`
   - `[*]`

7. **Declaração de Instâncias:** reconhece identificadores de indivíduos terminados em números, como `Student01` e `Teacher2026`.

**Observação:** o reconhecimento sintático de uma declaração não significa que o projeto realize validação semântica completa das relações entre todos os elementos da ontologia. O foco é a análise da estrutura da linguagem e a organização dos construtos reconhecidos.

---

## 📊 Visualizações e Saídas Geradas

A implementação em C++ produz duas saídas estruturadas após a análise do arquivo.

### (1) Tabela de Síntese da Ontologia

Apresenta um resumo quantitativo e o detalhamento dos construtos reconhecidos:

- **Resumo Quantitativo Global:** contagem de pacotes, classes, atributos, relações internas, relações externas, gensets, datatypes, enums e instâncias.
- **Mapeamento de Pacotes e Classes:** apresenta os pacotes identificados e as classes pertencentes a cada um.
- **Detalhamento de Classes:** exibe estereótipos, especializações, atributos, tipos e meta-atributos.
- **Relações Internas:** apresenta as relações declaradas dentro das classes.
- **Relações Externas:** exibe estereótipos, domínio, operador, cardinalidades e imagem.
- **Gensets:** apresenta classe geral, classes específicas, formato e restrições.
- **DataTypes e Enums:** apresenta os tipos estruturados e os valores das enumerações.

### (2) Relatório de Erros da Ontologia

Apresenta informações sobre inconformidades encontradas durante a análise:

- Localização do erro por linha e coluna.
- Diagnóstico da inconformidade.
- Token encontrado, quando disponibilizado pelo tratamento específico do erro.
- Sugestões de correção para auxiliar na identificação do problema.

As sugestões são produzidas por regras e heurísticas contextuais. Portanto, funcionam como orientações para o desenvolvedor, não como correção automática do código.

---

## 🚀 Como Compilar e Executar

### Pré-requisitos

Para compilar a implementação principal em C++ no Linux, Ubuntu, Mint ou WSL, instale:

```bash
sudo apt update
sudo apt install -y g++ flex bison cmake make
```

Para utilizar a implementação Python, é necessário ter Python 3 instalado.

### 1. Compilação via CMake

O CMake é o método de compilação configurado para utilizar os arquivos atuais do projeto, incluindo `grammar/rulesTonto.l`.

```bash
# Configura a compilação
cmake -B build -DCMAKE_BUILD_TYPE=Release

# Compila o projeto
cmake --build build

# Executa um arquivo de teste
./build/tonto_compiler testes/01_modelo_completo_anexo.tonto
```

**Importante:** o executável gerado pelo CMake possui o nome `tonto_compiler`.

### 2. Compilação via Makefile

O projeto possui um `Makefile` com os comandos de compilação e teste:

```bash
# Compila o projeto
make all

# Executa o teste padrão
make test

# Executa um arquivo específico
./tontoParser testes/01_modelo_completo_anexo.tonto
```

**Atenção:** no estado atual do repositório, o `Makefile` ainda referencia `grammar/lexerTonto.l`, arquivo que não está presente na estrutura do projeto. O analisador léxico atual é `grammar/rulesTonto.l`. Portanto, o método via Makefile precisa dessa atualização antes de funcionar corretamente.

### 3. Execução pelo VS Code

O projeto possui tarefas de compilação configuradas em `.vscode/tasks.json`.

- **Compilar:** pressione `Ctrl + Shift + B` e selecione a tarefa `Build Debug`.
- **Compilação Release:** também está disponível a tarefa `Build Release`.
- **Depuração:** a configuração de `F5` está disponível em `.vscode/launch.json`.

**Atenção:** a configuração atual de depuração aponta para `build/tontoParser`, mas o CMake gera `build/tonto_compiler`. Para utilizar o `F5` corretamente, o caminho do executável em `.vscode/launch.json` precisa ser atualizado para:

```json
"program": "${workspaceFolder}/build/tonto_compiler"
```

Até essa alteração, é possível compilar pelo VS Code e executar o binário diretamente pelo terminal.

### 4. Execução via Python

O projeto também disponibiliza o arquivo `run_tests.py`, que contém uma implementação independente do analisador em Python.

Esse modo permite executar os arquivos de teste sem precisar compilar o código C++ ou utilizar Flex e Bison.

**Executar a bateria completa de testes:**

```bash
python3 run_tests.py
```

O programa percorre os arquivos `.tonto` presentes na pasta `testes/`, executando a análise e exibindo as tabelas de síntese e os relatórios de erros.

**Executar um arquivo específico:**

```bash
python3 run_tests.py testes/01_modelo_completo_anexo.tonto
```

Também é possível executar diretamente o arquivo de teste com erros intencionais:

```bash
python3 run_tests.py testes/05_erros_sintaticos.tonto
```

**Importante:** a implementação Python é independente do analisador C++ baseado em Flex e Bison. Ela funciona como uma alternativa para demonstração e execução dos testes, mas não substitui a compilação nem executa o binário C++.

---

## 🧪 Suíte de Testes Disponível

A pasta `testes/` contém seis arquivos utilizados para verificar diferentes construções da linguagem:

| Arquivo | Objetivo |
| :--- | :--- |
| `01_modelo_completo_anexo.tonto` | Testa um modelo OntoUML mais completo, baseado no exemplo do anexo do trabalho. |
| `02_pacotes_classes.tonto` | Testa declarações de pacotes, classes, atributos, datatypes e enums. |
| `03_generalizacoes_genset.tonto` | Testa conjuntos de generalização nos formatos de bloco e inline. |
| `04_relacoes_internas_externas.tonto` | Testa relações internas e externas, cardinalidades, estereótipos e operadores. |
| `05_erros_sintaticos.tonto` | Contém erros intencionais para verificar os diagnósticos e as sugestões de tratamento. |
| `Universidade.tonto` | Utiliza uma ontologia de exemplo para testar a análise dos construtos da linguagem. |

Para executar a bateria pela implementação Python:

```bash
python3 run_tests.py
```

O arquivo `05_erros_sintaticos.tonto` foi criado justamente para apresentar inconformidades. Portanto, a exibição de erros nesse arquivo é esperada.

**Observação sobre os testes:** o runner Python exibe os resultados de cada arquivo, mas sua execução em lote não fornece um código de saída global confiável para indicar que todos os casos passaram ou falharam. Para conferir um arquivo individual, utilize o comando com o caminho do arquivo.

---

## 📁 Estrutura do Projeto

```text
Analisador-Sintatico/
│
├── .vscode/
│   ├── launch.json
│   └── tasks.json
│
├── grammar/
│   ├── parserTonto.y
│   └── rulesTonto.l
│
├── include/
│   ├── ErrorHandler.hpp
│   ├── OntologyModel.hpp
│   └── SyntaxReporter.hpp
│
├── src/
│   ├── ErrorHandler.cpp
│   ├── OntologyModel.cpp
│   ├── SyntaxReporter.cpp
│   └── main.cpp
│
├── testes/
│   ├── 01_modelo_completo_anexo.tonto
│   ├── 02_pacotes_classes.tonto
│   ├── 03_generalizacoes_genset.tonto
│   ├── 04_relacoes_internas_externas.tonto
│   ├── 05_erros_sintaticos.tonto
│   └── Universidade.tonto
│
├── CMakeLists.txt
├── Makefile
├── README.md
├── RELATORIO_DIVISAO.md
└── run_tests.py
```

### Principais arquivos

- **`grammar/rulesTonto.l`:** contém as regras léxicas implementadas com Flex. Reconhece palavras reservadas, estereótipos, tipos, identificadores, operadores, cardinalidades e símbolos da linguagem.
- **`grammar/parserTonto.y`:** contém as regras gramaticais implementadas com Bison para reconhecer os construtos da linguagem TONTO.
- **`include/OntologyModel.hpp` e `src/OntologyModel.cpp`:** definem e implementam as estruturas utilizadas para representar os elementos da ontologia.
- **`include/SyntaxReporter.hpp` e `src/SyntaxReporter.cpp`:** implementam a geração da tabela de síntese.
- **`include/ErrorHandler.hpp` e `src/ErrorHandler.cpp`:** armazenam, organizam e apresentam os diagnósticos de erros e sugestões.
- **`src/main.cpp`:** ponto de entrada da implementação C++, responsável por receber o arquivo, executar a análise e apresentar os relatórios.
- **`run_tests.py`:** implementação independente em Python para analisar arquivos TONTO e executar a bateria de exemplos.
- **`CMakeLists.txt`:** configura a compilação principal utilizando CMake, Flex e Bison.
- **`Makefile`:** disponibiliza comandos alternativos de compilação, mas precisa ser atualizado para utilizar o nome atual do arquivo léxico.
- **`.vscode/`:** contém as configurações de tarefas de compilação e depuração no Visual Studio Code.
