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
