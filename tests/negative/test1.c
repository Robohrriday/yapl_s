int main() {
    // This should throw: ***lexing terminated*** [lexer error]: unescaped newline in f-string
    char *bad_str = f"This string spans
    multiple lines improperly {42}";
    
    return 0;
}