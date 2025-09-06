import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chamber_narrative.dart';
import '../models/character.dart';
import '../../../services/narrative_service.dart';

class NarrativeDialogueWidget extends ConsumerStatefulWidget {
  final String chamberId;
  final Character character;
  final Function(NarrativeState) onNarrativeComplete;
  final VoidCallback? onClose;

  const NarrativeDialogueWidget({
    super.key,
    required this.chamberId,
    required this.character,
    required this.onNarrativeComplete,
    this.onClose,
  });

  @override
  ConsumerState<NarrativeDialogueWidget> createState() => _NarrativeDialogueWidgetState();
}

class _NarrativeDialogueWidgetState extends ConsumerState<NarrativeDialogueWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  ChamberNarrative? _narrative;
  NarrativeState? _currentState;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadNarrative();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadNarrative() async {
    try {
      await NarrativeService().initialize();
      final narrative = NarrativeService().getNarrative(
        widget.chamberId,
        widget.character.archetype,
      );

      if (narrative == null) {
        setState(() {
          _error = 'Narrative not found for ${widget.chamberId} with ${widget.character.name}';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _narrative = narrative;
        _currentState = NarrativeState(currentNodeId: narrative.startNodeId);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load narrative: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            widget.character.primaryColor.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_narrative == null || _currentState == null) {
      return _buildErrorState();
    }

    final currentNode = _narrative!.getNode(_currentState!.currentNodeId);
    if (currentNode == null) {
      return _buildErrorState();
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _buildDialogueContent(currentNode),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(widget.character.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading narrative...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'An error occurred',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onClose,
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.character.primaryColor.withValues(alpha: 0.2),
        border: Border(
          bottom: BorderSide(
            color: widget.character.primaryColor,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.character.primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.character.primaryColor.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.character.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.chamberId.toUpperCase()} Chamber Guide',
                  style: TextStyle(
                    color: widget.character.primaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onClose != null)
            IconButton(
              onPressed: widget.onClose,
              icon: const Icon(
                Icons.close,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDialogueContent(NarrativeNode node) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Character dialogue
          Expanded(
            flex: 3,
            child: _buildDialogueText(node),
          ),
          
          const SizedBox(height: 16),
          
          // Choices or continue button
          Expanded(
            flex: 2,
            child: _buildInteractionArea(node),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogueText(NarrativeNode node) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3), // Parchment color
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Node type indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getNodeTypeColor(node.type),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getNodeTypeLabel(node.type),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Dialogue content
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                node.content,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionArea(NarrativeNode node) {
    if (node.choices.isNotEmpty) {
      return _buildChoices(node.choices);
    } else {
      return _buildContinueButton(node);
    }
  }

  Widget _buildChoices(List<NarrativeChoice> choices) {
    return Column(
      children: [
        const Text(
          'Choose your response:',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: choices.length,
            itemBuilder: (context, index) {
              final choice = choices[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildChoiceButton(choice, index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceButton(NarrativeChoice choice, int index) {
    final labels = ['A', 'B', 'C', 'D'];
    final label = index < labels.length ? labels[index] : '${index + 1}';

    return GestureDetector(
      onTap: () => _handleChoiceSelected(choice),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.character.primaryColor,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: widget.character.primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                choice.text,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(NarrativeNode node) {
    final isComplete = _narrative!.completionNodeIds.contains(node.id);
    
    return Center(
      child: ElevatedButton(
        onPressed: () => _handleContinue(node),
        style: ElevatedButton.styleFrom(
          backgroundColor: isComplete ? Colors.green : widget.character.primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          isComplete ? 'Complete Journey' : 'Continue',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _handleChoiceSelected(NarrativeChoice choice) async {
    if (_narrative == null || _currentState == null) return;

    try {
      final newState = await NarrativeService().processChoice(
        _narrative!,
        _currentState!,
        choice.id,
      );

      setState(() {
        _currentState = newState;
      });

      // Check if narrative is complete
      if (NarrativeService().isNarrativeComplete(_narrative!, newState)) {
        widget.onNarrativeComplete(newState);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to process choice: $e';
      });
    }
  }

  void _handleContinue(NarrativeNode node) {
    if (node.nextNodeId != null) {
      setState(() {
        _currentState = _currentState!.copyWith(
          currentNodeId: node.nextNodeId!,
          visitedNodes: [..._currentState!.visitedNodes, node.nextNodeId!],
          progressScore: _currentState!.progressScore + 10,
        );
      });

      // Check if narrative is complete
      if (_narrative != null && NarrativeService().isNarrativeComplete(_narrative!, _currentState!)) {
        widget.onNarrativeComplete(_currentState!);
      }
    } else {
      // This is a completion node
      widget.onNarrativeComplete(_currentState!);
    }
  }

  Color _getNodeTypeColor(NarrativeNodeType type) {
    switch (type) {
      case NarrativeNodeType.dialogue:
        return widget.character.primaryColor;
      case NarrativeNodeType.choice:
        return Colors.blue;
      case NarrativeNodeType.insight:
        return Colors.amber;
      case NarrativeNodeType.completion:
        return Colors.green;
    }
  }

  String _getNodeTypeLabel(NarrativeNodeType type) {
    switch (type) {
      case NarrativeNodeType.dialogue:
        return 'DIALOGUE';
      case NarrativeNodeType.choice:
        return 'CHOICE';
      case NarrativeNodeType.insight:
        return 'INSIGHT';
      case NarrativeNodeType.completion:
        return 'COMPLETE';
    }
  }
}