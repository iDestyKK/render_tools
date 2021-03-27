CC = g++
CFLAGS = --std=c++98

all: hdr_datagen txt2srt

hdr_datagen: hdr_datagen.cpp
	$(CC) $(CFLAGS) -o $@ $^

txt2srt: txt2srt.cpp
	$(CC) $(CFLAGS) -o $@ $^

clean:
	$(RM) hdr_datagen txt2srt
