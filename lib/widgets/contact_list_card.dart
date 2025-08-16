import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/legal_models.dart';

class ContactListCard extends StatelessWidget {
  final String title;
  final List<LegalAidContact> contacts;
  final String jurisdiction;

  const ContactListCard({
    super.key,
    required this.title,
    required this.contacts,
    required this.jurisdiction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.contact_phone,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (contacts.isEmpty) ...[
              Text(
                'No local contacts available. Try enabling location access in settings.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ] else ...[
              ...contacts
                  .map((contact) => _buildContactItem(context, contact))
                  .toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(BuildContext context, LegalAidContact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Organization name
          Text(
            contact.name,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),

          if (contact.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              contact.description,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],

          const SizedBox(height: 8),

          // Contact actions
          Row(
            children: [
              // Phone button
              if (contact.phone.isNotEmpty) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _makePhoneCall(contact.phone),
                    icon: const Icon(Icons.phone, size: 16),
                    label: Text(
                      contact.phone,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Website button
              if (contact.website.isNotEmpty) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openWebsite(contact.website),
                    icon: const Icon(Icons.web, size: 16),
                    label: const Text(
                      'Website',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Areas of expertise
          if (contact.areas.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children:
                  contact.areas.map((area) {
                    return Chip(
                      label: Text(area, style: const TextStyle(fontSize: 10)),
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.1),
                      side: BorderSide.none,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openWebsite(String website) async {
    Uri uri;
    if (website.startsWith('http://') || website.startsWith('https://')) {
      uri = Uri.parse(website);
    } else {
      uri = Uri.parse('https://$website');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
