const mongoose = require('mongoose');

let cached = global._mongooseCache;
if (!cached) {
  cached = global._mongooseCache = { conn: null, promise: null };
}

const connectDB = async () => {
  if (cached.conn) return cached.conn;
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error('MONGODB_URI is not set');
    return null;
  }
  if (!cached.promise) {
    cached.promise = mongoose.connect(uri).then((conn) => {
      console.log(`MongoDB connected: ${conn.connection.host}`);
      return conn;
    }).catch((error) => {
      console.error(`MongoDB error: ${error.message}`);
      cached.promise = null;
      return null;
    });
  }
  cached.conn = await cached.promise;
  return cached.conn;
};

module.exports = connectDB;
