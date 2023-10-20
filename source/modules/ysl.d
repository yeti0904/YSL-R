module yslr.modules.ysl;

import std.conv;
import std.array;
import std.stdio;
import yslr.util;
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

static Variable GetLine(string[] args, Environment env) {
	int line = parse!int(args[0]);

	if (line !in env.code) {
		stderr.writefln("Error: get_line: Line %d doesn't exist", line);
		throw new YSLError();
	}

	env.returnStack ~= StringToIntArray(env.code[line]);
	return [];
}

static Variable GetLines(string[] args, Environment env) {
	int[] ret;

	foreach (key, ref value ; env.code) {
		ret ~= key;
	}

	return ret;
}

Module Module_Ysl() {
	Module ret;
	ret["reset"]     = Function.CreateBuiltIn(true, [], &Reset);
	ret["get_line"]  = Function.CreateBuiltIn(true, [ArgType.Numerical], &GetLine);
	ret["get_lines"] = Function.CreateBuiltIn(true, [], &GetLines);
	return ret;
}
