main() {
  auto i, max;
  i = 0;
  max = 10;

  loop:
  if (i >= max) {
    return (i);
  }
  i =+ 1;

  goto loop;
  return (1);
}
