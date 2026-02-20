struct Payload {
    char *name;
    int id;
};

int main() {
    int v = 99;
    
    // We initialize an inline struct, put an inner f-string 
    // inside the struct braces, and immediately access its .name field.
    char *log = f"Entry: { ((struct Payload){ f"Item_{v}", v }).name }";
    
    return 0;
}