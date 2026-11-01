"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const app_1 = require("./app");
const PORT = process.env.PORT || 8080;
app_1.app.listen(PORT, () => {
    console.log(`====================================================`);
    console.log(` RoomWala Production Backend Server Running on :${PORT}`);
    console.log(` Environment: Production-Ready (Demo Mock Fallback Active)`);
    console.log(` Base API: http://localhost:${PORT}/api/health`);
    console.log(`====================================================`);
});
