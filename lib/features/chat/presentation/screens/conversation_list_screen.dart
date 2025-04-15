import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:intl/intl.dart';

import '../../../../config/models/chat_conversation.dart';
import '../../../conversation/colors.dart';
import '../../../conversation/utils/colors.dart';
import '../providers/conversation_provider.dart';
import 'settings_screen.dart';

class ConversationsListScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends ConsumerState<ConversationsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationsProvider.notifier).loadConversations();
    });
  }

  void _createNewConversation() async {
    final id = await ref.read(conversationsProvider.notifier).createConversation(
        'Nueva conversación ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'
    );

    context.pushNamed('chat', queryParams: {'id': id.toString()});
  }

  void _goToSettings() {
    context.pushNamed('settings');
  }

  void _deleteAllConversations() {
    showConfirmDialogCustom(
      context,
      title: '¿Eliminar todas las conversaciones?',
      subTitle: 'Esta acción no se puede deshacer.',
      positiveText: 'Eliminar',
      negativeText: 'Cancelar',
      dialogType: DialogType.DELETE,
      onAccept: (context) {
        ref.read(conversationsProvider.notifier).deleteAllConversations();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversationsState = ref.watch(conversationsProvider);
    final conversations = conversationsState.conversations;
    final isLoading = conversationsState.isLoading;
    final error = conversationsState.error;

    return Scaffold(
      appBar: AppBar(
        title: Text('Conversaciones'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _goToSettings,
            tooltip: 'Configuración',
          ),
          if (conversations.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep),
              onPressed: _deleteAllConversations,
              tooltip: 'Eliminar todas',
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewConversation,
        child: Icon(Icons.add),
        tooltip: 'Nueva conversación',
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            8.height,
            Text('Error: $error', style: primaryTextStyle(color: Colors.red)),
            16.height,
            ElevatedButton(
              onPressed: () => ref.read(conversationsProvider.notifier).loadConversations(),
              child: Text('Reintentar'),
            ),
          ],
        ),
      )
          : conversations.isEmpty
          ? _buildEmptyState()
          : _buildConversationsList(conversations),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
          16.height,
          Text('No hay conversaciones', style: boldTextStyle(size: 18)),
          8.height,
          Text(
            'Inicia una nueva conversación con Gemini AI',
            style: secondaryTextStyle(),
            textAlign: TextAlign.center,
          ),
          24.height,
          ElevatedButton.icon(
            onPressed: _createNewConversation,
            icon: Icon(Icons.add),
            label: Text('Nueva conversación'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ).paddingAll(16),
    );
  }

  Widget _buildConversationsList(List<ChatConversation> conversations) {
    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: conversations.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return ConversationTile(
          conversation: conversation,
          onTap: () {
            context.pushNamed('chat', queryParams: {'id': conversation.id.toString()});
          },
          onDelete: () {
            ref.read(conversationsProvider.notifier).deleteConversation(conversation.id);
          },
        );
      },
    );
  }
}

class ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ConversationTile({
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(conversation.lastModified!);
    final isDefaultModel = conversation.modelName.contains('flash');

    return Container(
      decoration: boxDecorationDefault(
        borderRadius: radius(8),
        color: replyMsgBgColor.withOpacity(0.3),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          conversation.title,
          style: boldTextStyle(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            4.height,
            Text(
              'Última actualización: $formattedDate',
              style: secondaryTextStyle(size: 12),
            ),
            4.height,
            Row(
              children: [
                Icon(
                  isDefaultModel ? Icons.auto_awesome : Icons.auto_awesome_motion,
                  size: 14,
                  color: appColorPrimary,
                ),
                4.width,
                Text(
                  isDefaultModel ? 'Gemini Pro' : 'Gemini 1.5 Pro',
                  style: secondaryTextStyle(size: 12, color: appColorPrimary),
                ),
              ],
            ),
          ],
        ),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: appColorPrimary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.chat, color: appColorPrimary),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red.withOpacity(0.7)),
          onPressed: () {
            showConfirmDialogCustom(
              context,
              title: '¿Eliminar esta conversación?',
              positiveText: 'Eliminar',
              negativeText: 'Cancelar',
              dialogType: DialogType.DELETE,
              onAccept: (context) {
                onDelete();
              },
            );
          },
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: radius(8)),
      ),
    );
  }
}