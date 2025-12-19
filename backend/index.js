const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');

const app = express();
app.use(cors());

const pool = new Pool({
  host: 'db',              // service name in docker-compose
  user: 'postgresql',
  password: 'dayana',
  database: 'holamundo'
});

// Root route
app.get('/', (req, res) => {
  res.send('Backend working correctly 🚀');
});

// Route using database
app.get('/mensaje', async (req, res) => {
  try {
    const result = await pool.query('SELECT text FROM messages LIMIT 1');
    res.json({ message: result.rows[0].text });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database query error' });
  }
});

app.listen(3000, () => {
  console.log('Backend running on port 3000');
});
