#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>

int main() {
    setreuid(geteuid(), geteuid());
    setregid(geteuid(), geteuid());

    system("/bin/sh");
    return 0;
}