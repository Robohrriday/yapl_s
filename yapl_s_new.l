
%e  1019
%p  2807
%n  371
%k  284
%a  1213
%o  1117
%option yylineno

O   [0-7]
D   [0-9]
NZ  [1-9]
L   [a-zA-Z_]
A   [a-zA-Z_0-9]
H   [a-fA-F0-9]
HP  (0[xX])
E   ([Ee][+-]?{D}+)
P   ([Pp][+-]?{D}+)
FS  (f|F|l|L)
IS  (((u|U)(l|L|ll|LL)?)|((l|L|ll|LL)(u|U)?))
CP  (u|U|L)
SP  (u8|u|U|L)
ES  (\\(['"\?\\abfnrtv]|[0-7]{1,3}|x[a-fA-F0-9]+))
WS  [ \t\v\n\f]

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"


int yycolumn = 1;

#define YY_USER_ACTION \
    for (int i = 0; yytext[i] != '\0'; i++) { \
        if (yytext[i] == '\n') { \
            yycolumn = 1; \
        } else { \
            yycolumn++; \
        } \
    }

extern char buff[2048];
extern int mode;
extern void yyerror(const char *);  /* prints grammar violation message */

static void comment(void);

int state_stack[100];
int brace_stack[100];
int stack_ptr = 0;

int brace_depth = 0; 

void push_state(int s) {
    if (stack_ptr < 100) {
        state_stack[stack_ptr] = s;
        brace_stack[stack_ptr] = brace_depth;
        stack_ptr++;
    }
    else { yyerror("Lexer stack overflow"); exit(1); }
}

int pop_state() {
    if (stack_ptr > 0) {
        stack_ptr--;
        brace_depth = brace_stack[stack_ptr];
        return state_stack[stack_ptr];
    }
    else return 0;
}

int peek_state() {
    if (stack_ptr > 0) return state_stack[stack_ptr - 1];
    return -1;
}

/* Helper macro to translate the lexer state integer to a string */
#define STATE_NAME (YY_START == FSTRING ? "FSTRING" : "INITIAL")

/* DEBUG MACROS FOR PRINTING TOKENS, MODE, AND DEPTH */
#define PRINT_TOK(tok_name) do { \
    printf("[LEXER] Mode: %-7s | Depth: %d | %-22s : '%s'\n", \
           STATE_NAME, brace_depth, #tok_name, yytext); \
    return tok_name; \
} while(0)

#define PRINT_CHAR(char_val) do { \
    printf("[LEXER] Mode: %-7s | Depth: %d | %-22c : '%s'\n", \
           STATE_NAME, brace_depth, char_val, yytext); \
    return char_val; \
} while(0)

#define YY_DECL int real_yylex(void)

%}

%x FSTRING

%%
"/*"                                    { comment(); }
"//".*                                    { /* consume //-comment */ }

"break"					{ PRINT_TOK(BREAK); }
"case"					{ PRINT_TOK(CASE); }
"char"					{ PRINT_TOK(CHAR); }
"continue"				{ PRINT_TOK(CONTINUE); }
"default"				{ PRINT_TOK(DEFAULT); }
"do"					{ PRINT_TOK(DO); }
"double"				{ PRINT_TOK(DOUBLE); }
"else"					{ PRINT_TOK(ELSE); }
"extern"				{ PRINT_TOK(EXTERN); }
"float"					{ PRINT_TOK(FLOAT); }
"for"					{ PRINT_TOK(FOR); }
"if"					{ PRINT_TOK(IF); }
"int"					{ PRINT_TOK(INT); }
"long"					{ PRINT_TOK(LONG); }
"return"				{ PRINT_TOK(RETURN); }
"short"					{ PRINT_TOK(SHORT); }
"sizeof"				{ PRINT_TOK(SIZEOF); }
"struct"				{ PRINT_TOK(STRUCT); }
"switch"				{ PRINT_TOK(SWITCH); }
"void"					{ PRINT_TOK(VOID); }
"while"					{ PRINT_TOK(WHILE); }

"f\""|"F\"" {
    push_state(YY_START);
    BEGIN(FSTRING);
    PRINT_TOK(FSTRING_START);
}

<FSTRING>{
    "\"" {
        BEGIN(pop_state());
        PRINT_TOK(FSTRING_END);
    }
    
    "{{"|"}}" {
        PRINT_TOK(STRING_LITERAL_PART);
    }
    
    "{" {
        push_state(YY_START);
        BEGIN(INITIAL);
        brace_depth = 0;
        PRINT_TOK(INTERPOLATION_START);
    }
    
    ([^"{}\\\n]|{ES})+ {
        PRINT_TOK(STRING_LITERAL_PART);
    }

    "\\" {
        sprintf(buff, "***lexing terminated*** [lexer error]: invalid escape sequence in f-string");
        mode=0;
        yyerror(buff);
    }

    "\n" {
        sprintf(buff, "***lexing terminated*** [lexer error]: unescaped newline in f-string");
        mode=0;
        yyerror(buff);
    }
}

{L}{A}* {
    printf("[LEXER] Mode: %-7s | Depth: %d | %-22s : '%s'\n",
           STATE_NAME, brace_depth,
           "IDENTIFIER", yytext);
    yylval.sval = strdup(yytext);
    if (yylval.sval == NULL) {
        sprintf(buff, "***lexing terminated*** [lexer error]: out of memory while capturing identifier");
        mode=0;
        yyerror(buff);
    }
    return IDENTIFIER;
}

{HP}{H}+{IS}?				{ yylval.sval = strdup(yytext); if (yylval.sval == NULL) { sprintf(buff, "***lexing terminated*** [lexer error]: out of memory while capturing integer constant"); mode=0; yyerror(buff); } PRINT_TOK(I_CONSTANT); }
{NZ}{D}*{IS}?				{ yylval.sval = strdup(yytext); if (yylval.sval == NULL) { sprintf(buff, "***lexing terminated*** [lexer error]: out of memory while capturing integer constant"); mode=0; yyerror(buff); } PRINT_TOK(I_CONSTANT); }
"0"{O}*{IS}?				{ yylval.sval = strdup(yytext); if (yylval.sval == NULL) { sprintf(buff, "***lexing terminated*** [lexer error]: out of memory while capturing integer constant"); mode=0; yyerror(buff); } PRINT_TOK(I_CONSTANT); }
{CP}?"'"([^'\\\n]|{ES})+"'"		{ yylval.sval = strdup(yytext); if (yylval.sval == NULL) { sprintf(buff, "***lexing terminated*** [lexer error]: out of memory while capturing integer constant"); mode=0; yyerror(buff); } PRINT_TOK(I_CONSTANT); }

{D}+{E}{FS}?				{ yylval.sval = strdup(yytext); if (yylval.sval == NULL) { sprintf(buff, "***lexing terminated*** [lexer error]: out of memory while capturing float constant"); mode=0; yyerror(buff); } PRINT_TOK(F_CONSTANT); }
{D}*"."{D}+{E}?{FS}?			{ yylval.sval = strdup(yytext); if (yylval.sval == NULL) { sprintf(buff, "***lexing terminated*** [lexer error]: out of memory while capturing float constant"); mode=0; yyerror(buff); } PRINT_TOK(F_CONSTANT); }
{D}+"."{E}?{FS}?			{ yylval.sval = strdup(yytext); if (yylval.sval == NULL) { sprintf(buff, "***lexing terminated*** [lexer error]: out of memory while capturing float constant"); mode=0; yyerror(buff); } PRINT_TOK(F_CONSTANT); }
{HP}{H}+{P}{FS}?			{ yylval.sval = strdup(yytext); if (yylval.sval == NULL) { sprintf(buff, "***lexing terminated*** [lexer error]: out of memory while capturing float constant"); mode=0; yyerror(buff); } PRINT_TOK(F_CONSTANT); }
{HP}{H}*"."{H}+{P}{FS}?			{ yylval.sval = strdup(yytext); if (yylval.sval == NULL) { sprintf(buff, "***lexing terminated*** [lexer error]: out of memory while capturing float constant"); mode=0; yyerror(buff); } PRINT_TOK(F_CONSTANT); }
{HP}{H}+"."{P}{FS}?			{ yylval.sval = strdup(yytext); if (yylval.sval == NULL) { sprintf(buff, "***lexing terminated*** [lexer error]: out of memory while capturing float constant"); mode=0; yyerror(buff); } PRINT_TOK(F_CONSTANT); }

({SP}?\"([^"\\\n]|{ES})*\"{WS}*)+	{ PRINT_TOK(STRING_LITERAL); }

"<=>"					{ PRINT_TOK(TH_OP); }
"++"					{ PRINT_TOK(INC_OP); }
"--"					{ PRINT_TOK(DEC_OP); }
"->"					{ PRINT_TOK(PTR_OP); }
"&&"					{ PRINT_TOK(AND_OP); }
"||"					{ PRINT_TOK(OR_OP); }
"<="					{ PRINT_TOK(LE_OP); }
">="					{ PRINT_TOK(GE_OP); }
"=="					{ PRINT_TOK(EQ_OP); }
"!="					{ PRINT_TOK(NE_OP); }
";"					{ PRINT_CHAR(';'); }

("{"|"<%") {
    brace_depth++;
    PRINT_CHAR('{');
}

("}"|"%>") {
    if (brace_depth > 0) {
        brace_depth--;
        PRINT_CHAR('}');
    } else if (peek_state() == FSTRING) {
        BEGIN(pop_state());
        PRINT_TOK(INTERPOLATION_END);
    } else {
        PRINT_CHAR('}');
    }
}

","					{ PRINT_CHAR(','); }
":"					{ PRINT_CHAR(':'); }
"="					{ PRINT_CHAR('='); }
"("					{ PRINT_CHAR('('); }
")"					{ PRINT_CHAR(')'); }
"["|"<:"				{ PRINT_CHAR('['); }
"]"|":>"				{ PRINT_CHAR(']'); }
"."					{ PRINT_CHAR('.'); }
"&"					{ PRINT_CHAR('&'); }
"!"					{ PRINT_CHAR('!'); }
"~"					{ PRINT_CHAR('~'); }
"-"					{ PRINT_CHAR('-'); }
"+"					{ PRINT_CHAR('+'); }
"*"					{ PRINT_CHAR('*'); }
"/"					{ PRINT_CHAR('/'); }
"%"					{ PRINT_CHAR('%'); }
"<"					{ PRINT_CHAR('<'); }
">"					{ PRINT_CHAR('>'); }
"^"					{ PRINT_CHAR('^'); }
"|"					{ PRINT_CHAR('|'); }
"@"                 { PRINT_CHAR('@'); } 

{WS}+					{ /* whitespace separates tokens */ }
.					{ /* discard bad characters */ }

%%

int yywrap(void)        /* called at end of input */
{
    return 1;           /* terminate now */
}

static void comment(void)
{
    int c;
    while ((c = input()) != 0)
        if (c == '*')
        {
            while ((c = input()) == '*')
                ;

            if (c == '/')
                return;

            if (c == 0)
                break;
        }
	sprintf(buff,"***lexing terminated*** [lexer error]: ill-formed comment");
	mode=0;
    yyerror(buff);
}
