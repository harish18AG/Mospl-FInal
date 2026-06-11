require('dotenv').config();

const app = require('./src/app');

const port = Number(process.env.PORT || 8080);

app.listen(port, () => {
  console.log(`MOSPL API listening on http://localhost:${port}`);
});
