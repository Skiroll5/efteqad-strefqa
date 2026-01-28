#!/bin/sh

# Wait for the database to be ready (Optional but safe)
echo "Waiting for database to be ready..."

# Push the schema to the database
echo "Pushing Prisma schema..."
npx prisma db push

# Start the application
echo "Starting application..."
npm run start