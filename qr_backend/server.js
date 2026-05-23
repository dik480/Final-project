const express = require('express');
const cors = require('cors');
const path = require('path');
const dotenv = require('dotenv');

// Load env vars
dotenv.config();

// Require our modules
const { db, admin } = require('./config/firebase_config');

const app = express();
const PORT = process.env.PORT || 3000;

// View engine setup
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// Pass db to routes
app.use((req, res, next) => {
    req.db = db;
    next();
});

// Routes
const webRoutes = require('./routes/web');
const apiRoutes = require('./routes/api');

// Web Fallback Route: handle /pet/:qr_id
app.use('/pet', webRoutes);

// API Routes
app.use('/api', apiRoutes);

app.listen(PORT, () => {
    console.log(`Pawtner QR Backend running on port ${PORT}`);
});
