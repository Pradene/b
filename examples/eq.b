zero() {
  return (0);
}

main() {
  extrn char;
  auto s;
  s = "Hello";
  return ((char(s, 0) == 'H') ? 0 : 1);
}
