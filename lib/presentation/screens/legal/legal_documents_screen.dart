import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';

class LegalDocumentsScreen extends ConsumerWidget {
  const LegalDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final copy = AppCopy(profile.constraints.access.language);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(copy.legalDocumentsTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: copy.privacyPolicyTitle),
              Tab(text: copy.termsOfUseTitle),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LegalDocumentTab(assetPath: 'assets/legal/privacy_policy.md'),
            _LegalDocumentTab(assetPath: 'assets/legal/terms_of_use.md'),
          ],
        ),
      ),
    );
  }
}

class _LegalDocumentTab extends StatelessWidget {
  const _LegalDocumentTab({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: rootBundle.loadString(assetPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            SelectableText(
              snapshot.data ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.45,
              ),
            ),
          ],
        );
      },
    );
  }
}
