getuid() {
  extrn syscall;
  return (syscall(20));
}
