import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:foodlion/models/user_shop_model.dart';
import 'package:foodlion/scaffold/home.dart';
import 'package:foodlion/utility/my_constant.dart';
import 'package:foodlion/utility/my_style.dart';
import 'package:foodlion/utility/normal_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInshop extends StatefulWidget {
  @override
  _SignInshopState createState() => _SignInshopState();
}

class _SignInshopState extends State<SignInshop> {
  // Field
  String user, password;
  bool isLoading = false;

  // Method
  Widget showContent() {
    return SingleChildScrollView(
      child: Container(
        alignment: Alignment(0, -0.8),
        child: Container(
          width: 250.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              MyStyle().mySizeBox(),
              MyStyle().showLogoShop(),
              MyStyle().mySizeBox(),
              TextField(
                style: MyStyle().h2NormalStyle,
                onChanged: (value) => user = value.trim(),
                decoration: InputDecoration(
                  labelText: 'Username :',
                  labelStyle: MyStyle().h3StylePrimary,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: MyStyle().primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: MyStyle().dartColor)),
                ),
              ),
              SizedBox(
                height: 16.0,
              ),
              TextField(
                style: MyStyle().h2NormalStyle,
                onChanged: (valur) => password = valur.trim(),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password :',
                  labelStyle: MyStyle().h3StylePrimary,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: MyStyle().primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: MyStyle().dartColor)),
                ),
              ),
              SizedBox(
                height: 16.0,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: isLoading ? CircularProgressIndicator() : null,
              ),
              Container(
                width: 250.0,
                child: RaisedButton.icon(
                  color: MyStyle().primaryColor,
                  onPressed: () {
                    if (user == null ||
                        user.isEmpty ||
                        password == null ||
                        password.isEmpty) {
                      normalDialog(
                          context, 'Have Space', 'Please Fill Ever Blank');
                    } else {
                      checkAuthen();
                    }
                  },
                  icon: Icon(
                    Icons.fingerprint,
                    color: Colors.white,
                  ),
                  label: Text(
                    'เข้าสู่ระบบ SHOP',
                    style: MyStyle().h2StyleWhite,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> checkAuthen() async {
    setState(() {
      isLoading = true;
    });
    String url =
        '${MyConstant().urlGetUserShopWhereUser}?isAdd=true&User=$user';

    try {
      Response response = await Dio().get(url);
      setState(() {
        isLoading = false;
      });
      if (response.toString() == 'null') {
        normalDialog(context, 'User False', 'No $user in my Database');
      } else {
        var result = json.decode(response.data);
        for (var map in result) {
          UserShopModel model = UserShopModel.fromJson(map);
          if (password == model.password) {
            successLogin(model);
          } else {
            normalDialog(
                context, 'Password False', 'Please Try Agains Password False');
          }
        }
      }
    } catch (e) {}
  }

  Future<void> successLogin(UserShopModel model) async {
    try {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      preferences.setString('id', model.id);
      preferences.setString('Name', model.name);
      preferences.setString('UrlShop', model.urlShop);
      preferences.setString('Lat', model.lat);
      preferences.setString('Lng', model.lng);
      preferences.setString('Login', 'Shop');

      MaterialPageRoute route = MaterialPageRoute(builder: (value) => Home());
      Navigator.of(context).pushAndRemoveUntil(route, (value) => false);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        showContent(),
      ],
    );
  }
}
