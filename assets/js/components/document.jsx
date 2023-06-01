import React from "react";
import Editor from './editor';
import MarkDownEditor from './markdown';
const Document = (props) => {
  return <>
    <Editor code="e1" id="1"/>
    <Editor code="e2" id="2"/>
    <MarkDownEditor></MarkDownEditor>
    <Editor code="e3" id="3"/>
  </>
}

export default Document;