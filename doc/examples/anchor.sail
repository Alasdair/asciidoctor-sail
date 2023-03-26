default Order dec
$include <string.sail>

/*! This demonstrates the use of an _anchor_ directive to provide a
name to a free standing documentation comment without a toplevel
definition. */
$anchor my_comment

/*! Documentation comment for `main`. */
function main() -> unit = {
    print_endline("Hello, World!")
}
