
%{
#include<stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "symtab.h"

extern char *yytext;
extern int yylineno;

#define MAX_DERIVATION_STEPS 10000
char* derivation_tree[MAX_DERIVATION_STEPS];
int step_count = 0;

void record_reduction(const char* rule) {
    if (step_count < MAX_DERIVATION_STEPS) {
        derivation_tree[step_count] = strdup(rule);
        step_count++;
    }
}

#define DEBUG_PARSER 1

#if DEBUG_PARSER
    #define TRACE_REDUCE(rule) record_reduction(rule)
#else
    #define TRACE_REDUCE(rule)
#endif

#define MAX_LEXEMES 10000
char* lexeme_list[MAX_LEXEMES];
int lexeme_count = 0;

char* sanitize_for_dot(const char* str) {
    char* san = malloc(strlen(str) * 2 + 1);
    int j = 0;
    for (int i = 0; str[i]; i++) {
        if (str[i] == '"' || str[i] == '\\') {
            san[j++] = '\\';
        }
        if (str[i] != '\n' && str[i] != '\r') {
            san[j++] = str[i];
        }
    }
    san[j] = '\0';
    return san;
}

int real_yylex(void);
void yyerror(const char *s);

typedef struct Quad {
	char op[16];
	char arg1[32];
	char arg2[32];
	char result[32];
} Quad;

#define MAX_QUADS 2000
Quad quad_list[MAX_QUADS];
int quad_count = 0;

int yylex(void) {
    int tok = real_yylex();
    if (tok > 0 && yytext != NULL) {
        lexeme_list[lexeme_count++] = sanitize_for_dot(yytext);
    }
    return tok;
}


/* --- IR Generation Helper Globals & Stubs --- */
int temp_count = 0;
int label_count = 0;
int current_decl_type = SYM_TYPE_UNKNOWN;

/* Generates a fresh temporary variable (e.g., "t0", "t1") */
char* newtemp() {
    char* temp = (char*)malloc(16);
    sprintf(temp, "t%d", temp_count++);
    return temp;
}

/* Generates a fresh label (e.g., "L0", "L1") */
char* newlabel() {
    char* label = (char*)malloc(16);
    sprintf(label, "L%d", label_count++);
    return label;
}

/* Emits a Three-Address Code quadruple */
void emit(const char* op, const char* arg1, const char* arg2, const char* result) {
	if (quad_count >= MAX_QUADS) {
		yyerror("Internal Error: Quadruple list overflow");
	}

	snprintf(quad_list[quad_count].op, sizeof(quad_list[quad_count].op), "%s", op ? op : "");
	snprintf(quad_list[quad_count].arg1, sizeof(quad_list[quad_count].arg1), "%s", arg1 ? arg1 : "");
	snprintf(quad_list[quad_count].arg2, sizeof(quad_list[quad_count].arg2), "%s", arg2 ? arg2 : "");
	snprintf(quad_list[quad_count].result, sizeof(quad_list[quad_count].result), "%s", result ? result : "");
	quad_count++;
}

void print_quadruples(void) {
	int i;
	printf("\n===================== 3AC QUADRUPLES =====================\n");
	printf("%-6s %-16s %-16s %-16s %-16s\n", "#", "Op", "Arg1", "Arg2", "Result");
	printf("-----------------------------------------------------------\n");
	for (i = 0; i < quad_count; i++) {
		printf("%-6d %-16s %-16s %-16s %-16s\n",
			   i,
			   quad_list[i].op,
			   quad_list[i].arg1,
			   quad_list[i].arg2,
			   quad_list[i].result);
	}
	printf("===========================================================\n");
}


%}

%code requires {
typedef struct Attributes {
	char place[32];
	int type;
	char true_label[32];
	char false_label[32];
	char next_label[32];
	struct TreeNode* node;
} Attributes;
}

%define parse.error verbose

%token <sval>	IDENTIFIER
%token <sval>	I_CONSTANT F_CONSTANT
%token	STRING_LITERAL SIZEOF
%token	PTR_OP INC_OP DEC_OP LE_OP GE_OP EQ_OP NE_OP TH_OP
%token	AND_OP OR_OP
%token	EXTERN
%token	CHAR SHORT INT LONG FLOAT DOUBLE VOID
%token	STRUCT
%token	CASE DEFAULT IF ELSE SWITCH WHILE DO FOR CONTINUE BREAK RETURN

/* YAPL-S Tokens */
%token  FSTRING_START FSTRING_END INTERPOLATION_START INTERPOLATION_END STRING_LITERAL_PART

/* Precedence rules to resolve Shift/Reduce conflicts */
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%nonassoc '('

%start translation_unit

%type <val> IF
%type <val> ELSE

/* Assign the SDT attribute struct to our expression and statement branches */
%type <attr> primary_expression postfix_expression unary_expression
%type <attr> cast_expression multiplicative_expression additive_expression
%type <attr> shift_expression concatenation_expression
%type <attr> and_expression exclusive_or_expression inclusive_or_expression
%type <attr> relational_expression equality_expression
%type <attr> logical_and_expression logical_or_expression
%type <attr> conditional_expression assignment_expression expression
%type <attr> statement compound_statement selection_statement iteration_statement jump_statement
%type <attr> declaration init_declarator direct_declarator declarator
%type <attr> if_head


%union {
    int ival;
    float fval;
    char *sval;
    struct TreeNode *node;
    Attributes attr;       /* NEW: The SDT attribute bundle */
}

%%

primary_expression
	: IDENTIFIER {
		Symbol *sym = lookup_symbol($1);
		if (sym == NULL) {
			free($1);
			yyerror("Semantic Error: Undeclared identifier");
		}
		$$.type = sym->type;
		strncpy($$.place, sym->name, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		free($1);
		TRACE_REDUCE("primary_expression -> IDENTIFIER");
	}
	| I_CONSTANT {
		$$.type = SYM_TYPE_INT;
		strncpy($$.place, $1, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		free($1);
		TRACE_REDUCE("primary_expression -> I_CONSTANT");
	}
	| F_CONSTANT {
		$$.type = SYM_TYPE_FLOAT;
		strncpy($$.place, $1, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		free($1);
		TRACE_REDUCE("primary_expression -> F_CONSTANT");
	}
	| string {
		$$.type = SYM_TYPE_UNKNOWN;
		$$.place[0] = '\0';
		TRACE_REDUCE("primary_expression -> string");
	}
	| '(' expression ')' {
		$$.type = $2.type;
		strncpy($$.place, $2.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("primary_expression -> '(' expression ')'");
	}
    | f_string_expression { TRACE_REDUCE("primary_expression -> f_string_expression"); }
	;

f_string_expression
    : FSTRING_START f_string_body FSTRING_END { TRACE_REDUCE("f_string_expression -> FSTRING_START f_string_body FSTRING_END"); }

    ;

f_string_body
    : /* empty */ { TRACE_REDUCE("f_string_body -> epsilon"); }
    | f_string_body STRING_LITERAL_PART { TRACE_REDUCE("f_string_body -> f_string_body STRING_LITERAL_PART"); }
    | f_string_body interpolation_block { TRACE_REDUCE("f_string_body -> f_string_body interpolation_block"); }
    ;

interpolation_block
    : INTERPOLATION_START expression INTERPOLATION_END { TRACE_REDUCE("interpolation_block -> INTERPOLATION_START expression INTERPOLATION_END"); }

    ;

string
	: STRING_LITERAL { TRACE_REDUCE("string -> STRING_LITERAL"); }
	;

postfix_expression
	: primary_expression {
		$$.type = $1.type;
		strncpy($$.place, $1.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("postfix_expression -> primary_expression");
	}
	| postfix_expression '[' expression ']' {
		$$.type = $1.type;
		strncpy($$.place, $1.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("postfix_expression -> postfix_expression '[' expression ']'");
	}
	| postfix_expression '(' ')' {
		$$.type = $1.type;
		strncpy($$.place, $1.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("postfix_expression -> postfix_expression '(' ')'");
	}
	| postfix_expression '(' argument_expression_list ')' {
		$$.type = $1.type;
		strncpy($$.place, $1.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("postfix_expression -> postfix_expression '(' argument_expression_list ')'");
	}
	| postfix_expression '.' IDENTIFIER {
		$$.type = $1.type;
		strncpy($$.place, $1.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		free($3);
		TRACE_REDUCE("postfix_expression -> postfix_expression '.' IDENTIFIER");
	}
	| postfix_expression PTR_OP IDENTIFIER {
		$$.type = $1.type;
		strncpy($$.place, $1.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		free($3);
		TRACE_REDUCE("postfix_expression -> postfix_expression PTR_OP IDENTIFIER");
	}
	| postfix_expression INC_OP {
		$$.type = $1.type;
		strncpy($$.place, $1.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("postfix_expression -> postfix_expression INC_OP");
	}
	| postfix_expression DEC_OP {
		$$.type = $1.type;
		strncpy($$.place, $1.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("postfix_expression -> postfix_expression DEC_OP");
	}
	| '(' type_name ')' '{' initializer_list '}' {
		$$.type = SYM_TYPE_UNKNOWN;
		$$.place[0] = '\0';
		TRACE_REDUCE("postfix_expression -> '(' type_name ')' '{' initializer_list '}'");
	}
	| '(' type_name ')' '{' initializer_list ',' '}' {
		$$.type = SYM_TYPE_UNKNOWN;
		$$.place[0] = '\0';
		TRACE_REDUCE("postfix_expression -> '(' type_name ')' '{' initializer_list ',' '}'");
	}
	;

argument_expression_list
	: assignment_expression { TRACE_REDUCE("argument_expression_list -> assignment_expression"); }
	| argument_expression_list ',' assignment_expression { TRACE_REDUCE("argument_expression_list -> argument_expression_list ',' assignment_expression"); }
	;

unary_expression
	: postfix_expression {
		$$.type = $1.type;
		strncpy($$.place, $1.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("unary_expression -> postfix_expression");
	}
	| INC_OP unary_expression {
		$$.type = $2.type;
		strncpy($$.place, $2.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("unary_expression -> INC_OP unary_expression");
	}
	| DEC_OP unary_expression {
		$$.type = $2.type;
		strncpy($$.place, $2.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("unary_expression -> DEC_OP unary_expression");
	}
	| unary_operator cast_expression {
		$$.type = $2.type;
		strncpy($$.place, $2.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("unary_expression -> unary_operator cast_expression");
	}
	| SIZEOF unary_expression {
		$$.type = SYM_TYPE_INT;
		$$.place[0] = '\0';
		TRACE_REDUCE("unary_expression -> SIZEOF unary_expression");
	}
	| SIZEOF '(' type_name ')' {
		$$.type = SYM_TYPE_INT;
		$$.place[0] = '\0';
		TRACE_REDUCE("unary_expression -> SIZEOF '(' type_name ')'");
	}
	;

unary_operator
	: '&' { TRACE_REDUCE("unary_operator -> '&'"); }
	| '*' { TRACE_REDUCE("unary_operator -> '*'"); }
	| '+' { TRACE_REDUCE("unary_operator -> '+'"); }
	| '-' { TRACE_REDUCE("unary_operator -> '-'"); }
	| '~' { TRACE_REDUCE("unary_operator -> '~'"); }
	| '!' { TRACE_REDUCE("unary_operator -> '!'"); }
	;

cast_expression
	: unary_expression {
		$$.type = $1.type;
		strncpy($$.place, $1.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("cast_expression -> unary_expression");
	}
	| '(' type_name ')' cast_expression {
		$$.type = $4.type;
		strncpy($$.place, $4.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("cast_expression -> '(' type_name ')' cast_expression");
	}
	;

multiplicative_expression
	: cast_expression {
		$$.type = $1.type;
		strncpy($$.place, $1.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("multiplicative_expression -> cast_expression");
	}
	| multiplicative_expression '*' cast_expression {
		char* t;
		if ($1.type != $3.type) {
			yyerror("Semantic Error: Type mismatch in expression");
		}
		$$.type = $1.type;
		t = newtemp();
		strncpy($$.place, t, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		free(t);
		emit("*", $1.place, $3.place, $$.place);
		TRACE_REDUCE("multiplicative_expression -> multiplicative_expression '*' cast_expression");
	}
	| multiplicative_expression '/' cast_expression {
		char* t;
		if ($1.type != $3.type) {
			yyerror("Semantic Error: Type mismatch in expression");
		}
		$$.type = $1.type;
		t = newtemp();
		strncpy($$.place, t, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		free(t);
		emit("/", $1.place, $3.place, $$.place);
		TRACE_REDUCE("multiplicative_expression -> multiplicative_expression '/' cast_expression");
	}
	| multiplicative_expression '%' cast_expression {
		char* t;
		if ($1.type != $3.type) {
			yyerror("Semantic Error: Type mismatch in expression");
		}
		$$.type = $1.type;
		t = newtemp();
		strncpy($$.place, t, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		free(t);
		emit("%", $1.place, $3.place, $$.place);
		TRACE_REDUCE("multiplicative_expression -> multiplicative_expression '%' cast_expression");
	}
	;

additive_expression
	: multiplicative_expression {
		$$.type = $1.type;
		strncpy($$.place, $1.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("additive_expression -> multiplicative_expression");
	}
	| additive_expression '+' multiplicative_expression {
		char* t;
		if ($1.type != $3.type) {
			yyerror("Semantic Error: Type mismatch in expression");
		}
		$$.type = $1.type;
		t = newtemp();
		strncpy($$.place, t, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		free(t);
		emit("+", $1.place, $3.place, $$.place);
		TRACE_REDUCE("additive_expression -> additive_expression '+' multiplicative_expression");
	}
	| additive_expression '-' multiplicative_expression {
		char* t;
		if ($1.type != $3.type) {
			yyerror("Semantic Error: Type mismatch in expression");
		}
		$$.type = $1.type;
		t = newtemp();
		strncpy($$.place, t, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		free(t);
		emit("-", $1.place, $3.place, $$.place);
		TRACE_REDUCE("additive_expression -> additive_expression '-' multiplicative_expression");
	}
	;

shift_expression
	: additive_expression {
		$$.type = $1.type;
		strncpy($$.place, $1.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("shift_expression -> additive_expression");
	}
	;

/* YAPL-S: Concatenation Expression Tier */
concatenation_expression
	: shift_expression {
		$$.type = $1.type;
		strncpy($$.place, $1.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("concatenation_expression -> shift_expression");
	}
	| concatenation_expression '@' shift_expression {
		if ($1.type != $3.type) {
			yyerror("Semantic Error: Type mismatch in expression");
		}
		$$.type = $1.type;
		$$.place[0] = '\0';
		TRACE_REDUCE("concatenation_expression -> concatenation_expression '@' shift_expression");
	}
    ;

relational_expression
	: concatenation_expression {
		$$.type = $1.type;
		strncpy($$.place, $1.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("relational_expression -> concatenation_expression");
	}
	| relational_expression '<' concatenation_expression {
		char* t;
		if ($1.type != $3.type) {
			yyerror("Semantic Error: Type mismatch in expression");
		}
		$$.type = SYM_TYPE_INT;
		t = newtemp();
		strncpy($$.place, t, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		free(t);
		emit("<", $1.place, $3.place, $$.place);
		TRACE_REDUCE("relational_expression -> relational_expression '<' concatenation_expression");
	}
	| relational_expression '>' concatenation_expression {
		char* t;
		if ($1.type != $3.type) {
			yyerror("Semantic Error: Type mismatch in expression");
		}
		$$.type = SYM_TYPE_INT;
		t = newtemp();
		strncpy($$.place, t, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		free(t);
		emit(">", $1.place, $3.place, $$.place);
		TRACE_REDUCE("relational_expression -> relational_expression '>' concatenation_expression");
	}
	| relational_expression LE_OP concatenation_expression {
		char* t;
		if ($1.type != $3.type) {
			yyerror("Semantic Error: Type mismatch in expression");
		}
		$$.type = SYM_TYPE_INT;
		t = newtemp();
		strncpy($$.place, t, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		free(t);
		emit("<=", $1.place, $3.place, $$.place);
		TRACE_REDUCE("relational_expression -> relational_expression LE_OP concatenation_expression");
	}
	| relational_expression GE_OP concatenation_expression {
		char* t;
		if ($1.type != $3.type) {
			yyerror("Semantic Error: Type mismatch in expression");
		}
		$$.type = SYM_TYPE_INT;
		t = newtemp();
		strncpy($$.place, t, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		free(t);
		emit(">=", $1.place, $3.place, $$.place);
		TRACE_REDUCE("relational_expression -> relational_expression GE_OP concatenation_expression");
	}
	| relational_expression TH_OP concatenation_expression {
		char* t;
		if ($1.type != $3.type) {
			yyerror("Semantic Error: Type mismatch in expression");
		}
		$$.type = SYM_TYPE_INT;
		t = newtemp();
		strncpy($$.place, t, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		free(t);
		emit("<=>", $1.place, $3.place, $$.place);
		TRACE_REDUCE("relational_expression -> relational_expression TH_OP concatenation_expression");
	}
	;

equality_expression
	: relational_expression {
		$$.type = $1.type;
		strncpy($$.place, $1.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("equality_expression -> relational_expression");
	}
	| equality_expression EQ_OP relational_expression {
		char* t;
		if ($1.type != $3.type) {
			yyerror("Semantic Error: Type mismatch in expression");
		}
		$$.type = SYM_TYPE_INT;
		t = newtemp();
		strncpy($$.place, t, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		free(t);
		emit("==", $1.place, $3.place, $$.place);
		TRACE_REDUCE("equality_expression -> equality_expression EQ_OP relational_expression");
	}
	| equality_expression NE_OP relational_expression {
		char* t;
		if ($1.type != $3.type) {
			yyerror("Semantic Error: Type mismatch in expression");
		}
		$$.type = SYM_TYPE_INT;
		t = newtemp();
		strncpy($$.place, t, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		free(t);
		emit("!=", $1.place, $3.place, $$.place);
		TRACE_REDUCE("equality_expression -> equality_expression NE_OP relational_expression");
	}
	;

and_expression
	: equality_expression {
		$$.type = $1.type;
		TRACE_REDUCE("and_expression -> equality_expression");
	}
	| and_expression '&' equality_expression {
		$$.type = $1.type;
		TRACE_REDUCE("and_expression -> and_expression '&' equality_expression");
	}
	;

exclusive_or_expression
	: and_expression {
		$$.type = $1.type;
		TRACE_REDUCE("exclusive_or_expression -> and_expression");
	}
	| exclusive_or_expression '^' and_expression {
		$$.type = $1.type;
		TRACE_REDUCE("exclusive_or_expression -> exclusive_or_expression '^' and_expression");
	}
	;

inclusive_or_expression
	: exclusive_or_expression {
		$$.type = $1.type;
		TRACE_REDUCE("inclusive_or_expression -> exclusive_or_expression");
	}
	| inclusive_or_expression '|' exclusive_or_expression {
		$$.type = $1.type;
		TRACE_REDUCE("inclusive_or_expression -> inclusive_or_expression '|' exclusive_or_expression");
	}
	;

logical_and_expression
	: inclusive_or_expression { TRACE_REDUCE("logical_and_expression -> inclusive_or_expression"); }
	| logical_and_expression AND_OP inclusive_or_expression { TRACE_REDUCE("logical_and_expression -> logical_and_expression AND_OP inclusive_or_expression"); }
	;

logical_or_expression
	: logical_and_expression { TRACE_REDUCE("logical_or_expression -> logical_and_expression"); }
	| logical_or_expression OR_OP logical_and_expression { TRACE_REDUCE("logical_or_expression -> logical_or_expression OR_OP logical_and_expression"); }
	;

conditional_expression
	: logical_or_expression {
		$$.type = $1.type;
		strncpy($$.place, $1.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("conditional_expression -> logical_or_expression");
	}
	;

assignment_expression
	: conditional_expression {
		$$.type = $1.type;
		strncpy($$.place, $1.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("assignment_expression -> conditional_expression");
	}
	| unary_expression '=' assignment_expression {
		if ($1.type != $3.type) {
			yyerror("Semantic Error: Type mismatch in assignment");
		}
		$$.type = $1.type;
		strncpy($$.place, $1.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		emit("=", $3.place, "", $1.place);
		TRACE_REDUCE("assignment_expression -> unary_expression '=' assignment_expression");
	}
	;

expression
	: assignment_expression {
		$$.type = $1.type;
		strncpy($$.place, $1.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("expression -> assignment_expression");
	}
	| expression ',' assignment_expression {
		$$.type = $3.type;
		strncpy($$.place, $3.place, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		TRACE_REDUCE("expression -> expression ',' assignment_expression");
	}
	;

constant_expression
	: conditional_expression { TRACE_REDUCE("constant_expression -> conditional_expression"); }
	;

declaration
	: declaration_specifiers ';' { TRACE_REDUCE("declaration -> declaration_specifiers ';'"); }
	| declaration_specifiers init_declarator_list ';' { TRACE_REDUCE("declaration -> declaration_specifiers init_declarator_list ';'"); }
	;

declaration_specifiers
	: storage_class_specifier declaration_specifiers { TRACE_REDUCE("declaration_specifiers -> storage_class_specifier declaration_specifiers"); }
	| storage_class_specifier { TRACE_REDUCE("declaration_specifiers -> storage_class_specifier"); }
	| type_specifier declaration_specifiers { TRACE_REDUCE("declaration_specifiers -> type_specifier declaration_specifiers"); }
	| type_specifier { TRACE_REDUCE("declaration_specifiers -> type_specifier"); }
	;

init_declarator_list
	: init_declarator { TRACE_REDUCE("init_declarator_list -> init_declarator"); }
	| init_declarator_list ',' init_declarator { TRACE_REDUCE("init_declarator_list -> init_declarator_list ',' init_declarator"); }
	;

init_declarator
	: declarator '=' initializer {
		if (!insert_symbol($1.place, current_decl_type, yylineno)) {
			yyerror("Semantic Error: Redeclaration of variable.");
		}
		TRACE_REDUCE("init_declarator -> declarator '=' initializer");
	}
	| declarator {
		if (!insert_symbol($1.place, current_decl_type, yylineno)) {
			yyerror("Semantic Error: Redeclaration of variable.");
		}
		TRACE_REDUCE("init_declarator -> declarator");
	}
	;

storage_class_specifier
	: EXTERN { TRACE_REDUCE("storage_class_specifier -> EXTERN"); }
	;

type_specifier
	: VOID { current_decl_type = SYM_TYPE_VOID; TRACE_REDUCE("type_specifier -> VOID"); }
	| CHAR { current_decl_type = SYM_TYPE_CHAR; TRACE_REDUCE("type_specifier -> CHAR"); }
	| SHORT { current_decl_type = SYM_TYPE_SHORT; TRACE_REDUCE("type_specifier -> SHORT"); }
	| INT { current_decl_type = SYM_TYPE_INT; TRACE_REDUCE("type_specifier -> INT"); }
	| LONG { current_decl_type = SYM_TYPE_LONG; TRACE_REDUCE("type_specifier -> LONG"); }
	| FLOAT { current_decl_type = SYM_TYPE_FLOAT; TRACE_REDUCE("type_specifier -> FLOAT"); }
	| DOUBLE { current_decl_type = SYM_TYPE_DOUBLE; TRACE_REDUCE("type_specifier -> DOUBLE"); }
	| struct_or_union_specifier { current_decl_type = SYM_TYPE_STRUCT; TRACE_REDUCE("type_specifier -> struct_or_union_specifier"); }
	;

struct_or_union_specifier
	: STRUCT '{' struct_declaration_list '}' { TRACE_REDUCE("struct_or_union_specifier -> STRUCT '{' struct_declaration_list '}'"); }
	| STRUCT IDENTIFIER '{' struct_declaration_list '}' {
        free($2);
        TRACE_REDUCE("struct_or_union_specifier -> STRUCT IDENTIFIER '{' struct_declaration_list '}'");
    }
	| STRUCT IDENTIFIER {
        free($2);
        TRACE_REDUCE("struct_or_union_specifier -> STRUCT IDENTIFIER");
    }
	;

struct_declaration_list
	: struct_declaration { TRACE_REDUCE("struct_declaration_list -> struct_declaration"); }
	| struct_declaration_list struct_declaration { TRACE_REDUCE("struct_declaration_list -> struct_declaration_list struct_declaration"); }
	;

struct_declaration
	: specifier_qualifier_list ';' { TRACE_REDUCE("struct_declaration -> specifier_qualifier_list ';'"); }
	| specifier_qualifier_list struct_declarator_list ';' { TRACE_REDUCE("struct_declaration -> specifier_qualifier_list struct_declarator_list ';'"); }
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list { TRACE_REDUCE("specifier_qualifier_list -> type_specifier specifier_qualifier_list"); }
	| type_specifier { TRACE_REDUCE("specifier_qualifier_list -> type_specifier"); }
	;

struct_declarator_list
	: struct_declarator { TRACE_REDUCE("struct_declarator_list -> struct_declarator"); }
	| struct_declarator_list ',' struct_declarator { TRACE_REDUCE("struct_declarator_list -> struct_declarator_list ',' struct_declarator"); }
	;

struct_declarator
	: ':' constant_expression { TRACE_REDUCE("struct_declarator -> ':' constant_expression"); }
	| declarator ':' constant_expression { TRACE_REDUCE("struct_declarator -> declarator ':' constant_expression"); }
	| declarator { TRACE_REDUCE("struct_declarator -> declarator"); }
	;

declarator
	: pointer direct_declarator {
		strcpy($$.place, $2.place);
		TRACE_REDUCE("declarator -> pointer direct_declarator");
	}
	| direct_declarator {
		strcpy($$.place, $1.place);
		TRACE_REDUCE("declarator -> direct_declarator");
	}
    ;

direct_declarator
	: IDENTIFIER {
		strncpy($$.place, $1, sizeof($$.place) - 1);
		$$.place[sizeof($$.place) - 1] = '\0';
		free($1);
		TRACE_REDUCE("direct_declarator -> IDENTIFIER");
	}
	| '(' declarator ')' {
		strcpy($$.place, $2.place);
		TRACE_REDUCE("direct_declarator -> '(' declarator ')'");
	}
	| direct_declarator '[' ']' {
		strcpy($$.place, $1.place);
		TRACE_REDUCE("direct_declarator -> direct_declarator '[' ']'");
	}
	| direct_declarator '[' '*' ']' {
		strcpy($$.place, $1.place);
		TRACE_REDUCE("direct_declarator -> direct_declarator '[' '*' ']'");
	}
	| direct_declarator '[' assignment_expression ']' {
		strcpy($$.place, $1.place);
		TRACE_REDUCE("direct_declarator -> direct_declarator '[' assignment_expression ']'");
	}
	| direct_declarator '(' parameter_type_list ')' {
		strcpy($$.place, $1.place);
		TRACE_REDUCE("direct_declarator -> direct_declarator '(' parameter_type_list ')'");
	}
	| direct_declarator '(' ')' {
		strcpy($$.place, $1.place);
		TRACE_REDUCE("direct_declarator -> direct_declarator '(' ')'");
	}
	| direct_declarator '(' identifier_list ')' {
		strcpy($$.place, $1.place);
		TRACE_REDUCE("direct_declarator -> direct_declarator '(' identifier_list ')'");
	}
	;

pointer
	: '*' pointer { TRACE_REDUCE("pointer -> '*' pointer"); }
	| '*' { TRACE_REDUCE("pointer -> '*'"); }
	;

parameter_type_list
	: parameter_list { TRACE_REDUCE("parameter_type_list -> parameter_list"); }
	;

parameter_list
	: parameter_declaration { TRACE_REDUCE("parameter_list -> parameter_declaration"); }
	| parameter_list ',' parameter_declaration { TRACE_REDUCE("parameter_list -> parameter_list ',' parameter_declaration"); }
	;

parameter_declaration
	: declaration_specifiers declarator {
        if (!insert_symbol($2.place, current_decl_type, yylineno)) {
            yyerror("Semantic Error: Redeclaration of variable.");
        }
        TRACE_REDUCE("parameter_declaration -> declaration_specifiers declarator");
    }
	| declaration_specifiers abstract_declarator { TRACE_REDUCE("parameter_declaration -> declaration_specifiers abstract_declarator"); }
	| declaration_specifiers { TRACE_REDUCE("parameter_declaration -> declaration_specifiers"); }
	;

identifier_list
	: IDENTIFIER {
		free($1);
		TRACE_REDUCE("identifier_list -> IDENTIFIER");
	}
	| identifier_list ',' IDENTIFIER {
		free($3);
		TRACE_REDUCE("identifier_list -> identifier_list ',' IDENTIFIER");
	}
	;

type_name
	: specifier_qualifier_list abstract_declarator { TRACE_REDUCE("type_name -> specifier_qualifier_list abstract_declarator"); }
	| specifier_qualifier_list { TRACE_REDUCE("type_name -> specifier_qualifier_list"); }
	;

abstract_declarator
	: pointer direct_abstract_declarator { TRACE_REDUCE("abstract_declarator -> pointer direct_abstract_declarator"); }
	| pointer { TRACE_REDUCE("abstract_declarator -> pointer"); }
	| direct_abstract_declarator { TRACE_REDUCE("abstract_declarator -> direct_abstract_declarator"); }
	;

direct_abstract_declarator
	: '(' abstract_declarator ')' { TRACE_REDUCE("direct_abstract_declarator -> '(' abstract_declarator ')'"); }
	| '[' ']' { TRACE_REDUCE("direct_abstract_declarator -> '[' ']'"); }
	| '[' '*' ']' { TRACE_REDUCE("direct_abstract_declarator -> '[' '*' ']'"); }
	| '[' assignment_expression ']' { TRACE_REDUCE("direct_abstract_declarator -> '[' assignment_expression ']'"); }
	| direct_abstract_declarator '[' ']' { TRACE_REDUCE("direct_abstract_declarator -> direct_abstract_declarator '[' ']'"); }
	| direct_abstract_declarator '[' '*' ']' { TRACE_REDUCE("direct_abstract_declarator -> direct_abstract_declarator '[' '*' ']'"); }
	| direct_abstract_declarator '[' assignment_expression ']' { TRACE_REDUCE("direct_abstract_declarator -> direct_abstract_declarator '[' assignment_expression ']'"); }
	| '(' ')' { TRACE_REDUCE("direct_abstract_declarator -> '(' ')'"); }
	| '(' parameter_type_list ')' { TRACE_REDUCE("direct_abstract_declarator -> '(' parameter_type_list ')'"); }
	| direct_abstract_declarator '(' ')' { TRACE_REDUCE("direct_abstract_declarator -> direct_abstract_declarator '(' ')'"); }
	| direct_abstract_declarator '(' parameter_type_list ')' { TRACE_REDUCE("direct_abstract_declarator -> direct_abstract_declarator '(' parameter_type_list ')'"); }
	;

initializer
	: '{' initializer_list '}' { TRACE_REDUCE("initializer -> '{' initializer_list '}'"); }
	| '{' initializer_list ',' '}' { TRACE_REDUCE("initializer -> '{' initializer_list ',' '}'"); }
	| assignment_expression { TRACE_REDUCE("initializer -> assignment_expression"); }
	;

initializer_list
	: designation initializer { TRACE_REDUCE("initializer_list -> designation initializer"); }
	| initializer { TRACE_REDUCE("initializer_list -> initializer"); }
	| initializer_list ',' designation initializer { TRACE_REDUCE("initializer_list -> initializer_list ',' designation initializer"); }
	| initializer_list ',' initializer { TRACE_REDUCE("initializer_list -> initializer_list ',' initializer"); }
	;

designation
	: designator_list '=' { TRACE_REDUCE("designation -> designator_list '='"); }
	;

designator_list
	: designator { TRACE_REDUCE("designator_list -> designator"); }
	| designator_list designator { TRACE_REDUCE("designator_list -> designator_list designator"); }
	;

designator
	: '[' constant_expression ']' { TRACE_REDUCE("designator -> '[' constant_expression ']'"); }
	| '.' IDENTIFIER {
        free($2);
        TRACE_REDUCE("designator -> '.' IDENTIFIER");
    }
	;

statement
	: labeled_statement { TRACE_REDUCE("statement -> labeled_statement"); }
	| compound_statement { TRACE_REDUCE("statement -> compound_statement"); }
	| expression_statement { TRACE_REDUCE("statement -> expression_statement"); }
	| selection_statement { TRACE_REDUCE("statement -> selection_statement"); }
	| iteration_statement { TRACE_REDUCE("statement -> iteration_statement"); }
	| jump_statement { TRACE_REDUCE("statement -> jump_statement"); }
	;

labeled_statement
	: IDENTIFIER ':' statement {
        free($1);
        TRACE_REDUCE("labeled_statement -> IDENTIFIER ':' statement");
    }
	| CASE constant_expression ':' statement { TRACE_REDUCE("labeled_statement -> CASE constant_expression ':' statement"); }
	| DEFAULT ':' statement { TRACE_REDUCE("labeled_statement -> DEFAULT ':' statement"); }
	;

compound_statement
	: '{' { enter_scope(); } block_item_list_opt '}' {
        exit_scope();
        TRACE_REDUCE("compound_statement -> '{' block_item_list_opt '}'");
    }
	;

block_item_list_opt
	: /* empty */ { TRACE_REDUCE("block_item_list_opt -> epsilon"); }
	| block_item_list { TRACE_REDUCE("block_item_list_opt -> block_item_list"); }
	;

block_item_list
	: block_item { TRACE_REDUCE("block_item_list -> block_item"); }
	| block_item_list block_item { TRACE_REDUCE("block_item_list -> block_item_list block_item"); }
	;

block_item
	: declaration { TRACE_REDUCE("block_item -> declaration"); }
	| statement { TRACE_REDUCE("block_item -> statement"); }
	;

expression_statement
	: ';' { TRACE_REDUCE("expression_statement -> ';'"); }
	| expression ';' { TRACE_REDUCE("expression_statement -> expression ';'"); }
	;

selection_statement
	: if_head statement ELSE
		{
			emit("goto", "", "", $1.next_label);
			emit("label", "", "", $1.false_label);
		}
	  statement
		{
			emit("label", "", "", $1.next_label);
			TRACE_REDUCE("selection_statement -> IF ... ELSE ...");
		}
    | if_without_else 
        { 
            TRACE_REDUCE("selection_statement -> if_without_else"); 
        }
    | SWITCH '(' expression ')' statement 
        { 
            TRACE_REDUCE("selection_statement -> SWITCH '(' expression ')' statement"); 
        }
    ;

if_without_else
	: if_head statement %prec LOWER_THAN_ELSE
        {
			emit("label", "", "", $1.false_label);
            TRACE_REDUCE("if_without_else -> IF '(' expression ')' statement"); 
        }
    ;

if_head
	: IF '(' expression ')'
		{
			char* false_lbl = newlabel();
			char* next_lbl = newlabel();
			strncpy($$.false_label, false_lbl, sizeof($$.false_label) - 1);
			$$.false_label[sizeof($$.false_label) - 1] = '\0';
			strncpy($$.next_label, next_lbl, sizeof($$.next_label) - 1);
			$$.next_label[sizeof($$.next_label) - 1] = '\0';
			free(false_lbl);
			free(next_lbl);
			emit("ifFalse", $3.place, "goto", $$.false_label);
		}
	;

iteration_statement
	: WHILE
		{
			char* start_lbl = newlabel();
			strncpy($<attr>$.next_label, start_lbl, sizeof($<attr>$.next_label) - 1);
			$<attr>$.next_label[sizeof($<attr>$.next_label) - 1] = '\0';
			free(start_lbl);
			emit("label", "", "", $<attr>$.next_label);
		}
	  '(' expression ')'
		{
			char* exit_lbl = newlabel();
			strncpy($<attr>$.false_label, exit_lbl, sizeof($<attr>$.false_label) - 1);
			$<attr>$.false_label[sizeof($<attr>$.false_label) - 1] = '\0';
			free(exit_lbl);
			emit("ifFalse", $4.place, "goto", $<attr>$.false_label);
		}
	  statement
		{
			emit("goto", "", "", $<attr>2.next_label);
			emit("label", "", "", $<attr>6.false_label);
			TRACE_REDUCE("iteration_statement -> WHILE '(' expression ')' statement");
		}
	| DO
		{
			char* start_lbl = newlabel();
			strncpy($<attr>$.next_label, start_lbl, sizeof($<attr>$.next_label) - 1);
			$<attr>$.next_label[sizeof($<attr>$.next_label) - 1] = '\0';
			free(start_lbl);
			emit("label", "", "", $<attr>$.next_label);
		}
	  statement WHILE '(' expression ')' ';'
		{
			char* exit_lbl = newlabel();
			emit("ifFalse", $6.place, "goto", exit_lbl);
			emit("goto", "", "", $<attr>2.next_label);
			emit("label", "", "", exit_lbl);
			free(exit_lbl);
			TRACE_REDUCE("iteration_statement -> DO statement WHILE '(' expression ')' ';'");
		}
	| FOR '(' expression_statement expression_statement ')' statement { TRACE_REDUCE("iteration_statement -> FOR '(' expression_statement expression_statement ')' statement"); }
	| FOR '(' expression_statement expression_statement expression ')' statement { TRACE_REDUCE("iteration_statement -> FOR '(' expression_statement expression_statement expression ')' statement"); }
	| FOR '(' declaration expression_statement ')' statement { TRACE_REDUCE("iteration_statement -> FOR '(' declaration expression_statement ')' statement"); }
	| FOR '(' declaration expression_statement expression ')' statement { TRACE_REDUCE("iteration_statement -> FOR '(' declaration expression_statement expression ')' statement"); }
	;

jump_statement
	: CONTINUE ';' { TRACE_REDUCE("jump_statement -> CONTINUE ';'"); }
	| BREAK ';' { TRACE_REDUCE("jump_statement -> BREAK ';'"); }
	| RETURN ';' { TRACE_REDUCE("jump_statement -> RETURN ';'"); }
	| RETURN expression ';' { TRACE_REDUCE("jump_statement -> RETURN expression ';'"); }
	;

translation_unit
	: external_declaration { TRACE_REDUCE("translation_unit -> external_declaration"); }
	| translation_unit external_declaration { TRACE_REDUCE("translation_unit -> translation_unit external_declaration"); }
	;

external_declaration
	: function_definition { TRACE_REDUCE("external_declaration -> function_definition"); }
	| declaration { TRACE_REDUCE("external_declaration -> declaration"); }
	;

function_definition
	: declaration_specifiers declarator declaration_list compound_statement { TRACE_REDUCE("function_definition -> declaration_specifiers declarator declaration_list compound_statement"); }
	| declaration_specifiers declarator compound_statement { TRACE_REDUCE("function_definition -> declaration_specifiers declarator compound_statement"); }
	;

declaration_list
	: declaration { TRACE_REDUCE("declaration_list -> declaration"); }
	| declaration_list declaration { TRACE_REDUCE("declaration_list -> declaration_list declaration"); }
	;

%%
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char buff[2048];

int yylex(void);
int mode=-1;

extern int yylineno;
extern int yycolumn;

void yyerror(const char *s)
{
    fflush(stdout);
    
    if(mode==-1) {
        printf("\n======================================================\n");
        printf("                 COMPILER ERROR                       \n");
        printf("======================================================\n");
        
        int start_col = yycolumn - (int)strlen(yytext);
        if (start_col < 1) start_col = 1;

        printf(" Location : Line %d, Column %d\n", yylineno, start_col);
        printf(" Token    : '%s'\n", yytext);
        printf(" Message  : %s\n", s);
        
        printf("======================================================\n");
        printf("***parsing terminated*** [syntax error]\n");
    }
    else if(mode==0 || mode==1)
        printf("%s\n",s);
        
    exit(-1);
}

typedef struct TreeNode {
    int id;
    char name[128];
    struct TreeNode* children[20];
    int num_children;
} TreeNode;

int global_node_counter = 0;

void export_tree_to_dot(TreeNode* node, FILE* fp) {
    if (!node) return;
    
    if (node->num_children > 0) {
        fprintf(fp, "    node_%d [label=\"%s\", shape=box, style=filled, fillcolor=lightblue];\n", node->id, node->name);
    } else {
        fprintf(fp, "    node_%d [label=\"%s\", shape=ellipse, style=filled, fillcolor=lightgrey];\n", node->id, node->name);
    }

    for (int i = 0; i < node->num_children; i++) {
        fprintf(fp, "    node_%d -> node_%d;\n", node->id, node->children[i]->id);
        export_tree_to_dot(node->children[i], fp);
    }
}


void export_leaves_to_dot(TreeNode* node, FILE* fp, int* last_leaf_id) {
    if (!node) return;
    
    if (node->num_children == 0) {
        // Output the node for the rank=same block
        fprintf(fp, "        node_%d;\n", node->id);
        
        if (*last_leaf_id != -1) {
            fprintf(fp, "        node_%d -> node_%d [style=invis];\n", *last_leaf_id, node->id);
        }
        *last_leaf_id = node->id;
    } 
    else {
        for (int i = 0; i < node->num_children; i++) {
            export_leaves_to_dot(node->children[i], fp, last_leaf_id);
        }
    }
}

int current_lexeme_idx = 0;

void attach_lexemes_to_leaves(TreeNode* node) {
    if (!node) return;

    if (node->num_children == 0) {
        if (strcmp(node->name, "epsilon") != 0 && current_lexeme_idx < lexeme_count) {
            char new_label[256];
            snprintf(new_label, sizeof(new_label), "%s\\n%s", node->name, lexeme_list[current_lexeme_idx]);
            strcpy(node->name, new_label);
            current_lexeme_idx++;
        }
    } else {
        for (int i = 0; i < node->num_children; i++) {
            attach_lexemes_to_leaves(node->children[i]);
        }
    }
}

int main(int argc, char **argv)
{
    extern FILE *yyin;

	#if YYDEBUG
    yydebug = 1;
	#endif

	if(argc<2)
	{
		sprintf(buff,"***process terminated*** [input error]: invalid number of command-line arguments");
		mode=1;
		yyerror(buff);
		exit(1);
	}

	yyin=fopen(argv[1],"r");

	if(yyin==NULL)
	{
		sprintf(buff,"***process terminated*** [input error]: no such file \"%s\" exists",argv[1]);
		mode=1;
		yyerror(buff);
		exit(1);
	}
	else
	{
		symtab_init();
		enter_scope();

		do
		{
			int parse_result = yyparse();

            if (parse_result == 0) {
                TreeNode* root = NULL;
                TreeNode* stack[10000]; 
                int top = -1;

                for (int i = step_count - 1; i >= 0; i--) {
                    char rule_copy[512];
                    strcpy(rule_copy, derivation_tree[i]);

                    char* lhs_str = strtok(rule_copy, " \t\n");
                    if (!lhs_str) continue;

                    char* arrow = strtok(NULL, " \t\n");
                    if (!arrow) continue;

                    TreeNode* parent = NULL;
                    if (root == NULL) {
                        root = malloc(sizeof(TreeNode));
                        root->id = global_node_counter++;
                        strcpy(root->name, lhs_str);
                        root->num_children = 0;
                        parent = root;
                    } else {
                        int match_idx = -1;
                        for (int k = top; k >= 0; k--) {
                            if (strcmp(stack[k]->name, lhs_str) == 0) {
                                match_idx = k;
                                break;
                            }
                        }
                        
                        if (match_idx != -1) {
                            parent = stack[match_idx];
                            // Remove from stack by shifting down
                            for (int k = match_idx; k < top; k++) {
                                stack[k] = stack[k+1];
                            }
                            top--;
                        } else {
                            parent = malloc(sizeof(TreeNode));
                            parent->id = global_node_counter++;
                            strcpy(parent->name, lhs_str);
                            parent->num_children = 0;
                        }
                    }

                    TreeNode* temp_children[20];
                    int rhs_count = 0;
                    char* rhs_str;

                    while ((rhs_str = strtok(NULL, " \t\r\n")) != NULL) {
                        if (rhs_str[0] == '{') {
                            while (rhs_str[strlen(rhs_str)-1] != '}') {
                                rhs_str = strtok(NULL, " \t\r\n");
                                if (!rhs_str) break;
                            }
                            continue; 
                        }

                        TreeNode* child = malloc(sizeof(TreeNode));
                        child->id = global_node_counter++;
                        strcpy(child->name, rhs_str);
                        child->num_children = 0;
                        temp_children[rhs_count++] = child;
                        parent->children[parent->num_children++] = child;
                    }

                    if (rhs_count == 0) {
                        TreeNode* child = malloc(sizeof(TreeNode));
                        child->id = global_node_counter++;
                        strcpy(child->name, "epsilon");
                        child->num_children = 0;
                        parent->children[parent->num_children++] = child;
                    }

                    for (int j = 0; j < rhs_count; j++) {
                        char first_char = temp_children[j]->name[0];
                        if (islower(first_char) || first_char == '_') {
                            stack[++top] = temp_children[j];
                        }
                    }
                    free(derivation_tree[i]);
                }

				current_lexeme_idx = 0;
                attach_lexemes_to_leaves(root);

                FILE* dot_file = fopen("derivation_tree.dot", "w");
                if (dot_file) {
                    fprintf(dot_file, "digraph DerivationTree {\n");
                    fprintf(dot_file, "    ordering=\"out\";\n"); 
                    fprintf(dot_file, "    nodesep=0.4;\n");
                    fprintf(dot_file, "    ranksep=0.6;\n");
                    fprintf(dot_file, "    node [fontname=\"Arial\", margin=\"0.1,0.05\"];\n");
                    
                    export_tree_to_dot(root, dot_file);
                    
                    fprintf(dot_file, "\n    { rank=same;\n");
                    int last_leaf = -1;
                    export_leaves_to_dot(root, dot_file, &last_leaf);
                    fprintf(dot_file, "    }\n");
                    
                    fprintf(dot_file, "}\n");
                    fclose(dot_file);
                    
                    printf("\n======================================================\n");
                }
			}
		}
		while(!feof(yyin));

		exit_scope();
		print_quadruples();
		symtab_print();
		symtab_destroy();
	}

	printf("***parsing successful***\n");

	return(0);
}
