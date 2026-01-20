# St. Refqa Efteqad System

A comprehensive system for managing student attendance, notes, and notifications for St. Refqa Efteqad service. This project consists of a mobile application for servants and admins, and a backend server for data synchronization and management.

## Features

- **Attendance Tracking:** Record and view attendance for students.
- **Notes & Visitations:** Add notes and visitation records for students.
- **Real-time Synchronization:** Changes are synchronized across devices using Socket.IO.
- **Offline Support:** Mobile app uses a local database (Drift) and synchronizes data when online.
- **Notifications:** Push notifications for birthdays, inactivity, and new notes via Firebase.
- **User Roles:** Admin and Servant roles with different permissions.
- **Student Management:** Manage student details, classes, and assignments.

## Architecture

- **Mobile App:** Built with Flutter, using Riverpod for state management, Drift for local SQLite database, and GoRouter for navigation.
- **Backend Server:** Built with Node.js and Express, using Prisma ORM with PostgreSQL for data persistence, and Socket.IO for real-time communication.
- **Database:** PostgreSQL runs as a Docker container (or local instance).

## Prerequisites

- [Node.js](https://nodejs.org/) (v18 or higher recommended)
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.9.2 or higher)
- [Docker](https://www.docker.com/) (for running PostgreSQL) or a local PostgreSQL installation.

## Getting Started

### 1. Database Setup

The project includes a `docker-compose.yml` file to quickly spin up a PostgreSQL database.

```bash
docker-compose up -d
```

This will start a PostgreSQL container named `efteqad_db` on port 5432.

### 2. Server Setup

Navigate to the `server` directory:

```bash
cd server
```

Install dependencies:

```bash
npm install
```

**Environment Variables:**

Create a `.env` file in the `server` directory (or ensure the environment is configured) with the following variables:

```env
DATABASE_URL="postgresql://postgres:password@localhost:5432/efteqad_db?schema=public"
PORT=3000
JWT_SECRET="your_jwt_secret_key"
```

**Firebase Setup (Optional but recommended for notifications):**

Place your Firebase service account JSON file named `service-account.json` in the `server` root directory, or set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable to the path of the file.

Initialize the database schema:

```bash
npx prisma generate
npx prisma migrate dev
```

Start the server:

```bash
npm run dev
```

The server will start on port 3000 (or the port specified in `.env`).

### 3. Mobile App Setup

Navigate to the `mobile` directory:

```bash
cd mobile
```

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

Ensure the server is running and accessible. If running on a real device, you may need to update the API base URL in the mobile app configuration to point to your computer's IP address.

## Tech Stack

**Mobile:**
- **Framework:** Flutter
- **State Management:** Riverpod
- **Local Database:** Drift (SQLite)
- **Routing:** GoRouter
- **Network:** Dio, Socket.IO Client
- **Charts:** fl_chart

**Backend:**
- **Runtime:** Node.js
- **Framework:** Express
- **ORM:** Prisma
- **Database:** PostgreSQL
- **Real-time:** Socket.IO
- **Notifications:** Firebase Admin SDK
- **Scheduling:** node-cron

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
