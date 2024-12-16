// From: https://github.com/vlang/v/blob/1fae506900c79e3aafc00e08e1f861fc7cbf8012/vlib/veb/auth/auth.v
// The original file's source is licensed under MIT.

// This "fork" re-introduces the `ip` field of each token for additional security.

module auth

import rand
import crypto.rand as crypto_rand
import crypto.hmac
import crypto.sha256

const max_safe_unsigned_integer = u32(4_294_967_295)

pub struct Auth[T] {
	db T
}

pub struct Token {
pub:
	id      int @[primary; sql: serial]
	user_id int
	value   string
	ip      string
}

pub fn new[T](db T) Auth[T] {
	set_rand_crypto_safe_seed()
	sql db {
		create table Token
	} or { eprintln('veb.auth: failed to create table Token') }
	return Auth[T]{
		db: db
	}
}

pub fn (mut app Auth[T]) add_token(user_id int, ip string) !string {
	mut uuid := rand.uuid_v4()
	token := Token{
		user_id: user_id
		value:   uuid
		ip:      ip
	}
	sql app.db {
		insert token into Token
	}!
	return uuid
}

pub fn (app &Auth[T]) find_token(value string, ip string) ?Token {
	tokens := sql app.db {
		select from Token where value == value && ip == ip limit 1
	} or { []Token{} }
	if tokens.len == 0 {
		return none
	}
	return tokens.first()
}

pub fn (mut app Auth[T]) delete_tokens_for_user(user_id int) ! {
	sql app.db {
		delete from Token where user_id == user_id
	}!
}

pub fn (mut app Auth[T]) delete_tokens_for_ip(ip string) ! {
	sql app.db {
		delete from Token where ip == ip
	}!
}

pub fn set_rand_crypto_safe_seed() {
	first_seed := generate_crypto_safe_int_u32()
	second_seed := generate_crypto_safe_int_u32()
	rand.seed([first_seed, second_seed])
}

fn generate_crypto_safe_int_u32() u32 {
	return u32(crypto_rand.int_u64(max_safe_unsigned_integer) or { 0 })
}

pub fn generate_salt() string {
	return rand.i64().str()
}

pub fn hash_password_with_salt(plain_text_password string, salt string) string {
	salted_password := '${plain_text_password}${salt}'
	return sha256.sum(salted_password.bytes()).hex().str()
}

pub fn compare_password_with_hash(plain_text_password string, salt string, hashed string) bool {
	digest := hash_password_with_salt(plain_text_password, salt)
	// constant time comparison
	// I know this is operating on the hex-encoded strings, but it's still constant time
	// and better than not doing it at all
	return hmac.equal(digest.bytes(), hashed.bytes())
}
