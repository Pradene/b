putchar(c) {
  extrn syscall;
  syscall(4, 1, &c, 1);
}

puts(s) {
  extrn char;
  auto i, c;
  i = 0;
  while ((c = char(s, i)) != 0) {
    putchar(c);
    i =+ 1;
  }
}

main() {
  auto i, s;
  i = 0;
  s = "Hello world\n";
  puts(s);
  return (0);
}
