import '../models/cliente.dart';
import '../services/api_service.dart';
import 'package:flutter/material.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  _ClientesPageState createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  int? filtroSelecionado; // Alterado para ser o índice
  List<String> tiposClientes = [
    'Todos',
    'Tipo 1',
    'Tipo 2',
    'Tipo 3',
    'Tipo 4',
  ]; // A lista de tipos de cliente
  late Future<List<Cliente>> _clientesFuture;

  @override
  void initState() {
    super.initState();
    // Inicializa com todos os clientes
    _clientesFuture = ApiService.buscarClientes(
      filtro: null,
    ); // Filtro inicial com "Todos"
  }

  // Função para atualizar o Future ao mudar o filtro
  void _atualizarFiltro(int? novoFiltro) {
    setState(() {
      filtroSelecionado = novoFiltro;

      // Passa o índice do filtro para a API
      _clientesFuture = ApiService.buscarClientes(filtro: novoFiltro);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<int>(
              value: filtroSelecionado,
              hint: const Text('Filtrar'),
              onChanged: (int? novoFiltro) {
                _atualizarFiltro(
                  novoFiltro,
                ); // Atualiza o filtro com o índice selecionado
              },
              items:
                  tiposClientes.asMap().entries.map<DropdownMenuItem<int>>((
                    entry,
                  ) {
                    // 'entry.key' é o índice e 'entry.value' é o nome
                    return DropdownMenuItem<int>(
                      value: entry.key, // Aqui usamos o índice
                      child: Text(entry.value),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Cliente>>(
        future: _clientesFuture, // Usa o Future manualmente controlado
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum cliente encontrado'));
          } else {
            final clientes = snapshot.data!;
            return ListView.builder(
              itemCount: clientes.length,
              itemBuilder: (context, index) {
                final cliente = clientes[index];
                return ListTile(
                  title: Text(cliente.dsCliente ?? 'Nome não disponível'),
                  subtitle: Text(
                    'IP: ${cliente.dsIpCliente ?? 'IP não disponível'}',
                  ),
                  trailing: Text(
                    'Tipo: ${cliente.tipoCliente?.toString() ?? 'Tipo não disponível'}',
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

// import '../models/cliente.dart';
// import '../services/api_service.dart';
// import 'package:flutter/material.dart';

// class ClientesPage extends StatefulWidget {
//   const ClientesPage({super.key});

//   @override
//   _ClientesPageState createState() => _ClientesPageState();
// }

// class _ClientesPageState extends State<ClientesPage> {
//   String? filtroSelecionado;
//   List<String> tiposClientes = [
//     'Todos',
//     'Tipo 1',
//     'Tipo 2',
//     'Tipo 3',
//     'Tipo 4',
//   ]; // Ajuste conforme necessário

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Clientes'),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 16.0),
//             child: DropdownButton<String>(
//               value: filtroSelecionado,
//               hint: const Text('Filtrar'),
//               onChanged: (String? novoFiltro) {
//                 setState(() {
//                   filtroSelecionado = novoFiltro;
//                   print('Novo Filtro ${novoFiltro}');
//                 });
//               },
//               items:
//                   tiposClientes.map<DropdownMenuItem<String>>((String tipo) {
//                     return DropdownMenuItem<String>(
//                       value: tipo,
//                       child: Text(tipo),
//                     );
//                   }).toList(),
//             ),
//           ),
//         ],
//       ),
//       body: FutureBuilder<List<Cliente>>(
//         future: ApiService.buscarClientes(
//           filtro: filtroSelecionado,
//         ), // Passando o filtro para a API
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Erro: ${snapshot.error}'));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text('Nenhum cliente encontrado'));
//           } else {
//             final clientes = snapshot.data!;

//             return ListView.builder(
//               itemCount: clientes.length,
//               itemBuilder: (context, index) {
//                 final cliente = clientes[index];
//                 return ListTile(
//                   title: Text(cliente.dsCliente ?? 'Nome não disponível'),
//                   subtitle: Text(
//                     'IP: ${cliente.dsIpCliente ?? 'IP não disponível'}',
//                   ),
//                   trailing: Text(
//                     'Tipo: ${cliente.tipoCliente?.toString() ?? 'Tipo não disponível'}',
//                   ),
//                 );
//               },
//             );
//           }
//         },
//       ),
//     );
//   }
// }

// import '../models/cliente.dart';
// import '../services/api_service.dart';
// import 'package:flutter/material.dart';

// class ClientesPage extends StatelessWidget {
//   const ClientesPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Clientes')),
//       body: FutureBuilder<List<Cliente>>(
//         // future: buscarClientes(),
//         future: ApiService.buscarClientes(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Erro: ${snapshot.error}'));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text('Nenhum cliente encontrado'));
//           } else {
//             final clientes = snapshot.data!;
//             return ListView.builder(
//               itemCount: clientes.length,
//               itemBuilder: (context, index) {
//                 final cliente = clientes[index];
//                 return ListTile(
//                   title: Text(cliente.dsCliente ?? 'Nome não disponível'),
//                   subtitle: Text(
//                     'IP: ${cliente.dsIpCliente ?? 'IP não disponível'}',
//                   ),
//                   trailing: Text(
//                     'Tipo: ${cliente.tipoCliente?.toString() ?? 'Tipo não disponível'}',
//                   ),
//                 );
//               },
//             );
//           }
//         },
//       ),
//     );
//   }
// }
