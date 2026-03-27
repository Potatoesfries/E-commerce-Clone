import 'package:flutter/material.dart';

class DevelopersPage extends StatelessWidget {
  const DevelopersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFFF6B35),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Meet Our Team',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF6B35),
                      const Color(0xFFFF8C42),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'The Minds Behind the App',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Passionate developers creating amazing experiences',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 1. Full Stack Developer
                  _buildDeveloperCard(
                    name: 'Virak',
                    major: 'Full Stack Developer',
                    description:
                        'A creative and detail-oriented developer who specializes in building end-to-end digital solutions from backend logic to sleek user interfaces.',
                    imageUrl:
                        'https://res.cloudinary.com/dby0dkagu/image/upload/v1759855222/picture_j7gso9.jpg',
                    primaryColor: const Color(0xFF4A90E2),
                    iconColor: Colors.blue,
                  ),

                  const SizedBox(height: 20),

                  // 2. Database Design
                  _buildDeveloperCard(
                    name: 'Visoth',
                    major: 'Database Designer',
                    description:
                        'Expert in designing efficient and secure database architectures that ensure data integrity, scalability, and seamless app performance.',
                    imageUrl:
                        'https://res.cloudinary.com/dby0dkagu/image/upload/v1759855242/visoth_sngkcq.jpg',
                    primaryColor: const Color(0xFF9B59B6),
                    iconColor: Colors.purple,
                  ),

                  const SizedBox(height: 20),

                  // 3. UI Designer
                  _buildDeveloperCard(
                    name: 'Theavit',
                    major: 'UI Designer',
                    description:
                        'Focused on crafting modern, engaging, and user-friendly interfaces that bring digital products to life through clean and thoughtful design.',
                    imageUrl:
                        'https://res.cloudinary.com/dby0dkagu/image/upload/v1759855431/theavit_uqzpjy.jpg',
                    primaryColor: const Color(0xFFFF6B35),
                    iconColor: Colors.orange,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard({
    required String name,
    required String major,
    required String description,
    required String imageUrl,
    required Color primaryColor,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.1),
                  primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey[200]!, Colors.grey[100]!],
                          ),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: primaryColor,
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey[200]!, Colors.grey[100]!],
                            ),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primaryColor,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.school_rounded,
                              size: 14,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                major,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
