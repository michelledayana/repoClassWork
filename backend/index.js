const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');

const app = express();
app.use(cors());

const pool = new Pool({
  host: 'db',
  user: 'postgresql',
  password: 'dayana',
  database: 'holamundo'
});

app.get('/mensaje', async (req, res) => {
  try {
    const result = await pool.query('SELECT texto FROM mensajes LIMIT 1');
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).send(err);
  }
});

app.listen(3000, () => {
  console.log('Backend corriendo en puerto 3000');
});
