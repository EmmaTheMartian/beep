# beep

> *a legendary land of lowercase lovers.*

a self-hosted mini-blogger.

technically made because i wanted to mess around with rss, but i also wanted a
teensy little blog/slow-paced-chat-app for myself and my friends.

## hosting

you will need a postgresql database somewhere, along with v to compile beep:

edit `config.maple` to set the url, port, username, password, and database name.

> `config.maple` also has settings to configure the feel of your beep instance,
> including toggling images, post length, username length, etc etc.

> **do not** push your `config.maple`'s secrets to git!
> instead, use `config.real.maple` if you plan to push anywhere.
> it will be gitignored to keep your secrets a secret.

```sh
git clone https://github.com/emmathemartian/beep
cd beep
v -prod .
./beep config.maple
```

then go to the configured url to view (default is `http://localhost:8008`).

if you do not have a database, you can either self-host a postgresql database on
your machine, or you can find a free one online. i use and like
[neon.tech](https://neon.tech), their free plan is pretty comfortable for a
small beep instance!
