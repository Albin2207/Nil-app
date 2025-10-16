import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shorts_provider.dart';
import '../../widgets/shorts_csrd.dart';
import 'shortsplayer_screen.dart';

class ShortsListScreen extends StatelessWidget {
  const ShortsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shorts = context.watch<ShortProvider>().shorts;

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.57,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: shorts.length,
      itemBuilder: (context, index) {
        return ShortCard(
          short: shorts[index],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShortsPlayerScreen(initialIndex: index),
              ),
            );
          },
        );
      },
    );
  }
}
