module util

import time

@[noinit]
pub struct Stopwatch {
pub:
	start time.Time = time.now()
pub mut:
	stop time.Time
	took ?time.Duration
}

@[inline]
pub fn Stopwatch.new() Stopwatch {
	return Stopwatch{}
}

@[inline]
pub fn (mut stopwatch Stopwatch) stop() time.Duration {
	stopwatch.stop = time.now()
	duration := stopwatch.stop - stopwatch.start
	stopwatch.took = duration
	return duration
}

@[params]
pub struct TimeItParams {
pub:
	it   fn () @[required]
	name string
	log  bool
}

@[inline]
pub fn time_it(params TimeItParams) Stopwatch {
	mut stopwatch := Stopwatch.new()
	params.it()
	took := stopwatch.stop()
	if params.log {
		println('-> (time_it) ${params.name} took ${took}')
	}
	return stopwatch
}
