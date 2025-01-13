module database

import entity { Like, LikeCache }
import util

// add_like adds a like to the database, returns true if this succeeds and false
// otherwise.
pub fn (app &DatabaseAccess) add_like(like &Like) bool {
	sql app.db {
		insert like into Like
		// yeet the old cached like value
		delete from LikeCache where post_id == like.post_id
	} or {
		return false
	}
	return true
}

// get_net_likes_for_post returns the net likes of the given post.
pub fn (app &DatabaseAccess) get_net_likes_for_post(post_id int) int {
	// check cache
	cache := app.db.exec_param('SELECT likes FROM "LikeCache" WHERE post_id = $1 LIMIT 1', post_id.str()) or { [] }

	mut likes := 0

	if cache.len != 1 {
		println('calculating net likes for post: ${post_id}')
		// calculate
		db_likes := app.db.exec_param('SELECT is_like FROM "Like" WHERE post_id = $1', post_id.str()) or { [] }
		for like in db_likes {
			if util.or_throw(like.vals[0]).bool() {
				likes++
			} else {
				likes--
			}
		}

		// cache
		cached := LikeCache{
			post_id: post_id
			likes:   likes
		}
		sql app.db {
			insert cached into LikeCache
		} or {
			eprintln('failed to cache like: ${cached}')
			return likes
		}
	} else {
		likes = util.or_throw(cache.first().vals[0]).int()
	}

	return likes
}

// unlike_post removes a (dis)like from the given post, returns true if this
// succeeds and false otherwise.
pub fn (app &DatabaseAccess) unlike_post(post_id int, user_id int) bool {
	sql app.db {
		delete from Like where user_id == user_id && post_id == post_id
		// yeet the old cached like value
		delete from LikeCache where post_id == post_id
	} or {
		return false
	}
	return true
}
