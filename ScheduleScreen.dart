import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'main.dart';
import 'AddPatRDV.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(MyMedicalApp(loggedInEmail: 'email'));
}
class MyMedicalApp extends StatelessWidget {
  final String loggedInEmail;
  const MyMedicalApp({Key? key, required this.loggedInEmail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }}
class Session {
  /// Filled right after login/get_user
  static String nom = '';
  static String prenom = '';
}
class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedIndex = 0;
  Map<String, int> _dailyAppointments = {};
  Map<String, Map<String, String>> _hourlyAppointments = {};// Stores {time: {name, surname}}
  late Map<String, Map<String, List<Map<String, dynamic>>>> _groupedHourlyAppointments = {};

  bool _showPersonal = false;
  Map<String, int> _personalAppointments = {};
  List<Map<String, dynamic>> _personalAppointmentsList = [];
  // in your State class:
  Map<String, Map<String, String>> _appointmentStatusMap = {};

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
    _loadPersonalAppointments();
  }

  Future<void> _fetchAppointments() async {
    final url = Uri.parse('http://192.168.1.114/rendez_vousPD.php');
    try {
      final response = await http.get(url);

      print("🔹 API Response Status: ${response.statusCode}");
      print("🔹 API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        print("✅ Decoded API Data: $decodedData");

        if (decodedData is List) {
          print("⚠️ API returned a List instead of a Map! Adjusting...");

          // Si c'est une liste, on prend le premier élément (en supposant que c'est correct)
          if (decodedData.isNotEmpty &&
              decodedData.first is Map<String, dynamic>) {
            _processAppointments(decodedData.first as Map<String, dynamic>);
          } else {
            print("❌ API response is an empty list or malformed data.");
          }
        } else if (decodedData is Map<String, dynamic>) {
          _processAppointments(decodedData);
        } else {
          print("❌ Unexpected API response format.");
        }
      } else {
        print("❌ API Request failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching data: $e");
    }
  }
  Future<void> updateAppointment({
    required String dateRdv,
    required String newStatus,
    String? newDescription,     // ← New parameter
  }) async {
    final url = Uri.parse('http://192.168.1.114/update_status3.php');

    DateTime now = DateTime.now();
    DateTime appointmentDate;

    try {
      appointmentDate = DateTime.parse(dateRdv);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Date invalide: $dateRdv")),
      );
      return;
    }

    // Auto‐mark missed if in the past and no status set
    if (appointmentDate.isBefore(now) && newStatus.isEmpty) {
      newStatus = "Missed";
    }

    // Build the payload
    final payload = {
      "date_rdv": dateRdv,
      "statut": newStatus,
      // Only include description when we're marking Completed or it's provided
      if (newStatus.toLowerCase() == 'completed' )
        "description": newDescription,
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Statut mis à jour avec succès")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: ${responseData['message'] ?? responseData['error']}")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur réseau: ${response.statusCode}")),
      );
    }
  }
  Future<List<Map<String, dynamic>>> fetchPersonalAppointments() async {
    final uri = Uri.parse(
      'http://192.168.1.114/rdv_perso1.php'
          '?nom=${Uri.encodeComponent(Session.nom)}'
          '&prenom=${Uri.encodeComponent(Session.prenom)}',
    );
    final resp = await http.get(uri);

    if (resp.statusCode != 200) {
      throw Exception('Network error: ${resp.statusCode}');
    }
    final body = resp.body.trim();
    if (body.isEmpty) {
      throw Exception('Empty response from server');
    }

    final data = jsonDecode(body);
    if (data['success'] != true) {
      throw Exception('Server error: ${data['message'] ?? 'Unknown'}');
    }
    final raw = data['appointments'];
    if (raw is! List) {
      throw Exception('Invalid response format: expected a list');
    }
    return raw.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
  }

// 2️⃣ Load into your state
  Future<void> _loadPersonalAppointments() async {
    try {
      final apps = await fetchPersonalAppointments();
      setState(() {
        _personalAppointmentsList = apps;
      });
      print("✅Loaded personal: $_personalAppointmentsList");
    } catch (e) {
      print("Error loading personal appointments: $e");
      // Optionally show a SnackBar or placeholder in UI
    }
  }
  Future<Map<String, String>> fetchAppointmentStatuses() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.114/statut.php'), // Your PHP endpoint URL
      );

      // Print the raw response body for debugging
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Check if the 'data' array exists in the response
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> appointments = data['data'];

          Map<String, String> statusMap = {};

          // Process each appointment and create the key as 'patientName dateKey time' and map to statut
          for (var appointment in appointments) {
            final patientName = '${appointment['patients_nom']} ${appointment['patients_prenom']}';
            final dateTime = DateTime.parse(appointment['date_rdv']);
            final formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);
            final formattedTime = DateFormat('HH:mm:ss').format(dateTime);

            // Create the key in the format "patientName dateKey time:00"
            final fullDateTimeKey = '$patientName $formattedDate $formattedTime';

            // Map the status to the corresponding key
            statusMap[fullDateTimeKey] = appointment['statut'] ?? 'pending'; // Default to 'pending' if statut is missing
          }

          return statusMap;
        } else {
          throw Exception('Failed to load valid status data');
        }
      } else {
        throw Exception('Failed to load status data');
      }
    } catch (e) {
      print("Error fetching statuses: $e");
      return {}; // Return an empty map in case of an error
    }
  }

  Future<void> showAppointmentStatusDialog(
      BuildContext context, {
        required String patientName,
        required String date,
        required String time,
        required Function(String newStatus) onStatusSelected,
      }) async {
    String? selectedStatus;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Détails du rendez-vous'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🧑 $patientName'),
                const SizedBox(height: 8),
                Text('📅 $date'),
                const SizedBox(height: 8),
                Text('🕒 $time'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Statut'),
                  items: const [
                    DropdownMenuItem(value: 'Completed', child: Text('Validé')),
                    DropdownMenuItem(value: 'Missed', child: Text('Manqué')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Annuler'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text('Enregistrer'),
                onPressed: selectedStatus == null
                    ? null
                    : () {
                  onStatusSelected(selectedStatus!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  void _processAppointments(Map<String, dynamic> decoded) {
    // 1️⃣ dailyAppointments : Map<String,String> → Map<String,int>
    final rawDaily = decoded['dailyAppointments'] as Map<String, dynamic>;
    _dailyAppointments = rawDaily.map((k, v) =>
        MapEntry(k, int.tryParse(v.toString()) ?? 0),
    );

    // 2️⃣ hourlyAppointments : Map<String,Map> → grouped
    final rawHourly = decoded['hourlyAppointments'] as Map<String, dynamic>;
    final Map<String, Map<String, List<Map<String, dynamic>>>> grouped = {};

    rawHourly.forEach((dateTimeKey, info) {
      // dateTimeKey e.g. "2025-05-19 15:15:00"
      final parts = dateTimeKey.split(' ');
      if (parts.length != 2) return;
      final dateKey = parts[0];
      final timeKey = parts[1];

      grouped.putIfAbsent(dateKey, () => {});
      final dayMap = grouped[dateKey]!;

      dayMap.putIfAbsent(timeKey, () => []);
      final slotList = dayMap[timeKey]!;

      final Map<String, dynamic> mapInfo = info as Map<String, dynamic>;

      slotList.add({
        'date_rdv'             : dateTimeKey,
        'patients_nom'         : mapInfo['patients_nom']    ?? '',
        'patients_prenom'      : mapInfo['patients_prenom'] ?? '',
        'utilisateurs_nom'     : mapInfo['utilisateurs_nom']    ?? '',
        'utilisateurs_prenom'  : mapInfo['utilisateurs_prenom'] ?? '',
        'diagnostic'           : mapInfo['diagnostic'] ?? '',
        'statut'               : mapInfo['statut'] ?? '',
      });
    });

    setState(() {
      _groupedHourlyAppointments = grouped;
    });
  }
  /// ① Construit appointmentsMap en y ajoutant 'dentist'
  void _showPatientDetails(String dateKey) async {
    // 1) Construire searchDateKey et displayDate
    String searchDateKey, displayDate;
    try {
      final d = DateTime.parse(dateKey);
      searchDateKey = DateFormat('yyyy-MM-dd').format(d);
      displayDate   = DateFormat('EEEE, MMMM d, y', 'fr_FR').format(d);
    } catch (_) {
      searchDateKey = dateKey;
      displayDate   = dateKey;
    }

    // 2) Récupérer la map des RDV pour cette date
    final hourMap = _groupedHourlyAppointments[searchDateKey] ?? {};
    final Map<String, Map<String, String>> appointmentsMap = {};

    hourMap.forEach((time, slotList) {
      if (slotList.isEmpty) return;
      final raw = slotList.first;

      // 3) Extraction des noms/prénoms avec fallback sur "name"/"surname"
      final String prenom = ((raw['patients_prenom'] as String?)?.trim().isNotEmpty == true
          ? raw['patients_prenom']
          : (raw['surname'] as String?))?.trim() ?? '';
      final String nom    = ((raw['patients_nom'] as String?)?.trim().isNotEmpty == true
          ? raw['patients_nom']
          : (raw['name'] as String?))?.trim() ?? '';

      final String practPrenom = (raw['utilisateurs_prenom'] as String?)?.trim() ?? '';
      final String practNom    = (raw['utilisateurs_nom']    as String?)?.trim() ?? '';
      final String rawStat     = (raw['statut'] as String?)?.trim() ?? '';
      final String statut      = rawStat.isEmpty ? 'pending' : rawStat;
      final String diagnostic  = (raw['diagnostic'] as String?)?.trim() ?? '';

      final String patientName = (prenom.isNotEmpty || nom.isNotEmpty)
          ? '$prenom $nom'
          : 'Inconnu';
      final String dentistName = (practPrenom.isNotEmpty || practNom.isNotEmpty)
          ? '$practPrenom $practNom'
          : 'Inconnu';

      appointmentsMap[time] = {
        'patient'   : patientName,
        'dentist'   : dentistName,
        'statut'    : statut,
        'diagnostic': diagnostic,
      };
    });

    if (appointmentsMap.isEmpty) {
      _showNoAppointmentsBottomSheet(displayDate);
      return;
    }

    _showAppointmentsBottomSheet(
      context,
      searchDateKey,
      displayDate,
      appointmentsMap,
    );
  }
  /// ② Affiche le BottomSheet en utilisant 'dentist', 'diagnostic', 'statut'
  void _showAppointmentsBottomSheet(
      BuildContext context,
      String dateKey,
      String displayDate,
      Map<String, Map<String, String>> appointmentsMap,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Poignée + header…
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(children: [
              Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              Expanded(child: Text("Rendez-vous du $displayDate",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ]),
          ),

          // Liste des rendez-vous
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: appointmentsMap.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, i) {
                final entry     = appointmentsMap.entries.elementAt(i);
                final rawTime   = entry.key;       // "HH:mm"
                final data      = entry.value;     // { 'patient':..., 'dentist':..., 'statut':... }
                final parts     = rawTime.split(':');
                final formatted = parts.length >= 2
                    ? '${parts[0].padLeft(2,'0')}:${parts[1].padLeft(2,'0')}'
                    : rawTime;

                final patientName = data['patient']  ?? 'Inconnu';
                final dentistName = data['dentist']  ?? 'Inconnu';  // ← clé utilisée
                final statut      = (data['statut']  ?? '').toLowerCase().trim();

                // Statut
                late Widget statusWidget;
                if (statut == 'completed') {
                  statusWidget = Row(children: const [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text('Validé', style: TextStyle(color: Colors.green)),
                  ]);
                } else if (statut == 'missed') {
                  statusWidget = Row(children: const [
                    Icon(Icons.cancel, color: Colors.red, size: 16),
                    SizedBox(width: 4),
                    Text('Manqué', style: TextStyle(color: Colors.red)),
                  ]);
                } else if (statut == 'en cours') {
                  statusWidget = Row(children: const [
                    Icon(Icons.autorenew, color: Colors.orange, size: 16),
                    SizedBox(width: 4),
                    Text('En cours', style: TextStyle(color: Colors.orange)),
                  ]);
                } else {
                  statusWidget = Row(children: const [
                    Icon(Icons.hourglass_empty, color: Colors.grey, size: 16),
                    SizedBox(width: 4),
                    Text('En attente', style: TextStyle(color: Colors.grey)),
                  ]);
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(formatted,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ))),
                  ),
                  title: Text(patientName, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      statusWidget,
                      const SizedBox(height: 4),
                      Text(' $dentistName',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(context);
                    final fullDateTime = '$dateKey $formatted:00';
                    _showPatientDetailsPopup(
                      dateRdv:     fullDateTime,
                      patientName: patientName,
                      date:        dateKey,
                      time:        formatted,
                      dentistName: dentistName,            // ← on ajoute ici
                      diagnostic:  data['diagnostic'] ?? '',// ← et ici
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
  void _showPatientDetailsPopup({
    required String dateRdv,
    required String patientName,
    required String date,
    required String time,
    required String dentistName,     // nouveau
    required String diagnostic,

  }) {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedStatus;
        final descriptionController = TextEditingController(text: diagnostic);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Détails du Patient',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient : $patientName'),
                    const SizedBox(height: 8),
                    Text('Date : $date'),
                    const SizedBox(height: 8),
                    Text('Heure : $time'),
                    const SizedBox(height: 8),
                    Text('Praticien :  $dentistName'),
                    const SizedBox(height: 8),
                    Text('Diagnostic : ${diagnostic.isNotEmpty ? diagnostic : "Aucun"}'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Statut',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: selectedStatus,
                      items: const [
                        DropdownMenuItem(
                          value: 'Completed',
                          child: Text('Validé'),
                        ),
                        DropdownMenuItem(
                          value: 'Missed',
                          child: Text('Manqué'),
                        ),
                        DropdownMenuItem(
                          value: 'En cours',
                          child: Text('En cours'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => selectedStatus = value);
                      },
                    ),
                    if (selectedStatus == 'Completed' || selectedStatus == 'En cours') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Nouvelle description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: selectedStatus == null
                      ? null
                      : () async {
                    Navigator.pop(context); // Fermer le popup
                    await updateAppointment(
                      dateRdv: dateRdv,
                      newStatus: selectedStatus!,
                      newDescription: descriptionController.text.trim(),
                    );
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  void _showNoAppointmentsBottomSheet(String displayDate) {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          Container(
            decoration: BoxDecoration(
              color: Theme
                  .of(context)
                  .scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(
                  24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event_busy, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  "Aucun rendez-vous",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Pas de rendez-vous trouvé pour le $displayDate",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }
  void _showAddOptions3(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            Scaffold(
              appBar: AppBar(title: Text("Ajouter un Rendez-Vous")),
              body: AddRendezVousScreen(),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendrier',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSegmentedControl(),
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _selectedIndex == 0
                  ? _buildHourlySchedule()
                  : _buildMonthlyCalendar(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions3(context),
        child: Icon(Icons.add, size: 30),
        backgroundColor: Colors.white,
        shape: CircleBorder(),
        elevation: 5,
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: [
            _buildSegmentButton(0, 'Aujourdhui'),
            _buildSegmentButton(1, 'Calendrier'),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(int index, String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _selectedIndex == index ? Colors.blue.shade900 : Colors
                .transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _selectedIndex == index ? Colors.white : Colors.blue
                    .shade900,
              ),
            ),
          ),
        ),
      ),
    );
  }
  String _initials(Map<String, dynamic> appt) {
    final p = (appt['patients_prenom'] as String?)?.trim() ?? '';
    final n = (appt['patients_nom'] as String?)?.trim() ?? '';
    return (p.isNotEmpty ? p[0] : '') + (n.isNotEmpty ? n[0] : '');
  }

  Widget _buildHourlySchedule() {
    final today = DateTime.now();
    final searchDate = DateFormat('yyyy-MM-dd').format(today);
    final dayMap = _groupedHourlyAppointments[searchDate] ?? <String, List<Map<String, dynamic>>>{};

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: 8,
      itemBuilder: (context, idx) {
        final hour = 8 + idx;
        final hourStr = hour.toString().padLeft(2, '0');
        final appointments = <Map<String, dynamic>>[];
        dayMap.forEach((timeKey, slotList) {
          if (timeKey.startsWith(hourStr)) appointments.addAll(slotList);
        });
        final count = appointments.length;
        final isCurrentHour = DateTime.now().hour == hour;
        final isPastHour = DateTime.now().hour > hour;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ⏰ Left Timeline
              Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isCurrentHour
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  if (idx < 7)
                    Container(
                      width: 2,
                      height: 100,
                      color: Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // 📦 Right Card Content
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isPastHour
                        ? Colors.grey.shade100
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      if (count > 0)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: count > 0
                        ? () => _showHourAppointmentsDialog(hour, appointments)
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time Header
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_filled_rounded,
                              size: 18,
                              color: isCurrentHour
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$hourStr:00',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isCurrentHour
                                    ? Theme.of(context).primaryColor
                                    : Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            if (isCurrentHour)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'En cours',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Appointment chips or empty state
                        if (count > 0)
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ...appointments.take(4).map((appt) => _buildPatientChip(appt)),
                              if (count > 4)
                                GestureDetector(
                                  onTap: () =>
                                      _showHourAppointmentsDialog(hour, appointments),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.more_horiz, size: 16),
                                        const SizedBox(width: 4),
                                        Text('+${count - 4}'),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Icon(Icons.hourglass_empty_outlined,
                                  size: 18, color: Colors.grey.shade400),
                              const SizedBox(width: 8),
                              Text(
                                'Aucun rendez-vous',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildPatientChip(Map<String, dynamic> appt) {
    final initials = _initials(appt);
    final prenom = (appt['patients_prenom'] as String?)?.trim().split(' ').first ?? '';

    return Tooltip(
      message: '${appt['patients_prenom']} ${appt['patients_nom']}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              radius: 14,
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              prenom,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showHourAppointmentsDialog(int hour, List<dynamic> appointments) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poignée
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              // Titre
              Text(
                'Rendez-vous à ${hour.toString().padLeft(2, '0')}h',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Divider(),
              // Liste des rendez-vous
              ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: appointments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final appt = appointments[index] as Map<String, dynamic>;

                  // Extraction date et heure
                  final fullDate = appt['date_rdv'] as String? ?? '';
                  final parts = fullDate.split(' ');
                  final date = parts.isNotEmpty ? parts[0] : '';
                  final time = parts.length > 1 ? parts[1].substring(0, 5) : '';

                  // Nom/prénom du patient
                  final prenom = appt['patients_prenom'] as String? ?? '';
                  final nom    = appt['patients_nom']   as String? ?? '';
                  final patientName = '$prenom $nom'.trim().isEmpty
                      ? 'Inconnu'
                      : '$prenom $nom';

                  // Clinicien
                  final practPrenom = appt['utilisateurs_prenom'] as String? ?? '';
                  final practNom    = appt['utilisateurs_nom']   as String? ?? '';
                  final clinicianName = '$practPrenom $practNom'.trim().isEmpty
                      ? 'Inconnu'
                      : '$practPrenom $practNom';

                  // Diagnostic
                  final diagnosis = (appt['diagnostic'] as String?) ?? '';

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          time,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      title: Text(
                        patientName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // date et heure
                          Text(
                            '$date  •  $time',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          // nom du clinicien
                          Text(
                            ' $clinicianName',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade700),
                          ),

                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        _showPatientDetailsPopup(
                          dateRdv:      fullDate,
                          patientName:  patientName,
                          date:         date,
                          time:         time,
                          dentistName:  clinicianName, // ← nouveau
                          diagnostic:   diagnosis,      // ← nouveau
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Bouton fermer
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Fermer', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildMonthlyCalendar() {
    return Column(
      children: [
        // 🔵 Personal / General toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => setState(() => _showPersonal = false),
              child: Text(
                'General',
                style: TextStyle(
                  fontWeight: _showPersonal ? FontWeight.normal : FontWeight.bold,
                  color: _showPersonal ? Colors.grey : Colors.blue,
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _showPersonal = true),
              child: Text(
                'Personal',
                style: TextStyle(
                  fontWeight: _showPersonal ? FontWeight.bold : FontWeight.normal,
                  color: _showPersonal ? Colors.blue : Colors.grey,
                ),
              ),
            ),
          ],
        ),

        // 🔵 The calendar itself
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: DateTime.now(),
              calendarFormat: CalendarFormat.month,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final key = DateFormat('yyyy-MM-dd').format(day);

                  // ▶️ Nombre d’appels selon le toggle
                  final int count = _showPersonal
                      ? _personalAppointmentsList.where((a) {
                    final dateStr = (a['date'] as String?) ?? '';
                    return dateStr.startsWith(key);
                  }).length
                      : (_dailyAppointments[key] ?? 0);

                  return InkWell(
                    onTap: count > 0
                        ? () {
                      if (_showPersonal) {
                        _showPatientDetailsPersonal(key);
                      } else {
                        _showPatientDetails(key);
                      }
                    }
                        : null,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getDayColor(day),
                            ),
                          ),
                          if (count > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person, size: 10, color: Colors.blue),
                                  const SizedBox(width: 2),
                                  Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }


// Updated day color logic
  Color _getDayColor(DateTime day) {
    if (day.weekday == DateTime.friday) {
      return Colors.red; // Friday in red
    } else {
      return Colors.black; // Weekdays in black
    }
  }
  void _showPatientDetailsPersonal(String dateKey) {
    // 1) Construire displayDate pour l’entête
    String displayDate;
    try {
      final d = DateTime.parse(dateKey);
      displayDate = DateFormat('EEEE, MMMM d, y', 'fr_FR').format(d);
    } catch (_) {
      displayDate = dateKey;
    }

    // 2) Filtrer la liste perso pour ce jour
    final todaysApps = _personalAppointmentsList.where((appt) {
      // 'date' contient "YYYY-MM-DD HH:MM:SS"
      final dateStr = (appt['date'] as String?) ?? '';
      return dateStr.startsWith(dateKey);
    }).toList();

    if (todaysApps.isEmpty) {
      // Pas de RDV : on affiche le même bottom sheet "aucun RDV"
      _showNoAppointmentsBottomSheet(displayDate);
      return;
    }

    // 3) Construire le Map<String, Map<String,String>>
    final Map<String, Map<String, String>> appointmentsMap = {};
    for (var appt in todaysApps) {
      final fullDate     = appt['date'] as String? ?? '';
      final parts        = fullDate.split(' ');
      if (parts.length != 2) continue;
      final timeKey      = parts[1]; // "HH:MM:SS"
      final patientPrenom= (appt['patient_prenom'] as String?)?.trim()   ?? '';
      final patientNom   = (appt['patient_nom']    as String?)?.trim()   ?? '';
      final praticPrenom = (appt['utilisateurs_prenom'] as String?)?.trim() ?? '';
      final praticNom    = (appt['utilisateurs_nom']    as String?)?.trim() ?? '';
      final diagnostic   = (appt['diagnostic'] as String?)?.trim() ?? '';
      final rawStat      = (appt['statut'] as String?)?.trim().toLowerCase() ?? '';
      final statut       = rawStat.isEmpty ? 'pending' : rawStat;

      final patientName  = '$patientPrenom $patientNom'.trim();
      final dentistName  = '$praticPrenom $praticNom'.trim();

      appointmentsMap[timeKey.substring(0,5)] = {
        'patient'   : patientName,
        'dentist'   : dentistName,
        'diagnostic': diagnostic,
        'statut'    : statut,
      };
    }

    // 4) Appeler le bottom sheet générique
    _showAppointmentsBottomSheet(
      context,
      dateKey,        // YYYY-MM-DD
      displayDate,    // e.g. "lundi, mai 20, 2025"
      appointmentsMap,
    );
  }



}
/// 2) Nouvelle fonction qui affiche **uniquement** les RDV personnels

