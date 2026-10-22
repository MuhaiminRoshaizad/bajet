import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// A yes-or-no preference of this device rather than of the plan.
enum DeviceFlag {
  /// The sheet explaining wants and needs has been shown.
  kindsExplained,

  /// The user hid the tips on Insights.
  tipsHidden,
}

/// Where device flags are kept between launches.
abstract interface class DeviceFlags {
  Future<bool> isSet(DeviceFlag flag);
  Future<void> set(DeviceFlag flag, bool on);
}

/// Each set flag is an empty file of the app's own, so flags stay out of the
/// database and out of backup files, like the theme choice.
class FileDeviceFlags implements DeviceFlags {
  Future<File> _file(DeviceFlag flag) async => File('${(await getApplicationSupportDirectory()).path}/flag_${flag.name}');

  @override
  Future<bool> isSet(DeviceFlag flag) async => (await _file(flag)).exists();

  @override
  Future<void> set(DeviceFlag flag, bool on) async {
    final file = await _file(flag);
    if (on) {
      await file.writeAsString('');
    } else if (await file.exists()) {
      await file.delete();
    }
  }
}

final deviceFlagsProvider = Provider<DeviceFlags>((ref) => FileDeviceFlags());

/// Whether [DeviceFlag] is set; invalidate it after a change.
final deviceFlagProvider = FutureProvider.family<bool, DeviceFlag>((ref, flag) => ref.watch(deviceFlagsProvider).isSet(flag));
