import 'package:connectivity/connectivity.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets.dart';
import 'package:provider/provider.dart';

class Store extends StatefulWidget {
  _Store createState() => _Store();
}

class _Store extends State<Store> {
  InAppPurchaseConnection iap = InAppPurchaseConnection.instance;
  bool open;
  StreamSubscription<List<PurchaseDetails>> transactions;
  List<ProductDetails> products = [];
  List<PurchaseDetails> goods;
  int selection = 0;
  String id = 'scan_tokens';
  int current;

  purchase(int money) async {
    if (products.length > 0) {
      ProductDetails productDetails = products[selection];
      PurchaseParam param = PurchaseParam(productDetails: productDetails);
      bool complete =
          await iap.buyConsumable(purchaseParam: param, autoConsume: false);
      if (complete) {
        FirebaseDatabase.instance
            .reference()
            .child('users/' + FirebaseAuth.instance.currentUser.uid + '/scans')
            .set(money + 1);
      }
    } else {
      showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => AlertDialog(
                title: Text('No Products Loaded, Sort issue'),
              ));
    }
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    transactions.cancel();
    super.dispose();
  }

  PurchaseDetails hasPurchased(String productID, List<PurchaseDetails> items) {
    return items.firstWhere((purchase) => purchase.productID == productID,
        orElse: () => null);
  }

  initialize() async {
    open = await iap.isAvailable();
    if (open) {
      Set<String> ids = Set.from([id]);
      iap.queryProductDetails(ids).then((value) {
        Future.delayed(Duration.zero, () async {
          setState(() {
            products = value.productDetails;
          });
        });
      });
    }
  }

  Widget build(BuildContext context) {
    var profile = Provider.of<User>(context);
    var money = Provider.of<Coins>(context).money;
    var connection = Provider.of<ConnectivityResult>(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initialize();
    });
    return Scaffold(
      appBar: UniBar('Buy Scans'),
      body: Column(children: [
        if (profile != null) ...[
          CircleAvatar(backgroundImage: NetworkImage(profile.photoURL)),
          FlatButton(
            onPressed: () => purchase(money),
            child: Text('Purchase Scan'),
            color: Colors.blue[600],
          )
        ],
        if (profile == null && connection != ConnectivityResult.none) ...[
          Icon(Icons.account_circle),
          FlatButton(
            onPressed: null,
            child: Text('Purchase Scans'),
            color: Colors.grey[600],
          )
        ],
        if (connection == ConnectivityResult.none) ...[
          Center(
              child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [Icon(Icons.signal_wifi_off), Text('No connection')],
          ))
        ]
      ]),
    );
  }
}
