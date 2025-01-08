const search = async (query, limit, offset) => {
	const data = await fetch(`/api/search?query=${query}&limit=${limit}&offset=${offset}`, {
		method: 'GET'
	})
	const json = await data.json()
	return json
}
