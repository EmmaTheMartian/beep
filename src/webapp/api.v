module webapp

import veb
import auth
import entity { Like, LikeCache, Post, Site, User, Notification }
import database { PostSearchResult }

// search_hard_limit is the maximum limit for a search query, used to prevent
// people from requesting searches with huge limits and straining the SQL server
pub const search_hard_limit := 50

////// user //////

@['/api/user/register'; post]
fn (mut app App) api_user_register(mut ctx Context, username string, password string) veb.Result {
	if app.get_user_by_name(username) != none {
		ctx.error('username taken')
		return ctx.redirect('/register')
	}

	// validate username
	if !app.validators.username.validate(username) {
		ctx.error('invalid username')
		return ctx.redirect('/register')
	}

	// validate password
	if !app.validators.password.validate(password) {
		ctx.error('invalid password')
		return ctx.redirect('/register')
	}

	salt := auth.generate_salt()
	mut user := User{
		username:      username
		password:      auth.hash_password_with_salt(password, salt)
		password_salt: salt
	}

	if app.config.instance.default_theme != '' {
		user.theme = app.config.instance.default_theme
	}

	if x := app.new_user(user) {
		app.send_notification_to(
			x.id,
			app.config.welcome.summary.replace('%s', x.get_name()),
			app.config.welcome.body.replace('%s', x.get_name())
		)
		token := app.auth.add_token(x.id, ctx.ip()) or {
			eprintln(err)
			ctx.error('api_user_register: could not create token for user with id ${x.id}')
			return ctx.redirect('/')
		}
		ctx.set_cookie(
			name:      'token'
			value:     token
			same_site: .same_site_none_mode
			secure:    true
			path:      '/'
		)
	} else {
		eprintln('api_user_register: could not log into newly-created user: ${user}')
		ctx.error('could not log into newly-created user.')
	}

	return ctx.redirect('/')
}

@['/api/user/set_username'; post]
fn (mut app App) api_user_set_username(mut ctx Context, new_username string) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('you are not logged in!')
		return ctx.redirect('/login')
	}

	if app.get_user_by_name(new_username) != none {
		ctx.error('username taken')
		return ctx.redirect('/settings')
	}

	// validate username
	if !app.validators.username.validate(new_username) {
		ctx.error('invalid username')
		return ctx.redirect('/settings')
	}

	if !app.set_username(user.id, new_username) {
		ctx.error('failed to update username')
	}

	return ctx.redirect('/settings')
}

@['/api/user/set_password'; post]
fn (mut app App) api_user_set_password(mut ctx Context, current_password string, new_password string) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('you are not logged in!')
		return ctx.redirect('/login')
	}

	if !auth.compare_password_with_hash(current_password, user.password_salt, user.password) {
		ctx.error('current_password is incorrect')
		return ctx.redirect('/settings')
	}

	// validate password
	if !app.validators.password.validate(new_password) {
		ctx.error('invalid password')
		return ctx.redirect('/settings')
	}

	hashed_new_password := auth.hash_password_with_salt(new_password, user.password_salt)
	if !app.set_password(user.id, hashed_new_password) {
		ctx.error('failed to update password')
		return ctx.redirect('/settings')
	}

	// invalidate tokens and log out
	app.auth.delete_tokens_for_user(user.id) or {
		eprintln('failed to yeet tokens during password deletion for ${user.id} (${err})')
		return ctx.redirect('/settings')
	}
	ctx.set_cookie(
		name:      'token'
		value:     ''
		same_site: .same_site_none_mode
		secure:    true
		path:      '/'
	)

	return ctx.redirect('/login')
}

@['/api/user/login'; post]
fn (mut app App) api_user_login(mut ctx Context, username string, password string) veb.Result {
	user := app.get_user_by_name(username) or {
		ctx.error('invalid credentials')
		return ctx.redirect('/login')
	}

	if !auth.compare_password_with_hash(password, user.password_salt, user.password) {
		ctx.error('invalid credentials')
		return ctx.redirect('/login')
	}

	token := app.auth.add_token(user.id, ctx.ip()) or {
		eprintln('failed to add token on log in: ${err}')
		ctx.error('could not create token for user with id ${user.id}')
		return ctx.redirect('/login')
	}

	ctx.set_cookie(
		name:      'token'
		value:     token
		same_site: .same_site_none_mode
		secure:    true
		path:      '/'
	)

	return ctx.redirect('/')
}

@['/api/user/logout']
fn (mut app App) api_user_logout(mut ctx Context) veb.Result {
	if token := ctx.get_cookie('token') {
		if user := app.get_user_by_token(ctx, token) {
			app.auth.delete_tokens_for_ip(ctx.ip()) or {
				eprintln('failed to yeet tokens for ${user.id} with ip ${ctx.ip()} (${err})')
				return ctx.redirect('/login')
			}
		} else {
			eprintln('failed to get user for token for logout')
		}
	} else {
		eprintln('failed to get token cookie for logout')
	}

	ctx.set_cookie(
		name:      'token'
		value:     ''
		same_site: .same_site_none_mode
		secure:    true
		path:      '/'
	)

	return ctx.redirect('/login')
}

@['/api/user/full_logout']
fn (mut app App) api_user_full_logout(mut ctx Context) veb.Result {
	if token := ctx.get_cookie('token') {
		if user := app.get_user_by_token(ctx, token) {
			app.auth.delete_tokens_for_user(user.id) or {
				eprintln('failed to yeet tokens for ${user.id}')
				return ctx.redirect('/login')
			}
		} else {
			eprintln('failed to get user for token for full_logout')
		}
	} else {
		eprintln('failed to get token cookie for full_logout')
	}

	ctx.set_cookie(
		name:      'token'
		value:     ''
		same_site: .same_site_none_mode
		secure:    true
		path:      '/'
	)

	return ctx.redirect('/login')
}

@['/api/user/set_nickname'; post]
fn (mut app App) api_user_set_nickname(mut ctx Context, nickname string) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('you are not logged in!')
		return ctx.redirect('/login')
	}

	mut clean_nickname := ?string(nickname.trim_space())
	if clean_nickname or { '' } == '' {
		clean_nickname = none
	}

	// validate
	if clean_nickname != none && !app.validators.nickname.validate(clean_nickname or { '' }) {
		ctx.error('invalid nickname')
		return ctx.redirect('/me')
	}

	if !app.set_nickname(user.id, clean_nickname) {
		eprintln('failed to update nickname for ${user} (${user.nickname} -> ${clean_nickname})')
		return ctx.redirect('/me')
	}

	return ctx.redirect('/me')
}

@['/api/user/set_muted'; post]
fn (mut app App) api_user_set_muted(mut ctx Context, id int, muted bool) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('you are not logged in!')
		return ctx.redirect('/login')
	}

	to_mute := app.get_user_by_id(id) or {
		ctx.error('no such user')
		return ctx.redirect('/')
	}

	if user.admin {
		if !app.set_muted(to_mute.id, muted) {
			ctx.error('failed to change mute status')
			return ctx.redirect('/user/${to_mute.username}')
		}
		return ctx.redirect('/user/${to_mute.username}')
	} else {
		ctx.error('insufficient permissions!')
		eprintln('insufficient perms to update mute status for ${to_mute} (${to_mute.muted} -> ${muted})')
		return ctx.redirect('/user/${to_mute.username}')
	}
}

@['/api/user/set_automated'; post]
fn (mut app App) api_user_set_automated(mut ctx Context, is_automated bool) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('you are not logged in!')
		return ctx.redirect('/login')
	}

	if !app.set_automated(user.id, is_automated) {
		ctx.error('failed to set automated status.')
	}

	return ctx.redirect('/me')
}

@['/api/user/set_theme'; post]
fn (mut app App) api_user_set_theme(mut ctx Context, url string) veb.Result {
	if !app.config.instance.allow_changing_theme {
		ctx.error('this instance disallows changing themes :(')
		return ctx.redirect('/me')
	}

	user := app.whoami(mut ctx) or {
		ctx.error('you are not logged in!')
		return ctx.redirect('/login')
	}

	mut theme := ?string(none)
	if url.trim_space() != '' {
		theme = url.trim_space()
	}

	if !app.set_theme(user.id, theme) {
		ctx.error('failed to change theme')
		return ctx.redirect('/me')
	}

	return ctx.redirect('/me')
}

@['/api/user/set_pronouns'; post]
fn (mut app App) api_user_set_pronouns(mut ctx Context, pronouns string) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('you are not logged in!')
		return ctx.redirect('/login')
	}

	clean_pronouns := pronouns.trim_space()
	if !app.validators.pronouns.validate(clean_pronouns) {
		ctx.error('invalid pronouns')
		return ctx.redirect('/me')
	}

	if !app.set_pronouns(user.id, clean_pronouns) {
		ctx.error('failed to change pronouns')
		return ctx.redirect('/me')
	}

	return ctx.redirect('/me')
}

@['/api/user/set_bio'; post]
fn (mut app App) api_user_set_bio(mut ctx Context, bio string) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('you are not logged in!')
		return ctx.redirect('/login')
	}

	clean_bio := bio.trim_space()
	if !app.validators.user_bio.validate(clean_bio) {
		ctx.error('invalid bio')
		return ctx.redirect('/me')
	}

	if !app.set_bio(user.id, clean_bio) {
		eprintln('failed to update bio for ${user} (${user.bio} -> ${clean_bio})')
		return ctx.redirect('/me')
	}

	return ctx.redirect('/me')
}

@['/api/user/get_name']
fn (mut app App) api_user_get_name(mut ctx Context, username string) veb.Result {
	user := app.get_user_by_name(username) or { return ctx.server_error('no such user') }
	return ctx.text(user.get_name())
}

@['/api/user/delete']
fn (mut app App) api_user_delete(mut ctx Context, id int) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('you are not logged in!')
		return ctx.redirect('/login')
	}

	println('attempting to delete ${id} as ${user.id}')

	if user.admin || user.id == id {
		// yeet
		if !app.delete_user(user.id) {
			ctx.error('failed to delete user: ${id}')
			return ctx.redirect('/')
		}

		app.auth.delete_tokens_for_user(id) or {
			eprintln('failed to delete tokens for user during deletion: ${id}')
		}
		// log out
		if user.id == id {
			ctx.set_cookie(
				name:      'token'
				value:     ''
				same_site: .same_site_none_mode
				secure:    true
				path:      '/'
			)
		}
		println('deleted user ${id}')
	} else {
		ctx.error('be nice. deleting other users is off-limits.')
	}

	return ctx.redirect('/')
}

@['/api/user/search'; get]
fn (mut app App) api_user_search(mut ctx Context, query string, limit int, offset int) veb.Result {
	if limit >= search_hard_limit {
		return ctx.text('limit exceeds hard limit (${search_hard_limit})')
	}
	users := app.search_for_users(query, limit, offset)
	return ctx.json[[]User](users)
}

@['/api/user/whoami'; get]
fn (mut app App) api_user_whoami(mut ctx Context) veb.Result {
	user := app.whoami(mut ctx) or {
		return ctx.text('not logged in')
	}
	return ctx.text(user.username)
}

/// user/notification ///

@['/api/user/notification/clear']
fn (mut app App) api_user_notification_clear(mut ctx Context, id int) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('you are not logged in!')
		return ctx.redirect('/login')
	}

	if notification := app.get_notification_by_id(id) {
		if notification.user_id != user.id {
			ctx.error('no such notification for user')
			return ctx.redirect('/inbox')
		} else {
			if !app.delete_notification(id) {
				ctx.error('failed to delete notification')
				return ctx.redirect('/inbox')
			}
		}
	} else {
		ctx.error('no such notification for user')
	}

	return ctx.redirect('/inbox')
}

@['/api/user/notification/clear_all']
fn (mut app App) api_user_notification_clear_all(mut ctx Context) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('you are not logged in!')
		return ctx.redirect('/login')
	}
	if !app.delete_notifications_for_user(user.id) {
		ctx.error('failed to delete notifications')
		return ctx.redirect('/inbox')
	}
	return ctx.redirect('/inbox')
}

////// post //////

@['/api/post/new_post'; post]
fn (mut app App) api_post_new_post(mut ctx Context, replying_to int, title string, body string) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('not logged in!')
		return ctx.redirect('/login')
	}

	if user.muted {
		ctx.error('you are muted!')
		return ctx.redirect('/post/new')
	}

	// validate title
	if !app.validators.post_title.validate(title) {
		ctx.error('invalid title')
		return ctx.redirect('/post/new')
	}

	// validate body
	if !app.validators.post_body.validate(body) {
		ctx.error('invalid body')
		return ctx.redirect('/post/new')
	}

	mut post := Post{
		author_id: user.id
		title:     title
		body:      body
	}

	if replying_to != 0 {
		// check if replying post exists
		app.get_post_by_id(replying_to) or {
			ctx.error('the post you are trying to reply to does not exist')
			return ctx.redirect('/post/new')
		}
		post.replying_to = replying_to
	}

	if !app.add_post(post) {
		ctx.error('failed to post!')
		println('failed to post: ${post} from user ${user.id}')
		return ctx.redirect('/post/new')
	}

	// find the post's id to process mentions with
	if x := app.get_post_by_author_and_timestamp(user.id, post.posted_at) {
		app.process_post_mentions(x)
		return ctx.redirect('/post/${x.id}')
	} else {
		ctx.error('failed to get_post_by_timestamp_and_author for ${post}')
		return ctx.redirect('/me')
	}
}

@['/api/post/delete'; post]
fn (mut app App) api_post_delete(mut ctx Context, id int) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('not logged in!')
		return ctx.redirect('/login')
	}

	post := app.get_post_by_id(id) or {
		ctx.error('post does not exist')
		return ctx.redirect('/')
	}

	if user.admin || user.id == post.author_id {
		if !app.delete_post(post.id) {
			ctx.error('failed to delete post')
			eprintln('failed to delete post: ${id}')
			return ctx.redirect('/')
		}
		println('deleted post: ${id}')
		return ctx.redirect('/')
	} else {
		ctx.error('insufficient permissions!')
		eprintln('insufficient perms to delete post: ${id} (${user.id})')
		return ctx.redirect('/')
	}
}

@['/api/post/like']
fn (mut app App) api_post_like(mut ctx Context, id int) veb.Result {
	user := app.whoami(mut ctx) or { return ctx.unauthorized('not logged in') }

	post := app.get_post_by_id(id) or { return ctx.server_error('post does not exist') }

	if app.does_user_like_post(user.id, post.id) {
		if !app.unlike_post(post.id, user.id) {
			eprintln('user ${user.id} failed to unlike post ${id}')
			return ctx.server_error('failed to unlike post')
		}
		return ctx.ok('unliked post')
	} else {
		// remove the old dislike, if it exists
		if app.does_user_dislike_post(user.id, post.id) {
			if !app.unlike_post(post.id, user.id) {
				eprintln('user ${user.id} failed to remove dislike on post ${id} when liking it')
			}
		}

		like := Like{
			user_id: user.id
			post_id: post.id
			is_like: true
		}
		if !app.add_like(like) {
			eprintln('user ${user.id} failed to like post ${id}')
			return ctx.server_error('failed to like post')
		}
		return ctx.ok('liked post')
	}
}

@['/api/post/dislike']
fn (mut app App) api_post_dislike(mut ctx Context, id int) veb.Result {
	user := app.whoami(mut ctx) or { return ctx.unauthorized('not logged in') }

	post := app.get_post_by_id(id) or { return ctx.server_error('post does not exist') }

	if app.does_user_dislike_post(user.id, post.id) {
		if !app.unlike_post(post.id, user.id) {
			eprintln('user ${user.id} failed to undislike post ${id}')
			return ctx.server_error('failed to undislike post')
		}
		return ctx.ok('undisliked post')
	} else {
		// remove the old like, if it exists
		if app.does_user_like_post(user.id, post.id) {
			if !app.unlike_post(post.id, user.id) {
				eprintln('user ${user.id} failed to remove like on post ${id} when disliking it')
			}
		}

		like := Like{
			user_id: user.id
			post_id: post.id
			is_like: false
		}
		if !app.add_like(like) {
			eprintln('user ${user.id} failed to dislike post ${id}')
			return ctx.server_error('failed to dislike post')
		}
		return ctx.ok('disliked post')
	}
}

@['/api/post/save']
fn (mut app App) api_post_save(mut ctx Context, id int) veb.Result {
	user := app.whoami(mut ctx) or { return ctx.unauthorized('not logged in') }

	if app.get_post_by_id(id) != none {
		if app.toggle_save_post(user.id, id) {
			return ctx.text('toggled save')
		} else {
			return ctx.server_error('failed to save post')
		}
	} else {
		return ctx.server_error('post does not exist')
	}
}

@['/api/post/save_for_later']
fn (mut app App) api_post_save_for_later(mut ctx Context, id int) veb.Result {
	user := app.whoami(mut ctx) or { return ctx.unauthorized('not logged in') }

	if app.get_post_by_id(id) != none {
		if app.toggle_save_for_later_post(user.id, id) {
			return ctx.text('toggled save')
		} else {
			return ctx.server_error('failed to save post')
		}
	} else {
		return ctx.server_error('post does not exist')
	}
}

@['/api/post/get_title']
fn (mut app App) api_post_get_title(mut ctx Context, id int) veb.Result {
	post := app.get_post_by_id(id) or { return ctx.server_error('no such post') }
	return ctx.text(post.title)
}

@['/api/post/edit'; post]
fn (mut app App) api_post_edit(mut ctx Context, id int, title string, body string) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('not logged in!')
		return ctx.redirect('/login')
	}
	post := app.get_post_by_id(id) or {
		ctx.error('no such post')
		return ctx.redirect('/')
	}
	if post.author_id != user.id {
		ctx.error('insufficient permissions')
		return ctx.redirect('/')
	}

	if !app.update_post(id, title, body) {
		eprintln('failed to update post')
		ctx.error('failed to update post')
		return ctx.redirect('/')
	}

	return ctx.redirect('/post/${id}')
}

@['/api/post/pin'; post]
fn (mut app App) api_post_pin(mut ctx Context, id int) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('not logged in!')
		return ctx.redirect('/login')
	}

	if user.admin {
		if !app.pin_post(id) {
			eprintln('failed to pin post: ${id}')
			ctx.error('failed to pin post')
			return ctx.redirect('/post/${id}')
		}
		return ctx.redirect('/post/${id}')
	} else {
		ctx.error('insufficient permissions!')
		eprintln('insufficient perms to pin post: ${id} (${user.id})')
		return ctx.redirect('/')
	}
}

@['/api/post/get/<id>'; get]
fn (mut app App) api_post_get_post(mut ctx Context, id int) veb.Result {
	post := app.get_post_by_id(id) or {
		return ctx.text('no such post')
	}
	return ctx.json[Post](post)
}

@['/api/post/search'; get]
fn (mut app App) api_post_search(mut ctx Context, query string, limit int, offset int) veb.Result {
	if limit >= search_hard_limit {
		return ctx.text('limit exceeds hard limit (${search_hard_limit})')
	}
	posts := app.search_for_posts(query, limit, offset)
	return ctx.json[[]PostSearchResult](posts)
}

////// site //////

@['/api/site/set_motd'; post]
fn (mut app App) api_site_set_motd(mut ctx Context, motd string) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('not logged in!')
		return ctx.redirect('/login')
	}

	if user.admin {
		if !app.set_motd(motd) {
			ctx.error('failed to set motd')
			eprintln('failed to set motd: ${motd}')
			return ctx.redirect('/')
		}
		println('set motd to: ${motd}')
		return ctx.redirect('/')
	} else {
		ctx.error('insufficient permissions!')
		eprintln('insufficient perms to set motd to: ${motd} (${user.id})')
		return ctx.redirect('/')
	}
}
