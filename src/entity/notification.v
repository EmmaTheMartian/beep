module entity

pub struct Notification {
pub mut:
	id      int @[primary; sql: serial]
	user_id int
	summary string
	body    string
}
