import Split from 'split.js';

const DocumentHook = {
  mounted() {
    window.addEventListener("sandman:code-changed", e => {
      this.pushEvent("code-changed", e.data)
    });

    // Listen for request selection events from LiveView
    this.handleEvent("request-selected", (data) => {
      this.selectRequestRow(data.block_id, data.request_index);
    });
  },

  selectRequestRow(blockId, requestIndex) {
    // Remove any existing selections
    document.querySelectorAll('.request-row-selected').forEach(el => {
      el.classList.remove('request-row-selected');
    });

    // Find and select the specific request row
    const requestRow = document.querySelector(
      `.request-row[data-block-id="${blockId}"][data-request-index="${requestIndex}"]`
    );

    if (requestRow) {
      requestRow.classList.add('request-row-selected');
    }
  }
}

export default DocumentHook;