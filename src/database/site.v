module database

import entity { Site }

pub fn (app &DatabaseAccess) get_or_create_site_config() Site {
	mut configs := sql app.db {
		select from Site
	} or { [] }
	if configs.len == 0 {
		// make the site config
		site_config := Site{}
		sql app.db {
			insert site_config into Site
		} or { panic('failed to create site config (${err})') }
		configs = sql app.db {
			select from Site
		} or { [] }
	} else if configs.len > 1 {
		// this should never happen
		panic('there are multiple site configs')
	}
	return configs[0]
}

// set_motd sets the site's current message of the day, returns true if this
// succeeds and false otherwise.
pub fn (app &DatabaseAccess) set_motd(motd string) bool {
	sql app.db {
		update Site set motd = motd where id == 1
	} or {
		return false
	}
	return true
}
