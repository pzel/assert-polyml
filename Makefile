.PHONY: all test-polymlb test-mlton
LIBDIR := lib/github.com/pzel/assert-polyml

all: test-polymlb test-mlton

test-mlton: $(shell find $(LIBDIR) | grep .sml$$)
	mlton -output ./bin/runTests.mlton $(LIBDIR)/test/runTests-mlton.mlb && ./bin/runTests.mlton

test-polymlb: $(shell find $(LIBDIR) | grep .sml$$)
	polymlb -output ./bin/runTests.poly $(LIBDIR)/test/runTests.mlb && ./bin/runTests.poly

