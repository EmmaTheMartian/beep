module main

import db.pg
import veb
import auth
import entity
import os
import webapp { App, Context, StringValidator }
import beep_sql
import util

pub const version = '25.01.0'

@[inline]
fn connect(mut app App) {
	println('-> connecting to database...')
	app.db = pg.connect(pg.Config{
		host:     app.config.postgres.host
		dbname:   app.config.postgres.db
		user:     app.config.postgres.user
		password: app.config.postgres.password
		port:     app.config.postgres.port
	}) or {
		panic('failed to connect to database: ${err}')
	}
}

@[inline]
fn init_db(mut app App) {
	println('-> initializing database')
	sql app.db {
		create table entity.Site
		create table entity.User
		create table entity.Post
		create table entity.Like
		create table entity.LikeCache
		create table entity.Notification
		create table entity.SavedPost
	} or {
		panic('failed to initialize database: ${err}')
	}
}

@[inline]
fn load_validators(mut app App) {
	// vfmt off
	user := app.config.user
	app.validators.username   = StringValidator.new(user.username_min_len, user.username_max_len, user.username_pattern)
	app.validators.password   = StringValidator.new(user.password_min_len, user.password_max_len, user.password_pattern)
	app.validators.nickname   = StringValidator.new(user.nickname_min_len, user.nickname_max_len, user.nickname_pattern)
	app.validators.user_bio   = StringValidator.new(user.bio_min_len,      user.bio_max_len,      user.bio_pattern)
	app.validators.pronouns   = StringValidator.new(user.pronouns_min_len, user.pronouns_max_len, user.pronouns_pattern)
	post := app.config.post
	app.validators.post_title = StringValidator.new(post.title_min_len,    post.title_max_len,    post.title_pattern)
	app.validators.post_body  = StringValidator.new(post.body_min_len,     post.body_max_len,     post.body_pattern)
	// vfmt on
}

fn main() {
	mut stopwatch := util.Stopwatch.new()

	config := webapp.load_config_from(os.args[1])
	mut app := &App{ config: config }

	// connect to database
	util.time_it(
		it: fn [mut app] () {
			connect(mut app)
		}
		name: 'connect to db'
		log: true
	)

	defer { app.db.close() }

	// add authenticator
	app.auth = auth.new(app.db)

	// load sql files kept in beep_sql/
	util.time_it(
		it: fn [mut app] () {
			beep_sql.load(mut app.db)
		}
		name: 'load beep_sql'
		log: true
	)

	// load validators
	load_validators(mut app)

	// mount static things
	app.mount_static_folder_at(app.config.static_path, '/static')!

	// initialize database
	util.time_it(it: fn [mut app] () {
		init_db(mut app)
	}, name: 'init db', log: true)

	// make the website config, if it does not exist
	app.get_or_create_site_config()

	if config.dev_mode {
		println('\033[1;31mNOTE: YOU ARE IN DEV MODE\033[0m')
	}

	stop := stopwatch.stop()
	println('-> took ${stop} to start app')

	veb.run[App, Context](mut app, app.config.http.port)
}
