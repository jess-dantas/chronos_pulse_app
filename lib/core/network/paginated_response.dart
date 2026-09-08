/// Normaliza a resposta de listagens do backend, aceitando tanto o formato
/// "lista simples" (ex.: estoque/empresas) quanto o "envelope paginado"
/// do Spring (ex.: frota/patrimônio/protocolo -> { content, totalElements, ... }).
class PaginatedResponse<T> {
  final List<T> items;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final int pageSize;

  const PaginatedResponse({
    required this.items,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
  });

  bool get hasMore => currentPage < totalPages - 1;

  factory PaginatedResponse.from(
      dynamic data, List<T> Function(List<Map<String, dynamic>>) parser) {
    if (data is List) {
      final itens = parser(
          data.whereType<Map<String, dynamic>>().map((e) => Map<String, dynamic>.from(e)).toList());
      return PaginatedResponse(
        items: itens,
        totalElements: itens.length,
        totalPages: 1,
        currentPage: 0,
        pageSize: itens.length,
      );
    }
    if (data is Map) {
      final content = (data['content'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final total = (data['totalElements'] as num?)?.toInt() ?? (data['total'] as num?)?.toInt() ?? content.length;
      final totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
      final currentPage = (data['number'] as num?)?.toInt() ?? (data['page'] as num?)?.toInt() ?? 0;
      return PaginatedResponse(
        items: parser(content),
        totalElements: total,
        totalPages: totalPages,
        currentPage: currentPage,
        pageSize: (data['size'] as num?)?.toInt() ?? content.length,
      );
    }
    return const PaginatedResponse(items: [], totalElements: 0, totalPages: 0, currentPage: 0, pageSize: 0);
  }
}