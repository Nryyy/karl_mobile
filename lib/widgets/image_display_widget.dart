import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Widget for displaying images with various options
class ImageDisplayWidget extends StatelessWidget {
  final File? imageFile;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showDeleteButton;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  const ImageDisplayWidget({
    Key? key,
    this.imageFile,
    this.imageBytes,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.onTap,
    this.onDelete,
    this.showDeleteButton = false,
    this.borderRadius,
    this.placeholder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    
    if (imageFile != null) {
      if (kIsWeb) {
        // For web, read file as bytes
        imageWidget = FutureBuilder<Uint8List>(
          future: imageFile!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                width: width,
                height: height,
                fit: fit,
                errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
              );
            }
            return _buildLoadingWidget();
          },
        );
      } else {
        imageWidget = Image.file(
          imageFile!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        );
      }
    } else if (imageBytes != null) {
      imageWidget = Image.memory(
        imageBytes!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else if (imageUrl != null) {
      imageWidget = Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingWidget();
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else {
      imageWidget = placeholder ?? _buildPlaceholderWidget();
    }

    Widget container = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: imageWidget,
      ),
    );

    if (onTap != null || showDeleteButton) {
      container = Stack(
        children: [
          GestureDetector(
            onTap: onTap,
            child: container,
          ),
          if (showDeleteButton && onDelete != null)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return container;
  }

  Widget _buildPlaceholderWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'No image',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load',
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid widget for displaying multiple images
class ImageGridWidget extends StatelessWidget {
  final List<File> images;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final Function(int index)? onTap;
  final Function(int index)? onDelete;
  final bool showDeleteButton;

  const ImageGridWidget({
    Key? key,
    required this.images,
    this.crossAxisCount = 3,
    this.crossAxisSpacing = 4.0,
    this.mainAxisSpacing = 4.0,
    this.childAspectRatio = 1.0,
    this.onTap,
    this.onDelete,
    this.showDeleteButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'No images selected',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return ImageDisplayWidget(
          imageFile: images[index],
          onTap: onTap != null ? () => onTap!(index) : null,
          onDelete: showDeleteButton && onDelete != null 
              ? () => onDelete!(index) 
              : null,
          showDeleteButton: showDeleteButton,
          borderRadius: BorderRadius.circular(8),
        );
      },
    );
  }
}
