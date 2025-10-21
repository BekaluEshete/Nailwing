# Use official Python image
FROM python:3.13-slim

# Set work directory
WORKDIR /app

# Environment settings
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Install system dependencies
RUN apt-get update && apt-get install -y build-essential libpq-dev gcc --no-install-recommends \
 && rm -rf /var/lib/apt/lists/*

# Copy and install requirements
COPY requirements.txt /app/
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . /app/

# Run Django dev server
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
