module entity

import db.pg
import time
import util

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

// User.from_row creates a user object from the given database row.
// see src/database/user.v#search_for_users for usage.
@[inline]
pub fn User.from_row(row pg.Row) User {
	// this throws a cgen error when put in User{}
	//todo: report this
	created_at := time.parse(util.or_throw[string](row.vals[10])) or { panic(err) }

	return User{
		id: util.or_throw[string](row.vals[0]).int()
		username: util.or_throw[string](row.vals[1])
		nickname: if row.vals[2] == none { ?string(none) } else {
			util.or_throw[string](row.vals[3])
		}
		password: 'haha lol, nope'
		password_salt: 'haha lol, nope'
		muted: util.map_or_throw[string, bool](row.vals[5], |it| it.bool())
		admin: util.map_or_throw[string, bool](row.vals[6], |it| it.bool())
		theme: util.or_throw[string](row.vals[7])
		bio: util.or_throw[string](row.vals[8])
		pronouns: util.or_throw[string](row.vals[9])
		created_at: created_at
	}
}
