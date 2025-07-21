import 'package:constructionproject/Manger/manager_provider/atendence_provider.dart';
import 'package:constructionproject/Manger/manager_provider/manager_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  final _codeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

    @override
    void initState() {
    super.initState();
    Future.microtask(() => context.read<ManagerDataProvider>().loadSiteAndWorkers());
    }

    Future<String?> pickPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    return picked?.path;
    }

    @override
    Widget build(BuildContext context) {
    final managerProvider = Provider.of<ManagerDataProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    return Scaffold(
    appBar: AppBar(title: const Text('Manager Dashboard')),
    body: ListView(
    padding: const EdgeInsets.all(16),
    children: [
    // Attendance Form for workers
    Card(
    child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const Text("Worker Check-In/Check-Out", style: TextStyle(fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    TextField(
    controller: _codeController,
    decoration: const InputDecoration(
    labelText: "Enter worker code",
    ),
    ),
    const SizedBox(height: 12),
    if (attendanceProvider.error != null)
    Text(attendanceProvider.error!, style: const TextStyle(color: Colors.red)),
    Row(
    children: [
    ElevatedButton(
    onPressed: attendanceProvider.isLoading
    ? null
        : () async {
    final success = await attendanceProvider.checkIn(_codeController.text.trim());
    if (success) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked in!')));
    }
    },
    child: const Text('Check In'),
    ),
    const SizedBox(width: 16),
    ElevatedButton(
    onPressed: attendanceProvider.isLoading
    ? null
        : () async {
    final success = await attendanceProvider.checkOut(_codeController.text.trim());
    if (success) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked out!')));
    }
    },
    child: const Text('Check Out'),
    ),
    ],
    ),
    const SizedBox(height: 12),
    Row(
    children: [
    ElevatedButton.icon(
    icon: const Icon(Icons.face),
    label: const Text("Register Face"),
    onPressed: attendanceProvider.isLoading
    ? null
        : () async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    final photoPath = await pickPhoto();
    if (photoPath != null) {
    final success = await attendanceProvider.registerFace(code, photoPath);
    if (success) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Face registered!')));
    }
    }
    },
    ),
    const SizedBox(width: 16),
    ElevatedButton.icon(
    icon: const Icon(Icons.login),
    label: const Text("Face Check-In"),
    onPressed: attendanceProvider.isLoading
    ? null
        : () async {
    // Use siteId from managerProvider.site?.id or ask for input
    final siteId = managerProvider.site?.id ?? '';
    final photoPath = await pickPhoto();
    if (photoPath != null) {
    final success = await attendanceProvider.checkInWithFace(photoPath, siteId);
    if (success) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked in by face!')));
    }
    }
    },
    ),
    const SizedBox(width: 16),
    ElevatedButton.icon(
    icon: const Icon(Icons.logout),
    label: const Text("Face Check-Out"),
    onPressed: attendanceProvider.isLoading
    ? null
        : () async {
    final photoPath = await pickPhoto();
    if (photoPath != null) {
    final success = await attendanceProvider.checkOutWithFace(photoPath);
    if (success) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked out by face!')));
    }
    }
    },
    ),
    ],
    ),
    ],
    ),
    ),
    ),
    const SizedBox(height: 20),

    // Rest of Manager Dashboard
    if (managerProvider.isLoading)
    const Center(child: CircularProgressIndicator())
    else if (managerProvider.error != null)
    Center(child: Text(managerProvider.error!))
    else if (managerProvider.site == null)
    const Center(child: Text('No assigned site.'))
    else ...[
    Text(
    managerProvider.site!.name,
    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
    Text(managerProvider.site!.adresse),
    const SizedBox(height: 8),
    Text('Location: ${managerProvider.site!.latitude}, ${managerProvider.site!.longitude}'),
    Text('Geofence radius: ${managerProvider.site!.geofenceRadius ?? "N/A"} m'),
    Text('Active: ${managerProvider.site!.isActive ? "Yes" : "No"}'),
    Text('Budget: ${managerProvider.site!.budget ?? "N/A"}'),
    const SizedBox(height: 24),
    Text('Workers:', style: Theme.of(context).textTheme.titleMedium),
    ...managerProvider.workers.map((w) => ListTile(
    leading: const Icon(Icons.person),
    title: Text(w['firstName'] ?? 'Unknown'),
    subtitle: Text('ID: ${w['_id']}'),
    // Show face registration status if available
    trailing: w['faceRegistered'] == true
    ? const Icon(Icons.verified, color: Colors.green)
                      : const Icon(Icons.warning, color: Colors.red),
                )),
                if (managerProvider.workers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No workers assigned.'),
                  ),
              ]
        ],
      ),
    );
  }
}