#!/bin/bash

# File where encrypted passwords will be stored
PASSWORDS_FILE="$HOME/simp.enc"
# Optional: File for mapping website names to variable names
MAPPING_FILE="$HOME/.simple"

# Function to generate a secure password
generate_password() {
  PASSWORD=$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9!@#$%^&*()_+')
  
  # Ensure the password meets the complexity requirements
  while ! [[ "$PASSWORD" =~ [a-z] && "$PASSWORD" =~ [A-Z] && "$PASSWORD" =~ [0-9] && "$PASSWORD" =~ [\!\@\#\$\%\^\&\*\(\)_\+] ]]; do
    PASSWORD=$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9!@#$%^&*()_+')
  done
}

# Function to save password securely
save_password() {
  local var_name="$1"
  local password="$2"

  # Prompt for the master password (used for encryption)
  echo -n "Master Key: "
  read -s MASTER_PASSWORD
  echo

  # Encrypt the password using the master password (AES-256 with PBKDF2)
  echo "$password" | openssl enc -aes-256-cbc -salt -pbkdf2 -iter 10000 -pass pass:"$MASTER_PASSWORD" -out "$PASSWORDS_FILE"

  # Optional: Store a human-readable reference in a text file for mapping (useful for future reference)
  echo "$var_name=$MASTER_PASSWORD" >> "$MAPPING_FILE"
}

# Function to retrieve a password
retrieve_password() {
  local var_name="$1"

  # Ask for the master password to decrypt
  echo -n "Master Key: "
  read -s MASTER_PASSWORD
  echo

  # Decrypt the stored password using the provided master password (AES-256 with PBKDF2)
  decrypted_password=$(openssl enc -aes-256-cbc -d -salt -pbkdf2 -iter 10000 -pass pass:"$MASTER_PASSWORD" -in "$PASSWORDS_FILE")

  # Display the decrypted password
  echo "Password: $decrypted_password"
}


# Check if a website name is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: ./simp.sh <website>"
  exit 1
fi

website_name="$1"

# Check if the password already exists for this website (by checking if mapping file has entry)
if grep -q "$website_name=" "$MAPPING_FILE"; then
  retrieve_password "$website_name"
else
  # If the password doesn't exist, generate a new one
  generate_password
  echo "Password: $PASSWORD"

  # Save the new password securely with the master password
  save_password "$website_name" "$PASSWORD"

fi
