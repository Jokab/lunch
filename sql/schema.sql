
CREATE TABLE users (
    user_id SERIAL,
    username VARCHAR(64) NOT NULL,
    password VARCHAR(1024) NOT NULL,
    salt VARCHAR(512) NOT NULL,
    PRIMARY KEY (user_id),
    UNIQUE (username)
);

CREATE TABLE api_secrets (
    user_id INTEGER REFERENCES users(user_id),
    api_secret VARCHAR(512),
    created_on TIMESTAMP DEFAULT statement_timestamp(),
    PRIMARY KEY (user_id, api_secret),
    UNIQUE(api_secret)
);
