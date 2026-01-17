# Project Feature Analysis: Dashboard YAC

## 1. Project Overview
**Dashboard YAC** is a Flutter-based mobile application designed for organizational management with a specific focus on employee attendance, permit workflows, and integrated religious resources. It utilizes a PHP backend (native) for data handling and relies on a RESTful API architecture.

## 2. Core Modules & Features

### 🔐 Authentication & Session
- **Login System**: Email and password-based authentication.
- **Session Management**: Uses `SharedPreferences` to persist user session data (User ID, Name, Unit, Division, Position Level).
- **Security**: Basic obscure text for passwords; no visible biometric integration in the current code (though UI placeholders existed previously).

### 🏠 Dashboard (Home)
The central hub of the application displaying:
- **User Summary**: Profile picture (placeholder), Name, Unit, and Department.
- **Attendance Card**: 
  - Displays current status (`BELUM_ABSEN`, `SUDAH_MASUK`, `SELESAI`).
  - Shows Check-In/Check-Out times.
  - Quick action button for "Absen Masuk" or "Absen Pulang".
  - **Geolocation**: Validates user location (Latitude/Longitude) before allowing attendance via `geolocator`.
- **Work Schedule**: Fetches and displays the specific schedule for the current day.
- **Recent Activity**: A list view of the user's latest logs or actions.
- **Notification Center**: Pull-down sheet or separate view for system notifications (using FCM).

### 📝 Permit Management (Perizinan)
A robust workflow for requesting and approving leave/permits, featuring **Role-Based Access Control (RBAC)**:
- **Employee View**:
  - **Create Permit**: Form to submit new permit requests (`PermitScreen`).
  - **My Permits**: List of own history with filters (All, Pending, Approved, Rejected).
  - **Status Tracking**: Visual indicators (Color-coded borders and badges) for permit status.
- **Manager View (Position Level ≤ 3)**:
  - **Approvals Tab**: Dedicated tab to view incoming permit requests from subordinates.
  - **Action Interface**: Ability to **Approve** or **Reject** permits directly from the app.

### 🕌 Religious Services (Menu Islami)
A suite of tools catering to spiritual needs:
- **Assunnah TV**: Video streaming feature integrated with **YouTube** (`youtube_player_flutter`). Fetches a playlist or video list from a channel.
- **Al-Quran**: Digital Quran reader (List of Surahs -> Detail view).
- **Dzikir & Doa**: Digital collection of daily prayers and dhikr.
- **Qibla Direction**: Tool to find the Qibla direction (likely using device compass sensors).

### 🔔 Notification System
- **Push Notifications**: Integrated with **Firebase Cloud Messaging (FCM)**.
- **Token Management**: Automatically retrieves FCM token and syncs it with the backend (`api/update_fcm_token.php`) on app launch.
- **UI Indicators**: Badge counter on the dashboard bell icon for unread notifications.

### 👤 Profile
- **Profile Screen**: Dedicated page for user details and likely Account settings/Logout functionality.

## 3. Technical Architecture

### Frontend (Flutter)
- **State Management**: Primarily relies on `StatefulWidget` (`setState`) and `GlobalKey` for parent-child communication (e.g., refreshing lists after actions).
- **Navigation**: Standard `Navigator.push` / `pushReplacement`. Custom Bottom Navigation Bar with animated switching.
- **Styling**: 
  - **Font**: Google Fonts (Poppins).
  - **Theme**: Consistent Blue/White color palette with rounded styling (`BorderRadius`), shadows, and gradients.
  - **Responsive**: Uses `SafeArea` and `SingleChildScrollView` to handle different screen sizes.

### Backend (PHP - Inferred)
- **API Structure**: REST-like endpoints receiving JSON or Form Data.
- **Endpoints Identified**:
  - `login.php`
  - `get_dashboard_data.php`
  - `attendance.php`
  - `get_permits.php`
  - `get_approval_list.php`
  - `action_permit.php`
  - `update_fcm_token.php`
- **Database**: Likely MySQL, handling users, permits, attendance logs, and notifications.

## 4. Current State & Observations
- **News (Berita) & Performance (Kinerja)**: These tabs in the bottom navigation are currently placeholders (`Center(child: Text(...))`).
- **Error Handling**: The app implements robust error catching for network requests (timeouts, non-200 codes) and JSON parsing errors, often displaying user-friendly SnackBars or error messages in the UI.
- **Localization**: UI text is primarily in **Indonesian**.

## 5. File Structure Highlights
- `lib/screens`: detailed implementation of each feature page.
- `lib/services`: logic separation for API calls (`AuthService`, `NotificationService`, `YoutubeService`, etc.).
- `lib/models`: Data classes for type safety (`UserModel`, `VideoModel`).
