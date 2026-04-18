// Test 3: Nested Loops with Mixed Control Flow
int main() {
    int i; int j; int sum;
    sum = 0;
    for (i = 0; i < 3; i = i + 1) {
        j = 0;
        while (j < 5) {
            if (j == 2) { break; }
            sum = sum + 1;
            j = j + 1;
        }
        if (i == 1) { continue; }
        sum = sum + 10;
    }
    return sum;
}