const get_apple_music_iframe = src =>
	`<iframe
		class="post-iframe iframe-music iframe-music-apple"
		style="border-radius:12px"
		width="100%"
		height="152"
		frameBorder="0"
		allowfullscreen=""
		allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture"
		loading="lazy"
		src="${src}"
	></iframe>`

const get_spotify_iframe = src =>
	`<iframe
		class="post-iframe iframe-music iframe-music-spotify"
		allow="autoplay *; encrypted-media *; fullscreen *; clipboard-write"
		frameborder="0"
		height="175"
		style="width:100%;overflow:hidden;border-radius:10px;"
		sandbox="allow-forms allow-popups allow-same-origin allow-scripts allow-storage-access-by-user-activation allow-top-navigation-by-user-activation"
		loading="lazy"
		src="${src}"
	></iframe>`

const get_youtube_frame = src =>
	`<iframe
		width="560"
		height="315"
		src="${src}"
		title="YouTube video player"
		frameborder="0"
		allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
		referrerpolicy="strict-origin-when-cross-origin"
		allowfullscreen
	></iframe>`

const link_handlers = {
	'https://music.apple.com/': link => {
		const embed_url = `https://embed.${link.substring(8)}`
		return get_apple_music_iframe(embed_url)
	},
	'https://open.spotify.com/': link => {
		const type = link.substring(link.indexOf('/', 8) + 1, link.indexOf('/', link.indexOf('/', 8) + 1))
		const id = link.substring(link.lastIndexOf('/') + 1, link.indexOf('?'))
		const embed_url = `https://open.spotify.com/embed/${type}/${id}?utm_source=generator&theme=0`
		return get_spotify_iframe(embed_url)
	},
	'https://youtu.be/': link => {
		const id = link.substring(link.lastIndexOf('/') + 1, link.indexOf('?'))
		const embed_url = `https://www.youtube.com/embed/${id}`
		return get_youtube_frame(embed_url)
	},
}

const render_body = async id => {
	const element = document.getElementById(id)
	var body = element.innerText
	var html = element.innerHTML

	// give the body a loading """animation""" while we let the fetches cook
	element.innerText = 'loading...'

	const matches = body.matchAll(/[@#*]\([a-zA-Z0-9_.-]*\)/g)
	const cache = {}
	for (const match of matches) {
		// mention
		if (match[0][0] == '@') {
			if (cache.hasOwnProperty(match[0])) {
				html = html.replace(match[0], cache[match[0]])
				continue
			}
			const s = await (await fetch('/api/user/get_name?username=' + match[0].substring(2, match[0].length - 1))).text()
			const link = document.createElement('a')
			link.href = `/user/${match[0].substring(2, match[0].length - 1)}`
			link.innerText = '@' + s
			cache[match[0]] = link.outerHTML
			html = html.replace(match[0], link.outerHTML)
		}
		// tags
		else if (match[0][0] == '#') {
			// we do not cache tags because they do not need to do
			// any http queries, and most people will not use the
			// same tag multiple times in a single post.
			const link = document.createElement('a')
			const tag = match[0].substring(2, match[0].length - 1)
			link.href = `/tag/${tag}`
			link.innerText = '#' + tag
			cache[match[0]] = link.outerHTML
			html = html.replace(match[0], link.outerHTML)
		}
		// post reference
		else if (match[0][0] == '*') {
			if (cache.hasOwnProperty(match[0])) {
				html = html.replace(match[0], cache[match[0]])
				continue
			}
			const s = await (await fetch('/api/post/get_title?id=' + match[0].substring(2, match[0].length - 1))).text()
			const link = document.createElement('a')
			link.href = `/post/${match[0].substring(2, match[0].length - 1)}`
			link.innerText = '*' + s
			cache[match[0]] = link.outerHTML
			html = html.replace(match[0], link.outerHTML)
		}
	}

	var handled_links = []
	// i am not willing to write a url regex myself, so here is where i got
	// this: https://stackoverflow.com/a/3809435
	const links = html.matchAll(/https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)/g)
	for (const match of links) {
		const link = match[0]
		for (const entry of Object.entries(link_handlers)) {
			if (link.startsWith(entry[0])) {
				handled_links.push(entry[1](link))
				break
			}
		}
		// sanatize the link before rendering it directly.  no link
		// should ever have these three characters in them anyway.
		const sanatized = link
			.replace('<', '&gt;')
			.replace('>', '&lt;')
			.replace('"', '&quot;')
		html = html.replace(link, `<a href="${sanatized}">${sanatized}</a>`)
	}

	// append handled links
	if (handled_links.length > 0) {
		// element.innerHTML += '\n\nlinks:\n'
		for (const handled of handled_links) {
			html += `\n\n${handled}`
		}
	}

	element.innerHTML = html
}
