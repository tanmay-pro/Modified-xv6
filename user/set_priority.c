#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fcntl.h"

int main(int argc, char **argv)
{
    if (argc != 3)
    {
        printf("Usage: set_priority <pid> <priority>\n");
        exit(1);
    }
    int pid = atoi(argv[2]);
    int priority = atoi(argv[1]);
    if(priority < 0 || priority > 100)
    {
        printf("Invalid priority\n");
        exit(1);
    }
    int result = set_priority(priority, pid);
    printf("Prioirty changed from %d to %d\n", result, priority);
    exit(0);
}