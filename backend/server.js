require('dotenv').config();

if (!process.env.GEMINI_API_KEY) {
  console.error('FATAL: GEMINI_API_KEY environment variable is not defined.');
  process.exit(1);
}

const app = require('./src/app');

const port = Number(process.env.PORT || 8080);

app.listen(port, () => {
  console.log(`MOSPL API listening on http://localhost:${port}`);
});
