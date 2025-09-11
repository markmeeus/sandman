import * as monaco from "monaco-editor";
import globalUndoManager from "../globalUndo";


function trackSize(editor, container, resize){
  editor.onDidChangeHiddenAreas(()=>{
    // changing collapsible code block
    resize();
  });
  new ResizeObserver(()=>{
    if(!this.insideObserver){
      this.insideObserver = true;
      resize()
      this.insideObserver = false;
    }

  }).observe(container);
}

function resize(editor, container) {
  const contentHeight = editor.getContentHeight();
  container.style.height = `${contentHeight + 2}px`;
  editor.layout();
}

function decodeHtml(html) {
  var txt = document.createElement("textarea");
  txt.innerHTML = html;
  return txt.value;
}

const MonacoHook = {
  mounted() {
    const code = decodeHtml(this.el.innerHTML);
    const blockId = this.el.dataset.blockId;
    this.el.innerText = "";
    let editor = monaco.editor.create(this.el, {
    	value: code,
      language: 'lua',
      glyphMargin: true,
    	minimap: {
    		enabled: false
    	},
      scrollbar: {
        alwaysConsumeMouseWheel: false,
        enabled: false,
      },
      fontSize: '12px',
      //fontWeight: '600',
      theme: 'vs-dark',
      renderLineHighlight: "none",
      overviewRulerBorder: false,
      overviewRulerLanes: 0,
      scrollBeyondLastLine: false,
      lineNumbersMinChars: 2
    });

    // Register with global undo manager
    globalUndoManager.registerEditor(blockId, editor);

    // Track focus state manually
    let editorHasFocus = false;

    editor.onDidFocusEditorText(() => {
      editorHasFocus = true;
      // Send cursor-moved event when editor gains focus
      const event = new Event('sandman:cursor-moved');
      event.data = { blockId };
      window.dispatchEvent(event);
    });

    editor.onDidBlurEditorText(() => {
      editorHasFocus = false;
    });

    // Send cursor-moved event when cursor position changes within the editor
    editor.onDidChangeCursorPosition(() => {
      if (editorHasFocus) {
        const event = new Event('sandman:cursor-moved');
        event.data = { blockId };
        window.dispatchEvent(event);
      }
    });

    // Add keyboard shortcuts using DOM events instead of Monaco commands
    const editorDomNode = editor.getDomNode();
    editorDomNode.addEventListener('keydown', (e) => {
      // ESC - remove focus from editor while keeping block selected
      if (e.key === 'Escape' && editorHasFocus) {
        e.preventDefault();
        document.activeElement.blur();
      }
    });

    // send changes to backend
    editor.getModel().onDidChangeContent((changeEvent)=>{
      const event = new Event('sandman:code-changed');
      event.data = {value: editor.getValue(), blockId};
      window.dispatchEvent(event);
      resize(editor, this.el);
    });

    function addDecorations(decorations, countsPerLine, stats, statType) {
      stats.forEach(stat => {
        let count = countsPerLine[stat.line_nr];
        if(count > 9){
          count = '9p';
        } else {
          count = count.toString();
        }
        decorations.push({
          range: new monaco.Range(stat.line_nr, 0, stat.line_nr, 0),
          options: {
            isWholeLine: true,
            className: `line-has-requests ${statType}`,
            glyphMarginClassName: `has-requests ${statType} request-count-${count}`,
          },
        });
      });
    }
    // this.handleEvent(`monaco-highlight-id${blockId}`, ({line_number}) => {

    // });
    this.handleEvent(`monaco-update-selected`, ({block_id, selected}) => {

      // remove old decorations
      if(this.oldDecorationsCollection && this.oldDecorationsCollection.length > 0){
        editor.removeDecorations(this.oldDecorationsCollection._decorationIds);
      }

      // not for this block
      if(blockId != block_id) return;

      const decorations = this.oldDecorations || [];
      decorations.forEach(({range, options}) => {
        if(range.startLineNumber === selected.line_nr && blockId === blockId) {
          options.className += " highlighted"
        } else {
          options.className = options.className.replaceAll("highlighted", "")
        }
      })

      this.oldDecorationsCollection = editor.createDecorationsCollection(decorations);
      this.oldDecorations = decorations;
    });

    this.handleEvent(`monaco-update-${blockId}`, ({stats}) => {
      let countsPerLine = new Map();
      stats.ok.forEach(stat => {
        countsPerLine[stat.line_nr] = countsPerLine[stat.line_nr] + 1 || 1;
      });
      stats.warn.forEach(stat => {
        countsPerLine[stat.line_nr] = countsPerLine[stat.line_nr] + 1 || 1;
      });
      stats.error.forEach(stat => {
        countsPerLine[stat.line_nr] = countsPerLine[stat.line_nr] + 1 || 1;
      });

      const decorations = [];
      addDecorations(decorations, countsPerLine, stats.ok, "ok");
      addDecorations(decorations, countsPerLine, stats.warn, "warn");
      addDecorations(decorations, countsPerLine, stats.error, "error");

      if(this.oldDecorationsCollection && this.oldDecorationsCollection.length > 0){
        editor.removeDecorations(this.oldDecorationsCollection._decorationIds);
      }

      this.oldDecorationsCollection = editor.createDecorationsCollection(decorations);
      this.oldDecorations = decorations;

      console.log(this.oldDecorations, this.oldDecorations[0]);
      //below is the glyph I am calling
      // var decorations = editor.createDecorationsCollection([
      //   {
      //     range: new monaco.Range(2, 0, 2, 0),
      //     options: {
      //       isWholeLine: true,
      //       className: "line-has-requests ok",
      //       glyphMarginClassName: "has-requests ok request-count-1",
      //     },
      //   },
      //   // {
        //   range: new monaco.Range(3, 1, 3, 1),
        //   options: {
        //     isWholeLine: true,
        //     className: "line-has-requests error",
        //     glyphMarginClassName: "has-requests error request-count-9p",
        //   },
        // },
        // {
        //   range: new monaco.Range(4, 1, 4, 1),
        //   options: {
        //     isWholeLine: true,
        //     className: "line-has-requests warn",
        //     glyphMarginClassName: "has-requests warn request-count-4",
        //   },
        // }
    //   ]);
    })


    // keep track of sizing
    trackSize(editor, this.el, () => {
      resize(editor, this.el);
    })
    // set initial size
    resize(editor, this.el);

    // Store references for cleanup
    this.editor = editor;
    this.blockId = blockId;
  },

  destroyed() {
    // Unregister from global undo manager
    if (this.blockId) {
      globalUndoManager.unregisterEditor(this.blockId);
    }

    // Dispose of Monaco editor
    if (this.editor) {
      this.editor.dispose();
    }
  }
}

export default MonacoHook;