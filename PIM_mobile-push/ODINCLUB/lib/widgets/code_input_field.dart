import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class CodeInputField extends StatefulWidget {
  final int length;
  final Function(String)? onChanged;
  final Function(String)? onCompleted;
  final TextEditingController? controller;

  const CodeInputField({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.controller,
  });

  @override
  State<CodeInputField> createState() => _CodeInputFieldState();
}

class _CodeInputFieldState extends State<CodeInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (index) => widget.controller != null && index == 0
          ? widget.controller!
          : TextEditingController(),
    );
    _focusNodes = List.generate(widget.length, (index) => FocusNode());

    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      if (controller != widget.controller) {
        controller.dispose();
      }
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    // Handle paste - when multiple characters are entered
    if (value.length > 1) {
      final pastedCode = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (pastedCode.length >= widget.length) {
        // Fill all fields with pasted code
        for (int i = 0; i < widget.length; i++) {
          if (i < pastedCode.length) {
            _controllers[i].text = pastedCode[i];
          }
        }
        _focusNodes[widget.length - 1].requestFocus();
        _notifyCompletion();
        return;
      } else if (pastedCode.isNotEmpty) {
        // Partial paste - fill from current index
        for (int i = 0; i < pastedCode.length && (index + i) < widget.length; i++) {
          _controllers[index + i].text = pastedCode[i];
        }
        final nextIndex = (index + pastedCode.length < widget.length) 
            ? index + pastedCode.length 
            : widget.length - 1;
        _focusNodes[nextIndex].requestFocus();
        _notifyCompletion();
        return;
      }
    }

    // Handle single character input
    if (value.isEmpty) {
      // Backspace was pressed
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      _notifyCompletion();
      return;
    }

    // Only allow single digit (0-9)
    final digit = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digit.isEmpty) {
      _controllers[index].clear();
      return;
    }

    // Set the digit (take only first character if multiple)
    _controllers[index].text = digit[0];
    
    // Move to next field if not the last one
    if (index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      // Last field - unfocus to hide keyboard
      _focusNodes[index].unfocus();
    }

    _notifyCompletion();
  }

  void _notifyCompletion() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length == widget.length) {
      widget.onCompleted?.call(code);
    }
    widget.onChanged?.call(code);
  }

  String getCode() {
    return _controllers.map((c) => c.text).join();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.length,
        (index) => Container(
          width: 50,
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            showCursor: true,
            cursorColor: AppTheme.blueFonce,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGrey,
              letterSpacing: 0,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.blueFonce.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.blueFonce.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.blueFonce,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              _onChanged(index, value);
            },
            onTap: () {
              // Select all text when tapped
              _controllers[index].selection = TextSelection(
                baseOffset: 0,
                extentOffset: _controllers[index].text.length,
              );
            },
            onSubmitted: (_) {
              if (index < widget.length - 1) {
                _focusNodes[index + 1].requestFocus();
              } else {
                _focusNodes[index].unfocus();
              }
            },
          ),
        ),
      ),
    );
  }
}
