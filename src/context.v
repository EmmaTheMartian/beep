module main

import veb

pub struct Context {
	veb.Context
pub mut:
	title string
}

pub fn (ctx &Context) is_logged_in() bool {
	return ctx.get_cookie('token') or { '' } != ''
}

pub fn (mut ctx Context) unauthorized(msg string) veb.Result {
	ctx.res.set_status(.unauthorized)
	return ctx.send_response_to_client('text/plain', msg)
}
