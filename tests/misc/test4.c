int main() {
    int val = 100;
    
    // Nested F-String:
    // The inner expression { f"[{val}]" } evaluates to "[100]" first.
    char *debug = f"Debug Info: { f"Value -> [{val}]" }";
    
    return 0;
}