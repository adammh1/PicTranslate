import 'package:flutter/material.dart';
import 'package:pictranslate/screens/login_screen.dart';
import './register_screen.dart';
 
class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});
  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}
  class _LoginOrRegisterState extends State<LoginOrRegister> {
    bool showLoginPage=true;
    void toggelPages(){
      setState(() {
        showLoginPage=!showLoginPage;
      });
    }
@override
 Widget build (BuildContext context){
  if(showLoginPage){
    return LoginScreen(onTap: toggelPages,);
  }else{
    return RegisterScreen(onTap: toggelPages);
  }
 }  

}
