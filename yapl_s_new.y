
%{
#include<stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

extern char *yytext;
int global_declarations=0;
int func_definitions=0;
int int_consts=0;
int pointer_decls=0;
int ifs_wo_else=0;
int ladder_len=0,hold=0;
int max=-1;

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
%}

%token	IDENTIFIER I_CONSTANT F_CONSTANT STRING_LITERAL FUNC_NAME SIZEOF
%token	PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP TH_OP
%token	AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token	SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token	XOR_ASSIGN OR_ASSIGN
%token	TYPEDEF_NAME ENUMERATION_CONSTANT

%token	TYPEDEF EXTERN STATIC AUTO REGISTER INLINE
%token	CONST RESTRICT VOLATILE
%token	BOOL CHAR SHORT INT LONG SIGNED UNSIGNED FLOAT DOUBLE VOID
%token	COMPLEX IMAGINARY 
%token	STRUCT UNION ENUM ELLIPSIS

%token	CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN
%token	ALIGNAS ALIGNOF ATOMIC GENERIC NORETURN STATIC_ASSERT THREAD_LOCAL

/* YAPL-S Tokens */
%token  FSTRING_START FSTRING_END INTERPOLATION_START INTERPOLATION_END STRING_LITERAL_PART

/* Precedence rules to resolve Shift/Reduce conflicts */
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%nonassoc LOWER_THAN_LPAREN
%nonassoc '('

%start translation_unit

%type <val> IF
%type <val> ELSE

%union
{
	int val;
	struct symtab *symp;
}

%%

primary_expression
	: IDENTIFIER { TRACE_REDUCE("primary_expression -> IDENTIFIER"); }
	| constant { TRACE_REDUCE("primary_expression -> constant"); }
	| string { TRACE_REDUCE("primary_expression -> string"); }
	| '(' expression ')' { TRACE_REDUCE("primary_expression -> '(' expression ')'"); }
	| generic_selection { TRACE_REDUCE("primary_expression -> generic_selection"); }
    | f_string_expression { TRACE_REDUCE("primary_expression -> f_string_expression"); }
	;

f_string_expression
    : FSTRING_START f_string_body FSTRING_END { TRACE_REDUCE("f_string_expression -> FSTRING_START f_string_body FSTRING_END"); }

    ;

f_string_body
    : /* empty */ { TRACE_REDUCE("f_string_body -> /* empty */"); }
    | f_string_body STRING_LITERAL_PART { TRACE_REDUCE("f_string_body -> f_string_body STRING_LITERAL_PART"); }

    | f_string_body interpolation_block { TRACE_REDUCE("f_string_body -> f_string_body interpolation_block"); }

    ;

interpolation_block
    : INTERPOLATION_START expression INTERPOLATION_END { TRACE_REDUCE("interpolation_block -> INTERPOLATION_START expression INTERPOLATION_END"); }

    ;

constant
	: I_CONSTANT {int_consts++;} { TRACE_REDUCE("constant -> I_CONSTANT {int_consts++;}"); }
	| F_CONSTANT { TRACE_REDUCE("constant -> F_CONSTANT"); }
	| ENUMERATION_CONSTANT { TRACE_REDUCE("constant -> ENUMERATION_CONSTANT"); }
	;

enumeration_constant
	: IDENTIFIER { TRACE_REDUCE("enumeration_constant -> IDENTIFIER"); }
	;

string
	: STRING_LITERAL { TRACE_REDUCE("string -> STRING_LITERAL"); }
	| FUNC_NAME { TRACE_REDUCE("string -> FUNC_NAME"); }
	;

generic_selection
	: GENERIC '(' assignment_expression ',' generic_assoc_list ')' { TRACE_REDUCE("generic_selection -> GENERIC '(' assignment_expression ',' generic_assoc_list ')'"); }
	;

generic_assoc_list
	: generic_association { TRACE_REDUCE("generic_assoc_list -> generic_association"); }
	| generic_assoc_list ',' generic_association { TRACE_REDUCE("generic_assoc_list -> generic_assoc_list ',' generic_association"); }
	;

generic_association
	: type_name ':' assignment_expression { TRACE_REDUCE("generic_association -> type_name ':' assignment_expression"); }
	| DEFAULT ':' assignment_expression { TRACE_REDUCE("generic_association -> DEFAULT ':' assignment_expression"); }
	;

postfix_expression
	: primary_expression { TRACE_REDUCE("postfix_expression -> primary_expression"); }
	| postfix_expression '[' expression ']' { TRACE_REDUCE("postfix_expression -> postfix_expression '[' expression ']'"); }
	| postfix_expression '(' ')' { TRACE_REDUCE("postfix_expression -> postfix_expression '(' ')'"); }
	| postfix_expression '(' argument_expression_list ')' { TRACE_REDUCE("postfix_expression -> postfix_expression '(' argument_expression_list ')'"); }
	| postfix_expression '.' IDENTIFIER { TRACE_REDUCE("postfix_expression -> postfix_expression '.' IDENTIFIER"); }
	| postfix_expression PTR_OP IDENTIFIER { TRACE_REDUCE("postfix_expression -> postfix_expression PTR_OP IDENTIFIER"); }
	| postfix_expression INC_OP { TRACE_REDUCE("postfix_expression -> postfix_expression INC_OP"); }
	| postfix_expression DEC_OP { TRACE_REDUCE("postfix_expression -> postfix_expression DEC_OP"); }
	| '(' type_name ')' '{' initializer_list '}' { TRACE_REDUCE("postfix_expression -> '(' type_name ')' '{' initializer_list '}'"); }
	| '(' type_name ')' '{' initializer_list ',' '}' { TRACE_REDUCE("postfix_expression -> '(' type_name ')' '{' initializer_list ',' '}'"); }
	;

argument_expression_list
	: assignment_expression { TRACE_REDUCE("argument_expression_list -> assignment_expression"); }
	| argument_expression_list ',' assignment_expression { TRACE_REDUCE("argument_expression_list -> argument_expression_list ',' assignment_expression"); }
	;

unary_expression
	: postfix_expression { TRACE_REDUCE("unary_expression -> postfix_expression"); }
	| INC_OP unary_expression { TRACE_REDUCE("unary_expression -> INC_OP unary_expression"); }
	| DEC_OP unary_expression { TRACE_REDUCE("unary_expression -> DEC_OP unary_expression"); }
	| unary_operator cast_expression { TRACE_REDUCE("unary_expression -> unary_operator cast_expression"); }
	| SIZEOF unary_expression { TRACE_REDUCE("unary_expression -> SIZEOF unary_expression"); }
	| SIZEOF '(' type_name ')' { TRACE_REDUCE("unary_expression -> SIZEOF '(' type_name ')'"); }
	| ALIGNOF '(' type_name ')' { TRACE_REDUCE("unary_expression -> ALIGNOF '(' type_name ')'"); }
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
	: unary_expression { TRACE_REDUCE("cast_expression -> unary_expression"); }
	| '(' type_name ')' cast_expression { TRACE_REDUCE("cast_expression -> '(' type_name ')' cast_expression"); }
	;

multiplicative_expression
	: cast_expression { TRACE_REDUCE("multiplicative_expression -> cast_expression"); }
	| multiplicative_expression '*' cast_expression { TRACE_REDUCE("multiplicative_expression -> multiplicative_expression '*' cast_expression"); }
	| multiplicative_expression '/' cast_expression { TRACE_REDUCE("multiplicative_expression -> multiplicative_expression '/' cast_expression"); }
	| multiplicative_expression '%' cast_expression { TRACE_REDUCE("multiplicative_expression -> multiplicative_expression '%' cast_expression"); }
	;

additive_expression
	: multiplicative_expression { TRACE_REDUCE("additive_expression -> multiplicative_expression"); }
	| additive_expression '+' multiplicative_expression { TRACE_REDUCE("additive_expression -> additive_expression '+' multiplicative_expression"); }
	| additive_expression '-' multiplicative_expression { TRACE_REDUCE("additive_expression -> additive_expression '-' multiplicative_expression"); }
	;

shift_expression
	: additive_expression { TRACE_REDUCE("shift_expression -> additive_expression"); }
	| shift_expression LEFT_OP additive_expression { TRACE_REDUCE("shift_expression -> shift_expression LEFT_OP additive_expression"); }
	| shift_expression RIGHT_OP additive_expression { TRACE_REDUCE("shift_expression -> shift_expression RIGHT_OP additive_expression"); }
	;

/* YAPL-S: Concatenation Expression Tier */
concatenation_expression
    : shift_expression { TRACE_REDUCE("concatenation_expression -> shift_expression"); }
    | concatenation_expression '@' shift_expression { TRACE_REDUCE("concatenation_expression -> concatenation_expression '@' shift_expression"); }
    ;

relational_expression
	: concatenation_expression { TRACE_REDUCE("relational_expression -> concatenation_expression"); }
	| relational_expression '<' concatenation_expression { TRACE_REDUCE("relational_expression -> relational_expression '<' concatenation_expression"); }
	| relational_expression '>' concatenation_expression { TRACE_REDUCE("relational_expression -> relational_expression '>' concatenation_expression"); }
	| relational_expression LE_OP concatenation_expression { TRACE_REDUCE("relational_expression -> relational_expression LE_OP concatenation_expression"); }
	| relational_expression GE_OP concatenation_expression { TRACE_REDUCE("relational_expression -> relational_expression GE_OP concatenation_expression"); }
	| relational_expression TH_OP concatenation_expression { TRACE_REDUCE("relational_expression -> relational_expression TH_OP concatenation_expression"); }
	;

equality_expression
	: relational_expression { TRACE_REDUCE("equality_expression -> relational_expression"); }
	| equality_expression EQ_OP relational_expression { TRACE_REDUCE("equality_expression -> equality_expression EQ_OP relational_expression"); }
	| equality_expression NE_OP relational_expression { TRACE_REDUCE("equality_expression -> equality_expression NE_OP relational_expression"); }
	;

and_expression
	: equality_expression { TRACE_REDUCE("and_expression -> equality_expression"); }
	| and_expression '&' equality_expression { TRACE_REDUCE("and_expression -> and_expression '&' equality_expression"); }
	;

exclusive_or_expression
	: and_expression { TRACE_REDUCE("exclusive_or_expression -> and_expression"); }
	| exclusive_or_expression '^' and_expression { TRACE_REDUCE("exclusive_or_expression -> exclusive_or_expression '^' and_expression"); }
	;

inclusive_or_expression
	: exclusive_or_expression { TRACE_REDUCE("inclusive_or_expression -> exclusive_or_expression"); }
	| inclusive_or_expression '|' exclusive_or_expression { TRACE_REDUCE("inclusive_or_expression -> inclusive_or_expression '|' exclusive_or_expression"); }
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
	: logical_or_expression { TRACE_REDUCE("conditional_expression -> logical_or_expression"); }
	;

assignment_expression
	: conditional_expression { TRACE_REDUCE("assignment_expression -> conditional_expression"); }
	| unary_expression assignment_operator assignment_expression { TRACE_REDUCE("assignment_expression -> unary_expression assignment_operator assignment_expression"); }
	;

assignment_operator
	: '=' { TRACE_REDUCE("assignment_operator -> '='"); }
	| MUL_ASSIGN { TRACE_REDUCE("assignment_operator -> MUL_ASSIGN"); }
	| DIV_ASSIGN { TRACE_REDUCE("assignment_operator -> DIV_ASSIGN"); }
	| MOD_ASSIGN { TRACE_REDUCE("assignment_operator -> MOD_ASSIGN"); }
	| ADD_ASSIGN { TRACE_REDUCE("assignment_operator -> ADD_ASSIGN"); }
	| SUB_ASSIGN { TRACE_REDUCE("assignment_operator -> SUB_ASSIGN"); }
	| LEFT_ASSIGN { TRACE_REDUCE("assignment_operator -> LEFT_ASSIGN"); }
	| RIGHT_ASSIGN { TRACE_REDUCE("assignment_operator -> RIGHT_ASSIGN"); }
	| AND_ASSIGN { TRACE_REDUCE("assignment_operator -> AND_ASSIGN"); }
	| XOR_ASSIGN { TRACE_REDUCE("assignment_operator -> XOR_ASSIGN"); }
	| OR_ASSIGN { TRACE_REDUCE("assignment_operator -> OR_ASSIGN"); }
	;

expression
	: assignment_expression { TRACE_REDUCE("expression -> assignment_expression"); }
	| expression ',' assignment_expression { TRACE_REDUCE("expression -> expression ',' assignment_expression"); }
	;

constant_expression
	: conditional_expression { TRACE_REDUCE("constant_expression -> conditional_expression"); }
	;

declaration
	: declaration_specifiers ';' { TRACE_REDUCE("declaration -> declaration_specifiers ';'"); }
	| declaration_specifiers init_declarator_list ';' { TRACE_REDUCE("declaration -> declaration_specifiers init_declarator_list ';'"); }
	| static_assert_declaration { TRACE_REDUCE("declaration -> static_assert_declaration"); }
	;

declaration_specifiers
	: storage_class_specifier declaration_specifiers { TRACE_REDUCE("declaration_specifiers -> storage_class_specifier declaration_specifiers"); }
	| storage_class_specifier { TRACE_REDUCE("declaration_specifiers -> storage_class_specifier"); }
	| type_specifier declaration_specifiers { TRACE_REDUCE("declaration_specifiers -> type_specifier declaration_specifiers"); }
	| type_specifier { TRACE_REDUCE("declaration_specifiers -> type_specifier"); }
	| type_qualifier declaration_specifiers { TRACE_REDUCE("declaration_specifiers -> type_qualifier declaration_specifiers"); }
	| type_qualifier { TRACE_REDUCE("declaration_specifiers -> type_qualifier"); }
	| function_specifier declaration_specifiers { TRACE_REDUCE("declaration_specifiers -> function_specifier declaration_specifiers"); }
	| function_specifier { TRACE_REDUCE("declaration_specifiers -> function_specifier"); }
	| alignment_specifier declaration_specifiers { TRACE_REDUCE("declaration_specifiers -> alignment_specifier declaration_specifiers"); }
	| alignment_specifier { TRACE_REDUCE("declaration_specifiers -> alignment_specifier"); }
	;

init_declarator_list
	: init_declarator { TRACE_REDUCE("init_declarator_list -> init_declarator"); }
	| init_declarator_list ',' init_declarator { TRACE_REDUCE("init_declarator_list -> init_declarator_list ',' init_declarator"); }
	;

init_declarator
	: declarator '=' initializer { TRACE_REDUCE("init_declarator -> declarator '=' initializer"); }
	| declarator { TRACE_REDUCE("init_declarator -> declarator"); }
	;

storage_class_specifier
	: TYPEDEF { TRACE_REDUCE("storage_class_specifier -> TYPEDEF"); }
	| EXTERN { TRACE_REDUCE("storage_class_specifier -> EXTERN"); }
	| STATIC { TRACE_REDUCE("storage_class_specifier -> STATIC"); }
	| THREAD_LOCAL { TRACE_REDUCE("storage_class_specifier -> THREAD_LOCAL"); }
	| AUTO { TRACE_REDUCE("storage_class_specifier -> AUTO"); }
	| REGISTER { TRACE_REDUCE("storage_class_specifier -> REGISTER"); }
	;

type_specifier
	: VOID { TRACE_REDUCE("type_specifier -> VOID"); }
	| CHAR { TRACE_REDUCE("type_specifier -> CHAR"); }
	| SHORT { TRACE_REDUCE("type_specifier -> SHORT"); }
	| INT { TRACE_REDUCE("type_specifier -> INT"); }
	| LONG { TRACE_REDUCE("type_specifier -> LONG"); }
	| FLOAT { TRACE_REDUCE("type_specifier -> FLOAT"); }
	| DOUBLE { TRACE_REDUCE("type_specifier -> DOUBLE"); }
	| SIGNED { TRACE_REDUCE("type_specifier -> SIGNED"); }
	| UNSIGNED { TRACE_REDUCE("type_specifier -> UNSIGNED"); }
	| BOOL { TRACE_REDUCE("type_specifier -> BOOL"); }
	| COMPLEX { TRACE_REDUCE("type_specifier -> COMPLEX"); }
	| IMAGINARY { TRACE_REDUCE("type_specifier -> IMAGINARY"); }
	| atomic_type_specifier { TRACE_REDUCE("type_specifier -> atomic_type_specifier"); }
	| struct_or_union_specifier { TRACE_REDUCE("type_specifier -> struct_or_union_specifier"); }
	| enum_specifier { TRACE_REDUCE("type_specifier -> enum_specifier"); }
	| TYPEDEF_NAME { TRACE_REDUCE("type_specifier -> TYPEDEF_NAME"); }
	;

struct_or_union_specifier
	: struct_or_union '{' struct_declaration_list '}' { TRACE_REDUCE("struct_or_union_specifier -> struct_or_union '{' struct_declaration_list '}'"); }
	| struct_or_union IDENTIFIER '{' struct_declaration_list '}' { TRACE_REDUCE("struct_or_union_specifier -> struct_or_union IDENTIFIER '{' struct_declaration_list '}'"); }
	| struct_or_union IDENTIFIER { TRACE_REDUCE("struct_or_union_specifier -> struct_or_union IDENTIFIER"); }
	;

struct_or_union
	: STRUCT { TRACE_REDUCE("struct_or_union -> STRUCT"); }
	| UNION { TRACE_REDUCE("struct_or_union -> UNION"); }
	;

struct_declaration_list
	: struct_declaration { TRACE_REDUCE("struct_declaration_list -> struct_declaration"); }
	| struct_declaration_list struct_declaration { TRACE_REDUCE("struct_declaration_list -> struct_declaration_list struct_declaration"); }
	;

struct_declaration
	: specifier_qualifier_list ';' { TRACE_REDUCE("struct_declaration -> specifier_qualifier_list ';'"); }
	| specifier_qualifier_list struct_declarator_list ';' { TRACE_REDUCE("struct_declaration -> specifier_qualifier_list struct_declarator_list ';'"); }
	| static_assert_declaration { TRACE_REDUCE("struct_declaration -> static_assert_declaration"); }
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list { TRACE_REDUCE("specifier_qualifier_list -> type_specifier specifier_qualifier_list"); }
	| type_specifier { TRACE_REDUCE("specifier_qualifier_list -> type_specifier"); }
	| type_qualifier specifier_qualifier_list { TRACE_REDUCE("specifier_qualifier_list -> type_qualifier specifier_qualifier_list"); }
	| type_qualifier { TRACE_REDUCE("specifier_qualifier_list -> type_qualifier"); }
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

enum_specifier
	: ENUM '{' enumerator_list '}' { TRACE_REDUCE("enum_specifier -> ENUM '{' enumerator_list '}'"); }
	| ENUM '{' enumerator_list ',' '}' { TRACE_REDUCE("enum_specifier -> ENUM '{' enumerator_list ',' '}'"); }
	| ENUM IDENTIFIER '{' enumerator_list '}' { TRACE_REDUCE("enum_specifier -> ENUM IDENTIFIER '{' enumerator_list '}'"); }
	| ENUM IDENTIFIER '{' enumerator_list ',' '}' { TRACE_REDUCE("enum_specifier -> ENUM IDENTIFIER '{' enumerator_list ',' '}'"); }
	| ENUM IDENTIFIER { TRACE_REDUCE("enum_specifier -> ENUM IDENTIFIER"); }
	;

enumerator_list
	: enumerator { TRACE_REDUCE("enumerator_list -> enumerator"); }
	| enumerator_list ',' enumerator { TRACE_REDUCE("enumerator_list -> enumerator_list ',' enumerator"); }
	;

enumerator
	: enumeration_constant '=' constant_expression { TRACE_REDUCE("enumerator -> enumeration_constant '=' constant_expression"); }
	| enumeration_constant { TRACE_REDUCE("enumerator -> enumeration_constant"); }
	;

atomic_type_specifier
	: ATOMIC '(' type_name ')' { TRACE_REDUCE("atomic_type_specifier -> ATOMIC '(' type_name ')'"); }
	;

type_qualifier
    : CONST { TRACE_REDUCE("type_qualifier -> CONST"); }
    | RESTRICT { TRACE_REDUCE("type_qualifier -> RESTRICT"); }
    | VOLATILE { TRACE_REDUCE("type_qualifier -> VOLATILE"); }
    | ATOMIC %prec LOWER_THAN_LPAREN { TRACE_REDUCE("type_qualifier -> ATOMIC %prec LOWER_THAN_LPAREN"); }
    ;

function_specifier
	: INLINE { TRACE_REDUCE("function_specifier -> INLINE"); }
	| NORETURN { TRACE_REDUCE("function_specifier -> NORETURN"); }
	;

alignment_specifier
	: ALIGNAS '(' type_name ')' { TRACE_REDUCE("alignment_specifier -> ALIGNAS '(' type_name ')'"); }
	| ALIGNAS '(' constant_expression ')' { TRACE_REDUCE("alignment_specifier -> ALIGNAS '(' constant_expression ')'"); }
	;

declarator
    : pointer direct_declarator {pointer_decls++;} { TRACE_REDUCE("declarator -> pointer direct_declarator {pointer_decls++;}"); }
    | direct_declarator { TRACE_REDUCE("declarator -> direct_declarator"); }
    ;

direct_declarator
	: IDENTIFIER { TRACE_REDUCE("direct_declarator -> IDENTIFIER"); }
	| '(' declarator ')' { TRACE_REDUCE("direct_declarator -> '(' declarator ')'"); }
	| direct_declarator '[' ']' { TRACE_REDUCE("direct_declarator -> direct_declarator '[' ']'"); }
	| direct_declarator '[' '*' ']' { TRACE_REDUCE("direct_declarator -> direct_declarator '[' '*' ']'"); }
	| direct_declarator '[' STATIC type_qualifier_list assignment_expression ']' { TRACE_REDUCE("direct_declarator -> direct_declarator '[' STATIC type_qualifier_list assignment_expression ']'"); }
	| direct_declarator '[' STATIC assignment_expression ']' { TRACE_REDUCE("direct_declarator -> direct_declarator '[' STATIC assignment_expression ']'"); }
	| direct_declarator '[' type_qualifier_list '*' ']' { TRACE_REDUCE("direct_declarator -> direct_declarator '[' type_qualifier_list '*' ']'"); }
	| direct_declarator '[' type_qualifier_list STATIC assignment_expression ']' { TRACE_REDUCE("direct_declarator -> direct_declarator '[' type_qualifier_list STATIC assignment_expression ']'"); }
	| direct_declarator '[' type_qualifier_list assignment_expression ']' { TRACE_REDUCE("direct_declarator -> direct_declarator '[' type_qualifier_list assignment_expression ']'"); }
	| direct_declarator '[' type_qualifier_list ']' { TRACE_REDUCE("direct_declarator -> direct_declarator '[' type_qualifier_list ']'"); }
	| direct_declarator '[' assignment_expression ']' { TRACE_REDUCE("direct_declarator -> direct_declarator '[' assignment_expression ']'"); }
	| direct_declarator '(' parameter_type_list ')' { TRACE_REDUCE("direct_declarator -> direct_declarator '(' parameter_type_list ')'"); }
	| direct_declarator '(' ')' { TRACE_REDUCE("direct_declarator -> direct_declarator '(' ')'"); }
	| direct_declarator '(' identifier_list ')' { TRACE_REDUCE("direct_declarator -> direct_declarator '(' identifier_list ')'"); }
	;

pointer
	: '*' type_qualifier_list pointer { TRACE_REDUCE("pointer -> '*' type_qualifier_list pointer"); }
	| '*' type_qualifier_list { TRACE_REDUCE("pointer -> '*' type_qualifier_list"); }
	| '*' pointer { TRACE_REDUCE("pointer -> '*' pointer"); }
	| '*' { TRACE_REDUCE("pointer -> '*'"); }
	;

type_qualifier_list
	: type_qualifier { TRACE_REDUCE("type_qualifier_list -> type_qualifier"); }
	| type_qualifier_list type_qualifier { TRACE_REDUCE("type_qualifier_list -> type_qualifier_list type_qualifier"); }
	;

parameter_type_list
	: parameter_list ',' ELLIPSIS { TRACE_REDUCE("parameter_type_list -> parameter_list ',' ELLIPSIS"); }
	| parameter_list { TRACE_REDUCE("parameter_type_list -> parameter_list"); }
	;

parameter_list
	: parameter_declaration { TRACE_REDUCE("parameter_list -> parameter_declaration"); }
	| parameter_list ',' parameter_declaration { TRACE_REDUCE("parameter_list -> parameter_list ',' parameter_declaration"); }
	;

parameter_declaration
	: declaration_specifiers declarator { TRACE_REDUCE("parameter_declaration -> declaration_specifiers declarator"); }
	| declaration_specifiers abstract_declarator { TRACE_REDUCE("parameter_declaration -> declaration_specifiers abstract_declarator"); }
	| declaration_specifiers { TRACE_REDUCE("parameter_declaration -> declaration_specifiers"); }
	;

identifier_list
	: IDENTIFIER { TRACE_REDUCE("identifier_list -> IDENTIFIER"); }
	| identifier_list ',' IDENTIFIER { TRACE_REDUCE("identifier_list -> identifier_list ',' IDENTIFIER"); }
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
	| '[' STATIC type_qualifier_list assignment_expression ']' { TRACE_REDUCE("direct_abstract_declarator -> '[' STATIC type_qualifier_list assignment_expression ']'"); }
	| '[' STATIC assignment_expression ']' { TRACE_REDUCE("direct_abstract_declarator -> '[' STATIC assignment_expression ']'"); }
	| '[' type_qualifier_list STATIC assignment_expression ']' { TRACE_REDUCE("direct_abstract_declarator -> '[' type_qualifier_list STATIC assignment_expression ']'"); }
	| '[' type_qualifier_list assignment_expression ']' { TRACE_REDUCE("direct_abstract_declarator -> '[' type_qualifier_list assignment_expression ']'"); }
	| '[' type_qualifier_list ']' { TRACE_REDUCE("direct_abstract_declarator -> '[' type_qualifier_list ']'"); }
	| '[' assignment_expression ']' { TRACE_REDUCE("direct_abstract_declarator -> '[' assignment_expression ']'"); }
	| direct_abstract_declarator '[' ']' { TRACE_REDUCE("direct_abstract_declarator -> direct_abstract_declarator '[' ']'"); }
	| direct_abstract_declarator '[' '*' ']' { TRACE_REDUCE("direct_abstract_declarator -> direct_abstract_declarator '[' '*' ']'"); }
	| direct_abstract_declarator '[' STATIC type_qualifier_list assignment_expression ']' { TRACE_REDUCE("direct_abstract_declarator -> direct_abstract_declarator '[' STATIC type_qualifier_list assignment_expression ']'"); }
	| direct_abstract_declarator '[' STATIC assignment_expression ']' { TRACE_REDUCE("direct_abstract_declarator -> direct_abstract_declarator '[' STATIC assignment_expression ']'"); }
	| direct_abstract_declarator '[' type_qualifier_list assignment_expression ']' { TRACE_REDUCE("direct_abstract_declarator -> direct_abstract_declarator '[' type_qualifier_list assignment_expression ']'"); }
	| direct_abstract_declarator '[' type_qualifier_list STATIC assignment_expression ']' { TRACE_REDUCE("direct_abstract_declarator -> direct_abstract_declarator '[' type_qualifier_list STATIC assignment_expression ']'"); }
	| direct_abstract_declarator '[' type_qualifier_list ']' { TRACE_REDUCE("direct_abstract_declarator -> direct_abstract_declarator '[' type_qualifier_list ']'"); }
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
	| '.' IDENTIFIER { TRACE_REDUCE("designator -> '.' IDENTIFIER"); }
	;

static_assert_declaration
	: STATIC_ASSERT '(' constant_expression ',' STRING_LITERAL ')' ';' { TRACE_REDUCE("static_assert_declaration -> STATIC_ASSERT '(' constant_expression ',' STRING_LITERAL ')' ';'"); }
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
	: IDENTIFIER ':' statement { TRACE_REDUCE("labeled_statement -> IDENTIFIER ':' statement"); }
	| CASE constant_expression ':' statement { TRACE_REDUCE("labeled_statement -> CASE constant_expression ':' statement"); }
	| DEFAULT ':' statement { TRACE_REDUCE("labeled_statement -> DEFAULT ':' statement"); }
	;

compound_statement
	: '{' '}' { TRACE_REDUCE("compound_statement -> '{' '}'"); }
	| '{'  block_item_list '}' { TRACE_REDUCE("compound_statement -> '{'  block_item_list '}'"); }
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
    : IF '(' expression ')' statement ELSE {ladder_len++;$6=(ladder_len-1);} statement {if(ladder_len>=max){max=ladder_len;} ladder_len=$6;} { TRACE_REDUCE("selection_statement -> IF '(' expression ')' statement ELSE {ladder_len++;$6=(ladder_len-1);} statement {if(ladder_len>=max){max=ladder_len;} ladder_len=$6;}"); }
    | IF '(' expression ')' statement %prec LOWER_THAN_ELSE {ifs_wo_else++;} { TRACE_REDUCE("selection_statement -> IF '(' expression ')' statement %prec LOWER_THAN_ELSE {ifs_wo_else++;}"); }
    | SWITCH '(' expression ')' statement { TRACE_REDUCE("selection_statement -> SWITCH '(' expression ')' statement"); }
    ;

iteration_statement
	: WHILE '(' expression ')' statement { TRACE_REDUCE("iteration_statement -> WHILE '(' expression ')' statement"); }
	| DO statement WHILE '(' expression ')' ';' { TRACE_REDUCE("iteration_statement -> DO statement WHILE '(' expression ')' ';'"); }
	| FOR '(' expression_statement expression_statement ')' statement { TRACE_REDUCE("iteration_statement -> FOR '(' expression_statement expression_statement ')' statement"); }
	| FOR '(' expression_statement expression_statement expression ')' statement { TRACE_REDUCE("iteration_statement -> FOR '(' expression_statement expression_statement expression ')' statement"); }
	| FOR '(' declaration expression_statement ')' statement { TRACE_REDUCE("iteration_statement -> FOR '(' declaration expression_statement ')' statement"); }
	| FOR '(' declaration expression_statement expression ')' statement { TRACE_REDUCE("iteration_statement -> FOR '(' declaration expression_statement expression ')' statement"); }
	;

jump_statement
	: GOTO IDENTIFIER ';' { TRACE_REDUCE("jump_statement -> GOTO IDENTIFIER ';'"); }
	| CONTINUE ';' { TRACE_REDUCE("jump_statement -> CONTINUE ';'"); }
	| BREAK ';' { TRACE_REDUCE("jump_statement -> BREAK ';'"); }
	| RETURN ';' { TRACE_REDUCE("jump_statement -> RETURN ';'"); }
	| RETURN expression ';' { TRACE_REDUCE("jump_statement -> RETURN expression ';'"); }
	;

translation_unit
	: external_declaration {global_declarations++;} { TRACE_REDUCE("translation_unit -> external_declaration {global_declarations++;}"); }
	| translation_unit external_declaration {global_declarations++;} { TRACE_REDUCE("translation_unit -> translation_unit external_declaration {global_declarations++;}"); }
	;

external_declaration
	: function_definition {func_definitions++;} { TRACE_REDUCE("external_declaration -> function_definition {func_definitions++;}"); }
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

void yyerror(const char *s)
{
	fflush(stdout);
	
	if(mode==-1)
		printf("***parsing terminated*** [syntax error]\n");
	else if(mode==0 || mode==1)
		printf("%s\n",s);
		
	exit(-1);
}

typedef struct TreeNode {
    char name[128];
    struct TreeNode* children[20];
    int num_children;
} TreeNode;

void print_tree(TreeNode* node, char* prefix, int is_last) {
    if (!node) return;
    printf("%s", prefix);
    printf(is_last ? "\\-- " : "|-- ");
    printf("%s\n", node->name);

    char new_prefix[512];
    strcpy(new_prefix, prefix);
    strcat(new_prefix, is_last ? "    " : "|   ");

    for (int i = 0; i < node->num_children; i++) {
        print_tree(node->children[i], new_prefix, i == node->num_children - 1);
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
		do
		{
			int parse_result = yyparse();

            if (parse_result == 0) {
                printf("\n======================================================\n");
                printf("              HIERARCHICAL PARSE TREE                 \n");
                printf("======================================================\n");
                
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
                        strcpy(root->name, lhs_str);
                        root->num_children = 0;
                        parent = root;
                    } else {
                        if (top >= 0) {
                            parent = stack[top--];
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
                        strcpy(child->name, rhs_str);
                        child->num_children = 0;
                        temp_children[rhs_count++] = child;
                        parent->children[parent->num_children++] = child;
                    }

                    if (rhs_count == 0) {
                        TreeNode* child = malloc(sizeof(TreeNode));
                        strcpy(child->name, "epsilon");
                        child->num_children = 0;
                        parent->children[parent->num_children++] = child;
                    }

                    for (int j = 0; j < rhs_count; j++) {
                        char first_char = temp_children[j]->name[0];
                        // In Yacc, non-terminals are lowercase or start with underscore
                        if (islower(first_char) || first_char == '_') {
                            stack[++top] = temp_children[j];
                        }
                    }
                    free(derivation_tree[i]);
                }

                print_tree(root, "", 1);
                
                printf("======================================================\n");
                printf("Parsing Completed Successfully.\n\n");
			}
		}
		while(!feof(yyin));
	}

	printf("***parsing successful***\n");
	printf("#global_declarations = %d\n",global_declarations);
	printf("#function_definitions = %d\n",func_definitions);
	printf("#integer_constants = %d\n",int_consts);
	printf("#pointers_declarations = %d\n",pointer_decls);
	printf("#ifs_without_else = %d\n",ifs_wo_else);
	printf("if-else max-depth = %d\n",((max<0)?0:max));

	return(0);
}
