import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foodlion/models/order_model.dart';
import 'package:foodlion/models/order_user_model.dart';
import 'package:foodlion/models/send_location_model.dart';
import 'package:foodlion/models/user_shop_model.dart';
import 'package:foodlion/scaffold/have_problem.dart';
import 'package:foodlion/scaffold/home.dart';
import 'package:foodlion/scaffold/search_view_shop.dart';
import 'package:foodlion/scaffold/show_cart.dart';
import 'package:foodlion/utility/find_token.dart';
import 'package:foodlion/utility/my_api.dart';
import 'package:foodlion/utility/my_constant.dart';
import 'package:foodlion/utility/my_search.dart';
import 'package:foodlion/utility/my_style.dart';
import 'package:foodlion/utility/normal_dialog.dart';
import 'package:foodlion/utility/normal_toast.dart';
import 'package:foodlion/utility/sqlite_helper.dart';
import 'package:foodlion/widget/guestMap.dart';
import 'package:foodlion/widget/my_food.dart';
import 'package:foodlion/widget/notification_user.dart';
import 'package:foodlion/widget/show_order_user.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainHome extends StatefulWidget {
  @override
  _MainHomeState createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  // Field
  List<UserShopModel> userShopModels = List();
  List<UserShopModel> nearShopModels = List();

  List<Widget> showWidgets = List();

  List<Widget> searchShowWidgets = List();

  String idUser, nameLogin, nameLocalChoose = 'ตำแหน่งปัจจุบัน';
  int amount = 0;
  double lat, lng, latChoose, lngChoose;
  bool statusShowCard = false;

  List<SendLocationModeil> sendLocationModels = List();

  String choosedLocation;
  bool statusLoad = true;
  bool statusDistance = true;
  bool statusProcess = true;
  int amountOrder = 0;
  String searchShop;

  List<String> distances = List();

  // Method
  @override
  void initState() {
    super.initState();
    checkInternet();
    //myDuration();
    aboutNotification();
    editToken();
    findLatLng();
    findProcess();

    //findSendLocationWhereIdUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: userList(),
      ),
      appBar: buildAppBar(),
      body: Column(
        children: <Widget>[
          buildChooseSenLocation(context),
          statusLoad
              ? MyStyle().showProgress()
              : statusShowCard
                  ? showShop()
                  : Container(
                      child: Center(
                        child: MyStyle()
                            .showTitleH2Dark('ขออภัยคะ ไม่พบร้านอาหารใกล้คุณ'),
                      ),
                    ),
        ],
      ),
      bottomSheet:
          statusProcess ? MyStyle().mySizeBox() : buildBottomSheet(context),
    );
  }

  Future<Null> checkInternet() async {
    try {
      var result = await InternetAddress.lookup('google.com');
      if ((result.isNotEmpty) && (result[0].rawAddress.isNotEmpty)) {
        print('มี Internet');
      } else {
        print('ใน IF Inter False หรือ ไม่มี Internet');
        //routeToWarningInternet();
        //AppSettings.openDataRoamingSettings();
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => HaveProblem(),
            ),
            (route) => false);
      }
    } catch (e) {
      print('Inter False หรือ ไม่มี Internet');
      //routeToWarningInternet();
      //AppSettings.openDataRoamingSettings();
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HaveProblem(),
          ),
          (route) => false);
    }
  }

  Future<Null> myDuration() async {
    print('my Dutation ทำงาน');
    Duration duration = Duration(seconds: 12);
    await Timer(duration, () {
      if (showWidgets.length == 0) {
        //normalToast('ครบ 10 วินาทีแล้ว shopWidget.lengtho ==>0');
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => HaveProblem(),
            ),
            (route) => false);
      }
    });
  }

  Future<Null> findSendLocationWhereIdUser() async {
    //print('idUser ==>> $idUser');

    if (sendLocationModels.length != 0) {
      sendLocationModels.clear();
    }

    String url =
        'http://movehubs.com/app/getSenLocationWhereIdUser.php?isAdd=true&idUser=$idUser';
    Response response = await Dio().get(url);
    var result = json.decode(response.data);
    for (var map in result) {
      SendLocationModeil model = SendLocationModeil.fromJson(map);
      setState(() {
        sendLocationModels.add(model);
      });
    }
  }

  Future<Null> findLatLng() async {
    LocationData locationData = await findLocationData();

    setState(() {
      lat = locationData.latitude;
      lng = locationData.longitude;

      latChoose = lat;
      lngChoose = lng;

      readShopThread(lat, lng);
      checkAmount();
      findUser();
      //updateLatLng(lat, lng);
      findSendLocationWhereIdUser();
    });
  }

  Future<Null> updateLatLng(double lat, double lng) async {
    String url =
        'http://movehubs.com/app/editLatLngUserWhereId.php?isAdd=true&id=$idUser&Lat=$lat&Lng=$lng';
    Response response = await Dio().get(url);
    //print('edit $response');
  }

  Future<LocationData> findLocationData() async {
    Location location = Location();
    try {
      return await location.getLocation();
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {}
      return null;
    }
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
        normalToast('มี Notification คะ');
      },
      onResume: (message) {
        // ปิดเครื่อง หรือ หน้าจอ
        // print('onResume ==> $message');
        routeToShowOrder();
      },
      onBackgroundMessage: (message) {
        // print('onBackgroundMessage ==> $message');
      },
    );
  }

  Future<Null> findUser() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      nameLogin = preferences.getString('Name');
    });
  }

  Future<void> checkAmount() async {
    //print('checkAmount Work');
    try {
      List<OrderModel> list = await SQLiteHelper().readDatabase();
      setState(() {
        amount = list.length;
      });
    } catch (e) {}
  }

  Future<Null> editToken() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    idUser = preferences.getString('id');

    if (idUser != null) {
      String token = await findToken();
      //print('idUser = $idUser, token = $token');

      String url =
          'http://movehubs.com/app/editTokenUserWhereId.php?isAdd=true&id=$idUser&Token=$token';
      Response response = await Dio().get(url);
      if (response.toString() == 'true') {
        normalToast('อัพเดทตำแหน่งใหม่ สำเร็จ');
      }
    }
  }

  Future<void> readShopThread(double lat1, double lng1) async {
    //print('ที่อ่าน $lat1, $lng1');
    String url = MyConstant().urlGetAllShop;

    statusDistance = true;
    statusLoad = true;
    statusShowCard = false;

    try {
      await Dio().get(url).then((value) {
        var result = json.decode(value.data);
        //print('result ===>>> $result');

        if (showWidgets.length != 0) {
          showWidgets.clear();
        }

        int i = 0;

        if (nearShopModels.length != 0) {
          nearShopModels.clear();
        }

        for (var map in result) {
          i++;
          UserShopModel model = UserShopModel.fromJson(map);

          double distance = MyAPI().calculateDistance(
            lat1,
            lng1,
            double.parse(model.lat.trim()),
            double.parse(model.lng.trim()),
          );

          var myFormat = NumberFormat('##0.0#', 'en_US');

          String distanceString = myFormat.format(distance);

          setState(() {
            userShopModels.add(model);
            statusLoad = false;
            if (distance <= 400.0) {
              distances.add(distanceString);
              nearShopModels.add(model);

              statusDistance = false;
              showWidgets
                  .add(createCard(model, '${myFormat.format(distance)}'));
              searchShowWidgets = showWidgets;
              statusShowCard = true;
            }
          });
        }
      });
    } catch (e) {}
  }

  Widget showImageShop(UserShopModel model) {
    return Container(
      width: 80.0,
      height: 80.0,
      child: CircleAvatar(
        backgroundImage: NetworkImage(model.urlShop),
      ),
    );
  }

  Widget showImageShop2(UserShopModel model) => Container(
        child: CachedNetworkImage(
          height: 100.0,
          width: MediaQuery.of(context).size.width,
          imageUrl: model.urlShop,
          placeholder: (value, string) => MyStyle().showProgress(),
          fit: BoxFit.cover,
        ),
      );

  Widget createCard(UserShopModel model, String distance) {
    return GestureDetector(
      onTap: () {
        if (MyAPI().checkTimeShop()) {
          MaterialPageRoute route = MaterialPageRoute(
            builder: (cont) => MyFood(
              idShop: model.id,
              nameLocalChoose: nameLocalChoose,
              lat: latChoose,
              lng: lngChoose,
              distance: distance,
            ),
          );
          Navigator.of(context).push(route).then((value) => checkAmount());
        } else {
          normalDialog(context, 'SEND ปิดแล้ว',
              'SEND DRIVE บริการส่งเวลา 7.30- 20.00 น.');
        }
      },
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            showImageShop2(model),
            SizedBox(
              height: 4.0,
            ),
            showName(model),
            //showStatus(model),
            showDistance(distance),
          ],
        ),
      ),
    );
  }

  Widget showDistance(String distance) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        MyStyle().showRatting(),
        Text(
          '$distance กม.',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget showName(UserShopModel model) => Expanded(
        child: Text(model.name,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).primaryColor,
              letterSpacing: 2.0,
            )),
      );

  Text showStatus(UserShopModel model) => Text(model.status,
      style: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.bold,
        color: Colors.red,
        letterSpacing: 0.5,
      ));

  Widget showShop() {
    return showWidgets.length == 0
        ? MyStyle().showProgress()
        : Expanded(
            child: GridView.extent(
              mainAxisSpacing: 3.0,
              crossAxisSpacing: 3.0,
              maxCrossAxisExtent: 260.0,
              children: showWidgets,
            ),
          );
  }

  Widget showCart() {
    return GestureDetector(
      onTap: () {
        if (lat == null) {
          findLatLng();
          normalToast('โปรดรอสักครู่ กำลังค้นหาพิกัด');
        } else {
          routeToShowCart();
        }
      },
      child: MyStyle().showMyCart(amount),
    );
  }

  void routeToShowCart() {
    if (lat == null) {
      normalToast('กรุณาลองใหม่ กำลังหาพิกัดคะ');
    } else {
      MaterialPageRoute materialPageRoute = MaterialPageRoute(
          builder: (value) => ShowCart(
                lat: lat,
                lng: lng,
              ));
      Navigator.of(context)
          .push(materialPageRoute)
          .then((value) => checkAmount());
    }
  }

  ListView userList() {
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        showHeadUser(),
        menuHome(),
        menuNoti(),
        //menuShowCart(),
        menuUserOrder(),
        menuSignOut(),
      ],
    );
  }

  Future<void> signOutProcess() async {
    try {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      preferences.clear();
      MaterialPageRoute route = MaterialPageRoute(builder: (value) => Home());
      Navigator.of(context).pushAndRemoveUntil(route, (value) => false);
    } catch (e) {}
  }

  Widget menuSignOut() {
    return ListTile(
      leading: Icon(
        Icons.exit_to_app,
        color: MyStyle().dartColor,
        size: 36.0,
      ),
      title: Text(
        'ออกจากระบบ',
        style: MyStyle().h2Style,
      ),
      subtitle: Text(
        'กดที่นี่ เพื่อออกจากระบบ',
        style: MyStyle().h3StylePrimary,
      ),
      onTap: () {
        Navigator.of(context).pop();
        signOutProcess();
      },
    );
  }

  Widget menuUserOrder() {
    return ListTile(
      leading: Icon(
        Icons.directions_bike,
        size: 36.0,
        color: MyStyle().dartColor,
      ),
      title: Text(
        'ประวัติ',
        style: MyStyle().h2Style,
      ),
      subtitle: Text(
        'รายการสั่งอาหาร,​ประวัติการสั่งซื้อ',
        style: MyStyle().h3StylePrimary,
      ),
      onTap: () {
        Navigator.of(context).pop();
        routeToShowOrder();
      },
    );
  }

  Widget menuNoti() {
    return ListTile(
      leading: Icon(
        Icons.notifications_active,
        size: 36.0,
        color: MyStyle().dartColor,
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            'แจ้งเตือน',
            style: MyStyle().h2Style,
          ),
          Icon(
            Icons.looks_4,
            color: Colors.red,
          )
        ],
      ),
      subtitle: Text(
        'แจ้งเตือนจาก SEND',
        style: MyStyle().h3StylePrimary,
      ),
      onTap: () {
        Navigator.of(context).pop();
        routeToNoti();
      },
    );
  }

  void routeToNoti() {
    MaterialPageRoute materialPageRoute = MaterialPageRoute(
      builder: (context) => NotificationUser(),
    );
    Navigator.push(context, materialPageRoute);
  }

  void routeToShowOrder() {
    MaterialPageRoute materialPageRoute = MaterialPageRoute(
      builder: (context) => ShowOrderUser(),
    );
    Navigator.push(context, materialPageRoute);
  }

  Widget menuShowCart() {
    return ListTile(
      leading: Icon(
        Icons.shopping_cart,
        size: 36.0,
        color: MyStyle().dartColor,
      ),
      title: Text(
        'ตะกร้า',
        style: MyStyle().h2Style,
      ),
      subtitle: Text(
        'แสดงรายการสินค้า ที่มีใน ตะกร้า',
        style: MyStyle().h3StylePrimary,
      ),
      onTap: () {
        Navigator.of(context).pop();
        routeToShowCart();
      },
    );
  }

  Widget menuHome() {
    return ListTile(
      leading: Icon(
        Icons.fastfood,
        size: 36.0,
        color: MyStyle().dartColor,
      ),
      title: Text(
        'สั่งอาหาร',
        style: MyStyle().h2Style,
      ),
      subtitle: Text(
        'เมนูอร่อยมากมายพร้อมเสิร์ฟถึงบ้าน',
        style: MyStyle().h3StylePrimary,
      ),
      onTap: () {
        setState(() {
          Navigator.of(context).pop();
          // cuttentWidget = MainHome();
        });
      },
    );
  }

  Widget showHeadUser() {
    // print('nameLogin ==>>> $nameLogin');
    return UserAccountsDrawerHeader(
      decoration: BoxDecoration(
        image: DecorationImage(
            image: AssetImage('images/bic3.png'), fit: BoxFit.cover),
      ),
      currentAccountPicture: MyStyle().showProgress(),
      accountName: Text(
        nameLogin,
        style: MyStyle().h2StyleWhite,
      ),
      accountEmail: Text('Login'),
    );
  }

  void routeToShowSearch() {
    MaterialPageRoute materialPageRoute =
        MaterialPageRoute(builder: (value) => MySearch());
    Navigator.of(context).push(materialPageRoute);
  }

  Widget buildListSendLocation() {
    return ListView.builder(
      shrinkWrap: true,
      physics: ScrollPhysics(),
      itemCount: sendLocationModels.length,
      itemBuilder: (context, index) =>
          Text(sendLocationModels[index].nameLocation),
    );
  }

  Widget buildBottomSheet(BuildContext context) {
    return Container(
      height: 40.0,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, -1),
            blurRadius: 6.0,
          )
        ],
      ),
      child: Center(
        child: FlatButton(
          onPressed: () async {
            print('You Click');
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShowOrderUser(),
                ));
          },
          child: Column(
            children: <Widget>[
              LinearProgressIndicator(
                backgroundColor: Colors.white,
                valueColor: new AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
              Text(
                'คุณมี $amountOrder คำสั่งซื้อ กำลังดำเนินการ...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      title: Center(
        child: Text(
          'ค้นหาร้านค้า',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      actions: <Widget>[
        buildISearchViewShop(),
        SizedBox(
          width: 10,
        ),
        showCart(),
      ],
    );
  }

  Widget buildISearchViewShop() {
    return IconButton(
      icon: Icon(Icons.search, color: Colors.white),
      onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchViewShop(
              userShopModels: nearShopModels,
              nameLocalChoose: nameLocalChoose,
              distances: distances,
              
            ),
          )),
    );
  }

  Widget showSearch() {
    return IconButton(
        icon: Icon(Icons.search),
        onPressed: () {
          routeToShowSearch();
        });
  }

  Widget buildChooseSenLocation(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
          icon: Icon(
            Icons.add_circle,
            size: 30,
            color: Colors.green,
          ),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GuestMap(
                    myLat: lat,
                    myLng: lng,
                  ),
                )).then((value) {
              findSendLocationWhereIdUser();
            });
          },
        ),
        SizedBox(
          width: 10.0,
        ),
        Text(
          'ส่งที่ :',
          style: MyStyle().h2Stylegreen,
        ),
        SizedBox(
          width: 10.0,
        ),
        buildDropDown(context),
      ],
    );
  }

  int indexChooseLocation;

  Widget buildDropDown(BuildContext context) {
    List<int> indexs = List();
    int i = 0;
    for (var model in sendLocationModels) {
      indexs.add(i);
      i++;
      //print('$indexs');
    }
    return indexs.length == 0
        ? Text(
            'เพิ่มสถานที่ส่งของคุณ',
            style: MyStyle().h2Stylegreen,
          )
        : DropdownButton<int>(
            items: indexs.map(
              (e) {
                String string = sendLocationModels[e].nameLocation;
                if (string.length >= 20) {
                  string = string.substring(0, 19);
                  string = '$string ...';
                }

                return DropdownMenuItem(
                  child: Container(
                    width: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          string,
                          style: MyStyle().h2Stylegreen,
                        ),
                        IconButton(
                            icon: Icon(
                              Icons.highlight_off,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              deleteThread(sendLocationModels[e].id);
                            })
                      ],
                    ),
                  ),
                  value: e,
                );
              },
            ).toList(),
            hint: Text(
              'พิกัดเครื่อง',
              style: MyStyle().h2Stylegreen,
            ),
            value: indexChooseLocation,
            onChanged: (value) {
              setState(() {
                indexChooseLocation = value;

                nameLocalChoose = sendLocationModels[value].nameLocation;
                latChoose =
                    double.parse(sendLocationModels[indexChooseLocation].lat);
                lngChoose =
                    double.parse(sendLocationModels[indexChooseLocation].lng);

                print(
                    'nameLocal === $nameLocalChoose, latChooose = $latChoose, $lngChoose');

                double lat3 =
                    double.parse(sendLocationModels[indexChooseLocation].lat);
                double lng3 =
                    double.parse(sendLocationModels[indexChooseLocation].lng);

                //print('$lat3, $lng3');
                readShopThread(lat3, lng3);
              });
            },
          );
  }

  Future<void> deleteThread(String id) async {
    String url =
        'http://movehubs.com/app/deleteSendLocationWhereId.php?isAdd=true&id=$id';
    await Dio().get(url).then((value) {
      setState(() {
        findSendLocationWhereIdUser();
      });
    });
  }

  Future<Null> findProcess() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String idUser = preferences.getString('id');

    String url =
        'http://movehubs.com/app/getOrderWhereIdUser.php?isAdd=true&idUser=$idUser';

    //print('url ==== $url');

    try {
      Response response = await Dio().get(url);
      var result = json.decode(response.data);
      for (var map in result) {
        OrderUserModel model = OrderUserModel.fromJson(map);
        String string = model.success;
        print('Success ==== $string');

        if (string == '0' || string == 'ShopOrder' || string == 'RiderOrder') {
          setState(() {
            amountOrder++;
          });
        }

        if (!(string == 'Success' || string == 'ShopCancel')) {
          setState(() {
            statusProcess = false;
          });
        }
      }
    } catch (e) {}
  }
}
