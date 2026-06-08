@echo off
REM AC AI Project Generator for Windows
REM This script generates the complete AC AI Android project structure

setlocal enabledelayedexpansion

echo ========================================
echo AC AI Project Generator
echo ========================================
echo.

set PROJECT_ROOT=%CD%\ac_ai

if exist "%PROJECT_ROOT%" (
    echo Removing existing project...
    rmdir /s /q "%PROJECT_ROOT%"
)

echo Creating project structure...

REM Create directory structure
call :CreateDirectoryStructure

REM Generate Flutter pubspec.yaml
echo Generating pubspec.yaml...
call :GeneratePubspec

REM Generate Android build files
echo Generating Android build files...
call :GenerateAndroidBuild

REM Generate Kotlin source files
echo Generating Kotlin source files...
call :GenerateKotlinFiles

REM Generate Dart source files
echo Generating Dart source files...
call :GenerateDartFiles

echo.
echo ========================================
echo Project generation complete!
echo Project location: %PROJECT_ROOT%
echo.
echo To build the project:
echo   1. cd ac_ai
echo   2. flutter pub get
echo   3. flutter build apk --release
echo ========================================

goto :EOF

:CreateDirectoryStructure
    mkdir "%PROJECT_ROOT%\android\app\src\main\kotlin\com\ac\ai\services" >nul 2>&1
    mkdir "%PROJECT_ROOT%\android\app\src\main\kotlin\com\ac\ai\bridge" >nul 2>&1
    mkdir "%PROJECT_ROOT%\android\app\src\main\kotlin\com\ac\ai\receiver" >nul 2>&1
    mkdir "%PROJECT_ROOT%\android\app\src\main\res\drawable" >nul 2>&1
    mkdir "%PROJECT_ROOT%\android\app\src\main\res\drawable-v24" >nul 2>&1
    mkdir "%PROJECT_ROOT%\android\app\src\main\res\values" >nul 2>&1
    mkdir "%PROJECT_ROOT%\android\app\src\main\res\xml" >nul 2>&1
    mkdir "%PROJECT_ROOT%\android\gradle\wrapper" >nul 2>&1
    mkdir "%PROJECT_ROOT%\lib\core\constants" >nul 2>&1
    mkdir "%PROJECT_ROOT%\lib\core\theme" >nul 2>&1
    mkdir "%PROJECT_ROOT%\lib\core\utils" >nul 2>&1
    mkdir "%PROJECT_ROOT%\lib\data\database" >nul 2>&1
    mkdir "%PROJECT_ROOT%\lib\data\models" >nul 2>&1
    mkdir "%PROJECT_ROOT%\lib\data\repositories" >nul 2>&1
    mkdir "%PROJECT_ROOT%\lib\services" >nul 2>&1
    mkdir "%PROJECT_ROOT%\lib\ai" >nul 2>&1
    mkdir "%PROJECT_ROOT%\lib\bridge" >nul 2>&1
    mkdir "%PROJECT_ROOT%\lib\ui\screens" >nul 2>&1
    mkdir "%PROJECT_ROOT%\lib\ui\widgets" >nul 2>&1
    mkdir "%PROJECT_ROOT%\lib\ui\providers" >nul 2>&1
    mkdir "%PROJECT_ROOT%\assets\images" >nul 2>&1
    mkdir "%PROJECT_ROOT%\assets\animations" >nul 2>&1
    mkdir "%PROJECT_ROOT%\assets\models" >nul 2>&1
    mkdir "%PROJECT_ROOT%\assets\sounds" >nul 2>&1
    mkdir "%PROJECT_ROOT%\assets\fonts" >nul 2>&1
    mkdir "%PROJECT_ROOT%\test" >nul 2>&1
    exit /b

:GeneratePubspec
    (
    echo name: ac_ai
    echo description: AC AI - Android Technical Power User Assistant
    echo version: 1.0.0+1
    echo publish_to: 'none'
    echo.
    echo environment:
    echo   sdk: '>=3.2.0 ^<4.0.0'
    echo   flutter: '>=3.16.0'
    echo.
    echo dependencies:
    echo   flutter:
    echo     sdk: flutter
    echo   flutter_localizations:
    echo     sdk: flutter
    echo   cupertino_icons: ^1.0.6
    echo   flutter_riverpod: ^2.4.9
    echo   riverpod_annotation: ^2.3.0
    echo   sqflite: ^2.3.0
    echo   path: ^1.8.3
    echo   path_provider: ^2.1.1
    echo   dio: ^5.4.0
    echo   http: ^1.1.0
    echo   retrofit: ^4.0.3
    echo   json_annotation: ^4.8.1
    echo   freezed_annotation: ^2.4.1
    echo   speech_to_text: ^6.5.1
    echo   flutter_tts: ^3.8.5
    echo   permission_handler: ^11.1.0
    echo   device_info_plus: ^9.1.1
    echo   package_info_plus: ^5.0.1
    echo   flutter_local_notifications: ^16.3.0
    echo   awesome_notifications: ^0.8.2
    echo   file_picker: ^6.1.1
    echo   open_filex: ^4.3.4
    echo   image_picker: ^1.0.7
    echo   image: ^4.1.3
    echo   pdf: ^3.10.4
    echo   syncfusion_flutter_pdf: ^24.1.41
    echo   flutter_secure_storage: ^9.0.0
    echo   shared_preferences: ^2.2.2
    echo   flutter_svg: ^2.0.9
    echo   lottie: ^3.0.0
    echo   shimmer: ^3.0.0
    echo   flutter_animate: ^4.3.0
    echo   flutter_staggered_animations: ^1.1.1
    echo   intl: ^0.18.1
    echo   uuid: ^4.2.1
    echo   crypto: ^3.0.3
    echo   encrypt: ^5.0.1
    echo   background_fetch: ^1.2.1
    echo   workmanager: ^0.5.2
    echo   url_launcher: ^6.2.2
    echo   share_plus: ^7.2.1
    echo   connectivity_plus: ^5.0.2
    echo   logger: ^2.0.2
    echo   settings_ui: ^2.0.4
    echo   fl_chart: ^0.66.0
    echo   flutter_pdfview: ^1.3.2
    echo   docx_to_text: ^1.0.1
    echo   google_mlkit_text_recognition: ^0.11.0
    echo   google_mlkit_object_detection: ^0.10.0
    echo   google_mlkit_image_labeling: ^0.10.0
    echo   usb_serial: ^0.5.1
    echo   just_audio: ^0.9.36
    echo   audio_session: ^0.1.18
    echo   vibration: ^1.8.4
    echo   sensors_plus: ^4.0.2
    echo   geolocator: ^10.1.0
    echo   contacts_service: ^0.6.3
    echo   flutter_phone_direct_caller: ^2.1.1
    echo   torch_light: ^1.0.0
    echo   battery_plus: ^5.0.2
    echo   volume_controller: ^2.0.7
    echo   screen_brightness: ^0.2.2
    echo   flutter_blue_plus: ^1.29.0
    echo   wifi_iot: ^0.3.18
    echo   network_info_plus: ^4.1.0
    echo   archive: ^3.4.9
    echo   mime: ^1.0.4
    echo   jiffy: ^6.2.1
    echo.
    echo dev_dependencies:
    echo   flutter_test:
    echo     sdk: flutter
    echo   flutter_lints: ^3.0.1
    echo   build_runner: ^2.4.7
    echo   freezed: ^2.4.5
    echo   json_serializable: ^6.7.1
    echo   retrofit_generator: ^8.0.6
    echo   riverpod_generator: ^2.3.9
    echo   riverpod_lint: ^2.3.7
    echo.
    echo flutter:
    echo   uses-material-design: true
    echo   assets:
    echo     - assets/images/
    echo     - assets/animations/
    echo     - assets/models/
    echo     - assets/sounds/
    echo     - assets/fonts/
    ) > "%PROJECT_ROOT%\pubspec.yaml"
    exit /b

:GenerateAndroidBuild
    (
    echo plugins {
    echo     id "com.android.application"
    echo     id "kotlin-android"
    echo     id "dev.flutter.flutter-gradle-plugin"
    echo }
    echo.
    echo android {
    echo     namespace "com.ac.ai"
    echo     compileSdkVersion 34
    echo     ndkVersion flutter.ndkVersion
    echo.
    echo     compileOptions {
    echo         sourceCompatibility JavaVersion.VERSION_17
    echo         targetCompatibility JavaVersion.VERSION_17
    echo     }
    echo.
    echo     kotlinOptions {
    echo         jvmTarget = '17'
    echo     }
    echo.
    echo     defaultConfig {
    echo         applicationId "com.ac.ai"
    echo         minSdkVersion 24
    echo         targetSdkVersion 34
    echo         versionCode 1
    echo         versionName "1.0.0"
    echo         multiDexEnabled true
    echo     }
    echo.
    echo     buildTypes {
    echo         release {
    echo             signingConfig signingConfigs.debug
    echo             minifyEnabled true
    echo             proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    echo         }
    echo     }
    echo }
    echo.
    echo flutter {
    echo     source '../..'
    echo }
    ) > "%PROJECT_ROOT%\android\app\build.gradle"
    
    (
    echo buildscript {
    echo     ext.kotlin_version = '1.9.22'
    echo     repositories {
    echo         google()
    echo         mavenCentral()
    echo     }
    echo     dependencies {
    echo         classpath 'com.android.tools.build:gradle:8.2.0'
    echo         classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    echo     }
    echo }
    echo.
    echo allprojects {
    echo     repositories {
    echo         google()
    echo         mavenCentral()
    echo     }
    echo }
    ) > "%PROJECT_ROOT%\android\build.gradle"
    
    (
    echo org.gradle.jvmargs=-Xmx4G
    echo android.useAndroidX=true
    echo android.enableJetifier=true
    ) > "%PROJECT_ROOT%\android\gradle.properties"
    exit /b

:GenerateKotlinFiles
    echo Note: Kotlin files must be copied manually from the source repository.
    echo See android/app/src/main/kotlin/com/ac/ai/ directory.
    exit /b

:GenerateDartFiles
    echo Note: Dart files must be copied manually from the source repository.
    echo See lib/ directory for all Dart source files.
    exit /b
