module main

import veb
import entity { User, Post }

fn (mut app App) index(mut ctx Context) veb.Result {
	ctx.title = 'beep'
	recent_posts := app.get_recent_posts()
	user := app.whoami(mut ctx) or { User{} }
	return $veb.html()
}

fn (mut app App) login(mut ctx Context) veb.Result {
	ctx.title = 'login to beep'
	user := app.whoami(mut ctx) or { User{} }
	return $veb.html()
}

fn (mut app App) register(mut ctx Context) veb.Result {
	ctx.title = 'register for beep'
	user := app.whoami(mut ctx) or { User{} }
	return $veb.html()
}

fn (mut app App) me(mut ctx Context) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('not logged in')
		return ctx.redirect('/login')
	}
	ctx.title = 'beep - ${user.get_name()}'
	return $veb.html()
}

fn (mut app App) admin(mut ctx Context) veb.Result {
	ctx.title = 'beep dashboard'
	user := app.whoami(mut ctx) or { User{} }
	return $veb.html()
}

@['/user/:username']
fn (mut app App) user(mut ctx Context, username string) veb.Result {
	user := app.get_user_by_name(username) or {
		ctx.error('user not found')
		return ctx.redirect('/')
	}
	self := app.whoami(mut ctx) or { User{} }
	ctx.title = 'beep - ${user.get_name()}'
	return $veb.html()
}
