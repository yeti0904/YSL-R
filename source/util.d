module yslr.util;

string IntArrayToString(ref int[] arr) {
	string ret;

	foreach (ref ch ; arr) {
		ret ~= cast(char) ch;
	}

	return ret;
}

int[] StringToIntArray(string str) {
	int[] ret;

	foreach (ref ch ; str) {
		ret ~= cast(int) ch;
	}

	return ret;
}
