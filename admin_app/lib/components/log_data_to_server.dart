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
