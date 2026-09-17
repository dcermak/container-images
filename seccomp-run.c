#include <errno.h>
#include <seccomp.h>
#include <stdio.h>
#include <unistd.h>

int main(int argc, char **argv) {
  if (argc < 2) {
    fprintf(stderr, "usage: %s PROGRAM [ARGS...]\n", argv[0]);
    return 2;
  }

  scmp_filter_ctx ctx = seccomp_init(SCMP_ACT_ALLOW);
  if (!ctx) {
    perror("seccomp_init");
    return 1;
  }

  static const int syscalls[3] = {SCMP_SYS(add_key), SCMP_SYS(keyctl),
                                  SCMP_SYS(request_key)};

  for (int i = 0; i < 3; ++i) {
    const int err =
        seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), syscalls[i], 0);

    if (err != 0) {
      perror("seccomp_rule_add");
      return 1;
    }
  }

  if (seccomp_load(ctx) < 0) {
    fprintf(stderr, "could not install seccomp filter\n");
    return 1;
  }

  seccomp_release(ctx);

  execvp(argv[1], &argv[1]);
  perror("execvp");
  return 1;
}
