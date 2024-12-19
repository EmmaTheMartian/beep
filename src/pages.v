module main

import veb
import entity { User, Post }

fn (mut app App) index(mut ctx Context) veb.Result {
	ctx.title = app.config.instance.name
	user := app.whoami(mut ctx) or { User{} }
	recent_posts := app.get_recent_posts()
	pinned_posts := app.get_pinned_posts()
	motd := app.get_motd()
	return $veb.html()
}

fn (mut app App) login(mut ctx Context) veb.Result {
	ctx.title = 'login to ${app.config.instance.name}'
	user := app.whoami(mut ctx) or { User{} }
	return $veb.html()
}

fn (mut app App) register(mut ctx Context) veb.Result {
	ctx.title = 'register for ${app.config.instance.name}'
	user := app.whoami(mut ctx) or { User{} }
	return $veb.html()
}

fn (mut app App) me(mut ctx Context) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('not logged in')
		return ctx.redirect('/login')
	}
	ctx.title = '${app.config.instance.name} - ${user.get_name()}'
	return ctx.redirect('/user/${user.username}')
}

fn (mut app App) admin(mut ctx Context) veb.Result {
	ctx.title = '${app.config.instance.name} dashboard'
	user := app.whoami(mut ctx) or { User{} }
	return $veb.html()
}

@['/user/:username']
fn (mut app App) user(mut ctx Context, username string) veb.Result {
	user := app.whoami(mut ctx) or { User{} }
	viewing := app.get_user_by_name(username) or {
		ctx.error('user not found')
		return ctx.redirect('/')
	}
	ctx.title = '${app.config.instance.name} - ${user.get_name()}'
	return $veb.html()
}

@['/post/:post_id']
fn (mut app App) post(mut ctx Context, post_id int) veb.Result {
	post := app.get_post_by_id(post_id) or {
		ctx.error('no such post')
		return ctx.redirect('/')
	}
	ctx.title = '${app.config.instance.name} - ${post.title}'
	user := app.whoami(mut ctx) or { User{} }
	return $veb.html()
}
