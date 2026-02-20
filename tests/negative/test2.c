int main() {
    int x = 10;
    // Missing the closing '}' for the interpolation block
    // This should throw: ***parsing terminated*** [syntax error]
    char *broken = f"The value is { x + 5 ";
    
    return 0;
}