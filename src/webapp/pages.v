module webapp

import veb
import entity { User }

fn (mut app App) index(mut ctx Context) veb.Result {
	ctx.title = app.config.instance.name
	user := app.whoami(mut ctx) or { User{} }
	recent_posts := app.get_recent_posts()
	pinned_posts := app.get_pinned_posts()
	motd := app.get_motd()
	return $veb.html('../templates/index.html')
}

fn (mut app App) login(mut ctx Context) veb.Result {
	ctx.title = 'login to ${app.config.instance.name}'
	user := app.whoami(mut ctx) or { User{} }
	return $veb.html('../templates/login.html')
}

fn (mut app App) register(mut ctx Context) veb.Result {
	ctx.title = 'register for ${app.config.instance.name}'
	user := app.whoami(mut ctx) or { User{} }
	return $veb.html('../templates/register.html')
}

fn (mut app App) me(mut ctx Context) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('not logged in')
		return ctx.redirect('/login')
	}
	ctx.title = '${app.config.instance.name} - ${user.get_name()}'
	return ctx.redirect('/user/${user.username}')
}

@['/me/saved']
fn (mut app App) me_saved(mut ctx Context) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('not logged in')
		return ctx.redirect('/login')
	}
	ctx.title = '${app.config.instance.name} - saved posts'
	posts := app.get_saved_posts_as_post_for(user.id)
	return $veb.html('../templates/saved_posts.html')
}

@['/me/saved_for_later']
fn (mut app App) me_saved_for_later(mut ctx Context) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('not logged in')
		return ctx.redirect('/login')
	}
	ctx.title = '${app.config.instance.name} - posts saved for later'
	posts := app.get_saved_for_later_posts_as_post_for(user.id)
	return $veb.html('../templates/saved_posts_for_later.html')
}

fn (mut app App) settings(mut ctx Context) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('not logged in')
		return ctx.redirect('/login')
	}
	ctx.title = '${app.config.instance.name} - settings'
	return $veb.html('../templates/settings.html')
}

fn (mut app App) admin(mut ctx Context) veb.Result {
	ctx.title = '${app.config.instance.name} dashboard'
	user := app.whoami(mut ctx) or { User{} }
	return $veb.html('../templates/admin.html')
}

fn (mut app App) inbox(mut ctx Context) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('not logged in')
		return ctx.redirect('/login')
	}
	ctx.title = '${app.config.instance.name} inbox'
	notifications := app.get_notifications_for(user.id)
	return $veb.html('../templates/inbox.html')
}

fn (mut app App) logout(mut ctx Context) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('not logged in')
		return ctx.redirect('/login')
	}
	ctx.title = '${app.config.instance.name} logout'
	return $veb.html('../templates/logout.html')
}

@['/user/:username']
fn (mut app App) user(mut ctx Context, username string) veb.Result {
	user := app.whoami(mut ctx) or { User{} }
	viewing := app.get_user_by_name(username) or {
		ctx.error('user not found')
		return ctx.redirect('/')
	}
	ctx.title = '${app.config.instance.name} - ${user.get_name()}'
	posts := app.get_posts_from_user(viewing.id, 10)
	return $veb.html('../templates/user.html')
}

@['/post/:post_id']
fn (mut app App) post(mut ctx Context, post_id int) veb.Result {
	post := app.get_post_by_id(post_id) or {
		ctx.error('no such post')
		return ctx.redirect('/')
	}
	ctx.title = '${app.config.instance.name} - ${post.title}'
	user := app.whoami(mut ctx) or { User{} }

	mut replying_to_post := app.get_unknown_post()
	mut replying_to_user := app.get_unknown_user()

	if post.replying_to != none {
		replying_to_post = app.get_post_by_id(post.replying_to) or {
			app.get_unknown_post()
		}
		replying_to_user = app.get_user_by_id(replying_to_post.author_id) or {
			app.get_unknown_user()
		}
	}

	return $veb.html('../templates/post.html')
}

@['/post/:post_id/edit']
fn (mut app App) edit(mut ctx Context, post_id int) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('not logged in')
		return ctx.redirect('/login')
	}
	post := app.get_post_by_id(post_id) or {
		ctx.error('no such post')
		return ctx.redirect('/')
	}
	if post.author_id != user.id {
		ctx.error('insufficient permissions')
		return ctx.redirect('/post/${post_id}')
	}
	ctx.title = '${app.config.instance.name} - editing ${post.title}'
	return $veb.html('../templates/edit.html')
}

@['/post/:post_id/reply']
fn (mut app App) reply(mut ctx Context, post_id int) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('not logged in')
		return ctx.redirect('/login')
	}
	post := app.get_post_by_id(post_id) or {
		ctx.error('no such post')
		return ctx.redirect('/')
	}
	ctx.title = '${app.config.instance.name} - reply to ${post.title}'
	replying := true
	replying_to := post_id
	replying_to_user := app.get_user_by_id(post.author_id) or {
		ctx.error('no such post')
		return ctx.redirect('/')
	}
	return $veb.html('../templates/new_post.html')
}

@['/post/new']
fn (mut app App) new(mut ctx Context) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('not logged in')
		return ctx.redirect('/login')
	}
	ctx.title = '${app.config.instance.name} - new post'
	replying := false
	replying_to := 0
	replying_to_user := User{}
	return $veb.html('../templates/new_post.html')
}

@['/tag/:tag']
fn (mut app App) tag(mut ctx Context, tag string) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('not logged in')
		return ctx.redirect('/login')
	}
	ctx.title = '${app.config.instance.name} - #${tag}'
	offset := 0
	return $veb.html('../templates/tag.html')
}

@['/tag/:tag/:offset']
fn (mut app App) tag_with_offset(mut ctx Context, tag string, offset int) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('not logged in')
		return ctx.redirect('/login')
	}
	ctx.title = '${app.config.instance.name} - #${tag}'
	return $veb.html('../templates/tag.html')
}

@['/search']
fn (mut app App) search(mut ctx Context, q string, offset int) veb.Result {
	user := app.whoami(mut ctx) or {
		ctx.error('not logged in')
		return ctx.redirect('/login')
	}
	ctx.title = '${app.config.instance.name} - search'
	return $veb.html('../templates/search.html')
}
