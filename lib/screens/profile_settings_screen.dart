import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/custom_dialog_helper.dart';
import '../widgets/custom_loading_indicator.dart';
import '../widgets/custom_text_field.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;
  final _imagePicker = ImagePicker();
  final _authService = AuthService();

  static const _backgroundColor = Color(0xFF0D0D0D);
  static const _cardColor = Color(0xFF1A1A1A);
  static const _elevatedColor = Color(0xFF242424);
  static const _cyan = Color(0xFF00D4FF);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFA0A0A0);
  static const _textDisabled = Color(0xFF555555);
  static const _error = Color(0xFFFF4D4D);

  late TextEditingController _nameController;
  late TextEditingController _userIdController;
  late TextEditingController _bioController;
  final _userIdFocusNode = FocusNode();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _nameError;
  String? _userIdError;
  bool _isCheckingUserId = false;

  // 元の値（変更検出用）
  String _originalName = '';
  String _originalUserId = '';
  String _originalBio = '';
  String? _originalIconUrl;
  String? _originalBackgroundUrl;

  // 画像の状態
  File? _newIconImage;
  File? _newBackgroundImage;
  bool _iconRemoved = false;
  bool _backgroundRemoved = false;
  String? _currentIconUrl;
  String? _currentBackgroundUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController()..addListener(_onFieldChanged);
    _userIdController = TextEditingController()..addListener(_onFieldChanged);
    _bioController = TextEditingController()..addListener(_onFieldChanged);
    _userIdFocusNode.addListener(_onUserIdFocusChange);
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _userIdController.dispose();
    _bioController.dispose();
    _userIdFocusNode.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() {});
  }

  void _onUserIdFocusChange() {
    if (!_userIdFocusNode.hasFocus && _userIdController.text.isNotEmpty) {
      _validateUserId();
    }
  }

  // === データ読み込み ===

  Future<void> _loadProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!mounted) return;

      final data = doc.data();
      if (data == null) return;

      _originalName = data['name'] as String? ?? '';
      _originalUserId = data['userId'] as String? ?? '';
      _originalBio = data['bio'] as String? ?? '';
      _originalIconUrl = data['iconUrl'] as String?;
      _originalBackgroundUrl = data['backgroundUrl'] as String?;
      _currentIconUrl = _originalIconUrl;
      _currentBackgroundUrl = _originalBackgroundUrl;

      _nameController.text = _originalName;
      _userIdController.text = _originalUserId;
      _bioController.text = _originalBio;

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      await showCustomDialog(
        context,
        title: 'エラー',
        message: toUserFriendlyError(e),
      );
      if (mounted) Navigator.of(context).pop();
    }
  }

  // === 変更検出・バリデーション ===

  bool get _hasChanges {
    return _nameController.text != _originalName ||
        _userIdController.text != _originalUserId ||
        _bioController.text != _originalBio ||
        _newIconImage != null ||
        _newBackgroundImage != null ||
        _iconRemoved ||
        _backgroundRemoved;
  }

  bool get _canSave {
    return _hasChanges &&
        _nameController.text.isNotEmpty &&
        _userIdController.text.length >= 3 &&
        _nameError == null &&
        _userIdError == null &&
        !_isCheckingUserId &&
        !_isSaving;
  }

  void _validateName() {
    setState(() {
      _nameError =
          _nameController.text.isEmpty ? '名前を入力してください' : null;
    });
  }

  Future<void> _validateUserId() async {
    final userId = _userIdController.text;

    if (userId.isEmpty) {
      setState(() => _userIdError = 'ユーザーIDを入力してください');
      return;
    }
    if (userId.length < 3) {
      setState(() => _userIdError = '3文字以上入力してください');
      return;
    }
    if (userId == _originalUserId) {
      setState(() => _userIdError = null);
      return;
    }

    setState(() => _isCheckingUserId = true);

    try {
      final isAvailable = await _authService.isUserIdAvailable(userId);
      if (!mounted) return;
      setState(() {
        _userIdError = isAvailable ? null : 'このIDは既に使用されています';
        _isCheckingUserId = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _userIdError = '確認中にエラーが発生しました';
        _isCheckingUserId = false;
      });
    }
  }

  // === 画像選択 ===

  Future<void> _showImagePickerSheet({required bool isIcon}) async {
    final hasExistingImage = isIcon
        ? (_newIconImage != null ||
            (_currentIconUrl != null &&
                _currentIconUrl!.isNotEmpty &&
                !_iconRemoved))
        : (_newBackgroundImage != null ||
            (_currentBackgroundUrl != null &&
                _currentBackgroundUrl!.isNotEmpty &&
                !_backgroundRemoved));

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: _elevatedColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ハンドルバー
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _textDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // タイトル
            Text(
              isIcon ? 'プロフィール画像を選択' : '背景画像を選択',
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // カメラで撮影
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              leading: const Icon(Icons.camera_alt, color: _cyan),
              title: const Text(
                'カメラで撮影',
                style: TextStyle(color: _textPrimary, fontSize: 16),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(source: ImageSource.camera, isIcon: isIcon);
              },
            ),
            // ライブラリから選択
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              leading: const Icon(Icons.photo_library, color: _cyan),
              title: const Text(
                'ライブラリから選択',
                style: TextStyle(color: _textPrimary, fontSize: 16),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(source: ImageSource.gallery, isIcon: isIcon);
              },
            ),
            // 画像を削除（既存画像がある場合のみ）
            if (hasExistingImage)
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                leading: const Icon(Icons.delete_outline, color: _error),
                title: const Text(
                  '画像を削除',
                  style: TextStyle(color: _error, fontSize: 16),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _removeImage(isIcon: isIcon);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage({
    required ImageSource source,
    required bool isIcon,
  }) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: isIcon
            ? const CropAspectRatio(ratioX: 1, ratioY: 1)
            : const CropAspectRatio(ratioX: 16, ratioY: 9),
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: isIcon ? 'プロフィール画像' : '背景画像',
            toolbarColor: _backgroundColor,
            toolbarWidgetColor: _cyan,
            backgroundColor: _backgroundColor,
            activeControlsWidgetColor: _cyan,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: isIcon ? 'プロフィール画像' : '背景画像',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (cropped == null || !mounted) return;

      setState(() {
        if (isIcon) {
          _newIconImage = File(cropped.path);
          _iconRemoved = false;
        } else {
          _newBackgroundImage = File(cropped.path);
          _backgroundRemoved = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      showCustomDialog(
        context,
        title: 'エラー',
        message: '画像の選択に失敗しました',
      );
    }
  }

  void _removeImage({required bool isIcon}) {
    setState(() {
      if (isIcon) {
        _newIconImage = null;
        _iconRemoved = true;
      } else {
        _newBackgroundImage = null;
        _backgroundRemoved = true;
      }
    });
  }

  // === 保存処理 ===

  Future<void> _handleSave() async {
    // バリデーション
    _validateName();
    if (_nameError != null) return;

    await _validateUserId();
    if (_userIdError != null) return;

    // 自己紹介文が変更されている場合 → AI変換プレビュー
    final bioChanged =
        _bioController.text != _originalBio && _bioController.text.isNotEmpty;

    if (bioChanged) {
      final proceed = await _showAiConversionPreview();
      if (!proceed) return;
    }

    await _executeSave();
  }

  Future<bool> _showAiConversionPreview() async {
    final originalBio = _bioController.text;

    // MVP: モック変換（実際のAI APIは後から接続）
    await Future.delayed(const Duration(milliseconds: 500));
    final convertedBio = originalBio;

    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CustomDialog(
        title: '自己紹介の変換プレビュー',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 変換前ラベル
            const Text(
              '変換前',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // 変換前テキスト
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                originalBio,
                style: const TextStyle(color: _textSecondary, fontSize: 14),
              ),
            ),
            // 矢印
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Icon(Icons.arrow_downward, color: _cyan, size: 24),
              ),
            ),
            // 変換後ラベル
            const Text(
              '変換後',
              style: TextStyle(
                color: _cyan,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // 変換後テキスト
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                  left: BorderSide(color: _cyan, width: 2),
                ),
              ),
              child: Text(
                convertedBio,
                style: const TextStyle(color: _textPrimary, fontSize: 14),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'やり直す',
                  variant: CustomButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: '確認',
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _executeSave() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);

    try {
      String? newIconUrl = _currentIconUrl;
      String? newBackgroundUrl = _currentBackgroundUrl;

      // アイコン画像アップロード
      if (_newIconImage != null) {
        final ref = _storage.ref().child('users/$uid/icon.jpg');
        await ref.putFile(_newIconImage!);
        newIconUrl = await ref.getDownloadURL();
      } else if (_iconRemoved) {
        try {
          await _storage.ref().child('users/$uid/icon.jpg').delete();
        } catch (_) {}
        newIconUrl = null;
      }

      // 背景画像アップロード
      if (_newBackgroundImage != null) {
        final ref = _storage.ref().child('users/$uid/background.jpg');
        await ref.putFile(_newBackgroundImage!);
        newBackgroundUrl = await ref.getDownloadURL();
      } else if (_backgroundRemoved) {
        try {
          await _storage.ref().child('users/$uid/background.jpg').delete();
        } catch (_) {}
        newBackgroundUrl = null;
      }

      // Firestore更新
      await _firestore.collection('users').doc(uid).update({
        'name': _nameController.text,
        'userId': _userIdController.text,
        'bio': _bioController.text,
        'iconUrl': newIconUrl,
        'backgroundUrl': newBackgroundUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      await showCustomDialog(
        context,
        title: '完了',
        message: 'プロフィールを更新しました',
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showCustomDialog(
        context,
        title: 'エラー',
        message: toUserFriendlyError(e),
      );
    }
  }

  // === 戻る（破棄確認） ===

  Future<bool> _confirmDiscard() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CustomDialog(
        title: '変更を破棄しますか？',
        content: const Text(
          '編集中の内容は保存されません',
          style: TextStyle(color: _textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'キャンセル',
                  variant: CustomButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: '破棄',
                  variant: CustomButtonVariant.danger,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // === ビルド ===

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _backgroundColor,
        appBar: CustomAppBar(titleText: 'Edit Profile'),
        body: Center(child: CustomLoadingIndicator()),
      );
    }

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard();
        if (!shouldPop || !mounted) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: const CustomAppBar(titleText: 'Edit Profile'),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 24),
              _buildFormSection(),
              _buildSaveButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // === ヘッダー（背景画像 + アイコン） ===

  Widget _buildHeaderSection() {
    const backgroundHeight = 200.0;
    const iconRadius = 48.0;

    return SizedBox(
      height: backgroundHeight + iconRadius,
      child: Stack(
        children: [
          // 背景画像（タップで変更）
          GestureDetector(
            onTap: () => _showImagePickerSheet(isIcon: false),
            child: Stack(
              children: [
                _buildBackgroundImage(backgroundHeight),
                // 半透明オーバーレイ
                Container(
                  width: double.infinity,
                  height: backgroundHeight,
                  color: Colors.black.withOpacity( 0.3),
                ),
                // カメラアイコン
                SizedBox(
                  width: double.infinity,
                  height: backgroundHeight,
                  child: Center(
                    child: Icon(
                      Icons.camera_alt,
                      size: 32,
                      color: _textPrimary.withOpacity( 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // プロフィールアイコン（タップで変更）
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _showImagePickerSheet(isIcon: true),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _textPrimary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity( 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildIconAvatar(iconRadius),
                    ),
                    // カメラバッジ
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: _cyan,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: _backgroundColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage(double height) {
    if (_newBackgroundImage != null) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: Image.file(_newBackgroundImage!, fit: BoxFit.cover),
      );
    }

    if (!_backgroundRemoved &&
        _currentBackgroundUrl != null &&
        _currentBackgroundUrl!.isNotEmpty) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: Image.network(
          _currentBackgroundUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultBackground(height),
        ),
      );
    }

    return _buildDefaultBackground(height);
  }

  Widget _buildDefaultBackground(double height) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_cardColor, _elevatedColor],
        ),
      ),
    );
  }

  Widget _buildIconAvatar(double radius) {
    if (_newIconImage != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(_newIconImage!),
        backgroundColor: _cardColor,
      );
    }

    if (!_iconRemoved &&
        _currentIconUrl != null &&
        _currentIconUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(_currentIconUrl!),
        backgroundColor: _cardColor,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: _cardColor,
      child: Icon(Icons.person, size: radius, color: _textDisabled),
    );
  }

  // === フォームセクション ===

  Widget _buildFormSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          _buildFieldLabel('Name'),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _nameController,
            hintText: '表示名を入力',
            errorText: _nameError,
            inputFormatters: [LengthLimitingTextInputFormatter(20)],
            onChanged: (_) => _validateName(),
          ),
          _buildCharacterCounter(_nameController.text.length, 20),
          const SizedBox(height: 20),

          // User ID
          _buildFieldLabel('User ID'),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _userIdController,
            hintText: 'ユーザーIDを入力',
            focusNode: _userIdFocusNode,
            errorText: _userIdError,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                '@',
                style: TextStyle(color: _textSecondary, fontSize: 16),
              ),
            ),
            inputFormatters: [
              LengthLimitingTextInputFormatter(20),
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
              _LowercaseTextFormatter(),
            ],
            onChanged: (_) {
              setState(() {
                if (_userIdController.text.isNotEmpty &&
                    _userIdController.text.length < 3) {
                  _userIdError = '3文字以上入力してください';
                } else {
                  _userIdError = null;
                }
              });
            },
          ),
          _buildCharacterCounter(_userIdController.text.length, 20),
          const SizedBox(height: 20),

          // Bio
          _buildFieldLabel('Bio'),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _bioController,
            hintText: '自己紹介を入力',
            maxLines: 4,
            minLines: 2,
            inputFormatters: [LengthLimitingTextInputFormatter(150)],
          ),
          _buildCharacterCounter(_bioController.text.length, 150),
          const SizedBox(height: 4),
          const Text(
            '保存時にAIが文章を整えます',
            style: TextStyle(color: _textDisabled, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCharacterCounter(int current, int max) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '$current/$max',
          style: const TextStyle(color: _textSecondary, fontSize: 12),
        ),
      ),
    );
  }

  // === 保存ボタン ===

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: CustomButton(
        text: 'Save',
        isLoading: _isSaving,
        onPressed: _canSave ? _handleSave : null,
      ),
    );
  }
}

// === 小文字変換フォーマッター ===

class _LowercaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toLowerCase());
  }
}
