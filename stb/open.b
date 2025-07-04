open(string, mode) {
  extrn syscall;
  return (syscall(5, string, 0, mode));
}
