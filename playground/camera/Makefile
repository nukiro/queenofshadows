CC=gcc
CFLAGS=-Wall -Wextra -pedantic -std=c23
LIBS=-lraylib -lm -ldl -lpthread -lGL -lrt -lX11

# Directories
SRCDIR = src
OBJDIR = obj

# Source files
# get a list of all the C source files in a directory
SOURCES = $(wildcard $(SRCDIR)/*.c)
OBJECTS = $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)

# Target executable
TARGET = game

# Default target
all: $(TARGET)

# Create object directory
$(OBJDIR):
	@mkdir -p $(OBJDIR)

# Compile source files to object files
$(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR)
	@$(CC) $(CFLAGS) -c $< -o $@

# Link object files to create executable
$(TARGET): $(OBJECTS)
	@$(CC) $(OBJECTS) -o $@ $(LIBS)

# Clean build files
clean:
	@rm -rf $(OBJDIR) $(TARGET)

# Rebuild everything
rebuild: clean all

.PHONY: all clean rebuild