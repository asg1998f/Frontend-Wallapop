import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallapop Scraper',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),
      home: const SearchScreen(),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _products = [];

  Future<void> _search(String query) async {
    try {
      final url = Uri.parse('http://localhost:8000/api/search/$query');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Respuesta del backend: $data'); 
        setState(() {
          _products = List<Map<String, dynamic>>.from(data['products']);
        });
      } else {
        setState(() {
          _products = [
            {'title': 'Error: ${response.statusCode}', 'price': 0.0, 'image': '', 'location': ''},
          ];
        });
      }
    } catch (e) {
      setState(() {
        _products = [
          {'title': 'Error: $e', 'price': 0.0, 'image': '', 'location': ''},
        ];
      });
    }
  }
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se puede abrir el enlace')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir enlace: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/logo.jpg',
            fit: BoxFit.contain,
          ),
        ),
        title: const Text('Wallapop Scraper'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Busca un producto (ej. bicicleta)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  _search(_controller.text);
                }
              },
              child: const Text('Buscar'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _products.isEmpty
                  ? const Center(child: Text('Busca algo para ver productos'))
                  : ListView.builder(
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        print('Producto en ListView: $product'); 
                        String imageUrl = product['image'] ?? '';
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: InkWell(
                            onTap: () {
                              print('onTap activado para el producto: ${product['title']}'); 
                              if (product['link'] != null) {
                                print('Abriendo enlace: ${product['link']}'); 
                                _launchUrl(product['link']);
                              } else {
                                print('Enlace no disponible para el producto: ${product['title']}'); 
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No hay enlace disponible')),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  imageUrl.isNotEmpty
                                      ? Image.network(
                                          'http://localhost:8000/api/image/${imageUrl.replaceFirst("https://cdn.wallapop.com/", "")}',
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            print('Error loading image: $error');
                                            return const Icon(
                                              Icons.image_not_supported,
                                              size: 80,
                                              color: Colors.grey,
                                            );
                                          },
                                        )
                                      : const Icon(
                                          Icons.shopping_bag,
                                          size: 80,
                                          color: Colors.grey,
                                        ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['title'] ?? 'Sin título',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Precio: ${product['price']?.toString() ?? 'N/A'} EUR',
                                          style: const TextStyle(color: Colors.green),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          product['location'] ?? 'Ubicación desconocida',
                                          style: const TextStyle(color: Color.fromARGB(255, 4, 1, 1)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
