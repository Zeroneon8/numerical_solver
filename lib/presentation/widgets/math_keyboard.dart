import 'package:flutter/material.dart';

class MathKey {
  const MathKey(this.text, {this.cursorOffset});

  final String text;
  final int? cursorOffset;
}

class MathKeyboard extends StatelessWidget {
  const MathKeyboard({
    super.key,
    required this.visible,
    required this.onKeyPressed,
    required this.onBackspace,
    required this.onConfirm,
    required this.onMoveLeft,
    required this.onMoveRight,
  });

  final bool visible;
  final ValueChanged<MathKey> onKeyPressed;
  final VoidCallback onBackspace;
  final VoidCallback onConfirm;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 300,
          child: _NumericPad(
            onKeyPressed: onKeyPressed,
            onBackspace: onBackspace,
            onConfirm: onConfirm,
            onMoveLeft: onMoveLeft,
            onMoveRight: onMoveRight,
          ),
        ),
      ),
    );
  }
}

class _NumericPad extends StatelessWidget {
  const _NumericPad({
    required this.onKeyPressed,
    required this.onBackspace,
    required this.onConfirm,
    required this.onMoveLeft,
    required this.onMoveRight,
  });

  final ValueChanged<MathKey> onKeyPressed;
  final VoidCallback onBackspace;
  final VoidCallback onConfirm;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;

  static const String _moveLeftToken = '__move_left__';
  static const String _moveRightToken = '__move_right__';

  @override
  Widget build(BuildContext context) {
    const keys = <MathKey?>[
      MathKey('7'),
      MathKey('8'),
      MathKey('9'),
      MathKey('/'),
      MathKey('^()', cursorOffset: 2),
      MathKey('root(){}', cursorOffset: 5),
      MathKey('4'),
      MathKey('5'),
      MathKey('6'),
      MathKey('*'),
      MathKey('π'),
      MathKey('e'),
      MathKey('1'),
      MathKey('2'),
      MathKey('3'),
      MathKey('-'),
      MathKey('('),
      MathKey(')'),
      MathKey('0'),
      MathKey(_moveLeftToken),
      MathKey(_moveRightToken),
      MathKey('+'),
      MathKey('.'),
      null,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 360 ? 6 : 4;

        return Column(
          children: <Widget>[
            Expanded(
              child: GridView.count(
                crossAxisCount: columns,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.2,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                children: <Widget>[
                  for (final key in keys)
                    key == null
                        ? const SizedBox.shrink()
                        : key.text == _moveLeftToken
                            ? _KeyButton(
                                onPressed: onMoveLeft,
                                child: const Icon(Icons.chevron_left),
                              )
                            : key.text == _moveRightToken
                                ? _KeyButton(
                                    onPressed: onMoveRight,
                                    child: const Icon(Icons.chevron_right),
                                  )
                                : _KeyButton(
                                    label: _labelForKey(key),
                                    onPressed: () => onKeyPressed(key),
                                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _KeyButton(
                      onPressed: onBackspace,
                      child: const Icon(Icons.backspace_outlined),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KeyButton(
                      label: 'Siguiente',
                      onPressed: onConfirm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _labelForKey(MathKey key) {
    if (key.text == '^()') {
      return 'xⁿ';
    }
    if (key.text == 'root(){}') {
      return 'ⁿ√';
    }
    return key.text;
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    this.label,
    this.child,
    required this.onPressed,
  });

  final String? label;
  final Widget? child;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(14);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Focus(
        canRequestFocus: false,
        descendantsAreFocusable: false,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: borderRadius,
            ),
            child: InkWell(
              onTap: onPressed,
              canRequestFocus: false,
              borderRadius: borderRadius,
              splashFactory: NoSplash.splashFactory,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              child: Center(
                child: child ?? Text(label ?? '', textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
