// Test 4: The While Loop with break
int main() {
    int n; int fact;
    n = 5; fact = 1;
    while (n > 0) {
        if (n == 2) { break; }
        fact = fact * n;
        n = n - 1;
    }
    return fact;
}