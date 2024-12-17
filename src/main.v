module main

import db.pg
import veb
import auth
import entity
import os

fn init_db(db pg.DB) ! {
	sql db {
		create table entity.User
		create table entity.Post
		create table entity.Like
		create table entity.LikeCache
	}!
}

fn main() {
	config := load_config_from(os.args[1])

	mut db := pg.connect(pg.Config{
		host:     config.postgres.host
		dbname:   config.postgres.db
		user:     config.postgres.user
		password: config.postgres.password
		port:     config.postgres.port
	})!

	defer {
		db.close()
	}

	mut app := &App{
		config: config
		db: db
		auth: auth.new(db)
	}

	init_db(db)!

	if config.dev_mode {
		println('NOTE: YOU ARE IN DEV MODE')
	}

	veb.run[App, Context](mut app, app.config.http.port)
}

// bad users, no RCE!
fn sanatize(text string) string {
	return text
		.replace('&', '&amp;')
		.replace('<', '&lt;')
		.replace('>', '&gt;')
		.replace('"', '&quot;') // where did the `e` go??
		.replace('\'', '&#039;') // and what is this?!?!?
	// in the above two comments, you can see me (emma) having spontaneous
	// anger at old spec design, where "quote" becomes "quot" and a single
	// quote is an incomprehensible string of numbers.
	// my proposition: `dquote` and `squote`.
	// (end rant)
}
