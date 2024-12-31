.PHONY: test

test:
	polymlb -o ./bin/runTests runTests.mlb && ./bin/runTests

assertTest: assertTest.sml assert.sml
	polyc $< -o $@
