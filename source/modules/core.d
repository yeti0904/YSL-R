module yslr.modules.core;

import std.conv;
import std.math;
import std.stdio;
import std.string;
import std.algorithm;
import core.thread;
import core.stdc.stdlib;
import yslr.util;
import yslr.environment;

static Variable Var(string[] args, Environment env) {
	if (args.length < 2) {
		stderr.writefln("Error: var: Requires 2 arguments: variable name and operator");
		throw new YSLError();
	}

	string var = args[0];

	if (var == "return") {
		stderr.writefln("Error: var: Using disallowed variable name 'return'");
		throw new YSLError();
	}

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
		case "%=":
		case "^":
		case "^=": {
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
				case "+":
				case "+=": (*env.GetVariable(args[0]))[0] += operand; break;
				case "-":
				case "-=": (*env.GetVariable(args[0]))[0] -= operand; break;
				case "*":
				case "*=": (*env.GetVariable(args[0]))[0] *= operand; break;
				case "/":
				case "/=": (*env.GetVariable(args[0]))[0] /= operand; break;
				case "%":
				case "%=": (*env.GetVariable(args[0]))[0] %= operand; break;
				case "^":
				case "^=": {
					int* value = &((*env.GetVariable(args[0]))[0]);

					*value = pow(*value, operand);
					break;
				}
				default:   assert(0);
			}
			break;
		}
		case "c":
		case "copy":
		case "f":
		case "from": {
			bool copyFull = false;

			if ((args[1] == "c") || (args[1] == "copy")) {
				copyFull = true;
			}
		
			if (args.length < 3) {
				stderr.writeln("Error: var: from operator needs 3 arguments");
				throw new YSLError();
			}
		
			size_t index = args.length == 4? parse!size_t(args[3]) : 0;

			if ((args[2] != "return") && !env.VariableExists(args[2])) {
				stderr.writefln("Error: var: No such variable: '%s'", args[0]);
				throw new YSLError();
			}

			int[] value;

			if (args[2] == "return") {
				if (env.returnStack.empty()) {
					stderr.writefln("Error: var: Return stack empty");
					throw new YSLError();
				}

				if (copyFull) {
					value = env.PopReturn();
				}
				else {
					value = [env.PopReturn()[0]];
				}
			}
			else {
				if (copyFull) {
					value = *env.GetVariable(args[2]);
				}
				else {
					value = [(*env.GetVariable(args[2]))[0]];
				}
			}

			env.CreateVariable(args[0], value);
			break;
		}
		case "p":
		case "pass": {
			if (env.passStack.empty()) {
				stderr.writefln("Error: var: Pass stack empty");
				throw new YSLError();
			}

			env.CreateVariable(args[0], env.PopPass());
			break;
		}
		case "a":
		case "append": {
			if (!args[2].isNumeric()) {
				stderr.writefln("Error: var: %s required numerical parameter", args[1]);
				throw new YSLError();
			}
		
			(*env.GetVariable(args[0])) ~= parse!int(args[2]);
			break;
		}
		case "r":
		case "remove": {
			if (args.length != 4) {
				stderr.writefln("Error: var: %s requires 2 additional parameters", args[1]);
				throw new YSLError();
			}
			if (!args[2].isNumeric() || !args[3].isNumeric()) {
				stderr.writefln("Error: var: %s required numerical parameters", args[1]);
				throw new YSLError();
			}
			if (!env.VariableExists(args[0])) {
				stderr.writefln("Error: var: No such variable: %s", args[0]);
				throw new YSLError();
			}

			size_t    index  = parse!size_t(args[2]);
			size_t    length = parse!size_t(args[3]);
			Variable* varPtr = env.GetVariable(args[0]);

			foreach (i ; 0 .. length) {
				*varPtr = (*varPtr).remove(index);
			}
			break;
		}
		case "s":
		case "set": {
			if (args.length != 4) {
				stderr.writefln("Error: var: %s requires 2 additional parameters", args[1]);
				throw new YSLError();
			}
			if (!args[2].isNumeric() || !args[3].isNumeric()) {
				stderr.writefln("Error: var: %s required numerical parameters", args[1]);
				throw new YSLError();
			}
			if (!env.VariableExists(args[0])) {
				stderr.writefln("Error: var: No such variable: %s", args[0]);
				throw new YSLError();
			}

			size_t    index  = parse!size_t(args[2]);
			Variable* varPtr = env.GetVariable(args[0]);

			if (index >= (*varPtr).length) {
				stderr.writefln(
					"Error: var: %d is too big for array of size %d", index,
					(*varPtr).length
				);
				throw new YSLError();
			}

			(*varPtr)[index] = parse!int(args[3]);
			break;
		}
		case "j":
		case "join": {
			if (!env.VariableExists(args[0])) {
				stderr.writefln("Error: var: No such variable: %s", args[0]);
				throw new YSLError();
			}

			Variable* varPtr  = env.GetVariable(args[0]);
			(*varPtr)        ~= StringToIntArray(args[2]);
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

static Variable Gosub(string[] args, Environment env) {
	int line = parse!int(args[0]);

	foreach (ref arg ; args[1 .. $]) {
		if (arg.isNumeric()) {
			env.passStack ~= [parse!int(arg)];
		}
		else {
			env.passStack ~= StringToIntArray(arg);
		}
	}

	foreach (entry ; env.code.entries) {
		if (entry.value.key == line) {
			env.callStack ~= env.ip.value.key;
			env.ip         = entry;
			env.increment  = false;
			return [];
		}
	}

	stderr.writefln("Error: gosub: Couldn't find line %d", line);
	throw new YSLError();
}

static Variable GosubIf(string[] args, Environment env) {
	if (env.returnStack.length == 0) {
		stderr.writeln("Error: gosub_if: Return stack empty");
		throw new YSLError();
	}

	if (env.PopReturn()[0] != 0) {
		return Gosub(args, env);
	}

	return [];
}

static Variable Return(string[] args, Environment env) {
	foreach (ref arg ; args) {
		if (arg.isNumeric()) {
			env.returnStack ~= [parse!int(arg)];
		}
		else {
			env.returnStack ~= StringToIntArray(arg);
		}
	}

	if (env.callStack.length == 0) {
		stderr.writeln("Error: return: Nowhere to return to");
		throw new YSLError();
	}

	if (!env.Jump(env.PopCall(), true)) {
		stderr.writeln("Fatal error: return: Failed to return");
		throw new YSLError();
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

static Variable Size(string[] args, Environment env) {
	string varName = args[0];

	if (!env.VariableExists(varName)) {
		stderr.writefln("Error: size: No such variable: %s", varName);
		throw new YSLError();
	}

	auto var = env.GetVariable(varName);

	return [cast(int) (*var).length];
}

static Variable Wait(string[] args, Environment env) {
	int ms = parse!int(args[0]);

	Thread.sleep(dur!("msecs")(ms));
	return [];
}

static Variable SetSize(string[] args, Environment env) {
	string varName = args[0];

	if (!env.VariableExists(varName)) {
		stderr.writefln("Error: size: No such variable: %s", varName);
		throw new YSLError();
	}

	auto var = env.GetVariable(varName);

	(*var).length = parse!size_t(args[1]);

	return [];
}

Module Module_Core() {
	Module ret;
	ret["var"]      = Function.CreateBuiltIn(false, [], &Var);
	ret["goto"]     = Function.CreateBuiltIn(true, [ArgType.Numerical], &Goto);
	ret["goto_if"]  = Function.CreateBuiltIn(true, [ArgType.Numerical], &GotoIf);
	ret["gosub"]    = Function.CreateBuiltIn(true, [ArgType.Numerical], &Gosub);
	ret["gosub_if"] = Function.CreateBuiltIn(true, [ArgType.Numerical], &GosubIf);
	ret["return"]   = Function.CreateBuiltIn(false, [], &Return);
	ret["exit"]     = Function.CreateBuiltIn(true, [ArgType.Numerical], &Exit);
	ret["cmp"]      = Function.CreateBuiltIn(true, [ArgType.Other, ArgType.Other], &Cmp);
	ret["not"]      = Function.CreateBuiltIn(false, [], &Not);
	ret["size"]     = Function.CreateBuiltIn(true, [ArgType.Other], &Size);
	ret["wait"]     = Function.CreateBuiltIn(true, [ArgType.Numerical], &Wait);
	ret["set_size"] = Function.CreateBuiltIn(true, [ArgType.Other, ArgType.Numerical], &SetSize);
	return ret;
}
