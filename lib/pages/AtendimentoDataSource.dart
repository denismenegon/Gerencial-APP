import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class AtendimentoDataSource extends DataGridSource {
  final List<DataGridRow> _rows;

  AtendimentoDataSource(List<Map<String, String>> dados)
    : _rows =
          dados
              .map(
                (item) => DataGridRow(
                  cells: [
                    DataGridCell(
                      columnName: 'data',
                      value: item['AtendimentoDataHoraFormatado'],
                    ),
                    DataGridCell(
                      columnName: 'seq',
                      value: item['AtendimentoSequenciaFormatado'],
                    ),
                    DataGridCell(
                      columnName: 'empresa',
                      value: item['EmpresaRazaoSocialFormatado'],
                    ),
                    DataGridCell(
                      columnName: 'cliente',
                      value: item['ClienteRazaoSocialFormatado'],
                    ),
                    DataGridCell(
                      columnName: 'contato',
                      value: item['AtendimentoContatoDescricaoFormatado'],
                    ),
                    DataGridCell(
                      columnName: 'sistema',
                      value: item['SistemaDescricaoFormatado'],
                    ),
                    DataGridCell(
                      columnName: 'usuario',
                      value: item['UsuarioDescricaoFormatado'],
                    ),
                    DataGridCell(
                      columnName: 'classificacao',
                      value: item['ClassificacaoDescricaoFormatado'],
                    ),
                  ],
                ),
              )
              .toList();

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells:
          row.getCells().map<Widget>((cell) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              alignment: Alignment.centerLeft,
              child: Text(
                cell.value?.toString() ?? '',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
    );
  }
}
