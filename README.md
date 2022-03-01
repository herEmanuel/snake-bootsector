### Snake Bootsector

![Screenshot of the game](/snake-game.png?raw=true)

This is a simple version of the snake game that fits in a bootsector (512 bytes) and runs without any operating system.

*Disclaimer*: This version has some limitations, namely:

- The game is not restarted in case the snake touches itself
- The apple can only appear in some parts of the map

### Running it

To assemble and run the game, you will only need two things: QEMU and Nasm. After cloning the repo, simply type `make` and you should be able to play it.