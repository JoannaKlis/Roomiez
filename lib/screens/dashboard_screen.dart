import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/custom_text_field.dart';
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            floating: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      // Logo i Tytuł
                      const Center(
                        child: Column(
                          children: [
                            Icon(Icons.house, size: 80.0, color: textColor),
                            SizedBox(height: 10),
                            Text('ROOMIES',
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: textColor)),
                            SizedBox(height: 5),
                            Text('Hello! Let\'s get started',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor)),
                            SizedBox(height: 5),
                            Text('Manage your home in one place.',
                                style: TextStyle(
                                    fontSize: 14, color: lightTextColor)),
                            SizedBox(height: 40),
                          ],
                        ),
                      ),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 450),
                          child: Container(
                            decoration: BoxDecoration(
                              color: accentColor,
                              //border: Border.all(color: accentColor, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.house, size: 60, color: textColor),
                                    SizedBox(width: 15),
                                    Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Create a new place', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),),
                                        SizedBox(height: 5),
                                        Text('You will be an admin and invite others.', style: TextStyle(fontSize: 14, color: lightTextColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const CustomTextField(
                                        label: '',
                                        hint: 'Enter the name of your place',
                                      ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    //przejście na główną, nadanie admina
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                  child: const Text('Create'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 450),
                          child: Container(
                            decoration: BoxDecoration(
                              color: accentColor,
                              //border: Border.all(color: accentColor, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, //wyrównanie do lewej
                              children: [
                                const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.house, size: 60, color: textColor),
                                    SizedBox(width: 15),
                                    Expanded(child: 
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Join an existing place', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),),
                                        SizedBox(height: 5),
                                        Text('Use an invite code from the admin', style: TextStyle(fontSize: 14, color: lightTextColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const CustomTextField(
                                  label: '',
                                  hint: 'Enter an invite code',
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    //przejście na główną
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                  child: const Text('Join'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
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

