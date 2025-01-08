module database

import time
import entity { Post, User, Like, LikeCache }

// add_post adds a new post to the database, returns true if this succeeded and
// false otherwise.
pub fn (app &DatabaseAccess) add_post(post &Post) bool {
	sql app.db {
		insert post into Post
	} or {
		return false
	}
	return true
}

// get_post_by_id gets a post by its id, returns none if it does not exist.
pub fn (app &DatabaseAccess) get_post_by_id(id int) ?Post {
	posts := sql app.db {
		select from Post where id == id limit 1
	} or { [] }
	if posts.len != 1 {
		return none
	}
	return posts[0]
}

// get_post_by_author_and_timestamp gets a post by its author and timestamp,
// returns none if it does not exist
pub fn (app &DatabaseAccess) get_post_by_author_and_timestamp(author_id int, timestamp time.Time) ?Post {
	posts := sql app.db {
		select from Post where author_id == author_id && posted_at == timestamp order by posted_at desc limit 1
	} or { [] }
	if posts.len == 0 {
		return none
	}
	return posts[0]
}

// get_posts_with_tag gets a list of the 10 most recent posts with the given tag.
// this performs sql  string operations and probably is not very efficient, use
// sparingly.
pub fn (app &DatabaseAccess) get_posts_with_tag(tag string, offset int) []Post {
	posts := sql app.db {
		select from Post where body like '%#(${tag})%' order by posted_at desc limit 10 offset offset
	} or { [] }
	return posts
}

// get_pinned_posts returns a list of all pinned posts.
pub fn (app &DatabaseAccess) get_pinned_posts() []Post {
	posts := sql app.db {
		select from Post where pinned == true
	} or { [] }
	return posts
}

// get_recent_posts returns a list of the ten most recent posts.
pub fn (app &DatabaseAccess) get_recent_posts() []Post {
	posts := sql app.db {
		select from Post order by posted_at desc limit 10
	} or { [] }
	return posts
}

// get_popular_posts returns a list of the ten most liked posts.
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

// get_posts_from_user returns a list of all posts from a user in descending
// order by posting date.
pub fn (app &DatabaseAccess) get_posts_from_user(user_id int, limit int) []Post {
	posts := sql app.db {
		select from Post where author_id == user_id order by posted_at desc limit limit
	} or { [] }
	return posts
}

// get_all_posts_from_user returns a list of all posts from a user in descending
// order by posting date.
pub fn (app &DatabaseAccess) get_all_posts_from_user(user_id int) []Post {
	posts := sql app.db {
		select from Post where author_id == user_id order by posted_at desc
	} or { [] }
	return posts
}

// pin_post pins the given post, returns true if this succeeds and false
// otherwise.
pub fn (app &DatabaseAccess) pin_post(post_id int) bool {
	sql app.db {
		update Post set pinned = true where id == post_id
	} or {
		return false
	}
	return true
}

// update_post updates the given post's title and body with the given title and
// body, returns true if this succeeds and false otherwise.
pub fn (app &DatabaseAccess) update_post(post_id int, new_title string, new_body string) bool {
	sql app.db {
		update Post set body = new_body, title = new_title where id == post_id
	} or {
		return false
	}
	return true
}

// delete_post deletes the given post and all likes associated with it, returns
// true if this succeeds and false otherwise.
pub fn (app &DatabaseAccess) delete_post(id int) bool {
	sql app.db {
		delete from Post where id == id
		delete from Like where post_id == id
		delete from LikeCache where post_id == id
	} or {
		return false
	}
	return true
}

////// searching //////

// PostSearchResult represents a search result for a post.
pub struct PostSearchResult {
pub mut:
	post   Post
	author User
}

@[inline]
pub fn PostSearchResult.from_post(app &DatabaseAccess, post &Post) PostSearchResult {
	return PostSearchResult{
		post: post
		author: app.get_user_by_id(post.author_id) or { app.get_unknown_user() }
	}
}

@[inline]
pub fn PostSearchResult.from_post_list(app &DatabaseAccess, posts []Post) []PostSearchResult {
	mut results := []PostSearchResult{
		cap: posts.len,
		len: posts.len
	}
	for index, post in posts {
		results[index] = PostSearchResult.from_post(app, post)
	}
	return results
}

// search_for_post searches for posts matching the given query.
// todo: query options/filters, such as user:beep, !excluded-text, etc
pub fn (app &DatabaseAccess) search_for_posts(query string, limit int, offset int) []PostSearchResult {
	println('searching, q=${query},l=${limit},o=${offset}')
	posts := sql app.db {
		select from Post where title like '%${query}%' order by posted_at desc limit limit offset offset
	} or { [] }
	println('search results: ${posts.len}')
	return PostSearchResult.from_post_list(app, posts)
}
