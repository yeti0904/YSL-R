module yslr.modules.stdfunc;

import std.conv;
import std.array;
import std.stdio;
import yslr.environment;

static Variable NewFunc(string[] args, Environment env) {
	Function func;
	func.strictArgs = false;
	func.builtIn    = false;
	func.label      = parse!int(args[1]);
	func.from       = "custom";

	env.functions[args[0]] = func;
	return [];
}

Module Module_Stdfunc() {
	Module ret;
	ret["new_func"] = Function.CreateBuiltIn(
		true, [ArgType.Other, ArgType.Numerical], &NewFunc
	);
	return ret;
}
