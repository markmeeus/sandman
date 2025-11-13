const ScrollToTop = {
  mounted() {
    this.handleEvent("scroll-to-top", () => {
      this.el.scrollTop = 0;
    });
  }
};

export default ScrollToTop;

