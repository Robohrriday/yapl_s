#ifndef SYMTAB_H
#define SYMTAB_H

#include <stddef.h>

/* Symbol type tags for YAPL-S declarations. */
typedef enum {
    SYM_TYPE_UNKNOWN = 0,
    SYM_TYPE_INT,
    SYM_TYPE_FLOAT,
    SYM_TYPE_CHAR,
    SYM_TYPE_DOUBLE,
    SYM_TYPE_LONG,
    SYM_TYPE_SHORT,
    SYM_TYPE_VOID,
    SYM_TYPE_STRUCT
} SymbolType;

typedef struct Symbol {
    char *name;
    int type;
    int scope_level;
    int line_decl;
    struct Symbol *next;
} Symbol;

/* Initialize and destroy the scoped symbol table runtime. */
void symtab_init(void);
void symtab_destroy(void);

/* Scope management for nested blocks/functions/global environment. */
void enter_scope(void);
void exit_scope(void);

/*
 * Inserts into the current scope only.
 * Returns 1 on success, 0 if duplicate in current scope or on error.
 */
int insert_symbol(char *name, int type, int line);

/*
 * Lookup walks from current scope outward to global scope.
 * Returns pointer to symbol if found, NULL otherwise.
 */
Symbol *lookup_symbol(char *name);

/* Print active and archived symbols in a tabular form. */
void symtab_print(void);

/* Optional utility: current nesting level (-1 means no active scope). */
int get_current_scope_level(void);

#endif /* SYMTAB_H */
