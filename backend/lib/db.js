import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

let pool;
// connecting to the database
async function connect2DB() {
    try {
        if (!pool) {
            pool = mysql.createPool({
                host: process.env.DB_HOST,
                user: process.env.DB_USER,
                password: process.env.DB_PASSWORD,
                database: process.env.DB_NAME
            });
            console.log("connected to database successfully from lib/db.js");
        }
        return pool;
    } catch (error) {
        console.error("Error connecting to database from lib/db.js:", error);
    }
}   


export default connect2DB;