
# Directory containing your Apex classes
APEX_DIR="force-app/main/default/classes"

# Function to check for System.debug statements
check_debug_statements() {
    local file=$1
    if grep -q "System.debug" "$file"; then
        echo "System.debug found in $file"
        return 1
    fi
    return 0
}

# Iterate over all Apex class files
for file in "$APEX_DIR"/*.cls; do
    check_debug_statements "$file"
    if [ $? -ne 0 ]; then
        echo "Pull request cannot be merged due to System.debug statements."
        exit 1
    fi
done

echo "No System.debug statements found. Pull request can be merged."
exit 0