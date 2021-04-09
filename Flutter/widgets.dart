import 'dart:async';
import 'package:async/async.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UniBar extends StatelessWidget implements PreferredSizeWidget {
  final Color backgroundColor = Colors.blue;

  final String command;

  const UniBar(this.command, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: Text(command),
      backgroundColor: backgroundColor,
      actions: [
        GestureDetector(onTap: () {
          Navigator.pushNamed(context, 'Profile');
        }, child: Consumer<User>(builder: (context, user, child) {
          return Tooltip(
            message: user == null ? "Sign in for Profile" : user.displayName,
            child: user != null
                ? ClipRRect(child: CachedNetworkImage(imageUrl: user.photoURL))
                : Icon(Icons.account_circle),
          );
        }))
      ],
    );
  }

  @override
  Size get preferredSize => new Size.fromHeight(AppBar().preferredSize.height);
}

Drawer navBar() {
  return Drawer(
    child: ListView(
      children: [DrawerHeader(child: Text("Navigate to new page")), ListTile()],
    ),
  );
}

class Wallet {
  static final Wallet _singleton = Wallet._internal();
  factory Wallet() {
    return _singleton;
  }
  Wallet._internal();
  Stream coins;
  create() {
    Stream<CrossOver> signin = FirebaseAuth.instance
        .userChanges()
        .map((event) => CrossOver(user: event, isnum: false));
    group.add(signin);
    coins = replace(FirebaseAuth.instance.currentUser);
    group.add(coins);
  }

  Stream<CrossOver> replace(User user) async* {
    if (user != null) {
      await for (var x in FirebaseDatabase.instance
          .reference()
          .child('users/' + user.uid + '/scans')
          .onValue) {
        yield CrossOver(coins: Coins.load(x.snapshot.value), isnum: true);
      }
    } else {
      yield CrossOver(coins: Coins.load(0), isnum: true);
    }
  }

  Stream<Coins> real() {
    return group.stream.map((event) {
      Coins val;
      if (event.isnum == true) {
        val = event.coins;
      }
      if (event.isnum == false) {
        Stream<CrossOver> nStream = replace(event.user);

        group.remove(coins);
        coins = nStream;
        group.add(nStream);
        FirebaseDatabase.instance
            .reference()
            .child('users/' + event.user.uid + '/scans')
            .once()
            .then((value) => val = Coins.load(value.value));
      }
      return val;
    });
  }

  StreamGroup<CrossOver> group = StreamGroup();
}

class Selector extends StatefulWidget {
  @override
  _SelectorState createState() => _SelectorState();
}

class _SelectorState extends State<Selector> {
  double sx, sy;
  double x, y;

  @override
  void initState() {
    super.initState();
    sx = 500.0;
    sy = 300.0;
    x = 0;
    y = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      widthFactor: x,
      heightFactor: y,
      child: Draggable(
        onDragEnd: (details) {
          x += details.offset.dx;
          y += details.offset.dy;
        },
        feedback: Opacity(
            opacity: 0.5,
            child: Container(width: sx, height: sy, color: Colors.blue[300])),
        child: GestureDetector(
          onTap: () {},
          onScaleUpdate: (scaleUpdateDetails) {
            sx *= scaleUpdateDetails.horizontalScale;
            sy *= scaleUpdateDetails.verticalScale;
          },
          child: Opacity(
              opacity: 0.5,
              child: Container(width: sx, height: sy, color: Colors.blue[300])),
        ),
      ),
    );
  }
}

class ImageHolder extends StatelessWidget {
  Uint8List img;
  int i;
  double x, y;
  ImageHolder(this.img, this.i);
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: Container(
        color: Colors.white,
        child: Column(children: [
          Image.memory(img),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [],
          )
        ]),
      ),
    );
  }
}

class BottomButton extends StatelessWidget {
  String purpose;
  Icon icon;
  Function func;
  BottomButton(this.func, this.purpose, this.icon);
  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: SizedBox(
            height: 44,
            child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                    onTap: func,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[icon, Text(purpose)])))));
  }
}

class Coins {
  int money;
  Coins(this.money);
  factory Coins.load(int i) {
    return Coins(i);
  }
}

class CrossOver {
  bool isnum;
  User user;
  Coins coins;
  CrossOver({this.user, this.coins, this.isnum});
}
