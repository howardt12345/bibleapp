
import 'package:firebase_remote_config/firebase_remote_config.dart';


class RemoteConfigManager {
  RemoteConfig remoteConfig;

  RemoteConfigManager(this.remoteConfig);

  Future<void> fetchConfig() async {
    try {
      await remoteConfig.fetch(expiration: const Duration(seconds: 0));
      await remoteConfig.activateFetched();
    } catch (e) {

    }
  }

  String getString(String key) => remoteConfig.getString(key);
  int getInt(String key) => remoteConfig.getInt(key);
  double getDouble(String key) => remoteConfig.getDouble(key);
  bool getBool(String key) => getBool(key);
  RemoteConfigValue getValue(String key) => remoteConfig.getValue(key);
}