CREATE TABLE posts
(
    id         UUID PRIMARY KEY   DEFAULT uuid_generate_v4(),
    text       TEXT      NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    user_id    UUID      NOT NULL REFERENCES users (id)
);

CREATE INDEX posts_user_id_idx ON posts (user_id);