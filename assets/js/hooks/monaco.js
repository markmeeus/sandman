import * as monaco from "monaco-editor";

let insideObserver = false;

function trackSize(editor, container, resize){
  editor.onDidChangeHiddenAreas(()=>{
    // changing collapsible code block
    resize();
  });
  new ResizeObserver(()=>{
    if(!insideObserver){
      insideObserver = true;
      resize()
      insideObserver = false;
    }

  }).observe(container);
}

function resize(editor, container) {
  const contentHeight = editor.getContentHeight();
  container.style.height = `${contentHeight + 2}px`;
  editor.layout();
}

const MonacoHook = {
  mounted() {
    code = this.el.innerText;
    const blockId = this.el.dataset.blockId;
    this.el.innerText = "";
    let editor = monaco.editor.create(this.el, {
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

    // send changes to backend
    editor.getModel().onDidChangeContent((changeEvent)=>{
      const event = new Event('sandman:code-changed');
      event.data = {value: editor.getValue(), blockId};
      window.dispatchEvent(event);
      resize(editor, this.el);
    });

    // keep track of sizing
    trackSize(editor, this.el, () => {
      resize(editor, this.el);
    })
    // set initial size
    resize(editor, this.el);
  }
}

export default MonacoHook;