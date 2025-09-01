const mongoose = require('mongoose');
require('dotenv').config();

mongoose.set('strictQuery', false);

if (process.env.NODE_ENV !== 'test') {
  module.exports = mongoose
    .connect(process.env.MONGO_URI || 'mongodb://mongo:27017/Blog')
    .then(() => {
      console.log('connected!');
      return true;
    })
    .catch((err) => {
      console.error(err);
      throw err;
    });
} else {
  // En tests, no conectes a Mongo
  module.exports = Promise.resolve(true);
}
