import 'package:formz/formz.dart';

class Password extends FormzInput<String, void> {
  const Password.pure() : super.pure('');
  const Password.dirty(String value) : super.dirty(value);

  // Sin validación
  @override
  void validator(String value) => null;

  // Sin mensajes de error
  String? get errorMessage => null;
}
