SELECT * FROM films;
SELECT * FROM people;
SELECT * FROM reviews;
SELECT * FROM roles;

-- ============================================================
-- import verification: row-count consistency check
-- ============================================================
-- This compact count query provides an additional audit trail for the
-- import process. It supports the report's cleaned-data summary by
-- confirming the final number of rows stored in each implemented table.
SELECT 'films' AS table_name, COUNT(*) AS row_count FROM films
UNION ALL
SELECT 'people', COUNT(*) FROM people
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL
SELECT 'roles', COUNT(*) FROM roles
ORDER BY table_name;

-- ============================================================
-- integrity verification: orphan review detection
-- ============================================================
-- This query checks whether any review record still points to a film
-- that does not exist in films.id. The expected result is 0, which
-- demonstrates that the cleaned reviews table satisfies the intended
-- foreign-key dependency before and after import.
SELECT COUNT(*) AS orphan_reviews
FROM reviews r
LEFT JOIN films f ON r.film_id = f.id
WHERE f.id IS NULL;

-- ============================================================
-- integrity verification: orphan role detection
-- ============================================================
-- This query checks both sides of the associative roles relation. The
-- expected result is 0, showing that every role assignment connects one
-- existing film with one existing person, which is essential for the
-- many-to-many film-person relationship represented in the ERD.
SELECT COUNT(*) AS orphan_roles
FROM roles ro
LEFT JOIN films f ON ro.film_id = f.id
LEFT JOIN people p ON ro.people_id = p.id
WHERE f.id IS NULL OR p.id IS NULL;

-- ============================================================
-- Query 1
-- Top 5 films by average review score
-- ============================================================
-- Analytical purpose:
-- This query ranks films by their average IMDb review score. It joins
-- films with reviews, groups review rows at film level, calculates the
-- average score, and returns only the five highest-ranked films.
--
-- Design rationale:
-- A deterministic secondary ordering is included. If two films share
-- the same average score, the film with more review rows is shown first;
-- if both values are tied, the title is used as a stable final ordering
-- key. This makes the screenshot output easier to verify and reproduce.
WITH film_scores AS (
    SELECT
        f.id AS film_id,
        f.title,
        f.release_year,
        ROUND(AVG(r.imdb_score), 2) AS average_review_score,
        COUNT(r.id) AS review_count
    FROM films AS f
    INNER JOIN reviews AS r
        ON f.id = r.film_id
    GROUP BY f.id, f.title, f.release_year
)
SELECT
    RANK() OVER (
        ORDER BY average_review_score DESC
    ) AS rating_rank,
    film_id,
    title,
    release_year,
    average_review_score,
    review_count
FROM film_scores
ORDER BY average_review_score DESC, review_count DESC, title ASC
LIMIT 5;

-- ============================================================
-- Query 2
-- Films with more than 5 reviews
-- ============================================================
-- Analytical purpose:
-- This query identifies films with a review volume greater than five.
-- It uses GROUP BY to form one group per film and HAVING to filter the
-- aggregate result, which directly demonstrates the distinction between
-- row-level filtering and group-level filtering taught in SQL practice.
--
-- Design rationale:
-- INNER JOIN is used because the question concerns reviewed films only.
-- Films without review rows are therefore excluded before aggregation,
-- while COUNT(r.id) measures the number of review records attached to
-- each remaining film.
SELECT
    f.id AS film_id,
    f.title,
    f.release_year,
    COUNT(r.id) AS review_count
FROM films AS f
INNER JOIN reviews AS r
    ON f.id = r.film_id
GROUP BY f.id, f.title, f.release_year
HAVING COUNT(r.id) > 5
ORDER BY review_count DESC, f.title ASC;

-- ============================================================
-- Query 3
-- Number of films each actor appeared in
-- ============================================================
-- Analytical purpose:
-- This query counts how many distinct films each actor is associated
-- with. It answers the actor-focused requirement while preserving the
-- normalized design: people stores names, roles stores participation,
-- and films confirms the referenced film records.
--
-- Design rationale:
-- The query explicitly joins people, roles, and films so that the
-- calculation follows the coursework requirement to connect actors to
-- film records through the associative roles relation. The role filter
-- excludes directors, and COUNT(DISTINCT f.id) prevents duplicated role
-- rows from inflating the number of films if similar data issues appear
-- in future extensions of the dataset.
SELECT
    p.id AS actor_id,
    p.name AS actor_name,
    COUNT(DISTINCT f.id) AS number_of_films
FROM people AS p
INNER JOIN roles AS ro
    ON p.id = ro.people_id
INNER JOIN films AS f
    ON f.id = ro.film_id
WHERE ro.role = 'actor'
GROUP BY p.id, p.name
ORDER BY number_of_films DESC, actor_name ASC;
