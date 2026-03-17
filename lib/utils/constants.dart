/// App-wide constants and helpers
library;

class AppConstants {
  AppConstants._();

  // Roles
  static const String rolePatient = 'patient';
  static const String roleDoctor = 'doctor';
  static const String roleReceptionist = 'receptionist';
  static const String roleAdmin = 'admin';

  // Queue statuses (as used in PATCH /queue/:id body)
  static const String statusWaiting = 'waiting';
  static const String statusInProgress = 'in-progress';
  static const String statusDone = 'done';
  static const String statusSkipped = 'skipped';
}

/// Color helpers, etc. could go here.
