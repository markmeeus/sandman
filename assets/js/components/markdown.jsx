import React from "react";
import ReactMarkdown from 'react-markdown';

const MarkDownEditor = (props) => {
  return <div className="flex rounded m-5 pb-5 border-b-2"
  style={{marginLeft:"40px"}}>
    <ReactMarkdown>
      {props.block.code}
    </ReactMarkdown>
  </div>;
}

export default MarkDownEditor;