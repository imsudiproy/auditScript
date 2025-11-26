#!/bin/bash

# Ensure the config file exists and is readable
config_file="./config.txt"
if [[ ! -f "$config_file" ]]; then
    echo "Config file not found: $config_file"
    exit 1
fi

# Source the config file
source "$config_file"

# Ensure the build script variable is set
if [[ -z "$build_script" ]]; then
    echo "Build script path not set in the config file."
    exit 1
fi

# Ensure the build script exists
if [[ ! -f "$build_script" ]]; then
    echo "Build script not found: $build_script"
    exit 1
fi

# Ensure the log directory exists
log_dir="/root/logs"
mkdir -p "$log_dir"

run_verification() {
    image_name=$1
    container_name=$(echo "$image_name" | tr ':/' '_')"_container"
    log_file="${log_dir}/$(echo "$image_name" | tr ':/' '_')_logs.txt"
    # If the user is root
    script_path="/build_script.sh"
    if [ "$patch_available" == "yes" ]; then
        patch_dest_path="/diff.txt"
    fi

    # Build arg to set tests true or false
    if [ "$test" == "true" ]; then
        build_arg="yt"
    else
        build_arg="y"
    fi

    # If the user is test
    if [ "$user" == "test" ]; then
        script_path="/home/test/build_script.sh"
        if [ "$patch_available" == "yes" ]; then
            patch_dest_path="/home/test/diff.txt"
        fi
    fi

    # Create container
    container_id=$(docker run -d --privileged --name "$container_name" "$image_name")
    if [ $? -ne 0 ]; then
        echo "Failed to create container for image: $image_name" | tee -a "$log_file"
        return 1
    fi

    # Copy build script from host to container
    docker cp "$build_script" "$container_id:$script_path"
    if [ $? -ne 0 ]; then
        echo "Failed to copy build script to container: $container_id" | tee -a "$log_file"
        docker rm -f "$container_id"
        return 1
    fi

    # Handle patch if available
    if [ "$patch_available" == "yes" ]; then
        if [[ -z "$patch_path" || ! -f "$patch_path" ]]; then
            echo "Patch file not found or path not set: $patch_path" | tee -a "$log_file"
            docker rm -f "$container_id"
            return 1
        fi

        docker cp "$patch_path" "$container_id:$patch_dest_path"
        if [ $? -ne 0 ]; then
            echo "Failed to copy patch file to container: $container_id" | tee -a "$log_file"
            docker rm -f "$container_id"
            return 1
        fi
    fi

    # Determine current user inside the container
    current_container_user=$(docker exec "$container_id" whoami) || {
        echo "Failed to determine current user in container: $container_id" | tee -a "$log_file"
        docker rm -f "$container_id"
        return 1
    }
    
    if [ "$user" == "test" ] && [ "$current_container_user" != "test" ]; then
        # Only switch if not already test
        docker exec "$container_id" su - test -c "bash $script_path -$build_arg" &> "$log_file"
    else
        # Already test OR user isn't test
        docker exec "$container_id" bash $script_path -$build_arg &> "$log_file"
    fi

    if [ $? -ne 0 ]; then
        echo "Build script execution failed in container: $container_id" | tee -a "$log_file"
    else
        echo "Build script executed successfully in container: $container_id" | tee -a "$log_file"
    fi

    # Print logs path
    echo "Logs saved to: $log_file"

    # Delete container
    docker rm -f "$container_id"
}

# Ensure the images array is not empty
if [ ${#images[@]} -eq 0 ]; then
    echo "No Docker images specified in the config file."
    exit 1
fi

max_parallel="${parallel:-1}"
# Validate that parallel is a positive integer
if ! [[ "$max_parallel" =~ ^[0-9]+$ ]] || [ "$max_parallel" -lt 1 ]; then
    echo "Error: 'parallel' must be a positive integer. Got: $parallel"
    exit 1
fi

for image_name in "${images[@]}"; do
    echo "Testing image: $image_name"

    # Start in background
    run_verification "$image_name" &

    # Wait until we drop below the limit
    while [ "$(jobs -rp | wc -l)" -ge "$max_parallel" ]; do
        sleep 1
    done
done

# Wait for all background jobs to finish
wait
