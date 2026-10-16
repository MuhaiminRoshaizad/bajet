import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

import '../../../core/platform/outside_app.dart';
import '../domain/app_lock.dart';

class LocalDeviceAuth implements DeviceAuth {
  final _auth = LocalAuthentication();

  @override
  Future<bool> isAvailable() => _auth.isDeviceSupported();

  @override
  Future<AuthOutcome> authenticate({required String title, required String reason}) async {
    try {
      // The PIN screen can be an activity of its own, which sends bajet to
      // the background; that is not the owner leaving.
      final passed = await OutsideApp.run(() => _auth.authenticate(
            localizedReason: reason,
            authMessages: [AndroidAuthMessages(signInTitle: title, signInHint: 'Use your fingerprint or phone PIN')],
          ));
      return passed ? AuthOutcome.passed : AuthOutcome.failed;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.userRequestedFallback ||
        LocalAuthExceptionCode.authInProgress ||
        LocalAuthExceptionCode.uiUnavailable =>
          AuthOutcome.cancelled,
        LocalAuthExceptionCode.temporaryLockout || LocalAuthExceptionCode.biometricLockout => AuthOutcome.lockedOut,
        // Asked again, since a phone with a PIN but no fingerprint can still
        // be checked.
        LocalAuthExceptionCode.noCredentialsSet || LocalAuthExceptionCode.noBiometricsEnrolled || LocalAuthExceptionCode.noBiometricHardware =>
          await isAvailable() ? AuthOutcome.failed : AuthOutcome.unavailable,
        _ => AuthOutcome.failed,
      };
    }
  }
}
