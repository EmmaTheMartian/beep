module database

import time
import entity { Post, Like, LikeCache }

// get a post by its id, returns none if it does not exist
pub fn (app &DatabaseAccess) get_post_by_id(id int) ?Post {
	posts := sql app.db {
		select from Post where id == id limit 1
	} or { [] }
	if posts.len != 1 {
		return none
	}
	return posts[0]
}

// get a post by its author and timestamp, returns none if it does not exist
pub fn (app &DatabaseAccess) get_post_by_author_and_timestamp(author_id int, timestamp time.Time) ?Post {
	posts := sql app.db {
		select from Post where author_id == author_id && posted_at == timestamp order by posted_at desc limit 1
	} or { [] }
	if posts.len == 0 {
		return none
	}
	return posts[0]
}

// get a list of posts given a tag. this performs sql string operations and
// probably is not very efficient, use sparingly.
pub fn (app &DatabaseAccess) get_posts_with_tag(tag string, offset int) []Post {
	posts := sql app.db {
		select from Post where body like '%#(${tag})%' order by posted_at desc limit 10 offset offset
	} or { [] }
	return posts
}

// returns a list of all pinned posts
pub fn (app &DatabaseAccess) get_pinned_posts() []Post {
	posts := sql app.db {
		select from Post where pinned == true
	} or { [] }
	return posts
}

// returns a list of the ten most recent posts.
pub fn (app &DatabaseAccess) get_recent_posts() []Post {
	posts := sql app.db {
		select from Post order by posted_at desc limit 10
	} or { [] }
	return posts
}

// returns a list of the ten most liked posts.
// TODO: make this time-gated (i.e, top ten liked posts of the day)
pub fn (app &DatabaseAccess) get_popular_posts() []Post {
	cached_likes := sql app.db {
		select from LikeCache order by likes desc limit 10
	} or { [] }
	posts := cached_likes.map(fn [app] (it LikeCache) Post {
		return app.get_post_by_id(it.post_id) or {
			eprintln('cached like ${it} does not have a post related to it (from get_popular_posts)')
			return Post{}
		}
	}).filter(it.id != 0)
	return posts
}

// returns a list of all posts from a user in descending order of date
pub fn (app &DatabaseAccess) get_posts_from_user(user_id int) []Post {
	posts := sql app.db {
		select from Post where author_id == user_id order by posted_at desc
	} or { [] }
	return posts
}
