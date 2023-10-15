module yslr.modules.core;

import std.conv;
import std.stdio;
import std.string;
import core.stdc.stdlib;
import yslr.util;
import yslr.environment;

static Variable Var(string[] args, Environment env) {
	if (args.length < 2) {
		stderr.writefln("Error: var: Requires 2 arguments: variable name and operator");
		throw new YSLError();
	}

	string var = args[0];

	switch (args[1]) {
		case "=": {
			if (args[2].isNumeric()) {
				int[] array;
				
				for (int i = 2; i < args.length; ++ i) {
					array ~= parse!int(args[i]);
				}

				env.CreateVariable(var, array);
			}
			else {
				env.CreateVariable(var, args[2].StringToIntArray());
			}
			break;
		}
		default: {
			stderr.writefln("Error: var: Unknown operator %s", args[1]);
			throw new YSLError();
		}
	}

	return [];
}

static Variable Goto(string[] args, Environment env) {
	if (!args[0].isNumeric()) {
		stderr.writefln("Error: goto: Invalid argument");
		throw new YSLError();
	}

	int line = parse!int(args[0]);

	foreach (entry ; env.code.entries) {
		if (entry.value.key == line) {
			env.ip        = entry;
			env.increment = false;
			return [];
		}
	}

	stderr.writefln("Error: goto: Couldn't find line %d", line);
	return [];
}

static Variable Exit(string[] args, Environment env) {
	exit(0);
}

Module Module_Core() {
	Module ret;
	ret["var"]  = Function.CreateBuiltIn(false, [], &Var);
	ret["goto"] = Function.CreateBuiltIn(true, [ArgType.Other], &Goto);
	ret["exit"] = Function.CreateBuiltIn(false, [], &Exit);
	return ret;
}
