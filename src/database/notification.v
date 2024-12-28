module database

import entity { Notification }

// get_notification_by_id gets a notification by its given id, returns none if
// the notification does not exist.
pub fn (app &DatabaseAccess) get_notification_by_id(id int) ?Notification {
	notifications := sql app.db {
		select from Notification where id == id
	} or { [] }
	if notifications.len != 1 {
		return none
	}
	return notifications[0]
}

// delete_notification deletes the given notification, returns true if this
// succeeded and false otherwise.
pub fn (app &DatabaseAccess) delete_notification(id int) bool {
	sql app.db {
		delete from Notification where id == id
	} or {
		return false
	}
	return true
}

// delete_notifications_for_user deletes all notifications for the given user,
// returns true if this succeeded and false otherwise.
pub fn (app &DatabaseAccess) delete_notifications_for_user(user_id int) bool {
	sql app.db {
		delete from Notification where user_id == user_id
	} or {
		return false
	}
	return true
}

// get_notifications_for gets a list of notifications for the given user.
pub fn (app &DatabaseAccess) get_notifications_for(user_id int) []Notification {
	notifications := sql app.db {
		select from Notification where user_id == user_id
	} or { [] }
	return notifications
}

// get_notification_count gets the amount of notifications a user has, with a
// given limit.
pub fn (app &DatabaseAccess) get_notification_count(user_id int, limit int) int {
	notifications := sql app.db {
		select from Notification where user_id == user_id limit limit
	} or { [] }
	return notifications.len
}

// send_notification_to sends a notification to the given user.
pub fn (app &DatabaseAccess) send_notification_to(user_id int, summary string, body string) {
	notification := Notification{
		user_id: user_id
		summary: summary
		body: body
	}
	sql app.db {
		insert notification into Notification
	} or {
		eprintln('failed to send notification ${notification}')
	}
}
