char(s, i) {
  return (s[i]);
}

main() {
  extrn putchar;
  auto i, s, c;
  i = 0;
  s = "hello world\n";
  c = char(s, i);
  return (c);
}
