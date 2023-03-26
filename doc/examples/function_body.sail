default Order dec
$include <prelude.sail>

/*! We can choose to display this entire function, or we can just
display its body. There are various options to control the body
formatting. */
function main() -> unit = {
    let str = "Hello, World!";
    print_endline(str);
    print_endline("Goodbye!")
}
