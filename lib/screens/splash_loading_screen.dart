import 'package:flutter/material.dart';

class SplashLoadingScreen extends StatefulWidget {
  const SplashLoadingScreen({super.key});

  @override
  State<SplashLoadingScreen> createState() => _SplashLoadingScreenState();
}

class _SplashLoadingScreenState extends State<SplashLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _rotateController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final primaryColor = isDark ? Colors.indigoAccent : Colors.indigo;
    final bgColor = isDark ? const Color(0xFF0F1113) : const Color(0xFFF8FAFF);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background subtle pattern
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _rotateController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotateController.value * 2 * 3.14159,
                  child: Opacity(
                    opacity: isDark ? 0.03 : 0.05,
                    child: Icon(
                      Icons.settings_suggest_rounded,
                      size: 600,
                      color: primaryColor,
                    ),
                  ),
                );
              },
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    height: 140,
                    width: 140,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2125) : Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.shield_rounded,
                          color: primaryColor,
                          size: 70,
                        ),
                        // Inner "pulse" circle
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(seconds: 2),
                          builder: (context, value, child) {
                            return Container(
                              width: 80 + (value * 20),
                              height: 80 + (value * 20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.3 * (1 - value)),
                                  width: 2,
                                ),
                              ),
                            );
                          },
                          onEnd: () {}, // Handled by the widget rebuild loop
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // Text Content
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Text(
                        'IQ VAULT',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 10,
                          color: isDark ? Colors.white : Colors.indigo.shade900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, primaryColor.withValues(alpha: 0.5)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
                // Loading Indicator
                Column(
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        backgroundColor: isDark ? Colors.white10 : Colors.indigo.withValues(alpha: 0.05),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'SECURE LOGIC CORE INITIALIZING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white30 : Colors.indigo.withValues(alpha: 0.4),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
