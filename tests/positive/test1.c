int main() {
    char *user = "Alice";
    int score = 42;
    
    // Test 1: Standard F-string and concatenation
    char *basic = f"User: {user}" @ " - Online";
    
    // Test 2: Concatenation with pointer arithmetic (precedence test)
    // Additive runs first, offsetting "World" to "orld"
    char *subset = "Hello" @ "World" + 1;
    
    // Test 3: Nested F-Strings and literal braces
    // Escaped {{ and }} become literal braces in the string
    char *nested = f"Data: {{ { f"Inner: {score}" } }}";
    
    // Test 4: Expressions inside interpolation
    char *math = f"Calculated: { (score * 2) + 10 }";
    
    return 0;
}