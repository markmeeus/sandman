const RunnerHook = {
  mounted() {
    window.addEventListener("sandman:run-block", e => {
      this.pushEvent("run-block", e.data)
    });
  }
}

export default RunnerHook;