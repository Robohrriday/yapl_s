// Test 4: Invalid Dereference
int main() {
    int num; int val;
    num = 5;
    val = *num; // Cannot dereference a non-pointer (depth 0)
    return 0;
}