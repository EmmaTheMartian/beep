module database

import entity { SavedPost, Post }

// get_saved_posts_for gets all SavedPost objects for a given user.
pub fn (app &DatabaseAccess) get_saved_posts_for(user_id int) []SavedPost {
	saved_posts := sql app.db {
		select from SavedPost where user_id == user_id && saved == true
	} or { [] }
	return saved_posts
}

// get_saved_posts_as_post_for gets all saved posts for a given user converted
// to Post objects.
pub fn (app &DatabaseAccess) get_saved_posts_as_post_for(user_id int) []Post {
	saved_posts := sql app.db {
		select from SavedPost where user_id == user_id && saved == true
	} or { [] }
	posts := saved_posts.map(fn [app] (it SavedPost) Post {
		return app.get_post_by_id(it.post_id) or {
			// if the post does not exist, we will remove it now
			sql app.db {
				delete from SavedPost where id == it.id
			} or {
				eprintln('get_saved_posts_as_post_for: failed to remove non-existent post from saved post: ${it}')
			}
			app.get_unknown_post()
		}
	}).filter(it.id != 0)
	return posts
}

// get_saved_posts_as_post_for gets all posts saved for later for a given user
// converted to Post objects.
pub fn (app &DatabaseAccess) get_saved_for_later_posts_as_post_for(user_id int) []Post {
	saved_posts := sql app.db {
		select from SavedPost where user_id == user_id && later == true
	} or { [] }
	posts := saved_posts.map(fn [app] (it SavedPost) Post {
		return app.get_post_by_id(it.post_id) or {
			// if the post does not exist, we will remove it now
			sql app.db {
				delete from SavedPost where id == it.id
			} or {
				eprintln('get_saved_for_later_posts_as_post_for: failed to remove non-existent post from saved post: ${it}')
			}
			app.get_unknown_post()
		}
	}).filter(it.id != 0)
	return posts
}

// get_user_post_save_status returns the SavedPost object representing the user
// and post id. returns none if the post is not saved anywhere.
pub fn (app &DatabaseAccess) get_user_post_save_status(user_id int, post_id int) ?SavedPost {
	saved_posts := sql app.db {
		select from SavedPost where user_id == user_id && post_id == post_id
	} or { [] }
	if saved_posts.len == 1 {
		return saved_posts[0]
	} else if saved_posts.len == 0 {
		return none
	} else {
		eprintln('get_user_post_save_status: user `${user_id}` had multiple SavedPost entries for post `${post_id}')
		return none
	}
}

pub fn (app &DatabaseAccess) is_post_saved_by(user_id int, post_id int) bool {
	saved_post := app.get_user_post_save_status(user_id, post_id) or {
		return false
	}
	return saved_post.saved
}

pub fn (app &DatabaseAccess) is_post_saved_for_later_by(user_id int, post_id int) bool {
	saved_post := app.get_user_post_save_status(user_id, post_id) or {
		return false
	}
	return saved_post.later
}

// toggle_save_post (un)saves the given post for the user. returns true if this
// succeeds and false otherwise.
pub fn (app &DatabaseAccess) toggle_save_post(user_id int, post_id int) bool {
	if s := app.get_user_post_save_status(user_id, post_id) {
		if s.saved {
			sql app.db {
				update SavedPost set saved = false where id == s.id
			} or {
				eprintln('toggle_save_post: failed to unsave post (user_id: ${user_id}, post_id: ${post_id})')
				return false
			}
			return true
		} else {
			sql app.db {
				update SavedPost set saved = true where id == s.id
			} or {
				eprintln('toggle_save_post: failed to save post (user_id: ${user_id}, post_id: ${post_id})')
				return false
			}
			return true
		}
	} else {
		post := SavedPost{
			user_id: user_id
			post_id: post_id
			saved: true
			later: false
		}
		sql app.db {
			insert post into SavedPost
		} or {
			eprintln('toggle_save_post: failed to create saved post: ${post}')
			return false
		}
		return true
	}
}

// toggle_save_for_later_post (un)saves the given post for later for the user.
// returns true if this succeeds and false otherwise.
pub fn (app &DatabaseAccess) toggle_save_for_later_post(user_id int, post_id int) bool {
	if s := app.get_user_post_save_status(user_id, post_id) {
		if s.later {
			sql app.db {
				update SavedPost set later = false where id == s.id
			} or {
				eprintln('toggle_save_post: failed to unsave post for later (user_id: ${user_id}, post_id: ${post_id})')
				return false
			}
			return true
		} else {
			sql app.db {
				update SavedPost set later = true where id == s.id
			} or {
				eprintln('toggle_save_post: failed to save post for later (user_id: ${user_id}, post_id: ${post_id})')
				return false
			}
			return true
		}
	} else {
		post := SavedPost{
			user_id: user_id
			post_id: post_id
			saved: false
			later: true
		}
		sql app.db {
			insert post into SavedPost
		} or {
			eprintln('toggle_save_post: failed to create saved post for later: ${post}')
			return false
		}
		return true
	}
}
