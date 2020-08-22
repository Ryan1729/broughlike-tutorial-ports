This program relies on the SDL2 library via https://github.com/veandco/go-sdl2 
The setup instructions below refer to the instructions given there, but
they also reproduce the commands you may want to run, for easy copy-pasting.

## Setup and Build Commands

You will need to have golang installed, and the `go` tool available on your `PATH` for the below commands to work.

You'll also need to follow the setup instructions at https://github.com/veandco/go-sdl2

After that is done, running

```
go build
```

in the same folder as this README should produce a binary in that folder.
This binary will rely on the SDL libs to be present at runtime. So, to
distribute this version, the libs should be included with the executable,
for instance, in a zip file.

### Static Compilation

Static compilation is also possible. To statically compile for Linux on Linux, remove any previous linux binary, then run:

```
CGO_ENABLED=1 CC=gcc GOOS=linux GOARCH=amd64 go build -tags static -ldflags "-s -w"
```


To statically cross compile from Linux to Windows, perform the Cross-compiling, Linux to Windows setup instructions at https://github.com/veandco/go-sdl2

Then you can run to produce a statically-linked windows `.exe` file

```
CGO_ENABLED=1 CC=x86_64-w64-mingw32-gcc GOOS=windows GOARCH=amd64 go build -tags static -ldflags "-s -w"
```
