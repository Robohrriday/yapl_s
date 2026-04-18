// Test 5: The For Loop with continue
int main() {
    int sum; int i;
    sum = 0;
    for (i = 0; i < 5; i = i + 1) {
        if (i == 3) { continue; }
        sum = sum + i;
    }
    return sum;
}