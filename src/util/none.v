module util

@[inline]
pub fn map_or[T, R](val ?T, mapper fn (T) R, or_else R) R {
	return if val == none { or_else } else { mapper(val) }
}

@[inline]
pub fn map_or_throw[T, R](val ?T, mapper fn (T) R) R {
	return if val == none { panic('value was none: ${val}') } else { mapper(val) }
}

@[inline]
pub fn map_or_opt[T, R](val ?T, mapper fn (T) ?R, or_else ?R) ?R {
	return if val == none { or_else } else { mapper(val) }
}

@[inline]
pub fn or_throw[T](val ?T) T {
	return if val == none { panic('value was none: ${val}') } else { val }
}
