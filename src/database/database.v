module database

import db.pg

// all interactions with the database should be handled through this struct.
pub struct DatabaseAccess {
pub mut:
	db pg.DB
}
