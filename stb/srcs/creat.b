creat(filename, mode) {
  extrn syscall;
  return (syscall(8, filename, mode));
}
