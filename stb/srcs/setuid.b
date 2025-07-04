setuid(id) {
  extrn syscall;
  return (syscall(23, id));
}
