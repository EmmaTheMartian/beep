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
pub fn (validator StringValidator) validate(str string) bool {
	return str.len > validator.min_len && str.len < validator.max_len
		&& validator.pattern.matches_string(str)
}

// StringValidator.new creates a new StringValidator with the given min, max,
// and pattern.
pub fn StringValidator.new(min int, max int, pattern string) StringValidator {
	mut re := regex.new()
	re.compile_opt(pattern) or { panic(err) }
	return StringValidator{min, max, re}
}
