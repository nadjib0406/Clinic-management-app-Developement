import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:MyDental/Classhome.dart';
import 'package:MyDental/ScheduleScreen.dart';
import 'package:MyDental/PatientScreen.dart';
import 'FollowingScreen.dart';
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: DashboardScreen(loggedInEmail: loggedInEmail),
    );
  }
}

class Session {
  /// Filled right after login/get_user
  static String nom = '';
  static String prenom = '';
}

Widget AddPat= AddPatientScreen();

Widget AddRdv= AddRendezVousScreen();

  class DashboardScreen extends StatefulWidget {
  final String loggedInEmail;
  const DashboardScreen({Key? key, required this.loggedInEmail})
    : super(key: key);
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex =
      0; // Tracks the selected index of the bottom navigation bar
  late final List<Widget> _screens;
  // List of screens to display based on the selected index
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(loggedInEmail: widget.loggedInEmail),
      // The existing dashboard content
      ScheduleScreen(),
      // The new schedule screen
      PatientsScreen(label: 'Patients'),
      FollowingScreen(),
      PatientsScreen(label: 'Resident/Interne'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clinique Dentaire'),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
      ),
      body: _screens[_currentIndex], // Display the selected screen
      floatingActionButton:
          _currentIndex == 0
              ? FloatingActionButton(
                onPressed: _showAddOptions,
                child: Icon(Icons.add, size: 30),
                backgroundColor: Colors.white,
                shape: CircleBorder(),
                elevation: 5,
              )
              : null, // Hide FAB on other screens
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update the selected index
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendrier',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Patients'),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Praticien',
          ),
        ],
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.person_add, color: Colors.blue),
                title: Text(
                  'Nouveau patient',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                tileColor: Colors.blue.shade50,
                // Fond léger bleu
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    builder: (context) => AddPatientScreen(),
                  );
                },
              ),
              SizedBox(height: 10), // Espacement
              ListTile(
                leading: Icon(Icons.calendar_today, color: Colors.green),
                title: Text(
                  'Nouveau rendez-vous',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                tileColor: Colors.green.shade50,
                // Fond léger vert
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    builder: (context) => AddRendezVousScreen(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

final String email = '';
Widget home = HomeScreen(loggedInEmail: email);


Widget Schedule =ScheduleScreen() ;

Widget patients = PatientsScreen(label: "Your Patient List");


Widget details = PatientDetailsScreen({
  'id': 42,
  'nom': 'Doe',
  'prenom': 'John',
  // etc.
});

Widget Following= FollowingScreen();

class UtilisateurDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> utilisateur;

  UtilisateurDetailsScreen(this.utilisateur, {Key? key}) : super(key: key);
  Future<List<Map<String, dynamic>>> fetchUserPatientRendezVous({
    required String utilisateurNom,
    required String utilisateurPrenom,
    required String patientNom,
    required String patientPrenom,
  }) async {
    // Build the URI with query parameters
    final uri = Uri.parse('192.168.1.114/doc_pat.php').replace(
      queryParameters: {
        'utilisateurs_nom': utilisateurNom,
        'utilisateurs_prenom': utilisateurPrenom,
        'patients_nom': patientNom,
        'patients_prenom': patientPrenom,
      },
    );

    final response = await http.get(uri);

    // Debug: print raw response
    print('RV Response: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to load rendez-vous (${response.statusCode})');
    }

    final body = json.decode(response.body);
    if (body['success'] != true) {
      throw Exception('API error: ${body['error'] ?? 'unknown'}');
    }

    // body['data'] is a List<dynamic> of maps
    return List<Map<String, dynamic>>.from(body['data']);
  }

  Widget _appointmentCard(Map<String, dynamic> appt) {
    final String date = appt['date'] ?? '';
    final String heure = appt['heure'] ?? '';
    final String patient = appt['patient'] ?? '';
    final String statut = appt['statut'] ?? '';
    final Color cardColor =
        statut == 'Completed'
            ? Colors.green.shade100
            : statut == 'Missed'
            ? Colors.orange.shade100
            : Colors.blue.shade100;
    final IconData icon =
        statut == 'Completed'
            ? Icons.check_circle
            : statut == 'Missed'
            ? Icons.warning_rounded
            : Icons.access_time_filled;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon),
        title: Text("Patient: $patient"),
        subtitle: Text("Date: $date\nHeure: $heure"),
        trailing: Text(statut.isNotEmpty ? statut : 'À venir'),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchRendezVousByUtilisateur({
    required String utilisateurNom,
    required String utilisateurPrenom,
  }) async {
    final uri = Uri.parse('http://192.168.1.114/doc_pat.php');
    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        'utilisateurs_nom': utilisateurNom,
        'utilisateurs_prenom': utilisateurPrenom,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load appointments: ${response.statusCode}');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception('Server error: ${data['message']}');
    }

    return List<Map<String, dynamic>>.from(data['rendezvous']);
  }
  Widget _buildUserAppointmentsSection(BuildContext context) {
    final nom = utilisateur['nom'] as String;
    final prenom = utilisateur['prenom'] as String;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchRendezVousByUtilisateur(
        utilisateurNom: nom,
        utilisateurPrenom: prenom,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Erreur: ${snap.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final all = snap.data ?? <Map<String, dynamic>>[];

        // Filtrer par statut
        final enCours = all.where((a) {
          final s = (a['statut'] as String).trim().toLowerCase();
          return s.isEmpty || s == 'pending';
        }).toList();
        final traite = all.where((a) =>
        (a['statut'] as String).trim().toLowerCase() == 'completed')
            .toList();
        final manques = all.where((a) {
          final s = (a['statut'] as String).trim().toLowerCase();
          return s.isNotEmpty && s != 'completed' && s != 'pending';
        }).toList();

        if (all.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 24),
                Text(
                  "Aucun rendez-vous programmé",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                "$prenom $nom",
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            // Alerte manqués
            if (manques.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Rendez-vous non honorés",
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Stat cards row with equal spacing
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCard(
                      icon: Icons.access_time_filled,
                      count: enCours.length,
                      label: "Prochains",
                      iconColor: Colors.blue.shade700,
                      bgColor: Colors.blue.shade50,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCard(
                      icon: Icons.timelapse,
                      count: enCours.length,
                      label: "En cours",
                      iconColor: Colors.purple.shade600,
                      bgColor: Colors.purple.shade50,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCard(
                      icon: Icons.check_circle,
                      count: traite.length,
                      label: "Traités",
                      iconColor: Colors.green.shade700,
                      bgColor: Colors.green.shade50,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCard(
                      icon: Icons.error_outline,
                      count: manques.length,
                      label: "Manqués",
                      iconColor: Colors.orange.shade700,
                      bgColor: Colors.orange.shade50,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Sections
            if (enCours.isNotEmpty) ...[
              _buildSectionHeader("Prochains rendez-vous", icon: Icons.schedule),
              const SizedBox(height: 8),
              ..._buildAppointmentList(context, enCours),
              const SizedBox(height: 24),
            ],
            if (traite.isNotEmpty) ...[
              _buildSectionHeader("Rendez-vous traités", icon: Icons.check_circle),
              const SizedBox(height: 8),
              ..._buildAppointmentList(context, traite),
              const SizedBox(height: 24),
            ],
            if (manques.isNotEmpty) ...[
              _buildSectionHeader("Rendez-vous manqués", icon: Icons.warning_rounded),
              const SizedBox(height: 8),
              ..._buildAppointmentList(context, manques),
            ],
          ],
        );
      },
    );
  }
  /// En-tête de section
  Widget _buildSectionHeader(String title, {required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCard({
    required IconData icon,
    required int count,
    required String label,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  "$count",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 14, color: iconColor)),
          ],
        ),
      ),
    );
  }


  List<Widget> _buildAppointmentList(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) {
    return items.map((rv) {
      final dateRaw = rv['date_rdv'] as String;
      final patient = "${rv['patients_prenom']} ${rv['patients_nom']}";
      final date = DateTime.parse(dateRaw);
      final formattedDate = DateFormat('EEE, MMM d y · HH:mm').format(date);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                formattedDate,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            '${utilisateur["prenom"]} ${utilisateur["nom"]}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.black),
              onPressed: () {
                /* Edit functionality */
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: TabBar(
                indicatorColor: _getRoleColor(utilisateur["role"]),
                labelColor: _getRoleColor(utilisateur["role"]),
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: TextStyle(fontWeight: FontWeight.w500),
                tabs: [
                  Tab(text: "Information"),
                  Tab(text: "Activités"),
                  Tab(text: "Patients"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildInformationTab(),
            _buildUserAppointmentsSection(context),
            _buildPatientsTab(context),
          ],
        ),
      ),
    );
  }

  // 1) Define a new fetch method that returns the patient’s full info by name:
  Future<Map<String, dynamic>> fetchPatientDetails({
    required String nom,
    required String prenom,
  }) async {
    final resp = await http.post(
      Uri.parse('http://192.168.1.114/patient_details.php'),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {'patients_nom': nom, 'patients_prenom': prenom},
    );
    if (resp.statusCode != 200) {
      throw Exception('Détails échec: ${resp.statusCode}');
    }
    final data = json.decode(resp.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Erreur serveur');
    }
    final raw = data['patient'];
    if (raw == null || raw is! Map) {
      throw Exception('Aucune donnée patient renvoyée');
    }
    return Map<String, dynamic>.from(raw);
  }

  Widget _buildPatientsTab(BuildContext context) {
    final userNom = utilisateur['nom'] as String;
    final userPrenom = utilisateur['prenom'] as String;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchRendezVousByUtilisateur(
        utilisateurNom: userNom,
        utilisateurPrenom: userPrenom,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Erreur RV: ${snap.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final allRVs = snap.data ?? [];
        final seen = <String>{};
        final names = <Map<String, String>>[];

        // Build unique name list
        for (var rv in allRVs) {
          final nom = rv['patients_nom'] as String?;
          final prenom = rv['patients_prenom'] as String?;
          if (nom == null || prenom == null) continue;
          final key = '$prenom $nom';
          if (seen.add(key)) {
            names.add({'nom': nom, 'prenom': prenom});
          }
        }

        if (names.isEmpty) {
          return const Center(child: Text("Aucun patient trouvé"));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: names.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (ctx, i) {
            final entry = names[i];
            final fullName = "${entry['prenom']} ${entry['nom']}";
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(fullName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                try {
                  // 1) Fetch full patient info
                  final patient = await fetchPatientDetails(
                    nom: entry['nom']!,
                    prenom: entry['prenom']!,
                  );
                  // 2) Build this patient’s history from the allRVs we already have
                  final history =
                      allRVs
                          .where(
                            (rv) =>
                                rv['patients_nom'] == entry['nom'] &&
                                rv['patients_prenom'] == entry['prenom'],
                          )
                          .map(
                            (rv) => {
                              'date': rv['date_rdv'],
                              'statut': rv['statut'] ?? '',
                              'description': rv['description'] ?? '',
                            },
                          )
                          .toList();

                  // 3) Inject history into the patient map
                  patient['rendez_vous'] = history;

                  // 4) Navigate
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientDetailsScreen(patient),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur détails: $e')));
                }
              },
            );
          },
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'enseignant':
        return Colors.blue.shade800;
      case 'resident':
        return Colors.teal.shade700;
      case 'interne':
        return Colors.deepPurple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  // ===========================
  // 🔹 Information Tab
  // ===========================
  Widget _buildInformationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Role Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getRoleColor(utilisateur["role"]).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getRoleColor(utilisateur["role"]).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getRoleIcon(utilisateur["role"]),
                  size: 18,
                  color: _getRoleColor(utilisateur["role"]),
                ),
                SizedBox(width: 8),
                Text(
                  utilisateur["role"],
                  style: TextStyle(
                    color: _getRoleColor(utilisateur["role"]),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Information Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            shadowColor: _getRoleColor(utilisateur["role"]).withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildInfoItem(
                    Icons.person,
                    "Nom complet",
                    "${utilisateur["prenom"]} ${utilisateur["nom"]}",
                    primary: true,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, thickness: 1),
                  ),

                  _buildInfoItem(
                    Icons.email_rounded,
                    "Email",
                    utilisateur["email"] ?? "Non renseigné",
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, thickness: 1),
                  ),

                  _buildInfoItem(
                    Icons.phone_rounded,
                    "Téléphone",
                    utilisateur["telephone"] ?? "Non renseigné",
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, thickness: 1),
                  ),

                  _buildInfoItem(
                    Icons.calendar_today_rounded,
                    "Date d'inscription",
                    utilisateur["date_creation"] ?? "Date inconnue",
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'enseignant':
        return Icons.school_rounded;
      case 'resident':
        return Icons.medical_services_rounded;
      case 'interne':
        return Icons.work_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value, {
    bool primary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color:
                primary
                    ? _getRoleColor(utilisateur["role"])
                    : Colors.grey.shade700,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        primary
                            ? _getRoleColor(utilisateur["role"])
                            : Colors.black,
                    fontWeight: primary ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================
  // 🔹 Activities Tab
  // ===========================
  Widget _activityCard1(Map<String, dynamic> rv) {
    final dt = DateTime.parse(rv['date_rdv']);
    final formatted = DateFormat('dd MMM yyyy – HH:mm').format(dt);
    return ListTile(
      leading: Icon(Icons.today),
      title: Text('${rv['patients_nom']} ${rv['patients_prenom']}'),
      subtitle: Text('${rv['description']} • $formatted'),
      trailing: Text(rv['statut']),
    );
  }

  Widget _buildActivitiesTab({
    required String utilisateurNom,
    required String utilisateurPrenom,
    required String patientNom,
    required String patientPrenom,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // — your stats summary up top —
          _buildStats(),

          const SizedBox(height: 20),

          // — section title —
          _sectionTitle("Historique des rendez-vous", Icons.history),
          const SizedBox(height: 10),

          // — live data from PHP endpoint —
          FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchUserPatientRendezVous(
              utilisateurNom: utilisateurNom,
              utilisateurPrenom: utilisateurPrenom,
              patientNom: patientNom,
              patientPrenom: patientPrenom,
            ),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Erreur : ${snap.error}'));
              }
              final rvs = snap.data!;

              if (rvs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Aucune activité récente",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // If you already have an _activityCard that takes your map, use that:
              return Column(
                children:
                    rvs.map((rv) {
                      // optionally massage the rv map into whatever your card needs
                      return _activityCard(rv);
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            _statBox(
              Icons.event_available,
              "Consulter",
              utilisateur["activites"]?.length.toString() ?? "0",
              _getRoleColor(utilisateur["role"]),
            ),
            SizedBox(width: 15),
            _statBox(
              Icons.groups,
              "en cours",
              utilisateur["patients_count"]?.toString() ?? "0",
              Colors.green.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: color),
                SizedBox(width: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _activityCard(Map<String, dynamic> activity) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: _getRoleColor(utilisateur["role"]),
              width: 5,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: 8),
                  Text(
                    activity["date"],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.description,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activity["description"],
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
              if (activity["patient"] != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                    SizedBox(width: 8),
                    Text(
                      "Patient: ${activity["patient"]}",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Widget USEr = AddUserScreen();
