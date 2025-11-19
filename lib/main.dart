import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Splash(title: 'Chat App'),
    );
  }
}

class Splash extends StatelessWidget {
  const Splash({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 98, 39, 176),
        title: Text(title, style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Signin(title: 'Sign In'),
                  ),
                );
              },
              child: Text('Sign In'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Signup()),
                );
              },
              child: Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}

class Signin extends StatefulWidget {
  const Signin({super.key, required this.title});

  final String title;

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _fail = false;

  void _signInWithEmailAndPassword() async {
    try {
      await auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SelectScreen()),
        );
      });
    } catch (e) {
      setState(() {
        _fail = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 98, 39, 176),
        title: Text(widget.title, style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                child: Text('Sign In', style: TextStyle(fontSize: 24)),
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _signInWithEmailAndPassword();
                    }
                  },
                  child: Text('Submit'),
                ),
              ),
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _fail
                      ? 'Sign in failed'
                      : 'Enter email and password to sign in',
                  style: TextStyle(color: _fail ? Colors.red : Colors.green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final FirebaseAuth auth = FirebaseAuth.instance;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  bool _fail = false;
  String error = '';

  void _register() async {
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Add user to Firestore using the Firebase Auth UID
      await addUser(userCredential.user!.uid);

      final snackBar = SnackBar(content: const Text('Registration Successful'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _fail = true;
        error = e.toString();
      });
      print('Registration error: $e');
    }
  }

  Future<void> addUser(String userId) async {
    try {
      print('Adding user to Firestore with ID: $userId');
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'userid': userId,
        'displayname': _displayNameController.text,
        'firstname': _firstNameController.text,
        'lastname': _lastNameController.text,
        'role': 'user',
        'imageurl': null,
        'signupdate': Timestamp.fromDate(DateTime.now()),
      });
      print('User successfully added to Firestore');
    } catch (e) {
      print('Error adding user to Firestore: $e');
      setState(() {
        _fail = true;
        error = e.toString();
      });
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 98, 39, 176),
        title: Text('Signup', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),

                    TextFormField(
                      controller: _displayNameController,
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter your display name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _register();
                          }
                        },
                        child: Text('Submit'),
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _fail
                            ? 'Registration failed - $error'
                            : 'Enter email and password to register',
                        style: TextStyle(
                          color: _fail ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectScreen extends StatefulWidget {
  const SelectScreen({super.key});

  @override
  State<SelectScreen> createState() => _SelectScreenState();
}

class _SelectScreenState extends State<SelectScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 98, 39, 176),
        title: Text('Message Boards', style: TextStyle(color: Colors.white),),
      ),
      drawer: appbarDrawer(),
      body: Column(
        children: <Widget>[
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GamesScreen()),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: Image.asset(
                      'assets/game.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        'Games',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                        color: Colors.black,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.white,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FilmsScreen()),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: Image.asset(
                      'assets/film.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        'Films',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TVScreen()),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: Image.asset(
                      'assets/tv.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        'TV Shows',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                        color: Colors.black,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.white,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BooksScreen()),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: Image.asset(
                      'assets/book.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        'Books',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GamesScreen extends StatefulWidget {
  @override
  _GamesScreenState createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  @override
  Widget build(BuildContext context) {
    return messageroombody(roomId: 'games', title: 'Games Chatroom',);  
  }
}

class FilmsScreen extends StatefulWidget {
  @override
  _FilmsScreenState createState() => _FilmsScreenState();
}

class _FilmsScreenState extends State<FilmsScreen> {
  @override
  Widget build(BuildContext context) {
    return messageroombody(roomId: 'films', title: 'Films Chatroom',);
  }
}

class TVScreen extends StatefulWidget {
  @override
  _TVScreenState createState() => _TVScreenState();
}

class _TVScreenState extends State<TVScreen> {
  @override
  Widget build(BuildContext context) {
    return messageroombody(roomId: 'tv', title: 'TV Shows Chatroom',);
  }
}

class BooksScreen extends StatefulWidget {
  @override
  _BooksScreenState createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  @override
  Widget build(BuildContext context) {
    return messageroombody(roomId: 'books', title: 'Books Chatroom',);
  }
}

class profilescreen extends StatefulWidget {
  @override
  _profilescreenState createState() => _profilescreenState();
}

class _profilescreenState extends State<profilescreen> {
  final TextEditingController _displayNameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _isLoadingData = true;
  String? name;
  String? currentimage;
  String? imagestring;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          setState(() {
            name = userData['displayname'];
            currentimage = userData['imageurl'];
            _isLoadingData = false;
          });
        } else {
          setState(() {
            _isLoadingData = false;
          });
        }
      } else {
        setState(() {
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _updateDisplayName() async {
    if (_displayNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a display name')));
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      String userId = _auth.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'displayname': _displayNameController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Display name updated successfully')),
      );
      setState(() {
        name = _displayNameController.text;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating display name: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfileImage() async {
    if (imagestring == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select an image first')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String userId = _auth.currentUser!.uid;
      String cleanBase64 = imagestring!.replaceAll(RegExp(r'\s+'), '');

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'imageurl': cleanBase64,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile image updated successfully')),
      );
      setState(() {
        currentimage = cleanBase64;
      });
    } catch (e) {
      print('Error updating profile image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile image: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile Screen', style: TextStyle(color: Colors.white)), backgroundColor: const Color.fromARGB(255, 98, 39, 176),),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Profile Screen', style: TextStyle(color: Colors.white)), backgroundColor: const Color.fromARGB(255, 98, 39, 176),),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            currentimage == null
                ? Icon(Icons.account_circle, size: 225)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(100.0),
                    child: Builder(
                      builder: (context) {
                        try {
                          return Image.memory(
                            base64Decode(currentimage!),
                            height: 200,
                            width: 200,
                            fit: BoxFit.cover,
                          );
                        } catch (e) {
                          return Icon(Icons.account_circle, size: 225);
                        }
                      },
                    ),
                  ),
            SizedBox(height: 10),
            Text(
              name ?? 'No name set',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text('Display Name'),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: 'New Display Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateDisplayName,
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Update Display Name'),
            ),
            SizedBox(height: 20),
            Text('Profile Picture'),
            ElevatedButton(
              onPressed: () async {
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) {
                  final Uint8List bytes = await image.readAsBytes();
                  setState(() {
                    imagestring = base64Encode(bytes);
                  });
                  print('Selected image path: ${image.path}');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 188, 44, 44),
              ),
              child: Text(
                'Select Image',
                style: TextStyle(color: Colors.white),
              ),
            ),
            if (imagestring != null) ...[
              SizedBox(height: 10),
              Text('Image selected', style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(100.0),
                child: Builder(
                  builder: (context) {
                    try {
                      return Image.memory(
                        base64Decode(imagestring!),
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                      );
                    } catch (e) {
                      return Container(
                        height: 150,
                        width: 200,
                        color: Colors.grey[300],
                        child: Center(child: Text('Error loading image')),
                      );
                    }
                  },
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfileImage,
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Save Profile Image'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class settingsscreen extends StatefulWidget {
  @override
  _settingsscreenState createState() => _settingsscreenState();
}

class _settingsscreenState extends State<settingsscreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GlobalKey<FormState> _nameKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _emailKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _passKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _currentPassKey = GlobalKey<FormState>();
  TextEditingController _passController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _currentPassController = TextEditingController();
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  String? currentfname;
  String? currentlname;

  void initState() {
    super.initState();
    String userId = _auth.currentUser!.uid;
    FirebaseFirestore.instance.collection('users').doc(userId).get().then((
      doc,
    ) {
      if (doc.exists) {
        setState(() {
          currentfname = doc['firstname'];
          currentlname = doc['lastname'];
        });
      }
    });
  }

  void _signOut() async {
    await _auth.signOut();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Signed out successfully')));
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void updatename() async {
    try {
      String userId = _auth.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'firstname': _firstNameController.text,
        'lastname': _lastNameController.text,
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Name updated successfully')));
      setState(() {
        currentfname = _firstNameController.text;
        currentlname = _lastNameController.text;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update name: $e')));
    }
  }

  void updatepassword() async {
    try {
      if (_auth.currentUser != null && _auth.currentUser?.email != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: _auth.currentUser!.email!,
          password: _currentPassController.text,
        );
        await _auth.currentUser!.reauthenticateWithCredential(credential);
      }
      await _auth.currentUser?.updatePassword(_passController.text);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Password updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update password: $e')));
    }
  }

  void updateemail() async {
    try {
      if (_auth.currentUser != null && _auth.currentUser?.email != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: _auth.currentUser!.email!,
          password: _currentPassController.text,
        );
        await _auth.currentUser!.reauthenticateWithCredential(credential);
      }
      await _auth.currentUser?.updateEmail(_emailController.text);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Email updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update email: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings Screen', style: TextStyle(color: Colors.white)), backgroundColor: const Color.fromARGB(255, 98, 39, 176),),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Name'),
            Text('$currentfname $currentlname'),
            ElevatedButton(onPressed: _signOut, child: Text('Sign Out')),
            SizedBox(height: 20),
            Text('Update Personal Information'),
            SizedBox(height: 10),
            Form(
              key: _nameKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'New First Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your First Name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'New Last Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your Last Name';
                      }
                      return null;
                    },
                  ),

                  ElevatedButton(
                    onPressed: () {
                      if (_nameKey.currentState!.validate()) {
                        updatename();
                      }
                    },
                    child: Text('Update First & Last Name'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text('Update Credentials (Current Password Required)'),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Form(
                    key: _currentPassKey,
                    child: TextFormField(
                      controller: _currentPassController,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter your current password';
                        }
                        return null;
                      },
                      obscureText: true,
                    ),
                  ),
                  SizedBox(height: 20),
                  Form(
                    key: _passKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _passController,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please enter your new password';
                            }
                            return null;
                          },
                          obscureText: true,
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            bool currentPassValid =
                                _currentPassKey.currentState?.validate() ??
                                false;
                            bool newPassValid =
                                _passKey.currentState?.validate() ?? false;
                            if (currentPassValid && newPassValid) {
                              updatepassword();
                            }
                          },
                          child: Text('Update Password'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Form(
                    key: _emailKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'New Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please enter your new email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            bool currentPassValid =
                                _currentPassKey.currentState?.validate() ??
                                false;
                            bool newEmailValid =
                                _emailKey.currentState?.validate() ?? false;
                            if (currentPassValid && newEmailValid) {
                              updateemail();
                            }
                          },
                          child: Text('Update Email'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class appbarDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromARGB(255, 98, 39, 176),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(child: Text('Navigation', style: TextStyle(color: Colors.white, fontSize: 50)), 
            decoration: BoxDecoration(color: Color.fromARGB(255, 98, 39, 176)),),
            ListTile(
              title: const Text('Message Boards', style: TextStyle(color: Colors.white, fontSize: 25)),
              trailing: Icon(Icons.message, color: Colors.white,),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SelectScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('My Profile', style: TextStyle(color: Colors.white, fontSize: 25)),
              trailing: Icon(Icons.account_circle, color: Colors.white,),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => profilescreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 25)),
              trailing: Icon(Icons.settings, color: Colors.white,),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => settingsscreen()),
                );
              },
            ),
          ],
        ),
    );
  }
}

class messageroombody extends StatefulWidget {

  final String roomId;
  final String title;

  messageroombody({required this.roomId, required this.title});

  @override
  _messageroombodyState createState() => _messageroombodyState();
}

class _messageroombodyState extends State<messageroombody> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    try {
      String userId = _auth.currentUser!.uid;
      await FirebaseFirestore.instance.collection('messages').doc(widget.roomId).collection('messages').add({
        'message': _messageController.text.trim(),
        'userId': userId,
        'timestamp': Timestamp.now(),
      });
      
      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();
    
    if (dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day) {
      // Today - show time only
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Other days - show date and time
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 98, 39, 176),
        title: Text(widget.title, style: TextStyle(color: Colors.white)),
      ),
      drawer: appbarDrawer(),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No messages yet. Start the conversation!'));
                }

                return ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.all(8.0),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var messageDoc = snapshot.data!.docs[index];
                    Map<String, dynamic> message = messageDoc.data() as Map<String, dynamic>;
                    String messageText = message['message'] ?? '';
                    String userId = message['userId'] ?? '';
                    Timestamp timestamp = message['timestamp'] ?? Timestamp.now();
                    bool isCurrentUser = userId == _auth.currentUser?.uid;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get(),
                      builder: (context, userSnapshot) {
                        String username = 'Unknown';
                        String? userImage;

                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          username = userData['displayname'] ?? 'Unknown';
                          userImage = userData['imageurl'];
                        }

                        return Align(
                          alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                            child: Column(
                              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isCurrentUser) ...[
                                      userImage == null
                                          ? Icon(Icons.account_circle, size: 30)
                                          : ClipRRect(
                                              borderRadius: BorderRadius.circular(15.0),
                                              child: Builder(
                                                builder: (context) {
                                                  try {
                                                    return Image.memory(
                                                      base64Decode(userImage!),
                                                      height: 30,
                                                      width: 30,
                                                      fit: BoxFit.cover,
                                                    );
                                                  } catch (e) {
                                                    return Icon(Icons.account_circle, size: 30);
                                                  }
                                                },
                                              ),
                                            ),
                                      SizedBox(width: 8),
                                    ],
                                    Text(
                                      isCurrentUser ? 'You' : username,
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    if (isCurrentUser) ...[
                                      SizedBox(width: 8),
                                      userImage == null
                                          ? Icon(Icons.account_circle, size: 30)
                                          : ClipRRect(
                                              borderRadius: BorderRadius.circular(15.0),
                                              child: Builder(
                                                builder: (context) {
                                                  try {
                                                    return Image.memory(
                                                      base64Decode(userImage!),
                                                      height: 30,
                                                      width: 30,
                                                      fit: BoxFit.cover,
                                                    );
                                                  } catch (e) {
                                                    return Icon(Icons.account_circle, size: 30);
                                                  }
                                                },
                                              ),
                                            ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: 4),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                  decoration: BoxDecoration(
                                    color: isCurrentUser ? Colors.blue[100] : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Text(
                                    messageText,
                                    style: TextStyle(fontSize: 16.0),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(timestamp),
                                  style: TextStyle(
                                    fontSize: 10.0,
                                    color: Colors.grey[600],
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
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8.0),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}