module entity

// Like stores like information for a post.
pub struct Like {
pub mut:
	id      int @[primary; sql: serial]
	user_id int
	post_id int
	is_like bool
}

// LikeCache stores the total likes for a post.
pub struct LikeCache {
pub mut:
	id      int @[primary; sql: serial]
	post_id int @[unique]
	likes   int
}
