import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cliente.dart';

class ApiService {
  // static const String baseUrl = 'http://10.0.2.2:27015'; // localhost no emulador Android

  // static const String baseUrl = 'http://localhost:27015';

  static const String baseUrl = 'http://WK-230:27015';

  static Future<List<Cliente>> buscarClientes({int? filtro}) async {
    // final url = Uri.parse('$baseUrl/api/clientes');

    // Criar a URL com base no filtro, se fornecido
    String url = '$baseUrl/api/clientes';
    // if ((filtro == null) && (filtro != 0)) {
    url =
        '$url?tipoCliente=${filtro ?? 0}'; // Supondo que a API aceita um parâmetro chamado 'filtro'
    // }
    print(url);

    // final response = await http.get(url);
    final response = await http.get(Uri.parse(url));

    // final String url = 'http://localhost:27015/api/clientes?tipoCliente=$tipoCliente';

    print(
      'Status Code: ${response.statusCode}',
    ); // Adiciona para verificar o código de status
    print(
      'Response Body: ${response.body}',
    ); // Adiciona para ver o corpo da resposta

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Cliente.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao buscar clientes');
    }
  }
}
