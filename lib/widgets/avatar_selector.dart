import 'package:flutter/material.dart';

class Avatar {
  final String id;
  final String emoji;
  final String name;
  final Color color;

  const Avatar({
    required this.id,
    required this.emoji,
    required this.name,
    required this.color,
  });

  static const List<Avatar> availableAvatars = [
    Avatar(id: 'avatar_1', emoji: '🐱', name: 'Cat', color: Color(0xFFE74C3C)),
    Avatar(id: 'avatar_2', emoji: '🐶', name: 'Dog', color: Color(0xFF3498DB)),
    Avatar(id: 'avatar_3', emoji: '🐻', name: 'Bear', color: Color(0xFF8B4513)),
    Avatar(id: 'avatar_4', emoji: '🦊', name: 'Fox', color: Color(0xFFFF8C00)),
    Avatar(id: 'avatar_5', emoji: '🐸', name: 'Frog', color: Color(0xFF2ECC71)),
    Avatar(id: 'avatar_6', emoji: '🐧', name: 'Penguin', color: Color(0xFF34495E)),
  ];
}

class AvatarSelector extends StatelessWidget {
  final String? selectedAvatarId;
  final Function(String) onAvatarSelected;

  const AvatarSelector({
    super.key,
    required this.selectedAvatarId,
    required this.onAvatarSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: Avatar.availableAvatars.length,
      itemBuilder: (context, index) {
        final avatar = Avatar.availableAvatars[index];
        final isSelected = selectedAvatarId == avatar.id;
        
        return GestureDetector(
          onTap: () => onAvatarSelected(avatar.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? avatar.color : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? avatar.color : Colors.grey.shade300,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: avatar.color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  avatar.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 4),
                Text(
                  avatar.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
