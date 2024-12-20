module database

import entity { Site }

pub fn (app &DatabaseAccess) get_or_create_site_config() Site {
	configs := sql app.db {
		select from Site
	} or { [] }
	if configs.len == 0 {
		// make the site config
		site_config := Site{}
		sql app.db {
			insert site_config into Site
		} or { panic('failed to create site config (${err})') }
	} else if configs.len > 1 {
		// this should never happen
		panic('there are multiple site configs')
	}
	return configs[0]
}
