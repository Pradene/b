write(file, buffer, count) {
  syscall(4, file, buffer, count);
}
