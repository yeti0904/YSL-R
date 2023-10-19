module yslr.modules.file;

import std.file;
import std.array;
import std.stdio;
import core.stdc.stdio : getchar;
import yslr.util;
import yslr.environment;

static Variable Read(string[] args, Environment env) {
	if (!exists(args[0])) {
		stderr.writefln("Error: read: No such file: %s", args[0]);
		throw new YSLError();
	}
	
	return readText(args[0]).StringToIntArray();
}

static Variable Write(string[] args, Environment env) {
	std.file.write(args[0], args[1]);
	return [];
}

static Variable Flush(string[] args, Environment env) {
	stdout.flush();
	return [];
}

Module Module_File() {
	Module ret;
	ret["read"]  = Function.CreateBuiltIn(true, [ArgType.Other], &Read);
	ret["write"] = Function.CreateBuiltIn(true, [ArgType.Other, ArgType.Other], &Write);
	ret["flush"] = Function.CreateBuiltIn(true, [], &Flush);
	return ret;
}
