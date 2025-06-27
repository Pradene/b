main() {
  auto i, r;
  i = 0;
  r = 0;
  switch (i) {
    case 0:
      r = r + 1;
    case 1:
      r = r + 2;
    case 2:
      r = r + 4;
  }

  return (r);
}
