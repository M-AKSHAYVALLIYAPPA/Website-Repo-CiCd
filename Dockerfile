# -------------------------------
# Stage 1: Base App (Python 3.10)
# -------------------------------
FROM python:3.10-slim as base

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    nginx \
    curl \
    supervisor \
    && apt-get clean

# Create app directory
WORKDIR /app

# Copy application files
COPY . /app

# Install Flask and Gunicorn directly (without requirements.txt)
RUN pip install --no-cache-dir Flask gunicorn

# Copy custom Nginx config if any (optional)
# COPY nginx.conf /etc/nginx/nginx.conf

# Remove default Nginx site and use a minimal proxy config
RUN rm /etc/nginx/sites-enabled/default && \
    echo 'server {\n\
        listen 80;\n\
        location / {\n\
            proxy_pass http://127.0.0.1:8000;\n\
            proxy_set_header Host $host;\n\
            proxy_set_header X-Real-IP $remote_addr;\n\
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
        }\n\
    }' > /etc/nginx/sites-available/default && \
    ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Setup Supervisor to manage both Nginx and Gunicorn
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose port 80
EXPOSE 80

# Start all services
CMD ["/usr/bin/supervisord"]
