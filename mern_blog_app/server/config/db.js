const mongoose = require('mongoose');
require('dotenv').config();

mongoose.set('strictQuery', false);

module.exports = mongoose
  .connect(process.env.MONGO_URI || 'mongodb://mongo:27017/Blog')
  .then(() => {
    console.log('connected!');
    return true; // o: return mongoose.connection;
  })
  .catch((err) => {
    console.error(err);
    throw err; // importante para cumplir la regla
  });
