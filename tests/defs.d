module tests.defs;

void entryTest(string for_, string mod = __MODULE__, int line = __LINE__) {
    import std.stdio : writeln;
    writeln("Starting test ", for_, " at ", mod, ":", line);
}

void exitTest(string for_, string mod = __MODULE__, int line = __LINE__) {
    import std.stdio : writeln;
    writeln("Finished test ", for_, " at ", mod, ":", line);
}

void testOutput(string mod = __MODULE__, int line = __LINE__, T...)(T args) {
    import std.stdio : writeln, write, stdout;
    import std.traits : isSomeString;

    writeln("\\/ \\/ Output: ", mod, ":", line, " text \\/ \\/");
    write("\t");

    foreach(v; args) {
        static if (isSomeString!(typeof(v))) {
            foreach(c; v) {
                if (c == '\n') {
                    write("\n\t");
                } else {
                    write(c);
                }
            }
        } else {
            write(v);
        }
    }

    writeln();
    writeln("/\\ /\\ Output: ", mod, ":", line, " text /\\ /\\");
    stdout.flush;
}

string tempLocation(string for_) {
    import std.path : buildPath;
    import std.file : tempDir, exists, mkdirRecurse;
    import std.process : thisProcessID;
    import std.conv : text;

    string tempLoc = buildPath(tempDir(), thisProcessID.text);
    if (!exists(tempLoc))
        mkdirRecurse(tempLoc);

    return buildPath(tempLoc, for_);
}
