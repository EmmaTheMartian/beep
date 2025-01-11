module entity

// SavedPost represents a saved post for a given user
pub struct SavedPost {
pub mut:
	id      int @[primary; sql: serial]
	post_id int
	user_id int
	saved   bool
	later   bool
}

// can_remove returns true if the SavedPost is neither saved or saved for later.
pub fn (post &SavedPost) can_remove() bool {
	return !post.saved && !post.later
}
