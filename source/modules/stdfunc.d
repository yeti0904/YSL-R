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

static Variable CloneFunc(string[] args, Environment env) {
	if (args[0] !in env.functions) {
		stderr.writefln("Error: clone_func: No such function '%s'", args[0]);
		throw new YSLError();
	}

	env.functions[args[1]] = env.functions[args[0]];
	return [];
}

static Variable SetArgs(string[] args, Environment env) {
	if (args.empty()) {
		stderr.writeln("Error: set_args: At least 1 parameter required");
		throw new YSLError();
	}

	if (args[0] !in env.functions) {
		stderr.writefln("Error: set_args: No such function %s", args[0]);
		throw new YSLError();
	}

	ArgType[] argsList;

	for (size_t i = 1; i < args.length; ++ i) {
		switch (args[i]) {
			case "num": {
				argsList ~= ArgType.Numerical;
				break;
			}
			case "other": {
				argsList ~= ArgType.Other;
				break;
			}
			default: {
				stderr.writefln("Error: set_args: Invalid type '%s'", args[i]);
				throw new YSLError();
			}
		}
	}

	env.functions[args[0]].strictArgs   = true;
	env.functions[args[0]].requiredArgs = argsList;
	return [];
}

static Variable VarArgs(string[] args, Environment env) {
	if (args[0] !in env.functions) {
		stderr.writefln("Error: var_args: No such function '%s'", args[0]);
		throw new YSLError();
	}

	env.functions[args[0]].strictArgs   = false;
	env.functions[args[0]].requiredArgs = [];
	return [];
}

Module Module_Stdfunc() {
	Module ret;
	ret["new_func"]   = Function.CreateBuiltIn(true, [ArgType.Other, ArgType.Numerical], &NewFunc);
	ret["clone_func"] = Function.CreateBuiltIn(true, [ArgType.Other, ArgType.Other], &CloneFunc);
	ret["set_args"]   = Function.CreateBuiltIn(false, [], &SetArgs);	
	ret["var_args"]   = Function.CreateBuiltIn(true, [ArgType.Other], &VarArgs);
	return ret;
}
