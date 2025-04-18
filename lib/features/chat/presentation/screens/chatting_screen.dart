import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../config/constants/app_constans.dart';
import '../../../../config/models/chat_conversation.dart';
import '../../../../config/models/chat_message.dart';
import '../../../conversation/colors.dart';
import '../../../conversation/components/commonIconButton.dart';
import '../../../conversation/components/voice_search_component.dart';
import '../../../conversation/screens/empty_screen.dart';
import '../../../conversation/utils/colors.dart';
import '../../../conversation/utils/common.dart';
import '../../../conversation/utils/images.dart';
import '../providers/conversation_provider.dart';
import '../providers/gemini_provider.dart';
import 'settings_screen.dart';

class ChattingScreens extends ConsumerStatefulWidget {
  static String tag = '/gemini';

  final bool isDirect;
  final String? conversationId;

  ChattingScreens({this.isDirect = false, this.conversationId});

  @override
  ConsumerState<ChattingScreens> createState() => _ChattingScreenState();
}

class _ChattingScreenState extends ConsumerState<ChattingScreens> {
  ScrollController scrollController = ScrollController();
  TextEditingController msgController = TextEditingController();
  SpeechToText speech = SpeechToText();

  ChatConversation? currentConversation;
  String activeConversationId = '';

  List<String> chipList = [
    'Definitions',
    'Synonyms',
    'Antonyms',
  ];

  int adCount = 0;
  int selectedIndex = -1;

  String lastError = "";
  String lastStatus = "";
  String selectedText = '';

  bool isShowOption = false;
  bool isSelectedIndex = false;
  bool isScroll = false;

  @override
  void initState() {
    super.initState();
    initSpeechState();
    _initConversation();

    Future.delayed(Duration(milliseconds: 100), () {
      checkApiKeyAndNavigate();
    });
  }

  Future<void> _initConversation() async {
    if (widget.conversationId != null && widget.conversationId!.isNotEmpty) {
      try {
        final id = int.tryParse(widget.conversationId!) ?? -1;
        if (id > 0) {
          currentConversation = await ref.read(conversationsProvider.notifier).getConversation(id);
          if (currentConversation != null) {
            activeConversationId = widget.conversationId!;
            ref.read(messagesProvider(activeConversationId).notifier).loadMessages();
          }
        }
      } catch (e) {
        print('Error al cargar la conversación: $e');
      }
    }

    if (activeConversationId.isEmpty) {
      final id = await ref.read(conversationsProvider.notifier).createConversation(
          'Nueva conversación ${DateTime.now().toString().substring(0, 16)}'
      );
      activeConversationId = id.toString();
      currentConversation = await ref.read(conversationsProvider.notifier).getConversation(id);
      ref.read(messagesProvider(activeConversationId).notifier).setConversationId(activeConversationId);
    }
  }

  void checkApiKeyAndNavigate() async {
    final apiKeyConfigured = await ref.read(apiKeyConfiguredProvider.future);

    if (!apiKeyConfigured && mounted) {
      showConfirmDialogCustom(
          context,
          title: 'API Key no configurada',
          subTitle: 'Para usar la aplicación, necesitas configurar una API key de Google Gemini.',
          positiveText: 'Configurar',
          negativeText: 'Cancelar',
          dialogType: DialogType.CONFIRMATION,
          onAccept: (BuildContext dialogContext) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen()),
            );
          }
      );
    }
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

    final question = selectedText.isNotEmpty
        ? selectedText + msgController.text
        : msgController.text;

    if (question.isEmpty) return;

    await ref.read(messagesProvider(activeConversationId).notifier)
        .addMessage('user', question);

    final messageProv = ref.read(messagesProvider(activeConversationId).notifier);
    final geminiMessages = messageProv.getMessagesForGemini();

    try {
      final selectedModel = currentConversation?.modelName ?? AppConstants.DEFAULT_GEMINI_MODEL;

      await messageProv.addMessage('model', 'Generando respuesta...', isError: true);

      final geminiService = ref.read(geminiServiceProvider);
      final response = await geminiService.generateChat(
        messages: geminiMessages,
        model: selectedModel,
        maxTokens: AppConstants.DEFAULT_MAX_TOKENS,
        temperature: AppConstants.DEFAULT_TEMPERATURE,
      );

      final loadingMessage = ref.read(messagesProvider(activeConversationId)).messages
          .firstWhere((msg) => msg.isError && msg.content == 'Generando respuesta...');
      await messageProv.deleteMessage(loadingMessage.id);

      if (response.containsKey('candidates') &&
          response['candidates'].isNotEmpty &&
          response['candidates'][0].containsKey('content') &&
          response['candidates'][0]['content'].containsKey('parts') &&
          response['candidates'][0]['content']['parts'].isNotEmpty) {

        final text = response['candidates'][0]['content']['parts'][0]['text'];
        await messageProv.addMessage('model', text);
      } else {
        await messageProv.addMessage(
            'model',
            'No se recibió una respuesta válida de la API.',
            isError: true
        );
      }
    } catch (e) {
      try {
        final messages = ref.read(messagesProvider(activeConversationId)).messages;
        final loadingMessage = messages.firstWhere(
              (msg) => msg.isError == true && msg.content == 'Generando respuesta...',
          orElse: () => null!,
        );

        if (loadingMessage != null) {
          await messageProv.deleteMessage(loadingMessage.id);
        }
      } catch (e) {
        print('No se encontró mensaje de carga para eliminar: $e');
      }

      await messageProv.addMessage(
          'model',
          'Error: ${e.toString()}',
          isError: true,
          errorMessage: e.toString()
      );
    }

    msgController.clear();
    selectedText = '';

    if (adCount == AppConstants.SHOW_AD_COUNT) {} else {
      adCount++;
    }
  }

  void showClearDialog() {
    showConfirmDialogCustom(
      context,
      title: '¿Deseas borrar todas las conversaciones?',
      positiveText: 'Sí',
      positiveTextColor: Colors.white,
      negativeText: 'No',
      dialogType: DialogType.CONFIRMATION,
      onAccept: (p0) async {
        await ref.read(messagesProvider(activeConversationId).notifier).setConversationId('');
        await ref.read(conversationsProvider.notifier).deleteConversation(
            int.parse(activeConversationId)
        );
        await _initConversation();
      },
    );
  }

  void share(BuildContext context, {required List<ChatMessage> messages, RenderBox? box}) {
    String shareText = messages
        .map((e) => "Q: ${e.role == 'user' ? e.content : ''}\nGemini: ${e.role == 'model' ? e.content : ''}")
        .join('\n\n');

    Share.share(shareText, sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
  }

  @override
  void dispose() {
    speech.stop();
    msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(messagesProvider(activeConversationId));
    final messages = messagesState.messages;
    final isLoading = messagesState.isLoading;

    return Scaffold(
      appBar: appBarWidget(
        currentConversation?.title ?? 'Gemini AI',
        elevation: 0,
        color: transparentColor,
        backWidget: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          visualDensity: VisualDensity.compact,
          onPressed: () {
            finish(context);
          },
        ),
        actions: [
          CommonIconButton(
            icon: Icons.settings,
            toolTip: 'Configuración',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
          CommonIconButton(
            icon: Icons.restart_alt,
            toolTip: 'Limpiar Conversación',
            onPressed: () {
              showClearDialog();
            },
          ).visible(messages.isNotEmpty),
          isIOS
              ? Builder(builder: (context) {
            return CommonIconButton(
              icon: Icons.share,
              iconSize: 20,
              toolTip: 'Compartir Conversación',
              onPressed: () {
                final box = context.findRenderObject() as RenderBox?;
                share(context, messages: messages, box: box);
              },
            ).visible(messages.isNotEmpty);
          })
              : CommonIconButton(
            icon: Icons.share,
            iconSize: 20,
            toolTip: 'Compartir Conversación',
            onPressed: () {
              final box = context.findRenderObject() as RenderBox?;
              share(context, messages: messages, box: box);
            },
          ).visible(messages.isNotEmpty),
          PopupMenuButton(
            onSelected: (value) async {
              hideKeyboard(context);
              if (currentConversation != null) {
                currentConversation!.modelName = value == 0
                    ? AppConstants.DEFAULT_GEMINI_MODEL
                    : AppConstants.GEMINI_ADVANCED_MODEL;

                await ref.read(conversationsProvider.notifier)
                    .updateConversation(currentConversation!);

                setState(() {});
              }
            },
            icon: Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) {
              final isDefaultModel = currentConversation?.modelName == AppConstants.DEFAULT_GEMINI_MODEL;

              return [
                PopupMenuItem(
                  value: 0,
                  child: SettingItemWidget(
                    title: 'Gemini Pro',
                    titleTextStyle: primaryTextStyle(color: isDefaultModel ? appColorPrimary : null),
                    subTitle: 'Modelo estándar',
                    subTitleTextStyle: secondaryTextStyle(color: isDefaultModel ? appColorPrimary : null),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: Icon(
                        Icons.auto_awesome,
                        size: 20,
                        color: isDefaultModel ? appColorPrimary : Colors.white
                    ),
                    trailing: Icon(Icons.check, size: 18, color: appColorPrimary).visible(isDefaultModel),
                  ),
                ),
                PopupMenuItem(
                  value: 1,
                  child: SettingItemWidget(
                    title: 'Gemini 1.5 Pro',
                    titleTextStyle: primaryTextStyle(color: !isDefaultModel ? appColorPrimary : null),
                    subTitle: 'Modelo avanzado',
                    subTitleTextStyle: secondaryTextStyle(color: !isDefaultModel ? appColorPrimary : null),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: Icon(
                      Icons.auto_awesome_motion,
                      size: 22,
                      color: !isDefaultModel ? appColorPrimary : Colors.white,
                    ),
                    trailing: Icon(Icons.check, size: 18, color: appColorPrimary).visible(!isDefaultModel),
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
          if (isLoading)
            Center(child: CircularProgressIndicator()),
          if (!isLoading) Container(
            height: context.height(),
            width: context.width(),
            padding: EdgeInsets.only(left: 16, right: 16),
            child: ListView.separated(
              separatorBuilder: (_, i) => Divider(color: Colors.transparent),
              reverse: true,
              padding: EdgeInsets.only(bottom: 8, top: 16),
              controller: scrollController,
              itemCount: messages.length,
              itemBuilder: (_, index) {
                final message = messages[index];
                final isUserMessage = message.role == 'user';

                return isUserMessage
                    ? UserMessageWidget(message: message)
                    : BotMessageWidget(
                  message: message,
                  isLoading: message.isError && message.content == 'Generando respuesta...',
                );
              },
            ),
          ),
          if (!isLoading && messages.isEmpty)
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
                            color: (index == selectedIndex && isSelectedIndex)
                                ? Colors.white
                                : replyMsgBgColor.withAlpha(90),
                          ),
                          child: Text(chipList[index],
                              style: primaryTextStyle(
                                size: 14,
                                color: (index == selectedIndex && isSelectedIndex)
                                    ? Colors.black
                                    : Colors.white,
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
                        label: '¿En qué puedo ayudarte?...',
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

class UserMessageWidget extends StatelessWidget {
  final ChatMessage message;

  UserMessageWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: EdgeInsets.only(top: 3.0, bottom: 3.0, right: 0, left: (500 * 0.10).toDouble()),
      decoration: boxDecorationDefault(
        color: appColorPrimary,
        boxShadow: defaultBoxShadow(blurRadius: 0, shadowColor: Colors.transparent),
        borderRadius: radiusOnly(bottomLeft: 16, topLeft: 16, topRight: 16),
      ),
      child: SelectableText(
        'Q: ${message.content}',
        style: primaryTextStyle(size: 14),
      ),
    );
  }
}

class BotMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final bool isLoading;

  BotMessageWidget({required this.message, this.isLoading = false});

  @override
  State<BotMessageWidget> createState() => _BotMessageWidgetState();
}

class _BotMessageWidgetState extends State<BotMessageWidget> {
  FlutterTts flutterTts = FlutterTts();
  bool isSpeak = false;

  @override
  void initState() {
    super.initState();
  }

  void botSpeak({required String text}) async {
    await flutterTts.setLanguage("es-ES");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1);

    if (text.isNotEmpty) {
      await flutterTts.speak(text);
    }
  }

  void share(BuildContext context, {String? answer, RenderBox? box}) async {
    await Share.share(
      'Gemini: ${answer.validate()}',
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
        botSpeak(text: widget.message.content);
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
      share(context, answer: widget.message.content, box: box);
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: [
        16.height,
        Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: EdgeInsets.only(top: 4.0, bottom: 4.0, left: 0, right: (500 * 0.14).toDouble()),
                decoration: boxDecorationDefault(
                  color: widget.message.isError ? Colors.red.withOpacity(0.2) : replyMsgBgColor,
                  boxShadow: defaultBoxShadow(blurRadius: 0, shadowColor: Colors.transparent),
                  borderRadius: radiusOnly(topLeft: 16, bottomRight: 16, topRight: 16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      widget.message.isError ? 'Error: ${widget.message.content}' : 'Ans: ${widget.message.content}',
                      style: primaryTextStyle(
                          size: 14,
                          color: widget.message.isError ? Colors.red : Colors.white
                      ),
                    ),
                    if (!widget.message.isError) ...[
                      8.height,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${widget.message.content.calculateReadTime().toStringAsFixed(1).toDouble().ceil()} min read",
                            style: secondaryTextStyle(color: Colors.white54, size: 12),
                          ),
                          Spacer(),
                          shareIconWidget(),
                          8.width,
                          speakIconWidget(),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            ),
            if (!widget.message.isError)
              Positioned(
                right: 25,
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: decoration(),
                  child: Icon(Icons.copy, size: 16, color: Colors.white),
                ).onTap(() {
                  widget.message.content.copyToClipboard();
                  toast('Copiado al portapapeles');
                }),
              ),
          ],
        ),
      ],
    );
  }
}