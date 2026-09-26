import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<bool> insertNewLineInType(
  EditorState editorState,
  String type, {
  Attributes attributes = const {},
}) async {
  // check if the shift key is pressed, if so, we should return false to let the system handle it.
  final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
  if (isShiftPressed) {
    return false;
  }

  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return false;
  }

  final node = editorState.getNodeAtPath(selection.end.path);
  final delta = node?.delta;
  if (node?.type != type || delta == null) {
    return false;
  }

  final plainText = delta.toPlainText();
  final isEffectivelyEmpty = delta.isEmpty || plainText.trim().isEmpty;

  if (isEffectivelyEmpty) {
    // clear the style
    if (node != null && node.path.length > 1) {
      return KeyEventResult.ignored != outdentCommand.execute(editorState);
    }

    final textDirection = node?.attributes[blockComponentTextDirection];
    final transaction = editorState.transaction;
    final pNode = paragraphNode(
      attributes: {
        ParagraphBlockKeys.delta: Delta().toJson(),
      },
      textDirection: textDirection,
      children: node?.children.map((e) => e.deepCopy()).toList() ?? [],
    );
    transaction
      ..insertNode(node!.path, pNode)
      ..deleteNode(node)
      ..afterSelection = Selection.collapsed(
        Position(path: node.path, offset: 0),
      );
    await editorState.apply(transaction);

    return true;
  }

  await editorState.insertNewLine(
    nodeBuilder: (node) => node.copyWith(
      type: type,
      attributes: {
        ...node.attributes,
        ...attributes,
      },
    ),
  );

  return true;
}
