import 'package:flutter/material.dart';
import 'package:refund_class/screen/add_lecture_screen.dart';
import 'package:refund_class/widget/lecture_list_widget.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ko'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20.0,
          ),
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.notoSansKrTextTheme(),
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddLectureScreen()));
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        backgroundColor: Colors.blue[50],
        label: Text(
          '강좌 추가하기',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
        ),
      ),
      body: Material(
        color: Colors.transparent,
        child: ListView(
          children: [
            sectionRow(),
            LectureListWidget(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

Container sectionRow() {
  return Container(
    color: Colors.blue[50],
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: const [
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                '강좌명',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                '반복 요일',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                '총 금액',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                '총 횟수',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                '남은 횟수',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                '단가',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                '환불 금액',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
