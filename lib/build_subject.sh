
# Create a CSR subject from the supplied values. Parameters are:
# - Country Code - 2 letter country code
# - State Name
# - Locality name
# - Organisation name
# - Organisation unit
# - Common name - usually and URI, must not be blank
# - Email
build_subject() {
    RETVAL=""

    # Country code
    if [ ! -z "$1" ]; then
        RETVAL="/C=$1"
    fi

    # State name
    if [ ! -z "$2" ]; then
        RETVAL="${RETVAL}/ST=$2"
    fi

    # Locality name
    if [ ! -z "$3" ]; then
        RETVAL="${RETVAL}/L=$3"
    fi

    # Organisation name
    if [ ! -z "$4" ]; then
        RETVAL="${RETVAL}/O=$4"
    fi

    # Organisation unit
    if [ ! -z "$5" ]; then
        RETVAL="${RETVAL}/OU=$5"
    fi

    # Common name (required)
    RETVAL="${RETVAL}/CN=$6"

    # Email
    if [ ! -z "$7" ]; then
        RETVAL="${RETVAL}/emailAddress=$7"
    fi

    echo $RETVAL
}
