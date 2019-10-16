int g(int i) {
    int callee_local = 3;
    return callee_local + i;
}

int f() {
    int caller_local = 1;
    return caller_local + g(2);
}