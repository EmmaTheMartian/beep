module main

import emmathemartian.maple

pub struct Config {
pub mut:
	dev_mode    bool
	static_path string
	instance    struct {
	pub mut:
		name                 string
		welcome              string
		default_theme        string
		allow_changing_theme bool
	}
	http        struct {
	pub mut:
		port int
	}
	postgres    struct {
	pub mut:
		host     string
		port     int
		user     string
		password string
		db       string
	}
	post        struct {
	pub mut:
		title_min_len int
		title_max_len int
		title_pattern string
		body_min_len  int
		body_max_len  int
		body_pattern  string
	}
	user        struct {
	pub mut:
		username_min_len int
		username_max_len int
		username_pattern string
		nickname_min_len int
		nickname_max_len int
		nickname_pattern string
		password_min_len int
		password_max_len int
		password_pattern string
		pronouns_min_len int
		pronouns_max_len int
		pronouns_pattern string
		bio_min_len      int
		bio_max_len      int
		bio_pattern      string
	}
}

pub fn load_config_from(file_path string) Config {
	loaded := maple.load_file(file_path) or { panic(err) }
	mut config := Config{}

	config.dev_mode = loaded.get('dev_mode').to_bool()
	config.static_path = loaded.get('static_path').to_str()

	loaded_instance := loaded.get('instance')
	config.instance.name = loaded_instance.get('name').to_str()
	config.instance.welcome = loaded_instance.get('welcome').to_str()
	config.instance.default_theme = loaded_instance.get('default_theme').to_str()
	config.instance.allow_changing_theme = loaded_instance.get('allow_changing_theme').to_bool()

	loaded_http := loaded.get('http')
	config.http.port = loaded_http.get('port').to_int()

	loaded_postgres := loaded.get('postgres')
	config.postgres.host = loaded_postgres.get('host').to_str()
	config.postgres.port = loaded_postgres.get('port').to_int()
	config.postgres.user = loaded_postgres.get('user').to_str()
	config.postgres.password = loaded_postgres.get('password').to_str()
	config.postgres.db = loaded_postgres.get('db').to_str()

	loaded_post := loaded.get('post')
	config.post.title_min_len = loaded_post.get('title_min_len').to_int()
	config.post.title_max_len = loaded_post.get('title_max_len').to_int()
	config.post.title_pattern = loaded_post.get('title_pattern').to_str()
	config.post.body_min_len = loaded_post.get('body_min_len').to_int()
	config.post.body_max_len = loaded_post.get('body_max_len').to_int()
	config.post.body_pattern = loaded_post.get('body_pattern').to_str()

	loaded_user := loaded.get('user')
	config.user.username_min_len = loaded_user.get('username_min_len').to_int()
	config.user.username_max_len = loaded_user.get('username_max_len').to_int()
	config.user.username_pattern = loaded_user.get('username_pattern').to_str()
	config.user.nickname_min_len = loaded_user.get('nickname_min_len').to_int()
	config.user.nickname_max_len = loaded_user.get('nickname_max_len').to_int()
	config.user.nickname_pattern = loaded_user.get('nickname_pattern').to_str()
	config.user.password_min_len = loaded_user.get('password_min_len').to_int()
	config.user.password_max_len = loaded_user.get('password_max_len').to_int()
	config.user.password_pattern = loaded_user.get('password_pattern').to_str()
	config.user.pronouns_min_len = loaded_user.get('pronouns_min_len').to_int()
	config.user.pronouns_max_len = loaded_user.get('pronouns_max_len').to_int()
	config.user.pronouns_pattern = loaded_user.get('pronouns_pattern').to_str()
	config.user.bio_min_len = loaded_user.get('bio_min_len').to_int()
	config.user.bio_max_len = loaded_user.get('bio_max_len').to_int()
	config.user.bio_pattern = loaded_user.get('bio_pattern').to_str()

	return config
}
