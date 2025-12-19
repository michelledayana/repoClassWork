CREATE TABLE messages (
  id SERIAL PRIMARY KEY,
  text VARCHAR(100)
);

INSERT INTO messages (text)
VALUES ('Hello World from PostgreSQL');
