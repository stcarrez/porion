#include <stdio.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/resource.h>

struct porion_usage {
    long long utime;
    long long stime;
};

void porion_get_rusage(struct porion_usage *usage) 
{
    struct rusage rusage;

    if (getrusage(RUSAGE_CHILDREN, &rusage) != 0) {
        usage->utime = 0;
        usage->stime = 0;
        return;
    }

    usage->utime = (rusage.ru_utime.tv_sec * 1000) + (rusage.ru_utime.tv_usec / 1000);
    usage->stime = (rusage.ru_stime.tv_sec * 1000) + (rusage.ru_stime.tv_usec / 1000);
}

   