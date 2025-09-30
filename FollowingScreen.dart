import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'main.dart';
import 'PatientScreen.dart';
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
class FollowingScreen extends StatefulWidget {
  @override
  _FollowingScreenState createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.114/get_utilisateurs.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final allUsers = data['users'];

          final filteredUsers = allUsers.where((user) {
            final role = (user['role'] ?? '').toString().toLowerCase();
            final nom = (user['nom'] ?? '').toString().trim();
            final prenom = (user['prenom'] ?? '').toString().trim();

            // Si ce n'est pas un enseignant, on l'affiche
            if (role != 'Enseignant') return true;

            // Si c'est un enseignant, on ne garde que l'utilisateur connecté
            return nom == Session.nom && prenom == Session.prenom;
          }).toList();

          setState(() {
            _users = filteredUsers;
            _isLoading = false;
          });
        } else {
          throw Exception(data['error'] ?? 'Unknown error occurred');
        }
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }


  Future<void> _deleteUser(String nom, String prenom) async {
    final url = Uri.parse('http://192.168.1.114/delete_user.php');
    setState(() => _isLoading = true);

    try {
      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"nom": nom, "prenom": prenom}),
      );
      final data = json.decode(resp.body);
      if (resp.statusCode == 200 && data['success'] == true) {
        await _fetchUsers();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Utilisateur supprimé')));
      } else {
        final msg = data['message'] ?? 'Erreur inconnue';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur suppression: $msg')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur réseau ou format: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'Enseignant':
        return Colors.blue.shade800;
      case 'resident':
        return Colors.teal.shade700;
      case 'interne':
        return Colors.deepPurple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'Enseignant':
        return Icons.school_rounded;
      case 'resident':
        return Icons.medical_services_rounded;
      case 'interne':
        return Icons.work_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  List<dynamic> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      final fullName = '${user['prenom']} ${user['nom']}'.toLowerCase();
      return fullName.contains(_searchQuery.toLowerCase()) ||
          user['email'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user['role'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showAddOptions3(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
            Scaffold(
              appBar: AppBar(title: Text("Ajouter un Praticien")),
              body: AddUserScreen(), // your existing screen
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // group filtered users by role
    final Map<String, List<Map<String, dynamic>>> byRole = {};
    for (var u in _filteredUsers) {
      final role = u['role'] as String;
      byRole.putIfAbsent(role, () => []).add(u);
    }
    final roles = byRole.keys.toList()
      ..sort();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'Praticien',
          style: TextStyle(
            color: Colors.blue.shade900,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.blue.shade800),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: 24),
            onPressed: _fetchUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // … your search bar here, unchanged …
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Recherche de praticien',
                prefixIcon: Icon(
                    Icons.search_rounded, color: Colors.grey.shade500),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.close_rounded, color: Colors.grey.shade500),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // … loading / error / empty states unchanged …
          Expanded(
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.blue.shade800),
              ),
            )
                : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : _filteredUsers.isEmpty
                ? Center(
              child: Text(
                _searchQuery.isEmpty
                    ? 'Aucun praticien disponible'
                    : 'Aucun résultat trouvé',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
                : RefreshIndicator(
              color: Colors.blue.shade800,
              onRefresh: _fetchUsers,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (var role in roles) ...[
                    // Role header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        role,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    // Practitioners of this role
                    ...byRole[role]!.map((u) {
                      final fullName = '${u['prenom']} ${u['nom']}';
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        UtilisateurDetailsScreen(u),
                                  ),
                                ),
                            onLongPress: () =>
                                showDialog(
                                  context: context,
                                  builder: (d) =>
                                      AlertDialog(
                                        title: Text('Supprimer ?'),
                                        content: Text(
                                            'Voulez‑vous supprimer $fullName ?'),
                                        actions: [
                                          TextButton(
                                            child: Text('Annuler'),
                                            onPressed: () =>
                                                Navigator.of(d).pop(),
                                          ),
                                          ElevatedButton(
                                            child: Text('Supprimer'),
                                            onPressed: () async {
                                              Navigator.of(d).pop();
                                              await _deleteUser(
                                                  u['nom'], u['prenom']);
                                            },
                                          ),
                                        ],
                                      ),
                                ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _getRoleColor(u['role'])
                                          .withOpacity(0.15),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${u['prenom'][0]}${u['nom'][0]}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: _getRoleColor(
                                              u['role']),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fullName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                            FontWeight.w600,
                                            color: Colors
                                                .grey.shade900,
                                          ),
                                          maxLines: 1,
                                          overflow:
                                          TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              _getRoleIcon(
                                                  u['role']),
                                              size: 14,
                                              color:
                                              _getRoleColor(
                                                  u['role']),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              u['role'],
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                FontWeight.w500,
                                                color: _getRoleColor(
                                                    u['role']),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          u['email'],
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors
                                                .grey.shade600,
                                          ),
                                          maxLines: 1,
                                          overflow:
                                          TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded,
                                      color: Colors.grey.shade400),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
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
}
class AddUserScreen extends StatefulWidget {
  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  String _selectedRole = "Enseignant";
  String? _selectedResidentLevel;
  bool _isLoading = false;
  Future<void> _addUser() async {
    final url = Uri.parse('http://192.168.1.114/add_utilisateur.php');

    final Map<String, dynamic> body = {
      "nom": _nomController.text,
      "prenom": _prenomController.text,
      "email": _emailController.text,
      "mot_de_passe": _passwordController.text,
      "telephone": _telephoneController.text,
      "role": _selectedRole,
    };

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Utilisateur ajouté avec succès!")),
        );
        Navigator.pop(context);
      } else {
        throw Exception(data['message'] ?? "Erreur inconnue");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Échec: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
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
            controller: _emailController,
            decoration: InputDecoration(labelText: "Email"),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: "Mot de passe"),
            obscureText: true,
          ),
          TextField(
            controller: _telephoneController,
            decoration: InputDecoration(labelText: "Téléphone"),
            keyboardType: TextInputType.phone,
          ),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            items:
            ["Enseignant",  "Interne" , "Resident 1" , "Resident 2" , "Resident 3" , "Resident 4"]
                .map(
                  (role) =>
                  DropdownMenuItem(value: role, child: Text(role)),
            )
                .toList(),
            onChanged:
                (val) => setState(() {
              _selectedRole = val!;
            }),
            decoration: InputDecoration(labelText: "Rôle"),
          ),
          SizedBox(height: 20),
          _isLoading
              ? CircularProgressIndicator()
              : ElevatedButton(
            onPressed: _addUser,
            child: Text("Ajouter Utilisateur"),
          ),
        ],
      ),
    );
  }
}