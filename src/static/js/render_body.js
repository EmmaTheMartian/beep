// TODO: move this to the backend?
const render_body = async id => {
	const element = document.getElementById(id)
	var body = element.innerText

	const matches = body.matchAll(/[@#*]\([a-zA-Z0-9_.-]*\)/g)
	const cache = {}
	for (const match of matches) {
		// mention
		if (match[0][0] == '@') {
			if (cache.hasOwnProperty(match[0])) {
				element.innerHTML = element.innerHTML.replace(match[0], cache[match[0]])
				continue
			}
			(await fetch('/api/user/get_name?username=' + match[0].substring(2, match[0].length - 1))).text().then(s => {
				if (s == 'no such user') {
					return
				}
				const link = document.createElement('a')
				link.href = `/user/${match[0].substring(2, match[0].length - 1)}`
				link.innerText = s
				cache[match[0]] = link.outerHTML
				element.innerHTML = element.innerHTML.replace(match[0], link.outerHTML)
			})
		}
		// hashtag
		else if (match[0][0] == '#') {
		}
		// post reference
		else if (match[0][0] == '*') {
			if (cache.hasOwnProperty(match[0])) {
				element.innerHTML = element.innerHTML.replace(match[0], cache[match[0]])
				continue
			}
			(await fetch('/api/post/get_title?id=' + match[0].substring(2, match[0].length - 1))).text().then(s => {
				if (s == 'no such post') {
					return
				}
				const link = document.createElement('a')
				link.href = `/post/${match[0].substring(2, match[0].length - 1)}`
				link.innerText = s
				cache[match[0]] = link.outerHTML
				element.innerHTML = element.innerHTML.replace(match[0], link.outerHTML)
			})
		}
	}
}
