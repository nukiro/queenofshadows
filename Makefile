CC=gcc
CFLAGS=-Wall -Wextra -pedantic -std=c23

SRC=camera.c hero.c main.c
OBJS=$(SRC:.c=.o)

LIBS=-lraylib -lm -ldl -lpthread -lGL -lrt -lX11

all: queen

%.o: %.c
	@$(CC) -c -o $(@F) $(CFLAGS) $<

queen: $(OBJS)
	@$(CC) $(CFLAGS) -o $(@F) $(OBJS) $(LIBS)

clean:
	@rm -f $(OBJS)
	@rm -f queen