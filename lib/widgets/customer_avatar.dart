import 'package:flutter/material.dart';

class CustomerAvatar extends StatefulWidget {
  final String? avatarUrl;
  final String customerName;
  final double radius;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;

  const CustomerAvatar({
    super.key,
    this.avatarUrl,
    required this.customerName,
    this.radius = 24,
    this.backgroundColor,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
  });

  @override
  State<CustomerAvatar> createState() => _CustomerAvatarState();
}

class _CustomerAvatarState extends State<CustomerAvatar> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _debugPrintAvatarInfo();
  }

  @override
  void didUpdateWidget(CustomerAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset error state khi avatarUrl thay đổi
    if (oldWidget.avatarUrl != widget.avatarUrl) {
      setState(() {
        _hasError = false;
      });
      _debugPrintAvatarInfo();
    }
  }

  void _debugPrintAvatarInfo() {
    print('🔍 CustomerAvatar Debug:');
    print('  - Customer: ${widget.customerName}');
    print('  - AvatarUrl: ${widget.avatarUrl}');
    print('  - Has Error: $_hasError');
    print('  - Will use NetworkImage: ${widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty && !_hasError}');
    print('  - Will use AssetImage: ${widget.avatarUrl == null || widget.avatarUrl!.isEmpty || _hasError}');
    print('  - Final URL: ${widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty ? _getImageUrl() : "assets/logo.jpg"}');
    
    // Test thêm về định dạng URL
    if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty) {
      print('  - URL starts with https: ${widget.avatarUrl!.startsWith('https')}');
      print('  - URL contains firebase: ${widget.avatarUrl!.contains('firebase')}');
      print('  - URL contains customers: ${widget.avatarUrl!.contains('customers')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          Container(
            decoration: widget.showBorder
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.borderColor ?? Colors.green,
                      width: 2,
                    ),
                  )
                : null,
            child: CircleAvatar(
              radius: widget.radius,
              backgroundColor: widget.backgroundColor ?? Colors.green.shade100,
              // Ưu tiên hiển thị ảnh theo thứ tự: avatarUrl -> assets/logo.jpg -> fallback
              backgroundImage: _getBackgroundImage(),
              onBackgroundImageError: (exception, stackTrace) {
                print('❌ Error loading avatar for ${widget.customerName}: $exception');
                print('   URL was: ${_getImageUrl()}');
                print('   Stack trace: $stackTrace');
                if (mounted) {
                  setState(() {
                    _hasError = true;
                  });
                }
              },
              // Chỉ hiển thị fallback khi cả avatarUrl và assets đều lỗi
              child: _shouldShowFallback()
                  ? _buildFallbackIcon()
                  : null,
            ),
          ),
          // Debug indicator (hiển thị tạm thời)
          if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _hasError ? Colors.red : Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          // Debug text (tạm thời để xem trạng thái)
          if (widget.radius > 20)
            Positioned(
              bottom: -20,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.avatarUrl?.isEmpty ?? true ? 'LOGO' : (_hasError ? 'ERR→LOGO' : 'NET'),
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _shouldShowFallback() {
    // Chỉ hiển thị fallback khi cả avatarUrl và assets đều không dùng được
    return _hasError && (widget.avatarUrl == null || widget.avatarUrl!.isEmpty);
  }

  ImageProvider? _getBackgroundImage() {
    // Ưu tiên 1: Nếu có avatarUrl và chưa có lỗi, dùng NetworkImage
    if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty && !_hasError) {
      return NetworkImage(
        _getImageUrl(),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );
    }
    
    // Ưu tiên 2: Nếu không có avatarUrl hoặc có lỗi, dùng assets/logo.jpg
    return const AssetImage('assets/logo.jpg');
  }

  String _getImageUrl() {
    if (widget.avatarUrl == null || widget.avatarUrl!.isEmpty) {
      return '';
    }
    
    String url = widget.avatarUrl!;
    
    // Đảm bảo URL có https:// prefix
    if (!url.startsWith('http')) {
      print('⚠️ Invalid URL format: $url');
      return '';
    }
    
    // Nếu URL đã có timestamp, trả về nguyên bản
    if (url.contains('?t=')) {
      print('🔗 Using timestamped URL: $url');
      return url;
    }
    
    // Nếu URL đã có query parameters, thêm timestamp với &
    if (url.contains('?')) {
      url = '$url&t=${DateTime.now().millisecondsSinceEpoch}';
    } else {
      // Thêm timestamp để tránh cache
      url = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    }
    
    print('🔗 Generated URL with timestamp: $url');
    return url;
  }

  Widget _buildFallbackIcon() {
    // Fallback chỉ xảy ra khi cả NetworkImage và AssetImage đều lỗi
    return Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 16),
          Text(
            'FAIL',
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
