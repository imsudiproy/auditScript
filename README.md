# auditScript

A Docker-based automated verification tool for testing build scripts across multiple container environments.

## Overview

auditScript simplifies testing build scripts across different Docker environments. It automates container creation, script and patch copying, optional Docker installation inside containers, script execution, and log collection.

## Prerequisites

- Docker installed and running
- Bash shell environment
- Permissions to execute scripts and create Docker containers

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/imsudiproy/auditScript.git
   cd auditScript
   ```

2. Make the script executable:
   ```bash
   chmod +x auto_verify.sh
   ```

## Configuration

All configuration is done through the `config.txt` file. The following options are available:

| Option           | Description                                               | Example Value                                 |
|------------------|-----------------------------------------------------------|-----------------------------------------------|
| `images`         | Array of Docker images to test your script on             | `("ubuntu:20.04" "ubuntu:22.04")`            |
| `test`           | Enable test execution mode                                | `false` or `true`                             |
| `user`           | User context to run the script within the container       | `test` or `root`                              |
| `build_script`   | Full path to the build script on the host machine         | `/home/user/auditScript/build_script.sh`      |
| `patch_available`| Indicates whether a patch file should be applied          | `no` or `yes`                                 |
| `patch_path`     | Full path to the patch file on the host machine           | `/home/test/patch.diff`                       |
| `install_docker` | Install Docker inside the container before running script | `no` or `yes`                                 |

## Usage

1. Edit the `config.txt` file to configure your verification options:
   ```
   images=("ubuntu:20.04" "ubuntu:22.04")  # Enter images to test on
   test=false  # set true if you want to execute test
   user=test  # User to run the script (root or test)
   build_script="/path/to/your/build_script.sh"  # Path to the build script
   patch_available="no"  # set yes if you want to apply a patch
   patch_path="/path/to/your/patch.diff"  # Path to the patch file
   install_docker="no"  # set yes to install Docker inside the container
   ```

2. Run the verification script:
   ```bash
   bash auto_verify.sh
   ```

## How It Works

1. The script reads the configuration from `config.txt`
2. For each Docker image specified:
   - Creates a container
   - Optionally installs Docker inside the container (`install_docker="yes"`)
   - Copies your build script into the container
   - If patch is enabled, copies the patch file
   - Executes the build script inside the container
   - Collects and saves logs
   - Cleans up the container

## Patch Handling

The script supports applying patches during verification:

1. Set `patch_available="yes"` in your config.txt
2. Specify the path to your patch file using `patch_path`
3. The script will:
   - Validate the patch file exists
   - Copy the patch to the container
   - The patch will be placed in the same directory as the build script

This is useful for testing temporary fixes or modifications without altering the original build script.

## Docker Installation Inside Container

If `install_docker="yes"` is set, the script will attempt to install Docker inside each container before running your build script. This is useful for build scripts that require Docker commands inside the container.

Supported distros: Ubuntu, RHEL/CentOS, SLES/SUSE.

## Log Files

Logs for each container execution are saved in the `/root/logs/` directory with filenames derived from the Docker image name (special characters converted to underscores).

## Troubleshooting

### Common Issues

1. **"Config file not found"**
   - Ensure `config.txt` is in the same directory as the script

2. **"Build script path not set" or "Build script not found"**
   - Check that the `build_script` variable in config.txt points to a valid file

3. **"Patch file not found or path not set"**
   - If `patch_available` is set to "yes", ensure the `patch_path` variable points to a valid file

4. **"Failed to create container"**
   - Verify Docker is running
   - Check if you have permissions to create Docker containers
   - Ensure the specified Docker images exist or can be pulled

5. **"Build script execution failed"**
   - Check the generated log file for script-specific errors

6. **"Unsupported distro for Docker install"**
   - The script only supports Docker installation for Ubuntu, RHEL/CentOS, and SLES/SUSE. Ensure your Docker image is based on one of these distros if you want to use the Docker installation feature.
