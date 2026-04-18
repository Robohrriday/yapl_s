// Test 5: Function Redeclaration
int compute() { return 1; }
int compute() { return 2; } // Should trigger function redeclaration error
int main() { return 0; }