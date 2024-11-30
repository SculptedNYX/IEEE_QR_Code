import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ieee_qr_code/Pages/userPage.dart';
import 'package:ieee_qr_code/api/sheets/sheets_api.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

String? data = "";
bool fromSearch = false;


// Define a global key to access the state
final GlobalKey<_QrCodePageState> _qrCodePageKey = GlobalKey<_QrCodePageState>();

class QrCodePage extends StatefulWidget {
  final String ssID, workSheet, checkName;
  final List<int> qrColumns;
  final int checkColumn;

  QrCodePage({Key? key, required this.ssID, required this.workSheet, required this.qrColumns, required this.checkColumn, required this.checkName}) : super(key: _qrCodePageKey);

  @override
  State<QrCodePage> createState() => _QrCodePageState();
}

class _QrCodePageState extends State<QrCodePage> {
  bool gotValidQr = false;
  final qrKey = GlobalKey(debugLabel: 'QR');

  Barcode? barcode;

  QRViewController? controller;

  @override
  void dispose(){
    controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() async{
    if (Platform.isAndroid){
      await controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 5,
          actions: [
            IconButton(onPressed: () async {
              showSearch(context: context, delegate: CustomSearchDelegate(),);
            }, icon: const Icon(Icons.search, color: Colors.white,))
          ],
          leading: IconButton(
            icon: const Icon(
                Icons.arrow_back,
                color: Colors.white),
            onPressed: (){
              setState(() {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const UserPage()), (route) => false);
              });
            },
          ),
          backgroundColor: Colors.blue[900],
          centerTitle: true,
          title:Text(widget.workSheet + " - " + widget.checkName,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white)
          ),
        ),
        body: Stack(alignment: Alignment.center,
          children:<Widget> [
            buildQrView(context),
            Positioned(
                bottom: 10,
                child: buildResult()
            )
          ],
        )
    );
  }

  Widget buildQrView(BuildContext context) => QRView(
    key: qrKey,
    onQRViewCreated: onQRViewCreated,
    overlay: QrScannerOverlayShape(
        cutOutSize: MediaQuery.of(context).size.width * 0.8,
        borderWidth: 10,
        borderLength: 20,
        borderRadius: 10,
        borderColor: Colors.blueAccent
    ),
  );

  void onQRViewCreated(QRViewController controller) {
    setState(() => this.controller = controller);

    controller.scannedDataStream.listen((barcode) => setState(() async {
      if (gotValidQr) return;

      gotValidQr = true;
      this.barcode = barcode;

      try {
        await _dialogBuilder(context);
      } catch (e) {
        if (context.mounted) {
          // Dismiss any currently showing SnackBar before showing a new one
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Faulty QR code"))
          );
        }
      }

      gotValidQr = false;
    }));
  }



  Widget buildResult () => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      color: Colors.white24,
    ),
    child: Text(
      barcode != null ? "Result: ${barcode!.code}" : "Scan a code!",
      maxLines: 3,),
  );

  // This is used for the alert dialogue on scan
  Future<void> _dialogBuilder(BuildContext context) async {
    if (!fromSearch) {
      data = barcode?.code;
    }
    fromSearch = false;
    barcode = null;
    int isBoxChecked = 0;
    String targetState = "true";
    var alertBGColor = Colors.white;
    var alertTextColor = Colors.black;
    Color? alertTextHighlightColor = Colors.blue;
    String alertHeader = "Confirm scan?";
    int rowIndex = await SheetsApi.getRowByValues(widget.workSheet, widget.qrColumns, data!.split(","));
    // Simple internet check
    if(await InternetConnectionChecker().hasConnection) {
      isBoxChecked = await SheetsApi.CheckBoxCell(widget.workSheet, widget.checkColumn, rowIndex+1);
      if(isBoxChecked == 1) {
        alertBGColor = Colors.red;
        alertTextColor = Colors.white;
        alertTextHighlightColor = Colors.cyan[100];
        targetState = "false";
        alertHeader = "already scanned";
      }
    }
    else {
      if(context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No internet connection, Try again")));}
    }

    return showDialog(context: context, builder: (context) {
      return AlertDialog(
        backgroundColor: alertBGColor,
        title: Text("$alertHeader - ${widget.checkName}\n",style: TextStyle(color: alertTextColor),),
        content: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(fontSize: 28.0, color: alertTextColor), // Default style
            children: data?.split(',').asMap().entries.map((entry) {
              int index = entry.key;
              String value = entry.value;
              return TextSpan(text: "$value");
            }).toList(),
          ),
        )
        ,
        actions: [
          TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Deny", style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold, fontSize: 20),)),
          if (isBoxChecked == 0)
          TextButton(onPressed: () async {
            bool checkedComplete = await SheetsApi.scanQRtoSheet(widget.workSheet, widget.checkColumn, rowIndex, targetState);
            if (checkedComplete) {
              if(context.mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Successfully added")));}
            }
            else {
              if(context.mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("An error has occurred")));}
            }
            if(context.mounted){Navigator.of(context).pop();}
            }, child: Text("Confirm",
            style: TextStyle(color: Colors.blue[900],
                fontWeight: FontWeight.bold, fontSize: 20),
            )
          )
        ],
      );
    });
  }

}


class CustomSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(onPressed: (){
        query = '';
      }, icon: const Icon(Icons.clear))
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(onPressed: (){
      close(context, null);
    }, icon: const Icon(Icons.arrow_back));
  }

  @override
  Widget buildResults(BuildContext context) {
    List<String> matchQuery = [];
    for (var entry in SheetsApi.searchTerms) {
      if (entry.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(entry);
      }
    }

    return ListView.builder(itemCount: matchQuery.length, itemBuilder: (context, index) {
      var result = matchQuery[index];
      return InkWell(onTap: () async {
        data = result;
        fromSearch = true;
        await _qrCodePageKey.currentState!._dialogBuilder(context);
        close(context, null);
      },child: ListTile(title: Text(result),));
    },);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<String> matchQuery = [];
    for (var entry in SheetsApi.searchTerms) {
      if (entry.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(entry);
      }
    }

    return ListView.builder(itemCount: matchQuery.length, itemBuilder: (context, index) {
      var result = matchQuery[index];
      return InkWell(onTap: () async {
        data = result;
        fromSearch = true;
        await _qrCodePageKey.currentState!._dialogBuilder(context);
        close(context, null);
      },child: ListTile(title: Text(result),));
    },);
  }

}