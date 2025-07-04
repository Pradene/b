strlen(string) {
  auto i;
  i = -1;
  while (string[++i] != 0) {}
  return (i);
}

main() {
  extrn syscall;
  auto string, size, writed;
  string = "Hello world\n";
  size = strlen(string);
  writed = syscall(4, 1, string, size);
  return (!(writed == size));
}
