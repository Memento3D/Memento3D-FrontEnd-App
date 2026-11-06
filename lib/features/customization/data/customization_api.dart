import '../../../core/network/api_client.dart';

typedef DesignSelection = Map<String, String?>;

class DesignDraft {
  DesignDraft.fromJson(Map<String, dynamic> json)
    : fitId = json['fitResultId'] as String,
      revision = json['revision'] as int,
      exists = json['exists'] == true,
      editable = json['editable'] == true,
      selection = Map<String, String?>.from(json['selection'] as Map);
  final String fitId;
  final int revision;
  final bool exists, editable;
  final DesignSelection selection;
}

class DesignScene {
  DesignScene.fromJson(Map<String, dynamic> value)
    : json = value,
      draft = DesignDraft.fromJson(
        Map<String, dynamic>.from(value['customization'] as Map),
      ) {
    if (value['modelOutputId'] is! String ||
        value['fitResultId'] is! String ||
        value['baseModel'] is! Map ||
        value['assets'] is! List ||
        value['groups'] is! List) {
      throw const FormatException('Scene model không hợp lệ');
    }
    for (final asset in assets) {
      final matrix = asset['matrixColumnMajor'];
      if (matrix is! List ||
          matrix.length != 16 ||
          !matrix.every((v) => v is num && v.isFinite)) {
        throw const FormatException('Ma trận asset không hợp lệ');
      }
    }
    if (!accepts(draft.selection) || draft.fitId != fitId) {
      throw const FormatException('Bản lưu không khớp scene');
    }
  }
  final Map<String, dynamic> json;
  final DesignDraft draft;
  String get outputId => json['modelOutputId'] as String;
  String get fitId => json['fitResultId'] as String;
  Map<String, dynamic> get base =>
      Map<String, dynamic>.from(json['baseModel'] as Map);
  List<Map<String, dynamic>> get assets => (json['assets'] as List)
      .map((v) => Map<String, dynamic>.from(v as Map))
      .toList();
  List<Map<String, dynamic>> get groups => (json['groups'] as List)
      .map((v) => Map<String, dynamic>.from(v as Map))
      .toList();
  bool accepts(DesignSelection selection) =>
      selection.length == groups.length &&
      groups.every((group) {
        final id = group['id'] as String;
        return selection.containsKey(id) &&
            (selection[id] == null
                ? group['noneAllowed'] == true && group['required'] != true
                : (group['assetVersionIds'] as List).contains(selection[id]));
      });
  bool sameGeometry(DesignScene other) =>
      outputId == other.outputId &&
      fitId == other.fitId &&
      base['sha256'] == other.base['sha256'] &&
      assets.length == other.assets.length &&
      assets.every(
        (asset) => other.assets.any(
          (next) =>
              next['assetVersionId'] == asset['assetVersionId'] &&
              next['sha256'] == asset['sha256'],
        ),
      );
}

class CustomizationApi {
  CustomizationApi({ApiClient? client}) : client = client ?? ApiClient();
  final ApiClient client;
  String _path(String outputId) =>
      '/api/v1/models/${Uri.encodeComponent(outputId)}';
  Future<DesignScene> scene(String outputId) async => DesignScene.fromJson(
    Map<String, dynamic>.from(
      await client.get('${_path(outputId)}/scene') as Map,
    ),
  );
  Future<DesignDraft> draft(String outputId) async => DesignDraft.fromJson(
    Map<String, dynamic>.from(
      await client.get('${_path(outputId)}/customization') as Map,
    ),
  );
  Future<DesignDraft> save(
    String outputId,
    DesignDraft current,
    DesignSelection selection,
  ) async => DesignDraft.fromJson(
    Map<String, dynamic>.from(
      await client.put(
        '${_path(outputId)}/customization',
        body: {
          'fitResultId': current.fitId,
          'revision': current.revision,
          'selection': selection,
        },
      ) as Map,
    ),
  );
}
