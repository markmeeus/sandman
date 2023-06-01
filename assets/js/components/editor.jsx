import React from "react";
// this import is important, otherwise syntax highlighting is broken ...
import * as monaco from "monaco-editor";
import MonacoEditor from 'react-monaco-editor';

function resize(editor, id) {
  let container = document.getElementById(`editor-${id}`);
  // grab child element
  const reactMonacoContainer = container.querySelector('.react-monaco-editor-container');
  if(editor) {
    console.log('ed:', editor);
    const height = (editor.getModel().getLineCount() + 0) * 21;
    container.style.height = `${height + 4}px`;
    reactMonacoContainer.style.height = `${height}px`;
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
    //editor.focus();
  }
  onChange(newValue, e) {
    resize(this.editor, this.state.id);
  }
  evaluate(stepsToRun) {
    window.sandman.document.blocks[this.state.id - 1].code = this.editor.getValue();
    const event = new Event('sandman:run-block');
    event.data = {
      doc: window.sandman.document,
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
        alwaysConsumeMouseWheel: false
      },
      fontSize: '14px',
      fontWeight: "bold",
      theme: 'vs-dark',
      //automaticLayout: true,
      scrollBeyondLastLine: false
    };

    return (
      <div className="m-5 p-5 border-b-2">
        <div className="flex flex-row fs-2 mb-4 text-sm" >
            <button onClick={()=>this.evaluate.bind(this)("upto")} ><span>▶</span> Run Up To This Step</button>
            <button class="mx-2" onClick={()=>this.evaluate.bind(this)("only-this")} ><span>▶</span> This Step Only</button>
          </div>
        <div className="rounded p-2" style={{backgroundColor: "#1E1E1E"}}>

          <div id={`editor-${this.state.id}`}>
            <MonacoEditor
              language="lua"
              theme="vs-dark"
              value={code}
              options={options}
              onChange={this.onChange.bind(this)}
              editorDidMount={this.editorDidMount.bind(this)}
            />
          </div>
        </div>
      </div>
    );
  }
}

export default Editor;