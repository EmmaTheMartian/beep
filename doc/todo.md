# todo

> i use `:` to denote categories

## in-progress

- [x] post:search for posts
	- [ ] filters:
		```
		created-at:<date>
		created-after:<date>
		created-before:<date>
		is:pinned
		has-tag:<tag>
		posted-by:<user>
		!excluded-query
		```
- [x] user:search for users
	- [ ] filters:
		```
		created-at:<date>
		created-after:<date>
		created-before:<date>
		is:admin
		```
- [ ] misc:replace `SEARCH *` with `SEARCH <column>`

## planing

> p.s. when initially writing "planing," i made a typo. it should be "planning."
> however, i will not be fixing it, because it is funny.

- [ ] post:add more embedded link handling! (discord, github, gitlab, codeberg, etc)
- [ ] user:follow other users (send notifications on new posts)
- [ ] site:webhooks
	- could be used so that a github webhook can send a message when a new commit is pushed to beep!
- [ ] site:log new accounts, account deletions, etc etc in an admin-accessible site log
	- this should be set up to only log things when an admin enables it in the site config, so as to only log when necessary

## ideas

- [ ] user:per-user post pins
	- could be used as an alternative for a bio to include more information perhaps
- [ ] site:rss feed?

## done

- [x] user:nicknames
- [x] user:bio/about me
- [x] user:listed pronouns
- [x] user:notifications
- [x] user:deletion
- [x] user:change password
- [x] user:change username
- [x] post:likes/dislikes
- [x] post:mentioning ('tagging') other users in posts
	- [x] post:mentioning:who mentioned you (send notifications when a user mentions you)
- [x] post:editing
- [x] post:replies
- [x] post:tags ('hashtags')
- [x] post:embedded links (links added to a post will be embedded into the post
as images, music links, etc)
	- should have special handling for spotify, apple music, youtube,
	discord, and other common links. we want those ones to look fancy!
- [x] post:saving (add the post to a list of saved posts that a user can view later)
- [x] site:message of the day (admins can add a welcome message displayed on index.html)

## graveyard

- [ ] ~~post:images (should have a config.maple toggle to enable/disable)~~
	- replaced with post:embedded links
- [ ] ~~site:stylesheet (and a toggle for html-only mode)~~
	- replaced with per-user optional stylesheets
