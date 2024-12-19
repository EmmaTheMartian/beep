const like = async id => {
	await fetch('/api/post/like?id=' + id, {
		method: 'GET'
	})
	window.location.reload()
}

const dislike = async id => {
	await fetch('/api/post/dislike?id=' + id, {
		method: 'GET'
	})
	window.location.reload()
}

const render_post_body = async (id, mention_pattern) => {
	const element = document.getElementById(`post-${id}`)
	var body = element.innerText
	const matches = body.matchAll(new RegExp(mention_pattern, 'g'))
	for (const match of matches) {
		(await fetch('/api/user/get_name?username=' + match[0].substring(2, match[0].length - 1))).text().then(s => {
			element.innerHTML = element.innerHTML.replace(match[0], '<a href="/user/' + match[0].substring(2, match[0].length - 1) + '">' + s + '</a>')
		})
	}
}
