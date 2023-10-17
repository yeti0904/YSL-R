module yslr.modules.stdio;

import std.array;
import std.stdio;
import core.stdc.stdio : getchar;
import yslr.util;
import yslr.environment;

static Variable Println(string[] args, Environment env) {
	writeln(args.join(" "));
	return [];
}

static Variable Getch(string[] args, Environment env) {
	return [getchar()];
}

static Variable Input(string[] args, Environment env) {
	return StringToIntArray(readln());
}

Module Module_Stdio() {
	Module ret;
	ret["println"] = Function.CreateBuiltIn(false, [], &Println);
	ret["getch"]   = Function.CreateBuiltIn(false, [], &Getch);
	ret["input"]   = Function.CreateBuiltIn(false, [], &Input);
	return ret;
}
