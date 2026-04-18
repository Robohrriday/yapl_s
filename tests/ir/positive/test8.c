// Test 8: Arrays (L-Value & R-Value Semantics)
int main() {
    int *arr; int val;
    arr[2] = 50;        // L-Value store
    val = arr[2] + 10;  // R-Value load
    return val;
}