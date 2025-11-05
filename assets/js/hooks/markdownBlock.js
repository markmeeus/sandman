const MarkdownBlockHook = {
  mounted() {
    this.updateLinks();
  },

  updated() {
    this.updateLinks();
  },

  updateLinks() {
    // Find all links within this markdown block and add target="_blank"
    const links = this.el.querySelectorAll('a');
    links.forEach(link => {
      link.setAttribute('target', '_blank');
      link.setAttribute('rel', 'noopener noreferrer');
    });
  }
};

export default MarkdownBlockHook;

