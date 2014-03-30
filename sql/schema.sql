
CREATE TABLE users (
    username VARCHAR(64) NOT NULL,
    password VARCHAR(1024) NOT NULL,
    salt VARCHAR(512) NOT NULL,
    PRIMARY KEY (username)
);

-- Not part of users since one might want multiple secrets
-- for one user in the future. One per client possibly.
CREATE TABLE api_secrets (
    username VARCHAR(64) REFERENCES users(username) ON DELETE CASCADE,
    api_secret VARCHAR(512),
    created_on TIMESTAMP DEFAULT statement_timestamp(),
    PRIMARY KEY (username)
);
