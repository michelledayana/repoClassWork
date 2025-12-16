const express = require("express");
const app = express();

app.get("/", (req, res) => {
  res.json({ message: "Backend Docker funcionando" });
});

app.listen(3000, () => {
  console.log("Backend en puerto 3000");
});
