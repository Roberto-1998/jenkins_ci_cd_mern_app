const express = require('express');
const cors = require('cors');
const userRouter = require('./routes/user-routes');
const blogRouter = require('./routes/blog-routes');
require('./config/db'); // respeta la condición de NODE_ENV en db.js

const app = express();

app.set('view engine', 'ejs');
app.use(express.json());
app.use(cors());

// Rutas API
app.use('/api/users', userRouter);
app.use('/api/blogs', blogRouter);

// Rutas simples
app.get('/api', (req, res) => res.status(200).json({ message: 'hello' }));
app.get('/health', (req, res) => res.status(200).send('OK'));

// Solo escuchar cuando se ejecuta directamente
if (require.main === module) {
  const PORT = process.env.PORT || 5001;
  app.listen(PORT, () => console.log('app started at 5001...'));
}

module.exports = app;
