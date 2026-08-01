import 'package:flutter/material.dart';

/// Ism va familiyaning bosh harflaridan 1-2 ta belgi qaytaradi. Bo'sh
/// kelsa - bo'sh string. "Eshonov Fakhriyor" → "EF", "Ali" → "A".
String avatarInitials(String? name) {
  if (name == null) return '';
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  final parts =
      trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  if (parts.length == 1) {
    return parts[0].substring(0, 1).toUpperCase();
  }
  return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

/// Telegram uslubidagi gradient palitra - har bir foydalanuvchi nomi/idsiga
/// qarab birini tanlaymiz. Yumshoq, o'qiladigan ranglar; oq matn ustida
/// kontrast yaxshi bo'lishi uchun to'q-o'rta tonlar tanlangan.
const List<List<Color>> _avatarGradients = [
  [Color(0xFFFF885E), Color(0xFFFF516A)], // qizil-pushti
  [Color(0xFFFFCD6A), Color(0xFFFFA85C)], // to'q sariq
  [Color(0xFFE0A2F3), Color(0xFFD669ED)], // binafsha
  [Color(0xFFA0DE7E), Color(0xFF54CB68)], // yashil
  [Color(0xFF53EDD6), Color(0xFF28C9B7)], // turkuaz
  [Color(0xFF72D5FD), Color(0xFF2A9EF1)], // ko'k
  [Color(0xFF82B1FF), Color(0xFF665FFF)], // siyohrang
  [Color(0xFFFF8AAE), Color(0xFFFF5C8A)], // pushti
  [Color(0xFFB8C2D9), Color(0xFF6E7D9B)], // kulrang-ko'k
];

/// Berilgan stringdan barqaror (deterministik) gradient tanlaydi -
/// bir xil ism har doim bir xil rangga tushadi.
List<Color> avatarGradientFor(String? seed) {
  final s = (seed ?? '').trim();
  if (s.isEmpty) return _avatarGradients[5]; // default ko'k
  var hash = 0;
  for (final code in s.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return _avatarGradients[hash % _avatarGradients.length];
}

class CommonNetworkImage extends StatelessWidget {
  const CommonNetworkImage({
    super.key,
    this.imageUrl,
    this.height,
    this.width,
    this.radius,
    this.fit,
    this.fallback,
  });

  final String? imageUrl;
  final double? height;
  final double? width;
  final double? radius;
  final BoxFit? fit;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return _buildFallback();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? 0),
      child: Image.network(
        url,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    final iconSize = ((height ?? width ?? 40) * 0.5).clamp(16.0, 64.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? 0),
      child: Container(
        height: height,
        width: width,
        color: const Color(0xFFEFEFEF),
        alignment: Alignment.center,
        child: fallback ??
            Icon(
              Icons.person_outline,
              color: const Color(0xFF9E9E9E),
              size: iconSize,
            ),
      ),
    );
  }
}

/// Dumaloq avatar - agar [imageUrl] bo'sh yoki yuklanmasa, [name]'ning bosh
/// harflari (1–2 ta) bilan gradient doira ko'rsatadi. Ism ham bo'lmasa -
/// odam silueti iconi.
class AvatarImage extends StatelessWidget {
  const AvatarImage({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
  });

  final String? imageUrl;
  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    final fallback = _InitialAvatar(name: name, size: size);
    if (url.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name, required this.size});

  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = avatarInitials(name);
    final colors = avatarGradientFor(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      alignment: Alignment.center,
      child: initials.isEmpty
          ? Icon(
              Icons.person_outline,
              color: Colors.white,
              size: (size * 0.5).clamp(16.0, 48.0),
            )
          : Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: (size * 0.4).clamp(12.0, 32.0),
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
    );
  }
}