import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:share_plus/share_plus.dart';

import '../colors.dart';
import '../models/question_answer_model.dart';
import '../utils/colors.dart';
import '../utils/common.dart';
import '../utils/images.dart';


class ChatMessageWidget extends StatefulWidget {
  final String answer;
  final QuestionAnswerModel data;
  final bool isLoading;

  ChatMessageWidget({
    required this.answer,
    required this.data,
    required this.isLoading,
  });

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}

class _ChatMessageWidgetState extends State<ChatMessageWidget> {
  FlutterTts flutterTts = FlutterTts();

  bool isSpeak = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void botSpeak({required String text}) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5); //speed of speech
    await flutterTts.setVolume(1.0); //volume of speech
    await flutterTts.setPitch(1); //pitch of sound

    if (text.isNotEmpty) {
      await flutterTts.speak(text);
    }
  }

  void share(BuildContext context, {String? question, String? answer, RenderBox? box}) async {
    await Share.share(
      'Q: ${question.validate()}\nGemini: ${answer.validate()}',
      sharePositionOrigin: isIOS ? box!.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  Widget speakIconWidget() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: decoration(color: isSpeak ? Colors.white : Colors.white.withAlpha(40)),
      child: Image.asset(
        ic_speak,
        height: 14,
        width: 14,
        color: isSpeak ? appColorPrimary : Colors.white,
      ),
    ).onTap(() {
      if (isSpeak) {
        flutterTts.stop();
      } else {
        botSpeak(text: widget.answer);
      }

      isSpeak = !isSpeak;
      setState(() {});
    });
  }

  Widget shareIconWidget() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: decoration(color: Colors.white.withAlpha(40)),
      child: Icon(Icons.share, size: 14, color: Colors.white),
    ).onTap(() {
      final box = context.findRenderObject() as RenderBox?;
      share(context, question: widget.data.question, answer: widget.answer, box: box);
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: EdgeInsets.only(top: 3.0, bottom: 3.0, right: 0, left: (500 * 0.10).toDouble()),
          decoration: boxDecorationDefault(
            color: appColorPrimary,
            boxShadow: defaultBoxShadow(blurRadius: 0, shadowColor: Colors.transparent),
            borderRadius: radiusOnly(bottomLeft: 16, topLeft: 16, topRight: 16),
          ),
          child: SelectableText(
            widget.data.smartCompose.validate().isNotEmpty ? 'Q: ${widget.data.question.splitAfter('of ')}' : 'Q: ${widget.data.question}',
            style: primaryTextStyle(size: 14),
          ),
        ),
        16.height,
        if (widget.answer.isEmpty && widget.isLoading) Center(child: SpinKitThreeBounce(color: chatGPT_textField_bgColor, size: 20)),
        if (widget.answer.isNotEmpty && !widget.isLoading)
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: EdgeInsets.only(top: 4.0, bottom: 4.0, left: 0, right: (500 * 0.14).toDouble()),
                  decoration: boxDecorationDefault(
                    color: replyMsgBgColor,
                    boxShadow: defaultBoxShadow(blurRadius: 0, shadowColor: Colors.transparent),
                    borderRadius: radiusOnly(topLeft: 16, bottomRight: 16, topRight: 16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText('Ans: ${widget.answer}', style: primaryTextStyle(size: 14, color: Colors.white)),
                      8.height,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${widget.answer.calculateReadTime().toStringAsFixed(1).toDouble().ceil()} min read",
                            style: secondaryTextStyle(color: Colors.white54, size: 12),
                          ),
                          Spacer(),
                          shareIconWidget(),
                          8.width,
                          speakIconWidget(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 25,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: decoration(),
                      child: Icon(Icons.copy, size: 16, color: Colors.white),
                    ).onTap(() {
                      widget.answer.copyToClipboard();
                      toast('Copied to Clipboard');
                    }),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}