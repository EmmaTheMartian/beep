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
		console.log('found match: ' + match)
		const username = match[0].substring(1)
		element.innerHTML = element.innerHTML.replaceAll(username, '<a href="/user/' + username + '">' + username + '</a>')
	}
}
