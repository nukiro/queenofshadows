struct Logger;

#define DEBUG 0
#define INFO 1
#define WARN 2
#define ERROR 3
#define FATAL 4
#define OFF 5

struct Logger
{
    int level;
};

struct Logger create_logger(int level);
// struct Logger *create_logger(int level);
// void destroy_logger(struct Logger *l);

int debug(const struct Logger *l, const char *msg);
int info(const struct Logger *l, const char *msg);
int warn(const struct Logger *l, const char *msg);
int error(const struct Logger *l, const char *msg);
int fatal(const struct Logger *l, const char *msg);
