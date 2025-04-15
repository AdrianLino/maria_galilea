import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/infrastructure/services/key_value_storage_service.dart';
import '../../../shared/infrastructure/services/key_value_storage_service_impl.dart';
import '../../domain/domain.dart';
import '../../infrastructure/infrastructure.dart';


final authProvider = StateNotifierProvider<AuthNotifier,AuthState>((ref) {

  final authRepository = AuthRepositoryImpl();
  final keyValueStorageService = KeyValueStorageServiceImpl();


  return AuthNotifier(
    authRepository: authRepository,
    keyValueStorageService: keyValueStorageService
  );
});



class AuthNotifier extends StateNotifier<AuthState> {

  final AuthRepository authRepository;
  final KeyValueStorageService keyValueStorageService;

  AuthNotifier({
    required this.authRepository,
    required this.keyValueStorageService,
  }): super( AuthState() ) {
    checkAuthStatus();
  }


  Future<void> loginUser(String email, String password) async {
    print('[loginUser] Iniciando login con:');
    print('  Email: $email');
    print('  Password: $password');

    await Future.delayed(const Duration(milliseconds: 500));
    print('[loginUser] Espera artificial de 500ms completada');

    try {
      print('[loginUser] Intentando iniciar sesión con authRepository.login...');
      final user = await authRepository.login(email, password);

      if (user == null) {
        print('[loginUser] 🚨 authRepository.login devolvió null');
        return logout('Usuario inválido');
      }

      print('[loginUser] Usuario recibido exitosamente:');
      print('  userId: ${user.userId}');
      print('  email: ${user.email}');
      print('  nombre: ${user.nombre}');
      print('  token: ${user.token}');

      _setLoggedUser(user);
      print('[loginUser] ✅ Usuario autenticado y guardado en estado');
    } on CustomError catch (e) {
      print('[loginUser] ⚠️ CustomError detectado: ${e.message}');
      logout(e.message);
    } catch (e) {
      print('[loginUser] ❌ Error NO controlado: $e');
      logout('Error no controlado');
    }
  }


  void registerUser(String email, String password, String fullName) async {
    try {
      final user = await authRepository.register(email, password, fullName);
      _setLoggedUser(user);
    } on CustomError catch (e) {
      logout(e.message);
    } catch (e) {
      logout('Error no controlado');
    }
  }


  void checkAuthStatus() async {
    final token = await keyValueStorageService.getValue<String>('token');
    if( token == null ) return logout();

    try {
      final user = await authRepository.checkAuthStatus(token);
      _setLoggedUser(user);

    } catch (e) {
      logout();
    }

  }

  void _setLoggedUser(User user) async {
    if (user.token != null) {
      await keyValueStorageService.setKeyValue('token', user.token!);
    }

    state = state.copyWith(
      user: user,
      authStatus: AuthStatus.authenticated,
      errorMessage: '',
    );
  }


  Future<void> logout([ String? errorMessage ]) async {
    
    await keyValueStorageService.removeKey('token');

    state = state.copyWith(
      authStatus: AuthStatus.notAuthenticated,
      user: null,
      errorMessage: errorMessage
    );
  }

}



enum AuthStatus { checking, authenticated, notAuthenticated }

class AuthState {

  final AuthStatus authStatus;
  final User? user;
  final String errorMessage;

  AuthState({
    this.authStatus = AuthStatus.checking, 
    this.user, 
    this.errorMessage = ''
  });

  AuthState copyWith({
    AuthStatus? authStatus,
    User? user,
    String? errorMessage,
  }) => AuthState(
    authStatus: authStatus ?? this.authStatus,
    user: user ?? this.user,
    errorMessage: errorMessage ?? this.errorMessage
  );




}