import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:foodlion/models/delivery_model.dart';
import 'package:foodlion/models/food_model.dart';
import 'package:foodlion/models/sub_food_model.dart';
import 'package:foodlion/models/user_model.dart';
import 'package:foodlion/models/user_shop_model.dart';

import 'normal_toast.dart';

class MyAPI {

  
  Future<Null> addSendLocation(
      String idUser, String lat, String lng, String nameLocation) async {
    String url =
        'http://movehubs.com/app/addSendLocation.php?isAdd=true&idUser=$idUser&Lat=$lat&Lng=$lng&NameLocation=$nameLocation';
    await Dio().get(url).then((value) => normalToast('บันทึก ที่อยู่สำเร็จ'));
  }

  Future<Null> addPhoneThread(
      String idUserShop, String type, String phone) async {
    String url =
        'http://movehubs.com/app/addPhone.php?isAdd=true&idUserShop=$idUserShop&Type=$type&Phone=$phone';
    await Dio()
        .get(url)
        .then((value) => normalToast('บันทึก เบอร์ติดต่อสำเร็จ'));
  }

  Future<String> findPhone(String idUserShop, String type) async {
    String phone;
    String url =
        'http://movehubs.com/app/getPhoneWhereIdAnType.php?isAdd=true&idUserShop=$idUserShop&Type=$type';

    Response response = await Dio().get(url);
    print('res ===>> $response');
    if (response.toString() == 'null') {
      return 'null';
    } else {
      var result = json.decode(response.data);
      for (var map in result) {
        phone = map['Phone'];
      }
      return phone;
    }
  }

  Future<Null> notificationAPI(String token, String title, String body) async {
    String url =
        'http://movehubs.com/app/apiNotification.php?isAdd=true&token=$token&title=$title&body=$body';
    try {
      Response response = await Dio().get(url);
      print('resNoti ===>> $response');
    } catch (e) {}
  }

  Future<Null> notiToRider() async {
    String urlGetAllOrderStatus0 = 'http://movehubs.com/app/getAllRider.php';
    Response response = await Dio().get(urlGetAllOrderStatus0);

    var result = json.decode(response.data);
    for (var map in result) {
      DelivaryModel delivaryModel = DelivaryModel.fromJson(map);

      if (delivaryModel.token.isNotEmpty) {
        // print('Sent Token to in aaaaa ===>> ${delivaryModel.token}');
        MyAPI().notificationAPI(delivaryModel.token,
            'ร้านค้ารับ Order', 'จะต้องไปรับอาหารครับพี่ RIDER');
      }
    }
  }

  bool checkTimeShop() {
    DateTime now = DateTime.now();
    //print('now = ${now.toString()}');
    DateTime open = now;
    DateTime close = now;
    open = DateTime(now.year, now.month, now.day, 2, 30);
    close = DateTime(now.year, now.month, now.day, 23, 00);
    //print('open = ${open.toString()}');

    if (now.isAfter(open)) {
      if (now.isBefore(close)) {
        print('ร้านเปิดครับ');
        return true;
      } else {
        print('ร้านปิดครับ');
        return false;
      }
    } else {
      print('ร้านยังไม่เปิด');
      return false;
    }
  }

  Future<Null> aboutNotification() async {
    FirebaseMessaging firebaseMessaging = FirebaseMessaging();
    firebaseMessaging.configure(
      onLaunch: (message) {
        print('onLaunch ==> $message');
      },
      onMessage: (message) {
        // ขณะเปิดแอพอยู่
        print('onMessage ==> $message');
        normalToast('มี Notification คะ');
      },
      onResume: (message) {
        // ปิดเครื่อง หรือ หน้าจอ
        print('onResume ==> $message');
      },
      onBackgroundMessage: (message) {
        print('onBackgroundMessage ==> $message');
      },
    );
  }

// นีคือ Function ในการคำนวนค่าส่งอาหาร
  Future<int> checkTransport(int distance) async {
    int transport = 0;

    String url = 'http://movehubs.com/app/getAllCheckTransport.php';

    Response response = await Dio().get(url);

    var result = json.decode(response.data);

    for (var map in result) {
      int distanceJson = int.parse(map['Distance']);
      if (distance == distanceJson) {
        transport = int.parse(map['Transport']);
      }
    }
    print(' disn === $distance transpot==== $transport');
    return transport;

    // if (distance <= 1) {
    //   transport = 19;
    //   return transport;
    // } else {
    //   transport = 19 + ((distance - 1) * 5);
    //   return transport;
    // }
  }

  Future<String> findNameShopWhere(String idShop) async {
    String string = '';
    String url =
        'http://movehubs.com/app/getShopWhereId.php?isAdd=true&id=$idShop';
    Response response = await Dio().get(url);
    var result = json.decode(response.data);
    for (var map in result) {
      string = map['Name'];
    }
    return string;
  }

  Future<SubFoodModel> getSubFoodWhereIdFood(String idFood) async {
    SubFoodModel subFoodModel;
    String url =
        'http://movehubs.com/app/getSubFoodWhereIdFood.php?isAdd=true&idFood=$idFood';
    Response response = await Dio().get(url);
    var result = json.decode(response.data);
    for (var map in result) {
      subFoodModel = SubFoodModel.fromJson(map);
    }
    return subFoodModel;
  }

  Future<FoodModel> findDetailFoodWhereId(String idFood) async {
    FoodModel foodModel;
    String url =
        'http://movehubs.com/app/getFoodWhereId.php?isAdd=true&id=$idFood';
    Response response = await Dio().get(url);
    var result = json.decode(response.data);
    for (var map in result) {
      foodModel = FoodModel.fromJson(map);
    }
    return foodModel;
  }

  Future<Map<String, dynamic>> findLocationShopWhere(String idShop) async {
    Map<String, dynamic> myMap = Map();
    String url =
        'http://movehubs.com/app/getShopWhereId.php?isAdd=true&id=$idShop';
    Response response = await Dio().get(url);
    // print('res find ==> $response');
    var result = json.decode(response.data);
    for (var map in result) {
      myMap = map;
    }
    return myMap;
  }

  Future<UserModel> findDetailUserWhereId(String id) async {
    UserModel userModel;
    String url = 'http://movehubs.com/app/getUserWhereId.php?isAdd=true&id=$id';
    Response response = await Dio().get(url);
    var result = json.decode(response.data);
    for (var map in result) {
      userModel = UserModel.fromJson(map);
    }
    return userModel;
  }

  Future<UserShopModel> findDetailShopWhereId(String idShop) async {
    UserShopModel userShopModel;
    String url =
        'http://movehubs.com/app/getUserShopWhereId.php?isAdd=true&id=$idShop';
    Response response = await Dio().get(url);
    var result = json.decode(response.data);
    for (var map in result) {
      userShopModel = UserShopModel.fromJson(map);
    }
    return userShopModel;
  }

  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    double distance = 0;

    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lng2 - lng1) * p)) / 2;
    distance = 12742 * asin(sqrt(a));

    return distance;
  }

  MyAPI();
}
