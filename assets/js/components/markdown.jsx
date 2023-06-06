import React from "react";
import ReactMarkdown from 'react-markdown';

const MarkDownEditor = (props) => {
  return <div className="flex rounded my-1 py-2 px-5 border-b-2" >
    <ReactMarkdown>
      {props.block.code}
    </ReactMarkdown>
  </div>;
}

export default MarkDownEditor;