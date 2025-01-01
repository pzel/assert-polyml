.PHONY: test
LIBDIR := lib/github.com/pzel/assert-polyml

test: $(shell find $(LIBDIR) | grep .sml$$)
	polymlb -o ./bin/runTests -- $(LIBDIR)/test/runTests.mlb && ./bin/runTests

