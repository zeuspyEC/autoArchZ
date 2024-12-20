# AutoArchZ
This is a autoinstall for Arch users... Can use for UEFI and BIOS.

## Installation
1. Update the system packages:
```
pacman -Sy
```
2. Install `curl`:
```
pacman -S curl
```
3. Download and run the `run.sh` script:
```
curl -L https://raw.githubusercontent.com/zeuspyEC/AutoArchZeusPy/main/run.sh -o run.sh
```
4. Use dos2unix to convert file `run.py` to Unix format
```
pacman -S dos2unix
dos2unix run.sh
```
5. Run and enjoy
```
chmod +x run.sh
./run.sh
```

The script will handle the automated installation of Arch Linux on your system.

## Features
- Compatible with UEFI and BIOS systems
- Automated installation of Arch Linux
- Simplifies the installation process for new users

## Contribution
If you find any issues or have suggestions for improvements, please create an issue or submit a pull request on the GitHub repository:
https://github.com/zeuspyEC/AutoArchZeusPy

## License
This project is distributed under the MIT License. Check the `LICENSE` file for more information.
