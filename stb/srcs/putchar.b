putchar(c) {
  extrn syscall;
  syscall(4, 1, &c, 1);
}
