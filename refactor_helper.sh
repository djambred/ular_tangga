#!/bin/bash

# Script helper untuk refactoring main.dart
# Usage: ./refactor_helper.sh

echo "🔧 Ular Tangga Refactoring Helper"
echo "=================================="
echo ""

# Function to list all screen classes
list_screens() {
    echo "📋 Screens found in main.dart:"
    echo ""
    grep -n "^class.*Screen\|^class.*State extends State<" lib/main.dart | head -30
    echo ""
}

# Function to count lines
count_lines() {
    echo "📊 File sizes:"
    echo ""
    echo "main.dart: $(wc -l < lib/main.dart) lines"
    
    if [ -d "lib/screens" ]; then
        echo ""
        echo "Extracted screens:"
        find lib/screens -name "*.dart" -exec wc -l {} + | sort -n
    fi
    echo ""
}

# Function to check structure
check_structure() {
    echo "📁 Current structure:"
    echo ""
    tree -L 3 lib/ -I 'build|*.g.dart' 2>/dev/null || find lib -type d | sed 's|[^/]*/| |g'
    echo ""
}

# Function to find imports needed
find_imports() {
    local screen_name=$1
    echo "🔍 Imports needed for $screen_name:"
    echo ""
    
    # Common imports
    echo "import 'package:flutter/material.dart';"
    
    # Check if uses ApiService
    if grep -q "ApiService" lib/main.dart; then
        echo "import '../services/api_service.dart';"
    fi
    
    # Check if uses SocketService
    if grep -q "SocketService\|_socketService" lib/main.dart; then
        echo "import '../services/socket_service.dart';"
    fi
    
    # Check if uses Player
    if grep -q "Player(" lib/main.dart; then
        echo "import '../models/player.dart';"
    fi
    
    echo ""
}

# Function to validate
validate() {
    echo "✅ Running validation..."
    echo ""
    
    # Check if backup exists
    if [ ! -f "lib/main.dart.backup" ]; then
        echo "⚠️  No backup found. Creating backup..."
        cp lib/main.dart lib/main.dart.backup
        echo "✅ Backup created: lib/main.dart.backup"
    fi
    
    # Check directories
    if [ ! -d "lib/screens" ]; then
        echo "📁 Creating lib/screens/"
        mkdir -p lib/screens/multiplayer
    fi
    
    if [ ! -d "lib/models" ]; then
        echo "📁 Creating lib/models/"
        mkdir -p lib/models
    fi
    
    if [ ! -d "lib/widgets" ]; then
        echo "📁 Creating lib/widgets/"
        mkdir -p lib/widgets
    fi
    
    echo ""
    echo "✅ Structure validated"
    echo ""
}

# Function to run tests
run_tests() {
    echo "🧪 Running Flutter tests..."
    echo ""
    flutter analyze
    echo ""
    echo "✅ Analysis complete"
}

# Main menu
main_menu() {
    echo "Select an option:"
    echo ""
    echo "1. List all screens in main.dart"
    echo "2. Count lines (before/after)"
    echo "3. Check directory structure"
    echo "4. Validate & create directories"
    echo "5. Run Flutter analyze"
    echo "6. Create backup"
    echo "7. Exit"
    echo ""
    read -p "Enter choice [1-7]: " choice
    
    case $choice in
        1)
            list_screens
            ;;
        2)
            count_lines
            ;;
        3)
            check_structure
            ;;
        4)
            validate
            ;;
        5)
            run_tests
            ;;
        6)
            if [ -f "lib/main.dart.backup" ]; then
                echo "⚠️  Backup already exists. Overwrite? (y/n)"
                read -p "> " confirm
                if [ "$confirm" = "y" ]; then
                    cp lib/main.dart lib/main.dart.backup
                    echo "✅ Backup updated"
                fi
            else
                cp lib/main.dart lib/main.dart.backup
                echo "✅ Backup created"
            fi
            ;;
        7)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid choice"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    clear
    main_menu
}

# Run
clear
validate
main_menu
