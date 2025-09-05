import React from "react";
// this import is important, otherwise syntax highlighting is broken ...
import * as monaco from "monaco-editor";
import MonacoEditor from 'react-monaco-editor';

function observeResize(editor, id){
  let container = document.getElementById(`editor-${id}`);
  editor.onDidChangeHiddenAreas(()=>{
    // changing collapsible code block
    resize(editor, id);
  });
  new ResizeObserver(()=>resize(editor, id)).observe(container)
}
function resize(editor, id) {
  let container = document.getElementById(`editor-${id}`);
  // grab child element
  const reactMonacoContainer = container.querySelector('.react-monaco-editor-container');
  if(editor) {
    console.log('ed:', editor);

    const height = ((editor.getModel().getLineCount() + 0) * 21) + 12;
    container.style.height = `${height + 4}px`;
    //container.style.width = container.offsetWidth;
    reactMonacoContainer.style.height = `${height}px`;

    const contentHeight = editor.getContentHeight();
    container.style.height = `${contentHeight + 2}px`;
    reactMonacoContainer.style.height = `${contentHeight + 2}px`;
    editor.layout();
  }
}
class Editor extends React.Component {
  constructor(props) {
    super(props);
    this.monacoRef= React.createRef();
    this.state = {
      code: props.block.code,
      id: props.block.id
    }
  }
  editorDidMount(editor, monaco) {
    this.editor = editor;
    console.log('editorDidMount', editor);
    resize(this.editor, this.state.id);
    observeResize(editor, this.state.id);
  }
  onChange(newValue, e) {
    resize(this.editor, this.state.id);
  }
  evaluate(stepsToRun) {
    window.sandman.sandmanDocument.blocks[this.state.id - 1].code = this.editor.getValue();
    const event = new Event('sandman:run-block');
    event.data = {
      doc: window.sandman.sandmanDocument,
      block_id: this.state.id,
      stepsToRun: stepsToRun
    };
    window.dispatchEvent(event);
  }
  render() {
    const code = this.state.code;
    const options = {
      value: code,
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
      //automaticLayout: true,
      scrollBeyondLastLine: false
    };

    return (
      <div className="my-1 pt-1 pb-5 border-b-2">
        <div className="flex flex-row fs-2 mb-1 text-sm" >
            <button onClick={()=>this.evaluate.bind(this)("upto")} ><span>▶</span> Run</button>
            <button className="mx-2" onClick={()=>this.evaluate.bind(this)("only-this")} ><span>▶▶</span>From top</button>
          </div>
        <div className="rounded-t p-2" style={{backgroundColor: "#1E1E1E"}}>
          <div id={`editor-${this.state.id}`}>
            <MonacoEditor
              language="lua"
              theme="vs-dark"
              value={code}
              options={options}
              onChange={this.onChange.bind(this)}
              editorDidMount={this.editorDidMount.bind(this)}
              autoLayout={true}
            />
          </div>
        </div>
        <div class="flex flex-col">
          <div class="flex flex-row-reverse text-xs rounded-b pb-1 px-1" style={{backgroundColor: "#EEEEEE"}}>
            <a href="#" class="mt-1 text-emerald-600">&nbsp;2xx</a>
            <a href="#" class="mt-1">3 requests</a>
          </div>
          <div class="flex flex-row-reverse text-xs rounded-b pb-1 px-1" style={{backgroundColor: "#EEEEEE"}}>
            <a href="#" class="mt-1 text-emerald-600">&nbsp;302</a>
            <a href="#" class="mt-1">1 request</a>
          </div>
          <div class="flex flex-row-reverse text-xs rounded-b pb-1 px-1" style={{backgroundColor: "#EEEEEE"}}>
            <a href="#" class="mt-1 text-red-700">&nbsp;500</a>
            <a href="#" class="mt-1">GET https://test.com</a>
          </div>
        </div>

      </div>
    );
  }
}

export default Editor;