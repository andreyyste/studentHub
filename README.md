# 🎓 Student Hub UGM - Task & Schedule Tracker

A mobile application built with **Flutter** specifically designed to help university students (especially at Universitas Gadjah Mada) manage their academic life. This app serves as a centralized hub for tracking assignments, managing class schedules, and accessing the eLOK portal seamlessly.

## ✨ Key Features

* **📊 Smart Dashboard**: Displays the most urgent upcoming tasks and the next immediate class schedule for the day.
* **📝 Task Management**: Add, view, and complete assignments. Data is stored locally using SQLite for fast, offline access.
* **🗓️ Dynamic Class Schedule**:
    * Filter and view schedules by semester.
    * Visual indicators for "Makeup Classes" and "Cancelled Classes".
* **🌐 eLOK Portal Integration**:
    * Built-in WebView to securely browse `elok.ugm.ac.id`.
    * **Smart PDF Reader**: Automatically extracts session cookies to open eLOK PDF materials directly within the app—no external downloads or third-party apps required.
    * Support for external file downloads (ZIP, DOCX, etc.) directly to your device.

## 🛠️ Tech Stack

* **Framework**: [Flutter](https://flutter.dev/) (Dart)
* **Database**: [sqflite](https://pub.dev/packages/sqflite) (Local SQLite)
* **WebView**: [flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview)
* **PDF Viewer**: [syncfusion_flutter_pdfviewer](https://pub.dev/packages/syncfusion_flutter_pdfviewer)

## 🚀 Getting Started

Follow these instructions to set up and run the project locally on your machine.

### Prerequisites
Ensure you have the following installed and properly configured:
* [Flutter SDK](https://docs.flutter.dev/get-started/install)
* Android Studio or VS Code (with Flutter & Dart extensions)
* An Android Emulator or a physical device connected with USB Debugging enabled.

Installation Steps

**1. Clone the repository**
Open your terminal and runw:
```bash
git clone [https://github.com/manurungandre1927-cloud/studentHub.git](https://github.com/manurungandre1927-cloud/studentHub.git)y
```
2. Navigate to the project director

```bash
cd studentHub
```
3. Install dependencies
Fetch all the required Flutter packages:

```bash
flutter pub get
```
4. Run the application
Execute the following command to launch the app on your connected device/emulator:

```bash
flutter run
```
Note for Non-Developers: If you just want to use the app without compiling the code, head over to the Releases tab on the right side of this repository, download the app-release.apk file, and install it directly on your Android device.
```bash
📂 Project Structure
The codebase is modularized for better maintainability:

Plaintext
lib/
├── database_helper.dart        # SQLite configuration and CRUD operations
├── main.dart                   # Entry point and Main Dashboard Screen
├── models/
│   ├── class_schedule.dart     # Data model for schedules
│   └── student_task.dart       # Data model for tasks
└── screens/
    ├── add_edit_schedule_screen.dart
    ├── add_task_screen.dart
    ├── elok_portal_screen.dart # WebView implementation for eLOK
    ├── pdf_viewer_screen.dart  # Custom PDF Viewer with Cookie injection
    ├── schedule_screen.dart
    └── view_tasks_screen.dart
Built with ☕ to survive university deadlines.
