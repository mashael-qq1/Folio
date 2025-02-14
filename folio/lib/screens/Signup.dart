
// ignore_for_file: prefer_const_constructors
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/LoginPage.dart';
import 'package:folio/screens/ProfileSetup.dart';
import 'package:folio/screens/first.page.dart';
import 'package:flutter/services.dart';
import 'package:folio/screens/homePage.dart';
import 'package:image_picker/image_picker.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _booksController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;
  bool _obscurePassword = true; // Password visibility state
  bool _obscureConfirmPassword = true; // Confirm password visibility state

 
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;// Firestore instance

@override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _booksController.dispose();
    super.dispose();
  }
   // Function to pick image from gallery or camera
  Future<void> _showImagePickerOptions(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => BottomSheet(
        onClosing: () {},
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Take a Photo'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
 
  // Function to pick an image
Future<void> _pickImage(ImageSource source) async {
  final pickedFile = await _picker.pickImage(source: source);
  if (pickedFile != null) {
    setState(() {
      _imageFile = File(pickedFile.path);
    });
  }
}
// Upload profile photo to Firebase Storage
  Future<String?> _uploadProfilePhoto(String userId) async {
    if (_imageFile != null) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_photos')
            .child('$userId.jpg');
       await ref.putFile(_imageFile!);
        return await ref.getDownloadURL();
      } catch (e) {
        print('Error uploading profile photo: $e');
        return null;
      }
    }
    return null;
  }

  // Check if username or email already exists
  Future<bool> checkIfUsernameExists(String username) async {
    final QuerySnapshot result = await _firestore
        .collection('reader')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    final List<DocumentSnapshot> documents = result.docs;
    return documents.isNotEmpty; // Returns true if username exists
  }

  Future<bool> checkIfEmailExists(String email) async {
    final QuerySnapshot result = await _firestore
        .collection('reader')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    final List<DocumentSnapshot> documents = result.docs;
    return documents.isNotEmpty; // Returns true if email exists
  }

  // show dialg function
  void showEmailConfirmationDialog(BuildContext context, String email) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        contentPadding: EdgeInsets.all(24.0),
        content: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 32.0), // To add space for the X icon
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // email icon
                  Icon(Icons.email, size: 48.0, color: Color(0xFFF790AD)),
                  SizedBox(height: 16.0),
                  Text(
                    'Email Confirmation',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.0),
                 Text.rich(
  TextSpan(
    text: 'We have sent an email to ', // Default text before the email
    style: TextStyle(color: Colors.black), // Default style for the text
    children: [
      TextSpan(
        text: email, // The email that should be in pink
        style: TextStyle(
          color: Color(0xFFF790AD), // Pink color for the email
          fontWeight: FontWeight.bold, // Optional: make the email bold
        ),
      ),
      TextSpan(
        text:
            ' to confirm the validity of your email address. After receiving the email, follow the link provided to complete your registration.', // Remaining text after the email
        style: TextStyle(color: Colors.black), // Default style for the remaining text
      ),
    ],
  ),
  textAlign: TextAlign.center, // Align the text to the center
),

                  SizedBox(height: 24.0),
                  // Resend button
                  ElevatedButton(
                    onPressed: () async {
                      try {
                      
                      await _auth.currentUser!.sendEmailVerification();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Verification email resent")),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error resending email: ${e.toString()}")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFF790AD),
                      padding: EdgeInsets.symmetric(horizontal: 48.0, vertical: 16.0),
                      textStyle: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text('Resend confirmation mail'),
                  ),
                ],
              ),
            ),
            // Close (X) icon on the top-right corner
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Close the dialog
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}



  // Sign up function
  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        // Check if username already exists
        bool usernameExists = await checkIfUsernameExists(_usernameController.text.trim());
        if (usernameExists) {
          throw FirebaseAuthException(code: 'username-already-in-use');
        }

        // Check if email already exists
        bool emailExists = await checkIfEmailExists(_emailController.text.trim());
        if (emailExists) {
          throw FirebaseAuthException(code: 'email-already-in-use');
        }

        // Sign up the user using Firebase Auth
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Send email verification
        await userCredential.user!.sendEmailVerification();
        // Show a dialog to inform the user to verify their email
         showEmailConfirmationDialog(context, _emailController.text.trim());
       
        // Periodically check if the email is verified
        bool isVerified = false;
         while (!isVerified) {
           await Future.delayed(Duration(seconds: 5)); // Wait 5 seconds between checks
          await _auth.currentUser!.reload();
          isVerified = _auth.currentUser!.emailVerified;

          if (isVerified) {
             // Add user data to Firestore "reader" collection
        await _firestore.collection('reader').doc(userCredential.user!.uid).set({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'uid': userCredential.user!.uid,
           'name': _nameController.text.trim(),
         'bio': _bioController.text.trim(),
        'books': _booksController.text.trim(),
          'createdAt': Timestamp.now(),
          });
         // Direct the user to the login page after successful verification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email verified! Please log in.")),
      );
      Navigator.pushReplacementNamed(context, '/LoginPage');  // Assuming '/login' is your login route

       
         }};

        
         

        // Show a message to inform the user to verify their email
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("A verification email has been sent to ${_emailController.text.trim()}. Please verify your email before logging in.")),
        );

        // Poll to check if the email is verified, and prevent profile setup navigation until verified
        _auth.currentUser!.reload();
        if (_auth.currentUser!.emailVerified) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileSetup(userId: userCredential.user!.uid),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Please verify your email to continue.")),
          );
        }
      } on FirebaseAuthException catch (e) {
        // Handle Firebase Auth errors
        String message = 'An error occurred';
        if (e.code == 'username-already-in-use') {
          message = 'Username is already in use';
        } else if (e.code == 'email-already-in-use') {
          message = 'Email is already in use';
        } else if (e.code == 'weak-password') {
          message = 'Password is too weak';
        } else if (e.code == 'invalid-email') {
          message = 'Invalid email address';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        // Handle any other errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3),
      body: Center(
         child: SingleChildScrollView( 
        child: ConstrainedBox(
          constraints:
              BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                Stack(
                children: [
                 // Back arrow button positioned at the top left
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      iconSize: 40,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WelcomePage(),
                          ),
                        );
                      },
                    ),
                  ),

                
                ],
              ),
              const SizedBox(height: 100),
               ProfilePhotoWidget(
              onImagePicked: (File imageFile) {
                setState(() {
                  _imageFile = imageFile;
                });
              },
            ),
              const SizedBox(height: 20),
 // Introductory text at the bottom of the image
                  const Positioned(
                    bottom: 10, // Position the text 10 pixels from the bottom
                    left: 0,
                    right: 0,
                    child: Text(
                      "Explore, discuss, and enjoy books with a \ncommunity of passionate readers.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Color(0XFF695555),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 22.08 / 16,
                      ),
                    ),
                  ),

              

              const SizedBox(height: 20),

              // Form fields
              Container(
                width: 410,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                 
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
 const SizedBox(height: 40),
                    // Name
                          TextFormField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            autovalidateMode: AutovalidateMode.always,
                        validator: (value) {
    if (value == null || value.isEmpty) {
      return "*"; // Name is required
    }
    if (value.trim().isEmpty) {
      return "Name cannot contain only spaces";
    }
    if (value.startsWith(' ')) {
      return "Name cannot start with spaces";
    }
    return null; // Input is valid
  },
                            maxLength: 50, // Set maximum length of name field
                            decoration: InputDecoration(
                              hintText: "Name",
                              
                              hintStyle: const TextStyle(
                                color: Color(0xFF695555),
                                fontWeight: FontWeight.w400,
                                fontSize: 20,
                              ),
                               filled: true, // Make sure the field is filled with the color
                               fillColor: Colors.white, 
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(40),
                                borderSide:
                                    const BorderSide(color: Color(0xFFF790AD)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(40),
                                borderSide:
                                    const BorderSide(color: Color(0xFFF790AD)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Color(0xFFF790AD)),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: const BorderSide(color: Color(0xFFF790AD)),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(color: Color(0xFFF790AD)),
    ),
                            ),
                          ),
 
                    const SizedBox(height: 20),
                       
                     // Username
                      TextFormField(
  controller: _usernameController,
  autovalidateMode: AutovalidateMode.always,
  validator: (value) {
    if (value!.isEmpty) {
      return "* ";
    }
    if (value.length < 3) {
      return "Username can't be less than 3 characters";
    }
    RegExp usernamePattern = RegExp(r'^[a-zA-Z0-9_.-]+$');
    if (!usernamePattern.hasMatch(value)) {
      return "characters like @, #, and spaces aren't allowed";
    }
    return null;
  },
  keyboardType: TextInputType.text,
  maxLength: 20,
  decoration: InputDecoration(
    hintText: "@Username",
    hintStyle: const TextStyle(
      color: Color(0xFF695555),
      fontWeight: FontWeight.w400,
      fontSize: 20,
    ),
    filled: true, // Make sure the field is filled with the color
    fillColor: Colors.white, // Set the background color of the field
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(color: Color(0xFFF790AD)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(color: Color(0xFFF790AD)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(color: Color(0xFFF790AD)),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(color: Color(0xFFF790AD)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(color: Color(0xFFF790AD)),
    ),
  ),
),
 const SizedBox(height: 20),

                       // Email
                      TextFormField(
                        controller: _emailController,
                        autovalidateMode: AutovalidateMode.always,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "* ";
                          }
                          if (value.length > 254) {
                            return "Email can't exceed 254 characters";
                          }
                          // Regular expression to match both regular email and university email format
  if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value) &&
      !RegExp(r'^[0-9]+@student\.[a-zA-Z]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
    return "Enter a valid email address";
  }
                          
                          return null;
                        },
                        maxLength: 254,
                        decoration: InputDecoration(
                          hintText: "Email",
                          hintStyle: const TextStyle(
                            color: Color(0xFF695555),
                            fontWeight: FontWeight.w400,
                            fontSize: 20,
                          ),
                          filled: true, // Make sure the field is filled with the color
                          fillColor: Colors.white, // Set the background color of the field
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                            borderSide: const BorderSide(color: Color(0xFFF790AD)),
                          ),
                          focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(color: Color(0xFFF790AD)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(color: Color(0xFFF790AD)),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(color: Color(0xFFF790AD)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(color: Color(0xFFF790AD)),
    ),
                        ),
                      ),

                      const SizedBox(height: 20),
  // Password
                      TextFormField(
  controller: _passwordController,
  autovalidateMode: AutovalidateMode.always,
  keyboardType: TextInputType.text,
  obscureText: _obscurePassword,
  validator: (value) {
    if (value!.isEmpty) {
      return "* ";
    }
    if (value.length < 8) {
      return "Password must be at least 8 characters long";
    }
    if (!RegExp(r'^(?=.*[A-Z])').hasMatch(value)) {
      return "Password must contain at least one uppercase letter";
    }
    if (!RegExp(r'^(?=.*[a-z])').hasMatch(value)) {
      return "Password must contain at least one lowercase letter";
    }
    if (!RegExp(r'^(?=.*\d)').hasMatch(value)) {
      return "Password must contain at least one number";
    }
    if (!RegExp(r'^(?=.*[!@#\$%^&*])').hasMatch(value)) {
      return "Password must contain at least one special character";
    }
    if (value.length > 16) {
      return "Password can't exceed 16 characters";
    }
    if (value.contains(' ')) {
      return "Password cannot contain spaces";
    }
    return null;
  },


                        maxLength: 16,
                        decoration: InputDecoration(
                          hintText: "Password",
                          hintStyle: const TextStyle(
                            color: Color(0xFF695555),
                            fontWeight: FontWeight.w400,
                            fontSize: 20, 
                          ),
                         
                          filled: true, // Make sure the field is filled with the color
                          fillColor: Colors.white, // Set the background color of the field
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                            borderSide: const BorderSide(color: Color(0xFFF790AD)),
                          ),
                          focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(color: Color(0xFFF790AD)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(color: Color(0xFFF790AD)),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(color: Color(0xFFF790AD)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(color: Color(0xFFF790AD)),
    ),
     suffixIcon: IconButton(
    icon: Icon(
     _obscurePassword ? Icons.visibility_off : Icons.visibility,
      color: const Color(0xFFF790AD),
    ),
    onPressed: () {
    setState(() {
    _obscurePassword = !_obscurePassword;
     });
    }
     ),
                        ),
                      ),

                      const SizedBox(height: 20),


                       // Confirm password
                      TextFormField(
                        controller: _confirmPasswordController,
                        autovalidateMode: AutovalidateMode.always,
                        keyboardType: TextInputType.text,
                        maxLength: 16,
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "* ";
                          }
                          if (value != _passwordController.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Confirm Password",
                          hintStyle: const TextStyle(
                            color: Color(0xFF695555),
                            fontWeight: FontWeight.w400,
                            fontSize: 20,
                          ),
                          filled: true, // Make sure the field is filled with the color
                          fillColor: Colors.white, // Set the background color of the field
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                            borderSide: const BorderSide(color: Color(0xFFF790AD)),
                          ),
                          focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(color: Color(0xFFF790AD)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(color: Color(0xFFF790AD)),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(color: Color(0xFFF790AD)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(color: Color(0xFFF790AD)),
    ),
     suffixIcon: IconButton(
    icon: Icon(
      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
      color: const Color(0xFFF790AD),
    ),
    onPressed: () {
    setState(() {
     _obscureConfirmPassword = !_obscureConfirmPassword;
     });
    }
     ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Bio
                    TextFormField(
                      controller: _bioController,
                      keyboardType: TextInputType.text,
                      maxLines: 4,
                      maxLength: 152,
                      decoration: InputDecoration(
                        hintText: "Bio",
                        hintStyle: const TextStyle(
                          color: Color(0xFF695555),
                          fontSize: 20,
                        ), filled: true, // Make sure the field is filled with the color
                               fillColor: Colors.white, 
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide: const BorderSide(color: Color(0xFFF790AD)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide: const BorderSide(color: Color(0xFFF790AD)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFFF790AD)),
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                    ),


                     const SizedBox(height: 20),
 
                   
// Books number input field
TextFormField(
  controller: _booksController,
  keyboardType: TextInputType.number,
   inputFormatters: [FilteringTextInputFormatter.digitsOnly], // This ensures only numbers are allowed
  decoration: InputDecoration(
    hintText: "How many books do you want to read in this year?",
    hintStyle: const TextStyle(
      color: Color(0xFF695555),
      fontWeight: FontWeight.w400,
      fontSize: 15,
    ), filled: true, // Make sure the field is filled with the color
                               fillColor: Colors.white, 
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(color: Color(0xFFF790AD)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(color: Color(0xFFF790AD)),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFF790AD)),
      borderRadius: BorderRadius.circular(40),
    ),
  ),
),
 
                    const SizedBox(height: 20),


                                           // Sign up button
                      isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: 410,
                              child: MaterialButton(
                                color: const Color(0xFFF790AD),
                                textColor: const Color(0xFFFFFFFF),
                                height: 50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                onPressed: _signUp,
                                child: const Text("Sign up"),
                              ),
                            ),

                      const SizedBox(height: 20),

                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Footer with terms and conditions link
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text.rich(
                    TextSpan(
                      text: "By signing up, you agree to our ",
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: Color(0xFF695555),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: 'terms & conditions',
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            fontFamily: 'Roboto',
                            color: Color(0xFF695555),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          recognizer: TapGestureRecognizer()..onTap = () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
               const SizedBox(height: 20),
               // Already have an account? Login
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: "Already have an account? ",
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                color: Color(0XFF695555),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: "Login",
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                color: Color(0xFFF790AD),
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
class ProfilePhotoWidget extends StatefulWidget {
  final Function(File) onImagePicked;
  const ProfilePhotoWidget({super.key, required this.onImagePicked});
 
  @override
  _ProfilePhotoWidgetState createState() => _ProfilePhotoWidgetState();
}
 
class _ProfilePhotoWidgetState extends State<ProfilePhotoWidget> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
 
  // Function to pick image from gallery or camera
Future<void> _showImagePickerOptions(BuildContext context) async {
  showModalBottomSheet(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.only(bottom: 50.0), // Add padding for better look
      child: BottomSheet(
        onClosing: () {},
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Take a Photo'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    ),
  );
}


  // Function to pick an image
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        widget.onImagePicked(_imageFile!);
      });
      widget.onImagePicked(_imageFile!); // Notify parent widget
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Profile photo with thin border
CircleAvatar(
  radius: 64,
  backgroundImage: _imageFile != null
      ? FileImage(_imageFile!)
      : const AssetImage("assets/images/profile_pic.png") as ImageProvider,
  backgroundColor: const Color(0xFFF790AD),
  child: Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFFF790AD), width: 3),
    ),
  ),
),
 
        // Pencil icon for editing
        Positioned(
          bottom: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () => _showImagePickerOptions(context),
          ),
        ),
      ],
    );
  }
}
 
