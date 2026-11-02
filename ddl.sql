DROP TABLE IF EXISTS roles CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS people CASCADE;
DROP TABLE IF EXISTS films CASCADE;

CREATE TABLE films (
    id              INTEGER PRIMARY KEY,
    title           VARCHAR(255) NOT NULL,
    release_year    SMALLINT,
    place_name      VARCHAR(100),
    duration        INTEGER,
    language        VARCHAR(100),
    certification   VARCHAR(20),
    gross           BIGINT,
    budget          BIGINT,

    CONSTRAINT chk_films_release_year
        CHECK (release_year IS NULL OR release_year BETWEEN 1888 AND 2100),
    CONSTRAINT chk_films_duration
        CHECK (duration IS NULL OR duration > 0),
    CONSTRAINT chk_films_gross
        CHECK (gross IS NULL OR gross >= 0),
    CONSTRAINT chk_films_budget
        CHECK (budget IS NULL OR budget >= 0),
    CONSTRAINT chk_films_certification
        CHECK (
            certification IS NULL OR certification IN
            ('G', 'PG', 'PG-13', 'R', 'NC-17', 'Not Rated', 'Unrated',
             'Approved', 'Passed', 'X', 'GP', 'M')
        )
);

CREATE TABLE people (
    id          INTEGER PRIMARY KEY,
    name        VARCHAR(255) NOT NULL,
    birthdate   DATE,
    deathdate   DATE,

    CONSTRAINT chk_people_life_dates
        CHECK (deathdate IS NULL OR birthdate IS NULL OR deathdate >= birthdate)
);

CREATE TABLE reviews (
    id              INTEGER PRIMARY KEY,
    film_id         INTEGER NOT NULL,
    num_critic      INTEGER,
    imdb_score      NUMERIC(3,1) NOT NULL,
    num_votes       INTEGER NOT NULL,
    facebook_likes  INTEGER NOT NULL,

    CONSTRAINT fk_reviews_film
        FOREIGN KEY (film_id)
        REFERENCES films(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_reviews_num_critic
        CHECK (num_critic IS NULL OR num_critic >= 0),
    CONSTRAINT chk_reviews_imdb_score
        CHECK (imdb_score BETWEEN 0 AND 10),
    CONSTRAINT chk_reviews_num_votes
        CHECK (num_votes >= 0),
    CONSTRAINT chk_reviews_facebook_likes
        CHECK (facebook_likes >= 0)
);

CREATE TABLE roles (
    id          INTEGER PRIMARY KEY,
    film_id     INTEGER NOT NULL,
    people_id   INTEGER NOT NULL,
    role        VARCHAR(20) NOT NULL,

    CONSTRAINT fk_roles_film
        FOREIGN KEY (film_id)
        REFERENCES films(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_roles_people
        FOREIGN KEY (people_id)
        REFERENCES people(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_roles_role
        CHECK (role IN ('actor', 'director')),

    CONSTRAINT uq_roles_film_person_role
        UNIQUE (film_id, people_id, role)
);

CREATE INDEX idx_reviews_film_id ON reviews(film_id);
CREATE INDEX idx_roles_film_id ON roles(film_id);
CREATE INDEX idx_roles_people_id ON roles(people_id);
CREATE INDEX idx_roles_role ON roles(role);

-- ============================================================
-- End of DDL script
-- ============================================================
-- After executing this script in film_db, import the cleaned CSV files
-- through pgAdmin's Import/Export Data GUI in this order:
-- films_cleaned.csv, people_cleaned.csv, reviews_cleaned.csv, roles_cleaned.csv.
-- The import result and referential integrity are verified in dql.sql.
