module yslr.modules.editor;

import std.array;
import std.stdio;
import std.exception;
import ydlib.sortedMap;
import yslr.environment;

static Variable List(string[] args, Environment env) {
	foreach (key, ref value ; env.code) {
		writefln("  %.6d: %s", key, value);
	}
	
	return [];
}

static Variable Clear(string[] args, Environment env) {
	env.code = new SortedMap!(int, string);
	return [];
}

static Variable Load(string[] args, Environment env) {
	env.code = new SortedMap!(int, string);

	File file;

	try {
		file = File(args[0], "r");
	}
	catch (ErrnoException e) {
		stderr.writefln("Error: load: Failed to load file: %s", e.msg);
		return [];
	}

	string line;
	int    num = 10;
	
	while ((line = file.readln()) !is null) {
		env.code[num]  = line[0 .. $ - 1];
		num           += 10;
	}

	return [];
}

static Variable Save(string[] args, Environment env) {
	auto file = File(args[0], "w");

	foreach (key, ref value ; env.code) {
		file.writeln(value);
	}
	return [];
}

Module Module_Editor() {
	Module ret;
	ret["list"]  = Function.CreateBuiltIn(false, [], &List);
	ret["clear"] = Function.CreateBuiltIn(false, [], &Clear);
	ret["load"]  = Function.CreateBuiltIn(true, [ArgType.Other], &Load);
	ret["save"]  = Function.CreateBuiltIn(true, [ArgType.Other], &Save);
	return ret;
}
