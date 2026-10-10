SHELL = /usr/bin/sh

BIN_DIR = bin
PROJECT_NAME = tr.sh
BIN = $(BIN_DIR)/$(PROJECT_NAME)

.PHONY: all build clean

all: build
	exec ./$(BIN)

build: $(wildcard *.odin)
	mkdir -p $(BIN_DIR)
	odin build . -out:$(BIN)

clean: 
	rm -f $(BIN)
