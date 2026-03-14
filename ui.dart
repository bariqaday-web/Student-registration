import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: RoyalInterface()));

class RoyalInterface extends StatefulWidget {
  const RoyalInterface({super.key});
  @override
  State<RoyalInterface> createState() => _RoyalInterfaceState();
}

class _RoyalInterfaceState extends State<RoyalInterface> {
  int _currentIndex = 0;
  final TextEditingController _chatController = TextEditingController();
  List<dynamic> allLogs = [];
  List<dynamic> completedStudents = [];
  String currentEngineStatus = "المحرك مستعد...";
  String? lastErrorImg;
  Timer? _timer;

  final String baseUrl = "https://gkjcynn599-cbuad-app.hf.space";

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) => fetchData());
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_status"));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          allLogs = data['logs'] ?? [];
          completedStudents = data['completed_students'] ?? [];
          lastErrorImg = data['last_error_img'];
          currentEngineStatus = (data['queue'] != null && data['queue'].isNotEmpty) 
              ? data['queue'][0]['status'] 
              : "في انتظار بيانات جديدة...";
        });
      }
    } catch (e) {
      setState(() => currentEngineStatus = "خطأ في الاتصال بالسيرفر");
    }
  }

  Future<void> sendData(String txt) async {
    if (txt.isEmpty) return;
    try {
      await http.post(Uri.parse("$baseUrl/add_student"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"text": txt}));
      _chatController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ تم الإرسال للذكاء الاصطناعي")));
    } catch (e) { print(e); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("ROAYL SYSTEM", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        centerTitle: true, backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0.5,
      ),
      body: Directionality(textDirection: TextDirection.rtl, child: _pages()[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green[700],
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add_comment), label: 'إضافة'),
          BottomNavigationBarItem(icon: Icon(Icons.fact_check), label: 'الحجوزات'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_remote), label: 'التحكم'),
        ],
      ),
    );
  }

  List<Widget> _pages() => [_buildAdd(), _buildRecords(), _buildControl()];

  Widget _buildAdd() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 60, color: Colors.green),
          const SizedBox(height: 10),
          const Text("أدخل بيانات الطلاب بأي شكل (نص/دردشة)", style: TextStyle(color: Colors.grey)),
          const Spacer(),
          TextField(
            controller: _chatController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: "اكتب هنا... (الإيميل، الرمز، الطلبات)",
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => sendData(_chatController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], minimumSize: const Size(double.infinity, 50)),
            child: const Text("إرسال للسيرفر ", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildRecords() {
    return Column(
      children: [
        ListTile(
          title: const Text("تحميل التقرير النهائي (TXT)", style: TextStyle(fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.download, color: Colors.green),
          onTap: () => launchUrl(Uri.parse("$baseUrl/download_logs")),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: completedStudents.length,
            itemBuilder: (c, i) => Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(completedStudents[i]['email']),
                subtitle: Text(completedStudents[i]['date']),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControl() {
    bool alert = currentEngineStatus.contains("WAIT");
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(15), padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: alert ? Colors.red[50] : Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              Text(currentEngineStatus, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (lastErrorImg != null) TextButton(onPressed: _showImg, child: const Text("👁️ مشاهدة الشاشة الآن")),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: allLogs.length,
            itemBuilder: (c, i) => ListTile(
              title: Text(allLogs[i]['msg'], style: const TextStyle(fontSize: 12)),
              leading: Icon(Icons.circle, size: 10, color: allLogs[i]['type'] == 'success' ? Colors.green : Colors.grey),
            ),
          ),
        )
      ],
    );
  }

  void _showImg() {
    showDialog(context: context, builder: (c) => AlertDialog(
      content: Image.network("$baseUrl/get_error_img/$lastErrorImg"),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("إغلاق"))],
    ));
  }
}
