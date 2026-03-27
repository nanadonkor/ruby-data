// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener("turbo:load", () => {
  const toggleButton = document.getElementById("theme-toggle")
  const body = document.body

  const savedTheme = localStorage.getItem("theme")

  if (savedTheme === "dark") {
    body.classList.add("dark-mode")
    if (toggleButton) toggleButton.textContent = "Light Mode"
  }

  if (toggleButton) {
    toggleButton.addEventListener("click", () => {
      body.classList.toggle("dark-mode")

      if (body.classList.contains("dark-mode")) {
        localStorage.setItem("theme", "dark")
        toggleButton.textContent = "Light Mode"
      } else {
        localStorage.setItem("theme", "light")
        toggleButton.textContent = "Dark Mode"
      }
    })
  }
})