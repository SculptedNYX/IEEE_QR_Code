import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ieee_qr_code/Pages/adminPage.dart';
import 'package:ieee_qr_code/Pages/userPage.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {


  TextEditingController emailController = new TextEditingController();
  //
  // TextEditingController usernameController = new TextEditingController();
  TextEditingController passwordController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(

      appBar: AppBar(
        elevation:5,
        backgroundColor: Colors.blue[900],
        leading: const Icon(
          Icons.person,
          color: Colors.white,
        ),
        centerTitle: true,
        title: Text("Login",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white
          ),
        ),
      ),


      body: Column(
        mainAxisAlignment: MainAxisAlignment.center ,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          //email input
          const Text("Email",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20
            )
            ,),


          SizedBox(height: 10,width:screenWidth),

          //Email Text form field
          SizedBox(
            width: 250,
            child: TextFormField(
              controller: emailController,
              decoration:const InputDecoration(
                border: OutlineInputBorder(borderRadius:BorderRadius.all(
                    Radius.circular(25)
                ),
                    borderSide:BorderSide(color: Colors.blueAccent
                        ,width: 2.0
                    )
                ),
              ),
            ),
          ),
          const SizedBox(height: 20,),


          //password
          const Text("Password",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20
              )
          ),
          const SizedBox(height: 10),


          //password text form field
          SizedBox(
            width: 250,
            child: TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration:const InputDecoration(
                border: OutlineInputBorder(borderRadius:BorderRadius.all(
                    Radius.circular(25)
                ),
                    borderSide:BorderSide(color: Colors.blueAccent
                        ,width: 2.0
                    )
                ),
              ),
            ),

          ),
          const SizedBox(height: 20,),


          SizedBox(
            width: 250,
            child: TextButton(
              style: TextButton.styleFrom(
                  fixedSize: const Size(double.maxFinite, 50),
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue.shade900,
                  textStyle:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  shape: (RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.blue.shade900)))),
              onPressed: () async {
                try {
                  String emailData = emailController.text;
                  String passwordData = passwordController.text;

                  var re = RegExp(r'@admin.com');
                  // var re2 = RegExp(r'@dev.com');

                  final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: emailData,
                    password: passwordData,
                  );

                  if(re.hasMatch(emailData)) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPage()),);
                  }
                  else {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const UserPage()),);
                  }
                }
                on FirebaseAuthException catch (e) {
                  if (e.code == 'weak-password') {
                    print('The password provided is too weak.');
                  } else if (e.code == 'email-already-in-use') {
                    print('The account already exists for that email.');
                  }
                  else {
                    if(context.mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid name or password")));}
                  }
                }
              }, child: Text("LOGIN"),
              
            )
          )

        ],
      ),
    );
  }
}
