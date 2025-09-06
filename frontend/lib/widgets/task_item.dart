import 'package:flutter/material.dart';
import '../models/task.dart';
import '../theme.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback? onToggleComplete;
  
  const TaskItem({
    super.key,
    required this.task,
    this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: task.type == TaskType.ritual 
            ? LightModeColors.ritualTaskBackground 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Left side - Icon/Checkbox
          _buildLeftWidget(),
          const SizedBox(width: 16),
          
          // Middle - Task description
          Expanded(
            child: Text(
              task.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: task.isCompleted 
                    ? LightModeColors.taskTextSecondary 
                    : LightModeColors.taskTextPrimary,
                fontWeight: FontWeight.w500,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          
          // Right side - Time hint
          if (task.timeHint.isNotEmpty) ...[
            const SizedBox(width: 16),
            Text(
              task.timeHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: LightModeColors.taskTextSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildLeftWidget() {
    switch (task.type) {
      case TaskType.pinned:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.push_pin,
              size: 18,
              color: LightModeColors.warmYellowGlow,
            ),
            const SizedBox(width: 8),
            _buildCheckbox(),
          ],
        );
      case TaskType.routine:
        return _buildCheckbox();
      case TaskType.ritual:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            boxShadow: [
              BoxShadow(
                color: LightModeColors.ritualGlowColor.withValues(alpha: 0.6),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.nature,
            size: 20,
            color: LightModeColors.ritualGlowColor,
          ),
        );
      case TaskType.reflection:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),
          child: Icon(
            Icons.psychology,
            size: 20,
            color: LightModeColors.softPinkGlow,
          ),
        );
      case TaskType.courage:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),
          child: Icon(
            Icons.shield,
            size: 20,
            color: LightModeColors.vibrantGreenGlow,
          ),
        );
      case TaskType.connection:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),
          child: Icon(
            Icons.favorite,
            size: 20,
            color: LightModeColors.calmBlueGlow,
          ),
        );
    }
  }
  
  Widget _buildCheckbox() {
    return GestureDetector(
      onTap: onToggleComplete,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: task.isCompleted 
              ? LightModeColors.calmBlueGlow
              : Colors.transparent,
          border: Border.all(
            color: task.isCompleted 
                ? LightModeColors.calmBlueGlow
                : LightModeColors.taskCheckboxBorder,
            width: 2,
          ),
        ),
        child: task.isCompleted 
            ? Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}