import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../colors.dart';
import '../utils/AppConstant.dart';

class DownloadSourceCodeDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: context.scaffoldBackgroundColor,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(16),
        ),
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  finish(context);
                },
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(padding: EdgeInsets.only(top: 8, right: 16), child: Icon(Icons.close, color:Colors.black)),
                ),
              ),
              Image.asset('images/app/app_icon.png', height: 100),
              Text("Download the source code", style: boldTextStyle(size: 20)).fit(),
              SizedBox(height: 6),
              Text("Love ProKit Flutter? Tap on download to buy ProKit Flutter.", style: secondaryTextStyle(size: 16), textAlign: TextAlign.center),
              SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColorPrimary,
                ),
                onPressed: () {
                  finish(context);
                  launch(SourceCodeUrl as BuildContext);
                },
                child: Text('Download', style: primaryTextStyle(color: white)),
              ).paddingOnly(bottom: 24)
            ],
          ),
        ),
      ),
    );
  }
}
