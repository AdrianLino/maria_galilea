class User {
  final String userId;
  final String email;
  final String nombre;
  final String primerApellido;
  final String? segundoApellido;
  final String? displayName;
  final String? profilePictureUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool esActive;
  final String? token;


  User({
    required this.userId,
    required this.email,
    required this.nombre,
    required this.primerApellido,
    this.segundoApellido,
    this.displayName,
    this.profilePictureUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.esActive,
    this.token
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    userId: json['user_id'],
    email: json['email'],
    nombre: json['nombre'],
    primerApellido: json['primer_apellido'],
    segundoApellido: json['segundo_apellido'],
    displayName: json['display_name'],
    profilePictureUrl: json['profile_picture_url'],
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
    esActive: json['es_active'],
    token: null,
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'email': email,
    'nombre': nombre,
    'primer_apellido': primerApellido,
    'segundo_apellido': segundoApellido,
    'display_name': displayName,
    'profile_picture_url': profilePictureUrl,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'es_active': esActive,
  };

  User copyWith({
    String? token,
  }) {
    return User(
      userId: userId,
      email: email,
      nombre: nombre,
      primerApellido: primerApellido,
      segundoApellido: segundoApellido,
      displayName: displayName,
      profilePictureUrl: profilePictureUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      esActive: esActive,
      token: token ?? this.token,
    );
  }

}


