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

    // Register handler for focus events from LiveView
    this.handleEvent("focus-block", (payload) => {
      this.focusBlock(payload["block-id"]);
    });

    // Store reference to this hook instance for focus commands
    window.documentHook = this;
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