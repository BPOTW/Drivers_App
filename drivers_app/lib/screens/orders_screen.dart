import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'current_order_screen.dart';
import '../models/route_model.dart';
import '../services/firebase_service.dart' show StorageService;

class OrdersScreen extends StatefulWidget {
	const OrdersScreen({super.key});

	@override
	State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
	late Future<List<DeliveryRoute>> _routesFuture;

	@override
	void initState() {
		super.initState();
		_routesFuture = _fetchAssignedRoutes();
	}

	Future<List<DeliveryRoute>> _fetchAssignedRoutes() async {
		final userId = await StorageService.getUserId();
		if (userId.isEmpty) return [];
		return FirebaseService.getRoutesAssignedToDriver(userId);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Open Orders'),
				backgroundColor: Colors.grey[900],
			),
			backgroundColor: Colors.grey[900],
			body: FutureBuilder<List<DeliveryRoute>>(
				future: _routesFuture,
				builder: (context, snapshot) {
					if (snapshot.connectionState == ConnectionState.waiting) {
						return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
					}

					if (snapshot.hasError) {
						return Center(child: Text('Error: ${snapshot.error}'));
					}

					final routes = snapshot.data ?? [];
					if (routes.isEmpty) {
						return const Center(
							child: Text(
								'No orders assigned to you.',
								style: TextStyle(color: Colors.white70),
							),
						);
					}

					return ListView.builder(
						padding: const EdgeInsets.all(16),
						itemCount: routes.length,
						itemBuilder: (context, index) {
							final r = routes[index];
							return Card(
								color: Colors.grey[850],
								margin: const EdgeInsets.symmetric(vertical: 8),
								child: ListTile(
									title: Text(r.name, style: const TextStyle(color: Colors.tealAccent)),
									subtitle: Text('Route ID: ${r.id}', style: const TextStyle(color: Colors.white70)),
									trailing: r.isCompleted ? const Icon(Icons.check_circle, color: Colors.greenAccent) : null,
									onTap: () {
										Navigator.push(
											context,
											MaterialPageRoute(
												builder: (_) => CurrentOrderScreen(routeId: r.id),
											),
										);
									},
								),
							);
						},
					);
				},
			),
		);
	}
}

