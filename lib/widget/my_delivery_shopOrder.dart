import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:foodlion/models/order_user_model.dart';
import 'package:foodlion/models/user_model.dart';
import 'package:foodlion/models/user_shop_model.dart';
import 'package:foodlion/scaffold/detailOrder.dart';
import 'package:foodlion/scaffold/home.dart';
import 'package:foodlion/utility/find_token.dart';
import 'package:foodlion/utility/my_api.dart';
import 'package:foodlion/utility/my_style.dart';
import 'package:foodlion/utility/normal_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyDeliveryShopOrder extends StatefulWidget {
  @override
  _MyDeliveryShopOrderState createState() => _MyDeliveryShopOrderState();
}

class _MyDeliveryShopOrderState extends State<MyDeliveryShopOrder> {
  // Field
  List<OrderUserModel> orderUserModels = List();
  List<String> nameShops = List();
  List<int> distances = List();
  List<int> transports = List();
  String idRider;

  // Method
  @override
  void initState() {
    super.initState();
    aboutNotification();
    updateToken();
    readOrder();
  }

  Future<Null> aboutNotification() async {
    FirebaseMessaging firebaseMessaging = FirebaseMessaging();
    firebaseMessaging.configure(
      onLaunch: (message) {
        //print('onLaunch ==> $message');
      },
      onMessage: (message) {
        // ขณะเปิดแอพอยู่
        //print('onMessage ==> $message');
        normalToast('มีแจ้งเตือนจาก SEND');
        readOrder();
      },
      onResume: (message) {
        // ปิดเครื่อง หรือ หน้าจอ
        //print('onResume ==> $message');
        readOrder();
      },
      // onBackgroundMessage: (message) {
      //   print('onBackgroundMessage ==> $message');
      // },
    );
  }

  Future<Null> updateToken() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    idRider = preferences.getString('id');
    int distance = preferences.getInt('distance');
    int transport = preferences.getInt('transport');
    String token = await findToken();

    String url =
        'http://movehubs.com/app/editTokenRiderWhereId.php?isAdd=true&id=$idRider&Token=$token';
    Response response = await Dio().get(url);
    if (response.toString() == 'true') {
      normalToast('อัพเดทตำแหน่งใหม่ สำเร็จ');
    }

    String urlGetOrderWhereIdStatus =
        'http://movehubs.com/app/getOrderWhereIdRiderStatus.php?isAdd=true&Success=$idRider';
    Response response2 = await Dio().get(urlGetOrderWhereIdStatus);
    print('res2 ##########>>>>>>>>> $response2');

    if (response2.toString() != 'null') {
      var result = json.decode(response2.data);
      for (var map in result) {
        OrderUserModel orderUserModel = OrderUserModel.fromJson(map);
        String nameShop =
            await MyAPI().findNameShopWhere(orderUserModel.idShop);
        // int distance = 1234;
        // int transport = 4321;

        MaterialPageRoute route = MaterialPageRoute(
          builder: (context) => Home(
            orderUserModel: orderUserModel,
            nameShop: nameShop,
            distance: distance,
            transport: transport,
          ),
        );
        Navigator.pushAndRemoveUntil(context, route, (route) => false);
      }
    }
  }

  Future<void> readOrder() async {
    orderUserModels.clear();
    nameShops.clear();
    distances.clear();
    transports.clear();

    //String url = 'http://movehubs.com/app/getOrderWhereStatus0.php?isAdd=true';
    String url =
        'http://movehubs.com/app/getOrderWhereSuccess.php?isAdd=true&Success=ShopOrder';
    Response response = await Dio().get(url);
    var result = json.decode(response.data);
    print('result ==>> ${result.toString()}');

    for (var map in result) {
      OrderUserModel orderUserModel = OrderUserModel.fromJson(map);

      UserModel userModel =
          await MyAPI().findDetailUserWhereId(orderUserModel.idUser);

      UserShopModel userShopModel =
          await MyAPI().findDetailShopWhereId(orderUserModel.idShop);
      String nameShop = userShopModel.name;

      double distance = MyAPI().calculateDistance(
          double.parse(userModel.lat),
          double.parse(userModel.lng),
          double.parse(userShopModel.lat),
          double.parse(userShopModel.lng));
      // print('distance ==>>> $distance');

      int distanceToInt = distance.round();
      // print('distanceToInt ==>>> $distanceToInt');

      int transport = await MyAPI().checkTransport(distanceToInt);

      setState(() {
        orderUserModels.add(orderUserModel);
        nameShops.add(nameShop);
        distances.add(distanceToInt);
        transports.add(transport);
      });
    }
  }

  ListView showContent() {
    return ListView.builder(
      itemCount: orderUserModels.length,
      itemBuilder: (value, index) => GestureDetector(
        onTap: () => rountToDetailOrder(index),
        child: Card(
          color: index % 2 == 0 ? Colors.grey.shade300 : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      ' ร้าน${nameShops[index]}',
                      style: MyStyle().h2Style,
                    ),
                    Text(
                      'เลขที่${orderUserModels[index].id}',
                      style: MyStyle().h2Style,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(' เมื่อ ${orderUserModels[index].dateTime}',
                        style: MyStyle().h2NormalStyleGrey),
                    Text(
                      '${orderUserModels[index].distance} กม.',
                      style: MyStyle().h2NormalStyleGrey,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(' ส่งที่ ${orderUserModels[index].nameLocal}',
                        style: MyStyle().h2NormalStyleGrey),
                    Icon(Icons.pin_drop, color: Colors.deepOrange,),

                        
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  rountToDetailOrder(int index) {
    MaterialPageRoute route = MaterialPageRoute(
      builder: (value) => DetailOrder(
        orderUserModel: orderUserModels[index],
        nameShop: nameShops[index],
        distance: distances[index],
        transport: transports[index],
      ),
    );
    Navigator.push(context, route).then((value) => readOrder());
  }

 Center showNoOrder() {
    return Center(
      child: Column(
        children: <Widget>[
          SizedBox(height: 150.0,),
          Image.asset('images/time.png',width: 100.0,height: 100.0,) ,
          Text(
            'ยังไม่มี ใครสั่งอาหารคะ',
            style: MyStyle().h1PrimaryStyle,
          ),
           Text(
            'โปรดรอ...',
            style: MyStyle().h1PrimaryStyle,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: orderUserModels.length == 0 ? showNoOrder() : showContent());
  }
}
