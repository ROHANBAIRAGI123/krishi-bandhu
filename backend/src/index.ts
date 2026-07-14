import { app } from "./app";
import dotenv from "dotenv";

dotenv.config({
  path: "./.env"
});

const PORT: number = Number(process.env.PORT) || 8001;

console.log("Starting server...");

app.listen(PORT, () => {
  console.log(`Server is running at Port: ${PORT}`);
});
