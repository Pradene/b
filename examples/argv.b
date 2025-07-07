putchar(c) {
  extrn syscall;
  syscall(4, 1, &c, 1);
}

puts(s) {
  extrn char;
  auto i, c;
  i = 0;
  while ((c = char(s, i)) != 0) {
    putchar(c);
    i =+ 1;
  }
  putchar('\n');
}

main(argc, argv) {
  auto i;
  i = 0;
  while ((++i) < argc) {
    puts(argv[i]);
  }
  return (0);
}
