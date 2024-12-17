module entity

import time

@[json: 'user']
pub struct User {
pub mut:
	id       int    @[primary; sql: serial]
	username string @[unique]
	nickname ?string

	password      string
	password_salt string

	muted bool
	admin bool

	created_at time.Time = time.now()
}

@[inline]
pub fn (user User) get_name() string {
	return user.nickname or { user.username }
}
