// Test 5: The "Everything" Statement
int log_event(char *message) {
    return 1;
}

int main() {
    int code; char *module; int status;
    code = 500;
    module = "Auth";
    status = log_event(f"[{module}]" @ f" Failed with code: {code}");
    return status;
}