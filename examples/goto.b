main() {
  auto i, m;
  i = 0;
  m = 10;

  loop:
  if (i < m) {
    i =+ 1;
    goto loop;
  }

  i === m;
  return (i);
}
