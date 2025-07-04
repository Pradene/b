chmod(filename, mode) {
  extrn syscall;
  return (syscall(15, filename, mode));
}
