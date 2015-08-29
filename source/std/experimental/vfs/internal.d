module std.experimental.vfs.internal;

package:

///
string subGlob(string from, size_t count) {
    string ret = from;
    foreach(i; 0 .. count) {
        ret = subGlob(ret);
        if (ret is null)
            return null;
    }
    return ret;
}

///
string subGlob(string from) {
    // in/out of []
    // in/out of {}

    size_t inoutBrackets;

    foreach(i, c; from) {
        if (c == '[' || c == '{')
            inoutBrackets++;
        else if (c == ']' || c == '}') {
            assert(inoutBrackets > 0);
            inoutBrackets--;
        } else if (inoutBrackets == 0 && c == '/' && from.length > i) {
            return from[i + 1 .. $];
        }
    }

    return null;
}

///
unittest {
    assert(subGlob("a.b*c?/d") == "d");
    assert(subGlob("a.b*c?/d", 1) == "d");
    assert(subGlob("a.b*c?/d./e", 2) == "e");
    assert(subGlob("[abc]/{def}/[{a}{z}].", 1) == "{def}/[{a}{z}].");
    assert(subGlob("[abc]/{def}/[{a}{z}].", 2) == "[{a}{z}].");
}

///
string prefixGlob(string from, size_t count)
in {
    assert(count > 0);
} body {
    // in/out of []
    // in/out of {}
    
    size_t inoutBrackets;
    
    foreach(i, c; from) {
        if (c == '[' || c == '{')
            inoutBrackets++;
        else if (c == ']' || c == '}') {
            assert(inoutBrackets > 0);
            inoutBrackets--;
        } else if (inoutBrackets == 0 && c == '/') {
            count--;
            if (count == 0)
                return from[0 .. i];
        }
    }

    if (inoutBrackets == 0 && count == 1)
        return from;

    return null;
}

///
unittest {
    assert(prefixGlob("a.b*c?/d", 1) == "a.b*c?");
    assert(prefixGlob("a.b*c?/d", 2) == "a.b*c?/d");
    assert(prefixGlob("[abc]/{def}/[{a}{z}].", 1) == "[abc]");
    assert(prefixGlob("[abc]/{def}/[{a}{z}].", 2) == "[abc]/{def}");
}

///
size_t globPartCount(string from) {
    // in/out of []
    // in/out of {}
    
    size_t inoutBrackets;
    size_t ret;

    foreach(i, c; from) {
        if (c == '[' || c == '{')
            inoutBrackets++;
        else if (c == ']' || c == '}') {
            assert(inoutBrackets > 0);
            inoutBrackets--;
        } else if (inoutBrackets == 0 && c == '/') {
            ret++;
        }
    }
    
    if (inoutBrackets == 0)
        ret++;
    
    return ret;
}

///
unittest {
    assert(globPartCount("a.b*c?/d") == 2);
    assert(globPartCount("a.b*c?/d./e") == 3);
    assert(globPartCount("[abc]/{def}/[{a}{z}].") == 3);
}

///
auto prefixGlobParts(string from, bool countUp=true) {
    struct Result {
        private {
            string from;
            size_t count;
            size_t i;
            bool countUp;
        }

        this(string from, bool countUp) {
            this.from = from;
            this.count = globPartCount(from);
            this.countUp = countUp;

            if (countUp)
                this.i = 1;
            else
                this.i = this.count;
        }

        @property {
            string front() {
                return prefixGlob(from, i);
            }

            bool empty() {
                if (countUp)
                    return i > count;
                else
                    return i == 0;
            }
        }

        void popFront() {
            if (countUp) {
                assert(i <= count);
                i++;
            } else {
                assert(i > 0);
                i--;
            }
        }
    }

    return Result(from, countUp);
}

///
unittest {
    auto got = prefixGlobParts("a");
    assert(!got.empty);
    assert(got.front == "a");
    got.popFront;
    assert(got.empty);
}

///
unittest {
    bool gotSomething;
    foreach(v; prefixGlobParts("a")) {
        gotSomething = true;
    }
    assert(gotSomething);
}

///
unittest {
    auto got = prefixGlobParts("[abc]/{def}/[{a}{z}].");

    assert(!got.empty);
    assert(got.front == "[abc]");
    got.popFront;

    assert(!got.empty);
    assert(got.front == "[abc]/{def}");
    got.popFront;

    assert(!got.empty);
    assert(got.front == "[abc]/{def}/[{a}{z}].");
    got.popFront;

    assert(got.empty);
}

///
unittest {
    auto got = prefixGlobParts("[abc]/{def}/[{a}{z}].", false);
    
    assert(!got.empty);
    assert(got.front == "[abc]/{def}/[{a}{z}].");
    got.popFront;
    
    assert(!got.empty);
    assert(got.front == "[abc]/{def}");
    got.popFront;
    
    assert(!got.empty);
    assert(got.front == "[abc]");
    got.popFront;
    
    assert(got.empty);
}