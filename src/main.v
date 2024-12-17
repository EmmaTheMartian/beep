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
