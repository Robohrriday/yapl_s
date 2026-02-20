int main() {
    int depth = 3;
    char *name = "Inception";
    
    // The lexer must handle {{, }}, and recursively enter the f-string state twice.
    char *movie_log = f"JSON Output: {{ \"title\": { f"\"{name}\", \"depth\": {depth}" } }}";
    
    return 0;
}