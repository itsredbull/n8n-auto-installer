#!/bin/bash


# n8n Automated Installation & Troubleshooting Script
# This script automatically installs and configures n8n in Docker
# Detects Linux OS, saves logs and credentials to /n8ninstall.log

# Log file location
LOG_FILE="/n8ninstall.log"
N8N_DATA_DIR="/n8n-data"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Generate random password for n8n admin
ADMIN_PASSWORD=$(openssl rand -base64 12)

# Function to log messages
log() {
    echo "$TIMESTAMP - $1" | tee -a "$LOG_FILE"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo."
  exit 1
fi

# Create log file
touch "$LOG_FILE" && chmod 644 "$LOG_FILE"

# Start logging
log "Starting n8n automated installation and configuration"
log "========================================"

# Detect Linux OS
log "Detecting Linux distribution..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VERSION=$VERSION_ID
    log "Detected OS: $OS $VERSION"
elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
    VERSION=$(lsb_release -sr)
    log "Detected OS: $OS $VERSION"
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VERSION=$DISTRIB_RELEASE
    log "Detected OS: $OS $VERSION"
elif [ -f /etc/redhat-release ]; then
    OS=$(cat /etc/redhat-release | cut -d' ' -f1)
    VERSION=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+')
    log "Detected OS: $OS $VERSION (via redhat-release)"
else
    OS=$(uname -s)
    VERSION=$(uname -r)
    log "Detected OS: $OS $VERSION (generic method)"
fi

# Handle special cases for RHEL-based distros
if [[ "$OS" == *"AlmaLinux"* ]] || grep -q "AlmaLinux" /etc/os-release 2>/dev/null; then
    OS="AlmaLinux"
    log "Detected AlmaLinux distribution"
elif [[ "$OS" == *"Rocky"* ]] || grep -q "Rocky" /etc/os-release 2>/dev/null; then
    OS="Rocky Linux"
    log "Detected Rocky Linux distribution"
elif [[ "$OS" == *"CentOS"* ]] || grep -q "CentOS" /etc/redhat-release 2>/dev/null; then
    OS="CentOS"
    log "Detected CentOS distribution"
elif [[ "$OS" == *"Red Hat"* ]] || grep -q "Red Hat" /etc/redhat-release 2>/dev/null; then
    OS="Red Hat Enterprise Linux"
    log "Detected RHEL distribution"
elif [[ "$OS" == *"Oracle"* ]] || grep -q "Oracle" /etc/oracle-release 2>/dev/null; then
    OS="Oracle Linux"
    log "Detected Oracle Linux distribution"
fi

# Get server IP address
SERVER_IP=$(hostname -I | awk '{print $1}')
log "Server IP: $SERVER_IP"

# Check if Docker is installed
log "Checking if Docker is installed..."
if ! command -v docker &> /dev/null; then
    log "Docker not found. Installing Docker..."
    
    # Install Docker based on detected OS
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        apt-get update
        apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
        add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]] || [[ "$OS" == *"Fedora"* ]] || [[ "$OS" == *"AlmaLinux"* ]] || [[ "$OS" == *"Rocky"* ]] || [[ "$OS" == *"Oracle"* ]]; then
        # For CentOS, RHEL, Fedora, AlmaLinux, Rocky Linux, Oracle Linux
        log "Installing Docker for RHEL-based system: $OS"
        yum install -y yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io
        systemctl start docker
        systemctl enable docker
        
        # In case Docker installation fails with the above method on AlmaLinux/Rocky Linux
        if ! command -v docker &> /dev/null && ( [[ "$OS" == *"AlmaLinux"* ]] || [[ "$OS" == *"Rocky"* ]] ); then
            log "Trying alternative Docker installation method for $OS..."
            dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
            dnf -y install docker-ce docker-ce-cli containerd.io
            systemctl start docker
            systemctl enable docker
            
            # If still failing, try with the official RHEL 8 AppStream repository
            if ! command -v docker &> /dev/null; then
                log "Trying with official repository..."
                dnf -y module install container-tools
                systemctl start docker
                systemctl enable docker
            fi
        fi
    elif [[ "$OS" == *"SUSE"* ]]; then
        zypper install -y docker
        systemctl start docker
        systemctl enable docker
    elif [[ "$OS" == *"Amazon"* ]]; then
        yum install -y docker
        systemctl start docker
        systemctl enable docker
    else
        log "Attempting generic Docker installation for unknown OS: $OS"
        # Try a generic approach that might work on various Linux distros
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        systemctl start docker
        systemctl enable docker
        
        if ! command -v docker &> /dev/null; then
            log "Automatic Docker installation failed. Please install Docker manually and run this script again."
            exit 1
        else
            log "Docker installed successfully via generic installer."
        fi
    fi
    
    log "Docker installed successfully."
else
    log "Docker is already installed."
fi

# Check if Docker Compose is installed
log "Checking if Docker Compose is installed..."
if ! command -v docker compose &> /dev/null; then
    log "Docker Compose not found. Installing Docker Compose..."
    
    # Install Docker Compose v2 plugin (new approach)
    mkdir -p ~/.docker/cli-plugins/
    curl -SL https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
    chmod +x ~/.docker/cli-plugins/docker-compose
    
    # Create symlink for system-wide access
    ln -sf ~/.docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
    
    # Test if Docker Compose works as a plugin
    if docker compose version >/dev/null 2>&1; then
        log "Docker Compose plugin installed successfully."
    else
        log "Docker Compose plugin installation may have issues. Trying alternative method..."
        
        # Alternative: install standalone docker-compose
        curl -L "https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        
        if docker-compose --version >/dev/null 2>&1; then
            log "Docker Compose standalone installation successful."
            # Create alias in shell profiles
            echo 'alias docker-compose="docker compose"' >> /etc/profile.d/docker-compose-alias.sh
            chmod +x /etc/profile.d/docker-compose-alias.sh
        else
            log "WARNING: Docker Compose installation might have issues but continuing..."
        fi
    fi
else
    log "Docker Compose is already installed."
fi

# Start Docker if not running
if ! systemctl is-active --quiet docker; then
    log "Starting Docker service..."
    systemctl start docker
    systemctl enable docker
    log "Docker service started."
fi

# Create n8n data directory
log "Creating n8n data directory at $N8N_DATA_DIR..."
mkdir -p "$N8N_DATA_DIR/n8n_data"
chmod -R 777 "$N8N_DATA_DIR/n8n_data"  # Ensure proper permissions

# Create docker-compose.yml
log "Creating docker-compose.yml file..."
cat > "$N8N_DATA_DIR/docker-compose.yml" << EOL
version: '3'

services:
  n8n:
    image: n8nio/n8n:latest
    restart: always
    ports:
      - "5678:5678"
    environment:
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - WEBHOOK_URL=http://${SERVER_IP}:5678/
      - N8N_PROTOCOL=http
      - N8N_USER_MANAGEMENT_DISABLED=false
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=${ADMIN_PASSWORD}
      - N8N_SECURE_COOKIE=false
    volumes:
      - ${N8N_DATA_DIR}/n8n_data:/home/node/.n8n
EOL

# Log the credentials for future reference
log "========================================"
log "n8n admin credentials:"
log "Username: admin"
log "Password: $ADMIN_PASSWORD"
log "========================================"

# Configure firewall if it exists
log "Configuring firewall..."
if command -v ufw >/dev/null 2>&1; then
    log "UFW firewall detected. Adding rule for port 5678..."
    ufw allow 5678/tcp > /dev/null 2>&1
    log "UFW rule added for port 5678."
elif command -v firewall-cmd >/dev/null 2>&1; then
    log "firewalld detected. Adding rule for port 5678..."
    firewall-cmd --permanent --add-port=5678/tcp > /dev/null 2>&1
    firewall-cmd --reload > /dev/null 2>&1
    log "firewalld rule added for port 5678."
else
    # Extra check for specific distros like AlmaLinux that might have firewalld but not enabled by default
    if [[ "$OS" == *"AlmaLinux"* ]] || [[ "$OS" == *"Rocky"* ]] || [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        log "RHEL-based distro detected. Installing and configuring firewalld..."
        # Install firewalld if not present
        if ! rpm -q firewalld >/dev/null 2>&1; then
            yum install -y firewalld > /dev/null 2>&1
        fi
        # Start and enable firewalld
        systemctl start firewalld > /dev/null 2>&1
        systemctl enable firewalld > /dev/null 2>&1
        # Add port rule
        firewall-cmd --permanent --add-port=5678/tcp > /dev/null 2>&1
        firewall-cmd --reload > /dev/null 2>&1
        log "firewalld installed and configured for port 5678."
    else
        log "No common firewall detected (ufw/firewalld)."
    fi
fi

# Stop any existing n8n container
log "Stopping any existing n8n containers..."
docker ps -a --format '{{.Names}}' | grep n8n | xargs -r docker rm -f >/dev/null 2>&1 || true

# Start n8n container
log "Starting n8n container..."
cd "$N8N_DATA_DIR" && docker compose up -d
sleep 10  # Wait for container to start

# Check if n8n container is running
log "Checking if n8n container is running..."
# Use docker ps with --format to avoid potential grep issues
if docker ps --format '{{.Names}}' | grep -q "n8n"; then
    N8N_CONTAINER=$(docker ps -f name=n8n --format '{{.ID}}')
    log "n8n container is running with ID: $N8N_CONTAINER"
    
    # Check if port is correctly mapped
    if docker port $N8N_CONTAINER 2>/dev/null | grep -q "5678"; then
        PORT_MAPPING=$(docker port $N8N_CONTAINER 2>/dev/null | grep "5678")
        log "Port mapping: $PORT_MAPPING"
    else
        log "WARNING: Port 5678 not mapped correctly. Attempting to fix..."
        
        # Restart with corrected port mapping
        cd "$N8N_DATA_DIR" && docker compose down && docker compose up -d
        
        sleep 5
        
        if docker ps | grep -q n8n; then
            N8N_CONTAINER=$(docker ps | grep n8n | awk '{print $1}')
            if docker port $N8N_CONTAINER 2>/dev/null | grep -q "5678"; then
                PORT_MAPPING=$(docker port $N8N_CONTAINER 2>/dev/null | grep "5678")
                log "Port mapping fixed: $PORT_MAPPING"
            else
                log "ERROR: Failed to fix port mapping."
            fi
        else
            log "ERROR: Failed to restart n8n container."
        fi
    fi
else
    log "ERROR: n8n container failed to start. Checking logs..."
    cd "$N8N_DATA_DIR" && docker compose logs >> "$LOG_FILE" 2>&1
    
    # Try alternative approach with simple docker run
    log "Trying alternative approach with direct docker run..."
    docker run -d --name n8n \
      -p 5678:5678 \
      -e N8N_HOST=0.0.0.0 \
      -e N8N_PORT=5678 \
      -e WEBHOOK_URL=http://${SERVER_IP}:5678/ \
      -e N8N_PROTOCOL=http \
      -e N8N_USER_MANAGEMENT_DISABLED=false \
      -e N8N_BASIC_AUTH_ACTIVE=true \
      -e N8N_BASIC_AUTH_USER=admin \
      -e N8N_BASIC_AUTH_PASSWORD=${ADMIN_PASSWORD} \
      -e N8N_SECURE_COOKIE=false \
      -v ${N8N_DATA_DIR}/n8n_data:/home/node/.n8n \
      n8nio/n8n:latest
      
    sleep 10
    
    if docker ps | grep -q n8n; then
        log "Alternative approach successful. n8n container is now running."
    else
        log "ERROR: Both approaches failed to start n8n container."
    fi
fi

# Try to connect to n8n from inside the container
if docker ps --format '{{.Names}}' | grep -q "n8n"; then
    N8N_CONTAINER=$(docker ps -f name=n8n --format '{{.ID}}')
    log "Testing n8n from inside the container..."
    
    # Install curl in container if needed
    docker exec $N8N_CONTAINER sh -c "apt-get update && apt-get install -y curl > /dev/null 2>&1 || apk add --no-cache curl > /dev/null 2>&1 || true"
    
    sleep 5
    
    if docker exec $N8N_CONTAINER curl -s -o /dev/null -w "%{http_code}" http://localhost:5678/ > /dev/null 2>&1; then
        RESP_CODE=$(docker exec $N8N_CONTAINER curl -s -o /dev/null -w "%{http_code}" http://localhost:5678/)
        log "n8n is responding inside container with status code: $RESP_CODE"
    else
        log "WARNING: n8n is not responding inside container."
    fi
    
    # Test port visibility
    log "Testing external port visibility..."
    if command -v nc >/dev/null 2>&1; then
        if nc -z -v -w5 $SERVER_IP 5678 >> "$LOG_FILE" 2>&1; then
            log "✅ Port 5678 is externally visible"
        else
            log "❌ Port 5678 is NOT externally visible"
        fi
    elif command -v nmap >/dev/null 2>&1; then
        if nmap -p 5678 $SERVER_IP | grep -q "open"; then
            log "✅ Port 5678 is externally visible"
        else
            log "❌ Port 5678 is NOT externally visible"
        fi
    else
        log "Installing netcat for network testing..."
        if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
            apt-get install -y netcat-openbsd > /dev/null 2>&1
        elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]] || [[ "$OS" == *"Fedora"* ]]; then
            yum install -y nc > /dev/null 2>&1
        elif [[ "$OS" == *"SUSE"* ]]; then
            zypper install -y netcat > /dev/null 2>&1
        fi
        
        if nc -z -v -w5 $SERVER_IP 5678 >> "$LOG_FILE" 2>&1; then
            log "✅ Port 5678 is externally visible"
        else
            log "❌ Port 5678 is NOT externally visible"
        fi
    fi
fi

# Final summary
log "========================================"
log "n8n Installation Summary:"
log "- n8n URL: http://$SERVER_IP:5678"
log "- Admin username: admin"
log "- Admin password: $ADMIN_PASSWORD"
log "- Data directory: $N8N_DATA_DIR"
log "- Logs and credentials saved to: $LOG_FILE"
log "========================================"

# Use docker ps with --format to avoid potential grep issues
if docker ps --format '{{.Names}}' | grep -q "n8n"; then
    log "✅ Installation successful! n8n is running and should be accessible at http://$SERVER_IP:5678"
else
    log "❌ Installation encountered issues. Please check $LOG_FILE for details."
fi

# Provide quick access URL
echo ""
echo "====================================================="
echo "
