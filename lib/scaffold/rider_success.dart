import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:foodlion/models/food_model.dart';
import 'package:foodlion/models/order_user_model.dart';
import 'package:foodlion/models/user_model.dart';
import 'package:foodlion/models/user_shop_model.dart';
import 'package:foodlion/scaffold/home.dart';
import 'package:foodlion/utility/my_api.dart';
import 'package:foodlion/utility/my_style.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';

class RiderSuccess extends StatefulWidget {
  final OrderUserModel orderUserModel;
  RiderSuccess({Key key, this.orderUserModel}) : super(key: key);

  @override
  _RiderSuccessState createState() => _RiderSuccessState();
}

class _RiderSuccessState extends State<RiderSuccess> {
  OrderUserModel orderUserModel;
  String nameShop, nameUser, tokenUser, idUser, idShop;
  int distance, transport, sumFood = 0;
  LatLng shopLatLng, userLatLng;
  IconData shopMarkerIcon;
  List<String> nameFoods = List();
  List<int> amounts = List();
  List<int> prices = List();
  List<int> sums = List();
  int sumPrice = 0;
  bool stateStatus = true, statusReceive = true;
  double lat, lng;
   List<String> detailFoods = List();

  @override
  void initState() {
    super.initState();
    orderUserModel = widget.orderUserModel;
    findDetailShopAnUser();
    findOrder();
    findAmound();
    findLocation();
  }

  Future<void> findLocation() async {
    LocationData myData = await locationData();
    setState(() {
      lat = myData.latitude;
      lng = myData.longitude;
    });
  }

  Future<LocationData> locationData() async {
    var location = Location();

    try {
      return await location.getLocation();
    } catch (e) {
      return null;
    }
  }

  Future<void> findDetailShopAnUser() async {
    UserShopModel userShopModel =
        await MyAPI().findDetailShopWhereId(orderUserModel.idShop);

    UserModel userModel =
        await MyAPI().findDetailUserWhereId(orderUserModel.idUser);

    setState(() {
      nameShop = userShopModel.name;
      idShop = userShopModel.id;
      shopLatLng = LatLng(double.parse(userShopModel.lat.trim()),
          double.parse(userShopModel.lng.trim()));

      nameUser = userModel.name;
      idUser = userModel.id;
      tokenUser = userModel.token;
      userLatLng = LatLng(double.parse(orderUserModel.latUser.trim()),
          double.parse(orderUserModel.lngUser.trim()));
    });
  }

  Future<void> findAmound() async {
    String string = orderUserModel.amountFoods;
    string = string.substring(1, string.length - 1);
    List<String> strings = string.split(',');

    // int i = 0;
    for (var string in strings) {
      setState(() {
        amounts.add(int.parse(string.trim()));
      });
      // i++;
    }
  }

  Future<void> findOrder() async {
    String string = orderUserModel.idFoods;
    string = string.substring(1, string.length - 1);
    List<String> strings = string.split(',');

    for (var string in strings) {
      FoodModel foodModel = await MyAPI().findDetailFoodWhereId(string.trim());
      setState(() {
        nameFoods.add(foodModel.nameFood);
        prices.add(int.parse(foodModel.priceFood));
        detailFoods.add(foodModel.detailFood);

      });
    }
  }

  Widget successJob() => Container(
        margin: EdgeInsets.only(
          bottom: 120.0,
        ),
        child: FloatingActionButton(
          backgroundColor: statusReceive ? Colors.red : Colors.purple,
          onPressed: () {
            if (statusReceive) {
              confirmReceiveFood();
            } else {
              confirmSuccessDialog();
            }
          },
          child: stateStatus
              ? Icon(Icons.store_mall_directory)
              : Icon(Icons.account_box),
        ),
      );

  Future<Null> confirmReceiveFood() async {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('รับอาหารจากร้านค้าแล้ว!!'),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              OutlineButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    statusReceive = false;
                    sendNotiToUser();
                  });
                },
                icon: Icon(
                  Icons.check,
                  color: Colors.green,
                ),
                label: Text('รับอาหารเรียบร้อย'),
              ),
              OutlineButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.clear,
                  color: Colors.red,
                ),
                label: Text('ยังไม่ถึง กำลังไป'),
              )
            ],
          )
        ],
      ),
    );
  }

  Future<Null> confirmSuccessDialog() async {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('ส่งอาหารถึงลูกค้าแล้ว ^^'),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              OutlineButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  editOrderSuccess();
                },
                icon: Icon(
                  Icons.check,
                  color: Colors.green,
                ),
                label: Text('ส่งเรียบร้อย'),
              ),
              OutlineButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.clear,
                  color: Colors.red,
                ),
                label: Text('ยังไม่ถึง กำลังไป'),
              )
            ],
          )
        ],
      ),
    );
  }

  Future<Null> editOrderSuccess() async {
    String url =
        'http://movehubs.com/app/editOrderWhereIdRider.php?isAdd=true&id=${orderUserModel.id}&Success=Success';
    await Dio().get(url).then((value) {
      print(
          'value from orderSuccess ################===========>>>>> $value and tokenUser ---->>> $tokenUser');
      MyAPI().notificationAPI(tokenUser, 'รับอาหารเรียบร้อย',
          'SEND ส่งอาหารเรียบร้อย ขอบคุณที่ใช้บริการครับ');

      // exit(0);

      MaterialPageRoute route = MaterialPageRoute(
        builder: (context) => Home(),
      );
      Navigator.pushAndRemoveUntil(context, route, (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: successJob(),
      appBar: AppBar(
        title: Text(
          'GO ร้าน$nameShop',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2.0),
        ),
      ),
      body: Column(
        children: <Widget>[
          //MyStyle().showTitle(nameShop == null ? '' : nameShop),
          // Text('${orderUserModel.idShop}'),
          showListOrder(),
          showSumFood(),
          showSumDistance(),
          sumTotalPrice(),
          Expanded(
            child: Container(
              child: lat == null || shopLatLng == null || userLatLng == null
                  ? MyStyle().showProgress()
                  : showMap(),
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Marker shopMarker() {
    return Marker(
      onTap: () {
        print('You Tap Shop');
        confirmCallShop(nameShop, 'Shop', idShop);
      },
      markerId: MarkerId('shopID'),
      icon: BitmapDescriptor.defaultMarkerWithHue(100.0),
      position: shopLatLng,
      infoWindow: InfoWindow(
        title: 'ร้านที่ต้องไปรับอาหาร',
        snippet: nameShop,
      ),
    );
  }

  Marker userMarker() {
    return Marker(
      onTap: () {
        confirmCall(nameUser, 'User', idUser);
      },
      markerId: MarkerId('userID'),
      icon: BitmapDescriptor.defaultMarkerWithHue(310.0),
      position: userLatLng,
      infoWindow: InfoWindow(
        title: 'สถานที่ส่งอาหาร',
        snippet: nameUser,
      ),
    );
  }

  Future<Null> confirmCallShop(
      String nameCall, String type, String idCall) async {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('คุณต้องการโทรหาร $nameCall'),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              OutlineButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await MyAPI().findPhone(idShop, 'Shop').then((value) {
                      callPhoneThread(value);
                    });
                  },
                  icon: Icon(
                    Icons.phone,
                    color: Colors.green,
                  ),
                  label: Text('โทร')),
              OutlineButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.clear,
                    color: Colors.red,
                  ),
                  label: Text('ไม่โทร')),
            ],
          )
        ],
      ),
    );
  }

  Future<Null> confirmCall(String nameCall, String type, String idCall) async {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('คุณต้องการโทรหา $nameCall'),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              OutlineButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await MyAPI().findPhone(idUser, 'User').then((value) {
                      callPhoneThread(value);
                    });
                  },
                  icon: Icon(
                    Icons.phone,
                    color: Colors.green,
                  ),
                  label: Text('โทร')),
              OutlineButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.clear,
                    color: Colors.red,
                  ),
                  label: Text('ไม่โทร')),
            ],
          )
        ],
      ),
    );
  }

  Set<Marker> myMarker() {
    return <Marker>[shopMarker(), userMarker()].toSet();
  }

  GoogleMap showMap() {
    CameraPosition cameraPosition = CameraPosition(
      target: LatLng(lat, lng),
      zoom: 16.0,
    );
    return GoogleMap(
      myLocationEnabled: true,
      initialCameraPosition: cameraPosition,
      mapType: MapType.normal,
      onMapCreated: (controller) {},
      markers: myMarker(),
    );
  }

  Widget showListOrder() => ListView.builder(
        shrinkWrap: true,
        physics: ScrollPhysics(),
        itemCount: nameFoods.length,
        itemBuilder: (value, index) => Container(
          padding: EdgeInsets.only(left: 16.0),
          child: Column(
            children: [
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          nameFoods[index],
                          style: MyStyle().h2NormalStyleGrey,
                        ),
                        Text(
                      detailFoods[index],
                      style: TextStyle(fontSize: 16,color: Colors.grey,letterSpacing: 1)
                    ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      amounts[index].toString(),
                      style: MyStyle().h2NormalStyleGrey,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      prices[index].toString(),
                      style: MyStyle().h2NormalStyleGrey,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${amounts[index] * prices[index]}',
                      style: MyStyle().h2NormalStyleGrey,
                    ),
                  ),
                ],
              ),
              
              // Row(mainAxisAlignment: MainAxisAlignment.end,
              //   children: [
              //     Text('ค่าขนส่ง ',style: MyStyle().h2NormalStyle,),
              //     Text(
              //       orderUserModel.totalDelivery,
              //             style: MyStyle().h2NormalStyle,
              //     ),
              //    Text(' บาท',style: MyStyle().h2NormalStyle,),
              //   ],
              // ),
              //  Row(mainAxisAlignment: MainAxisAlignment.end,
              //   children: [
              //     Text('รวมทั้งหมด ',style: MyStyle().h2NormalStyle,),
              //     Text(
              //       orderUserModel.sumTotal,
              //             style: MyStyle().h2NormalStyle,
              //     ),
              //    Text(' บาท',style: MyStyle().h2NormalStyle,),
              //   ],
              // ),
            ],
          ),
        ),
      );

      Widget showSumDistance() => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Text(
              'ค่าขนส่ง  ',
              style: MyStyle().h2StylePrimary,
            ),
            Text(
              '${orderUserModel.totalDelivery}',
              style: MyStyle().h2StylePrimary,
            ),
          ],
        ),
      );

  Widget sumTotalPrice() => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Text(
              'รวม  ',
              style: MyStyle().h2StylePrimary,
            ),
            Text(
              '${orderUserModel.sumTotal}',
              style: MyStyle().h2StylePrimary,
            ),
          ],
        ),
      );

  Widget showSumFood() => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Text(
              'ค่าอาหาร  ',
              style: MyStyle().h2StylePrimary,
            ),
            Text(
              '${orderUserModel.totalPrice}',
              style: MyStyle().h2StylePrimary,
            ),
          ],
        ),
      );
  Future<Null> sendNotiToUser() async {
    UserModel userModel =
        await MyAPI().findDetailUserWhereId(orderUserModel.idUser);
    MyAPI().notificationAPI(userModel.token, 'RIDER รับอาหารแล้ว',
        'RIDER รับอาหารจากร้านค้าแล้ว รออีกแป๊บเดียวครับ');
  }

  Future<Null> callPhoneThread(String phoneNumber) async {
    String url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Cannot Launch $url';
    }
  }
}
