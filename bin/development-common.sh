
if [[ $(id -u) -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

export cw_ROOT='/opt/clusterware'
export PATH="${cw_ROOT}/opt/ruby/bin:$PATH"
