module main

import db.pg
import veb
import auth
import entity
import os
import webapp { App, Context, StringValidator }

fn init_db(db pg.DB) ! {
	sql db {
		create table entity.Site
		create table entity.User
		create table entity.Post
		create table entity.Like
		create table entity.LikeCache
		create table entity.Notification
	}!
}

fn main() {
	config := webapp.load_config_from(os.args[1])

	println('-> connecting to db...')
	mut db := pg.connect(pg.Config{
		host:     config.postgres.host
		dbname:   config.postgres.db
		user:     config.postgres.user
		password: config.postgres.password
		port:     config.postgres.port
	})!
	println('<- connected')

	defer {
		db.close()
	}

	mut app := &App{
		config: config
		db:     db
		auth:   auth.new(db)
	}

	// vfmt off
	app.validators.username = StringValidator.new(config.user.username_min_len, config.user.username_max_len, config.user.username_pattern)
	app.validators.password = StringValidator.new(config.user.username_min_len, config.user.username_max_len, config.user.username_pattern)
	app.validators.nickname = StringValidator.new(config.user.nickname_min_len, config.user.nickname_max_len, config.user.nickname_pattern)
	app.validators.user_bio = StringValidator.new(config.user.bio_min_len, config.user.bio_max_len, config.user.bio_pattern)
	app.validators.pronouns = StringValidator.new(config.user.pronouns_min_len, config.user.pronouns_max_len, config.user.pronouns_pattern)
	app.validators.post_title = StringValidator.new(config.post.title_min_len, config.post.title_max_len, config.post.title_pattern)
	app.validators.post_body = StringValidator.new(config.post.body_min_len, config.post.body_max_len, config.post.body_pattern)
	// vfmt on

	app.mount_static_folder_at(app.config.static_path, '/static')!

	println('-> initializing database...')
	init_db(db)!
	println('<- done')

	// make the website config, if it does not exist
	app.get_or_create_site_config()

	if config.dev_mode {
		println('\033[1;31mNOTE: YOU ARE IN DEV MODE\033[0m')
	}

	veb.run[App, Context](mut app, app.config.http.port)
}
