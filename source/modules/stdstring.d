module yslr.modules.stdstring;

import std.conv;
import std.array;
import std.stdio;
import yslr.util;
import yslr.environment;

static Variable Atoi(string[] args, Environment env) {
	return [parse!int(args[0])];
}

static Variable Itoa(string[] args, Environment env) {
	return text(args[0]).StringToIntArray();
}

Module Module_Stdstring() {
	Module ret;
	ret["atoi"] = Function.CreateBuiltIn(true, [ArgType.Numerical], &Atoi);
	ret["itoa"] = Function.CreateBuiltIn(true, [ArgType.Numerical], &Itoa);
	return ret;
}
