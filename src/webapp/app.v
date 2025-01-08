module webapp

import veb
import db.pg
import regex
import auth
import entity { LikeCache, Like, Post, Site, User, Notification }
import database { DatabaseAccess }

pub struct App {
	veb.StaticHandler
	DatabaseAccess
pub:
	config Config
pub mut:
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

// get_user_by_token returns a user by their token, returns none if the user was
// not found.
pub fn (app &App) get_user_by_token(ctx &Context, token string) ?User {
	user_token := app.auth.find_token(token, ctx.ip()) or {
		eprintln('no such user corresponding to token')
		return none
	}
	return app.get_user_by_id(user_token.user_id)
}

// whoami returns the current logged in user, or none if the user is not logged
// in.
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

// logged_in_as returns true if the user is logged in as the provided user id.
pub fn (app &App) logged_in_as(mut ctx Context, id int) bool {
	if !ctx.is_logged_in() {
		return false
	}
	return app.whoami(mut ctx) or { return false }.id == id
}

// get_motd returns the site's message of the day.
@[inline]
pub fn (app &App) get_motd() string {
	site := app.get_or_create_site_config()
	return site.motd
}

// get_notification_count_for_frontend returns the notification count for a
// given user, formatted for usage on the frontend.
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

// process_post_mentions parses a post's body to send notifications for mentions
// or replies.
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
