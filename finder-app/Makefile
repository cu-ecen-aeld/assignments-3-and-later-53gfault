# Simple Makefile for the finder‑app/writer utility
# Supports native builds and cross‑compilation via the CROSS_COMPILE variable.
# Example cross build:
#     make CROSS_COMPILE=aarch64-none-linux-gnu-

# ---- Toolchain -------------------------------------------------------------
CC      ?= $(CROSS_COMPILE)gcc
AR      ?= $(CROSS_COMPILE)ar
STRIP   ?= $(CROSS_COMPILE)strip

# ---- Project files ---------------------------------------------------------
TARGET  := writer
SRC     := writer.c
OBJ     := $(SRC:.c=.o)

# ---- Flags -----------------------------------------------------------------
CFLAGS  ?= -Wall -Werror -g
LDFLAGS ?=

# ---- Default target --------------------------------------------------------
.PHONY: all
all: $(TARGET)

# ---- Link step -------------------------------------------------------------
$(TARGET): $(OBJ)
	$(CC) $(LDFLAGS) $^ -o $@

# ---- Compile step ----------------------------------------------------------
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# ---- Clean -----------------------------------------------------------------
.PHONY: clean
clean:
	rm -f $(TARGET) $(OBJ)

# ---------------------------------------------------------------------------
# End of Makefile

