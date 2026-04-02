int main() {
    int x = 1;
    int y = 1;
    int z = 0;
    
    /* Triggers the State 466 Dangling-Else conflict */
    if (x > 0)
        if (y > 0)
            z = 1;
    else
        z = 2;
        
    return 0;
}