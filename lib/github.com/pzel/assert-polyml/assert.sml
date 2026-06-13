signature ASSERT = sig
  type testresult = (string * bool);
  type tcase;
  type raisesTestExn;
  val It : string -> (unit -> raisesTestExn) -> tcase;
  val T : (unit -> raisesTestExn) -> tcase;
  val Pending : string -> (unit -> raisesTestExn) -> tcase;
  val succeed : string -> raisesTestExn;
  val fail : string -> raisesTestExn;
  val == : (''a * ''a) -> raisesTestExn;
  val =/= : (''a * ''a) -> raisesTestExn;
  val != : (exn * (unit -> 'z)) -> raisesTestExn;
  val =?= : (''a * ''a) -> ''a;

  (* V0.5+ API: Poly no longer carries type info at runtime, so
     PolyML.makestring will always spit out '?'
     unless the type is  known at compile-time
   *)
  val eq : (''a -> string) -> (''a * ''a) -> raisesTestExn;
  val neq : (''a -> string) -> (''a * ''a) -> raisesTestExn;

  val runTest : tcase -> testresult;
  val runTests : tcase list -> unit;
end


structure Assert = struct

exception TestOK of string * string;
exception TestErr of string * string;
datatype raisesTestExn = RAISES of unit;
infixr 2 == != =/= =?=;

fun return (a: 'a) : raisesTestExn = RAISES (ignore a);

type testresult = (string * bool);
datatype tcase = TC of (string * (unit -> raisesTestExn))

fun succeed (msg : string) : raisesTestExn =
    return (raise TestOK (msg, msg))

fun fail (msg : string) : raisesTestExn =
    return (raise TestErr (msg, "~explicit fail~"))

fun It desc t = TC(desc, t)
fun T t = TC("", t)
fun Pending desc _ = TC(desc, fn () => succeed "~PENDING~")


fun eq show (left : ''a, right: ''a) : raisesTestExn =
    return (if left <> right
           then raise TestErr (show left, show right)
           else raise TestOK (show left, show right))

fun neq show (left : ''a, right: ''a) : raisesTestExn =
    return (if left = right
           then raise TestErr (show left, show right)
           else raise TestOK (show left, show right))

fun showQuestionMark (_ : 'a) : string =
    "?";

fun (left : ''a) == (right : ''a) : raisesTestExn =
    eq showQuestionMark (left, right)

fun (left : ''a) =/= (right : ''a) : raisesTestExn =
    neq showQuestionMark (left, right)

fun (expected : exn) != (f : (unit -> 'z)) : raisesTestExn =
    (return (ignore(f())
             handle e => let val (exp, got) = (exnMessage expected, exnMessage e);
                            fun fmt e = "exception "^ e;
                        in if exp = got
                           then raise TestOK (fmt exp, fmt got)
                           else raise TestErr (fmt exp, fmt got)
                        end);
     (* We ran left() without any errors, even though we expected them.
        This makes the current test case a failure. *)
     raise TestErr (exnMessage expected, "~did not raise~"))

fun (left : ''a) =?= (right : ''a) : ''a =
    if left = right
    then left
    else raise (TestErr ("Assertion failed:", "~values not equal~"))


fun runTest ((TC (desc,f)) : tcase) : testresult =
    let fun fmt (result, data) =
            String.concat([result, " ", desc, "\n\t", data, "\n"]);
        fun ppExn (e : exn) : string = "exception " ^ exnMessage e;
    in
                       (* this outcome is likely uncompileable now
                          that raisesTestExn is opaque *)
      ( f ();             (fmt ("ERROR", "~no assertion in test body~"), false))
      handle TestOK(a,b) =>  (fmt ("OK",  "left:  "^a^"\n\tright: "^b), true)
           | TestErr(a,b) => (fmt ("FAILED", "left:  "^a^"\n\tright: "^b), false)
           | exn =>          (fmt ("ERROR", ppExn exn), false)
    end

fun runTests (tests : tcase list) =
    let
      val results = map runTest tests;
      val errors = List.filter (fn (_, n) => not n) results;
      val successes = List.filter (fn (_, n) => n) results;
      val error_count = length errors;
      val test_count = length results;
      val p = fn s => ignore(print (s ^"\n"));
      val i = Int.toString;
      val error_ratio = concat [i error_count, "/", i test_count];
      val success_ratio = concat [i test_count, "/", i test_count]
    in
      if error_count = 0
      then p ("ALL TESTS PASSED: " ^ success_ratio)
      else (p "";
            (* app (p o #1) successes; *) (* TODO: make this optional *)
            app (p o #1) errors;
            p ("\nTESTS FAILED: " ^ error_ratio ^ "\n");
            OS.Process.exit(OS.Process.failure))
    end

end : ASSERT
