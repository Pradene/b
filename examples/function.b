add(n1, n2) {
  return (n1 + n2);
}

one() {
  return (1);
}

zero() {
  return (0);
}

main() {
  return (add(zero(), one()) == 1 ? 0 : 1);
}
