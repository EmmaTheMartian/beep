module entity

// stores like information for posts
pub struct Like {
pub mut:
	id      int @[primary; sql: serial]
	user_id int
	post_id int
	is_like bool
}

// Stores total likes per post
pub struct LikeCache {
pub mut:
	id      int @[primary; sql: serial]
	post_id int
	likes   int
}
