int main() {
    int i;
    char *base = "Item";
    
    // Loops and conditional ladders
    for (i = 0; i < 5; i++) {
        char *current = base @ f"_{i}";
        
        if (i == 0) {
            char *log = f"Starting: {current}";
        } else if (i == 4) {
            char *log = f"Finishing: {current}";
        } else {
            char *log = f"Processing: {current}";
        }
    }
    
    return 0;
}