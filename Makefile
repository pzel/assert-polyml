.PHONY: test

test: assertTest
	./assertTest

assertTest: assertTest.sml assert.sml
	polyc $< -o $@
