import React, { useState } from "react";
import Editor from './editor';
import MarkDownEditor from './markdown';

// initial document ...
window.sandman = {
  document: {
    blocks: [
      {id: 1, type:'md', code: '# Start with a reuest.'},
      {id: 2, type:'lua', code: 'http.get("http://google.com")'}
    ]
  }
}

const Document = (props) => {
  const [document, setDocument] = useState(window.sandman.document);

  const onNewBlock = (type) => {
    window.sandman.document.blocks.push({id: window.sandman.document.blocks.length +1, type:type, code: ""});
    // Dirty of me to keep the doc in the windod ...
    // even more dirty that I need this to render (could also use a counter to bruteforce rerendering here)
    setDocument({...window.sandman.document});
  }

  return (<>
  {window.sandman?.document.blocks.map(block => {
    if(block.type === 'lua') {
      console.log("usin ke", block.id)
      return <Editor key={block.id} block={block}/>;
    }else{
      console.log("usin ke", block.id)
      return <MarkDownEditor key={block.id} block={block} />;
    }
  })}
  <button onClick={()=>onNewBlock('lua')}>New block</button>
  </>);
}

export default Document;