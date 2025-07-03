char(s, i) {
  return (s[i]);
}

zero() {
  return (0);
}

main() {
  auto s;
  s = "Hello";
  return ((char(s, 0) == 'H') ? 0 : 1);
}
