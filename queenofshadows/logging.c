#include "logging.h"

#include "error.h"

#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

struct Logger create_logger(int level)
{
    if (level < 0)
        die("level must be between 0 and 5");
    if (level > 5)
        die("level must be between 0 and 5");

    return (struct Logger){
        .level = level};
}

// struct Logger *create_logger(int level)
// {
//     if (level < 0)
//         die("level must be between 0 and 5");
//     if (level > 5)
//         die("level must be between 0 and 5");

//     struct Logger *l;

//     // dynamically allocate memory
//     l = (struct Logger *)malloc(sizeof(*l));
//     if (l != NULL)
//         l->level = level;

//     return l;
// }

// void destroy_logger(struct Logger *l)
// {
//     if (l == NULL)
//         die("logger pointer must not be null");

//     free(l);
// }

int format(const char *level, const char *msg)
{
    time_t ct;      /* long integer which hold current time */
    struct tm *lct; /* structure that contains a calendar time broken down into its components */
    char ts[100];   /* formatted string holding current time */
    char b[1024];   /* log entry displayed */

    // get current time
    time(&ct);
    // check current time was obtained correctly
    if (ct == ((time_t)-1))
        die("Failure to obtain the current time");

    // transform it to localtime and break down into tm struct
    lct = localtime(&ct);
    // check cast to string if ts is no big enough will fail
    if (!strftime(ts, sizeof(ts), "%F %T %z", lct))
        /*
        - 0 will be returned by strftime if an error occurs formatting time
        - null character is added by strftime
        */
        die("Failure to format the current time");

    // build log entry: time level message
    // copy ts to initialize b string
    strcpy(b, ts);
    strcat(b, " ");
    strcat(b, level);
    strcat(b, "\t");
    strcat(b, msg);
    strcat(b, "\n");

    // write formatted string to the stream
    return (int)write(STDOUT_FILENO, b, strlen(b));
}

bool check(const struct Logger *l, const int level)
{
    // if (l == NULL)
    //     die("logger pointer must not be null");

    if (l->level > level)
        return false;

    return true;
}

int debug(const struct Logger *l, const char *msg)
{
    if (!check(l, DEBUG))
        return 0;

    return format("\x1b[4mDEBUG\x1b[0m", msg);
}

int info(const struct Logger *l, const char *msg)
{
    if (!check(l, INFO))
        return 0;

    return format("\x1b[32mINFO\x1b[0m", msg);
}

int warn(const struct Logger *l, const char *msg)
{
    if (!check(l, WARN))
        return 0;

    return format("\x1b[33mWARN\x1b[0m", msg);
}

int error(const struct Logger *l, const char *msg)
{
    if (!check(l, ERROR))
        return 0;

    return format("\x1b[31mERROR\x1b[0m", msg);
}

int fatal(const struct Logger *l, const char *msg)
{
    if (!check(l, FATAL))
        return 0;

    return format("\x1b[35mFATAL\x1b[0m", msg);
}
