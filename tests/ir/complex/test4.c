// Test 4: Pointer Arithmetic Chaining
int main() {
    int *arr; int *ptr; int offset;
    offset = 2;
    ptr = &arr[offset]; // Synthesizes address, adds scaled offset, assigns pointer
    *ptr = *ptr + 1;    // Dereferences, adds 1, stores back into dereferenced address
    return 0;
}