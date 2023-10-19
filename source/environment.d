module yslr.environment;

import std.conv;
import std.stdio;
import std.string;
import std.algorithm;
import core.stdc.stdlib;
import ydlib.list;
import ydlib.sortedMap;
import yslr.util;
import yslr.split;

alias Variable = int[];
alias Scope    = Variable[string];
alias Module   = Function[string];
alias BuiltIn  = Variable function(string[], Environment);
alias Label    = ListNode!(MapEntry!(int, string));

enum ArgType {
	Numerical,
	Other
}

struct Function {
	bool      strictArgs;
	ArgType[] requiredArgs;           
	bool      builtIn;
	BuiltIn   func;
	int       label;
	string    from = "nowhere";

	static Function CreateBuiltIn(
		bool strictArgs, ArgType[] requiredArgs, BuiltIn func
	) {
		return Function(strictArgs, requiredArgs, true, func, -1);
	}
}

// required functions
Variable BuiltIn_Import(string[] args, Environment env) {
	if (args.length < 1) {
		stderr.writeln("Error: import: At least 1 argument required (module name)");
		throw new YSLError();
	}

	if (!env.ModuleExists(args[0])) {
		stderr.writefln("Error: import: No such module '%s'", args[0]);
		throw new YSLError();
	}

	bool global = false;

	if (args.length > 1) {
		global = args[1] == "global";
	}

	env.Import(args[0], global);
	return [];
}

Variable BuiltIn_Run(string[] args, Environment env) {
	env.Run();
	return [];
}

Variable BuiltIn_ImportSTD(string[] args, Environment env) {
	env.Import("stdio", true);
	env.Import("stdfunc", true);
	env.Import("stdstring", true);
	return [];
}

class YSLError : Exception {
	this(string file = __FILE__, size_t line = __LINE__) {
		super("", file, line);
	}
}

class Environment {
	Scope                   globals;
	Scope[]                 locals;
	Variable[]              returnStack;
	int[]                   callStack;
	Variable[]              passStack;
	Function[string]        functions;
	Label                   ip;
	bool                    increment;
	SortedMap!(int, string) code;
	Module[string]          modules;

	this() {
		code = new SortedMap!(int, string);
	
		// add default functions
		functions["import"]     = Function.CreateBuiltIn(false, [], &BuiltIn_Import);
		functions["run"]        = Function.CreateBuiltIn(false, [], &BuiltIn_Run);
		functions["import_std"] = Function.CreateBuiltIn(true, [], &BuiltIn_ImportSTD);

		// add modules
		import yslr.modules.doc;
		import yslr.modules.ysl;
		import yslr.modules.core;
		import yslr.modules.file;
		import yslr.modules.stdio;
		import yslr.modules.editor;
		import yslr.modules.stdfunc;
		import yslr.modules.stdstring;

		modules["doc"]       = Module_Doc();
		modules["ysl"]       = Module_Ysl();
		modules["core"]      = Module_Core();
		modules["file"]      = Module_File();
		modules["stdio"]     = Module_Stdio();
		modules["editor"]    = Module_Editor();
		modules["stdfunc"]   = Module_Stdfunc();
		modules["stdstring"] = Module_Stdstring();

		Import("core", true);
	}

	bool ModuleExists(string name) {
		return (name in modules) !is null;
	}

	void Import(string name, bool global, string as = "") {
		if (as == "") {
			as = name;
		}
	
		foreach (key, value ; modules[name]) {
			string funcName;

			value.from = name;

			if (global) {
				funcName = key;
			}
			else {
				funcName = format("%s.%s", as, key);
			}

			functions[funcName] = value;
		}
	}

	void LoadFile(string path) {
		code = new SortedMap!(int, string);

		File file = File(path, "r");

		string line;
		int    num = 10;
		
		while ((line = file.readln()) !is null) {
			code[num]  = line[0 .. $ - 1];
			num       += 10;
		}
	}

	Variable PopReturn() {
		Variable ret = returnStack[$ - 1];
		returnStack  = returnStack[0 .. $ - 1];
		return ret;
	}

	Variable PopPass() {
		Variable ret = passStack[$ - 1];
		passStack    = passStack[0 .. $ - 1];
		return ret;
	}

	int PopCall() {
		int ret   = callStack[$ - 1];
		callStack = callStack[0 .. $ - 1];
		return ret;
	}

	bool LocalExists(string name) {
		if (locals.empty()) {
			return false;
		}
		
		return (name in locals[$ - 1]) !is null;
	}

	int[]* GetLocal(string name) {
		return &locals[$ - 1][name];
	}

	bool GlobalExists(string name) {
		return (name in globals) !is null;
	}

	int[]* GetGlobal(string name) {
		return &globals[name];
	}

	bool VariableExists(string name) {
		return LocalExists(name) || GlobalExists(name);
	}

	int[]* GetVariable(string name) {
		if (LocalExists(name)) {
			return GetLocal(name);
		}

		return GetGlobal(name);
	}

	void CreateVariable(string name, int[] value) {
		if (!GlobalExists(name) && (locals.length > 0)) {
			locals[$ - 1][name] = value;
		}
		else {
			globals[name] = value;
		}
	}

	bool Jump(int line, bool skip = false) {
		foreach (entry ; code.entries) {
			if (entry.value.key == line) {
				ip        = entry;
				increment = skip;
				return true;
			}
		}

		return false;
	}

	string[] SubstituteParts(int line, string[] parts) {
		string[] ret;

		foreach (ref part ; parts) {
			if (part.empty()) {
				continue;
			}
			
			switch (part[0]) {
				case '$': {
					string varName = part[1 .. $];

					if (!VariableExists(varName)) {
						stderr.writefln(
							"Error: line %d: Unknown variable %s", line, varName
						);
						throw new YSLError();
					}

					ret ~= text((*GetVariable(varName))[0]);
					break;
				}
				case '!': {
					string varName = part[1 .. $];

					if (!VariableExists(varName)) {
						stderr.writefln(
							"Error: line %d: Unknown variable %s", line, varName
						);
						throw new YSLError();
					}

					ret ~= IntArrayToString(*GetVariable(varName));
					break;
				}
				case '*': {
					if (part.length == 1) {
						ret ~= part;
						break;
					}
				
					string labelName = part[1 .. $];

					Label start = code.entries.head;

					if (start is null) {
						goto errorNoLabel;
					}

					if (labelName[0] == '.') {
						auto it2 = start;

						while (it2.previous !is null) {
							it2 = it2.previous;

							if (
								(it2.value.value.length > 0) &&
								(it2.value.value[$ - 1] == ':') &&
								(it2.value.value[0] != '.')
							) {
								break;
							}
						}

						start = it2;
					}
					
					for (auto it = start; it !is null; it = it.next) {
						if (it.value.value.strip().empty()) {
							continue;
						}
						
						if (it.value.value.strip()[$ - 1] == ':') {
							string thisLabel = it.value.value.strip()[0 .. $ - 1];

							if (thisLabel == labelName) {
								ret ~= text(it.value.key);
								goto nextPart;
							}
						}
					}

					errorNoLabel:
					stderr.writefln(
						"Error: line %d: Couldn't find label '%s'", line, labelName
					);
					throw new YSLError();
				}
				default: ret ~= part;
			}

			nextPart:
		}

		return ret;
	}

	bool ArgumentsCorrect(ArgType[] args, string[] parts) {
		if (args.length != parts.length) {
			return false;
		}

		foreach (i, ref arg ; args) {
			switch (arg) {
				case ArgType.Numerical: {
					if (!parts[i].isNumeric()) {
						return false;
					}
					break;
				}
				case ArgType.Other: break;
				default:            assert(0);
			}
		}

		return true;
	}

	void ErrorHandler() {
		if (ip is null) {
			return;
		}
		
		stderr.writefln("Error from line %d", ip.value.key);
		stderr.writeln("Backtrace");
		foreach (i, ref call ; callStack) {
			stderr.writefln(
				"#%d: Line %d: %s", i, call, code[call]
			);
		}
	}

	void Interpret(int line, string str) {
		increment = true;
		
		if (str.strip().empty() || (str.strip()[0] == '#')) {
			return;
		}
	
		// string[] parts = SubstituteParts(line, str.Split(line));
		string[] parts = str.Split(line);

		if (parts.length == 0) {
			return;
		}

		if (parts[0].isNumeric()) {
			// WriteCode(parse!int(parts[0]), parts[1 .. $].join(" "));
			if (parts.length == 1) {
				code[parse!int(parts[0])] = "";
				// TODO: delete the line
			}
			else {
				string codeLine = str.strip().find(" ")[1 .. $];
				
				code[parse!int(parts[0])] = codeLine;
			}
		}
		else if (parts[0][$ - 1] == ':') {
			return; // this is a label
		}
		else {
			parts = SubstituteParts(line, parts);
			
			if (parts[0] !in functions) {
				stderr.writefln("ERROR: Line %d: Unknown function %s", line, parts[0]);
				throw new YSLError();
			}
			
			auto func = functions[parts[0]];

			if (func.builtIn) {
				if (
					func.strictArgs &&
					!ArgumentsCorrect(func.requiredArgs, parts[1 .. $])
				) {
					stderr.writefln(
						"Error: Line %d: Invalid parameters for function %s", line,
						parts[0]
					);
					throw new YSLError();
				}
				
				auto ret = func.func(parts[1 .. $], this);

				if (ret.length > 0) {
					returnStack ~= ret;
				}
			}
			else {
				callStack ~= ip.value.key;

				if (!Jump(func.label, false)) {
					stderr.writefln("Error: Broken function %s", parts[0]);
					throw new YSLError();
				}
			}
		}
	}

	void Run() {
		if (code.entries.head is null) {
			stderr.writeln("Nothing to run");
			return;
		}
	
		ip = code.entries.head;

		while (ip !is null) {
			Interpret(ip.value.key, ip.value.value);

			if (increment) {		
				ip = ip.next;
			}
		}
	}
}
