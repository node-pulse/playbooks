#!/bin/bash
# Umami - Reset Password Script
# Resets a user's password in the Umami database

set -e

INSTALL_DIR="/opt/umami"
USERNAME="admin"
PASSWORD=""

usage() {
    echo "Usage: $0 --password <password> [--username <username>]"
    echo ""
    echo "Options:"
    echo "  --password, -p    New password (required)"
    echo "  --username, -u    Username to reset (default: admin)"
    echo "  --help, -h        Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --password MySecurePassword123"
    echo "  $0 -u yumin -p MySecurePassword123"
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--password)
            PASSWORD="$2"
            shift 2
            ;;
        -u|--username)
            USERNAME="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required arguments
if [ -z "$PASSWORD" ]; then
    echo "ERROR: --password is required"
    echo ""
    usage
fi

echo "Umami Password Reset"
echo "===================="
echo ""

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q '^umami-db$'; then
    echo "ERROR: umami-db container is not running"
    echo "Start it with: cd $INSTALL_DIR && docker compose up -d"
    exit 1
fi

# Check if python3-bcrypt is available
if ! python3 -c "import bcrypt" 2>/dev/null; then
    echo "Installing python3-bcrypt..."
    apt-get update -qq && apt-get install -y -qq python3-bcrypt
fi

# Generate bcrypt hash using Python
echo "Generating password hash..."
HASH=$(python3 -c "import bcrypt; print(bcrypt.hashpw(b'$PASSWORD', bcrypt.gensalt(10)).decode())")

# Update password in PostgreSQL
echo "Updating password for user '$USERNAME'..."
docker exec umami-db psql -U umami -d umami -c "UPDATE \"user\" SET password = '$HASH' WHERE username = '$USERNAME';"

# Restart Umami to clear cached sessions
echo "Restarting Umami to clear sessions..."
cd $INSTALL_DIR && docker compose restart umami
sleep 5

echo ""
echo "Password reset complete!"
echo "========================"
echo "Username: $USERNAME"
echo "Password: (as specified)"
echo ""
echo "You can now log in at your Umami URL."
