// Test 10: F-Strings (Interpolation lowers to concatenation)
int main() {
    int user_id; int attempts; char *log;
    user_id = 404;
    attempts = 3;
    log = f"User {user_id} failed {attempts} times.";
    return 0;
}