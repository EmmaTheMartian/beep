# resources

making beep has taught me a lot related to backend web development, database
design, and performance considerations for those. not to mention security!

to help others that want to learn these skills too, here are the resources that
helped me design beep!

## database design

- https://stackoverflow.com/questions/59505855/liked-posts-design-specifics
	- my programmer brain automatically assumed "oh i can just store a list
	in the user table!" turns out, that is a bad implementation.
	- i do have scalability concerns with the current implementation, but i
	can address those in the near future.

## sql

postgresql documentation: https://www.postgresql.org/docs/

- https://stackoverflow.com/questions/11144394/order-sql-by-strongest-like
	- helped me develop the initial search system, which is subject to be
	overhauled, but for now, this helped a lot.

## sql security

![xkcd comic #327](https://imgs.xkcd.com/comics/exploits_of_a_mom.png)

source: xkcd, <https://xkcd.com/327/>

- sql injections
	- https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html#other-examples-of-safe-prepared-statements
	- https://cheatsheetseries.owasp.org/cheatsheets/Query_Parameterization_Cheat_Sheet.html#using-net-built-in-feature
	- https://www.slideshare.net/slideshow/sql-injection-myths-and-fallacies/3729931#3

## misc

- https://stackoverflow.blog/2021/12/28/what-i-wish-i-had-known-about-single-page-applications/
	- i thought about turning beep into a single page application (spa),
	then done a bit of research. this blog post pointed out a variety of
	problems that the author had with their spa, and many of those problems
	would be problems for beep too.
	- tl;dr: this blog post gave me the warnings about an spa before i
	wasted my time implementing it on beep.
