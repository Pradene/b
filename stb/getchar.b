getchar() {
  auto buf;
  syscall(3, 1, &buf, 1);
  return (buf);
}
