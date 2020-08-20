import 'dart:async';

import 'package:flutter/material.dart';
import 'package:foodlion/models/user_shop_model.dart';
import 'package:foodlion/utility/my_api.dart';
import 'package:foodlion/utility/my_style.dart';
import 'package:foodlion/utility/normal_dialog.dart';
import 'package:foodlion/widget/my_food.dart';

class SearchViewShop extends StatefulWidget {
  final List<UserShopModel> userShopModels;
  final String nameLocalChoose;
  final List<String> distances;
  final double latChoose, lngChoose;

  SearchViewShop(
      {this.userShopModels,
      this.nameLocalChoose,
      this.distances,
      this.latChoose,
      this.lngChoose});
  @override
  _SearchViewShopState createState() => _SearchViewShopState();
}

class Debouncer {
  int mill;
  VoidCallback callback;
  Timer timer;

  Debouncer({this.mill});

  run(VoidCallback callback) {
    if (timer != null) {
      timer.cancel();
    }
    timer = Timer(Duration(milliseconds: mill), callback);
  }
}

class _SearchViewShopState extends State<SearchViewShop> {
  List<UserShopModel> userShopModels;
  List<UserShopModel> filterUserShopModels = List();

  List<String> distances;
  List<String> filterDistances = List();

  final Debouncer debouncer = Debouncer(mill: 500);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (filterUserShopModels.length != 0) {
      // print('initStat Work');
      filterUserShopModels.clear();
    }

    userShopModels = widget.userShopModels;
    filterUserShopModels = userShopModels;
    //print('userShopModels.leght===== ${userShopModels.length}');

    distances = widget.distances;
    filterDistances = distances;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.white54,
          ),
          height: 35,
          child: TextField(
            onChanged: (value) {
              debouncer.run(() {
                setState(() {
                  filterUserShopModels = userShopModels.where((element) {
                    return element.name
                        .toLowerCase()
                        .contains(value.toLowerCase());
                  }).toList();
                });
              });
            },
            style: TextStyle(fontSize: 20),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.only(bottom: 8),
              hintStyle: TextStyle(
                fontSize: 18,
              ),
              hintText: 'ชื่อร้านอาหาร',
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
      body: userShopModels.length == 0
          ? MyStyle().showProgress()
          : buildListShop(),
    );
  }

  Widget buildListShop() => ListView.builder(
        itemCount: filterUserShopModels.length,
        itemBuilder: (context, index) => GestureDetector(
            onTap: () {
              String idShop = filterUserShopModels[index].id;
              String nameLocalChoose = widget.nameLocalChoose;
              List<String> distances = widget.distances;

              print('You Click idShop  ===>>>> $idShop');
              print('You Click nameLocalChoose  ===>>>> $nameLocalChoose');
              print('You Click distances  ===>>>> $distances');

              if (MyAPI().checkTimeShop()) {
                MaterialPageRoute route = MaterialPageRoute(
                  builder: (cont) => MyFood(
                    idShop: idShop,
                    nameLocalChoose: nameLocalChoose,
                  ),
                );
                Navigator.of(context).push(route).then((value) => (idShop));
              } else {
                normalDialog(context, 'SEND ปิดแล้ว',
                    'SEND DRIVE บริการส่งเวลา 7.30- 20.00 น.');
              }
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    NetworkImage(filterUserShopModels[index].urlShop),
              ),
              title: Text(filterUserShopModels[index].name),
              subtitle: Text(filterUserShopModels[index].detailShop),
              trailing: Icon(Icons.keyboard_arrow_right),
            )
            //Text(filterUserShopModels[index].name),
            ),
      );
}
