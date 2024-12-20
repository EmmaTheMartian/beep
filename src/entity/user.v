module entity

import time

pub struct User {
pub mut:
	id       int    @[primary; sql: serial]
	username string @[unique]
	nickname ?string

	password      string
	password_salt string

	muted bool
	admin bool

	theme string

	bio      string
	pronouns string

	created_at time.Time = time.now()
}

// get_name returns the user's nickname if it is not none, if so then their
// username is returned.
@[inline]
pub fn (user User) get_name() string {
	return user.nickname or { user.username }
}

// to_str_without_sensitive_data returns the stringified data for the user with
// their password and salt censored.
@[inline]
pub fn (user User) to_str_without_sensitive_data() string {
	return user.str()
		.replace(user.password, '*'.repeat(16))
		.replace(user.password_salt, '*'.repeat(16))
}
