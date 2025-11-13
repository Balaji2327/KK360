import 'package:flutter/material.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  bool rememberMe = false;
  bool isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: h * 0.14),

              // 🔹 Admin top image
              Image.asset("assets/images/login.png", height: h * 0.12),

              SizedBox(height: h * 0.02),

              // 🔹 Title
              const Text(
                "Log in as Admin",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: h * 0.006),

              const Text(
                "Welcome back! Select method to Log in",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),

              SizedBox(height: h * 0.02),

              // 🔹 Username Field
              TextField(
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  hintText: "Your username or email",
                  hintStyle: const TextStyle(fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),

              SizedBox(height: h * 0.015),

              // 🔹 Password Field
              TextField(
                obscureText: !isPasswordVisible,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  hintText: "Your password",
                  hintStyle: const TextStyle(fontSize: 14),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),

              SizedBox(height: h * 0.005),

              // 🔹 Remember Me
              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged: (val) {
                      setState(() {
                        rememberMe = val!;
                      });
                    },
                  ),
                  const Text("Remember Me", style: TextStyle(fontSize: 13)),
                ],
              ),

              SizedBox(height: h * 0.01),

              // 🔹 Login Button
              Container(
                width: w,
                height: h * 0.055,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(35),
                ),
                child: const Center(
                  child: Text(
                    "Log In",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: h * 0.015),

              // 🔹 Forget password & OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("Forget Password?", style: TextStyle(fontSize: 13)),
                  Text("Log in with OTP?", style: TextStyle(fontSize: 13)),
                ],
              ),

              SizedBox(height: h * 0.02),

              const Text("or", style: TextStyle(fontSize: 14)),

              SizedBox(height: h * 0.015),

              // 🔹 Google Login Button
              Container(
                width: w * 0.7,
                height: h * 0.055,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: Colors.black38),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("assets/images/google.png", height: h * 0.025),
                    SizedBox(width: w * 0.02),
                    const Text(
                      "Continue with Google",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // SizedBox(height: h * 0.02),

              // const Text("Are you a Tutor?", style: TextStyle(fontSize: 13)),
              // const SizedBox(height: 3),
              // Text(
              //   "Click here",
              //   style: TextStyle(
              //     color: Colors.green.shade600,
              //     fontSize: 14,
              //     fontWeight: FontWeight.w600,
              //   ),
              // ),

              // SizedBox(height: h * 0.03),
            ],
          ),
        ),
      ),
    );
  }
}
