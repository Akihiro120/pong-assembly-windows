build:
	nasm -f win64 main.asm
	gcc main.obj -o main -L"lib" -lraylib -lopengl32 -lgdi32 -lwinmm
	main.exe
