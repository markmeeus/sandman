import Split from 'split.js';

const DocumentHook = {
  mounted() {
    window.addEventListener("sandman:code-changed", e => {
      this.pushEvent("code-changed", e.data)
    });
  }
}

export default DocumentHook;