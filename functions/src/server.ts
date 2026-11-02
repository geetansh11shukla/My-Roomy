import { app } from './app';

const PORT = 5050;
app.listen(PORT, () => {
  console.log(`[My Roomy Server] API listening on port ${PORT}`);
});
