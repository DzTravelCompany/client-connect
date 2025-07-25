import 'package:fluent_ui/fluent_ui.dart';
import 'design_tokens.dart';
import 'component_library.dart';
import 'layout_system.dart';
import 'animation_system.dart';
import 'accessibility_utils.dart';

/// Design system showcase for testing and documentation
class DesignSystemShowcase extends StatefulWidget {
  const DesignSystemShowcase({super.key});

  @override
  State<DesignSystemShowcase> createState() => _DesignSystemShowcaseState();
}

class _DesignSystemShowcaseState extends State<DesignSystemShowcase> {
  int _selectedIndex = 0;
  
  final List<ShowcaseSection> _sections = [
    ShowcaseSection('Colors', FluentIcons.color),
    ShowcaseSection('Typography', FluentIcons.font_size),
    ShowcaseSection('Buttons', FluentIcons.button_control),
    ShowcaseSection('Cards', FluentIcons.collapse_content_single),
    ShowcaseSection('Forms', FluentIcons.form_library),
    ShowcaseSection('Layout', FluentIcons.p_b_i_home_layout_default),
    ShowcaseSection('Animations', FluentIcons.play),
    ShowcaseSection('Accessibility', FluentIcons.accessibilty_checker),
  ];

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(
        title: Text('Design System Showcase'),
      ),
      content: Row(
        children: [
          // Navigation sidebar
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: DesignTokens.surfaceSecondary,
              border: Border(
                right: BorderSide(color: DesignTokens.borderPrimary),
              ),
            ),
            child: ListView.builder(
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                final section = _sections[index];
                return DesignSystemComponents.navigationItem(
                  label: section.title,
                  icon: section.icon,
                  isActive: _selectedIndex == index,
                  onPressed: () => setState(() => _selectedIndex = index),
                );
              },
            ),
          ),
          
          // Content area
          Expanded(
            child: LayoutSystem.pageContainer(
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildColorsShowcase();
      case 1:
        return _buildTypographyShowcase();
      case 2:
        return _buildButtonsShowcase();
      case 3:
        return _buildCardsShowcase();
      case 4:
        return _buildFormsShowcase();
      case 5:
        return _buildLayoutShowcase();
      case 6:
        return _buildAnimationsShowcase();
      case 7:
        return _buildAccessibilityShowcase();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildColorsShowcase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutSystem.sectionHeader(title: 'Color System'),
        
        LayoutSystem.sectionContainer(
          title: 'Primary Colors',
          child: Wrap(
            spacing: DesignTokens.space4,
            runSpacing: DesignTokens.space4,
            children: [
              _buildColorSwatch('Primary Blue', DesignTokens.primaryBlue),
              _buildColorSwatch('Primary Blue Light', DesignTokens.primaryBlueLight),
              _buildColorSwatch('Primary Blue Dark', DesignTokens.primaryBlueDark),
            ],
          ),
        ),
        
        LayoutSystem.sectionContainer(
          title: 'Accent Colors',
          child: Wrap(
            spacing: DesignTokens.space4,
            runSpacing: DesignTokens.space4,
            children: [
              _buildColorSwatch('Accent Primary', DesignTokens.accentPrimary),
              _buildColorSwatch('Accent Secondary', DesignTokens.accentSecondary),
              _buildColorSwatch('Accent Tertiary', DesignTokens.accentTertiary),
            ],
          ),
        ),
        
        LayoutSystem.sectionContainer(
          title: 'Semantic Colors',
          child: Wrap(
            spacing: DesignTokens.space4,
            runSpacing: DesignTokens.space4,
            children: [
              _buildColorSwatch('Success', DesignTokens.semanticSuccess),
              _buildColorSwatch('Warning', DesignTokens.semanticWarning),
              _buildColorSwatch('Error', DesignTokens.semanticError),
              _buildColorSwatch('Info', DesignTokens.semanticInfo),
            ],
          ),
        ),
        
        LayoutSystem.sectionContainer(
          title: 'Neutral Colors',
          child: Wrap(
            spacing: DesignTokens.space4,
            runSpacing: DesignTokens.space4,
            children: [
              _buildColorSwatch('Gray 100', DesignTokens.neutralGray100),
              _buildColorSwatch('Gray 300', DesignTokens.neutralGray300),
              _buildColorSwatch('Gray 500', DesignTokens.neutralGray500),
              _buildColorSwatch('Gray 700', DesignTokens.neutralGray700),
              _buildColorSwatch('Gray 900', DesignTokens.neutralGray900),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorSwatch(String name, Color color) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            border: Border.all(color: DesignTokens.borderPrimary),
          ),
        ),
        const SizedBox(height: DesignTokens.space2),
        Text(
          name,
          style: DesignTextStyles.caption,
          textAlign: TextAlign.center,
        ),
        Text(
          '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
          style: DesignTextStyles.caption.copyWith(
            color: DesignTokens.textTertiary,
            fontFamily: DesignTokens.fontFamilyMonospace,
          ),
        ),
      ],
    );
  }

  Widget _buildTypographyShowcase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutSystem.sectionHeader(title: 'Typography System'),
        
        LayoutSystem.sectionContainer(
          title: 'Text Styles',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypographyExample('Display Large', DesignTextStyles.displayLarge),
              _buildTypographyExample('Display', DesignTextStyles.display),
              _buildTypographyExample('Title Large', DesignTextStyles.titleLarge),
              _buildTypographyExample('Title', DesignTextStyles.title),
              _buildTypographyExample('Subtitle', DesignTextStyles.subtitle),
              _buildTypographyExample('Body Large', DesignTextStyles.bodyLarge),
              _buildTypographyExample('Body', DesignTextStyles.body),
              _buildTypographyExample('Caption', DesignTextStyles.caption),
              _buildTypographyExample('Accent', DesignTextStyles.accent),
              _buildTypographyExample('Code', DesignTextStyles.code),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypographyExample(String name, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: DesignTextStyles.caption.copyWith(
            color: DesignTokens.textTertiary,
          )),
          const SizedBox(height: DesignTokens.space1),
          Text('The quick brown fox jumps over the lazy dog', style: style),
        ],
      ),
    );
  }

  Widget _buildButtonsShowcase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutSystem.sectionHeader(title: 'Button Components'),
        
        LayoutSystem.sectionContainer(
          title: 'Button Variants',
          child: Wrap(
            spacing: DesignTokens.space4,
            runSpacing: DesignTokens.space4,
            children: [
              DesignSystemComponents.primaryButton(
                text: 'Primary Button',
                onPressed: () {},
                icon: FluentIcons.add,
              ),
              DesignSystemComponents.secondaryButton(
                text: 'Secondary Button',
                onPressed: () {},
                icon: FluentIcons.edit,
              ),
              DesignSystemComponents.dangerButton(
                text: 'Danger Button',
                onPressed: () {},
                icon: FluentIcons.delete,
              ),
            ],
          ),
        ),
        
        LayoutSystem.sectionContainer(
          title: 'Button States',
          child: Wrap(
            spacing: DesignTokens.space4,
            runSpacing: DesignTokens.space4,
            children: [
              DesignSystemComponents.primaryButton(
                text: 'Loading Button',
                onPressed: () {},
                isLoading: true,
              ),
              DesignSystemComponents.primaryButton(
                text: 'Disabled Button',
                onPressed: null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardsShowcase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutSystem.sectionHeader(title: 'Card Components'),
        
        LayoutSystem.responsiveGrid(
          children: [
            DesignSystemComponents.standardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Standard Card', style: DesignTextStyles.subtitle),
                  const SizedBox(height: DesignTokens.space2),
                  Text('This is a standard card with basic styling.', 
                       style: DesignTextStyles.body),
                ],
              ),
            ),
            DesignSystemComponents.standardCard(
              isSelected: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selected Card', style: DesignTextStyles.subtitle),
                  const SizedBox(height: DesignTokens.space2),
                  Text('This card is in a selected state.', 
                       style: DesignTextStyles.body),
                ],
              ),
            ),
            DesignSystemComponents.glassmorphismCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Glassmorphism Card', style: DesignTextStyles.subtitle),
                  const SizedBox(height: DesignTokens.space2),
                  Text('This card uses glassmorphism effects.', 
                       style: DesignTextStyles.body),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormsShowcase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutSystem.sectionHeader(title: 'Form Components'),
        
        LayoutSystem.sectionContainer(
          title: 'Input Fields',
          child: LayoutSystem.formFieldGroup(
            children: [
              DesignSystemComponents.textInput(
                controller: TextEditingController(),
                label: 'Standard Input',
                placeholder: 'Enter text here...',
                helperText: 'This is helper text',
              ),
              DesignSystemComponents.textInput(
                controller: TextEditingController(),
                label: 'Input with Icon',
                placeholder: 'Search...',
                prefixIcon: FluentIcons.search,
              ),
              DesignSystemComponents.textInput(
                controller: TextEditingController(),
                label: 'Error State',
                placeholder: 'Invalid input',
                errorText: 'This field is required',
              ),
            ],
          ),
        ),
        
        LayoutSystem.sectionContainer(
          title: 'Status Indicators',
          child: Wrap(
            spacing: DesignTokens.space4,
            runSpacing: DesignTokens.space4,
            children: [
              DesignSystemComponents.statusBadge(
                text: 'Success',
                type: SemanticColorType.success,
                icon: FluentIcons.check_mark,
              ),
              DesignSystemComponents.statusBadge(
                text: 'Warning',
                type: SemanticColorType.warning,
                icon: FluentIcons.warning,
              ),
              DesignSystemComponents.statusBadge(
                text: 'Error',
                type: SemanticColorType.error,
                icon: FluentIcons.error,
              ),
              DesignSystemComponents.statusBadge(
                text: 'Info',
                type: SemanticColorType.info,
                icon: FluentIcons.info,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLayoutShowcase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutSystem.sectionHeader(title: 'Layout System'),
        
        LayoutSystem.sectionContainer(
          title: 'Two Column Layout',
          child: LayoutSystem.twoColumnLayout(
            left: Container(
              height: 100,
              decoration: BoxDecoration(
                color: DesignTokens.accentPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              ),
              child: const Center(child: Text('Left Column')),
            ),
            right: Container(
              height: 100,
              decoration: BoxDecoration(
                color: DesignTokens.semanticInfo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              ),
              child: const Center(child: Text('Right Column')),
            ),
          ),
        ),
        
        LayoutSystem.sectionContainer(
          title: 'Responsive Grid',
          child: LayoutSystem.responsiveGrid(
            children: List.generate(6, (index) => Container(
              height: 80,
              decoration: BoxDecoration(
                color: DesignTokens.neutralGray200,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              ),
              child: Center(child: Text('Item ${index + 1}')),
            )),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimationsShowcase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutSystem.sectionHeader(title: 'Animation System'),
        
        LayoutSystem.sectionContainer(
          title: 'Entrance Animations',
          child: Column(
            children: [
              AnimationSystem.fadeIn(
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: DesignTokens.accentPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                  ),
                  child: const Center(child: Text('Fade In Animation')),
                ),
              ),
              const SizedBox(height: DesignTokens.space4),
              AnimationSystem.slideIn(
                direction: SlideDirection.left,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: DesignTokens.semanticSuccess.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                  ),
                  child: const Center(child: Text('Slide In Animation')),
                ),
              ),
              const SizedBox(height: DesignTokens.space4),
              AnimationSystem.scaleIn(
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: DesignTokens.semanticWarning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                  ),
                  child: const Center(child: Text('Scale In Animation')),
                ),
              ),
            ],
          ),
        ),
        
        LayoutSystem.sectionContainer(
          title: 'Interactive Animations',
          child: Wrap(
            spacing: DesignTokens.space4,
            runSpacing: DesignTokens.space4,
            children: [
              AnimationSystem.hoverScale(
                child: Container(
                  width: 120,
                  height: 80,
                  decoration: BoxDecoration(
                    color: DesignTokens.accentPrimary,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                  ),
                  child: const Center(
                    child: Text('Hover Me', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
              AnimationSystem.pulse(
                child: Container(
                  width: 120,
                  height: 80,
                  decoration: BoxDecoration(
                    color: DesignTokens.semanticInfo,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                  ),
                  child: const Center(
                    child: Text('Pulsing', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccessibilityShowcase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutSystem.sectionHeader(title: 'Accessibility Features'),
        
        LayoutSystem.sectionContainer(
          title: 'Color Contrast Report',
          child: FutureBuilder<Map<String, dynamic>>(
            future: Future.value(AccessibilityUtils.generateAccessibilityReport()),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return DesignSystemComponents.loadingIndicator(message: 'Generating report...');
              }
              
              final report = snapshot.data!;
              final colorTests = report['color_contrast_tests'] as Map<String, dynamic>;
              
              return Column(
                children: colorTests.entries.map((entry) {
                  final testName = entry.key;
                  final testData = entry.value as Map<String, dynamic>;
                  final wcagAA = testData['wcag_aa'] as bool;
                  final contrastRatio = testData['contrast_ratio'] as double;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: DesignTokens.space2),
                    padding: const EdgeInsets.all(DesignTokens.space3),
                    decoration: BoxDecoration(
                      color: wcagAA 
                          ? DesignTokens.semanticSuccess.withValues(alpha: 0.1)
                          : DesignTokens.semanticError.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                      border: Border.all(
                        color: wcagAA 
                            ? DesignTokens.semanticSuccess.withValues(alpha: 0.3)
                            : DesignTokens.semanticError.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          wcagAA ? FluentIcons.check_mark : FluentIcons.error,
                          color: wcagAA ? DesignTokens.semanticSuccess : DesignTokens.semanticError,
                          size: DesignTokens.iconSizeSmall,
                        ),
                        const SizedBox(width: DesignTokens.space2),
                        Expanded(
                          child: Text(
                            testName,
                            style: DesignTextStyles.body.copyWith(
                              fontWeight: DesignTokens.fontWeightMedium,
                            ),
                          ),
                        ),
                        Text(
                          '${contrastRatio.toStringAsFixed(2)}:1',
                          style: DesignTextStyles.caption.copyWith(
                            fontFamily: DesignTokens.fontFamilyMonospace,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        
        LayoutSystem.sectionContainer(
          title: 'Focus Management',
          child: Column(
            children: [
              Text(
                'All interactive components include proper focus management and keyboard navigation support.',
                style: DesignTextStyles.body,
              ),
              const SizedBox(height: DesignTokens.space4),
              Wrap(
                spacing: DesignTokens.space2,
                runSpacing: DesignTokens.space2,
                children: [
                  DesignSystemComponents.primaryButton(
                    text: 'Focusable Button 1',
                    onPressed: () {},
                  ),
                  DesignSystemComponents.secondaryButton(
                    text: 'Focusable Button 2',
                    onPressed: () {},
                  ),
                  DesignSystemComponents.primaryButton(
                    text: 'Focusable Button 3',
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ShowcaseSection {
  final String title;
  final IconData icon;
  
  ShowcaseSection(this.title, this.icon);
}
