# Build stage
FROM golang:1.17 as builder

# Install Git
RUN apt-get update && apt-get install -y git

WORKDIR /app

# Clone and build GitLeaks
RUN git clone https://github.com/zricethezav/gitleaks.git && \
    cd gitleaks && \
    go build -o /app/gitleaks

# Final stage
FROM python:3.10-slim

# Create a new user with restricted permissions
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Create /app directory and set permissions
RUN mkdir -p /app && chown -R appuser:appuser /app && chmod 700 /app

# Create a directory for the worker with restricted permissions
RUN mkdir -p /worker && chown -R appuser:appuser /worker && chmod 700 /worker

# Copy Git and GitLeaks from the builder stage
RUN apt-get update && apt-get install -y git
COPY --from=builder /app/gitleaks /usr/local/bin/gitleaks

# Grant execute permissions to GitLeaks
RUN chmod +x /usr/local/bin/gitleaks

# Append Git and GitLeaks paths to the PATH variable
ENV PATH="/usr/local/bin/gitleaks:/usr/bin/git:${PATH}"

# Install Flask and dependencies
RUN pip install flask gevent gevent-websocket flask-socketio pexpect regex

RUN chmod 755 /bin /boot /dev /etc /home /lib /lib64 /media /mnt /opt /proc /root /run /sbin /srv /tmp /usr /var

# Switch to the new user
USER appuser

# Set the working directory to /app
WORKDIR /app

# Copy only necessary files into the container (excluding hidden files)
COPY app.py ./
COPY templates ./templates/
COPY static ./static/

# Change working directory to /worker
WORKDIR /worker

# Expose the Flask port
EXPOSE 5000


# Run the Flask app
CMD ["python", "/app/app.py"]
