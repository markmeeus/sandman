import Split from 'split.js';

const HomeHook = {
  mounted() {
    Split(['#document-log-container', '#req-res-container'], {
      direction: 'horizontal',
      minSize: [400, 80],
      gutterStyle: () => {
        return {
          'background-color': '#CCC',
          width: "2px"
        }
      }
    });


    Split(['#document-container', '#log-container'], {
      direction: 'vertical',
      minSize: [40, 80],
      gutterSize: 2,
      gutterStyle: () => {
        return {
          'background-color': '#CCC',
          height: "2px"
        }
      }
    });
  }
}

export default HomeHook;