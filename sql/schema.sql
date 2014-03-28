
CREATE TABLE users (
    user_id SERIAL,
    username varchar(64) NOT NULL,
    password varchar(1024) NOT NULL,
    salt varchar(512) NOT NULL,
    api_secret varchar(512) NOT NULL,
    PRIMARY KEY (user_id),
    UNIQUE (username),
    UNIQUE (api_secret)
);
