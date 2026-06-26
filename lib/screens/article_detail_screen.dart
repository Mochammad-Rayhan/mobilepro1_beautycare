import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/home_models.dart';

class ArticleDetailScreen extends StatelessWidget {
  final ArticleModel article;

  const ArticleDetailScreen({super.key, required this.article});

  Widget _buildContent(String text) {
    // Attempt to split by double newline for paragraph separation
    List<String> paragraphs = text.split('\n\n');

    // In some API responses, they might use \r\n\r\n
    if (paragraphs.length == 1) {
      paragraphs = text.split('\r\n\r\n');
    }

    if (paragraphs.length > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            paragraphs.first.trim(),
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF4A4A4A),
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            paragraphs.sublist(1).join('\n\n').trim(),
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF1A1A1A),
              height: 1.8,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 15,
        color: const Color(0xFF1A1A1A),
        height: 1.8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8), // Soft cream background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFCF8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF1A1A1A),
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'BEAUTYPEDIA',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1A1A),
            letterSpacing: 2.0,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              color: Color(0xFF1A1A1A),
              size: 22,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            Image.network(
              article.imageUrl,
              width: double.infinity,
              height: 280,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: double.infinity,
                height: 280,
                color: const Color(0xFFC4B5FD).withOpacity(0.18),
                child: const Center(
                  child: Icon(
                    Icons.article_outlined,
                    color: Color(0xFFC4B5FD),
                    size: 50,
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Read Time Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E5E5)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Color(0xFF8C8C8C),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          article.readTime.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8C8C8C),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    article.title,
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                      height: 1.2,
                      letterSpacing:
                          -0.5, // Better kerning for large sans-serif
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description & Content
                  _buildContent(article.description),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
