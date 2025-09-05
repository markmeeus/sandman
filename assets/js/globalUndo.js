import * as monaco from "monaco-editor";
/**
 * Global Undo/Redo Manager for Multiple Monaco Editors
 * Handles undo/redo operations across all editors on the page
 */

class GlobalUndoManager {
  constructor() {
    this.undoStack = [];
    this.redoStack = [];
    this.maxStackSize = 100;
    this.isApplyingOperation = false;
    this.editors = new Map(); // blockId -> editor instance

    // Bind keyboard shortcuts
    this.bindKeyboardShortcuts();
  }

  /**
   * Register a Monaco editor with the global undo manager
   */
  registerEditor(blockId, editor) {
    this.editors.set(blockId, editor);

    // Disable Monaco's built-in undo/redo
    editor.updateOptions({
      readOnly: false
    });

    // Override Monaco's undo/redo commands
    editor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyZ, () => {
      this.undo();
    });

    editor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyMod.Shift | monaco.KeyCode.KeyZ, () => {
      this.redo();
    });

    editor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyY, () => {
      this.redo();
    });

    // Listen to content changes
    const model = editor.getModel();
    if (model) {
      // Store content and cursor position before changes
      let contentBeforeChange = model.getValue();
      let cursorBeforeChange = editor.getPosition();

      // Capture cursor position before any change
      editor.onDidChangeCursorPosition((event) => {
        if (!this.isApplyingOperation) {
          cursorBeforeChange = event.position;
        }
      });

      model.onDidChangeContent((event) => {
        if (!this.isApplyingOperation) {
          this.recordOperationImmediate(blockId, contentBeforeChange, model.getValue(), cursorBeforeChange);
        }
        // Update for next change
        contentBeforeChange = model.getValue();
        cursorBeforeChange = editor.getPosition();
      });
    }
  }

  /**
   * Unregister an editor (when it's destroyed)
   */
  unregisterEditor(blockId) {
    this.editors.delete(blockId);

    // Clean up any operations for this editor from the stacks
    this.undoStack = this.undoStack.filter(op => op.blockId !== blockId);
    this.redoStack = this.redoStack.filter(op => op.blockId !== blockId);
  }

  /**
   * Record a change operation for global undo (immediate version)
   */
  recordOperationImmediate(blockId, beforeContent, afterContent, cursorBeforeChange) {
    // Only record if content actually changed
    if (beforeContent === afterContent) return;

    // Create operation record
    const operation = {
      blockId,
      timestamp: Date.now(),
      beforeContent,
      afterContent,
      cursorBeforeChange // Store the cursor position where the change originated
    };

    // Add to undo stack
    this.undoStack.push(operation);

    // Clear redo stack when new operation is recorded
    this.redoStack = [];

    // Limit stack size
    if (this.undoStack.length > this.maxStackSize) {
      this.undoStack.shift();
    }
  }


  /**
   * Perform global undo
   */
  undo() {
    if (this.undoStack.length === 0) return;

    const operation = this.undoStack.pop();
    this.redoStack.push(operation);

    // Focus the editor where the undo is happening (if not already focused)
    this.focusEditorIfNeeded(operation.blockId);

    this.applyInverseOperation(operation);
  }

  /**
   * Perform global redo
   */
  redo() {
    if (this.redoStack.length === 0) return;

    const operation = this.redoStack.pop();
    this.undoStack.push(operation);

    // Focus the editor where the redo is happening (if not already focused)
    this.focusEditorIfNeeded(operation.blockId);

    this.applyOperation(operation);
  }

  /**
   * Apply an operation (for redo)
   */
  applyOperation(operation) {
    const editor = this.editors.get(operation.blockId);
    if (!editor) return;

    const model = editor.getModel();
    if (!model) return;

    this.isApplyingOperation = true;

    try {
      // Store current cursor position
      const position = editor.getPosition();
      const selection = editor.getSelection();

      // Set the content
      model.setValue(operation.afterContent);

      // Restore cursor position if possible
      this.restoreCursorPosition(editor, position, selection, operation);

      // Trigger the backend update
      this.triggerBackendUpdate(operation.blockId, operation.afterContent);

    } finally {
      this.isApplyingOperation = false;
    }
  }

  /**
   * Apply inverse operation (for undo)
   */
  applyInverseOperation(operation) {
    const editor = this.editors.get(operation.blockId);
    if (!editor) return;

    const model = editor.getModel();
    if (!model) return;

    this.isApplyingOperation = true;

    try {
      // Store current cursor position
      const position = editor.getPosition();
      const selection = editor.getSelection();

      // Set the content to the before state
      model.setValue(operation.beforeContent);

      // Restore cursor position if possible
      this.restoreCursorPosition(editor, position, selection, operation);

      // Trigger the backend update
      this.triggerBackendUpdate(operation.blockId, operation.beforeContent);

    } finally {
      this.isApplyingOperation = false;
    }
  }


  /**
   * Focus the editor if it's not already focused
   */
  focusEditorIfNeeded(blockId) {
    const editor = this.editors.get(blockId);
    if (!editor) return;

    // Check if this editor is already focused
    const currentlyFocusedElement = document.activeElement;
    const editorDomElement = editor.getDomNode();

    // If the currently focused element is not within this editor, focus it
    if (!editorDomElement || !editorDomElement.contains(currentlyFocusedElement)) {
      editor.focus();
    }
  }

  /**
   * Restore cursor position after content change
   */
  restoreCursorPosition(editor, position, selection, operation = null) {
    try {
      const model = editor.getModel();
      if (!model) return;

      // Use the original cursor position where the change happened (for undo)
      if (operation && operation.cursorBeforeChange) {
        const originalPosition = operation.cursorBeforeChange;
        const lineCount = model.getLineCount();
        const maxLine = Math.max(1, lineCount);

        // Validate the original position is still valid
        const validLine = Math.min(originalPosition.lineNumber, maxLine);
        const lineLength = model.getLineLength(validLine);
        const validColumn = Math.min(originalPosition.column, lineLength + 1);

        editor.setPosition({
          lineNumber: validLine,
          column: validColumn
        });
        return;
      }

      // Default cursor position restoration (fallback)
      const lineCount = model.getLineCount();
      const maxLine = Math.max(1, lineCount);

      if (position) {
        const validLine = Math.min(position.lineNumber, maxLine);
        const lineLength = model.getLineLength(validLine);
        const validColumn = Math.min(position.column, lineLength + 1);

        const newPosition = {
          lineNumber: validLine,
          column: validColumn
        };

        editor.setPosition(newPosition);
      }

      // If we had a selection, try to restore it
      if (selection && (selection.startLineNumber !== selection.endLineNumber ||
          selection.startColumn !== selection.endColumn)) {

        const startLine = Math.min(selection.startLineNumber, maxLine);
        const endLine = Math.min(selection.endLineNumber, maxLine);
        const startLineLength = model.getLineLength(startLine);
        const endLineLength = model.getLineLength(endLine);

        const newSelection = {
          startLineNumber: startLine,
          startColumn: Math.min(selection.startColumn, startLineLength + 1),
          endLineNumber: endLine,
          endColumn: Math.min(selection.endColumn, endLineLength + 1)
        };

        editor.setSelection(newSelection);
      }
    } catch (error) {
      // If restoration fails, just place cursor at the end
      const model = editor.getModel();
      if (model) {
        const lineCount = model.getLineCount();
        const lastLineLength = model.getLineLength(lineCount);
        editor.setPosition({
          lineNumber: lineCount,
          column: lastLineLength + 1
        });
      }
    }
  }

  /**
   * Trigger backend update (same as the original Monaco hook)
   */
  triggerBackendUpdate(blockId, value) {
    const event = new Event('sandman:code-changed');
    event.data = { value, blockId };
    window.dispatchEvent(event);
  }

  /**
   * Bind global keyboard shortcuts
   */
  bindKeyboardShortcuts() {
    document.addEventListener('keydown', (event) => {
      // Only handle if not inside an input/textarea (but allow Monaco editors)
      const target = event.target;
      const isInInput = target.tagName === 'INPUT' || target.tagName === 'TEXTAREA';
      const isInMonaco = target.closest('.monaco-editor') !== null;

      if (isInInput && !isInMonaco) return;

      const isCtrlCmd = event.ctrlKey || event.metaKey;

      if (isCtrlCmd && event.key === 'z' && !event.shiftKey) {
        event.preventDefault();
        this.undo();
      } else if (isCtrlCmd && ((event.key === 'z' && event.shiftKey) || event.key === 'y')) {
        event.preventDefault();
        this.redo();
      }
    });
  }

  /**
   * Clear all undo/redo history
   */
  clearHistory() {
    this.undoStack = [];
    this.redoStack = [];
  }

  /**
   * Get current state info (for debugging)
   */
  getState() {
    return {
      undoStackSize: this.undoStack.length,
      redoStackSize: this.redoStack.length,
      registeredEditors: Array.from(this.editors.keys())
    };
  }
}

// Create global instance
window.globalUndoManager = new GlobalUndoManager();

export default window.globalUndoManager;
