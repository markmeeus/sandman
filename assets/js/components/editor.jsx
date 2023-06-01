import React from "react";
import MonacoEditor from 'react-monaco-editor';

function resize(editor, id) {
  let container = document.getElementById(`editor-${id}`);
  // grab child element
  container = container.querySelector('.react-monaco-editor-container');
  if(editor) {
    console.log('ed:', editor);
    const height = (editor.getModel().getLineCount() + 0) * 21;
    container.style.height = `${height}px`;
    editor.layout();
  }
}
class Editor extends React.Component {
  constructor(props) {
    super(props);
    this.monacoRef= React.createRef();
    this.state = {
      code: props.code,
      id: props.id
    }
  }
  editorDidMount(editor, monaco) {
    this.editor = editor;
    console.log('editorDidMount', editor);
    resize(this.editor, this.state.id);
    editor.focus();
  }
  onChange(newValue, e) {
    console.log('onChange', newValue, e);
    resize(this.editor, this.state.id);
  }
  render() {
    const code = this.state.code;
    const options = {
      value: code,
      minimap: {
        enabled: false
      },
      language: 'lua',
      fontSize: '14px',
      fontWeight: "bold",
      theme: 'vs-dark',
      //automaticLayout: true,
      scrollBeyondLastLine: false
    };
    return (
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

    );
  }
}

export default Editor;