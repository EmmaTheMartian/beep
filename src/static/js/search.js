const search_posts = async (query, limit, offset) => {
	const data = await fetch(`/api/post/search?query=${query}&limit=${limit}&offset=${offset}`, {
		method: 'GET'
	})
	const json = await data.json()
	return json
}

const search_users = async (query, limit, offset) => {
	const data = await fetch(`/api/user/search?query=${query}&limit=${limit}&offset=${offset}`, {
		method: 'GET'
	})
	const json = await data.json()
	return json
}
