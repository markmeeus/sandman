import React from "react";
import ReactMarkdown from 'react-markdown';

const MarkDownEditor = () => {
  return <div className="flex rounded"
  style={{margin:"40px", padding:"8px"}}>
    <ReactMarkdown>
      {'# Hello, *world*!\n\n* een\n* twee'}
    </ReactMarkdown>
  </div>;
}

export default MarkDownEditor;