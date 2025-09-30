import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:intl/date_symbol_data_local.dart';
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
class AddPatientScreen extends StatefulWidget {
  @override
  _AddPatientScreenState createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _dateNaissanceController =
  TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _gender;

  Future<void> _addPatient() async {
    final url = Uri.parse('http://192.168.1.114/add_patient.php');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nom": _nomController.text,
        "prenom": _prenomController.text,
        "date_naissance": _dateNaissanceController.text,
        "telephone": _telephoneController.text,
        "gender": _gender,
        "adresse": _adresseController.text,
        "description": _descriptionController.text,
      }),
    );
    if (response.statusCode == 200) {
      Navigator.pop(context); // Close the form
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Patient added successfully!")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to add patient.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16).copyWith(
        bottom: MediaQuery
            .of(context)
            .viewInsets
            .bottom + 16,
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
  String? _selectedResident;
  String?
  _selectedDiagnostic; // Nouveau: pour stocker le diagnostic sélectionné
  List<String> _diagnostics = [];
  List<Map<String, dynamic>> _usersByRole = [];
  String? _selectedUserFullName;
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
    "Enseignant": ['Biodépulpation sur mono/biradiculée',
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
      'Gestion des patients à risque', 'Thérapeutique dentinaire et préparation de cavité pour classe I',
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
      'Restauration prophylactique',"Perte de substance d'origine carieuse : Reconstitution des faces occlusales",
      "Perte de substance d'origine carieuse : Reconstitution des faces proximales",
      "Perte de substance d'origine carieuse : Reconstitution du 1/3 cervical",
      "Perte de substance d'origine non carieuse",
      "Thérapeutique de la dent de 06 ans",
      "Biodépulpation sur mono/biradiculée",
      "Biodépulpation sur pluriradiculée",
      "Traitements des LIPOE sur mono/biradiculée",
      "Traitements des LIPOE sur pluriradiculée",
      "Thérapeutiques dentinogènes sur dents temporaires",
      "Gestion des patients à risque.", "Thérapeutiques restauratrices sur dent antérieure vivante",
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
      "Traitement des dyschromies","Techniques de restaurations indirectes",
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

  Future<void> fetchUsersByRole(String role) async {
    final url = Uri.parse('http://192.168.1.114/get_role.php');
    final resp = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"role": role}),
    );

    final Map<String, dynamic> data = jsonDecode(resp.body);

    if (data["success"] == true) {
      List<dynamic> users = data["users"];

      setState(() {
        _usersByRole =
            users.map<Map<String, dynamic>>((user) {
              return {
                "nom": user["nom"],
                "prenom": user["prenom"],
                "fullName": "${user["nom"]} ${user["prenom"]}", // 💥 new field
              };
            }).toList();
        _selectedUserFullName = null;
      });
    } else {
      print("Erreur: ${data["message"]}");
    }
  }

  String? _errorMessage;

  Future<void> _addRendezVous() async {
    final url = Uri.parse('http://192.168.1.114/add_rdv.php');

    if (_nomController.text.isEmpty ||
        _prenomController.text.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null ||
        _descriptionController.text.isEmpty ||
        _selectedResident == null ||
        _selectedDiagnostic == null ||
        _selectedUserFullName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }



    final body = jsonEncode({
      "patients_nom": _nomController.text,
      "patients_prenom": _prenomController.text,
      "date_rdv":
      "${_selectedDate!.toIso8601String().split('T')[0]} ${_selectedTime!
          .hour}:${_selectedTime!.minute}:00",
      "description": _descriptionController.text,
      "utilisateurs_role": _selectedResident,
      "diagnostic": _selectedDiagnostic,
      "utilisateur_nom_complet": _selectedUserFullName, // 💥 send full name
    });
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    final responseData = jsonDecode(response.body);
    if (responseData["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Rendez-vous ajouté avec succès!")),
      );
      Navigator.pop(context);
    } else {
      setState(
            () =>
        _errorMessage = "Échec de l'ajout: ${responseData["message"]}",
      );
    }
  }

  void initState() {
    super.initState();
    // Pre-set the logged-in user’s full name
    _selectedUserFullName = "${Session.nom} ${Session.prenom}";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery
            .of(context)
            .viewInsets
            .bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            TextField(
              controller: _nomController,
              decoration: InputDecoration(labelText: "Nom"),
            ),
            TextField(
              controller: _prenomController,
              decoration: InputDecoration(labelText: "Prénom"),
            ),
            TextField(
              controller: _dateController,
              decoration: InputDecoration(labelText: "Date du rendez-vous"),
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                    _dateController.text =
                    "${pickedDate.toLocal()}".split(' ')[0];
                  });
                }
              },
            ),
            TextField(
              controller: _timeController,
              decoration: InputDecoration(labelText: "Heure du rendez-vous"),
              readOnly: true,
              onTap: () async {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  setState(() {
                    _selectedTime = pickedTime;
                    _timeController.text = pickedTime.format(context);
                  });
                }
              },
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Description"),
            ),
            SizedBox(height: 16),

            // 1️⃣ Select Role
            DropdownButtonFormField<String>(
              isExpanded: true,
              // ← Ajouté
              decoration: const InputDecoration(
                  labelText: "Sélectionner le rôle"),
              value: _selectedResident,
              onChanged: (String? newValue) async {
                setState(() {
                  _selectedResident = newValue;
                  _selectedDiagnostic = null;
                  _usersByRole = [];
                  _selectedUserFullName = null;
                  _diagnostics = _casObligatoires[newValue] ?? [];
                });

                if (newValue == 'Enseignant') {
                  setState(() {
                    _selectedUserFullName = "${Session.nom} ${Session.prenom}";
                  });
                } else if (newValue != null) {
                  await fetchUsersByRole(newValue);
                }
              },
              items: _casObligatoires.keys.map((role) {
                return DropdownMenuItem(value: role, child: Text(role));
              }).toList(),
            ),

            // 2️⃣ Select User (only shown if NOT enseignant)
            if (_selectedResident != 'Enseignant') ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                // ← Ajouté
                decoration: const InputDecoration(
                    labelText: "Sélectionner le médecin"),
                value: _selectedUserFullName,
                onChanged: (String? newFullName) {
                  setState(() {
                    _selectedUserFullName = newFullName;
                  });
                },
                items: _usersByRole.map((user) {
                  return DropdownMenuItem<String>(
                    value: user['fullName'],
                    child: Text(user['fullName']),
                  );
                }).toList(),
              ),
            ],

            // 3️⃣ Select Diagnostic (always shown)
            if (_selectedResident != null) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                // ← Ajouté
                decoration: const InputDecoration(
                    labelText: "Sélectionner un diagnostic"),
                value: _selectedDiagnostic,
                onChanged: (String? newValue) {
                  setState(() => _selectedDiagnostic = newValue);
                },
                items: _diagnostics.map((diag) {
                  return DropdownMenuItem(value: diag, child: Text(diag));
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addRendezVous,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade100,
                foregroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 12),
              ),
              child: const Text("Ajouter Rendez-vous"),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}