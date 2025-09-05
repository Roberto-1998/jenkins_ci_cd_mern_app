const isProd = process.env.NODE_ENV === 'production';


const config = {
  BASE_URL: isProd ? '/api' : 'http://localhost:5001',
};
export default config;
