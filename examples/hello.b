char(s, i) {
  return (s[i]);
}

main() {
  auto i, s, c, t;
  i = 1;
  s = "Hello world\n";
  c = char(s, i);
  t = c == 'e';
  return (t);
}
