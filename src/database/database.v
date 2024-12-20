// **all** interactions with the database should be handled in this module.
module database

import db.pg

// DatabaseAccess handles all interactions with the database.
pub struct DatabaseAccess {
pub mut:
	db pg.DB
}
