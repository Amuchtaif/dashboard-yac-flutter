class ApiConstants {
  // Base URL for the API
  // NOTE: Use 'http://10.0.2.2/dashboard-yac/api/' for Android Emulator to access localhost
  // If testing on a real device, replace 10.0.2.2 with your machine's LAN IP address
  // e.g., 'http://192.168.1.10/dashboard-yac/api/'
  static const String baseUrl = 'http://10.0.2.2/dashboard-yac/api/';
  
  // Auth Endpoints
  static const String loginEndpoint = '${baseUrl}login.php';
}
