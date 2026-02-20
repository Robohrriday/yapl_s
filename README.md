# YAPL-S: YAPL with String Interpolation

## Overview

YAPL-S is an extension of the YAPL (Yet Another Programming Language) taught in **CS327: Compilers at IIT Gandhinagar**. This project implements a compiler for YAPL-S using **Lex** and **Yacc**, adding support for **F-strings** (formatted string literals) with interpolation capabilities.

## Features

### Core Language Features
- **C-like Syntax**: Based on standard C grammar with proper declarations, functions, and control flow
- **Data Types**: Support for integers, floats, chars, strings, pointers, and composite types (struct, union, enum)
- **Control Flow**: if/else, switch/case, while, do-while, for loops, goto, break, continue
- **Functions**: Function declarations and definitions with parameter passing
- **Type Qualifiers**: const, restrict, volatile, static, extern, auto, register, inline

### YAPL-S Extensions
- **F-Strings (Formatted Strings)**: Enhanced string literals with embedded expressions
  - Syntax: `f"string with {expression}"`
  - Support for nested f-strings
  - Escaped literal braces: `{{` and `}}` become literal `{` and `}`
  
- **String Concatenation**: The `@` operator for string concatenation
  - Syntax: `string1 @ string2`
  - Works with f-strings and pointer arithmetic

- **Lexical State Management**: Specialized lexer states for handling f-string parsing with brace depth tracking for nested structures

## Project Structure

```
yapl_s/
├── yapl_s.y          # Yacc grammar file defining YAPL-S syntax
├── yapl_s.l          # Lex lexical analyzer file
├── y.tab.c           # Generated parser (from yacc)
├── y.tab.h           # Generated parser header
├── lex.yy.c          # Generated lexer (from lex)
├── Makefile          # Build and test automation
├── yapl_s            # Compiled executable
├── README.md         # This file
├── docs/             # Documentation files
│   ├── yapl-s.pdf    # YAPL-S language specification
│   └── y_man.pdf     # Yacc/Bison manual reference
└── tests/
    ├── positive/     # Valid YAPL-S programs (6 test cases)
    ├── negative/     # Invalid programs for error handling (4 test cases)
    └── misc/         # Miscellaneous test cases (5 test cases)

```

## Building

### Prerequisites
- GCC compiler
- Lex (flex)
- Yacc (bison)
- Make

### Compilation

Build the compiler using Make:

```bash
make
```

This will:
1. Generate the parser from `yapl_s.y` using yacc
2. Generate the lexer from `yapl_s.l` using lex
3. Compile everything with GCC (with `-O3` optimization)

### Cleaning

Remove generated files and executables:

```bash
make clean
```

## Usage

### Basic Syntax

Run the compiler on a YAPL-S source file:

```bash
./yapl_s input_file.c
```

The compiler outputs lexical and parser analysis information to stdout, including:
- Lexer tokens with their values and context
- Parser reduction rules (when debug mode is enabled)
- Grammar analysis information

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
- Execute each test with: `./yapl_s test_file.c > output_file.txt`
- Generate output files for comparison and validation

### Test Categories

- **Positive Tests** (`tests/positive/`): Valid YAPL-S programs demonstrating correct syntax and features
- **Negative Tests** (`tests/negative/`): Invalid programs for testing error handling and recovery
- **Misc Tests** (`tests/misc/`): Additional edge cases and special scenarios

## Notes

- The compiler focuses on parsing and lexical analysis; no code generation or compilation to machine code
- Output primarily consists of analysis information useful for debugging and understanding program structure
- The f-string implementation handles complex nesting scenarios and proper escape sequence handling
