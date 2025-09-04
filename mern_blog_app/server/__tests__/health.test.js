const request = require('supertest');
const app = require('../server');

describe('Health endpoint', () => {
  it('GET /health -> 200 OK', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.text).toBe('OK');
  });
});
