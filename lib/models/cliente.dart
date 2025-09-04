class Cliente {
  final String? dsIpCliente;
  final String? dsCliente;
  final int? tipoCliente;

  Cliente({this.dsIpCliente, this.dsCliente, this.tipoCliente});

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      dsIpCliente: json['ds_ipCliente'] as String?,
      dsCliente: json['ds_Cliente'] as String?,
      // tipoCliente: json['fl_TipoCliente'],
      tipoCliente:
          json['fl_TipoCliente'] as int?, // Garantir que seja 'int' no modelo
    );
  }
}
