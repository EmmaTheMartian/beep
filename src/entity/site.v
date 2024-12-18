module entity

pub struct Site {
pub mut:
	id   int    @[primary; sql: serial]
	motd string
}
