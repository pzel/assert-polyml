.PHONY: test

test:	$(shell find . | grep .sml$$)
	polymlb -o ./bin/runTests runTests.mlb && ./bin/runTests

assertTest: assertTest.sml assert.sml
	polyc $< -o $@
