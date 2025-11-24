import 'package:flutter/material.dart';

import '../../theme/metro_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      title: 'Bienvenido al pulso del metro',
      description:
          'Explora un mapa vivo que muestra cómo se mueve el Metro de Panamá en tiempo real.',
      highlights: [
        'Líneas 1 y 2',
        'Trenes animados',
        'Estados por estación',
      ],
      icon: Icons.directions_subway_filled,
      accentColor: MetroColors.blue,
    ),
    _OnboardingPageData(
      title: 'Reporta y gana puntos',
      description:
          'Comparte lo que ves en segundos y desbloquea logros, niveles y recompensas.',
      highlights: [
        'Reportes en 3 toques',
        'Puntos y rachas',
        'Badges épicos',
      ],
      icon: Icons.emoji_events,
      accentColor: MetroColors.energyOrange,
    ),
    _OnboardingPageData(
      title: 'Ayuda a la comunidad',
      description:
          'Cada reporte mejora la experiencia de miles de viajeros que dependen del metro.',
      highlights: [
        'Impacto comunitario',
        'Alertas colaborativas',
        'Seguimiento automático',
      ],
      icon: Icons.groups,
      accentColor: MetroColors.green,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handlePrimaryAction() {
    if (_isLastPage) {
      widget.onFinished();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  bool get _isLastPage => _currentIndex == _pages.length - 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MetroColors.grayLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onFinished,
                  child: const Text('Saltar'),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (value) {
                    setState(() => _currentIndex = value);
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return _OnboardingCard(page: page);
                  },
                ),
              ),
              const SizedBox(height: 16),
              _PageIndicator(
                length: _pages.length,
                currentIndex: _currentIndex,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handlePrimaryAction,
                  child: Text(_isLastPage ? 'Comenzar' : 'Siguiente'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.page});

  final _OnboardingPageData page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MetroColors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: page.accentColor.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OnboardingIllustration(
            accentColor: page.accentColor,
            icon: page.icon,
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: MetroColors.grayDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: page.highlights
                .map(
                  (item) => Chip(
                    label: Text(item),
                    backgroundColor: page.accentColor.withValues(alpha: 0.1),
                    labelStyle: theme.textTheme.labelLarge?.copyWith(
                      color: page.accentColor.darken(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.length,
    required this.currentIndex,
  });

  final int length;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isActive = currentIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 32 : 12,
          decoration: BoxDecoration(
            color: isActive
                ? MetroColors.energyOrange
                : MetroColors.energyOrange.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({
    required this.accentColor,
    required this.icon,
  });

  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.1),
            accentColor.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 96,
          color: accentColor,
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.highlights,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String description;
  final List<String> highlights;
  final IconData icon;
  final Color accentColor;
}

extension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

