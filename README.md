# YAPL-S: YAPL with String Interpolation

## Overview

YAPL-S is an extension of the YAPL (Yet Another Programming Language) taught in **CS327: Compilers at IIT Gandhinagar**. This project implements compilers for YAPL-S using **Lex** and **Yacc**, adding support for **F-strings** (formatted string literals) and **native string concatenation** using `@`.

This repository currently maintains two compiler pipelines:
- **Legacy pipeline**: `yapl_s.l` + `yapl_s.y` -> `yapl_s`
- **Enhanced pipeline**: `yapl_s_new.l` + `yapl_s_new.y` -> `yapl_s_new`

The enhanced pipeline includes improved diagnostics and reverse-derivation-tree generation.

## Features

### Core Language Features
- **C-like Syntax**: Based on standard C grammar with proper declarations, functions, and control flow
- **Data Types**: Support for integers, floats, chars, strings, pointers, and struct-based composite declarations
- **Control Flow**: if/else, switch/case, while, do-while, for loops, break, continue, return
- **Functions**: Function declarations and definitions with parameter passing
- **Declaration Support**: External declarations and standard initializer/declarator forms

### YAPL-S Extensions
- **F-Strings (Formatted Strings)**: Enhanced string literals with embedded expressions
  - Syntax: `f"string with {expression}"`
  - Support for nested f-strings
  - Escaped literal braces: `{{` and `}}` become literal `{` and `}`
  
- **String Concatenation**: The `@` operator for string concatenation
  - Syntax: `string1 @ string2`
  - Precedence inserted between shift and relational tiers

- **Lexical State Management**: Specialized lexer states for handling f-string parsing with brace-depth tracking for nested structures

### Enhanced Compiler Outputs (`yapl_s_new`)
- Reverse derivation trace capture using `TRACE_REDUCE`
- DOT export (`derivation_tree.dot`) and optional SVG generation during tests
- Improved parse error diagnostics with line/column context

## Project Structure

```
yapl_s/
├── yapl_s.y          # Legacy Yacc grammar
├── yapl_s.l          # Legacy Lex lexer
├── yapl_s_new.y      # Enhanced Yacc grammar
├── yapl_s_new.l      # Enhanced Lex lexer
├── Makefile          # Build and test automation
├── yapl_s            # Legacy compiler executable
├── yapl_s_new        # Enhanced compiler executable
├── README.md         # This file
├── docs/             # Supporting docs and manuals
├── parser_analysis/
│   ├── parsing_table_old.html          # Parsing table old
│   ├── parsing_table_new.html          # Parsing table new
│   ├── yapl_s.output                   # Verbose Yacc output of legacy compiler
│   ├── yapl_s_new.output               # Verbose Yacc output of new compiler
│   └── adversarial_tests/              # Adversarial tests for conflicts
├── yapl/             # Original YAPL language reference
│   ├── yapl.y        # Original YAPL grammar
│   └── yapl.l        # Original YAPL lexer
└── tests/
    ├── positive/
    ├── negative/
    └── misc/
```

## Building

### Prerequisites
- GCC compiler
- Lex (flex)
- Yacc (bison)
- Make

### Compilation

Build both compilers:

```bash
make all
```

Build only legacy compiler:

```bash
make yapl_s
```

Build only enhanced compiler:

```bash
make yapl_s_new
```

The Makefile keeps old/new generated artifacts separate (`old_*`, `new_*`) and compiles both with `-O3`.

### Cleaning

Remove generated files and executables:

```bash
make clean
```

## Usage

### Basic Syntax

Run the legacy compiler:

```bash
./yapl_s input_file.c
```

Run the enhanced compiler:

```bash
./yapl_s_new input_file.c
```

`yapl_s_new` additionally generates reverse derivation tree artifacts used for DOT/SVG visualization.

### Example Programs

#### Simple F-String
```c
int main() {
    char *name = "World";
    char *greeting = f"Hello, {name}!";
    return 0;
}
```

#### Nested F-Strings
```c
int main() {
    int depth = 3;
    char *name = "Inception";
    char *movie_log = f"JSON Output: {{ \"title\": { f"\"{name}\", \"depth\": {depth}" } }}";
    return 0;
}
```

#### String Concatenation with @
```c
int main() {
    char *part1 = "Hello";
    char *part2 = "World";
    char *combined = part1 @ " " @ part2;
    return 0;
}
```

## Testing

### Running All Tests

Execute all test cases in the `tests/` directory:

```bash
make test
```

This will:
- Run all `.c` files in `tests/positive/`, `tests/negative/`, and `tests/misc/`
- Run with **both** compilers (`test_old` + `test_new`)
- Store outputs separately as:
  - `output_old_<id>.txt`
  - `output_new_<id>.txt`
- For `yapl_s_new`, generate `tree_new_<id>.svg` when `derivation_tree.dot` is produced

### Test Categories

- **Positive Tests** (`tests/positive/`): Valid YAPL-S programs demonstrating correct syntax and features
- **Negative Tests** (`tests/negative/`): Invalid programs for testing error handling and recovery
- **Misc Tests** (`tests/misc/`): Additional edge cases and special scenarios

## Notes

- These compilers focus on lexical analysis and parsing; there is no machine-code generation backend
- The architecture and conflict-analysis discussion are documented in `yapl-s-latest.pdf`
- Current grammar/lexer implementations are synchronized with the supported subset policy from the report appendices
