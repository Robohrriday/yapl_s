void log_event(char *msg) {
    // Implementation for logging...
}

int main() {
    int x = 10, y = 20;
    
    // Direct usage in printf (replaces %s format specifiers)
    printf(f"Coordinates: x={x}, y={y}\n");
    
    // Usage in custom functions with embedded arithmetic
    // The expression {x + y} is evaluated before string construction
    log_event(f"System Check: {x + y} units detected.");
    
    return 0;
}