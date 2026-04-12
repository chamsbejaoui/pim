class CommunicationPermissions {
  static bool canSendAnnouncement(String role) {
    return role == 'STAFF_TECHNIQUE' || role == 'CLUB_RESPONSABLE';
  }

  static bool canSendMedicalAlert(String role) {
    return role == 'STAFF_MEDICAL';
  }

  static bool canSendEmergency(String role) {
    return role == 'CLUB_RESPONSABLE' ||
        role == 'STAFF_TECHNIQUE' ||
        role == 'STAFF_MEDICAL';
  }

  static bool canScheduleTraining(String role) {
    return role == 'STAFF_TECHNIQUE' || role == 'CLUB_RESPONSABLE';
  }
}
