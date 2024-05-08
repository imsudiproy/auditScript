#!/bin/bash

# Load configuration from config.yaml
source config.yaml

# Path to the build script on host
build_script="./build_script.sh"

log_dir="/root/logs"
mkdir -p "$log_dir"

run_verification() {
    image_name=$1
    container_name=$(echo "$image_name" | tr ':/' '_')"_container"
    log_file="${log_dir}/$(echo "$image_name" | tr ':/' '_')_logs.txt"

    # Create container
    container_id=$(docker run -d --name "$container_name" "$image_name")

    # Copy build script from host to container
    docker cp "$build_script" "$container_id:/build_script.sh"

    # Execute build script inside the container and save logs
    if [[ "$TEST" == true ]]; then
        docker exec "$container_id" bash /build_script.sh -yt &> "$log_file"
    else
        docker exec "$container_id" bash /build_script.sh -y &> "$log_file"
    fi

    # Print logs path
    echo "Logs saved to: $log_file"

    # Delete container
    docker rm -f "$container_id"
}

for image_name in "${IMAGES[@]}"; do
    echo "Testing image: $image_name"
    run_verification "$image_name"
done
