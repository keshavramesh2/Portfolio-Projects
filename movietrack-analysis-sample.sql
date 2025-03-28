/*
This is a sample from my movie and track analysis project
*/

-- Select the albums with at least 8 tracks and with the word 'Rock' and its derivatives in their titles. In the end, print the average number of tracks in these albums.
SELECT
    AVG(albums_1.album_track_count) AS avg_tracks_per_album
FROM (
    SELECT
        albums.album_id,
        albums.album_track_count
    FROM
        (SELECT 
            album.album_id AS album_id,
            COUNT(track.track_id) AS album_track_count
        FROM album LEFT JOIN track ON track.album_id = album.album_id
        WHERE album.title LIKE '%Rock%'
        GROUP BY album.album_id
        HAVING COUNT(track.track_id) >= 8) AS albums
    GROUP BY
        albums.album_id,
        albums.album_track_count
) AS albums_1

-- Find the MPAA movie rating that corresponds to the most expensive movies. Print the movie categories with this rating. Then display the average movie length.
SELECT name AS category, AVG(length) AS avg_movie_length
FROM
    movie
    LEFT JOIN film_category ON film_category.film_id = movie.film_id
    LEFT JOIN category ON category.category_id = film_category.category_id
WHERE rating IN (
    SELECT 
        rating
    FROM movie
    GROUP BY rating
    ORDER BY AVG(rental_rate) DESC
    LIMIT 1
)
GROUP BY rating, name;

-- Create a table displaying each category and the number of movies in the category. Then, select the movies for the second field using the following condition: count only the movies featuring actors who have acted in more than seven films released after 2013. Order the number of movies in descending order and then by category name in lexographical order.
SELECT 
    category.name AS name_category,
    COUNT(DISTINCT film_actor.film_id) AS total_films
    
FROM
    movie
    LEFT JOIN film_actor ON film_actor.film_id = movie.film_id
    LEFT JOIN film_category ON film_category.film_id = movie.film_id
    LEFT JOIN category ON category.category_id = film_category.category_id
WHERE actor_id IN (
    SELECT 
        film_actor.actor_id AS actor
    FROM
        movie
        LEFT JOIN film_actor ON film_actor.film_id = movie.film_id
        LEFT JOIN actor ON actor.actor_id = film_actor.actor_id
    WHERE
        release_year > 2013
    GROUP BY
        actor
    HAVING COUNT(DISTINCT movie.film_id) > 7
)
GROUP BY name_category
ORDER BY total_films DESC, name_category;


-- Analyze the forty longest movies that cost over $2 to rent.
WITH m AS (
    SELECT title, rating, length, rental_rate
    FROM movie
    WHERE rental_rate > 2
    ORDER BY length DESC
    LIMIT 40
)

SELECT
    m.rating,
    MIN(m.length) AS min_length,
    MAX(m.length) AS max_length,
    AVG(m.length) AS avg_length,
    MIN(m.rental_rate) AS min_rental_rate,
    MAX(m.rental_rate) AS max_rental_rate,
    AVG(m.rental_rate) AS avg_rental_rate
FROM m
GROUP BY m.rating
ORDER BY avg_length;
