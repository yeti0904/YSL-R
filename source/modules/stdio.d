module yslr.modules.stdio;

import std.array;
import std.stdio;
import yslr.environment;

static Variable Println(string[] args, Environment env) {
	writeln(args.join(" "));
	return [];
}

Module Module_Stdio() {
	Module ret;
	ret["println"] = Function.CreateBuiltIn(false, [], &Println);
	return ret;
}
