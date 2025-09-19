import React, { useState, useEffect } from "react";
import Editor from './editor';
import MarkDownEditor from './markdown';

// initial document ...
window.sandman = {
}
//


const Document = (props) => {

  const [sandmanDocument, setDocument] = useState(window.sandman.sandmanDocument);

  useEffect(() => {
    window.addEventListener(`phx:document_event`, (e) => {
      if(e.detail.type === 'loaded') {
        window.sandman.sandmanDocument = e.detail.document;
        setDocument({...window.sandman.sandmanDocument});
      }
    })
  });



  const onNewBlock = (type) => {
    window.sandman.sandmanDocument.blocks.push({id: window.sandman.sandmanDocument.blocks.length +1, type:type, code: ""});
    // Dirty of me to keep the doc in the windod ...
    // even more dirty that I need this to render (could also use a counter to bruteforce rerendering here)
    setDocument({...window.sandman.sandmanDocument});
  }

  if(!sandmanDocument) {
    return <></>
  }
  return (<>
    <>
      {window.sandman?.sandmanDocument.blocks.map(block => {
        if(block.type === 'lua') {
          return <Editor key={block.id} block={block}/>;
        }else{
          return <MarkDownEditor key={block.id} block={block} />;
        }
      })}
    <button onClick={()=>onNewBlock('lua')}>New block</button>
  </>

  </>);
}

export default Document;