
const TitleForm = {
  mounted() {
    this.el.addEventListener('submit', (e) => {
      e.preventDefault();
      return false;
    });
    const input = this.el.getElementsByTagName('input')[0];
    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        e.preventDefault();
        return false;
      }
    });
  }
}

export default TitleForm;