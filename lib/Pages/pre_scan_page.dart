import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ieee_qr_code/Pages/qrCodePage.dart';
import 'package:ieee_qr_code/api/sheets/sheets_api.dart';
import 'package:loader_overlay/loader_overlay.dart';

class PreScan extends StatefulWidget {
  // This is the object for the whole document IE: worksheets included
  final QueryDocumentSnapshot eventDocument;
  const PreScan({super.key, required this.eventDocument});
  @override
  State<PreScan> createState() => _PreScanState();
}

class _PreScanState extends State<PreScan> {
  // The keep track of the selected WorkSheet
  late String selectedWorkSheet;
  late String selectedColumnToCheckBox;

  // We start the page without any selected sheet or column so initialize them with false
  bool isWorkSheetSelected = false;
  bool isColumnToCheckBoxSelected = false;

  @override
  Widget build(BuildContext context) {
    // Make a list of all the worksheets
    List<String> WorkSheetList = widget.eventDocument['WorkSheets'].keys.toList();

    if(!isWorkSheetSelected) {
      selectedWorkSheet = WorkSheetList[0];
    }

    // Make a list of all the columns in the selected worksheet above
    List<dynamic> CheckBoxColumns = widget.eventDocument['WorkSheets'][selectedWorkSheet];

    if(!isColumnToCheckBoxSelected) {
      selectedColumnToCheckBox = CheckBoxColumns[0];
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back,
              color: Colors.white),
          onPressed: (){
            setState(() {
              Navigator.pop(context);
            });
          },
        ),
        backgroundColor: Colors.blue[900],
        title:const Center(
          child: Text("Pre scan",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white)
          ),
        ),
      ),
      body: LoaderOverlay( // A cool thing to do a loading screen when the button is pressed
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const SizedBox(height: 20,),
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.blue.shade900, borderRadius: BorderRadius.circular(10)),
                child: DropdownButton(
                  iconEnabledColor: Colors.white,
                  dropdownColor: Colors.lightBlue,
                  underline: const SizedBox(),
                  value: selectedWorkSheet,
                  items: WorkSheetList.map((sheet) {return DropdownMenuItem(value: sheet, child: Text(sheet, style: const TextStyle(color: Colors.white)));}).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedWorkSheet = value!;
                      CheckBoxColumns = widget.eventDocument['WorkSheets'][selectedWorkSheet];
                      isWorkSheetSelected = true;
                      isColumnToCheckBoxSelected = false;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20,),
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.blue.shade900, borderRadius: BorderRadius.circular(10)),
                child: DropdownButton(
                  iconEnabledColor: Colors.white,
                  dropdownColor: Colors.lightBlue,
                  underline: const SizedBox(),
                  value: selectedColumnToCheckBox,
                  items: CheckBoxColumns.map((columns) {return DropdownMenuItem(value: columns, child: Text(columns, style: const TextStyle(color: Colors.white)));}).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedColumnToCheckBox = value!.toString();
                      isColumnToCheckBoxSelected = true;
                    });
                  },
                ),
              ),
              const Spacer(),
              // The start scan button
              TextButton(
                style: TextButton.styleFrom(
                    fixedSize: const Size(double.maxFinite, 50),
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue.shade900,
                    textStyle:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    shape: (RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.blue.shade900)))),
                onPressed: () async {
                  context.loaderOverlay.show(); // Show the loading overlay

                  String? ssID = SheetsApi.getSheetIdFromUrl(widget.eventDocument['sheetUrl']); // The sheet ssID is used to identify the exact document from google sheets
                  int targetColumn = await SheetsApi.headerNameToIndex(ssID, selectedWorkSheet, selectedColumnToCheckBox); // Converts the name of the column to it's index in the columns

                  // Prepare all the columns to be searched
                  List<int> QRSearchColumns = [];
                  for (int i = 0; i <widget.eventDocument['QrCols'].length; i++) {
                    QRSearchColumns.add(await SheetsApi.headerNameToIndex(ssID, selectedWorkSheet, widget.eventDocument['QrCols'][i]));
                  }
                  if(context.mounted){
                    SheetsApi.init(ssID);
                    SheetsApi.updateRowsLocal(selectedWorkSheet);
                    SheetsApi.searchTerms = await SheetsApi.getSearchTerms(selectedWorkSheet, QRSearchColumns);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => QrCodePage(ssID: ssID!, checkName: selectedColumnToCheckBox ,workSheet: selectedWorkSheet, qrColumns: QRSearchColumns, checkColumn: targetColumn,)),);}
                },
                child: const Text('Start Scan'),
              ),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
