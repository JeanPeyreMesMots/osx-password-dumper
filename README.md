# 🍎 🔓 OSX Password Cracker Script

## Overview

A bash script to retrieve user's .plist files on a macOS system and to convert the data inside it to a crackable hash format. 
(to use with John The Ripper or Hashcat)

Useful for CTFs/Pentesting/Red Teaming on macOS systems. 

## Prerequisites

- The script must be run as a root user (`sudo`)
- macOS environment (tested on a )

## Usage

```bash
sudo ./osx_password_cracker.sh OUTPUT_FILE /path/to/save/.plist
```