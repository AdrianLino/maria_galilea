import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../../config/theme/app_theme.dart';
import '../../colors.dart';
import '../../utils/constant.dart';
import '../component/DownloadSourceCodeDialog.dart';
import '../utils/AppConstant.dart';
import '../utils/AppImages.dart';
import '../utils/AppStrings.dart';
import '../utils/AppWidget.dart';
import '../utils/app_scroll_behaviour.dart';


class ProKitLauncher extends StatefulWidget {
  static String tag = '/prokit_launcher';
  static String workingAppsTag = '/working_apps';
  static String integrationTag = '/integrations';
  static String fullAppsTag = '/full_apps';
  static String widgetsTag = '/widgets';
  static String dashboardTag = '/dashboards';
  static String chartsTag = '/charts';
  static String flutterFxAnimationsTag = '/flutter_fx_animations';
  final String? route;

  ProKitLauncher({this.route});

  @override
  ProKitLauncherState createState() => ProKitLauncherState();
}

class ProKitLauncherState extends State<ProKitLauncher> with TickerProviderStateMixin {
  PageController _controller = PageController(initialPage: 0, keepPage: false);
  var selectedTab = 0;
  Future<AppTheme>? future;

  @override
  void initState() {
    super.initState();
    afterBuildCreated(() {
      if (!getBoolAsync(IN_APP_STORE_REVIEW)) {
        if (getIntAsync(appOpenCount) >= 5) {
          setValue(appOpenCount, 0);
          showDialog(
            context: context,
            builder: (BuildContext context) => DownloadSourceCodeDialog(),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget tabItem(String name, int pos, {var isRight = false, bool isNew = false}) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _controller.jumpToPage(pos);
            selectedTab = pos;
          });
        },
        child: Stack(
          children: [
            Container(
              child: Text(name, style: boldTextStyle(color: selectedTab == pos ? appColorPrimary : textSecondaryColorGlobal, size: 18)),
              alignment: Alignment.center,
              height: 50,
              decoration: selectedTab == pos ? BoxDecoration(color: appColorPrimary.withOpacity(0.1), borderRadius: isRight ? BorderRadius.only(topLeft: Radius.circular(16)) : BorderRadius.only(topRight: Radius.circular(16))) : BoxDecoration(),
            ),
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Container(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(color: appDarkRed, shape: BoxShape.circle),
                //decoration: boxDecoration(bgColor: appDarkRed, radius: 4),
              ),
            ).visible(isNew.validate()),
          ],
        ),
      );
    }

    Widget category(Color color, String img, String? name, {bool isNew = false, String? type = 'New', required Function onTap, int? appCount}) {
      return Container(
        width: 145,
        height: 100,
        margin: EdgeInsets.only(right: 16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              width: 145,
              height: 100,
              decoration: boxDecorationDefault(color: color),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SvgPicture.asset(img, width: 40, height: 40, color: Colors.white),
                  4.height,
                  Text('${appCount != null ? '$appCount ' : ''}$name', style: boldTextStyle(color: Colors.white), maxLines: 2, textAlign: TextAlign.center),
                ],
              ),
            ),
            if (isNew && (type != null && type.isNotEmpty))
              Positioned(
                right: -5,
                top: -5,
                child: Container(
                  alignment: Alignment.centerRight,
                  margin: EdgeInsets.only(right: 8, top: 8),
                  padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
                  decoration: boxDecorationDefault(color: appDarkRed, boxShadow: []),
                  child: FittedBox(child: text(type.validate(), fontSize: 8.0, textColor: Colors.white)),
                ),
              ),
          ],
        ).onTap(() => onTap(), borderRadius: radius()),
      );
    }

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: FutureBuilder<AppTheme>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return SafeArea(
              child: NestedScrollView(
                headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: 230.0,
                      floating: false,
                      backgroundColor: context.scaffoldBackgroundColor,
                      forceElevated: innerBoxIsScrolled,
                      pinned: true,
                      automaticallyImplyLeading: false,
                      elevation: 0.5,
                      actions: [
                        IconButton(
                          icon: Icon(Icons.settings, color: Colors.black),
                          onPressed: () {
                            //SettingScreen().launch(context);
                          },
                        )
                      ],
                      title: innerBoxIsScrolled ? Text(mainAppName, style: boldTextStyle(size: 24)) : null,
                      bottom: innerBoxIsScrolled
                          ? PreferredSize(
                              preferredSize: Size(context.width(), 80),
                              child: Container(
                                height: 80,
                                padding: EdgeInsets.only(left: 16, right: 16),
                                margin: EdgeInsets.only(left: 8),
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 60,
                                      margin: EdgeInsets.only(right: 12),
                                      padding: EdgeInsets.all(16),
                                      child: Image.asset(icons[0], color: Colors.white),
                                      decoration: boxDecorationDefault(color: appCat5),
                                    ),
                                    Expanded(
                                      child: Stack(
                                        alignment: Alignment.centerRight,
                                        children: <Widget>[
                                          Container(
                                            width: context.width(),
                                            height: 60,
                                            padding: EdgeInsets.only(left: 16, right: 16),
                                            margin: EdgeInsets.only(right: context.width() / 28),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: <Widget>[
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: <Widget>[
                                                    Text('Default Theme', style: boldTextStyle(), maxLines: 2),
                                                  ],
                                                ).expand(),
                                              ],
                                            ),
                                            decoration: boxDecorationDefault(color: context.scaffoldBackgroundColor),
                                          ),
                                          Container(
                                            width: 30,
                                            height: 30,
                                            child: Icon(Icons.keyboard_arrow_right, color: Colors.white),
                                            decoration: boxDecorationDefault(color: appCat5, shape: BoxShape.circle),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ).onTap(() {
                                //DTWalkThoughScreen().launch(context);
                              }),
                            )
                          : null,
                      flexibleSpace: FlexibleSpaceBar(
                        collapseMode: CollapseMode.parallax,
                        background: Container(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(mainAppName, style: boldTextStyle(size: 30)).paddingOnly(top: 16, left: 16, right: 16),
                              SizedBox(height: 16),
                              ScrollConfiguration(
                                behavior: AppScrollBehavior(),
                                child: SingleChildScrollView(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[

                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ];
                },
                body: Container(
                  margin: EdgeInsets.only(top: 8),
                  width: context.width(),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          tabItem(appLblThemeList, 0, isNew: false).expand(),
                          tabItem(appLblScreenList, 1, isRight: true, isNew: false).expand(),
                        ],
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.only(top: 16),
                          height: double.maxFinite,
                          child: PageView(
                            pageSnapping: false,
                            scrollBehavior: AppScrollBehavior(),
                            onPageChanged: (value) {
                              selectedTab = value;
                              setState(() {});
                            },
                            controller: _controller,
                            physics: NeverScrollableScrollPhysics(),
                            children: <Widget>[

                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error.toString()}", style: primaryTextStyle());
          }
          return CircularProgressIndicator().center();
        },
      ),
    );
  }
}
