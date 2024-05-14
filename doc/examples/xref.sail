default Order dec

$include <prelude.sail>

val foo : unit -> unit

val baz : unit -> unit

function baz() = {
  print_endline("This is the baz function")
}

val bar : unit -> unit

function bar() = {
  foo();
  baz()
}
