# database spec

i have a mental map of the databases in use for beep, but that does not mean
others also do. along with that, having a visual representation is probably
going to be pretty useful. so with that said, i present to you, the database
spec for beep:

## `User`

> represents a registered user

| name | type | desc |
|------|------|------|
| `id` | int | identifier this user on the backend |
| `username` | string | identifier this user on the frontend |
| `nickname` | ?string | optional nickname for this user on the frontend |
| `password` | string | hashed and salted password for this user |
| `password_salt` | string | salt for this user's password |
| `muted` | bool | controls whether or not this user can make posts |
| `admin` | bool | controls whether or not this user is an admin |
| `created_at` | time.Time | a timestamp of when this user was made |

## `Post`

> represents a public post

| name | type | desc |
|------|------|------|
| `id` | int | identifier for this post |
| `author_id` | int | id of the user that authored this post |
| `title` | string | the title of this post |
| `body` | string | the body of this post |
| `posted_at` | time.Time | a timestamp of when this post was made |

## `Like`

> represents all likes and dislikes on posts for this beep instance

| name | type | desc |
|------|------|------|
| `id` | int | identifier for this (dis)like |
| `user_id` | int | the user that sent this (dis)like |
| `post_id` | int | the post this (dis)like is for |
<!-- | `liked` | bool | `true` if this is a like, `false` if a dislike | -->

## `TotalLike`

> stores total likes and dislikes for a post

> a post with no likes nor dislikes will not be in this table

> the data in this table is cleared and recalculated every
> `config:post:likes_refresh_minutes` minutes

| name | type | desc |
|------|------|------|
| `id` | int | identifier for this entry |
| `post_id` | int | the post this entry is for |
| `likes` | int | how many likes the post has |
<!-- | `dislikes` | int | how many dislikes the post has | -->
