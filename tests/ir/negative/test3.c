// Test 3: Strict Type Mismatch
int main() {
    int x; char *str;
    str = "Hello";
    x = str; // Type mismatch (Int vs Char *)
    return 0;
}