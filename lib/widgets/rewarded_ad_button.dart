import 'package:flutter/material.dart';
import '../services/ad_service.dart';

class RewardedAdButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRewardEarned;
  final String? buttonText;

  const RewardedAdButton({
    super.key,
    required this.child,
    this.onRewardEarned,
    this.buttonText,
  });

  @override
  State<RewardedAdButton> createState() => _RewardedAdButtonState();
}

class _RewardedAdButtonState extends State<RewardedAdButton> {
  bool _isLoading = false;
  bool _isAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    AdService.instance.loadRewardedAd(
      onRewarded: (reward) {
        if (widget.onRewardEarned != null) {
          widget.onRewardEarned!();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡Recompensa obtenida! ${reward.amount} ${reward.type}'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Recargar para siguiente uso
        _loadRewardedAd();
      },
      onAdFailedToLoad: (error) {
        setState(() {
          _isAdReady = false;
        });
        // Reintentar después de un delay
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            _loadRewardedAd();
          }
        });
      },
    );
    
    // Asumir que el ad está listo después de un breve delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isAdReady = true;
        });
      }
    });
  }

  void _showRewardedAd() {
    if (!_isAdReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El anuncio aún se está cargando. Por favor espera...'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    AdService.instance.showRewardedAd(
      onRewarded: (reward) {
        setState(() {
          _isLoading = false;
        });
        if (widget.onRewardEarned != null) {
          widget.onRewardEarned!();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡Recompensa obtenida! ${reward.amount} ${reward.type}'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Recargar para siguiente uso
        _loadRewardedAd();
      },
      onAdFailedToShow: () {
        setState(() {
          _isLoading = false;
          _isAdReady = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo mostrar el anuncio. Intenta más tarde.'),
            backgroundColor: Colors.red,
          ),
        );
        _loadRewardedAd();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _showRewardedAd,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.play_circle_outline),
      label: Text(widget.buttonText ?? 'Ver Anuncio para Beneficio'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
    );
  }
}

