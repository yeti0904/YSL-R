module yslr.modules.core;

import std.conv;
import std.stdio;
import std.string;
import std.algorithm;
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
		case "+":
		case "+=":
		case "-":
		case "-=":
		case "*":
		case "*=":
		case "/":
		case "/=":
		case "%":
		case "%=": {
			if (!args[2].isNumeric()) {
				stderr.writefln("Error: var: %s required numerical parameter", args[1]);
				throw new YSLError();
			}
			if (!env.VariableExists(args[0])) {
				stderr.writefln("Error: var: No such variable: '%s'", args[0]);
				throw new YSLError();
			}

			int operand = parse!int(args[2]);
			switch (args[1]) {
				case "+":  (*env.GetVariable(args[0]))[0] += operand; break;
				case "+=": (*env.GetVariable(args[0]))[0] += operand; break;
				case "-":  (*env.GetVariable(args[0]))[0] -= operand; break;
				case "-=": (*env.GetVariable(args[0]))[0] -= operand; break;
				case "*":  (*env.GetVariable(args[0]))[0] *= operand; break;
				case "*=": (*env.GetVariable(args[0]))[0] *= operand; break;
				case "/":  (*env.GetVariable(args[0]))[0] /= operand; break;
				case "/=": (*env.GetVariable(args[0]))[0] /= operand; break;
				case "%":  (*env.GetVariable(args[0]))[0] %= operand; break;
				case "%=": (*env.GetVariable(args[0]))[0] %= operand; break;
				default:   assert(0);
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
	int line = parse!int(args[0]);

	foreach (entry ; env.code.entries) {
		if (entry.value.key == line) {
			env.ip        = entry;
			env.increment = false;
			return [];
		}
	}

	stderr.writefln("Error: goto: Couldn't find line %d", line);
	throw new YSLError();
}

static Variable GotoIf(string[] args, Environment env) {
	if (env.returnStack.length == 0) {
		stderr.writeln("Error: goto_if: Return stack empty");
		throw new YSLError();
	}

	if (env.PopReturn()[0] != 0) {
		return Goto(args, env);
	}

	return [];
}

static Variable Exit(string[] args, Environment env) {
	exit(parse!int(args[0]));
}

static Variable Cmp(string[] args, Environment env) {
	return [args[0] == args[1]? 1 : 0];
}

static Variable Not(string[] args, Environment env) {
	if (env.returnStack.length == 0) {
		stderr.writeln("Error: goto_if: Return stack empty");
		throw new YSLError();
	}
	
	return [env.PopReturn()[0] == 0? 1 : 0];
}

Module Module_Core() {
	Module ret;
	ret["var"]     = Function.CreateBuiltIn(false, [], &Var);
	ret["goto"]    = Function.CreateBuiltIn(true, [ArgType.Numerical], &Goto);
	ret["exit"]    = Function.CreateBuiltIn(true, [ArgType.Numerical], &Exit);
	ret["cmp"]     = Function.CreateBuiltIn(true, [ArgType.Other, ArgType.Other], &Cmp);
	ret["goto_if"] = Function.CreateBuiltIn(true, [ArgType.Numerical], &GotoIf);
	ret["not"]     = Function.CreateBuiltIn(false, [], &Not);
	return ret;
}
