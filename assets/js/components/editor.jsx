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
    container.style.height = `${height + 16}px`;
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
  evaluate(e) {
    window.sandman.document.blocks[this.state.id - 1].code = this.editor.getValue();
  }
  render() {
    const code = this.state.code;
    const options = {
      value: code,
      minimap: {
        enabled: false
      },
      // scrollbar: {
      //   alwaysConsumeMouseWheel: false
      // },
      //language: 'lua',
      fontSize: '14px',
      fontWeight: "bold",
      theme: 'vs-dark',
      //automaticLayout: true,
      scrollBeyondLastLine: false
    };

    return (
      <div className="block rounded" style={{margin:"40px", padding:"8px", backgroundColor: "#1E1E1E"}}>
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
        <div className="block flex flex-row flex-row-reverse flex-directio fs-2 text-sm text-white" >
          <button onClick={this.evaluate.bind(this)} ><span>▶</span> Save & Run</button>
        </div>
      </div>

    );
  }
}

export default Editor;