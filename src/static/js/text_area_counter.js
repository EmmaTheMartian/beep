// this script is used to provide character counters to textareas

const add_character_counter = (textarea_id, p_id, max_len) => {
	const textarea = document.getElementById(textarea_id)
	const p = document.getElementById(p_id)
	textarea.addEventListener('input', () => {
		p.innerText = textarea.value.length + '/' + max_len
	})
	p.innerText = textarea.value.length + '/' + max_len
}
