import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robostream/services/lg_service.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginInitial());

  Future<void> login({
    required String lgIpAddress,
    required String lgUsername,
    required String lgPassword,
  }) async {
    emit(LoginInProgress()); // Cambiado de LoginLoading a LoginInProgress

    if (lgIpAddress.isEmpty ||
        lgUsername.isEmpty ||
        lgPassword.isEmpty) {
      emit(const LoginFailure('Por favor, rellena todos los campos.'));
      return;
    }

    try {
      // Lógica de Conexión
      final lgService = LGService(
        host: lgIpAddress,
        username: lgUsername,
        password: lgPassword,
      );

      final bool isConnected = await lgService.connect();

      if (isConnected) {
        await lgService.showLogoUsingKML();
        emit(LoginSuccess());
      } else {
        emit(const LoginFailure('No se pudo conectar a Liquid Galaxy. Verifica los datos.'));
      }
        } catch (e) {
      emit(LoginFailure('Error de conexión: ${e.toString()}'));
        }
  }
}