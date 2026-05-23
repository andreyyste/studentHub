import 'package:flutter/material.dart';

class MaterialCard extends StatelessWidget {
  final Map<String, dynamic> material;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const MaterialCard({
    super.key,
    required this.material,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.description, color: Color(0xFF4A00E0)),
        title: Text(material['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${material['course']} • ${material['category']}"),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.grey),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}
