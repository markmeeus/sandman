import React from "react";
import ReactMarkdown from 'react-markdown';

const MarkDownEditor = (props) => {
  return <div className="flex rounded"
  style={{margin:"40px", padding:"8px"}}>
    <ReactMarkdown>
      {props.block.code}
    </ReactMarkdown>
  </div>;
}

export default MarkDownEditor;