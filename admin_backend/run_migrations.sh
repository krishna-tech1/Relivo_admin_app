#!/bin/bash
# Run database migrations before starting the server

echo "Running database migrations..."
python add_rejection_reason_migration.py

echo "Starting server..."
exec "$@"
