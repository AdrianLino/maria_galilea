class ConnectedAccount {
  final String accountId;
  final String userId;
  final String serviceType; // Enum: spotify, gmail, google_home
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiryTime;
  final List<String>? scopes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConnectedAccount({
    required this.accountId,
    required this.userId,
    required this.serviceType,
    required this.accessToken,
    this.refreshToken,
    this.expiryTime,
    this.scopes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConnectedAccount.fromJson(Map<String, dynamic> json) => ConnectedAccount(
    accountId: json['account_id'],
    userId: json['user_id'],
    serviceType: json['service_type'],
    accessToken: json['access_token'],
    refreshToken: json['refresh_token'],
    expiryTime: json['expiry_time'] != null ? DateTime.parse(json['expiry_time']) : null,
    scopes: (json['scopes'] as List?)?.cast<String>(),
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'account_id': accountId,
    'user_id': userId,
    'service_type': serviceType,
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expiry_time': expiryTime?.toIso8601String(),
    'scopes': scopes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
