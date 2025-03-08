          Padding(
               padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 6.0),
             child: Row(
               children: [
                 SizedBox(
                   width: 160, // Increased width for Search field
                   height: 40, // Match height of dropdowns
                   child: TextField(
                     decoration: InputDecoration(
                      prefixIcon: ShaderMask(
                         shaderCallback: (Rect bounds) {
                           return LinearGradient(
                             begin: Alignment.topLeft,
                             end: Alignment.bottomRight,
                             stops: [0.16, 0.38, 0.58, 0.88],
                             colors: [
                               Color(0xFFF9F295),
                               Color(0xFFE0AA3E),
                               Color(0xFFF9F295),
                               Color(0xFFB88A44),
                             ],
                           ).createShader(bounds);
                         },
                         child: Icon(
                           Icons.search_rounded,
                           size: 25, // Adjust size to match dropdown icon size
                           color: Colors.white, // This will be overridden by ShaderMask
                         ),
                       ),
                       hintText: "Search Asnaf",
                       hintStyle: TextStyle(fontSize: 14), // Match dropdown text size
                       filled: true,
                       fillColor: Colors.white,
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                       contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                     ),
                     style: TextStyle(fontSize: 14), // Match dropdown text size
                     onChanged: (value) {
                       setState(() {}); // Triggers UI refresh on text change
                     },
                   ),
                 ),
                          SizedBox(width: 8), // Small gap between search and filter

                 // Filter Dropdown (Reduce width)
                 SizedBox(
                   width: 100, // Reduced width for Filter field
                   height: 40,
                   child: DropdownButtonFormField<String>(
                     value: selectedFilter,
                     decoration: InputDecoration(
                       filled: true,
                       fillColor: Colors.white,
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                       contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 2), // Reduced padding
                     ),
                     dropdownColor: Colors.black,
                     icon: Align(
                       alignment: Alignment.centerRight,
                       child: Icon(Icons.filter_list, color: Colors.black),
                     ),
                     style: TextStyle(color: Colors.black),
                     selectedItemBuilder: (BuildContext context) {
                       return ["All", "Pending", "Approved", "Rejected"]
                           .map<Widget>((String value) {
                         return Padding(
                           padding: EdgeInsets.only(left: 10),  // Add left padding to move text to the right
                           child: Center(
                             child: Text(value, style: TextStyle(color: Colors.black)),
                           ),
                         );
                       }).toList();
                     },
                     onChanged: (String? newValue) {
                       setState(() {
                         selectedFilter = newValue!;
                       });
                     },
                     items: ["All", "Pending", "Approved", "Rejected"]
                         .map<DropdownMenuItem<String>>((String value) {
                       return DropdownMenuItem<String>(
                         value: value,
                         child: Center(
                           child: Text(value, style: TextStyle(color: Colors.white)),
                         ),
                       );
                     }).toList(),
                   ),
                 ),
                          SizedBox(width: 8), // Small gap between filter and sort

                 // Sort Dropdown (Reduce width)
                 SizedBox(
                   width: 90, // Reduced width for Sort field
                   height: 40,
                   child: DropdownButtonFormField<String>(
                     value: selectedSort,
                     decoration: InputDecoration(
                       filled: true,
                       fillColor: Colors.white,
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                       contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 12), // Reduced padding
                     ),
                     dropdownColor: Colors.black,
                     icon: Align(
                       alignment: Alignment.centerRight,
                       child: Icon(Icons.sort, color: Colors.black),
                     ),
                     style: TextStyle(color: Colors.black),
                     selectedItemBuilder: (BuildContext context) {
                       return ["Date", "Name", "Status"].map<Widget>((String value) {
                         return Center(
                           child: Text(
                             value,
                             style: TextStyle(color: Colors.black),
                             textAlign: TextAlign.center,
                           ),
                         );
                       }).toList();
                     },
                     onChanged: (String? newValue) {
                       setState(() {
                         selectedSort = newValue!;
                       });
                     },
                     items: ["Date", "Name", "Status"]
                         .map<DropdownMenuItem<String>>((String value) {
                       return DropdownMenuItem<String>(
                         value: value,
                         child: Center(
                           child: Text(
                             value,
                             style: TextStyle(color: Colors.white),
                             textAlign: TextAlign.center,
                           ),
                         ),
                       );
                     }).toList(),
                   ),
                 ),
               ],
             ),
           ),
