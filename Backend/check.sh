#!/bin/bash
# Run this before pushing to catch CI failures early
# Usage: bash check.sh

set -e  # stop on first error

echo "========================================="
echo " Pre-push checks"
echo "========================================="

echo ""
echo "1. Linting (syntax errors)..."
flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics \
  --exclude=migrations,__pycache__,.venv
echo "   Lint passed."

echo ""
echo "2. Django system check..."
python manage.py check
echo "   Django check passed."

echo ""
echo "3. Migration check..."
python manage.py migrate --check
echo "   Migrations up to date."

echo ""
echo "4. Checking for missing migrations..."
python manage.py makemigrations --check --dry-run
echo "   No missing migrations."

echo ""
echo "5. Running tests..."
python manage.py test --settings=core.test_settings --verbosity=1
echo "   All tests passed."

echo ""
echo "6. Checking for missing migrations..."
python manage.py makemigrations --check --dry-run
echo "   No missing migrations."

echo ""
echo "========================================="
echo " All checks passed. Safe to push."
echo "========================================="
echo ""
echo "Zero-downtime migration procedure (if you have schema changes):"
echo "  Step A: Add nullable columns / new tables (expand)"
echo "  Step B: Deploy code that writes to both old + new schema"
echo "  Step C: Backfill data in background tasks"
echo "  Step D: Switch reads/writes to new schema only"
echo "  Step E: Drop old columns in a follow-up release (contract)"
