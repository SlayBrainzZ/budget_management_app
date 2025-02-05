import 'package:flutter/material.dart';
import 'package:budget_management_app/auth.dart';
import 'package:budget_management_app/pages/home_page.dart';
import 'package:budget_management_app/pages/login_register_page.dart';
import 'package:budget_management_app/MoneyGuard/home_page.dart';

class WidgetTree extends StatefulWidget{
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();

}

class _WidgetTreeState extends State<WidgetTree> {
  @override
  Widget build(BuildContext context){
    return StreamBuilder(
        stream: Auth().authStateChanges,
        builder: (context, snapshot){
          if(snapshot.hasData){
            return MyApp();
            //returnHomePage();
          } else{
            return const LoginPage();
          }
        });
  }
}