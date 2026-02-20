struct Point {
    int x;
    int y;
};

int compute_area(int length, int width) {
    return length * width;
}

int main() {
    struct Point pt;
    pt.x = 15;
    pt.y = 25;
    
    int grid[10];
    grid[0] = 5;
    
    // Interpolation contains: struct access, function call, array access, and arithmetic
    char *complex_str = f"Area at ({pt.x}, {pt.y}) is {compute_area(grid[0], pt.y * 2)} sq units.";
    
    return 0;
}