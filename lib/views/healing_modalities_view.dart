import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/healing_modality.dart';
import '../constants/colors/color_constants.dart';
import '../constants/strings/asset_constants.dart';
import '../l10n/app_localizations.dart';

class HealingModalitiesView extends ConsumerWidget {
  const HealingModalitiesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.healingModalities),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorConstants.oceanBlue.withValues(alpha: 0.1),
                    ColorConstants.seafoam.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.exploreModalities,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.oceanBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.modalityDescription,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: ColorConstants.lightOnSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Modalities grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: HealingModality.allModalities.length,
              itemBuilder: (context, index) {
                final modality = HealingModality.allModalities[index];
                return _ModalityCard(modality: modality);
              },
            ),
            
            const SizedBox(height: 24),
            
            // Call to action
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ColorConstants.oceanBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.startHealingJourney,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to first modality or onboarding
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: ColorConstants.oceanBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: Text(
                      l10n.continueText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalityCard extends StatelessWidget {
  final HealingModality modality;

  const _ModalityCard({required this.modality});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to modality detail view
        _showModalityDetail(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and background
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      modality.color.withValues(alpha: 0.1),
                      modality.color.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: modality.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getModalityIcon(modality.type),
                      size: 32,
                      color: modality.color,
                    ),
                  ),
                ),
              ),
            ),
            
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modality.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.lightOnSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${modality.sessionCount} sessions',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColorConstants.lightOnSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: modality.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Explore',
                          style: TextStyle(
                            color: modality.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getModalityIcon(HealingModalityType type) {
    switch (type) {
      case HealingModalityType.meditation:
        return Icons.self_improvement;
      case HealingModalityType.soundHealing:
        return Icons.volume_up;
      case HealingModalityType.yoga:
        return Icons.accessibility_new;
      case HealingModalityType.journaling:
        return Icons.edit_note;
      case HealingModalityType.nature:
        return Icons.nature;
      case HealingModalityType.creative:
        return Icons.palette;
      case HealingModalityType.sleep:
        return Icons.bedtime;
      case HealingModalityType.emotional:
        return Icons.favorite;
      case HealingModalityType.energy:
        return Icons.energy_savings_leaf;
      case HealingModalityType.breathwork:
        return Icons.air;
    }
  }

  void _showModalityDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModalityDetailSheet(modality: modality),
    );
  }
}

class _ModalityDetailSheet extends StatelessWidget {
  final HealingModality modality;

  const _ModalityDetailSheet({required this.modality});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: modality.color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getModalityIcon(modality.type),
                          size: 24,
                          color: modality.color,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              modality.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${modality.sessionCount} sessions available',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  Text(
                    modality.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Benefits
                  Text(
                    'Benefits',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...modality.benefits.map((benefit) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: modality.color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            benefit,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
                  
                  const SizedBox(height: 32),
                  
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to modality sessions
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: modality.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Start Practicing',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getModalityIcon(HealingModalityType type) {
    switch (type) {
      case HealingModalityType.meditation:
        return Icons.self_improvement;
      case HealingModalityType.soundHealing:
        return Icons.volume_up;
      case HealingModalityType.yoga:
        return Icons.accessibility_new;
      case HealingModalityType.journaling:
        return Icons.edit_note;
      case HealingModalityType.nature:
        return Icons.nature;
      case HealingModalityType.creative:
        return Icons.palette;
      case HealingModalityType.sleep:
        return Icons.bedtime;
      case HealingModalityType.emotional:
        return Icons.favorite;
      case HealingModalityType.energy:
        return Icons.energy_savings_leaf;
      case HealingModalityType.breathwork:
        return Icons.air;
    }
  }
}




