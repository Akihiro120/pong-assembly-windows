# Pong
#
I made Pong using NASM Assembly on the Windows 64x Architecture and Raylib

<img src="https://github.com/Akihiro120/pong-assembly-windows/assets/127700131/5fe59a45-552e-48bb-8743-0ad7e154123f" width="500" height="300">

# Features:
<ul>
  <li>Two Player Functionality</li>
  <li>Collision Detection</li>
</ul>

# How to Compile
```
make
```

or

```
nasm -f win64 main.asm
gcc main.obj -o main -L"lib" -lraylib -lopengl32 -lgdi32 -lwinmm
main.exe
```
