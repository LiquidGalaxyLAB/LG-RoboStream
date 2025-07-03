import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robostream/services/lg_service.dart';
import 'package:robostream/services/lg_config_service.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginInitial());

  Future<void> login({
    required String lgIpAddress,
    required String lgUsername,
    required String lgPassword,
  }) async {
    emit(LoginInProgress());

    if (lgIpAddress.isEmpty ||
        lgUsername.isEmpty ||
        lgPassword.isEmpty) {
      emit(const LoginFailure('Por favor, rellena todos los campos.'));
      return;
    }

    try {
      final lgService = LGService(
        host: lgIpAddress,
        username: lgUsername,
        password: lgPassword,
      );

      final bool isConnected = await lgService.connect();

      if (isConnected) {
        await lgService.showLogoUsingKML();
        
        await LGConfigService.saveLGConfig(
          host: lgIpAddress,
          username: lgUsername,
          password: lgPassword,
        );
        
        emit(const LoginSuccess(message: 'Conectado exitosamente. Configuración guardada automáticamente.'));
      } else {
        emit(const LoginFailure('No se pudo conectar a Liquid Galaxy. Verifica los datos.'));
      }
        } catch (e) {
      emit(LoginFailure('Error de conexión: ${e.toString()}'));
        }
  }
}
