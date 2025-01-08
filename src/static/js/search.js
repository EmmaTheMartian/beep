const search = async (query, limit, offset) => {
	const data = await fetch(`/api/search?query=${query}&limit=${limit}&offset=${offset}`, {
		method: 'GET'
	})
	console.log(data)
	const json = await data.json()
	console.log(json)
	return json
}
