import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foodlion/scaffold/register_shop_success.dart';
import 'package:foodlion/utility/my_constant.dart';
import 'package:foodlion/utility/my_style.dart';
import 'package:foodlion/utility/normal_dialog.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';

class RegisterShop extends StatefulWidget {
  @override
  _RegisterShopState createState() => _RegisterShopState();
}

class _RegisterShopState extends State<RegisterShop> {
  // Field
  double lat, lng;
  File file;
  String name, user, password, phone, urlImage, check;
  bool isLoading = false;

  // Method

  @override
  void initState() {
    super.initState();
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
    } on PlatformException catch (e) {
      if (e.code == 'PEMISSION_DENIED') {
        
      }
      return null;
    }
  }

  Widget showMap() {
    LatLng centerLatLng = LatLng(lat, lng);
    CameraPosition cameraPosition = CameraPosition(
      target: centerLatLng,
      zoom: 16.0,
    );

    return GoogleMap(
      initialCameraPosition: cameraPosition,
      markers: myMarkers(),
      onMapCreated: (value) {},
    );
  }

  Set<Marker> myMarkers() {
    LatLng latLng = LatLng(lat, lng);

    return <Marker>[
      Marker(
        markerId: MarkerId('idShop'),
        position: latLng,
        infoWindow: InfoWindow(
          title: 'You',
          snippet: '$lat,$lng',
        ),
      ),
    ].toSet();
  }

  Widget showLocation() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.3,
      child: lat == null ? MyStyle().showProgress() : showMap(),
    );
  }

  Widget nameForm() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 250.0,
          child: TextField(
            onChanged: (value) => name = value.trim(),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.account_box),
              hintText: 'ชื่อร้านของคุณ :',
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget userForm() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 250.0,
          child: TextField(
            onChanged: (value) => user = value.trim(),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.email),
              hintText: 'Username :',
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget passwordForm() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 250.0,
          child: TextField(
            onChanged: (value) => password = value.trim(),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.lock_open),
              hintText: 'Password :',
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget phoneForm() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 250.0,
          child: TextField(
            onChanged: (value) => phone = value.trim(),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.phone),
              hintText: 'เบอร์โทรศัพท์ :',
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget cameraButton() {
    return OutlineButton.icon(
      onPressed: () => chooseImage(ImageSource.camera),
      icon: Icon(Icons.add_a_photo),
      label: Text('ถ่ายภาพร้าน'),
    );
  }

  Future<void> chooseImage(ImageSource source) async {
    try {
       var object = await ImagePicker()
          .getImage(source: source, maxWidth: 800.0, maxHeight: 800.0);

      setState(() {
        file = File(object.path);
      });
    } catch (e) {}
  }

  Widget galleryButton() {
    return OutlineButton.icon(
      onPressed: () => chooseImage(ImageSource.gallery),
      icon: Icon(Icons.add_photo_alternate),
      label: Text('คลังภาพ'),
    );
  }

  Widget showButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        cameraButton(),
        galleryButton(),
      ],
    );
  }

  Widget showPicture() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.2,
      child:
          file == null ? Image.asset('images/shopicon.png') : Image.file(file),
    );
  }

  Widget uploadButton() {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: RaisedButton.icon(
        color: MyStyle().primaryColor,
        onPressed: () {
          if (file == null) {
            normalDialog(context, 'ไม่ได้เลือกรูปภาพ',
                'กรุณา ถ่ายภาพร้านสวยๆ หรือ ภาพอาหารเด่น');
          } else if (name == null ||
              name.isEmpty ||
              user == null ||
              user.isEmpty ||
              password == null ||
              password.isEmpty ||
              phone == null ||
              phone.isEmpty) {
            normalDialog(context, 'มีที่ว่าง', 'กรุณากรอกโดยไม่เว้นช่องว่าง');
          } else {
            checkUser();
          }
        },
        icon: Icon(
          Icons.cloud_upload,
          color: Colors.white,
        ),
        label: Text(
          'บันทึก',
          style: MyStyle().h2StyleWhite,
        ),
      ),
    );
  }

  Future<void> checkUser() async {
    setState(() {
      isLoading = true;
    });
    String url =
        '${MyConstant().urlGetUserShopWhereUser}?isAdd=true&User=$user';
    try {
      await Dio().get(url).then((response) {
        setState(() {
          isLoading = false;
        });
        if (response.toString() == 'null') {
          uploadImageToServer();
        } else {
          normalDialog(
            context,
            'User ซ้ำ',
            'เปลี่ยน User ใหม่ คะ ? User ซ้ำ',
            icon: MyStyle().signUpIcon,
          );
        }
      });
    } catch (e) {}
  }

  Future<void> uploadImageToServer() async {
    String url = MyConstant().urlSaveFile;
    Random random = Random();
    int i = random.nextInt(100000);
    String nameFile = 'shop$i.jpg';
    setState(() {
      isLoading = true;
    });

    try {
      Map<String, dynamic> map = Map();
      // map['file'] = UploadFileInfo(file, nameFile);
      map['file'] = await MultipartFile.fromFile(file.path, filename: nameFile);
      FormData formData = FormData.fromMap(map);
      await Dio()
          .post(url, data: formData)
          .then((response) => insertDtaToMySQL(nameFile))
          .catchError(() {});
    } catch (e) {}
  }

  Future<void> insertDtaToMySQL(String string) async {
    urlImage = '${MyConstant().urlImagePathShop}$string';
    setState(() {
      isLoading = true;
    });
    String urlAPI =
        '${MyConstant().urlAddUserShop}?isAdd=true&Name=$name&User=$user&Password=$password&UrlShop=$urlImage&Lat=$lat&Lng=$lng&Check=off&phoneShop=$phone';

    try {
      await Dio().get(urlAPI).then(
        
        (response) {
          print('response $response');
          setState(() {
            isLoading = false;
          });
          if (response.toString() == 'true') {
            MaterialPageRoute route = MaterialPageRoute(
              builder: (value) => RegisterShopSuccess(),
            );
            Navigator.of(context).pushAndRemoveUntil(route, (value) => false);
          } else {
            normalDialog(context, 'Register False', 'Please Try Again');
          }
        },
      );
    } catch (e) {}
  }

  Widget showListView() {
    return ListView(
      padding: EdgeInsets.all(16.0),
      children: <Widget>[
        showPicture(),
        showButton(),
        MyStyle().mySizeBox(),
        nameForm(),
        MyStyle().mySizeBox(),
        userForm(),
        MyStyle().mySizeBox(),
        passwordForm(),
        MyStyle().mySizeBox(),
        phoneForm(),
        MyStyle().mySizeBox(),
        showLocation(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: isLoading ? MyStyle().showProgress() : null,
        ),
        MyStyle().mySizeBox(),
        uploadButton(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return showListView();
  }
}
