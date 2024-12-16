module entity

import time

@[json: 'post']
pub struct Post {
pub mut:
	id        int @[primary; sql: serial]
	author_id int

	title  string
	body   string

	posted_at time.Time = time.now()
}
