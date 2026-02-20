int main() {
    char *base = "Error Code: ";
    int code = 404;

    // INVALID: Cannot concatenate string (char *) with integer (int)
    // char *err = base @ code;  <-- Compilation Error

    // CORRECT: Use F-String to convert the integer first
    char *msg = base @ f"{code}"; 
    // Result: "Error Code: 404"

    return 0;
}