// Hook specifically for split.js containers to maintain their dimensions
const MaintainSplitDimensions = {
  beforeUpdate() {
    // Store all CSS properties that split.js sets
    const style = this.el.style;
    this.prevStyles = {
      width: style.width,
      height: style.height,
      flexBasis: style.flexBasis,
      flexGrow: style.flexGrow,
      flexShrink: style.flexShrink,
      minWidth: style.minWidth,
      maxWidth: style.maxWidth,
      minHeight: style.minHeight,
      maxHeight: style.maxHeight
    };
  },
  updated() {
    // Restore all the properties that split.js uses
    const style = this.el.style;
    Object.entries(this.prevStyles).forEach(([prop, value]) => {
      if (value) {
        style[prop] = value;
      }
    });
  }
};

export default {
  MaintainSplitDimensions
};
