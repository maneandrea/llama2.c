# choose your compiler, e.g. gcc/clang
# example override to clang: make run CC=clang
CC = gcc

PREFIX = 'build/'

# build also the python bindings
.PHONY: build
build: run.c llamamodule.c
	mkdir -p $(PREFIX)
	$(CC) -O3 -c -o $(PREFIX)run.o run.c -lm
	$(CC) -O3 $(shell pkg-config --cflags python3) \
		-o $(PREFIX)llama.so llamamodule.c \
		-fPIC -shared

# the most basic way of building that is most likely to work on most systems
.PHONY: run
run: run.c
	mkdir -p $(PREFIX)
	$(CC) -O3 -o $(PREFIX)run run.c -lm
	$(CC) -O3 -o $(PREFIX)runq runq.c -lm

# useful for a debug build, can then e.g. analyze with valgrind, example:
# $ valgrind --leak-check=full ./run out/model.bin -n 3
rundebug: run.c
	mkdir -p $(PREFIX)
	$(CC) -g -o $(PREFIX)run run.c -lm
	$(CC) -g -o $(PREFIX)runq runq.c -lm

# https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html
# https://simonbyrne.github.io/notes/fastmath/
# -Ofast enables all -O3 optimizations.
# Disregards strict standards compliance.
# It also enables optimizations that are not valid for all standard-compliant programs.
# It turns on -ffast-math, -fallow-store-data-races and the Fortran-specific
# -fstack-arrays, unless -fmax-stack-var-size is specified, and -fno-protect-parens.
# It turns off -fsemantic-interposition.
# In our specific application this is *probably* okay to use
.PHONY: runfast
runfast: run.c
	mkdir -p $(PREFIX)
	$(CC) -Ofast -o $(PREFIX)run run.c -lm
	$(CC) -Ofast -o $(PREFIX)runq runq.c -lm

# additionally compiles with OpenMP, allowing multithreaded runs
# make sure to also enable multiple threads when running, e.g.:
# OMP_NUM_THREADS=4 ./run out/model.bin
.PHONY: runomp
runomp: run.c	
	mkdir -p $(PREFIX)
	$(CC) -Ofast -fopenmp -march=native run.c  -lm  -o $(PREFIX)run
	$(CC) -Ofast -fopenmp -march=native runq.c  -lm  -o $(PREFIX)runq

.PHONY: win64
win64:
	mkdir -p $(PREFIX)
	x86_64-w64-mingw32-gcc -Ofast -D_WIN32 -o $(PREFIX)run.exe -I. run.c win.c
	x86_64-w64-mingw32-gcc -Ofast -D_WIN32 -o $(PREFIX)runq.exe -I. runq.c win.c

# compiles with gnu99 standard flags for amazon linux, coreos, etc. compatibility
.PHONY: rungnu
rungnu:
	mkdir -p $(PREFIX)
	$(CC) -Ofast -std=gnu11 -o $(PREFIX)run run.c -lm
	$(CC) -Ofast -std=gnu11 -o $(PREFIX)runq runq.c -lm

.PHONY: runompgnu
runompgnu:
	mkdir -p $(PREFIX)
	$(CC) -Ofast -fopenmp -std=gnu11 $(PREFIX)run.c  -lm  -o run
	$(CC) -Ofast -fopenmp -std=gnu11 $(PREFIX)runq.c  -lm  -o runq

# run all tests
.PHONY: test
test:
	pytest

# run only tests for run.c C implementation (is a bit faster if only C code changed)
.PHONY: testc
testc:
	pytest -k runc

# run the C tests, without touching pytest / python
# to increase verbosity level run e.g. as `make testcc VERBOSITY=1`
VERBOSITY ?= 0
.PHONY: testcc
testcc:
	$(CC) -DVERBOSITY=$(VERBOSITY) -O3 -o $(PREFIX)testc test.c -lm
	./testc

.PHONY: clean
clean:
	rm -f run
	rm -f runq
