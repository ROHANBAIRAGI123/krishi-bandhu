import mongoose from "mongoose";
const MONGODB_URI = process.env.MONGO_DB_URI;

// const buildMongoUri = (baseUri?: string, dbName?: string): string | undefined => {
//     if (!baseUri) {
//         return undefined;
//     }

//     // If the URI already includes a database path, keep it as-is.
//     try {
//         const parsed = new URL(baseUri);
//         if (parsed.pathname && parsed.pathname !== "/") {
//             return baseUri;
//         }
//     } catch {
//         // If parsing fails, fall back to simple string handling below.
//     }

//     if (!dbName) {
//         return baseUri;
//     }

//     const trimmed = baseUri.replace(/\/+$/, "");
//     return `${trimmed}/${dbName}`;
// };
const connectDB = async (): Promise<void> => {
    try {
        // const uri = buildMongoUri(MONGODB_URI, DB_NAME);
        // if (!uri) {
        //     throw new Error("Missing MONGODB_URI");
        // }

        const connection = await mongoose.connect(MONGODB_URI || "");
        console.log(
            `Database connected succesfully ! \n Name: ${connection.connection.name}`
        );
    } catch (error) {
        console.log(`Database not connected, ${error}`);
        process.exit(1);
    }
};

export default connectDB;

/*
 * ===========================================================================================
 *                              NOTES — db/index.ts
 * ===========================================================================================
 *
 * PURPOSE: Manages the connection to the MongoDB database using Mongoose.
 * ROLE IN ARCHITECTURE: Infrastructure/Database Layer. Ensures the server is connected to the DB before it starts accepting requests.
 * 
 * IMPORTS:
 * - `mongoose`: The MongoDB ODM.
 * - `../utils/env`: Ensures environment variables (`DB_NAME`, `MONGODB_URI`) are loaded before this file runs.
 * 
 * FUNCTION-BY-FUNCTION ANALYSIS:
 * - `buildMongoUri(baseUri, dbName)`
 *   - Does: Safely constructs the full MongoDB connection URI. Checks if the base URI already has a path/DB name. If it does, it keeps it. If not, it appends the `dbName`.
 *   - Parameters: `baseUri` (string), `dbName` (string).
 *   - Returns: A perfectly formatted URI string or undefined.
 *   - Edge cases: Wraps URL parsing in a `try/catch` to fallback to basic string manipulation if the URI format is non-standard.
 * 
 * - `connectDB()`
 *   - Does: Asynchronously establishes the Mongoose connection using the built URI.
 *   - Returns: Promise<void>.
 *   - Side effects: Opens a TCP connection to the database. If it fails, it logs the error and forcibly exits the Node process (`process.exit(1)`).
 * 
 * HOW THIS FILE CONNECTS TO OTHER FILES:
 * - Inbound: Imported and called by the main server entry point (`src/index.ts`) before starting the Express listener.
 * - Outbound: Calls `mongoose.connect`.
 * 
 * DESIGN PATTERNS:
 * - Fail-Fast Initialization Pattern: If the database connection fails, the process exits immediately (`process.exit(1)`). The application cannot function without the DB, so it's better to crash on startup than fail randomly during requests.
 * 
 * POTENTIAL INTERVIEW QUESTIONS:
 * 1. Why do we run `process.exit(1)` if the connection fails?
 *    - Answer: In containerized environments (like Docker/Kubernetes), crashing the process signals the orchestration tool to restart the container or mark it as unhealthy. If we just logged the error and kept running, the server would return 500s to all users silently.
 * 2. Why the complex `buildMongoUri` logic instead of just `${MONGODB_URI}/${DB_NAME}`?
 *    - Answer: MongoDB SRV URIs or URIs provided by cloud providers often already contain default auth databases or trailing slashes. Simply concatenating strings can easily produce invalid URIs (e.g., `mongodb+srv://...//mydb`).
 */