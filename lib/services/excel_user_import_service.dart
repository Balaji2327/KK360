import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart';

class ExcelImportSheet {
  ExcelImportSheet({required this.headers, required this.rows});

  final List<String> headers;
  final List<Map<String, String>> rows;
}

class ExcelUserImportService {
  Future<ExcelImportSheet?> pickAndReadSheet() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: true,
    );

    if (picked == null || picked.files.isEmpty) {
      return null;
    }

    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw 'The selected Excel file is empty.';
    }

    return _parseWorkbook(bytes);
  }

  String? readValue(Map<String, String> row, List<String> aliases) {
    for (final alias in aliases) {
      final value = row[_normalizeHeader(alias)];
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  ExcelImportSheet _parseWorkbook(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    final worksheetFile = _findWorksheetFile(archive);
    if (worksheetFile == null) {
      throw 'No worksheet was found in the Excel file.';
    }

    final sharedStrings = _readSharedStrings(archive);
    final worksheetXml = _readArchiveFileAsString(worksheetFile);
    final worksheet = XmlDocument.parse(worksheetXml);

    final rows = <int, Map<int, String>>{};
    for (final rowNode in worksheet.findAllElements('row')) {
      final rowIndex = int.tryParse(rowNode.getAttribute('r') ?? '');
      if (rowIndex == null) {
        continue;
      }

      final rowCells = <int, String>{};
      for (final cellNode in rowNode.findElements('c')) {
        final ref = cellNode.getAttribute('r');
        final columnIndex = ref == null ? null : _columnIndexFromRef(ref);
        if (columnIndex == null) {
          continue;
        }

        final value = _readCellValue(cellNode, sharedStrings).trim();
        rowCells[columnIndex] = value;
      }

      if (rowCells.values.any((value) => value.isNotEmpty)) {
        rows[rowIndex] = rowCells;
      }
    }

    if (rows.isEmpty) {
      throw 'The Excel sheet does not contain any data.';
    }

    final orderedIndexes = rows.keys.toList()..sort();
    final headerIndex = orderedIndexes.first;
    final headerCells = rows[headerIndex]!;

    final maxColumn = headerCells.keys.isEmpty
        ? 0
        : headerCells.keys.reduce((a, b) => a > b ? a : b);

    final headers = <String>[];
    for (var column = 0; column <= maxColumn; column++) {
      headers.add(_normalizeHeader(headerCells[column] ?? ''));
    }

    final dataRows = <Map<String, String>>[];
    for (final rowIndex in orderedIndexes.skip(1)) {
      final rowCells = rows[rowIndex]!;
      final data = <String, String>{};

      for (var column = 0; column < headers.length; column++) {
        final header = headers[column];
        if (header.isEmpty) {
          continue;
        }
        data[header] = (rowCells[column] ?? '').trim();
      }

      if (data.values.any((value) => value.isNotEmpty)) {
        dataRows.add(data);
      }
    }

    return ExcelImportSheet(headers: headers, rows: dataRows);
  }

  ArchiveFile? _findWorksheetFile(Archive archive) {
    final worksheets = archive.files
        .where((file) => file.name.startsWith('xl/worksheets/sheet'))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (worksheets.isEmpty) {
      return null;
    }

    return worksheets.first;
  }

  List<String> _readSharedStrings(Archive archive) {
    final sharedStringsFile = archive.files.where(
      (file) => file.name == 'xl/sharedStrings.xml',
    );

    if (sharedStringsFile.isEmpty) {
      return const [];
    }

    final sharedStringsXml = _readArchiveFileAsString(sharedStringsFile.first);
    final document = XmlDocument.parse(sharedStringsXml);

    return document.findAllElements('si').map((entry) {
      return entry
          .findAllElements('t')
          .map((node) => node.innerText)
          .join();
    }).toList();
  }

  String _readArchiveFileAsString(ArchiveFile file) {
    final content = file.content;
    if (content is Uint8List) {
      return String.fromCharCodes(content);
    }
    if (content is List<int>) {
      return String.fromCharCodes(content);
    }
    throw 'Failed to read ${file.name} from the Excel file.';
  }

  String _readCellValue(XmlElement cellNode, List<String> sharedStrings) {
    final type = cellNode.getAttribute('t');

    if (type == 'inlineStr') {
      return cellNode.findAllElements('t').map((node) => node.innerText).join();
    }

    final rawValue = cellNode.getElement('v')?.innerText ?? '';
    if (rawValue.isEmpty) {
      return '';
    }

    if (type == 's') {
      final index = int.tryParse(rawValue);
      if (index == null || index < 0 || index >= sharedStrings.length) {
        return '';
      }
      return sharedStrings[index];
    }

    return rawValue;
  }

  int? _columnIndexFromRef(String ref) {
    final match = RegExp(r'^([A-Z]+)').firstMatch(ref.toUpperCase());
    if (match == null) {
      return null;
    }

    final letters = match.group(1)!;
    var index = 0;
    for (final codeUnit in letters.codeUnits) {
      index = (index * 26) + (codeUnit - 64);
    }
    return index - 1;
  }

  String _normalizeHeader(String header) {
    return header
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
