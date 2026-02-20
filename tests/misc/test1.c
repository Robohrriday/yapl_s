int main() {
    int id = 42;
    double score = 98.5;
    char *user = "Alice";

    // --- Standard C11 Approach (Tedious) ---
    // Requires <stdio.h>, <stdlib.h>, <string.h>
    // char buffer[100];
    // sprintf(buffer, "User: %s (ID: %d)", user, id);
    
    // --- YAPL-S Approach (Native) ---
    // F-Strings handle implicit memory allocation and formatting
    char *status = f"User: {user} (ID: {id})";
    
    // String Concatenation using the @ operator
    char *full_msg = status @ " - Status: Active";
    
    // full_msg is now: "User: Alice (ID: 42) - Status: Active"
    
    return 0;
}