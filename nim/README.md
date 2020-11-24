# Broughlike tutorial: Nim version

On Linux, assuming you don't want to install raylib globally, the `libraylib.so` file should in the same folder as the binary, and the `LD_LIBRARY_PATH` environment variale should include that folder as well.

For example, this should work:
```bash
LD_LIBRARY_PATH='.' ./broughlike_tutorial
```

## Stuff I had to do that I feel like noting down

I went to https://guevara-chan.github.io/Raylib-Forever/main.html and got raylib.nim, but then I got this error:

```
raylib.nim(921, 64) Error: undeclared identifier: 'unsigned'
```

So I had to comment out the several instances of `unsigned`, but then it seemed to work just fine.
