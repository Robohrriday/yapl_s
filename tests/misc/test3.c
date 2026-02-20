int main() {
    char *h = "Hello";
    char *w = "World";

    // Scenario A: Pointer Arithmetic on the Operand (Standard Precedence)
    // 1. ("World" + 1) advances pointer to "orld"
    // 2. "Hello" @ "orld" concatenates
    char *subset = h @ w + 1; 
    // Result: "Helloorld"

    // Scenario B: Pointer Arithmetic on the Result (Grouped)
    // 1. ("Hello" @ "World") creates "HelloWorld"
    // 2. (+ 1) advances pointer on the new string
    char *offset = (h @ w) + 1;
    // Result: "elloWorld"

    return 0;
}