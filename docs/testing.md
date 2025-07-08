# Testing

## Unit Testing

### 🛠️ How to Build and Run the Tests

Run: `zig test test_math.zig -lc -I. mathlib.c`

- `zig test` — Runs Zig's built-in test runner
- `test_math.zig` — Your Zig test file
- `-lc` — Link the standard C library
- `-I.` — Include the current folder (for mathlib.h)
- `mathlib.c` — Compile and link your C source
