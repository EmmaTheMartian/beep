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

const save = async id => {
	await fetch('/api/post/save?id=' + id, {
		method: 'GET'
	})
	window.location.reload()
}

const save_for_later = async id => {
	await fetch('/api/post/save_for_later?id=' + id, {
		method: 'GET'
	})
	window.location.reload()
}
