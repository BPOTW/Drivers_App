class MockUser {
  final String id;
  final String name;
  final String email;
  final String role;
  String? assignedRouteId;
  double? lastLat;
  double? lastLng;

  MockUser({required this.id, required this.name, required this.email, required this.role, this.assignedRouteId, this.lastLat, this.lastLng});
}

class MockCheckpoint {
  final String id;
  final String name;
  final int expectedTimeMins;

  MockCheckpoint({required this.id, required this.name, required this.expectedTimeMins});
}

class MockRoute {
  final String id;
  final String name;
  final List<MockCheckpoint> checkpoints;

  MockRoute({required this.id, required this.name, required this.checkpoints});
}

class MockData {
  static List<MockUser> users = [
    MockUser(id: 'u1', name: 'Ali Khan', email: 'ali@example.com', role: 'driver', assignedRouteId: 'r1', lastLat: 33.6844, lastLng: 73.0479),
    MockUser(id: 'u2', name: 'Sara Ahmed', email: 'sara@example.com', role: 'driver', assignedRouteId: 'r1'),
    MockUser(id: 'admin1', name: 'Admin', email: 'admin@example.com', role: 'admin'),
  ];

  static List<MockRoute> routes = [
    MockRoute(id: 'r1', name: 'Islamabad to Lahore', checkpoints: [
      MockCheckpoint(id: 'c1', name: 'Warehouse', expectedTimeMins: 180),
      MockCheckpoint(id: 'c2', name: 'Checkpoint 1', expectedTimeMins: 120),
      MockCheckpoint(id: 'c3', name: 'Checkpoint 2', expectedTimeMins: 90),
    ])
  ];
}