CC ?= gcc
CFLAGS ?= -Wall -Werror

TARGET = writer
SRC = writer.c
OBJ = $(SRC:.c=.o)

ifeq ($(CROSS_COMPILE),)
	CC := gcc
else
	CC := $(CROSS_COMPILE)gcc
endif

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(TARGET) *.o

