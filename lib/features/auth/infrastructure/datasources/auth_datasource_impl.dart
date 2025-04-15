import 'package:dio/dio.dart';

import '../../../../config/constants/environment.dart';
import '../../../../config/entities/user_data.dart';
import '../../domain/datasources/auth_datasource.dart';
import '../errors/auth_errors.dart';

class AuthDataSourceImpl extends AuthDataSource {
  final dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiUrl,
      connectTimeout: const Duration(seconds: 10),
    ),
  );

  @override
  Future<User> checkAuthStatus(String token) async {
    print('[checkAuthStatus] Iniciando verificación de token...');
    print('[checkAuthStatus] Token recibido: $token');

    try {
      print('[checkAuthStatus] Enviando GET a /auth/check-status...');

      final response = await dio.get(
        '/auth/check-status',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('[checkAuthStatus] ✅ Respuesta recibida: ${response.statusCode}');
      print('[checkAuthStatus] Body: ${response.data}');

      final user = User.fromJson(response.data);
      print('[checkAuthStatus] ✅ User parseado correctamente: ${user.email}');

      return user;

    } on DioException catch (e) {
      print('[checkAuthStatus] ❌ DioException atrapada');
      print('[checkAuthStatus] Código de estado: ${e.response?.statusCode}');
      print('[checkAuthStatus] Respuesta de error: ${e.response?.data}');

      if (e.response?.statusCode == 401) {
        throw CustomError('Token incorrecto');
      }
      throw Exception('Error de red o del servidor');
    } catch (e) {
      print('[checkAuthStatus] ❌ Error inesperado al parsear el usuario o procesar respuesta');
      print('[checkAuthStatus] Error: $e');
      throw Exception('Error desconocido en checkAuthStatus');
    }
  }


  @override
  Future<User> login(String email, String password) async {
    print('[AuthDataSourceImpl.login] Iniciando login...');
    print('  Email: $email');
    print('  Password: $password');

    try {
      print('[AuthDataSourceImpl.login] Enviando petición POST a /auth/login...');
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      print('[AuthDataSourceImpl.login] Respuesta recibida: ${response.statusCode}');
      print('[AuthDataSourceImpl.login] Body: ${response.data}');

      final token = response.data['access_token'];
      print('[AuthDataSourceImpl.login] Token recibido: $token');

      print('[AuthDataSourceImpl.login] Verificando token con checkAuthStatus...');
      final user = await checkAuthStatus(token);

      print('[AuthDataSourceImpl.login] Usuario recibido desde checkAuthStatus: ${user.email}');
      return user.copyWith(token: token);

    } on DioError catch (e) {
      print('[AuthDataSourceImpl.login] ❌ DioError atrapado');
      if (e.response != null) {
        print('  StatusCode: ${e.response?.statusCode}');
        print('  Response data: ${e.response?.data}');
      } else {
        print('  DioError sin respuesta del servidor');
      }

      if (e.response?.statusCode == 401) {
        throw CustomError(e.response?.data['detail'] ?? 'Credenciales incorrectas');
      }

      if (e.type == DioErrorType.connectionTimeout) {
        throw CustomError('Revisar conexión a internet');
      }

      throw Exception('[AuthDataSourceImpl.login] Error inesperado: $e');
    } catch (e) {
      print('[AuthDataSourceImpl.login] ❌ Error inesperado: $e');
      throw Exception();
    }
  }


  @override
  Future<User> register(String email, String password, String fullName) async {
    try {
      final parts = fullName.trim().split(' ');
      if (parts.length < 2) throw CustomError('Nombre completo inválido');

      final nombre = parts[0];
      final primerApellido = parts.length > 1 ? parts[1] : '';
      final segundoApellido = parts.length > 2 ? parts.sublist(2).join(' ') : null;

      final response = await dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'nombre': nombre,
        'primer_apellido': primerApellido,
        'segundo_apellido': segundoApellido,
      });

      // Luego de registrar, iniciamos sesión automáticamente
      return await login(email, password);
    } on DioError catch (e) {
      final msg = e.response?.data['detail'] ?? 'Error en el registro';
      throw CustomError(msg);
    } catch (e) {
      throw Exception();
    }
  }
}
