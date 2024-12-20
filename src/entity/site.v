module entity

// Site stores mutable site-wide config and data.
pub struct Site {
pub mut:
	id   int @[primary; sql: serial]
	motd string
}
