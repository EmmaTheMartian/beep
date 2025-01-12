CREATE OR REPLACE FUNCTION search_for_posts (IN Query TEXT, IN Count INT, IN Index INT)
RETURNS SETOF "Post"
AS $$
	SELECT *
	FROM "Post"
	WHERE title LIKE CONCAT('%', Query, '%') OR body LIKE CONCAT('%', Query, '%')
	ORDER BY (CASE
		WHEN title LIKE CONCAT('%', Query, '%') THEN 1
		WHEN body LIKE CONCAT('%', Query, '%') THEN 2
		END)
	LIMIT Count OFFSET Index;
$$ LANGUAGE SQL;
