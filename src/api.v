module main

import veb
import auth
import entity { Site, User, Post, Like, LikeCache }

////// Users //////

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
		username: username
		password: auth.hash_password_with_salt(password, salt)
		password_salt: salt
	}

	if app.config.user.default_theme != '' {
		user.theme = app.config.user.default_theme
	}

	sql app.db {
		insert user into User
	} or {
		eprintln('failed to insert user ${user}')
		return ctx.redirect('/')
	}

	println('reg: ${username}')

	if x := app.get_user_by_name(username) {
		token := app.auth.add_token(x.id, ctx.ip()) or {
			eprintln(err)
			ctx.error('could not create token for user with id ${user.id}')
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
		eprintln('could not log into newly-created user: ${user}')
		ctx.error('could not log into newly-created user.')
	}

	return ctx.redirect('/')
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
				eprintln('failed to yeet tokens for ${user.id} with ip ${ctx.ip()}')
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

	mut sanatized_nickname := ?string(sanatize(nickname).trim_space())
	if sanatized_nickname or { '' } == '' {
		sanatized_nickname = none
	}

	// validate
	if sanatized_nickname != none && !app.validators.nickname.validate(sanatized_nickname or { '' }) {
		ctx.error('invalid nickname')
		return ctx.redirect('/me')
	}

	sql app.db {
		update User set nickname = sanatized_nickname where id == user.id
	} or {
		ctx.error('failed to change nickname')
		eprintln('failed to update nickname for ${user} (${user.nickname} -> ${sanatized_nickname})')
		return ctx.redirect('/me')
	}

	return ctx.redirect('/me')
}

@['/api/user/set_muted'; post]
fn (mut app App) api_user_set_muted(mut ctx Context, muted bool) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('you are not logged in!')
		return ctx.redirect('/login')
	}

	if user.admin || app.config.dev_mode {
		sql app.db {
			update User set muted = muted where id == user.id
		} or {
			ctx.error('failed to change mute status')
			eprintln('failed to update mute status for ${user} (${user.muted} -> ${muted})')
			return ctx.redirect('/user/${user.username}')
		}
		return ctx.redirect('/user/${user.username}')
	} else {
		ctx.error('insufficient permissions!')
		eprintln('insufficient perms to update mute status for ${user} (${user.muted} -> ${muted})')
		return ctx.redirect('/user/${user.username}')
	}
}

@['/api/user/set_theme'; post]
fn (mut app App) api_user_set_theme(mut ctx Context, url string) veb.Result {
	if !app.config.user.allow_changing_theme {
		ctx.error('this instance disallows changing themes :(')
		return ctx.redirect('/me')
	}

	user := app.whoami(mut ctx) or {
		ctx.error('you are not logged in!')
		return ctx.redirect('/login')
	}

	mut theme := ?string(none)
	if url.trim_space() != '' {
		theme = sanatize(url).trim_space()
	}

	sql app.db {
		update User set theme = theme where id == user.id
	} or {
		ctx.error('failed to change theme')
		eprintln('failed to update theme for ${user} (${user.theme} -> ${theme})')
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

	clean_pronouns := sanatize(pronouns).trim_space()
	if !app.validators.pronouns.validate(clean_pronouns) {
		ctx.error('invalid pronouns')
		return ctx.redirect('/me')
	}

	sql app.db {
		update User set pronouns = clean_pronouns where id == user.id
	} or {
		ctx.error('failed to change pronouns')
		eprintln('failed to update pronouns for ${user} (${user.pronouns} -> ${clean_pronouns})')
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

	clean_bio := sanatize(bio).trim_space()
	if !app.validators.user_bio.validate(clean_bio) {
		ctx.error('invalid bio')
		return ctx.redirect('/me')
	}

	sql app.db {
		update User set bio = clean_bio where id == user.id
	} or {
		ctx.error('failed to change bio')
		eprintln('failed to update bio for ${user} (${user.bio} -> ${clean_bio})')
		return ctx.redirect('/me')
	}

	return ctx.redirect('/me')
}

////// Posts //////

@['/api/post/new_post'; post]
fn (mut app App) api_post_new_post(mut ctx Context, title string, body string) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('not logged in!')
		return ctx.redirect('/')
	}

	if user.muted {
		ctx.error('you are muted!')
		return ctx.redirect('/me')
	}

	// validate title
	if !app.validators.post_title.validate(title) {
		ctx.error('invalid title')
		return ctx.redirect('/me')
	}

	// validate body
	if !app.validators.post_body.validate(body) {
		ctx.error('invalid body')
		return ctx.redirect('/me')
	}

	post := Post{
		author_id: user.id
		title: sanatize(title)
		body: sanatize(body)
	}

	sql app.db {
		insert post into Post
	} or {
		ctx.error('failed to post!')
		println('failed to post: ${post} from user ${user.id}')
		return ctx.redirect('/me')
	}

	return ctx.redirect('/me')
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
		sql app.db {
			delete from Post where id == id
			delete from Like where post_id == id
		} or {
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
	user := app.whoami(mut ctx) or {
		return ctx.unauthorized('not logged in')
	}

	post := app.get_post_by_id(id) or {
		return ctx.server_error('post does not exist')
	}

	if app.does_user_like_post(user.id, post.id) {
		sql app.db {
			delete from Like where user_id == user.id && post_id == post.id
			// yeet the old cached like value
			delete from LikeCache where post_id == post.id
		} or {
			eprintln('user ${user.id} failed to unlike post ${id}')
			return ctx.server_error('failed to unlike post')
		}
		return ctx.ok('unliked post')
	} else {
		// remove the old dislike, if it exists
		if app.does_user_dislike_post(user.id, post.id) {
			sql app.db {
				delete from Like where user_id == user.id && post_id == post.id
			} or {
				eprintln('user ${user.id} failed to remove dislike on post ${id} when liking it')
			}
		}

		like := Like{
			user_id: user.id
			post_id: post.id
			is_like: true
		}
		sql app.db {
			insert like into Like
			// yeet the old cached like value
			delete from LikeCache where post_id == post.id
		} or {
			eprintln('user ${user.id} failed to like post ${id}')
			return ctx.server_error('failed to like post')
		}
		return ctx.ok('liked post')
	}
}

@['/api/post/dislike']
fn (mut app App) api_post_dislike(mut ctx Context, id int) veb.Result {
	user := app.whoami(mut ctx) or {
		return ctx.unauthorized('not logged in')
	}

	post := app.get_post_by_id(id) or {
		return ctx.server_error('post does not exist')
	}

	if app.does_user_dislike_post(user.id, post.id) {
		sql app.db {
			delete from Like where user_id == user.id && post_id == post.id
			// yeet the old cached like value
			delete from LikeCache where post_id == post.id
		} or {
			eprintln('user ${user.id} failed to unlike post ${id}')
			return ctx.server_error('failed to unlike post')
		}
		return ctx.ok('undisliked post')
	} else {
		// remove the old like, if it exists
		if app.does_user_like_post(user.id, post.id) {
			sql app.db {
				delete from Like where user_id == user.id && post_id == post.id
			} or {
				eprintln('user ${user.id} failed to remove like on post ${id} when disliking it')
			}
		}

		like := Like{
			user_id: user.id
			post_id: post.id
			is_like: false
		}
		sql app.db {
			insert like into Like
			// yeet the old cached like value
			delete from LikeCache where post_id == post.id
		} or {
			eprintln('user ${user.id} failed to dislike post ${id}')
			return ctx.server_error('failed to dislike post')
		}
		return ctx.ok('disliked post')
	}
}

////// Site //////

@['/api/site/set_motd'; post]
fn (mut app App) api_site_set_motd(mut ctx Context, motd string) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('not logged in!')
		return ctx.redirect('/login')
	}

	if user.admin {
		sql app.db {
			update Site set motd = motd where id == 1
		} or {
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
