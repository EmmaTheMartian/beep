module main

import regex

// handles validation of user-input fields
pub struct StringValidator {
pub:
	min_len int
	max_len int = max_int
	pattern regex.RE
}

@[inline]
pub fn (validator StringValidator) validate(str string) bool {
	return str.len > validator.min_len && str.len < validator.max_len
		&& validator.pattern.matches_string(str)
}

pub fn StringValidator.new(min int, max int, pattern string) StringValidator {
	mut re := regex.new()
	re.compile_opt(pattern) or { panic(err) }
	return StringValidator{min, max, re}
}
