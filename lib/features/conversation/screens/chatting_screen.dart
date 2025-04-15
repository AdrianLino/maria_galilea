import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../colors.dart';
import '../components/chat_message_widget.dart';
import '../components/commonIconButton.dart';
import '../components/voice_search_component.dart';
import '../main/screens/ProKitLauncher.dart';
import '../models/question_answer_model.dart';
import '../services/gemini_api_service.dart';
import '../utils/colors.dart';
import '../utils/common.dart';
import '../utils/constant.dart';
import '../utils/images.dart';
import 'empty_screen.dart';
import 'settings_screen.dart';

// Definir showAdCount si no está disponible en constant.dart
const int showAdCount = 5;

class ChattingScreen extends StatefulWidget {
  static String tag = '/gemini';

  final bool isDirect;

  ChattingScreen({this.isDirect = false});

  @override
  _ChattingScreenState createState() => _ChattingScreenState();
}

class _ChattingScreenState extends State<ChattingScreen> {
  late GeminiApiService _geminiApiService;
  List<Map<String, dynamic>> _chatHistory = [];

  ScrollController scrollController = ScrollController();

  TextEditingController msgController = TextEditingController();

  SpeechToText speech = SpeechToText();

  StreamSubscription<String>? _streamSubscription;

  final List<QuestionAnswerModel> questionAnswers = [];
  List<String> chipList = [
    'Definitions',
    'Synonyms',
    'Antonyms',
  ];

  int adCount = 0;
  int selectedIndex = -1;
  int selectedGeminiModel = 0;

  String lastError = "";
  String lastStatus = "";
  String selectedText = '';
  String question = '';

  bool isBannerLoad = false;
  bool isShowOption = false;
  bool isSelectedIndex = false;
  bool isScroll = false;

  @override
  void initState() {
    super.initState();
    _geminiApiService = GeminiApiService();
    init();
    initSpeechState();

    // Verificar la API key después de un breve retraso
    Future.delayed(Duration(milliseconds: 100), () {
      checkApiKeyAndNavigate();
    });
  }

  void checkApiKeyAndNavigate() {
    final apiKey = getStringAsync(GEMINI_API_KEY);
    print("API Key recuperada: '${apiKey.isNotEmpty ? 'No vacía' : 'VACÍA'}'");

    if (apiKey.isEmpty && mounted) {
      showConfirmDialogCustom(
          context,
          title: 'API Key no configurada',
          subTitle: 'Para usar la aplicación, necesitas configurar una API key de Google Gemini.',
          positiveText: 'Configurar',
          negativeText: 'Cancelar',
          dialogType: DialogType.CONFIRMATION,
          onAccept: (BuildContext dialogContext) {
            // Navegar a la pantalla de configuración
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen()),
            );
          }
      );
    } else {
      print("API Key está configurada correctamente");
    }
  }

  void init() async {
    afterBuildCreated(() {
      setStatusBarColor(Colors.white);
    });

    // Suscribirse al stream para recibir respuestas en tiempo real
    _streamSubscription = _geminiApiService.responseStream.listen(
            (chunk) {
          setState(() {
            if (questionAnswers.isNotEmpty) {
              questionAnswers.first.answer!.write(chunk);
            }
          });
        },
        onError: (error) {
          setState(() {
            if (questionAnswers.isNotEmpty) {
              questionAnswers.first.answer!.write("Error: $error");
            }
          });
          log("Stream error: $error");
        }
    );
  }

  Future<void> initSpeechState() async {
    await speech.initialize(onError: errorListener, onStatus: statusListener);
  }

  void startListening() {
    lastError = "";
    speech.listen(onResult: resultListener, pauseFor: Duration(seconds: 4));

    setState(() {});
  }

  void stopListening() {
    speech.stop();
    setState(() {});
  }

  void cancelListening() {
    speech.cancel();
    setState(() {});
  }

  void resultListener(SpeechRecognitionResult result) {
    log('Speech result=== $result');
    log('Speech result=== ${result.recognizedWords.capitalizeFirstLetter()}');
    msgController.text = "${result.recognizedWords.capitalizeFirstLetter()} ?";
    setState(() {});
  }

  void errorListener(SpeechRecognitionError error) {
    setState(() {
      lastError = "${error.errorMsg} - ${error.permanent}";
    });
  }

  void statusListener(String status) {
    setState(() {
      lastStatus = "$status";
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void sendMessage() async {
    hideKeyboard(context);

    if (selectedText.isNotEmpty) {
      question = selectedText + msgController.text;
      setState(() {});
    } else {
      question = msgController.text;
      setState(() {});
    }

    if (question.isEmpty) return;

    log('QUESTION: $question');
    setState(() {
      msgController.clear();
      questionAnswers.insert(0, QuestionAnswerModel(question: question, answer: StringBuffer(), isLoading: true, smartCompose: selectedText));
    });

    try {
      // Guardar el mensaje del usuario en el historial
      _chatHistory.add({
        'role': 'user',
        'content': question
      });

      // Si ya hay muchos mensajes en el historial, mantener solo los últimos 10
      if (_chatHistory.length > 20) {
        _chatHistory = _chatHistory.sublist(_chatHistory.length - 20);
      }

      if (selectedGeminiModel == 0) {
        // Para gemini-pro (modelo estándar)
        await _geminiApiService.generateContentStream(
          prompt: question,
          model: 'gemini-2.0-flash', // Modelo actualizado
          maxTokens: 4000,
          temperature: 0.7,
        );
      } else {
        // Para gemini-1.5-pro-latest (modelo avanzado)
        final response = await _geminiApiService.generateChat(
          messages: _chatHistory,
          model: 'gemini-1.5-pro-latest', // Modelo actualizado
          maxTokens: 4000,
          temperature: 0.7,
        );

        if (response.containsKey('candidates') &&
            response['candidates'].isNotEmpty &&
            response['candidates'][0].containsKey('content') &&
            response['candidates'][0]['content'].containsKey('parts') &&
            response['candidates'][0]['content']['parts'].isNotEmpty) {

          final text = response['candidates'][0]['content']['parts'][0]['text'];

          setState(() {
            questionAnswers.first.answer!.write(text);
          });

          // Guardar la respuesta en el historial
          _chatHistory.add({
            'role': 'model',
            'content': text
          });
        } else {
          setState(() {
            questionAnswers.first.answer!.write("No se recibió una respuesta válida de la API.");
          });
        }
      }

      if (adCount == showAdCount) {
      } else {
        adCount++;
      }

      log("========== AD count $adCount");
    } catch (error) {
      setState(() {
        questionAnswers.first.answer!.write("An error occurred: $error");
      });
      log("Error occurred: $error");
    } finally {
      setState(() {
        questionAnswers.first.isLoading = false;
      });
    }
  }

  void showDialog() {
    showConfirmDialogCustom(
      context,
      title: 'Do you want to clear the conversations?',
      positiveText: 'Yes',
      positiveTextColor: Colors.white,
      negativeText: 'No',
      dialogType: DialogType.CONFIRMATION,
      onAccept: (p0) {
        setState(() {
          questionAnswers.clear();
          _chatHistory.clear();
        });
      },
    );
  }

  void share(BuildContext context, {required List<QuestionAnswerModel> questionAnswers, RenderBox? box}) {
    String getFinalString = questionAnswers.map((e) => "Q: ${e.question}\nGemini: ${e.answer.toString().trim()}\n\n").join(' ');
    Share.share(getFinalString, sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
  }

  @override
  void dispose() {
    speech.stop();
    msgController.dispose();
    _streamSubscription?.cancel();
    _geminiApiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        'Gemini AI',
        elevation: 0,
        color: transparentColor,
        backWidget: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          visualDensity: VisualDensity.compact,
          onPressed: () {
            if (widget.isDirect.validate()) {
              ProKitLauncher().launch(context, isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
            } else {
              finish(context);
            }
          },
        ),
        actions: [
          // Botón de configuración
          CommonIconButton(
            icon: Icons.settings,
            toolTip: 'Configuración',
            onPressed: () {
              // Navegar a la pantalla de configuración
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
          CommonIconButton(
            icon: Icons.restart_alt,
            toolTip: 'Clear Conversation',
            onPressed: () {
              showDialog();
            },
          ).visible(questionAnswers.isNotEmpty),
          isIOS
              ? Builder(builder: (context) {
            return CommonIconButton(
              icon: Icons.share,
              iconSize: 20,
              toolTip: 'Share Conversation',
              onPressed: () {
                final box = context.findRenderObject() as RenderBox?;
                share(context, questionAnswers: questionAnswers, box: box);
              },
            ).visible(questionAnswers.isNotEmpty);
          })
              : CommonIconButton(
            icon: Icons.share,
            iconSize: 20,
            toolTip: 'Share Conversation',
            onPressed: () {
              final box = context.findRenderObject() as RenderBox?;
              share(context, questionAnswers: questionAnswers, box: box);
            },
          ).visible(questionAnswers.isNotEmpty),
          PopupMenuButton(
            onSelected: (value) {
              hideKeyboard(context);
              if (selectedGeminiModel != value) {
                selectedGeminiModel = value;
                setState(() {});
              }
            },
            icon: Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: 0,
                  child: SettingItemWidget(
                    title: 'Gemini Pro', // Actualizado
                    titleTextStyle: primaryTextStyle(color: selectedGeminiModel == 0 ? appColorPrimary : null),
                    subTitle: 'Modelo estándar',
                    subTitleTextStyle: secondaryTextStyle(color: selectedGeminiModel == 0 ? appColorPrimary : null),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: Icon(
                        Icons.auto_awesome,
                        size: 20,
                        color: selectedGeminiModel == 0 ? appColorPrimary : Colors.white
                    ),
                    trailing: Icon(Icons.check, size: 18, color: appColorPrimary).visible(selectedGeminiModel == 0),
                  ),
                ),
                PopupMenuItem(
                  value: 1,
                  child: SettingItemWidget(
                    title: 'Gemini 1.5 Pro', // Actualizado
                    titleTextStyle: primaryTextStyle(color: selectedGeminiModel == 1 ? appColorPrimary : null),
                    subTitle: 'Modelo avanzado',
                    subTitleTextStyle: secondaryTextStyle(color: selectedGeminiModel == 1 ? appColorPrimary : null),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: Icon(
                      Icons.auto_awesome_motion,
                      size: 22,
                      color: selectedGeminiModel == 1 ? appColorPrimary : Colors.white,
                    ),
                    trailing: Icon(Icons.check, size: 18, color: appColorPrimary).visible(selectedGeminiModel == 1),
                  ),
                )
              ];
            },
          ),
        ],
      ),
      bottomSheet: VoiceSearchComponent().visible(speech.isListening),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: Image.asset(chat_default_bg_image).image,
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(context.scaffoldBackgroundColor, BlendMode.multiply)
              ),
            ),
          ),
          Container(
            height: context.height(),
            width: context.width(),
            padding: EdgeInsets.only(left: 16, right: 16),
            child: ListView.separated(
              separatorBuilder: (_, i) => Divider(color: Colors.transparent),
              reverse: true,
              padding: EdgeInsets.only(bottom: 8, top: 16),
              controller: scrollController,
              itemCount: questionAnswers.length,
              itemBuilder: (_, index) {
                QuestionAnswerModel data = questionAnswers[index];

                String answer = data.answer.toString().trim();

                return ChatMessageWidget(answer: answer, data: data, isLoading: data.isLoading.validate());
              },
            ),
          ),
          if (questionAnswers.validate().isEmpty)
            EmptyScreen(
              isScroll: isScroll,
              onTap: (value) {
                msgController.text = value;
                setState(() {});
              },
            ).center(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (isShowOption)
                  Wrap(
                    spacing: 16,
                    children: List.generate(chipList.length, (index) {
                      return GestureDetector(
                        onTap: () {
                          if (index == selectedIndex) {
                            isSelectedIndex = !isSelectedIndex;
                          }

                          selectedIndex = index;

                          if (isSelectedIndex && index == selectedIndex) {
                            selectedText = '${chipList[index]} of ';
                          } else {
                            selectedText = '';
                          }

                          setState(() {});
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: boxDecorationDefault(
                            borderRadius: radius(20),
                            color: true
                                ? (index == selectedIndex && isSelectedIndex)
                                ? Colors.white
                                : replyMsgBgColor.withAlpha(90)
                                : (index == selectedIndex && isSelectedIndex)
                                ? Colors.white
                                : appColorPrimary.withAlpha(20),
                          ),
                          child: Text(chipList[index],
                              style: primaryTextStyle(
                                size: 14,
                                color: true
                                    ? (index == selectedIndex && isSelectedIndex)
                                    ? Colors.black
                                    : Colors.white
                                    : appColorPrimary,
                              )),
                        ),
                      );
                    }),
                  ),
                16.height,
                Row(
                  children: [
                    AppTextField(
                      textFieldType: TextFieldType.MULTILINE,
                      controller: msgController,
                      minLines: 1,
                      maxLines: 5,
                      cursorColor: Colors.white,
                      keyboardType: TextInputType.multiline,
                      decoration: inputDecoration(
                        context,
                        label: 'How can I help you!...',
                        prefixIcon: IconButton(
                          icon: Icon(Icons.mic, color: Colors.grey),
                          onPressed: () {
                            startListening();
                          },
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isShowOption ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            isShowOption = !isShowOption;

                            if (isShowOption == false) {
                              isSelectedIndex = false;
                              selectedText = '';
                            }

                            setState(() {});
                          },
                        ),
                      ),
                      onFieldSubmitted: (s) {
                        sendMessage();
                      },
                      onTap: () {
                        isScroll = true;
                        setState(() {});
                      },
                    ).expand(),
                    16.width,
                    Container(
                      decoration: boxDecorationDefault(
                        shape: BoxShape.circle,
                        color: appColorPrimary,
                        boxShadow: defaultBoxShadow(blurRadius: 0, shadowColor: Colors.transparent),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send, size: 16, color: Colors.white),
                        onPressed: () {
                          if (msgController.text.isNotEmpty) {
                            sendMessage();
                          }
                        },
                      ),
                    ),
                  ],
                ).paddingSymmetric(horizontal: 16),
                16.height,
              ],
            ),
          ),
        ],
      ),
    );
  }
}