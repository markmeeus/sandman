const MaintainHeight = {
  beforeUpdate() {
    this.prevHeight = this.el.style.height;
  },
  updated() {
    this.el.style.height = this.prevHeight;
  }
}

const MaintainWidth = {
  beforeUpdate() {
    this.prevWidth = this.el.style.width;
  },
  updated() {
    this.el.style.width = this.prevWidth;
  }
}

export default {
  MaintainHeight, MaintainWidth
};
