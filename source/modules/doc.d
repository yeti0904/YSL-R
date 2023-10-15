module yslr.modules.doc;

import std.stdio;
import yslr.environment;

static Variable Doc(string[] args, Environment env) {
	if (args.length == 0) {
		stderr.writeln("Error: doc: 1 argument required (operation)");
	}

	switch (args[0]) {
		case "list": {
			string filter;
			
			if (args.length > 1) {
				filter = args[1];
			}
			
			foreach (key, ref value ; env.functions) {
				if ((filter == "") || (filter == value.from)) {
					writefln("From %s: %s", value.from, key);
				}
			}
			break;
		}
		default: {
			stderr.writefln("Error: doc: Unknown operation %s", args[0]);
			throw new YSLError();
		}
	}

	return [];
}

Module Module_Doc() {
	Module ret;
	ret["doc"] = Function.CreateBuiltIn(false, [], &Doc);
	return ret;
}
