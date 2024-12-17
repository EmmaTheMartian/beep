module main

import veb
import auth
import entity { User, Post }

////// Users //////

@['/api/user/register'; post]
fn (mut app App) api_user_register(mut ctx Context, username string, password string) veb.Result {
	println('reg: ${username}')

	if app.get_user_by_name(username) != none {
		ctx.error('username taken')
		return ctx.redirect('/register')
	}

	salt := auth.generate_salt()
	user := User{
		username: username
		password: auth.hash_password_with_salt(password, salt)
		password_salt: salt
	}

	sql app.db {
		insert user into User
	} or {
		eprintln('failed to insert user ${user}')
		return ctx.redirect('/')
	}

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
			eprintln('failed to get user for token: `${token}` for logout')
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
			eprintln('failed to get user for token: `${token}` for full_logout')
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
fn (mut app App) api_user_set_nickname(mut ctx Context) veb.Result {
	mut nickname := ?string(ctx.form['nickname'] or { '' })
	if (nickname or { '' }) == '' {
		nickname = none
	}
	user := app.whoami(mut ctx) or {
		ctx.error('you are not logged in!')
		return ctx.redirect('/login')
	}
	sql app.db {
		update User set nickname = nickname where id == user.id
	} or {
		ctx.error('failed to change nickname')
		eprintln('failed to update nickname for ${user} (${user.nickname} -> ${nickname})')
		return ctx.redirect('/me')
	}
	return ctx.redirect('/me')
}

////// Posts //////

@['/api/post/new_post'; post]
fn (mut app App) api_post_new_post(mut ctx Context, title string, body string) veb.Result {
	mut user := app.whoami(mut ctx) or {
		ctx.error('not logged in!')
		return ctx.redirect('/')
	}

	post := Post{
		author_id: user.id
		title: title
		body: body
	}

	sql app.db {
		insert post into Post
	} or {
		ctx.error('failed to post!')
		println('failed to post: ${post} from user ${user.id}')
		return ctx.redirect('/me')
	}

	user.posts << post

	return ctx.redirect('/me')
}
