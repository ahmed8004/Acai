#!/usr/bin/env python3
"""
AC AI Project Generator
Generates the complete AC AI Android project structure and source files.
"""

import os
import shutil
import sys
from pathlib import Path

PROJECT_NAME = "ac_ai"
PROJECT_STRUCTURE = {
    "android/app/src/main/kotlin/com/ac/ai": ["services", "bridge", "receiver", "util"],
    "android/app/src/main/res": ["drawable", "drawable-v24", "layout", "mipmap-hdpi", 
                                  "mipmap-mdpi", "mipmap-xhdpi", "mipmap-xxhdpi", 
                                  "mipmap-xxxhdpi", "values", "xml"],
    "android/app/src/main/res/raw": [],
    "android/app/src/profile": [],
    "android/app/src/debug": [],
    "android/gradle/wrapper": [],
    "lib/core/constants": [],
    "lib/core/theme": [],
    "lib/core/utils": [],
    "lib/data/database": [],
    "lib/data/models": [],
    "lib/data/repositories": [],
    "lib/services": [],
    "lib/ai": [],
    "lib/bridge": [],
    "lib/ui/screens": [],
    "lib/ui/widgets": [],
    "lib/ui/providers": [],
    "lib/automation": [],
    "assets/images": [],
    "assets/animations": [],
    "assets/models": [],
    "assets/sounds": [],
    "assets/fonts": [],
    "test": [],
}

def create_directories(project_root: Path):
    """Create all project directories."""
    print("Creating directory structure...")
    
    for base_path, subdirs in PROJECT_STRUCTURE.items():
        full_path = project_root / base_path
        full_path.mkdir(parents=True, exist_ok=True)
        
        for subdir in subdirs:
            (full_path / subdir).mkdir(parents=True, exist_ok=True)
    
    # Create additional files
    (project_root / ".metadata").touch()
    (project_root / "analysis_options.yaml").touch()
    
    print("Directory structure created.")

def generate_pubspec_yaml(project_root: Path):
    """Generate pubspec.yaml file."""
    content = '''name: ac_ai
description: AC AI - Android Technical Power User Assistant
version: 1.0.0+1
publish_to: 'none'

environment:
  sdk: '>=3.2.0 <4.0.0'
  flutter: '>=3.16.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.6
  flutter_riverpod: ^2.4.9
  sqflite: ^2.3.0
  path: ^1.8.3
  path_provider: ^2.1.1
  dio: ^5.4.0
  http: ^1.1.0
  speech_to_text: ^6.5.1
  flutter_tts: ^3.8.5
  permission_handler: ^11.1.0
  device_info_plus: ^9.1.1
  package_info_plus: ^5.0.1
  flutter_local_notifications: ^16.3.0
  file_picker: ^6.1.1
  image_picker: ^1.0.7
  pdf: ^3.10.4
  syncfusion_flutter_pdf: ^24.1.41
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.2
  flutter_svg: ^2.0.9
  lottie: ^3.0.0
  intl: ^0.18.1
  uuid: ^4.2.1
  url_launcher: ^6.2.2
  connectivity_plus: ^5.0.2
  google_mlkit_text_recognition: ^0.11.0
  usb_serial: ^0.5.1
  battery_plus: ^5.0.2
  flutter_blue_plus: ^1.29.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/animations/
    - assets/sounds/
    - assets/fonts/
'''
    
    with open(project_root / "pubspec.yaml", "w") as f:
        f.write(content)
    print("Generated pubspec.yaml")

def main():
    """Main entry point."""
    if len(sys.argv) > 1:
        project_root = Path(sys.argv[1]).resolve() / PROJECT_NAME
    else:
        project_root = Path.cwd() / PROJECT_NAME
    
    print(f"AC AI Project Generator")
    print(f"Target directory: {project_root}")
    print()
    
    # Remove existing project if it exists
    if project_root.exists():
        print("Removing existing project...")
        shutil.rmtree(project_root)
    
    # Create project structure
    project_root.mkdir(parents=True, exist_ok=True)
    create_directories(project_root)
    generate_pubspec_yaml(project_root)
    
    print()
    print("=" * 50)
    print("Project generation complete!")
    print(f"Project location: {project_root}")
    print()
    print("Next steps:")
    print(f"  1. cd {PROJECT_NAME}")
    print("  2. flutter pub get")
    print("  3. Copy all source files from the repository")
    print("  4. flutter build apk --release")
    print("=" * 50)

if __name__ == "__main__":
    main()
