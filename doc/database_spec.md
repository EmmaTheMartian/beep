# database spec

i have a mental map of the databases in use for beep, but that does not mean
others also do. along with that, having a visual representation is probably
going to be pretty useful. so with that said, i present to you, the database
spec for beep:

## `User`

> represents a registered user

| name            | type      | desc                                             |
|-----------------|-----------|--------------------------------------------------|
| `id`            | int       | identifier this user on the backend              |
| `username`      | string    | identifier this user on the frontend             |
| `nickname`      | ?string   | optional nickname for this user on the frontend  |
| `password`      | string    | hashed and salted password for this user         |
| `password_salt` | string    | salt for this user's password                    |
| `muted`         | bool      | controls whether or not this user can make posts |
| `admin`         | bool      | controls whether or not this user is an admin    |
| `automated`     | bool      | controls whether or not this user is automated   |
| `theme`         | ?string   | controls per-user css themes                     |
| `bio`           | string    | bio for this user                                |
| `pronouns`      | string    | pronouns for this user                           |
| `created_at`    | time.Time | a timestamp of when this user was made           |

## `Post`

> represents a public post

| name          | type      | desc                                         |
|---------------|-----------|----------------------------------------------|
| `id`          | int       | identifier for this post                     |
| `author_id`   | int       | id of the user that authored this post       |
| `replying_to` | ?int      | id of the post that this post is replying to |
| `title`       | string    | the title of this post                       |
| `body`        | string    | the body of this post                        |
| `posted_at`   | time.Time | a timestamp of when this post was made       |

## `Like`

> represents all likes and dislikes on posts for this beep instance

| name      | type | desc                                           |
|-----------|------|------------------------------------------------|
| `id`      | int  | identifier for this (dis)like                  |
| `user_id` | int  | the user that sent this (dis)like              |
| `post_id` | int  | the post this (dis)like is for                 |
| `is_like` | bool | `true` if this is a like, `false` if a dislike |

## `LikeCache`

> stores total likes for a post

<!-- todo: implement this -->
<!-- > a post with no likes nor dislikes will not be in this table -->
<!-- > the data in this table is cleared and recalculated every
> `config:post:likes_refresh_minutes` minutes -->

| name      | type | desc                                  |
|-----------|------|---------------------------------------|
| `id`      | int  | identifier for this entry             |
| `post_id` | int  | the post this entry is for            |
| `likes`   | int  | the net amount of likes this post has |

## `Site`

> stores mutable, site-wide data. there should only ever be one entry here

| name   | type   | desc                                         |
|--------|--------|----------------------------------------------|
| `id`   | int    | identifier for this (should always be 0)     |
| `motd` | string | the message of the day displayed on `/index` |

## `Notification`

> represents a notification sent to a user

| name      | type   | desc                                     |
|-----------|--------|------------------------------------------|
| `id`      | int    | identifier for this notification         |
| `user_id` | int    | the user that receives this notification |
| `summary` | string | the summary for this notification        |
| `body`    | string | the full text for this notification      |

## `SavedPost`

> a list of saved posts for a user

| name      | type | desc                                             |
|-----------|------|--------------------------------------------------|
| `id`      | int  | identifier for this entry, this is mostly unused |
| `post_id` | int  | the id of the post this entry relates to         |
| `user_id` | int  | the id of the user that saved this post          |
| `saved`   | bool | if this post is saved                            |
| `later`   | bool | if this post is saved in "read later"            |
