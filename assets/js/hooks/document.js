import Split from 'split.js';

const DocumentHook = {
  mounted() {
    window.addEventListener("sandman:code-changed", e => {
      this.pushEvent("code-changed", e.data)
    });

    // Handle keyboard shortcuts - send to LiveView for validation and execution
    window.addEventListener("sandman:shortcut", e => {
      this.pushEvent("shortcut", {
        "type": e.data.type,
        "block-id": e.data.blockId
      });
    });

    // Handle cursor movement events
    window.addEventListener("sandman:cursor-moved", e => {
      this.pushEvent("cursor-moved", {
        "block-id": e.data.blockId
      });
    });

    window.addEventListener("keydown", (e) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        this.pushEvent("keydown", {key: 'Escape'});
      }
    });

    // Handle keyboard navigation when no editor is focused
    document.addEventListener("keydown", (e) => {
      // Check if any Monaco editor currently has focus
      const globalUndoManager = window.globalUndoManager;
      let anyEditorFocused = false;

      if (globalUndoManager && globalUndoManager.editors) {
        for (let [blockId, editor] of globalUndoManager.editors) {
          if (editor.hasTextFocus()) {
            anyEditorFocused = true;
            break;
          }
        }
      }

      // Handle shortcuts that work in both focused and unfocused states
      if (e.key === 'Enter') {
        if (e.ctrlKey && !e.shiftKey && !e.metaKey) {
          // Ctrl+Enter - run current block
          const blockId = this.getCurrentBlockId(anyEditorFocused);
          if (blockId) {
            this.pushEvent("shortcut", {
              "type": "run-block",
              "block-id": blockId
            });
            e.preventDefault();
          }
        }
        else if (e.shiftKey && !e.ctrlKey && !e.metaKey) {
          // Shift+Enter - run current block and move to next
          const blockId = this.getCurrentBlockId(anyEditorFocused);
          if (blockId) {
            this.pushEvent("shortcut", {
              "type": "run-block-and-next",
              "block-id": blockId
            });
            e.preventDefault();
          }
        }
        else if (e.shiftKey && (e.ctrlKey || e.metaKey)) {
          // Cmd+Shift+Enter (or Ctrl+Shift+Enter) - run all blocks from top
          const blockId = this.getCurrentBlockId(anyEditorFocused);
          if (blockId) {
            this.pushEvent("shortcut", {
              "type": "run-all-blocks",
              "block-id": blockId
            });
            e.preventDefault();
          }
        }
        else if (!e.ctrlKey && !e.shiftKey && !e.metaKey && !anyEditorFocused) {
          // Plain Enter when no editor focused - focus the selected block
          const selectedBlockElement = document.querySelector('.selected-block');

          if (selectedBlockElement) {
            // Extract block ID from the monaco wrapper element
            const wrapperElement = selectedBlockElement.querySelector('[id^="monaco-wrapper-"]');

            if (wrapperElement) {
              const blockId = wrapperElement.id.replace('monaco-wrapper-', '');

              // Send focus event to backend (for markdown blocks to switch to editor mode)
              this.pushEvent("focus-block", { "block-id": blockId });

              // For markdown blocks, wait a bit for DOM to update before focusing
              const monacoElement = wrapperElement.querySelector('[id^="monaco-"]');
              if (monacoElement && monacoElement.dataset.blockType === 'markdown') {
                setTimeout(() => {
                  this.focusBlock(blockId);
                }, 50);
              } else {
                // Focus immediately for non-markdown blocks
                this.focusBlock(blockId);
              }
              e.preventDefault();
            }
          }
        }
      }
      // Navigation keys only work when no editor is focused
      else if (!anyEditorFocused) {
        if (e.key === 'ArrowUp' && !e.ctrlKey && !e.shiftKey && !e.metaKey) {
          // Navigate to previous block
          this.pushEvent("navigate-up");
          e.preventDefault();
        }
        else if (e.key === 'ArrowDown' && !e.ctrlKey && !e.shiftKey && !e.metaKey) {
          // Navigate to next block
          this.pushEvent("navigate-down");
          e.preventDefault();
        }
      }
    });

    // Register handler for focus events from LiveView
    this.handleEvent("focus-block", (payload) => {
      this.focusBlock(payload["block-id"]);
    });

    // Store reference to this hook instance for focus commands
    window.documentHook = this;
  },

  // Get the current block ID (either focused or selected)
  getCurrentBlockId(anyEditorFocused) {
    if (anyEditorFocused) {
      // Find which editor is focused
      const globalUndoManager = window.globalUndoManager;
      if (globalUndoManager && globalUndoManager.editors) {
        for (let [blockId, editor] of globalUndoManager.editors) {
          if (editor.hasTextFocus()) {
            return blockId;
          }
        }
      }
    } else {
      // Use the selected block
      const selectedBlockElement = document.querySelector('.selected-block');
      if (selectedBlockElement) {
        const wrapperElement = selectedBlockElement.querySelector('[id^="monaco-wrapper-"]');
        if (wrapperElement) {
          return wrapperElement.id.replace('monaco-wrapper-', '');
        }
      }
    }
    return null;
  },

  // Move focus to a specific block
  focusBlock(blockId) {
    const globalUndoManager = window.globalUndoManager;
    if (globalUndoManager && globalUndoManager.editors) {
      const monacoEditor = globalUndoManager.editors.get(blockId);
      if (monacoEditor) {
        monacoEditor.focus();
      }
    }
  }
}

export default DocumentHook;