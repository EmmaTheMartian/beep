module database

import entity { User, Notification, Like, LikeCache, Post }
import util

// new_user creates a new user and returns their struct after creation.
pub fn (app &DatabaseAccess) new_user(user User) ?User {
	sql app.db {
		insert user into User
	} or {
		eprintln('failed to insert user ${user}')
		return none
	}

	println('reg: ${user.username}')

	return app.get_user_by_name(user.username)
}

// set_username sets the given user's username, returns true if this succeeded
// and false otherwise.
pub fn (app &DatabaseAccess) set_username(user_id int, new_username string) bool {
	sql app.db {
		update User set username = new_username where id == user_id
	} or {
		eprintln('failed to update username for ${user_id}')
		return false
	}
	return true
}

// set_password sets the given user's password, returns true if this succeeded
// and false otherwise.
pub fn (app &DatabaseAccess) set_password(user_id int, hashed_new_password string) bool {
	sql app.db {
		update User set password = hashed_new_password where id == user_id
	} or {
		eprintln('failed to update password for ${user_id}')
		return false
	}
	return true
}

// set_nickname sets the given user's nickname, returns true if this succeeded
// and false otherwise.
pub fn (app &DatabaseAccess) set_nickname(user_id int, new_nickname ?string) bool {
	sql app.db {
		update User set nickname = new_nickname where id == user_id
	} or {
		eprintln('failed to update nickname for ${user_id}')
		return false
	}
	return true
}

// set_muted sets the given user's muted status, returns true if this succeeded
// and false otherwise.
pub fn (app &DatabaseAccess) set_muted(user_id int, muted bool) bool {
	sql app.db {
		update User set muted = muted where id == user_id
	} or {
		eprintln('failed to update muted status for ${user_id}')
		return false
	}
	return true
}

// set_automated sets the given user's automated status, returns true if this
// succeeded and false otherwise.
pub fn (app &DatabaseAccess) set_automated(user_id int, automated bool) bool {
	sql app.db {
		update User set automated = automated where id == user_id
	} or {
		eprintln('failed to update automated status for ${user_id}')
		return false
	}
	return true
}

// set_theme sets the given user's theme url, returns true if this succeeded and
// false otherwise.
pub fn (app &DatabaseAccess) set_theme(user_id int, theme ?string) bool {
	sql app.db {
		update User set theme = theme where id == user_id
	} or {
		eprintln('failed to update theme url for ${user_id}')
		return false
	}
	return true
}

// set_pronouns sets the given user's pronouns, returns true if this succeeded
// and false otherwise.
pub fn (app &DatabaseAccess) set_pronouns(user_id int, pronouns string) bool {
	sql app.db {
		update User set pronouns = pronouns where id == user_id
	} or {
		eprintln('failed to update pronouns for ${user_id}')
		return false
	}
	return true
}

// set_bio sets the given user's bio, returns true if this succeeded and false
// otherwise.
pub fn (app &DatabaseAccess) set_bio(user_id int, bio string) bool {
	sql app.db {
		update User set bio = bio where id == user_id
	} or {
		eprintln('failed to update bio for ${user_id}')
		return false
	}
	return true
}

// get_user_by_name gets a user by their username, returns none if the user was
// not found.
pub fn (app &DatabaseAccess) get_user_by_name(username string) ?User {
	users := sql app.db {
		select from User where username == username
	} or { [] }
	if users.len != 1 {
		return none
	}
	return users[0]
}

// get_user_by_id gets a user by their id, returns none if the user was not
// found.
pub fn (app &DatabaseAccess) get_user_by_id(id int) ?User {
	users := sql app.db {
		select from User where id == id
	} or { [] }
	if users.len != 1 {
		return none
	}
	return users[0]
}

// get_users returns all users.
pub fn (app &DatabaseAccess) get_users() []User {
	users := sql app.db {
		select from User
	} or { [] }
	return users
}

// does_user_like_post returns true if a user likes the given post.
pub fn (app &DatabaseAccess) does_user_like_post(user_id int, post_id int) bool {
	likes := app.db.exec_param2('SELECT id, is_like FROM "Like" WHERE user_id = $1 AND post_id = $2', user_id.str(), post_id.str()) or { [] }
	if likes.len > 1 {
		// something is very wrong lol
		eprintln('does_user_like_post: a user somehow got two or more likes on the same post (user: ${user_id}, post: ${post_id})')
	} else if likes.len == 0 {
		return false
	}
	return util.or_throw(likes.first().vals[1]).bool()
}

// does_user_dislike_post returns true if a user dislikes the given post.
pub fn (app &DatabaseAccess) does_user_dislike_post(user_id int, post_id int) bool {
	likes := app.db.exec_param2('SELECT id, is_like FROM "Like" WHERE user_id = $1 AND post_id = $2', user_id.str(), post_id.str()) or { [] }
	if likes.len > 1 {
		// something is very wrong lol
		eprintln('does_user_dislike_post: a user somehow got two or more likes on the same post (user: ${user_id}, post: ${post_id})')
	} else if likes.len == 0 {
		return false
	}
	return !util.or_throw(likes.first().vals[1]).bool()
}

// does_user_like_or_dislike_post returns true if a user likes *or* dislikes the
// given post.
pub fn (app &DatabaseAccess) does_user_like_or_dislike_post(user_id int, post_id int) bool {
	likes := app.db.exec_param2('SELECT id FROM "Like" WHERE user_id = $1 AND post_id = $2', user_id.str(), post_id.str()) or { [] }
	if likes.len > 1 {
		// something is very wrong lol
		eprintln('does_user_like_or_dislike_post: a user somehow got two or more likes on the same post (user: ${user_id}, post: ${post_id})')
	}
	return likes.len == 1
}

// delete_user deletes the given user and their data, returns true if this
// succeeded and false otherwise.
pub fn (app &DatabaseAccess) delete_user(user_id int) bool {
	sql app.db {
		delete from User where id == user_id
		delete from Like where user_id == user_id
		delete from Notification where user_id == user_id
	} or {
		return false
	}

	// delete posts and their likes
	posts_from_this_user := app.db.exec_param('SELECT id FROM "Post" WHERE author_id = $1', user_id.str()) or { [] }

	for post in posts_from_this_user {
		id := util.or_throw(post.vals[0]).int()
		sql app.db {
			delete from Like where post_id == id
			delete from LikeCache where post_id == id
		} or {
			eprintln('failed to delete like cache for post during user deletion: ${id}')
		}
	}

	sql app.db {
		delete from Post where author_id == user_id
	} or {
		eprintln('failed to delete posts by deleting user: ${user_id}')
	}

	return true
}

// search_for_users searches for posts matching the given query.
// todo: query options/filters, such as created-after:<date>, created-before:<date>, etc
pub fn (app &DatabaseAccess) search_for_users(query string, limit int, offset int) []User {
	queried_users := app.db.exec_param_many('SELECT * FROM search_for_users($1, $2, $3)', [query, limit.str(), offset.str()]) or {
		eprintln('search_for_users error in app.db.error: ${err}')
		[]
	}
	users := queried_users.map(|it| User.from_row(it))
	return users
}
