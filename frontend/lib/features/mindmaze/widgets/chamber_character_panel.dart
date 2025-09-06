import 'package:flutter/material.dart';
import '../models/character.dart';

class ChamberCharacterPanel extends StatelessWidget {
  final Character? selectedCharacter;
  final List<Character> availableCharacters;
  final Function(Character) onCharacterSelected;
  final String? chamberType;

  const ChamberCharacterPanel({
    super.key,
    this.selectedCharacter,
    this.availableCharacters = const [],
    required this.onCharacterSelected,
    this.chamberType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Choose Your Guide',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (availableCharacters.isEmpty)
            Text(
              'No characters available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            )
          else
            ...availableCharacters.map((character) => _buildCharacterTile(
              context,
              character,
              selectedCharacter?.id == character.id,
            )),
        ],
      ),
    );
  }

  Widget _buildCharacterTile(BuildContext context, Character character, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onCharacterSelected(character),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected 
                ? character.primaryColor.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                  ? character.primaryColor
                  : Colors.white.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: character.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCharacterIcon(character.archetype),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        character.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        character.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: character.primaryColor,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCharacterIcon(CharacterArchetype archetype) {
    switch (archetype) {
      case CharacterArchetype.compassionateFriend:
        return Icons.favorite;
      case CharacterArchetype.resilientExplorer:
        return Icons.explore;
      case CharacterArchetype.wiseDetective:
        return Icons.psychology;
    }
  }
}