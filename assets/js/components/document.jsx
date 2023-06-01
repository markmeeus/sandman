import React from "react";
import Editor from './editor';
import MarkDownEditor from './markdown';

// initial document ...
window.sandman = {
  document: {
    blocks: [
      {id: 1, type:'md', code: '# Sandman, helps you rest.'},
      {id: 1, type:'lua', code: 'print("hello world")'}
    ]
  }
}

const Document = (props) => {
  return (<>
  {window.sandman?.document.blocks.map(block => {
    if(block.type === 'lua') {
      return <Editor block={block}/>;
    }else{
      return <MarkDownEditor block={block} />;
    }
  })}
  </>);
}

export default Document;