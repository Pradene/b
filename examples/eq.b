char(s, i) {
  return (s[i]);
}

main() {
  auto s;
  s = "Hello";
  return ((char(s, 0) == 'H') ? 0 : 1);
}
