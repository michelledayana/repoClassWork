CREATE TABLE mensajes (
id SERIAL PRIMARY KEY,
texto VARCHAR(100)
);


INSERT INTO mensajes (texto) VALUES ('Hola Mundo desde PostgreSQL');
