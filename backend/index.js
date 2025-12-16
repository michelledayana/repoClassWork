const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');

const app = express();
app.use(cors());

const db = mysql.createConnection({
  host: 'db',
  user: 'root',
  password: 'root',
  database: 'holamundo'
});

app.get('/mensaje', (req, res) => {
  db.query('SELECT texto FROM mensajes LIMIT 1', (err, result) => {
    if (err) return res.status(500).send(err);
    res.json(result[0]);
  });
});

app.listen(3000, () => {
  console.log('Backend corriendo en puerto 3000');
});
