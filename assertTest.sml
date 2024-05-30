use "assert";

fun main() =
    let open Assert
        exception TestExn of string;
        infixr 2 == != =/= =?=;
        val passingTests = [
          It "adds numbers correctly" (fn() => 3 + 3 == 6),
          It "can compare record types" (fn() => {a=1} == {a=1}),
          It "can assert that an exn was raised" (fn()=> TestExn("hello") != (fn()=> raise TestExn("hello")))
        ];
        val failingTests = [
          T(fn () => 3 + 2 == 4),
          T(fn()=> 3 + 3 == ~1),
          T(fn()=> {a = "a", b=2} == {a = "A", b=2}),
          T(fn()=> Subscript != (fn()=> tl(tl[1]))),
          T(fn()=> Empty != (fn()=> hd [1])),
          T(fn()=> ignore(2 + 2)),
          T(fn()=> TestExn("hellop") != (fn()=> raise TestExn("hello"))), (*fails*)
          T(fn()=> fail("this should never happen"))
        ];
    in
      runTests (passingTests @ failingTests)
    end
