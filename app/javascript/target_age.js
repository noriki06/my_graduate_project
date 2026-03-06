document.addEventListener("turbo:load", () => {
  const avgBtn    = document.getElementById("btn-avg-life")
  const healthBtn = document.getElementById("btn-health-life")
  const input     = document.getElementById("input-target-age")

  if (!avgBtn || !healthBtn || !input) return

  avgBtn.addEventListener("click", () => { input.value = 84 })
  healthBtn.addEventListener("click", () => { input.value = 74 })
})
