CREATE OR REPLACE FUNCTION search_for_users (IN Query TEXT, IN Count INT, IN Index INT)
RETURNS SETOF "User"
AS $$
	SELECT *
	FROM "User"
	WHERE username LIKE CONCAT('%', Query, '%') OR nickname LIKE CONCAT('%', Query, '%')
	ORDER BY (CASE
		WHEN username LIKE CONCAT('%', Query, '%') THEN 1
		WHEN nickname LIKE CONCAT('%', Query, '%') THEN 2
		END)
	LIMIT Count OFFSET Index;
$$ LANGUAGE SQL;
