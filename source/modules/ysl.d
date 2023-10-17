module yslr.modules.ysl;

import std.conv;
import std.array;
import std.stdio;
import yslr.environment;

static Variable Reset(string[] args, Environment env) {
	Function[string] noFunctions;
	Module[string]   noModules;
	Scope            noScope; // 420

	env.globals     = noScope; // 420
	env.locals      = cast(Scope[])    [];
	env.returnStack = cast(Variable[]) [];
	env.callStack   = cast(int[])      [];
	env.passStack   = cast(Variable[]) [];
	return [];
}

Module Module_Ysl() {
	Module ret;
	ret["reset"] = Function.CreateBuiltIn(
		true, [ArgType.Other, ArgType.Numerical], &Reset
	);
	return ret;
}
