int main() {
    char *prefix = "Dir_";
    char *folder = "SystemFiles";
    char *target = "Dir_ystemFiles";
    int offset = 1;

    // 1. Pointer arithmetic (+) must happen BEFORE concatenation (@)
    // Evaluates as: prefix @ (folder + offset)
    char *path = prefix @ folder + offset;

    // 2. Concatenation (@) must happen BEFORE equality (==)
    // Evaluates as: (prefix @ folder) == target
    if (prefix @ folder == target) {
        int match_found = 1;
    }

    return 0;
}