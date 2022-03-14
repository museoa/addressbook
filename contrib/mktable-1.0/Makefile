CC= gcc
CFLAGS= -g -Wall

mktable: mktable.o parse.o
	$(CC) mktable.o parse.o -o $@

mktable.o: mktable.c parse.h
parse.o: parse.c parse.h
