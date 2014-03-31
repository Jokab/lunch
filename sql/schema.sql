
CREATE TABLE users (
    username VARCHAR(64),
    password VARCHAR(1024) NOT NULL,
    salt VARCHAR(512) NOT NULL,
    PRIMARY KEY (username)
);

-- Not part of users since one might want multiple secrets
-- for one user in the future. One per client possibly.
CREATE TABLE api_secrets (
    username VARCHAR(64) REFERENCES users ON DELETE CASCADE ON UPDATE CASCADE,
    api_secret VARCHAR(512) NOT NULL,
    created_on TIMESTAMP DEFAULT statement_timestamp(),
    PRIMARY KEY (username)
);

CREATE TABLE groups (
    name VARCHAR(64) NOT NULL,
    id SERIAL,
    PRIMARY KEY (id)
);

CREATE TABLE lunch_places (
    group_id INTEGER REFERENCES groups ON DELETE CASCADE ON UPDATE CASCADE,
    name VARCHAR(64) NOT NULL,
    location TEXT,
    PRIMARY KEY (group_id, name)
);

CREATE TABLE users_part_of_group (
    group_id INTEGER REFERENCES groups ON DELETE CASCADE ON UPDATE CASCADE,
    username VARCHAR(64) REFERENCES users ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (group_id, username)
);

CREATE TABLE group_lunch_places_visits (
    lunch_place VARCHAR(64),
    group_id INTEGER REFERENCES groups ON DELETE CASCADE ON UPDATE CASCADE,
    visited_on TIMESTAMP DEFAULT statement_timestamp(),
    FOREIGN KEY (lunch_place, group_id) REFERENCES lunch_places(name, group_id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (lunch_place, group_id, visited_on)
);
