import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'main3.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(MyMedicalAppInterne(loggedInEmail: 'email',));
}

class MyMedicalAppInterne extends StatelessWidget {
  final String loggedInEmail;
  const MyMedicalAppInterne({Key? key, required this.loggedInEmail}) : super(key: key);
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
  static String role = '';
}
class AddPatientScreen extends StatefulWidget {
  @override
  _AddPatientScreenState createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _dateNaissanceController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _gender;

  Future<void> _addPatient() async {
    final url = Uri.parse('http://192.168.1.114/add_patient2.php');

    // Construire le JSON à envoyer, en injectant le nom/prénom de l'utilisateur connecté
    final body = jsonEncode({
      "nom": _nomController.text,
      "prenom": _prenomController.text,
      "date_naissance": _dateNaissanceController.text,
      "telephone": _telephoneController.text,
      "gender": _gender,
      "adresse": _adresseController.text,
      "description": _descriptionController.text,
      "utilisateurs_nom": Session.nom,          // injecté depuis la session
      "utilisateurs_prenom": Session.prenom,    // injecté depuis la session
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        Navigator.pop(context); // Fermer le formulaire
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Patient ajouté avec succès !")),
        );
      } else {
        final msg = data['message'] ?? 'Erreur inconnue';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Échec de l'ajout du patient : $msg")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur réseau ou format : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16).copyWith(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nomController,
            decoration: InputDecoration(labelText: "Nom"),
          ),
          TextField(
            controller: _prenomController,
            decoration: InputDecoration(labelText: "Prénom"),
          ),
          TextField(
            controller: _dateNaissanceController,
            decoration: InputDecoration(
              labelText: "Date de naissance (YYYY-MM-DD)",
            ),
          ),
          TextField(
            controller: _telephoneController,
            decoration: InputDecoration(labelText: "Téléphone"),
          ),
          DropdownButtonFormField<String>(
            value: _gender,
            items: ["Male", "Female"]
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) => setState(() => _gender = val),
            decoration: InputDecoration(labelText: "Sexe"),
          ),
          TextField(
            controller: _adresseController,
            decoration: InputDecoration(labelText: "Adresse"),
          ),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: "Description"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _addPatient,
            child: const Text("Ajouter Patient"),
          ),
        ],
      ),
    );
  }
}
class AddRendezVousScreen extends StatefulWidget {

  @override
  _AddRendezVousScreenState createState() => _AddRendezVousScreenState();
}

class _AddRendezVousScreenState extends State<AddRendezVousScreen> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String? _selectedDiagnostic; // Nouveau: pour stocker le diagnostic sélectionné
  List<String> _diagnostics = [];
  List<Map<String, dynamic>> _usersByRole = [];
  late String _selectedResident = Session.role;
  late final String _selectedUserFullName;
  String? _selectedUser;
  final Map<String, List<String>> _casObligatoires = {
    "interne": ['Biodépulpation sur mono/biradiculée',
      'Biodépulpation sur pluriradiculée',
      'Traitement des LIPOE sur mono/biradiculée',
      'Traitement des LIPOE sur pluriradiculée',
      'Traitement des urgences pulpaires',
      'Traitement des urgences péri-apicales',
      'Restauration corono-radiculaire sur dent antérieure',
      'Restauration corono-radiculaire sur dent postérieure',
      'Coiffage dentino-pulpaire',
      'Restauration directe au composite',
      'Thérapeutiques conservatrices sur dents temporaires',
      'Traitement endodontique sur dents temporaires',
      'Gestion des patients à risque',
    ],
    "Resident 1": [
      'Thérapeutique dentinaire et préparation de cavité pour classe I',
      'Thérapeutique dentinaire et préparation de cavité pour classe II',
      'Thérapeutique dentinaire et préparation de cavité pour classe III',
      'Thérapeutique dentinaire et préparation de cavité pour classe V',
      'Coiffage pulpo-dentinaire naturel',
      'Biodépulpation sur monoradiculée',
      'Biodépulpation sur pluriradiculée',
      'Traitement des LIPOE sur monoradiculée',
      'Traitement des LIPOE sur pluriradiculée',
      'Restauration au composite',
      'Restauration au CVI',
      'Restauration prophylactique',
    ],
    "Resident 2": [
      "Perte de substance d'origine carieuse : Reconstitution des faces occlusales",
      "Perte de substance d'origine carieuse : Reconstitution des faces proximales",
      "Perte de substance d'origine carieuse : Reconstitution du 1/3 cervical",
      "Perte de substance d'origine non carieuse",
      "Thérapeutique de la dent de 06 ans",
      "Biodépulpation sur mono/biradiculée",
      "Biodépulpation sur pluriradiculée",
      "Traitements des LIPOE sur mono/biradiculée",
      "Traitements des LIPOE sur pluriradiculée",
      "Thérapeutiques dentinogènes sur dents temporaires",
      "Gestion des patients à risque."
    ],
    "Resident 3": ["Thérapeutiques restauratrices sur dent antérieure vivante",
      "Thérapeutiques restauratrices sur dent postérieure vivante",
      "Thérapeutiques restauratrices sur dent antérieure dépulpée",
      "Thérapeutiques restauratrices sur dent postérieure dépulpée",
      "Endodontie mécanisée + obturation canalaire thermoplastifiée",
      "Eclaircissements",
      "Traitement des fractures coronaires sans exposition pulpaire",
      "Traitement des fractures coronaires avec exposition pulpaire",
      "Traitement des fractures radiculaires",
      "Retraitement endodontique orthograde sur monoradiculées",
      "Retraitement endodontique orthograde sur pluriradiculées",
      "Traitement des dyschromies",
      "Gestion des patients à risque"],
    "Resident 4": [ "Techniques de restaurations indirectes",
      "Restauration corono-radiculaire sur dent antérieure",
      "Restauration corono-radiculaire sur dent postérieure",
      "Retraitement endodontique orthograde mécanisé",
      "Apexogénèse",
      "Apexification",
      "Revitalisation",
      "Thérapeutiques endodontiques sur molaires temporaires",
      "Traitement des traumatismes dentaires",
      "Thérapeutiques esthétiques",
      "Chirurgie endodontique",
      "Thérapeutiques gériatriques",
      "Gestion des patients à risque"],
  };
  void initState() {
    super.initState();
    _loadCurrentUserRoleAndDiagnostics();
  }

  Future<void> _loadCurrentUserRoleAndDiagnostics() async {
    try {
      // 1) Fetch all users
      final resp = await http.get(
        Uri.parse('http://192.168.1.114/get_utilisateurs.php'),
      );
      if (resp.statusCode != 200) throw Exception('Failed to load users');

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      if (decoded['success'] != true) throw Exception(decoded['error']);

      // 2) Find the record matching our full name
      final fullName = '${Session.nom}'.trim() + ' ' + '${Session.prenom}'.trim();
      final allUsers = (decoded['users'] as List)
          .cast<Map<String, dynamic>>();
      final me = allUsers.firstWhere(
            (u) =>
        '${u['nom']}'.trim().toLowerCase()    == Session.nom.trim().toLowerCase() &&
            '${u['prenom']}'.trim().toLowerCase() == Session.prenom.trim().toLowerCase(),
        orElse: () => {},
      );
      final myRole = (me['role'] as String?)?.trim() ?? '';
      if (myRole.isEmpty) {
        print('⚠️ Could not find my user record in get_utilisateurs.php');
      }

      // 3) Match that to your cas obligatoires map
      final roleKey = _casObligatoires.keys.firstWhere(
            (k) => k.toLowerCase() == myRole.toLowerCase(),
        orElse: () => '',
      );

      // 4) Finally set your dropdown data
      setState(() {
        _selectedResident     = myRole;
        _selectedUserFullName = fullName;
        _diagnostics = roleKey.isEmpty
            ? <String>[]
            : _casObligatoires[roleKey]!;
      });

      print('🔑 Detected roleKey="$roleKey", diagnostics=$_diagnostics');
    } catch (e) {
      print('❌ Error fetching my role ⇒ $e');
      setState(() {
        _diagnostics = [];
      });
    }
  }
  Future<void> _addRendezVous() async {
    if (_nomController.text.isEmpty ||
        _prenomController.text.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null ||
        _descriptionController.text.isEmpty ||
        _selectedDiagnostic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    final formattedDate = _selectedDate!.toIso8601String().split('T')[0];
    final formattedTime = _selectedTime!.format(context) + ":00";

    final body = jsonEncode({
      "patients_nom":            _nomController.text,
      "patients_prenom":         _prenomController.text,
      "date_rdv":                "$formattedDate $formattedTime",
      "description":             _descriptionController.text,
      "utilisateurs_role":       _selectedResident,
      "diagnostic":              _selectedDiagnostic,
      "utilisateur_nom_complet": _selectedUserFullName,
    });

    final resp = await http.post(
      Uri.parse('http://192.168.1.114/add_rdv2.php'),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    final data = jsonDecode(resp.body);
    if (data["success"] == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Rendez-vous ajouté !")));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${data["message"]}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            // Patient last / first name
            TextField(
              controller: _nomController,
              decoration: InputDecoration(labelText: "Nom"),
            ),
            TextField(
              controller: _prenomController,
              decoration: InputDecoration(labelText: "Prénom"),
            ),

            // Date
            TextField(
              controller: _dateController,
              decoration: InputDecoration(labelText: "Date du rendez-vous"),
              readOnly: true,
              onTap: () async {
                final dd = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (dd != null) {
                  setState(() {
                    _selectedDate = dd;
                    _dateController.text = "${dd.toLocal()}".split(' ')[0];
                  });
                }
              },
            ),

            // Time
            TextField(
              controller: _timeController,
              decoration: InputDecoration(labelText: "Heure du rendez-vous"),
              readOnly: true,
              onTap: () async {
                final tt = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (tt != null) {
                  setState(() {
                    _selectedTime = tt;
                    _timeController.text = tt.format(context);
                  });
                }
              },
            ),

            // Description
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Description"),
            ),

            SizedBox(height: 16),

            // Diagnostic dropdown (clickable)
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: "Diagnostic",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              hint: const Text("Sélectionnez un diagnostic"),
              value: _selectedDiagnostic,
              items: _diagnostics.map((diag) {
                return DropdownMenuItem(
                  value: diag,
                  child: Text(diag),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedDiagnostic = v),
              validator: (v) => v == null ? "Requis" : null,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _addRendezVous,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade100,
                foregroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: Text("Ajouter Rendez-vous"),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final String loggedInEmail;
  const DashboardScreen({Key? key, required this.loggedInEmail}) : super(key: key);
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0; // Tracks the selected index of the bottom navigation bar
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
      floatingActionButton: _currentIndex == 0
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
              icon: Icon(Icons.calendar_today), label: 'Calendrier'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Patients'),

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
                          top: Radius.circular(16)),
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
                          top: Radius.circular(16)),
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
class HomeScreen extends StatefulWidget {
  final String loggedInEmail;
  const HomeScreen({Key? key, required this.loggedInEmail}) : super(key: key);

  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List rendez_vous = [];
  List utilisateurs = [];
  int totalPatients = 0;
  int totalAppointments = 0;
  int totalResidents = 0;
  late String currentUserNom;
  late String currentUserPrenom;

  // main.dart or a utility file (e.g., 'utils.dart')
  String? loggedInUserEmail;
  Map<String, dynamic>? _userDetails;
  String? _loggedInNom;
  String? _loggedInPrenom;
  String? _loggedInRole;
  List<Map<String, dynamic>> userInfo = [];
  bool isLoadingUser = true;
  int _todayCount = 0;
  int _todayCompletedCount = 0;
  Future<void> fetchAppointments() async {
    final response = await http.get(
      Uri.parse('http://192.168.1.114/rendez_vous1.php'),
    );

    if (response.statusCode != 200) {
      print("Failed to load rendez-vous. Status Code: ${response.statusCode}");
      throw Exception('Erreur de connexion');
    }

    // On s'attend désormais à un objet Map<String, dynamic>, pas à une liste brute
    final Map<String, dynamic> jsonResp = json.decode(response.body);
    print("Full JSON response: $jsonResp");

    if (jsonResp['success'] != true) {
      print("Server returned success=false");
      throw Exception('Erreur serveur');
    }

    // 'data' contient la liste des RDV du jour
    final List<dynamic> todayList = jsonResp['data'] as List<dynamic>;
    print("Fetched today’s rendez-vous: $todayList");

    final today = DateTime.now();
    final todayKey = "${today.year.toString().padLeft(4,'0')}-"
        "${today.month.toString().padLeft(2,'0')}-"
        "${today.day.toString().padLeft(2,'0')}";

    final userFullName = "${Session.nom} ${Session.prenom}".trim();
    print("➡️ Comparing against logged-in userFullName: '$userFullName'");

    var countToday = 0;
    var completedToday = 0;

    // On parcourt uniquement les RDV renvoyés par la clé 'data'
    for (final item in todayList) {
      final appt = item as Map<String, dynamic>;

      // Heure + date
      final dt = (appt['date_rdv'] as String?) ?? '';
      // Propriétaire
      String owner = (appt['utilisateur_nom_complet'] as String?)?.trim() ?? '';
      if (owner.isEmpty) {
        final nom  = (appt['utilisateurs_nom']   as String?) ?? '';
        final pren = (appt['utilisateurs_prenom'] as String?) ?? '';
        owner = "$nom $pren".trim();
      }

      // On ne compte que ceux du user courant
      if (owner != userFullName) continue;

      countToday++;

      final statut = (appt['statut'] as String?)?.trim().toLowerCase() ?? '';
      if (statut == 'completed') {
        completedToday++;
      }
    }

    setState(() {
      rendez_vous           = todayList;
      _todayCount           = countToday;
      _todayCompletedCount  = completedToday;
    });

    print("Today's total: $_todayCount, completed: $_todayCompletedCount");
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
  Future<void> fetchUserInfo() async {
    final uri = Uri.parse(
        'http://192.168.1.114/get_user.php'
            '?email=${Uri.encodeComponent(widget.loggedInEmail)}'
    );
    print('▶️ GET $uri');
    final resp = await http.get(uri);
    print('⬅️ ${resp.statusCode} ${resp.body}');

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data['success'] == true && data['users'] is List) {
        final List<Map<String, dynamic>> raw =
        List<Map<String, dynamic>>.from(data['users']);
        final Map<String, dynamic> user = (data['users'] as List).first;
        Session.nom    = user['nom']    as String;
        Session.prenom = user['prenom'] as String;
        // convert all values to String for simplicity
        setState(() {

          userInfo = raw
              .map((row) => row.map((k, v) => MapEntry(k, v.toString())))
              .toList();
        });
      } else {
        print('⚠️ get_user returned success=false or bad format');
      }
    } else {
      print('❌ HTTP ${resp.statusCode}');
    }
  }
  Future<void> fetchStatistics() async {
    try {
      final response = await http.get(
          Uri.parse('http://192.168.1.114/statistics.php'));

      print("HTTP Status Code: ${response.statusCode}");
      print("Raw API Response: ${response
          .body}"); // Debugging: See the full response

      if (response.statusCode == 200) {
        // Decode the JSON response
        var data = json.decode(response.body);

        // Check if the response is null or empty
        if (data == null || data.isEmpty) {
          print("API response is empty or null");
          return;
        }
        print("Decoded JSON: $data"); // Debugging: Print the parsed JSON

        // Safely parse the data
        setState(() {
          totalPatients =
              int.tryParse(data['total_patients']?.toString() ?? '0') ?? 0;
          totalAppointments =
              int.tryParse(data['total_appointments']?.toString() ?? '0') ?? 0;
          totalResidents =
              int.tryParse(data['total_residents']?.toString() ?? '0') ?? 0;
        });

        print(
            "Updated State: Patients: $totalPatients, Appointments: $totalAppointments, Residents: $totalResidents");
      } else {
        // Handle non-200 status codes
        print("Server returned an error: ${response.statusCode}");
        print("Error response body: ${response.body}");
      }
    } catch (e) {
      // Handle any exceptions
      print("Error fetching statistics: $e");
    }
  }
  @override
  void initState() {
    super.initState();
    fetchAppointments();
    /* fetchUtilisateurs();*/
    fetchStatistics();
    fetchUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.blue.shade50],
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildHeader(),
                SizedBox(height: 20),
                _buildStatistics(),
                SizedBox(height: 20),
                _buildCalendar(),
                SizedBox(height: 20),
                _buildSchedule(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: BorderRadius.circular(20),
      ),
      child: userInfo.isNotEmpty
          ? Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${userInfo[0]['nom']} ${userInfo[0]['prenom']}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                '${userInfo[0]['role']}',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 40, color: Colors.blue.shade700),
          ),
        ],
      )
          : Center(
        child: Text(
          "No user data available",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
  Widget _buildStatistics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              'RDV Prochain',
              '$_todayCount',
              Icons.calendar_today,
              Colors.orange.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              'RDV Honoré',
              '$_todayCompletedCount',
              Icons.check_circle,
              Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCalendar() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          focusedDay: DateTime.now(),
          firstDay: DateTime(2020),
          lastDay: DateTime(2030),
          calendarFormat: CalendarFormat.week,
          headerStyle: HeaderStyle(
              formatButtonVisible: false, titleCentered: true),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
                color: Colors.blue, shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(
                color: Colors.green, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
  Widget _statCard(String title, String count, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,               // let the column wrap its contents
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      count,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchedule(BuildContext context) {
    // 1) Only keep this user’s appointments
    final myAppointments = rendez_vous.where((r) {
      final userNom    = r['utilisateurs_nom']   as String? ?? '';
      final userPrenom = r['utilisateurs_prenom'] as String? ?? '';
      return userNom == Session.nom && userPrenom == Session.prenom;
    }).toList();

    // 2) Now pick only those with empty statut or statut == "à venir"
    final upcomingAppointments = myAppointments.where((rendezVous) {
      final statutRaw = rendezVous['statut'];
      final statut    = statutRaw == null
          ? ''
          : statutRaw.toString().toLowerCase().trim();
      return statut.isEmpty || statut == 'à venir';
    }).toList();

    // 3) Limit to at most 2 entries
    final limitedAppointments = upcomingAppointments.take(2).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prochain Rendez-vous',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: limitedAppointments.isEmpty
                ? const Center(child: Text("Pas de Rendez-vous"))
                : Column(
              children: limitedAppointments.map((rendezVous) {
                final patientFullName =
                    "${rendezVous['patients_nom'] ?? 'Unknown'} ${rendezVous['patients_prenom'] ?? ''}";
                return _appointmentTile(
                  context,
                  patientFullName,
                  // time
                  (rendezVous['date_rdv'] ?? '')
                      .toString()
                      .length >= 16
                      ? rendezVous['date_rdv']
                      .toString()
                      .substring(11, 16)
                      : 'N/A',
                  // full date string
                  rendezVous['date_rdv'] ?? 'N/A',
                  rendezVous['diagnostic'] ?? 'Unknown',
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }


  Widget _appointmentTile(BuildContext context, String name, String time,
      String dateRdv,String diagnostic) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Heure: $time'),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          _showPatientDetails(context, name, time, dateRdv,diagnostic);
        },
      ),
    );
  }

  void _showPatientDetails(
      BuildContext context,
      String name,
      String time,
      String dateRdv,
      String diagnostic,
      /*  String userFullName,*/ // ← NEW PARAMETER
      ) {
    String? selectedStatut;
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(20),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 60,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    /* _buildDetailRow(
                      Icons.account_circle,
                      'Médecin responsable:',
                     /* userFullName,*/ // ← DISPLAY USER FULL NAME
                    ),*/
                    const SizedBox(height: 24),
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Date du rendez-vous:',
                      dateRdv,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.access_time,
                      'Heure du rendez-vous:',
                      time,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.medical_services,
                      'Diagnostic:',
                      diagnostic,
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Statut du rendez-vous',
                        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      value: selectedStatut,
                      items: ['Completed', 'Missed', 'En cours']
                          .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                          .toList(),
                      onChanged: (val) {
                        setState(() => selectedStatut = val);
                      },
                    ),
                    if (selectedStatut == 'Completed' || selectedStatut == 'En cours') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Nouvelle description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (selectedStatut != null) {
                          updateAppointment(
                            dateRdv: dateRdv,
                            newStatus: selectedStatut!,
                            newDescription: descriptionController.text.trim(),
                          );
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Veuillez sélectionner un statut"),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Mettre à jour le statut'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Fermer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        minimumSize: const Size.fromHeight(50),
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: "$label ",
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedIndex = 0;
  Map<String, int> _dailyAppointments = {};
  Map<String, Map<String, String>> _hourlyAppointments = {};// Stores {time: {name, surname}}
  Map<String, Map<String, List<Map<String, String>>>> _groupedHourlyAppointments = {};
  bool _showPersonal = false;
  Map<String, int> _personalAppointments = {};
  List<Map<String, dynamic>> _personalAppointmentsList = [];
  // in your State class:
  Map<String, Map<String, String>> _appointmentStatusMap = {};

  @override
  void initState() {
    super.initState();

    _loadPersonalAppointments();
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
  Future<Map<String, dynamic>> fetchPersonalAppointments() async {
    final uri = Uri.parse(
      'http://192.168.1.114/rdv_perso2.php'
          '?nom=${Uri.encodeComponent(Session.nom)}'
          '&prenom=${Uri.encodeComponent(Session.prenom)}',
    );
    print('➡️ Fetching personal appointments from: $uri');
    final resp = await http.get(uri);
    print('🔍 HTTP status: ${resp.statusCode}');
    final body = resp.body;
    print('📦 Raw body:\n$body\n');

    if (resp.statusCode != 200) {
      throw Exception('Network error: ${resp.statusCode}');
    }
    if (body.trim().isEmpty) {
      throw Exception('Empty response from server');
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    print('✅ JSON decoded: $decoded');
    if (decoded['success'] != true) {
      throw Exception('Server error: ${decoded['message'] ?? 'Unknown'}');
    }

    // 1️⃣ appointments list (each map contains patient_nom, patient_prenom, date, description, statut, diagnostic)
    final rawList = decoded['appointments'] as List<dynamic>? ?? [];
    final appointments = rawList
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    print('🎉 Parsed appointments (${appointments.length}): $appointments');
    // 2️⃣ build hourly grouping ourselves
    final Map<String, Map<String, List<Map<String, dynamic>>>> hourly = {};
    for (final appt in appointments) {
      final fullDate = appt['date'] as String;            // "2025-05-09 11:30:00"
      final parts = fullDate.split(' ');
      if (parts.length != 2) continue;
      final dateKey = parts[0];                            // "2025-05-09"
      final timeKey = parts[1];                            // "11:30:00"

      hourly.putIfAbsent(dateKey, () => {});
      hourly[dateKey]!.putIfAbsent(timeKey, () => []);
      // push the entire appointment map (with diagnostic!)
      hourly[dateKey]![timeKey]!.add(appt);
    }
    print('✅ Built hourly map: $hourly');

    return {
      'appointments': appointments,
      'hourly': hourly,
    };
  }

  bool _hasError = false;
  Future<void> _loadPersonalAppointments() async {
    try {
      final data = await fetchPersonalAppointments();

      // Flatten appointments to List<Map<String,String>>
      final personalList = (data['appointments'] as List<Map<String, dynamic>>)
          .map((e) => e.map((k, v) => MapEntry(k, v?.toString() ?? '')))
          .toList();

      // Convert hourly to Map<String, Map<String, List<Map<String,String>>>>
      final rawHourly = data['hourly'] as Map<String, dynamic>;
      final groupedHourly = <String, Map<String, List<Map<String, String>>>>{};
      rawHourly.forEach((date, slots) {
        final slotMap = <String, List<Map<String, String>>>{};
        (slots as Map<String, dynamic>).forEach((time, apps) {
          final listOfStringMaps = (apps as List<dynamic>).map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            return m.map((k, v) => MapEntry(k, v?.toString() ?? ''));
          }).toList();
          slotMap[time] = listOfStringMaps;
        });
        groupedHourly[date] = slotMap;
      });

      setState(() {
        _personalAppointmentsList   = personalList;
        _groupedHourlyAppointments = groupedHourly;
      });

      print("✅ Loaded personal appointments: $_personalAppointmentsList");
      print("✅ Loaded hourly map: $_groupedHourlyAppointments");
    } catch (e, st) {
      print("❌ Error loading personal appointments:\n$e\n$st");
      setState(() {
        _personalAppointmentsList = [];
        _groupedHourlyAppointments = {};
        _hasError = true;
      });
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
  void _showPatientDetails(String dateKey) async {
    // 1) build searchKey/displayDate
    String searchDateKey, displayDate;
    try {
      final d = DateTime.parse(dateKey);
      searchDateKey = DateFormat('yyyy-MM-dd').format(d);
      displayDate   = DateFormat('EEEE, MMMM d, y').format(d);
    } catch (_) {
      searchDateKey = dateKey;
      displayDate   = dateKey;
    }
    print('🔎 DateKey: $dateKey ➜ SearchKey: $searchDateKey');

    // 2) pull your grouped appointments
    final hourMap = _groupedHourlyAppointments[searchDateKey] ?? {};
    print('📅 Appointments for $searchDateKey:');
    final Map<String, Map<String, String>> appointmentsMap = {};

    hourMap.forEach((time, patientList) {
      if (patientList.isEmpty) return;
      final raw = patientList.first;
      print('🧾 Raw patient data at $time: $raw');

      final nom         = (raw['patient_nom']    ?? '').toString();
      final prenom      = (raw['patient_prenom'] ?? '').toString();
      final statutRaw   = raw['statut']         ?? '';
      final statut      = statutRaw.toString().isEmpty ? 'pending' : statutRaw.toString();
      final patientName = '$prenom $nom'.trim().isEmpty ? 'Inconnu' : '$prenom $nom';

      // ← pull **diagnostic** instead of description
      final diagnostic  = (raw['diagnostic'] ?? '').toString();

      print('🕒 $time • $patientName • diagnostic="$diagnostic" • statut="$statut"');

      appointmentsMap[time] = {
        'patient'   : patientName,
        'statut'    : statut,
        'diagnostic': diagnostic,    // ← store under diagnostic
      };
    });



    _showAppointmentsBottomSheet(
      context,
      searchDateKey,
      displayDate,
      appointmentsMap,
    );
  }
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
          // header
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

          // list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: appointmentsMap.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, i) {
                final entry     = appointmentsMap.entries.elementAt(i);
                final rawTime   = entry.key;
                final data      = entry.value;
                final parts     = rawTime.split(':');
                final formatted = parts.length >= 2
                    ? '${parts[0].padLeft(2,'0')}:${parts[1].padLeft(2,'0')}'
                    : rawTime;

                final name   = data['patient'] ?? 'Inconnu';
                final statut = (data['statut'] ?? '').toLowerCase().trim();
                final diag   = data['diagnostic'] ?? '';

                // ✅ Accurate statut handling
                late Widget subtitle;
                if (statut == 'completed' || statut == '1') {
                  subtitle = Row(children: const [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text('Validé', style: TextStyle(color: Colors.green)),
                  ]);
                } else if (statut == 'missed' || statut == 'non honnore' || statut == '2') {
                  subtitle = Row(children: const [
                    Icon(Icons.cancel, color: Colors.red, size: 16),
                    SizedBox(width: 4),
                    Text('Manqué', style: TextStyle(color: Colors.red)),
                  ]);
                } else if (statut == 'en cours') {
                  subtitle= Row(children: const [
                    Icon(Icons.autorenew, color: Colors.orange, size: 16),
                    SizedBox(width: 4),
                    Text('En cours', style: TextStyle(color: Colors.orange)),
                  ]);
                } else {
                  subtitle = Row(children: const [
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
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      subtitle,
                      if (diag.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text("Diagnostic: $diag",
                              style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(context);
                    final fullDateTime = '$dateKey $formatted:00';
                    _showPatientDetailsPopup(
                      dateRdv:    fullDateTime,
                      patientName: name,
                      date:        dateKey,
                      time:        formatted,
                      diagnostic:  diag,
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
    required String diagnostic,         // ← added
  }) {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedStatus;
        final descriptionController = TextEditingController();

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
                    Text('Patient: $patientName'),
                    const SizedBox(height: 8),
                    Text('Date: $date'),
                    const SizedBox(height: 8),
                    Text('Heure: $time'),
                    const SizedBox(height: 8),
                    Text('Diagnostic: $diagnostic'),   // ← displayed
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
                    Navigator.pop(context); // Close dialog first
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
            _buildSegmentButton(0, 'Aujourdhui '),
            _buildSegmentButton(1, 'Calendrier personelle'),
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
    final p = (appt['patient_prenom'] as String?)?.trim() ?? '';
    final n = (appt['patient_nom']   as String?)?.trim() ?? '';
    return '${p.isNotEmpty?p[0]:''}${n.isNotEmpty?n[0]:''}';
  }

  Widget _buildHourlySchedule() {
    final today = DateTime.now();
    final searchKey = DateFormat('yyyy-MM-dd').format(today);
    final dayMap = _groupedHourlyAppointments[searchKey] ?? {};

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: 8,
      itemBuilder: (context, idx) {
        final hour = 8 + idx;
        final hourStr = hour.toString().padLeft(2, '0');

        // collect all slots that start with this hour
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
              // timeline dot + line
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

              // card
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isPastHour ? Colors.grey.shade100 : Colors.white,
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
                        // time & marker
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
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'En cours',
                                  style: TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // either chips or empty
                        if (count > 0)
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ...appointments.take(4).map(_buildPatientChip),
                              if (count > 4)
                                GestureDetector(
                                  onTap: () => _showHourAppointmentsDialog(
                                    hour,
                                    appointments,
                                  ),
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
                                    fontStyle: FontStyle.italic),
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
    final prenom = (appt['patient_prenom'] ?? '').toString().trim();
    final nom = (appt['patient_nom'] ?? '').toString().trim();
    final name = '$prenom $nom'.trim();
    final initials = [
      if (prenom.isNotEmpty) prenom[0],
      if (nom.isNotEmpty) nom[0],
    ].join();

    return Tooltip(
      message: name.isEmpty ? 'Inconnu' : name,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 11,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              prenom,
              style: const TextStyle(
                fontSize: 13,
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
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              // Header title
              Text(
                'Rendez-vous à ${hour}h',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              // Appointment list
              ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: appointments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final appt = appointments[index] as Map<String, dynamic>;
                  final fullDate = appt['date'] as String? ?? '';
                  final parts = fullDate.split(' ');
                  final date = parts.isNotEmpty ? parts[0] : '';
                  final time = parts.length > 1 ? parts[1].substring(0,5) : '';

                  // **Use the correct keys here:**
                  final prenom = appt['patient_prenom'] as String? ?? '';
                  final nom    = appt['patient_nom']   as String? ?? '';
                  final patientName = '$prenom $nom'.trim().isEmpty
                      ? 'Inconnu'
                      : '$prenom $nom';

                  // ← diagnosis pulled from your data
                  final diagnosis = appt['diagnostic'] as String? ?? '';

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: diagnosis.isNotEmpty
                          ? Text("Diagnostic: $diagnosis",
                          style: TextStyle(color: Colors.grey[700]))
                          : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        _showPatientDetailsPopup(
                          dateRdv:    fullDate,
                          patientName: patientName,
                          date:        date,
                          time:        time,
                          diagnostic:  diagnosis,  // pass it along
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Close button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TableCalendar(
        firstDay: DateTime(2020),
        lastDay: DateTime(2030),
        focusedDay: DateTime.now(),
        calendarFormat: CalendarFormat.month,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, _) {
            // Build the key "yyyy-MM-dd"
            final key =
                '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

            // Count how many personal appointments start with that date
            final count = _personalAppointmentsList
                .where((a) {
              final d = a['date'] as String?;
              return d != null && d.startsWith(key);
            })
                .length;

            return InkWell(
              onTap: count > 0 ? () => _showPatientDetails(key) : null,
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
                    if (count > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person, size: 10, color: Colors.blue),
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
                  ],
                ),
              ),
            );
          },
        ),
      ),
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
}
class PatientsScreen extends StatefulWidget {
  final String label;
  PatientsScreen({required this.label});
  @override
  _PatientsScreenState createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _searchQuery = "";
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchPatientsByUser();
  }
  Future<void> _deletePatient(
      String nom,
      String prenom,
      BuildContext scaffoldContext,  // ← ajout
      ) async {
    final url = Uri.parse('http://192.168.1.114/delete_pat.php');
    setState(() => _isLoading = true);
    try {
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nom': nom, 'prenom': prenom}),
      );
      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['success'] == true) {
        await fetchPatientsByUser();
        // ← Utilisation du context du Scaffold, pas le context du dialogue
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(content: Text('Patient supprimé')),
        );
      } else {
        final msg = data['message'] ?? 'Erreur inconnue';
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(content: Text('Erreur suppression: $msg')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(content: Text('Erreur réseau ou format: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> fetchPatientsByUser() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final uri = Uri.parse(
        'http://192.168.1.114/pat_user.php'
            '?userNom=${Uri.encodeComponent(Session.nom)}'
            '&userPrenom=${Uri.encodeComponent(Session.prenom)}',
      );
      final response = await http.get(uri);

      print("🔹 Response status: ${response.statusCode}");
      print("🔹 Response body: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception('Erreur réseau ${response.statusCode}');
      }

      final Map<String, dynamic> data = json.decode(response.body);
      print("✅ Decoded data: $data");

      if (data['success'] != true || data['patients'] == null) {
        throw Exception('Serveur: ${data['message'] ?? 'Pas de patients retournés'}');
      }

      // On mappe directement les champs envoyés par le PHP (nom, prenom, telephone)
      final List<dynamic> list = data['patients'] as List<dynamic>;
      _patients = list.map<Map<String, dynamic>>((raw) {
        final Map<String, dynamic> p = Map<String, dynamic>.from(raw);
        return {
          'nom'            : p['nom'] ?? '',
          'prenom'         : p['prenom'] ?? '',
          'telephone'      : p['telephone'] ?? 'N/A',
        };
      }).toList();

      print("📋 Mapped patients: $_patients");

      // On initialise le filtre
      _filteredPatients = List<Map<String, dynamic>>.from(_patients);
    } catch (e) {
      print("❌ Fetch error: $e");
      setState(() {
        _hasError = true;
      });
    } finally {
      // On met à jour l'état une seule fois
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<Map<String, dynamic>> fetchPatientHistory({
    required String patientNom,
    required String patientPrenom,
  }) async {
    final url = Uri.parse("http://192.168.1.114/patient_details.php");

    final response = await http.post(url, body: {
      'patients_nom': patientNom,
      'patients_prenom': patientPrenom,
    });

    // Debug: HTTP status and raw body
    print('History fetch status: ${response.statusCode}');
    print('History fetch body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Debug: full decoded JSON
      print('Decoded history data: $data');

      if (data['success'] == true) {
        final patient = data['patient'] as Map<String, dynamic>;
        // Debug: the patient map you’ll return
        print('Patient details: $patient');
        return patient;
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la récupération');
      }
    } else {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }
  }
  void _filterPatients(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _searchQuery = q;
      if (q.isEmpty) {
        _filteredPatients = List.from(_patients);
      } else {
        _filteredPatients = _patients.where((patient) {
          final nom = (patient['nom'] as String).toLowerCase();
          final prenom = (patient['prenom'] as String).toLowerCase();
          final telephone = (patient['telephone'] as String);
          return nom.contains(q) || prenom.contains(q);
        }).toList();
      }
    });
  }

  void _showAddOptions2(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            Scaffold(
              appBar: AppBar(title: Text("Ajouter un Patient")),
              body: AddPatientScreen(),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patients', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              onChanged: _filterPatients,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: "Rechercher un patient...",
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _hasError
                ? Center(child: Text("⚠️ Erreur lors du chargement"))
                : _filteredPatients.isEmpty
                ? Center(child: Text("Aucun patient trouvé"))
                : ListView.separated(
              padding: EdgeInsets.all(10),
              itemCount: _filteredPatients.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (context, index) {
                final patient = _filteredPatients[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade900,
                    child: Text(
                      patient["nom"][0].toUpperCase(),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    "${patient["nom"]} ${patient["prenom"]}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                      "📞 ${patient['telephone'] ?? 'N/A'}"),
                  trailing:
                  Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    try {
                      final fullPatient = await fetchPatientHistory(
                        patientNom: patient['nom'],
                        patientPrenom: patient['prenom'],
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PatientDetailsScreen(fullPatient)),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Erreur chargement : $e")),
                      );
                    }
                  },
                  onLongPress: () {
                    // On capture le context du Scaffold ici
                    final scaffoldCtx = context;
                    showDialog(
                      context: scaffoldCtx,
                      builder: (dialogCtx) => AlertDialog(
                        title: Text('Supprimer ?'),
                        content: Text('Voulez-vous supprimer ${patient["nom"]} ${patient["prenom"]} ?'),
                        actions: [
                          TextButton(
                            child: Text('Annuler'),
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                          ),
                          ElevatedButton(
                            child: Text('Supprimer'),
                            onPressed: () {
                              // 1) fermer le dialogue
                              Navigator.of(dialogCtx).pop();
                              // 2) appeler la suppression avec le bon context
                              _deletePatient(
                                patient['nom'],
                                patient['prenom'],
                                scaffoldCtx,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions2(context),
        child: Icon(Icons.add, size: 30),
        backgroundColor: Colors.white,
        shape: CircleBorder(),
        elevation: 5,
      ),
    );
  }
}


class PatientDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> patient;

  PatientDetailsScreen(this.patient, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            '${patient["nom"]} ${patient["prenom"]}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),

          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TabBar(
                indicatorColor: Colors.blue.shade800,
                labelColor: Colors.blue.shade800,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(text: "Information"),
                  Tab(text: "Historique"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildInformationTab(patient),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

// ===========================
// 🔹 Patient Information Tab
// ===========================
  Widget _buildInformationTab(Map<String, dynamic> p) {
    // use the same null-safe code from before, e.g.:
    final nom = p['nom'] as String? ?? '';
    final prenom = p['prenom'] as String? ?? '';
    final telephone = p['telephone'] as String? ?? 'Non renseigné';
    final dateNaissance = p['date_naissance'] as String? ?? 'Non renseignée';
    final gender = p['gender'] as String? ?? 'Non renseigné';
    final address = p['adresse'] as String? ?? 'Non renseignée';
    final description = p['description'] as String? ?? 'Aucune description';
    final dateInscription = p['date_inscription'] as String? ?? 'Date inconnue';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              shadowColor: Colors.blue.shade900.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    children: [
                      _buildInfoItem(
                        Icons.person,
                        "Nom complet",
                        "${patient["nom"]} ${patient["prenom"]}",
                        primary: true,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, thickness: 1),
                      ),
                      _buildInfoItem(
                        Icons.phone_rounded,
                        "Téléphone",
                        patient["telephone"] ?? "Non renseigné",
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, thickness: 1),
                      ),
                      _buildInfoItem(
                        Icons.cake_rounded,
                        "Date de naissance",
                        patient["date_naissance"] ?? "Non renseignée",
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, thickness: 1),
                      ),
                      _buildInfoItem(
                        Icons.transgender,
                        "Genre",
                        patient["gender"] ?? "Non renseigné",
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, thickness: 1),
                      ),
                      _buildInfoItem(
                        Icons.home_rounded,
                        "Adresse",
                        patient["adresse"] ?? "Non renseignée",
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, thickness: 1),
                      ),
                      _buildInfoItem(
                        Icons.description_rounded,
                        "Description",
                        patient["description"] ?? "Aucune description",
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, thickness: 1),
                      ),
                      _buildInfoItem(
                        Icons.calendar_today_rounded,
                        "Date d'inscription",
                        patient["date_inscription"] ?? "Date inconnue",
                      ),
            ]),
          ),
        ),
      ]),
    );
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
            color: primary ? Colors.blue.shade900 : Colors.grey.shade700,
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
                    color: primary ? Colors.blue.shade900 : Colors.black,
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
// 🔹 Appointment History Tab
// ===========================
  Widget _buildHistoryTab() {
    final rawList = patient['rendez_vous'] as List<dynamic>? ?? [];
    final now = DateTime.now();

    // 1) Build a strongly-typed list of appointments
    final List<Map<String, dynamic>> processed = rawList.map((raw) {
      final dateStr = raw['date_rdv'] as String? ?? '';
      DateTime? date;
      try {
        date = DateTime.parse(dateStr);
      } catch (_) {
        date = null;
      }
      // normalize statut to lowercase or empty
      String statut = (raw['statut'] as String?)?.toLowerCase().trim() ?? '';
      // if past and statut empty => missed
      if (date != null && date.isBefore(now) && statut.isEmpty) {
        statut = 'missed';
      }
      return {
        'parsedDate': date,
        'statut': statut,
        'description': raw['description'] as String? ?? '',
      };
    }).toList();

    // 2) Split into categories:
    final upcoming = processed.where((a) {
      final d = a['parsedDate'] as DateTime?;
      final s = (a['statut'] as String);
      // Show if date in future AND statut is 'pending' or empty
      return d != null
          && d.isAfter(now)
          && (s.isEmpty || s == 'pending');
    }).toList();

    final completed = processed.where((a) {
      return (a['statut'] as String) == 'completed';
    }).toList();

    final missed = processed.where((a) {
      final d = a['parsedDate'] as DateTime?;
      final s = (a['statut'] as String);
      return s == 'missed'
          || (d != null && d.isBefore(now) && (s.isEmpty || s == 'pending'));
    }).toList();

    // 3) Determine overall patient status
    String patientStatus = '0';
    if (missed.isNotEmpty) {
      patientStatus = 'non honnore';
    } else if (completed.isNotEmpty) {
      patientStatus = '1';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ——— Status Banner ———
          if (patientStatus != '0')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: patientStatus == '1'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: patientStatus == '1' ? Colors.green : Colors.orange,
                  width: 1,
                ),
              ),
              child: Row(children: [
                Icon(
                  patientStatus == '1'
                      ? Icons.check_circle
                      : Icons.warning_rounded,
                  color: patientStatus == '1' ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    patientStatus == '1'
                        ? 'Patient a honoré ses rendez-vous'
                        : 'Patient a des rendez-vous non honorés',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: patientStatus == '1' ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ]),
            ),

          // ——— Stats Summary ———
          _buildStats(processed),
          const SizedBox(height: 20),

          // ——— Upcoming ———
          if (upcoming.isNotEmpty) ...[
            _sectionTitle('Prochains rendez-vous', Icons.calendar_today),
            const SizedBox(height: 8),
            ...upcoming.map((appt) => _appointmentCard(
              appt,
              Colors.blue.shade100,
              icon: Icons.access_time_filled,
            )),
            const SizedBox(height: 20),
          ],

          // ——— Completed ———
          if (completed.isNotEmpty) ...[
            _sectionTitle('Rendez-vous honorés', Icons.check_circle),
            const SizedBox(height: 8),
            ...completed.map((appt) => _appointmentCard(
              appt,
              Colors.green.shade100,
              icon: Icons.done_all,
            )),
            const SizedBox(height: 20),
          ],

          // ——— Missed ———
          if (missed.isNotEmpty) ...[
            _sectionTitle('Rendez-vous manqués', Icons.warning_rounded),
            const SizedBox(height: 8),
            ...missed.map((appt) => _appointmentCard(
              appt,
              Colors.orange.shade100,
              icon: Icons.error_outline,
            )),
          ],

          // ——— No Appointments ———
          if (processed.isEmpty) ...[
            const SizedBox(height: 40),
            Center(
              child: Column(children: [
                Icon(Icons.calendar_today, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Aucun rendez-vous enregistré',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }


// ===========================
// 🔹 Single Appointment Card
// ===========================
  Widget _appointmentCard(Map<String, dynamic> appt, Color bgColor,
      {required IconData icon}) {
    final DateTime? date = appt['parsedDate'];
    final String dateText = date != null
        ? DateFormat('EEE, MMM d y • HH:mm').format(date.toLocal())
        : 'Date inconnue';

    final String statut = (appt['statut'] as String?) ?? '';
    final String description = (appt['description'] as String?) ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Icon(icon, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(dateText, style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 4),
                if (statut.isNotEmpty)
                  Text(
                    'Statut : ${statut[0].toUpperCase()}${statut.substring(1)}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

Widget _buildStats(List<dynamic> appointments) {
  final int consultationsCount = appointments
      .where((a) => (a['statut'] as String?)?.toLowerCase() == 'completed')
      .length;

  final int missedCount = appointments
      .where((a) => (a['statut'] as String?)?.toLowerCase() == 'missed')
      .length;

  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        _statBox(
          Icons.medical_services,
          "Consultations",
          consultationsCount.toString(),
          Colors.blue.shade900,
        ),
        const SizedBox(width: 15),
        _statBox(
          Icons.close,
          "Non honorées",
          missedCount.toString(),
          Colors.red.shade700,
        ),
      ]),
    ),
  );
}

Widget _statBox(IconData icon, String label, String value, Color color) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
      ]),
    ),
  );
}

Widget _sectionTitle(String title, IconData icon) {
  return Row(children: [
    Icon(icon, size: 20, color: Colors.grey.shade700),
    const SizedBox(width: 8),
    Text(
      title,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
    ),
  ]);
}
