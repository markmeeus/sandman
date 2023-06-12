import Split from 'split.js';

const HomeHook = {
  mounted() {
    Split(['#document-log-container', '#req-res-container'], {
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


    Split(['#document-container', '#log-container'], {
      direction: 'vertical',
      minSize: [40, 80],
      gutterSize: 12,
      gutter: (index, diretion) => {
        return document.getElementById('doc-log-gutter');
      },
      gutterStyle: () => {
        return {
          'background-color': '#CCC',
          height: "4px",
        }
      }
    });
  }
}

export default HomeHook;