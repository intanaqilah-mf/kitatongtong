final docs = snapshot.data!.docs;
docs.sort((a, b) {
int valueA = int.tryParse((a['value'] as String).replaceAll("RM ", "")) ?? 0;
int valueB = int.tryParse((b['value'] as String).replaceAll("RM ", "")) ?? 0;
if (valueA != valueB) return valueA.compareTo(valueB);
return a.reference.id.compareTo(b.reference.id); // fallback sort
});

return Column(
children: docs.asMap().entries.map((entry) {
final index = entry.key;
final doc = entry.value;
final pkg = doc.data() as Map<String, dynamic>;
final bannerUrl = pkg["bannerUrl"] ?? "";
final value = pkg["value"] ?? "RM 0";
final label = String.fromCharCode(65 + index); // A, B, C, ...

return Container(
margin: EdgeInsets.symmetric(vertical: 8),
padding: EdgeInsets.all(10),
decoration: BoxDecoration(
color: Colors.transparent,
border: Border.all(color: Colors.black),
borderRadius: BorderRadius.circular(10),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.center,
children: [
Text(
"Package $label:",
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
color: Color(0xFFA67C00),
),
textAlign: TextAlign.center,
),
SizedBox(height: 5),
if (pkg["items"] != null)
Column(
crossAxisAlignment: CrossAxisAlignment.center,
children: (pkg["items"] as List<dynamic>)
    .asMap()
    .entries
    .map((entry) {
final i = entry.key;
final item = entry.value as Map<String, dynamic>;
return Text(
"${i + 1}. ${item['name']} ${item['unit']}",
style: TextStyle(color: Colors.black),
textAlign: TextAlign.center,
);
}).toList(),
),
SizedBox(height: 10),
bannerUrl.isNotEmpty
? ClipRRect(
borderRadius: BorderRadius.circular(10),
child: Image.network(
bannerUrl,
height: 140,
width: double.infinity,
fit: BoxFit.cover,
),
)
    : Container(
height: 100,
color: Colors.grey[300],
child: Center(
child: Icon(Icons.image, color: Colors.grey),
),
),
SizedBox(height: 10),
Text(
"Value $value",
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
color: Colors.black,
),
),
],
),
);
}).toList(),
);
