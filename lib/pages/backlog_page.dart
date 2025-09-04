import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'dart:io' as io;
import 'dart:io' show Platform; // Import específico para Platform
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Importe para formatar datas
import 'package:fl_chart/fl_chart.dart';
import 'package:gerencial/config.dart';
import 'package:gerencial/pages/LegendItem.dart';
import 'package:gerencial/pages/AtendimentoDataSource.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class BacklogScreen extends StatefulWidget {
  const BacklogScreen({super.key});

  @override
  _BacklogScreenState createState() => _BacklogScreenState();
}

class _BacklogScreenState extends State<BacklogScreen> {
  Timer? _timerAtualizacao;

  int? setorId;
  int? empresaId;
  int? clienteId;
  int? sistemaId;
  String status = 'Pendente';
  String classificacao = '';
  String usuario = '';
  String contato = '';
  String solicitacao = '';

  List<Map<String, dynamic>> setores = [];
  List<Map<String, dynamic>> sistemas = [];
  List<Map<String, dynamic>> empresas = [];
  List<Map<String, dynamic>> clientes = [];
  List<Map<String, dynamic>> resultados = [];

  late List<Map<String, String>> sortedData;

  bool isLoading = false;

  bool sortAscending = true;
  int? sortColumnIndex;

  String baseUrl = '';
  String baseUrlHttp = '';

  final statusMap = {
    'Não Informado': 'N',
    'Pendente': 'P',
    'Retorno': 'R',
    'Concluído': 'A',
    'Cancelado': 'C',
    'Chamado': 'O',
  };

  DateTime dataFim = DateTime.now();

  // Para subtrair 30 dias da data de início:
  DateTime dataInicio = DateTime.now();

  List<String> classificacoes = [];

  int paginaAtual = 1;
  int tamanhoPagina = 50;
  List<Map<String, dynamic>> todosResultados =
      []; // Armazena todos os resultados
  List<Map<String, dynamic>> resultadosExibidos =
      []; // Resultados exibidos na página atual

  bool exibirGraficoAtendimentosGeral =
      false; // Controla a exibição entre cards e gráfico
  bool exibirGraficoComparativoDias = false;
  bool exibirGraficoAtendimentosAndamento = false;
  bool exibirGraficoOSAndamento = false;

  bool exibirPesquisaCard = false;
  bool exibirPesquisaTable = true;

  List<PieChartSectionData> pieChartData = [];
  List<LegendItem> legendItems = []; // Nova lista para os itens da legenda
  List<BarChartGroupData> barChartData = [];

  // Variáveis de estado para o gráfico comparativo
  List<BarChartGroupData> comparativoBarChartData = [];
  List<LegendItem> comparativoLegendItems = [];

  // Variáveis de estado para o gráfico de barras por status
  List<BarChartGroupData> statusBarChartData = [];
  List<LegendItem> statusLegendItems = [];

  String descricaoGrafico = 'Atendimentos';

  final ScrollController horizontalController = ScrollController();

  late MaskedTextController _dataInicioController;
  late MaskedTextController _dataFimController;

  // Função para alternar entre a exibição de cards e gráfico
  void alternarExibicao(bool blnPesquisar) {
    setState(() {
      if (!blnPesquisar) {
        exibirGraficoAtendimentosGeral = false;
        exibirGraficoComparativoDias = false;
        exibirGraficoAtendimentosAndamento = false;
        exibirGraficoOSAndamento = false;
      }
    });
  }

  @override
  void dispose() {
    horizontalController.dispose();

    _timerAtualizacao?.cancel();

    super.dispose();
  }

  Future<void> buscarSetores() async {
    try {
      final url = Uri.parse('$baseUrl/api/setores');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          setores = List<Map<String, dynamic>>.from(json.decode(response.body));

          print(setores);
        });
      } else {
        print('Erro ao buscar setores: ${response.statusCode}');
        _mostrarMensagem('Erro ao buscar setores: ${response.statusCode}');
      }
    } catch (error) {
      print('Erro na requisição de setores: $error');
      _mostrarMensagem('Erro na requisição de setores: $error');
    }
  }

  Future<void> buscarSistemas(int setorId) async {
    try {
      print('$baseUrl/api/sistemas?idAtendimentoSetor=$setorId');

      final url = Uri.parse(
        '$baseUrl/api/sistemas?idAtendimentoSetor=$setorId',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          sistemas = List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );
        });
      } else {
        print('Erro ao buscar sistemas: ${response.statusCode}');
        _mostrarMensagem('Erro ao buscar sistemas: ${response.statusCode}');
      }
    } catch (error) {
      print('Erro na requisição de sistemas: $error');
      _mostrarMensagem('Erro na requisição de sistemas: $error');
    }
  }

  Future<void> buscarEmpresas() async {
    try {
      final url = Uri.parse('$baseUrl/api/empresas');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          empresas = List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );

          print(empresas);
        });
      } else {
        print('Erro ao buscar empresas: ${response.statusCode}');
        _mostrarMensagem('Erro ao buscar empresas: ${response.statusCode}');
      }
    } catch (error) {
      print('Erro na requisição de empresas: $error');
      _mostrarMensagem('Erro na requisição de empresas: $error');
    }
  }

  Future<void> buscarClientes() async {
    try {
      final url = Uri.parse('$baseUrl/api/clientes?tipoCliente=1');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          clientes = List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );

          print(clientes);
        });
      } else {
        print('Erro ao buscar clientes: ${response.statusCode}');
        _mostrarMensagem('Erro ao buscar clientes: ${response.statusCode}');
      }
    } catch (error) {
      print('Erro na requisição de clientes: $error');
      _mostrarMensagem('Erro na requisição de clientes: $error');
    }
  }

  Future<void> buscarClassificacao() async {
    try {
      final url = Uri.parse('$baseUrl/api/classificacao');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          classificacoes =
              [''] +
              data
                  .map((item) => item['ClassificacaoDescricao'].toString())
                  .toList();
        });
      } else {
        print('Erro ao buscar classificação: ${response.statusCode}');
        _mostrarMensagem(
          'Erro ao buscar classificação: ${response.statusCode}',
        );
      }
    } catch (error) {
      print('Erro na requisição de classificação: $error');
      _mostrarMensagem('Erro na requisição de classificação: $error');
    }
  }

  Future<void> pesquisar() async {
    setState(() {
      isLoading = true;
      paginaAtual = 1;
      todosResultados.clear();
      resultados.clear();
    });

    try {
      // Formata as datas para o formato "ano-mês-dia"
      String dataInicioFormatada =
          "${dataInicio.year}-${dataInicio.month.toString().padLeft(2, '0')}-${dataInicio.day.toString().padLeft(2, '0')}";
      String dataFimFormatada =
          "${dataFim.year}-${dataFim.month.toString().padLeft(2, '0')}-${dataFim.day.toString().padLeft(2, '0')}";

      final url = Uri.http(baseUrlHttp, '/api/pesquisa', {
        'idEmpresa': (empresaId ?? 0).toString(),
        'idAtendimentoSetor': (setorId ?? 0).toString(),
        'idAtendimentoStatus': statusMap[status] ?? '0',
        'idSistemaCodigo': (sistemaId ?? 0).toString(),
        'idAtendimentoConteudoTexto': solicitacao.isEmpty ? '0' : solicitacao,
        'idClassificacaoDescricao': classificacao.isEmpty ? '0' : classificacao,
        'idUsuario': usuario.isEmpty ? '0' : usuario,
        'idContato': contato.isEmpty ? '0' : contato,
        'idCliente': (clienteId ?? 0).toString(),
        'dtInicio': dataInicioFormatada,
        'dtFim': dataFimFormatada,
      });

      print('URL da pesquisa: $url');
      final response = await http.get(url);
      print('Resposta da pesquisa: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          todosResultados =
              data.map<Map<String, dynamic>>((item) {
                return {
                  ...item,

                  'AtendimentoDataHoraFormatado':
                      item['AtendimentoDataHoraFormatado']?.toString() ?? '',
                  'AtendimentoSequenciaFormatado':
                      item['AtendimentoSequencia']?.toString() ?? '',
                  'EmpresaRazaoSocialFormatado':
                      item['EmpresaRazaoSocial']?.toString() ?? '',
                  'ClienteRazaoSocialFormatado':
                      item['ClienteRazaoSocial']?.toString() ?? '',
                  'AtendimentoContatoDescricaoFormatado':
                      item['AtendimentoContatoDescricao']?.toString() ?? '',
                  'SistemaDescricaoFormatado':
                      item['SistemaDescricao']?.toString() ?? '',
                  'UsuarioDescricaoFormatado':
                      item['UsuarioDescricao']?.toString() ?? '',
                  'ClassificacaoDescricaoFormatado':
                      item['ClassificacaoDescricao']?.toString() ?? '',
                };
              }).toList();

          // Filtro Distinct por AtendimentoSequencia
          final sequenciasVistas = <dynamic>{};
          todosResultados =
              todosResultados.where((item) {
                final seq = item['AtendimentoSequencia'];
                if (sequenciasVistas.contains(seq)) {
                  return false;
                } else {
                  sequenciasVistas.add(seq);
                  return true;
                }
              }).toList();

          _atualizarPagina();
        } else {
          print('Erro: resposta da pesquisa não é uma lista');
          _mostrarMensagem('Erro: resposta da pesquisa não é uma lista');
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print('Erro na requisição de pesquisa: ${response.statusCode}');
        _mostrarMensagem(
          'Erro na requisição de pesquisa: ${response.statusCode}',
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print('Erro na requisição de pesquisa: $error');
      _mostrarMensagem('Erro na requisição de pesquisa: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _atualizarPagina() {
    final inicio = (paginaAtual - 1) * tamanhoPagina;
    final fim = inicio + tamanhoPagina;

    if (todosResultados.length <= 2000) {
      setState(() {
        resultados = List.from(todosResultados);
        isLoading = false;
        print('Carregando todos os resultados: ${resultados.length}');
      });
    } else {
      final inicio = (paginaAtual - 1) * tamanhoPagina;
      final fim = inicio + tamanhoPagina;
      setState(() {
        resultados = todosResultados.sublist(
          inicio,
          fim > todosResultados.length ? todosResultados.length : fim,
        );
        isLoading = false;
        print(
          'Carregando página $paginaAtual com ${resultados.length} resultados',
        );
      });
    }
  }

  void proximaPagina() {
    if (paginaAtual * tamanhoPagina < todosResultados.length) {
      setState(() {
        paginaAtual++;
      });
      _atualizarPagina();
    }
  }

  void paginaAnterior() {
    if (paginaAtual > 1) {
      setState(() {
        paginaAtual--;
      });
      _atualizarPagina();
    }
  }

  int get totalPaginas {
    return (todosResultados.length / tamanhoPagina).ceil();
  }

  // Função para definir a cor de cada status
  Color _getColor(String status) {
    switch (status) {
      case 'A':
        return Colors.green;
      case 'P':
        return Colors.orange;
      case 'R':
        return Colors.blue;
      case 'C':
        return Colors.red;
      case 'O':
        return Colors.purple;
      case 'Não Informado':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  Color _getColorOS(String status) {
    switch (status) {
      case 'Autorizado':
        return Colors.green;
      case 'Execução':
        return Colors.orange;
      case 'Compilado':
        return Colors.blue;
      case 'Não Conformidade':
        return Colors.red;
      case 'Especificação':
        return Colors.brown;
      case 'Teste':
        return Colors.purple;
      case 'Validado':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  // Andamento Geral
  Future<void> buscarAtendimentosGeralStatus() async {
    print("Função buscarTodosStatusParaGrafico chamada.");
    _resetGraficosData();

    // Formata as datas para o formato "ano-mês-dia"
    String dataInicioFormatada =
        "${dataInicio.year}-${dataInicio.month.toString().padLeft(2, '0')}-${dataInicio.day.toString().padLeft(2, '0')}";
    String dataFimFormatada =
        "${dataFim.year}-${dataFim.month.toString().padLeft(2, '0')}-${dataFim.day.toString().padLeft(2, '0')}";

    try {
      final url = Uri.http(baseUrlHttp, '/api/pesquisa', {
        'idEmpresa': (empresaId ?? 0).toString(),
        'idAtendimentoSetor': (setorId ?? 0).toString(),
        'idAtendimentoStatus': '0', // Passando 0 para pegar todos os status
        'idSistemaCodigo': (sistemaId ?? 0).toString(),
        'idAtendimentoConteudoTexto': solicitacao.isEmpty ? '0' : solicitacao,
        'idClassificacaoDescricao': classificacao.isEmpty ? '0' : classificacao,
        'idUsuario': usuario.isEmpty ? '0' : usuario,
        'idContato': contato.isEmpty ? '0' : contato,
        'idCliente': (clienteId ?? 0).toString(),
        'dtInicio': dataInicioFormatada, // Usa o nome do parâmetro do backend
        'dtFim': dataFimFormatada, // Usa o nome do parâmetro do backend
      });

      print("URL da requisição para gráfico: $url"); // Verificar a URL

      final response = await http.get(url);

      print(
        "Resposta da requisição para gráfico: ${response.body}",
      ); // Verificar o corpo da resposta

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          // Filtrar dados duplicados por AtendimentoSequencia
          final sequenciasVistas = <String>{};
          final dadosDistintos =
              data.where((item) {
                final sequencia =
                    item['AtendimentoSequencia']?.toString().trim();
                if (sequencia != null &&
                    !sequenciasVistas.contains(sequencia)) {
                  sequenciasVistas.add(sequencia);
                  return true;
                }
                return false;
              }).toList();

          // Contar a frequência de cada status
          final Map<String, int> statusCounts = {};
          for (final item in dadosDistintos) {
            final status =
                item['AtendimentoStatus']?.toString() ?? 'Não Informado';
            statusCounts[status] = (statusCounts[status] ?? 0) + 1;
          }

          final total = statusCounts.values.reduce((a, b) => a + b);
          legendItems.clear(); // Limpa a lista de legenda anterior
          pieChartData.clear(); // Limpa os dados do gráfico anteriores

          pieChartData =
              statusCounts.entries.map((entry) {
                String statusTexto;

                statusTexto = _getStatusText(entry.key.toUpperCase());

                final percentage = (entry.value / total * 100).toStringAsFixed(
                  1,
                );
                legendItems.add(
                  LegendItem(
                    color: _getColor(entry.key),
                    text:
                        '$statusTexto (${entry.value.toString()} - $percentage%)',
                  ),
                );

                return PieChartSectionData(
                  value: entry.value.toDouble(),
                  showTitle: false, // Não mostrar título dentro da pizza
                  radius: 150,
                  color: _getColor(entry.key),
                );
              }).toList();

          setState(() {
            exibirGraficoAtendimentosGeral = true;
            exibirGraficoComparativoDias = false;
            exibirGraficoAtendimentosAndamento = false;
            exibirGraficoOSAndamento = false;

            isLoading = false;
          });
        } else {
          print('Erro: resposta para gráfico não é uma lista');
          _mostrarMensagem('Erro: resposta para gráfico não é uma lista');
        }
      } else {
        print('Erro na requisição para gráfico: ${response.statusCode}');
        _mostrarMensagem(
          'Erro na requisição para gráfico: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erro na requisição para gráfico: $e'); // Captura erros de exceção
      // _mostrarMensagem('Erro: $e');

      setState(() {
        isLoading = false;
      });
    }
  }

  //O.S. em Andamento
  Future<void> buscarOSAndamentoStatus() async {
    print("Função buscarOSAndamentoStatus chamada.");
    _resetGraficosData();
    // Formata as datas para o formato "ano-mês-dia"
    String dataInicioFormatada =
        "${dataInicio.year}-${dataInicio.month.toString().padLeft(2, '0')}-${dataInicio.day.toString().padLeft(2, '0')}";
    String dataFimFormatada =
        "${dataFim.year}-${dataFim.month.toString().padLeft(2, '0')}-${dataFim.day.toString().padLeft(2, '0')}";

    try {
      final url = Uri.http(baseUrlHttp, '/api/ordemservico', {
        'idEmpresa': (empresaId ?? 0).toString(),
        'idAtendimentoSetor': (setorId ?? 0).toString(),
        'idSistemaCodigo': (sistemaId ?? 0).toString(),
        'idUsuario': usuario.isEmpty ? '0' : usuario,
        'dtInicio': dataInicioFormatada,
        'dtFim': dataFimFormatada,
      });

      print(
        "URL da requisição para OS Andamento Status: $url",
      ); // Verificar a URL

      final response = await http.get(url);

      print(
        "Resposta da requisição para OS Andamento Status: ${response.body}",
      ); // Verificar o corpo da resposta

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          // Contar a frequência de cada status
          final Map<String, int> statusCounts = {};
          for (final item in data) {
            final status =
                item['OrdemServicoItemStatusOrdemDescricao']?.toString() ??
                'Não Informado';
            statusCounts[status] = (statusCounts[status] ?? 0) + 1;
          }

          final total = statusCounts.values.reduce((a, b) => a + b);

          // Imprimir os resultados para verificação
          statusCounts.forEach((status, count) {
            final percentage = (count / total * 100).toStringAsFixed(1);
            print('$status: $count ($percentage%)');
          });

          legendItems.clear(); // Limpa a lista de legenda anterior
          pieChartData.clear(); // Limpa os dados do gráfico anteriores

          pieChartData =
              statusCounts.entries.map((entry) {
                String statusTexto;

                statusTexto = entry.key;

                final percentage = (entry.value / total * 100).toStringAsFixed(
                  1,
                );
                legendItems.add(
                  LegendItem(
                    color: _getColorOS(statusTexto),
                    text:
                        '$statusTexto (${entry.value.toString()} - $percentage%)',
                  ),
                );

                return PieChartSectionData(
                  value: entry.value.toDouble(),
                  showTitle: false, // Não mostrar título dentro da pizza
                  radius: 150,
                  color: _getColorOS(entry.key),
                );
              }).toList();

          setState(() {
            exibirGraficoAtendimentosGeral = false;
            exibirGraficoComparativoDias = false;
            exibirGraficoAtendimentosAndamento = false;
            exibirGraficoOSAndamento = true;

            isLoading = false;
          });
        } else {
          print('Erro: resposta para OS Andamento Status não é uma lista');
          _mostrarMensagem(
            'Erro: resposta para OS Andamento Status não é uma lista',
          );
        }
      } else {
        print(
          'Erro na requisição para OS Andamento Status: ${response.statusCode}',
        );
        _mostrarMensagem(
          'Erro na requisição para OS Andamento Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print(
        'Erro na requisição para OS Andamento Status: $e',
      ); // Captura erros de exceção
      // _mostrarMensagem('Erro: $e');

      setState(() {
        isLoading = false;
      });
    }
  }

  // Atendimento X Dias
  Future<void> buscarAtendimentosComparativoDias() async {
    print("Função buscarAtendimentosComparativoDias chamada.");
    _resetGraficosData();
    try {
      final DateTime dataFinal = dataFim;
      final periodos = {
        'Hoje': [dataFinal, dataFinal],
        'Últimos 2 Dias': [
          dataFinal.subtract(const Duration(days: 1)),
          dataFinal,
        ],
        'Últimos 10 Dias': [
          dataFinal.subtract(const Duration(days: 9)),
          dataFinal,
        ],
        'Últimos 30 Dias': [
          dataFinal.subtract(const Duration(days: 29)),
          dataFinal,
        ],
      };

      final Map<String, int> atendimentosPorPeriodo = {};
      final List<BarChartGroupData> barChartDataList = [];
      final List<LegendItem> legendItemsList = [];
      int barIndex = 0;
      int totalAtendimentosGeral = 0;

      for (final entry in periodos.entries) {
        final periodoNome = entry.key;
        final datas = entry.value;
        final dataInicioPeriodo = datas[0];
        final dataFimPeriodo = datas[1];

        final dataInicioFormatada =
            "${dataInicioPeriodo.year}-${dataInicioPeriodo.month.toString().padLeft(2, '0')}-${dataInicioPeriodo.day.toString().padLeft(2, '0')}";
        final dataFimFormatada =
            "${dataFimPeriodo.year}-${dataFimPeriodo.month.toString().padLeft(2, '0')}-${dataFimPeriodo.day.toString().padLeft(2, '0')}";

        final url = Uri.http(baseUrlHttp, '/api/pesquisa', {
          'idEmpresa': (empresaId ?? 0).toString(),
          'idAtendimentoSetor': (setorId ?? 0).toString(),
          'idAtendimentoStatus': 'P',
          'idSistemaCodigo': (sistemaId ?? 0).toString(),
          'idAtendimentoConteudoTexto': solicitacao.isEmpty ? '0' : solicitacao,
          'idClassificacaoDescricao':
              classificacao.isEmpty ? '0' : classificacao,
          'idUsuario': usuario.isEmpty ? '0' : usuario,
          'idContato': contato.isEmpty ? '0' : contato,
          'idCliente': (clienteId ?? 0).toString(),
          'dtInicio': dataInicioFormatada,
          'dtFim': dataFimFormatada,
        });

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as List;
          final sequenciasVistas = <String>{};
          final quantidadeAtendimentosPeriodo =
              data.where((item) {
                final sequencia =
                    item['AtendimentoSequencia']?.toString().trim();
                final status = item['AtendimentoStatus']?.toString().trim();
                if (sequencia != null &&
                    !sequenciasVistas.contains(sequencia)) {
                  sequenciasVistas.add(sequencia);
                  return status == 'P' ||
                      status == 'R' ||
                      status == null ||
                      status.isEmpty;
                }
                return false;
              }).length;
          atendimentosPorPeriodo[periodoNome] = quantidadeAtendimentosPeriodo;
          totalAtendimentosGeral += quantidadeAtendimentosPeriodo;
        } else {
          print('Erro na requisição para $periodoNome: ${response.statusCode}');
          _mostrarMensagem(
            'Erro ao buscar dados para $periodoNome: ${response.statusCode}',
          );
          atendimentosPorPeriodo[periodoNome] = 0;
        }
      }

      barIndex = 0;
      for (final entry in periodos.entries) {
        final periodoNome = entry.key;
        final quantidadeAtendimentos = atendimentosPorPeriodo[periodoNome] ?? 0;
        final percentage =
            totalAtendimentosGeral > 0
                ? (quantidadeAtendimentos / totalAtendimentosGeral * 100)
                    .toStringAsFixed(1)
                : '0.0';

        barChartDataList.add(
          BarChartGroupData(
            x: barIndex,
            barRods: [
              BarChartRodData(
                toY: quantidadeAtendimentos.toDouble(),
                color: _getColorPeriodo(periodoNome),
                width: 30,
              ),
            ],
          ),
        );

        legendItemsList.add(
          LegendItem(
            color: _getColorPeriodo(periodoNome),
            text: '$periodoNome ($quantidadeAtendimentos - $percentage%)',
          ),
        );

        barIndex++;
      }

      setState(() {
        comparativoBarChartData = barChartDataList;
        comparativoLegendItems = legendItemsList;
        exibirGraficoAtendimentosGeral = false;
        exibirGraficoComparativoDias = true;
        exibirGraficoAtendimentosAndamento = false;
        exibirGraficoOSAndamento = false;

        isLoading = false;
      });
    } catch (e) {
      print('Erro na função buscarAtendimentosComparativo: $e');
      // _mostrarMensagem('Erro ao buscar dados comparativos: $e');

      setState(() {
        isLoading = false;
      });
    }
  }

  // Atendimento em Andamento
  Future<void> buscarAtendimentosAndamentoStatus() async {
    print("Função buscarAtendimentosPorStatusParaGrafico chamada.");
    _resetGraficosData();
    // Formata as datas para o formato "ano-mês-dia"
    String dataInicioFormatada =
        "${dataInicio.year}-${dataInicio.month.toString().padLeft(2, '0')}-${dataInicio.day.toString().padLeft(2, '0')}";
    String dataFimFormatada =
        "${dataFim.year}-${dataFim.month.toString().padLeft(2, '0')}-${dataFim.day.toString().padLeft(2, '0')}";

    try {
      final url = Uri.http(baseUrlHttp, '/api/pesquisa', {
        'idEmpresa': (empresaId ?? 0).toString(),
        'idAtendimentoSetor': (setorId ?? 0).toString(),
        'idAtendimentoStatus': 'P', // Pegar todos os status para análise
        'idSistemaCodigo': (sistemaId ?? 0).toString(),
        'idAtendimentoConteudoTexto': solicitacao.isEmpty ? '0' : solicitacao,
        'idClassificacaoDescricao': classificacao.isEmpty ? '0' : classificacao,
        'idUsuario': usuario.isEmpty ? '0' : usuario,
        'idContato': contato.isEmpty ? '0' : contato,
        'idCliente': (clienteId ?? 0).toString(),
        'dtInicio': dataInicioFormatada,
        'dtFim': dataFimFormatada,
      });

      print("URL da requisição para gráfico de status: $url");

      final response = await http.get(url);

      // print("Resposta da requisição para gráfico de status: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final sequenciasVistas = <String>{};
        final List<dynamic> dadosDistintos =
            data.where((item) {
              final sequencia = item['AtendimentoSequencia']?.toString().trim();
              if (sequencia != null && !sequenciasVistas.contains(sequencia)) {
                sequenciasVistas.add(sequencia);
                return true;
              }
              return false;
            }).toList();

        final Map<String, int> statusCounts = {
          "P": 0,
          "R": 0,
          "Não Informado": 0,
        };

        for (final item in dadosDistintos) {
          print('teste ' + item['AtendimentoStatus']);
          String? status;
          // Ignora status nulo ou em branco

          print('fora ' + item['AtendimentoStatus']);
          if (item['SistemaDescricao']?.toString().toUpperCase() ==
                  'NÃO INFORMADO' &&
              item['AtendimentoStatus']?.toString().toUpperCase() == 'P') {
            status = 'Não Informado';
          } else {
            status = item['AtendimentoStatus']?.toString().trim();

            print('entrei ' + item['AtendimentoStatus']);
          }

          if (status == null || status.isEmpty) {
            continue;
          }

          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        }

        final totalAtendimentos = statusCounts.values.fold(
          0,
          (sum, count) => sum + count,
        );
        final List<BarChartGroupData> statusBarChartList = [];
        final List<LegendItem> statusLegendList = [];
        int barIndex = 0;

        print(status);

        statusCounts.forEach((status, quantidade) {
          final percentage = (totalAtendimentos > 0
                  ? (quantidade / totalAtendimentos * 100)
                  : 0)
              .toStringAsFixed(1);
          statusBarChartList.add(
            BarChartGroupData(
              x: barIndex++,
              barRods: [
                BarChartRodData(
                  toY: quantidade.toDouble(),
                  color: _getColor(status), // Função para obter cor por status
                  width: 30,
                ),
              ],
            ),
          );

          print(totalAtendimentos);
          print(quantidade);
          print(percentage);
          print(status);
          print(statusCounts.keys.toList());
          print(_getStatusText(status));

          statusLegendList.add(
            LegendItem(
              color: _getColor(status),
              text: '${_getStatusText(status)} ($quantidade - $percentage%)',
            ),
          );
        });

        setState(() {
          statusBarChartData = statusBarChartList;
          statusLegendItems = statusLegendList;

          exibirGraficoAtendimentosGeral = false;
          exibirGraficoComparativoDias = false;
          exibirGraficoAtendimentosAndamento = true;
          exibirGraficoOSAndamento = false;

          isLoading = false;
        });
      } else {
        print(
          'Erro na requisição para gráfico de status: ${response.statusCode}',
        );
        _mostrarMensagem(
          'Erro na requisição para gráfico de status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erro na função buscarAtendimentosPorStatusParaGrafico: $e');
      // _mostrarMensagem('Erro ao buscar dados para gráfico de status: $e');

      setState(() {
        isLoading = false;
      });
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  // Função para obter o texto completo do status
  String _getStatusText(String status) {
    switch (status) {
      case 'A':
        return 'Concluído';
      case 'P':
        return 'Pendente';
      case 'R':
        return 'Retorno';
      case 'C':
        return 'Cancelado';
      case 'O':
        return 'Chamado';
      case 'Não Informado':
        return 'Não Informado';
      default:
        return 'Vazio';
    }
  }

  Color _getColorPeriodo(String periodo) {
    switch (periodo) {
      case 'Hoje':
        return Colors.blue;
      case 'Últimos 2 Dias':
        return Colors.green;
      case 'Últimos 10 Dias':
        return Colors.orange;
      case 'Últimos 30 Dias':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getColorStatus(String status) {
    switch (status.toUpperCase()) {
      case 'A':
        return Colors.green;
      case 'P':
        return Colors.orange;
      case 'R':
        return Colors.blue;
      case 'C':
        return Colors.red;
      case 'O':
        return Colors.purple;
      case 'Não Informado':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  Future<void> initStateSincrono() async {
    await buscarEmpresas();
    await buscarSetores(); // Aguarda a conclusão de buscarSetores()
    await buscarClassificacao(); // Aguarda a conclusão de buscarClassificacao()
    await buscarClientes();
  }

  void _resetGraficosData() {
    isLoading = true;

    pieChartData.clear();
    legendItems.clear();
    barChartData.clear();
    comparativoBarChartData.clear();
    comparativoLegendItems.clear();
    statusBarChartData.clear();
    statusLegendItems.clear();
  }

  @override
  void initState() {
    super.initState();

    dataFim = DateTime.now();

    // Para subtrair 30 dias da data de início:
    dataInicio = dataFim.subtract(Duration(days: 30));
    baseUrl = getBaseUrl();
    baseUrlHttp = baseUrl.replaceAll("http://", "").replaceAll("https://", "");

    initStateSincrono(); // Chama a função síncrona

    _dataInicioController = MaskedTextController(
      mask: '00/00/0000',
      text:
          "${dataInicio.day.toString().padLeft(2, '0')}/${dataInicio.month.toString().padLeft(2, '0')}/${dataInicio.year}",
    );

    _dataFimController = MaskedTextController(
      mask: '00/00/0000',
      text:
          "${dataFim.day.toString().padLeft(2, '0')}/${dataFim.month.toString().padLeft(2, '0')}/${dataFim.year}",
    );

    _timerAtualizacao = Timer.periodic(Duration(minutes: 2), (Timer timer) {
      print("Timer em ação...");
      _atualizarTempoReal();
    });
  }

  Widget buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Scaffold(
          appBar: AppBar(
            title: Text(constraints.maxWidth < 600 ? '' : 'Gerencial.: 1.0.1'),
            actions: <Widget>[
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // Chama a função gerarCsv após obter e processar os resultados
                  gerarCsv(todosResultados);
                },
                child: const Icon(Icons.insert_drive_file),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  pesquisar();
                  alternarExibicao(false);
                  descricaoGrafico = 'Atendimentos';
                  setState(() {
                    exibirPesquisaCard = true;
                    exibirPesquisaTable = false;

                    exibirGraficoAtendimentosGeral = false;
                    exibirGraficoComparativoDias = false;
                    exibirGraficoAtendimentosAndamento = false;
                    exibirGraficoOSAndamento = false;
                  });
                },
                child: const Icon(Icons.description),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  pesquisar();
                  alternarExibicao(false);
                  descricaoGrafico = 'Atendimentos';
                  setState(() {
                    exibirPesquisaCard = false;
                    exibirPesquisaTable = true;

                    exibirGraficoAtendimentosGeral = false;
                    exibirGraficoComparativoDias = false;
                    exibirGraficoAtendimentosAndamento = false;
                    exibirGraficoOSAndamento = false;
                  });
                },
                child: const Icon(Icons.table_chart),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                offset: const Offset(0, 50),
                onSelected: (value) {
                  print('Gráfico selecionado: $value');

                  if (value == 'Atendimento Geral') {
                    buscarAtendimentosGeralStatus();
                    setState(() {
                      exibirGraficoAtendimentosGeral = true;
                      exibirGraficoComparativoDias = false;
                      exibirGraficoAtendimentosAndamento = false;
                      exibirGraficoOSAndamento = false;

                      exibirPesquisaCard = false;
                      exibirPesquisaTable = false;

                      descricaoGrafico = value;
                    });
                  } else if (value == 'O.S. em Andamento') {
                    buscarOSAndamentoStatus();
                    setState(() {
                      exibirGraficoAtendimentosGeral = false;
                      exibirGraficoComparativoDias = false;
                      exibirGraficoAtendimentosAndamento = false;
                      exibirGraficoOSAndamento = true;

                      exibirPesquisaCard = false;
                      exibirPesquisaTable = false;

                      descricaoGrafico = value;
                    });
                  } else if (value == 'Atendimento X Dias') {
                    buscarAtendimentosComparativoDias();
                    setState(() {
                      exibirGraficoAtendimentosGeral = false;
                      exibirGraficoComparativoDias = true;
                      exibirGraficoAtendimentosAndamento = false;
                      exibirGraficoOSAndamento = false;

                      exibirPesquisaCard = false;
                      exibirPesquisaTable = false;

                      descricaoGrafico = value;
                    });
                  } else if (value == 'Atendimento em Andamento') {
                    buscarAtendimentosAndamentoStatus();
                    setState(() {
                      exibirGraficoAtendimentosGeral = false;
                      exibirGraficoComparativoDias = false;
                      exibirGraficoAtendimentosAndamento = true;
                      exibirGraficoOSAndamento = false;

                      exibirPesquisaCard = false;
                      exibirPesquisaTable = false;

                      descricaoGrafico = value;
                    });
                  }
                },
                itemBuilder:
                    (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'Atendimento Geral',
                        child: Row(
                          children: [
                            Icon(Icons.pie_chart),
                            SizedBox(width: 8),
                            Text('Atendimento Geral'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'O.S. em Andamento',
                        child: Row(
                          children: [
                            Icon(Icons.pie_chart),
                            SizedBox(width: 8),
                            Text('O.S. em Andamento'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Atendimento X Dias',
                        child: Row(
                          children: [
                            Icon(Icons.bar_chart),
                            SizedBox(width: 8),
                            Text('Atendimento X Dias'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Atendimento em Andamento',
                        child: Row(
                          children: [
                            Icon(Icons.bar_chart),
                            SizedBox(width: 8),
                            Text('Atendimento em Andamento'),
                          ],
                        ),
                      ),
                    ],
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.analytics),
                    SizedBox(width: 8),
                    // Text('Gráficos'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 600;

              if (isMobile) {
                return _buildMobileLayout(); // Chama o layout para mobile
              } else {
                return _buildDesktopLayout(); // Chama o layout para desktop
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget _buildDesktopLayout() {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Alinhar os elementos à esquerda
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildEmpresaDropdown(constraints, isMobile),
                    ),

                    const SizedBox(width: 12),

                    Expanded(child: _buildSetorDropdown(constraints, isMobile)),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _buildSistemaDropdown(constraints, isMobile),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusDropdown(constraints, isMobile),
                    ),

                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildClienteDropdown(constraints, isMobile),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildClassificacaoDropdown(constraints, isMobile),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: _buildUsuarioTextField(isMobile: isMobile)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildContatoTextField(isMobile: isMobile)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSolicitacaoTextField(isMobile: isMobile),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: isMobile ? 120 : 200,
                      child: _buildDataInicioField(context),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: isMobile ? 120 : 200,
                      child: _buildDataFimField(context, isMobile),
                    ),
                    if (!isMobile) const Spacer(),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Expanded(child: buildResultado())],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget _buildMobileLayout() {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildEmpresaDropdown(constraints, isMobile),
                    _buildSetorDropdown(constraints, isMobile),
                    _buildSistemaDropdown(constraints, isMobile),
                    _buildStatusDropdown(constraints, isMobile),
                    _buildClienteDropdown(constraints, isMobile),
                    _buildClassificacaoDropdown(constraints, isMobile),
                    _buildUsuarioTextField(isMobile: isMobile),
                    _buildContatoTextField(isMobile: isMobile),
                    _buildSolicitacaoTextField(isMobile: isMobile),
                    _buildDataInicioField(context),
                    _buildDataFimField(context, isMobile), // Corrigido aqui
                    buildResultado(),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget buildResultado() {
    return LayoutBuilder(
      // body: LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;
        return SingleChildScrollView(
          child: Column(
            children: [
              // Align(
              //   alignment: Alignment.center,
              //   child: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       ElevatedButton(
              //         onPressed: () {
              //           pesquisar();
              //           alternarExibicao(false);
              //           descricaoGrafico = 'Atendimentos';

              //           exibirPesquisaCard = true;
              //           exibirPesquisaTable = false;
              //         },

              //         child: const Icon(Icons.description),
              //       ),
              //       const SizedBox(width: 8),

              //       ElevatedButton(
              //         onPressed: () {
              //           pesquisar();
              //           alternarExibicao(false);
              //           descricaoGrafico = 'Atendimentos';

              //           exibirPesquisaCard = false;
              //           exibirPesquisaTable = true;
              //         },

              //         child: const Icon(Icons.table_chart),
              //       ),
              //       const SizedBox(width: 8),

              //       PopupMenuButton<String>(
              //         offset: const Offset(
              //           0,
              //           30,
              //         ), // Opcional: Ajusta a posição do menu
              //         onSelected: (value) {
              //           print('Gráfico selecionado: $value');
              //           // Aqui você implementaria a lógica para exibir o gráfico selecionado
              //           if (value == 'Atendimento Geral') {
              //             buscarAtendimentosGeralStatus(); // Já está implementado para pizza
              //             setState(() {
              //               exibirGraficoAtendimentosGeral = true;
              //               exibirGraficoComparativoDias = false;
              //               exibirGraficoAtendimentosAndamento = false;
              //               exibirGraficoOSAndamento = false;

              //               descricaoGrafico = value;
              //             });
              //           } else if (value == 'O.S. em Andamento') {
              //             buscarOSAndamentoStatus();
              //             setState(() {
              //               exibirGraficoAtendimentosGeral = false;
              //               exibirGraficoComparativoDias = false;
              //               exibirGraficoAtendimentosAndamento = false;
              //               exibirGraficoOSAndamento = true;

              //               descricaoGrafico = value;
              //             });
              //           } else if (value == 'Atendimento X Dias') {
              //             // Implementar função para buscar dados e exibir gráfico de barra
              //             print("Entrei");
              //             buscarAtendimentosComparativoDias();
              //             setState(() {
              //               exibirGraficoAtendimentosGeral = false;
              //               exibirGraficoComparativoDias = true;
              //               exibirGraficoAtendimentosAndamento = false;
              //               exibirGraficoOSAndamento = false;

              //               descricaoGrafico = value;
              //             });
              //           } else if (value == 'Atendimento em Andamento') {
              //             // Implementar função para buscar dados e exibir gráfico de barra
              //             print("Entrei - Atendimento em Andamento");
              //             buscarAtendimentosAndamentoStatus();
              //             setState(() {
              //               exibirGraficoAtendimentosGeral = false;
              //               exibirGraficoComparativoDias = false;
              //               exibirGraficoAtendimentosAndamento = true;
              //               exibirGraficoOSAndamento = false;

              //               descricaoGrafico = value;
              //             });
              //           }
              //         },
              //         itemBuilder:
              //             (BuildContext context) => <PopupMenuEntry<String>>[
              //               const PopupMenuItem<String>(
              //                 value: 'Atendimento Geral',
              //                 child: Row(
              //                   children: [
              //                     Icon(Icons.pie_chart),
              //                     SizedBox(width: 8),
              //                     Text('Atendimento Geral'),
              //                   ],
              //                 ),
              //               ),
              //               const PopupMenuItem<String>(
              //                 value: 'O.S. em Andamento',
              //                 child: Row(
              //                   children: [
              //                     Icon(Icons.pie_chart),
              //                     SizedBox(width: 8),
              //                     Text('O.S. em Andamento'),
              //                   ],
              //                 ),
              //               ),
              //               const PopupMenuItem<String>(
              //                 value: 'Atendimento X Dias',
              //                 child: Row(
              //                   children: [
              //                     Icon(Icons.bar_chart),
              //                     SizedBox(width: 8),
              //                     Text('Atendimento X Dias'),
              //                   ],
              //                 ),
              //               ),
              //               const PopupMenuItem<String>(
              //                 value: 'Atendimento em Andamento',
              //                 child: Row(
              //                   children: [
              //                     Icon(Icons.bar_chart),
              //                     SizedBox(width: 8),
              //                     Text('Atendimento em Andamento'),
              //                   ],
              //                 ),
              //               ),
              //             ],
              //         // child: Row(
              //         //   // Este é o widget que será exibido como o botão
              //         //   mainAxisSize: MainAxisSize.min,
              //         //   children: const [
              //         //     // Icon(Icons.pie_chart),
              //         //     Icon(Icons.analytics),
              //         //     SizedBox(width: 8),
              //         //     Text('Gráficos'),
              //         //   ],
              //         // ),
              //       ),
              //       const SizedBox(width: 8),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    descricaoGrafico,
                    textAlign: TextAlign.center, // Pode manter isso aqui também
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (exibirGraficoAtendimentosGeral)
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                      children: [
                        SizedBox(
                          height: 400,
                          child:
                              pieChartData.isNotEmpty
                                  ? PieChart(
                                    PieChartData(
                                      sections: pieChartData,
                                      borderData: FlBorderData(show: false),
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 40,
                                    ),
                                  )
                                  : const Center(
                                    child: Text('Nenhum dado para o gráfico.'),
                                  ),
                        ),
                        const SizedBox(height: 60),
                        Wrap(
                          // Use Wrap para quebrar a legenda em várias linhas se necessário
                          spacing: 10,
                          runSpacing: 5,
                          children:
                              legendItems.map((item) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: item.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(item.text),
                                    const SizedBox(width: 15),
                                  ],
                                );
                              }).toList(),
                        ),
                      ],
                    )
              else if (exibirGraficoOSAndamento)
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                      children: [
                        SizedBox(
                          height: 400,
                          child:
                              pieChartData.isNotEmpty
                                  ? PieChart(
                                    PieChartData(
                                      sections: pieChartData,
                                      borderData: FlBorderData(show: false),
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 40,
                                    ),
                                  )
                                  : const Center(
                                    child: Text('Nenhum dado para o gráfico.'),
                                  ),
                        ),
                        const SizedBox(height: 60),
                        Wrap(
                          // Ou Column, dependendo do layout desejado
                          spacing:
                              8, // Espaçamento horizontal entre os itens da legenda
                          runSpacing:
                              4, // Espaçamento vertical entre as linhas da legenda
                          children:
                              legendItems.map((item) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: item.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Text(item.text),
                                    SizedBox(width: 8),
                                  ],
                                );
                              }).toList(),
                        ),
                      ],
                    )
              else if (exibirGraficoAtendimentosAndamento)
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                      children: [
                        SizedBox(
                          height: 300,
                          child:
                              statusBarChartData.isNotEmpty
                                  ? BarChart(
                                    BarChartData(
                                      gridData: FlGridData(show: true),
                                      titlesData: FlTitlesData(
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (
                                              double value,
                                              TitleMeta meta,
                                            ) {
                                              final statusNomes = [
                                                'Pendente',
                                                'Retorno',
                                                'Não Informado',
                                              ];
                                              if (value.toInt() >= 0 &&
                                                  value.toInt() <
                                                      statusNomes.length) {
                                                return SideTitleWidget(
                                                  axisSide: meta.axisSide,
                                                  child: Text(
                                                    statusNomes[value.toInt()],
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                );
                                              }
                                              return const SizedBox();
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      barGroups: statusBarChartData,
                                    ),
                                  )
                                  : const Center(
                                    child: Text(
                                      'Nenhum dado para o gráfico status andamento.',
                                    ),
                                  ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 10,
                          runSpacing: 5,
                          children:
                              statusLegendItems.map((item) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: item.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(item.text),
                                    const SizedBox(width: 15),
                                  ],
                                );
                              }).toList(),
                        ),
                      ],
                    )
              else if (exibirGraficoComparativoDias)
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                      children: [
                        SizedBox(
                          height: 300,
                          child:
                              comparativoBarChartData.isNotEmpty
                                  ? BarChart(
                                    BarChartData(
                                      gridData: FlGridData(show: true),
                                      titlesData: FlTitlesData(
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              final periodosNomes = [
                                                'Hoje',
                                                'Últimos 2 Dias',
                                                'Últimos 10 Dias',
                                                'Últimos 30 Dias',
                                              ];
                                              if (value.toInt() >= 0 &&
                                                  value.toInt() <
                                                      periodosNomes.length) {
                                                return SideTitleWidget(
                                                  axisSide: meta.axisSide,
                                                  child: Text(
                                                    periodosNomes[value
                                                        .toInt()],
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                );
                                              }
                                              return const SizedBox();
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      barGroups: comparativoBarChartData,
                                    ),
                                  )
                                  : const Center(
                                    child: Text(
                                      'Nenhum dado para o gráfico comparativo.',
                                    ),
                                  ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 10,
                          runSpacing: 5,
                          children:
                              comparativoLegendItems.map((item) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: item.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(item.text),
                                    const SizedBox(width: 15),
                                  ],
                                );
                              }).toList(),
                        ),
                      ],
                    )
              else if (exibirPesquisaTable)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final bool blnOcultar = constraints.maxWidth < 1600;
                    //     return isLoading
                    //         ? const Center(child: CircularProgressIndicator())
                    //         : resultados.isNotEmpty
                    //         ? SingleChildScrollView(
                    //           scrollDirection: Axis.vertical,
                    //           child: Scrollbar(
                    //             controller: horizontalController,
                    //             thumbVisibility: true,
                    //             child: SingleChildScrollView(
                    //               scrollDirection: Axis.horizontal,
                    //               controller: horizontalController,
                    //               child: ConstrainedBox(
                    //                 constraints:
                    //                     !blnOcultar
                    //                         ? const BoxConstraints(minWidth: 1400)
                    //                         : const BoxConstraints(minWidth: 500),

                    //                 child: DataTable(
                    //                   sortColumnIndex: sortColumnIndex,
                    //                   sortAscending: sortAscending,
                    //                   columnSpacing: 10,
                    //                   headingRowHeight: 40,
                    //                   dataRowHeight: 30,

                    //                   border:
                    //                       TableBorder.all(), // Adicione esta linha

                    //                   columns: [
                    //                     if (!blnOcultar)
                    //                       DataColumn(
                    //                         label: SizedBox(
                    //                           width: 100,
                    //                           child: Row(
                    //                             children: [
                    //                               const Text(
                    //                                 'Data',
                    //                                 style: TextStyle(fontSize: 14),
                    //                               ),
                    //                               if (sortColumnIndex == 0)
                    //                                 Icon(
                    //                                   sortAscending
                    //                                       ? Icons.arrow_downward
                    //                                       : Icons.arrow_upward,
                    //                                   size: 14,
                    //                                 ),
                    //                             ],
                    //                           ),
                    //                         ),
                    //                         onSort: (columnIndex, ascending) {
                    //                           _ordenarPorData(
                    //                             columnIndex,
                    //                             ascending,
                    //                           );
                    //                         },
                    //                       ),
                    //                     if (blnOcultar)
                    //                       DataColumn(
                    //                         label: SizedBox(
                    //                           width: 40,
                    //                           child: Row(
                    //                             children: [
                    //                               const Text(
                    //                                 'Data',
                    //                                 style: TextStyle(fontSize: 10),
                    //                               ),
                    //                               if (sortColumnIndex == 0)
                    //                                 Icon(
                    //                                   sortAscending
                    //                                       ? Icons.arrow_downward
                    //                                       : Icons.arrow_upward,
                    //                                   size: 14,
                    //                                 ),
                    //                             ],
                    //                           ),
                    //                         ),
                    //                         onSort: (columnIndex, ascending) {
                    //                           _ordenarPorData(
                    //                             columnIndex,
                    //                             ascending,
                    //                           );
                    //                         },
                    //                       ),
                    //                     if (!blnOcultar)
                    //                       const DataColumn(
                    //                         label: SizedBox(
                    //                           width: 80,
                    //                           child: Text(
                    //                             'Nº Atend.',
                    //                             style: TextStyle(fontSize: 14),
                    //                           ),
                    //                         ),
                    //                       ),
                    //                     if (blnOcultar)
                    //                       const DataColumn(
                    //                         label: SizedBox(
                    //                           width: 20,
                    //                           child: Text(
                    //                             'Nº',
                    //                             style: TextStyle(fontSize: 10),
                    //                           ),
                    //                         ),
                    //                       ),
                    //                     if (!blnOcultar)
                    //                       const DataColumn(
                    //                         label: SizedBox(
                    //                           width: 270,
                    //                           child: Text(
                    //                             'Empresa',
                    //                             style: TextStyle(fontSize: 14),
                    //                           ),
                    //                         ),
                    //                       ),
                    //                     if (blnOcultar)
                    //                       const DataColumn(
                    //                         label: SizedBox(
                    //                           width: 80,
                    //                           child: Text(
                    //                             'Empresa',
                    //                             style: TextStyle(fontSize: 10),
                    //                           ),
                    //                         ),
                    //                       ),
                    //                     if (!blnOcultar)
                    //                       const DataColumn(
                    //                         label: SizedBox(
                    //                           width: 350,
                    //                           child: Text(
                    //                             'Cliente',
                    //                             style: TextStyle(fontSize: 14),
                    //                           ),
                    //                         ),
                    //                       ),

                    //                     if (blnOcultar)
                    //                       const DataColumn(
                    //                         label: SizedBox(
                    //                           width: 280,
                    //                           child: Text(
                    //                             'Cliente',
                    //                             style: TextStyle(fontSize: 10),
                    //                           ),
                    //                         ),
                    //                       ),

                    //                     if (!blnOcultar)
                    //                       const DataColumn(
                    //                         label: SizedBox(
                    //                           width: 120,
                    //                           child: Text(
                    //                             'Contato',
                    //                             style: TextStyle(fontSize: 14),
                    //                           ),
                    //                         ),
                    //                       ),

                    //                     if (blnOcultar)
                    //                       const DataColumn(
                    //                         label: SizedBox(
                    //                           width: 70,
                    //                           child: Text(
                    //                             'Contato',
                    //                             style: TextStyle(fontSize: 10),
                    //                           ),
                    //                         ),
                    //                       ),

                    //                     if (!blnOcultar)
                    //                       const DataColumn(
                    //                         label: SizedBox(
                    //                           width: 120,
                    //                           child: Text(
                    //                             'Sistema',
                    //                             style: TextStyle(fontSize: 14),
                    //                           ),
                    //                         ),
                    //                       ),

                    //                     if (blnOcultar)
                    //                       const DataColumn(
                    //                         label: SizedBox(
                    //                           width: 70,
                    //                           child: Text(
                    //                             'Sistema',
                    //                             style: TextStyle(fontSize: 10),
                    //                           ),
                    //                         ),
                    //                       ),

                    //                     if (!blnOcultar)
                    //                       const DataColumn(
                    //                         label: SizedBox(
                    //                           width: 120,
                    //                           child: Text(
                    //                             'Usuário',
                    //                             style: TextStyle(fontSize: 14),
                    //                           ),
                    //                         ),
                    //                       ),

                    //                     if (blnOcultar)
                    //                       const DataColumn(
                    //                         label: SizedBox(
                    //                           width: 70,
                    //                           child: Text(
                    //                             'Usuário',
                    //                             style: TextStyle(fontSize: 10),
                    //                           ),
                    //                         ),
                    //                       ),
                    //                     if (!blnOcultar)
                    //                       const DataColumn(
                    //                         label: SizedBox(
                    //                           width: 140,
                    //                           child: Text(
                    //                             'Classificação',
                    //                             style: TextStyle(fontSize: 14),
                    //                           ),
                    //                         ),
                    //                       ),
                    //                   ],
                    //                   rows:
                    //                       resultados.map((item) {
                    //                         return DataRow(
                    //                           cells: [
                    //                             DataCell(
                    //                               Text(
                    //                                 item['AtendimentoDataHoraFormatado'] ??
                    //                                     '',
                    //                                 style: const TextStyle(
                    //                                   fontSize: 10,
                    //                                 ),
                    //                               ),
                    //                             ),

                    //                             DataCell(
                    //                               Text(
                    //                                 item['AtendimentoSequenciaFormatado'] ??
                    //                                     '',
                    //                                 style: const TextStyle(
                    //                                   fontSize: 10,
                    //                                 ),
                    //                               ),
                    //                             ),

                    //                             DataCell(
                    //                               Text(
                    //                                 item['EmpresaRazaoSocialFormatado'] ??
                    //                                     '',
                    //                                 style: const TextStyle(
                    //                                   fontSize: 10,
                    //                                 ),
                    //                               ),
                    //                             ),

                    //                             DataCell(
                    //                               Text(
                    //                                 item['ClienteRazaoSocialFormatado'] ??
                    //                                     '',
                    //                                 style: const TextStyle(
                    //                                   fontSize: 10,
                    //                                 ),
                    //                               ),
                    //                             ),
                    //                             DataCell(
                    //                               Text(
                    //                                 item['AtendimentoContatoDescricaoFormatado'] ??
                    //                                     '',
                    //                                 style: const TextStyle(
                    //                                   fontSize: 10,
                    //                                 ),
                    //                               ),
                    //                             ),
                    //                             DataCell(
                    //                               Text(
                    //                                 item['SistemaDescricaoFormatado'] ??
                    //                                     '',
                    //                                 style: const TextStyle(
                    //                                   fontSize: 10,
                    //                                 ),
                    //                               ),
                    //                             ),
                    //                             DataCell(
                    //                               Text(
                    //                                 item['UsuarioDescricaoFormatado'] ??
                    //                                     '',
                    //                                 style: const TextStyle(
                    //                                   fontSize: 10,
                    //                                 ),
                    //                               ),
                    //                             ),
                    //                             if (!blnOcultar)
                    //                               DataCell(
                    //                                 Text(
                    //                                   item['ClassificacaoDescricaoFormatado'] ??
                    //                                       '',
                    //                                   style: const TextStyle(
                    //                                     fontSize: 10,
                    //                                   ),
                    //                                 ),
                    //                               ),
                    //                           ],
                    //                         );
                    //                       }).toList(),
                    //                 ),
                    //               ),
                    //             ),
                    //           ),
                    //         )
                    //         : const Center(child: Text('Nenhum resultado'));
                    //   },
                    // )

                    return isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : resultados.isNotEmpty
                        ? SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Scrollbar(
                            controller: horizontalController,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              controller: horizontalController,
                              child: ConstrainedBox(
                                constraints:
                                    !blnOcultar
                                        ? const BoxConstraints(minWidth: 1400)
                                        : const BoxConstraints(minWidth: 400),
                                child: DataTable(
                                  sortColumnIndex: sortColumnIndex,
                                  sortAscending: sortAscending,
                                  columnSpacing: 10,
                                  headingRowHeight: 40,
                                  dataRowHeight: 30,
                                  border: TableBorder.all(),
                                  columns: [
                                    DataColumn(
                                      label: SizedBox(
                                        width: !blnOcultar ? 100 : 90,
                                        child: Row(
                                          children: [
                                            Text(
                                              'Data',
                                              style: TextStyle(
                                                fontSize: !blnOcultar ? 14 : 10,
                                              ),
                                            ),
                                            if (sortColumnIndex == 0)
                                              Icon(
                                                sortAscending
                                                    ? Icons.arrow_downward
                                                    : Icons.arrow_upward,
                                                size: 14,
                                              ),
                                          ],
                                        ),
                                      ),
                                      onSort: (columnIndex, ascending) {
                                        _ordenarPorData(columnIndex, ascending);
                                      },
                                    ),
                                    DataColumn(
                                      label: SizedBox(
                                        width: !blnOcultar ? 80 : 50,
                                        child: Text(
                                          !blnOcultar ? 'Nº Atend.' : 'Nº',
                                          style: TextStyle(
                                            fontSize: !blnOcultar ? 14 : 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: SizedBox(
                                        width: !blnOcultar ? 270 : 220,
                                        child: Text(
                                          'Empresa',
                                          style: TextStyle(
                                            fontSize: !blnOcultar ? 14 : 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: SizedBox(
                                        width: !blnOcultar ? 350 : 280,
                                        child: Text(
                                          'Cliente',
                                          style: TextStyle(
                                            fontSize: !blnOcultar ? 14 : 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: SizedBox(
                                        width: !blnOcultar ? 120 : 100,
                                        child: Text(
                                          'Contato',
                                          style: TextStyle(
                                            fontSize: !blnOcultar ? 14 : 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: SizedBox(
                                        width: !blnOcultar ? 120 : 100,
                                        child: Text(
                                          'Sistema',
                                          style: TextStyle(
                                            fontSize: !blnOcultar ? 14 : 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: SizedBox(
                                        width: !blnOcultar ? 120 : 100,
                                        child: Text(
                                          'Usuário',
                                          style: TextStyle(
                                            fontSize: !blnOcultar ? 14 : 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (!blnOcultar)
                                      const DataColumn(
                                        label: SizedBox(
                                          width: 140,
                                          child: Text(
                                            'Classificação',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ),
                                  ],
                                  rows:
                                      resultados.map((item) {
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Tooltip(
                                                message:
                                                    item['AtendimentoDataHoraFormatado'] ??
                                                    '',
                                                child: SizedBox(
                                                  width: !blnOcultar ? 100 : 90,
                                                  child: Text(
                                                    item['AtendimentoDataHoraFormatado'] ??
                                                        '',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Tooltip(
                                                message:
                                                    item['AtendimentoSequenciaFormatado'] ??
                                                    '',
                                                child: SizedBox(
                                                  width: !blnOcultar ? 80 : 50,
                                                  child: Text(
                                                    item['AtendimentoSequenciaFormatado'] ??
                                                        '',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Tooltip(
                                                message:
                                                    item['EmpresaRazaoSocialFormatado'] ??
                                                    '',
                                                child: SizedBox(
                                                  width:
                                                      !blnOcultar ? 270 : 220,
                                                  child: Text(
                                                    item['EmpresaRazaoSocialFormatado'] ??
                                                        '',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      // (item['EmpresaRazaoSocialFormatado'])
                                                      //             .length >
                                                      //         37
                                                      //     ? 8
                                                      //     : 10,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Tooltip(
                                                message:
                                                    item['ClienteRazaoSocialFormatado'] ??
                                                    '',
                                                child: SizedBox(
                                                  width:
                                                      !blnOcultar ? 350 : 280,
                                                  child: Text(
                                                    item['ClienteRazaoSocialFormatado'] ??
                                                        '',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      // (item['ClienteRazaoSocialFormatado'])
                                                      //             .length >
                                                      //         46
                                                      //     ? 8
                                                      //     : 10,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Tooltip(
                                                message:
                                                    item['AtendimentoContatoDescricaoFormatado'] ??
                                                    '',
                                                child: SizedBox(
                                                  width:
                                                      !blnOcultar ? 120 : 100,
                                                  child: Text(
                                                    item['AtendimentoContatoDescricaoFormatado'] ??
                                                        '',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      // (item['AtendimentoContatoDescricaoFormatado'])
                                                      //             .length >
                                                      //         14
                                                      //     ? 8
                                                      //     : 10,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Tooltip(
                                                message:
                                                    item['SistemaDescricaoFormatado'] ??
                                                    '',
                                                child: SizedBox(
                                                  width:
                                                      !blnOcultar ? 120 : 100,
                                                  child: Text(
                                                    item['SistemaDescricaoFormatado'] ??
                                                        '',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      // (item['SistemaDescricaoFormatado'])
                                                      //             .length >
                                                      //         14
                                                      //     ? 8
                                                      //     : 10,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Tooltip(
                                                message:
                                                    item['UsuarioDescricaoFormatado'] ??
                                                    '',
                                                child: SizedBox(
                                                  width:
                                                      !blnOcultar ? 120 : 100,
                                                  child: Text(
                                                    item['UsuarioDescricaoFormatado'] ??
                                                        '',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      // (item['UsuarioDescricaoFormatado'])
                                                      //             .length >
                                                      //         17
                                                      //     ? 8
                                                      //     : 10,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (!blnOcultar)
                                              DataCell(
                                                SizedBox(
                                                  width: 140,
                                                  child: Text(
                                                    item['ClassificacaoDescricaoFormatado'] ??
                                                        '',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      }).toList(),
                                ),
                              ),
                            ),
                          ),
                        )
                        : const Center(child: Text('Nenhum resultado'));
                  },
                )
              else
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : resultados.isNotEmpty
                    ? ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: resultados.length,
                      itemBuilder: (context, index) {
                        final item = resultados[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Data: ${item['AtendimentoDataHoraFormatado']}',
                                ),
                                Text(
                                  'Nº Atend.: ${item['AtendimentoSequenciaFormatado']}',
                                ),
                                Text(
                                  'Empresa: ${item['EmpresaRazaoSocialFormatado']}',
                                ),
                                Text(
                                  'Cliente: ${item['ClienteRazaoSocialFormatado']}',
                                ),
                                Text(
                                  'Contato: ${item['AtendimentoContatoDescricaoFormatado']}',
                                ),
                                Text(
                                  'Sistema: ${item['SistemaDescricaoFormatado']}',
                                ),
                                Text(
                                  'Usuário: ${item['UsuarioDescricaoFormatado']}',
                                ),
                                Text(
                                  'Classificação: ${item['ClassificacaoDescricaoFormatado'] ?? ''}',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                    : const Center(child: Text('Nenhum resultado')),

              Row(children: [const SizedBox(height: 20.0)]),

              // Botões de navegação/paginamento
              if (!exibirGraficoAtendimentosGeral &&
                  !exibirGraficoComparativoDias &&
                  !exibirGraficoAtendimentosAndamento &&
                  !exibirGraficoOSAndamento &&
                  resultados.isNotEmpty &&
                  todosResultados.length > 2000)
                // Row(children: [const SizedBox(height: 30.0)]),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: paginaAtual > 1 ? paginaAnterior : null,
                      child: Text(
                        constraints.maxWidth < 600
                            ? 'Pág. ant.'
                            : 'Página anterior',
                        style: TextStyle(
                          fontSize: constraints.maxWidth < 600 ? 12 : 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Página $paginaAtual de $totalPaginas   ',
                      style: TextStyle(
                        fontSize: constraints.maxWidth < 600 ? 12 : 16,
                      ),
                    ),

                    ElevatedButton(
                      onPressed:
                          (paginaAtual * tamanhoPagina) < todosResultados.length
                              ? proximaPagina
                              : null,
                      child: Text(
                        constraints.maxWidth < 600
                            ? 'Próx. pag.'
                            : 'Próxima página',
                        style: TextStyle(
                          fontSize: constraints.maxWidth < 600 ? 12 : 16,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClienteDropdown(BoxConstraints constraints, bool isMobile) {
    return buildDropdown<int>(
      label: 'Cliente',
      value: clienteId,
      items: [
        const DropdownMenuItem<int>(value: null, child: Text('Todos')),
        ...clientes.map<DropdownMenuItem<int>>((e) {
          final dynamic dsClienteValue = e['ds_Cliente'];
          String descricao = 'Descrição não disponível';
          if (dsClienteValue is String) {
            descricao = dsClienteValue;
          } else if (dsClienteValue is List && dsClienteValue.isNotEmpty) {
            descricao = dsClienteValue[0]; // Pega o primeiro item da lista
          }

          String textoTruncado = "";

          final estilo = TextStyle(fontSize: 12);

          final textoFinal = cortarTextoAteCaber(
            texto: descricao,
            maxWidth: constraints.maxWidth,
            estilo: estilo,
            isMobile: isMobile,
          );

          if (isMobile) {
            textoTruncado = textoFinal;
          } else {
            if (textoFinal.length > 20 && constraints.maxWidth < 1200) {
              textoTruncado = textoFinal.substring(0, 20);
            } else if (textoFinal.length > 30 &&
                constraints.maxWidth > 1200 &&
                constraints.maxWidth < 1400) {
              textoTruncado = textoFinal.substring(0, 30);
            } else {
              textoTruncado = descricao;
            }
          }

          return DropdownMenuItem<int>(
            value: e['cd_Cliente'],
            child: Tooltip(
              message: descricao,
              child: Text(
                textoTruncado.isEmpty ? '' : textoTruncado,
                style: const TextStyle(fontSize: 12.00),
              ),
            ),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          clienteId = value;

          _atualizarTempoReal();
        });
      },
      width: isMobile ? double.infinity : 1000,
    );
  }

  Widget _buildEmpresaDropdown(BoxConstraints constraints, bool isMobile) {
    return buildDropdown<int>(
      label: 'Empresa',
      value: empresaId,
      items: [
        const DropdownMenuItem<int>(value: null, child: Text('Todas')),
        ...empresas.map<DropdownMenuItem<int>>((e) {
          final descricao =
              e['EmpresaRazaoSocial'] ?? 'Descrição não disponível';

          String textoTruncado = "";

          final estilo = TextStyle(fontSize: 12);

          final textoFinal = cortarTextoAteCaber(
            texto: descricao,
            maxWidth: constraints.maxWidth,
            estilo: estilo,
            isMobile: isMobile,
          );

          if (isMobile) {
            textoTruncado = textoFinal;
          } else {
            if (textoFinal.length > 20 && constraints.maxWidth < 1200) {
              textoTruncado = textoFinal.substring(0, 20);
            } else if (textoFinal.length > 30 &&
                constraints.maxWidth > 1200 &&
                constraints.maxWidth < 1400) {
              textoTruncado = textoFinal.substring(0, 30);
            } else {
              textoTruncado = descricao;
            }
          }

          return DropdownMenuItem<int>(
            value: e['EmpresaId'],
            child: Tooltip(
              message: descricao,
              child: Text(
                textoTruncado.isEmpty ? '' : textoTruncado,
                style: const TextStyle(fontSize: 12.00),
              ),
            ),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          empresaId = value;

          _atualizarTempoReal();
        });
      },
      width: isMobile ? double.infinity : 1000,
    );
  }

  Widget _buildSetorDropdown(BoxConstraints constraints, bool isMobile) {
    return buildDropdown<int>(
      label: 'Setor',
      value: setorId,
      items:
          setores.map<DropdownMenuItem<int>>((e) {
            final descricao =
                e['AtendimentoSetorDescricao'] ?? 'Descrição não disponível';

            String textoTruncado = "";

            final estilo = TextStyle(fontSize: 12);

            final textoFinal = cortarTextoAteCaber(
              texto: descricao,
              maxWidth: constraints.maxWidth,
              estilo: estilo,
              isMobile: isMobile,
            );

            if (isMobile) {
              textoTruncado = textoFinal;
            } else {
              if (textoFinal.length > 20 && constraints.maxWidth < 1200) {
                textoTruncado = textoFinal.substring(0, 20);
              } else if (textoFinal.length > 30 &&
                  constraints.maxWidth > 1200 &&
                  constraints.maxWidth < 1400) {
                textoTruncado = textoFinal.substring(0, 30);
              } else {
                textoTruncado = descricao;
              }
            }

            return DropdownMenuItem<int>(
              value: e['AtendimentoSetorID'],
              child: Tooltip(
                message: descricao,
                child: Text(
                  textoTruncado.isEmpty ? '' : textoTruncado,
                  style: const TextStyle(fontSize: 12.0),
                ),
              ),
            );
          }).toList(),
      onChanged: (value) {
        setState(() {
          setorId = value;
          sistemaId = null;
        });
        if (value != null) {
          Future(() async {
            await buscarSistemas(value);

            _atualizarTempoReal();
          });
        }
      },
      width: isMobile ? double.infinity : 200, // <--- Parâmetro width aqui
    );
  }

  Widget _buildSistemaDropdown(BoxConstraints constraints, bool isMobile) {
    return buildDropdown<int>(
      label: 'Sistema',
      value: sistemaId,
      items: [
        const DropdownMenuItem<int>(value: null, child: Text('Todos')),
        ...sistemas.map<DropdownMenuItem<int>>((e) {
          final descricao = e['SistemaDescricao'] ?? 'Sistema';

          String textoTruncado = "";

          final estilo = TextStyle(fontSize: 12);

          final textoFinal = cortarTextoAteCaber(
            texto: descricao,
            maxWidth: constraints.maxWidth,
            estilo: estilo,
            isMobile: isMobile,
          );

          if (isMobile) {
            textoTruncado = textoFinal;
          } else {
            if (textoFinal.length > 20 && constraints.maxWidth < 1200) {
              textoTruncado = textoFinal.substring(0, 20);
            } else if (textoFinal.length > 30 &&
                constraints.maxWidth > 1200 &&
                constraints.maxWidth < 1400) {
              textoTruncado = textoFinal.substring(0, 30);
            } else {
              textoTruncado = descricao;
            }
          }

          return DropdownMenuItem<int>(
            value: e['SistemaCodigo'],
            child: Tooltip(
              message: descricao,
              child: Text(
                textoTruncado.isEmpty ? '' : textoTruncado,
                style: const TextStyle(fontSize: 12.0),
              ),
            ),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          sistemaId = value;

          _atualizarTempoReal();
        });
      },
      width: isMobile ? double.infinity : 200, // <--- Parâmetro width aqui
    );
  }

  Widget _buildStatusDropdown(BoxConstraints constraints, bool isMobile) {
    return buildDropdown<String>(
      label: 'Status',
      value: status,
      items:
          [
            'Não Informado',
            'Pendente',
            'Retorno',
            'Concluído',
            'Cancelado',
            'Chamado',
          ].map((e) {
            return DropdownMenuItem<String>(value: e, child: Text(e));
          }).toList(),
      onChanged: (value) {
        setState(() {
          status = value!;

          _atualizarTempoReal();
        });
      },
      width: isMobile ? double.infinity : 200, // <--- Parâmetro width aqui
    );
  }

  Widget _buildClassificacaoDropdown(
    BoxConstraints constraints,
    bool isMobile,
  ) {
    return buildDropdown<String>(
      label: 'Classificação',
      value: classificacao,
      items:
          classificacoes.map((e) {
            final descricao = e;

            String textoTruncado = "";

            final estilo = TextStyle(fontSize: 12);

            final textoFinal = cortarTextoAteCaber(
              texto: descricao,
              maxWidth: constraints.maxWidth,
              estilo: estilo,
              isMobile: isMobile,
            );

            if (isMobile) {
              textoTruncado = textoFinal;
            } else {
              if (textoFinal.length > 20 && constraints.maxWidth < 1200) {
                textoTruncado = textoFinal.substring(0, 20);
              } else if (textoFinal.length > 30 &&
                  constraints.maxWidth > 1200 &&
                  constraints.maxWidth < 1400) {
                textoTruncado = textoFinal.substring(0, 30);
              } else {
                textoTruncado = descricao;
              }
            }

            return DropdownMenuItem<String>(
              value: e,
              child: Tooltip(
                message: descricao,
                child: Tooltip(
                  // Envolve o Text com Tooltip
                  message: descricao, // Exibe a descrição completa no tooltip
                  child: Text(
                    textoTruncado.isEmpty ? '' : textoTruncado,
                    style: const TextStyle(fontSize: 12.0),
                  ),
                ),
              ),
            );
          }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            classificacao = value;

            _atualizarTempoReal();
          });
        }
      },
      width: isMobile ? double.infinity : 200, // <--- Parâmetro width aqui
    );
  }

  Widget _buildUsuarioTextField({required bool isMobile}) {
    final textField = TextField(
      decoration: const InputDecoration(
        labelText: 'Usuário',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() {
          usuario = value;

          _atualizarTempoReal();
        });
      },
    );

    return isMobile
        ? SizedBox(width: double.infinity, child: textField)
        : Expanded(child: textField);
  }

  Widget _buildContatoTextField({required bool isMobile}) {
    final textField = TextField(
      decoration: const InputDecoration(
        labelText: 'Contato',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() {
          contato = value;

          _atualizarTempoReal();
        });
      },
    );

    return isMobile
        ? SizedBox(width: double.infinity, child: textField)
        : Expanded(child: textField);
  }

  Widget _buildSolicitacaoTextField({required bool isMobile}) {
    final textField = TextField(
      decoration: const InputDecoration(
        labelText: 'Solicitação',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() {
          solicitacao = value;

          _atualizarTempoReal();
        });
      },
    );

    return isMobile
        ? SizedBox(width: double.infinity, child: textField)
        : Expanded(child: textField);
  }

  Widget _buildDataInicioField(BuildContext context) {
    return SizedBox(
      child: TextField(
        decoration: InputDecoration(
          labelText: 'Data Início',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: dataInicio,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  dataInicio = picked;
                  _dataInicioController.text =
                      "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                });
              }
            },
          ),
        ),
        controller: _dataInicioController,
        keyboardType: TextInputType.number,
        onChanged: (value) {
          final parts = value.split('/');
          if (parts.length == 3) {
            try {
              final parsedDate = DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
              setState(() {
                dataInicio = parsedDate;

                if (value.length == 10) {
                  _atualizarTempoReal();
                }
              });
            } catch (e) {
              // Data inválida, ignore ou trate como quiser
            }
          }
        },
      ),
    );
  }

  Widget _buildDataFimField(BuildContext context, bool isMobile) {
    return SizedBox(
      width: isMobile ? double.infinity : 200,
      child: TextField(
        decoration: InputDecoration(
          labelText: 'Data Fim',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: dataFim,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  dataFim = picked;
                  _dataFimController.text =
                      "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                });
              }
            },
          ),
        ),
        controller: _dataFimController,
        keyboardType: TextInputType.number,
        onChanged: (value) {
          final parts = value.split('/');
          if (parts.length == 3) {
            try {
              final parsedDate = DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
              setState(() {
                dataFim = parsedDate;

                if (value.length == 10) {
                  _atualizarTempoReal();
                }
              });
            } catch (e) {
              // Data inválida — trate se quiser
            }
          }
        },
      ),
    );
  }

  String cortarTextoAteCaber({
    required String texto,
    required double maxWidth,
    required TextStyle estilo,
    required bool isMobile,
  }) {
    double fatorAjuste =
        0.6; // Fator aproximado de ajuste (pode variar com o tipo de fonte)

    // Cálculo aproximado da largura do texto por caractere
    double larguraPorCaractere = estilo.fontSize! * fatorAjuste;

    // Número máximo de caracteres que cabem na largura disponível
    int maxChars = (maxWidth / larguraPorCaractere).floor() - 10;

    // Cortando o texto para caber dentro da largura
    String textoFinal =
        texto.length > maxChars ? '${texto.substring(0, maxChars)}...' : texto;

    return textoFinal;
  }

  void _ordenarPorData(int columnIndex, bool ascending) {
    final dateFormat = DateFormat('dd/MM/yyyy - HH:mm');
    setState(() {
      sortColumnIndex = columnIndex;
      sortAscending = ascending;

      resultados.sort((a, b) {
        try {
          final dateA = dateFormat.parse(
            a['AtendimentoDataHoraFormatado'] ?? '',
            true,
          );
          final dateB = dateFormat.parse(
            b['AtendimentoDataHoraFormatado'] ?? '',
            true,
          );
          return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });
    });
  }

  void _atualizarTempoReal() {
    if (exibirPesquisaCard) {
      pesquisar();
      setState(() {
        exibirGraficoAtendimentosGeral = false;
        exibirGraficoComparativoDias = false;
        exibirGraficoAtendimentosAndamento = false;
        exibirGraficoOSAndamento = false;

        exibirPesquisaCard = true;
        exibirPesquisaTable = false;
      });
    } else if (exibirPesquisaTable) {
      pesquisar();
      setState(() {
        exibirGraficoAtendimentosGeral = false;
        exibirGraficoComparativoDias = false;
        exibirGraficoAtendimentosAndamento = false;
        exibirGraficoOSAndamento = false;

        exibirPesquisaCard = false;
        exibirPesquisaTable = true;
      });
    } else if (exibirGraficoAtendimentosGeral) {
      buscarAtendimentosGeralStatus();
      setState(() {
        exibirGraficoAtendimentosGeral = true;
        exibirGraficoComparativoDias = false;
        exibirGraficoAtendimentosAndamento = false;
        exibirGraficoOSAndamento = false;

        exibirPesquisaCard = false;
        exibirPesquisaTable = false;
      });
    } else if (exibirGraficoOSAndamento) {
      buscarOSAndamentoStatus();
      setState(() {
        exibirGraficoAtendimentosGeral = false;
        exibirGraficoComparativoDias = false;
        exibirGraficoAtendimentosAndamento = false;
        exibirGraficoOSAndamento = true;

        exibirPesquisaCard = false;
        exibirPesquisaTable = false;
      });
    } else if (exibirGraficoComparativoDias) {
      buscarAtendimentosComparativoDias();
      setState(() {
        exibirGraficoAtendimentosGeral = false;
        exibirGraficoComparativoDias = true;
        exibirGraficoAtendimentosAndamento = false;
        exibirGraficoOSAndamento = false;

        exibirPesquisaCard = false;
        exibirPesquisaTable = false;
      });
    } else if (exibirGraficoAtendimentosAndamento) {
      buscarAtendimentosAndamentoStatus();
      setState(() {
        exibirGraficoAtendimentosGeral = false;
        exibirGraficoComparativoDias = false;
        exibirGraficoAtendimentosAndamento = true;
        exibirGraficoOSAndamento = false;

        exibirPesquisaCard = false;
        exibirPesquisaTable = false;
      });
    }
  }

  Future<void> gerarCsv(List<Map<String, dynamic>> data) async {
    print('Função gerarCsv chamada com ${data.length} itens.');
    if (data.isEmpty) {
      print('Não há dados para gerar o CSV.');
      _mostrarMensagem('Não há dados para gerar o CSV.');
      return;
    }

    // List<String> headers = data.first.keys.toList();
    // List<List<dynamic>> rows =
    //     data
    //         .map((item) => headers.map((header) => item[header]).toList())
    //         .toList();

    // List<String> headers = data.first.keys.toList();

    // Filtrando as colunas com chave vazia (sem nome)
    List<String> headers =
        data.first.keys
            .where((key) => key.isNotEmpty) // Remove colunas com chave vazia
            .toList();

    List<List<dynamic>> rows =
        data.map((item) {
          // Formatar a data do AtendimentoDataHora
          if (item['AtendimentoDataHora'] != null) {
            try {
              DateTime dataHora = DateTime.parse(item['AtendimentoDataHora']);
              String formattedDate = DateFormat(
                'yyyy-MM-dd HH:mm:ss',
              ).format(dataHora);
              item['AtendimentoDataHora'] = formattedDate;
            } catch (e) {
              print('Erro ao formatar a data: $e');
              item['AtendimentoDataHora'] = 'Data inválida';
            }
          }

          // Aplicar o "case when" para AtendimentoStatus
          if (item['AtendimentoStatus'] != null) {
            switch (item['AtendimentoStatus']) {
              case 'A':
                item['AtendimentoStatus'] = 'Concluido';
                break;
              case 'P':
                item['AtendimentoStatus'] = 'Pendente';
                break;
              case 'R':
                item['AtendimentoStatus'] = 'Retorno';
                break;
              case 'C':
                item['AtendimentoStatus'] = 'Cancelado';
                break;
              case 'O':
                item['AtendimentoStatus'] = 'Camado';
                break;
              default:
                item['AtendimentoStatus'] = 'Status desconhecido';
                break;
            }
          }

          // Retorna os dados formatados para cada linha
          return headers.map((header) => item[header]).toList();
        }).toList();
    String csv = [headers, ...rows].map((row) => row.join(';')).join('\n');
    print(
      'Texto CSV gerado (primeiros 50 caracteres): ${csv.substring(0, csv.length > 50 ? 50 : csv.length)}...',
    );

    try {
      if (kIsWeb) {
        print('Ambiente: Web');
        final blob = html.Blob([csv], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor =
            html.AnchorElement(href: url)
              ..target = 'blank'
              ..download = 'resultados_pesquisa.csv';
        anchor.click();
        html.Url.revokeObjectUrl(url);
        print('Download do arquivo CSV iniciado no navegador.');
        _mostrarMensagem('Download do arquivo CSV iniciado no navegador.');
      } else if (Platform.isAndroid || Platform.isIOS) {
        print('Ambiente: Mobile (Android/iOS)');
        final directory =
            await path_provider.getApplicationDocumentsDirectory();
        final file = io.File('${directory.path}/resultados_pesquisa.csv');

        // await file.writeAsString(csv, encoding: utf8); // Especifique UTF-8

        final bom = utf8.encode('\uFEFF');
        final csvBytes = utf8.encode(csv);
        await file.writeAsBytes([...bom, ...csvBytes]);

        print('Arquivo CSV gerado com sucesso em: ${file.path}');
        _mostrarMensagem('Arquivo CSV gerado com sucesso em: ${file.path}');
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        print('Ambiente: Desktop (Windows/Linux/macOS)');
        try {
          final directory =
              await path_provider.getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/resultados_pesquisa.csv';
          final file = io.File(filePath);

          // await file.writeAsString(csv, encoding: utf8); // Especifique UTF-8

          final bom = utf8.encode('\uFEFF');
          final csvBytes = utf8.encode(csv);
          await file.writeAsBytes([...bom, ...csvBytes]);

          print('Arquivo CSV gerado com sucesso em: $filePath');
          _mostrarMensagem('Arquivo CSV gerado com sucesso em: $filePath');
        } catch (e) {
          print('Erro ao gerar arquivo no desktop usando path_provider: $e');
          // Se path_provider não funcionar bem para desktop, podemos tentar um caminho padrão
          final filePath =
              '${io.Directory.current.path}/resultados_pesquisa.csv';
          final file = io.File(filePath);

          // await file.writeAsString(csv, encoding: utf8); // Especifique UTF-8

          final bom = utf8.encode('\uFEFF');
          final csvBytes = utf8.encode(csv);
          await file.writeAsBytes([...bom, ...csvBytes]);

          print(
            'Arquivo CSV gerado com sucesso (caminho padrão) em: $filePath',
          );
          _mostrarMensagem(
            'Arquivo CSV gerado com sucesso (caminho padrão) em: $filePath',
          );
        }
      } else {
        print('Plataforma não suportada para gerar CSV.');
        _mostrarMensagem('Plataforma não suportada para gerar CSV.');
      }
    } catch (e) {
      print('Erro ao gerar/baixar o arquivo CSV: $e');
      _mostrarMensagem('Erro ao gerar/baixar o arquivo CSV: $e');
    }
  }
}
