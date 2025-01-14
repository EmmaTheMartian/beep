module webapp

import regex

// StringValidator handles validation of user-input fields.
pub struct StringValidator {
pub:
	min_len int
	max_len int = max_int
	pattern regex.RE
}

// validate validates a given string and returns true if it succeeded and false
// otherwise.
@[inline]
pub fn (validator StringValidator) validate(str_ string) bool {
	// for whatever reason form inputs can end up with \r\n. i have
	// absolutely no clue why this is a thing. anyway, this is here as a fix
	str := str_.replace('\r\n', '\n')

	// used for debugging validators. don't uncomment this in prod, please.
	// a) it will log a crap ton of unneeded info, and b) basically all user
	// inputs are validated. including passwords.
	// println('validator on: ${str}')
	// println('  >= min_len: ${str.len >= validator.min_len} (${str.len} >= ${validator.min_len})')
	// println('  <= max_len: ${str.len <= validator.max_len} (${str.len} <= ${validator.max_len})')
	// println('  regex:      ${validator.pattern.matches_string(str)}')

	return str.len >= validator.min_len && str.len <= validator.max_len
		&& validator.pattern.matches_string(str)
}

// StringValidator.new creates a new StringValidator with the given min, max,
// and pattern.
pub fn StringValidator.new(min int, max int, pattern string) StringValidator {
	mut re := regex.new()
	re.compile_opt(pattern) or { panic(err) }
	return StringValidator{min, max, re}
}
