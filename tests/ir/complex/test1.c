// Test 1: Deep Scoping & Shadowing
int main() {
    int x; x = 1;
    {
        int x; x = 2;
        {
            int x; x = 3;
        }
    }
    return x; // Should return the outermost x (1)
}