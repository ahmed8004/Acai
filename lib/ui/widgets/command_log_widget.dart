import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CommandLogWidget extends StatelessWidget {
  final List<String> commands;
  final int maxItems;

  const CommandLogWidget({
    super.key,
    required this.commands,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context) {
    final displayCommands = commands.length > maxItems 
        ? commands.sublist(commands.length - maxItems) 
        : commands;

    if (displayCommands.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No commands yet',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        reverse: true,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayCommands.length,
        itemBuilder: (context, index) {
          final command = displayCommands[displayCommands.length - 1 - index];
          return _buildCommandItem(command, index);
        },
      ),
    );
  }

  Widget _buildCommandItem(String command, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              command,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
