import 'package:flutter/material.dart';

class DocumentSection extends StatelessWidget {
  const DocumentSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5, // Placeholder for document count
              itemBuilder: (context, index) {
                return Container(
                  width: 100,
                  margin: EdgeInsets.only(right: 8),
                  color: Colors.grey[300],
                  child: Center(child: Text('Doc ${index + 1}')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
