// **all** interactions with the database should be handled in this module.
module database

import db.pg
import entity { User, Post }

// DatabaseAccess handles all interactions with the database.
pub struct DatabaseAccess {
pub mut:
	db pg.DB
}

// get_unknown_user returns a user representing an unknown user
pub fn (app &DatabaseAccess) get_unknown_user() User {
	return User{
		username: 'unknown'
	}
}

// get_unknown_post returns a post representing an unknown post
pub fn (app &DatabaseAccess) get_unknown_post() Post {
	return Post{
		title: 'unknown'
	}
}
