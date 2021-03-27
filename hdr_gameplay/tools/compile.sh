#!/bin/bash

# Make bin folder if it doesn't already exist
if [ ! -d "bin" ]; then
	mkdir "bin"
fi

# Make directory specifically for whatever platform you're on
if [ ! -d "bin/$OSTYPE" ]; then
	mkdir "bin/$OSTYPE"
fi

# Compile away
g++ -o "bin/$OSTYPE/hdr_datagen" "hdr_datagen.cpp"
g++ -o "bin/$OSTYPE/txt2srt" "txt2srt.cpp"
