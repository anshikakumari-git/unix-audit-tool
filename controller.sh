#!/bin/bash

# Find the main project directory
BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

MODULE_DIR="$BASE_DIR/modules"
REPORT_DIR="$BASE_DIR/reports"

# Function to check root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Error: Please run the audit using sudo."
        return 1
    fi
    return 0
}

# Function to execute an audit module
run_module() {
    local module_file="$1"

    if [[ ! -f "$module_file" ]]; then
        echo "Error: Module not found: $module_file"
        return 1
    fi

    echo
    echo "Running: $(basename "$module_file")"
    echo "--------------------------------------"

    if bash "$module_file"; then
        echo "Module completed successfully."
        return 0
    else
        echo "Error: Module execution failed."
        return 1
    fi
}

# Function to run all audit modules
run_complete_audit() {
    local total=3
    local successful=0
    local failed=0

    echo
    echo "======================================"
    echo "       COMPLETE SECURITY AUDIT"
    echo "======================================"

    if run_module "$MODULE_DIR/password_audit.sh"; then
        ((successful++))
    else
        ((failed++))
    fi

    if run_module "$MODULE_DIR/file_audit.sh"; then
        ((successful++))
    else
        ((failed++))
    fi

    if run_module "$MODULE_DIR/log_analyzer.sh"; then
        ((successful++))
    else
        ((failed++))
    fi

    echo
    echo "======================================"
    echo "          AUDIT SUMMARY"
    echo "======================================"
    echo "Total Modules: $total"
    echo "Successful: $successful"
    echo "Failed: $failed"
    echo "======================================"
}

# Handle the operation received from audit.sh
case "$1" in

    all)
        if ! check_root; then
            exit 1
        fi

        run_complete_audit
        ;;

    password)
        if check_root; then
            run_module "$MODULE_DIR/password_audit.sh"
        else
            exit 1
        fi
        ;;

    files)
        if check_root; then
            run_module "$MODULE_DIR/file_audit.sh"
        else
            exit 1
        fi
        ;;

    logs)
        if check_root; then
            run_module "$MODULE_DIR/log_analyzer.sh"
        else
            exit 1
        fi
        ;;

    reports)
        echo "Previous Security Audit Reports:"
        echo "--------------------------------"

        if [[ -d "$REPORT_DIR" ]]; then
            if ! find "$REPORT_DIR" -maxdepth 1 -type f -print -quit | grep -q .; then
                echo "No previous reports found."
            else
                ls -lt "$REPORT_DIR"
            fi
        else
            echo "Reports directory not found."
        fi
        ;;

    *)
        echo "Invalid controller operation!"
        exit 1
        ;;

esac
