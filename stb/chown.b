chown(filename, owner) {
  extrn syscall;
  return (syscall(182, filename, owner, 0));
}
