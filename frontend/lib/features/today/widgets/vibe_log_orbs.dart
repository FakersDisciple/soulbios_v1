import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/vibe_provider.dart';

class VibeOrb {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final Color glowColor;
  final bool isCustom;

  VibeOrb({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.glowColor,
    this.isCustom = false,
  });
}

class VibeLogOrbs extends ConsumerStatefulWidget {
  const VibeLogOrbs({super.key});

  @override
  ConsumerState<VibeLogOrbs> createState() => _VibeLogOrbsState();
}

class _VibeLogOrbsState extends ConsumerState<VibeLogOrbs> {
  final Set<String> _selectedVibeIds = {};
  
  final List<VibeOrb> _vibes = [
    VibeOrb(
      id: 'awake',
      label: 'Awake',
      icon: Icons.lightbulb,
      color: const Color(0xFFFFB800),
      glowColor: const Color(0xFFFFB800).withValues(alpha: 0.4),
    ),
    VibeOrb(
      id: 'self_care',
      label: 'Self-Care',
      icon: Icons.favorite,
      color: const Color(0xFFFF4081),
      glowColor: const Color(0xFFFF4081).withValues(alpha: 0.4),
    ),
    VibeOrb(
      id: 'responsibilities',
      label: 'Responsibilities',
      icon: Icons.work_outline,
      color: const Color(0xFF2196F3),
      glowColor: const Color(0xFF2196F3).withValues(alpha: 0.4),
    ),
    VibeOrb(
      id: 'creativity',
      label: 'Creativity',
      icon: Icons.brush,
      color: const Color(0xFF4CAF50),
      glowColor: const Color(0xFF4CAF50).withValues(alpha: 0.4),
    ),
  ];

  void _selectVibe(String vibeId) {
    HapticFeedback.lightImpact();
    final vibe = _vibes.firstWhere((v) => v.id == vibeId);
    
    setState(() {
      if (_selectedVibeIds.contains(vibeId)) {
        _selectedVibeIds.remove(vibeId);
      } else {
        _selectedVibeIds.add(vibeId);
      }
    });
    
    // Update the active vibe colors provider
    final activeColors = _selectedVibeIds
        .map((id) => _vibes.firstWhere((v) => v.id == id).color)
        .toList();
    ref.read(activeVibeColorsProvider.notifier).state = activeColors;
    
    final isSelected = _selectedVibeIds.contains(vibeId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSelected 
            ? 'Vibe activated: ${vibe.label}' 
            : 'Vibe deactivated: ${vibe.label}'),
        backgroundColor: vibe.color,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _addCustomVibe() {
    showDialog(
      context: context,
      builder: (context) => _AddVibeDialog(
        onAdd: (vibe) {
          setState(() {
            _vibes.add(vibe);
          });
        },
      ),
    );
  }

  double _getOrbSize() {
    // Calculate orb size based on number of orbs
    // Start with base size and reduce as more orbs are added
    const baseSize = 80.0;
    const minSize = 50.0;
    final orbCount = _vibes.length;
    
    if (orbCount <= 4) return baseSize;
    
    // Reduce size gradually as orbs increase
    final reduction = (orbCount - 4) * 5.0;
    return (baseSize - reduction).clamp(minSize, baseSize);
  }

  Widget _buildVibeOrb(VibeOrb vibe) {
    final isSelected = _selectedVibeIds.contains(vibe.id);
    final orbSize = _getOrbSize();
    
    return GestureDetector(
      onTap: () => _selectVibe(vibe.id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: orbSize,
            height: orbSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  vibe.color.withValues(alpha: 0.8),
                  vibe.color.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: vibe.glowColor,
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: vibe.glowColor,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.9),
                border: Border.all(
                  color: isSelected ? vibe.color : Colors.white.withValues(alpha: 0.3),
                  width: isSelected ? 3 : 2,
                ),
              ),
              child: Icon(
                vibe.icon,
                color: vibe.color,
                size: orbSize * 0.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            vibe.label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    if (_vibes.length >= 7) return const SizedBox.shrink();
    
    final orbSize = _getOrbSize();
    
    return GestureDetector(
      onTap: _addCustomVibe,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: orbSize,
            height: orbSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.glassBg,
              border: Border.all(
                color: AppColors.glassBorder,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.add,
              color: AppColors.textSecondary,
              size: orbSize * 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _getOrbSize() + 80, // Orb size + label space + glow padding
      padding: const EdgeInsets.symmetric(vertical: 20), // Add vertical padding for glow
      clipBehavior: Clip.none, // Allow glow to extend beyond bounds
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none, // Allow glow to extend beyond scroll bounds
        padding: const EdgeInsets.symmetric(horizontal: 30), // Add horizontal padding for glow
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ..._vibes.map((vibe) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15), // Increase spacing for glow
              child: _buildVibeOrb(vibe),
            )),
            if (_vibes.length < 7) ...[
              const SizedBox(width: 15),
              _buildAddButton(),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddVibeDialog extends StatefulWidget {
  final Function(VibeOrb) onAdd;

  const _AddVibeDialog({required this.onAdd});

  @override
  State<_AddVibeDialog> createState() => _AddVibeDialogState();
}

class _AddVibeDialogState extends State<_AddVibeDialog> {
  final _labelController = TextEditingController();
  IconData _selectedIcon = Icons.star;
  Color _selectedColor = const Color(0xFF9C27B0);

  final List<IconData> _availableIcons = [
    Icons.star,
    Icons.favorite,
    Icons.lightbulb,
    Icons.flash_on,
    Icons.spa,
    Icons.self_improvement,
    Icons.psychology,
    Icons.emoji_emotions,
    Icons.local_fire_department,
    Icons.water_drop,
    Icons.air,
    Icons.nature,
  ];

  final List<Color> _availableColors = [
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFE91E63), // Pink
    const Color(0xFFFF5722), // Deep Orange
    const Color(0xFFFF9800), // Orange
    const Color(0xFFCDDC39), // Lime
    const Color(0xFF8BC34A), // Light Green
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF3F51B5), // Indigo
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E), // Solid dark background
      title: Text(
        'Add Custom Vibe',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelController,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Vibe Name',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.glassBorder),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Icon selection
          Text(
            'Choose Icon',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _availableIcons.map((icon) => GestureDetector(
              onTap: () => setState(() => _selectedIcon = icon),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIcon == icon 
                      ? _selectedColor.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedIcon == icon 
                        ? _selectedColor 
                        : AppColors.glassBorder,
                  ),
                ),
                child: Icon(icon, color: _selectedColor),
              ),
            )).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Color selection
          Text(
            'Choose Color',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _availableColors.map((color) => GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedColor == color 
                        ? Colors.white 
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_labelController.text.isNotEmpty) {
              final vibe = VibeOrb(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                label: _labelController.text,
                icon: _selectedIcon,
                color: _selectedColor,
                glowColor: _selectedColor.withValues(alpha: 0.4),
                isCustom: true,
              );
              widget.onAdd(vibe);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedColor,
          ),
          child: const Text('Add', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}