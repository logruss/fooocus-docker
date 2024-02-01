# Description: Helper functions for scripts

# Function to execute a script
execute_script() {
    local script_path=$1
    local script_msg=$2
    if [[ -f ${script_path} ]]; then
        echo "${script_msg}"
        bash ${script_path}
    fi
}

# Function to create directory if it does not exist
create_dir(){
    local dir=$1
    if [ ! -d "${dir}" ]; then
        mkdir -p "${dir}"
        sleep 2
        echo "Created directory ${dir}"
    fi
}

# Function to create a symbolic link
create_symlink() {
    local source_dir="$1"
    local target_dir="$2"
    local description="$3"

    rm -fr "$target_dir"
    ln -s "$source_dir" "$target_dir"
    echo "Symlink to $source_dir created for $description!"
}

# Function to download a file from a direct URL
download_file() {
    local file_path=$1
    local file_url=$2
    local file_name=$(basename "$file_url")
    local curl_opts="-L -o ${file_path}/${file_name}"

    # Add Authorization header if M_API_TOKEN is provided
    if [ -n "$M_API_TOKEN" ]; then
        curl_opts+=" -H 'Authorization: Bearer ${M_API_TOKEN}'"
    fi

    echo "Downloading ${file_name}..."
    eval curl $curl_opts "$file_url"
}