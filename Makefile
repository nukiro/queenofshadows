CC=gcc
CFLAGS=-Wall -Wextra -pedantic -std=c23

SRC=error.c logging.c camera.c hero.c main.c
OBJS=$(SRC:.c=.o)

LIBS=-lraylib -lm -ldl -lpthread -lGL -lrt -lX11

all: queen

%.o: %.c
	@if [ "$(OS)" = "macos" ]; then \
		$(CC) -c -o $(@F) $(CFLAGS) -I/opt/homebrew/Cellar/raylib/5.5/include $<; \
	else \
		@$(CC) -c -o $(@F) $(CFLAGS) $<; \
	fi

queen: $(OBJS)
	@if [ "$(OS)" = "macos" ]; then \
		$(CC) $(CFLAGS) -o $(@F) $(OBJS) -L/opt/homebrew/Cellar/raylib/5.5/lib -lraylib -framework Cocoa -framework IOKit -framework CoreAudio -framework CoreVideo; \
	else \
		@$(CC) $(CFLAGS) -o $(@F) $(OBJS) $(LIBS); \
	fi

clean:
	@rm -f $(OBJS)
	@rm -f queen