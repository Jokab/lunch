
CREATE TABLE users (
    username varchar(30) NOT NULL,
    password_hash text NOT NULL,
    PRIMARY KEY (username),
);
