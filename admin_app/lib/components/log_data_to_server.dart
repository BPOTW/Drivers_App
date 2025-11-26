import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> logEvent({
  required String event,
  required String message,
  String type = 'INFO',
  String? userId,
  Map<String, dynamic>? metadata,
}) async {
  final firestore = FirebaseFirestore.instance;
  final logRef = firestore.collection('server_events').doc();
try{
  await logRef.set({
    'is_deleted':false,
    'type': type,
    'event': event,
    'userId': userId ?? 'system',
    'message': message,
    'timestamp': FieldValue.serverTimestamp(),
    'metadata': metadata ?? {},
  });
  print('uploaded');
}catch(errr){
  print(errr);
}
}

// qarza 13000
// rent 8000
// ride 2000
// kharch 2000
// ticket 2000
// 1000
// salan 2500