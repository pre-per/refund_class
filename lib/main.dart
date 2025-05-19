import 'package:flutter/material.dart';
import 'package:refund_class/provider/base_time_provider.dart';
import 'package:refund_class/provider/search_query_provider.dart';
import 'package:refund_class/screen/add_lecture_screen.dart';
import 'package:refund_class/widget/lecture_list_widget.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
    final baseDateTime = ref.watch(baseTimeProvider);

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
            const SizedBox(height: 10),
            _DateTimeSelector(ref: ref, dateTime: baseDateTime),
            const SizedBox(height: 10),
            _SearchBar(),
            const SizedBox(height: 10),
            _sectionRow(),
            LectureListWidget(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _DateTimeSelector extends StatelessWidget {
  final WidgetRef ref;
  final DateTime dateTime;

  const _DateTimeSelector({required this.ref, required this.dateTime});

  @override
  Widget build(BuildContext context) {
    final formatted = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Text('기준 날짜 및 시간: $formatted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.date_range),
              label: const Text('날짜 선택'),
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: dateTime,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  final updated = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    dateTime.hour,
                    dateTime.minute,
                  );
                  ref.read(baseTimeProvider.notifier).state = updated;
                }
              },
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.access_time),
              label: const Text('시간 선택'),
              onPressed: () async {
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(dateTime),
                );
                if (pickedTime != null) {
                  final updated = DateTime(
                    dateTime.year,
                    dateTime.month,
                    dateTime.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                  ref.read(baseTimeProvider.notifier).state = updated;
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.today),
          label: const Text('오늘로 돌아가기'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black,
          ),
          onPressed: () {
            ref.read(baseTimeProvider.notifier).state = DateTime.now();
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar({super.key});

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  String _input = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        decoration: InputDecoration(
          hintText: '강좌명 검색',
          hintStyle: TextStyle(
            fontSize: 17.0,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        onChanged: (value) {
          setState(() {
            _input = value;
          });
          ref.read(lectureSearchQueryProvider.notifier).state = value.trim();
        },
      ),
    );
  }
}



Container _sectionRow() {
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
            flex: 1,
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
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                '최종 환불 금액',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
