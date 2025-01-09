module entity

import db.pg
import time
import util

pub struct Post {
pub mut:
	id          int @[primary; sql: serial]
	author_id   int
	replying_to ?int

	title string
	body  string

	pinned bool

	posted_at time.Time = time.now()
}

// Post.from_row creates a post from the given database row.
// see src/database/post.v#search_for_posts for usage.
@[inline]
pub fn Post.from_row(row pg.Row) Post {
	// this throws a cgen error when put in Post{}
	//todo: report this
	posted_at := time.parse(util.or_throw[string](row.vals[6])) or { panic(err) }

	return Post{
		id: util.or_throw[string](row.vals[0]).int()
		author_id: util.or_throw[string](row.vals[1]).int()
		replying_to: if row.vals[2] == none { ?int(none) } else {
			util.map_or_throw[string, int](row.vals[2], |it| it.int())
		}
		title: util.or_throw[string](row.vals[3])
		body: util.or_throw[string](row.vals[4])
		pinned: util.map_or_throw[string, bool](row.vals[5], |it| it.bool())
		posted_at: posted_at
	}
}
