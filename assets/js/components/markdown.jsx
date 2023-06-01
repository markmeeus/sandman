import React from "react";
import ReactMarkdown from 'react-markdown';

const MarkDownEditor = () => {
  return <ReactMarkdown>
    {'# Hello, *world*!\n* een\n* twee'}
  </ReactMarkdown>;
}

export default MarkDownEditor;