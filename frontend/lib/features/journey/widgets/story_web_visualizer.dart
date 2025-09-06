import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Note: GraphView implementation simplified for compatibility
import '../../../core/theme/app_colors.dart';
import '../../../models/api_models.dart';
import '../../../widgets/glassmorphic_card.dart';
import '../../../services/alice_service.dart';
import '../../../utils/performance_optimizer.dart';

class StoryWebVisualizer extends ConsumerStatefulWidget {
  final List<PatternNode> nodes;
  final bool isPro;
  final VoidCallback? onUpgradeRequested;

  const StoryWebVisualizer({
    super.key,
    required this.nodes,
    this.isPro = false,
    this.onUpgradeRequested,
  });

  @override
  ConsumerState<StoryWebVisualizer> createState() => _StoryWebVisualizerState();
}

class _StoryWebVisualizerState extends ConsumerState<StoryWebVisualizer>
    with TickerProviderStateMixin {
  // Simplified graph representation for now
  Map<String, PatternNode> nodeMap = {};
  late AnimationController _revealController;
  late AnimationController _pulseController;
  
  final Set<String> _revealedNodes = {};
  final Map<String, AnimationController> _nodeAnimations = {};
  
  @override
  void initState() {
    super.initState();
    
    _revealController = OptimizedAnimationController.create(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
      debugLabel: 'StoryWebRevealController',
    );
    
    _pulseController = OptimizedAnimationController.create(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
      debugLabel: 'StoryWebPulseController',
    )..repeat(reverse: true);
    
    _buildGraph();
    
    // Reveal initial nodes
    if (widget.nodes.isNotEmpty) {
      _revealNode(widget.nodes.first.id);
    }
  }

  @override
  void didUpdateWidget(StoryWebVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.nodes != oldWidget.nodes) {
      _buildGraph();
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    _pulseController.dispose();
    for (final controller in _nodeAnimations.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _buildGraph() {
    nodeMap.clear();
    for (final node in widget.nodes) {
      nodeMap[node.id] = node;
    }
  }

  void _revealNode(String nodeId) {
    if (_revealedNodes.contains(nodeId)) return;
    
    setState(() {
      _revealedNodes.add(nodeId);
    });
    
    // Create animation for this node
    final controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _nodeAnimations[nodeId] = controller;
    controller.forward();
    
    // Reveal connected nodes after delay
    final node = widget.nodes.firstWhere((n) => n.id == nodeId);
    Future.delayed(const Duration(milliseconds: 500), () {
      for (final connectionId in node.connectionIds) {
        if (!_revealedNodes.contains(connectionId)) {
          _revealNode(connectionId);
        }
      }
    });
  }

  void _showNodeDetails(PatternNode node) async {
    if (!widget.isPro) {
      widget.onUpgradeRequested?.call();
      return;
    }

    // Generate AI prompt for this pattern
    final aliceService = ref.read(aliceServiceProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return GlassmorphicCard(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Node title
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: node.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          node.label,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Pattern info
                  Text(
                    'Pattern: ${node.pattern}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  
                  Text(
                    'Discovered: ${_formatDate(node.discoveredAt)}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // AI-generated insights
                  Expanded(
                    child: FutureBuilder<String?>(
                      future: _generateInsight(node),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: AppColors.warmGold,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Alice is analyzing this pattern...',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Unable to generate insights at this time.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }
                        
                        return SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alice\'s Insight:',
                                style: TextStyle(
                                  color: AppColors.warmGold,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                snapshot.data ?? 'No insights available.',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String?> _generateInsight(PatternNode node) async {
    try {
      final aliceService = ref.read(aliceServiceProvider);
      final prompt = "I've been exploring the pattern '${node.label}' in my life story web. "
          "This pattern was identified as '${node.pattern}' and connects to other themes. "
          "What deeper insight can you share about this pattern and how it might be serving or limiting me?";
      
      // This would call the Alice service to generate insights
      // For now, return a placeholder
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      return "This pattern often emerges as a protective mechanism, helping you navigate "
          "challenging situations. However, it may also be limiting your growth in unexpected ways. "
          "Consider how this pattern serves you and where it might be holding you back from "
          "your authentic expression.";
    } catch (e) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPro) {
      return _buildProUpgradePrompt();
    }

    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.hub,
                color: AppColors.deepPurple,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Your Story Web',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_revealedNodes.length}/${widget.nodes.length} revealed',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: AppColors.glassBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 2.0,
              child: CustomPaint(
                painter: NodeConnectionPainter(
                  nodes: widget.nodes,
                  revealedNodes: _revealedNodes,
                ),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: widget.nodes.map((patternNode) {
                    final isRevealed = _revealedNodes.contains(patternNode.id);
                    
                    return AnimatedBuilder(
                      animation: _nodeAnimations[patternNode.id] ?? 
                                 AlwaysStoppedAnimation(isRevealed ? 1.0 : 0.0),
                      builder: (context, child) {
                        final animationValue = _nodeAnimations[patternNode.id]?.value ?? 
                                             (isRevealed ? 1.0 : 0.0);
                        
                        return Transform.scale(
                          scale: animationValue,
                          child: Opacity(
                            opacity: isRevealed ? 1.0 : 0.3,
                            child: GestureDetector(
                              onTap: isRevealed ? () => _showNodeDetails(patternNode) : null,
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  final pulseScale = isRevealed ? 
                                    1.0 + (_pulseController.value * 0.05) : 1.0;
                                  
                                  return Transform.scale(
                                    scale: pulseScale,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12, 
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isRevealed 
                                          ? patternNode.color.withValues(alpha: 0.2)
                                          : AppColors.glassBg,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isRevealed 
                                            ? patternNode.color
                                            : AppColors.glassBorder,
                                          width: 2,
                                        ),
                                        boxShadow: isRevealed ? [
                                          BoxShadow(
                                            color: patternNode.color.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ] : null,
                                      ),
                                      child: Text(
                                        isRevealed ? patternNode.label : '???',
                                        style: TextStyle(
                                          color: isRevealed 
                                            ? AppColors.textPrimary
                                            : AppColors.textTertiary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Tap revealed nodes to explore deeper insights',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProUpgradePrompt() {
    return GlassmorphicCard(
      onTap: widget.onUpgradeRequested,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome,
            color: AppColors.warmGold,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Unlock Your Story Web',
            style: TextStyle(
              color: AppColors.warmGold,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover how your life patterns connect in an interactive web of insights. '
            'See the hidden threads that weave through your experiences and unlock '
            'deeper understanding of your personal narrative.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.deepPurple, AppColors.warmGold],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              'Upgrade to Pro',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NodeConnectionPainter extends CustomPainter {
  final List<PatternNode> nodes;
  final Set<String> revealedNodes;

  NodeConnectionPainter({
    required this.nodes,
    required this.revealedNodes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.glassBorder
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw connections between revealed nodes
    for (final node in nodes) {
      if (!revealedNodes.contains(node.id)) continue;
      
      for (final connectionId in node.connectionIds) {
        if (!revealedNodes.contains(connectionId)) continue;
        
        final connectedNode = nodes.firstWhere(
          (n) => n.id == connectionId,
          orElse: () => node,
        );
        
        if (connectedNode != node) {
          // Draw a simple line connection
          // In a real implementation, you'd calculate actual node positions
          canvas.drawLine(
            Offset(size.width * 0.3, size.height * 0.3),
            Offset(size.width * 0.7, size.height * 0.7),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}