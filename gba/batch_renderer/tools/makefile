CC = gcc
CFLAGS = --std=gnu89 -O3

all: vbm2unixts

vbm2unixts: vbm2unixts.c
	$(CC) $(CFLAGS) -o $@ $^

clean:
	$(RM) vbm2unixts
