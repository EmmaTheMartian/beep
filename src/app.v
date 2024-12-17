module main

import veb
import auth
import db.pg
import entity { User, Post }

pub struct App {
pub:
	config Config
pub mut:
	db    pg.DB
	auth  auth.Auth[pg.DB]
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
		eprintln('no such user corresponding to token: ${token}')
		return none
	}
	return app.get_user_by_id(user_token.user_id)
}

pub fn (mut app App) get_recent_posts() []Post {
	posts := sql app.db {
		select from Post order by posted_at desc limit 10
	} or { [] }
	return posts
}

pub fn (mut app App) get_users() []User {
	users := sql app.db {
		select from User
	} or { [] }
	return users
}

pub fn (app &App) whoami(mut ctx Context) ?User {
	token := ctx.get_cookie('token') or {
		return none
	}.trim_space()
	if token == '' {
		return none
	}
	if user := app.get_user_by_token(ctx, token) {
		if user.username == '' || user.id == 0 {
			eprintln('a user had a token (${token}) for the blank user')
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
	}
	return none
}

pub fn (app &App) get_unknown_user() User {
	return User{ username: 'unknown' }
}

pub struct Context {
	veb.Context
pub mut:
	title string
}

pub fn (ctx &Context) is_logged_in() bool {
	return ctx.get_cookie('token') or { '' } != ''
}
