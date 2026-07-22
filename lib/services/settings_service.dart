// =================================================================
// 设置服务：使用 SharedPreferences 持久化用户配置
// =================================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyWxToken = 'wx_token';
  static const _keyDefaultPileNo = 'default_pile_no';
  static const _keyPileTagMap = 'pile_tag_map';
  static const _keyUseChargeRecord = 'use_charge_record';
  static const _keyDefaultFilter = 'default_filter';

  // 默认值
  static const String defaultWxToken =
      '068869666a7a0c9e9dd435e425399d8fffde3831';

  static const Map<String, String> defaultPileNoMap = {
    '0000288': '浙江省杭州市钱塘区经济开发区学林支路与2号大街辅路交叉口西北角杭州钱塘宝龙广场',
    '0000279': '浙江省杭州市钱塘区经济开发区学林支路与2号大街辅路交叉口西北角杭州钱塘宝龙广场',
    '0000286': '浙江省杭州市钱塘区经济开发区学林支路与2号大街辅路交叉口西北角杭州钱塘宝龙广场',
    '0000224': '浙江省杭州市钱塘区经济开发区学林支路与2号大街辅路交叉口西北角杭州钱塘宝龙广场',
    '0000280': '浙江省杭州市钱塘区经济开发区学林支路与2号大街辅路交叉口西北角杭州钱塘宝龙广场',
    '0000225': '浙江省杭州市钱塘区经济开发区学林支路与2号大街辅路交叉口西北角杭州钱塘宝龙广场',
  };

  static const Map<String, String> defaultPileTagMap = {
    '0000224': '地下室',
    '0000225': '地下室',
  };

  static const bool defaultUseChargeRecord = true;
  static const int defaultFilterIndex = 1;

  final SharedPreferences _prefs;

  SettingsService._(this._prefs);

  static Future<SettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService._(prefs);
  }

  // ========== wxToken ==========
  String get wxToken => _prefs.getString(_keyWxToken) ?? defaultWxToken;

  Future<void> setWxToken(String value) async {
    await _prefs.setString(_keyWxToken, value);
  }

  // ========== defaultPileNo ==========
  Map<String, String> get defaultPileNo {
    final json = _prefs.getString(_keyDefaultPileNo);
    if (json == null) return Map<String, String>.from(defaultPileNoMap);
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as String));
  }

  Future<void> setDefaultPileNo(Map<String, String> value) async {
    await _prefs.setString(_keyDefaultPileNo, jsonEncode(value));
  }

  // ========== pileTagMap ==========
  Map<String, String> get pileTagMap {
    final json = _prefs.getString(_keyPileTagMap);
    if (json == null) return Map<String, String>.from(defaultPileTagMap);
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as String));
  }

  Future<void> setPileTagMap(Map<String, String> value) async {
    await _prefs.setString(_keyPileTagMap, jsonEncode(value));
  }

  // ========== useChargeRecord ==========
  bool get useChargeRecord =>
      _prefs.getBool(_keyUseChargeRecord) ?? defaultUseChargeRecord;

  Future<void> setUseChargeRecord(bool value) async {
    await _prefs.setBool(_keyUseChargeRecord, value);
  }

  int get defaultFilter =>
      _prefs.getInt(_keyDefaultFilter) ?? defaultFilterIndex;

  Future<void> setDefaultFilter(int value) async {
    await _prefs.setInt(_keyDefaultFilter, value);
  }
}