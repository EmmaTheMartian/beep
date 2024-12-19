module entity

import time

pub struct Post {
pub mut:
	id        int @[primary; sql: serial]
	author_id int

	title string
	body  string

	pinned bool

	posted_at time.Time = time.now()
}
