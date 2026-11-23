import { app } from './app';

const PORT = 5050;
const HOST = '0.0.0.0';

app.listen(PORT, HOST, () => {
  console.log(`[My Roomy Server] API listening on http://${HOST}:${PORT}`);
});
