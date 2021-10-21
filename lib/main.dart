import 'package:flutter/material.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get_storage/get_storage.dart';
import '../db/db_helper.dart';
import '../services/theme_services.dart';
import '../ui/theme.dart';
import '../ui/pages/home_page.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  //NotifyHelper().initializeNotification();
  await DBHelper.initDb();
  await GetStorage.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: Themes.light,
      darkTheme: Themes.dark,
      themeMode: ThemeServices().theme,
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}