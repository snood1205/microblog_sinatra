CREATE TABLE users
(
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username      VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX users_username_idx ON users (username);