module yslr.modules.core;

import std.conv;
import std.math;
import std.stdio;
import std.string;
import std.algorithm;
import std.exception;
import core.math;
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
			if (args.length == 2) {
				env.CreateVariable(var, []);
			}
			else if (args[2].isNumeric()) {
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

			size_t index;

			if ((args[1] == "f") || (args[1] == "from")) {
				index = args.length == 4? parse!size_t(args[3]) : 0;
			}

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
					value = [env.PopReturn()[index]];
				}
			}
			else {
				if (copyFull) {
					value = *env.GetVariable(args[2]);
				}
				else {
					value = [(*env.GetVariable(args[2]))[index]];
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

static Variable StringArray(string[] args, Environment env) {
	if (args.empty()) {
		stderr.writeln("Error: string_array: Operation parameter required");
		throw new YSLError();
	}

	switch (args[0]) {
		case "n":
		case "new": {
			string[] ret;

			for (size_t i = 1; i < args.length; ++ i) {
				ret ~= args[i];
			}

			return StringArrayToIntArray(ret);
		}
		case "g":
		case "get": {
			if (args.length != 3) {
				stderr.writeln("Error: string_array: Get operation requires 2 parameters");
				throw new YSLError();
			}

			if (!args[2].isNumeric()) {
				stderr.writeln("Error: string_array: Index parameter must be numerical");
				throw new YSLError();
			}

			if (!env.VariableExists(args[1])) {
				stderr.writefln("Error: string_array: No such variable: '%s'", args[1]);
				throw new YSLError();
			}

			auto var   = env.GetVariable(args[1]);
			auto array = IntArrayToStringArray(*var);
			auto index = parse!int(args[2]);

			return StringToIntArray(array[index]);
		}
		case "l":
		case "length": {
			if (args.length != 2) {
				stderr.writeln("Error: string_array: Length operation requires 1 parameter");
				throw new YSLError();
			}

			if (!env.VariableExists(args[1])) {
				stderr.writefln("Error: string_array: No such variable: '%s'", args[1]);
				throw new YSLError();
			}

			auto var   = env.GetVariable(args[1]);
			auto array = IntArrayToStringArray(*var);

			return [cast(int) array.length];
		}
		case "a":
		case "append": {
			if (args.length != 3) {
				stderr.writeln("Error: string_array: Append operation requires 2 parameters");
				throw new YSLError();
			}

			if (!env.VariableExists(args[1])) {
				stderr.writefln("Error: string_array: No such variable: '%s'", args[1]);
				throw new YSLError();
			}

			auto var = env.GetVariable(args[1]);

			*var ~= StringToIntArray(args[2]);
			*var ~= 0;
			break;
		}
		case "s":
		case "set": {
			if (args.length != 4) {
				stderr.writeln("Error: string_array: Set operation requires 3 parameters");
				throw new YSLError();
			}

			if (!args[2].isNumeric()) {
				stderr.writeln("Error: string_array: Index parameter must be numerical");
				throw new YSLError();
			}

			if (!env.VariableExists(args[1])) {
				stderr.writefln("Error: string_array: No such variable: '%s'", args[1]);
				throw new YSLError();
			}

			auto var   = env.GetVariable(args[1]);
			auto array = IntArrayToStringArray(*var);
			auto index = parse!int(args[2]);

			if (index >= array.length) {
				stderr.writefln("Error: string_array: index out of bounds");
				throw new YSLError();
			}
			
			array[index] = args[3];

			*var = StringArrayToIntArray(array);
			break;
		}
		case "r":
		case "remove": {
			if (args.length != 3) {
				stderr.writeln("Error: string_array: Remove operation requires 2 parameters");
				throw new YSLError();
			}

			if (!args[2].isNumeric()) {
				stderr.writeln("Error: string_array: Index parameter must be numerical");
				throw new YSLError();
			}

			if (!env.VariableExists(args[1])) {
				stderr.writefln("Error: string_array: No such variable: '%s'", args[1]);
				throw new YSLError();
			}

			auto var   = env.GetVariable(args[1]);
			auto array = IntArrayToStringArray(*var);
			array      = array.remove(parse!int(args[2]));
			*var       = StringArrayToIntArray(array);
			break;
		}
		default: {
			stderr.writefln("Error: string_array: Unknown operation '%s'", args[0]);
			throw new YSLError();
		}
	}

	return [];
}

static Variable Matrix(string[] args, Environment env) {
	if (args.length < 2) {
		stderr.writeln("Error: matrix: Operation and variable parameter required");
		throw new YSLError();
	}

	string varName = args[0];

	switch (args[1]) {
		case "c":
		case "create": {
			if (args.length != 4) {
				stderr.writeln("Error: matrix: Create operation requires 2 arguments");
				throw new YSLError();
			}

			if (!args[2].isNumeric() || !args[3].isNumeric()) {
				stderr.writeln("Error: matrix: Create operation requires numerical arguments");
				throw new YSLError();
			}

			int width  = parse!int(args[2]);
			int height = parse!int(args[3]);

			int[] array = new int[]((width * height) + 2);
			array[0]    = width;
			array[1]    = height;
			env.CreateVariable(varName, array);
			break;
		}
		case "g":
		case "get": {
			if (args.length != 4) {
				stderr.writeln("Error: matrix: Get operation requires 2 arguments");
				throw new YSLError();
			}

			if (!args[2].isNumeric() || !args[3].isNumeric()) {
				stderr.writeln("Error: matrix: Get operation requires numerical arguments");
				throw new YSLError();
			}

			if (!env.VariableExists(varName)) {
				stderr.writefln("Error: matrix: No such variable '%s'", varName);
				throw new YSLError();
			}

			int x    = parse!int(args[2]);
			int y    = parse!int(args[3]);
			auto arr = env.GetVariable(varName);
			int w    = (*arr)[0];
			int h    = (*arr)[1];

			if ((x >= w) || (y >= h) || (x < 0) || (y < 0)) {
				stderr.writeln("Error: matrix: Indices don't fit in matrix");
				throw new YSLError();
			}

			int ret = (*arr)[(y * w) + x];
			return [ret];
		}
		case "s":
		case "set": {
			if (args.length != 5) {
				stderr.writeln("Error: matrix: Set operation requires 3 arguments");
				throw new YSLError();
			}

			if (!args[2].isNumeric() || !args[3].isNumeric() || !args[4].isNumeric()) {
				stderr.writeln("Error: matrix: Set operation requires numerical arguments");
				throw new YSLError();
			}

			if (!env.VariableExists(varName)) {
				stderr.writefln("Error: matrix: No such variable '%s'", varName);
				throw new YSLError();
			}

			int x     = parse!int(args[2]);
			int y     = parse!int(args[3]);
			auto arr  = env.GetVariable(varName);
			int w     = (*arr)[0];
			int h     = (*arr)[1];
			int value = parse!int(args[4]);

			if ((x >= w) || (y >= h) || (x < 0) || (y < 0)) {
				stderr.writeln("Error: matrix: Indices don't fit in matrix");
				throw new YSLError();
			}

			(*arr)[(y * w) + x] = value;
			break;
		}
		default: {
			stderr.writefln("Error: matrix: Unknown operation '%s'", args[1]);
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
	if (!args[0].isNumeric()) {
		stderr.writeln("Error: gosub: Invalid jump location");
		throw new YSLError();
	}

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
			Scope newScope;
			
			env.callStack ~= env.ip.value.key;
			env.ip         = entry;
			env.increment  = false;
			env.locals    ~= newScope;
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

	if (env.locals.length == 0) {
		stderr.writeln("Fatal error: No scopes to end at return");
		throw new YSLError();
	}
	env.locals = env.locals.remove(env.locals.length - 1);

	return [];
}

static Variable Exit(string[] args, Environment env) {
	if (args.length == 0) {
		exit(0);
	}
	else {
		if (!args[0].isNumeric()) {
			stderr.writeln("Error: exit: Must have numerical exit code");
			throw new YSLError();
		}
	
		exit(parse!int(args[0]));
	}
}

static Variable Cmp(string[] args, Environment env) {
	return [args[0] == args[1]? 1 : 0];
}

static Variable Gt(string[] args, Environment env) {
	auto a = parse!int(args[0]);
	auto b = parse!int(args[1]);

	return [a > b? 1 : 0];
}

static Variable Lt(string[] args, Environment env) {
	auto a = parse!int(args[0]);
	auto b = parse!int(args[1]);

	return [a < b? 1 : 0];
}

static Variable Not(string[] args, Environment env) {
	if (env.returnStack.length == 0) {
		stderr.writeln("Error: not: Return stack empty");
		throw new YSLError();
	}
	
	return [env.PopReturn()[0] == 0? 1 : 0];
}

static Variable And(string[] args, Environment env) {
	if (env.returnStack.length < 2) {
		stderr.writeln("Error: and: Not enough values in return stack");
		throw new YSLError();
	}

	return [((env.PopReturn()[0] != 0) && (env.PopReturn()[0] != 0))? 1 : 0];
}

static Variable Or(string[] args, Environment env) {
	if (env.returnStack.length < 2) {
		stderr.writeln("Error: or: Not enough values in return stack");
		throw new YSLError();
	}

	return [((env.PopReturn()[0] != 0) || (env.PopReturn()[0] != 0))? 1 : 0];
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

static Variable Swap(string[] args, Environment env) {
	if (!env.VariableExists(args[0])) {
		stderr.writefln("Error: swap: Non existant variable: %s", args[0]);
		throw new YSLError();
	}
	if (!env.VariableExists(args[1])) {
		stderr.writefln("Error: swap: Non existant variable: %s", args[1]);
		throw new YSLError();
	}

	auto arr1 = *env.GetVariable(args[0]);
	auto arr2 = *env.GetVariable(args[1]);

	env.CreateVariable(args[0], arr2);
	env.CreateVariable(args[1], arr1);
	return [];
}

static Variable Pow(string[] args, Environment env) {
	return [cast(int) pow(parse!int(args[0]), parse!int(args[1]))];
}

static Variable IsNum(string[] args, Environment env) {
	return [args[0].isNumeric()? 1 : 0];
}

static Variable LoadEnd(string[] args, Environment env) {
	int lineNum = 10;

	if (env.code.entries.head !is null) {
		lineNum = env.code.entries.head.GetLastEntry().value.key + 10;
	}

	File file;

	try {
		file = File(args[0], "r");
	}
	catch (ErrnoException) {
		stderr.writefln("Error: load_end: No such file '%s'", args[0]);
		throw new YSLError();
	}

	string line;
	while ((line = file.readln()) !is null) {
		env.code[lineNum]  = line[0 .. $ - 1];
		lineNum           += 10;
	}

	return [];
}

static Variable Error(string[] args, Environment env) {
	throw new YSLError();
}

static Variable Sqrt(string[] args, Environment env) {
	int num = parse!int(args[0]);
	int res = cast(int) core.math.sqrt(cast(float) num);
	return [res];
}

static Variable Local(string[] args, Environment env) {
	env.locals[$ - 1][args[0]] = [];
	return [];
}

static Variable String(string[] args, Environment env) {
	return StringToIntArray(args[0]);
}

static Variable LShift(string[] args, Environment env) {
	return [parse!int(args[0]) << parse!int(args[1])];
}

static Variable RShift(string[] args, Environment env) {
	return [parse!int(args[0]) >> parse!int(args[1])];
}

static Variable BitAnd(string[] args, Environment env) {
	return [parse!int(args[0]) & parse!int(args[1])];
}

static Variable BitOr(string[] args, Environment env) {
	return [parse!int(args[0]) | parse!int(args[1])];
}

static Variable BitNot(string[] args, Environment env) {
	return [~parse!int(args[0])];
}

static Variable BitXor(string[] args, Environment env) {
	return [parse!int(args[0]) ^ parse!int(args[1])];
}

static Variable StartScope(string[] args, Environment env) {
	env.locals ~= [];
	return [];
}

static Variable EndScope(string[] args, Environment env) {
	env.locals = env.locals.remove(env.locals.length - 1);
	return [];
}

static Variable Object(string[] args, Environment env) {
	return StringToIntArray(format("%s.%s", args[0], args[1]));
}

Module Module_Core() {
	Module ret;
	ret["var"]          = Function.CreateBuiltIn(false, [], &Var);
	ret["string_array"] = Function.CreateBuiltIn(false, [], &StringArray);
	ret["matrix"]       = Function.CreateBuiltIn(false, [], &Matrix);
	ret["goto"]         = Function.CreateBuiltIn(true, [ArgType.Numerical], &Goto);
	ret["goto_if"]      = Function.CreateBuiltIn(true, [ArgType.Numerical], &GotoIf);
	ret["gosub"]        = Function.CreateBuiltIn(false, [], &Gosub);
	ret["gosub_if"]     = Function.CreateBuiltIn(false, [], &GosubIf);
	ret["return"]       = Function.CreateBuiltIn(false, [], &Return);
	ret["exit"]         = Function.CreateBuiltIn(false, [], &Exit);
	ret["cmp"]          = Function.CreateBuiltIn(true, [ArgType.Other, ArgType.Other], &Cmp);
	ret["gt"]           = Function.CreateBuiltIn(true, [ArgType.Numerical, ArgType.Numerical], &Gt);
	ret["lt"]           = Function.CreateBuiltIn(true, [ArgType.Numerical, ArgType.Numerical], &Lt);
	ret["not"]          = Function.CreateBuiltIn(true, [], &Not);
	ret["and"]          = Function.CreateBuiltIn(true, [], &And);
	ret["or"]           = Function.CreateBuiltIn(true, [], &Or);
	ret["size"]         = Function.CreateBuiltIn(true, [ArgType.Other], &Size);
	ret["wait"]         = Function.CreateBuiltIn(true, [ArgType.Numerical], &Wait);
	ret["set_size"]     = Function.CreateBuiltIn(true, [ArgType.Other, ArgType.Numerical], &SetSize);
	ret["swap"]         = Function.CreateBuiltIn(true, [ArgType.Other, ArgType.Other], &Swap);
	ret["pow"]          = Function.CreateBuiltIn(true, [ArgType.Numerical, ArgType.Numerical], &Pow);
	ret["is_num"]       = Function.CreateBuiltIn(true, [ArgType.Other], &IsNum);
	ret["load_end"]     = Function.CreateBuiltIn(true, [ArgType.Other], &LoadEnd);
	ret["error"]        = Function.CreateBuiltIn(false, [], &Error);
	ret["sqrt"]         = Function.CreateBuiltIn(true, [ArgType.Numerical], &Sqrt);
	ret["local"]        = Function.CreateBuiltIn(true, [ArgType.Other], &Local);
	ret["string"]       = Function.CreateBuiltIn(true, [ArgType.Other], &String);
	ret["l_shift"]      = Function.CreateBuiltIn(true, [ArgType.Numerical, ArgType.Numerical], &LShift);
	ret["r_shift"]      = Function.CreateBuiltIn(true, [ArgType.Numerical, ArgType.Numerical], &RShift);
	ret["bit_and"]      = Function.CreateBuiltIn(true, [ArgType.Numerical, ArgType.Numerical], &BitAnd);
	ret["bit_or"]       = Function.CreateBuiltIn(true, [ArgType.Numerical, ArgType.Numerical], &BitOr);
	ret["bit_not"]      = Function.CreateBuiltIn(true, [ArgType.Numerical], &BitNot);
	ret["bit_xor"]      = Function.CreateBuiltIn(true, [ArgType.Numerical, ArgType.Numerical], &BitXor);
	ret["start_scope"]  = Function.CreateBuiltIn(true, [], &StartScope);
	ret["end_scope"]    = Function.CreateBuiltIn(true, [], &EndScope);
	ret["object"]       = Function.CreateBuiltIn(true, [ArgType.Other, ArgType.Other], &Object);
	return ret;
}
