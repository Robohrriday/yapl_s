// Test 2: Complex Logical Short-Circuiting
int main() {
    int a; int b; int c; int result;
    a = 1; b = 0; c = 1;
    if ((a > 0 && b > 0) || c == 1) {
        result = 1;
    } else {
        result = 0;
    }
    return result;
}