class AppConstants {
  // Email service configuration
  static const String emailServiceId = 'service_yrz397m';
  static const String emailTemplateId = 'template_kqobk0r';
  static const String emailPublicKey = 'nIdsDTNhRs67zApkj';
  static String adminEmail = '';
  static const String defaultAdminEmail = 'zanin0431@gmail.com';
  
  // Location settings
  static const double minDistanceThreshold = 50.0; // meters
  static const double minSpeedThreshold = 0.0; // m/s
  
  // Timer settings
  static const Duration locationUpdateInterval = Duration(minutes: 5);
  static const Duration countdownInterval = Duration(seconds: 1);
  
  // UI constants
  static const double defaultPadding = 18.0;
  static const double buttonHeight = 50.0;
  static const double borderRadius = 16.0;
  static const double progressBarHeight = 12.0;
  
  // Colors
  static const int primaryColorValue = 0xFF4FC3F7;
  static const int secondaryColorValue = 0xFF00BFA5;
  static const int backgroundColorValue = 0xFF121212;
  
  // Storage keys
  static const String userIdKey = 'userId';
  static const String loginKey = 'loginKey';
  
  // Firebase collections
  static const String usersCollection = 'users';
  static const String routesCollection = 'routes';
  static const String checkpointsCollection = 'checkpoints';
  static const String liveLocationsCollection = 'live_locations';
  
  // Status messages
  static const String statusIdle = 'Idle';
  static const String statusSystemDataNotFound = 'System Data Not Found';
  static const String statusSystemDataFound = 'System Data Loaded Successfully';
  static const String statusLoadingUserData = 'Loading User Data...';
  static const String statusUpdatingLocation = 'Updating Location...';
  static const String statusLocationUpdated = 'Location Updated Successfully';
  static const String statusFailedToUpdateLocation = 'Failed to Update Location';
  static const String statusNoUserFound = 'No user found.';
  static const String statusUserDataMissing = 'User data is missing.';
  static const String statusNoRouteAssigned = 'No route has been assigned.';
  static const String statusNoCheckpoints = 'No checkpoints found for this route.';
  static const String statusRouteCompleted = 'Route is Completed.';
  static const String statusRouteLoaded = 'Route loaded.';
  static const String statusFailedToLoadUserData = 'Failed to Load User Data.';
  static const String statusSavingCheckpoint = 'Saving checkpoint';
  static const String statusCheckpointSaved = 'Checkpoint Saved Successfully';
  static const String statusFailedToSaveCheckpoint = 'Failed to Save Checkpoint';
  static const String statusTimeoutAlertingAdmin = 'Timeout: Alerting Admin';
  static const String statusTimeoutEmailSent = 'Timeout: Email Sent';
  static const String statusAllLocationsLogged = 'All locations logged successfully!';
  static const String statusEnableLocationService = 'Enable Location Service';
  static const String statusLocationPermissionDenied = 'Location Permision Denied';
  static const String statusPermissionDeniedForever = 'Permision Denied Forever';
}
