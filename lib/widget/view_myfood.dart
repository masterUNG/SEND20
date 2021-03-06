import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:foodlion/models/food_model.dart';
import 'package:foodlion/models/user_shop_model.dart';
import 'package:foodlion/scaffold/home.dart';
import 'package:foodlion/utility/my_api.dart';
import 'package:foodlion/utility/my_style.dart';
import 'package:foodlion/utility/normal_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewMyFood extends StatefulWidget {
  final String idShop;
  final String nameLocalChoose, distance;
  final double lat;
  final double lng;

  ViewMyFood(
      {Key key,
      this.idShop,
      this.nameLocalChoose,
      this.lat,
      this.lng,
      this.distance})
      : super(key: key);
  @override
  _ViewMyFoodState createState() => _ViewMyFoodState();
}

class Dedouncer {
  final int milliseconds;
  VoidCallback voidCallback;
  Timer timer;

  Dedouncer({this.milliseconds});

  run(VoidCallback voidCallback) {
    if (timer != null) {
      timer.cancel();
    }
    timer = Timer(Duration(microseconds: milliseconds), voidCallback);
  }
}

class _ViewMyFoodState extends State<ViewMyFood> {
  // Field
  bool statusData = true;
  List<FoodModel> foodModels = List();
  List<UserShopModel> userShopModels = List();
  String myIdShop;
  int amount = 0;
  List<String> nameShops = List();

  UserShopModel userShopModel;

  String searchString;
  List<FoodModel> searchFoodModels = List();
  final Dedouncer dedouncer = Dedouncer(milliseconds: 500);
  String nameShop, nameLocalChoose, distance;
  double latChoose, lngChoose;

  // Method
  @override
  void initState() {
    super.initState();

    myIdShop = widget.idShop;
    nameLocalChoose = widget.nameLocalChoose;
    latChoose = widget.lat;
    lngChoose = widget.lng;
    distance = widget.distance;

    readAllFood();
  }

  Future<String> getIdShop() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String idShop = preferences.getString('id');
    return idShop;
  }

  Future<void> readAllFood() async {
    String idShop = await getIdShop();

    if (myIdShop != null) {
      idShop = myIdShop;
    }

    // print('idShop ===> $idShop');

    String url =
        'http://movehubs.com/app/getFoodWhereIdShop.php?isAdd=true&idShop=$idShop';

    Response response = await Dio().get(url);
    // print('response ===>> $response');

    if (response.toString() != 'null') {
      var result = json.decode(response.data);
      // print('result ===>>> $result');

      for (var map in result) {
        FoodModel model = FoodModel.fromJson(map);

        if (nameShop == null) {
          nameShop = await MyAPI().findNameShopWhere(model.idShop);
        }
        setState(() {
          foodModels.add(model);
          searchFoodModels = foodModels;
          userShopModel = UserShopModel.fromJson(map);
          userShopModels.add(userShopModel);
          statusData = false;
        });
      }
    }
  }

  Widget showNoData() {
    return Center(
      child: Text(
        'ไม่มีรายการอาหาร',
        style: TextStyle(fontSize: 24.0),
      ),
    );
  }

  Widget showListFood() {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              margin: EdgeInsets.only(top: 5, bottom: 5),
              child: TextField(
                onChanged: (value) {
                  dedouncer.run(() {
                    setState(() {
                      searchFoodModels =
                          foodModels.where((FoodModel foodModel) {
                        return (foodModel.nameFood
                            .toLowerCase()
                            .contains(value.toLowerCase()));
                      }).toList();
                    });
                  });
                },
                decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      size: 30.0,
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(
                            width: 0.8, color: Theme.of(context).primaryColor)),
                    hintText: 'ค้นหารายการอาหาร'),
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: ScrollPhysics(),
            itemCount: searchFoodModels.length,
            itemBuilder: (value, index) {
              return showContent(index);
            },
          ),
        ],
      ),
    );
  }

  Widget showContent(int index) {
    return GestureDetector(
      onTap: () {
        normalToast('ไม่สารถสั่งอาหารได้ครับ');
      },
      child: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.0),
              border: Border.all(
                width: 1.0,
                color: Colors.grey[200],
              ),
            ),
            child: Row(
              children: <Widget>[
                showImagefood(index),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          searchFoodModels[index].nameFood,
                          style: TextStyle(
                              fontSize: 22.0,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                        //RatingStars(),
                        SizedBox(
                          height: 4.0,
                        ),
                        Text(
                          searchFoodModels[index].detailFood,
                          style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(
                          height: 4.0,
                        ),
                        showPrice(index),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget showImagefood(int index) => ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: CachedNetworkImage(
          height: 100.0,
          width: 100.0,
          imageUrl: searchFoodModels[index].urlFood,
          placeholder: (value, string) => MyStyle().showProgress(),
          fit: BoxFit.cover,
        ),
      );

  Widget showPrice(int index) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Text(
            '${searchFoodModels[index].priceFood} บาท',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ร้าน$nameShop'),
        actions: [
          IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                MaterialPageRoute materialPageRoute = MaterialPageRoute(
                  builder: (context) => Home(),
                );
                Navigator.push(context, materialPageRoute);
              })
        ],
      ),
      body: statusData ? showNoData() : showListFood(),
    );
  }
}
