# 🚀 n8n Automated Installation Script

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Required-blue.svg)](https://www.docker.com/)
[![n8n](https://img.shields.io/badge/n8n-Latest-green.svg)](https://n8n.io/)
[![Linux](https://img.shields.io/badge/Platform-Linux-orange.svg)](https://www.linux.org/)

> **One-click automated installation and configuration of n8n workflow automation platform on Linux servers**

## 📋 Overview

This bash script provides a fully automated installation of [n8n](https://n8n.io/) - a powerful workflow automation tool that helps you connect apps and automate tasks. The script handles everything from OS detection to Docker installation, firewall configuration, and n8n deployment.

## ✨ Features

- 🔍 **Automatic OS Detection** - Supports Ubuntu, Debian, CentOS, RHEL, AlmaLinux, Rocky Linux, Oracle Linux, SUSE, and Amazon Linux
- 🐳 **Docker Auto-Installation** - Installs Docker and Docker Compose if not present
- 🔥 **Firewall Configuration** - Automatically configures UFW and firewalld
- 🔐 **Secure Setup** - Generates random admin password and enables basic authentication
- 📝 **Comprehensive Logging** - All actions logged to `/n8ninstall.log`
- 🌐 **Network Optimization** - Configures proper port mapping and webhook URLs
- 🛠️ **Troubleshooting** - Built-in error handling and alternative installation methods

## 🖥️ Recommended Server Provider

For optimal performance and global accessibility, we recommend **[MyHBD.net](https://myhbd.net)** as your server provider:

### Why MyHBD.net?
- 🌍 **Multiple Global Locations** - Choose from data centers worldwide
- ⚡ **High Performance SSD Storage** - Fast disk I/O for better n8n performance
- 🔒 **Enterprise-Grade Security** - Advanced DDoS protection and security features
- 💰 **Competitive Pricing** - Cost-effective solutions for all budgets
- 🎛️ **One-Click Deployments** - Easy server provisioning with just one click
- 📞 **24/7 Expert Support** - Round-the-clock technical assistance

**[🚀 Get Your Server at MyHBD.net](https://myhbd.net)**

## 📋 Prerequisites

- Linux server (Ubuntu, Debian, CentOS, RHEL, AlmaLinux, Rocky Linux, Oracle Linux, SUSE, or Amazon Linux)
- Root access or sudo privileges
- Internet connection
- Minimum 1GB RAM (2GB+ recommended)
- At least 10GB free disk space

## 🚀 Quick Installation

### Method 1: Direct Download & Execute
```bash
# Download and execute the script
curl -fsSL https://raw.githubusercontent.com/itsredbull/n8n-auto-installer/main/install-n8n.sh | sudo bash
```

### Method 2: Manual Download
```bash
# Download the script
wget https://raw.githubusercontent.com/itsredbull/n8n-auto-installer/main/install-n8n.sh

# Make it executable
chmod +x install-n8n.sh

# Run the script
sudo ./install-n8n.sh
```

### Method 3: Git Clone
```bash
# Clone the repository
git clone https://github.com/itsredbull/n8n-auto-installer.git
cd YOUR_REPO

# Make script executable
chmod +x install-n8n.sh

# Run the installation
sudo ./install-n8n.sh
```

## 📖 What Happens During Installation

1. **System Analysis** - Detects your Linux distribution and version
2. **Docker Installation** - Installs Docker and Docker Compose if needed
3. **Service Configuration** - Starts and enables Docker service
4. **Security Setup** - Configures firewall rules for port 5678
5. **n8n Deployment** - Creates Docker Compose configuration and starts n8n
6. **Credential Generation** - Creates secure admin credentials
7. **Health Checks** - Verifies installation and connectivity
8. **Logging** - Saves all details to `/n8ninstall.log`

## 🔐 Accessing Your n8n Instance

After successful installation, you can access n8n using:

### 🌐 Web Interface
```
http://YOUR-SERVER-IP:5678
```

**Replace `YOUR-SERVER-IP` with your actual server's IP address**

### 👤 Initial Setup
1. Open your browser and navigate to `http://YOUR-SERVER-IP:5678`
2. You'll be prompted to create your first account
3. Fill in your details:
   - **Email**: Your email address
   - **First Name**: Your first name
   - **Last Name**: Your last name
   - **Password**: Choose a strong password

> 💡 **Note**: The script creates basic authentication, but you'll need to set up your personal account on first access.

## 📄 Installation Logs & Credentials

All installation details are saved to `/n8ninstall.log`, including:
- Generated admin credentials
- Installation steps and timestamps
- Any errors or warnings encountered
- Server configuration details

To view the log:
```bash
sudo cat /n8ninstall.log
```

## 🛠️ Supported Operating Systems

| OS | Version | Status |
|---|---|---|
| Ubuntu | 18.04+ | ✅ Fully Supported |
| Debian | 9+ | ✅ Fully Supported |
| CentOS | 7+ | ✅ Fully Supported |
| RHEL | 7+ | ✅ Fully Supported |
| AlmaLinux | 8+ | ✅ Fully Supported |
| Rocky Linux | 8+ | ✅ Fully Supported |
| Oracle Linux | 7+ | ✅ Fully Supported |
| SUSE | 15+ | ✅ Fully Supported |
| Amazon Linux | 2+ | ✅ Fully Supported |

## 🔧 Post-Installation Management

### Check n8n Status
```bash
docker ps | grep n8n
```

### View n8n Logs
```bash
cd /n8n-data && docker compose logs -f
```

### Restart n8n
```bash
cd /n8n-data && docker compose restart
```

### Stop n8n
```bash
cd /n8n-data && docker compose down
```

### Start n8n
```bash
cd /n8n-data && docker compose up -d
```

## 🔥 Firewall Configuration

The script automatically configures your firewall to allow connections on port 5678:

- **UFW** (Ubuntu/Debian): `ufw allow 5678/tcp`
- **firewalld** (CentOS/RHEL): `firewall-cmd --permanent --add-port=5678/tcp`

## 📂 File Locations

- **Docker Compose Config**: `/n8n-data/docker-compose.yml`
- **n8n Data Directory**: `/n8n-data/n8n_data/`
- **Installation Log**: `/n8ninstall.log`

## 🆘 Troubleshooting

### Common Issues

**1. Port 5678 not accessible**
```bash
# Check if n8n container is running
docker ps | grep n8n

# Check firewall status
sudo ufw status  # Ubuntu/Debian
sudo firewall-cmd --list-ports  # CentOS/RHEL
```

**2. Docker not starting**
```bash
# Check Docker service
sudo systemctl status docker
sudo systemctl start docker
```

**3. Permission issues**
```bash
# Fix n8n data directory permissions
sudo chmod -R 777 /n8n-data/n8n_data/
```

### Getting Help
- Check the installation log: `sudo cat /n8ninstall.log`
- View n8n container logs: `cd /n8n-data && docker compose logs`
- Restart the installation script if needed

## 🤝 Contributing

We welcome contributions! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⭐ Support

If this script helped you, please consider:
- ⭐ Starring this repository
- 🐛 Reporting issues
- 🔧 Contributing improvements
- 💬 Sharing with others

## 🔗 Useful Links

- [n8n Official Documentation](https://docs.n8n.io/)
- [n8n Community Forum](https://community.n8n.io/)
- [Docker Documentation](https://docs.docker.com/)
- [MyHBD.net - Recommended Hosting](https://myhbd.net)

---

**Made with ❤️ for the n8n community**

> 🚀 **Ready to automate your workflows?** [Get started with MyHBD.net hosting](https://myhbd.net) and deploy n8n in minutes!
