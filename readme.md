# beep

> *a legendary land of lowercase lovers.*

a self-hosted "social-media-oriented" mini-blogger.

technically made because i wanted to mess around with rss, but i also wanted a
teensy little blog/slow-paced-chat-app for myself and my friends.

## hosting

you will need a postgresql database somewhere, along with v to compile beep:

copy the `config.maple` as `config.real.maple`

edit `config.real.maple` to set the url, port, username, password, and database
name.

> `config.real.maple` also has settings to configure the feel of your beep
> instance, post length, username length, welcome messages, etc etc.

> **do not put your secrets in `config.maple`**. it is intended to be pushed to
> git as a "template config." instead, use `config.real.maple` if you plan to
> push anywhere. it is gitignored already, meaning you do not have to fear about
> your secrets not being kept a secret.

```sh
git clone https://github.com/emmathemartian/beep
cd beep
v -prod .
./beep config.real.maple
```

then go to the configured url to view (default is `http://localhost:8008`).

if you do not have a database, you can either self-host a postgresql database on
your machine, or you can find a free one online. i use and like
[neon.tech](https://neon.tech), their free plan is pretty comfortable for a
small beep instance!
