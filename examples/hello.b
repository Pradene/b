char(s, i) {
  return (s[i]);
}

main() {
  extrn putchar;
  auto i, s, c;
  i = 0;
  s = "Hello world";
  while ((c = char(s, i)) != 0) {
    putchar(c);
    ++i;
  }

  return (0);
}
