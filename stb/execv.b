execv(string, argv, argc) {
  extrn syscall;
  syscall(11, string, argv, envp);
}
