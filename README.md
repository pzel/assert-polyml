Assert: An ergonomic testing library for Poly/ML
================================================

```
signature ASSERT = sig
  type testresult = (string * bool);
  type tcase;
  type raisesTestExn;
  val It : string -> (unit -> raisesTestExn) -> tcase;
  val T : (unit -> raisesTestExn) -> tcase;
  val succeed : string -> raisesTestExn;
  val fail : string -> raisesTestExn;
  val == : (''a * ''a) -> raisesTestExn;
  val =/= : (''a * ''a) -> raisesTestExn;
  val != : (exn * (unit -> 'z)) -> raisesTestExn;
  val =?= : (''a * ''a) -> ''a;
  val runTest : tcase -> testresult;
  val runTests : tcase list -> unit;
end
```

___________________________________________________

TLDR: How to use this
---------------------

### 1: Include the file [assert.sml](assert.sml) in your project.

```
use "assert";
```

### 2: Open the `Assert` module and declare the fixity of the assertion functions.

```
open Assert;
infixr 2 == != =/= =?=;
```

### 3: Write some tests.

```
val myTests = [
  It "adds integers" (fn() => 2 + 2 == 5),
  It "concatenates strings" (fn() => "foo" ^ "bar" == "foolbar"),
  It "raises Subscript" (fn()=> Subscript != (fn() => String.sub("hello", 1)))
];
```

### 4: Run your tests and exit the process with a POSIX error code.

```
> runTests myTests;

FAILED adds integers
	4 <> 5

FAILED concatenates strings
	"foobar" <> "foolbar"

FAILED raises Subscript
	Subscript <> ~ran successfully~


TESTS FAILED: 3/3

$ echo $?
1
```

___________________________________________________

Test constructors
-----------------

Create tests with either the `T` function

```
T (fn () => 2 + 2 == 4)
```

Or the `It` function:

```
It "can put two and two together" (fn () => 2 + 2 == 4)
```

You can run an individual test with `runTest`:

```
> val t1 = T (fn () => 2 + 2 == 4);
val t1 = TC ("", fn): tcase
> runTest t1;
val it = ("OK \n\t4 = 4\n", true): testresult
```

The `testresult` type is a tuple where the first element is a printable
description of the test result, and the second element indicates success or
failure.

```
> val t2 = T (fn () => "a" ^ "b" == "abc");
val t2 = TC ("", fn): tcase
> runTest t2;
val it = ("FAILED \n\t\"ab\" <> \"abc\"\n", false): testresult
```

You can imperatively run a `testcase list` to get formatted output printed to
stdout, and have the entire SML program exit with a POSIX success code if there
were no failures, and an error code if some tests did not pass.

```
runTests [t1, t2];

FAILED
	"ab" <> "abc"


TESTS FAILED: 1/2

$ echo $?
1
```

___________________________________________________

Assertions
-----------------

Let's take a look at the type of the `It` function above:

```
> Assert.It;
val it = fn: string -> (unit -> Assert.raisesTestExn) -> Assert.tcase
```

It takes a string that describes the test case, and then a function typed
`(unit -> Assert.raisesTestExn)`. How do we obtain such a function? By
embedding within its body one of the assertions offered by the module. They are
listed below.



### succeed (msg : string)

This assertion 'manually' passes a test. For example, in cases where the data
under test doesn't support equality.

```
> val t1 = T (fn () => if Real.==(Real.*(2.0, 2.0), 4.0)
                       then succeed "reals are equal"
                        else fail "reals not equal");
val t1 = TC ("", fn): tcase
> runTest t1;
val it = ("OK \n\treals are equal = reals are equal\n", true): testresult
```

### fail (msg : string)

The counterpart to `succeed`. Makes a test fail when executed.

```
> val t2 = T (fn () => if Real.==(Real.*(2.0, 2.0), 5.0)
                       then succeed "reals are equal"
                       else fail "reals not equal");
val t2 = TC ("", fn): tcase
> runTest t2;
val it = ("FAILED \n\treals not equal <> ~explicit fail~\n", false):
   testresult
```

### (left : ''a) == (right : ''a)

Fails the test case if `left` and `right` are not equal. The first element of
the testresult will contain string representations of the data (courtesy of
`PolyML.makestring`).

```
> val t4 = T (fn () => {a="record"} == {a="cd"});
val t4 = TC ("", fn): tcase
> runTest t4;
val it = ("FAILED \n\t{a = \"record\"} <> {a = \"cd\"}\n", false): testresult
> print (#1 it);
FAILED
	{a = "record"} <> {a = "cd"}
val it = (): unit
```

### (left : ''a) =/= (right : ''a)

The inverse of `==`. Will fail the test case if `left` and `right` _are_ equal.


### (expected : exn) != (f : (unit -> 'z))

Succeeds when `f`, after evaluation, raises exception `exn`. Both the exception
name and message must match. If the function runs successfully, the test case
is counted as a failure.

```
> runTest (T (fn () => (Boom "Aaa!") != (fn () => raise Boom "zzz")));
val it = ("FAILED \n\tBoom \"Aaa!\" <> Boom \"zzz\"\n", false): testresult
> print (#1 it);
FAILED
	Boom "Aaa!" <> Boom "zzz"
val it = (): unit

> runTest (T (fn () => (Boom "Aaa!") != (fn ()=> 2 + 2)));
val it = ("FAILED \n\tBoom \"Aaa!\" <> ~ran successfully~\n", false):
   testresult
> print (#1 it);
FAILED
	Boom "Aaa!" <> ~ran successfully~
val it = (): unit

> runTest (T (fn () => (Boom "Aaa!") != (fn () => raise Boom "Aaa!")));
val it = ("OK \n\tBoom \"Aaa!\" = Boom \"Aaa!\"\n", true): testresult
> print (#1 it);
OK
	Boom "Aaa!" = Boom "Aaa!"
val it = (): unit

```


### (left : ''a) =?= (right : ''a)

This is a classic "assert" function, in the sense that it will simply return
`left` if it's equal to `right`, but if the two operands are *not* equal, it
will fail the entire test case.

Useful for getting around match exhaustiveness warnings when you want
match-based assertions throughout your test, like in Erlang. This approach is
problematic in Standard ML, because "assertively" matching on expected values
will generate "Matches are not exhaustive" messages, like below:

```
  let val ALGOOD = (someOp() =?= ALLGOOD);
      val foo = worksOnAllGood(ALLGOOD);
      ...
```

If we'd like to get rid of all exhaustiveness warnings, we can use `=?=` to
encode our expectations on the right side of the match, while keeping the left
side non-specific, like so:

```
  let val ag = (someOp() =?= ALLGOOD);
      val foo = worksOnAllGood(ag);
      ...
```

The above will fail the test if `someOp` does not return ALLGOOD. If it does,
it'll bind `ag` to `ALLGOOD` and proceed to evaluate subsequent expressions as
normal.

  

