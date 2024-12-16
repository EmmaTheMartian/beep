module main

import emmathemartian.maple

pub struct Config {
pub mut:
	dev_mode bool
	http struct {
	pub mut:
		port int
	}
	postgres struct {
	pub mut:
		host string
		port int
		user string
		password string
		db string
	}
	oauth struct {
	pub mut:
		github struct {
		pub mut:
			enabled bool
			id string
			secret string
		}
	}
	post struct {
	pub mut:
		title_max_len int
		body_max_len int
	}
	user struct {
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
	}
}

pub fn load_config_from(file_path string) Config {
	loaded := maple.load_file(file_path) or { panic(err) }
	mut config := Config{}

	config.dev_mode = loaded.get('dev_mode').to_bool()

	loaded_http := loaded.get('http')
	config.http.port = loaded_http.get('port').to_int()

	loaded_postgres := loaded.get('postgres')
	config.postgres.host = loaded_postgres.get('host').to_str()
	config.postgres.port = loaded_postgres.get('port').to_int()
	config.postgres.user = loaded_postgres.get('user').to_str()
	config.postgres.password = loaded_postgres.get('password').to_str()
	config.postgres.db = loaded_postgres.get('db').to_str()

	loaded_oauth := loaded.get('oauth')
	loaded_oauth_github := loaded_oauth.get('github')
	config.oauth.github.enabled = loaded_oauth_github.get('enabled').to_bool()
	config.oauth.github.id = loaded_oauth_github.get('id').to_str()
	config.oauth.github.secret = loaded_oauth_github.get('secret').to_str()

	loaded_post := loaded.get('post')
	config.post.title_max_len = loaded_post.get('title_max_len').to_int()
	config.post.body_max_len = loaded_post.get('body_max_len').to_int()

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

	return config
}