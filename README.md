# 📊 Gerencial - Aplicativo de Gestão e Análise de Backlog

Este é um projeto **Multiplataforma** desenvolvido em **Flutter** e **Dart** focado em fornecer uma ferramenta gerencial completa para consulta, filtragem e análise visual de grandes volumes de dados (como atendimentos, clientes, ou ordens de serviço) através de uma API RESTful.

## ✨ Funcionalidades em Destaque

O aplicativo foi projetado para ser robusto e funcionar em diversos ambientes:

### 🌐 Plataformas Suportadas
* **Windows Desktop**
* **Mobile** (Android e, implicitamente, iOS)

### 🔍 Módulo de Pesquisa e Filtros (`BacklogScreen`)
A tela principal de Backlog permite consultas detalhadas e dinâmicas:
* **Filtros Abrangentes:** Pesquisa por período de Data, Empresa, Setor, Cliente, Sistema, Status, Usuário, Classificação e Conteúdo da Solicitação.
* **Otimização de Dados:** Gerenciamento de grandes resultados com lógica de paginação manual.
* **Exportação de Dados:** Funcionalidade integrada para exportar os resultados filtrados para um arquivo **CSV** (com suporte multi-plataforma).

### 📈 Visualização de Dados
Transforme dados brutos em insights claros e objetivos:
* **Gráficos de Distribuição:** Geração de **Gráficos de Pizza (`PieChart`)** para mostrar a distribuição percentual de status de Atendimentos e Ordens de Serviço (O.S.).
* **Gráficos Comparativos:** Suporte a **Gráficos de Barra (`BarChart`)** para análise de indicadores ao longo do tempo (e.g., Atendimentos por dia).
* **Tabelas Avançadas:** Exibição de resultados em uma tabela interativa (`Syncfusion DataGrid`) com colunas formatadas e *overflow* gerenciado.

---

## 🛠️ Tecnologias Utilizadas

O projeto foi construído utilizando os seguintes pacotes e tecnologias, conforme o `pubspec.yaml`:

| Categoria | Pacote/Tecnologia | Versão | Descrição |
| :--- | :--- | :--- | :--- |
| **Framework** | **Flutter** | `^3.7.2` | Framework base para desenvolvimento de UI nativa. |
| **Gráficos** | `fl_chart` | `^0.64.0` | Biblioteca essencial para gráficos de pizza e barra. |
| **Tabela** | `syncfusion_flutter_datagrid` | `^24.1.41` | Componente DataGrid profissional para exibição de dados. |
| **API/Rede** | `http` | `^1.3.0` | Cliente para comunicação com a API RESTful. |
| **Configuração** | `flutter_dotenv` | `^5.1.0` | Carregamento da URL da API e outras variáveis de ambiente a partir do arquivo `.env`. |
| **Dados/Input** | `flutter_masked_text2` | `^0.9.0` | Aplicação de máscaras para formatação de entradas (ex: data/hora). |
| **Dados/Formato** | `intl` | `^0.19.0` | Suporte a internacionalização e formatação de datas. |
| **Suporte Multiplataforma** | `path_provider` | `^2.1.1` | Acesso a caminhos de diretórios do sistema (usado na exportação CSV). |
| **Suporte Web/Exportação**| `universal_html` | `^2.2.4` | Ajuda na abstração de funcionalidades de ambiente (usado na exportação CSV). |

---

## ⚙️ Configuração do Ambiente

Para rodar este projeto, siga os passos abaixo:

### Pré-requisitos
1.  **Flutter SDK** (Versão compatível com o `sdk: ^3.7.2` ou mais recente).
2.  Configuração da sua máquina para o desenvolvimento do target desejado (Windows ou Mobile).

### 1. Clonar o Repositório e Instalar Dependências
