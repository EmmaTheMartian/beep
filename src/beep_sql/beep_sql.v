module beep_sql

import os
import db.pg

fn load_procedures(mut db pg.DB) {
	os.walk('src/beep_sql/procedures/', fn [mut db] (it string) {
		println('-> loading procedure: ${it}')
		db.exec(os.read_file(it) or { panic(err) }) or { panic(err) }
	})
}

pub fn load(mut db pg.DB) {
	println('-> loading sql code')
	load_procedures(mut db)
	println('<- done')
}
