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
    window.addEventListener('keydown', (event) => {
      // Check if Ctrl (or Command on Mac) key is pressed and the "+" key is pressed
      if ((event.ctrlKey || event.metaKey)) {
        if(event.key === "+" || event.key === "=" || event.Code === "Equal"){
          currentZoom = parseInt(document.documentElement.style.zoom) || 100;
          document.documentElement.style.zoom = `${currentZoom * 1.1}%`;
          event.preventDefault();
        }
        else if(event.key === "-" || event.code === "Minus") {
          currentZoom = parseInt(document.documentElement.style.zoom) || 100;
          document.documentElement.style.zoom = `${currentZoom / 1.1}%`;
          event.preventDefault();
        }else {
          //this.pushEvent("ctrl-key", {key: event.key, code: event.code});
        }



      }
    });
  }
}

export default HomeHook;