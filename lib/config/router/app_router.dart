import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/chat/presentation/screens/settings_screen.dart';
import '../../features/conversation/screens/chatting_screen.dart';
import '../../features/products/presentation/screens/screens.dart';
import 'app_router_notifier.dart';

final goRouterProvider = Provider((ref) {

  final goRouterNotifier = ref.read(goRouterNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: goRouterNotifier,
    routes: [
      ///* Primera pantalla
      GoRoute(
        path: '/splash',
        builder: (context, state) => const CheckAuthStatusScreen(),
      ),

      ///* Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      ///* Product Routes
      GoRoute(
        path: '/',
        builder: (context, state) => const ProductsScreen(),
      ),

      GoRoute(
        path: '/conversation',
        builder: (context, state) => ChattingScreen(),
      ),

      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) {
          final conversationId = state.queryParams['id']; // <-- la forma correcta
          return ChattingScreen(
            isDirect: false,
            //conversationId: conversationId,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => SettingsScreen(),
      ),
    ],

    redirect: (context, state) {
      
      final isGoingTo = state.subloc;
      final authStatus = goRouterNotifier.authStatus;

      if ( isGoingTo == '/splash' && authStatus == AuthStatus.checking ) return null;

      if ( authStatus == AuthStatus.notAuthenticated ) {
        if ( isGoingTo == '/login' || isGoingTo == '/register' ) return null;

        return '/login';
      }

      if ( authStatus == AuthStatus.authenticated ) {
        if ( isGoingTo == '/login' || isGoingTo == '/register' || isGoingTo == '/splash' ){
           return '/';
        }
      }


      return null;
    },
  );
});
