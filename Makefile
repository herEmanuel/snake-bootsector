all:
	nasm -o src/snake.bin -fbin src/snake.asm 
	qemu-system-x86_64 -drive format=raw,file=src/snake.bin

run:
	qemu-system-x86_64 -drive format=raw,file=src/snake.bin