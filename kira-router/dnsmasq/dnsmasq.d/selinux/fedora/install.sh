#!/usr/bin/env bash

# Define the paths and filenames
TE_FILE="my-dnsmasq.te"
MOD_FILE="my-dnsmasq.mod"
PP_FILE="my-dnsmasq.pp"
MODULE_DIR="/etc/dnsmasq.d/selinux"

# Check if the policy file exists
if [ ! -f "$MODULE_DIR/$TE_FILE" ]; then
  echo "Error: $TE_FILE not found in $MODULE_DIR!"
  exit 1
fi

# Install required tools if they're not already installed
echo "Checking for required tools..."
if ! command -v checkmodule &> /dev/null || ! command -v semodule_package &> /dev/null || ! command -v semodule &> /dev/null; then
  echo "Required SELinux tools not found. Installing..."
  sudo yum install -y policycoreutils-devel
else
  echo "Required tools are already installed."
fi

# Change to the module directory
cd "$MODULE_DIR" || {
  echo "Error: Failed to change directory to $MODULE_DIR"
  exit 1
}

# Compile the .te file into a .mod file
echo "Compiling $TE_FILE into $MOD_FILE..."
checkmodule -M -m -o "$MOD_FILE" "$TE_FILE" || {
  echo "Error: Failed to compile $TE_FILE"
  exit 1
}

# Create the .pp package from the .mod file
echo "Creating $PP_FILE from $MOD_FILE..."
semodule_package -o "$PP_FILE" -m "$MOD_FILE" || {
  echo "Error: Failed to create $PP_FILE"
  exit 1
}

# Install the .pp module into SELinux
echo "Installing $PP_FILE into SELinux..."
sudo semodule -i "$PP_FILE" || {
  echo "Error: Failed to install $PP_FILE into SELinux"
  exit 1
}

# Verify that the module is installed
echo "Verifying module installation..."
if semodule -l | grep -q "my-dnsmasq"; then
  echo "Module my-dnsmasq installed successfully."
else
  echo "Error: Module my-dnsmasq not found after installation."
  exit 1
fi

# Optional: Restore SELinux file contexts
echo "Restoring SELinux file contexts..."
#sudo semanage fcontext -a -t dnsmasq_etc_t "/etc/dnsmasq.d(/.*)?"
sudo semanage fcontext -a -t dnsmasq_etc_t "/etc/dnsmasq.d/dhcp.d/dnsmasq.leases"
sudo restorecon -R -v /etc/dnsmasq.d/

echo "SELinux policy module installation complete."
