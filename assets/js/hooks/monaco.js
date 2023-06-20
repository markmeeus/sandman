import * as monaco from "monaco-editor";


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

const MonacoHook = {
  mounted() {
    const code = this.el.innerHTML;
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
      fontSize: '12px',
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