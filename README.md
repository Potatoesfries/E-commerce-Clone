# Flutter E-commerce Application

![Project Status](https://img.shields.io/badge/Status-Active-brightgreen)
![Flutter](https://img.shields.io/badge/Flutter-SDK-blue)
![Node.js](https://img.shields.io/badge/Backend-Node.js-green)
![MySQL](https://img.shields.io/badge/Database-MySQL-orange)

A fully functional, professional e-commerce application built with a **Flutter** frontend, **Node.js/Express** backend, and a **MySQL** database. This project includes user authentication, shopping carts, order tracking, and profile management.

---

## 📸 UI Gallery

Here is a showcase of the application's user interface:

<p align="center">
  <img src="./E-commerce/Screenshot%202025-10-07%20232136.png" width="23%" style="margin: 1%" />
  <img src="./E-commerce/Screenshot%202025-10-07%20233802.png" width="23%" style="margin: 1%" />
  <img src="./E-commerce/Screenshot%202025-10-07%20233821.png" width="23%" style="margin: 1%" />
  <img src="./E-commerce/Screenshot%202025-10-07%20233828.png" width="23%" style="margin: 1%" />
</p>
<p align="center">
  <img src="./E-commerce/Screenshot%202025-10-07%20233835.png" width="23%" style="margin: 1%" />
  <img src="./E-commerce/Screenshot%202025-10-07%20233842.png" width="23%" style="margin: 1%" />
  <img src="./E-commerce/Screenshot%202025-10-07%20233850.png" width="23%" style="margin: 1%" />
  <img src="./E-commerce/Screenshot%202025-10-07%20233911.png" width="23%" style="margin: 1%" />
</p>

---

## 🌟 Key Features

- **User Authentication**: Secure Login/Register flows with JWT integration.
- **Dynamic Shopping Cart**: Effortlessly add, remove, and manage products.
- **Product Discovery**: Browse items, search for specific products, and filter your favorite choices.
- **Order Management**: Real-time order processing and status tracking.
- **Profile Management**: Profile picture upload (via Cloudinary) and editable user details.
- **Cross-Platform Support**: Renderable dynamically on iOS and Android devices.

---

## 📁 Project Structure

```text
├── E-commerce/          # UI Gallery Screenshots
├── backend/             # Node.js + Express + MySQL Server
│   ├── controllers/     # API Logic & Database interactions
│   ├── lib/             # Database connection handling
│   ├── middleware/      # JWT and other express middleware
│   ├── routes/          # Express routing
│   └── index.js         # Entry point for the server
└── frontend/            # Flutter Application
    ├── lib/             
    │   ├── screens/     # Application UI views (Cart, Home, Profile, etc.)
    │   ├── services/    # Integration logic with backend REST API
    │   └── main.dart    # Flutter entry point
```

---

## 🚀 Setup Guide

### 1. Database Setup (MySQL)
1. Ensure your local MySQL server is running.
2. Create a new database in MySQL:
   ```sql
   CREATE DATABASE db4pm;
   ```

### 2. Backend Configuration
1. Navigate to the backend folder:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Create your environment variables:
   Copy `.env.example` into a new `.env` file and fill in your secrets.
   ```bash
   cp .env.example .env
   ```
   **Where to put API Keys:** Open `.env`. This is where your **JWT Secret** and **Cloudinary Keys** should be configured securely. Make sure never to push `.env` to GitHub (it is excluded via `.gitignore`).
4. Run the server:
   ```bash
   npm start
   # or node index.js
   ```

### 3. Frontend Configuration (Flutter)
1. Navigate to the frontend folder:
   ```bash
   cd frontend
   ```
2. Install packages:
   ```bash
   flutter pub get
   ```
3. **Configure API Base URL:**
   Open the services folder (`frontend/lib/services/`). For each service file (ex: `auth_service.dart`, `shop_service.dart`, etc.), verify that `baseUrl` corresponds to your local IP Address.
   *Example:*
   ```dart
   static const String baseUrl = 'http://192.168.100.46:5000';
   ```
   Change the IP to match your local Wi-Fi router IP (which usually hosts the backend Node.js server) if deploying on a physical device, or use `10.0.2.2` if testing via Android Emulator.

4. Run the application:
   ```bash
   flutter run
   ```

---

## 🔒 Security Audited
Secrets inside the codebase (via `.env`) and external database/cache configurations run outside of the tracking tree. A robust `.gitignore` prevents leaks of any `node_modules`, `.env` keys, keystores, database backups, cache structures or macOS `DS_Store` indices. All external secrets should be injected via environments.
