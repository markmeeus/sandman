import Split from 'split.js';

const HomeHook = {
  mounted() {
    Split(['#document-container', '#req-res-container'], {
      direction: 'horizontal',
      minSize: [400, 80],
      gutter: (index, diretion) => {
        return document.getElementById('doc-req-gutter');
      },
      gutterStyle: () => {
        return {
          'background-color': '#CCC',
          width: "4px",
        }
      }
    });
  }
}

export default HomeHook;