import Split from 'split.js';

const MaintainDimensions = {
  beforeUpdate() {
    this.prevHeight = this.el.style.height;
    this.prevWidth = this.el.style.Width;
  },
  updated() {
    this.el.style.height = this.prevHeight;
    this.el.style.width = this.prevWidth;
  }
}

export default MaintainDimensions;