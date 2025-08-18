#!/bin/bash
set -e

echo "=== Arch Container SSH Setup ==="
read -rp "Enter base username (e.g. 'alice'): " BASE

# Names derived from base
PERSIST_USER="${BASE}"
EPHEMERAL_USER="${BASE}-nopersist"
PERSIST_CONTAINER="${BASE}-arch"
EPHEMERAL_CONTAINER="${BASE}-arch-nopersist"

# Directories and scripts
LOGIN_DIR="/usr/local/bin"
PERSIST_SCRIPT="${LOGIN_DIR}/login-${PERSIST_CONTAINER}"
EPHEMERAL_SCRIPT="${LOGIN_DIR}/login-${EPHEMERAL_CONTAINER}"
PERSIST_VOLUME="/srv/${PERSIST_CONTAINER}"

echo
echo "Configuring users and containers for base: $BASE"
echo "  Persistent user: $PERSIST_USER"
echo "  Ephemeral user:  $EPHEMERAL_USER"
echo "  Persistent container: $PERSIST_CONTAINER"
echo "  Ephemeral container:  $EPHEMERAL_CONTAINER"
echo

# Ensure docker is available
if ! command -v docker >/dev/null; then
    echo "Docker is not installed or not in PATH."
    exit 1
fi

# Pull Arch image if not present
if ! docker image inspect archlinux:latest >/dev/null 2>&1; then
    echo "Pulling archlinux:latest..."
    docker pull archlinux:latest
fi

# Create persistent login script
cat > "$PERSIST_SCRIPT" <<EOF
#!/bin/bash
# Start persistent container if not already running
if ! docker ps --format '{{.Names}}' | grep -q "^${PERSIST_CONTAINER}\$"; then
    docker run -dit --name ${PERSIST_CONTAINER} \\
        -h ${PERSIST_CONTAINER} \\
        -v ${PERSIST_VOLUME}:/root \\
        archlinux:latest
fi

exec docker exec -it ${PERSIST_CONTAINER} /bin/bash
EOF
chmod +x "$PERSIST_SCRIPT"

# Create ephemeral login script
cat > "$EPHEMERAL_SCRIPT" <<EOF
#!/bin/bash
# Kill any existing ephemeral container with same name
docker rm -f ${EPHEMERAL_CONTAINER} >/dev/null 2>&1 || true

# Start a fresh ephemeral container
docker run -dit --rm --name ${EPHEMERAL_CONTAINER} \\
    -h ${EPHEMERAL_CONTAINER} \\
    archlinux:latest >/dev/null

exec docker exec -it ${EPHEMERAL_CONTAINER} /bin/bash
EOF
chmod +x "$EPHEMERAL_SCRIPT"

# Create persistent and ephemeral users
for USERNAME in "$PERSIST_USER" "$EPHEMERAL_USER"; do
    if id "$USERNAME" >/dev/null 2>&1; then
        echo "User $USERNAME already exists, skipping useradd."
    else
        echo "Creating user: $USERNAME"
        useradd -m -s "$LOGIN_DIR/login-${USERNAME}-arch" -G docker "$USERNAME"
        passwd "$USERNAME"
    fi
done

# Fix login shells
usermod -s "$PERSIST_SCRIPT" "$PERSIST_USER"
usermod -s "$EPHEMERAL_SCRIPT" "$EPHEMERAL_USER"

echo
echo "=== Setup complete ==="
echo "Users created:"
echo "  $PERSIST_USER → persistent Arch container ($PERSIST_CONTAINER)"
echo "  $EPHEMERAL_USER → ephemeral Arch container ($EPHEMERAL_CONTAINER)"
echo
echo "Your friend can now SSH as either of those users."
