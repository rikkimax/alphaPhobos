import std.stdio : writeln;

version(unittest) {
} else {
	static assert(0, "Please compile with unittesting enabled");
}

void main() {
    writeln("Unittests for alphaPhobos has run successfully.");
}
