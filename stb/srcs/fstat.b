fstat(string, status) {
  extrn syscall;
  return (syscall(108, string, status));
}
