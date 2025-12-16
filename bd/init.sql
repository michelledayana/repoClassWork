CREATE DATABASE holamundo;

USE holamundo;

CREATE TABLE mensajes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  texto VARCHAR(100)
);

INSERT INTO mensajes (texto) VALUES ('Hola Mundo desde la Base de Datos');
