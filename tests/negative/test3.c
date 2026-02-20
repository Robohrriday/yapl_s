int main() {
    int x = 10;
    // You cannot put a statement (like a 'while' loop or declaration) inside an expression
    // This should throw: ***parsing terminated*** [syntax error]
    char *invalid_syntax = f"Result: { int y = 5; x + y }";
    
    return 0;
}