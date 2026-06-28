import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends Notifier<ThemeMode>{
  static const _themeKey='user_theme_mode';

  @override
  ThemeMode build(){
    _loadTheme();
    return ThemeMode.system;
  }
  Future<void> _loadTheme() async{
    final prefs=await SharedPreferences.getInstance();
    final savedTheme=prefs.getString(_themeKey);
    if(savedTheme=='light'){
      state=ThemeMode.light;
    }else if(savedTheme == 'dark') {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.system;
    }
  }
  Future<void> setThemeMode(ThemeMode mode) async{
    state=mode;
    final prefs=await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }
}

final themeProvider=NotifierProvider<ThemeNotifier,ThemeMode>((){
  return ThemeNotifier();
});