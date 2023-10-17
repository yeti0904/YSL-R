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

static Variable Print(string[] args, Environment env) {
	write(args.join(" "));
	return [];
}

static Variable Getch(string[] args, Environment env) {
	return [getchar()];
}

static Variable Input(string[] args, Environment env) {
	return StringToIntArray(readln()[0 .. $ - 1]);
}

Module Module_Stdio() {
	Module ret;
	ret["println"] = Function.CreateBuiltIn(false, [], &Println);
	ret["print"]   = Function.CreateBuiltIn(false, [], &Print);
	ret["getch"]   = Function.CreateBuiltIn(false, [], &Getch);
	ret["input"]   = Function.CreateBuiltIn(false, [], &Input);
	return ret;
}
