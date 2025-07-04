chown(string, owner) {
  extrn syscall;
  return (syscall(182, string, owner, 0));
}
