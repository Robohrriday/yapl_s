#include "symtab.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SYMTAB_BUCKETS 211

typedef struct Scope {
    int level;
    Symbol *buckets[SYMTAB_BUCKETS];
    struct Scope *parent;
    struct Scope *archive_next;
} Scope;

static Scope *g_current_scope = NULL;
static Scope *g_archived_scopes = NULL;
static int g_scope_level = -1;

static const char *symbol_type_name(int type) {
    switch (type) {
        case SYM_TYPE_INT:
            return "Int";
        case SYM_TYPE_FLOAT:
            return "Float";
        case SYM_TYPE_CHAR:
            return "Char";
        case SYM_TYPE_DOUBLE:
            return "Double";
        case SYM_TYPE_LONG:
            return "Long";
        case SYM_TYPE_SHORT:
            return "Short";
        case SYM_TYPE_VOID:
            return "Void";
        case SYM_TYPE_STRUCT:
            return "Struct";
        case SYM_TYPE_STRING:
            return "String";
        case SYM_TYPE_UNKNOWN:
        default:
            return "Unknown";
    }
}

static void format_type_with_pointer(int type, int pointer_depth, char *out, size_t out_size) {
    const char *base = symbol_type_name(type);
    size_t pos = 0U;
    int i = 0;

    if (out == NULL || out_size == 0U) {
        return;
    }

    out[0] = '\0';
    snprintf(out, out_size, "%s", base);
    pos = strlen(out);

    if (pointer_depth <= 0) {
        return;
    }

    if (pos + 1U < out_size) {
        out[pos++] = ' ';
        out[pos] = '\0';
    }

    for (i = 0; i < pointer_depth && pos + 1U < out_size; ++i) {
        out[pos++] = '*';
        out[pos] = '\0';
    }
}

static unsigned long hash_name(const char *name) {
    /* djb2 hash, simple and stable for compiler symbols. */
    unsigned long hash = 5381UL;
    int c = 0;

    if (name == NULL) {
        return 0UL;
    }

    while ((c = (unsigned char)*name++) != 0) {
        hash = ((hash << 5) + hash) + (unsigned long)c;
    }

    return hash % (unsigned long)SYMTAB_BUCKETS;
}

static char *dup_string(const char *src) {
    size_t len = 0;
    char *dst = NULL;

    if (src == NULL) {
        return NULL;
    }

    len = strlen(src);
    dst = (char *)malloc(len + 1U);
    if (dst == NULL) {
        return NULL;
    }

    memcpy(dst, src, len + 1U);
    return dst;
}

static void free_scope_symbols(Scope *scope) {
    int i = 0;

    if (scope == NULL) {
        return;
    }

    for (i = 0; i < SYMTAB_BUCKETS; ++i) {
        Symbol *sym = scope->buckets[i];
        while (sym != NULL) {
            Symbol *next = sym->next;
            free(sym->name);
            free(sym);
            sym = next;
        }
        scope->buckets[i] = NULL;
    }
}

static Symbol *lookup_in_scope(Scope *scope, const char *name) {
    unsigned long bucket = 0UL;
    Symbol *sym = NULL;

    if (scope == NULL || name == NULL) {
        return NULL;
    }

    bucket = hash_name(name);
    sym = scope->buckets[bucket];

    while (sym != NULL) {
        if (strcmp(sym->name, name) == 0) {
            return sym;
        }
        sym = sym->next;
    }

    return NULL;
}

void symtab_init(void) {
    /* Reset any old state and create the global scope (level 0). */
    symtab_destroy();
    enter_scope();
}

void symtab_destroy(void) {
    Scope *archived = NULL;

    while (g_current_scope != NULL) {
        Scope *old_scope = g_current_scope;
        g_current_scope = old_scope->parent;
        free_scope_symbols(old_scope);
        free(old_scope);
    }

    archived = g_archived_scopes;
    while (archived != NULL) {
        Scope *next = archived->archive_next;
        free_scope_symbols(archived);
        free(archived);
        archived = next;
    }

    g_archived_scopes = NULL;
    g_scope_level = -1;
}

void enter_scope(void) {
    Scope *new_scope = (Scope *)calloc(1U, sizeof(Scope));

    if (new_scope == NULL) {
        return;
    }

    g_scope_level += 1;
    new_scope->level = g_scope_level;
    new_scope->parent = g_current_scope;
    new_scope->archive_next = NULL;
    g_current_scope = new_scope;
}

void exit_scope(void) {
    Scope *old_scope = g_current_scope;

    if (old_scope == NULL) {
        return;
    }

    g_current_scope = old_scope->parent;

    old_scope->parent = NULL;
    old_scope->archive_next = g_archived_scopes;
    g_archived_scopes = old_scope;

    g_scope_level -= 1;
    if (g_scope_level < -1) {
        g_scope_level = -1;
    }
}

void symtab_print(void) {
    Scope *scope = NULL;
    int printed = 0;

    printf("\n======================= SYMBOL TABLE =======================\n");
    printf("%-13s %-20s %-14s %-14s\n", "Scope Level", "Name", "Type", "Line Declared");
    printf("------------------------------------------------------------\n");

    for (scope = g_current_scope; scope != NULL; scope = scope->parent) {
        int i;
        for (i = 0; i < SYMTAB_BUCKETS; ++i) {
            Symbol *sym = scope->buckets[i];
            while (sym != NULL) {
                  {
                      char type_buf[32];
                      format_type_with_pointer(sym->type, sym->pointer_depth, type_buf, sizeof(type_buf));
                      printf("%-13d %-20s %-14s %-14d\n",
                       sym->scope_level,
                       sym->name,
                      type_buf,
                       sym->line_decl);
                  }
                printed = 1;
                sym = sym->next;
            }
        }
    }

    for (scope = g_archived_scopes; scope != NULL; scope = scope->archive_next) {
        int i;
        for (i = 0; i < SYMTAB_BUCKETS; ++i) {
            Symbol *sym = scope->buckets[i];
            while (sym != NULL) {
                  {
                      char type_buf[32];
                      format_type_with_pointer(sym->type, sym->pointer_depth, type_buf, sizeof(type_buf));
                      printf("%-13d %-20s %-14s %-14d\n",
                       sym->scope_level,
                       sym->name,
                      type_buf,
                       sym->line_decl);
                  }
                printed = 1;
                sym = sym->next;
            }
        }
    }

    if (!printed) {
        printf("(no symbols)\n");
    }

    printf("============================================================\n");
}

int insert_symbol(char *name, int type, int pointer_depth, int line) {
    unsigned long bucket = 0UL;
    Symbol *sym = NULL;

    if (g_current_scope == NULL || name == NULL) {
        return 0;
    }

    if (lookup_in_scope(g_current_scope, name) != NULL) {
        return 0;
    }

    sym = (Symbol *)malloc(sizeof(Symbol));
    if (sym == NULL) {
        return 0;
    }

    sym->name = dup_string(name);
    if (sym->name == NULL) {
        free(sym);
        return 0;
    }

    sym->type = type;
    sym->pointer_depth = pointer_depth;
    sym->scope_level = g_current_scope->level;
    sym->line_decl = line;

    bucket = hash_name(name);
    sym->next = g_current_scope->buckets[bucket];
    g_current_scope->buckets[bucket] = sym;

    return 1;
}

Symbol *lookup_symbol(char *name) {
    Scope *scope = g_current_scope;

    while (scope != NULL) {
        Symbol *found = lookup_in_scope(scope, name);
        if (found != NULL) {
            return found;
        }
        scope = scope->parent;
    }

    return NULL;
}

int get_current_scope_level(void) {
    return g_scope_level;
}
