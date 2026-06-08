#!/bin/bash
# AC AI Project Generator for Linux/macOS
# This script generates the complete AC AI Android project structure

set -e

PROJECT_NAME="ac_ai"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$SCRIPT_DIR/..}"

echo "========================================"
echo "AC AI Project Generator"
echo "========================================"
echo ""

cd "$PROJECT_ROOT"

# Function to create directory structure
create_directories() {
    echo "Creating directory structure..."
    
    mkdir -p android/app/src/main/kotlin/com/ac/ai/{services,bridge,receiver,util}
    mkdir -p android/app/src/main/res/{drawable,drawable-v24,layout,mipmap-hdpi,mipmap-mdpi,mipmap-xhdpi,mipmap-xxhdpi,mipmap-xxxhdpi,values,xml}
    mkdir -p android/app/src/main/res/raw
    mkdir -p android/app/src/{profile,debug}
    mkdir -p android/gradle/wrapper
    
    mkdir -p lib/core/{constants,theme,utils}
    mkdir -p lib/data/{database,models,repositories}
    mkdir -p lib/{services,ai,bridge}
    mkdir -p lib/ui/{screens,widgets,providers}
    mkdir -p lib/automation
    
    mkdir -p assets/{images,animations,models,sounds,fonts}
    mkdir -p test
    mkdir -p scripts
    
    echo "Directory structure created."
}

# Function to generate build scripts
generate_build_scripts() {
    echo "Generating build scripts..."
    
    cat > scripts/build.sh << 'EOF'
#!/bin/bash
# AC AI Build Script

set -e

echo "Building AC AI..."

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Generate code
echo "Generating code..."
dart run build_runner build --delete-conflicting-outputs

# Build APK
echo "Building APK..."
flutter build apk --release

echo "Build complete!"
echo "APK location: build/app/outputs/flutter-apk/app-release.apk"
EOF
    chmod +x scripts/build.sh
    
    cat > scripts/build_debug.sh << 'EOF'
#!/bin/bash
# AC AI Debug Build Script

set -e

echo "Building AC AI (Debug)..."

flutter pub get
flutter build apk --debug

echo "Debug build complete!"
EOF
    chmod +x scripts/build_debug.sh
    
    echo "Build scripts generated."
}

# Function to verify project structure
verify_structure() {
    echo "Verifying project structure..."
    
    required_files=(
        "pubspec.yaml"
        "analysis_options.yaml"
        "lib/main.dart"
        "android/app/src/main/AndroidManifest.xml"
        "android/app/build.gradle"
        "android/build.gradle"
    )
    
    missing=()
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing+=("$file")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "WARNING: Missing files:"
        printf '  - %s\n' "${missing[@]}"
    else
        echo "All required files present."
    fi
}

# Function to generate documentation
generate_docs() {
    echo "Generating documentation..."
    
    cat > PROJECT_STRUCTURE.md << 'EOF'
# AC AI Project Structure

## Overview
AC AI is an Android Technical Power User Assistant built with Flutter and Kotlin.

## Directory Structure

```
ac_ai/
├── android/                    # Android native code
│   ├── app/
│   │   ├── src/main/kotlin/com/ac/ai/
│   │   │   ├── services/      # Foreground service, wake word, notifications
│   │   │   ├── bridge/        # Native bridges (USB, Termux)
│   │   │   └── receiver/      # Broadcast receivers
│   │   └── ...
│   └── ...
├── lib/                       # Flutter Dart code
│   ├── core/                  # Constants, themes, utilities
│   ├── data/                  # Database, models, repositories
│   ├── services/              # Business logic services
│   ├── ai/                    # AI/ML services
│   ├── bridge/                # Platform bridges
│   ├── ui/                    # User interface
│   └── main.dart             # Entry point
├── assets/                    # Static resources
│   ├── images/
│   ├── animations/
│   ├── models/
│   ├── sounds/
│   └── fonts/
├── scripts/                   # Build scripts
└── test/                      # Unit tests
```

## Key Components

### Services
- **WakeWordService**: Porcupine-based offline wake word detection
- **STTService**: Speech-to-text with Hindi/English/Hinglish support
- **TTSService**: Text-to-speech with engine selection
- **GroqService**: AI brain integration
- **CommandRouter**: Intent detection and command routing
- **FileAgentService**: File management operations
- **DownloadManager**: Download queue management

### UI
- **HomeScreen**: Main interface with orb animation
- **SettingsScreen**: Configuration panel
- **OrbWidget**: Animated voice assistant orb

### Database
- **SQLite**: User memory, conversation history, reminders

## Build Instructions

1. Install Flutter SDK
2. Run `flutter pub get`
3. Run `flutter build apk --release`

## Features
- Wake word detection ("Hey AC", "AC", "Okay AC")
- Voice commands in multiple languages
- AI-powered responses via Groq
- File management and automation
- Termux integration
- USB device monitoring
- Accessibility automation
- Document intelligence (PDF, images)
EOF

    echo "Documentation generated."
}

# Main execution
echo "Starting project setup..."
echo ""

create_directories
generate_build_scripts
generate_docs
verify_structure

echo ""
echo "========================================"
echo "Project setup complete!"
echo ""
echo "Next steps:"
echo "  1. Ensure Flutter SDK is installed"
echo "  2. Run: flutter pub get"
echo "  3. Run: ./scripts/build.sh"
echo ""
echo "Project Structure:"
echo "  - Android native code: android/"
echo "  - Flutter code: lib/"
echo "  - Resources: assets/"
echo "  - Scripts: scripts/"
echo "========================================"
