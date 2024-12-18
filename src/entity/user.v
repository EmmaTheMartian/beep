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

	theme ?string

	bio      string
	pronouns string

	created_at time.Time = time.now()
}

@[inline]
pub fn (user User) get_name() string {
	return user.nickname or { user.username }
}

@[inline]
pub fn (user User) get_theme() string {
	return user.theme or { '' }
}

@[inline]
pub fn (user User) to_str_without_sensitive_data() string {
	return user.str()
		.replace(user.password, '*'.repeat(16))
		.replace(user.password_salt, '*'.repeat(16))
}
