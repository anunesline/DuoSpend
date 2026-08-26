import 'package:image_picker/image_picker.dart';

import '../../domain/models/receipt_capture_source.dart';
import '../../domain/models/receipt_scan_image.dart';
import '../../domain/repositories/receipt_image_capture_provider.dart';

class ImagePickerReceiptImageCaptureProvider
    implements ReceiptImageCaptureProvider {
  final ImagePicker _imagePicker;

  ImagePickerReceiptImageCaptureProvider({
    ImagePicker? imagePicker,
  }) : _imagePicker = imagePicker ?? ImagePicker();

  @override
  Future<ReceiptScanImage?> capture(ReceiptCaptureSource source) async {
    final image = await _imagePicker.pickImage(
      source: source == ReceiptCaptureSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 90,
    );
    if (image == null) return null;

    return ReceiptScanImage(
      bytes: await image.readAsBytes(),
      mimeType: _mimeTypeFor(image.path),
      filePath: image.path,
    );
  }

  String _mimeTypeFor(String path) {
    final normalized = path.toLowerCase();
    if (normalized.endsWith('.png')) return 'image/png';
    if (normalized.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
