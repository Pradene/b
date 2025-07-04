char(s, i) {
  return (s[i]);
}

putchar(c) {
  extrn syscall;
  syscall(4, 1, &c, 1);
}

puts(s) {
  auto i, c;
  i = 0;
  while ((c = char(s, i)) != 0) {
    putchar(c);
    i =+ 1;
  }
  putchar('\n');
}

main() {
  auto i, s;
  i = 0;
  s = "Hello world";
  puts(s);
  return (0);
}
