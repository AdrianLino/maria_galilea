import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../utils/colors.dart';


class EmptyScreen extends StatefulWidget {
  final Function(String value) onTap;
  final bool isScroll;

  EmptyScreen({Key? key, required this.onTap, this.isScroll = false}) : super(key: key);

  @override
  State<EmptyScreen> createState() => _EmptyScreenState();
}

class _EmptyScreenState extends State<EmptyScreen> {
  ScrollController controller = ScrollController();

  List<String> questionList = [
    'Explain quantum computing in simple terms ?',
    'What is the difference between supervised and unsupervised learning ?',
  ];

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isScroll) {
      controller.animToBottom(milliseconds: 100);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: widget.isScroll ? 185 : 90),
      controller: controller,
      child: Column(
        children: [
          Text('Iqonic Bot', style: boldTextStyle(size: 34)),
          8.height,
          RichTextWidget(
            list: [
              TextSpan(text: 'powered by ', style: secondaryTextStyle()),
              TextSpan(text: 'Gemini', style: boldTextStyle(size: 24)),
            ],
          ),
          30.height,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.light_mode_outlined, size: 30),
              16.width,
              Text('Examples', style: boldTextStyle(size: 20)),
            ],
          ),
          32.height,
          Wrap(
            runSpacing: 16,
            children: List.generate(questionList.length, (index) {
              return GestureDetector(
                onTap: () {
                  widget.onTap.call(questionList[index]);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: boxDecorationDefault(
                    color: replyMsgBgColor.withAlpha(50),
                    borderRadius: radius(),
                  ),
                  child: Row(
                    children: [
                      Text(questionList[index], style: primaryTextStyle(color: Colors.white)).expand(),
                      16.width,
                      Icon(Icons.arrow_forward_ios, color: Colors.white),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}