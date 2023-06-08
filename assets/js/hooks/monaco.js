import * as monaco from "monaco-editor";

function observeResize(editor, container){
  editor.onDidChangeHiddenAreas(()=>{
    // changing collapsible code block
    resize(editor, container);
  });
}
function resize(editor, container) {
  const contentHeight = editor.getContentHeight();
  container.style.height = `${contentHeight + 2}px`;
  editor.layout();
}

const MonacoHook = {
  mounted() {
    code = this.el.innerText;
    this.el.innerText = "";
    editor = monaco.editor.create(this.el, {
    	value: code,
      language: 'lua',
    	minimap: {
    		enabled: false
    	},
      scrollbar: {
        alwaysConsumeMouseWheel: false,
        enabled: false,
      },
      fontSize: '14px',
      fontWeight: "bold",
      theme: 'vs-dark',
      renderLineHighlight: "none",
      overviewRulerBorder: false,
      overviewRulerLanes: 0,
      scrollBeyondLastLine: false
    });
    editor.getModel().onDidChangeContent(()=>resize(editor, this.el));
    resize(editor, this.el);
    observeResize(editor, this.el);
  }
}

export default MonacoHook;