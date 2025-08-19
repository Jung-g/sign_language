import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'package:camera/camera.dart';
import 'package:ffi/ffi.dart' as ffi_pkg;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:permission_handler/permission_handler.dart';

typedef SendFn =
    Future<Map<String, dynamic>?> Function(List<String> base64Frames);
typedef ServerResponseFn = void Function(Map<String, dynamic> res);
typedef CameraStateFn = void Function(bool isOn);

class CameraWidget extends StatefulWidget {
  const CameraWidget({
    super.key,
    required this.onSend, // 서버로 전송하는 함수
    this.onServerResponse, // 서버 응답을 부모에 전달
    this.onCameraState, // 카메라 On/Off 콜백
    this.batchSize = 45, // 배치 크기
    this.maxBuffer = 120, // 프레임 버퍼 상한
    this.useNV12 = false, // NV12(true) / NV21(false)
    this.rotate90CCW = true, // 90도 반시계 회전
    this.targetSize, // 인코딩 전 리사이즈 크기(Size(720, 480))
    this.autoStart = false, // 위젯 마운트 시 자동 시작
    this.preferFrontCamera = true, // 전면 카메라 우선
    this.visible = true, // 프리뷰 가시성
    this.paused = false, // 전송 일시 정지(배치 드롭)
  });

  final SendFn onSend;
  final ServerResponseFn? onServerResponse;
  final CameraStateFn? onCameraState;

  final int batchSize;
  final int maxBuffer;
  final bool useNV12;
  final bool rotate90CCW;
  final Size? targetSize;

  final bool autoStart;
  final bool preferFrontCamera;
  final bool visible;
  final bool paused;

  @override
  State<CameraWidget> createState() => CameraWidgetState();
}

class CameraWidgetState extends State<CameraWidget> {
  CameraController? _controller;
  bool _isOn = false;
  bool _busy = false;

  final List<Uint8List> _frameBuffer = [];
  Future<void> sendQueue = Future.value();

  bool get isOn => _isOn;
  CameraController? get controller => _controller;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      unawaited(start());
    }
  }

  @override
  void didUpdateWidget(covariant CameraWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // paused가 true로 바뀌면 전송용 버퍼는 비워 메모리 누수를 방지
    if (widget.paused && !oldWidget.paused) {
      _frameBuffer.clear();
    }
  }

  @override
  void dispose() {
    unawaited(stop());
    super.dispose();
  }

  Future<bool> _ensurePermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> start() async {
    if (_isOn) return;
    if (!await _ensurePermission()) {
      debugPrint('카메라 권한 필요');
      return;
    }

    try {
      final cams = await availableCameras();
      CameraDescription cam;
      if (widget.preferFrontCamera) {
        cam = cams.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cams.first,
        );
      } else {
        cam = cams.first;
      }

      final ctrl = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await ctrl.initialize();
      await ctrl.startImageStream(onFrameAvailable);

      setState(() {
        _controller = ctrl;
        _isOn = true;
      });
      widget.onCameraState?.call(true);
    } catch (e) {
      debugPrint('카메라 시작 실패: $e');
      await stop();
    }
  }

  Future<void> stop() async {
    if (_controller == null && !_isOn) return;

    try {
      if (_controller?.value.isStreamingImages == true) {
        await _controller!.stopImageStream();
      }
    } catch (_) {}

    try {
      await sendQueue;
    } catch (_) {}

    // 잔여 프레임은 폐기하여 실시간 흐름과 일관성 유지
    _frameBuffer.clear();

    try {
      await _controller?.dispose();
    } catch (_) {}

    setState(() {
      _controller = null;
      _isOn = false;
    });
    widget.onCameraState?.call(false);
  }

  void enqueueSend(List<Uint8List> frames) {
    final payload = frames.map((f) => base64Encode(f)).toList();
    sendQueue = sendQueue.then((_) async {
      if (widget.paused) return;
      try {
        final res = await widget.onSend(payload);
        if (res != null) {
          widget.onServerResponse?.call(res);
        }
      } catch (e) {
        debugPrint('프레임 전송 오류: $e');
      }
    });
  }

  void onFrameAvailable(CameraImage image) async {
    if (_busy || widget.paused) {
      // 일시 정지 시에는 들어온 프레임을 사용하지 않음
      return;
    }
    _busy = true;

    try {
      final jpeg = await encodeJpegWithOpenCV(
        image,
        useNV12: widget.useNV12,
        rotate90CCW: widget.rotate90CCW,
        targetSize: widget.targetSize ?? const Size(720, 480),
      );
      if (jpeg != null) {
        if (_frameBuffer.length >= widget.maxBuffer) {
          final drop = _frameBuffer.length - widget.maxBuffer + 1;
          _frameBuffer.removeRange(0, drop);
        }
        _frameBuffer.add(jpeg);

        while (_frameBuffer.length >= widget.batchSize) {
          final chunk = List<Uint8List>.from(
            _frameBuffer.take(widget.batchSize),
          );
          _frameBuffer.removeRange(0, widget.batchSize);
          enqueueSend(chunk);
        }
      }
    } catch (e) {
      debugPrint('프레임 처리 오류: $e');
    } finally {
      _busy = false;
    }
  }

  // YUV_420_888 → NVxx(NV21/NV12)
  Uint8List yuv420ToNVsp(CameraImage image, {required bool useNV12}) {
    final int w = image.width, h = image.height;

    final planeY = image.planes[0];
    final planeU = image.planes[1];
    final planeV = image.planes[2];

    final out = Uint8List(w * h + (w * h) ~/ 2);

    int dst = 0;
    for (int r = 0; r < h; r++) {
      final src = r * planeY.bytesPerRow;
      out.setRange(dst, dst + w, planeY.bytes, src);
      dst += w;
    }

    final int ch = h ~/ 2, cw = w ~/ 2;
    int cIdx = w * h;

    final int uvRowStride = planeU.bytesPerRow;
    final int uvPixStride = planeU.bytesPerPixel ?? 1;

    for (int r = 0; r < ch; r++) {
      final int row = r * uvRowStride;
      for (int c = 0; c < cw; c++) {
        final int off = row + c * uvPixStride;
        final int u = planeU.bytes[off];
        final int v = planeV.bytes[off];
        if (useNV12) {
          out[cIdx++] = u;
          out[cIdx++] = v;
        } else {
          out[cIdx++] = v;
          out[cIdx++] = u;
        }
      }
    }
    return out;
  }

  // NVxx → BGR → 회전/리사이즈 → JPEG 인코딩
  Future<Uint8List?> encodeJpegWithOpenCV(
    CameraImage image, {
    required bool useNV12,
    required bool rotate90CCW,
    required Size targetSize,
  }) async {
    final int w = image.width, h = image.height;

    final nv = yuv420ToNVsp(image, useNV12: useNV12);

    final ptr = ffi_pkg.calloc<ffi.Uint8>(nv.length);
    try {
      ptr.asTypedList(nv.length).setAll(0, nv);
      final yuv = cv.Mat.fromBuffer(
        h + h ~/ 2,
        w,
        cv.MatType.CV_8UC1,
        ptr.cast<ffi.Void>(),
      );

      final code = useNV12 ? cv.COLOR_YUV2BGR_NV12 : cv.COLOR_YUV2BGR_NV21;
      final bgr = cv.cvtColor(yuv, code);

      cv.Mat processed = bgr;
      if (rotate90CCW) {
        final rot = cv.rotate(processed, cv.ROTATE_90_COUNTERCLOCKWISE);
        processed.dispose();
        processed = rot;
      }

      if (targetSize.width > 0 && targetSize.height > 0) {
        final resized = cv.resize(processed, (
          targetSize.width.toInt(),
          targetSize.height.toInt(),
        ), interpolation: cv.INTER_AREA);
        processed.dispose();
        processed = resized;
      }

      final params = cv.VecI32.fromList([cv.IMWRITE_JPEG_QUALITY, 90]);
      final rec = cv.imencode('.jpg', processed, params: params);
      final ok = rec.$1;
      final jpeg = rec.$2;

      yuv.dispose();
      processed.dispose();

      if (!ok) return null;
      return jpeg;
    } catch (e) {
      debugPrint('OpenCV 인코딩 오류: $e');
      return null;
    } finally {
      ffi_pkg.calloc.free(ptr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showPreview =
        widget.visible &&
        _controller != null &&
        _controller!.value.isInitialized;
    return RepaintBoundary(
      child: showPreview
          ? CameraPreview(_controller!)
          : const SizedBox.shrink(),
    );
  }
}
