module main

import veb
import db.pg
import regex
import time
import auth
import entity { LikeCache, Like, Post, Site, User, Notification }

pub struct App {
	veb.StaticHandler
pub:
	config Config
pub mut:
	db         pg.DB
	auth       auth.Auth[pg.DB]
	validators struct {
	pub mut:
		username   StringValidator
		password   StringValidator
		nickname   StringValidator
		pronouns   StringValidator
		user_bio   StringValidator
		post_title StringValidator
		post_body  StringValidator
	}
}

pub fn (app &App) get_user_by_name(username string) ?User {
	users := sql app.db {
		select from User where username == username
	} or { [] }
	if users.len != 1 {
		return none
	}
	return users[0]
}

pub fn (app &App) get_user_by_id(id int) ?User {
	users := sql app.db {
		select from User where id == id
	} or { [] }
	if users.len != 1 {
		return none
	}
	return users[0]
}

pub fn (app &App) get_user_by_token(ctx &Context, token string) ?User {
	user_token := app.auth.find_token(token, ctx.ip()) or {
		eprintln('no such user corresponding to token')
		return none
	}
	return app.get_user_by_id(user_token.user_id)
}

pub fn (app &App) get_recent_posts() []Post {
	posts := sql app.db {
		select from Post order by posted_at desc limit 10
	} or { [] }
	return posts
}

pub fn (app &App) get_popular_posts() []Post {
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

pub fn (app &App) get_posts_from_user(user_id int) []Post {
	posts := sql app.db {
		select from Post where author_id == user_id order by posted_at desc
	} or { [] }
	return posts
}

pub fn (app &App) get_users() []User {
	users := sql app.db {
		select from User
	} or { [] }
	return users
}

pub fn (app &App) get_post_by_id(id int) ?Post {
	posts := sql app.db {
		select from Post where id == id limit 1
	} or { [] }
	if posts.len != 1 {
		return none
	}
	return posts[0]
}

pub fn (app &App) get_post_by_author_and_timestamp(author_id int, timestamp time.Time) ?Post {
	posts := sql app.db {
		select from Post where author_id == author_id && posted_at == timestamp order by posted_at desc limit 1
	} or { [] }
	if posts.len == 0 {
		return none
	}
	return posts[0]
}

pub fn (app &App) get_pinned_posts() []Post {
	posts := sql app.db {
		select from Post where pinned == true
	} or { [] }
	return posts
}

pub fn (app &App) whoami(mut ctx Context) ?User {
	token := ctx.get_cookie('token') or { return none }.trim_space()
	if token == '' {
		return none
	}
	if user := app.get_user_by_token(ctx, token) {
		if user.username == '' || user.id == 0 {
			eprintln('a user had a token for the blank user')
			// Clear token
			ctx.set_cookie(
				name:      'token'
				value:     ''
				same_site: .same_site_none_mode
				secure:    true
				path:      '/'
			)
			return none
		}
		return user
	} else {
		eprintln('a user had a token for a non-existent user (this token may have been expired and left in cookies)')
		// Clear token
		ctx.set_cookie(
			name:      'token'
			value:     ''
			same_site: .same_site_none_mode
			secure:    true
			path:      '/'
		)
		return none
	}
}

pub fn (app &App) get_unknown_user() User {
	return User{
		username: 'unknown'
	}
}

pub fn (app &App) get_unknown_post() Post {
	return Post{
		title: 'unknown'
	}
}

pub fn (app &App) logged_in_as(mut ctx Context, id int) bool {
	if !ctx.is_logged_in() {
		return false
	}
	return app.whoami(mut ctx) or { return false }.id == id
}

pub fn (app &App) does_user_like_post(user_id int, post_id int) bool {
	likes := sql app.db {
		select from Like where user_id == user_id && post_id == post_id
	} or { [] }
	if likes.len > 1 {
		// something is very wrong lol
		eprintln('a user somehow got two or more likes on the same post (user: ${user_id}, post: ${post_id})')
	} else if likes.len == 0 {
		return false
	}
	return likes.first().is_like
}

pub fn (app &App) does_user_dislike_post(user_id int, post_id int) bool {
	likes := sql app.db {
		select from Like where user_id == user_id && post_id == post_id
	} or { [] }
	if likes.len > 1 {
		// something is very wrong lol
		eprintln('a user somehow got two or more likes on the same post (user: ${user_id}, post: ${post_id})')
	} else if likes.len == 0 {
		return false
	}
	return !likes.first().is_like
}

pub fn (app &App) does_user_like_or_dislike_post(user_id int, post_id int) bool {
	likes := sql app.db {
		select from Like where user_id == user_id && post_id == post_id
	} or { [] }
	if likes.len > 1 {
		// something is very wrong lol
		eprintln('a user somehow got two or more likes on the same post (user: ${user_id}, post: ${post_id})')
	}
	return likes.len == 1
}

pub fn (app &App) get_net_likes_for_post(post_id int) int {
	// check cache
	cache := sql app.db {
		select from LikeCache where post_id == post_id limit 1
	} or { [] }

	mut likes := 0

	if cache.len != 1 {
		println('calculating net likes for post: ${post_id}')
		// calculate
		db_likes := sql app.db {
			select from Like where post_id == post_id
		} or { [] }

		for like in db_likes {
			if like.is_like {
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
		likes = cache.first().likes
	}

	return likes
}

pub fn (app &App) get_or_create_site_config() Site {
	configs := sql app.db {
		select from Site
	} or { [] }
	if configs.len == 0 {
		// make the site config
		site_config := Site{}
		sql app.db {
			insert site_config into Site
		} or { panic('failed to create site config (${err})') }
	} else if configs.len > 1 {
		// this should never happen
		panic('there are multiple site configs')
	}
	return configs[0]
}

@[inline]
pub fn (app &App) get_motd() string {
	site := app.get_or_create_site_config()
	return site.motd
}

pub fn (app &App) get_notifications_for(user_id int) []Notification {
	notifications := sql app.db {
		select from Notification where user_id == user_id
	} or { [] }
	return notifications
}

pub fn (app &App) get_notification_count(user_id int, limit int) int {
	notifications := sql app.db {
		select from Notification where user_id == user_id limit limit
	} or { [] }
	return notifications.len
}

pub fn (app &App) get_notification_count_for_frontend(user_id int, limit int) string {
	count := app.get_notification_count(user_id, limit)
	if count == 0 {
		return ''
	} else if count > limit {
		return ' (${count}+)'
	} else {
		return ' (${count})'
	}
}

pub fn (app &App) send_notification_to(user_id int, summary string, body string) {
	notification := Notification{
		user_id: user_id
		summary: summary
		body: body
	}
	sql app.db {
		insert notification into Notification
	} or {
		eprintln('failed to send notification ${notification}')
	}
}

// sends notifications to each user mentioned in a post
pub fn (app &App) process_post_mentions(post &Post) {
	author := app.get_user_by_id(post.author_id) or {
		eprintln('process_post_mentioned called on a post with a non-existent author: ${post}')
		return
	}
	author_name := author.get_name()

	// used so we do not send more than one notification per post
	mut notified_users := []int{}

	// notify who we replied to, if applicable
	if post.replying_to != none {
		if x := app.get_post_by_id(post.replying_to) {
			app.send_notification_to(x.author_id, '${author_name} replied to your post!', '${author_name} replied to *(${x.id})')
		}
	}

	// find mentions
	mut re := regex.regex_opt('@\\(${app.config.user.username_pattern}\\)') or {
		eprintln('failed to compile regex for process_post_mentions (err: ${err})')
		return
	}
	matches := re.find_all_str(post.body)
	for mat in matches {
		println('found mentioned user: ${mat}')
		username := mat#[2..-1]
		user := app.get_user_by_name(username) or {
			continue
		}

		if user.id in notified_users || user.id == author.id {
			continue
		}
		notified_users << user.id

		app.send_notification_to(
			user.id,
			'${author_name} mentioned you!',
			'you have been mentioned in this post: *(${post.id})'
		)
	}
}
